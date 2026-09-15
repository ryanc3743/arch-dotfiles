# Super gestures for Expander

Installed on 2026-09-15. This host runs **Arch Linux**, Hyprland 0.56.2 and keyd 2.6.0.

- Tap Super: Launcher. Tap again while open: switch Launcher/Overview.
- Hold Super for at least **400 ms**, then release: shortcuts and power menu.
- Any intervening keyboard or configured mouse button cancels the standalone action.
- Existing Super+B/W and other Hyprland bindings remain unchanged.

Ryan selected hold recognition **on release** to preserve slow Super shortcuts.
A menu that opens while the key remains down cannot distinguish a long standalone
hold from a slow upcoming Super shortcut.

## Mapping and XKB

`default.conf` uses `timeout(overload(meta, f13), 400, overload(meta, f14))`.
The brief's `overload(F13, F14)` used a key as a layer and could not preserve Super.
The corrected mapping passes Gate 0; no kanata fallback was needed.

On this host, `xkbcli compile-keymap --layout us` maps Linux F13/F14 to
**XF86Tools/XF86Launch5**. Hyprland binds those keysyms. Its Lua `code:191` and
`code:192` bindings were observed to register as keycode 0 on 0.56.2, so they are
not used. Do not replace the verified keysyms with literal `F13`/`F14`.

Mouse IDs in the config let mouse clicks and scroll resolve/cancel the gesture,
including quick Super+drag. A newly attached mouse needs its ID added to the same
config. The first click causes pending Super to resolve before the click is sent.

## Install / recovery

Run `./install.sh` from a desktop terminal. It installs keyd, grim, slurp and
swaylock; validates and backs up any existing `/etc/keyd/default.conf`; then enables
keyd. Authenticate through sudo in your terminal.

To immediately restore ordinary Super behavior:

```sh
sudo systemctl disable --now keyd
```

keyd's emergency chord is **Backspace + Escape + Enter**.

## Validation

`tests/*.t` contains tap, hold, keyboard combinations with 50–1500 ms delays,
mouse buttons and scroll. All 34 fixtures pass using the upstream **v2.6.0**
`test-io` harness (commit `7c0aecb`), matching the installed version. The upstream
suite also passed. Reproduce with an existing keyd v2.6.0 checkout:

```sh
make -C /path/to/keyd test-io
/path/to/keyd/bin/test-io default.conf tests/*.t
keyd check default.conf
```

`python3 test-live-gestures.py` creates a temporary uinput keyboard, emits only
Super, and verifies tap, re-tap and hold through the **running keyd → XKB →
Hyprland → Quickshell** path. It briefly opens the panels and closes them afterward.
It requires permission to write `/dev/uinput`. This test passed after correcting
the XKB bindings.

References: [keyd manual](https://github.com/rvaiya/keyd/blob/v2.6.0/docs/keyd.scdoc),
[Hyprland binds](https://wiki.hypr.land/configuring/core/binds/).
