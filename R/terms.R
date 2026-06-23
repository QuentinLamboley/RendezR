rr_terms_text <- function() {
  paste(
    "RendezR LAN is an opt-in peer-to-peer conversation tool for private local IPv4 networks.",
    "It has no central service, account, domain, or cloud relay. A participating R session opens a temporary local listener and peers send messages directly to one another.",
    "Use it only on a network you are authorised to use. Do not use it to probe networks that you do not own or administer.",
    "Local LAN HTTP traffic is not end-to-end encrypted in version 0.2.0. Do not share personal, health, financial, identifying, confidential, or regulated information.",
    "Do not harass, threaten, sexualize, solicit, or attempt to identify another person. Do not use the tool for emergencies.",
    "The package blocks links, email addresses and phone-like strings by default. You may leave or block a peer at any time.",
    "See CODE_OF_CONDUCT.md, PRIVACY.md, and SECURITY.md before using the package in a shared workplace or institutional network.",
    sep = "\n\n"
  )
}

#' Display RendezR LAN participation rules
#' @export
rr_terms <- function() {
  cat(rr_terms_text(), "\n")
  invisible(rr_terms_text())
}

rr_has_accepted_rules <- function() identical(rr_get_config()$accepted_terms_version, rr_terms_version())

rr_require_rules <- function() {
  if (!rr_has_accepted_rules()) {
    rr_abort("Participation rules have not been accepted for this version. Read rr_terms() and call rr_accept_rules(accept = TRUE).")
  }
  invisible(TRUE)
}

#' Explicitly accept participation rules before starting LAN mode
#'
#' `library(rendezr)` never opens a listener or scans a network. This explicit
#' consent step is required before `rr_lan_start()` can make the local session
#' discoverable.
#'
#' @param accept Must be `TRUE` non-interactively. Interactively, a confirmation
#'   prompt is shown when omitted.
#' @return Invisibly `TRUE` when consent was stored locally.
#' @export
rr_accept_rules <- function(accept = FALSE) {
  if (!isTRUE(accept)) {
    if (!interactive()) rr_abort("Set accept = TRUE only after reading rr_terms().")
    rr_terms()
    answer <- tolower(trimws(readline("I confirm that I meet these conditions [yes/NO]: ")))
    if (!answer %in% c("y", "yes", "oui", "o")) {
      cli::cli_alert_info("No consent was stored; RendezR LAN remains offline.")
      return(invisible(FALSE))
    }
  }
  cfg <- rr_get_config()
  cfg$accepted_terms_version <- rr_terms_version()
  cfg$accepted_terms_at <- format(Sys.time(), tz = "UTC", usetz = TRUE)
  rr_set_config(cfg, persist = TRUE)
  cli::cli_alert_success("Participation rules accepted locally. No port has been opened yet.")
  invisible(TRUE)
}
