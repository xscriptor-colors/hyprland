# ═══════════════════════════════════════════════════════════════════════════
# kitty — temas por paleta + include y borde activo en kitty.conf.
#
# Genera ~/.config/kitty/themes/<slug>.conf para TODAS las paletas y apunta
# kitty.conf al tema activo (`include themes/<slug>.conf`) + el borde activo
# con el acento. De kitty.conf solo se tocan esas dos cosas (y el include
# legado `current-theme.conf`): shaders, fuentes, binds y demás quedan
# intactos. Kitty recarga al vuelo al cambiar el archivo.
# ═══════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import re

from ..core import palette_bg_fg, palette_hex

NAME = "kitty"
DESCRIPTION = "temas por paleta + include y borde activo en kitty.conf"


def available(env) -> bool:
    # Siempre: los temas se generan aunque kitty.conf no exista todavía.
    return True


def apply(env) -> list:
    out = []
    themes = env.home / ".config/kitty/themes"
    env.mkdir(themes)

    # ── 1) Regenerar TODOS los temas desde dock/palettes ──
    slugs = []
    for pal in env.palettes:
        slug = pal.get("slug") or "?"
        b = pal.get("base16") or {}
        bg, fg = palette_bg_fg(pal)
        lines = []
        for i in range(16):
            lines.append("color%-2d  %s" % (i, b.get("color%d" % i, "#000000")))
        lines.append("background %s" % bg)
        lines.append("foreground %s" % fg)
        lines.append("cursor %s" % fg)
        env.write(themes / (slug + ".conf"), "\n".join(lines) + "\n")
        slugs.append(slug)

    # Temas huérfanos (paletas borradas): fuera.
    for stale in themes.glob("*.conf"):
        if stale.stem not in slugs:
            env.unlink(stale)
    out.append("kitty themes regenerated from dock/palettes: %d" % len(slugs))

    # ── 2) Apuntar kitty.conf al tema activo + borde ──
    conf = env.home / ".config/kitty/kitty.conf"
    if not conf.is_file():
        return out

    lines = conf.read_text(encoding="utf-8", errors="replace").splitlines()
    # Include legado del instalador antiguo.
    lines = [ln for ln in lines if not re.match(r"^include\s+current-theme\.conf", ln)]

    replaced = False
    for i, ln in enumerate(lines):
        if re.match(r"^include\s+themes/", ln):
            lines[i] = "include themes/%s.conf" % env.slug
            replaced = True
            break
    if not replaced:
        lines += ["", "include themes/%s.conf" % env.slug]

    accent = palette_hex(env.palette, "color1", "#fc618d")
    if not accent.startswith("#"):
        accent = "#" + accent
    done = False
    for i, ln in enumerate(lines):
        if re.match(r"^active_border_color", ln):
            lines[i] = "active_border_color %s" % accent
            done = True
            break
    if not done:
        lines.append("active_border_color %s" % accent)

    env.write(conf, "\n".join(lines) + "\n")
    out.append("kitty theme → '%s' (border %s)" % (env.slug, accent))
    return out
