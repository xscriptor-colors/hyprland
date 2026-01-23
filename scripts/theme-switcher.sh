#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ Theme Switcher - Hyprland, Waybar, and Kitty                              ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

CONFIG_DIR="$HOME/.config/hypr"
THEMES_DIR="$CONFIG_DIR/themes"
CURRENT_THEME="$CONFIG_DIR/theme.conf"
WAYBAR_THEMES="$HOME/.config/waybar/themes"
WAYBAR_CURRENT="$HOME/.config/waybar/current-theme.css"
KITTY_THEMES="$HOME/.config/kitty/themes"
KITTY_CONF="$HOME/.config/kitty/kitty.conf"
KITTY_CURRENT="$HOME/.config/kitty/current-theme.conf"
ROFI_DIR="$HOME/.config/rofi"
ROFI_COLORS="$ROFI_DIR/colors.rasi"

# Fallback paths
SCRIPT_DIR="$(dirname "$(dirname "$(realpath "$0")")")"
if [ ! -d "$THEMES_DIR" ]; then
    THEMES_DIR="$SCRIPT_DIR/themes"
fi
if [ ! -d "$WAYBAR_THEMES" ]; then
    WAYBAR_THEMES="$SCRIPT_DIR/config/waybar/themes"
fi
if [ ! -d "$KITTY_THEMES" ]; then
    KITTY_THEMES="$SCRIPT_DIR/config/kitty/themes"
fi

# Get list of themes
get_themes() {
    ls -1 "$THEMES_DIR"/*.conf 2>/dev/null | xargs -n1 basename | sed 's/.conf$//'
}

# Main function
main() {
    themes=$(get_themes)
    
    if [ -z "$themes" ]; then
        notify-send "Theme Switcher" "No themes found!" -u critical
        exit 1
    fi
    
    # Use wofi to select theme
    selected=$(echo "$themes" | wofi --dmenu --prompt "Select Theme" --cache-file /dev/null)
    
    if [ -z "$selected" ]; then
        exit 0
    fi
    
    theme_file="$THEMES_DIR/${selected}.conf"
    waybar_css="$WAYBAR_THEMES/${selected}.css"
    kitty_theme="$KITTY_THEMES/${selected}.conf"
    
    if [ ! -f "$theme_file" ]; then
        notify-send "Theme Switcher" "Theme not found: $selected" -u critical
        exit 1
    fi

    # Determine which theme to use for Rofi colors (User Request: Praha for most, specific exceptions)
    case "$selected" in
        helsinki|london|miami|oslo|seul)
            rofi_source="$theme_file"
            ;;
        *)
            rofi_source="$THEMES_DIR/praha.conf"
            ;;
    esac

    # Temporarily set theme_file to the source for get_hex
    real_theme_file="$theme_file"
    theme_file="$rofi_source"
    
    # Ensure source file exists
    if [ ! -f "$theme_file" ]; then
        theme_file="$real_theme_file" 
    fi

    mkdir -p "$ROFI_DIR"

    get_hex() {
        local key="$1"
        awk -v key="$key" '
            $1 == key {
                if (match($0, /rgb\(([0-9a-fA-F]{6})\)/, m)) {
                    print m[1]
                    exit
                }
            }
        ' "$theme_file"
    }

    bg_hex=$(get_hex '$color0')
    bg_alt_hex=$(get_hex '$color8')
    fg_hex=$(get_hex '$color7')
    accent_hex=$(get_hex '$accent')
    # If accent is empty (variable reference), fallback to color4 or color6
    [ -z "$accent_hex" ] && accent_hex=$(get_hex '$color4')
    
    accent2_hex=$(get_hex '$accent2')
    [ -z "$accent2_hex" ] && accent2_hex=$(get_hex '$color6')
    
    active_hex=$(get_hex '$color2')
    urgent_hex=$(get_hex '$color1')

    # Fallbacks
    bg_hex=${bg_hex:-1E1E2E}
    bg_alt_hex=${bg_alt_hex:-252535}
    fg_hex=${fg_hex:-FFFFFF}
    accent_hex=${accent_hex:-89B4FA}
    accent2_hex=${accent2_hex:-A6E3A1}
    active_hex=${active_hex:-A6E3A1}
    urgent_hex=${urgent_hex:-F38BA8}

    cat > "$ROFI_COLORS" <<EOF
* {
    background:     #${bg_hex}E6;
    background-alt: #${bg_alt_hex}FF;
    foreground:     #${fg_hex}FF;
    selected:       #${accent_hex}FF;
    active:         #${active_hex}FF;
    urgent:         #${urgent_hex}FF;
    
    border-col:     #${accent_hex}FF;
    border-col-2:   #${accent2_hex}FF;
}
EOF
    
    # Restore the actual selected theme for system application
    theme_file="$real_theme_file"

    # ┌─────────────────────────────────────────────────────────────────────────┐
    # │ Apply Hyprland theme                                                    │
    # └─────────────────────────────────────────────────────────────────────────┘
    cp "$theme_file" "$CURRENT_THEME"
    
    # ┌─────────────────────────────────────────────────────────────────────────┐
    # │ Apply Waybar theme                                                      │
    # └─────────────────────────────────────────────────────────────────────────┘
    if [ -f "$waybar_css" ]; then
        cp "$waybar_css" "$WAYBAR_CURRENT"
    else
        if [ -f "$WAYBAR_THEMES/x.css" ]; then
            cp "$WAYBAR_THEMES/x.css" "$WAYBAR_CURRENT"
        fi
    fi
    
    # ┌─────────────────────────────────────────────────────────────────────────┐
    # │ Apply Kitty theme                                                       │
    # └─────────────────────────────────────────────────────────────────────────┘
    if [ -f "$kitty_theme" ]; then
        cp "$kitty_theme" "$KITTY_CURRENT"
        
        # Reload Kitty if running - send SIGUSR1 to reload config
        pkill -USR1 kitty 2>/dev/null
    else
        if [ -f "$KITTY_THEMES/x.conf" ]; then
            cp "$KITTY_THEMES/x.conf" "$KITTY_CURRENT"
            pkill -USR1 kitty 2>/dev/null
        fi
    fi
    
    # ┌─────────────────────────────────────────────────────────────────────────┐
    # │ Reload components                                                       │
    # └─────────────────────────────────────────────────────────────────────────┘
    
    # Reload Hyprland
    hyprctl reload
    
    # Restart Waybar
    killall waybar 2>/dev/null
    sleep 0.3
    waybar &
    disown
    
    notify-send "Theme Switcher" "Applied: $selected" -i preferences-desktop-theme
}

main "$@"
