-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║ WINDOW RULES                                                              ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ FLOATING WINDOWS                                                          │
-- └───────────────────────────────────────────────────────────────────────────┘

-- System windows
hl.window_rule({ match = { class = "^(pavucontrol)$" }, float = true })
hl.window_rule({ match = { class = "^(nm-connection-editor)$" }, float = true })
hl.window_rule({ match = { class = "^(blueman-manager)$" }, float = true })
hl.window_rule({ match = { class = "^(gnome-calculator)$" }, float = true })
hl.window_rule({ match = { class = "^(org.gnome.Calculator)$" }, float = true })
hl.window_rule({ match = { class = "^(file-roller)$" }, float = true })
hl.window_rule({ match = { class = "^(nwg-look)$" }, float = true })
hl.window_rule({ match = { class = "^(qt5ct)$" }, float = true })
hl.window_rule({ match = { class = "^(qt6ct)$" }, float = true })

-- File managers dialogs
hl.window_rule({ match = { title = "^(Open File)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(Open Folder)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(Save As)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(Confirm to replace files)$" }, float = true })
hl.window_rule({ match = { title = "^(File Operation Progress)$" }, float = true })

-- Picture in Picture
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, float = true })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, pin = true })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, size = { 640, 360 } })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, move = { "100% - 660", "100% - 380" } })

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ CENTERED FLOATING                                                         │
-- └───────────────────────────────────────────────────────────────────────────┘

hl.window_rule({ match = { class = "^(pavucontrol)$" }, center = true })
hl.window_rule({ match = { class = "^(blueman-manager)$" }, center = true })

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ SIZE CONSTRAINTS                                                          │
-- └───────────────────────────────────────────────────────────────────────────┘

hl.window_rule({ match = { class = "^(pavucontrol)$" }, size = { 800, 600 } })
hl.window_rule({ match = { class = "^(blueman-manager)$" }, size = { 800, 600 } })

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ OPACITY                                                                   │
-- └───────────────────────────────────────────────────────────────────────────┘

hl.window_rule({ match = { class = "^(kitty)$" }, opacity = "0.95 0.95" })
hl.window_rule({ match = { class = "^(Code)$" }, opacity = "0.95 0.95" })
hl.window_rule({ match = { class = "^(code-oss)$" }, opacity = "0.95 0.95" })
hl.window_rule({ match = { class = "^(firefox)$" }, opacity = "0.98 0.98" })
hl.window_rule({ match = { class = "^(chromium)$" }, opacity = "0.98 0.98" })
hl.window_rule({ match = { class = "^(google-chrome)$" }, opacity = "0.98 0.98" })

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ WORKSPACE ASSIGNMENTS                                                     │
-- └───────────────────────────────────────────────────────────────────────────┘

-- Browser on workspace 2
hl.window_rule({ match = { class = "^(firefox)$" }, workspace = "2" })
hl.window_rule({ match = { class = "^(chromium)$" }, workspace = "2" })
hl.window_rule({ match = { class = "^(google-chrome)$" }, workspace = "2" })

-- Code editors on workspace 3
hl.window_rule({ match = { class = "^(Code)$" }, workspace = "3" })
hl.window_rule({ match = { class = "^(code-oss)$" }, workspace = "3" })

-- Communication on workspace 4
hl.window_rule({ match = { class = "^(discord)$" }, workspace = "4" })
hl.window_rule({ match = { class = "^(Slack)$" }, workspace = "4" })
hl.window_rule({ match = { class = "^(telegram-desktop)$" }, workspace = "4" })

-- Media on workspace 5
hl.window_rule({ match = { class = "^(Spotify)$" }, workspace = "5" })
hl.window_rule({ match = { class = "^(spotify)$" }, workspace = "5" })

-- Games on workspace 6
hl.window_rule({ match = { class = "^(steam)$" }, workspace = "6" })
hl.window_rule({ match = { class = "^(lutris)$" }, workspace = "6" })
hl.window_rule({ match = { class = "^(heroic)$" }, workspace = "6" })

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ GAMES - FULLSCREEN & TEARING                                              │
-- └───────────────────────────────────────────────────────────────────────────┘

hl.window_rule({ match = { class = "^(steam_app_.*)$" }, fullscreen = true })
hl.window_rule({ match = { class = "^(steam_app_.*)$" }, immediate = true })
hl.window_rule({ match = { class = "^(.*%.exe)$" }, immediate = true })
