-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║ CORE VARIABLES                                                             ║
-- ║                                                                           ║
-- ║ Reusable Lua values consumed by keybinds.lua, autostart.lua and others.   ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

local V = {
    mainMod   = "SUPER",
    terminal  = "kitty",
    fileMgr   = "nautilus",
    browser   = "firefox",
    menu      = "rofi -show drun -theme ~/.config/rofi/launcher.rasi",
    shellDir  = os.getenv("HOME") .. "/.config/hypr/scripts",
}

return V
