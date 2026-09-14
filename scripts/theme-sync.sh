#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# theme-sync — entry point fino.
#
# Toda la lógica vive en scripts/themesync/ (paquete Python modular, un módulo
# por aplicación). Este .sh se mantiene porque lo invocan:
#   - dock/Colors.qml  (hook de cambio de paleta)
#   - install.sh       (sync inicial tras instalar)
#   - scripts/reload.sh
#
# Uso directo:
#   ./theme-sync.sh [--list] [--dry-run] [--targets kitty,xfetch]
#                   [--palettes DIR] [--settings FILE]
#
# Nota: se resuelve el directorio del propio script (el runtime es una copia,
# no un symlink) y se añade al PYTHONPATH para `python3 -m themesync`.
# ═══════════════════════════════════════════════════════════════════════════
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec env PYTHONPATH="$DIR${PYTHONPATH:+:$PYTHONPATH}" python3 -m themesync "$@"
