#!/usr/bin/env bash
# Generate the SDDM login theme Colors.qml from the active palette.
#
# Reads settings.json -> dock.palette, derives the 7 roles the SDDM theme
# uses (base, surface0, text, subtext0, mauve, blue, red) exactly like
# dock/Colors.qml does, and writes ~/.config/hypr/sddm-colors.qml. If the
# installed theme dir exists it also tries to update its Colors.qml.
#
# No Matugen involved. Safe to run at any time (cheap: jq + python3).

set -e

HOME_DIR="${HOME:-$HOME}"
SETTINGS="$HOME_DIR/.config/hypr/settings.json"
PALETTES="$HOME_DIR/.config/hypr/scripts/quickshell/dock/palettes"
OUT="$HOME_DIR/.config/hypr/sddm-colors.qml"

PALETTE="$(jq -r '.dock.palette // "x"' "$SETTINGS" 2>/dev/null || echo "x")"
PAL_JSON="$PALETTES/$PALETTE.json"
[ -f "$PAL_JSON" ] || PAL_JSON="$PALETTES/x.json"
[ -f "$PAL_JSON" ] || { echo "No palette found" >&2; exit 1; }

python3 - "$PAL_JSON" "$OUT" "$PALETTE" << 'PYEOF'
import json, sys

pal = json.load(open(sys.argv[1]))
out_path = sys.argv[2]
palette = sys.argv[3]
b = pal.get("base16", {}) or {}

def rgb(h):
    h = h.lstrip("#")
    return [int(h[i:i+2], 16) for i in (0, 2, 4)]

def tohex(c):
    return "#" + "".join("%02x" % max(0, min(255, round(v))) for v in c)

def mix(a, b_, t):
    return tohex([x + (y - x) * t for x, y in zip(rgb(a), rgb(b_))])

def color(k, default):
    v = b.get(k, default)
    return v if v.startswith("#") else "#" + v

base   = pal.get("background") or color("color0", "#363537")
text   = pal.get("foreground") or color("color7", "#f7f1ff")
roles  = pal.get("roles", {}) or {}

out = {
    "base":     base,
    "surface0": roles.get("surface0") or mix(base, text, 0.06),
    "text":     text,
    "subtext0": roles.get("subtext0") or mix(text, base, 0.20),
    "mauve":    roles.get("mauve") or color("color5", "#948ae3"),
    "blue":     roles.get("blue") or color("color6", "#5ad4e6"),
    "red":      roles.get("red") or color("color1", "#fc618d"),
}

# Dark/light flag so the theme can tint its backdrop accordingly
# (dark base -> thin dark overlay; light base -> stronger light tint).
def luminance(h):
    r, g, bl = rgb(h)
    return (0.2126 * r + 0.7152 * g + 0.0722 * bl) / 255.0

is_dark = luminance(base) < 0.5

lines = ["pragma Singleton", "import QtQuick", "QtObject {"]
for k, v in out.items():
    lines.append('    readonly property color %s: "%s"' % (k, v))
lines.append('    readonly property bool isDark: %s' % ("true" if is_dark else "false"))
lines.append("}")
open(out_path, "w").write("\n".join(lines) + "\n")
print("SDDM colors from palette '%s': base=%s mauve=%s blue=%s isDark=%s" % (palette, base, out["mauve"], out["blue"], is_dark))
PYEOF

# Sync into the installed theme dir if present. The dir is root-owned, so this
# needs sudo. Only attempt it from an INTERACTIVE terminal: silent sudo calls
# from reloads/theme-changes/dock fail PAM without a passwordless rule and trip
# pam_faillock, eventually locking sudo out until `faillock --reset`.
THEME="/usr/share/sddm/themes/x"
if [ -d "$THEME" ] && [ -t 0 ]; then
    if [ -w "$THEME" ]; then
        cp "$OUT" "$THEME/Colors.qml" 2>/dev/null || true
    else
        sudo cp "$OUT" "$THEME/Colors.qml" 2>/dev/null || true
    fi
fi

# Point the login background at the live wallpaper cache (dynamic: it updates
# automatically whenever the wallpaper changes). Falls back to the bundled
# wallpaper.jpg when the cache doesn't exist yet.
CACHE_WALL="$HOME/.cache/quickshell/wallpaper_picker/current_wallpaper.png"
THEME_CONF="$THEME/theme.conf"
if [ -f "$CACHE_WALL" ] && [ -f "$THEME_CONF" ] && [ -t 0 ]; then
    if [ -w "$THEME_CONF" ]; then
        sed -i "s|^background=.*|background=$CACHE_WALL|" "$THEME_CONF" 2>/dev/null || true
    else
        sudo sed -i "s|^background=.*|background=$CACHE_WALL|" "$THEME_CONF" 2>/dev/null || true
    fi
fi
