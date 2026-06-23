#' Block the current local peer and end the conversation
#'
#' The block is stored only in the local RendezR configuration. A blocked peer is
#' excluded from future random pairing on this computer.
#'
#' @param reason Optional private note recorded only in the current R session.
#' @return Invisibly `TRUE`.
#' @export
rr_block <- function(reason = NULL) {
  rr_require_match()
  peer_id <- .rr$active_peer$id
  peer_name <- .rr$active_peer$nickname %||% "Local peer"
  rr_add_local_block(peer_id)
  if (!is.null(reason)) {
    reason <- substr(rr_validate_message(as.character(reason), allow_contact_details = FALSE), 1L, 240L)
    rr_add_inbox("local_note", paste0("Blocked peer: ", reason), peer = peer_name)
  }
  try(rr_post_to_peer("/rr/v1/leave", list(reason = "blocked")), silent = TRUE)
  rr_clear_match(make_available = TRUE)
  cli::cli_alert_success("Peer blocked locally and conversation ended.")
  invisible(TRUE)
}

#' Record a local safety note
#'
#' LAN mode has no central operator or reporting service. This function stores a
#' short note only in the current R session and never transmits it.
#'
#' @param reason Short local note, maximum 240 characters.
#' @param include_recent Logical. When `TRUE`, only a notice is added that recent
#'   messages were intentionally retained in the active R session; no content is
#'   sent anywhere.
#' @return Invisibly `TRUE`.
#' @export
rr_report <- function(reason, include_recent = FALSE) {
  rr_require_match()
  reason <- substr(rr_validate_message(as.character(reason), allow_contact_details = FALSE), 1L, 240L)
  suffix <- if (isTRUE(include_recent)) " (recent messages remain in this R session only)" else ""
  rr_add_inbox("local_report", paste0(reason, suffix), peer = .rr$active_peer$nickname)
  cli::cli_alert_info("Local note recorded in this R session only. LAN mode has no central reporting service.")
  invisible(TRUE)
}
