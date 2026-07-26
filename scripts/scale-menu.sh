#!/bin/bash
# Monitor scale: scales EVERYTHING (apps, windows and the shell) by changing the
# Hyprland output scale.
#
# Two things this has to get right, both of which used to be broken:
#   1. Keep the monitor's current mode. Passing `preferred` drops a 144Hz panel
#      back to 60Hz.
#   2. Persist the result into settings.json. Otherwise the next settings write
#      makes settings_watcher.sh regenerate monitors.conf from the old value and
#      `hyprctl reload` silently reverts the scale.
#
# Hyprland refuses scales whose logical size is not a whole number of pixels and
# snaps to the nearest usable one, so the value is read back after applying and
# it is that effective value which gets stored.
#
# Usage: scale-menu.sh [scale]     (no argument opens the rofi menu)

if ! command -v hyprctl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    exit 1
fi

SETTINGS="$HOME/.config/hypr/settings.json"

scale="$1"

if [ -z "$scale" ]; then
    choices=$(cat <<'EOF'
100% (1.0)
110% (1.1)
125% (1.25)
150% (1.5)
175% (1.75)
200% (2.0)
90% (0.9)
80% (0.8)
EOF
)
    if ! command -v rofi >/dev/null 2>&1; then
        exit 1
    fi
    pick=$(printf "%s" "$choices" | rofi -dmenu -p "Scale" -theme "$HOME/.config/rofi/launcher.rasi")
    [ -z "$pick" ] && exit 0
    # Pull the numeric factor out of the "... (1.25)" label
    scale=$(printf "%s" "$pick" | sed -n 's/.*(\([0-9.]*\)).*/\1/p')
fi

case "$scale" in
    ''|*[!0-9.]*) exit 1 ;;
esac

# Re-apply every monitor at its CURRENT mode and position, changing only scale.
while IFS=$'\t' read -r name w h rate x y transform; do
    [ -z "$name" ] && continue
    line="$name,${w}x${h}@${rate},${x}x${y},$scale"
    [ "$transform" != "0" ] && line="$line,transform,$transform"
    hyprctl keyword monitor "$line" >/dev/null 2>&1
done < <(hyprctl -j monitors | jq -r '.[] | [.name, .width, .height, (.refreshRate|round), .x, .y, (.transform // 0)] | @tsv')

sleep 0.5

# Store what Hyprland actually accepted, so a reload reproduces this state
# instead of fighting it.
MONS=$(hyprctl -j monitors | jq '[.[] | {
    name: .name,
    resW: .width,
    resH: .height,
    rate: (.refreshRate | round),
    x: .x,
    y: .y,
    scale: .scale,
    transform: (.transform // 0)
}]')

if [ -n "$MONS" ] && [ "$MONS" != "null" ]; then
    mkdir -p "$(dirname "$SETTINGS")"
    [ ! -f "$SETTINGS" ] && echo '{}' > "$SETTINGS"
    if jq --argjson mons "$MONS" '.monitors = $mons' "$SETTINGS" > "${SETTINGS}.tmp"; then
        mv "${SETTINGS}.tmp" "$SETTINGS"
    else
        rm -f "${SETTINGS}.tmp"
    fi
fi

# Report the effective scale, which may differ from the requested one.
EFFECTIVE=$(printf "%s" "$MONS" | jq -r '.[0].scale')
if command -v notify-send >/dev/null 2>&1; then
    if [ "$EFFECTIVE" != "$scale" ]; then
        notify-send "Display Scale" "Requested ${scale}x, applied ${EFFECTIVE}x (nearest scale with whole-pixel output)"
    else
        notify-send "Display Scale" "Applied ${EFFECTIVE}x to all monitors"
    fi
fi
