#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# UNIFIED DESKTOPS — SHARED HELPERS
# -----------------------------------------------------------------------------
# Multi-monitor "desktop" grouping: each desktop (as Windows/macOS understand
# it) spans one workspace per physical screen. Workspace ID for desktop `d` and
# screen rank `r` (1-based) is:  id = (d - 1) * ROSTER_W + r
#
# The mode is OPTIONAL and inert on other hardware / single-screen setups:
#   - It only activates while >= 2 screens from ROSTER_DESCS are connected.
#   - It can be hard-disabled with "unifiedDesktops": false in settings.json.
# Anything else keeps the classic per-monitor workspace behavior untouched.
#
# KEEP THE ROSTER IN SYNC with the MON_* descriptions in
# config/hypr/workspaces.lua (the Lua side only needs them for the boot
# defaults of desktop 1; this file drives the actual switching).

ROSTER_DESCS=(
    "BOE NE160WUM-NXA"
    "Xiaomi Corporation P27FBB-RGGL 5275600003084"
    "Xiaomi Corporation P27FBB-RGGL 5275600003570"
    "Xiaomi Corporation P27FBB-RGGL 5275600072695"
)
ROSTER_W="${#ROSTER_DESCS[@]}"

DESKTOPS_SETTINGS_FILE="${DESKTOPS_SETTINGS_FILE:-$HOME/.config/hypr/settings.json}"

# Number of desktop pills/slots (mirrors the UI "workspaceCount" setting).
ws_desktop_count() {
    local d
    # NOTE: do NOT use `.x // 8` here — jq's `//` also substitutes on `false`.
    d="$(jq -r 'if has("workspaceCount") then .workspaceCount else 8 end' "$DESKTOPS_SETTINGS_FILE" 2>/dev/null)"
    [[ "$d" =~ ^[0-9]+$ ]] || d=8
    echo "$d"
}

# Master switch: settings.json "unifiedDesktops": false forces the classic
# per-monitor behavior even on the full multi-screen rig.
ws_desktops_enabled_in_settings() {
    local v
    v="$(jq -r 'if has("unifiedDesktops") then .unifiedDesktops else true end' "$DESKTOPS_SETTINGS_FILE" 2>/dev/null)"
    [[ "$v" != "false" ]]
}

# Prints "rank<TAB>monitor-name" for every connected roster screen, in rank
# order (rank = slot of that screen inside a desktop, 1..ROSTER_W).
ws_connected_ranks() {
    local -A desc_of_name=()
    local name desc
    while IFS=$'\t' read -r name desc; do
        [ -n "$name" ] && desc_of_name["$name"]="$desc"
    done < <(hyprctl monitors -j 2>/dev/null | jq -r '.[] | [.name, .description] | @tsv')

    local i d
    for ((i = 0; i < ROSTER_W; i++)); do
        d="${ROSTER_DESCS[$i]}"
        for name in "${!desc_of_name[@]}"; do
            if [[ "${desc_of_name[$name]}" == "$d" ]]; then
                printf '%s\t%s\n' "$((i + 1))" "$name"
            fi
        done
    done
}

# Rank (1..ROSTER_W) of a connected monitor by name; empty when not in roster.
ws_rank_of_monitor() {
    local name="$1" rank nm
    while IFS=$'\t' read -r rank nm; do
        if [[ "$nm" == "$name" ]]; then
            echo "$rank"
            return 0
        fi
    done < <(ws_connected_ranks)
    return 1
}

# Name of the currently focused monitor.
ws_focused_monitor() {
    hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .name'
}

# Workspace id that slot `rank` of desktop `desktop` must hold.
ws_slot_id() {
    echo "$(( (${1:-1} - 1) * ROSTER_W + ${2:-1} ))"
}

# "yes" when unified-desktops mode is active right now, "no" otherwise.
ws_desktops_unified() {
    ws_desktops_enabled_in_settings || { echo no; return; }
    if [[ "$(ws_connected_ranks | wc -l)" -ge 2 ]]; then echo yes; else echo no; fi
}

# Clamp a desktop number into 1..D and echo it.
ws_clamp_desktop() {
    local k="${1:-1}" d
    d="$(ws_desktop_count)"
    [[ "$k" =~ ^[0-9]+$ ]] || k=1
    (( k < 1 )) && k=1
    (( k > d )) && k="$d"
    echo "$k"
}

# -----------------------------------------------------------------------------
# ACTIONS (used by qs_manager.sh)
# -----------------------------------------------------------------------------

# Jump every connected roster screen to desktop `k`.
ws_desktop_goto() {
    local k rank name orig
    k="$(ws_clamp_desktop "$1")"
    orig="$(ws_focused_monitor)"
    while IFS=$'\t' read -r rank name; do
        hyprctl eval "hl.dispatch(hl.dsp.focus({ monitor = \"$name\" }))" >/dev/null 2>&1
        hyprctl eval "hl.dispatch(hl.dsp.focus({ workspace = $(ws_slot_id "$k" "$rank") }))" >/dev/null 2>&1
    done < <(ws_connected_ranks)
    [ -n "$orig" ] && hyprctl eval "hl.dispatch(hl.dsp.focus({ monitor = \"$orig\" }))" >/dev/null 2>&1
}

# Move the active window to desktop `k` of ITS OWN screen (same physical
# monitor, different desktop).
ws_desktop_move_window() {
    local k rank slot winmon monid
    k="$(ws_clamp_desktop "$1")"
    monid="$(hyprctl activewindow -j 2>/dev/null | jq -r '.monitor // empty')"
    [ -n "$monid" ] || monid=""
    winmon=""
    if [ -n "$monid" ]; then
        winmon="$(hyprctl monitors -j 2>/dev/null | jq -r --argjson mid "$monid" '.[] | select(.id == $mid) | .name' | head -n1)"
    fi
    rank="$(ws_rank_of_monitor "$winmon")"
    if [ -z "$rank" ]; then
        # Window lives on a screen outside the roster: classic move.
        hyprctl eval "hl.dispatch(hl.dsp.window.move({ workspace = $k }))" >/dev/null 2>&1
        return
    fi
    slot="$(ws_slot_id "$k" "$rank")"
    hyprctl eval "hl.dispatch(hl.dsp.window.move({ workspace = $slot }))" >/dev/null 2>&1
}

# All screens one desktop forward/backward (dir = +1 or -1).
ws_desktop_rel() {
    local dir="${1:-+1}" k cur
    cur="$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // 1')"
    k="$(( (cur - 1) / ROSTER_W + 1 ))"
    if [[ "$dir" == "-1" || "$dir" == "-" || "$dir" == "prev" ]]; then
        ws_desktop_goto "$(( k - 1 ))"
    else
        ws_desktop_goto "$(( k + 1 ))"
    fi
}
