# ═══════════════════════════════════════════════════════════════════════════
# browsers — light/dark scheme in Brave/Beta and Firefox.
#
# - Brave/Beta: profile prefs (browser.theme.color_scheme2 1=light/2=dark,
#   follows_system_colors=false, user_color2=accent ARGB). ONLY when the channel
#   is closed: with the browser running, its in-memory prefs would overwrite the
#   change on exit.
# - Firefox: user.js with a managed block (toolbar-theme/content-theme +
#   ui.systemUsesDarkTheme). It is read at startup, so writing it live is safe;
#   the rest of the user's user.js is preserved.
# No profiles (fresh Firefox install) → skipped without error.
# ═══════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import configparser
import glob
import json
import os

from ..core import load_json, palette_hex

NAME = "browsers"
DESCRIPTION = "light/dark scheme in Brave/Beta (prefs) and Firefox (user.js)"

# (channel directory, pgrep pattern, label)
BRAVE_DIRS = (
    (".config/BraveSoftware/Brave-Browser", "/opt/brave-bin/brave", "brave"),
    (".config/BraveSoftware/Brave-Browser-Beta", "brave-browser-beta", "brave-beta"),
)
FIREFOX_REL = ".mozilla/firefox"

FF_BEGIN = "// === xscriptor-colors theme-sync (managed) ==="
FF_END = "// === end xscriptor-colors ==="
FF_KEYS = ("browser.theme.toolbar-theme", "browser.theme.content-theme",
           "ui.systemUsesDarkTheme")


def available(env) -> bool:
    # Always: the "no profiles / running" messages are informational.
    return True


def apply(env) -> list:
    out = []
    scheme = env.scheme_int
    accent_hex = palette_hex(env.palette, "color5") or palette_hex(env.palette, "color1")
    try:
        accent = 0xFF000000 | int(str(accent_hex).lstrip("#"), 16)
    except ValueError:
        accent = 0

    out.extend(_brave(env, scheme, accent))
    out.extend(_firefox(env, scheme))
    return out


# ── Brave / Brave Beta ────────────────────────────────────────────────────────

def _brave(env, scheme: int, accent: int) -> list:
    out = []
    for rel, pattern, label in BRAVE_DIRS:
        bdir = env.home / rel
        if not bdir.is_dir():
            continue
        if env.pgrep(pattern):
            if label == "brave":
                out.append("brave: running; theme prefs untouched "
                           "(applies after closing and reopening)")
            else:
                out.append("brave-beta: running; theme prefs untouched")
            continue

        changed = 0
        for pref in sorted(bdir.glob("*/Preferences")):
            base = pref.parent.name
            if not (base == "Default" or base.startswith("Profile ")):
                continue
            data = load_json(pref)
            if not isinstance(data, dict):
                continue
            theme = data.setdefault("browser", {}).setdefault("theme", {})
            theme["color_scheme2"] = scheme
            theme["follows_system_colors"] = False
            theme["user_color2"] = accent
            if env.dry_run:
                env.note("[dry-run] %s" % pref)
            else:
                tmp = str(pref) + ".xsc.tmp"
                with open(tmp, "w", encoding="utf-8") as f:
                    json.dump(data, f, separators=(",", ":"))
                os.replace(tmp, pref)
            changed += 1
        out.append("brave theme prefs updated: %d profile(s)" % changed)
    return out


# ── Firefox ───────────────────────────────────────────────────────────────────

def _firefox_profiles(ffdir) -> list:
    """Profiles from profiles.ini; fallback to any directory with prefs.js."""
    profiles = []
    ini = os.path.join(str(ffdir), "profiles.ini")
    if os.path.isfile(ini):
        cp = configparser.ConfigParser()
        try:
            cp.read(ini)
            for sec in cp.sections():
                if sec.startswith("Profile") and cp.has_option(sec, "Path"):
                    p = cp.get(sec, "Path")
                    if cp.has_option(sec, "IsRelative") and cp.get(sec, "IsRelative") == "1":
                        p = os.path.join(str(ffdir), p)
                    profiles.append(p)
        except Exception:
            pass
    if not profiles:
        profiles = [os.path.dirname(p) for p in glob.glob(os.path.join(str(ffdir), "*", "prefs.js"))]
    return profiles


def _firefox(env, scheme: int) -> list:
    out = []
    ffdir = env.home / FIREFOX_REL
    if not ffdir.is_dir():
        return ["firefox: no profiles (~/.mozilla/firefox does not exist); skipped"]

    for prof in _firefox_profiles(ffdir):
        if not os.path.isdir(prof):
            continue
        uj = os.path.join(prof, "user.js")

        # Keep the whole user.js except our block and managed keys.
        kept, inside = [], False
        if os.path.isfile(uj):
            for ln in open(uj, encoding="utf-8", errors="replace"):
                t = ln.strip()
                if t == FF_BEGIN:
                    inside = True
                    continue
                if t == FF_END:
                    inside = False
                    continue
                if inside:
                    continue
                if any(k in ln for k in FF_KEYS):
                    continue
                kept.append(ln.rstrip("\n"))

        block = [FF_BEGIN,
                 'user_pref("browser.theme.toolbar-theme", %s);' % scheme,
                 'user_pref("browser.theme.content-theme", %s);' % scheme,
                 'user_pref("ui.systemUsesDarkTheme", %d);' % (1 if scheme == 2 else 0),
                 FF_END]
        env.write(uj, "\n".join(kept + [""] + block) + "\n")
        out.append("firefox user.js updated: %s" % prof)
    return out
