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
    palettes/*.json       # 13 palettes (base-16 from references.md + optional role overrides)
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

- **Config lives in `settings.json` under `"dock"`.** The dock watches the file with
  `inotifywait` (same pattern the old bar used) and re-applies on every write — no reload
  needed for visual changes.
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

---

## 6. Roadmap (mega menu)

1. **Dock tab** in `SettingsPopup.qml` (replaces the old "Topbar" tab): position picker,
   palette picker, roundness/pill/border controls (reusing the existing live-edit +
   debounced-save pattern), and a **zone editor** that CRUDs on `dock.zones`.
2. **Per-module options** (`dock.modules.<id>.*`): accent color, icon, label, click action,
   visibility conditions — the "radical customization" layer.
3. **Presets / import-export**: share a full `dock` config as JSON.
4. **Per-monitor layouts** (`dock.byMonitor.<name>`): different position/zones per display.
