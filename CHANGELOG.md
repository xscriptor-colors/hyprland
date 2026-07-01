# Changelog

## [Unreleased]

### Added
- `scripts/detect-monitors.sh` -- auto-detects all connected monitors and generates `config/monitors.conf` with each monitor set to its highest available refresh rate. Runs on startup and at install time.

### Changed
- `hyprland.conf` -- replaced hardcoded `monitor = , preferred, auto, 1` with `source = ~/.config/hypr/config/monitors.conf`, enabling per-monitor max refresh rate detection and GUI-based monitor management to take effect.
- `scripts/settings_watcher.sh` -- fallback path (no monitors in settings.json) now calls `detect-monitors.sh` instead of hardcoding `preferred`, ensuring new or unconfigured monitors always get the best rate.
- `config/hypr/autostart.conf` -- added `exec-once = ~/.config/hypr/scripts/detect-monitors.sh` before init so monitors are configured at every session start.
- `install.sh` -- runs `detect-monitors.sh --silent` after deploying dotfiles so the first boot already has the correct refresh rate.

### Fixed
- Monitor refresh rate resetting to 60Hz on systems that support higher rates (e.g. 144Hz). The root cause was `monitor = , preferred, auto, 1` picking the EDID default (usually 60Hz) and the generated `monitors.conf` never being sourced by `hyprland.conf`.

### Changed
- `scripts/quickshell/applauncher/app_fetcher.py` -- complete rewrite:
  - Replaced broad substring blocklist with desktop file ID prefix/exact matching, keyword matching, and exec path matching. Prevents false positives where real apps were caught by overly broad terms like "network" or "arch".
  - Parses additional .desktop fields: `GenericName`, `Comment`, `Categories`, `Keywords` for richer search.
  - Honors `Hidden=true` and `NotShowIn=Hyprland` per the freedesktop spec.
  - Hides zero-usage apps once the user has accumulated 15+ total launches across 3+ unique apps, keeping the list clean of never-used entries.
- `scripts/quickshell/applauncher/appLauncher.qml`:
  - Fixed usage tracking base64 key mismatch: `echo "$1"` (which appends `\n`) was replaced with `printf '%s' "$1"` so the bash-side key matches Python's `b64encode()`. This was the root cause of apps never being sorted by frequency despite being used repeatedly.
  - Search now also matches `generic_name`, `comment`, `categories`, and `keywords` in addition to `name` and `exec`.

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
