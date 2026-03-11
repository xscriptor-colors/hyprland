#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ UNINSTALL SCRIPT                                                          ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

CONFIG_DIR="$HOME/.config"

echo "This will remove the Hyprland configuration files."
echo "It will NOT uninstall packages or remove NVIDIA configuration."
echo ""
echo "The following will be removed:"
echo "  - ~/.config/hypr"
echo "  - ~/.config/waybar"
echo "  - ~/.config/rofi"
echo "  - ~/.config/wlogout"
echo "  - ~/.config/dunst"
echo "  - ~/.config/kitty"
echo "  - ~/.config/hyprlock"
echo "  - ~/.config/hypridle"
echo ""
read -p "Continue? [y/N] " response

if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Find and restore backup
BACKUP_DIR=$(ls -td "$HOME/.config/hyprland-backup-"* 2>/dev/null | head -1)

if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
    echo "Found backup: $BACKUP_DIR"
    read -p "Restore from backup? [Y/n] " restore_response
    
    if [[ ! "$restore_response" =~ ^[Nn]$ ]]; then
        for config in hypr waybar rofi wlogout kitty dunst hyprlock hypridle; do
            if [ -d "$BACKUP_DIR/$config" ]; then
                rm -rf "$CONFIG_DIR/$config"
                cp -r "$BACKUP_DIR/$config" "$CONFIG_DIR/"
                echo "Restored: $config"
            fi
        done
        echo "Backup restored!"
        exit 0
    fi
fi

# Remove configs
echo "Removing configuration files..."
rm -rf "$CONFIG_DIR/hypr"
rm -rf "$CONFIG_DIR/waybar"
rm -rf "$CONFIG_DIR/rofi"
rm -rf "$CONFIG_DIR/wlogout"
rm -rf "$CONFIG_DIR/dunst"
rm -rf "$CONFIG_DIR/kitty"
rm -rf "$CONFIG_DIR/hyprlock"
rm -rf "$CONFIG_DIR/hypridle"

# Remove wallpaper cache
rm -rf "$HOME/.cache/wallpaper-thumbs"

echo ""
echo "Configuration removed successfully!"
echo ""
echo "To reinstall, run:"
echo "  ./install.sh"
