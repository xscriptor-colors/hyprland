#!/usr/bin/env bash
# Idle / auto-lock control.
#
#   idle-mode.sh awake   -> nothing auto-dims, locks or suspends; manual only
#                            (SUPER+L lock, SUPER+CTRL+L suspend)
#   idle-mode.sh normal  -> hypridle timers back on (dim/lock/display/suspend)
#   idle-mode.sh boot    -> called from autostart.lua: honors the saved mode
#   idle-mode.sh status  -> prints awake|normal
#
# "Keep awake" simply stops the hypridle daemon, which is the only source of
# auto-dimming/locking/suspending here, so the machine never locks by itself.
# The choice is stored in ~/.config/hypr/idle-settings.json and restored on
# every login (idle-mode.sh boot replaces the plain `hypridle` autostart).

STATE="$HOME/.config/hypr/idle-settings.json"

ensure_state() {
    mkdir -p "$HOME/.config/hypr"
    [ -f "$STATE" ] || printf '{"idleMode":"normal"}' > "$STATE"
}

current() {
    ensure_state
    python3 -c "import json; print(json.load(open('$STATE')).get('idleMode','normal'))" 2>/dev/null || echo "normal"
}

start_idle() {
    pgrep -x hypridle >/dev/null 2>&1 && return 0
    setsid nohup hypridle >/dev/null 2>&1 </dev/null &
}

stop_idle() {
    pkill -x hypridle 2>/dev/null || true
}

notify() {
    command -v notify-send >/dev/null 2>&1 && notify-send -t 3500 "Idle & sleep" "$1"
}

case "$1" in
    awake)
        ensure_state
        printf '{"idleMode":"awake"}' > "$STATE"
        stop_idle
        notify "Keep awake: no auto lock/suspend. Manual: SUPER+L lock, SUPER+CTRL+L suspend"
        ;;
    normal)
        ensure_state
        printf '{"idleMode":"normal"}' > "$STATE"
        start_idle
        notify "Auto mode: dim/lock/suspend per hypridle.conf"
        ;;
    boot)
        ensure_state
        if [ "$(current)" = "awake" ]; then
            stop_idle
        else
            start_idle
        fi
        ;;
    status)
        current
        ;;
    *)
        echo "usage: idle-mode.sh awake|normal|boot|status" >&2
        exit 1
        ;;
esac
