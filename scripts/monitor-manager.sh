#!/bin/bash

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ MONITOR MANAGEMENT                                                       ║
# ║                                                                           ║
# ║ Rofi menu to manage monitor position, resolution, and refresh rate.      ║
# ║ Detects connected monitors via hyprctl and provides quick presets.        ║
# ║                                                                           ║
# ║ Usage:                                                                    ║
# ║   monitor-manager.sh          - Open Rofi monitor menu                   ║
# ║   monitor-manager.sh info     - Show current monitor info                ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

# ────────────────────────────────────────────────────────────────────────────
# Apply a monitor via the Lua API (Hyprland 0.55+ has no `hyprctl keyword`)
# ────────────────────────────────────────────────────────────────────────────

apply_monitor_lua() {
    # $1: lua snippet, e.g. { output = "eDP-1", mode = "preferred", position = "0x0", scale = 1 }
    hyprctl eval 'hl.monitor('"$1"')' >/dev/null 2>&1
}

# Layout value from ~/.config/hypr/display-config (desc|x|y|scale|mode) for the
# physical screen behind a given output name. Saved lines are keyed by the EDID
# description (survives connector renames), so we first resolve name -> desc.
get_layout_value() {
    local mon="$1" col="$2" desc saved
    desc=$(get_monitors | python3 -c "
import json, sys
try:
    for m in json.load(sys.stdin):
        if m['name'] == sys.argv[1]:
            print(m.get('description', ''))
            break
except Exception:
    pass
" "$mon" 2>/dev/null)
    if [ -f "$HOME/.config/hypr/display-config" ]; then
        [ -n "$desc" ] && saved=$(awk -F'|' -v d="$desc" "\$1 == d {print \$$col; exit}" "$HOME/.config/hypr/display-config")
        [ -z "$saved" ] && saved=$(awk -F'|' -v m="$mon" "\$1 == m {print \$$col; exit}" "$HOME/.config/hypr/display-config")
        [ -n "$saved" ] && { echo "$saved"; return; }
    fi
}

# Current scale for a monitor: the persisted value when available, otherwise the
# live one. Keeps layout changes from clobbering the scale chosen in scale-menu.
get_scale() {
    local val
    val=$(get_layout_value "$1" 4)
    [ -n "$val" ] && { echo "$val"; return; }
    get_monitors | python3 -c "
import json, sys
for m in json.load(sys.stdin):
    if m['name'] == sys.argv[1]:
        print(m.get('scale', 1))
        break
" "$1" 2>/dev/null || echo "1"
}

# Exact saved mode for a monitor (e.g. 1920x1080@144.11Hz). Reusing it keeps the
# real refresh rate: plain "preferred" and "preferred@<int>" silently fall back
# to the EDID-preferred 60Hz when the asked rate is not an exact mode.
get_mode() {
    local val
    val=$(get_layout_value "$1" 5)
    [ -n "$val" ] && { echo "$val"; return; }
    echo "highrr"
}

# Persist the current monitor layout (desc|x|y|scale|mode) so monitors.lua and
# restore-monitors.sh restore it on the next session instead of falling back.
persist_monitors() {
    bash "$(dirname "${BASH_SOURCE[0]}")/persist-display-config.sh" > "$HOME/.config/hypr/display-config" 2>/dev/null || true
}

# ────────────────────────────────────────────────────────────────────────────
# Get monitor info from hyprctl
# ────────────────────────────────────────────────────────────────────────────

get_monitors() {
    hyprctl monitors -j 2>/dev/null
}

get_monitor_count() {
    get_monitors | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0"
}

get_monitor_names() {
    get_monitors | python3 -c "
import json, sys
monitors = json.load(sys.stdin)
for m in monitors:
    print(m['name'])
" 2>/dev/null
}

get_monitor_details() {
    get_monitors | python3 -c "
import json, sys
monitors = json.load(sys.stdin)
for m in monitors:
    name = m.get('name', '?')
    desc = m.get('description', '?')
    w = m.get('width', 0)
    h = m.get('height', 0)
    rate = m.get('refreshRate', 0)
    x = m.get('x', 0)
    y = m.get('y', 0)
    scale = m.get('scale', 1)
    active_ws = m.get('activeWorkspace', {}).get('id', '?')
    print(f'{name}|{desc}|{w}x{h}|{rate:.0f}Hz|{x},{y}|{scale}|WS:{active_ws}')
" 2>/dev/null
}

# ────────────────────────────────────────────────────────────────────────────
# Show monitor info notification
# ────────────────────────────────────────────────────────────────────────────

show_info() {
    local details
    details=$(get_monitor_details)
    local count
    count=$(get_monitor_count)

    local msg="Monitors: $count\n"
    while IFS='|' read -r name desc res rate pos scale ws; do
        msg+="━━━━━━━━━━━━━━━━━━━━━━━\n"
        msg+="$name ($desc)\n"
        msg+="  Resolution: $res @ $rate\n"
        msg+="  Position: $pos | Scale: $scale\n"
        msg+="  Active: $ws\n"
    done <<< "$details"

    notify-send -t 8000 -h string:x-dunst-stack-tag:monitor-info \
        "󰍹 Monitor Info" "$msg"
}

# ────────────────────────────────────────────────────────────────────────────
# Position presets for dual-monitor
# ────────────────────────────────────────────────────────────────────────────

apply_position() {
    local layout="$1"
    local monitors
    mapfile -t monitors < <(get_monitor_names)

    if [ ${#monitors[@]} -lt 2 ]; then
        notify-send -u warning "Monitor Manager" "Only 1 monitor detected. Connect an external display first."
        return
    fi

    local primary="${monitors[0]}"
    local secondary="${monitors[1]}"

    # Get primary resolution for positioning
    local primary_w primary_h
    primary_w=$(get_monitors | python3 -c "import json,sys; m=json.load(sys.stdin); print(m[0].get('width',1920))" 2>/dev/null)
    primary_h=$(get_monitors | python3 -c "import json,sys; m=json.load(sys.stdin); print(m[0].get('height',1080))" 2>/dev/null)
    local secondary_w secondary_h
    secondary_w=$(get_monitors | python3 -c "import json,sys; m=json.load(sys.stdin); print(m[1].get('width',1920))" 2>/dev/null)
    secondary_h=$(get_monitors | python3 -c "import json,sys; m=json.load(sys.stdin); print(m[1].get('height',1080))" 2>/dev/null)

    case "$layout" in
        "right")
            apply_monitor_lua "{ output = \"$primary\", mode = \"$(get_mode "$primary")\", position = \"0x0\", scale = $(get_scale "$primary") }"
            apply_monitor_lua "{ output = \"$secondary\", mode = \"$(get_mode "$secondary")\", position = \"${primary_w}x0\", scale = $(get_scale "$secondary") }"
            notify-send -t 3000 "󰍹 Monitor Layout" "External on the RIGHT"
            ;;
        "left")
            apply_monitor_lua "{ output = \"$secondary\", mode = \"$(get_mode "$secondary")\", position = \"0x0\", scale = $(get_scale "$secondary") }"
            apply_monitor_lua "{ output = \"$primary\", mode = \"$(get_mode "$primary")\", position = \"${secondary_w}x0\", scale = $(get_scale "$primary") }"
            notify-send -t 3000 "󰍹 Monitor Layout" "External on the LEFT"
            ;;
        "above")
            apply_monitor_lua "{ output = \"$secondary\", mode = \"$(get_mode "$secondary")\", position = \"0x0\", scale = $(get_scale "$secondary") }"
            apply_monitor_lua "{ output = \"$primary\", mode = \"$(get_mode "$primary")\", position = \"0${secondary_h}\", scale = $(get_scale "$primary") }"
            notify-send -t 3000 "󰍹 Monitor Layout" "External ABOVE"
            ;;
        "below")
            apply_monitor_lua "{ output = \"$primary\", mode = \"$(get_mode "$primary")\", position = \"0x0\", scale = $(get_scale "$primary") }"
            apply_monitor_lua "{ output = \"$secondary\", mode = \"$(get_mode "$secondary")\", position = \"0${primary_h}\", scale = $(get_scale "$secondary") }"
            notify-send -t 3000 "󰍹 Monitor Layout" "External BELOW"
            ;;
        "mirror")
            apply_monitor_lua "{ output = \"$secondary\", mode = \"$(get_mode "$secondary")\", position = \"auto\", scale = $(get_scale "$secondary"), mirror = \"$primary\" }"
            notify-send -t 3000 "󰍹 Monitor Layout" "MIRRORED displays"
            ;;
        "only-primary")
            apply_monitor_lua "{ output = \"$secondary\", disabled = true }"
            notify-send -t 3000 "󰍹 Monitor Layout" "Only PRIMARY ($primary)"
            ;;
        "only-external")
            apply_monitor_lua "{ output = \"$primary\", disabled = true }"
            notify-send -t 3000 "󰍹 Monitor Layout" "Only EXTERNAL ($secondary)"
            ;;
    esac

    persist_monitors
}

