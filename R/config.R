rr_config_dir <- function() fs::path(rappdirs::user_config_dir("rendezr"))
rr_config_file <- function() fs::path(rr_config_dir(), "settings.json")

rr_default_nickname <- function() {
  left <- c("Curious", "Quiet", "Bright", "Kind", "Rapid", "Mellow", "Clever", "Gentle")
  right <- c("Badger", "Manta", "Lynx", "Otter", "Puffin", "Fox", "Raven", "Mole")
  paste0(sample(left, 1L), "-", sample(right, 1L), "-", sample(1000:9999, 1L))
}

rr_default_config <- function() {
  raw_locale <- tolower(Sys.getenv("LANG", unset = "en"))
  locale <- sub("[_.].*$", "", raw_locale)
  if (!grepl("^[a-z0-9_-]{1,12}$", locale, perl = TRUE)) locale <- "en"
  list(
    nickname = rr_default_nickname(),
    locale = locale,
    identity = uuid::UUIDgenerate(),
    accepted_terms_version = NULL,
    accepted_terms_at = NULL,
    blocked_peer_ids = character(),
    allow_contact_details = FALSE,
    default_port = 47831L,
    default_room = "general"
  )
}

rr_normalize_config <- function(x) {
  base <- rr_default_config()
  if (!is.list(x)) return(base)
  for (nm in intersect(names(x), names(base))) base[[nm]] <- x[[nm]]
  base$blocked_peer_ids <- unique(as.character(base$blocked_peer_ids %||% character()))
  base$nickname <- rr_validate_nickname(base$nickname)
  base$identity <- as.character(base$identity %||% uuid::UUIDgenerate())
  base$default_port <- rr_validate_port(base$default_port)
  base$default_room <- rr_validate_room(base$default_room)
  base
}

rr_read_config <- function() {
  path <- rr_config_file()
  if (!fs::file_exists(path)) return(rr_default_config())
  out <- tryCatch(jsonlite::read_json(path, simplifyVector = FALSE), error = function(e) NULL)
  rr_normalize_config(out)
}

rr_write_config <- function(config = rr_get_config()) {
  fs::dir_create(rr_config_dir(), recurse = TRUE)
  jsonlite::write_json(config, rr_config_file(), auto_unbox = TRUE, pretty = TRUE, null = "null")
  invisible(config)
}

rr_get_config <- function() {
  if (is.null(.rr$config)) .rr$config <- rr_read_config()
  .rr$config
}

rr_set_config <- function(config, persist = TRUE) {
  .rr$config <- rr_normalize_config(config)
  if (persist) rr_write_config(.rr$config)
  invisible(.rr$config)
}

rr_validate_nickname <- function(nickname) {
  nickname <- trimws(as.character(nickname %||% ""))
  nickname <- gsub("[^[:alnum:] _.-]", "", nickname, perl = TRUE)
  nickname <- gsub("\\s+", " ", nickname, perl = TRUE)
  if (!nzchar(nickname)) nickname <- rr_default_nickname()
  substr(nickname, 1L, 32L)
}

rr_validate_port <- function(port) {
  port <- suppressWarnings(as.integer(port[[1L]]))
  if (is.na(port) || port < 1024L || port > 65535L) {
    rr_abort("Port must be an integer between 1024 and 65535.")
  }
  port
}

rr_validate_room <- function(room) {
  room <- tolower(trimws(as.character(room %||% "general")))
  room <- gsub("[^a-z0-9_-]", "-", room, perl = TRUE)
  room <- gsub("-+", "-", room, perl = TRUE)
  room <- gsub("(^-|-$)", "", room, perl = TRUE)
  if (!nzchar(room)) room <- "general"
  substr(room, 1L, 32L)
}

#' Configure local RendezR LAN preferences
#'
#' The configuration stays on the current computer. This function never opens a
#' port, scans a network, or transmits data.
#'
#' @param nickname Optional pseudonym shown to a matched local peer.
#' @param locale Optional language tag such as `"fr"` or `"en"`.
#' @param port Default local TCP port used by `rr_lan_start()`.
#' @param room Default local conversation room. Peers must use the same room to
#'   be considered for random pairing.
#' @param allow_contact_details Logical. Defaults to `FALSE`; links, emails and
#'   phone-like strings are rejected locally when `FALSE`.
#' @return Invisibly returns the stored local configuration.
#' @export
rr_config <- function(nickname = NULL, locale = NULL, port = NULL, room = NULL,
                      allow_contact_details = NULL) {
  cfg <- rr_get_config()
  if (!is.null(nickname)) cfg$nickname <- rr_validate_nickname(nickname)
  if (!is.null(locale)) cfg$locale <- substr(trimws(as.character(locale)), 1L, 12L)
  if (!is.null(port)) cfg$default_port <- rr_validate_port(port)
  if (!is.null(room)) cfg$default_room <- rr_validate_room(room)
  if (!is.null(allow_contact_details)) cfg$allow_contact_details <- isTRUE(allow_contact_details)
  rr_set_config(cfg, persist = TRUE)
  cli::cli_alert_success("RendezR LAN configuration saved locally.")
  invisible(cfg)
}

#' Change the local pseudonym
#' @param nickname A short pseudonym. Avoid real-world identifying information.
#' @export
rr_set_nickname <- function(nickname) rr_config(nickname = nickname)

#' Rotate the local pseudonymous identifier
#'
#' Rotating the identifier clears locally stored blocks because older peer IDs no
#' longer identify the current client. It never transmits anything.
#'
#' @param confirm Must be `TRUE` outside an interactive confirmation prompt.
#' @export
rr_rotate_identity <- function(confirm = FALSE) {
  if (!isTRUE(confirm)) {
    if (!interactive()) rr_abort("Set confirm = TRUE to rotate the local identity non-interactively.")
    answer <- tolower(trimws(readline("Rotate pseudonymous identity and clear local blocks? [yes/NO]: ")))
    if (!answer %in% c("y", "yes", "oui", "o")) return(invisible(FALSE))
  }
  cfg <- rr_get_config()
  cfg$identity <- uuid::UUIDgenerate()
  cfg$blocked_peer_ids <- character()
  rr_set_config(cfg, persist = TRUE)
  cli::cli_alert_success("A new local pseudonymous identity was created.")
  invisible(TRUE)
}
