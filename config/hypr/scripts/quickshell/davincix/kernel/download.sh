#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# davincix · kernel — download
#
# Downloads a URL to a destination file, converting webp when needed.
# ═══════════════════════════════════════════════════════════════════════════

# Download $1 into $2 (webp → converted in place).
davincix_download() {
    local url="$1" dest="$2" tmp="$2.tmp"
    curl -s -L -A "Mozilla/5.0" "$url" -o "$tmp" || return 1
    if file "$tmp" | grep -iq "webp"; then
        magick "$tmp" "$dest" && rm -f "$tmp"
    else
        mv "$tmp" "$dest"
    fi
}
