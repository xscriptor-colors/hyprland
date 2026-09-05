# Dock System — Architecture & Customization

The dock replaces the old `TopBar.qml` with a **position-agnostic island bar** that can sit
on any screen edge (`top` / `bottom` / `left` / `right`) while keeping the same aesthetic
(island pills, unified zones, borders, animations) and all module functionality.

This document is the canonical reference for extending it, and especially for building the
**mega customization menu** (the settings panel tab that will let users edit every aspect of
the dock without touching QML).

---

## 1. File layout

```
quickshell/
  Shell.qml               # entry point: Main {} + TopBar {} + Floating {}
                          #   -> will become: Main {} + Dock {} + Floating {}
  dock/                   # the new dock system (self-contained)
    Dock.qml              # the PanelWindow shell (position, orientation, IPC, data pollers)
    Zone.qml              # renders ONE zone as a Row (horizontal) or Column (vertical)
    ModulePill.qml        # the shared island pill (all visual plumbing)
    Colors.qml            # Matugen-free palette loader + semantic role derivation
    DockLayout.js         # pure-JS engine: zone-as-data model, module catalog, migration
    palettes/*.json       # 12 palettes (base-16 + optional role overrides)
  topbar/modules/*.qml    # the 16 modules (being migrated to ModulePill)
  topbar/TopbarLayout.js  # OLD catalog — still used by the legacy TopBar during migration
```

---

## 2. Data flow

```
settings.json
   "dock": { position, palette, thickness, zones: [...] }
        |
        v
Dock.qml (settingsReader, inotify watcher)
   dockConfig = DockLayout.getDock(parsed)     // pure JS normalize/migrate
        |
        v
Dock.qml -> zones (Repeater) -> Zone.qml -> module Loaders -> modules
        ^                                        |
        |-- shared state: bar.* (pollers/watchers) + colors.* (palette)
```

- **Config lives in `settings.json` under `"dock"`.** The dock watches the file
  with `inotifywait` and re-applies on every write — no reload needed for visual
  changes. Since Phase D3 the watchers target the `~/.config/hypr` **directory**
  (settings.json is written atomically via tmp + `mv`, which kills a watch on
  the file inode) and every re-read goes through a content-compare choke point,
  so unrelated config edits never cause redundant repaints — live editing is
  reliable even while the shell runs.
- **Data state** (workspaces, wifi, volume, battery, music, clock, sysmon…) is fetched by
  `Process` watchers declared in `Dock.qml` and exposed on the `bar` object that every
  module receives.
- **Colors** come from `Colors.qml` (palette system), never from Matugen.

---

## 3. `settings.json` → `dock` schema (the mega-menu contract)

Everything the menu will edit lives under one key:

```jsonc
{
  "dock": {
    "position": "top",            // "top" | "bottom" | "left" | "right"
    "palette": "x",               // slug of dock/palettes/<slug>.json
    "thickness": 48,              // bar height (horizontal) or width (vertical)
    "edgeGap": 8,                 // distance from the chosen screen edge
    "roundness": 1.0,             // 0.0 (square) … 1.0 (fully rounded)
    "pillBg": true,               // islands show a background fill
    "pillSolid": false,           // opaque fill vs semi-transparent
    "barBg": false,               // continuous strip behind the whole bar
    "barOpacity": 0.85,           // alpha of the barBg strip (0.2–1.0)
    "dragModules": true,          // live island drag & drop on the bar
    "stylePreset": "modular",     // "modular" | "solid" | "fill" (label + shortcut)
    "borderWidth": 0,             // default border for all zones
    "borderColor": "surface1",    // color role (colors.*) for the border
    "zones": [                    // ← zones are DATA, not code
      {
        "id": "start",            // unique, user-renamable
        "align": "start",         // "start" | "center" | "end" (along the main axis)
        "unify": false,           // merge every module into one continuous pill
        "borderWidth": 0,         // per-zone override (defaults to dock.borderWidth)
        "borderColor": "surface1",
        "modules": [              // ordered, enabled/disabled
          { "id": "time", "enabled": true },
          { "id": "date", "enabled": true }
        ]
      }
      // …add as many zones as you like
    ]
  }
}
```

