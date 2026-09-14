# ═══════════════════════════════════════════════════════════════════════════
# core — utilidades compartidas por todos los targets.
#
# Aquí vive lo común: carga de paletas y settings, operaciones de color
# (rgb/mix/luminancia/contraste), escritura atómica, bloques gestionados con
# marcadores y resolución de binarios. El fallback a ~/.local/bin es
# imprescindible: el hook de paleta corre desde Quickshell, cuyo PATH no
# incluye ese directorio (xfetch vive ahí y ya nos mordió una vez).
# ═══════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import json
import os
import shutil
import subprocess
from dataclasses import dataclass, field
from pathlib import Path

DEFAULT_SLUG = "x"


# ── Color ─────────────────────────────────────────────────────────────────────

def rgb(c: str) -> tuple[int, int, int]:
    """Normaliza '#rrggbb' (o '#rrggbbaa') a (r, g, b) 0..255."""
    h = str(c or "").lstrip("#")
    if len(h) >= 6:
        h = h[:6]
    try:
        n = int(h, 16)
    except ValueError:
        return (0, 0, 0)
    return ((n >> 16) & 255, (n >> 8) & 255, n & 255)


def hexstr(r: float, g: float, b: float) -> str:
    """(r, g, b) → '#rrggbb' con clamp a 0..255."""
    clamp = lambda v: max(0, min(255, round(v)))
    return "#%02x%02x%02x" % (clamp(r), clamp(g), clamp(b))


def mix(a: str, b: str, t: float) -> str:
    """Mezcla a → b por t (0..1). Devuelve '#rrggbb'."""
    ca, cb = rgb(a), rgb(b)
    return hexstr(ca[0] + (cb[0] - ca[0]) * t,
                  ca[1] + (cb[1] - ca[1]) * t,
                  ca[2] + (cb[2] - ca[2]) * t)


def luminance(c: str) -> float:
    """Luminancia relativa (WCAG) de un hex."""
    def lin(v: float) -> float:
        v /= 255.0
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = rgb(c)
    return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)


