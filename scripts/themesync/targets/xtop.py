# ═══════════════════════════════════════════════════════════════════════════
# xtop — temas por paleta + tema activo.
#
# Genera ~/.config/xtop/themes/<slug>.jsonc para todas las paletas y activa
# el de la paleta en curso con `xtop --ct <slug>` (persiste; las instancias
# vivas siguen en el siguiente tick). Los temas custom cuyo slug no sea una
# paleta se conservan; solo se borran los generados por nosotros (cabecera
# "synced from dock/palettes/") que queden huérfanos. Snapshot único de los
# temas preexistentes en themes.bak.
# ═══════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import json

from ..core import palette_bg_fg, read_text

NAME = "xtop"
DESCRIPTION = "temas por paleta + tema activo (xtop --ct)"

THEMES_REL = ".config/xtop/themes"
HEADER_MARK = "synced from dock/palettes/"


def available(env) -> bool:
    return (env.home / THEMES_REL).is_dir()


def apply(env) -> list:
    out = []
    themes = env.home / THEMES_REL
    env.copytree_once(themes, str(themes) + ".bak")

    # ── 1) Regenerar temas por paleta ──
    slugs = []
    for pal in env.palettes:
        slug = pal.get("slug") or "?"
        b = pal.get("base16") or {}
        bg, fg = palette_bg_fg(pal)
        palette = [b.get("color%d" % i, bg) for i in range(16)]
        body = json.dumps({
            "name": slug,
            "background": bg,
            "foreground": fg,
            "palette": palette,
        }, indent=4)
        header = "// %s -- synced from dock/palettes/%s.json by theme-sync.sh\n" % (
            pal.get("name", slug), slug)
        env.write(themes / (slug + ".jsonc"), header + body + "\n")
        slugs.append(slug)

    # ── 2) Limpieza de huérfanos nuestros ──
    for stale in themes.glob("*.jsonc"):
        if stale.stem in slugs:
            continue
        first = read_text(stale).splitlines()
        if first and HEADER_MARK in first[0]:
            env.unlink(stale)
    out.append("xtop themes regenerated from dock/palettes: %d" % len(slugs))

    # ── 3) Activar el tema de la paleta en curso ──
    binary = env.binary("xtop")
    if binary and (themes / (env.slug + ".jsonc")).is_file():
        if env.dry_run:
            env.note("[dry-run] xtop --ct %s" % env.slug)
        elif env.run([binary, "--ct", env.slug], timeout=10):
            out.append("xtop theme → '%s'" % env.slug)
    return out
