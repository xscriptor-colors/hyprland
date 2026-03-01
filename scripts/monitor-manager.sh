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
            hyprctl keyword monitor "$primary, preferred, 0x0, 1"
            hyprctl keyword monitor "$secondary, preferred, ${primary_w}x0, 1"
            notify-send -t 3000 "󰍹 Monitor Layout" "External on the RIGHT"
            ;;
        "left")
            hyprctl keyword monitor "$secondary, preferred, 0x0, 1"
            hyprctl keyword monitor "$primary, preferred, ${secondary_w}x0, 1"
            notify-send -t 3000 "󰍹 Monitor Layout" "External on the LEFT"
            ;;
        "above")
            hyprctl keyword monitor "$secondary, preferred, 0x0, 1"
            hyprctl keyword monitor "$primary, preferred, 0x${secondary_h}, 1"
            notify-send -t 3000 "󰍹 Monitor Layout" "External ABOVE"
            ;;
        "below")
            hyprctl keyword monitor "$primary, preferred, 0x0, 1"
            hyprctl keyword monitor "$secondary, preferred, 0x${primary_h}, 1"
            notify-send -t 3000 "󰍹 Monitor Layout" "External BELOW"
            ;;
        "mirror")
            hyprctl keyword monitor "$secondary, preferred, auto, 1, mirror, $primary"
            notify-send -t 3000 "󰍹 Monitor Layout" "MIRRORED displays"
            ;;
        "only-primary")
            hyprctl keyword monitor "$secondary, disable"
            notify-send -t 3000 "󰍹 Monitor Layout" "Only PRIMARY ($primary)"
            ;;
        "only-external")
            hyprctl keyword monitor "$primary, disable"
            notify-send -t 3000 "󰍹 Monitor Layout" "Only EXTERNAL ($secondary)"
            ;;
    esac
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

    if [ -z "$choice" ]; then
        choice=$(echo -e "$options" | wofi --dmenu -i -p "Set Refresh Rate" 2>/dev/null)
    fi

    if [ -n "$choice" ]; then
        local mon rate
        mon=$(echo "$choice" | awk '{print $1}')
        rate=$(echo "$choice" | awk '{print $3}' | sed 's/Hz//')
        hyprctl keyword monitor "$mon, preferred@${rate}, auto, 1"
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

    if [ -z "$choice" ]; then
        choice=$(echo -e "$options" | wofi --dmenu -i -p "Monitor Manager ($count displays)" 2>/dev/null)
    fi

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
