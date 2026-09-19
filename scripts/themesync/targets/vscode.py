# ═══════════════════════════════════════════════════════════════════════════
# vscode — colorTheme + iconTheme in every installed variant.
#
# The xscriptor-themes extension ships one color theme AND one icon theme per
# palette (id "<slug>-icons"). workbench.colorTheme and workbench.iconTheme are
# updated in the settings.json of Code and Code - Insiders; VS Code applies them
# live. The color theme name is the capitalized slug (x → "X", bogota → "Bogotá").
# ═══════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import re

NAME = "vscode"
DESCRIPTION = "colorTheme + iconTheme in Code / Code - Insiders"

VARIANTS = (
    ".config/Code/User/settings.json",
    ".config/Code - Insiders/User/settings.json",
)


def available(env) -> bool:
    # Always: if no variant is installed, apply() does nothing.
    return True


def _theme_name(slug: str) -> str:
    if slug == "x":
        return "X"
    if slug == "bogota":
        return "Bogotá"
    return slug[:1].upper() + slug[1:]


def _set_key(text: str, key: str, value: str) -> str:
    """Set a top-level JSON key (replace it or insert after the first '{')."""
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
