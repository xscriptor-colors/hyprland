# ═══════════════════════════════════════════════════════════════════════════
# __main__ — permite `python3 -m themesync` (lo usa el wrapper theme-sync.sh).
# ═══════════════════════════════════════════════════════════════════════════
import sys

from .cli import main

if __name__ == "__main__":
    sys.exit(main())
