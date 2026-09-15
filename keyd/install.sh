#!/usr/bin/env bash
# Run as your desktop user. sudo prompts in your terminal, never in chat.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
printf '%s\n' 'Install Expander dependencies and enable the tested Super mapping.'
printf '%s\n' 'Tap: F13; hold for 400 ms then release: F14; keyboard/mouse combos retain Super.'
sudo pacman -S --needed keyd grim slurp swaylock
keyd check "$PWD/default.conf"
sudo install -d -m 755 /etc/keyd
if sudo test -e /etc/keyd/default.conf; then
  sudo cp -a /etc/keyd/default.conf "/etc/keyd/default.conf.before-expander-$(date +%Y%m%d-%H%M%S)"
fi
sudo install -m 644 "$PWD/default.conf" /etc/keyd/default.conf
sudo systemctl enable --now keyd
sudo keyd reload
systemctl is-active keyd
printf '%s\n' 'Installed. Test tap Super, hold/release Super, Super+B/W, and Super+mouse drag.'
printf '%s\n' 'Recovery: sudo systemctl disable --now keyd (or keyd emergency chord: Backspace+Escape+Enter).'
read -r -p 'Press Enter to close this installer. ' _
