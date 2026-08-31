#!/usr/bin/env bash
# Sync kitty + starship to the active palette (source of truth: dock/palettes).
#
# - kitty   : regenerates ALL theme files (~/.config/kitty/themes/<slug>.conf)
#             from dock/palettes/*.json and switches kitty.conf to the active
#             palette + accent border. Kitty reloads on config change.
# - starship: writes [palettes.<slug>] sections into the active starship
#             config (STARSHIP_CONFIG from fish config) and sets the active
#             palette, so the prompt follows the bar.
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

# ── starship (xscriptor themes used by zsh) ───────────────────────────────────────
# The per-palette theme files (~/.config/xscriptor/starship/themes/<slug>.toml)
# come from xscriptor-colors/terminal prompts/starship/themes. We regenerate
# them from dock/palettes (single source of truth) and point zsh's
# STARSHIP_CONFIG at the active theme.
XSC_THEMES="$HOME_DIR/.config/xscriptor/starship/themes"
if [ -d "$XSC_THEMES" ] && [ -f "$XSC_THEMES/x.toml" ]; then
    python3 - "$PALETTES" "$XSC_THEMES" << 'PYEOF'
import json, pathlib, sys

palettes_dir = pathlib.Path(sys.argv[1])
themes_dir = pathlib.Path(sys.argv[2])

# x.toml is the structural template; its hardcoded hexes map to palette roles.
template = (themes_dir / "x.toml").read_text()
ROLES = {
    "#363537": "color0", "#fc618d": "color1", "#7bd88f": "color2",
    "#fce566": "color3", "#948ae3": "color5", "#5ad4e6": "color6",
    "#f7f1ff": "color7", "#69676c": "color8",
}

slugs = []
for pal_file in sorted(palettes_dir.glob("*.json")):
    if pal_file.name == "index.json":
        continue
    pal = json.load(open(pal_file))
    slug = pal.get("slug") or pal_file.stem
    b = pal.get("base16", {}) or {}
    out = template
    for hexv, role in ROLES.items():
        out = out.replace(hexv, b.get(role, hexv))
    (themes_dir / (slug + ".toml")).write_text(out)
    slugs.append(slug)

# Remove stale themes no longer in the palette set (e.g. seul).
for stale in themes_dir.glob("*.toml"):
    if stale.stem not in slugs:
        stale.unlink(missing_ok=True)
print("starship themes regenerated from dock/palettes: %d" % len(slugs))
PYEOF

    # Point zsh's STARSHIP_CONFIG at the active theme (applies next shell start).
    ZSHRC="$HOME_DIR/.zshrc"
    ACTIVE_THEME="$XSC_THEMES/$SLUG.toml"
    if [ -f "$ZSHRC" ] && [ -f "$ACTIVE_THEME" ]; then
        if grep -q '^export STARSHIP_CONFIG=' "$ZSHRC"; then
            sed -i -E "s|^export STARSHIP_CONFIG=.*|export STARSHIP_CONFIG=\"$ACTIVE_THEME\"|" "$ZSHRC"
        else
            printf 'export STARSHIP_CONFIG="%s"\n' "$ACTIVE_THEME" >> "$ZSHRC"
        fi
        echo "starship (zsh) → '$SLUG'"
    fi
fi

# ── VS Code ───────────────────────────────────────────────────────────────────────
# The xscriptor-themes extension ships one color theme AND one icon theme per
# palette (id "<slug>-icons"), plus a single product icon theme ("x"). Update
# workbench.colorTheme + workbench.iconTheme in the settings.json of every
# installed VS Code variant (Code and Code - Insiders) — VS Code applies live.
case "$SLUG" in
    x)      VSCODE_THEME="X" ;;
    bogota) VSCODE_THEME="Bogotá" ;;
    *)      VSCODE_THEME="$(printf '%s' "${SLUG:0:1}" | tr '[:lower:]' '[:upper:]')${SLUG:1}" ;;
