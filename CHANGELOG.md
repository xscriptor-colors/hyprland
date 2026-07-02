# Changelog

## [Unreleased]

### Added
- `scripts/detect-monitors.sh` -- auto-detects all connected monitors and generates `config/monitors.conf` with each monitor set to its highest available refresh rate.
- `scripts/quickshell/quicknotes/QuickNotes.qml` -- lightweight text editor with auto-save, bound to SUPER+Y.
- `scripts/quickshell/system-monitor/SystemMonitor.qml` and `fetch.sh` -- CPU, RAM, disk, temperature, processes, uptime display, bound to SUPER+I.
- `scripts/quickshell/rss-reader/RssReader.qml` and `fetch.py`, `feeds.txt` -- RSS feed reader with per-source filtering, bound to SUPER+O.
- `scripts/quickshell/file-search/FileSearch.qml` and `fetch.sh` -- local file search via fd/find, opens with xdg-open, bound to SUPER+'.
- `scripts/quickshell/window-controls/WindowControls.qml` and `persist.sh` -- live window opacity, blur, and rounding sliders. Changes persist across Hyprland reloads via `config/window-effects.conf`. Bound to SUPER+SHIFT+B.
- `config/window-effects.conf` -- persisted decoration overrides, sourced at the end of `hyprland.conf` so it properly overrides defaults.

### Changed
- `hyprland.conf` -- replaced hardcoded `monitor = , preferred, auto, 1` with `source = ~/.config/hypr/config/monitors.conf`; added `source = ~/.config/hypr/config/window-effects.conf` at the end.
- `scripts/settings_watcher.sh` -- fallback path (no monitors in settings.json) calls `detect-monitors.sh` instead of `preferred`.
- `config/hypr/autostart.conf` -- added `exec-once` for detect-monitors.
- `install.sh` -- runs monitor detection after deploying dotfiles.
- `scripts/quickshell/applauncher/app_fetcher.py` -- complete rewrite: desktop ID blocklist, Hidden/NotShowIn support, extra search fields, icon validation via `BAD_ICONS` blacklist.
- `scripts/quickshell/applauncher/appLauncher.qml` -- fixed base64 key mismatch (echo -> printf); search now covers generic_name, comment, categories, keywords; letter fallback for missing icons.
- `scripts/quickshell/calendar/CalendarPopup.qml` -- removed duplicate horizontal centering that conflicted with WindowRegistry.js.
- `scripts/quickshell/WindowRegistry.js` -- registered all new widgets.
- `config/hypr/keybinds.conf` -- added shortcuts for all new widgets.
- `scripts/caching.sh` -- fixed invalid variable names when widget name contains hyphens.
- `scripts/quickshell/TopBar.qml` -- added CPU/RAM pill in the system indicator bar.

### Fixed
- Monitor refresh rate resetting to 60Hz on systems that support higher rates. Root cause: `preferred` picks EDID default (60Hz) and `monitors.conf` was never sourced.
- App launcher usage tracking broken: `echo` added `\n` to base64 keys, preventing frequency sort from ever working.
- System Monitor widget not loading: hyphen in widget name broke caching.sh; inline QML `component` keyword not supported by Quickshell 0.3.
- Calendar popup not centered: QML was overriding X position set by WindowRegistry.js with a different scale calculation.

## [1.0.4] - 2026-01-25

### Fixed
- Migrated `windowrules.conf` to Hyprland v0.53 syntax standards.
  - Replaced deprecated `windowrulev2` with `windowrule`.
  - Updated regex matching to use `match:field criteria` syntax.
  - Added explicit boolean values (e.g., `float 1`) to all rules.
  - Removed unsupported `floating` matchers and unstable xwayland rules.

### Pending Tasks
- [x] Change notification background (Dunst) to black
- [x] Set wallpaper selector search bar background to black
- [x] Implement randomized wallpaper transition animations
- [x] Implement wallpaper selector with thumbnails (Super+W)
- [x] Update Waybar icons and add new modules (hostname, gpu, memory, etc.)
- [x] Implement theme name island in Waybar
- [x] Ensure Waybar styling follows "island" design with black backgrounds
- [x] Verify solutions are up-to-date and optimal
- [x] Ensure installer includes new Waybar/Wofi scripts and dependencies
- [x] Reorganize Waybar islands (clock far right; battery before; IP+theme left)
- [x] Update wallpaper picker behavior (keep Super+W)
- [x] Update Sofi behavior and dimensions
- [x] Update logout menu and add a new shortcut
- [x] Update installer for any new dependencies
- [x] Evaluate and apply 120fps animations where possible
- [x] Reduce Waybar font size slightly and add scale menu (75%/80%)
- [x] Fix wallpaper picker thumbnails layout (style cards)
- [x] Fix rofi launcher theming ( readable text)
- [x] Improve logout menu layout and icons (wlogout)
- [x] Improve wallpaper cards (single background + no search bar) and fix selection
- [x] Make rofi drun icons rounded and ensure white text on black
- [x] Fix logout icons rendering (remove red background issue)
- [x] Add required deps for rofi/wlogout thumbnails (jq, imagemagick, librsvg)

### Completed
- [x] Update Waybar icons to user-specified icons
- [x] Add theme name island to Waybar
- [x] Wallpaper selector opens correctly

---

## [1.0.3] - 2026-01-22

### Added
- Theme name island in Waybar
- New Waybar icons

---

## [1.0.2] - 2026-01-22

### Added
- Kitty theme integration
- KDE kwallet support

---

## [1.0.0] - 2026-01-21

### Added
- Initial release
