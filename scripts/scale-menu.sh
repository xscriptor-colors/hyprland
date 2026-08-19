#!/bin/bash
# Global display scale: makes EVERYTHING bigger or smaller (apps, windows and
# the shell) by changing the Hyprland output scale.
#
# settings.json stays as the record for QuickShell, but the actual scale is
# applied through the Lua API (`hyprctl eval 'hl.monitor(...)'`) — Hyprland
# 0.55+ has no `hyprctl keyword monitor` and no config generator daemon.
#
# Usage:
#   scale-menu.sh            rofi menu
#   scale-menu.sh 1.5        set an explicit scale
#   scale-menu.sh up|down    step through the ladder below

if ! command -v jq >/dev/null 2>&1; then
    exit 1
fi

SETTINGS="$HOME/.config/hypr/settings.json"

# Only scales that divide 1920x1080 into whole pixels. Hyprland rejects anything
# else and silently snaps to a nearby value, which makes the stored number and
# the real one drift apart.
LADDER="0.8 1.0 1.25 1.5 2.0"

mkdir -p "$(dirname "$SETTINGS")"
[ ! -f "$SETTINGS" ] && echo '{}' > "$SETTINGS"

# settings.json is the source of truth. Seed it from the live outputs only if it
# has nothing yet, so this never depends on hyprctl during a modeset.
if [ "$(jq '(.monitors // []) | length' "$SETTINGS")" = "0" ]; then
    if ! command -v hyprctl >/dev/null 2>&1; then
        exit 1
    fi
    SEED=$(hyprctl -j monitors | jq '[.[] | {
        name: .name, resW: .width, resH: .height,
        rate: (.refreshRate | round), x: .x, y: .y,
        scale: .scale, transform: (.transform // 0)
    }]')
    [ -z "$SEED" ] && exit 1
    jq --argjson mons "$SEED" '.monitors = $mons' "$SETTINGS" > "${SETTINGS}.tmp" \
        && mv "${SETTINGS}.tmp" "$SETTINGS" || { rm -f "${SETTINGS}.tmp"; exit 1; }
fi

CURRENT=$(jq -r '.monitors[0].scale // 1' "$SETTINGS")

next_in_ladder() {
    # $1 = up|down -- picks the neighbouring rung, clamping at both ends.
    awk -v cur="$CURRENT" -v dir="$1" -v ladder="$LADDER" 'BEGIN {
        n = split(ladder, a, " ")
        idx = 1
        best = 1e9
        for (i = 1; i <= n; i++) {
            d = (a[i] - cur); if (d < 0) d = -d
            if (d < best) { best = d; idx = i }
        }
        if (dir == "up")   idx = (idx < n) ? idx + 1 : n
        if (dir == "down") idx = (idx > 1) ? idx - 1 : 1
        print a[idx]
    }'
}

case "$1" in
    up|down)
        scale=$(next_in_ladder "$1")
        ;;
    "")
        command -v rofi >/dev/null 2>&1 || exit 1
        choices=""
        for s in $LADDER; do
            pct=$(awk -v s="$s" 'BEGIN{ printf "%d", s*100 }')
            mark=""
            [ "$s" = "$CURRENT" ] && mark="  ●"
            choices="${choices}${pct}% (${s})${mark}\n"
        done
        pick=$(printf "%b" "$choices" | rofi -dmenu -p "Display scale" -theme "$HOME/.config/rofi/launcher.rasi")
        [ -z "$pick" ] && exit 0
        scale=$(printf "%s" "$pick" | sed -n 's/.*(\([0-9.]*\)).*/\1/p')
        ;;
    *)
        scale="$1"
        ;;
esac

case "$scale" in
    ''|*[!0-9.]*) exit 1 ;;
esac

[ "$scale" = "$CURRENT" ] && exit 0

# Record in settings.json (QuickShell reads this for its own UI scale).
jq --argjson s "$scale" '.monitors = [ .monitors[] | .scale = $s ]' "$SETTINGS" > "${SETTINGS}.tmp" \
    && mv "${SETTINGS}.tmp" "$SETTINGS" || { rm -f "${SETTINGS}.tmp"; exit 1; }

# Apply to every connected monitor through the Lua API, then persist the layout
# to display-config so monitors.lua restores it on the next session instead of
# falling back to the "auto" DPI scale (which resets to 125%/150% on login).
if command -v hyprctl >/dev/null 2>&1; then
    hyprctl -j monitors 2>/dev/null | jq -r --argjson s "$scale" '.[] | "hyprctl eval '\''hl.monitor({ output = \"\(.name)\", mode = \"preferred\", position = \"\(.x)x\(.y)\", scale = \($s) })'\''"' | bash
    hyprctl -j monitors 2>/dev/null | jq -r '.[] | "\(.name)|\(.x)|\(.y)|\(.scale)"' > "$(dirname "$SETTINGS")/display-config"
fi

if command -v notify-send >/dev/null 2>&1; then
    notify-send "Display Scale" "$(awk -v s="$scale" 'BEGIN{ printf "%d%%", s*100 }') — applied to all monitors"
fi
