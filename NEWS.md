# rendezr 0.2.0

- Replaces the central WebSocket-matchmaker design with local-only peer-to-peer LAN mode.
- Removes the public server, Docker deployment and domain requirements.
- Adds `rr_lan_start()`, `rr_lan_discover()`, `rr_lan_find()`, `rr_lan_peers()`, `rr_lan_set_available()` and `rr_lan_stop()`.
- Uses bounded private IPv4 `/24` discovery by default, direct local HTTP messages, local blocks and memory-only session history.
- Documents the lack of end-to-end encryption and the requirement to use only authorised local networks.

# rendezr 0.1.0

- Initial public-server prototype.
