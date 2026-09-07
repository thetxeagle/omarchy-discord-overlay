# Omarchy Discord Voice Overlay

A click-through Discord voice overlay for Omarchy, Hyprland, and Quickshell.

It uses [Nameplate](https://github.com/rollecode/nameplate) for the Discord
bridge and roster rendering. The Omarchy bar plugin adds a hide/show control
and a 3×3 placement grid. The channel name appears in the same transparent,
click-through overlay.

The bundled Nameplate bridge is pinned to commit
`b49464b652fccfb1ca7cf43d25dacdbe1e19db38`.

## What gets installed

- A user-level Nameplate Quickshell overlay.
- The `python-websocket-client` dependency through Arch packages.
- The `eagle.discord-voice-overlay` Omarchy plugin.
- A user systemd unit for Nameplate, enabled only when requested by the installer.
- A backup of `~/.config/omarchy/shell.json` before the bar entry is added.

The Discord OAuth token remains in `~/.config/nameplate/token`. It is never
copied into this repository or included in configuration backups.

## Install

```bash
git clone https://github.com/thetxeagle/omarchy-discord-overlay
cd omarchy-discord-overlay
./install.sh
```

The installer does not need root. It may call `sudo pacman` only to install
the packaged Python WebSocket dependency. Start or restart Discord, join a
voice channel, and approve the Discord authorization dialog once.

After installation, restart the Omarchy shell if the bar button does not
appear:

```bash
omarchy restart shell
```

Open the Discord icon in the bar to hide/show the overlay or choose one of the
nine grid positions. The overlay itself has an empty Wayland input region, so
mouse and keyboard input continue to reach the game underneath.

## Manual test and diagnostics

Run the overlay in the foreground:

```bash
quickshell -c nameplate
```

Test the bridge separately:

```bash
nameplate-bridge
```

Check the permanent user service:

```bash
systemctl --user status nameplate
```

The overlay is expected to be invisible when not connected to a voice
channel. Games running inside a nested Gamescope compositor may not display
Wayland layer-shell overlays.

## Uninstall

```bash
./uninstall.sh
```

The uninstall script disables the Nameplate user service and removes only the
files installed by this project. It does not delete the Discord OAuth token.

## Security notes

This project runs as the current user and does not inject into games or
capture input. Nameplate connects to Discord locally and caches a scoped OAuth
token. Treat `~/.config/nameplate/token` like a password and revoke the app
from Discord's Authorized Apps page if you stop using the overlay.
