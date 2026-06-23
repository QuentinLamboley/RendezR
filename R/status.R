#' Inspect current local RendezR LAN state
#' @return An object of class `rendezr_status`.
#' @export
rr_status <- function() {
  cfg <- rr_get_config()
  out <- list(
    state = .rr$state %||% "offline",
    active = isTRUE(.rr$started),
    address = .rr$advertise_address %||% "<not started>",
    port = .rr$port %||% cfg$default_port,
    subnet = .rr$subnet %||% "<not selected>",
    room = .rr$room %||% cfg$default_room,
    available = isTRUE(.rr$available),
    nickname = cfg$nickname,
    active_peer = .rr$active_peer$nickname %||% NA_character_,
    session_messages = length(.rr$inbox %||% list()),
    discovered_peers = length(.rr$peers %||% list()),
    terms_accepted = rr_has_accepted_rules(),
    local_block_count = length(rr_local_blocks())
  )
  class(out) <- "rendezr_status"
  out
}

#' @export
print.rendezr_status <- function(x, ...) {
  cat("RendezR LAN status\n")
  cat("  state: ", x$state, "\n", sep = "")
  cat("  active: ", if (isTRUE(x$active)) "yes" else "no", "\n", sep = "")
  cat("  endpoint: ", x$address, ":", x$port, "\n", sep = "")
  cat("  subnet: ", x$subnet, "\n", sep = "")
  cat("  room: ", x$room, "\n", sep = "")
  cat("  available: ", if (isTRUE(x$available)) "yes" else "no", "\n", sep = "")
  cat("  pseudonym: ", x$nickname, "\n", sep = "")
  if (!is.na(x$active_peer)) cat("  peer: ", x$active_peer, "\n", sep = "")
  cat("  discovered peers: ", x$discovered_peers, "\n", sep = "")
  cat("  session messages: ", x$session_messages, "\n", sep = "")
  cat("  local blocks: ", x$local_block_count, "\n", sep = "")
  invisible(x)
}

#' Show core RendezR LAN commands
#' @export
rr_help <- function() {
  cat(paste(
    "RendezR LAN core commands:",
    "  rr_terms(); rr_accept_rules(accept = TRUE)",
    "  rr_lan_start(room = 'general')",
    "  rr_lan_find(); rr_send('Hello'); rr_inbox(); rr_leave()",
    "  rr_lan_peers(); rr_lan_set_available(FALSE); rr_lan_stop()",
    "  rr_block(); rr_report('local note'); rr_status()",
    "  rr_pump() during long computations",
    sep = "\n"
  ), "\n")
  invisible(NULL)
}
