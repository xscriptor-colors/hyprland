# ═══════════════════════════════════════════════════════════════════════════
# core — shared utilities for every target.
#
# Palette/settings loading, color math (rgb/mix/luminance/contrast), atomic
# writes, marker-based managed blocks and binary resolution. The ~/.local/bin
# fallback is essential: the palette hook runs from Quickshell, whose PATH does
# not include that directory (xfetch lives there and it bit us once).
# ═══════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import json
import os
import shutil
import subprocess
from dataclasses import dataclass, field
from pathlib import Path

DEFAULT_SLUG = "x"

# Metadata files inside the palettes directory (they are not palettes).
METADATA_FILES = ("index.json", "schema.json")


# ── Color ─────────────────────────────────────────────────────────────────────

def rgb(c: str) -> tuple[int, int, int]:
    """Normalize '#rrggbb' (or '#rrggbbaa') to (r, g, b) 0..255."""
    h = str(c or "").lstrip("#")
    if len(h) >= 6:
        h = h[:6]
    try:
        n = int(h, 16)
    except ValueError:
        return (0, 0, 0)
    return ((n >> 16) & 255, (n >> 8) & 255, n & 255)


def hexstr(r: float, g: float, b: float) -> str:
    """(r, g, b) → '#rrggbb', clamped to 0..255."""
    clamp = lambda v: max(0, min(255, round(v)))
    return "#%02x%02x%02x" % (clamp(r), clamp(g), clamp(b))


def mix(a: str, b: str, t: float) -> str:
    """Blend a → b by t (0..1). Returns '#rrggbb'."""
    ca, cb = rgb(a), rgb(b)
    return hexstr(ca[0] + (cb[0] - ca[0]) * t,
                  ca[1] + (cb[1] - ca[1]) * t,
                  ca[2] + (cb[2] - ca[2]) * t)


def luminance(c: str) -> float:
    """WCAG relative luminance of a hex color."""
    def lin(v: float) -> float:
        v /= 255.0
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = rgb(c)
    return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)


