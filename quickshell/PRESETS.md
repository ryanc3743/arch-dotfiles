# Saved desktop and wallpaper presets

## Wallpaper presets

Open **Wallpaper Picker → Presets**. The draft starts with your current monitor
wallpapers and slideshow settings. Choose a saved name and **Edit preset**, or
start with **Use current setup**.

- Assign a separate image to each monitor with **Browse**, or choose **Span one image**.
- Edit slideshow timing, order, target and image paths; **Use gallery images** copies
  the currently filtered gallery into the slideshow draft.
- Enter a name and **Save preset**. Reusing a name updates it; a new name saves a copy.
- **Rename** and **Delete** manage the selected preset. Delete asks for a second click.
- **Apply draft** applies the images and slideshow. Editing/saving alone does not.
- Empty monitor assignments leave that monitor unchanged. Disconnected monitor
  assignments stay saved for later. Missing image files produce an error before
  the helper changes any wallpaper.

## Desktop presets

Open **Customization Center → Desktop presets**. The center opens on an Overview
of HUD modules — live preview, Colors, Icons, Descriptions, Desktop presets,
Opacity — each opening its own section (back to return). Use the existing desktop
color editor, color picker, live preview, border controls, icons, descriptions and
opacity; pending edits accumulate across sections until an explicit Save.

The window and preview respect **Opacity & Layers**: Bar panels stays at its existing
default; **Center window** (default 55%) makes the Customization Center translucent
over your desktop, matching the bar's color preview.
**Subtitle** is an independently editable color for secondary labels and help text;
it is preserved by Save and included in both colorways and desktop presets.

Desktop presets include desktop styling **and wallpaper by default**. Pick a saved
wallpaper preset or use the current wallpaper snapshot. Uncheck **Include wallpaper
setup** for an appearance-only preset.

**Save preset** stores your draft without applying it. **Edit preset** restores its
values into the editor; the main **Save** applies the desktop draft. A desktop
preset embeds its wallpaper snapshot, so later edits to a standalone wallpaper
preset do not unexpectedly change an existing desktop preset.

## Escape

**Esc closes the active desktop GUI**, including Wallpaper Picker and its preset
editor, Customization Center and its color picker, Audio outputs, Network & Bluetooth,
Launcher/Overview, and Power. It does not save unfinished drafts. Native file
selection dialogs retain their normal Escape-to-cancel behavior.

## Storage and validation

Named desktop and wallpaper presets persist in Quickshell's
`desktop-presets.json`, alongside the existing `bar-settings.json`,
`wallpaper-settings.json` and `slideshow-settings.json` state files. On this host,
that directory is:

`~/.local/state/quickshell/by-shell/838f3e4f7284be9504f1042d710aec99/`

The files survive shell reloads. Existing bar colorways remain in their original
file. Runtime tests cover create/update/rename/delete, duplicate-name rejection,
reload, separate drafts, combined desktop+wallpaper apply, and Subtitle persistence.
Wallpaper helper checks cover per-monitor/span assignments and validation before
changes. Escape was exercised on all eight desktop GUI/editor routes through a
real temporary keyboard.

Test QML files are in `tests/`; provide `PRESET_TEST_STATE` pointing to a disposable
path and run with `QT_QPA_PLATFORM=offscreen`. The desktop draft test uses a fake
wallpaper controller so it does not alter real wallpapers.

Pre-change component backups are in `/home/ry/projects/presets-backup/`.
