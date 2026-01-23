#!/bin/bash

WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"
CACHE_DIR="$HOME/.cache/wallpaper-thumbs"
THUMB_SIZE="150x100"
THUMB_SQRE_SIZE="256x256"

mkdir -p "$CACHE_DIR"

if [ ! -d "$WALLPAPER_DIR" ] || [ -z "$(ls -A "$WALLPAPER_DIR" 2>/dev/null)" ]; then
    WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
fi

if [ ! -d "$WALLPAPER_DIR" ] || [ -z "$(ls -A "$WALLPAPER_DIR" 2>/dev/null)" ]; then
    WALLPAPER_DIR="$HOME/Pictures"
fi

if [ ! -d "$WALLPAPER_DIR" ]; then
    notify-send "Wallpaper" "No wallpaper directory found" -u critical
    exit 1
fi

use_rofi=0
command -v rofi >/dev/null 2>&1 && use_rofi=1

ensure_thumb() {
    local img="$1"
    local out="$2"
    local size="$3"

    if [ -f "$out" ] && [ "$img" -ot "$out" ]; then
        return 0
    fi

    local w=${size%x*}
    local h=${size#*x}
    local radius=20

    if command -v magick >/dev/null 2>&1; then
        magick "$img" -resize "${size}^" -gravity center -extent "$size" \
            \( -size "$size" xc:none -fill white -draw "roundrectangle 0,0,$((w-1)),$((h-1)),$radius,$radius" \) \
            -compose DstIn -composite \
            "$out" 2>/dev/null
        return 0
    fi
    if command -v convert >/dev/null 2>&1; then
        convert "$img" -resize "${size}^" -gravity center -extent "$size" \
            \( -size "$size" xc:none -fill white -draw "roundrectangle 0,0,$((w-1)),$((h-1)),$radius,$radius" \) \
            -compose DstIn -composite \
            "$out" 2>/dev/null
        return 0
    fi
    return 1
}

pick_with_rofi() {
    local tmp
    tmp=$(mktemp)
    local count=0

    shopt -s nullglob nocaseglob
    for img in "$WALLPAPER_DIR"/*.{jpg,jpeg,png,webp}; do
        [ -f "$img" ] || continue
        filename=$(basename "$img")
        thumb_sqre="$CACHE_DIR/${filename}.sqre.png"
        ensure_thumb "$img" "$thumb_sqre" "$THUMB_SQRE_SIZE" || true
        if [ -f "$thumb_sqre" ]; then
            printf '%s\0icon\x1f%s\0info\x1f%s\n' "$filename" "$thumb_sqre" "$img" >> "$tmp"
        else
            printf '%s\0info\x1f%s\n' "$filename" "$img" >> "$tmp"
        fi
        count=$((count + 1))
    done
    shopt -u nocaseglob nullglob

    if [ "$count" -eq 0 ]; then
        rm -f "$tmp"
        notify-send "Wallpaper" "No wallpapers found in $WALLPAPER_DIR" -u critical
        exit 1
    fi

    mon_x_res=1920
    mon_scale=100
    if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
        mon_x_res=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .width' 2>/dev/null)
        mon_scale=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .scale' 2>/dev/null | sed 's/\.//')
        mon_x_res=${mon_x_res:-1920}
        mon_scale=${mon_scale:-100}
    fi
    mon_x_res=$((mon_x_res * 100 / mon_scale))
    columns=$((mon_x_res / 360))
    [ "$columns" -lt 3 ] && columns=3
    [ "$columns" -gt 7 ] && columns=7

    selected=$(cat "$tmp" | rofi -dmenu \
        -show-icons \
        -theme "$HOME/.config/rofi/selector.rasi" \
        -theme-str "listview { columns: ${columns}; }")

    rm -f "$tmp"

    [ -z "$selected" ] && exit 0

    selected=$(basename "$selected")
    wallpaper="$WALLPAPER_DIR/$selected"

    if [ -f "$wallpaper" ]; then
        printf '%s' "$wallpaper"
        return 0
    fi

    name="${selected%.*}"
    for img in "$WALLPAPER_DIR"/*; do
        [ -f "$img" ] || continue
        imgname=$(basename "${img%.*}")
        if [ "$imgname" = "$name" ]; then
            printf '%s' "$img"
            return 0
        fi
    done

    return 1
}

pick_with_wofi() {
    local entries=""
    local count=0
    shopt -s nullglob nocaseglob
    for img in "$WALLPAPER_DIR"/*.{jpg,jpeg,png,webp}; do
        [ -f "$img" ] || continue
        filename=$(basename "$img")
        name="${filename%.*}"
        thumb="$CACHE_DIR/${filename}.png"
        ensure_thumb "$img" "$thumb" "$THUMB_SIZE" || true
        if [ -f "$thumb" ]; then
            entries+="img:${thumb}:text:${name}\n"
        else
            entries+="${filename}\n"
        fi
        count=$((count + 1))
    done
    shopt -u nocaseglob nullglob

    if [ "$count" -eq 0 ]; then
        notify-send "Wallpaper" "No wallpapers found in $WALLPAPER_DIR" -u critical
        exit 1
    fi

    selected=$(printf "%b" "$entries" | wofi --dmenu \
        --prompt " Wallpaper" \
        --cache-file /dev/null \
        --allow-images \
        --define image_size=150 \
        --columns 4 \
        --width 1000 \
        --height 600 \
        --style "$HOME/.config/wofi/wallpaper.css")

    [ -z "$selected" ] && exit 0

    if [[ "$selected" == img:*:text:* ]]; then
        name="${selected#img:}"
        name="${name#*:text:}"
    else
        name="$(basename "$selected")"
        name="${name%.*}"
    fi

    wallpaper=""
    for ext in jpg jpeg png webp JPG JPEG PNG WEBP; do
        if [ -f "$WALLPAPER_DIR/$name.$ext" ]; then
            wallpaper="$WALLPAPER_DIR/$name.$ext"
            break
        fi
    done

    if [ -z "$wallpaper" ] || [ ! -f "$wallpaper" ]; then
        for img in "$WALLPAPER_DIR"/*; do
            [ -f "$img" ] || continue
            imgname=$(basename "${img%.*}")
            if [ "$imgname" = "$name" ]; then
                wallpaper="$img"
                break
            fi
        done
    fi

    [ -z "$wallpaper" ] && exit 1
    printf '%s' "$wallpaper"
}

if [ "$use_rofi" -eq 1 ]; then
    wallpaper=$(pick_with_rofi)
else
    wallpaper=$(pick_with_wofi)
fi

if [ -z "$wallpaper" ] || [ ! -f "$wallpaper" ]; then
    notify-send "Wallpaper" "Could not find wallpaper" -u critical
    exit 1
fi

if ! pgrep -x "swww-daemon" >/dev/null 2>&1; then
    swww-daemon &
    sleep 0.5
fi

types=("fade" "left" "right" "top" "bottom" "wipe" "wave" "grow" "center" "outer")
positions=("center" "top" "left" "right" "bottom" "top-left" "top-right" "bottom-left" "bottom-right")
rand_type=${types[$RANDOM % ${#types[@]}]}
rand_pos=${positions[$RANDOM % ${#positions[@]}]}

swww img "$wallpaper" \
    --transition-type "$rand_type" \
    --transition-pos "$rand_pos" \
    --transition-duration 2 \
    --transition-fps 120

notify-send "Wallpaper" "Applied: $(basename "$wallpaper")" -i preferences-desktop-wallpaper
