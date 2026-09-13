#!/usr/bin/env bash
# Authoritative monitor layout restorer + reconciler.
#
# Applies the layout saved in ~/.config/hypr/display-config and keeps it that
# way: a poll loop every ~2s compares the live state of every saved screen
# (matched by EDID DESCRIPTION, which survives connector renames like
# DP-5 -> DP-3) against the saved x/y/scale/refresh-rate plus the extended
# fields (transform/vrr/bitdepth/cm/mirror/disabled) and re-applies any drift.
# Recovering from:
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
STATE_BAK="$STATE.bak"

# The reconciler keeps a backup so a missing/accidentally-deleted layout can
# still be recovered at boot (only a deliberate "Reset to auto" removes both).
resolve_state() {
    if [ -s "$STATE" ] && grep -qv '^#' "$STATE"; then
        echo "$STATE"
    elif [ -s "$STATE_BAK" ] && grep -qv '^#' "$STATE_BAK"; then
        echo "$STATE_BAK"
    else
        echo ""
    fi
}

# Apply a single saved rule. `desc:` is accepted by hl.monitor and uniquely
# identifies the physical screen even when its connector was renamed.
# Formato: desc|x|y|scale|mode|transform|vrr|bitdepth|cm|mirror|disabled
# Los campos 6-11 son OPCIONALES: los archivos viejos de 5 campos siguen
# funcionando con defaults (0, 0, 8, auto, "", 0).
apply_rule() {
    local desc="$1" x="$2" y="$3" scale="$4" mode="$5"
    local transform="${6:-0}" vrr="${7:-0}" bitdepth="${8:-8}" cm="${9:-auto}"
    local mirror="${10:-}" disabled="${11:-0}"
    local lua="output = \"desc:$desc\""
    if [ "$disabled" = "1" ]; then
        # Deshabilitado a propósito: solo `disabled` (sin mode/position).
        lua+=", disabled = true"
    else
        [ -z "$mode" ] && mode="highrr"
        lua+=", mode = \"$mode\", position = \"${x}x${y}\""
    fi
    [ -n "$scale" ] && lua+=", scale = $scale"
    [ "$transform" != "0" ] && lua+=", transform = $transform"
    [ "$vrr" != "0" ] && lua+=", vrr = $vrr"
    [ "$bitdepth" != "8" ] && lua+=", bitdepth = $bitdepth"
    [ "$cm" != "auto" ] && lua+=", cm = \"$cm\""
    [ -n "$mirror" ] && lua+=", mirror = \"desc:$mirror\""
    hyprctl eval "hl.monitor({ $lua })" >/dev/null 2>&1
}

# Returns, one per line, the saved rules (desc|x|y|scale|mode|transform|vrr|
# bitdepth|cm|mirror|disabled) whose monitor is currently connected AND drifted
# from the saved state. Monitors not connected yet are ignored here; the next
# poll catches them when they appear.
drifted() {
    python3 - "$1" <<'PY'
import json, os, sys
try:
    live = json.loads(os.popen("hyprctl monitors -j 2>/dev/null").read())
except Exception:
    sys.exit(1)
by = {}
for m in live:
    by[m.get("description", "")] = m
by_name = {m.get("name", ""): m for m in live}
out = []
for line in open(sys.argv[1], encoding="utf-8"):
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    p = line.split("|")
    if len(p) < 4:
        continue
    # Campos extendidos opcionales (retrocompatible con el formato de 5 campos).
    while len(p) < 11:
        p.append("")
    desc, x, y, scale, mode = p[0], p[1], p[2], p[3], p[4]
    transform, vrr, bitdepth, cm, mirror, disabled = p[5], p[6], p[7], p[8], p[9], p[10]
    m = by.get(desc)
    if not m:
        continue
    # ── geometría + rate (como siempre) ──
    ok = (m["x"] == int(x) and m["y"] == int(y)
          and abs(m["scale"] - float(scale)) < 0.01)
    rate = None
    if mode and "@" in mode:
        try:
            rate = float(mode.split("@")[1].replace("Hz", ""))
        except Exception:
            rate = None
    if rate is not None and abs(m["refreshRate"] - rate) > 0.5:
        ok = False
    # ── campos extendidos ──
    if disabled == "1":
        if not m.get("disabled"):
            ok = False
    elif m.get("disabled"):
        ok = False
    if transform and int(m.get("transform") or 0) != int(transform):
        ok = False
    # vrr=1 debe estar activo; vrr=2 (fullscreen-only) reporta false fuera de
    # fullscreen, así que no se puede verificar (no forzamos drift).
    if vrr == "1" and not m.get("vrr"):
        ok = False
    if bitdepth:
        live10 = "2101010" in str(m.get("currentFormat") or "")
        if live10 != (bitdepth == "10"):
            ok = False
    if cm and cm != "auto" and str(m.get("colorManagementPreset") or "") != cm:
        ok = False
    if mirror:
        # mirrorOf es un NOMBRE; el archivo guarda la descripción del espejado.
        mo = m.get("mirrorOf") or "none"
        t = by_name.get(mo) if mo != "none" else None
        live_desc = (t.get("description") or mo) if t else ""
        if live_desc != mirror:
            ok = False
    if not ok:
        out.append((desc, x, y, scale, mode, transform, vrr, bitdepth, cm, mirror, disabled))
for t in out:
    print("|".join(t))
PY
}

# Wait a moment for monitors that may still be enumerating, then reconcile in a
# loop. After any apply we sleep longer so concurrent modesets don't stomp on
# each other (avoids DRM "Device or resource busy" storms).
sleep 3
while true; do
    SRCFILE="$(resolve_state)"
    if [ -z "$SRCFILE" ]; then
        sleep 5
        continue
    fi
    # Grace: si display-config se acaba de escribir (panel/monitor-manager/
    # scale-menu), espera a que asienten los modesets en vez de competir.
    now=$(date +%s)
    mtime=$(stat -c %Y "$SRCFILE" 2>/dev/null || echo 0)
    if [ $((now - mtime)) -lt 3 ]; then
        sleep 2
        continue
    fi
    changed=0
    while IFS='|' read -r desc x y scale mode transform vrr bitdepth cm mirror disabled; do
        [ -z "$desc" ] && continue
        apply_rule "$desc" "$x" "$y" "$scale" "$mode" "$transform" "$vrr" "$bitdepth" "$cm" "$mirror" "$disabled"
        changed=1
        sleep 0.8
    done < <(drifted "$SRCFILE")
    if [ "$changed" = "1" ]; then
        sleep 4
    else
        sleep 2
    fi
    # Keep the backup current every cycle (not only after a drift apply), so a
    # deleted layout can always be recovered on the next boot.
    cp "$SRCFILE" "$STATE_BAK" 2>/dev/null
done
