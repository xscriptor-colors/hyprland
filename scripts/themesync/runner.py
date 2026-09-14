# ═══════════════════════════════════════════════════════════════════════════
# runner — orquesta la ejecución de los targets.
#
# Recorre el registro (o un subconjunto con --targets), comprueba
# disponibilidad y ejecuta apply(). Un fallo en un target NO aborta el resto:
# se anota el error y se continúa (mejor que el `set -e` monolítico anterior,
# donde un fallo podía dejar secciones sin procesar).
# ═══════════════════════════════════════════════════════════════════════════
from __future__ import annotations

from .core import Env
from .targets import BY_NAME, TARGETS


def run(env: Env, only: list | None = None) -> int:
    """Ejecuta los targets seleccionados. Devuelve 1 si hubo fallos."""
    if only:
        unknown = [n for n in only if n not in BY_NAME]
        for name in unknown:
            print("target desconocido: %s" % name)
        targets = [BY_NAME[n] for n in only if n in BY_NAME]
    else:
        targets = TARGETS

    failures = len([n for n in (only or []) if n not in BY_NAME])
    for target in targets:
        before = len(env.log)
        try:
            if not target.available(env):
                print("%s: no disponible; se omite" % target.NAME)
                continue
            for line in target.apply(env):
                print(line)
        except Exception as exc:  # un target roto no tumba el resto
            failures += 1
            print("%s: ERROR: %s" % (target.NAME, exc))
        finally:
            # Notas del target (p. ej. trazas de --dry-run).
            for line in env.log[before:]:
                print(line)
    return 1 if failures else 0


def listing(env: Env) -> list:
    """Líneas de `--list`: nombre, disponibilidad y descripción."""
    out = []
    for target in TARGETS:
        try:
            ok = target.available(env)
        except Exception:
            ok = False
        out.append("%-9s %s  %s" % (target.NAME, "sí" if ok else "--", target.DESCRIPTION))
    return out
