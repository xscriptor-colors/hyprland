#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/caching.sh"
qs_ensure_cache "wallpaper_picker"

FLAG="$QS_STATE_WALLPAPER_PICKER/wallpaper_initialized"
CACHE_IMG="$QS_CACHE_WALLPAPER_PICKER/current_wallpaper.png"

RELOAD_SCRIPT_PATH="$(dirname "${BASH_SOURCE[0]}")/quickshell/wallpaper/matugen_reload.sh"

# If the flag exists, just run matugen and the reload script, then exit
if [ -f "$FLAG" ]; then
    # Use the cached wallpaper image for matugen
    if [ -f "$CACHE_IMG" ] && command -v matugen >/dev/null 2>&1; then
        matugen image "$CACHE_IMG" --source-color-index 0 2>/dev/null || true
    fi
    
    if [ -f "$RELOAD_SCRIPT_PATH" ]; then
        chmod +x "$RELOAD_SCRIPT_PATH"
        bash "$RELOAD_SCRIPT_PATH"
    fi
    
    exit 0
fi

# If no wallpaper dir is set, default to hyprland config wallpapers
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/.config/hypr/wallpapers}"

sleep 0.5

# Find a random file
file=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) 2>/dev/null | shuf -n 1)

if [ -n "$file" ]; then
    # Copy to our persistent cache location instead of /tmp
    cp "$file" "$CACHE_IMG"
    
    WPBIN=""; command -v swww >/dev/null 2>&1 && WPBIN=swww || command -v awww >/dev/null 2>&1 && WPBIN=awww
    [ -n "$WPBIN" ] && $WPBIN img "$file" --transition-type any --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1 &
    
    command -v matugen >/dev/null 2>&1 && matugen image "$file" --source-color-index 0 2>/dev/null || true
    
    # Execute reload script if it exists
    if [ -f "$RELOAD_SCRIPT_PATH" ]; then
        chmod +x "$RELOAD_SCRIPT_PATH"
        bash "$RELOAD_SCRIPT_PATH"
    fi
fi

mkdir -p "$(dirname "$FLAG")"
touch "$FLAG"
