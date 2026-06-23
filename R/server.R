rr_lan_server_app <- function() {
  list(
    call = function(req) {
      method <- toupper(as.character(req$REQUEST_METHOD %||% "GET"))
      path <- as.character(req$PATH_INFO %||% "/")
      remote <- as.character(req$REMOTE_ADDR %||% "")
      if (!rr_request_is_local(remote)) {
        return(rr_json_response(list(ok = FALSE, error = "LAN-only endpoint."), status = 403L))
      }
      tryCatch({
        if (identical(method, "GET") && identical(path, "/rr/v1/ping")) return(rr_lan_ping_response())
        if (identical(method, "POST") && identical(path, "/rr/v1/pair")) return(rr_lan_pair_response(req))
        if (identical(method, "POST") && identical(path, "/rr/v1/message")) return(rr_lan_message_response(req))
        if (identical(method, "POST") && identical(path, "/rr/v1/leave")) return(rr_lan_leave_response(req))
        rr_json_response(list(ok = FALSE, error = "Not found."), status = 404L)
      }, error = function(e) {
        rr_json_response(list(ok = FALSE, error = conditionMessage(e)), status = 400L)
      })
    }
  )
}

rr_request_is_local <- function(remote) {
  if (identical(remote, "127.0.0.1") || identical(remote, "::1")) return(TRUE)
  isTRUE(.rr$started) && nzchar(.rr$subnet %||% "") && rr_is_private_ipv4(remote) && rr_ip_in_cidr(remote, .rr$subnet)
}

rr_lan_ping_response <- function() {
  cfg <- rr_get_config()
  rr_json_response(list(
    ok = TRUE,
    protocol = rr_protocol_version(),
    version = as.character(utils::packageVersion("rendezr")),
    id = cfg$identity,
    nickname = cfg$nickname,
    locale = cfg$locale,
    room = .rr$room,
    port = .rr$port,
    available = isTRUE(.rr$available) && identical(.rr$state, "idle"),
    subnet = .rr$subnet
  ))
}

rr_lan_pair_response <- function(req) {
  body <- rr_read_json_body(req)
  rr_validate_pair_request(body)
  cfg <- rr_get_config()
  sender_id <- rr_scalar(body$sender_id)
  if (sender_id %in% rr_local_blocks()) return(rr_json_response(list(ok = FALSE, accepted = FALSE, reason = "blocked")))
  if (!isTRUE(.rr$available) || !identical(.rr$state, "idle")) return(rr_json_response(list(ok = TRUE, accepted = FALSE, reason = "unavailable")))
  if (!identical(rr_scalar(body$room), .rr$room)) return(rr_json_response(list(ok = TRUE, accepted = FALSE, reason = "room_mismatch")))
  if (!identical(rr_scalar(body$protocol), rr_protocol_version())) return(rr_json_response(list(ok = TRUE, accepted = FALSE, reason = "protocol_mismatch")))
  sender_address <- rr_scalar(body$sender_address)
  request_address <- as.character(req$REMOTE_ADDR %||% "")
  if (!rr_ip_in_cidr(sender_address, .rr$subnet) || !identical(sender_address, request_address)) {
    return(rr_json_response(list(ok = FALSE, accepted = FALSE, reason = "non_local_sender")))
  }
  token <- rr_uuid_token()
  .rr$active_peer <- list(
    id = sender_id,
    nickname = rr_validate_nickname(rr_scalar(body$sender_nickname, "Anonymous peer")),
    locale = rr_scalar(body$sender_locale, ""),
    address = sender_address,
    port = rr_validate_port(body$sender_port),
    token = token,
    paired_at = rr_now(),
    room = .rr$room
  )
  .rr$state <- "matched"
  .rr$available <- FALSE
  rr_console_line("rendezr", paste0("matched with ", .rr$active_peer$nickname, " on the local network. Use rr_send('…')."))
  rr_json_response(list(
    ok = TRUE,
    accepted = TRUE,
    token = token,
    peer_id = cfg$identity,
    peer_nickname = cfg$nickname,
    peer_locale = cfg$locale,
    peer_address = .rr$advertise_address,
    peer_port = .rr$port
  ))
}

rr_validate_pair_request <- function(body) {
  need <- c("protocol", "sender_id", "sender_nickname", "sender_address", "sender_port", "room")
  if (!is.list(body) || !all(need %in% names(body))) rr_abort("Malformed pair request.")
  if (!rr_is_private_ipv4(rr_scalar(body$sender_address))) rr_abort("Sender address is not a private IPv4 address.")
  rr_validate_port(body$sender_port)
  invisible(TRUE)
}

rr_session_authorized <- function(body, remote = NULL) {
  is.list(body) && identical(.rr$state, "matched") && !is.null(.rr$active_peer) &&
    identical(rr_scalar(body$sender_id), .rr$active_peer$id) &&
    identical(rr_scalar(body$token), .rr$active_peer$token) &&
    (is.null(remote) || identical(as.character(remote), .rr$active_peer$address))
}

