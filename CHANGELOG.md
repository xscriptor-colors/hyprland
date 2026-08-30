# Changelog

## [2026-08-30]

### Added
- **Palette system** — 12 fixed palettes in `dock/palettes/*.json` + `dock/Colors.qml` (replaces `MatugenColors`). Every widget, border, SDDM, kitty and nvim now follows the active palette.
- **Window borders UI** — Dock Editor "Window borders" card (follow-palette toggle + manual active/inactive colors), applied live via `hyprctl eval` without restarting windows.
- **`scripts/theme-sync.sh`** — kitty + starship + VS Code themes regenerate from `dock/palettes` (single source of truth) and follow `settings.json → dock.palette` (VS Code updates `workbench.colorTheme` + `workbench.iconTheme` live, both `code` and `code-insiders`); nvim keeps its own upstream config.
- **`scripts/sddm-colors.sh`** — SDDM login theme colors derived from the palette, plus a dynamic background that follows the current wallpaper.

### Changed
- **Matugen removed** entirely: `MatugenColors.qml`, `qs_colors.json`, `matugen-apply.sh`, `matugen_reload.sh`, `matugen-colors.lua`, `config/matugen`, `install.sh`/`init.sh` matugen blocks.
- **All widgets migrated** to the palette (Blocks 1–3): bar modules, volume, network, battery, applauncher, calendar, settings, music, clipboard, system-monitor, quicknotes, rss-reader, file-search, scale, updater, guide, focustime, window-controls, Floating, Lock, ScreenshotOverlay, notifications.
- **Window borders** now derive from the active palette in `colors.lua` (reads `settings.json` + palette JSON).
- **SDDM theme** renamed `matugen-minimal` → `x`, palette-driven colors, adaptive dark/light overlay, background points at the live wallpaper cache.
- **kitty + nvim** installed from remote repos (`xscriptor-colors/terminal`, `xscriptor-colors/nvim`); bundled copies removed.
- **Removed widgets** `movies` (SUPER+P) and `stewart` (SUPER+X).
- **Removed legacy** `TopBar.qml`, `themes/*.conf`, `references.md`.

### Fixed
- Settings popup sidebar not drawing after topbar dead-code cleanup (brace imbalance) + missing `overlay1`/`overlay2` roles.
- Wallpaper picker applying from the wrong directory (`srcDir` now from `settings.json`).
- Kitty comment lines invisible: `color8` was too close to the background in several palettes (and `paris` had `color7` = background) — `color8` is now a mid-tone `mix(background, foreground, 0.5/0.65)` with sufficient contrast in all 12 palettes; `paris` `color7` fixed to the foreground.
- Shell comments (`# ...`) invisible when typed in zsh: `zsh-syntax-highlighting` defaults to `fg=black` (the background) — `~/.zshrc` now sets `ZSH_HIGHLIGHT_STYLES[comment]='fg=bright-black,bold'` so comments use the palette's `color8` (visible in every theme).
- Notifications popup: removed decorative background bubbles; kept small/minimal on the side; removed the redundant `swaync` daemon (double popup + broken app icon).
- Various pre-existing QML bugs: widget property injection (`Main.qml`), QuickNotes autosave, FileSearch `surface2`, Guide/Clipboard/appLauncher/Calendar transform scoping, NetworkPopup scoping, Updater null guard, Zone reload noise.

## [2026-08-23]

- Migrate all customizations to xscriptor-colors

## [2026-08-12]

### Added
- Migrated the Hyprland config from hyprlang to the Lua format (Hyprland 0.55+): `hyprland.lua` entry point plus `env.lua`, `colors.lua`, `variables.lua`, `settings.lua`, `monitors.lua`, `keybinds.lua`, `animations.lua`, `windowrules.lua`, `workspaces.lua` and `autostart.lua`.
- `config/matugen/scheme` -- configurable Matugen color scheme (defaults to `scheme-fruit-salad` for celeste tones instead of the default blue).
- `config/hypr/scripts/quickshell/wallpaper/matugen-apply.sh` -- central helper that runs Matugen with the configured scheme; used by the wallpaper picker, init and installer.
- `config/matugen/templates/hyprland.lua.template` -- regenerates dynamic window border colors from the wallpaper into `matugen-colors.lua`, consumed by `colors.lua` with a fallback to the fixed X palette.

