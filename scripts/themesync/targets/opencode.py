# ═══════════════════════════════════════════════════════════════════════════
# opencode — temas por paleta + tema activo en tui.json.
#
# Genera ~/.config/opencode/themes/<slug>.json (defs base16 + colores
# estructurales derivados del fondo/foreground) y fija el tema de la paleta
# activa en tui.json (atómico, conserva el resto de claves). Los temas custom
# cuyo slug no sea una paleta se dejan intactos; snapshot único de los temas
# preexistentes en themes.bak. El TUI puede requerir reinicio para releerlo.
# ═══════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import json

from ..core import load_json, mix, palette_bg_fg

NAME = "opencode"
DESCRIPTION = "temas por paleta + tema activo en tui.json"

OC_REL = ".config/opencode"
# Manifiesto de slugs generados por nosotros (el dir puede tener temas del
# usuario; solo borramos lo que generamos y ya no es paleta).
STATE_REL = ".local/state/quickshell/themesync/opencode-themes.json"


def available(env) -> bool:
    return (env.home / OC_REL / "themes").is_dir()


def apply(env) -> list:
    out = []
    root = env.home / OC_REL
    themes = root / "themes"
    env.copytree_once(themes, root / "themes.bak")

    # ── 1) Regenerar temas por paleta ──
    slugs = []
    for pal in env.palettes:
        slug = pal.get("slug") or "?"
        b = pal.get("base16") or {}
        bg, fg = palette_bg_fg(pal)

        def c(i, fallback=fg):
            return b.get("color%d" % i) or fallback

        defs = {
            "bg0": bg,
            "red": c(1), "green": c(2), "yellow": c(3), "orange": c(4),
            "purple": c(5), "cyan": c(6), "fg0": fg, "muted": c(8),
            "redBright": c(9, c(1)), "greenBright": c(10, c(2)),
            "yellowBright": c(11, c(3)), "orangeBright": c(12, c(4)),
            "purpleBright": c(13, c(5)), "cyanBright": c(14, c(6)),
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
            "diffAddedBg": mix(bg, c(2), 0.15),
            "diffRemovedBg": mix(bg, c(1), 0.15),
            "diffContextBg": "bg0", "diffLineNumber": "muted",
            "diffAddedLineNumberBg": mix(bg, c(2), 0.15),
            "diffRemovedLineNumberBg": mix(bg, c(1), 0.15),
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
        data = {"$schema": "https://opencode.ai/theme.json", "defs": defs, "theme": theme}
        env.write(themes / (slug + ".json"), json.dumps(data, indent=2) + "\n")
        slugs.append(slug)

    # ── 2) Limpieza de huérfanos: solo los que generamos nosotros ──
    # El directorio de temas de opencode puede contener temas propios del
    # usuario, así que (a diferencia de kitty/starship/Qt, cuyos directorios son
    # 100% nuestros) se lleva un manifiesto de los slugs generados y solo se
    # borran los que ya no son paleta. Sin manifiesto previo no se borra nada.
    state = env.home / STATE_REL
    previous = load_json(state, []) or []
    for slug in previous:
        if slug not in slugs:
            env.unlink(themes / (slug + ".json"))
    env.write(state, json.dumps(slugs, indent=2) + "\n")

    out.append("opencode themes regenerated from dock/palettes: %d" % len(slugs))

    # ── 3) Tema activo en tui.json (conserva el resto) ──
    tui = root / "tui.json"
    if tui.is_file():
        data = load_json(tui)
        if isinstance(data, dict):
            data["theme"] = env.slug
            env.write(tui, json.dumps(data, indent=2, ensure_ascii=False) + "\n")
            out.append("opencode theme → '%s'" % env.slug)
    return out
