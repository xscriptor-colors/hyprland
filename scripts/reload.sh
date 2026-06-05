#!/usr/bin/env bash
# Soft reload: refresh colors without killing workspace daemon
quickshell -p ~/.config/hypr/scripts/quickshell/Shell.qml ipc call topbar reloadColors 2>/dev/null || \
qs -p ~/.config/hypr/scripts/quickshell/Shell.qml ipc call topbar reloadColors 2>/dev/null || true
