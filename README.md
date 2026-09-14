# Arch Linux Desktop Configuration

My personal Arch Linux desktop configuration, built from scratch while learning
how Linux, Hyprland, Wayland, Quickshell, QML, and Git work together.

This repository mirrors my live configuration in `~/.config` and is my working,
real-world setup.

## Current Stack

- Arch Linux
- Hyprland (with hyprland-lua)
- Wayland
- Quickshell
- QML
- systemd user services
- Git

## Layout

The repo mirrors the config directory structure:

```
hypr/              # Hyprland compositor config (hyprland.lua)
quickshell/        # Desktop shell UI (shell.qml, components/, assets/, scripts/)
linux-config/      # Startup + health scripts
docs/              # Notes and recovery guides
```

## Monitor Layout

### DP-3 — Left / Vertical (rotated)

- Workspace 1 — Development
- Workspace 2 — Web
- Workspace 3 — Files
- 1920x1080 @ 200Hz

### DP-2 — Center / Main

- Workspace 4 — Game
- Workspace 5 — Steam
- Workspace 6 — Wallpaper Picker
- 2560x1440 @ 240Hz

### HDMI-A-1 — Right

- Workspace 7 — Media
- Workspace 8 — Misc
- Workspace 9 — Overflow
- 1920x1080 @ 60Hz

Application homes route specific apps to those workspaces (VS Code → 1,
Firefox → 2, Dolphin → 3, Steam → 5, Steam games → 4, CurseForge → 7).
`SUPER+SHIFT+R` (or the Quickshell reset button) restores the fixed monitor,
workspace, and application-homes arrangement without closing windows.

## Startup

`linux-config/start-desktop.sh` runs on `hyprland.start` and starts the
supervised desktop services:

- `desktop-bar.service` — Quickshell bar
- `desktop-wallpaper.service` — wallpaper
- `app-dev.lizardbyte.app.Sunshine.service` — remote access
- `cliphist-text.service` / `cliphist-image.service` — clipboard watchers
- `desktop-health.timer` — service state notifications

`desktop-health.sh` (run by the timer) watches OpenSSH and Sunshine and
shows a notification when either drops or recovers.

## Quickshell

A custom desktop shell running as a `desktop-bar.service`. See
[`quickshell/README.md`](quickshell/README.md) for the bar features
(launcher, workspaces, system/media/audio/tray pills, taskbar drag-to-move,
settings editor, wallpaper picker) and the app homes it shares with Hyprland.

## Keybinds (SUPER = Main Mod)

- `SUPER+Q` — terminal
- `SUPER+E` — file manager
- `SUPER+D` — native launcher (Wofi fallback on `SUPER+SPACE`)
- `SUPER+K` — network/Bluetooth panel
- `SUPER+N` — restore last notification
- `SUPER+SHIFT+W` variants — close, `SUPER+SHIFT+D` launcher, `SUPER+SHIFT+S` full screenshot, `SUPER+SHIFT+A` region screenshot, `SUPER+SHIFT+V` clipboard, `SUPER+SHIFT+R` reset layout
- `SUPER+[0-9]` — switch workspace, `SUPER+SHIFT+[0-9]` — move window
- `SUPER+S` — scratchpad toggle
- `SUPER+B` — fullscreen, `SUPER+V` — float, `SUPER+P` — pseudo, `SUPER+J` — toggle split
- Multimedia keys — volume, brightness, play/pause
- `SUPER+mouse_down/up` — cycle workspaces

## Hardware Notes

- Input: US layout, natural-scroll touchpad, 3-finger horizontal gesture for workspace switching
- A per-device mouse sensitivity override is configured for the Epic mouse