# ═══════════════════════════════════════════════════════════════════════════
# cli — themesync entry point.
#
#   theme-sync.sh [--list] [--dry-run] [--targets a,b,c]
#                 [--palettes DIR] [--settings FILE]
#
# Defaults match the xscriptor desktop layout; the .sh wrapper forwards its
# arguments as-is. `--list` is the quick way to see the available targets.
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
    """Build the Env from the arguments (or from the defaults)."""
    home = Path(os.environ.get("HOME") or "~").expanduser()
    palettes_dir = Path(args.palettes).expanduser() if args.palettes else home / DEFAULT_PALETTES
    settings_path = Path(args.settings).expanduser() if args.settings else home / DEFAULT_SETTINGS

    settings = load_json(settings_path, {}) or {}
    slug = active_slug(settings)
    palettes = load_palettes(palettes_dir)
    palette = next((p for p in palettes if p.get("slug") == slug), None)
    if palette is None:
        # The active palette may be missing from the directory (e.g. deleted):
        # try loading its file directly; otherwise it stays empty.
        palette = load_json(palettes_dir / (slug + ".json"), {}) or {}

    return Env(home=home, palettes_dir=palettes_dir, settings_path=settings_path,
               slug=slug, palettes=palettes, palette=palette, dry_run=args.dry_run)


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(
        prog="theme-sync",
        description="Sync applications with the active palette (dock/palettes).")
    parser.add_argument("--palettes", help="palettes directory")
    parser.add_argument("--settings", help="path to settings.json")
    parser.add_argument("--targets", help="comma-separated list (e.g. kitty,xfetch)")
    parser.add_argument("--list", action="store_true", help="list targets and exit")
    parser.add_argument("--dry-run", action="store_true", help="do not write or run anything")
    args = parser.parse_args(argv)

    env = build_env(args)
    if args.list:
        print("active palette: %s (%d palettes)" % (env.slug, len(env.palettes)))
        for line in listing(env):
            print(line)
        return 0

    return run(env, only=args.targets.split(",") if args.targets else None)
