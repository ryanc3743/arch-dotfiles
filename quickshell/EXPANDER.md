# Expander

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

## Window minimize

SUPER+X toggles the focused window into `special:expander-minimized` and back:
the first press minimizes it, the second restores it to its original workspace and
focuses it. Restore metadata lives per window under
`$XDG_RUNTIME_DIR/expander-windows/`; stale PID/address records fall back to
workspace 1. Minimized windows survive shell reloads and remain in Overview,
which restores them when clicked. This Hyprland version uses Lua dispatchers;
there is no native minimize action, so the toggle drives
`scripts/window-actions.py`.

No per-window overlay controls remain: close and fullscreen keep their existing
keybinds (SUPER+W, SUPER+B), and the Super key's tap/hold gestures still split
Launcher from Shortcuts & power.

## IPC

```sh
quickshell ipc -p ~/.config/quickshell call expander open
quickshell ipc -p ~/.config/quickshell call expander power
quickshell ipc -p ~/.config/quickshell call expander hide
quickshell ipc -p ~/.config/quickshell call expander status
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
- Disposable window: minimize/restore round-trip and restore-to-original-workspace
  for both addressed and focused windows, with per-window metadata cleanup.
- Keybind review: SUPER+X free of conflicts; close (SUPER+W) and fullscreen
  (SUPER+B) untouched; the removed per-window overlay no longer covers content.
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
