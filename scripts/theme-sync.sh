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
# La plantilla estructural es starship.toml (canónica, NUNCA se reescribe);
# themes/x.toml es un OUTPUT generado más, no el template.
XSC_TEMPLATE="$HOME_DIR/.config/xscriptor/starship/starship.toml"
if [ -d "$XSC_THEMES" ] && [ -f "$XSC_TEMPLATE" ]; then
    python3 - "$PALETTES" "$XSC_THEMES" "$XSC_TEMPLATE" << 'PYEOF'
import json, pathlib, sys

palettes_dir = pathlib.Path(sys.argv[1])
themes_dir = pathlib.Path(sys.argv[2])

# starship.toml (canónico) es la plantilla estructural; sus hex canónicos se
# mapean a roles de paleta. NUNCA se usa themes/x.toml como template: es un
# output generado y usarlo causaba corrupción auto-destructiva.
# NOTA: los darks estructurales del template (#2a2a2a/#141414/#0b0b0b) son
# fijos por diseño; solo los acentos/foreground se palettizan.
template = pathlib.Path(sys.argv[3]).read_text()
if not template.strip():
    # Plantilla vacía/corrupta: avisar y SALTAR starship sin abortar el script
    # (kitty ya está hecho; VS Code y nvim deben seguir procesándose).
    print("WARN: starship template is empty, skipping starship themes: " + sys.argv[3])
    raise SystemExit(0)
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

    # ── Archivo activo fijo (~/.config/starship.toml) ──────────────────────
    # Starship RELEE su config en cada prompt, así que un archivo fijo hace que
    # el cambio de paleta se aplique en el siguiente prompt de TODAS las shells
    # abiertas (mismo espíritu que el include de kitty.conf).
    # Casos:
    #   a) no existe            → se crea con marcador.
    #   b) existe con marcador  → se actualiza (nuestro archivo).
    #   c) existe SIN marcador  → config propia del usuario: NO se toca; se
    #      mantiene el cambio por STARSHIP_CONFIG (tema por slug) + aviso.
    STARSHIP_ACTIVE="$HOME_DIR/.config/starship.toml"
    STARSHIP_MARKER="# Auto-generated by theme-sync.sh (xscriptor-colors). Do not edit."
    ACTIVE_THEME="$XSC_THEMES/$SLUG.toml"
    STARSHIP_FIXED_OK=0
    if [ -f "$STARSHIP_ACTIVE" ] && ! grep -qF "$STARSHIP_MARKER" "$STARSHIP_ACTIVE"; then
        echo "starship: ~/.config/starship.toml es config propia; se conserva (STARSHIP_CONFIG por slug)"
    else
        TMP_ACTIVE="$(mktemp)"
        { printf '%s\n' "$STARSHIP_MARKER"; cat "$ACTIVE_THEME"; } > "$TMP_ACTIVE" \
            && mv "$TMP_ACTIVE" "$STARSHIP_ACTIVE"
        STARSHIP_FIXED_OK=1
        echo "starship active config → '$SLUG' (~/.config/starship.toml)"
    fi

    # Point the shell rc's STARSHIP_CONFIG at the right target (fixed file when
    # possible; per-slug theme only in the custom-config fallback). Never
    # clobber a custom export: only rewrite ours (xscriptor themes or the fixed
    # path). zsh + bash (the xscriptor installer supports both); fish uses the
    # default path anyway (fixed file), so it is intentionally left untouched.
    if [ "$STARSHIP_FIXED_OK" = "1" ]; then
        TARGET="$STARSHIP_ACTIVE"
    else
        TARGET="$ACTIVE_THEME"
    fi
    for RC in "$HOME_DIR/.zshrc" "$HOME_DIR/.bashrc"; do
        [ -f "$RC" ] && [ -f "$TARGET" ] || continue
        RC_NAME="$(basename "$RC")"
        if grep -q '^export STARSHIP_CONFIG=' "$RC"; then
            CUR="$(grep -m1 '^export STARSHIP_CONFIG=' "$RC" | sed -E 's/^[^=]*="?([^"]*)"?.*/\1/')"
            case "$CUR" in
                *"/xscriptor/starship/themes/"*)
                    sed -i -E "s|^export STARSHIP_CONFIG=.*|export STARSHIP_CONFIG=\"$TARGET\"|" "$RC"
                    echo "starship ($RC_NAME) → '$TARGET'"
                    ;;
                "$HOME_DIR/.config/starship.toml")
                    if [ "$STARSHIP_FIXED_OK" = "1" ]; then
                        echo "starship ($RC_NAME) → default ~/.config/starship.toml"
                    else
                        echo "starship: STARSHIP_CONFIG en $RC_NAME apunta a tu config propia; no se toca"
                    fi
                    ;;
                *)
                    echo "starship: STARSHIP_CONFIG custom detectado en $RC_NAME; no se toca ($CUR)"
                    ;;
            esac
        elif [ "$STARSHIP_FIXED_OK" != "1" ]; then
            printf 'export STARSHIP_CONFIG="%s"\n' "$TARGET" >> "$RC"
            echo "starship ($RC_NAME) → '$TARGET' (export añadido)"
        fi
        # Con archivo fijo OK y sin export no hace falta nada: el path por
        # defecto de starship ya es ~/.config/starship.toml.
    done
    if [ -f "$ZSHRC" ] && [ -f "$TARGET" ]; then
        if grep -q '^export STARSHIP_CONFIG=' "$ZSHRC"; then
            CUR="$(grep -m1 '^export STARSHIP_CONFIG=' "$ZSHRC" | sed -E 's/^[^=]*="?([^"]*)"?.*/\1/')"
            case "$CUR" in
                *"/xscriptor/starship/themes/"*)
                    sed -i -E "s|^export STARSHIP_CONFIG=.*|export STARSHIP_CONFIG=\"$TARGET\"|" "$ZSHRC"
                    echo "starship (zsh) → '$TARGET'"
                    ;;
                "$HOME_DIR/.config/starship.toml")
                    if [ "$STARSHIP_FIXED_OK" = "1" ]; then
                        echo "starship (zsh) → default ~/.config/starship.toml"
                    else
                        echo "starship: STARSHIP_CONFIG apunta a tu config propia; no se toca"
                    fi
                    ;;
                *)
                    echo "starship: STARSHIP_CONFIG custom detectado; no se toca ($CUR)"
                    ;;
            esac
        else
            if [ "$STARSHIP_FIXED_OK" != "1" ]; then
                printf 'export STARSHIP_CONFIG="%s"\n' "$TARGET" >> "$ZSHRC"
                echo "starship (zsh) → '$TARGET' (export añadido)"
            else
                echo "starship (zsh) → default ~/.config/starship.toml"
            fi
        fi
    fi
