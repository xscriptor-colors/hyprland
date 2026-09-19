#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════
# pexels provider — short stock videos (live wallpapers) as "thumb|full".
#
# thumb = preview image (Pexels' `image` field), full = the best mp4 file
# >= 1920x1080. Needs an API key (free): PEXELS_KEY env or the keys.conf
# file sourced by search.sh.
# ═══════════════════════════════════════════════════════════════════════════
import json
import os
import sys
import time
import urllib.parse
import urllib.request

LOG_DIR = os.environ.get("DAVINCIX_LOG_DIR", "/tmp/quickshell/logs")
LOG_FILE = os.path.join(LOG_DIR, "pexels_scraper.log")
API = "https://api.pexels.com/videos/search"
MIN_W, MIN_H = 1920, 1080
PER_PAGE = 24

CURSOR_FILE = None  # next page number (load more)


def log(msg):
    try:
        with open(LOG_FILE, "a") as f:
            f.write(f"{time.strftime('%H:%M:%S')} - {msg}\n")
    except:
        pass


def warn_missing_key():
    log("ERROR: PEXELS_KEY not set (env or keys.conf).")
    if os.path.exists("/usr/bin/notify-send"):
        os.system("notify-send 'Search' 'Pexels: add PEXELS_KEY to keys.conf (free at pexels.com/api)' -t 5000")


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


def best_file(res):
    """Smallest mp4 that still covers 1920x1080."""
    files = res.get("video_files") or []
    cands = [
        f for f in files
        if f.get("file_type") == "video/mp4"
        and int(f.get("width") or 0) >= MIN_W
        and int(f.get("height") or 0) >= MIN_H
    ]
    if not cands:
        return None
    return min(cands, key=lambda f: int(f.get("width") or 0) * int(f.get("height") or 0))


def main():
    global CURSOR_FILE
    log("=== NEW PEXELS SEARCH ===")
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
    key = os.environ.get("PEXELS_KEY", "").strip()
    if not key:
        warn_missing_key()
        return

    page = load_cursor() if continue_mode else 1
    log(f"Query: '{query}' (page {page}, continue={continue_mode})")

    params = {
        "query": query,
        "orientation": "landscape",
        "per_page": str(PER_PAGE),
        "page": str(page),
    }
    url = API + "?" + urllib.parse.urlencode(params)

    headers = {
        "Authorization": key,
        "User-Agent": "davincix/0.1 (wallpaper engine)",
        "Accept": "application/json",
    }

    try:
        req = urllib.request.Request(url, headers=headers)
        data = json.loads(urllib.request.urlopen(req, timeout=15).read().decode("utf-8"))
    except Exception as e:
        log(f"ERROR fetching page {page}: {str(e)}")
        return

    results = data.get("videos", [])
    links = 0
    for res in results:
        f = best_file(res)
        thumb = res.get("image")
        if f and thumb:
            try:
                sys.stdout.write(f"{thumb}|{f['link']}\n")
                sys.stdout.flush()
                links += 1
            except BrokenPipeError:
                log("Broken pipe. Exiting.")
                os._exit(0)

    if data.get("next_page"):
        save_cursor(page + 1)
        log(f"Page {page}: {links} FHD+ videos. Cursor -> {page + 1}")
    else:
        log(f"Page {page}: {links} FHD+ videos. No more pages.")
    log(f"=== PEXELS COMPLETE ({links} links) ===")


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
