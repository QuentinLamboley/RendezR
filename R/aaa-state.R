.rr <- new.env(parent = emptyenv())

rr_init <- function(force = FALSE) {
  if (!force && isTRUE(.rr$initialized)) return(invisible(NULL))
  .rr$initialized <- TRUE
  .rr$listener <- NULL
  .rr$started <- FALSE
  .rr$state <- "offline"
  .rr$active_peer <- NULL
  .rr$inbox <- list()
  .rr$peers <- list()
  .rr$port <- NULL
  .rr$advertise_address <- NULL
  .rr$subnet <- NULL
  .rr$room <- "general"
  .rr$available <- FALSE
  .rr$config <- NULL
  invisible(NULL)
}

rr_reset_runtime <- function(keep_config = TRUE) {
  cfg <- if (keep_config) rr_get_config() else NULL
  rr_init(force = TRUE)
  .rr$config <- cfg
  invisible(NULL)
}

rr_protocol_version <- function() "2"
rr_terms_version <- function() "2026-06-24-lan-v1"

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L || (is.character(x) && !nzchar(x[[1L]]))) y else x
}
