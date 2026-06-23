rr_candidate_peers <- function(room = .rr$room) {
  peers <- .rr$peers %||% list()
  blocked <- rr_local_blocks()
  Filter(function(x) {
    isTRUE(x$available) &&
      identical(x$room, room) &&
      identical(x$protocol, rr_protocol_version()) &&
      !identical(x$id, rr_get_config()$identity) &&
      !x$id %in% blocked
  }, peers)
}

rr_post_to_peer <- function(path, payload, peer = .rr$active_peer, timeout_ms = 1000L) {
  if (is.null(peer)) rr_abort("No local peer is selected.")
  payload$sender_id <- rr_get_config()$identity
  if (!is.null(peer$token)) payload$token <- peer$token
  rr_http_post_json(rr_peer_url(peer$address, peer$port, path), payload, timeout_ms = timeout_ms)
}

#' Randomly pair with an available opted-in peer on the same local subnet
#'
#' The function refreshes the bounded local discovery cache by default, excludes
#' blocked peers, selects one compatible available peer uniformly at random, and
#' asks that peer to accept the direct LAN conversation. No central matchmaker is
#' used.
#'
#' @param room Conversation room. Defaults to the room selected at start-up.
#' @param refresh Whether to run a new bounded local discovery before pairing.
#' @return Invisibly returns the active peer on success.
#' @export
rr_lan_find <- function(room = .rr$room, refresh = TRUE) {
  rr_require_started()
  if (identical(.rr$state, "matched")) rr_abort("Leave the current conversation before requesting another peer.")
  room <- rr_validate_room(room)
  if (isTRUE(refresh)) rr_lan_discover(refresh = TRUE)
  candidates <- rr_candidate_peers(room)
  if (!length(candidates)) {
    cli::cli_alert_info("No available compatible peer was found on this local subnet. Ask another participant to run rr_lan_start() with the same port and room.")
    return(invisible(NULL))
  }
  order <- sample.int(length(candidates), length(candidates), replace = FALSE)
  for (i in order) {
    candidate <- candidates[[i]]
    payload <- list(
      protocol = rr_protocol_version(),
      sender_id = rr_get_config()$identity,
      sender_nickname = rr_get_config()$nickname,
      sender_locale = rr_get_config()$locale,
      sender_address = .rr$advertise_address,
      sender_port = .rr$port,
      room = room,
      nonce = rr_uuid_token()
    )
    reply <- tryCatch(rr_http_post_json(rr_peer_url(candidate$address, candidate$port, "/rr/v1/pair"), payload), error = function(e) NULL)
    if (!is.null(reply) && isTRUE(reply$ok) && isTRUE(reply$accepted)) {
      .rr$active_peer <- list(
        id = rr_scalar(reply$peer_id),
        nickname = rr_validate_nickname(rr_scalar(reply$peer_nickname, candidate$nickname)),
        locale = rr_scalar(reply$peer_locale, candidate$locale),
        address = candidate$address,
        port = candidate$port,
        token = rr_scalar(reply$token),
        paired_at = rr_now(),
        room = room
      )
      .rr$state <- "matched"
      .rr$available <- FALSE
      rr_console_line("rendezr", paste0("matched with ", .rr$active_peer$nickname, " on the local network. Send a message with rr_send('…')."))
      return(invisible(.rr$active_peer))
    }
  }
  cli::cli_alert_info("Compatible peers were discovered, but none remained available when contacted. Try rr_lan_find() again.")
  invisible(NULL)
}

#' Compatibility alias for local random matching
#' @export
rr_find <- function(...) rr_lan_find(...)

#' Cancel a pending local match request
#'
#' In LAN mode requests are synchronous and have no persistent central queue, so
#' this function only reports that there is no queue to cancel.
#' @export
rr_cancel_match <- function() {
  if (identical(.rr$state, "waiting")) .rr$state <- "idle"
  cli::cli_alert_info("RendezR LAN has no central waiting queue; no pending match is stored.")
  invisible(TRUE)
}
