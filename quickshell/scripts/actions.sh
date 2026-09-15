#!/usr/bin/env bash
set -euo pipefail
fail() { notify-send 'Expander' "$*"; exit 1; }
need() { command -v "$1" >/dev/null || fail "Missing command: $1"; }
case "${1:-}" in
  calc) exec python3 "$(dirname "$0")/calculator.py" "${2:-}" ;;
  copy) need wl-copy; printf '%s' "${2:-}" | wl-copy ;;
  ss|ssf)
    need grim
    mkdir -p "$HOME/Pictures/Screenshots"
    target="$HOME/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S-%N).png"
    if [[ $1 == ss ]]; then
      need slurp
      region=$(slurp) || exit 0
      [[ -n $region ]] || exit 0
      grim -g "$region" "$target"
    else grim "$target"; fi
    notify-send 'Screenshot saved' "$target"
    ;;
  cl)
    need cliphist; need wofi; need wl-copy
    selection=$(cliphist list | wofi --dmenu --prompt Clipboard) || exit 0
    [[ -n $selection ]] || exit 0
    printf '%s\n' "$selection" | cliphist decode | wl-copy
    ;;
  ssh)
    need wofi; need kitty
    hosts=$(python3 "$(dirname "$0")/ssh-hosts.py")
    [[ -n $hosts ]] || fail 'No concrete Host aliases found in ~/.ssh/config.'
    host=$(printf '%s\n' "$hosts" | wofi --dmenu --prompt SSH) || exit 0
    [[ -n $host ]] || exit 0
    # Only permit a host from the picker, never shell text or SSH options.
    printf '%s\n' "$hosts" | grep -Fxq -- "$host" || fail 'Select a configured host.'
    exec kitty -- ssh -- "$host"
    ;;
  emoji)
    need wofi; need wl-copy
    choice=$(printf '%s\n' '😀 smile' '😂 laugh' '❤️ heart' '👍 thumbs up' '🎉 celebrate' '🔥 fire' '✅ done' '👀 eyes' '🤔 thinking' '🚀 rocket' '🙏 thanks' '💻 computer' | wofi --dmenu --prompt Emoji) || exit 0
    [[ -n $choice ]] && printf '%s' "${choice%% *}" | wl-copy
    ;;
  lock) need swaylock; exec swaylock -c 1e1e2e ;;
  sleep) systemctl suspend ;;
  logout) exec hyprctl dispatch 'hl.dsp.exit()' ;;
  reboot) systemctl reboot ;;
  *) fail 'Unknown action' ;;
esac
