#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                   ║
# ║    ██╗  ██╗██╗   ██╗██████╗ ██████╗ ██╗      █████╗ ███╗   ██╗██████╗             ║
# ║    ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██║     ██╔══██╗████╗  ██║██╔══██╗            ║
# ║    ███████║ ╚████╔╝ ██████╔╝██████╔╝██║     ███████║██╔██╗ ██║██║  ██║            ║
# ║    ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██║     ██╔══██║██║╚██╗██║██║  ██║            ║
# ║    ██║  ██║   ██║   ██║     ██║  ██║███████╗██║  ██║██║ ╚████║██████╔╝            ║
# ║    ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝             ║
# ║                                                                                   ║
# ║                Hyprland Premium Configuration Installer v2.0.0                    ║
# ║                         by xscriptor                                              ║
# ║                                                                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════════╝

set -e

# ┌───────────────────────────────────────────────────────────────────────────────────┐
# │ COLORS                                                                            │
# └───────────────────────────────────────────────────────────────────────────────────┘
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# ┌───────────────────────────────────────────────────────────────────────────────────┐
# │ VARIABLES                                                                         │
# └───────────────────────────────────────────────────────────────────────────────────┘
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config/hyprland-backup-$(date +%Y%m%d_%H%M%S)"
CONFIG_DIR="$HOME/.config"
LOG_FILE="/tmp/hyprland-install-$(date +%Y%m%d_%H%M%S).log"
INSTALL_GPU_MODE=""
INSTALL_VERSION="2.0.0"

# ┌───────────────────────────────────────────────────────────────────────────────────┐
# │ HELPER FUNCTIONS                                                                  │
# └───────────────────────────────────────────────────────────────────────────────────┘

print_banner() {
    echo -e "${MAGENTA}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║     HYPRLAND PREMIUM CONFIGURATION INSTALLER v2.0.0           ║"
    echo "║                by xscriptor                                   ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log() {
    echo -e "${GREEN}[✓]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[!]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$LOG_FILE"
}

error() {
    echo -e "${RED}[✗]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[i]${NC} $1"
}

prompt() {
    echo -e "${CYAN}[?]${NC} $1"
}

# ┌───────────────────────────────────────────────────────────────────────────────────┐
# │ DISTRO DETECTION                                                                  │
# └───────────────────────────────────────────────────────────────────────────────────┘

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        DISTRO_LIKE=$ID_LIKE
    elif [ -f /etc/arch-release ]; then
        DISTRO="arch"
    elif [ -f /etc/fedora-release ]; then
        DISTRO="fedora"
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
    else
        DISTRO="unknown"
    fi

    log "Detected distribution: $DISTRO"
}

# ┌───────────────────────────────────────────────────────────────────────────────────┐
# │ GPU DETECTION                                                                     │
# └───────────────────────────────────────────────────────────────────────────────────┘

detect_gpu() {
    GPU_VENDOR="unknown"
    NVIDIA_SERIES="unknown"

    if lspci | grep -i nvidia &>/dev/null; then
        GPU_VENDOR="nvidia"

        # Detect NVIDIA series
        if lspci | grep -i "RTX 50" &>/dev/null; then
            NVIDIA_SERIES="50xx"
        elif lspci | grep -i "RTX 40" &>/dev/null; then
            NVIDIA_SERIES="40xx"
        elif lspci | grep -i "RTX 30" &>/dev/null; then
            NVIDIA_SERIES="30xx"
        elif lspci | grep -i "RTX 20" &>/dev/null; then
            NVIDIA_SERIES="20xx"
        elif lspci | grep -i "GTX 16" &>/dev/null; then
            NVIDIA_SERIES="16xx"
        elif lspci | grep -i "GTX 10" &>/dev/null; then
            NVIDIA_SERIES="10xx"
        fi

        log "Detected NVIDIA GPU (Series: $NVIDIA_SERIES)"
    elif lspci | grep -i amd &>/dev/null; then
        GPU_VENDOR="amd"
        log "Detected AMD GPU"
    elif lspci | grep -i intel &>/dev/null; then
        GPU_VENDOR="intel"
        log "Detected Intel GPU"
    fi
}

# ┌───────────────────────────────────────────────────────────────────────────────────┐
# │ PACKAGE INSTALLATION                                                              │
# └───────────────────────────────────────────────────────────────────────────────────┘