fi

# ── xtop (TUI system monitor) ─────────────────────────────────────────────────────
# Per-palette themes (~/.config/xtop/themes/<slug>.jsonc) regenerated from
# dock/palettes (single source of truth) + active theme switched with
# `xtop --ct <slug>` (persists; live instances follow on the next tick).
# Custom themes whose slug is NOT a palette are left untouched. A one-time
# snapshot of the pre-existing themes is kept in themes.bak.
XTOP_THEMES="$HOME_DIR/.config/xtop/themes"
if [ -d "$XTOP_THEMES" ]; then
    [ -d "$XTOP_THEMES.bak" ] || cp -r "$XTOP_THEMES" "$XTOP_THEMES.bak" 2>/dev/null || true
    python3 - "$PALETTES" "$XTOP_THEMES" << 'XTOP_PY'
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
    palette = [b.get("color%d" % i, bg) for i in range(16)]
    body = json.dumps({
        "name": slug,
        "background": bg,
        "foreground": fg,
        "palette": palette,
    }, indent=4)
    header = "// %s -- synced from dock/palettes/%s.json by theme-sync.sh\n" % (pal.get("name", slug), slug)
    (themes_dir / (slug + ".jsonc")).write_text(header + body + "\n")
    slugs.append(slug)

# Limpieza: solo temas generados por nosotros (cabecera "synced from
# dock/palettes") cuyo slug ya no sea paleta; los temas propios se conservan.
for stale in themes_dir.glob("*.jsonc"):
    if stale.stem in slugs:
        continue
    try:
        first = stale.read_text(errors="replace").splitlines()[0]
    except Exception:
        continue
    if "synced from dock/palettes/" in first:
        stale.unlink(missing_ok=True)

print("xtop themes regenerated from dock/palettes: %d" % len(slugs))
XTOP_PY

    # Switch the active theme (persists; live xtop instances follow next tick).
    if command -v xtop >/dev/null 2>&1 && [ -f "$XTOP_THEMES/$SLUG.jsonc" ]; then
        timeout 10 xtop --ct "$SLUG" >/dev/null 2>&1 && echo "xtop theme → '$SLUG'"
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

# ── Browsers (Brave / Brave Beta / Firefox) ───────────────────────────────────────
# Esquema claro/oscuro según la luminancia del fondo de la paleta activa:
#   - Brave/Beta: prefs de perfil (browser.theme.color_scheme2 1=light/2=dark,
#     follows_system_colors=false, user_color2=acento ARGB). SOLO si el canal
#     está cerrado: con el navegador abierto, sus prefs en memoria pisarían el
#     cambio al salir.
#   - Firefox: user.js (browser.theme.toolbar-theme/content-theme + ui.systemUsesDarkTheme).
#     Se lee al arrancar, así que es seguro escribirlo en caliente; se conserva
#     el resto del user.js del usuario.
# Sin perfiles (p.ej. Firefox recién instalado) → se salta sin error.
XSC_BROWSER_SCHEME=$(python3 - "$PALETTES/$SLUG.json" <<'XSC_SCHEME'
import json, sys
try:
    p = json.load(open(sys.argv[1]))
except Exception:
    print("dark"); raise SystemExit(0)
b = p.get("base16", {}) or {}
bg = p.get("background") or b.get("color0") or "#000000"
h = bg.lstrip("#")
try:
    r, g, bl = (int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4))
except Exception:
    print("dark"); raise SystemExit(0)
def lin(c):
    return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
L = 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(bl)
print("light" if L > 0.5 else "dark")
XSC_SCHEME
)
if [ "$XSC_BROWSER_SCHEME" = "light" ]; then
    XSC_SCHEME_INT=1
else
    XSC_SCHEME_INT=2
