# Arch Linux Desktop Configuration

My personal Arch Linux desktop configuration, built from scratch while learning
how Linux, Hyprland, Wayland, Quickshell, QML, and Git work together.

This repository contains my actual working configuration and documentation
about how I built it.

## Current Stack

- Arch Linux
- Hyprland
- Wayland
- Quickshell
- QML
- Git

## Architecture

Hyprland is responsible for the compositor and desktop behavior:

- Monitors
- Workspaces
- Keybinds
- Window rules
- Layout
- Gaps
- Decorations

Quickshell is responsible for the desktop UI:

- Top bar
- Clock/date
- Workspace indicator
- Future widgets and controls

The goal is to keep the configuration modular so individual components can
be changed without replacing the entire desktop environment.

## Monitor Layout

### DP-3 — Left / Vertical

- Workspace 4
- Workspace 5
- Workspace 6
- 1920x1080 @ 200Hz
- Rotated vertically

### DP-2 — Center / Main

- Workspace 1
- Workspace 2
- Workspace 3
- 2560x1440 @ 240Hz

### HDMI-A-1 — Right

- Workspace 7
- Workspace 8
- Workspace 9
- 1920x1080 @ 60Hz

## Quickshell

The Quickshell configuration is being built incrementally rather than
installing an entire pre-made shell.

### `quickshell/shell.qml`

Creates a `PanelWindow` for every detected monitor using:

```qml
Variants {
    model: Quickshell.screens
}
