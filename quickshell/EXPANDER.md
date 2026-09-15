# Expander and window controls

Implemented from Ryan's `/home/ry/projects/handoff-plan.md`, 2026-09-15.
Live config: `~/.config/quickshell/`; tracked mirror: `~/dotfiles/quickshell/`.

## Use

Tap Super for **Launcher**; tap again to switch to **Overview**. Hold Super for
400 ms and release for **Shortcuts & power**. Escape closes the panel. The existing
Super+Shift+D launcher binding and bar launcher button also open Expander.
The footer hint disappears after three seconds; `?` shows it again.

Launcher search accepts:

| Input | Action |
|---|---|
| `calc (2+3)*4` | Inline arithmetic result; Enter copies it |
| `ss` | Select a screenshot region |
| `ssf` | Capture all monitors |
| `cl` | Clipboard history picker |
| `ssh` | Pick a concrete Host alias from `~/.ssh/config` and Include files |
| `emoji` | Small searchable emoji picker; copies selection |
| `pm` | Power menu |
| Other text | Search desktop applications |

Screenshot files are saved under `~/Pictures/Screenshots/`. Clipboard, SSH and
emoji pickers retain wofi. Arguments are passed as arguments, not evaluated as
shell commands. Calculator accepts bounded arithmetic only, with no Python eval.
SSH aliases are read without executing SSH Match/Proxy commands during discovery.
Selecting an alias launches the user's configured SSH connection in Kitty.

Overview reuses the workspace strip and displays live window previews. A fallback
class label appears when the compositor cannot supply a capture. Previews stop
when Overview closes. Click a card to focus or restore its window.

Power has Lock, Sleep, Log out and Reboot. Sleep/logout/reboot require selecting
the action a second time. **Lock uses swaylock** because this desktop had no locker
or loginctl lock-signal listener. Tests do not lock, suspend, log out or reboot.

## Window controls

Each visible window has its own control strip centered along its top edge, including on the
rotated display and monitors at negative coordinates. Controls operate on their
own window without requiring it to be focused. Inactive workspaces, minimized
windows, and windows covered by a fullscreen window do not leave stray controls.
The order is **minimize · maximize · close**. Controls sit above their window only
when the entire strip clears other windows and the taskbar; otherwise they sit
inside their own top edge, centered. Very small/off-screen windows hide controls
when there is no room. One shared timer refreshes geometry.
The overlay never requests keyboard focus and reserves no workspace area.

**Super+B fullscreen only:** the controls sit inside the top-center screen edge; all button and strip
backgrounds are transparent, including on hover. Symbols follow **Text**, and each button has a separate **Subtitle**-colored outline.
Hover strengthens the outline and adds an action-color tint: red for close and
theme accent colors for minimize/maximize. Normal mode also tints the button
background; fullscreen keeps the background transparent even on hover. Leaving fullscreen restores the
desktop colorway. Maximize mode (the square button) retains desktop colors.

This Hyprland version uses Lua dispatchers; there is no native minimize action.
Minimize moves the addressed window to `special:expander-minimized`. Overview
restores its original workspace and focuses it. Per-window restore metadata lives
under `$XDG_RUNTIME_DIR/expander-windows/`; stale PID/address records fall back to
workspace 1. Minimized windows survive shell reloads and remain in Overview.

Geometry is refreshed every 100 ms by one shared timer to track moves and
resizes across all windows. Controls use monitor-relative logical coordinates. Super+B still uses the
original fullscreen binding, and Super+W retains its original close binding.

## IPC

```sh
quickshell ipc -p ~/.config/quickshell call expander open
quickshell ipc -p ~/.config/quickshell call expander power
quickshell ipc -p ~/.config/quickshell call expander hide
quickshell ipc -p ~/.config/quickshell call expander status
quickshell ipc -p ~/.config/quickshell call windowActions status
quickshell ipc -p ~/.config/quickshell call shell reload
```

`expander open` toggles tabs if already open. The compatibility `launcher open`
handler always prepares the Launcher tab. `shell reload` restarts the supervised
`desktop-bar.service`; no logout is needed. Its existing `KillMode=process`
preserves applications launched from the shell when the bar restarts.

## Verified

- QML loads and both tabs render, including live window captures.
- End-to-end virtual keyboard: keyd → XKB → Hyprland → IPC for tap/re-tap/hold.
- Keyd 2.6.0 event fixtures: tap, hold, delayed Super+B/W/Q/E/workspace combos,
  mouse buttons and scroll. See `../keyd/README.md`.
- Calculator arithmetic, injection rejection, divide-by-zero and expression bounds.
- SSH Include/alias handling and argument safety; clipboard selection/cancel,
  using isolated test fixtures (no remote SSH connection was initiated).
- Actual grim full-screen and region captures to temporary files, with a fixed
  test selection standing in for interactive slurp selection.
- Disposable window: maximize/unmaximize, minimize/restore, addressed close,
  monitor tracking on DP-3, DP-2 and HDMI-A-1, fullscreen overlay placement.
- Per-window revision: controls on focused and unfocused windows, addressed close,
  centered transparent fullscreen, opaque normal/maximized modes, taskbar
  clearance, and safe above/inside placement.
- Lua syntax, Hyprland config errors, shell syntax and dotfiles whitespace checks.

Pre-existing icon lookup and PipeWire channel-map warnings remain unrelated to
these features. Systemd reports preserved application processes on bar restart
because the existing service intentionally uses `KillMode=process`.

## Restore the previous UI

The pre-change backup is `/home/ry/projects/expander-backup/`.
To restore the original behavior without deleting new files:

```sh
cp /home/ry/projects/expander-backup/quickshell/shell.qml ~/.config/quickshell/shell.qml
cp /home/ry/projects/expander-backup/hyprland.lua ~/.config/hypr/hyprland.lua
hyprctl reload
systemctl --user restart desktop-bar.service
sudo systemctl disable --now keyd
```

The added components remain unused after restoring the old shell. To keep the
tracked mirror aligned, copy those restored shell and Hyprland files to dotfiles.

References: [keyd](https://github.com/rvaiya/keyd/blob/v2.6.0/docs/keyd.scdoc),
[Hyprland Lua dispatchers](https://wiki.hypr.land/configuring/core/dispatchers/).
Local installed Quickshell `.qmltypes` and existing `DesktopActions.qml` were
used to verify `activated`, `lastIpcObject`, monitor geometry and screencopy APIs.
