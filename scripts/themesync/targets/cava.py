# ═══════════════════════════════════════════════════════════════════════════
# cava — bloque [color] gestionado en la config standalone.
#
# El visualizador de la barra (Cava.qml) lanza cava con config inline y pinta
# las barras con la paleta, así que esto solo afecta a `cava` standalone en
# terminal. Se crea ~/.config/cava/config desde config_base si no existe y se
# gestiona SOLO el bloque [color] marcado; un [color] propio del usuario se
# respeta intacto (y se avisa).
# ═══════════════════════════════════════════════════════════════════════════
from __future__ import annotations

from ..core import palette_bg_fg, palette_hex, read_text, strip_block

NAME = "cava"
DESCRIPTION = "bloque [color] con gradiente de la paleta"

CAVA_REL = ".config/cava"
BEGIN = "# === xscriptor-colors theme-sync (managed) ==="
END = "# === end xscriptor-colors ==="


def available(env) -> bool:
    return (env.home / CAVA_REL).is_dir()


def apply(env) -> list:
    cdir = env.home / CAVA_REL
    pal = env.palette
    bg, fg = palette_bg_fg(pal)
    c5 = palette_hex(pal, "color5", fg)
    c6 = palette_hex(pal, "color6", c5)
    c4 = palette_hex(pal, "color4", c5)

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
        kept, _ = strip_block(read_text(cfg).splitlines(), BEGIN, END)
        if any(ln.strip() == "[color]" for ln in kept):
            # El usuario gestiona sus propios colores: no se toca.
            return ["cava: [color] propio detectado; no se toca"]
        text = "\n".join(kept).rstrip("\n") + "\n\n" + block + "\n"
    elif base.exists():
        text = read_text(base).rstrip("\n") + "\n\n" + block + "\n"
    else:
        return ["cava: sin config ni config_base; se omite"]

    env.write(cfg, text)
    return ["cava colors → '%s' (~/.config/cava/config)" % env.slug]
