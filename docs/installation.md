# Installation

## Prerequisites

- **Distribution**: Arch Linux or derivatives (EndeavourOS, Manjaro, CachyOS, Garuda, X Arch Linux spin)
- **Kernel**: Linux 6.x or newer recommended
- **RAM**: 4 GB minimum, 8 GB or more recommended

## Quick Install

```bash
git clone https://github.com/xscriptor/hyprland.git
cd hyprland
chmod +x install.sh
./install.sh
```

## Options

### NVIDIA Only
```bash
./install.sh --nvidia-only
```
Configures NVIDIA drivers (kernel parameters, mkinitcpio, DRM modeset, power management, envycontrol sudoers rule) without installing dotfiles or packages.

### Dotfiles Only
```bash
./install.sh --dotfiles-only
```
Deploys configuration files without package installation. Useful if packages are already installed or for manual setup.

## What the Installer Does

1. Detects your distribution and GPU vendor
2. Installs required packages via AUR helper (yay/paru):
   - Hyprland and its Wayland ecosystem (xdg-desktop-portal, qt5/6-wayland, polkit)
   - QuickShell (QML shell), Matugen (color generation), SwayOSD (on-screen display)
   - Utilities: kitty, awww, dunst, grim, slurp, cliphist, gpu-screen-recorder, rofi, cava, and more
   - Fonts: Hack Nerd Font (downloaded separately), Noto Fonts, Noto Emoji
   - Themes: adw-gtk3, Papirus icons, Bibata cursors
   - NVIDIA: nvidia-utils, nvidia-settings, libva-nvidia-driver, egl-wayland, envycontrol
3. Backs up existing configurations to `~/.config/hyprland-backup-<timestamp>`
4. Deploys all configuration files
5. Configures NVIDIA (if applicable and confirmed):
   - Kernel parameters for GRUB and systemd-boot
   - mkinitcpio modules
   - DRM modeset and fbdev
   - Blacklists nouveau
   - Enables NVIDIA power management services
   - Optional: passwordless sudo rule for envycontrol
6. Downloads optional wallpaper collection (1.37 GB)
7. Optionally installs Kitty config, SDDM theme (matugen-minimal), Neovim config
8. Generates initial Matugen color scheme from first wallpaper
9. Enables system services (NetworkManager, power-profiles-daemon, swayosd, pipewire, wireplumber)

## Uninstallation

```bash
./uninstall.sh
```

Removes all deployed configuration files and SDDM theme. Optionally restores from backup. Does NOT remove installed packages or NVIDIA driver configuration.

## Post-Install

- Reboot is required (mandatory for NVIDIA driver changes)
- Select Hyprland from your display manager
- Default terminal: SUPER + Return
- App launcher: SUPER + D

The first boot will initialize the wallpaper daemon, generate Matugen colors, and start all background services automatically.