fi
XSC_ACCENT_HEX=$(jq -r '.base16.color5 // .base16.color1 // "#cba6f7"' "$PALETTES/$SLUG.json" 2>/dev/null || echo "#cba6f7")
XSC_ACCENT_INT=$(python3 -c "print(0xFF000000 | int('$XSC_ACCENT_HEX'.lstrip('#'), 16))" 2>/dev/null || echo 0)
# XSC_BR_BEGIN
for XSC_BROWSER_DIR in "$HOME_DIR/.config/BraveSoftware/Brave-Browser" "$HOME_DIR/.config/BraveSoftware/Brave-Browser-Beta"; do
    [ -d "$XSC_BROWSER_DIR" ] || continue
    if [ "$XSC_BROWSER_DIR" = "$HOME_DIR/.config/BraveSoftware/Brave-Browser" ]; then
        if pgrep -f "/opt/brave-bin/brave" >/dev/null 2>&1; then
            echo "brave: abierto; prefs de tema no tocados (aplica al cerrarlo y reiniciar)"
            continue
        fi
    else
        if pgrep -f "brave-browser-beta" >/dev/null 2>&1; then
            echo "brave-beta: abierto; prefs de tema no tocados"
            continue
        fi
    fi
    python3 - "$XSC_BROWSER_DIR" "$XSC_SCHEME_INT" "$XSC_ACCENT_INT" <<'XSC_BR'
import json, os, glob, sys
bdir, scheme, accent = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
changed = 0
for pref in glob.glob(os.path.join(bdir, "*", "Preferences")):
    base = os.path.basename(os.path.dirname(pref))
    if not (base == "Default" or base.startswith("Profile ")):
        continue
    try:
        d = json.load(open(pref, encoding="utf-8"))
    except Exception:
        continue
    theme = d.setdefault("browser", {}).setdefault("theme", {})
    theme["color_scheme2"] = scheme
    theme["follows_system_colors"] = False
    theme["user_color2"] = accent
    tmp = pref + ".xsc.tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(d, f, separators=(",", ":"))
    os.replace(tmp, pref)
    changed += 1
print("brave theme prefs updated: %d profile(s)" % changed)
XSC_BR
done
# XSC_BR_END

XSC_FF_DIR="$HOME_DIR/.mozilla/firefox"
if [ -d "$XSC_FF_DIR" ]; then
    python3 - "$XSC_FF_DIR" "$XSC_SCHEME_INT" <<'XSC_FF'
import configparser, glob, os, sys
ffdir, scheme = sys.argv[1], sys.argv[2]
profiles = []
ini = os.path.join(ffdir, "profiles.ini")
if os.path.isfile(ini):
    cp = configparser.ConfigParser()
    try:
        cp.read(ini)
        for sec in cp.sections():
            if sec.startswith("Profile") and cp.has_option(sec, "Path"):
                p = cp.get(sec, "Path")
                if cp.has_option(sec, "IsRelative") and cp.get(sec, "IsRelative") == "1":
                    p = os.path.join(ffdir, p)
                profiles.append(p)
    except Exception:
        pass
if not profiles:
    profiles = [os.path.dirname(p) for p in glob.glob(os.path.join(ffdir, "*", "prefs.js"))]
BEGIN = "// === xscriptor-colors theme-sync (managed) ==="
END = "// === end xscriptor-colors ==="
KEYS = ("browser.theme.toolbar-theme", "browser.theme.content-theme", "ui.systemUsesDarkTheme")
for prof in profiles:
    if not os.path.isdir(prof):
        continue
    uj = os.path.join(prof, "user.js")
    kept, inside = [], False
    if os.path.isfile(uj):
        for ln in open(uj, encoding="utf-8", errors="replace"):
            t = ln.strip()
            if t == BEGIN:
                inside = True
                continue
            if t == END:
                inside = False
                continue
            if inside:
                continue
            if any(k in ln for k in KEYS):
                continue
            kept.append(ln.rstrip("\n"))
    block = [BEGIN,
             'user_pref("browser.theme.toolbar-theme", %s);' % scheme,
             'user_pref("browser.theme.content-theme", %s);' % scheme,
             'user_pref("ui.systemUsesDarkTheme", %d);' % (1 if scheme == "2" else 0),
             END]
    out = "\n".join(kept + [""] + block) + "\n"
    tmp = uj + ".xsc.tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(out)
    os.replace(tmp, uj)
    print("firefox user.js updated: %s" % prof)
XSC_FF
else
    echo "firefox: sin perfiles (~/.mozilla/firefox no existe); se omite"
fi

# ── opencode (TUI) ────────────────────────────────────────────────────────────────
# Temas por paleta en ~/.config/opencode/themes/<slug>.json (defs base16 +
# estructurales derivados del fondo/foreground) y tema activo en tui.json
# (`theme`). Los temas custom cuyo slug NO sea una paleta se dejan intactos y
# se guarda un backup único en themes.bak. El TUI puede requerir reinicio para
# releer el tema.
XSC_OC_DIR="$HOME_DIR/.config/opencode"
if [ -d "$XSC_OC_DIR/themes" ]; then
    [ -d "$XSC_OC_DIR/themes.bak" ] || cp -r "$XSC_OC_DIR/themes" "$XSC_OC_DIR/themes.bak" 2>/dev/null || true
    python3 - "$PALETTES" "$XSC_OC_DIR/themes" <<'XSC_OC_PY'
import json, pathlib, sys

palettes_dir = pathlib.Path(sys.argv[1])
themes_dir = pathlib.Path(sys.argv[2])

def mix(a, b, t):
    ca = [int(a.lstrip("#")[i:i+2], 16) for i in (0, 2, 4)]
    cb = [int(b.lstrip("#")[i:i+2], 16) for i in (0, 2, 4)]
    return "#%02x%02x%02x" % tuple(round(ca[i] + (cb[i] - ca[i]) * t) for i in range(3))

