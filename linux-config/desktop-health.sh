#!/usr/bin/env bash
set -u
health_dir="${XDG_CACHE_HOME:-$HOME/.cache}/linux-config"
mkdir -p "$health_dir"
check_service() {
    local label="$1" unit="$2" scope="$3" state previous
    if [ "$scope" = user ]; then
        state=$(systemctl --user is-active "$unit" 2>/dev/null) || true
    else
        state=$(systemctl is-active "$unit" 2>/dev/null) || true
    fi
    state="${state:-unknown}"
    previous=$(cat "$health_dir/$unit.status" 2>/dev/null) || previous=""
    if [ "$state" != "$previous" ]; then
        if [ "$state" != active ]; then
            notify-send -u critical "Remote access: $label is down" "Service state: $state. Check $unit before relying on remote access."
        elif [ -n "$previous" ] && [ "$previous" != active ]; then
            notify-send "Remote access: $label recovered" "The service is running again."
        fi
        printf '%s\n' "$state" > "$health_dir/$unit.status"
    fi
}
check_service OpenSSH sshd.service system
check_service Sunshine app-dev.lizardbyte.app.Sunshine.service user
