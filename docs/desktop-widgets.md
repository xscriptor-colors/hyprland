# Desktop Widgets — Personalization & State

Desktop widgets are small floating panels that live **above the wallpaper and below
windows** on every monitor. They are plain QuickShell windows (Bottom layer, no focus,
no exclusive zone) whose content comes from the same face catalog that the redactor
edits, so what you see in the editor is exactly what renders on the desktop.

They form their own subsystem inside the quickshell process:

```
quickshell/
  widgets/
    Widgets.qml            # root component (one WidgetLoader per screen)
    WidgetLoader.qml       # per-screen model + persistence + edit-bus handling
    Widget.qml             # the actual PanelWindow (Bottom layer) hosting a face
    WidgetRegistry.qml     # type/variant catalog (shared by loader and redactor)
    WidgetRedactor.qml     # full-screen visual editor (SUPER+SHIFT+W)
    faces/*.qml            # 13 face components (pure QtQuick + Theme/Cava singletons)
```

The widget subsystem is **live-themed**: faces read the `Theme` singleton
(`dock/palettes/<active>.json`, same derivation as the dock) and the shared `Cava`
singleton feeds the visualizers, so switching the palette in the Dock Editor recolors
every widget instantly without a reload.

---

## 1. Opening the editor

Press **`SUPER + SHIFT + W`** (the wallpaper picker stays on `SUPER + W`) to open the
**widget redactor** on the current monitor:

- The real widget windows of that monitor are hidden while the editor is open and are
  restored (with their state flushed to disk) when you leave it.
- `Esc` (or pressing the keybind again) closes the editor. There is **no save button**:
  every change is persisted automatically, debounced, by the loader.
- The redactor is a full-screen overlay of the popup system (`WindowRegistry.js`
  entry `"widgets-redactor"`), so it only edits the monitor it is shown on.

Editor controls (floating toolbar at the top):

| Control | Effect |
|---------|--------|
| Type buttons (Clock / Music / Weather / Visualizer / Image) | Add a widget of that type at a free position (image widgets then open the image picker) |
| `Variant: …` | Cycle the face variant of the selected widget (e.g. digital → analog → minimal) |
| `Rotate 90°` | Rotate the widget by 90° (0 / 90 / 180 / 270; the surface box swaps axes) |
| `Stretch width` | Fill the monitor width (minus margins) — available for Clock / Music / Visualizer |
| `Pick image…` | Open the image picker for an **Image** widget |
| `Duplicate` | Copy the selected widget (same type/variant/rotation/opacity/image) |
| `Delete` | Remove the selected widget (`Del` also works) |
| Opacity slider | 10–100 % opacity, live |
| `Clear all` | Remove every widget (press twice to confirm) |

Direct manipulation:

- **Drag** a widget body to move it. Position snaps to the 20 px grid, the monitor
  center and the edges/centers of other widgets (guide lines appear while snapping).
- **Pull the 8 handles** (corners and edge midpoints of the selection frame) to resize.
  Sizes are clamped by the face's declared constraints (min/max size and, for locked
  faces such as the analog clock or the round variants, a fixed aspect ratio), so the
  proxy and the real window always agree.
- Clicking empty desktop space deselects; clicking another widget selects it.

---

## 2. Widget types & variants

| Type | Variants | Notes |
|------|----------|-------|
| **Clock** `󰥔` | digital / analog / minimal | Analog is locked to a square aspect |
| **Music** `󰝚` | full / round | Live MPRIS data (`music_info.json`, written by the dock); full shows a Cava bar strip |
| **Weather** `󰖐` | compact / full / round | Reads the local weather cache (`~/.cache/quickshell/weather/weather.json`); no network |
| **Visualizer** `󰎈` | bars / continuous | Mirrored spectrum over the shared `Cava` instance (64 bins); stretches to any size |
| **Image** `󰋩` | rect / rounded / round | Shows a picture from your wallpaper folder (see §4); round is a locked square |

Faces self-constrain: each one declares `minWidth/maxWidth/minHeight/maxHeight` and
`minAspect/maxAspect`. The redactor and the real widget window clamp with the exact
same algorithm, so a face never renders distorted or below its minimum size.

---

## 3. State file

Each monitor stores its own layout in the user state directory, one JSON list per
monitor (the monitor name is sanitized to `[a-zA-Z0-9_-]`):

```
~/.local/state/quickshell/widgets/<monitor-sanitized>/layout.json
```

```json
[ { "id": "w_abcd12", "type": "time", "variant": "analog",
    "x": 60, "y": 60, "w": 250, "h": 120,
    "opacity": 1.0, "rotation": 0, "imagePath": "" } ]
```

| Field | Meaning |
|-------|---------|
| `id` | Stable unique id (`w_<timestamp>_<rand>`); never reuse after deletion |
| `type` / `variant` | Catalog ids from `WidgetRegistry` (see table above) |
| `x` / `y` | Top-left corner in monitor pixels (0,0 = monitor top-left) |
| `w` / `h` | **Logical** size in pixels (before rotation; the window box swaps axes for 90°/270° like the real window) |
| `opacity` | 0.0 – 1.0 |
| `rotation` | 0 / 90 / 180 / 270 |
| `imagePath` | Absolute path of the displayed picture (Image widgets; `""` = placeholder) |

The file is rewritten atomically (temp file + `mv`) ~300 ms after the last edit and
flushed immediately when the editor closes. Widgets survive shell reloads
(`reload.sh`) untouched. If a layout file is ever corrupted it is moved aside to
`layout.json.bak` and the screen starts empty.

## 4. Image picker

Image widgets pull from the wallpaper collection:

- Gallery source: `$WALLPAPER_DIR` (`~/.config/hypr/wallpapers` by default), image
  files only (jpg / jpeg / png / gif / webp — video wallpapers are excluded).
- Thumbnails: the picker prefers `~/.cache/quickshell/wallpaper_picker/thumbs/`
  (maintained by `qs_manager.sh`) and falls back to loading the file itself.
- A manual path field accepts any absolute image path and validates it live; leaving
  it empty clears the widget's image (the face shows its placeholder).

## 5. Notes & tips

- **Cava is shared**: music/visualizer faces register a consumer on the single
  `Cava` instance only while they are actually visible. During an editor session the
  hidden previews never register consumers, so no double audio processing occurs.
- **Palette is live**: all faces and the editor chrome bind `Theme` colors; editing
  or switching palettes (Dock Editor → Palette) repaints them instantly.
- **Multi-monitor**: the editor edits the monitor it opens on (the one where the
  central popup appears); every monitor keeps an independent `layout.json`.
- **Z order** follows the widget list order: the last added widget renders on top.
- Adding the keybind to `keybinds.lua` requires a config reload
  (`hyprctl reload` or `SUPER+SHIFT+R`) to take effect.
