# RendezR LAN

> **Consent-first random conversations in the R console, directly between opted-in peers on the same private local network.**

RendezR LAN is a peer-to-peer R/RStudio package for a deliberately narrow idea: people who have **explicitly started RendezR LAN on the same local IPv4 network** can be matched at random and exchange short console messages.

There is **no central server, no public domain, no cloud relay, no account, no telemetry, and no network activity when `library(rendezr)` runs**. Each active participant temporarily hosts a very small local HTTP endpoint on their own computer. Discovery is initiated only by an explicit command and is constrained to one private IPv4 `/24` subnet by default.

> **Important:** “serverless” here means *no central or public server*. Each participant still runs a temporary local listener so that a peer can deliver a message directly. Version 0.2.0 uses local HTTP rather than end-to-end encryption; it is unsuitable for sensitive information.

## What it does

| Need | RendezR LAN response |
|---|---|
| No domain or hosted service | Each RStudio session creates its own short-lived local listener. |
| Find a random nearby peer | An explicit discovery probes only the fixed RendezR port on the selected private local subnet. |
| Keep it opt-in | `library(rendezr)` is inert; `rr_lan_start()` is required and the participant can be hidden at any time. |
| Keep control | Leave, block locally, disable availability, clear session messages and stop the listener. |
| Keep content modest | 600-character messages; links, e-mails and phone-like strings are rejected by default. |
| Avoid accidental Internet scanning | Only private IPv4 CIDRs are accepted and automatic discovery is capped at 254 candidate hosts. |

## Five-minute start

Everyone who wants to participate must be on the **same local private IPv4 subnet**, install the package, accept the rules, and start LAN mode.

```r
install.packages(c("cli", "curl", "digest", "fs", "httpuv", "jsonlite", "later", "rappdirs", "uuid"))
install.packages("remotes")
remotes::install_github("QuentinLamboley/rendezr")

library(rendezr)

rr_terms()
rr_accept_rules(accept = TRUE)

# Opens a temporary listener on the current computer.
# Default: port 47831, room "general", inferred private /24 subnet.
rr_lan_start()

# Explicitly discover opted-in peers, choose one available person at random,
# then establish a direct local conversation.
rr_lan_find()

rr_send("Bonjour ! Sur quoi travailles-tu aujourd’hui ?")
rr_inbox()
rr_leave()
rr_lan_stop()
```

Two users may also make a themed local room:

```r
rr_lan_start(room = "bayesian-methods")
rr_lan_find(room = "bayesian-methods")
```

## Design and safety boundaries

- **Nothing happens at package load.** `library(rendezr)` does not open a port, inspect the network, or communicate.
- **Participation is explicit.** `rr_terms()` and `rr_accept_rules(accept = TRUE)` are required before `rr_lan_start()`.
- **No central matchmaker exists.** The initiating peer discovers willing peers, chooses one randomly, then sends direct HTTP messages locally.
- **Only a private IPv4 LAN scope is allowed.** The default is `x.y.z.0/24`, capped at 254 potential addresses. Public addresses and broad private ranges are rejected.
- **No confidentiality guarantee.** v0.2.0 uses local HTTP. Do not transmit any sensitive data, credentials, health data, research data, personal identifiers, or confidential workplace information.
- **Short-lived memory.** Messages live only in the current R session unless a participant deliberately copies them elsewhere.
- **Network controls can prevent it.** Guest Wi-Fi, VLAN separation, client isolation, campus firewalls and Windows/macOS firewall rules can block peer discovery or inbound connections.

## Core commands

```r
rr_lan_start()                     # begin local participation
rr_lan_discover()                  # list opted-in peers on the bounded local subnet
rr_lan_peers()                     # inspect most recent discovery result
rr_lan_find()                      # random compatible local peer
rr_send("Hello")                  # direct local message
rr_inbox()                         # session-local message history
rr_leave()                         # end chat, become available again
rr_lan_set_available(FALSE)        # hide from random matching without stopping listener
rr_block("unwanted conduct")      # local block and end chat
rr_lan_stop()                      # close listener completely
rr_status()                        # inspect current state
```

`rr_connect()`, `rr_disconnect()` and `rr_find()` remain short compatibility aliases for `rr_lan_start()`, `rr_lan_stop()` and `rr_lan_find()`.

## Shared-network setup notes

1. Everyone must use the same port (default `47831`) and room.
2. When Windows/macOS asks, allow R/RStudio through the firewall on **private networks only**. Do not create an Internet-facing port-forwarding rule.
3. If the automatic address choice is wrong because of a VPN or several network interfaces, provide it explicitly:

```r
rr_lan_start(address = "192.168.1.42", subnet = "192.168.1.0/24")
```

4. If your LAN uses a larger range, intentionally choose the `/24` segment containing your peers. The package refuses broad scans to minimise impact.

## Privacy

See [PRIVACY.md](PRIVACY.md). There is no hosted service and no analytics. Network traffic necessarily includes local IP addresses and metadata visible to the other peer and to any administrator of the local network. The protocol is intentionally unsuitable for private or regulated communications.

## Development

```r
# In the repository root
R CMD check .
```

The GitHub workflow tests package structure on Linux, macOS and Windows. See [CONTRIBUTING.md](CONTRIBUTING.md) and [SECURITY.md](SECURITY.md).

## License

MIT © 2026 Quentin Lamboley.
