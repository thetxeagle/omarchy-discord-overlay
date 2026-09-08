# Changelog

## Unreleased

### Added

- Marketplace-compatible self-contained plugin using the bundled Nameplate bridge.
- Omarchy bar plugin with hide/show controls and a 3×3 placement grid.
- Channel-name display in the click-through overlay.
- Installer, removal, manual diagnostics, token-handling, and Gamescope notes.

### Security

- Verify the local Discord RPC listener before sending the OAuth token.
- Bound RPC, token-exchange, channel, and roster data.
- Harden token storage against symlink and permission attacks.
- Remove remote avatar fetching and render plain text with bounded fields.
