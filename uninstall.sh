#!/usr/bin/env bash
set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"

systemctl --user disable --now nameplate 2>/dev/null || true
rm -rf "$config_dir/omarchy/plugins/eagle.discord-voice-overlay"

echo "Removed the overlay, bridge, service, and bar plugin."
echo "The OAuth token was preserved at $config_dir/nameplate/token."
echo "Remove eagle.discord-voice-overlay from $config_dir/omarchy/shell.json if it remains."
