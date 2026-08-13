-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║ WORKSPACE RULES & SCRATCHPADS                                              ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ MULTI-MONITOR WORKSPACE BINDING                                          │
-- │                                                                           │
-- │ Identify your monitors with: hyprctl monitors all                        │
-- │ Workspaces 1-5 → Primary monitor (usually eDP-1 on laptops)             │
-- │ Workspaces 6-10 → Secondary monitor (external)                          │
-- └───────────────────────────────────────────────────────────────────────────┘

-- --- PRIMARY MONITOR (laptop screen) ---
-- hl.workspace_rule({ workspace = "1", monitor = "desc:YOUR_PRIMARY_DESCRIPTION", default = true })
-- hl.workspace_rule({ workspace = "2", monitor = "desc:YOUR_PRIMARY_DESCRIPTION" })
-- hl.workspace_rule({ workspace = "3", monitor = "desc:YOUR_PRIMARY_DESCRIPTION" })
-- hl.workspace_rule({ workspace = "4", monitor = "desc:YOUR_PRIMARY_DESCRIPTION" })
-- hl.workspace_rule({ workspace = "5", monitor = "desc:YOUR_PRIMARY_DESCRIPTION" })

-- --- SECONDARY MONITOR (external) ---
-- hl.workspace_rule({ workspace = "6", monitor = "desc:YOUR_SECONDARY_DESCRIPTION" })
-- hl.workspace_rule({ workspace = "7", monitor = "desc:YOUR_SECONDARY_DESCRIPTION" })
-- hl.workspace_rule({ workspace = "8", monitor = "desc:YOUR_SECONDARY_DESCRIPTION" })
-- hl.workspace_rule({ workspace = "9", monitor = "desc:YOUR_SECONDARY_DESCRIPTION" })
-- hl.workspace_rule({ workspace = "10", monitor = "desc:YOUR_SECONDARY_DESCRIPTION" })

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ SPECIAL WORKSPACES (Scratchpads)                                         │
-- │                                                                           │
-- │ Named scratchpads toggled with keybinds. They launch their app           │
-- │ automatically on first toggle via on_created_empty.                      │
-- └───────────────────────────────────────────────────────────────────────────┘

hl.workspace_rule({ workspace = "special:terminal", on_created_empty = "kitty --class scratchpad-terminal" })
hl.workspace_rule({ workspace = "special:files", on_created_empty = "nautilus" })
hl.workspace_rule({ workspace = "special:music", on_created_empty = "spotify" })
