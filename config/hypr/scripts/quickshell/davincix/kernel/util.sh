#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# davincix · kernel — shared helpers
#
# Logging and media-type detection used across the kernel modules.
# ═══════════════════════════════════════════════════════════════════════════

# Append a timestamped line to the subsystem log.
davincix_log() {
    echo "[$(date +'%H:%M:%S.%3N')] $*" >> "$DAVINCIX_LOG_FILE"
}

# True when $1 has a video extension.
davincix_is_video() {
    case "${1,,}" in
        *.mp4|*.mkv|*.mov|*.webm) return 0 ;;
        *) return 1 ;;
    esac
}
