#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# davincix · kernel — online search (DuckDuckGo)
#
# Orchestrates the providers (providers/<source>.py): it receives "thumb|full" pairs on
# stdout, validates the full URL content-type, downloads the thumbnail,
# converts it when it is webp and records it in search_map.txt (name|url).
# It honors the run/pause/stop control file (written by the UI).
# ═══════════════════════════════════════════════════════════════════════════

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/paths.sh"
davincix_ensure_dirs

QUERY="${1:-}"
if [ -z "$QUERY" ]; then
    echo "usage: search.sh <query> [--continue] [--source ddg|wallhaven]" >&2
    exit 2
fi
shift

CONTINUE=0
SOURCE="ddg"
while [ $# -gt 0 ]; do
    case "$1" in
        --continue) CONTINUE=1; shift ;;
        --source) SOURCE="${2:-ddg}"; shift 2 ;;
        *) shift ;;
    esac
done

PROVIDER="$DIR/providers/$SOURCE.py"
if [ ! -f "$PROVIDER" ]; then
    echo "unknown search provider: $SOURCE" >&2
    exit 2
fi

# API keys para proveedores que las necesitan (Pexels, Pixabay...).
KEYS_FILE="$DAVINCIX_STATE_DIR/keys.conf"
if [ -f "$KEYS_FILE" ]; then
    set -a
    . "$KEYS_FILE"
    set +a
fi

SEARCH_DIR="$DAVINCIX_SEARCH_DIR"
MAP_FILE="$DAVINCIX_MAP_FILE"
CONTROL_FILE="$DAVINCIX_CONTROL_FILE"
CURSOR_FILE="$DAVINCIX_CURSOR_DIR/$SOURCE"
LOG_FILE="$DAVINCIX_LOG_DIR/search_downloader.log"

echo "=== Starting $SOURCE search for: $QUERY (continue=$CONTINUE) ===" > "$LOG_FILE"

mkdir -p "$SEARCH_DIR" "$DAVINCIX_CURSOR_DIR"

# The provider → shell pipe delivers the links; the shell applies backpressure.
python3 -u "$PROVIDER" "$QUERY" \
    $([ "$CONTINUE" = "1" ] && echo "--continue") \
    --cursor-file "$CURSOR_FILE" | while IFS='|' read -r thumb_url full_url; do

    state=$(cat "$CONTROL_FILE" 2>/dev/null | tr -d '[:space:]')

    if [[ "$state" == "stop" ]]; then
        echo "Stop signal received. Exiting." >> "$LOG_FILE"
        exit 0
    fi

    while [[ "$state" == "pause" ]]; do
        sleep 1
        state=$(cat "$CONTROL_FILE" 2>/dev/null | tr -d '[:space:]')
    done

    if [ -z "$thumb_url" ] || [ -z "$full_url" ]; then continue; fi

    # Pre-flight: the full URL must be an image (drops dead URLs/HTML).
    target_headers=$(curl -s -I -L -m 3 -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" "$full_url")
    target_type=$(echo "$target_headers" | grep -i "content-type:" | tail -n 1 | tr -d '\r')

    # Se aceptan imágenes y vídeos: para vídeo, el archivo guardado es el
    # preview (miniatura) y el contenedor se resuelve al aplicar (fetch).
    if [[ ! "$target_type" =~ (image|video)/ ]]; then
        echo "Skip: Full URL is dead or HTML ($target_type) -> $full_url" >> "$LOG_FILE"
        continue
    fi

    uuid=$(date +%s%N)
    # El archivo almacenado es siempre una imagen: la extensión sale del thumb.
    ext="${thumb_url##*.}"
    ext="${ext%%\?*}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    if [[ ! "$ext" =~ ^(jpg|jpeg|png|webp|gif)$ ]]; then ext="jpg"; fi

    is_webp=0
    if [[ "$ext" == "webp" ]]; then
        is_webp=1
        ext="jpg"
    fi

    filename="web_${uuid}.${ext}"
    filepath="$SEARCH_DIR/$filename"
    tmppath="${filepath}.tmp"

    echo "Downloading Thumb: $thumb_url -> $filename" >> "$LOG_FILE"

    curl -s -L -m 5 -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" "$thumb_url" -o "$tmppath"

    # Re-check the state after the download block.
    state=$(cat "$CONTROL_FILE" 2>/dev/null | tr -d '[:space:]')
    if [[ "$state" == "stop" ]]; then
        echo "Stop signal received during download. Discarding." >> "$LOG_FILE"
        rm -f "$tmppath"
        exit 0
    fi

    if [ -s "$tmppath" ]; then
        actual_mime=$(file -b --mime-type "$tmppath")

        if [[ ! "$actual_mime" =~ ^image/ ]]; then
            echo "ERROR: Thumb is not an image ($actual_mime). Discarding." >> "$LOG_FILE"
            rm -f "$tmppath"
        else
            if [[ "$actual_mime" == "image/webp" ]] || [ $is_webp -eq 1 ]; then
                magick "$tmppath" "$filepath" 2>/dev/null || mv "$tmppath" "$filepath"
                rm -f "$tmppath"
            else
                mv "$tmppath" "$filepath"
            fi
            echo "$filename|$full_url" >> "$MAP_FILE"
            echo "Success: $filename saved." >> "$LOG_FILE"
        fi
    else
        echo "ERROR: Failed or empty download for $thumb_url" >> "$LOG_FILE"
        rm -f "$tmppath"
    fi
done

echo "=== Pipeline finished ===" >> "$LOG_FILE"
