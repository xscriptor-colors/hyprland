# ═══════════════════════════════════════════════════════════════════════════
# __main__ — enables `python3 -m themesync` (used by the theme-sync.sh wrapper).
# ═══════════════════════════════════════════════════════════════════════════
import sys

from .cli import main

if __name__ == "__main__":
    sys.exit(main())
