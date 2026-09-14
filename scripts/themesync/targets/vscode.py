# ═══════════════════════════════════════════════════════════════════════════
# vscode — colorTheme + iconTheme en cada variante instalada.
#
# La extensión xscriptor-themes publica un tema de color Y uno de iconos por
# paleta (id "<slug>-icons"). Se actualizan workbench.colorTheme y
# workbench.iconTheme en el settings.json de Code y Code - Insiders; VS Code
# los aplica en vivo. El nombre del tema de color es el slug capitalizado
# (x → "X", bogota → "Bogotá").
# ═══════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import re

NAME = "vscode"
DESCRIPTION = "colorTheme + iconTheme en Code / Code - Insiders"

VARIANTS = (
    ".config/Code/User/settings.json",
    ".config/Code - Insiders/User/settings.json",
)


def available(env) -> bool:
    # Siempre: si no hay ninguna variante, apply() no hace nada.
    return True


def _theme_name(slug: str) -> str:
    if slug == "x":
        return "X"
    if slug == "bogota":
        return "Bogotá"
    return slug[:1].upper() + slug[1:]


def _set_key(text: str, key: str, value: str) -> str:
    """Fija una clave JSON de primer nivel (reemplaza o inserta tras la '{')."""
    pat = re.compile(r'"%s":[^,}]*' % re.escape(key))
    if pat.search(text):
        return pat.sub('"%s": "%s"' % (key, value), text, count=1)
    return text.replace("{", '{\n    "%s": "%s",' % (key, value), 1)


def apply(env) -> list:
    out = []
    theme = _theme_name(env.slug)
    icons = "%s-icons" % env.slug
    for rel in VARIANTS:
        path = env.home / rel
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        text = _set_key(text, "workbench.colorTheme", theme)
        text = _set_key(text, "workbench.iconTheme", icons)
        env.write(path, text)
        variant = path.parent.parent.name  # "Code" / "Code - Insiders"
        out.append("vscode (%s) → color '%s', icons '%s'" % (variant, theme, icons))
    return out