**Migration:** if `dock` is missing but the legacy `topbar` key exists
(`{left, center, right}` + `topbarRoundness`/`topbarBorder*`/`topbarUnify*`), it is
converted automatically by `DockLayout.getDock()`.

### What each mega-menu control will edit (integration map)

| UI control (planned)            | settings.json key                    | consumed by                |
| ------------------------------- | ------------------------------------ | -------------------------- |
| Position picker (4 edges)       | `dock.position`                      | `Dock.qml` (anchors/orient)|
| Palette selector                | `dock.palette`                       | `Colors.qml`               |
| Bar thickness / gap             | `dock.thickness`, `dock.edgeGap`     | `Dock.qml` geometry        |
| Roundness slider                | `dock.roundness`                     | `Dock.qml` → `pillRadius()`|
| Island fill / solid toggles     | `dock.pillBg`, `dock.pillSolid`      | `Dock.qml` → modules       |
| Border (width/color, global)    | `dock.borderWidth`, `dock.borderColor`| zones → `effectiveBorder*` |
| **Zone editor** (add/remove/rename/align) | `dock.zones`              | `DockLayout.js` CRUD fns   |
| Per-zone unify / border         | `dock.zones[i].unify/border*`        | `Zone.qml`                 |
| Module ordering/toggle (drag)   | `dock.zones[i].modules`              | `DockLayout.js` move/set   |
| Module options (future)         | `dock.modules.<id>.*`                | modules read `bar.modCfg`  |

---

## 4. `DockLayout.js` — the pure engine

All zone/module manipulation is **pure JS** (no QML), so the settings menu and the dock
share the exact same logic. Key functions:

| function | purpose |
| --- | --- |
| `getDock(rawSettings)` | parse + normalize + migrate legacy → full dock config |
| `normalizeDock(raw)` | validate a `dock` object, re-add missing modules/zones |
| `defaultDock()` | factory default (3 zones, all modules) |
| `getModule(id)` / `MODULES` | module catalog (label/icon/component) |
| `zoneModel(zone)` | enabled module ids of a zone (for Repeaters) |
| `cloneDock / setEnabled / toggleEnabled / isEnabled` | module enable/disable |
| `moduleMove(dock, id, delta)` | reorder, hops zones at edges |
| `moduleMoveTo(dock, id, zoneId, index)` | move a module to a zone/position (enabled-index semantics) |
| `applyStylePreset(dock, preset)` | one-click bar look (modular/solid/fill, §6) |
| `arrangeAllInZone(dock, align)` / `firstZoneWithAlign` | gather every enabled module into one alignment zone |
| `addZone / removeZone / renameZone / setZoneAlign` | zone CRUD for the editor |
| `setZoneUnify / setZoneBorder` | per-zone visuals |
| `flatten(dock)` | flat list for the editor's module list |

> **Gotcha:** arrays that cross the QML ↔ JS boundary through `property var` become
> `QVariantList`, which breaks `Array.isArray`. All iteration uses the length-based
> `isList()` helper. Keep it that way in new code.

---

## 5. Adding / removing / customizing modules

See **`docs/dock-modules.md`** for the module contract, the `ModulePill` API and the
orientation/compact behavior.

Two dock-level settings are consumed by the dock window (`dock/Dock.qml`):

- `dock.dragModules` (default `true`) — enables **drag & drop island
  reordering** directly on the bar (see below).
- `dock.barOpacity` (0.2–1, default 0.85) — alpha of the full-bar background
  strip shown when `dock.barBg` is enabled.

### Drag & drop islands

Grab any enabled island with the left mouse button and drag it along the bar:
the remaining islands reorder live under the cursor. Release over a zone to
commit (the new `dock.zones` order is written to `settings.json` atomically);
release **outside** the bar to cancel (nothing changes). A short press without
movement still triggers the module's normal click, so dragging never fights
existing click behavior. Disable the whole gesture with the "Drag modules"
toggle in the Dock Editor, or `dock.dragModules: false`.

Implementation notes (for maintainers):

