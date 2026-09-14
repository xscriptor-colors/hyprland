# davincix — wallpaper subsystem

All wallpaper domain logic lives here, split into two layers: `kernel/` (the
headless core) and `ui/` (the Quickshell frontend). The UI only decides
**what** to apply; everything else (applying, downloading, thumbnails, search)
lives in `kernel/` and does not depend on Quickshell, which makes it testable
and extractable as a standalone tool (`davincix`).

## Layers

```
davincix/
├── ui/
│   ├── DavincixPicker.qml       UI root: state + logic (filters, focus, search)
│   ├── lib/                     pure helpers (constants.js, color.js)
│   └── components/
│       ├── grid/                DavincixGrid (list) + DavincixCard (item)
│       └── filter/              DavincixFilterBar + DavincixMonitors + DavincixSearch
└── kernel/                      core: no shell dependencies
    ├── davincix.sh              entry CLI (set/fetch/current/thumbs/search/stop/paths)
    ├── paths.sh                 path resolution + environment overrides
    ├── util.sh                  shared helpers (logging, media-type detection)
    ├── apply.sh                 apply with awww/mpvpaper + transitions
    ├── state.sh                 current wallpaper + cached current image
    ├── download.sh              URL download (webp-aware)
    ├── thumbs.sh                thumbnail cache + manifest (webp, video posters)
    ├── search.sh                DuckDuckGo search (run/pause/stop control)
    └── ddg_links.py             link scraper (stdlib only)
```

> **Registration note:** Quickshell's qmlscanner only synthesizes a `qmldir`
> for directories reachable from `Shell.qml`'s import graph, and the picker is
> loaded lazily through `WindowRegistry`. `davincix/ui` is therefore registered
> via `import "davincix/ui"` in `Floating.qml`, which lets the scanner follow
> the picker's `import "components/grid"` / `import "components/filter"` and
> synthesize their `qmldir`.

## CLI

```bash
kernel/davincix.sh paths                          # resolved paths (debug)
kernel/davincix.sh current [--thumb-name]         # current wallpaper / its thumbnail
kernel/davincix.sh set <file|url> [--video] [--monitors all|A,B] \
                   [--transition name] [--thumb <poster>] [--notify] [--dry-run]
kernel/davincix.sh fetch --name <n> --map <f> --dest <f> \
                   [--thumb-in <f>] [--thumb-out <f>] [--monitors ...] [--transition ...]
kernel/davincix.sh thumbs                         # prepare thumbnails (async)
kernel/davincix.sh search <query>                 # DuckDuckGo search
kernel/davincix.sh stop                           # stop the running search
```

## Paths and state (contracts)

Defaults reproduce the current shell layout and can be overridden through the
environment (this is what will allow extracting davincix as a standalone tool):

| Variable | Default | Use |
|---|---|---|
| `DAVINCIX_WALLPAPER_DIR` | `$WALLPAPER_DIR` or `~/.config/hypr/wallpapers` | source directory |
| `DAVINCIX_CACHE_DIR` | `~/.cache/quickshell/wallpaper_picker` | thumbs, current, search |
| `DAVINCIX_STATE_DIR` | `~/.local/state/quickshell/wallpaper_picker` | flags |
| `DAVINCIX_RUN_DIR` | `$XDG_RUNTIME_DIR/quickshell/wallpaper_picker` | control, locks |

Files that are contracts between layers/components:

- `current_wallpaper.png` — read by `Lock.qml` (lock background) and `sddm-colors.sh`.
- `ddg_search_control` — `run|pause|stop`; written by the UI.
- `thumbs/.manifest` + `thumbs/.source_dir` — thumbnail cache index.
- `search_map.txt` — `name|url` for search results.

## Who calls what

- `ui/DavincixPicker.qml` → `kernel/davincix.sh set|fetch|search|stop`
  (array exec, no shell).
- `qs_manager.sh` → `davincix.sh thumbs` (background prep) and
  `current --thumb-name` (highlight the current wallpaper when opening the picker).
- `init.sh` → `davincix.sh set <random> --transition any` on first run.
- `Lock.qml` / `sddm-colors.sh` → read `current_wallpaper.png`.

## Testing

```bash
bash kernel/davincix.sh paths
bash kernel/davincix.sh current
bash kernel/davincix.sh set ~/.config/hypr/wallpapers/7.png --dry-run   # does not apply
bash kernel/davincix.sh thumbs                                          # thumbnails only
```

## Future extraction

This subsystem is the candidate for its own repo (`davincix`): `kernel/` no
longer depends on the shell and `ui/` would stay in the shell as a frontend
(or move along as a Quickshell app). Comments and messages are already in
English (same pattern as `theme-sync`).
