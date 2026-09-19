#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# davincix · kernel — CLI entry point
#
# The UI (ui/DavincixPicker.qml) and the desktop scripts (qs_manager.sh,
# init.sh) call this CLI; the logic lives in the kernel modules
# (paths / util / apply / state / download / thumbs / search).
# ═══════════════════════════════════════════════════════════════════════════
set -uo pipefail

DAVINCIX_VERSION="0.1.0"

# Proveedores que piden API key: NAME|label|where (fuente única para el CLI y
# para el panel de la UI vía `keys list`).
DAVINCIX_KEYED_KEYS=(
    "PEXELS_KEY|Pexels|pexels.com/api"
    "PIXABAY_KEY|Pixabay|pixabay.com/api/docs"
)

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
  search <query>   run a DuckDuckGo search (--source ddg|wallhaven)
  search --continue <query>  next page (keeps the cache; --source optional)
  search --clear   stop the search and drop its cache
  stop             stop the running search
  rm <file>        move a wallpaper to the trash (and its thumbnail)
  import <paths…>  copy files into the wallpaper dir and build thumbnails
  slideshow start|stop|status [interval-seconds]
  keys             show provider API key status (keys.conf)
  keys list        machine-readable key status (UI panel)
  keys set <NAME> <VALUE>  save a provider API key
  paths            print the resolved paths
  --version        print the version
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

    # Vídeo: el map guarda el preview (.jpg como nombre), pero el archivo
    # local debe llevar la extensión real del contenedor para que
    # davincix_is_video/mpvpaper lo detecten.
    local video=0 vext
    if davincix_is_video "$url"; then
        video=1
        vext="${url%%\?*}"
        vext="${vext##*.}"
        vext="$(printf '%s' "$vext" | tr '[:upper:]' '[:lower:]')"
        case "$vext" in
            mp4|webm|mov|mkv) ;;
            *) vext="mp4" ;;
        esac
        dest="${dest%.*}.$vext"
    fi

    mkdir -p "$(dirname "$dest")"
    if ! davincix_download "$url" "$dest"; then
        notify-send "Wallpaper Error" "Download failed" -u critical -t 5000
        exit 1
    fi

    if [ "$video" = "1" ]; then
        # El póster 000_ lo genera la preparación de miniaturas (async).
        source "$DIR/thumbs.sh"
        davincix_thumbs_prep
    elif [ -n "$thumb_out" ]; then
        # Final thumbnail: copy of the temporary one plus a resize.
        mkdir -p "$(dirname "$thumb_out")"
        if [ -n "$thumb_in" ] && [ -f "$thumb_in" ]; then cp "$thumb_in" "$thumb_out"; fi
        magick "$dest" -resize x420 -quality 70 "$thumb_out" 2>/dev/null || true
    fi

    davincix_cache_current "$dest"
    if [ "$video" = "1" ]; then
        davincix_set_video "$dest" "$monitors"
    else
        davincix_set_image "$dest" "$monitors" "$transition"
    fi
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
    pkill -f "$DIR/providers/" 2>/dev/null || true
    pkill -f "$DIR/search.sh" 2>/dev/null || true
}

