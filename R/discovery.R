rr_peer_record <- function(payload, address) {
  list(
    id = rr_scalar(payload$id),
    nickname = rr_validate_nickname(rr_scalar(payload$nickname, "Anonymous peer")),
    locale = rr_scalar(payload$locale, ""),
    room = rr_scalar(payload$room, ""),
    port = rr_validate_port(payload$port),
    address = address,
    available = isTRUE(payload$available),
    protocol = rr_scalar(payload$protocol),
    seen_at = rr_now()
  )
}

rr_peers_to_df <- function(peers = .rr$peers %||% list()) {
  if (!length(peers)) {
    return(data.frame(id = character(), nickname = character(), locale = character(), room = character(), port = integer(), address = character(), available = logical(), protocol = character(), seen_at = character(), stringsAsFactors = FALSE))
  }
  data.frame(
    id = vapply(peers, `[[`, character(1), "id"),
    nickname = vapply(peers, `[[`, character(1), "nickname"),
    locale = vapply(peers, `[[`, character(1), "locale"),
    room = vapply(peers, `[[`, character(1), "room"),
    port = as.integer(vapply(peers, `[[`, numeric(1), "port")),
    address = vapply(peers, `[[`, character(1), "address"),
    available = vapply(peers, `[[`, logical(1), "available"),
    protocol = vapply(peers, `[[`, character(1), "protocol"),
    seen_at = vapply(peers, `[[`, character(1), "seen_at"),
    stringsAsFactors = FALSE
  )
}

#' Discover opted-in RendezR peers on the private local subnet
#'
#' Discovery is intentional and bounded: it probes only the configured fixed port
#' on the private CIDR selected by `rr_lan_start()`, which defaults to one `/24`
#' subnet. It never scans the public Internet and never runs at package load.
#'
#' @param timeout_ms Per-host connection timeout in milliseconds.
#' @param refresh Whether to overwrite the session's previous discovery cache.
#' @return A data frame of peers that responded to the local protocol endpoint.
#' @export
rr_lan_discover <- function(timeout_ms = 550L, refresh = TRUE) {
  rr_require_started()
  timeout_ms <- suppressWarnings(as.integer(timeout_ms))
  if (is.na(timeout_ms) || timeout_ms < 100L || timeout_ms > 5000L) rr_abort("timeout_ms must be between 100 and 5000.")
  hosts <- rr_cidr_hosts(.rr$subnet, max_hosts = 254L)
  hosts <- setdiff(hosts, .rr$advertise_address)
  peers <- list()
  pool <- curl::new_pool(total_con = min(64L, length(hosts)), host_con = 1L, multiplex = FALSE)
  for (address in hosts) {
    url <- rr_peer_url(address, .rr$port, "/rr/v1/ping")
    h <- rr_http_handle(timeout_ms)
    curl::curl_fetch_multi(
      url,
      done = local({ addr <- address; function(res) {
        if (!identical(as.integer(res$status_code), 200L)) return(invisible(NULL))
        payload <- tryCatch(jsonlite::fromJSON(rawToChar(res$content), simplifyVector = FALSE), error = function(e) NULL)
        if (is.null(payload) || !isTRUE(payload$ok) || !identical(rr_scalar(payload$protocol), rr_protocol_version())) return(invisible(NULL))
        if (identical(rr_scalar(payload$id), rr_get_config()$identity)) return(invisible(NULL))
        if (!rr_is_private_ipv4(addr) || !rr_ip_in_cidr(addr, .rr$subnet)) return(invisible(NULL))
        peer <- tryCatch(rr_peer_record(payload, addr), error = function(e) NULL)
        if (!is.null(peer)) peers[[length(peers) + 1L]] <<- peer
        invisible(NULL)
      }}),
      fail = function(msg) invisible(NULL),
      pool = pool,
      handle = h
    )
  }
  if (length(hosts)) try(curl::multi_run(pool = pool, timeout = max(2, (timeout_ms + 1500) / 1000)), silent = TRUE)
  if (isTRUE(refresh)) .rr$peers <- peers
  out <- rr_peers_to_df(peers)
  if (nrow(out)) {
    cli::cli_alert_success(paste0(nrow(out), " opted-in local peer(s) discovered; ", sum(out$available), " currently available."))
  } else {
    cli::cli_alert_info("No opted-in RendezR LAN peer responded on this subnet and port.")
  }
  out
}

#' Inspect the session-local LAN discovery cache
#' @return A data frame of recently discovered opted-in peers.
#' @export
rr_lan_peers <- function() rr_peers_to_df(.rr$peers %||% list())

#' Change whether this local peer is available for random pairing
#' @param available Logical. Cannot become available during an active chat.
#' @return Invisibly the new availability.
#' @export
rr_lan_set_available <- function(available = TRUE) {
  rr_require_started()
  if (identical(.rr$state, "matched") && isTRUE(available)) rr_abort("Leave the active conversation before becoming available.")
  .rr$available <- isTRUE(available)
  if (!.rr$available && identical(.rr$state, "idle")) cli::cli_alert_info("Local peer is now hidden from random matching.")
  if (.rr$available && identical(.rr$state, "idle")) cli::cli_alert_success("Local peer is available for random matching.")
  invisible(.rr$available)
}
