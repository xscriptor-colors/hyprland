-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║ WORKSPACE RULES & SCRATCHPADS                                              ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ MULTI-MONITOR: UNIFIED DESKTOPS & BOOT DEFAULTS                          │
-- │                                                                           │
-- │ The author's rig is 4 physical screens (laptop + 3 Xiaomi). The rules    │
-- │ below are only the BOOT DEFAULTS of "desktop 1": each monitor starts on  │
-- │ its own pinned workspace (laptop = 1, then leftwards 2, 3, 4).           │
-- │                                                                           │
-- │ Optional UNIFIED DESKTOPS mode (scripts/ws-desktops-lib.sh is the engine)│
-- │ turns SUPER + 1..9 into full-desktop jumps: with >= 2 roster screens     │
-- │ connected, EVERY screen switches at once (workspace = (d-1)*4 + rank).   │
-- │ With fewer screens — or on other people's hardware (different EDIDs) —   │
-- │ the classic per-monitor behavior is kept untouched. Disable the mode     │
-- │ explicitly with "unifiedDesktops": false in settings.json.               │
-- │                                                                           │
-- │ KEEP THE MON_* DESCRIPTIONS IN SYNC with ROSTER_DESCS in                 │
-- │ scripts/ws-desktops-lib.sh (same rank order!).                           │
-- │                                                                           │
-- │ Identify your own monitors with: hyprctl monitors all                    │
-- │ (the "description" field is the key, e.g. "Xiaomi ... 5275600003570").   │
-- └───────────────────────────────────────────────────────────────────────────┘

-- --- LAPTOP (rightmost) + externals leftwards ---
-- NOTE: same order/descriptions as ROSTER_DESCS in scripts/ws-desktops-lib.sh
local MON_LAPTOP = "desc:BOE NE160WUM-NXA"
local MON_LEFT2  = "desc:Xiaomi Corporation P27FBB-RGGL 5275600003084"  -- DP-6
local MON_LEFT3  = "desc:Xiaomi Corporation P27FBB-RGGL 5275600003570"  -- HDMI-A-3
local MON_LEFT4  = "desc:Xiaomi Corporation P27FBB-RGGL 5275600072695"  -- DP-5

-- Desktop-1 boot defaults: each monitor shows its own pinned workspace on login.
hl.workspace_rule({ workspace = "1", monitor = MON_LAPTOP, default = true })
hl.workspace_rule({ workspace = "2", monitor = MON_LEFT2, default = true })
hl.workspace_rule({ workspace = "3", monitor = MON_LEFT3, default = true })
hl.workspace_rule({ workspace = "4", monitor = MON_LEFT4, default = true })

-- --- ALTERNATIVE: pin your own screens here (examples) ---
-- hl.workspace_rule({ workspace = "1", monitor = "desc:YOUR_PRIMARY_DESCRIPTION", default = true })
-- hl.workspace_rule({ workspace = "2", monitor = "desc:YOUR_SECONDARY_DESCRIPTION" })
-- hl.workspace_rule({ workspace = "3", monitor = "desc:YOUR_THIRD_DESCRIPTION" })

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ SPECIAL WORKSPACES (Scratchpads)                                         │
-- │                                                                           │
-- │ Named scratchpads toggled with keybinds. They launch their app           │
-- │ automatically on first toggle via on_created_empty.                      │
-- └───────────────────────────────────────────────────────────────────────────┘

hl.workspace_rule({ workspace = "special:terminal", on_created_empty = "kitty --class scratchpad-terminal" })
hl.workspace_rule({ workspace = "special:files", on_created_empty = "nautilus" })
hl.workspace_rule({ workspace = "special:music", on_created_empty = "spotify" })
