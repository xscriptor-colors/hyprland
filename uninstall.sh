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
echo "  - ~/.config/rofi"
echo "  - ~/.config/dunst"
echo "  - ~/.config/kitty"
echo "  - ~/.config/hypridle"
echo "  - /usr/share/sddm/themes/matugen-minimal"
echo "  - /etc/sddm.conf.d/10-matugen-theme.conf"
echo "  - /etc/sddm.conf.d/z-disable-virtualkbd.conf"
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
        for config in hypr rofi kitty dunst hypridle; do
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
rm -rf "$CONFIG_DIR/rofi"
rm -rf "$CONFIG_DIR/dunst"
rm -rf "$CONFIG_DIR/kitty"
rm -rf "$CONFIG_DIR/hypridle"

# Restore SDDM theme override if it was backed up
if [ -f /etc/sddm.conf.d/theme.conf.user.bak ]; then
    sudo mv /etc/sddm.conf.d/theme.conf.user.bak /etc/sddm.conf.d/theme.conf.user
    echo "Restored: theme.conf.user"
fi

# Remove SDDM theme and configs
sudo rm -f /etc/sddm.conf.d/10-matugen-theme.conf
sudo rm -f /etc/sddm.conf.d/z-disable-virtualkbd.conf
sudo rm -rf /usr/share/sddm/themes/matugen-minimal

# Restore previous PAM service for the quickshell lock screen, if backed up
if [ -f /etc/pam.d/quickshell.backup ]; then
    sudo mv /etc/pam.d/quickshell.backup /etc/pam.d/quickshell
    echo "Restored: /etc/pam.d/quickshell"
else
    sudo rm -f /etc/pam.d/quickshell
fi

# Remove wallpaper cache
rm -rf "$HOME/.cache/wallpaper-thumbs"

echo ""
echo "Configuration removed successfully!"
echo ""
echo "To reinstall, run:"
echo "  ./install.sh"
