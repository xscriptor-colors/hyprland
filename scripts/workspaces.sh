#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# CACHING & MIGRATION
# -----------------------------------------------------------------------------
source "$(dirname "${BASH_SOURCE[0]}")/caching.sh"
qs_ensure_cache "workspaces"

# ============================================================================
# 1. ZOMBIE PREVENTION
# Kills any older instances of this script. When Quickshell reloads, 
# it can leave the old listener pipelines running in the background infinitely.
# ============================================================================
for pid in $(pgrep -f "workspaces.sh"); do
    if [ "$pid" != "$$" ] && [ "$pid" != "$PPID" ]; then
        kill -9 "$pid" 2>/dev/null
    fi
done

# Cleanly kill immediate children (like socat) when the script exits normally
cleanup() {
    pkill -P $$ 2>/dev/null
}
trap cleanup EXIT SIGTERM SIGINT

# --- Special Cleanup for Network/Bluetooth ---
# The network toggle starts a background bluetooth scan that must be killed explicitly.
BT_PID_FILE="$QS_RUN_WORKSPACES/bt_scan_pid"

if [ -f "$BT_PID_FILE" ]; then
    kill $(cat "$BT_PID_FILE") 2>/dev/null
    rm -f "$BT_PID_FILE"
fi

# Ensure bluetooth scan is explicitly turned off (timeout prevents deadlocks on fresh installs)
(timeout 2 bluetoothctl scan off > /dev/null 2>&1) &
# ---------------------------------------------

# Configuration: Parse from settings.json dynamically, fallback to 8
SETTINGS_FILE="$HOME/.config/hypr/settings.json"
SEQ_END=$(jq -r '.workspaceCount // 8' "$SETTINGS_FILE" 2>/dev/null)
# Double check it is a valid integer to prevent jq errors later
if ! [[ "$SEQ_END" =~ ^[0-9]+$ ]]; then
    SEQ_END=8
fi

print_workspaces() {
    # Get raw data with a timeout fallback
    spaces=$(timeout 2 hyprctl workspaces -j 2>/dev/null)
    active=$(timeout 2 hyprctl activeworkspace -j 2>/dev/null | jq '.id')

    # Failsafe if hyprctl crashes to prevent jq from outputting errors
    if [ -z "$spaces" ] || [ -z "$active" ]; then return; fi

    # Generate the JSON with workspace states
    echo "$spaces" | jq --unbuffered --argjson a "$active" --arg end "$SEQ_END" -c '
        (map({(.id|tostring): .}) | add) as $s |
        [range(1; ($end|tonumber)+1)] | map(. as $i |
            (if $i == $a then "active" elif ($s[$i|tostring] != null and $s[$i|tostring].windows > 0) then "occupied" else "empty" end) as $state |
            (if $s[$i|tostring] != null then $s[$i|tostring].lastwindowtitle else "Empty" end) as $win |
            {id: $i, state: $state, tooltip: $win}
        )
    ' > "$QS_RUN_WORKSPACES/workspaces.tmp"
    
    # Add app classes per workspace using Python (simpler than complex jq)
    python3 -c "
import json, subprocess, sys
try:
    with open('$QS_RUN_WORKSPACES/workspaces.tmp') as f:
        data = json.load(f)
except:
    sys.exit(0)
try:
    out = subprocess.run(['timeout', '2', 'hyprctl', 'clients', '-j'], capture_output=True, text=True, timeout=3)
    clients = json.loads(out.stdout) if out.stdout else []
except:
    clients = []
# Build workspace -> classes map
ws_classes = {}
for c in clients:
    ws = str(c.get('workspace', {}).get('id', ''))
    cls = c.get('class', '')
    if ws and cls:
        ws_classes.setdefault(ws, []).append(cls)
# Deduplicate and add to each workspace (as comma-separated string - ListModel friendly)
for entry in data:
    ws_id = str(entry['id'])
    classes = list(dict.fromkeys(ws_classes.get(ws_id, [])))  # unique, preserve order
    entry['classes'] = ','.join(classes)
with open('$QS_RUN_WORKSPACES/workspaces.json', 'w') as f:
    json.dump(data, f)
" 2>/dev/null || mv "$QS_RUN_WORKSPACES/workspaces.tmp" "$QS_RUN_WORKSPACES/workspaces.json"
    
    rm -f "$QS_RUN_WORKSPACES/workspaces.tmp"
}

# Print initial state
print_workspaces

# ============================================================================
# 2. THE EVENT DEBOUNCER
# Listen to Hyprland socket wrapped in an infinite loop
# ============================================================================
while true; do
    socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read -r line; do
        case "$line" in
            workspace*|focusedmon*|activewindow*|createwindow*|closewindow*|movewindow*|destroyworkspace*)
                
                # -> THE FIX <-
                # Hyprland emits HUNDREDS of events a second when you move/resize windows.
                # This reads and discards all subsequent events arriving within a 50ms window.
                # It bundles the storm into a single UI update, completely preventing CPU clogging!
                while read -t 0.05 -r extra_line; do
                    continue
                done

                print_workspaces
                ;;
        esac
    done
    sleep 1
done
