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
│       ├── ConfirmDialog.qml    delete confirmation overlay
│       ├── grid/                DavincixGrid (list) + DavincixCard (item)
│       └── filter/              DavincixFilterBar + DavincixMonitors + DavincixSearch
└── kernel/                      core: no shell dependencies
    ├── davincix.sh              entry CLI (set/fetch/current/thumbs/search/stop/rm/import/slideshow)
    ├── paths.sh                 path resolution + environment overrides
    ├── util.sh                  shared helpers (logging, media-type detection)
    ├── apply.sh                 apply with xwww/mpvpaper + transitions
    ├── state.sh                 current wallpaper + cached current image
    ├── download.sh              URL download (webp-aware)
    ├── thumbs.sh                thumbnail cache + manifest (webp, video posters)
    ├── search.sh                source search (run/pause/stop, continue, --source)
    ├── slideshow.sh             rotation daemon (PID + enabled flag)
    └── providers/               one scraper per source (ddg | wallhaven | pexels | pixabay)
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
kernel/davincix.sh search <query> [--source SRC]   # SRC: ddg|wallhaven|pexels|pixabay
kernel/davincix.sh search --continue <query>      # next page (keeps the cache)
kernel/davincix.sh search --clear                 # stop + drop the search cache
kernel/davincix.sh stop                           # stop the running search
kernel/davincix.sh rm <file>                      # trash a wallpaper (+ thumbnail)
kernel/davincix.sh import <paths…>                # copy into the dir + thumbs
kernel/davincix.sh slideshow start|stop|status [interval]
kernel/davincix.sh keys [list | set NAME VALUE]   # provider API keys (keys.conf)
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

- `ui/DavincixPicker.qml` → `kernel/davincix.sh set|fetch|search|stop|rm|slideshow`
  (array exec, no shell). `import` queda como utilidad de CLI (sin botón en la
  UI para no depender de herramientas externas de selección de archivos).
- `qs_manager.sh` → `davincix.sh thumbs` (background prep) and
  `current --thumb-name` (highlight the current wallpaper when opening the picker).
- `init.sh` → `davincix.sh set <random> --transition any` on first run.
- `Lock.qml` / `sddm-colors.sh` → read `current_wallpaper.png`.

## UI preferences (persisted)

- `settings.json` key `davincixView` (via `Config.setSetting`, the shell's
  standard mechanism): `orientation` (horizontal/vertical), `shape`
  (rect/circle), `favorites` (array of shown names).
- Search state (query, searched, last name) lives in a `Settings` object with
  `category: "QS_Davincix"` — same pattern as the other shell widgets
  (its QSettings init warning is shell-wide and harmless).

The slideshow daemon keeps a PID file and an enabled flag; resuming it after a
reboot requires an autostart hook (e.g. `davincix.sh slideshow start`), which is
out of this repo's kernel (see the shell's autostart).

## Testing

```bash
bash kernel/davincix.sh paths
bash kernel/davincix.sh current
bash kernel/davincix.sh set ~/.config/hypr/wallpapers/7.png --dry-run   # does not apply
bash kernel/davincix.sh thumbs                                          # thumbnails only
```

## Version and split plan

Version **0.1.0**.

The `kernel/` is the candidate for its own repo (planned home: `equisdots`):
it has no shell dependency and ships its own README. The `ui/` stays in the
dottes shell and finds the CLI through `$DAVINCIX_CLI` or the sibling
`../kernel/davincix.sh` (see `ui/DavincixPicker.qml` → `cliPath()`). The
recommended layout for a separate kernel repo is a symlink:

```bash
ln -s ~/davincix ~/.config/hypr/scripts/quickshell/davincix/kernel
```
