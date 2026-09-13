#!/usr/bin/env bash
# Persists the CURRENT live layout to ~/.config/hypr/display-config using the
# canonical (extended) format:
#
#   desc|x|y|scale|mode|transform|vrr|bitdepth|cm|mirror|disabled
#
# desc  = hyprctl "description" (EDID model + serial): survives connector
#         renames across boots, unlike output names (DP-5 -> DP-3).
# mode  = exact mode string from availableModes (e.g. 1920x1080@144.11Hz) so a
#         reboot restores the real refresh rate instead of snapping to 60Hz
#         (plain "preferred" and "preferred@<int>" both silently pick 60Hz).
#
# The trailing fields are OPTIONAL for readers: old 5-field files keep working
# (defaults: transform=0, vrr=0, bitdepth=8, cm=auto, mirror="", disabled=0).
#
# vrr: the live JSON exposes a bool, which cannot express 2 (fullscreen-only).
# If settings.json ("monitors", written by the Settings panel) has an explicit
# vrr for that monitor we respect it; otherwise the live bool is used.

JSON="$(hyprctl monitors -j 2>/dev/null)" \
SETTINGS="$(cat "$HOME/.config/hypr/settings.json" 2>/dev/null)" \
python3 - <<'PY'
import json, os, sys

try:
    data = json.loads(os.environ.get("JSON", ""))
except Exception:
    sys.exit(1)

# Desired vrr from settings.json (panel-owned); live bool as fallback.
want_vrr = {}
try:
    st = json.loads(os.environ.get("SETTINGS", "") or "{}")
    for mm in (st.get("monitors") or []):
        if isinstance(mm, dict) and mm.get("name") is not None and mm.get("vrr") is not None:
            want_vrr[mm["name"]] = int(mm["vrr"])
except Exception:
    pass

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

def bitdepth_of(m):
    fmt = str(m.get("currentFormat") or "")
    return 10 if "2101010" in fmt else 8

by_name = {m.get("name", ""): m for m in data}

out = []
for m in data:
    desc = m.get("description") or m["name"]
    name = m.get("name", "")
    live_vrr = 1 if m.get("vrr") else 0
    vrr = want_vrr.get(name, live_vrr)
    mirror = ""
    mo = m.get("mirrorOf") or "none"
    if mo and mo != "none":
        t = by_name.get(mo)
        mirror = (t.get("description") or mo) if t else mo
    out.append("|".join([
        desc,
        str(m["x"]),
        str(m["y"]),
        str(m["scale"]),
        best_mode(m),
        str(int(m.get("transform") or 0)),
        str(vrr),
        str(bitdepth_of(m)),
        str(m.get("colorManagementPreset") or "auto"),
        mirror,
        "1" if m.get("disabled") else "0",
    ]))

print("# Monitor layout: desc|x|y|scale|mode|transform|vrr|bitdepth|cm|mirror|disabled")
print("#   desc = hyprctl description (EDID model+serial, survives connector renames)")
print("#   x,y  = logical position | scale = fractional scale")
print("#   mode = exact Hyprland mode, e.g. 1920x1080@144.11Hz (empty = highest RR)")
print("#   transform = 0/1/2/3 | vrr = 0/1/2 (2 = fullscreen-only) | bitdepth = 8/10")
print("#   cm = color management preset | mirror = desc of the mirrored screen")
print("#   disabled = 1 while the monitor is intentionally disabled")
print("# Fields 6-11 are optional for readers (defaults: 0,0,8,auto,,0)")
print("\n".join(out))
PY