- The pure engine functions live in `DockLayout.js`
  (`moduleMoveTo(dock, id, zoneId, index)`, `enabledCount`,
  `enabledIndexOf`) — they clone, never mutate.
- Each module slot in `dock/Zone.qml` carries a drag `MouseArea`; once the
  ~12 px threshold is crossed it calls `bar.startDrag(id)` and feeds pointer
  positions to `bar.updateDragAt()` / `bar.endDragAt()` / `bar.cancelDrag()`.
- While `bar.dragBusy`, zone entrance animations and pill size/opacity
  behaviors are suppressed (`ModulePill.dragSuppress`) so model rewrites stay
  flicker-free, and the settings reader defers external refreshes until the
  gesture ends.

---

## 6. Bar styles & quick layout (one-click looks)

The Dock Editor ships three **style presets** (Appearance → Style) that map to
the pill/bar flags without ever clobbering unrelated manual tweaks (only the
keys a preset declares are applied; `dock.stylePreset` is an informational
label + apply shortcut — re-raise "Edge margin" after choosing Fill and the
label stays, the strip just gains a gap):

| Preset  | Writes                                          | Look |
| ------- | ----------------------------------------------- | ---- |
| Modular | `pillBg:true, pillSolid:false, barBg:false`     | floating islands on the raw desktop |
| Solid   | `barBg:true, pillBg:true`                       | continuous bar strip with islands floating inside it (accent islands stay colored) |
| Fill    | `barBg:true, pillBg:true, edgeGap:0`            | edge-to-edge strip, no gap to the screen edge |

Pure-JS helpers: `DockLayout.applyStylePreset(dock, preset)` (clone-first,
preset-key only) and `normalizeDock()` defaults an absent `stylePreset` to
`"modular"` **without** inferring or touching the real flag values
(backwards-compatible: old configs keep their exact look).

### Quick layout: "Center all" (Zones card)

The **Center all** pill gathers every **enabled** island into the first zone
aligned `center` (creating that zone when the dock has none), in catalog
order, and never touches disabled entries — `weather`/`focus` stay disabled
where they were, emptied zones are not deleted. Implemented by the pure
`DockLayout.arrangeAllInZone(dock, align)`.

### Dragging modules between zones (inside the editor)

Each module chip in the Zones cards is draggable with the left button past a
~10 px threshold (short presses still toggle, the ◀ ▶ buttons still work). A
ghost follows the pointer, the target card lights up with an accent border and
a thin insertion bar shows the exact spot; drop to move the module to that
zone/position, release anywhere else to cancel. Semantics (documented, engine
coherent): drop indices count **enabled** chips only and ignore the dragged
chip — exactly what `DockLayout.moduleMoveTo()` expects — and disabled chips
are not draggable. Same-zone/same-spot drops are no-ops (nothing is written).

### Hot orientation (no shell reload)

Since Phase D3, changing the dock **position/orientation** from the Position
card never reloads the whole shell: an axis flip (horizontal ↔ vertical)
triggers an **in-process remount** — `Dock.qml` empties the zones model and
refills it on the next event turn, so every `Zone` and module `Loader` is
recreated against the already-synced geometry/orientation (same-axis moves and
visual changes never rebuild anything). Zone entrance animations replay and
the window relayouts through the existing size/anchors bindings.

---

## 6b. Dual bar engines (dock ⇄ serp)

Since Phase D4-E1b the same host window supports **two interchangeable render
engines**, switched live (no reload) through one top-level settings key:

```jsonc
{
  "barEngine": "dock",              // "dock" | "serp"
  "dock": { /* unchanged — zones config is preserved and restored */ },
  "serpbar": {
    "position": "top",              // "top" | "bottom" | "left" | "right"
    "style": "modular",             // "modular" | "solid" | "fill"
    "widthPercent": 100,            // 40–100: strip length on the main axis
    "distinctPills": false,         // solid/fill: give every module+group its
                                    // own subtle slab on the strip (default
                                    // false = plain flat strip, like serpantium)
    "thickness": null,              // px 24–120 or null = inherit dock.thickness
                                    // (the bar band height/width)
    "opacity": 100,                 // % 20–100 strip alpha (default 100 = opaque)
    "autohide": false,              // slide away + 4px edge tab
    "autohideTimeout": 800,         // ms before hiding after the cursor leaves
    "modules": {
      "left":   ["help", "search", "settings", "media"],
      "center": [["time", "date", "weather"]],
      "right":  [["keyboard", "wifi", "bluetooth", "volume", "battery"], "tray", "update"]
    }
  }
}
```