esac
VSCODE_ICONS="${SLUG}-icons"
for VSCODE_SETTINGS in "$HOME_DIR/.config/Code/User/settings.json" "$HOME_DIR/.config/Code - Insiders/User/settings.json"; do
    if [ -f "$VSCODE_SETTINGS" ]; then
        if grep -q '"workbench.colorTheme"' "$VSCODE_SETTINGS"; then
            sed -i -E "s|\"workbench.colorTheme\":[^,}]*|\"workbench.colorTheme\": \"$VSCODE_THEME\"|" "$VSCODE_SETTINGS"
        else
            sed -i "s|^{|{\n    \"workbench.colorTheme\": \"$VSCODE_THEME\",|" "$VSCODE_SETTINGS"
        fi
        if grep -q '"workbench.iconTheme"' "$VSCODE_SETTINGS"; then
            sed -i -E "s|\"workbench.iconTheme\":[^,}]*|\"workbench.iconTheme\": \"$VSCODE_ICONS\"|" "$VSCODE_SETTINGS"
        else
            sed -i "s|^{|{\n    \"workbench.iconTheme\": \"$VSCODE_ICONS\",|" "$VSCODE_SETTINGS"
        fi
        echo "vscode ($(basename "$(dirname "$(dirname "$VSCODE_SETTINGS")")")) → color '$VSCODE_THEME', icons '$VSCODE_ICONS'"
    fi
done

# ── nvim ──────────────────────────────────────────────────────────────────────────
# The nvim config (plugins, keymaps, options) comes from the user's own repo
# (cloned to ~/.config/nvim). We only regenerate the PALETTE DATA
# (lua/themes/palettes.lua) and the active-theme bootstrap (lua/config/theme.lua)
# from dock/palettes so nvim follows the panel. Everything else stays untouched.
NVIM_DIR="$HOME_DIR/.config/nvim"
if [ -d "$NVIM_DIR/lua/themes" ] && [ -d "$NVIM_DIR/lua/config" ]; then
    python3 - "$PALETTES" "$NVIM_DIR" "$SLUG" << 'PYEOF'
import json, pathlib, sys

palettes_dir = pathlib.Path(sys.argv[1])
nvim_dir = pathlib.Path(sys.argv[2])
active = sys.argv[3]

entries = []
for pal_file in sorted(palettes_dir.glob("*.json")):
    if pal_file.name == "index.json":
        continue
    pal = json.load(open(pal_file))
    slug = pal.get("slug") or pal_file.stem
    b = pal.get("base16", {}) or {}
    bg = pal.get("background") or b.get("color0", "#000000")
    fg = pal.get("foreground") or b.get("color7", "#ffffff")
    lines = ["  %s = {" % slug]
    for i in range(16):
        lines.append('    color%d = "%s",' % (i, b.get("color%d" % i, "#000000")))
    lines.append('    background = "%s",' % bg)
    lines.append('    foreground = "%s",' % fg)
    lines.append("  },")
    entries.append("\n".join(lines))

palettes_lua = "local M = {\n" + "\n".join(entries) + "\n}\n\n"
palettes_lua += '''function M.strip_alpha(hex)
  if #hex == 9 then
    return hex:sub(1, 7)
  end
  return hex
end

return M
'''
(nvim_dir / "lua/themes/palettes.lua").write_text(palettes_lua)

theme_lua = '''-- Auto-generated by theme-sync.sh — follows the active palette (dock/palettes).
-- The rest of the nvim config comes from the user's own repo.
local function current_palette()
  local home = vim.fn.expand("~")
  local f = io.popen('jq -r ".dock.palette // \\\\"x\\\\"" ' .. vim.fn.shellescape(home .. "/.config/hypr/settings.json") .. " 2>/dev/null")
  if not f then return "x" end
  local slug = f:read("*l")
  f:close()
  return (slug ~= "" and slug) or "x"
end
vim.g.theme = vim.g.theme or current_palette()
require("themes").apply(vim.g.theme)
'''
(nvim_dir / "lua/config/theme.lua").write_text(theme_lua)
print("nvim palettes regenerated from dock/palettes: %d → active '%s'" % (len(entries), active))
PYEOF
fi