# ── search: run a source search (stops the previous one and clears its cache) ─
# --continue: keeps the cache and resumes from the source cursor (load more).
# --source: ddg (default) | wallhaven.
# --clear: stops the search and drops the cache (called when the picker closes).
cmd_search() {
    if [ "${1:-}" = "--clear" ]; then
        cmd_stop
        rm -rf "${DAVINCIX_SEARCH_DIR:?}"/* 2>/dev/null || true
        rm -f "$DAVINCIX_MAP_FILE" "$DAVINCIX_SOURCE_FILE" 2>/dev/null || true
        rm -rf "$DAVINCIX_CURSOR_DIR" 2>/dev/null || true
        return 0
    fi

    local continue=0 source="" query=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --continue) continue=1; shift ;;
            --source) source="${2:-}"; shift 2 ;;
            *) query="$1"; shift ;;
        esac
    done
    [ -n "$query" ] || usage

    cmd_stop
    sleep 0.2

    if [ "$continue" = "1" ]; then
        [ -n "$source" ] || source="$(cat "$DAVINCIX_SOURCE_FILE" 2>/dev/null)"
        [ -n "$source" ] || source="ddg"
    else
        [ -n "$source" ] || source="ddg"
        rm -rf "${DAVINCIX_SEARCH_DIR:?}"/* 2>/dev/null || true
        rm -f "$DAVINCIX_MAP_FILE" 2>/dev/null || true
        rm -rf "$DAVINCIX_CURSOR_DIR" 2>/dev/null || true
        echo "$source" > "$DAVINCIX_SOURCE_FILE"
    fi

    echo 'run' > "$DAVINCIX_CONTROL_FILE"
    local args=( "$query" --source "$source" )
    [ "$continue" = "1" ] && args+=( --continue )
    nohup bash "$DIR/search.sh" "${args[@]}" >/dev/null 2>&1 &
}

# ── rm: move a wallpaper to the trash (and drop its thumbnail + manifest) ─────
cmd_rm() {
    local name="${1:-}"
    [ -n "$name" ] || usage
    name="$(basename "$name")"

    local target="$DAVINCIX_WALLPAPER_DIR/$name"
    if [ ! -f "$target" ]; then
        notify-send "Wallpaper Error" "Not found: $name" -u critical -t 5000
        exit 1
    fi

    # Papelera vía gio (gvfs); fallback: borrado directo.
    if ! gio trash "$target" 2>/dev/null; then
        rm -f "$target"
    fi

    rm -f "$DAVINCIX_THUMB_DIR/$name" "$DAVINCIX_THUMB_DIR/000_$name"
    sed -i "/^${name}$/d;/^000_${name}$/d" "$DAVINCIX_MANIFEST" 2>/dev/null || true

    notify-send "Wallpaper" "Moved to trash: $name" -t 2000
}

# ── import: copy files into the wallpaper dir and refresh thumbnails ──────────
cmd_import() {
    local imported=0
    while [ $# -gt 0 ]; do
        local src="$1"; shift
        [ -f "$src" ] || continue

        local base dest candidate=0
        base="$(basename "$src")"
        dest="$DAVINCIX_WALLPAPER_DIR/$base"
        while [ -e "$dest" ]; do
            candidate=$((candidate + 1))
            dest="$DAVINCIX_WALLPAPER_DIR/${base%.*}-${candidate}.${base##*.}"
        done

        if cp "$src" "$dest"; then
            imported=$((imported + 1))
        fi
    done

    [ "$imported" -gt 0 ] || { notify-send "Wallpaper Error" "No files imported" -u critical -t 5000; exit 1; }

    source "$DIR/thumbs.sh"
    davincix_thumbs_prep

    notify-send "Wallpaper" "Imported ${imported} file(s)" -t 2000
}

# ── slideshow: start/stop/status of the rotation daemon ───────────────────────
cmd_slideshow() {
    bash "$DIR/slideshow.sh" "$@"
}

# ── keys: provider API keys (free) stored in keys.conf ────────────────────────
#   keys         → human status
#   keys list    → machine status: NAME|label|where|0/1 (consumed by the UI)
#   keys set NAME VALUE
cmd_keys() {
    local action="${1:-}" name="${2:-}" value="${3:-}"
    local conf="$DAVINCIX_STATE_DIR/keys.conf"

    key_value() {
        local k="$1" v=""
        [ -f "$conf" ] && v="$(grep "^${k}=" "$conf" 2>/dev/null | head -n1 | cut -d= -f2-)"
        [ -n "$v" ] || v="${!k:-}"
        printf '%s' "$v"
    }

    if [ "$action" = "set" ]; then
        [ -n "$name" ] && [ -n "$value" ] || usage
        local entry known=0
        for entry in "${DAVINCIX_KEYED_KEYS[@]}"; do
            [ "${entry%%|*}" = "$name" ] && known=1
        done
        if [ "$known" != "1" ]; then
            echo "davincix: unknown key: $name" >&2
            exit 2
        fi
        touch "$conf" && chmod 600 "$conf"
        if grep -q "^${name}=" "$conf" 2>/dev/null; then
            sed -i "s|^${name}=.*|${name}=${value}|" "$conf"
        else
            echo "${name}=${value}" >> "$conf"
        fi
        echo "saved ${name} in ${conf}"
        return 0
    fi

    if [ "$action" = "list" ]; then
        local entry label where
        for entry in "${DAVINCIX_KEYED_KEYS[@]}"; do
            IFS='|' read -r name label where <<< "$entry"
            if [ -n "$(key_value "$name")" ]; then
                printf '%s|%s|%s|1\n' "$name" "$label" "$where"
            else
                printf '%s|%s|%s|0\n' "$name" "$label" "$where"
            fi
        done
        return 0
    fi

    printf 'keys file: %s\n' "$conf"
    local label where v
    for entry in "${DAVINCIX_KEYED_KEYS[@]}"; do
        IFS='|' read -r name label where <<< "$entry"
        v="$(key_value "$name")"
        if [ -n "$v" ]; then
            printf '%-12s = %s...%s (set)\n' "$name" "${v:0:4}" "${v: -4}"
        else
            printf '%-12s = (not set) — free at %s\n' "$name" "$where"
        fi
    done
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
    rm) cmd_rm "$@" ;;
    import) cmd_import "$@" ;;
    slideshow) cmd_slideshow "$@" ;;
    keys) cmd_keys "$@" ;;
    paths) cmd_paths "$@" ;;
    --version|-v|version) echo "davincix $DAVINCIX_VERSION" ;;
    *) usage ;;
esac