- **`serpbar`** lives at the top level of `settings.json` next to `dock`
  (schema handled by the pure `DockLayout.js` serpbar section: `serpbarDefaults`,
  `normalizeSerpbar`, `getSerpbar`, `serpTokenModules`, `serpStyleFlags`,
  `isFillStyle`, `serpSectionNames`, `dockToSerpModules`).
- The **zone config under `dock` is never touched** while engine `"serp"` is
  active and is restored exactly when switching back to `"dock"` — the host
  re-applies the persisted `dock` flags/position through `syncDockConfig()`.
- **Size language:** the strip band takes `serpbar.thickness` when set
  (Phase R1; `null` = the current `dock.thickness`, so the classic bar starts
  at the size the user's dock has). Corner radii scale with the **shared**
  `dock.roundness` knob and module fonts with `dock.font` — both are edited
  from the dock engine's Appearance card.
- **Palette is shared**: the Palette card of the Dock Editor is available in
  both engines and writes `dock.palette`; Colors roles recolor whichever
  engine is live.
- No module changes: SerpBar instantiates the **same
  `topbar/modules/*.qml` islands with the standard contract**
  (`bar`, `colors`, `zoneReady`, `slotIndex`, `effectiveBorderWidth/Color`,
  `unified`). While `barEngine: "serp"` the host mirrors the serp style onto
  its own visual flags (`serpStyleFlags()` → `pillBg`/`pillSolid`/`barBg`/
  `edgeGap`, plus thickness/opacity, see `applySerpVisuals()`) and takes the
  bar edge from `serpbar.position`, so island rendering (incl. accent islands)
  is identical in both engines.

### Styles (same vocabulary as the dock presets)

| Style | Host flags (via `serpStyleFlags`) | SerpBar renders |
| ----- | --------------------------------- | --------------- |
| Modular | `pillBg:true, pillSolid:false, barBg:false` | no strip; loose islands + group slabs float on the desktop |
| Solid | `barBg:true, pillBg:false` (edgeGap → 4) | base-colored strip (alpha = `serpbar.opacity`), all corners rounded `s(8)·roundness`; islands float inside it (transparent fills) |
| Fill | like solid + `edgeGap:0` | the same strip flush against **all four** screen edges (margins 0, widthPercent forced to 100); the screen-edge side is flat, the far-side corners are rounded `s(12)·roundness` |

### Distinct pills

`serpbar.distinctPills` (only meaningful for the solid/fill strip — the
editor hides the toggle in modular, mirroring serpantium's BarTab): every
loose module **and** every group gets its own subtle raised slab
(`colors.surface1` @ 0.55, radius `s(8)·roundness`, inset `s(3)` per cross
side) over the strip. With `distinctPills: false` (default) the strip is
plain: modules and groups are flat and only the content is visible — this is
serpantium's `bar.distinctPills` semantics (default false).

### Sections, tokens and groups

`serpbar.modules` has three sections: **left**, **center**, **right** —
laid out along the bar's main axis (start / center / end). Each entry is:

- a **module id** (`"time"`, `"tray"`, …) → one loose island;
- a **layout token** (`"center"`, `"centerbox"`) → expands to several LOOSE
  islands (`time` + `weather`, see `DockLayout.serpTokenModules`);
- an **array** of module ids → ONE group: a chrome rectangle hosting the
  modules with `unified: true`, spacing 0 — the dock's unified zones
  semantics (ModulePill checks `unified` before its accent branch, so accent
  islands are transparent group members too).

Group chrome follows serpantium's `TopBar` rules: in modular every group is a
`colors.surface0` slab spanning the full bar height (exactly the member
bounds, no extra padding); on a plain solid/fill strip the slab is hidden;
with `distinctPills` it comes back as a raised slab inset `s(3)` per side.
Every island (loose or grouped) sits centered on its own full-height lane, so
mixed module heights never top-align.

Spacing between adjacent entries: `s(8)` in modular, `s(2)` on the strip
(serpantium uses a flat `s(2)` gap everywhere — see the parity table below).

### widthPercent / autohide

- `widthPercent` sizes the strip band on the main axis (centered); everything
  outside the band is transparent **and click-through** — the window's input
  mask (`Dock.qml`, `Region { item: … }`) tracks the SerpBar content box, so
  clicks outside the band reach the windows below. Fill forces 100%.
- `autohide: true` zeroes the edge-side margin and gives the bar a 4px edge
  sliver/tab: leaving the bar arms `autohideTimeout`, the band slides out
  along the cross axis (250 ms OutExpo) leaving only the tab; the exclusive
  zone drops to 0 while hidden and the input mask shrinks to the sliver, so
  maximized windows are fully usable. Hovering the tab (or the leftover
  sliver) reveals it again. The settings popup keeps the bar revealed.
- When sections do not fit (center + sides overlap), side sections keep their
  edge positions and the strip clip trims the overflow.

Switching engines, editing `serpbar`, or crossing the axis is **hot**: the
host re-applies visuals in place and only recreates module loaders when the
axis flips (same remount idea as the dock zones).

---

## 6c. Visual parity with serpantium's classic bar (Phase R1)

The classic engine reproduces serpantium's bar geometry with the hyprland
vocabulary (`bar.s()` scaling, `dock.roundness`, `colors.*` roles, shared
modules). Every value below cites the upstream source; **deliberate
differences** are listed at the end.

| Visual element | serpantium (file:line) | hyprland serp engine (file:line) |
| --- | --- | --- |
| Bar band size (thickness) | `barHeight: s(40)` fixed — `bar/Bar.qml:244` | `serpbar.thickness` (px) or the dock thickness; band = `barHeight`/`barWidth` (`Dock.qml:491-495`, applied `Dock.qml:347-349`) — at scale 1.0 with `thickness: 40` the band matches `s(40)` exactly |
| Edge breathing (distance to screen edge) | margins `s(4)` per side, `0` in fill — `bar/Bar.qml:265-270` | host margins: edge side `s(4)` (edgeGap override `Dock.qml:346`), cross sides `s(4)`, all `0` in fill (`Dock.qml:522-553`) |
| Strip radius — solid | `ThemeBackend.borderRadius` (8 raw) — `bar/TopBar.qml:491`; `singletons/ThemeBackend.qml:10` | `s(8)·roundness` — `SerpBar.qml:103,106,174` |
| Strip radius — fill | strip radius 0 + far-side corner canvases of `s(12)` — `bar/Bar.qml:245`, `bar/TopBar.qml:513-615` | far-side corners `s(12)·roundness`, screen-edge side flat — `SerpBar.qml:105-106,175-186` |
| Strip color / alpha | `alpha(base, opacity/100)`, opacity default 100 — `bar/TopBar.qml:490`; `guide/BarTab.qml:33-49` | `colors.base` @ `barOpacity` = `serpbar.opacity/100` (default 100) — `SerpBar.qml:187`, host `Dock.qml:350-352` |
| Strip border | `surface0` @ opacity, 1px, only in modular (solid: none) — `bar/TopBar.qml:492-493` | the serp strip uses the dock border keys (`bar.borderWidth/Color`) — see deliberate differences |
| Group slab — modular | visible, height = full `barHeight`, color `base` @ opacity — `bar/TopBar.qml:617-679` (height 629, color 658-660) | visible, full band height, `colors.surface0` (dock unified tone) — `SerpBar.qml:283,304-325` |
| Group slab — solid/fill | hidden (`!isSolid \|\| distinctPills`) — `bar/TopBar.qml:655` | hidden unless `distinctPills` — `SerpBar.qml:283,310-312` |
| Group slab — solid/fill + distinctPills | visible, `barHeight − 6` tall, `darker(surface0, 1.15)` @ opacity — `bar/TopBar.qml:629,658-659` | visible, band − `s(6)`, inset `s(3)`/side, `colors.surface1` @ 0.55 — `SerpBar.qml:112,320-323` |
| Loose island — modular | own island bg: `base` @ opacity, hover `surface0`, full `barHeight` — `bar/modules/TimeDateWidget.qml:96,53` | ModulePill capsule islands (`pillHeight` = thickness − `s(12)`), translucent `surface0` @ 0.4 → hover `surface1` — shared module language |
| Loose island — solid/fill | transparent (no fill) — `TimeDateWidget.qml:96` | transparent (`pillBg:false` style flags, `DockLayout.js:794-797`) |
| Loose island — solid/fill + distinctPills | `barHeight − 6` tall, `darker(surface0,1.15)` — `TimeDateWidget.qml:96,53` | raised slab `surface1` @ 0.55, `s(3)` inset per side — `SerpBar.qml:312,320-323` |
| Island/group radius | `ThemeBackend.borderRadius` (8) — e.g. `TimeDateWidget.qml:95` | `s(8)·roundness` — `SerpBar.qml:103,319` |
| Group inner layout | member widgets overlap `−s(4)` (`groupGap`) — `bar/TopBar.qml:238` | unified pills, spacing 0 (the transparent pill paddings reproduce the tightened look) — `SerpBar.qml:332,341` |
| Unit centering | every widget centered individually — `bar/TopBar.qml:450-459` | per-island band lanes, each centered — `SerpBar.qml:364-365,375-377` |
| Item spacing | `s(2)` between units — `bar/TopBar.qml:237` | `s(2)` on the strip, `s(8)` in modular — `SerpBar.qml:97` |
| Section insets | first unit at `horizontalOffset + s(1) + s(4)` — `bar/TopBar.qml:278` | section pad `s(6)` from the band edge — `SerpBar.qml:93,207,239` |
| Hide sliver (autohide) | window mask keeps `s(4)` at the edge — `bar/Bar.qml:275-276` | `s(4)` leftover tab — `SerpBar.qml:138,412` |
| Hide/reveal animation | 300 ms OutQuint translate of the whole bar — `bar/TopBar.qml:465-477` | 250 ms OutExpo slide of the band — `SerpBar.qml:158-159` |
| Autohide timeout default | 1000 ms — `bar/Bar.qml:110` | `serpbar.autohideTimeout` default 800 ms (editor-adjustable) |

**Deliberate differences (documented, keep in mind when debugging):**

- **Islands keep the dock capsule language** (full capsule ends, translucent
  `surface0` fills, accent solid pills) instead of serpantium's
  `base`-colored rounded rects. The serp engine therefore reads as "classic
  bar geometry + hyprland islands".
- **Vertical bars** keep the dock's minimum cross size of `s(70)`
  (`Dock.qml:475`) because the shared compact modules need the width;
  serpantium's vertical bar is `s(40)` thin. `serpbar.thickness` only widens
  a vertical bar beyond 70.
- **Group chrome tones** use the dock's unified-zone `colors.surface0`
  (modular) and `colors.surface1` @ 0.55 (strip) instead of serpantium's
  `base`/`darker(surface0,1.15)` — same luminance relationship, our roles.
- **Opacity** only fades the strip (solid/fill); modular island fills keep
  their own translucency (serpantium fades the whole island content too).
- **Solid strip radius** derives from our roundness knob and the strip can
  take a 1px border via the dock border keys (serpantium borders its modular
  window only).
- Modules are hyprland-native (time+date separate islands, weather island
  with hex accent, tray, update island…), not serpantium's combined
  timedate/info/vis widgets — the section cards map them 1:1 instead.

---

## 7. Roadmap (mega menu)

1. **Dock tab** in `SettingsPopup.qml` (replaces the old "Topbar" tab): position picker,
   palette picker, roundness/pill/border controls (reusing the existing live-edit +
   debounced-save pattern), and a **zone editor** that CRUDs on `dock.zones`.
2. **Per-module options** (`dock.modules.<id>.*`): accent color, icon, label, click action,
   visibility conditions — the "radical customization" layer.
3. **Presets / import-export**: share a full `dock` config as JSON.
4. **Per-monitor layouts** (`dock.byMonitor.<name>`): different position/zones per display.
