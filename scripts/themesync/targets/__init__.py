# ═══════════════════════════════════════════════════════════════════════════
# targets — theming target registry.
#
# Contract for a target (a module in this package):
#   NAME         str         short name (for --targets)
#   DESCRIPTION  str         one-line description (for --list)
#   available(env) -> bool   should it run? (app/directory present)
#   apply(env) -> list[str]  run it and return the log lines
#
# TARGETS order is the execution order. There is no shared state between
# targets: gtk computes light/dark from the palette (env.light), not from the
# browsers result.
# ═══════════════════════════════════════════════════════════════════════════
from . import (
    browsers,
    cava,
    gtk,
    kitty,
    nvim,
    opencode,
    qt,
    rofi,
    starship,
    vscode,
    xfetch,
    xtop,
)

TARGETS = [kitty, starship, xtop, vscode, nvim, browsers,
           opencode, rofi, cava, qt, gtk, xfetch]

BY_NAME = {t.NAME: t for t in TARGETS}
