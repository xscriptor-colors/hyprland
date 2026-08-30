# QuickShell Widgets

The UI is built with QuickShell, a QML-based shell environment for Hyprland. It consists of three main windows and a collection of popup widgets.

## Architecture

Three panel windows run simultaneously:

- **TopBar.qml** -- Persistent top bar visible on all monitors. Modules are not hardcoded: `topbar/TopbarLayout.js` holds the module catalog and the pure helpers that read and mutate the layout, `topbar/modules/*.qml` holds one file per module, and the bar renders three zones (left / center / right) from `settings.json`'s `topbar` key. Edit it from the settings panel's Topbar tab (SUPER + SHIFT + E); changes hot-reload with no restart.
- **Main.qml** -- Full-screen overlay that handles widget popup positioning, animations, and IPC dispatch
- **Floating.qml** -- Full-screen overlay for the persistent sidebar and exclusive UI surfaces

All windows share a `Caching` QML singleton for path management, the palette system (`Colors.qml`) for theming, and `Scaler` for resolution-independent sizing.

## Widget Popups

Accessible via keybinds (SUPER + letter):

| Widget | File | Keybind | Position |
|--------|------|---------|----------|
| Battery | `battery/BatteryPopup.qml`, `BatteryPopupAlt.qml` | SUPER + B | Top right |
| Network | `network/NetworkPopup.qml` | SUPER + N | Top right |
| Volume | `volume/VolumePopup.qml` | SUPER + V | Top right |
| App Launcher | `applauncher/appLauncher.qml` | SUPER + D | Center |
| Clipboard | `clipboard/ClipboardManager.qml` | SUPER + C | Center |
| Calendar | `calendar/CalendarPopup.qml` | SUPER + S | Top center |
| Music Player | `music/MusicPopup.qml` | SUPER + M | Top left |
| Wallpaper Picker | `wallpaper/WallpaperPicker.qml` | SUPER + W | Center |
| Guide/Help | `guide/GuidePopup.qml` | SUPER + H | Center |
| Settings | `settings/SettingsPopup.qml` | SUPER + SHIFT + S | Left edge |
| Display Scale | `scale/ScalePicker.qml` | SUPER + Z | Center |
| Focus Time | `focustime/FocusTimePopup.qml` | SUPER + SHIFT + T | Center |
| Stewart | `stewart/stewart.qml` | SUPER + X | Center |
| Updater | `updater/UpdaterPopup.qml` | SUPER + U | Center |
| Stewart | `stewart/stewart.qml` | SUPER + X | Center |
| Updater | `updater/UpdaterPopup.qml` | SUPER + U | Center |
| System Monitor | `system-monitor/SystemMonitor.qml` | SUPER + I | Center |
| Quick Notes | `quicknotes/QuickNotes.qml` | SUPER + Y | Center |
| RSS Reader | `rss-reader/RssReader.qml` | SUPER + O | Center |
| File Search | `file-search/FileSearch.qml` | SUPER + ' | Center |
| Quick Actions | `quickactions/DrawAction.qml`, `SystemUsage.qml`, `Timer.qml` | (internal) | Varies |

## Specialty QML Windows

### Lock.qml
Hyprlock-compatible lock screen with PAM authentication, session locking via `WlSessionLock`, animated background blobs, battery/weather/keyboard info pills, and power menu. Uses the same Matugen color scheme.

### ScreenshotOverlay.qml
Full-screen overlay for region selection, video recording controls (with virtual audio routing), QR code scanning, and magnifier. Supports multi-monitor with area/active-window/fullscreen capture modes.

## IPC System

The `qs_manager.sh` script communicates with Main.qml via QuickShell's built-in IPC:

- `qs_manager.sh toggle <widget>` -- Opens/closes a named widget
- `qs_manager.sh close` -- Closes the currently open widget
- `qs_manager.sh <number>` -- Switches to workspace N (fast path, no shell overhead)
- `qs_manager.sh <number> move` -- Moves active window to workspace N

Widget position and size are defined in `WindowRegistry.js` which provides responsive scaling based on screen resolution and user-defined UI scale.

## Data Watchers

Background processes in `watchers/` feed real-time data into QML:

- `audio_fetch.sh` / `audio_wait.sh` -- Audio devices state
- `battery_fetch.sh` / `battery_wait.sh` -- Battery percentage and status
- `bt_fetch.sh` / `bt_wait.sh` -- Bluetooth device scanning
- `network_fetch.sh` / `network_wait.sh` -- WiFi and Ethernet status
- `kb_fetch.sh` / `kb_wait.sh` -- Keyboard layout polling
- `sys_fetcher.sh` -- CPU, RAM, temperature, network I/O
