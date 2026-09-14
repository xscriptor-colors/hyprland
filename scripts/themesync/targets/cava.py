# ═══════════════════════════════════════════════════════════════════════════
# cava — managed [color] block in the standalone config.
#
# The bar visualizer (Cava.qml) spawns cava with an inline config and paints
# the bars from the palette, so this only affects standalone `cava` in a
# terminal. ~/.config/cava/config is created from config_base when missing and
# ONLY the marked [color] block is managed; a user-owned [color] section is
# preserved untouched (and reported).
# ═══════════════════════════════════════════════════════════════════════════
from __future__ import annotations

from ..core import palette_bg_fg, palette_hex, read_text, strip_block

NAME = "cava"
DESCRIPTION = "managed [color] block with a palette gradient"

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
            # The user manages their own colors: leave it alone.
            return ["cava: custom [color] section detected; left untouched"]
        text = "\n".join(kept).rstrip("\n") + "\n\n" + block + "\n"
    elif base.exists():
        text = read_text(base).rstrip("\n") + "\n\n" + block + "\n"
    else:
        return ["cava: no config or config_base; skipped"]

    env.write(cfg, text)
    return ["cava colors → '%s' (~/.config/cava/config)" % env.slug]
