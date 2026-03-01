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
# ║                     Premium Configuration Installer                               ║
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

# ┌───────────────────────────────────────────────────────────────────────────────────┐
# │ HELPER FUNCTIONS                                                                  │
# └───────────────────────────────────────────────────────────────────────────────────┘

print_banner() {
    echo -e "${MAGENTA}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║     HYPRLAND PREMIUM CONFIGURATION INSTALLER                  ║"
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
    "xdg-desktop-portal-hyprland"
    "xdg-desktop-portal-gtk"
    "qt5-wayland"
    "qt6-wayland"
    "qt5ct"
    "qt6ct"
    "polkit-kde-agent"
    "xorg-xwayland"
    
    # Bar and launcher
    "waybar"
    "wofi"
    "rofi"
    "jq"
    "imagemagick"
    "librsvg"
    
    # Terminal
    "kitty"
    
    # Utilities
    "swww"
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
    "wofi-emoji"
    "radeontop"
    
    # System
    "pipewire"
    "pipewire-alsa"
    "pipewire-pulse"
    "wireplumber"
    "network-manager-applet"
    "blueman"
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
    "papirus-icon-theme"
    "bibata-cursor-theme"
    
    # File manager
    "nautilus"
    "gvfs"
    "gvfs-mtp"
    
    # Other
    "jq"
    "imagemagick"
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
    
    local configs=("hypr" "waybar" "wofi" "rofi" "wlogout" "kitty" "dunst")
    
    for config in "${configs[@]}"; do
        if [ -d "$CONFIG_DIR/$config" ]; then
            cp -r "$CONFIG_DIR/$config" "$BACKUP_DIR/"
            log "Backed up: $config"
        fi
    done
    
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
    cp -r "$SCRIPT_DIR/scripts/"* "$CONFIG_DIR/hypr/scripts/"
    chmod +x "$CONFIG_DIR/hypr/scripts/"*.sh
    
    # Copy wallpapers
    mkdir -p "$CONFIG_DIR/hypr/wallpapers"
    if [ -d "$SCRIPT_DIR/wallpapers" ] && [ "$(ls -A "$SCRIPT_DIR/wallpapers" 2>/dev/null)" ]; then
        cp -r "$SCRIPT_DIR/wallpapers/"* "$CONFIG_DIR/hypr/wallpapers/"
        log "Copied $(ls -1 "$SCRIPT_DIR/wallpapers" | wc -l) wallpapers"
    fi
    
    # Copy Waybar config
    mkdir -p "$CONFIG_DIR/waybar"
    cp -r "$SCRIPT_DIR/config/waybar/"* "$CONFIG_DIR/waybar/"
    
    # Copy Wofi config
    mkdir -p "$CONFIG_DIR/wofi"
    cp -r "$SCRIPT_DIR/config/wofi/"* "$CONFIG_DIR/wofi/"

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
    mkdir -p "$CONFIG_DIR/dunst"
    cp -r "$SCRIPT_DIR/config/dunst/"* "$CONFIG_DIR/dunst/"
    
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
# │ CREATE SCREENSHOTS DIR                                                            │
# └───────────────────────────────────────────────────────────────────────────────────┘

create_directories() {
    log "Creating necessary directories..."
    mkdir -p "$HOME/Pictures/Screenshots"
    mkdir -p "$HOME/Pictures/Wallpapers"
}

check_requirements() {
    local missing=()
    local cmds=(wofi waybar swww notify-send ip lspci)

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
                fi
            fi
            ;;
        fedora)
            warn "Fedora support is experimental. Some packages may not be available."
            # Basic packages for Fedora
            install_packages_fedora hyprland waybar wofi rofi kitty dunst wlogout grim slurp wl-clipboard jq imagemagick librsvg2 ddcutil
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
    
    # Install Kitty config
    prompt "Install custom Kitty configuration? [Y/n] "
    read -r kitty_response
    if [[ ! "$kitty_response" =~ ^[Nn]$ ]]; then
        install_kitty_config
    fi
    
    # Create directories
    create_directories

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
    echo "Hyprland Premium Configuration Installer"
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
        echo "Hyprland Premium Config Installer v1.0.0"
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
        create_directories
        check_requirements
        log "Dotfiles installed!"
        exit 0
        ;;
    *)
        main
        ;;
esac