slugs = []
for pf in sorted(palettes_dir.glob("*.json")):
    if pf.name == "index.json":
        continue
    pal = json.load(open(pf))
    slug = pal.get("slug") or pf.stem
    b = pal.get("base16", {}) or {}
    bg = pal.get("background") or b.get("color0", "#000000")
    fg = pal.get("foreground") or b.get("color7", "#ffffff")
    def c(i, fallback):
        return b.get("color%d" % i) or fallback
    defs = {
        "bg0": bg,
        "red": c(1, fg), "green": c(2, fg), "yellow": c(3, fg), "orange": c(4, fg),
        "purple": c(5, fg), "cyan": c(6, fg), "fg0": fg, "muted": c(8, fg),
        "redBright": c(9, c(1, fg)), "greenBright": c(10, c(2, fg)),
        "yellowBright": c(11, c(3, fg)), "orangeBright": c(12, c(4, fg)),
        "purpleBright": c(13, c(5, fg)), "cyanBright": c(14, c(6, fg)),
        "fgBright": c(15, fg),
    }
    theme = {
        "primary": "cyan", "secondary": "purple", "accent": "cyan",
        "error": "red", "warning": "yellow", "success": "green", "info": "cyan",
        "text": "fg0", "textMuted": "muted", "background": "bg0",
        "backgroundPanel": mix(bg, fg, 0.06),
        "backgroundElement": mix(bg, fg, 0.12),
        "border": mix(bg, fg, 0.20),
        "borderActive": "cyan",
        "borderSubtle": mix(bg, fg, 0.10),
        "diffAdded": "green", "diffRemoved": "red", "diffContext": "fg0",
        "diffHunkHeader": "muted", "diffHighlightAdded": "green",
        "diffHighlightRemoved": "red",
        "diffAddedBg": mix(bg, c(2, fg), 0.15),
        "diffRemovedBg": mix(bg, c(1, fg), 0.15),
        "diffContextBg": "bg0", "diffLineNumber": "muted",
        "diffAddedLineNumberBg": mix(bg, c(2, fg), 0.15),
        "diffRemovedLineNumberBg": mix(bg, c(1, fg), 0.15),
        "markdownText": "fg0", "markdownHeading": "cyan", "markdownLink": "orange",
        "markdownLinkText": "cyan", "markdownCode": "green",
        "markdownBlockQuote": "muted", "markdownEmph": "yellow",
        "markdownStrong": "yellow", "markdownHorizontalRule": "muted",
        "markdownListItem": "cyan", "markdownListEnumeration": "cyan",
        "markdownImage": "orange", "markdownImageText": "cyan",
        "markdownCodeBlock": "fg0",
        "syntaxComment": "muted", "syntaxKeyword": "purple", "syntaxFunction": "cyan",
        "syntaxVariable": "orange", "syntaxString": "green", "syntaxNumber": "yellow",
        "syntaxType": "orange", "syntaxOperator": "red", "syntaxPunctuation": "fg0",
    }
    out = {"$schema": "https://opencode.ai/theme.json", "defs": defs, "theme": theme}
    (themes_dir / (slug + ".json")).write_text(json.dumps(out, indent=2) + "\n")
    slugs.append(slug)

print("opencode themes regenerated from dock/palettes: %d" % len(slugs))
XSC_OC_PY

    # Activar el tema de la paleta activa en tui.json (atómico; conserva el resto).
    XSC_OC_TUI="$XSC_OC_DIR/tui.json"
    if [ -f "$XSC_OC_TUI" ] && command -v jq >/dev/null 2>&1; then
        TMP_TUI="$(mktemp)"
        if jq --arg t "$SLUG" '.theme = $t' "$XSC_OC_TUI" > "$TMP_TUI" 2>/dev/null; then
            mv "$TMP_TUI" "$XSC_OC_TUI"
            echo "opencode theme → '$SLUG'"
        else
            rm -f "$TMP_TUI"
        fi
    fi
fi

# ── rofi ──────────────────────────────────────────────────────────────────────────
# colors.rasi lo importan launcher.rasi (emoji picker SUPER+., drun, scale-menu)
# y selector.rasi; se regenera con la paleta. Además se genera config.rasi (solo
# colores, importa colors.rasi) para que las llamadas `rofi -dmenu` sin -theme
# (gpu-mode.sh, monitor-manager.sh) sigan la paleta sin cambiar su layout.
# Solo se escriben esos dos archivos.
ROFI_DIR="$HOME_DIR/.config/rofi"
if [ -d "$ROFI_DIR" ]; then
    python3 - "$PALETTES/$SLUG.json" "$ROFI_DIR" <<'XSC_ROFI'
import json, pathlib, sys

pal = json.load(open(sys.argv[1]))
rdir = pathlib.Path(sys.argv[2])
b = pal.get("base16", {}) or {}
bg = pal.get("background") or b.get("color0", "#000000")
fg = pal.get("foreground") or b.get("color7", "#ffffff")
slug = pal.get("slug") or "?"

def mix(a, b2, t):
    ca = [int(a.lstrip("#")[i:i+2], 16) for i in (0, 2, 4)]
    cb = [int(b2.lstrip("#")[i:i+2], 16) for i in (0, 2, 4)]
    return "#%02x%02x%02x" % tuple(round(ca[i] + (cb[i] - ca[i]) * t) for i in range(3))

c5 = b.get("color5", fg)
colors = "\n".join([
    "/* Auto-generated by theme-sync.sh (xscriptor-colors) — palette '%s'. Do not edit. */" % slug,
    "* {",
    "    background:     %sCC;" % mix(bg, fg, 0.05),
    "    background-alt: %sFF;" % mix(bg, fg, 0.10),
    "    foreground:     %s;" % fg,
    "    selected:       %s;" % c5,
    "    active:         %s;" % b.get("color2", fg),
    "    urgent:         %s;" % b.get("color1", fg),
    "    border-col:     %s;" % c5,
    "    border-col-2:   %s;" % b.get("color13", c5),
    "}",
]) + "\n"
(rdir / "colors.rasi").write_text(colors)