rr_lan_message_response <- function(req) {
  body <- rr_read_json_body(req)
  if (!rr_session_authorized(body, req$REMOTE_ADDR %||% "")) return(rr_json_response(list(ok = FALSE, error = "Unauthorized session."), status = 403L))
  message <- rr_validate_message(rr_scalar(body$body), allow_contact_details = rr_get_config()$allow_contact_details)
  peer_name <- .rr$active_peer$nickname %||% "Local peer"
  rr_add_inbox("incoming", message, peer = peer_name, id = rr_scalar(body$message_id, NULL))
  rr_console_line(paste0(peer_name, ">"), message)
  rr_json_response(list(ok = TRUE, received_at = rr_now()))
}

rr_lan_leave_response <- function(req) {
  body <- rr_read_json_body(req)
  if (!rr_session_authorized(body, req$REMOTE_ADDR %||% "")) return(rr_json_response(list(ok = FALSE, error = "Unauthorized session."), status = 403L))
  peer <- .rr$active_peer$nickname %||% "The peer"
  rr_clear_match(make_available = TRUE)
  rr_console_line("rendezr", paste0(peer, " left the local conversation."))
  rr_json_response(list(ok = TRUE))
}

rr_clear_match <- function(make_available = TRUE) {
  .rr$active_peer <- NULL
  .rr$state <- if (isTRUE(.rr$started)) "idle" else "offline"
  .rr$available <- isTRUE(make_available) && isTRUE(.rr$started)
  invisible(TRUE)
}

#' Start a local RendezR LAN peer
#'
#' Starts a small HTTP listener on the current computer and advertises no data
#' until another explicitly initiated RendezR LAN discovery probes its fixed local
#' port. The listener accepts only source addresses inside the selected private
#' IPv4 CIDR. It is not a public relay or central service.
#'
#' @param port TCP port shared by local peers, default `47831`.
#' @param address Local private IPv4 address to advertise. By default the first
#'   private address detected on the current computer is used.
#' @param subnet Private CIDR to scan/accept, such as `"192.168.1.0/24"`. The
#'   default is a conservative `/24` around `address`.
#' @param room Conversation room. Only peers using the same room can match.
#' @param available Whether this peer can receive a random match immediately.
#' @return Invisibly returns local LAN status.
#' @export
rr_lan_start <- function(port = rr_get_config()$default_port, address = NULL,
                         subnet = NULL, room = rr_get_config()$default_room,
                         available = TRUE) {
  rr_require_rules()
  if (isTRUE(.rr$started)) rr_abort("RendezR LAN is already active. Call rr_lan_stop() before starting another listener.")
  port <- rr_validate_port(port)
  address <- rr_choose_ipv4(address)
  subnet <- subnet %||% rr_default_cidr(address)
  subnet_info <- rr_parse_cidr(subnet)
  if (!rr_ip_in_cidr(address, subnet_info)) rr_abort("The advertised address must belong to subnet.")
  room <- rr_validate_room(room)
  listener <- tryCatch(
    httpuv::startServer(host = "0.0.0.0", port = port, app = rr_lan_server_app()),
    error = function(e) rr_abort(paste0("Could not open local port ", port, ": ", conditionMessage(e), ". Choose another port or allow private-network access in the firewall."))
  )
  .rr$listener <- listener
  .rr$started <- TRUE
  .rr$state <- "idle"
  .rr$port <- port
  .rr$advertise_address <- address
  .rr$subnet <- subnet_info$cidr
  .rr$room <- room
  .rr$available <- isTRUE(available)
  cli::cli_alert_success(paste0("RendezR LAN is active on ", address, ":", port, " (", .rr$subnet, ", room: ", room, ")."))
  cli::cli_alert_info("No server, domain, account or public Internet connection is used. Run rr_lan_find() to explicitly search this private subnet.")
  invisible(rr_status())
}

#' Stop local RendezR LAN mode
#'
#' Ends the active chat, closes the local listener and removes this R session from
#' local discovery. No external service is contacted.
#'
#' @param notify_peer Whether to attempt a direct local leave notification.
#' @return Invisibly `TRUE`.
#' @export
rr_lan_stop <- function(notify_peer = TRUE) {
  if (!isTRUE(.rr$started)) return(invisible(FALSE))
  if (isTRUE(notify_peer) && identical(.rr$state, "matched") && !is.null(.rr$active_peer)) {
    try(rr_post_to_peer("/rr/v1/leave", list(reason = "peer_stopped")), silent = TRUE)
  }
  if (!is.null(.rr$listener)) try(.rr$listener$stop(), silent = TRUE)
  rr_reset_runtime(keep_config = TRUE)
  cli::cli_alert_info("RendezR LAN stopped; local listener closed.")
  invisible(TRUE)
}

#' Compatibility alias for starting local LAN mode
#' @export
rr_connect <- function(...) {
  cli::cli_alert_info("rr_connect() now starts local LAN mode. Prefer rr_lan_start().")
  rr_lan_start(...)
}

#' Compatibility alias for stopping local LAN mode
#' @export
rr_disconnect <- function(...) rr_lan_stop(...)
