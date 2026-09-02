-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║ AUTOSTART APPLICATIONS                                                    ║
-- ║                                                                           ║
-- ║ hl.exec_cmd() launched inside hl.on("hyprland.start") runs exactly once  ║
-- ║ at session start. Top-level hl.exec_cmd() would re-run on every reload,  ║
-- ║ so everything autostart-ish lives in this handler.                        ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

hl.on("hyprland.start", function()

    -- ┌───────────────────────────────────────────────────────────────────────┐
    -- │ SYSTEM SERVICES                                                       │
    -- └───────────────────────────────────────────────────────────────────────┘

    -- Keyring daemon for WiFi passwords (supports both GNOME and KDE users)
    -- KDE users: kwallet is used if available, GNOME/other users: gnome-keyring
    hl.exec_cmd("/usr/lib/pam_kwallet_init || gnome-keyring-daemon --start --components=secrets,pkcs11")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets 2>/dev/null")

    -- Authentication agent (with fallback paths for KDE and GNOME)
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1 || /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 || /usr/libexec/polkit-kde-authentication-agent-1")

    -- XDG Desktop Portal
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- ┌───────────────────────────────────────────────────────────────────────┐
    -- │ UI COMPONENTS                                                         │
    -- └───────────────────────────────────────────────────────────────────────┘

    -- Kill any leftover shells from previous sessions
    hl.exec_cmd("pkill -f \"quickshell.*Main.qml\" 2>/dev/null || true")
    hl.exec_cmd("pkill -f \"quickshell.*TopBar.qml\" 2>/dev/null || true")
    hl.exec_cmd("pkill -f \"quickshell.*Floating.qml\" 2>/dev/null || true")

    -- Monitor layout restore: applies display-config at start and re-applies
    -- it on hotplug, so dock monitors that enumerate late don't pile up at
    -- "auto" positions after a reboot or re-dock.
    hl.exec_cmd("pkill -f \"restore-monitors.sh\" 2>/dev/null || true")
    hl.exec_cmd("~/.config/hypr/scripts/restore-monitors.sh")

    -- Wallpaper daemon
    hl.exec_cmd("awww-daemon")

    -- Quickshell QML-based shell — SINGLE ENTRY POINT via Shell.qml
    -- Shell.qml loads Main.qml + TopBar.qml + Floating.qml internally
    hl.exec_cmd("bash -c 'BIN=\"\"; command -v quickshell >/dev/null 2>&1 && BIN=quickshell || command -v qs >/dev/null 2>&1 && BIN=qs; [ -n \"$BIN\" ] && exec $BIN -p ~/.config/hypr/scripts/quickshell/Shell.qml || true'")

    -- Focus daemon
    hl.exec_cmd("python3 ~/.config/hypr/scripts/quickshell/focustime/focus_daemon.py &")

    -- System init (wallpaper on first boot)
    hl.exec_cmd("~/.config/hypr/scripts/init.sh")

    -- Show the getting-started guide on first session
    hl.exec_cmd("bash -c 'sleep 1 && ~/.config/hypr/scripts/qs_manager.sh toggle guide'")

    -- MPRIS player daemon
    hl.exec_cmd("playerctld")

    -- On-screen display
    hl.exec_cmd("swayosd-server --top-margin 0.9 --style \"$HOME/.config/swayosd/style.css\"")

    -- ┌───────────────────────────────────────────────────────────────────────┐
    -- │ UTILITIES                                                             │
    -- └───────────────────────────────────────────────────────────────────────┘

    -- Clipboard manager
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Network manager applet
    hl.exec_cmd("nm-applet --indicator")

    -- Bluetooth
    hl.exec_cmd("blueman-applet")

    -- Idle management
    hl.exec_cmd("hypridle")

    -- Volume listener
    hl.exec_cmd("~/.config/hypr/scripts/volume_listener.sh")

    -- Update notifier
    hl.exec_cmd("~/.config/hypr/scripts/update_notifier.sh")

    -- ┌───────────────────────────────────────────────────────────────────────┐
    -- │ CURSOR                                                                │
    -- └───────────────────────────────────────────────────────────────────────┘

    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 24")

    -- ┌───────────────────────────────────────────────────────────────────────┐
    -- │ GTK THEME                                                             │
    -- └───────────────────────────────────────────────────────────────────────┘

    hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'")
end)
