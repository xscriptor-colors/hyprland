# Shell Scripts

All scripts reside in the repository root `scripts/` directory and are deployed to `~/.config/hypr/scripts/` by the installer.

## Core Infrastructure

| Script | Purpose |
|--------|---------|
| `caching.sh` | Dynamic caching framework. Exports `QS_CACHE_DIR`, `QS_STATE_DIR`, `QS_RUN_DIR`. Provides `qs_ensure_cache()` to create and export cache paths for any module by name. All QML and shell widgets use this for their runtime directories. |
| `init.sh` | First-run initialization. Picks a random wallpaper from the collection, applies it via `awww`, runs `matugen` for color generation, then executes the Matugen reload script. Subsequent runs skip wallpaper selection and only regenerate colors. |
| `qs_manager.sh` | Central IPC manager for QuickShell widgets. Routes workspace switching (fast path, no sourcing) and widget toggle/open/close commands. Also handles wallpaper thumbnail preparation (converts webp, generates video poster frames) and Bluetooth scan lifecycle. |
| `reload.sh` | Triggers a full QuickShell QML reload via IPC and copies Matugen-generated SDDM colors to the system theme directory. |

## UI Scripts

| Script | Purpose |
|--------|---------|
| `brightness.sh` | Controls display brightness via `brightnessctl` (internal backlight) with fallback to `ddcutil` (external monitors via DDC/CI). Sends desktop notifications with percentage. |
| `volume.sh` | Controls audio volume via `pamixer`. Sends desktop notifications with percentage and mute state. |
| `volume_listener.sh` | Listens to PipeWire events via `pactl subscribe`. Triggers `swayosd-client` on volume changes without altering levels. Prevents duplicate popups from the same device. |
| `scale-menu.sh` | Rofi-based display scale selector (100%, 80%, 75%). Applies scale per-monitor via `hyprctl` and triggers QuickShell reload. |

## System Scripts

| Script | Purpose |
|--------|---------|
| `lock.sh` | Locks the session by launching `Lock.qml` via QuickShell, which acquires a `WlSessionLock`. |
| `exit.sh` | Gracefully ends the Hyprland session by stopping user targets and dispatching `hyprctl dispatch exit`. |
| `gpu-mode.sh` | NVIDIA Optimus mode switcher wrapping `envycontrol`. Supports cycle (silent/hybrid/nvidia), Rofi menu selector, and Waybar status output. Requires passwordless sudo rule (set up by installer). |
| `monitor-manager.sh` | Rofi-based multi-monitor manager. Supports positioning (left/right/above/below/mirror), single display modes, and refresh rate changes per monitor. Displays monitor info via notification. |
| `screenshot.sh` | Comprehensive screenshot and screen recording system. Supports area selection, full screen, active window, edit mode (satty), screen recording (gpu-screen-recorder with virtual audio routing), and QR code scanning (zbarimg). Records multi-track audio with independent desktop/mic volume and mute controls. |
| `settings_watcher.sh` | Watches `settings.json` and `.env` for changes. Regenerates Hyprland config files (env, keybindings, autostart, monitors) from templates and JSON settings. Triggers `hyprctl reload` only on actual changes to avoid flicker. |
| `update_notifier.sh` | Checks for updates every 10 minutes. Compares local version against remote, shows notification if newer version is available, and signals the topbar to show an update icon. |
| `workspaces.sh` | Daemon that listens to Hyprland socket events and generates workspace state JSON (id, state: active/occupied/empty, tooltip, app classes). Uses 50ms debouncing to prevent CPU overload during rapid window events. Includes zombie cleanup of stale instances. |