install_packages_arch() {
    local packages=("$@")

    # Check if yay or paru is available
    if command -v paru &>/dev/null; then
        AUR_HELPER="paru"
    elif command -v yay &>/dev/null; then
        AUR_HELPER="yay"
    else
        warn "No AUR helper found. Installing yay..."
        sudo pacman -S --needed --noconfirm git base-devel
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay && makepkg -si --noconfirm
        AUR_HELPER="yay"
    fi

    log "Installing packages with $AUR_HELPER..."
    $AUR_HELPER -S --needed --noconfirm "${packages[@]}"
}

install_packages_fedora() {
    local packages=("$@")
    log "Installing packages with dnf..."
    sudo dnf install -y "${packages[@]}"
}

install_packages_debian() {
    local packages=("$@")
    log "Installing packages with apt..."
    sudo apt update
    sudo apt install -y "${packages[@]}"
}

# ┌───────────────────────────────────────────────────────────────────────────────────┐
# │ CORE PACKAGES                                                                     │
# └───────────────────────────────────────────────────────────────────────────────────┘

CORE_PACKAGES_ARCH=(
    # Hyprland core
    "hyprland"
    "hypridle"
    "xdg-desktop-portal-hyprland"
    "xdg-desktop-portal-gtk"
    "xdg-desktop-portal-wlr"
    "qt5-wayland"
    "qt6-wayland"
    "qt5ct"
    "qt6ct"
    "polkit-kde-agent"
    "hyprpolkitagent"
    "xorg-xwayland"

    # Bar and launcher
    "waybar"
    "rofi-wayland"
    "jq"
    "imagemagick"
    "librsvg"

    # Terminal
    "kitty"

    # Utilities
    "awww"
    "dunst"
    "hyprlock"
    "hypridle"
    "wlogout"
    "grim"
    "slurp"
    "wl-clipboard"
    "cliphist"
    "brightnessctl"
    "ddcutil"
    "pamixer"
    "playerctl"
    "hyprpicker"

    "libnotify"
    "iproute2"
    "pciutils"
    "pavucontrol"
    "networkmanager"
    "rofi-emoji"
    "radeontop"

    # System
    "pipewire"
    "pipewire-alsa"
    "pipewire-pulse"
    "wireplumber"
    "network-manager-applet"
    "blueman"
    "bluez"
    "bluez-utils"
    "xdg-utils"
    "xdg-user-dirs"
    "wget"
    "curl"
    "gnome-keyring"
    "seahorse"
    "kwallet5"
    "libsecret"

    # Fonts
    "ttf-jetbrains-mono-nerd"
    "noto-fonts"
    "noto-fonts-emoji"

    # Themes
    "adw-gtk3"
    "adw-gtk-theme"
    "papirus-icon-theme"
    "bibata-cursor-theme"

    # File manager
    "nautilus"
    "gvfs"
    "gvfs-mtp"

    # New packages from imperative-dots
    "quickshell-git"
    "matugen-bin"
    "swayosd-git"
    "cava"
    "zbar"
    "fd"
    "ripgrep"
    "socat"
    "inotify-tools"
    "acpi"
    "iw"
    "lm_sensors"
    "bc"
    "python"
    "python-websockets"
    "qt6-websockets"
    "ffmpeg"
    "fastfetch"
    "satty"
    "yq"
    "mpvpaper"
    "wmctrl"
    "power-profiles-daemon"
    "easyeffects"
    "lsp-plugins"
    "gpu-screen-recorder"
    "qt5-quickcontrols"
    "qt5-quickcontrols2"
    "qt5-graphicaleffects"
    "networkmanager-dmenu-git"

    # Other
    "jq"
    "imagemagick"
    "unzip"
)

NVIDIA_PACKAGES_ARCH=(
    "nvidia-utils"
    "nvidia-settings"
    "libva-nvidia-driver"
    "egl-wayland"
    "envycontrol"
)

# ┌───────────────────────────────────────────────────────────────────────────────────┐
# │ NVIDIA DRIVER SELECTION                                                           │
# └───────────────────────────────────────────────────────────────────────────────────┘

