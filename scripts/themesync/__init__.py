# ═══════════════════════════════════════════════════════════════════════════
# themesync — theming engine for equisdots.
#
# Syncs applications with the desktop's active palette (source of truth: the
# palettes directory, by default dock/palettes/*.json). Each target lives in
# targets/<app>.py and exposes NAME, DESCRIPTION, available(env) and apply(env);
# orchestration is in runner.py and the CLI in cli.py.
#
# Entry point: theme-sync.sh (thin wrapper) → `python3 -m themesync`.
# ═══════════════════════════════════════════════════════════════════════════

__version__ = "2.0.0"
