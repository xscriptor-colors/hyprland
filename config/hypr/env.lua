-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║ ENVIRONMENT VARIABLES                                                      ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ NVIDIA SPECIFIC                                                           │
-- └───────────────────────────────────────────────────────────────────────────┘

-- Force GBM backend for NVIDIA (required for Wayland)
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

-- VA-API for hardware video acceleration
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ WAYLAND / QT / GTK                                                        │
-- └───────────────────────────────────────────────────────────────────────────┘

hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")

-- Qt settings
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")

-- GTK settings
hl.env("GDK_BACKEND", "wayland,x11,*")

-- SDL / Clutter
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ ELECTRON / CHROMIUM APPS                                                  │
-- └───────────────────────────────────────────────────────────────────────────┘

hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("XOS_WL", "1")

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ CURSOR THEME                                                              │
-- └───────────────────────────────────────────────────────────────────────────┘

hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ HYPRLAND SPECIFIC                                                         │
-- └───────────────────────────────────────────────────────────────────────────┘

hl.env("HYPRLAND_LOG_WLR", "1")
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")

-- Mozilla (Firefox / Thunderbird)
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("MOZ_DBUS_REMOTE", "1")

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ PATHS                                                                     │
-- │                                                                           │
-- │ WALLPAPER_DIR must match where install.sh places wallpapers.              │
-- └───────────────────────────────────────────────────────────────────────────┘

hl.env("WALLPAPER_DIR", os.getenv("HOME") .. "/.config/hypr/wallpapers")
hl.env("SCRIPT_DIR", os.getenv("HOME") .. "/.config/hypr/scripts")

-- XDG user directories (falls back to sensible defaults)
hl.env("XDG_PICTURES_DIR", os.getenv("XDG_PICTURES_DIR") or os.getenv("HOME") .. "/Pictures")
hl.env("XDG_VIDEOS_DIR", os.getenv("XDG_VIDEOS_DIR") or os.getenv("HOME") .. "/Videos")

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ APPLICATION SCALING                                                       │
-- │                                                                           │
-- │ NOTE: QuickShell is a Qt app, so QT_SCALE_FACTOR is deliberately avoided   │
-- │ (it would rescale the shell instead of the apps). GTK gets an integer     │
-- │ scale plus a DPI correction, Electron/Chromium take a fractional factor.  │
-- └───────────────────────────────────────────────────────────────────────────┘

local appScale = 1.0
if appScale ~= 1.0 then
    local gdkInt = math.max(1, math.floor(appScale + 0.0001))
    local gdkDpi = appScale / gdkInt
    hl.env("GDK_SCALE", tostring(gdkInt))
    hl.env("GDK_DPI_SCALE", string.format("%.4f", gdkDpi))
    hl.env("ELECTRON_FORCE_DEVICE_SCALE_FACTOR", tostring(appScale))
    hl.env("XCURSOR_SIZE", tostring(math.floor(24 * appScale)))
end
