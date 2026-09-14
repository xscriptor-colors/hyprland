# ═══════════════════════════════════════════════════════════════════════════
# cli — punto de entrada de themesync.
#
#   theme-sync.sh [--list] [--dry-run] [--targets a,b,c]
#                 [--palettes DIR] [--settings FILE]
#
# Los defaults son los del runtime de xscriptor-colors; el wrapper .sh pasa
# los argumentos tal cual. `--list` es la forma rápida de ver qué targets hay
# y cuáles están disponibles.
# ═══════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import argparse
import os
from pathlib import Path

from .core import Env, active_slug, load_json, load_palettes
from .runner import listing, run

DEFAULT_PALETTES = ".config/hypr/scripts/quickshell/dock/palettes"
DEFAULT_SETTINGS = ".config/hypr/settings.json"


def build_env(args) -> Env:
    """Construye el Env a partir de los argumentos (o de los defaults)."""
    home = Path(os.environ.get("HOME") or "~").expanduser()
    palettes_dir = Path(args.palettes).expanduser() if args.palettes else home / DEFAULT_PALETTES
    settings_path = Path(args.settings).expanduser() if args.settings else home / DEFAULT_SETTINGS

    settings = load_json(settings_path, {}) or {}
    slug = active_slug(settings)
    palettes = load_palettes(palettes_dir)
    palette = next((p for p in palettes if p.get("slug") == slug), None)
    if palette is None:
        # La paleta activa puede no estar en el directorio (p. ej. borrada):
        # se intenta cargar su archivo directo; si no, queda {}.
        palette = load_json(palettes_dir / (slug + ".json"), {}) or {}

    return Env(home=home, palettes_dir=palettes_dir, settings_path=settings_path,
               slug=slug, palettes=palettes, palette=palette, dry_run=args.dry_run)


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(
        prog="theme-sync",
        description="Sincroniza las aplicaciones con la paleta activa (dock/palettes).")
    parser.add_argument("--palettes", help="directorio de paletas")
    parser.add_argument("--settings", help="ruta de settings.json")
    parser.add_argument("--targets", help="lista separada por comas (p. ej. kitty,xfetch)")
    parser.add_argument("--list", action="store_true", help="lista los targets y sale")
    parser.add_argument("--dry-run", action="store_true", help="no escribe ni ejecuta nada")
    args = parser.parse_args(argv)

    env = build_env(args)
    if args.list:
        print("paleta activa: %s (%d paletas)" % (env.slug, len(env.palettes)))
        for line in listing(env):
            print(line)
        return 0

    return run(env, only=args.targets.split(",") if args.targets else None)
