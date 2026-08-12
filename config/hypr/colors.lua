-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║ THEME: X (FIXED PALETTE)                                                   ║
-- ║ Color scheme from references.md                                            ║
-- ║                                                                           ║
-- ║ This module exports the X palette as a Lua table so other config files    ║
-- ║ can consume it. Colors are stored as stripped hex; use X.hex(name) or     ║
-- ║ X.rgba(name, alpha) to build Hyprland color strings.                      ║
-- ║                                                                           ║
-- ║ Window borders are dynamic: they come from Matugen (matugen-colors.lua)   ║
-- ║ when present, falling back to the fixed X palette otherwise.              ║
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
-- Dynamic: from Matugen when matugen-colors.lua exists, else the X palette.
local ok, matugenColors = pcall(require, "matugen-colors")
if ok and type(matugenColors) == "table" then
    X.active_border   = matugenColors.active_border
    X.inactive_border = matugenColors.inactive_border
else
    X.active_border   = "rgba(" .. X.color1 .. "ee)" -- accent (red)
    X.inactive_border = "rgba(" .. X.color8 .. "aa)" -- bright black
end

return X
