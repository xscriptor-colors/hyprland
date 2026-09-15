#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════
# pixabay provider — short stock videos (live wallpapers) as "thumb|full".
#
# thumb = Vimeo preview image built from `picture_id`, full = the best video
# file >= 1920x1080 (large → medium fallback). Needs an API key (free):
# PIXABAY_KEY env or the keys.conf file sourced by search.sh.
# ═══════════════════════════════════════════════════════════════════════════
import json
import os
import sys
import time
import urllib.parse
import urllib.request

LOG_DIR = os.environ.get("DAVINCIX_LOG_DIR", "/tmp/quickshell/logs")
LOG_FILE = os.path.join(LOG_DIR, "pixabay_scraper.log")
API = "https://pixabay.com/api/videos/"
MIN_W, MIN_H = 1920, 1080
PER_PAGE = 20

CURSOR_FILE = None  # next page number (load more)


def log(msg):
    try:
        with open(LOG_FILE, "a") as f:
            f.write(f"{time.strftime('%H:%M:%S')} - {msg}\n")
    except:
        pass


def warn_missing_key():
    log("ERROR: PIXABAY_KEY not set (env or keys.conf).")
    if os.path.exists("/usr/bin/notify-send"):
        os.system("notify-send 'Search' 'Pixabay: add PIXABAY_KEY to keys.conf (free at pixabay.com/api/docs)' -t 5000")


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
    """First variant (large → medium → small) that covers 1920x1080."""
    vids = res.get("videos") or {}
    for name in ("large", "medium", "small"):
        v = vids.get(name) or {}
        w, h = int(v.get("width") or 0), int(v.get("height") or 0)
        if v.get("url") and w >= MIN_W and h >= MIN_H:
            return v["url"]
    return None


def main():
    global CURSOR_FILE
    log("=== NEW PIXABAY SEARCH ===")
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
    key = os.environ.get("PIXABAY_KEY", "").strip()
    if not key:
        warn_missing_key()
        return

    page = load_cursor() if continue_mode else 1
    log(f"Query: '{query}' (page {page}, continue={continue_mode})")

    params = {
        "key": key,
        "q": query,
        "orientation": "horizontal",
        "per_page": str(PER_PAGE),
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

    hits = data.get("hits", [])
    total_hits = int(data.get("totalHits", 0))
    links = 0
    for res in hits:
        full = best_file(res)
        pid = res.get("picture_id")
        thumb = f"https://i.vimeocdn.com/video/{pid}_640x360.jpg" if pid else None
        if full and thumb:
            try:
                sys.stdout.write(f"{thumb}|{full}\n")
                sys.stdout.flush()
                links += 1
            except BrokenPipeError:
                log("Broken pipe. Exiting.")
                os._exit(0)

    if page * PER_PAGE < total_hits:
        save_cursor(page + 1)
        log(f"Page {page} ({total_hits} hits): {links} FHD+ videos. Cursor -> {page + 1}")
    else:
        log(f"Page {page} ({total_hits} hits): {links} FHD+ videos. No more pages.")
    log(f"=== PIXABAY COMPLETE ({links} links) ===")


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
