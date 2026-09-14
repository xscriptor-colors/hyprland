#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# davincix · kernel — paths
#
# Resolves every path of the wallpaper subsystem and exports it. There is no
# shell dependency: the defaults reproduce the current desktop layout
# (~/.cache/quickshell/wallpaper_picker, ...) so existing contracts keep
# working (Lock.qml, sddm-colors.sh, init.sh), and they can be overridden
# through the environment, which is what will allow extracting davincix as a
# standalone tool.
#
# Overrides:
#   DAVINCIX_WALLPAPER_DIR   wallpaper source dir      (legacy WALLPAPER_DIR)
#   DAVINCIX_CACHE_DIR       cache (thumbs, current, search)
#   DAVINCIX_STATE_DIR       persistent state (flags)
#   DAVINCIX_RUN_DIR         runtime (search control, locks, logs)
#   DAVINCIX_LOG_DIR         logs (defaults to run/logs)
# ═══════════════════════════════════════════════════════════════════════════

DAVINCIX_WALLPAPER_DIR="${DAVINCIX_WALLPAPER_DIR:-${WALLPAPER_DIR:-$HOME/.config/hypr/wallpapers}}"
DAVINCIX_CACHE_DIR="${DAVINCIX_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/wallpaper_picker}"
DAVINCIX_STATE_DIR="${DAVINCIX_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/wallpaper_picker}"
DAVINCIX_RUN_DIR="${DAVINCIX_RUN_DIR:-${XDG_RUNTIME_DIR:-/tmp}/quickshell/wallpaper_picker}"
DAVINCIX_LOG_DIR="${DAVINCIX_LOG_DIR:-${XDG_RUNTIME_DIR:-/tmp}/quickshell/logs}"

# Derived paths (subsystem contracts).
DAVINCIX_THUMB_DIR="$DAVINCIX_CACHE_DIR/thumbs"
DAVINCIX_SEARCH_DIR="$DAVINCIX_CACHE_DIR/search_thumbs"
DAVINCIX_DOWNLOAD_DIR="$DAVINCIX_CACHE_DIR/downloads"
DAVINCIX_MAP_FILE="$DAVINCIX_CACHE_DIR/search_map.txt"
DAVINCIX_CONTROL_FILE="$DAVINCIX_RUN_DIR/ddg_search_control"
DAVINCIX_NEXT_FILE="$DAVINCIX_RUN_DIR/ddg_next_url"
DAVINCIX_SLIDESHOW_PID="$DAVINCIX_RUN_DIR/slideshow.pid"
DAVINCIX_SLIDESHOW_FLAG="$DAVINCIX_STATE_DIR/slideshow_enabled"
DAVINCIX_CURRENT_IMG="$DAVINCIX_CACHE_DIR/current_wallpaper.png"
DAVINCIX_PREP_LOCK="$DAVINCIX_RUN_DIR/wallpaper_prep.lock"
DAVINCIX_MANIFEST="$DAVINCIX_THUMB_DIR/.manifest"
DAVINCIX_LOG_FILE="$DAVINCIX_LOG_DIR/awww_debug.log"

davincix_ensure_dirs() {
    mkdir -p "$DAVINCIX_CACHE_DIR" "$DAVINCIX_STATE_DIR" "$DAVINCIX_RUN_DIR" \
             "$DAVINCIX_LOG_DIR" "$DAVINCIX_THUMB_DIR" "$DAVINCIX_SEARCH_DIR" \
             "$DAVINCIX_DOWNLOAD_DIR"
}

export DAVINCIX_WALLPAPER_DIR DAVINCIX_CACHE_DIR DAVINCIX_STATE_DIR DAVINCIX_RUN_DIR \
       DAVINCIX_LOG_DIR DAVINCIX_THUMB_DIR DAVINCIX_SEARCH_DIR DAVINCIX_DOWNLOAD_DIR \
       DAVINCIX_MAP_FILE DAVINCIX_CONTROL_FILE DAVINCIX_NEXT_FILE \
       DAVINCIX_SLIDESHOW_PID DAVINCIX_SLIDESHOW_FLAG \
       DAVINCIX_CURRENT_IMG DAVINCIX_PREP_LOCK \
       DAVINCIX_MANIFEST DAVINCIX_LOG_FILE
