-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║ KEYBINDINGS                                                                ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

local V = require("variables")

local mainMod = V.mainMod
local mod     = mainMod .. " + "
local scripts = V.shellDir

-- Shorthand: exec a script inside the hypr scripts dir
local function run(script, args)
    local cmd = script .. (args and (" " .. args) or "")
    return hl.dsp.exec_cmd(cmd)
end

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ APPLICATIONS                                                              │
-- └───────────────────────────────────────────────────────────────────────────┘

hl.bind(mod .. "Return", hl.dsp.exec_cmd(V.terminal))
hl.bind(mod .. "T", hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. "SHIFT + Q", hl.dsp.exit())
hl.bind(mod .. "E", hl.dsp.exec_cmd(V.fileMgr))
hl.bind(mod .. "F", hl.dsp.exec_cmd(V.browser))
hl.bind(mod .. "period", hl.dsp.exec_cmd("rofi -show emoji -theme ~/.config/rofi/launcher.rasi"))

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ QUICKSHELL CONTROLS                                                       │
-- └───────────────────────────────────────────────────────────────────────────┘

hl.bind(mod .. "Q", hl.dsp.window.kill())
hl.bind(mod .. "M", run("bash " .. scripts .. "/qs_manager.sh", "toggle music"))
hl.bind(mod .. "C", run(scripts .. "/qs_manager.sh", "toggle clipboard"))
hl.bind(mod .. "D", run("bash " .. scripts .. "/qs_manager.sh", "toggle applauncher"))
hl.bind(mod .. "B", run("bash " .. scripts .. "/qs_manager.sh", "toggle battery"))
hl.bind(mod .. "W", run("bash " .. scripts .. "/qs_manager.sh", "toggle wallpaper"))
hl.bind(mod .. "S", run("bash " .. scripts .. "/qs_manager.sh", "toggle calendar"))
hl.bind(mod .. "N", run("bash " .. scripts .. "/qs_manager.sh", "toggle network"))
hl.bind(mod .. "V", run("bash " .. scripts .. "/qs_manager.sh", "toggle volume"))
hl.bind(mod .. "H", run("bash " .. scripts .. "/qs_manager.sh", "toggle guide"))
hl.bind(mod .. "SHIFT + S", run("bash " .. scripts .. "/qs_manager.sh", "toggle settings"))
hl.bind(mod .. "SHIFT + E", run("bash " .. scripts .. "/qs_manager.sh", "toggle settings topbar"))
hl.bind(mod .. "SHIFT + T", run("bash " .. scripts .. "/qs_manager.sh", "toggle focustime"))
hl.bind(mod .. "U", run("bash " .. scripts .. "/qs_manager.sh", "toggle updater"))
hl.bind(mod .. "X", run("bash " .. scripts .. "/qs_manager.sh", "toggle stewart"))
hl.bind(mod .. "Y", run("bash " .. scripts .. "/qs_manager.sh", "toggle quicknotes"))
hl.bind(mod .. "I", run("bash " .. scripts .. "/qs_manager.sh", "toggle system-monitor"))
hl.bind(mod .. "O", run("bash " .. scripts .. "/qs_manager.sh", "toggle rss-reader"))
hl.bind(mod .. "apostrophe", run("bash " .. scripts .. "/qs_manager.sh", "toggle file-search"))
hl.bind(mod .. "SHIFT + B", run("bash " .. scripts .. "/qs_manager.sh", "toggle window-controls"))
hl.bind(mod .. "SHIFT + D", run("bash " .. scripts .. "/qs_manager.sh", "toggle dock-editor"))
hl.bind(mod .. "R", run(scripts .. "/reload.sh"))

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ WINDOW MANAGEMENT                                                         │
-- └───────────────────────────────────────────────────────────────────────────┘