def contrast(a: str, b: str) -> float:
    """WCAG contrast ratio between two hex colors."""
    la, lb = luminance(a), luminance(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


def argb(c: str) -> str:
    """'#rrggbb' → '#ffrrggbb' (qt6ct/qt5ct color scheme format)."""
    return "#ff" + str(c).lstrip("#").lower()


def best_fg(accent: str, fg: str, bg: str) -> str:
    """Of fg/bg, whichever contrasts most with accent (text over the accent)."""
    return fg if contrast(accent, fg) >= contrast(accent, bg) else bg


# ── Palettes and settings ─────────────────────────────────────────────────────

def load_json(path: Path, default=None):
    """Failure-tolerant JSON load (strict JSON only; JSONC is not attempted)."""
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return default


def load_palettes(palettes_dir: Path) -> list:
    """All palettes, sorted by file name.

    Metadata files in the directory are skipped (index.json = panel card model,
    schema.json = format contract): only files with palette data count.
    """
    out = []
    for pf in sorted(Path(palettes_dir).glob("*.json")):
        if pf.name in METADATA_FILES:
            continue
        pal = load_json(pf)
        if isinstance(pal, dict):
            pal.setdefault("slug", pf.stem)
            out.append(pal)
    return out


def active_slug(settings: dict) -> str:
    """Active palette slug from settings.json (dock.palette); 'x' if missing."""
    dock = settings.get("dock") if isinstance(settings, dict) else None
    slug = dock.get("palette") if isinstance(dock, dict) else None
    return str(slug) if slug else DEFAULT_SLUG


def palette_bg_fg(pal: dict) -> tuple[str, str]:
    """(background, foreground) with fallback to base16 color0/color7."""
    b = pal.get("base16") or {}
    bg = pal.get("background") or b.get("color0") or "#000000"
    fg = pal.get("foreground") or b.get("color7") or "#ffffff"
    return bg, fg


def palette_hex(pal: dict, key: str, fallback: str = "#000000") -> str:
    """Palette color by key: 'background'/'foreground' or 'colorN'."""
    b = pal.get("base16") or {}
    if key == "background":
        return pal.get("background") or b.get("color0") or fallback
    if key == "foreground":
        return pal.get("foreground") or b.get("color7") or fallback
    return b.get(key) or fallback


# ── Files ─────────────────────────────────────────────────────────────────────

def read_text(path: Path) -> str:
    """Failure-tolerant read (utf-8 with replacement); '' if missing."""
    try:
        return Path(path).read_text(encoding="utf-8", errors="replace")
    except Exception:
        return ""


def atomic_write(path: Path, text: str) -> None:
    """Atomic write (tmp + rename), creating the parent directory."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".xsc.tmp")
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(text)
    os.replace(tmp, path)


def strip_block(lines: list, begin: str, end: str) -> tuple[list, bool]:
    """Drop the lines of the managed block [begin..end].

    Returns (remaining_lines, had_block). Compares with strip() so indentation
    is tolerated.
    """
    kept, inside, found = [], False, False
    for ln in lines:
        t = ln.strip()
        if t == begin:
            inside, found = True, True
            continue
        if t == end:
            inside = False
            continue
        if inside:
            continue
        kept.append(ln)
    return kept, found


# ── Binaries ──────────────────────────────────────────────────────────────────

def find_binary(name: str, home: Path | None = None) -> str | None:
    """PATH first; fallback to ~/.local/bin (missing from Quickshell's PATH)."""
    found = shutil.which(name)
    if found:
        return found
    if home is not None:
        candidate = Path(home) / ".local/bin" / name
        if candidate.is_file() and os.access(candidate, os.X_OK):
            return str(candidate)
    return None


# ── Execution context ─────────────────────────────────────────────────────────

@dataclass
class Env:
    """Context every target receives: paths, active palette and helpers."""
    home: Path
    palettes_dir: Path
    settings_path: Path
    slug: str
    palettes: list
    palette: dict
    dry_run: bool = False
    log: list = field(default_factory=list)

    # -- state ----------------------------------------------------------------
    @property
    def light(self) -> bool:
        """Does the active palette have a light background? (luminance > 0.5)"""
        bg, _ = palette_bg_fg(self.palette)
        return luminance(bg) > 0.5

    @property
    def scheme_int(self) -> int:
        """1 = light, 2 = dark (browser.theme.color_scheme2)."""
        return 1 if self.light else 2

    def note(self, msg: str) -> None:
        self.log.append(msg)

    # -- files ----------------------------------------------------------------
    def write(self, path, text: str) -> None:
        """Write honoring dry-run."""
        path = Path(path)
        if self.dry_run:
            self.note("[dry-run] would write %s (%d bytes)" % (path, len(text)))
            return
        atomic_write(path, text)

    def mkdir(self, path) -> None:
        if not self.dry_run:
            Path(path).mkdir(parents=True, exist_ok=True)

    def unlink(self, path) -> None:
        if self.dry_run:
            return
        try:
            Path(path).unlink(missing_ok=True)
        except Exception:
            pass

    def copytree_once(self, src, dst) -> None:
        """Recursive copy only if dst does not exist (one-time .bak snapshot)."""
        src, dst = Path(src), Path(dst)
        if dst.exists() or self.dry_run:
            return
        try:
            shutil.copytree(src, dst)
        except Exception:
            pass

    # -- processes ------------------------------------------------------------
    def binary(self, name: str) -> str | None:
        return find_binary(name, self.home)

    def pgrep(self, pattern: str) -> bool:
        """Is any process matching pattern running? (browser guards)"""
        try:
            return subprocess.run(["pgrep", "-f", pattern],
                                  stdout=subprocess.DEVNULL,
                                  stderr=subprocess.DEVNULL).returncode == 0
        except Exception:
            return False

    def run(self, cmd, timeout: int = 10) -> bool:
        """Run an external binary; True if it exits with code 0."""
        if self.dry_run:
            self.note("[dry-run] would run: %s" % " ".join(str(c) for c in cmd))
            return True
        try:
            return subprocess.run(cmd, stdout=subprocess.DEVNULL,
                                  stderr=subprocess.DEVNULL,
                                  timeout=timeout).returncode == 0
        except Exception:
            return False

    def capture(self, cmd, timeout: int = 10) -> str:
        """Run and return stdout ('' on failure)."""
        try:
            r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
            return r.stdout or ""
        except Exception:
            return ""
