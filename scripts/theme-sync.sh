#!/usr/bin/env bash
# Sync the kitty themes to the active palette (source of truth: dock/palettes).
#
# Regenerates ALL kitty theme files (~/.config/kitty/themes/<slug>.conf) from
# dock/palettes/*.json, switches kitty.conf to the active palette
# (settings.json -> dock.palette) and syncs active_border_color to the palette
# accent. Kitty reloads kitty.conf automatically on change.
#
# nvim is intentionally NOT touched (keeps its own upstream config).
# No Matugen involved. Safe to re-run at any time.

set -e

HOME_DIR="${HOME:-$HOME}"
SETTINGS="$HOME_DIR/.config/hypr/settings.json"
PALETTES="$HOME_DIR/.config/hypr/scripts/quickshell/dock/palettes"
THEMES_DIR="$HOME_DIR/.config/kitty/themes"

SLUG="$(jq -r '.dock.palette // "x"' "$SETTINGS" 2>/dev/null || echo "x")"

mkdir -p "$THEMES_DIR"

# Regenerate every kitty theme from the dock palettes (single source of truth).
python3 - "$PALETTES" "$THEMES_DIR" << 'PYEOF'
import json, pathlib, sys

palettes_dir = pathlib.Path(sys.argv[1])
themes_dir = pathlib.Path(sys.argv[2])

slugs = []
for pal_file in sorted(palettes_dir.glob("*.json")):
    if pal_file.name == "index.json":
        continue
    pal = json.load(open(pal_file))
    slug = pal.get("slug") or pal_file.stem
    b = pal.get("base16", {}) or {}
    bg = pal.get("background") or b.get("color0", "#000000")
    fg = pal.get("foreground") or b.get("color7", "#ffffff")
    lines = []
    for i in range(16):
        lines.append("color%-2d  %s" % (i, b.get("color%d" % i, "#000000")))
    lines.append("background %s" % bg)
    lines.append("foreground %s" % fg)
    lines.append("cursor %s" % fg)
    (themes_dir / (slug + ".conf")).write_text("\n".join(lines) + "\n")
    slugs.append(slug)

# Remove stale theme files no longer in the palette set (e.g. seul).
for stale in themes_dir.glob("*.conf"):
    if stale.stem not in slugs:
        stale.unlink(missing_ok=True)

print("kitty themes regenerated from dock/palettes: %d" % len(slugs))
PYEOF

# Switch kitty.conf to the active palette + accent border color.
# Only these two (plus the stale current-theme.conf include) are ever touched:
# every other kitty.conf setting (shaders, window decorations, fonts, binds)
# is left untouched.
KITTY_CONF="$HOME_DIR/.config/kitty/kitty.conf"
if [ -f "$KITTY_CONF" ]; then
    # Drop the legacy "current-theme.conf" include (old installer pattern).
    sed -i -E '/^include[[:space:]]+current-theme\.conf/d' "$KITTY_CONF"

    if ! grep -qE '^include[[:space:]]+themes/' "$KITTY_CONF"; then
        printf '\ninclude themes/%s.conf\n' "$SLUG" >> "$KITTY_CONF"
    else
        sed -i -E "s|^include[[:space:]]+themes/.*\.conf|include themes/$SLUG.conf|" "$KITTY_CONF"
    fi

    ACCENT="$(jq -r '.base16.color1 // "#fc618d"' "$PALETTES/$SLUG.json" 2>/dev/null || echo "#fc618d")"
    [ "${ACCENT:0:1}" = "#" ] || ACCENT="#$ACCENT"
    if grep -qE '^active_border_color' "$KITTY_CONF"; then
        sed -i -E "s|^active_border_color.*|active_border_color $ACCENT|" "$KITTY_CONF"
    else
        printf 'active_border_color %s\n' "$ACCENT" >> "$KITTY_CONF"
    fi
    echo "kitty theme → '$SLUG' (border $ACCENT)"
fi