config = "\n".join([
    "/* Auto-generated by theme-sync.sh (xscriptor-colors) — palette '%s'. Do not edit. */" % slug,
    '@import "colors.rasi"',
    "",
    "* {",
    "    background-color: transparent;",
    "    text-color: @foreground;",
    "}",
    "",
    "window {",
    "    background-color: @background;",
    "    border-color: @border-col;",
    "}",
    "",
    "inputbar, entry, prompt, textbox {",
    "    background-color: @background-alt;",
    "    text-color: @foreground;",
    "}",
    "",
    "element selected.normal {",
    "    background-color: @background-alt;",
    "    text-color: @foreground;",
    "    border-color: @border-col;",
    "}",
]) + "\n"
(rdir / "config.rasi").write_text(config)
print("rofi colors → '%s' (colors.rasi + config.rasi)" % slug)
XSC_ROFI
fi

# ── cava (standalone) ─────────────────────────────────────────────────────────────
# El visualizador de la barra (Cava.qml) lanza cava con config inline y pinta las
# barras con la paleta, así que esto solo afecta a `cava` standalone en terminal.
# Se crea ~/.config/cava/config desde config_base si no existe y se gestiona SOLO
# el bloque [color] marcado; un [color] propio del usuario se respeta intacto.
CAVA_DIR="$HOME_DIR/.config/cava"
if [ -d "$CAVA_DIR" ]; then
    python3 - "$PALETTES/$SLUG.json" "$CAVA_DIR" <<'XSC_CAVA'
import json, os, pathlib, sys

pal = json.load(open(sys.argv[1]))
cdir = pathlib.Path(sys.argv[2])
b = pal.get("base16", {}) or {}
bg = pal.get("background") or b.get("color0", "#000000")
fg = pal.get("foreground") or b.get("color7", "#ffffff")
slug = pal.get("slug") or "?"
c5 = b.get("color5", fg)
c6 = b.get("color6", c5)
c4 = b.get("color4", c5)
BEGIN = "# === xscriptor-colors theme-sync (managed) ==="
END = "# === end xscriptor-colors ==="
block = "\n".join([
    BEGIN,
    "[color]",
    "background = '%s'" % bg,
    "foreground = '%s'" % fg,
    "gradient = 1",
    "gradient_color_1 = '%s'" % c5,
    "gradient_color_2 = '%s'" % c6,
    "gradient_color_3 = '%s'" % c4,
    "gradient_count = 3",
    END,
])
cfg = cdir / "config"
base = cdir / "config_base"
if cfg.exists():
    kept, inside, has_color, has_managed = [], False, False, False
    for ln in cfg.read_text(errors="replace").splitlines():
        t = ln.strip()
        if t == BEGIN:
            inside, has_managed = True, True
            continue
        if t == END:
            inside = False
            continue
        if inside:
            continue
        if t == "[color]":
            has_color = True
        kept.append(ln)
    if has_color:
        print("cava: [color] propio detectado; no se toca")
        raise SystemExit(0)
    out = "\n".join(kept).rstrip("\n") + "\n\n" + block + "\n"
elif base.exists():
    out = base.read_text().rstrip("\n") + "\n\n" + block + "\n"
else:
    print("cava: sin config ni config_base; se omite")
    raise SystemExit(0)
tmp = str(cfg) + ".xsc.tmp"
with open(tmp, "w", encoding="utf-8") as f:
    f.write(out)
os.replace(tmp, cfg)
print("cava colors → '%s' (~/.config/cava/config)" % slug)
XSC_CAVA
fi

# ── Qt (qt6ct / qt5ct) ────────────────────────────────────────────────────────────
# Genera un color scheme por paleta en ~/.config/{qt6ct,qt5ct}/colors/<slug>.conf
# (22 roles en el orden del enum QPalette::ColorRole, incluidos NoRole y Accent;
# Qt5 lee los 21 primeros) y activa el de la paleta en qt6ct.conf/qt5ct.conf
# ([Appearance] color_scheme_path + custom_palette + style=Fusion), conservando
# el resto de claves. Las apps Qt requieren reinicio para verlo.
for XSC_QT_DIR in "$HOME_DIR/.config/qt6ct" "$HOME_DIR/.config/qt5ct"; do
    XSC_QT_BIN="$(basename "$XSC_QT_DIR")"
    command -v "$XSC_QT_BIN" >/dev/null 2>&1 || continue
    mkdir -p "$XSC_QT_DIR/colors"
    python3 - "$PALETTES" "$XSC_QT_DIR/colors" <<'XSC_QT_PY'
import json, pathlib, sys

palettes_dir = pathlib.Path(sys.argv[1])
colors_dir = pathlib.Path(sys.argv[2])

def rgb(c):
    h = c.lstrip("#")
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def mix(a, b, t):
    ca, cb = rgb(a), rgb(b)
    return "#%02x%02x%02x" % tuple(round(ca[i] + (cb[i] - ca[i]) * t) for i in range(3))

def lum(c):
    def lin(v):
        v /= 255.0
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = rgb(c)
    return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)

def contrast(a, b):
    la, lb = lum(a), lum(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)

def argb(c):
    return "#ff" + c.lstrip("#").lower()

TEXT = {0, 6, 7, 8, 13, 14, 15, 19, 20}

