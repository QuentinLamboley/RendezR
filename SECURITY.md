# Security policy — RendezR LAN

## Scope and threat model

RendezR LAN is an experimental peer-to-peer local-network chat tool. It is not designed for confidential, regulated, clinical, legal, financial, or emergency communication.

It limits discovery to a configured private IPv4 CIDR, caps automatic discovery at 254 candidate hosts, allows only a fixed small HTTP protocol, and checks that inbound requests originate from the selected subnet. These measures reduce accidental exposure; they do not provide cryptographic confidentiality, strong authentication or protection against a malicious local-network participant.

## Safe deployment rules

- Use only on networks you own or are authorised to administer.
- Do not enable port-forwarding, public DNS, reverse proxies or Internet exposure.
- Allow R/RStudio through a firewall only for private networks.
- Do not transmit credentials, sensitive research data, personal data or confidential material.
- Keep `httpuv`, `curl`, `jsonlite` and R updated.

## Reporting a vulnerability

Please open a private GitHub security advisory in `QuentinLamboley/rendezr` with a minimal reproduction and impact description. Do not post sensitive exploit details in a public issue before a maintainer has had time to assess them.
