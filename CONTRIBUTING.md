# Contributing to RendezR LAN

Thank you for improving RendezR LAN.

## Principles

1. Preserve explicit consent: package loading must remain network-inert.
2. Preserve local-only design: do not add central analytics, remote presence services, public Internet discovery or silent external requests.
3. Keep safety defaults: private CIDRs only, bounded discovery, no automatic port forwarding, no code execution, no files, no links/contact details by default.
4. Document protocol changes, privacy implications and tests.

## Development

```r
pak::pak(".")
testthat::test_local()
devtools::check()
```

Add tests for validation, CIDR boundaries, discovery filtering, session authorization and any protocol message added. Avoid tests that scan a real local network.
