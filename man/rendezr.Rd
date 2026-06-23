\name{rendezr}
\alias{rendezr}
\alias{rr_accept_rules}
\alias{rr_block}
\alias{rr_cancel_match}
\alias{rr_clear_inbox}
\alias{rr_config}
\alias{rr_connect}
\alias{rr_console}
\alias{rr_disconnect}
\alias{rr_find}
\alias{rr_help}
\alias{rr_inbox}
\alias{rr_lan_discover}
\alias{rr_lan_find}
\alias{rr_lan_peers}
\alias{rr_lan_set_available}
\alias{rr_lan_start}
\alias{rr_lan_stop}
\alias{rr_leave}
\alias{rr_pump}
\alias{rr_report}
\alias{rr_rotate_identity}
\alias{rr_send}
\alias{rr_set_nickname}
\alias{rr_status}
\alias{rr_terms}
\title{RendezR LAN: consent-first random local-network conversations for R}
\description{
RendezR LAN enables direct, opt-in, short-lived console conversations between
people who have started the package on the same private IPv4 local network.
It never opens a port or scans a network at package load time. There is no
central service, account, domain or public relay.
}
\usage{
rr_terms()
rr_accept_rules(accept = FALSE)
rr_config(nickname = NULL, locale = NULL, port = NULL, room = NULL,
  allow_contact_details = NULL)
rr_lan_start(port = rr_get_config()$default_port, address = NULL,
  subnet = NULL, room = rr_get_config()$default_room, available = TRUE)
rr_lan_discover(timeout_ms = 550L, refresh = TRUE)
rr_lan_peers()
rr_lan_find(room = .rr$room, refresh = TRUE)
rr_send(text)
rr_leave()
rr_lan_stop(notify_peer = TRUE)
rr_lan_set_available(available = TRUE)
rr_block(reason = NULL)
rr_report(reason, include_recent = FALSE)
rr_status()
rr_pump(timeout_secs = 0)
}
\arguments{
  \item{accept}{Logical confirmation after reading the participation rules.}
  \item{nickname}{A short pseudonym.}
  \item{locale}{A language tag.}
  \item{port}{Local TCP port shared by peers, default 47831.}
  \item{room}{A local room identifier; peers must share it to match.}
  \item{allow_contact_details}{Whether local message validation may permit contact-like strings.}
  \item{address}{Private local IPv4 address to advertise.}
  \item{subnet}{Private IPv4 CIDR, usually a conservative /24.}
  \item{available}{Whether the participant is eligible for random matching.}
  \item{timeout_ms}{Discovery per-host timeout.}
  \item{refresh}{Whether discovery should replace the local cache.}
  \item{text}{A short message for the active peer.}
  \item{notify_peer}{Whether stopping tries to notify an active peer directly.}
  \item{reason}{A local block or report note.}
  \item{include_recent}{Whether to note that messages are retained in the current R session.}
  \item{timeout_secs}{Manual callback-service time.}
}
\details{
The package uses a temporary local HTTP listener and explicit bounded discovery
of the configured private IPv4 subnet. It does not offer end-to-end encryption
in version 0.2.0 and is unsuitable for sensitive or confidential content.
}
\value{Functions return local state, status data, or invisibly indicate completion.}
\examples{
\dontrun{
library(rendezr)
rr_terms()
rr_accept_rules(accept = TRUE)
rr_lan_start()
rr_lan_find()
rr_send("Hello from R")
rr_leave()
rr_lan_stop()
}
}
\author{Quentin Lamboley}
\keyword{utilities}
