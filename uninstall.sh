#!/usr/bin/env bash
set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
data_dir="${XDG_DATA_HOME:-$HOME/.local/share}"

systemctl --user disable --now nameplate 2>/dev/null || true
rm -f "$config_dir/systemd/user/nameplate.service"
rm -f "$HOME/.local/bin/nameplate-bridge"
rm -f "$data_dir/applications/nameplate.desktop"
rm -rf "$config_dir/quickshell/nameplate"
rm -rf "$config_dir/omarchy/plugins/eagle.discord-voice-overlay"
systemctl --user daemon-reload

echo "Removed the overlay, bridge, service, and bar plugin."
echo "The OAuth token was preserved at $config_dir/nameplate/token."
echo "Remove eagle.discord-voice-overlay from $config_dir/omarchy/shell.json if it remains."