def scheme(bg, fg, b):
    c5 = b.get("color5") or fg
    accent_fg = fg if contrast(c5, fg) >= contrast(c5, bg) else bg
    active = [
        fg,                         # 0  WindowText
        mix(bg, fg, 0.10),          # 1  Button
        mix(bg, fg, 0.22),          # 2  Light
        mix(bg, fg, 0.16),          # 3  Midlight
        mix(bg, fg, 0.05),          # 4  Dark
        mix(bg, fg, 0.12),          # 5  Mid
        fg,                         # 6  Text
        b.get("color1") or fg,      # 7  BrightText
        fg,                         # 8  ButtonText
        mix(bg, fg, 0.04),          # 9  Base
        bg,                         # 10 Window
        mix(bg, "#000000", 0.35),   # 11 Shadow
        c5,                         # 12 Highlight
        accent_fg,                  # 13 HighlightedText
        b.get("color4") or fg,      # 14 Link
        c5,                         # 15 LinkVisited
        mix(bg, fg, 0.07),          # 16 AlternateBase
        bg,                         # 17 NoRole
        mix(bg, fg, 0.12),          # 18 ToolTipBase
        fg,                         # 19 ToolTipText
        mix(fg, bg, 0.45),          # 20 PlaceholderText
        c5,                         # 21 Accent (Qt >= 6.6)
    ]
    inactive = [mix(c, bg, 0.20) if i in TEXT else c for i, c in enumerate(active)]
    disabled = [mix(c, bg, 0.55) if i in TEXT else mix(c, bg, 0.25) for i, c in enumerate(active)]
    return active, inactive, disabled

slugs = []
for pf in sorted(palettes_dir.glob("*.json")):
    if pf.name == "index.json":
        continue
    pal = json.load(open(pf))
    slug = pal.get("slug") or pf.stem
    b = pal.get("base16", {}) or {}
    bg = pal.get("background") or b.get("color0", "#000000")
    fg = pal.get("foreground") or b.get("color7", "#ffffff")
    active, inactive, disabled = scheme(bg, fg, b)
    lines = ["[ColorScheme]"]
    for key, group in (("active_colors", active),
                       ("disabled_colors", disabled),
                       ("inactive_colors", inactive)):
        lines.append("%s=%s" % (key, ", ".join(argb(c) for c in group)))
    (colors_dir / (slug + ".conf")).write_text("\n".join(lines) + "\n")
    slugs.append(slug)

for stale in colors_dir.glob("*.conf"):
    if stale.stem not in slugs:
        stale.unlink(missing_ok=True)

print("Qt color schemes regenerated: %d (%s)" % (len(slugs), colors_dir.parent.name))
XSC_QT_PY

    XSC_QT_CONF="$XSC_QT_DIR/$XSC_QT_BIN.conf"
    XSC_QT_SCHEME="$XSC_QT_DIR/colors/$SLUG.conf"
    if [ -f "$XSC_QT_SCHEME" ]; then
        python3 - "$XSC_QT_CONF" "$XSC_QT_SCHEME" <<'XSC_QT_CNF'
import os, sys

conf, scheme = sys.argv[1], sys.argv[2]
wanted = [("color_scheme_path", scheme), ("custom_palette", "true"), ("style", "Fusion")]
lines = []
if os.path.isfile(conf):
    lines = open(conf, encoding="utf-8", errors="replace").read().splitlines()
if "[Appearance]" not in lines:
    lines.append("[Appearance]")
for key, val in wanted:
    found = False
    for i, ln in enumerate(lines):
        if ln.strip().startswith(key + "="):
            lines[i] = "%s=%s" % (key, val)
            found = True
            break
    if not found:
        lines.insert(lines.index("[Appearance]") + 1, "%s=%s" % (key, val))
tmp = conf + ".xsc.tmp"
with open(tmp, "w", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n")
os.replace(tmp, conf)
print("qt config → %s (%s)" % (os.path.basename(conf), os.path.basename(scheme)))
XSC_QT_CNF
    fi
done

# ── GTK3 / GTK4 ───────────────────────────────────────────────────────────────────
# Overrides @define-color de la paleta en ~/.config/gtk-3.0/gtk.css y
# gtk-4.0/gtk.css (nombres de adw-gtk3/Adwaita/libadwaita) + esquema del sistema
# (gsettings color-scheme y gtk-theme adw-gtk3[-dark]) para que GTK3, libadwaita,
# los diálogos del portal y los navegadores en modo sistema sigan la paleta.
# GTK3 se tiñe entero; GTK4/libadwaita respeta claro/oscuro y los @define-color
# que use. Las apps ya abiertas necesitan reinicio.
XSC_GTK_DARK=0
[ "$XSC_BROWSER_SCHEME" = "dark" ] && XSC_GTK_DARK=1
python3 - "$PALETTES/$SLUG.json" "$HOME_DIR/.config" <<'XSC_GTK_CSS'
import json, os, pathlib, sys

pal = json.load(open(sys.argv[1]))
cfg = pathlib.Path(sys.argv[2])
b = pal.get("base16", {}) or {}
bg = pal.get("background") or b.get("color0", "#000000")
fg = pal.get("foreground") or b.get("color7", "#ffffff")
c5 = b.get("color5") or fg

def rgb(c):
    h = c.lstrip("#")
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def mix(a, b2, t):
    ca, cb = rgb(a), rgb(b2)
    return "#%02x%02x%02x" % tuple(round(ca[i] + (cb[i] - ca[i]) * t) for i in range(3))

def lum(c):
    def lin(v):
        v /= 255.0
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    r, g, bl = rgb(c)
    return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(bl)

def contrast(a, b2):
    la, lb = lum(a), lum(b2)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)

