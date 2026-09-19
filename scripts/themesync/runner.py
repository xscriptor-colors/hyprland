# ═══════════════════════════════════════════════════════════════════════════
# runner — orchestrates target execution.
#
# Walks the registry (or a subset via --targets), checks availability and runs
# apply(). A failing target never aborts the rest: the error is recorded and
# the runner continues (better than the old monolithic `set -e`, where one
# failure could leave sections unprocessed).
# ═══════════════════════════════════════════════════════════════════════════
from __future__ import annotations

from .core import Env
from .targets import BY_NAME, TARGETS


def run(env: Env, only: list | None = None) -> int:
    """Run the selected targets. Returns 1 if anything failed."""
    if only:
        unknown = [n for n in only if n not in BY_NAME]
        for name in unknown:
            print("unknown target: %s" % name)
        targets = [BY_NAME[n] for n in only if n in BY_NAME]
    else:
        targets = TARGETS

    failures = len([n for n in (only or []) if n not in BY_NAME])

    for target in targets:
        before = len(env.log)
        try:
            if not target.available(env):
                print("%s: not available; skipped" % target.NAME)
                continue
            for line in target.apply(env):
                print(line)
        except Exception as exc:  # a broken target must not kill the rest
            failures += 1
            print("%s: ERROR: %s" % (target.NAME, exc))
        finally:
            # Target notes (e.g. --dry-run traces).
            for line in env.log[before:]:
                print(line)
    return 1 if failures else 0


def listing(env: Env) -> list:
    """Lines for `--list`: name, availability and description."""
    out = []
    for target in TARGETS:
        try:
            ok = target.available(env)
        except Exception:
            ok = False
        out.append("%-9s %s  %s" % (target.NAME, "yes" if ok else "--", target.DESCRIPTION))
    return out
