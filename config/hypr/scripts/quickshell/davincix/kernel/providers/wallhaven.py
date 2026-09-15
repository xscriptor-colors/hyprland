#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════
# wallhaven provider — emits "thumb|full" pairs on stdout.
#
# Same contract as providers/ddg.py: search.sh consumes the pairs, downloads
# the thumbnails and validates the full URLs. This provider talks to the
# public Wallhaven API (no key needed for SFW) and paginates via a page
# number stored in the cursor file (the same file ddg uses for its "next"
# URL, so "load more" works per source).
# ═══════════════════════════════════════════════════════════════════════════
import json
import os
import sys
import time
import urllib.parse
import urllib.request

LOG_DIR = os.environ.get("DAVINCIX_LOG_DIR", "/tmp/quickshell/logs")
LOG_FILE = os.path.join(LOG_DIR, "wallhaven_scraper.log")
API = "https://wallhaven.cc/api/v1/search"
MIN_W, MIN_H = 1920, 1080

CURSOR_FILE = None  # page number to fetch next (load more)


def log(msg):
    try:
        with open(LOG_FILE, "a") as f:
            f.write(f"{time.strftime('%H:%M:%S')} - {msg}\n")
    except:
        pass


def save_cursor(page):
    if not CURSOR_FILE:
        return
    try:
        with open(CURSOR_FILE, "w") as f:
            f.write(str(page))
    except:
        pass


def load_cursor():
    try:
        with open(CURSOR_FILE, "r") as f:
            return int(f.read().strip() or "1")
    except:
        return 1


def main():
    global CURSOR_FILE
    log("=== NEW WALLHAVEN SEARCH ===")
    if len(sys.argv) < 2:
        log("ERROR: No query provided.")
        return

    continue_mode = "--continue" in sys.argv
    if "--cursor-file" in sys.argv:
        CURSOR_FILE = sys.argv[sys.argv.index("--cursor-file") + 1]
        sys.argv.remove(CURSOR_FILE)
        sys.argv.remove("--cursor-file")
    if continue_mode:
        sys.argv.remove("--continue")

    query = sys.argv[1].strip()
    page = load_cursor() if continue_mode else 1
    log(f"Query: '{query}' (page {page}, continue={continue_mode})")

    params = {
        "q": query,
        "atleast": f"{MIN_W}x{MIN_H}",
        "purity": "100",        # SFW
        "sorting": "relevance",
        "page": str(page),
    }
    url = API + "?" + urllib.parse.urlencode(params)

    headers = {
        "User-Agent": "davincix/0.1 (wallpaper engine)",
        "Accept": "application/json",
    }

    try:
        req = urllib.request.Request(url, headers=headers)
        data = json.loads(urllib.request.urlopen(req, timeout=15).read().decode("utf-8"))
    except Exception as e:
        log(f"ERROR fetching page {page}: {str(e)}")
        return

    results = data.get("data", [])
    links = 0
    for res in results:
        width = int(res.get("dimension_x", 0))
        height = int(res.get("dimension_y", 0))
        full = res.get("path")
        thumb = (res.get("thumbs") or {}).get("original") or (res.get("thumbs") or {}).get("large")
        if width >= MIN_W and height >= MIN_H and full and thumb:
            try:
                sys.stdout.write(f"{thumb}|{full}\n")
                sys.stdout.flush()
                links += 1
            except BrokenPipeError:
                log("Broken pipe. Exiting.")
                os._exit(0)

    meta = data.get("meta", {})
    last_page = int(meta.get("last_page", page))
    if page < last_page:
        save_cursor(page + 1)
        log(f"Page {page}/{last_page}: {links} FHD links. Cursor -> {page + 1}")
    else:
        log(f"Page {page}/{last_page}: {links} FHD links. No more pages.")
    log(f"=== WALLHAVEN COMPLETE ({links} links) ===")


if __name__ == "__main__":
    try:
        os.remove(LOG_FILE)
    except:
        pass

    try:
        main()
        sys.stdout.flush()
    except BrokenPipeError:
        os._exit(0)
    except KeyboardInterrupt:
        os._exit(1)
    except Exception as e:
        log(f"FATAL: {str(e)}")
        os._exit(1)
