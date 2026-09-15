# davincix — kernel

Headless wallpaper engine for Hyprland/wlroots: apply, thumbnail, search and
rotate wallpapers from the command line. No shell dependency — the Quickshell
UI that usually drives it lives in the dottes repo and talks to this CLI.

Version: **0.1.0**

## Requirements

| Role | Tool |
|---|---|
| Apply still images | `awww` (awww-daemon) |
| Apply videos | `mpvpaper` |
| Thumbnails / webp / color helpers | ImageMagick (`magick`) |
| Video posters | `ffmpeg` + `ffprobe` |
| Search downloads | `curl` |
| Search scraper | `python3` (stdlib only) |
| Trash on delete | `gio` (optional; falls back to `rm`) |
| Notifications | `notify-send` (optional) |

## Install

Clone the repo and make it visible to whichever frontend you use. For the
Quickshell picker (UI lives in the dottes repo at
`config/hypr/scripts/quickshell/davincix/ui/`), the kernel is resolved in
this order:

1. `$DAVINCIX_CLI` — explicit path to `kernel/davincix.sh`.
2. Sibling `../kernel/davincix.sh` next to the UI.

Recommended: keep the clone and expose it as the sibling kernel:

```bash
git clone <repo-url> ~/davincix
ln -s ~/davincix ~/.config/hypr/scripts/quickshell/davincix/kernel
```

Any other frontend only needs the CLI path.

## CLI

```bash
kernel/davincix.sh set <file|url> [--video] [--monitors all|A,B] \
                   [--transition name] [--thumb <poster>] [--notify] [--dry-run]
kernel/davincix.sh fetch --name <n> --map <f> --dest <f> \
                   [--thumb-in <f>] [--thumb-out <f>] [--monitors ...] [--transition ...]
kernel/davincix.sh current [--thumb-name]
kernel/davincix.sh thumbs
kernel/davincix.sh search <query>
kernel/davincix.sh search --continue <query>   # next page (keeps the cache)
kernel/davincix.sh search --clear              # stop + drop the cache
kernel/davincix.sh stop
kernel/davincix.sh rm <file>
kernel/davincix.sh import <paths…>
kernel/davincix.sh slideshow start|stop|status [interval]
kernel/davincix.sh paths
kernel/davincix.sh --version
```

## Environment overrides

| Variable | Default | Use |
|---|---|---|
| `DAVINCIX_WALLPAPER_DIR` | `$WALLPAPER_DIR` or `~/.config/hypr/wallpapers` | source directory |
| `DAVINCIX_CACHE_DIR` | `~/.cache/quickshell/wallpaper_picker` | thumbs, current, search |
| `DAVINCIX_STATE_DIR` | `~/.local/state/quickshell/wallpaper_picker` | persistent flags |
| `DAVINCIX_RUN_DIR` | `$XDG_RUNTIME_DIR/quickshell/wallpaper_picker` | control, locks, PIDs |
| `DAVINCIX_LOG_DIR` | `$XDG_RUNTIME_DIR/quickshell/logs` | logs |
| `DAVINCIX_CLI` | — | consumed by the UI (CLI location) |

## Files that are contracts

- `current_wallpaper.png` — current wallpaper cache (lock screens, theme tools).
- `ddg_search_control` — `run|pause|stop`; written by the UI.
- `ddg_next_url` — DuckDuckGo pagination cursor (`search --continue`).
- `thumbs/.manifest` + `thumbs/.source_dir` — thumbnail cache index.
- `search_map.txt` — `name|url` for search results.
- `slideshow.pid` + `slideshow_enabled` — slideshow daemon state.

## Slideshow

`slideshow start [interval]` runs a detached daemon that rotates still images
(`--transition random`) and never repeats the previous one. State lives in the
run/state dirs; resuming after a reboot needs an autostart entry in the host
(e.g. `davincix.sh slideshow start` when the enabled flag exists).

## Testing

```bash
bash kernel/davincix.sh --version
bash kernel/davincix.sh paths
bash kernel/davincix.sh current
bash kernel/davincix.sh set ~/.config/hypr/wallpapers/7.png --dry-run   # no aplica
bash kernel/davincix.sh thumbs
```

## Search notes

The DuckDuckGo scraper (`ddg_links.py`, stdlib only) uses the public JSON
endpoint and the VQD token dance; DDG can change it at any time. Results are
filtered to >= 1920x1080 and validated (`content-type` + mime) before being
kept.
