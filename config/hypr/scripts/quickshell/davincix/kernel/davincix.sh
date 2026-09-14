#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# davincix · kernel — CLI entry point
#
# The UI (ui/DavincixPicker.qml) and the desktop scripts (qs_manager.sh,
# init.sh) call this CLI; the logic lives in the kernel modules
# (paths / util / apply / state / download / thumbs / search).
# ═══════════════════════════════════════════════════════════════════════════
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/paths.sh"
source "$DIR/util.sh"
source "$DIR/apply.sh"
source "$DIR/state.sh"
source "$DIR/download.sh"
davincix_ensure_dirs

usage() {
    cat <<'EOF'
usage: davincix.sh <command> [options]

  set <file|url>   apply a wallpaper (--video, --monitors all|A,B,
                   --transition name, --thumb <poster>, --notify, --dry-run)
  fetch            download a search result and apply it (--name, --map,
                   --dest, --thumb-in, --thumb-out, --monitors, --transition)
  current          print the current wallpaper path (--thumb-name for its thumb)
  thumbs           prepare the thumbnail cache (async)
  search <query>   run a DuckDuckGo search
  stop             stop the running search
  paths            print the resolved paths
EOF
    exit 2
}

# ── set: apply a local file or a URL ──────────────────────────────────────────
cmd_set() {
    local src="" video=0 monitors="all" transition="" thumb="" notify=0 dry=0
    while [ $# -gt 0 ]; do
        case "$1" in
            --video) video=1; shift ;;
            --monitors) monitors="$2"; shift 2 ;;
            --transition) transition="$2"; shift 2 ;;
            --thumb) thumb="$2"; shift 2 ;;
            --notify) notify=1; shift ;;
            --dry-run) dry=1; shift ;;
            -*) echo "davincix: unknown option: $1" >&2; exit 2 ;;
            *) src="$1"; shift ;;
        esac
    done
    [ -n "$src" ] || usage

    # URL → download into the download cache.
    if [[ "$src" =~ ^https?:// ]]; then
        local dest="$DAVINCIX_DOWNLOAD_DIR/$(basename "${src%%\?*}")"
        if ! davincix_download "$src" "$dest"; then
            notify-send "Wallpaper Error" "Download failed" -u critical -t 5000
            exit 1
        fi
        src="$dest"
    fi

    if [ ! -f "$src" ]; then
        notify-send "Wallpaper Error" "File not found: $src" -u critical -t 5000
        exit 1
    fi

    if [ "$video" != "1" ] && davincix_is_video "$src"; then video=1; fi

    if [ "$dry" = "1" ]; then
        printf 'dry-run: set src=%s video=%s monitors=%s transition=%s thumb=%s notify=%s\n' \
            "$src" "$video" "$monitors" "${transition:-random}" "${thumb:-none}" "$notify"
        exit 0
    fi

    if [ "$video" = "1" ]; then
        davincix_cache_current "${thumb:-}"
        davincix_set_video "$src" "$monitors"
    else
        davincix_cache_current "$src"
        davincix_set_image "$src" "$monitors" "$transition"
    fi

    if [ "$notify" = "1" ]; then
        notify-send "Wallpaper" "Applied: $(basename "$src")" \
            -i preferences-desktop-wallpaper -t 2000
    fi
}

# ── fetch: download a search result and apply it ──────────────────────────────
cmd_fetch() {
    local name="" map="" dest="" thumb_in="" thumb_out="" monitors="all" transition=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --name) name="$2"; shift 2 ;;
            --map) map="$2"; shift 2 ;;
            --dest) dest="$2"; shift 2 ;;
            --thumb-in) thumb_in="$2"; shift 2 ;;
            --thumb-out) thumb_out="$2"; shift 2 ;;
            --monitors) monitors="$2"; shift 2 ;;
            --transition) transition="$2"; shift 2 ;;
            *) shift ;;
        esac
    done
    if [ -z "$name" ] || [ -z "$map" ] || [ -z "$dest" ]; then usage; fi

    local url
    url="$(awk -F'|' -v fname="$name" '$1 == fname {print $2; exit}' "$map")"
    if [ -z "$url" ]; then
        notify-send "Wallpaper Error" "URL not found for $name" -u critical -t 5000
        exit 1
    fi

    mkdir -p "$(dirname "$dest")"
    if ! davincix_download "$url" "$dest"; then
        notify-send "Wallpaper Error" "Download failed" -u critical -t 5000
        exit 1
    fi

    # Final thumbnail: copy of the temporary one plus a resize.
    if [ -n "$thumb_out" ]; then
        mkdir -p "$(dirname "$thumb_out")"
        if [ -n "$thumb_in" ] && [ -f "$thumb_in" ]; then cp "$thumb_in" "$thumb_out"; fi
        magick "$dest" -resize x420 -quality 70 "$thumb_out" 2>/dev/null || true
    fi

    davincix_cache_current "$dest"
    davincix_set_image "$dest" "$monitors" "$transition"
}

# ── current ───────────────────────────────────────────────────────────────────
cmd_current() {
    if [ "${1:-}" = "--thumb-name" ]; then
        davincix_current_thumb_name
    else
        davincix_current
    fi
}

# ── thumbs: prepare the thumbnail cache (async) ───────────────────────────────
cmd_thumbs() {
    source "$DIR/thumbs.sh"
    davincix_thumbs_prep
}

# ── stop: stop the running search ─────────────────────────────────────────────
cmd_stop() {
    echo 'stop' > "$DAVINCIX_CONTROL_FILE"
    pkill -f "$DIR/search.sh" 2>/dev/null || true
    pkill -f "$DIR/ddg_links.py" 2>/dev/null || true
}

# ── search: run a DDG search (stops the previous one and clears its cache) ────
cmd_search() {
    local query="${1:-}"
    [ -n "$query" ] || usage

    cmd_stop
    sleep 0.2

    rm -rf "${DAVINCIX_SEARCH_DIR:?}"/* 2>/dev/null || true
    rm -f "$DAVINCIX_MAP_FILE" 2>/dev/null || true

    echo 'run' > "$DAVINCIX_CONTROL_FILE"
    nohup bash "$DIR/search.sh" "$query" >/dev/null 2>&1 &
}

# ── paths: print the resolved paths (debug) ───────────────────────────────────
cmd_paths() {
    printf 'wallpaper_dir = %s\n' "$DAVINCIX_WALLPAPER_DIR"
    printf 'cache_dir     = %s\n' "$DAVINCIX_CACHE_DIR"
    printf 'thumb_dir     = %s\n' "$DAVINCIX_THUMB_DIR"
    printf 'search_dir    = %s\n' "$DAVINCIX_SEARCH_DIR"
    printf 'run_dir       = %s\n' "$DAVINCIX_RUN_DIR"
    printf 'control_file  = %s\n' "$DAVINCIX_CONTROL_FILE"
    printf 'current_img   = %s\n' "$DAVINCIX_CURRENT_IMG"
}

cmd="${1:-}"
[ $# -gt 0 ] && shift
case "$cmd" in
    set) cmd_set "$@" ;;
    fetch) cmd_fetch "$@" ;;
    current) cmd_current "$@" ;;
    thumbs) cmd_thumbs "$@" ;;
    search) cmd_search "$@" ;;
    stop) cmd_stop "$@" ;;
    paths) cmd_paths "$@" ;;
    *) usage ;;
esac
