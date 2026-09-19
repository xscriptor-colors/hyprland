#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# GLOBAL VARS
# -----------------------------------------------------------------------------
SCRIPTS_DIR="$HOME/.config/hypr/scripts/quickshell"
SHELL_QML_PATH="$SCRIPTS_DIR/Shell.qml"
QS=""; command -v quickshell >/dev/null 2>&1 && QS=quickshell || command -v qs >/dev/null 2>&1 && QS=qs

# Shared helpers for the optional "unified desktops" mode (tiny, no caching).
source "$(dirname "${BASH_SOURCE[0]}")/ws-desktops-lib.sh"

# -----------------------------------------------------------------------------
# FAST PATH: WORKSPACE / DESKTOP SWITCHING
# Must be first — before any other sourcing, caching, or pgrep.
# -----------------------------------------------------------------------------
ACTION="$1"
TARGET="$2"
SUBTARGET="$3"

if [[ "$ACTION" =~ ^[0-9]+$ ]]; then
    # Send IPC command directly to Main.qml via Quickshell's native IPC handler
    $QS -p "$SHELL_QML_PATH" ipc call main handleCommand "close" "" "" >/dev/null 2>&1

    if [[ "$(ws_desktops_unified)" == "yes" ]]; then
        # Unified desktops: >=2 roster screens connected -> desktop `ACTION`
        # jumps on EVERY screen. Falls through to classic below otherwise.
        if [[ "$TARGET" == "move" ]]; then
            ws_desktop_move_window "$ACTION"
        else
            ws_desktop_goto "$ACTION"
        fi
        exit 0
    fi

    if [[ "$TARGET" == "move" ]]; then
        hyprctl eval "hl.dispatch(hl.dsp.window.move({ workspace = $ACTION }))" >/dev/null 2>&1
    else
        hyprctl eval "hl.dispatch(hl.dsp.focus({ workspace = $ACTION }))" >/dev/null 2>&1
    fi
    exit 0
fi

if [[ "$ACTION" == "next" || "$ACTION" == "prev" ]]; then
    # Close popups first, like numeric switches do.
    $QS -p "$SHELL_QML_PATH" ipc call main handleCommand "close" "" "" >/dev/null 2>&1

    if [[ "$(ws_desktops_unified)" == "yes" ]]; then
        ws_desktop_rel "$ACTION"
        exit 0
    fi

    if [[ "$ACTION" == "next" ]]; then
        hyprctl eval 'hl.dispatch(hl.dsp.focus({ workspace = "e+1" }))' >/dev/null 2>&1
    else
        hyprctl eval 'hl.dispatch(hl.dsp.focus({ workspace = "e-1" }))' >/dev/null 2>&1
    fi
    exit 0
fi

# -----------------------------------------------------------------------------
# SLOW PATH: Everything below only runs for non-workspace actions
# -----------------------------------------------------------------------------

source "$(dirname "${BASH_SOURCE[0]}")/caching.sh"

qs_ensure_cache "workspaces"
qs_ensure_cache "network"
qs_ensure_cache "wallpaper_picker"

BT_PID_FILE="$QS_RUN_DIR/bt_scan_pid"
BT_SCAN_LOG="$QS_LOG_DIR/bt_scan.log"

QS_NETWORK_CACHE="$QS_CACHE_NETWORK"
mkdir -p "$QS_NETWORK_CACHE"

NETWORK_MODE_FILE="$QS_NETWORK_CACHE/mode"

# -----------------------------------------------------------------------------
# ZOMBIE WATCHDOG
# Only runs on slow path — not on every workspace switch
# -----------------------------------------------------------------------------

if ! pgrep -f "Shell.qml" >/dev/null; then
    $QS -p "$SHELL_QML_PATH" >/dev/null 2>&1 &
    disown
fi

# -----------------------------------------------------------------------------
# HELPERS
# -----------------------------------------------------------------------------
# La preparación de miniaturas vive en davincix/kernel/thumbs.sh;
# aquí solo se lanza en segundo plano.
handle_wallpaper_prep() {
    bash "$SCRIPTS_DIR/davincix/kernel/davincix.sh" thumbs &
}

handle_network_prep() {
    # Kill any PREVIOUS BT scan session first (dedupe): toggling the network
    # popup (SUPER+N) starts a new scan but the old one only dies on an
    # explicit `close network` — every toggle used to leak a resident
    # `bluetoothctl | sleep infinity` process until the next close.
    if [ -f "$BT_PID_FILE" ]; then
        OLD_PID=$(cat "$BT_PID_FILE" 2>/dev/null)
        if [ -n "$OLD_PID" ]; then
            kill "$OLD_PID" 2>/dev/null
            pkill -P "$OLD_PID" 2>/dev/null
            rm -f "$BT_PID_FILE"
        fi
    fi
    (bluetoothctl scan off > /dev/null 2>&1) &
    echo "" > "$BT_SCAN_LOG"
    { echo "scan on"; sleep infinity; } | stdbuf -oL bluetoothctl > "$BT_SCAN_LOG" 2>&1 &
    echo $! > "$BT_PID_FILE"
    (nmcli device wifi rescan) >/dev/null 2>&1 &
}

# -----------------------------------------------------------------------------
# IPC ROUTING
# -----------------------------------------------------------------------------
if [[ "$ACTION" == "close" ]]; then
    $QS -p "$SHELL_QML_PATH" ipc call main handleCommand "close" "" "" >/dev/null 2>&1
    if [[ "$TARGET" == "network" || "$TARGET" == "all" || -z "$TARGET" ]]; then
        if [ -f "$BT_PID_FILE" ]; then
            kill $(cat "$BT_PID_FILE") 2>/dev/null
            rm -f "$BT_PID_FILE"
        fi
        (bluetoothctl scan off > /dev/null 2>&1) &
    fi
    exit 0
fi

if [[ "$ACTION" == "open" || "$ACTION" == "toggle" ]]; then
    if [[ "$TARGET" == "network" ]]; then
        handle_network_prep
        [[ -n "$SUBTARGET" ]] && echo "$SUBTARGET" > "$NETWORK_MODE_FILE"
        $QS -p "$SHELL_QML_PATH" ipc call main handleCommand "$ACTION" "$TARGET" "$SUBTARGET" >/dev/null 2>&1
        exit 0
    fi

    if [[ "$TARGET" == "wallpaper" ]]; then
        handle_wallpaper_prep
        TARGET_THUMB="$(bash "$SCRIPTS_DIR/davincix/kernel/davincix.sh" current --thumb-name 2>/dev/null)"

        $QS -p "$SHELL_QML_PATH" ipc call main handleCommand "$ACTION" "$TARGET" "$TARGET_THUMB" >/dev/null 2>&1
    else
        $QS -p "$SHELL_QML_PATH" ipc call main handleCommand "$ACTION" "$TARGET" "$SUBTARGET" >/dev/null 2>&1
    fi
    exit 0
fi
