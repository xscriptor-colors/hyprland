#!/usr/bin/env bash
# Persists the CURRENT live layout to ~/.config/hypr/display-config using the
# canonical format: desc|x|y|scale|mode (see header of display-config).
#
# desc  = hyprctl "description" (EDID model + serial): survives connector
#         renames across boots, unlike output names (DP-5 -> DP-3).
# mode  = exact mode string from availableModes (e.g. 1920x1080@144.11Hz) so a
#         reboot restores the real refresh rate instead of snapping to 60Hz
#         (plain "preferred" and "preferred@<int>" both silently pick 60Hz).

JSON="$(hyprctl monitors -j 2>/dev/null)" python3 - <<'PY'
import json, os, sys

try:
    data = json.loads(os.environ.get("JSON", ""))
except Exception:
    sys.exit(1)

def best_mode(m):
    target = m.get("refreshRate", 60)
    cands = []
    for s in m.get("availableModes") or []:
        try:
            rate = float(s.split("@")[1].replace("Hz", ""))
        except Exception:
            continue
        cands.append((abs(rate - target), s))
    if cands:
        return min(cands)[1]
    return "%dx%d@%.2fHz" % (m["width"], m["height"], target)

out = []
for m in data:
    if m.get("disabled"):
        continue  # intentional (e.g. "Only primary"): don't re-enable on boot
    desc = m.get("description") or m["name"]
    out.append("%s|%s|%s|%s|%s" % (desc, m["x"], m["y"], m["scale"], best_mode(m)))

print("# Monitor layout: desc|x|y|scale|mode")
print("#   desc = hyprctl description (EDID model+serial, survives connector renames)")
print("#   x,y  = logical position | scale = fractional scale")
print("#   mode = exact Hyprland mode, e.g. 1920x1080@144.11Hz (empty = highest RR)")
print("\n".join(out))
PY
