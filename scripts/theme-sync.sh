#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# theme-sync — entry point.
#
# All logic lives in the themesync/ Python package (one module per application
# under themesync/targets/). On the desktop it is called by the palette hook
# (dock/Colors.qml), install.sh and reload.sh.
#
# Usage:
#   ./theme-sync.sh [--list] [--dry-run] [--targets kitty,xfetch]
#                   [--palettes DIR] [--settings FILE]
#
# The script resolves its own directory (the runtime is a copy, not a symlink)
# and adds it to PYTHONPATH for `python3 -m themesync`.
# ═══════════════════════════════════════════════════════════════════════════
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec env PYTHONPATH="$DIR${PYTHONPATH:+:$PYTHONPATH}" python3 -m themesync "$@"
