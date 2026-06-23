# Privacy statement — RendezR LAN v0.2.0

## No central collection

RendezR LAN does not provide or contact a central service. The package does not create an account, perform analytics, send telemetry, use cookies, or upload message histories.

## What necessarily travels on the local network

When a user explicitly starts LAN mode and another user explicitly runs discovery or matching, the local protocol can expose to the other participant:

- local IPv4 address and chosen TCP port;
- pseudonymous RendezR identifier, nickname, locale and room;
- availability state;
- message content and timing during an active conversation.

The network itself may expose packet metadata to network administrators. The v0.2.0 protocol uses HTTP on the LAN and is not end-to-end encrypted. It must never be treated as confidential communication.

## Local persistence

The package keeps local preferences, one pseudonymous identifier and local block identifiers under the operating-system user configuration directory for `rendezr`. Conversation messages remain only in the R session's memory unless a user intentionally copies, exports or records them elsewhere.

## User control

- Do not call `rr_lan_start()` to remain fully offline.
- Call `rr_lan_set_available(FALSE)` to remain listening but not eligible for matching.
- Call `rr_leave()` to end the current conversation.
- Call `rr_block()` to exclude a peer identifier locally.
- Call `rr_lan_stop()` to close the local listener.
- Call `rr_rotate_identity(confirm = TRUE)` to replace the local pseudonymous identifier and clear local blocks.
