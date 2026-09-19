#!/usr/bin/env python3
import sys, json, time, re, os
import urllib.request, urllib.parse, http.cookiejar

# Tap into QS dynamic cache variables
# Paths: prefer the davincix ones (exported by paths.sh); the QS_* variables
# remain as a fallback for the old layout.
LOG_DIR = os.environ.get("DAVINCIX_LOG_DIR") or os.environ.get("QS_LOG_DIR", "/tmp/quickshell/logs")
CONTROL_FILE = os.environ.get("DAVINCIX_CONTROL_FILE") or os.path.join(
    os.environ.get("QS_RUN_WALLPAPER_PICKER", "/tmp/quickshell/wallpaper_picker"),
    "ddg_search_control")

LOG_FILE = os.path.join(LOG_DIR, "ddg_python_scraper.log")

CURSOR_FILE = None  # cursor persistente (URL "next" para load more)


def log(msg):
    try:
        with open(LOG_FILE, "a") as f:
            f.write(f"{time.strftime('%H:%M:%S')} - {msg}\n")
    except:
        pass


def get_state():
    try:
        with open(CONTROL_FILE, "r") as f:
            return f.read().strip()
    except:
        return "run"


def save_cursor(url):
    if not CURSOR_FILE or not url:
        return
    try:
        with open(CURSOR_FILE, "w") as f:
            f.write(url)
    except:
        pass


def load_cursor():
    try:
        with open(CURSOR_FILE, "r") as f:
            return f.read().strip() or None
    except:
        return None

def main():
    global CURSOR_FILE
    log("=== NEW SEARCH STARTING (Safe Search: OFF) ===")
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

    query = sys.argv[1].strip() + " wallpaper"
    log(f"Query: '{query}' (continue={continue_mode})")

    cj = http.cookiejar.CookieJar()
    opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj))
    urllib.request.install_opener(opener)

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.5",
        "Referer": "https://duckduckgo.com/"
    }

    search_url = f"https://duckduckgo.com/?q={urllib.parse.quote(query)}&iar=images&iax=images&ia=images&kp=-1"
    vqd = None

    # "load more": arranca desde el cursor guardado; el vqd ya va embebido
    # en la URL "next", pero se conserva el fallback por si expiró.
    next_url = load_cursor() if continue_mode else None

    if not continue_mode:
        log(f"Fetching VQD token from: {search_url}")
        for i in range(3):
            try:
                req = urllib.request.Request(search_url, headers=headers)
                html = urllib.request.urlopen(req, timeout=10).read().decode("utf-8")
                match = re.search(r'vqd=([0-9a-zA-Z_-]+)', html) or re.search(r'vqd[\'"]?\s*:\s*[\'"]?([0-9a-zA-Z_-]+)', html)

                if match:
                    vqd = match.group(1)
                    log(f"Success! Found VQD token: {vqd}")
                    break
                else:
                    log(f"Attempt {i+1}: No VQD found in HTML.")
            except Exception as e:
                log(f"Attempt {i+1} Network Error: {str(e)}")
                time.sleep(1)

        if not vqd:
            log("CRITICAL ERROR: Failed to get VQD token. Exiting.")
            return

    if continue_mode and not next_url:
        log("No saved cursor. Nothing more to load.")
        return

    headers["Referer"] = search_url
    headers["Accept"] = "application/json, text/javascript, */*; q=0.01"

    links_found = 0

    for page in range(5):
        # Check state before making the next HTTP request
        state = get_state()
        if state == "stop":
            log("Stop signal detected. Exiting cleanly.")
            break

        while state == "pause":
            time.sleep(1)
            state = get_state()

        log(f"Fetching JSON page {page + 1}...")

        params = {
            "l": "us-en",
            "o": "json",
            "q": query,
            "vqd": vqd,
            "f": ",,,",
            "p": "-1",
            "ex": "-1"
        }

        if next_url:
            url = "https://duckduckgo.com" + next_url
            if "p=-1" not in url: url += "&p=-1"
            if "vqd=" not in url and vqd: url += f"&vqd={vqd}"
        else:
            url = "https://duckduckgo.com/i.js?" + urllib.parse.urlencode(params)

        try:
            req = urllib.request.Request(url, headers=headers)
            # Catch HTTP errors specifically so token expiry doesn't crash us violently
            response = urllib.request.urlopen(req, timeout=10)
            data = json.loads(response.read().decode("utf-8"))
            results = data.get("results", [])
            log(f"Successfully parsed JSON. Found {len(results)} raw image results.")

            for res in results:
                width = int(res.get("width", 0))
                height = int(res.get("height", 0))
                if width >= 1920 and height >= 1080:
                    t, i = res.get("thumbnail"), res.get("image")
                    if t and i:
                        try:
                            sys.stdout.write(f"{t}|{i}\n")
                            sys.stdout.flush()
                            links_found += 1
                        except BrokenPipeError:
                            log("Broken pipe detected. Bash script stopped listening. Exiting.")
                            os._exit(0)

            next_url = data.get("next")
            if not next_url:
                log("No 'next' URL provided by DDG.")
                break
            save_cursor(next_url)

        except BrokenPipeError:
            os._exit(0)
        except Exception as e:
            log(f"Error fetching page {page + 1}: {str(e)}. Assuming session expired or blocked.")
            break

    log(f"=== SEARCH COMPLETE. Total FHD links: {links_found} ===")

if __name__ == "__main__": 
    try: os.remove(LOG_FILE)
    except: pass
    
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
