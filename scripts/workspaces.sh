#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# CACHING & MIGRATION
# -----------------------------------------------------------------------------
source "$(dirname "${BASH_SOURCE[0]}")/caching.sh"
source "$(dirname "${BASH_SOURCE[0]}")/ws-desktops-lib.sh"
qs_ensure_cache "workspaces"

# Roster for the optional unified-desktops pill view (rank order).
ROSTER_JSON="$(printf '%s\n' "${ROSTER_DESCS[@]}" | jq -Rn '[inputs]' 2>/dev/null || echo '[]')"

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

# ============================================================================
# CLASSIC VIEW (default; every monitor-free / single-screen / non-roster rig)
# One pill per workspace id 1..SEQ_END, states taken from all monitors.
# ============================================================================
print_workspaces_classic() {
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

# ============================================================================
# UNIFIED DESKTOPS VIEW (optional; only while >= 2 roster screens are docked
# and settings.json does not force "unifiedDesktops": false)
# One pill per DESKTOP 1..SEQ_END. A desktop is "occupied" when any connected
# roster screen holds a window on that desktop; app icons are aggregated from
# all the screens' windows of that desktop.
# ============================================================================
print_workspaces_unified() {
    WS_ROSTER="$ROSTER_JSON" python3 - "$SEQ_END" > "$QS_RUN_WORKSPACES/workspaces.tmp" <<'PY'
import json, os, subprocess, sys

D = int(sys.argv[1]) if len(sys.argv) > 1 else 8
try:
    roster = json.loads(os.environ.get("WS_ROSTER", "[]"))
except Exception:
    roster = []
W = len(roster)

def hs(*args):
    try:
        out = subprocess.run(["hyprctl", *args], capture_output=True, text=True, timeout=3)
        return json.loads(out.stdout) if out.stdout else []
    except Exception:
        return []

mons = hs("monitors", "-j")
clients = hs("clients", "-j")
ws_list = hs("workspaces", "-j")

by_desc = {m.get("description"): m.get("name") for m in mons}
focused_name = next((m.get("name") for m in mons if m.get("focused")), "")
ranks = []
for i, desc in enumerate(roster, start=1):
    name = by_desc.get(desc)
    if name:
        ranks.append((i, name))

# Which desktop is the focused screen showing?
focused_ws = None
for m in mons:
    if m.get("name") == focused_name:
        focused_ws = m.get("activeWorkspace", {}).get("id")
        break
active_desktop = 1
if isinstance(focused_ws, int) and focused_ws > 0 and W > 0:
    if D * W >= focused_ws >= 1:
        active_desktop = min(D, (focused_ws - 1) // W + 1)

ws_by_id = {}
for w in ws_list:
    ws_by_id[w.get("id")] = w.get("lastwindowtitle", "")

cls_by_ws = {}
for c in clients:
    ws = c.get("workspace", {}).get("id")
    cls = c.get("class", "")
    if ws and cls:
        cls_by_ws.setdefault(ws, []).append(cls)

out = []
for d in range(1, D + 1):
    titles, classes, has_win = [], [], False
    for rank, _name in ranks:
        wid = (d - 1) * W + rank
        if wid in ws_by_id:
            has_win = True
        if ws_by_id.get(wid):
            titles.append(ws_by_id[wid])
        classes.extend(cls_by_ws.get(wid, []))
    if d == active_desktop:
        state = "active"
    elif has_win:
        state = "occupied"
    else:
        state = "empty"
    uniq_cls = []
    for c in classes:
        if c not in uniq_cls:
            uniq_cls.append(c)
    out.append({
        "id": d,
        "state": state,
        "tooltip": " | ".join(dict.fromkeys(titles)) or ("Empty" if not has_win else ""),
        "classes": ",".join(uniq_cls),
    })

print(json.dumps(out))
PY
    mv -f "$QS_RUN_WORKSPACES/workspaces.tmp" "$QS_RUN_WORKSPACES/workspaces.json"
}

print_workspaces() {
    if [[ "$(ws_desktops_unified)" == "yes" ]]; then
        print_workspaces_unified
    else
        print_workspaces_classic
    fi
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
