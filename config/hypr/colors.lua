-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║ THEME: X (FIXED PALETTE)                                                   ║
-- ║ Color scheme from dock/palettes (12 fixed palettes)                                            ║
-- ║                                                                           ║
-- ║ This module exports the X palette as a Lua table so other config files    ║
-- ║ can consume it. Colors are stored as stripped hex; use X.hex(name) or     ║
-- ║ X.rgba(name, alpha) to build Hyprland color strings.                      ║
-- ║                                                                           ║
-- ║ Window borders are palette-driven: the active palette slug and any manual ║
-- ║ border overrides are read from settings.json "dock"; the accent (color1)  ║
-- ║ and muted (color8) colors come from dock/palettes/<slug>.json.            ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

local X = {
    -- Base 16 palette (0-7 normal, 8-15 bright)
    color0  = "363537", -- black / background
    color1  = "fc618d", -- red
    color2  = "7bd88f", -- green
    color3  = "fce566", -- yellow
    color4  = "fd9353", -- orange
    color5  = "948ae3", -- purple
    color6  = "5ad4e6", -- cyan
    color7  = "f7f1ff", -- white / foreground
    color8  = "69676c", -- bright black
    color9  = "fc618d", -- bright red
    color10 = "7bd88f", -- bright green
    color11 = "fce566", -- bright yellow
    color12 = "fd9353", -- bright orange
    color13 = "948ae3", -- bright purple
    color14 = "5ad4e6", -- bright cyan
    color15 = "f7f1ff", -- bright white
}

-- Semantic aliases (mirrors the old theme.conf)
X.background = X.color0
X.foreground = X.color7
X.accent     = X.color1
X.accent2    = X.color5

-- Build "rgba(<hex><aa>)" with an alpha byte (0-255, or a 2-digit hex string)
function X.rgba(name, alpha)
    alpha = alpha or "ee"
    return "rgba(" .. X[name] .. alpha .. ")"
end

-- Build a plain "rgb(<hex>)" string
function X.hex(name)
    return "rgb(" .. X[name] .. ")"
end

-- Ready-to-use border colors
-- Palette-driven: reads settings.json "dock" (palette slug + optional manual
-- border overrides) and the matching dock/palettes/<slug>.json for the accent
-- (color1) and muted (color8) colors. Matugen is NOT involved.
local function jsonString(path, key)
    local f = io.open(path, "r")
    if not f then return nil end
    local c = f:read("*a")
    f:close()
    return c:match('"' .. key .. '"%s*:%s*"([^"]+)"')
end

local function jsonBool(path, key)
    local f = io.open(path, "r")
    if not f then return nil end
    local c = f:read("*a")
    f:close()
    return c:match('"' .. key .. '"%s*:%s*(%w+)')
end

local home = os.getenv("HOME") or ""
local settingsPath = home .. "/.config/hypr/settings.json"

local borderActiveHex   = jsonString(settingsPath, "borderActive")
local borderInactiveHex = jsonString(settingsPath, "borderInactive")
local followPalette     = jsonBool(settingsPath, "borderFollowPalette")

if followPalette == "false" and borderActiveHex and borderActiveHex ~= "" and borderActiveHex:sub(1,1) == "#" then
    X.active_border = "rgba(" .. borderActiveHex:sub(2) .. "ee)"
else
    local slug = jsonString(settingsPath, "palette") or "x"
    local palPath = home .. "/.config/hypr/scripts/quickshell/dock/palettes/" .. slug .. ".json"
    local c1 = jsonString(palPath, "color1")
    X.active_border = c1 and c1:sub(1,1) == "#" and ("rgba(" .. c1:sub(2) .. "ee)") or ("rgba(" .. X.color1 .. "ee)")
end

if followPalette == "false" and borderInactiveHex and borderInactiveHex ~= "" and borderInactiveHex:sub(1,1) == "#" then
    X.inactive_border = "rgba(" .. borderInactiveHex:sub(2) .. "aa)"
else
    local slug = jsonString(settingsPath, "palette") or "x"
    local palPath = home .. "/.config/hypr/scripts/quickshell/dock/palettes/" .. slug .. ".json"
    local c8 = jsonString(palPath, "color8")
    X.inactive_border = c8 and c8:sub(1,1) == "#" and ("rgba(" .. c8:sub(2) .. "aa)") or ("rgba(" .. X.color8 .. "aa)")
end

return X
