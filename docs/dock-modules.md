# Dock Modules — Contract & Customization Guide

Every module is a small QML file that renders one island pill. Thanks to `ModulePill`
(the shared component), a module no longer re-implements backgrounds, borders, hover
scale, entrance animations or clicks — it only declares *what* it shows and *what it does*.

---

## 1. The module contract (what Zone injects)

When `Zone.qml` instantiates a module it always injects these 7 properties (also
injected by the legacy `TopBar` during the migration, so modules work in both):

| property                  | type   | meaning |
| ------------------------- | ------ | ------- |
| `bar`                     | var    | the Dock window: all shared state + helpers (`bar.s()`, `bar.orientation`, `bar.timeStr`, `bar.wifiSsid`, …) |
| `colors`                  | var    | the active palette (`colors.base`, `colors.mauve`, `colors.surface1`, …) |
| `zoneReady`               | bool   | zone entrance finished (drive the per-module stagger) |
| `slotIndex`               | int    | module position in its zone (stagger offset) |
| `effectiveBorderWidth`    | real   | zone border width (0 if unified) |
| `effectiveBorderColor`    | string | zone border color role |
| `unified`                 | bool   | zone is a single continuous pill |

---

## 2. `ModulePill` API

A module's root is a `ModulePill`; its children become the pill content.

```qml
import QtQuick
import Quickshell
import "../../dock"

ModulePill {
    // --- injected (declared as required inside ModulePill) ---
    // bar, colors, zoneReady, slotIndex, effectiveBorderWidth,
    // effectiveBorderColor, unified

    // --- orientation helpers (read-only) ---
    // horizontal: bool   (true on top/bottom docks AND legacy TopBar)
    // compact:    bool   (true on left/right docks)

    // --- visuals ---
    accentRole: "color6"      // colors.* role; when accentActive → solid accent island
    accentColor: "transparent"// direct color override (dynamic values, e.g. battery)
    accentActive: true        // whether the accent fill is shown (state-driven)
    pulse: false              // pulsing ring behind content (update/recording)
    bgRole: "surface0"        // idle island tone (or "base" for the soft look)
    bgHoverRole: "surface1"
    idleRole: "text"          // content color role when idle
    hoverRole: ""             // content color role on hover (falls back to idleRole)
    fullHeight: false         // use bar.barHeight instead of bar.pillHeight
    showState: true           // collapse the pill (width/height animate to 0)
    noFill: false             // force transparent background (media/tray)
    padH / padV: int          // inner padding

    // --- signals ---
    // clicked()   rightClicked()   wheelUp()   wheelDown()

    // --- content color (bind text color to it) ---
    // contentColor  -> colors.base on accent islands, else idle/hover role

    // content children:
    Text { color: mod.contentColor ... }
}
```

### Visual modes (preserving the original aesthetic)

- **Standard island** (help, search, settings, time, tray…): semi-transparent
  `surface0` → `surface1` on hover.
- **Accent island** (wifi, bluetooth, volume, battery, keyboard, sysmon, update,
  recording): solid colored pill; content drawn in `colors.base`. Driven by
  `accentRole`/`accentColor` + `accentActive`.
- **Transparent island** (media): `noFill: true`, only border.
- **Unified zone**: when the zone is unified, pills become transparent and the zone
  background takes over (`unified` prop).

---

## 3. Orientation / compact mode

On **left/right docks** (`bar.orientation === "vertical"`) the pill becomes a narrow
vertical island and every module is expected to show **reduced** content:

| module | horizontal (full) | compact (reduced) |
| --- | --- | --- |
| help / search / settings | icon | icon (unchanged) |
| update | icon + pulse | icon + pulse |
| recording | icon + blink | icon + blink |
| time | `HH:mm:ss` | `HH:mm` |
| date | full date (typewriter) | hidden |
| media | art + title + controls | music icon |
| workspaces | row of ws pills | **column** of ws pills |
| tray | single row of icons | 2-column grid |
| keyboard | icon + layout | icon |
| wifi | icon + ssid | icon |
| bluetooth | icon + device | icon |
| sysmon | icon + cpu + ram | two tiny stacked values |
| volume | icon + percent | icon |
| battery | icon + percent | icon |
| weather | weather glyph + temperature | glyph over temperature |
| focus | app icon + window title | app icon |

`weather` and `focus` are **new islands shipped disabled by default** — enable
them in the Dock Editor → Zones (their entries exist in `dock.zones` with
`enabled: false` and are re-added disabled after updates, so existing bars
never change on their own).

Modules can be moved between zones/alignments from the Dock Editor by
**dragging the zone card chips** (Dock Editor → Zones, ghost + insertion
indicator; enabled chips only, drop index counts enabled chips — see
`docs/dock.md` §6).

- **weather**: shows `bar.weatherIcon` + `bar.weatherTemp` (data polled every
  150 s by the dock from `calendar/weather.sh`). The island fill follows the
  weather code color (`bar.weatherHex`); click opens the calendar popup.
- **focus**: shows the title of the currently focused window
  (`bar.focusTitle`, polled every second via `hyprctl activewindow -j`),
  with an app glyph derived from the window class (`bar.focusIcon`). The
  island collapses on an empty desktop; click opens the app launcher.

Modules branch with `visible: mod.horizontal` / `visible: mod.compact` inside the
content.

---

### Workspaces module — empty markers

Empty workspaces (no windows) render a configurable marker instead of the
workspace number:

- `dock.workspacesMarker`: `number` (default) / `dot` / `letter` (A, B, C… by
  index) / `custom`.
- `dock.workspacesMarkerText`: the glyph for `custom` — any Unicode character,
  e.g. a Japanese one (up to 4 chars).
- Occupied workspaces always show their app icons; markers only appear on empty
  pills (including an empty ACTIVE workspace, drawn over the sliding
  highlight). Marker color follows the pill state (active/hover/empty).

The active-workspace highlight color can be themed per palette through the
`workspaceActive` role (see `docs/themes.md`) — e.g. theme `x` uses gold, while
`berlin`/`london` use a theme gray and `madrid`/`helsinki` a dark gold.

## 4. Adding a new module

1. Create `quickshell/topbar/modules/MyModule.qml` (root = `ModulePill`).
2. Register it in **`dock/DockLayout.js`** `MODULES` array:
   ```js
   { id: "mymodule", label: "My Module", icon: "󰂓",
     component: "topbar/modules/MyModule.qml" }
   ```
   (`component` is resolved relative to the quickshell root by `Zone.qml`.)
3. Give it a default zone placement if you want it on fresh installs
   (`normalizeDock` re-adds catalog modules not present in the config).
4. If it needs live data, read `bar.<prop>` (add a watcher in `Dock.qml` if needed) or
   read the future per-module options from `bar.modCfg(id)`.

---

## 5. Future per-module options (mega menu hook)

The settings menu will eventually expose per-module options. The planned schema lives
under `dock.modules.<id>.*` and modules will read them via a small helper:

```qml
// planned helper on the bar object
// bar.modCfg("time") -> { accent: "blue", icon: "...", action: "...", showWhen: "..." }
```

Until that ships, all per-module behavior is declared inline in the module file — which
is exactly where a future `dock.modules.<id>.*` lookup will plug in, so keep module
props simple and self-contained.
