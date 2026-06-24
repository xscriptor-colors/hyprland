# Screenshot and Recording System

The `screenshot.sh` script provides a comprehensive capture system with an interactive QuickShell overlay.

## QuickShell Overlay (ScreenshotOverlay.qml)

Activated by pressing the Print key. A full-screen overlay with:

- **Area selection** -- Drag to select a rectangular region. Shows pixel dimensions live. Snaps to window edges.
- **Full screen** -- Captures the entire screen.
- **Active window** -- Captures the currently focused window.
- **Screen recording** -- Toggle to switch from screenshot to video mode.
- **Audio controls** -- Independent desktop and microphone volume sliders with mute toggles. Virtual audio routing via PipeWire module-loopback.
- **QR scanning** -- Scans QR codes in the selected region via `zbarimg` and displays the result.
- **Magnifier** -- Hovering over the selection area shows a magnified preview.
- **Edit mode** -- Sends capture to `satty` for annotation.

## Screenshot Keybinds

| Key | Action |
|-----|--------|
| Print | Open screenshot overlay |
| SHIFT + Print | Open overlay in edit mode |
| SUPER + Print | Full-screen capture (no overlay) |
| SUPER + SHIFT + Print | Full-screen capture with edit |

## Screen Recording

Recording uses `gpu-screen-recorder` for hardware-accelerated encoding. Virtual audio routing creates separate sinks for desktop audio and microphone, mixed into a single track.

- **Start**: Select recording mode and region, press record. Audio preferences are persisted.
- **Stop**: Press the same shortcut again. The recording is finalized, virtual audio cables are destroyed, and a notification with file location is shown.

Output is saved to `~/Videos/Recordings/` as MP4.

## Dependencies

- `grim` -- Screenshot capture
- `slurp` -- Region selection
- `satty` -- Image annotation/editing
- `gpu-screen-recorder` -- Screen recording with GPU encoding
- `zbarimg` -- QR code decoding
- `pactl` / `pipewire` -- Virtual audio routing
- `wl-copy` -- Clipboard integration
- `ffmpeg` -- Video thumbnail generation (used by wallpaper picker)
