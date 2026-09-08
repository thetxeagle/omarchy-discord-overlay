# Omarchy Discord Voice Overlay

A click-through Discord voice overlay for Omarchy, Hyprland, and Quickshell.

It uses the [Nameplate](https://github.com/rollecode/nameplate) Discord bridge
inside an Omarchy plugin. The bar plugin adds a hide/show control and a 3×3
placement grid. The channel name appears in the same transparent,
click-through overlay.

The bundled Nameplate bridge is pinned to commit
`b49464b652fccfb1ca7cf43d25dacdbe1e19db38`.

## What gets installed

- A self-contained Omarchy plugin and bundled Nameplate bridge.
- The `python-websocket-client` dependency through Arch packages.
- The `eagle.discord-voice-overlay` Omarchy plugin at the required repository root.
- A backup of `~/.config/omarchy/shell.json` before the bar entry is added.

The Discord OAuth token remains in `~/.config/nameplate/token`. It is never
copied into this repository or included in configuration backups.

## Install

Install the bridge dependency first on Arch:

```bash
sudo pacman -S python-websocket-client
```

Then install and enable the plugin:

```bash
omarchy plugin add https://github.com/thetxeagle/omarchy-discord-overlay.git --enable
```

For a local checkout, use `./install.sh`. It does not need root except when it
calls `sudo pacman` to install the packaged Python WebSocket dependency.
Restart Discord, join a voice channel, and approve the Discord authorization
dialog once.

After installation, restart the Omarchy shell if the bar button does not
appear:

```bash
omarchy restart shell
```

Open the Discord icon in the bar to hide/show the overlay or choose one of the
nine grid positions. The overlay itself has an empty Wayland input region, so
mouse and keyboard input continue to reach the game underneath.

## Manual test and diagnostics

Restart the Omarchy shell after installation:

```bash
omarchy restart shell
```

Test the bridge separately:

```bash
~/.config/omarchy/plugins/eagle.discord-voice-overlay/nameplate-bridge
```

The bridge is launched by the Omarchy service plugin, so no separate
Nameplate systemd unit is required. If the plugin does not appear, inspect
the Omarchy shell logs and verify that the bridge dependency is installed.

The overlay is expected to be invisible when not connected to a voice
channel. Games running inside a nested Gamescope compositor may not display
Wayland layer-shell overlays.

## Uninstall

```bash
./uninstall.sh
```

The uninstall script removes only the plugin files installed by this project.
It does not delete the Discord OAuth token.

## Security notes

This project runs as the current user and does not inject into games or
capture input. The bridge verifies the local RPC listener belongs to the
current user's Discord/Vesktop executable before sending a token, bounds RPC
and user data, and stores the scoped OAuth token through no-follow file
descriptors. Treat `~/.config/nameplate/token` like a password and revoke the
app from Discord's Authorized Apps page if you stop using the overlay. User
avatars are intentionally rendered as bounded initials instead of downloaded
remote images.