hl.bind("ALT + F4", hl.dsp.window.kill())
hl.bind(mod .. "J", hl.dsp.layout("togglesplit"))
hl.bind(mod .. "Space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. "SHIFT + Space", hl.dsp.window.pin({ action = "toggle" }))
hl.bind(mod .. "G", hl.dsp.window.center())

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ LOCK / LOGOUT / POWER                                                     │
-- └───────────────────────────────────────────────────────────────────────────┘

hl.bind(mod .. "L", run("bash " .. scripts .. "/lock.sh"), { locked = true, repeating = true })
hl.bind(mod .. "SHIFT + L", run("bash " .. scripts .. "/qs_manager.sh", "toggle battery"))
hl.bind(mod .. "Escape", run(scripts .. "/exit.sh"))
hl.bind(mod .. "CTRL + L", hl.dsp.exec_cmd("systemctl suspend"))
hl.bind(mod .. "CTRL + SHIFT + L", hl.dsp.exec_cmd("systemctl poweroff"))

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ SCREENSHOTS                                                               │
-- └───────────────────────────────────────────────────────────────────────────┘

hl.bind("Print", run(scripts .. "/screenshot.sh"), { locked = true })
hl.bind("SHIFT_L + Print", run(scripts .. "/screenshot.sh", "--edit"), { locked = true })
hl.bind(mod .. "Print", run(scripts .. "/screenshot.sh", "--full"), { locked = true })
hl.bind(mod .. "SHIFT + Print", run(scripts .. "/screenshot.sh", "--full --edit"), { locked = true })

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ MULTIMEDIA KEYS                                                           │
-- └───────────────────────────────────────────────────────────────────────────┘

hl.bind("XF86AudioRaiseVolume", run(scripts .. "/volume.sh", "up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", run(scripts .. "/volume.sh", "down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", run(scripts .. "/volume.sh", "mute"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle"), { locked = true })

hl.bind("XF86MonBrightnessUp", run(scripts .. "/brightness.sh", "up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", run(scripts .. "/brightness.sh", "down"), { locked = true, repeating = true })

-- Alternative brightness keys (for keyboards without brightness keys)
hl.bind(mod .. "F3", run(scripts .. "/brightness.sh", "up"), { locked = true, repeating = true })
hl.bind(mod .. "F2", run(scripts .. "/brightness.sh", "down"), { locked = true, repeating = true })

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"), { locked = true })

-- Alternative volume keys (for keyboards without multimedia keys)
hl.bind(mod .. "equal", run(scripts .. "/volume.sh", "up"))
hl.bind(mod .. "minus", run(scripts .. "/volume.sh", "down"))
hl.bind(mod .. "BackSpace", run(scripts .. "/volume.sh", "mute"))

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ FOCUS MOVEMENT (Arrow Keys + HJKL)                                        │
-- └───────────────────────────────────────────────────────────────────────────┘

hl.bind(mod .. "left",  hl.dsp.focus({ direction = "l" }))
hl.bind(mod .. "right", hl.dsp.focus({ direction = "r" }))
hl.bind(mod .. "up",    hl.dsp.focus({ direction = "u" }))
hl.bind(mod .. "down",  hl.dsp.focus({ direction = "d" }))

hl.bind(mod .. "H", hl.dsp.focus({ direction = "l" }))
hl.bind(mod .. "L", hl.dsp.focus({ direction = "r" }))
hl.bind(mod .. "K", hl.dsp.focus({ direction = "u" }))
hl.bind(mod .. "J", hl.dsp.focus({ direction = "d" }))

-- Cycle through windows (cycle focus + raise active window)
hl.bind("ALT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end)
hl.bind("ALT + SHIFT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
    hl.dispatch(hl.dsp.window.bring_to_top())
end)

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ WINDOW MOVEMENT                                                           │
-- └───────────────────────────────────────────────────────────────────────────┘

hl.bind(mod .. "SHIFT + left",  hl.dsp.window.move({ direction = "l" }))
hl.bind(mod .. "SHIFT + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mod .. "SHIFT + up",    hl.dsp.window.move({ direction = "u" }))
hl.bind(mod .. "SHIFT + down",  hl.dsp.window.move({ direction = "d" }))

hl.bind(mod .. "SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mod .. "SHIFT + L", hl.dsp.window.move({ direction = "r" }))
hl.bind(mod .. "SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mod .. "SHIFT + J", hl.dsp.window.move({ direction = "d" }))

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ WINDOW RESIZE                                                             │
-- └───────────────────────────────────────────────────────────────────────────┘

hl.bind(mod .. "CTRL + left",  hl.dsp.window.resize({ x = -40, y = 0, relative = true }))
hl.bind(mod .. "CTRL + right", hl.dsp.window.resize({ x = 40, y = 0, relative = true }))
hl.bind(mod .. "CTRL + up",    hl.dsp.window.resize({ x = 0, y = -40, relative = true }))
hl.bind(mod .. "CTRL + down",  hl.dsp.window.resize({ x = 0, y = 40, relative = true }))

hl.bind(mod .. "CTRL + H", hl.dsp.window.resize({ x = -40, y = 0, relative = true }))
hl.bind(mod .. "CTRL + L", hl.dsp.window.resize({ x = 40, y = 0, relative = true }))
hl.bind(mod .. "CTRL + K", hl.dsp.window.resize({ x = 0, y = -40, relative = true }))
hl.bind(mod .. "CTRL + J", hl.dsp.window.resize({ x = 0, y = 40, relative = true }))

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ WORKSPACES                                                                │
-- └───────────────────────────────────────────────────────────────────────────┘

-- Switch workspaces with mainMod + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mod .. key, run(scripts .. "/qs_manager.sh", tostring(i)))
    -- Move active window to a workspace with mainMod + SHIFT + [0-9]
    hl.bind(mod .. "SHIFT + " .. key, run(scripts .. "/qs_manager.sh", tostring(i) .. " move"))
end

-- Navigate workspaces with Page Up/Down
hl.bind(mod .. "Page_Up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. "Page_Down", hl.dsp.focus({ workspace = "e+1" }))

-- Previous workspace (XMonad-style, stays on current monitor)
hl.bind(mod .. "Tab", hl.dsp.focus({ workspace = "previous", on_current_monitor = true }))

-- Special workspaces (scratchpads)
hl.bind(mod .. "A", hl.dsp.workspace.toggle_special("files"))
hl.bind(mod .. "SHIFT + A", hl.dsp.window.move({ workspace = "special:files" }))

-- Scroll through workspaces
hl.bind(mod .. "mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. "mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ MULTI-MONITOR                                                             │
-- └───────────────────────────────────────────────────────────────────────────┘

-- Move focus between monitors
hl.bind(mod .. "ALT + I", hl.dsp.focus({ monitor = "+1" }))
hl.bind(mod .. "ALT + U", hl.dsp.focus({ monitor = "-1" }))

-- Move active window to adjacent monitor
hl.bind(mod .. "ALT + SHIFT + I", hl.dsp.window.move({ monitor = "+1" }))
hl.bind(mod .. "ALT + SHIFT + U", hl.dsp.window.move({ monitor = "-1" }))

-- Swap workspaces between monitors
hl.bind(mod .. "ALT + O", hl.dsp.workspace.swap_monitors({ monitor1 = 0, monitor2 = 1 }))

-- Move current workspace to the next monitor
hl.bind(mod .. "ALT + P", hl.dsp.workspace.move({ monitor = "+1" }))

-- Monitor manager (position, resolution, refresh rate)
hl.bind(mod .. "ALT + M", run(scripts .. "/monitor-manager.sh"))
hl.bind(mod .. "ALT + SHIFT + M", run(scripts .. "/monitor-manager.sh", "info"))

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ MOUSE BINDINGS                                                            │
-- └───────────────────────────────────────────────────────────────────────────┘

hl.bind(mod .. "mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. "mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ THEME & WALLPAPER                                                         │
-- └───────────────────────────────────────────────────────────────────────────┘

hl.bind(mod .. "Z", run("bash " .. scripts .. "/qs_manager.sh", "toggle scale"))
hl.bind(mod .. "SHIFT + Z", run(scripts .. "/scale-menu.sh", "up"))
hl.bind(mod .. "CTRL + Z", run(scripts .. "/scale-menu.sh", "down"))

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ COLOR PICKER                                                              │
-- └───────────────────────────────────────────────────────────────────────────┘

hl.bind(mod .. "SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ GPU PERFORMANCE MODE (NVIDIA)                                             │
-- └───────────────────────────────────────────────────────────────────────────┘

-- Cycle GPU performance modes: silent → normal → turbo
hl.bind(mod .. "ALT + G", run(scripts .. "/gpu-mode.sh", "cycle"))

-- Open Rofi GPU mode selector
hl.bind(mod .. "ALT + SHIFT + G", run(scripts .. "/gpu-mode.sh", "menu"))

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ HYPRLAND RELOAD                                                           │
-- └───────────────────────────────────────────────────────────────────────────┘

hl.bind(mod .. "SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))
