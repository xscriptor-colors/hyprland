# Palette System

The system uses **12 fixed palettes** (Matugen-free) defined as JSON in `config/hypr/scripts/quickshell/dock/palettes/`. The active palette is controlled from the Dock Editor (`SUPER + SHIFT + D` → *Palette* card) and stored in `settings.json` under `dock.palette`.

## Palette files

- `dock/palettes/<slug>.json` — one file per palette (base-16 colors + optional `background`/`foreground`/`roles` overrides).
- `dock/palettes/index.json` — ordered list of palettes shown in the Dock Editor.
- `dock/Colors.qml` — singleton-style component that loads the active palette and derives the semantic roles (`base`, `surface0/1/2`, `text`, `overlay0/1/2`, accent set). Every widget reads from `colors.<role>`, so swapping the palette never touches widget code.

## Color Flow

1. User picks a palette (or border color) in the Dock Editor.
2. `DockEditor` writes `settings.json` → `dock` (palette slug, border overrides).
3. Each widget's `Colors` instance watches `settings.json` and re-applies the palette live.
4. The dock bar and Dock Editor push window-border colors to Hyprland **live** via `hyprctl eval 'hl.config({ general = { col = { active_border = "rgba(...)", inactive_border = "rgba(...)" } } })'` — no window restart needed.

## Window borders

Window borders are palette-driven, with optional manual override:

- `dock.borderFollowPalette` (`true` by default) — active border = palette accent (`color1`), inactive = muted (`color8`).
- When `false`, the manual `dock.borderActive` / `dock.borderInactive` hex values are used.
- Load-time defaults are derived in `config/hypr/colors.lua` from the active palette JSON (no Matugen involved).

## Editing the active palette (live)

The Dock Editor can recolor the **active** palette in real time — no Matugen, no new palette format:

1. Open the Dock Editor (`SUPER + SHIFT + D`) → *Palette* card → **Edit colors**.
2. The inline editor lists the 18 editable slots of the active palette file: base16 `color0`..`color15` plus the top-level `background` and `foreground` rows. Each row has a swatch, the slot name and a validated `#rrggbb` hex field (invalid input gets a red border and is discarded on blur).
3. Committing a hex (Enter or click elsewhere) normalizes it to lowercase and rewrites `dock/palettes/<slug>.json` atomically — debounced ~250 ms, `jq` over a `mktemp` temp file then `mv`, preserving `name`/`author`/`slug`/`roles` and any unknown keys. `settings.json` is never touched: the palette file is the source of truth.
4. Propagation is instant: `dock/Colors.qml` and the widgets `Theme.qml` singleton watch the palettes directory, re-read the active file and re-apply it, so dock islands, Dock Editor chrome and every desktop-widget face recolor live. The border push (`syncWindowBorders`) also re-syncs Hyprland window borders via `hyprctl eval`, regenerates kitty themes + the starship palette (`theme-sync.sh`) and rewrites the SDDM login theme (`sddm-colors.sh`).
5. **Session snapshot**: the first edit of a palette copies its pristine file to `~/.local/state/quickshell/palette_backup/<slug>.json` (a snapshot from an earlier session is never overwritten). The card's **Reset** button (enabled while a snapshot exists) restores that snapshot atomically and deletes it; editing after a Reset starts a fresh snapshot. Only the active palette file is ever written — the other palettes stay untouched, and the file format is unchanged, so deleting `palette_backup/` and re-deploying `dock/palettes/` reverts everything.

## Colors.qml roles

`Colors` exposes the same role API the widgets have always used: `base`, `mantle`, `crust`, `text`, `subtext0/1`, `surface0/1/2`, `overlay0/1/2`, the accent set (`blue`, `sapphire`, `peach`, `green`, `red`, `mauve`, `pink`, `yellow`, `maroon`, `teal`), plus `color0..color15`, `background`, `foreground`, `accent`, `accent2`.

## Hyprland colors.lua

Hyprland border colors come from `config/hypr/colors.lua`, which reads `settings.json` (`dock.palette`, `dock.borderFollowPalette`, `dock.borderActive`, `dock.borderInactive`) and the matching palette JSON:

- `X.active_border` -- active window border (palette accent)
- `X.inactive_border` -- inactive window border (palette muted / color8)
- Palette exported as `X.color0..X.color15`, plus `background`, `foreground`, `accent`, `accent2` aliases

These are consumed by `settings.lua` via `require("colors")`.
