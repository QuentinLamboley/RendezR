#' Send a direct message to the active local peer
#'
#' Messages are sent as local HTTP requests directly between the two opted-in
#' machines. Version 0.2.0 does not provide end-to-end encryption; do not send
#' sensitive content.
#'
#' @param text One message of at most 600 characters.
#' @return Invisibly `TRUE` on accepted delivery.
#' @export
rr_send <- function(text) {
  rr_require_match()
  text <- rr_validate_message(text)
  payload <- list(
    message_id = uuid::UUIDgenerate(),
    body = text,
    sent_at = rr_now()
  )
  reply <- rr_post_to_peer("/rr/v1/message", payload)
  if (!isTRUE(reply$ok)) rr_abort("The local peer did not accept the message.")
  rr_add_inbox("outgoing", text, peer = .rr$active_peer$nickname, id = payload$message_id)
  rr_console_line("you>", text)
  invisible(TRUE)
}

#' End the active local conversation safely
#' @return Invisibly `TRUE`.
#' @export
rr_leave <- function() {
  rr_require_match()
  peer <- .rr$active_peer$nickname %||% "Local peer"
  try(rr_post_to_peer("/rr/v1/leave", list(reason = "left")), silent = TRUE)
  rr_clear_match(make_available = TRUE)
  rr_console_line("rendezr", paste0("conversation with ", peer, " ended; you are available again."))
  invisible(TRUE)
}

#' Inspect in-memory conversation messages
#' @return A data frame containing messages held only in the active R session.
#' @export
rr_inbox <- function() {
  x <- .rr$inbox %||% list()
  if (!length(x)) return(data.frame(direction = character(), at = character(), peer = character(), body = character(), id = character(), stringsAsFactors = FALSE))
  data.frame(
    direction = vapply(x, `[[`, character(1), "direction"),
    at = vapply(x, `[[`, character(1), "at"),
    peer = vapply(x, `[[`, character(1), "peer"),
    body = vapply(x, `[[`, character(1), "body"),
    id = vapply(x, `[[`, character(1), "id"),
    stringsAsFactors = FALSE
  )
}

#' Clear in-memory messages from the current R session
#' @return Invisibly `TRUE`.
#' @export
rr_clear_inbox <- function() {
  .rr$inbox <- list()
  invisible(TRUE)
}

#' Process pending local listener callbacks
#'
#' RStudio usually processes callbacks while the console is idle. Call this inside
#' a long-running computation or loop when you want to manually service queued
#' local messages.
#'
#' @param timeout_secs Maximum time spent processing callbacks.
#' @return Invisibly `TRUE`.
#' @export
rr_pump <- function(timeout_secs = 0) {
  timeout_secs <- suppressWarnings(as.numeric(timeout_secs))
  if (is.na(timeout_secs) || timeout_secs < 0 || timeout_secs > 5) rr_abort("timeout_secs must be between 0 and 5.")
  try(later::run_now(timeout_secs = timeout_secs), silent = TRUE)
  invisible(TRUE)
}

#' Run a minimal console chat loop
#'
#' Use `/leave` to end the conversation, `/status` to print status, and `/quit`
#' to stop LAN mode. Incoming messages are handled when R returns to its event
#' loop; `rr_pump()` is called before each prompt.
#'
#' @export
rr_console <- function() {
  rr_require_match()
  cat("Console mode. Type /leave to leave, /quit to stop LAN mode, /status for status.\n")
  while (identical(.rr$state, "matched")) {
    rr_pump(0)
    line <- readline("rendezr> ")
    if (identical(line, "/leave")) { rr_leave(); break }
    if (identical(line, "/quit")) { rr_lan_stop(); break }
    if (identical(line, "/status")) { print(rr_status()); next }
    if (nzchar(trimws(line))) rr_send(line)
  }
  invisible(NULL)
}
