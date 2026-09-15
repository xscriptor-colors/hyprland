#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# davincix · kernel — apply
#
# Applies wallpapers: xwww for still images (with transitions) and mpvpaper
# for video. Starts xwww-daemon when missing and resolves "random"
# transitions. No UI, no search, no download logic here.
# ═══════════════════════════════════════════════════════════════════════════

# Valid xwww transitions (davincix_resolve_transition picks one for "random").
DAVINCIX_TRANSITIONS=(simple fade left right top bottom wipe grow center outer wave glitch decrypt dissolve clock zoom)

# Start xwww-daemon if it is not alive.
davincix_ensure_xwww() {
    pgrep -x xwww-daemon >/dev/null 2>&1 && return 0
    if ! xwww-daemon >/dev/null 2>&1; then
        notify-send "Wallpaper Error" "Failed to start xwww-daemon" -u critical -t 5000
        return 1
    fi
    sleep 0.5
}

# Resolve a transition: empty/"random" → pick one; anything else passes through.
davincix_resolve_transition() {
    local t="${1:-}"
    if [ -z "$t" ] || [ "$t" = "random" ]; then
        echo "${DAVINCIX_TRANSITIONS[$((RANDOM % ${#DAVINCIX_TRANSITIONS[@]}))]}"
    else
        echo "$t"
    fi
}

# Apply a still image. $1=file $2=monitors ("all" or "A,B") $3=transition
davincix_set_image() {
    local file="$1" monitors="${2:-all}" transition="$3"
    local t
    t="$(davincix_resolve_transition "$transition")"

    davincix_ensure_xwww || return 1
    pkill mpvpaper 2>/dev/null || true
    davincix_log "APPLY IMAGE: $file → $monitors (${t})"

    if [ "$monitors" = "all" ]; then
        xwww img "$file" --transition-type "$t" --transition-pos 0.5,0.5 \
            --transition-fps 144 --transition-duration 1 >> "$DAVINCIX_LOG_FILE" 2>&1 &
    else
        xwww img -o "$monitors" "$file" --transition-type "$t" --transition-pos 0.5,0.5 \
            --transition-fps 144 --transition-duration 1 >> "$DAVINCIX_LOG_FILE" 2>&1 &
    fi
}

# Apply a video. $1=file $2=monitors
davincix_set_video() {
    local file="$1" monitors="${2:-all}"
    local opts='loop --no-audio --hwdec=auto --profile=high-quality --video-sync=display-resample --interpolation --tscale=oversample'
    davincix_log "APPLY VIDEO: $file → $monitors"

    if [ "$monitors" = "all" ]; then
        mpvpaper -o "$opts" '*' "$file" >> "$DAVINCIX_LOG_FILE" 2>&1 &
    else
        local mon
        IFS=',' read -ra MON_ARR <<< "$monitors"
        for mon in "${MON_ARR[@]}"; do
            mpvpaper -o "$opts" "$mon" "$file" >> "$DAVINCIX_LOG_FILE" 2>&1 &
        done
    fi
}
