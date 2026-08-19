-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║ MONITORS                                                                   ║
-- ║                                                                           ║
-- ║ Auto-detects every connected monitor at its highest available refresh     ║
-- ║ rate ("highrr" replaces the old detect-monitors.sh generator).            ║
-- ║                                                                           ║
-- ║ The scale/position chosen from the scale menu (SUPER + Z) or the monitor  ║
-- ║ manager (SUPER + ALT + M) is persisted by those scripts to               ║
-- ║ ~/.config/hypr/display-config and restored here on every session, so a   ║
-- ║ saved scale survives logins and monitor reconnects instead of snapping    ║
-- ║ back to the "auto" DPI guess.                                             ║
-- ║                                                                           ║
-- ║ For a static multi-monitor layout, uncomment and edit the entries below.  ║
-- ║ Identify your monitors with: hyprctl monitors all                         ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

local HOME = os.getenv("HOME") or ""
local STATE = HOME .. "/.config/hypr/display-config"

-- Wildcard: monitors without a saved layout get the preferred resolution, the
-- highest refresh rate and auto position/scale. Explicit entries below win.
hl.monitor({ output = "", mode = "highrr", position = "auto", scale = "auto" })

-- Restore the persisted layout (one line per monitor: name|x|y|scale).
local file = io.open(STATE, "r")
if file then
    for line in file:lines() do
        local clean = line:gsub("%s+", "")
        if clean ~= "" and not clean:match("^#") then
            local name, x, y, scale = clean:match("^([^|]+)|([^|]+)|([^|]+)|([^|]+)$")
            if name and name ~= "" and x and scale then
                hl.monitor({
                    output = name,
                    mode = "highrr",
                    position = x .. "x" .. y,
                    scale = tonumber(scale) or "auto",
                })
            end
        end
    end
    file:close()
end

-- ────────────────────────────────────────────────────────────────────────────
-- Example static layout (uncomment to use instead of the wildcard):
--
-- hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "0x0",  scale = 1 })
-- hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "1920x0", scale = 1 })
-- ────────────────────────────────────────────────────────────────────────────
