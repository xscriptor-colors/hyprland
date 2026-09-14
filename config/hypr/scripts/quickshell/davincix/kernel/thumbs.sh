#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# davincix · kernel — thumbnails
#
# Builds and maintains the picker's thumbnail cache:
#   - webp → jpg (ImageMagick)
#   - video poster (ffmpeg, frame at ~5s or the middle for short clips)
#   - manifest (.manifest) + source-dir marker (.source_dir)
#   - orphan cleanup when the source dir changes or files are deleted
# Runs in the background; a lock prevents duplicate runs.
# ═══════════════════════════════════════════════════════════════════════════

# Rebuild the manifest from whatever is in the thumbnail directory.
davincix_build_manifest() {
    find "$DAVINCIX_THUMB_DIR" -maxdepth 1 -type f \
        ! -name '.source_dir' ! -name '.manifest' \
        -printf "%f\n" | sort > "$DAVINCIX_MANIFEST"
}

# Prepare thumbnails (async: returns immediately).
davincix_thumbs_prep() {
    mkdir -p "$DAVINCIX_THUMB_DIR"

    (
        # Atomic lock: flock releases itself when this subshell exits, so a
        # prep killed mid-run can never leave a stale lock that skips future
        # runs (the old PID-file check could: a reused PID looks alive).
        exec 9>"$DAVINCIX_PREP_LOCK"
        flock -n 9 || exit 0

        # The body works with these names; they are exported to reuse the
        # original logic as-is.
        export THUMB_DIR="$DAVINCIX_THUMB_DIR" SRC_DIR="$DAVINCIX_WALLPAPER_DIR" \
               MANIFEST="$DAVINCIX_MANIFEST" MAGICK_THREAD_LIMIT=1

        THUMB_SOURCE_FILE="$THUMB_DIR/.source_dir"
        if [ -f "$THUMB_SOURCE_FILE" ]; then
            read -r CACHED_SRC < "$THUMB_SOURCE_FILE"
            if [ "$CACHED_SRC" != "$SRC_DIR" ]; then
                find "$THUMB_DIR" -maxdepth 1 -type f \
                    ! -name '.source_dir' ! -name '.manifest' -delete
                echo "$SRC_DIR" > "$THUMB_SOURCE_FILE"
                > "$MANIFEST"
            fi
        else
            echo "$SRC_DIR" > "$THUMB_SOURCE_FILE"
            > "$MANIFEST"
        fi

        [ ! -f "$MANIFEST" ] && davincix_build_manifest

        SRC_LIST=$(mktemp)
        find "$SRC_DIR" -maxdepth 1 -type f \
            \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \
               -o -iname "*.gif" -o -iname "*.mp4" -o -iname "*.mkv" \
               -o -iname "*.mov" -o -iname "*.webm" \) \
            -printf "%f\n" | sort > "$SRC_LIST"

        # Orphans: in the manifest but no longer in the source dir.
        comm -23 <(sed 's/^000_//' "$MANIFEST" | sort) "$SRC_LIST" | while read -r orphan; do
            rm -f "$THUMB_DIR/$orphan" "$THUMB_DIR/000_$orphan"
            sed -i "/^${orphan}$/d;/^000_${orphan}$/d" "$MANIFEST"
        done

        # Pending: in the source dir but not in the manifest yet.
        while IFS= read -r filename; do
            img="$SRC_DIR/$filename"
            [ -f "$img" ] || continue

            extension="${filename##*.}"

            if [[ "${extension,,}" == "webp" ]]; then
                new_img="${img%.*}.jpg"
                if magick "$img" "$new_img"; then
                    rm -f "$img"
                    img="$new_img"
                    filename="$(basename "$img")"
                    extension="jpg"
                else
                    continue
                fi
            fi

            if [[ "${extension,,}" =~ ^(mp4|mkv|mov|webm)$ ]]; then
                thumb="$THUMB_DIR/000_$filename"
                [ -f "$THUMB_DIR/$filename" ] && rm -f "$THUMB_DIR/$filename"
                if [ ! -f "$thumb" ]; then
                    thumb_offset="00:00:05"
                    if command -v ffprobe >/dev/null 2>&1; then
                        v_dur=$(ffprobe -v error -show_entries format=duration \
                            -of default=nw=1:nk=1 -- "$img" 2>/dev/null)
                        if [ -n "$v_dur" ]; then
                            seek_pt=$(awk -v d="$v_dur" 'BEGIN { s = (d < 6.5) ? d / 2 : 5; if (s < 0) s = 0; printf "%.0f", s }')
                            thumb_offset=$(printf "%02d:%02d:%02d" \
                                $((seek_pt / 3600)) $(((seek_pt % 3600) / 60)) $((seek_pt % 60)))
                        fi
                    fi
                    ffmpeg -y -ss "$thumb_offset" -i "$img" -vframes 1 \
                        -threads 1 -f image2 -q:v 2 "$thumb" >/dev/null 2>&1
                    [ -f "$thumb" ] && echo "000_$filename" >> "$MANIFEST"
                fi
            else
                thumb="$THUMB_DIR/$filename"
                if [ ! -f "$thumb" ]; then
                    magick "$img" -resize x420 -quality 70 "$thumb" \
                        && echo "$filename" >> "$MANIFEST"
                fi
            fi
        done < <(comm -23 "$SRC_LIST" <(sed 's/^000_//' "$MANIFEST" | sort))

        rm -f "$SRC_LIST"
    ) </dev/null >/dev/null 2>&1 &
}
