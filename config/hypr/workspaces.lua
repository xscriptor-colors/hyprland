-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║ WORKSPACE RULES & SCRATCHPADS                                              ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ MULTI-MONITOR WORKSPACE BINDING                                          │
-- │                                                                           │
-- │ Workspaces 1-4 are pinned to the physical screens below, following the   │
-- │ author's layout from the laptop outwards (laptop = 1, then leftwards     │
-- │ 2, 3, 4). Rules match by EDID description (model + serial), so on other  │
-- │ hardware they are INERT: unmatched monitors keep free-floating           │
-- │ workspaces and nothing is imposed on different rigs.                     │
-- │                                                                           │
-- │ Identify your own monitors with: hyprctl monitors all                    │
-- │ (the "description" field is the key, e.g. "Xiaomi ... 5275600003570").   │
-- │ Workspaces 5-10 stay unbound (float wherever focused).                   │
-- └───────────────────────────────────────────────────────────────────────────┘

-- --- LAPTOP (rightmost) + externals leftwards ---
local MON_LAPTOP = "desc:BOE NE160WUM-NXA"
local MON_LEFT2  = "desc:Xiaomi Corporation P27FBB-RGGL 5275600003084"  -- DP-6
local MON_LEFT3  = "desc:Xiaomi Corporation P27FBB-RGGL 5275600003570"  -- HDMI-A-3
local MON_LEFT4  = "desc:Xiaomi Corporation P27FBB-RGGL 5275600072695"  -- DP-5

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