def contrast(a: str, b: str) -> float:
    """Ratio de contraste WCAG entre dos hex."""
    la, lb = luminance(a), luminance(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


def argb(c: str) -> str:
    """'#rrggbb' → '#ffrrggbb' (formato de color scheme de qt6ct/qt5ct)."""
    return "#ff" + str(c).lstrip("#").lower()


def best_fg(accent: str, fg: str, bg: str) -> str:
    """De fg/bg, el que más contrasta con accent (texto sobre el acento)."""
    return fg if contrast(accent, fg) >= contrast(accent, bg) else bg


# ── Paletas y settings ────────────────────────────────────────────────────────

def load_json(path: Path, default=None):
    """JSON tolerante a fallos (JSONC con // no se intenta: solo JSON estricto)."""
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return default


def load_palettes(palettes_dir: Path) -> list:
    """Todas las paletas (sin index.json), ordenadas por nombre de archivo."""
    out = []
    for pf in sorted(Path(palettes_dir).glob("*.json")):
        if pf.name == "index.json":
            continue
        pal = load_json(pf)
        if isinstance(pal, dict):
            pal.setdefault("slug", pf.stem)
            out.append(pal)
    return out


def active_slug(settings: dict) -> str:
    """Slug de la paleta activa en settings.json (dock.palette); 'x' si falta."""
    dock = settings.get("dock") if isinstance(settings, dict) else None
    slug = dock.get("palette") if isinstance(dock, dict) else None
    return str(slug) if slug else DEFAULT_SLUG


def palette_bg_fg(pal: dict) -> tuple[str, str]:
    """(background, foreground) de una paleta con fallback a base16 0/7."""
    b = pal.get("base16") or {}
    bg = pal.get("background") or b.get("color0") or "#000000"
    fg = pal.get("foreground") or b.get("color7") or "#ffffff"
    return bg, fg


def palette_hex(pal: dict, key: str, fallback: str = "#000000") -> str:
    """Color de paleta por clave: 'background'/'foreground' o 'colorN'."""
    b = pal.get("base16") or {}
    if key == "background":
        return pal.get("background") or b.get("color0") or fallback
    if key == "foreground":
        return pal.get("foreground") or b.get("color7") or fallback
    return b.get(key) or fallback


# ── Ficheros ──────────────────────────────────────────────────────────────────

def read_text(path: Path) -> str:
    """Lectura tolerante (utf-8 con reemplazo); '' si no existe."""
    try:
        return Path(path).read_text(encoding="utf-8", errors="replace")
    except Exception:
        return ""


def atomic_write(path: Path, text: str) -> None:
    """Escritura atómica (tmp + rename) creando el directorio padre."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".xsc.tmp")
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(text)
    os.replace(tmp, path)


def strip_block(lines: list, begin: str, end: str) -> tuple[list, bool]:
    """Quita las líneas del bloque gestionado [begin..end].

    Devuelve (líneas_restantes, había_bloque). Compara por strip() para
    tolerar indentación.
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


# ── Binarios ──────────────────────────────────────────────────────────────────

def find_binary(name: str, home: Path | None = None) -> str | None:
    """PATH primero; fallback a ~/.local/bin (ausente en el PATH de Quickshell)."""
    found = shutil.which(name)
    if found:
        return found
    if home is not None:
        candidate = Path(home) / ".local/bin" / name
        if candidate.is_file() and os.access(candidate, os.X_OK):
            return str(candidate)
    return None


# ── Contexto de ejecución ─────────────────────────────────────────────────────

@dataclass
class Env:
    """Contexto que recibe cada target: rutas, paleta activa y helpers."""
    home: Path
    palettes_dir: Path
    settings_path: Path
    slug: str
    palettes: list
    palette: dict
    dry_run: bool = False
    log: list = field(default_factory=list)

    # -- estado ---------------------------------------------------------------
    @property
    def light(self) -> bool:
        """¿La paleta activa tiene fondo claro? (luminancia > 0.5)"""
        bg, _ = palette_bg_fg(self.palette)
        return luminance(bg) > 0.5

    @property
    def scheme_int(self) -> int:
        """1 = claro, 2 = oscuro (browser.theme.color_scheme2)."""
        return 1 if self.light else 2

    def note(self, msg: str) -> None:
        self.log.append(msg)

    # -- ficheros -------------------------------------------------------------
    def write(self, path, text: str) -> None:
        """Escritura respetando dry-run."""
        path = Path(path)
        if self.dry_run:
            self.note("[dry-run] escribiría %s (%d bytes)" % (path, len(text)))
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
        """Copia recursiva solo si dst no existe (snapshot único, tipo .bak)."""
        src, dst = Path(src), Path(dst)
        if dst.exists() or self.dry_run:
            return
        try:
            shutil.copytree(src, dst)
        except Exception:
            pass

    # -- procesos -------------------------------------------------------------
    def binary(self, name: str) -> str | None:
        return find_binary(name, self.home)

    def pgrep(self, pattern: str) -> bool:
        """¿Hay algún proceso que case con pattern? (guards de navegador)."""
        try:
            return subprocess.run(["pgrep", "-f", pattern],
                                  stdout=subprocess.DEVNULL,
                                  stderr=subprocess.DEVNULL).returncode == 0
        except Exception:
            return False

    def run(self, cmd, timeout: int = 10) -> bool:
        """Ejecuta un binario externo; True si termina con código 0."""
        if self.dry_run:
            self.note("[dry-run] ejecutaría: %s" % " ".join(str(c) for c in cmd))
            return True
        try:
            return subprocess.run(cmd, stdout=subprocess.DEVNULL,
                                  stderr=subprocess.DEVNULL,
                                  timeout=timeout).returncode == 0
        except Exception:
            return False

    def capture(self, cmd, timeout: int = 10) -> str:
        """Ejecuta y devuelve stdout ('' si falla)."""
        try:
            r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
            return r.stdout or ""
        except Exception:
            return ""
