#!/bin/bash

if ! command -v hyprctl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    exit 1
fi

choices=$(cat <<'EOF'
100% (1.0)
80% (0.8)
75% (0.75)
EOF
)

pick=""
if command -v rofi >/dev/null 2>&1; then
    pick=$(printf "%s" "$choices" | rofi -dmenu -p "Scale" -theme "$HOME/.config/rofi/launcher.rasi")
else
    exit 1
fi

[ -z "$pick" ] && exit 0

case "$pick" in
    "100% (1.0)") scale="1" ;;
    "80% (0.8)") scale="0.8" ;;
    "75% (0.75)") scale="0.75" ;;
    *) exit 0 ;;
esac

hyprctl -j monitors | jq -r '.[] | [.name, .x, .y] | @tsv' | while IFS=$'\t' read -r name x y; do
    [ -z "$name" ] && continue
    hyprctl keyword monitor "$name,preferred,${x}x${y},$scale" >/dev/null 2>&1
done

killall waybar 2>/dev/null
sleep 0.2
waybar &
disown