get_nvidia_driver() {
    # It is generally safer to use nvidia-dkms for all cards on Wayland to avoid conflicts
    # with the open drivers which can still be problematic on some setups.
    echo "nvidia-dkms"
}

# ┌───────────────────────────────────────────────────────────────────────────────────┐
# │ NVIDIA CONFIGURATION                                                              │
# └───────────────────────────────────────────────────────────────────────────────────┘

configure_nvidia() {
    log "Configuring NVIDIA for Wayland/Hyprland..."

    # Get current kernel
    KERNEL=$(uname -r | sed 's/-.*//g')
    KERNEL_HEADERS="linux-headers"

    if [[ $(uname -r) == *"zen"* ]]; then
        KERNEL_HEADERS="linux-zen-headers"
    elif [[ $(uname -r) == *"lts"* ]]; then
        KERNEL_HEADERS="linux-lts-headers"
    fi

    # Install kernel headers and driver
    NVIDIA_DRIVER=$(get_nvidia_driver)

    if pacman -Qq "$NVIDIA_DRIVER" >/dev/null 2>&1; then
        log "NVIDIA driver ($NVIDIA_DRIVER) is already installed. Skipping driver package."
        install_packages_arch "$KERNEL_HEADERS" "${NVIDIA_PACKAGES_ARCH[@]}"
    else
        log "Installing NVIDIA driver: $NVIDIA_DRIVER"
        install_packages_arch "$KERNEL_HEADERS" "$NVIDIA_DRIVER" "${NVIDIA_PACKAGES_ARCH[@]}"
    fi

    # Configure mkinitcpio
    log "Configuring mkinitcpio..."
    if [ -f /etc/mkinitcpio.conf ]; then
        sudo cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.backup

        # Add NVIDIA modules
        if ! grep -q "nvidia nvidia_modeset nvidia_uvm nvidia_drm" /etc/mkinitcpio.conf; then
            sudo sed -i 's/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
        fi

        # Regenerate initramfs
        sudo mkinitcpio -P
    fi

    # Configure kernel parameters for GRUB
    if command -v grub-mkconfig >/dev/null 2>&1 && [ -f /etc/default/grub ]; then
        log "Configuring GRUB kernel parameters..."
        sudo cp /etc/default/grub /etc/default/grub.backup

        NVIDIA_PARAMS="nvidia_drm.modeset=1 nvidia.NVreg_PreserveVideoMemoryAllocations=1"
        if ! grep -q "nvidia_drm.modeset=1" /etc/default/grub; then
            sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"$NVIDIA_PARAMS /" /etc/default/grub
            sudo grub-mkconfig -o /boot/grub/grub.cfg || warn "grub-mkconfig failed. You may need to update GRUB manually."
        fi
    elif [ -f /etc/default/grub ]; then
        warn "/etc/default/grub found but grub-mkconfig is missing. Skipping GRUB update."
    fi

    # Configure kernel parameters for systemd-boot
    if [ -d /boot/loader/entries ]; then
        log "Configuring systemd-boot kernel parameters..."
        for entry in /boot/loader/entries/*.conf; do
            if [ -f "$entry" ] && ! grep -q "nvidia_drm.modeset=1" "$entry"; then
                sudo sed -i '/^options/ s/$/ nvidia_drm.modeset=1 nvidia.NVreg_PreserveVideoMemoryAllocations=1/' "$entry"
            fi
        done
    fi

    # Enable NVIDIA power management services
    log "Enabling NVIDIA power management services..."
    sudo systemctl enable nvidia-suspend.service 2>/dev/null || true
    sudo systemctl enable nvidia-hibernate.service 2>/dev/null || true
    sudo systemctl enable nvidia-resume.service 2>/dev/null || true

    # Blacklist nouveau
    log "Blacklisting nouveau driver..."
    echo "blacklist nouveau" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf > /dev/null
    echo "options nouveau modeset=0" | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf > /dev/null

    # NVIDIA DRM modeset for modern Wayland support
    log "Setting NVIDIA DRM modeset and fbdev..."
    echo "options nvidia-drm modeset=1 fbdev=1" | sudo tee /etc/modprobe.d/nvidia.conf > /dev/null

    # GPU Mode Script Optional Setup
    echo ""
    prompt "Enable GPU Performance Mode script (adds sudoers rule for envycontrol)? [Y/n] "
    read -r gpu_mode_response
    if [[ ! "$gpu_mode_response" =~ ^[Nn]$ ]]; then
        INSTALL_GPU_MODE=true
        log "Adding sudoers rule for GPU mode (envycontrol)..."
        echo "%wheel ALL=(ALL) NOPASSWD: /usr/bin/envycontrol -s *" | sudo tee /etc/sudoers.d/99-gpu-mode > /dev/null
        sudo chmod 440 /etc/sudoers.d/99-gpu-mode
    else
        INSTALL_GPU_MODE=false
        log "Skipping GPU mode script installation."
    fi

    log "NVIDIA configuration complete!"
}

# ┌───────────────────────────────────────────────────────────────────────────────────┐
# │ BACKUP EXISTING CONFIG                                                            │
# └───────────────────────────────────────────────────────────────────────────────────┘

backup_config() {
    log "Creating backup of existing configurations..."
    mkdir -p "$BACKUP_DIR"

    local configs=("hypr" "waybar" "rofi" "wlogout" "kitty" "dunst" "cava" "matugen" "swayosd")

    for config in "${configs[@]}"; do
        if [ -d "$CONFIG_DIR/$config" ]; then
            cp -r "$CONFIG_DIR/$config" "$BACKUP_DIR/"
            log "Backed up: $config"
        fi
    done

    # Backup .zshrc if it exists
    if [ -f "$HOME/.zshrc" ]; then
        cp "$HOME/.zshrc" "$BACKUP_DIR/.zshrc"
        log "Backed up: .zshrc"
    fi

    # Backup settings.json specifically
    if [ -f "$CONFIG_DIR/hypr/settings.json" ]; then
        mkdir -p "$BACKUP_DIR/hypr"
        cp "$CONFIG_DIR/hypr/settings.json" "$BACKUP_DIR/hypr/settings.json"
        log "Backed up: hypr/settings.json"
    fi

    log "Backup created at: $BACKUP_DIR"
}

# ┌───────────────────────────────────────────────────────────────────────────────────┐
# │ INSTALL DOTFILES                                                                  │
# └───────────────────────────────────────────────────────────────────────────────────┘

install_dotfiles() {
    log "Installing dotfiles..."

    # Copy Hyprland config
    mkdir -p "$CONFIG_DIR/hypr"
    cp -r "$SCRIPT_DIR/config/hypr/"* "$CONFIG_DIR/hypr/"

    # Copy themes
    mkdir -p "$CONFIG_DIR/hypr/themes"
    cp -r "$SCRIPT_DIR/themes/"* "$CONFIG_DIR/hypr/themes/"

    # Copy scripts
    mkdir -p "$CONFIG_DIR/hypr/scripts"
    if [ -d "$SCRIPT_DIR/scripts" ]; then
        cp -r "$SCRIPT_DIR/scripts/"* "$CONFIG_DIR/hypr/scripts/"
        find "$CONFIG_DIR/hypr/scripts" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    fi

    # Copy quickshell scripts
    if [ -d "$SCRIPT_DIR/config/hypr/scripts/quickshell" ]; then
        mkdir -p "$CONFIG_DIR/hypr/scripts/quickshell"
        cp -r "$SCRIPT_DIR/config/hypr/scripts/quickshell/"* "$CONFIG_DIR/hypr/scripts/quickshell/"
        log "Installed quickshell scripts"
    fi

    # Copy hypr config/ subdirectory files
    if [ -d "$SCRIPT_DIR/config/hypr/config" ]; then
        mkdir -p "$CONFIG_DIR/hypr/config"
        cp -r "$SCRIPT_DIR/config/hypr/config/"* "$CONFIG_DIR/hypr/config/"
        log "Installed hypr config subdirectory files"
    fi

    # Copy hypr templates
    if [ -d "$SCRIPT_DIR/config/hypr/templates" ]; then
        mkdir -p "$CONFIG_DIR/hypr/templates"
        cp -r "$SCRIPT_DIR/config/hypr/templates/"* "$CONFIG_DIR/hypr/templates/"
        log "Installed hypr templates"
    fi

    # Copy default_settings.json
    if [ -f "$SCRIPT_DIR/config/hypr/default_settings.json" ]; then
        cp "$SCRIPT_DIR/config/hypr/default_settings.json" "$CONFIG_DIR/hypr/default_settings.json"
        log "Installed default_settings.json"
    fi

    # Copy wallpapers
    mkdir -p "$CONFIG_DIR/hypr/wallpapers"
    if [ -d "$SCRIPT_DIR/wallpapers" ] && [ "$(ls -A "$SCRIPT_DIR/wallpapers" 2>/dev/null)" ]; then
        cp -r "$SCRIPT_DIR/wallpapers/"* "$CONFIG_DIR/hypr/wallpapers/"
        log "Copied $(ls -1 "$SCRIPT_DIR/wallpapers" | wc -l) wallpapers"
    fi

    # Copy Waybar config
    if [ -d "$SCRIPT_DIR/config/waybar" ]; then
        mkdir -p "$CONFIG_DIR/waybar"
        cp -r "$SCRIPT_DIR/config/waybar/"* "$CONFIG_DIR/waybar/"
    fi

    # Copy Rofi config
    if [ -d "$SCRIPT_DIR/config/rofi" ]; then
        mkdir -p "$CONFIG_DIR/rofi"
        cp -r "$SCRIPT_DIR/config/rofi/"* "$CONFIG_DIR/rofi/"
    fi

    # Copy Wlogout config
    if [ -d "$SCRIPT_DIR/config/wlogout" ]; then
        mkdir -p "$CONFIG_DIR/wlogout"
        cp -r "$SCRIPT_DIR/config/wlogout/"* "$CONFIG_DIR/wlogout/"
    fi

    # Copy Dunst config
    if [ -d "$SCRIPT_DIR/config/dunst" ]; then
        mkdir -p "$CONFIG_DIR/dunst"
        cp -r "$SCRIPT_DIR/config/dunst/"* "$CONFIG_DIR/dunst/"
    fi

    # Copy Cava config
    if [ -d "$SCRIPT_DIR/config/cava" ]; then
        mkdir -p "$CONFIG_DIR/cava"
        cp -r "$SCRIPT_DIR/config/cava/"* "$CONFIG_DIR/cava/"
        log "Installed cava config"
    fi

    # Copy Matugen config
    if [ -d "$SCRIPT_DIR/config/matugen" ]; then
        mkdir -p "$CONFIG_DIR/matugen"
        cp -r "$SCRIPT_DIR/config/matugen/"* "$CONFIG_DIR/matugen/"
        log "Installed matugen config"
    fi

    # Copy Hyprlock config (goes to ~/.config/hypr/)
    if [ -f "$SCRIPT_DIR/config/hyprlock/hyprlock.conf" ]; then
        cp "$SCRIPT_DIR/config/hyprlock/hyprlock.conf" "$CONFIG_DIR/hypr/"
        log "Installed hyprlock.conf"
    fi

    # Copy Hypridle config (goes to ~/.config/hypr/)
    if [ -f "$SCRIPT_DIR/config/hypridle/hypridle.conf" ]; then
        cp "$SCRIPT_DIR/config/hypridle/hypridle.conf" "$CONFIG_DIR/hypr/"
        log "Installed hypridle.conf"
    fi

    # Copy .zshrc from config/zsh/ if it exists
    if [ -f "$SCRIPT_DIR/config/zsh/.zshrc" ]; then
        mkdir -p "$CONFIG_DIR/zsh"
        cp "$SCRIPT_DIR/config/zsh/.zshrc" "$CONFIG_DIR/zsh/.zshrc"
        cp "$SCRIPT_DIR/config/zsh/.zshrc" "$HOME/.zshrc"
        log "Installed .zshrc"
    fi

    # Clean up GPU mode if user opted out
    if [ "$INSTALL_GPU_MODE" = "false" ]; then
        rm -f "$CONFIG_DIR/hypr/scripts/gpu-mode.sh"
        sed -i '/custom\/gpu-mode/d' "$CONFIG_DIR/waybar/config.jsonc" 2>/dev/null || true
    fi

    log "Dotfiles installed successfully!"
}

# ┌───────────────────────────────────────────────────────────────────────────────────┐
# │ INSTALL KITTY WITH CUSTOM CONFIG                                                  │
# └───────────────────────────────────────────────────────────────────────────────────┘

install_kitty_config() {
    log "Installing Kitty configuration..."

    # Copy Kitty config from local
    mkdir -p "$CONFIG_DIR/kitty/themes"

    if [ -f "$SCRIPT_DIR/config/kitty/kitty.conf" ]; then
        cp "$SCRIPT_DIR/config/kitty/kitty.conf" "$CONFIG_DIR/kitty/"
        log "Installed kitty.conf"
    fi

    if [ -d "$SCRIPT_DIR/config/kitty/themes" ]; then
        cp -r "$SCRIPT_DIR/config/kitty/themes/"* "$CONFIG_DIR/kitty/themes/"
        log "Installed Kitty themes"
    fi

    # Set default theme
    if [ -f "$CONFIG_DIR/kitty/themes/x.conf" ]; then
        cp "$CONFIG_DIR/kitty/themes/x.conf" "$CONFIG_DIR/kitty/current-theme.conf"
    fi

    log "Kitty configuration installed!"
}

# ┌───────────────────────────────────────────────────────────────────────────────────┐
# │ INSTALL MATUGEN CONFIG                                                            │
# └───────────────────────────────────────────────────────────────────────────────────┘

install_matugen_config() {
    log "Installing Matugen color generation configuration..."

    # Copy matugen config and templates (already done in install_dotfiles)
    # Generate initial colors if wallpapers exist
    local first_wallpaper=""

    if [ -d "$CONFIG_DIR/hypr/wallpapers" ]; then
        first_wallpaper=$(find "$CONFIG_DIR/hypr/wallpapers" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | head -n 1)
    fi

    if [ -n "$first_wallpaper" ] && command -v matugen &>/dev/null; then
        log "Generating initial Matugen colors from $first_wallpaper..."
        matugen image "$first_wallpaper" --source-color-index 0 || warn "Matugen color generation failed (non-fatal)"
    else
        if [ -z "$first_wallpaper" ]; then
            warn "No wallpapers found for Matugen color generation. Run matugen manually after setting a wallpaper."
        elif ! command -v matugen &>/dev/null; then
            warn "matugen binary not found. Skipping color generation."
        fi
    fi

    log "Matugen configuration installed!"
}

# ┌───────────────────────────────────────────────────────────────────────────────────┐
# │ INSTALL SDDM THEME                                                                │
# └───────────────────────────────────────────────────────────────────────────────────┘

install_sddm_theme() {
    log "Installing SDDM theme..."

    if [ -d "$SCRIPT_DIR/config/sddm/themes/matugen-minimal" ]; then
        sudo mkdir -p /usr/share/sddm/themes/matugen-minimal
        sudo cp -r "$SCRIPT_DIR/config/sddm/themes/matugen-minimal/"* /usr/share/sddm/themes/matugen-minimal/

        # Create Colors.qml with default Catppuccin Mocha palette
        if [ ! -f /usr/share/sddm/themes/matugen-minimal/Colors.qml ]; then
            cat <<EOF | sudo tee /usr/share/sddm/themes/matugen-minimal/Colors.qml > /dev/null
pragma Singleton
import QtQuick
QtObject {
    readonly property color base: "#1e1e2e"
    readonly property color crust: "#11111b"
    readonly property color mantle: "#181825"
    readonly property color text: "#cdd6f4"
    readonly property color subtext0: "#a6adc8"
    readonly property color surface0: "#313244"
    readonly property color surface1: "#45475a"
    readonly property color surface2: "#585b70"
    readonly property color mauve: "#cba6f7"
    readonly property color red: "#f38ba8"
    readonly property color peach: "#fab387"
    readonly property color blue: "#89b4fa"
    readonly property color green: "#a6e3a1"
}
EOF
        fi

        # Configure SDDM to use the theme
        sudo mkdir -p /etc/sddm.conf.d
        cat <<EOF | sudo tee /etc/sddm.conf.d/10-matugen-theme.conf > /dev/null
[Theme]
Current=matugen-minimal
EOF

        log "SDDM theme installed and configured!"
    else
        warn "SDDM theme directory not found at config/sddm/themes/matugen-minimal"
    fi
}

# ┌───────────────────────────────────────────────────────────────────────────────────┐
# │ DOWNLOAD WALLPAPERS                                                               │
# └───────────────────────────────────────────────────────────────────────────────────┘

download_wallpapers() {
    local WALLPAPER_DIR="$CONFIG_DIR/hypr/wallpapers"
    local WALLPAPER_URL="https://github.com/xscriptor/xwall/releases/download/1.0.0/xwall-1.0.0.zip"
    local TMP_ZIP="/tmp/xwall-1.0.0.zip"
    local TMP_EXTRACT="/tmp/xwall-extract"

    echo ""
    warn "The full wallpaper pack weighs approximately 1.37 GB."
    prompt "Download the complete wallpaper collection? [y/N] "
    read -r wall_response
    if [[ ! "$wall_response" =~ ^[Yy]$ ]]; then
        log "Skipping wallpaper download."
        return
    fi

    log "Downloading wallpaper pack (1.37 GB)... This may take a while."
    if ! wget --progress=bar:force -O "$TMP_ZIP" "$WALLPAPER_URL"; then
        error "Failed to download wallpaper pack."
        rm -f "$TMP_ZIP"
        return
    fi

    log "Extracting wallpapers..."
    mkdir -p "$TMP_EXTRACT"
    if ! unzip -qo "$TMP_ZIP" -d "$TMP_EXTRACT"; then
        error "Failed to extract wallpaper pack."
        rm -rf "$TMP_ZIP" "$TMP_EXTRACT"
        return
    fi

    # The zip contains a folder named "xwall-1,0,0" — move its contents into the wallpapers dir
    mkdir -p "$WALLPAPER_DIR"
    local INNER_DIR
    INNER_DIR=$(find "$TMP_EXTRACT" -mindepth 1 -maxdepth 1 -type d | head -n 1)

    if [ -n "$INNER_DIR" ] && [ -d "$INNER_DIR" ]; then
        cp -r "$INNER_DIR/"* "$WALLPAPER_DIR/"
        log "Wallpapers installed to $WALLPAPER_DIR ($(ls -1 "$INNER_DIR" | wc -l) files)"
    else
        # Fallback: copy everything directly
        cp -r "$TMP_EXTRACT/"* "$WALLPAPER_DIR/"
        log "Wallpapers installed to $WALLPAPER_DIR"
    fi

    # Cleanup
    rm -rf "$TMP_ZIP" "$TMP_EXTRACT"
    log "Wallpaper download complete!"
}

# ┌───────────────────────────────────────────────────────────────────────────────────┐
# │ CREATE SCREENSHOTS DIR                                                            │
# └───────────────────────────────────────────────────────────────────────────────────┘

create_directories() {
    log "Creating necessary directories..."
    mkdir -p "$HOME/Pictures/Screenshots"
    mkdir -p "$HOME/Pictures/Wallpapers"
}

check_requirements() {
    local missing=()
    local cmds=(rofi waybar notify-send ip lspci)

    for c in "${cmds[@]}"; do
        if ! command -v "$c" >/dev/null 2>&1; then
            missing+=("$c")
        fi
    done

    if ! command -v magick >/dev/null 2>&1 && ! command -v convert >/dev/null 2>&1; then
        missing+=("magick/convert")
    fi

    if [ "${#missing[@]}" -gt 0 ]; then
        warn "Some commands are missing: ${missing[*]}"
        warn "Wallpapers thumbnails require ImageMagick (magick/convert)."
    fi
}

# ┌───────────────────────────────────────────────────────────────────────────────────┐
# │ MAIN INSTALLATION                                                                 │
# └───────────────────────────────────────────────────────────────────────────────────┘

main() {
    print_banner

    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        error "Please do not run this script as root!"
        exit 1
    fi

    # Detect system
    detect_distro
    detect_gpu

    # Show detected info
    echo ""
    info "Detected Distribution: ${WHITE}$DISTRO${NC}"
    info "Detected GPU: ${WHITE}$GPU_VENDOR${NC}"
    if [ "$GPU_VENDOR" = "nvidia" ]; then
        info "NVIDIA Series: ${WHITE}$NVIDIA_SERIES${NC}"
        info "Recommended Driver: ${WHITE}$(get_nvidia_driver)${NC}"
    fi
    echo ""

    # Confirm installation
    prompt "This will install Hyprland and its configuration. Continue? [y/N] "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi

    # Backup existing config
    backup_config

    # Install based on distribution
    case "$DISTRO" in
        arch|endeavouros|manjaro|cachyos|garuda|arcolinux|xos|x)
            log "Installing packages for Arch-based system..."
            install_packages_arch "${CORE_PACKAGES_ARCH[@]}"

            # NVIDIA specific setup
            if [ "$GPU_VENDOR" = "nvidia" ]; then
                prompt "Configure NVIDIA drivers for Wayland? [Y/n] "
                read -r nvidia_response
                if [[ ! "$nvidia_response" =~ ^[Nn]$ ]]; then
                    configure_nvidia
                else
                    INSTALL_GPU_MODE=false
                fi
            fi
            ;;
        fedora)
            warn "Fedora support is experimental. Some packages may not be available."
            # Basic packages for Fedora
            install_packages_fedora hyprland waybar rofi-wayland kitty dunst wlogout grim slurp wl-clipboard jq imagemagick librsvg2 ddcutil
            ;;
        debian|ubuntu|pop)
            error "Debian/Ubuntu requires manual Hyprland installation from source."
            error "Please visit: https://wiki.hyprland.org/Getting-Started/Installation/"
            exit 1
            ;;
        *)
            error "Unsupported distribution: $DISTRO"
            exit 1
            ;;
    esac

    # Install dotfiles
    install_dotfiles

    # Download wallpaper pack
    download_wallpapers

    # Install Kitty config
    prompt "Install custom Kitty configuration? [Y/n] "
    read -r kitty_response
    if [[ ! "$kitty_response" =~ ^[Nn]$ ]]; then
        install_kitty_config
    fi

    # Install Matugen config and generate colors
    install_matugen_config

    # Install SDDM theme
    prompt "Install SDDM theme (matugen-minimal) and configure display manager? [y/N] "
    read -r sddm_response
    if [[ "$sddm_response" =~ ^[Yy]$ ]]; then
        install_sddm_theme
    fi

    # Create directories
    create_directories

    # Enable core system services
    log "Enabling core system services..."
    sudo systemctl enable NetworkManager.service 2>/dev/null || true
    sudo systemctl enable --now power-profiles-daemon.service 2>/dev/null || true
    sudo systemctl enable --now swayosd-libinput-backend.service 2>/dev/null || true
    systemctl --user enable easyeffects.service 2>/dev/null || true
    sudo systemctl --global enable pipewire wireplumber pipewire-pulse 2>/dev/null || true
    systemctl --user start pipewire wireplumber pipewire-pulse 2>/dev/null || true

    check_requirements

    # Final message
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              INSTALLATION COMPLETE!                           ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    info "Configuration backup: $BACKUP_DIR"
    info "Installation log: $LOG_FILE"
    echo ""
    warn "Please reboot your system to apply all changes."
    if [ "$GPU_VENDOR" = "nvidia" ]; then
        warn "NVIDIA users: Reboot is REQUIRED for driver changes."
    fi
    echo ""
    info "After reboot, select Hyprland from your display manager."
    info "Default terminal: SUPER + Return"
    info "App launcher: SUPER + D"
    info "Theme switcher: SUPER + T"
    echo ""
}

# ┌───────────────────────────────────────────────────────────────────────────────────┐
# │ HELP                                                                              │
# └───────────────────────────────────────────────────────────────────────────────────┘

show_help() {
    echo "Hyprland Premium Configuration Installer v$INSTALL_VERSION"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show this help message"
    echo "  -v, --version   Show version"
    echo "  --nvidia-only   Only configure NVIDIA (skip other installation)"
    echo "  --dotfiles-only Only install dotfiles (skip packages)"
    echo ""
}

# Parse arguments
case "$1" in
    -h|--help)
        show_help
        exit 0
        ;;
    -v|--version)
        echo "Hyprland Premium Config Installer v$INSTALL_VERSION"
        exit 0
        ;;
    --nvidia-only)
        detect_distro
        detect_gpu
        if [ "$GPU_VENDOR" = "nvidia" ]; then
            configure_nvidia
        else
            error "No NVIDIA GPU detected!"
            exit 1
        fi
        exit 0
        ;;
    --dotfiles-only)
        backup_config
        install_dotfiles
        install_kitty_config
        install_matugen_config
        create_directories
        check_requirements
        log "Dotfiles installed!"
        exit 0
        ;;
    *)
        main
        ;;
esac
