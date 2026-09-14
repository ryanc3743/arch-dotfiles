#!/usr/bin/env bash
set -eu
systemctl --user import-environment WAYLAND_DISPLAY DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP
systemctl --user start desktop-wallpaper.service desktop-bar.service app-dev.lizardbyte.app.Sunshine.service cliphist-text.service cliphist-image.service desktop-health.timer
