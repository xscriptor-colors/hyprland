-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║ SETTINGS                                                                   ║
-- ║                                                                           ║
-- ║ Core categories: general, decoration, input, cursor, misc, xwayland,      ║
-- ║ dwindle, master and ecosystem.                                            ║
-- ║                                                                           ║
-- ║ NOTE: the Window Controls widget persists its own overrides to            ║
-- ║ config/window-effects.lua and config/gaps.lua (loaded last in            ║
-- ║ hyprland.lua) so they take precedence over the values below.             ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

local X = require("colors")

hl.config({
    general = {
        gaps_in = 16,
        gaps_out = 25,
        border_size = 2,
        float_gaps = 6,
        layout = "dwindle",
        resize_on_border = true,
        extend_border_grab_area = 30,
        allow_tearing = false,

        col = {
            active_border   = X.active_border,
            inactive_border = X.inactive_border,
        },
    },
})

hl.config({
    decoration = {
        rounding = 20,

        active_opacity   = 0.85,
        inactive_opacity = 0.80,
        fullscreen_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 35,
            render_power = 5,
            color        = "rgba(000000CC)",
            color_inactive = "rgba(00000088)",
            offset       = { 0, 10 },
        },

        blur = {
            enabled           = true,
            size              = 8,
            passes            = 3,
            new_optimizations = true,
            xray              = false,
            ignore_opacity    = true,
            noise             = 0.02,
            contrast          = 1.0,
            brightness        = 1.0,
            vibrancy          = 0.2,
            vibrancy_darkness = 0.5,
            special           = false,
            popups            = true,
        },
    },
})

hl.config({
    input = {
        kb_layout  = "es",
        kb_variant = "",
        kb_model   = "",
        kb_options = "grp:alt_shift_toggle",
        kb_rules   = "",

        follow_mouse  = 1,
        mouse_refocus = false,

        sensitivity   = 0,
        accel_profile = "flat",

        touchpad = {
            natural_scroll      = true,
            disable_while_typing = true,
            tap_to_click        = true,
            drag_lock           = false,
            scroll_factor       = 1.0,
        },
    },
})

hl.config({
    cursor = {
        no_hardware_cursors = true,
        no_warps            = true,
    },
})

hl.config({
    dwindle = {
        preserve_split = true,
        smart_split    = false,
        smart_resizing = true,
    },
})

hl.config({
    master = {
        orientation = "left",
    },
})

hl.config({
    misc = {
        font_family           = "Hack Nerd Font",
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,
        vrr                       = 0,
        mouse_move_enables_dpms   = true,
        key_press_enables_dpms    = true,
        always_follow_on_dnd      = true,
        layers_hog_keyboard_focus = true,
        animate_manual_resizes    = true,
        animate_mouse_windowdragging = true,
        enable_swallow            = true,
        swallow_regex             = "^(kitty)$",
        focus_on_activate         = false,
    },
})

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})

hl.config({
    ecosystem = {
        no_update_news   = true,
        no_donation_nag  = true,
    },
})

-- 3-finger horizontal swipe for workspace switching (gestures)
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})