# ────────────────────────────────────────────────────────────────────────────
# Refresh rate change
# ────────────────────────────────────────────────────────────────────────────

change_refresh_rate() {
    local monitors
    mapfile -t monitors < <(get_monitor_names)

    local options=""
    for mon in "${monitors[@]}"; do
        options+="$mon - 60Hz\n"
        options+="$mon - 90Hz\n"
        options+="$mon - 120Hz\n"
        options+="$mon - 144Hz\n"
        options+="$mon - 165Hz\n"
        options+="$mon - 240Hz\n"
    done

    local choice
    choice=$(echo -e "$options" | rofi -dmenu -i -p "Set Refresh Rate" -theme-str 'window {width: 350px;}' 2>/dev/null)

    if [ -n "$choice" ]; then
        local mon rate mode
        mon=$(echo "$choice" | awk '{print $1}')
        rate=$(echo "$choice" | awk '{print $3}' | sed 's/Hz//')
        # Resolve the requested rate to the closest exact available mode.
        # "preferred@<int>" would silently land on 60Hz when the panel's real
        # mode is e.g. 144.11Hz, so never use it here.
        mode=$(get_monitors | python3 -c "
import json, sys
try:
    target = float(sys.argv[2])
    for m in json.load(sys.stdin):
        if m['name'] == sys.argv[1]:
            best = None
            for s in m.get('availableModes') or []:
                try:
                    r = float(s.split('@')[1].replace('Hz', ''))
                except Exception:
                    continue
                if best is None or abs(r - target) < abs(best[0] - target):
                    best = (r, s)
            print(best[1] if best else 'highrr')
            break
except Exception:
    print('highrr')
" "$mon" "$rate" 2>/dev/null)
        [ -z "$mode" ] && mode="highrr"
        apply_monitor_lua "{ output = \"$mon\", mode = \"$mode\", position = \"auto\", scale = $(get_scale "$mon") }"
        persist_monitors
        notify-send -t 3000 "󰍹 Refresh Rate" "$mon set to ${rate}Hz"
    fi
}

# ────────────────────────────────────────────────────────────────────────────
# Main Rofi menu
# ────────────────────────────────────────────────────────────────────────────

main_menu() {
    local count
    count=$(get_monitor_count)

    local details=""
    while IFS='|' read -r name desc res rate pos scale ws; do
        details+="  $name: $res $rate\n"
    done < <(get_monitor_details)

    local options=""

    # Always show info option
    options+="󰍹  Monitor Info\n"

    if [ "$count" -ge 2 ]; then
        options+="━━━━━━━━━━━━━━━━━━━━━━━\n"
        options+="  External on RIGHT\n"
        options+="  External on LEFT\n"
        options+="  External ABOVE\n"
        options+="  External BELOW\n"
        options+="  Mirror displays\n"
        options+="━━━━━━━━━━━━━━━━━━━━━━━\n"
        options+="  Only primary\n"
        options+="  Only external\n"
    fi

    options+="━━━━━━━━━━━━━━━━━━━━━━━\n"
    options+="󰓅  Change refresh rate"

    local choice
    choice=$(echo -e "$options" | rofi -dmenu -i -p "Monitor Manager ($count displays)" -theme-str 'window {width: 400px;}' 2>/dev/null)

    case "$choice" in
        *"Monitor Info"*)       show_info ;;
        *"External on RIGHT"*)  apply_position "right" ;;
        *"External on LEFT"*)   apply_position "left" ;;
        *"External ABOVE"*)     apply_position "above" ;;
        *"External BELOW"*)     apply_position "below" ;;
        *"Mirror displays"*)    apply_position "mirror" ;;
        *"Only primary"*)       apply_position "only-primary" ;;
        *"Only external"*)      apply_position "only-external" ;;
        *"refresh rate"*)       change_refresh_rate ;;
    esac
}

# ────────────────────────────────────────────────────────────────────────────
# Main
# ────────────────────────────────────────────────────────────────────────────

case "$1" in
    info) show_info ;;
    *)    main_menu ;;
esac