### Changed
- Removed the dynamic config generator (`settings_watcher.sh`, `detect-monitors.sh`, `templates/`) and all legacy `.conf` files. `monitors.lua` auto-detects monitors at the highest refresh rate via `mode = "highrr"`.
- `scripts/monitor-manager.sh` and `scripts/scale-menu.sh` -- now apply monitors via `hyprctl eval 'hl.monitor(...)'` (the old `hyprctl keyword monitor` no longer exists).
- `scripts/quickshell/window-controls/persist.sh` -- writes `config/window-effects.lua` and `config/gaps.lua` instead of `.conf`; `WindowControls.qml` no longer uses `hyprctl keyword`.
- `scripts/quickshell/Config.qml` -- `applyMonitors()` uses the Lua API so refresh rate changes from the settings panel actually apply; `saveAllKeybinds()` and `saveAllStartup()` now write `config/user-keybinds.lua` / `config/user-startup.lua` (loaded by `hyprland.lua`) instead of relying on the removed generator.
- `scripts/quickshell/settings/SettingsPopup.qml` -- replaced legacy `hyprctl dispatch` calls with `hyprctl eval`.
- `scripts/qs_manager.sh` -- workspace switching uses `hl.dsp.focus`/`hl.dsp.window.move` via `hyprctl eval`.
- `scripts/exit.sh` -- session exit uses `hyprctl eval 'hl.dispatch(hl.dsp.exit())'`.
- `scripts/quickshell/applauncher/appLauncher.qml` -- launching apps uses `hyprctl eval 'hl.dispatch(hl.dsp.exec_cmd(...))'` (the removed `hyprctl dispatch exec` failed silently).
- `config/hypridle/hypridle.conf` -- dpms commands use `hyprctl eval 'hl.dispatch(hl.dsp.dpms(...))'`.
- `install.sh` -- cleans up legacy config on install; runs Matugen through `matugen-apply.sh`.
- `config/matugen/config.toml` -- Hyprland template now outputs `matugen-colors.lua` instead of `colors.conf`.

### Fixed
- Refresh rate changes from the settings panel (gear) staying at 60Hz: `applyMonitors()` used the removed `hyprctl keyword monitor` and failed silently. Now applies 60Hz/144Hz correctly via the Lua API.
- Display scaling (SUPER+Z) not applying: a leftover `settings_watcher.sh` process from before the migration was regenerating old configs and reloading Hyprland, reverting the scale. The zombie process was removed.
- App launcher (SUPER+D) showing the menu but never launching apps: `hyprctl dispatch exec` no longer exists and failed silently. Fixed with the Lua exec dispatcher.
- hypridle display dpms off/on (dim/suspend path) failing silently due to legacy `hyprctl dispatch dpms` syntax.
- Workspace switching and session exit broken by legacy `hyprctl dispatch` syntax.
- Settings panel keybinds/startup editor writing to `settings.json` with no effect (the generator was removed): now generates Lua override modules that Hyprland loads.

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
- `scripts/quickshell/MatugenColors.qml` -- added terminal-style dynamic colors (color0 through color15, background, foreground) derived from the Matugen palette.
- `scripts/quickshell/TopBar.qml` -- added CPU/RAM pill in the system indicator bar; assigned distinct dynamic palette colors to each indicator (KB=color5, WiFi=color6, BT=color4, CPU/RAM=color1, Volume=color3).
- `install.sh` -- install_nvim_config now asks whether to use bundled config, clone xscriptor-colors/nvim, or skip; install_hack_nerd_font now copies font to /usr/share/fonts/ via sudo for SDDM.

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
