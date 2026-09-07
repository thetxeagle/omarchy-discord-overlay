#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
data_dir="${XDG_DATA_HOME:-$HOME/.local/share}"
plugin_dir="$config_dir/omarchy/plugins/eagle.discord-voice-overlay"
nameplate_dir="$config_dir/quickshell/nameplate"
unit_dir="$config_dir/systemd/user"
bin_dir="$HOME/.local/bin"
apps_dir="$data_dir/applications"
shell_config="$config_dir/omarchy/shell.json"

command -v quickshell >/dev/null || { echo "quickshell is required" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq is required to update shell.json" >&2; exit 1; }

if ! python -c 'import websocket' >/dev/null 2>&1; then
  sudo pacman -S python-websocket-client
fi

mkdir -p "$plugin_dir" "$nameplate_dir" "$unit_dir" "$bin_dir" "$apps_dir"
install -Dm644 "$repo_dir/plugin/manifest.json" "$plugin_dir/manifest.json"
install -Dm644 "$repo_dir/plugin/BarWidget.qml" "$plugin_dir/BarWidget.qml"
install -Dm644 "$repo_dir/plugin/Service.qml" "$plugin_dir/Service.qml"
install -Dm644 "$repo_dir/nameplate/shell.qml" "$nameplate_dir/shell.qml"
install -Dm755 "$repo_dir/nameplate/nameplate-bridge" "$bin_dir/nameplate-bridge"
install -Dm644 "$repo_dir/nameplate/nameplate.service" "$unit_dir/nameplate.service"
install -Dm644 "$repo_dir/nameplate/nameplate.desktop" "$apps_dir/nameplate.desktop"

if [[ -f "$shell_config" ]]; then
  backup="$shell_config.bak.$(date +%Y%m%d%H%M%S)"
  cp -p "$shell_config" "$backup"
  tmp="$(mktemp)"
  jq '
    .bar.layout.right = (.bar.layout.right // [])
      | if any(.bar.layout.right[]?; .id == "eagle.discord-voice-overlay")
        then .
        else .bar.layout.right = ([{"id":"eagle.discord-voice-overlay"}] + .bar.layout.right)
        end
    | .plugins = (.plugins // [])
      | if any(.plugins[]?; .id == "eagle.discord-voice-overlay")
        then .
        else .plugins = ([{"id":"eagle.discord-voice-overlay"}] + .plugins)
        end
  ' "$shell_config" > "$tmp"
  mv "$tmp" "$shell_config"
  echo "Backed up shell config to $backup"
else
  echo "No Omarchy shell.json found; add eagle.discord-voice-overlay manually."
fi

systemctl --user daemon-reload
systemctl --user enable nameplate

echo
echo "Installed. Start Nameplate now with:"
echo "  systemctl --user start nameplate"
echo "Then join a Discord voice channel and approve authorization."
