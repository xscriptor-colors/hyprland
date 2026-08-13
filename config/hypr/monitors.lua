-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║ MONITORS                                                                   ║
-- ║                                                                           ║
-- ║ Auto-detects every connected monitor at its highest available refresh     ║
-- ║ rate ("highrr" replaces the old detect-monitors.sh generator).            ║
-- ║                                                                           ║
-- ║ For a static multi-monitor layout, uncomment and edit the entries below.  ║
-- ║ Identify your monitors with: hyprctl monitors all                         ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- Wildcard: all monitors, preferred resolution, highest refresh rate, auto position/scale
hl.monitor({ output = "", mode = "highrr", position = "auto", scale = "auto" })

-- ────────────────────────────────────────────────────────────────────────────
-- Example static layout (uncomment to use instead of the wildcard):
--
-- hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "0x0",  scale = 1 })
-- hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "1920x0", scale = 1 })
-- ────────────────────────────────────────────────────────────────────────────
