# Desktop bar

Adapted from Serpantinum's dock and modular workspace pill design.
Attribution and AGPL license are in [third-party](third-party/SERPANTINUM.md).

Six pinned apps appear on every monitor: VS Code, Firefox, Dolphin, Steam,
Fastfetch, and CurseForge. Click to launch or focus; multiple windows cycle on
repeated clicks. Fastfetch uses Kitty's hold option. Utilities are wallpaper,
notification history, settings, and reset. The notification button restores
Mako's most recent notification; hover a button for its name.

The wide-monitor System pill shows CPU utilization and memory usage, refreshed
every three seconds. Hover for used/total memory and uptime. Memory usage uses
Linux's available-memory estimate; CPU usage is measured between samples.
The media controls fit within their pill and show a play button when paused.
Tray icons accept Quickshell image-provider URLs as well as theme icon names.
CurseForge focus and workspace reset recognize both observed class spellings.

The volume pill tracks live PipeWire audio properties. Left-click to mute,
scroll to adjust volume, and click its down arrow or right-click to choose an
audio output. The picker highlights the active device and handles devices
appearing/disappearing. Choosing an output sets PipeWire's preferred default;
opening the picker does not change audio routing. Existing streams follow
the session manager's routing policy.

Drag a running app icon onto a workspace pill in the same bar to move that
window without switching workspaces. This is a taskbar drag handle, not an
application title bar. Workspace buttons switch to their current workspace
location. They do not migrate workspaces between monitors.

Settings edits are saved explicitly and update all bars. Enter an installed
icon name (e.g. firefox), an absolute image path, or a file URL. The file is
Quickshell's statePath("bar-settings.json"). Old app-icons.json files are left
untouched; the former glyph-only editor is superseded by this working editor.
Default opacity is 88%; Qt.rgba avoids confusion over QML's alpha-first hex.
The Customization Center is a HUD-style overview — bracketed translucent
modules (Colors, Icons, Descriptions, Desktop presets, Opacity) with a live
translucent desktop preview; its window translucency defaults to 55% via
Center window opacity. The window floats at a fixed 1000x850.

The reset button invokes resetDesktopLayout() in hypr/hyprland.lua, exactly
the same function as SUPER+SHIFT+R. It restores all nine workspace monitors
and each matching app window. Settings/other Quickshell windows are excluded
from wallpaper routing.

## Checks

Run from the repository root:

```sh
QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input quickshell/tests -o -,txt
lua quickshell/tests/test-reset.lua
luac -p hypr/hyprland.lua
```

`quickshell -p quickshell/test-system.qml` checks real system sampling, media
layout/paused state, and tray URL handling; successful output includes
`SYSTEM_METRICS_PASS` and `SERVICE_PILLS_PASS`. Use an offscreen Qt platform
and a private runtime directory for isolated checks.

`quickshell -p quickshell/test-audio.qml` uses simulated devices to verify
output filtering, selection/confirmation, disconnect handling, mute and
volume limits without changing the host's audio route. It prints
`AUDIO_CHECK_PASS` on success.

The settings runtime check uses the actual Quickshell plugins:

```sh
BAR_TEST_STATE=/tmp/bar-settings-check.json quickshell -p quickshell/test-settings.qml
```

The live check opens/focuses apps and resets their homes; run deliberately:

```sh
python quickshell/tests/verify-live.py
```

Start only one instance: `quickshell -n -d -p ~/.config/quickshell`.
Do not append `&` to the daemon launch. Use `quickshell list` to identify
duplicates and `quickshell kill -i ID` for only that instance.

On this desktop, Hyprland starts the managed `desktop-bar.service` at login.
Use `systemctl --user restart desktop-bar.service` to restart that instance.
See `docs/boot-recovery.md` for the service and graphics-driver recovery setup.

Development IPC: `quickshell ipc -p ~/.config/quickshell call desktop status`.
Utility/app actions use the same desktop activate ID handler internally.
Bar snapshots: call target bar-DP-3, method capture, with a local PNG path.

## Personalization

See [saved desktop and wallpaper presets](PRESETS.md) and [Expander/window controls](EXPANDER.md).
