#!/usr/bin/env bash
# Authoritative monitor layout restorer + reconciler.
#
# Applies the layout saved in ~/.config/hypr/display-config and keeps it that
# way: a poll loop every ~2s compares the live state of every saved screen
# (matched by EDID DESCRIPTION, which survives connector renames like
# DP-5 -> DP-3) against the saved x/y/scale/refresh-rate and re-applies any
# drift. Recovering from:
#   - dock monitors that enumerate after login,
#   - unplug/re-plug (re-dock),
#   - stray `hyprctl reload` that resets outputs to "auto",
#   - kernel renaming connectors between boots.
#
# Self-healing means edits made through your own tools are safe: monitor-
# manager.sh, scale-menu.sh and quickshell Config.qml all re-persist
# display-config after applying, so the reconciler converges instead of
# fighting them. Manually re-arranging WITHOUT persisting (e.g. wdisplays)
# will be reverted within ~2-4s.
#
# Started from autostart.lua (hyprland.start). Idempotent: re-applying the
# same values is a visual no-op.

STATE="$HOME/.config/hypr/display-config"

# Apply a single saved rule. `desc:` is accepted by hl.monitor and uniquely
# identifies the physical screen even when its connector was renamed.
apply_rule() {
    local desc="$1" x="$2" y="$3" scale="$4" mode="$5"
    [ -z "$mode" ] && mode="highrr"
    hyprctl eval "hl.monitor({ output = \"desc:$desc\", mode = \"$mode\", position = \"${x}x${y}\", scale = ${scale} })" >/dev/null 2>&1
}

# Returns, one per line, the saved rules (desc|x|y|scale|mode) whose monitor is
# currently connected AND drifted from the saved geometry/refresh. Monitors not
# connected yet are ignored here; the next poll catches them when they appear.
drifted() {
    python3 - "$STATE" <<'PY'
import json, os, sys
try:
    live = json.loads(os.popen("hyprctl monitors -j 2>/dev/null").read())
except Exception:
    sys.exit(1)
by = {}
for m in live:
    by[m.get("description", "")] = m
out = []
for line in open(sys.argv[1], encoding="utf-8"):
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    p = line.split("|")
    if len(p) < 4:
        continue
    desc, x, y, scale, mode = p[0], p[1], p[2], p[3], (p[4] if len(p) > 4 else "")
    m = by.get(desc)
    if not m:
        continue
    rate = None
    if mode and "@" in mode:
        try:
            rate = float(mode.split("@")[1].replace("Hz", ""))
        except Exception:
            rate = None
    ok = (m["x"] == int(x) and m["y"] == int(y)
          and abs(m["scale"] - float(scale)) < 0.01)
    if rate is not None and abs(m["refreshRate"] - rate) > 0.5:
        ok = False
    if not ok:
        out.append((desc, x, y, scale, mode))
for t in out:
    print("|".join(t))
PY
}

# Wait a moment for monitors that may still be enumerating, then reconcile in a
# loop. After any apply we sleep longer so concurrent modesets don't stomp on
# each other (avoids DRM "Device or resource busy" storms).
sleep 3
while true; do
    changed=0
    while IFS='|' read -r desc x y scale mode; do
        [ -z "$desc" ] && continue
        apply_rule "$desc" "$x" "$y" "$scale" "$mode"
        changed=1
        sleep 0.8
    done < <(drifted)
    if [ "$changed" = "1" ]; then
        sleep 4
    else
        sleep 2
    fi
done
