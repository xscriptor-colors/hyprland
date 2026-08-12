-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║                                                                           ║
-- ║    ██╗  ██╗██╗   ██╗██████╗ ██████╗ ██╗      █████╗ ███╗   ██╗██████╗     ║
-- ║    ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██║     ██╔══██╗████╗  ██║██╔══██╗    ║
-- ║    ███████║ ╚████╔╝ ██████╔╝██████╔╝██║     ███████║██╔██╗ ██║██║  ██║    ║
-- ║    ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██║     ██╔══██║██║╚██╗██║██║  ██║    ║
-- ║    ██║  ██║   ██║   ██║     ██║  ██║███████╗██║  ██║██║ ╚████║██████╔╝    ║
-- ║    ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝     ║
-- ║                                                                           ║
-- ║             X Configuration by xscriptor                                  ║
-- ║             Lua configuration (Hyprland 0.55+)                           ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ MODULAR CONFIGURATION                                                     │
-- │                                                                           │
-- │ Every require() points to a sibling .lua file in ~/.config/hypr/          │
-- │ (relative paths resolve from the directory of hyprland.lua).              │
-- └───────────────────────────────────────────────────────────────────────────┘

require("env")          -- Environment variables (hl.env)
require("colors")       -- Fixed X palette (color variables)
require("variables")    -- User variables (mods, terminal, programs)
require("settings")     -- general / decoration / input / misc / xwayland
require("monitors")     -- Monitor configuration
require("keybinds")     -- All keybindings (hl.bind)
require("animations")   -- Curves + animations (hl.curve / hl.animation)
require("windowrules")  -- Window rules (hl.window_rule)
require("workspaces")   -- Workspace rules & scratchpads (hl.workspace_rule)
require("autostart")    -- Startup applications (hl.on "hyprland.start")

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ RUNTIME OVERRIDES                                                         │
-- │                                                                           │
-- │ The Window Controls widget persists its effects to config/window-effects  │
-- │ and config/gaps. They are loaded last so they always win (if present).    │
-- └───────────────────────────────────────────────────────────────────────────┘

pcall(require, "config.window-effects")
pcall(require, "config.gaps")
