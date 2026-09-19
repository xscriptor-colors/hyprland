#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# init.sh — primera ejecución: elige un wallpaper al azar y lo aplica.
#
# Aplicar (y cachear la imagen para lock/SDDM) vive en la capa lib/ del
# subsistema de wallpapers (davincix); aquí solo se decide CUÁL aplicar.
# El flag de estado evita repetir la elección en cada arranque.
# ═══════════════════════════════════════════════════════════════════════════

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/quickshell/davincix/kernel/paths.sh"

FLAG="$DAVINCIX_STATE_DIR/wallpaper_initialized"

# Si el flag existe, el wallpaper ya se aplicó; nada que hacer.
if [ -f "$FLAG" ]; then
    exit 0
fi

sleep 0.5

# Un archivo al azar del directorio de wallpapers.
file=$(find "$DAVINCIX_WALLPAPER_DIR" -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) 2>/dev/null | shuf -n 1)

if [ -n "$file" ]; then
    bash "$DIR/quickshell/davincix/kernel/davincix.sh" set "$file" --transition any
fi

mkdir -p "$(dirname "$FLAG")"
touch "$FLAG"