accent_fg = fg if contrast(c5, fg) >= contrast(c5, bg) else bg
base = mix(bg, fg, 0.04)
header = mix(bg, fg, 0.06)
border = mix(bg, fg, 0.15)
border2 = mix(bg, fg, 0.10)
muted = mix(fg, bg, 0.45)
insens = mix(bg, fg, 0.06)
shade = mix(bg, "#000000", 0.18)
red = b.get("color1") or fg
green = b.get("color2") or fg
yellow = b.get("color3") or fg

defs = [
    ("window_bg_color", bg), ("window_fg_color", fg),
    ("view_bg_color", base), ("view_fg_color", fg),
    ("headerbar_bg_color", header), ("headerbar_fg_color", fg),
    ("headerbar_border_color", border), ("headerbar_backdrop_color", bg),
    ("headerbar_shade_color", shade), ("headerbar_darker_shade_color", shade),
    ("sidebar_bg_color", base), ("sidebar_fg_color", fg),
    ("sidebar_backdrop_color", bg), ("sidebar_border_color", border),
    ("sidebar_shade_color", shade),
    ("card_bg_color", header), ("card_fg_color", fg), ("card_shade_color", shade),
    ("popover_bg_color", mix(bg, fg, 0.08)), ("popover_fg_color", fg),
    ("popover_shade_color", shade),
    ("dialog_bg_color", bg), ("dialog_fg_color", fg),
    ("panel_bg_color", header), ("panel_fg_color", fg),
    ("accent_color", c5), ("accent_bg_color", c5), ("accent_fg_color", accent_fg),
    ("destructive_color", red), ("destructive_bg_color", red), ("destructive_fg_color", accent_fg),
    ("error_color", red), ("error_bg_color", red), ("error_fg_color", accent_fg),
    ("warning_color", yellow), ("warning_bg_color", yellow), ("warning_fg_color", accent_fg),
    ("success_color", green), ("success_bg_color", green), ("success_fg_color", accent_fg),
    ("borders", border), ("unfocused_borders", border2),
    ("theme_bg_color", bg), ("theme_base_color", base),
    ("theme_fg_color", fg), ("theme_text_color", fg),
    ("theme_selected_bg_color", c5), ("theme_selected_fg_color", accent_fg),
    ("theme_unfocused_bg_color", bg), ("theme_unfocused_base_color", base),
    ("theme_unfocused_fg_color", muted), ("theme_unfocused_text_color", muted),
    ("theme_unfocused_selected_bg_color", c5), ("theme_unfocused_selected_fg_color", accent_fg),
    ("insensitive_bg_color", insens), ("insensitive_fg_color", muted),
    ("insensitive_base_color", insens), ("unfocused_insensitive_color", muted),
    ("content_view_bg", base), ("text_view_bg", base),
    ("shade_color", shade), ("scrollbar_outline_color", border),
    ("thumbnail_bg_color", header), ("thumbnail_fg_color", fg),
]
slug = pal.get("slug") or "?"
BEGIN = "/* === xscriptor-colors theme-sync (managed) === */"
END = "/* === end xscriptor-colors === */"
block = [BEGIN,
         "/* palette: %s — auto-generated, do not edit this block */" % slug]
block += ["@define-color %s %s;" % (name, val) for name, val in defs]
block.append(END)

for gtk_dir in ("gtk-3.0", "gtk-4.0"):
    d = cfg / gtk_dir
    d.mkdir(parents=True, exist_ok=True)
    css = d / "gtk.css"
    kept, inside = [], False
    if css.is_file():
        for ln in css.read_text(errors="replace").splitlines():
            t = ln.strip()
            if t == BEGIN:
                inside = True
                continue
            if t == END:
                inside = False
                continue
            if inside:
                continue
            kept.append(ln)
    out = "\n".join(kept).rstrip("\n")
    out = (out + "\n\n" if out else "") + "\n".join(block) + "\n"
    css.write_text(out)
print("gtk colors → '%s' (gtk-3.0 + gtk-4.0 gtk.css)" % slug)
XSC_GTK_CSS

# Esquema del sistema (afecta a libadwaita, al portal y a los navegadores en
# modo sistema). Solo se cambia si gsettings y el tema adw-gtk3 están presentes.
if command -v gsettings >/dev/null 2>&1; then
    if [ "$XSC_GTK_DARK" = "1" ]; then
        XSC_GTK_THEME="adw-gtk3-dark"
        XSC_GTK_SCHEME="prefer-dark"
    else
        XSC_GTK_THEME="adw-gtk3"
        XSC_GTK_SCHEME="prefer-light"
    fi
    if [ -d "/usr/share/themes/$XSC_GTK_THEME" ]; then
        gsettings set org.gnome.desktop.interface gtk-theme "$XSC_GTK_THEME" 2>/dev/null || true
    fi
    # prefer-light explícito (portal=2); fallback a 'default' en esquemas viejos.
    if ! gsettings set org.gnome.desktop.interface color-scheme "$XSC_GTK_SCHEME" 2>/dev/null; then
        XSC_GTK_SCHEME="default"
        gsettings set org.gnome.desktop.interface color-scheme "$XSC_GTK_SCHEME" 2>/dev/null || true
    fi
    echo "gtk system scheme → $XSC_GTK_SCHEME ($XSC_GTK_THEME)"
fi

