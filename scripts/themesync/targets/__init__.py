# ═══════════════════════════════════════════════════════════════════════════
# targets — registro de destinos de theming.
#
# Contrato de un target (módulo de este paquete):
#   NAME         str         nombre corto (para --targets)
#   DESCRIPTION  str         descripción de una línea (para --list)
#   available(env) -> bool   ¿procede ejecutarlo? (app/directorio presente)
#   apply(env) -> list[str]  ejecuta y devuelve las líneas de log
#
# El orden de TARGETS es el orden de ejecución. No hay estado compartido
# entre targets: gtk calcula claro/oscuro desde la paleta (env.light), no
# desde el resultado de browsers.
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
