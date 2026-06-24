#!/usr/bin/env bash
# Reload QuickShell (full QML reload)
QS=""; command -v quickshell >/dev/null 2>&1 && QS=quickshell || command -v qs >/dev/null 2>&1 && QS=qs
if [ -n "$QS" ]; then
    $QS -p ~/.config/hypr/scripts/quickshell/Shell.qml ipc call topbar forceReload 2>/dev/null || true
fi

# Update SDDM Colors.qml from Matugen if available
if [ -f "$HOME/.config/hypr/sddm-colors.qml" ] && [ -d /usr/share/sddm/themes/matugen-minimal ]; then
    sudo cp "$HOME/.config/hypr/sddm-colors.qml" /usr/share/sddm/themes/matugen-minimal/Colors.qml 2>/dev/null || true
fi
