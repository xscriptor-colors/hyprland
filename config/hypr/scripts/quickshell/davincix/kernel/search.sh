#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# davincix · kernel — online search (DuckDuckGo)
#
# Orchestrates the scraper (ddg_links.py): it receives "thumb|full" pairs on
# stdout, validates the full URL content-type, downloads the thumbnail,
# converts it when it is webp and records it in search_map.txt (name|url).
# It honors the run/pause/stop control file (written by the UI).
# ═══════════════════════════════════════════════════════════════════════════

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/paths.sh"
davincix_ensure_dirs

QUERY="${1:-}"
if [ -z "$QUERY" ]; then
    echo "usage: search.sh <query> [--continue]" >&2
    exit 2
fi

CONTINUE=0
[ "${2:-}" = "--continue" ] && CONTINUE=1

SEARCH_DIR="$DAVINCIX_SEARCH_DIR"
MAP_FILE="$DAVINCIX_MAP_FILE"
CONTROL_FILE="$DAVINCIX_CONTROL_FILE"
LOG_FILE="$DAVINCIX_LOG_DIR/ddg_downloader.log"

echo "=== Starting search for: $QUERY (continue=$CONTINUE) ===" > "$LOG_FILE"

mkdir -p "$SEARCH_DIR"

# The Python → shell pipe provides the links; the shell applies backpressure.
python3 -u "$DIR/ddg_links.py" "$QUERY" \
    $([ "$CONTINUE" = "1" ] && echo "--continue") \
    --next-file "$DAVINCIX_NEXT_FILE" | while IFS='|' read -r thumb_url full_url; do

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

    if [[ ! "$target_type" =~ "image/" ]]; then
        echo "Skip: Full URL is dead or HTML ($target_type) -> $full_url" >> "$LOG_FILE"
        continue
    fi

    uuid=$(date +%s%N)
    ext="${full_url##*.}"
    ext="${ext%%\?*}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    if [[ ! "$ext" =~ ^(jpg|jpeg|png|webp|gif)$ ]]; then ext="jpg"; fi

    is_webp=0
    if [[ "$ext" == "webp" ]]; then
        is_webp=1
        ext="jpg"
    fi

    filename="ddg_${uuid}.${ext}"
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