# ── xfetch (temas) ────────────────────────────────────────────────────────────────
# Genera un tema xfetch por paleta en ~/.config/xfetch/themes/<slug>.jsonc con la
# estructura de los temas oficiales (colors por módulo + logo_color) y activa el
# de la paleta en ~/.config/xfetch/config.jsonc (edición textual: conserva
# comentarios y evita la clave duplicada de `xfetch theme set`). El mapeo de
# módulos es el canónico del registro (helsinki) resuelto a HEX exacto de la
# paleta: xfetch >= 1.0.0 acepta #rrggbb en colors (truecolor, sin depender del
# terminal); en versiones anteriores cae a los nombres ANSI, que resolvía kitty.
# logo_color lleva el acento exacto. Solo se borran temas generados por nosotros
# (primera línea marcador) cuyo slug ya no sea una paleta; los temas propios del
# usuario quedan intactos.
XFETCH_DIR="$HOME_DIR/.config/xfetch"
if [ -d "$XFETCH_DIR" ]; then
    mkdir -p "$XFETCH_DIR/themes"
    # El hook de paleta corre desde Quickshell, cuyo PATH NO incluye
    # ~/.local/bin (donde vive xfetch): resolvemos con fallback explícito.
    XSC_XF_BIN="$(command -v xfetch 2>/dev/null || true)"
    [ -n "$XSC_XF_BIN" ] || XSC_XF_BIN="$HOME_DIR/.local/bin/xfetch"
    [ -x "$XSC_XF_BIN" ] || XSC_XF_BIN=""
    # xfetch >= 1.0.0 acepta hex en colors; antes solo nombres ANSI.
    XSC_XF_HEX=0
    if [ -n "$XSC_XF_BIN" ]; then
        XSC_XF_MAJOR="$("$XSC_XF_BIN" --version 2>/dev/null | grep -oE '[0-9]+' | head -1)"
        if [ -n "$XSC_XF_MAJOR" ] && [ "$XSC_XF_MAJOR" -ge 1 ] 2>/dev/null; then
            XSC_XF_HEX=1
        fi
    fi
    python3 - "$PALETTES" "$XFETCH_DIR" "$SLUG" "$XSC_XF_HEX" <<'XSC_XF_PY'
import json, pathlib, re, sys

palettes_dir = pathlib.Path(sys.argv[1])
xfetch_dir = pathlib.Path(sys.argv[2])
active = sys.argv[3]
use_hex = len(sys.argv) > 4 and sys.argv[4] == "1"

# Módulo → color ANSI canónico (del tema helsinki del registro oficial).
MODULES = {
    "os": "Green", "kernel": "Blue", "hostname": "Magenta", "uptime": "Red",
    "packages": "Green", "shell": "Green", "terminal": "Cyan", "wm": "Blue",
    "cpu": "Red", "gpu": "Magenta", "memory": "Yellow", "swap": "Red",
    "disk": "Cyan", "battery": "Green", "user": "Magenta", "datetime": "Cyan",
    "local_ip": "Blue", "palette": "Green",
    "plugin:docker": "Cyan", "plugin:github-stats": "Blue",
    "plugin:music-player": "Yellow", "plugin:weather": "Cyan",
    "plugin:timezone": "Blue", "plugin:user-info": "Magenta",
    "plugin:display-resolution": "Green", "plugin:theme-detection": "Blue",
}
ANSI_INDEX = {"Black": 0, "Red": 1, "Green": 2, "Yellow": 3, "Blue": 4,
              "Magenta": 5, "Cyan": 6, "White": 7, "Grey": 8}
MARKER = "// Generated by xscriptor-colors theme-sync"

themes_dir = xfetch_dir / "themes"
slugs = []
for pf in sorted(palettes_dir.glob("*.json")):
    if pf.name == "index.json":
        continue
    pal = json.load(open(pf))
    slug = pal.get("slug") or pf.stem
    b = pal.get("base16", {}) or {}
    fg = pal.get("foreground") or b.get("color7") or "#ffffff"

    def c(i, fallback=fg):
        return b.get("color%d" % i) or fallback

    if use_hex:
        colors = {mod: c(ANSI_INDEX[name]) for mod, name in MODULES.items()}
    else:
        colors = {mod: name for mod, name in MODULES.items()}
    out = {
        "colors": colors,
        "logo_color": c(5),
    }
    body = json.dumps(out, indent=4)
    (themes_dir / (slug + ".jsonc")).write_text(
        MARKER + " — palette '" + slug + "'. Do not edit.\n" + body + "\n")
    slugs.append(slug)

# Limpieza: solo temas nuestros cuyo slug ya no sea paleta.
for f in themes_dir.glob("*.jsonc"):
    if f.stem in slugs:
        continue
    try:
        first = f.read_text(errors="replace").splitlines()[0]
    except Exception:
        continue
    if first.startswith(MARKER):
        f.unlink(missing_ok=True)

# Activar el tema de la paleta activa (textual; reemplaza TODAS las apariciones
# de "theme" para que duplicados previos de xfetch theme set no ganen al final).
cfg = xfetch_dir / "config.jsonc"
if (themes_dir / (active + ".jsonc")).is_file():
    if cfg.is_file():
        txt = cfg.read_text(errors="replace")
        pat = re.compile(r'("theme"\s*:\s*)"[^"]*"')
        if pat.search(txt):
            txt = pat.sub(lambda m: m.group(1) + '"' + active + '"', txt)
        else:
            txt = re.sub(r"\{", '{\n    "theme": "' + active + '",', txt, count=1)
        cfg.write_text(txt)
        print("xfetch theme → '%s' (config.jsonc)" % active)
    else:
        cfg.write_text('{\n    "theme": "' + active + '"\n}\n')
        print("xfetch theme → '%s' (config.jsonc creado)" % active)
print("xfetch themes regenerated from dock/palettes: %d" % len(slugs))
XSC_XF_PY
fi
