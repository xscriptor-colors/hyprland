-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║ ANIMATIONS - Smooth and Modern                                            ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

hl.config({
    animations = {
        enabled = true,
    },
})

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ BEZIER CURVES                                                             │
-- └───────────────────────────────────────────────────────────────────────────┘

-- Smooth and snappy but with subtle bounce
hl.curve("smooth",         { type = "bezier", points = { {0.25, 0.1}, {0.25, 1} } })
hl.curve("overshot",       { type = "bezier", points = { {0.13, 0.99}, {0.29, 1.15} } })
hl.curve("easeInOutQuart", { type = "bezier", points = { {0.76, 0}, {0.24, 1} } })
hl.curve("easeOutExpo",    { type = "bezier", points = { {0.16, 1}, {0.3, 1} } })
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.22, 1}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0}, {1, 1} } })

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ WINDOW ANIMATIONS                                                         │
-- └───────────────────────────────────────────────────────────────────────────┘

-- Window open/close
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 6, bezier = "overshot", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "easeOutExpo", style = "popin 80%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "overshot" })

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ FADE ANIMATIONS                                                           │
-- └───────────────────────────────────────────────────────────────────────────┘

hl.animation({ leaf = "fadeIn",     enabled = true, speed = 4, bezier = "easeOutExpo" })
hl.animation({ leaf = "fadeOut",    enabled = true, speed = 4, bezier = "easeOutExpo" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 4, bezier = "easeOutExpo" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 4, bezier = "easeOutExpo" })
hl.animation({ leaf = "fadeDim",    enabled = true, speed = 4, bezier = "easeOutExpo" })

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ BORDER ANIMATIONS                                                         │
-- └───────────────────────────────────────────────────────────────────────────┘

hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "smooth" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 100, bezier = "linear", style = "loop" })

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ WORKSPACE ANIMATIONS                                                      │
-- └───────────────────────────────────────────────────────────────────────────┘

hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "overshot", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 6, bezier = "overshot", style = "slidevert" })
