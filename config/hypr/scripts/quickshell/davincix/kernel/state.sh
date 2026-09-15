#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# davincix · kernel — state
#
# Detects the current wallpaper (mpvpaper or xwww) and keeps the cached copy
# that the lock screen and SDDM read (current_wallpaper.png).
# ═══════════════════════════════════════════════════════════════════════════

# Path of the current wallpaper, or empty.
davincix_current() {
    local src=""
    if pgrep -a mpvpaper >/dev/null 2>&1; then
        src="$(pgrep -a mpvpaper | grep -o "$DAVINCIX_WALLPAPER_DIR/[^' ]*" | head -n1)"
    elif command -v xwww >/dev/null 2>&1; then
        src="$(xwww query 2>/dev/null | grep -o "$DAVINCIX_WALLPAPER_DIR/[^ ]*" | head -n1)"
    fi
    printf '%s' "$src"
}

# Thumbnail name of the current wallpaper ("000_" prefix for video), or empty.
davincix_current_thumb_name() {
    local src base
    src="$(davincix_current)"
    [ -n "$src" ] || return 0
    base="$(basename "$src")"
    if davincix_is_video "$base"; then
        printf '000_%s' "$base"
    else
        printf '%s' "$base"
    fi
}

# Cache the current wallpaper image (used by the lock screen and SDDM).
davincix_cache_current() {
    local img="$1"
    [ -f "$img" ] && cp "$img" "$DAVINCIX_CURRENT_IMG" 2>/dev/null || true
}
