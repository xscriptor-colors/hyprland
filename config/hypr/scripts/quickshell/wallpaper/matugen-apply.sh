#!/usr/bin/env bash
# Apply Matugen to an image using the configured color scheme.
#
# Reads the scheme type from ~/.config/matugen/scheme (one of:
#   scheme-tonal-spot, scheme-vibrant, scheme-fidelity, scheme-fruit-salad,
#   scheme-neutral, scheme-rainbow, scheme-expressive, scheme-content,
#   scheme-monochrome)
# Defaults to scheme-fruit-salad (celeste tones instead of the tiring blue).
#
# Usage: matugen-apply.sh <image>

SCHEME="$(cat "$HOME/.config/matugen/scheme" 2>/dev/null || echo scheme-fruit-salad)"

case "$SCHEME" in
    scheme-content|scheme-expressive|scheme-fidelity|scheme-fruit-salad|scheme-monochrome|scheme-neutral|scheme-rainbow|scheme-tonal-spot|scheme-vibrant)
        ;;
    *)
        SCHEME="scheme-fruit-salad"
        ;;
esac

exec matugen image "$1" --source-color-index 0 -t "$SCHEME"
