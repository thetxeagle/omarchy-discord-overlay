#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
plugin_dir="$config_dir/omarchy/plugins/eagle.discord-voice-overlay"
shell_config="$config_dir/omarchy/shell.json"

command -v quickshell >/dev/null || { echo "quickshell is required" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq is required to update shell.json" >&2; exit 1; }

if ! python -c 'import websocket' >/dev/null 2>&1; then
  sudo pacman -S python-websocket-client
fi

mkdir -p "$plugin_dir"
install -Dm644 "$repo_dir/manifest.json" "$plugin_dir/manifest.json"
install -Dm644 "$repo_dir/BarWidget.qml" "$plugin_dir/BarWidget.qml"
install -Dm644 "$repo_dir/Service.qml" "$plugin_dir/Service.qml"
install -Dm755 "$repo_dir/nameplate-bridge" "$plugin_dir/nameplate-bridge"

# Migrate away from the earlier standalone Nameplate service if it exists.
systemctl --user disable --now nameplate 2>/dev/null || true

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

echo
echo "Installed. Restart the Omarchy shell, then join a Discord voice channel."
echo "The plugin starts the bundled Nameplate bridge inside omarchy-shell."
