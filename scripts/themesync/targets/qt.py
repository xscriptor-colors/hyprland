# ═══════════════════════════════════════════════════════════════════════════
# qt — color schemes de qt6ct/qt5ct + config activa.
#
# Genera un color scheme por paleta en ~/.config/{qt6ct,qt5ct}/colors/<slug>.conf
# con los 22 roles en el orden del enum QPalette::ColorRole (incluidos NoRole y
# Accent; Qt5 lee los 21 primeros) y activa el de la paleta en
# qt6ct.conf/qt5ct.conf ([Appearance] color_scheme_path + custom_palette +
# style=Fusion), conservando el resto de claves. Las apps Qt requieren
# reinicio para verlo.
# ═══════════════════════════════════════════════════════════════════════════
from __future__ import annotations

from pathlib import Path

from ..core import argb, best_fg, mix, palette_bg_fg, palette_hex, read_text

NAME = "qt"
DESCRIPTION = "color schemes de qt6ct/qt5ct + config activa"

QT_DIRS = (".config/qt6ct", ".config/qt5ct")
# Roles que se atenúan en inactive/disabled (texto y acentos).
TEXT_ROLES = {0, 6, 7, 8, 13, 14, 15, 19, 20}


def available(env) -> bool:
    return any(env.binary(Path(rel).name) for rel in QT_DIRS)


def _scheme(bg: str, fg: str, b: dict):
    """22 roles activos (orden del enum) + variantes inactive/disabled."""
    c5 = b.get("color5") or fg
    accent_fg = best_fg(c5, fg, bg)
    active = [
        fg,                          # 0  WindowText
        mix(bg, fg, 0.10),           # 1  Button
        mix(bg, fg, 0.22),           # 2  Light
        mix(bg, fg, 0.16),           # 3  Midlight
        mix(bg, fg, 0.05),           # 4  Dark
        mix(bg, fg, 0.12),           # 5  Mid
        fg,                          # 6  Text
        b.get("color1") or fg,       # 7  BrightText
        fg,                          # 8  ButtonText
        mix(bg, fg, 0.04),           # 9  Base
        bg,                          # 10 Window
        mix(bg, "#000000", 0.35),    # 11 Shadow
        c5,                          # 12 Highlight
        accent_fg,                   # 13 HighlightedText
        b.get("color4") or fg,       # 14 Link
        c5,                          # 15 LinkVisited
        mix(bg, fg, 0.07),           # 16 AlternateBase
        bg,                          # 17 NoRole
        mix(bg, fg, 0.12),           # 18 ToolTipBase
        fg,                          # 19 ToolTipText
        mix(fg, bg, 0.45),           # 20 PlaceholderText
        c5,                          # 21 Accent (Qt >= 6.6)
    ]
    inactive = [mix(c, bg, 0.20) if i in TEXT_ROLES else c for i, c in enumerate(active)]
    disabled = [mix(c, bg, 0.55) if i in TEXT_ROLES else mix(c, bg, 0.25)
                for i, c in enumerate(active)]
    return active, inactive, disabled


def _update_conf(env, conf, scheme_path: str) -> None:
    """Fija las claves de [Appearance] sin tocar el resto del archivo."""
    lines = read_text(conf).splitlines() if conf.is_file() else []
    if "[Appearance]" not in lines:
        lines.append("[Appearance]")
    wanted = [("color_scheme_path", scheme_path),
              ("custom_palette", "true"),
              ("style", "Fusion")]
    for key, val in wanted:
        found = False
        for i, ln in enumerate(lines):
            if ln.strip().startswith(key + "="):
                lines[i] = "%s=%s" % (key, val)
                found = True
                break
        if not found:
            lines.insert(lines.index("[Appearance]") + 1, "%s=%s" % (key, val))
    env.write(conf, "\n".join(lines) + "\n")


def apply(env) -> list:
    out = []
    for rel in QT_DIRS:
        name = Path(rel).name          # qt6ct / qt5ct
        if not env.binary(name):
            continue
        base = env.home / rel
        colors = base / "colors"
        env.mkdir(colors)

        # ── 1) Color scheme por paleta ──
        slugs = []
        for pal in env.palettes:
            slug = pal.get("slug") or "?"
            b = pal.get("base16") or {}
            bg, fg = palette_bg_fg(pal)
            active, inactive, disabled = _scheme(bg, fg, b)
            lines = ["[ColorScheme]"]
            for key, group in (("active_colors", active),
                               ("disabled_colors", disabled),
                               ("inactive_colors", inactive)):
                lines.append("%s=%s" % (key, ", ".join(argb(c) for c in group)))
            env.write(colors / (slug + ".conf"), "\n".join(lines) + "\n")
            slugs.append(slug)

        for stale in colors.glob("*.conf"):
            if stale.stem not in slugs:
                env.unlink(stale)
        out.append("Qt color schemes regenerated: %d (%s)" % (len(slugs), name))

        # ── 2) Activar el de la paleta en curso ──
        scheme_path = colors / (env.slug + ".conf")
        if scheme_path.is_file():
            conf = base / (name + ".conf")
            _update_conf(env, conf, str(scheme_path))
            out.append("qt config → %s.conf (%s)" % (name, scheme_path.name))
    return out
