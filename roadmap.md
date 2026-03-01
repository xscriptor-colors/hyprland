# Hyprland Configuration Roadmap

> **Project**: Premium Hyprland Configuration with custom color schemes
> **Start date**: 2026-01-21
> **Status**: Complete

---

## Project Summary

Create a complete and optimized Hyprland configuration based on the best community dotfiles (ML4W), adapted with custom color schemes and full support for NVIDIA RTX 4060 and other graphics cards.

---

## Task Checklist

### Phase 1: Research and Planning
- [x] Research most popular Hyprland configurations
- [x] Analyze project color references (13 schemes)
- [x] Research best practices for NVIDIA RTX 4060/Wayland
- [x] Create roadmap.md

### Phase 2: Base Structure
- [x] Create project directory structure
  - [x] `hypr/` - Main Hyprland configuration
  - [x] `waybar/` - Status bar
  - [x] `wofi/` - App launcher
  - [x] `kitty/` - Terminal (integrated via external script)
  - [x] `dunst/` - Notifications
  - [x] `themes/` - Color schemes
  - [x] `wallpapers/` - Wallpapers
  - [x] `scripts/` - Helper scripts

### Phase 3: Hyprland Configuration
- [x] Create main `hypr/hyprland.conf`
- [x] Configure monitors and resolution
- [x] Configure keybindings
- [x] Configure animations and visual effects
- [x] Configure window decorations
- [x] Configure workspaces
- [x] Configure window rules
- [x] Configure gestures (touchpad/touchscreen)
- [x] Configure NVIDIA environment variables
- [x] Configure autostart applications

### Phase 4: Additional Components
- [x] Configure Waybar (status bar)
  - [x] Modules: workspaces, clock, battery, network, audio, etc.
  - [x] CSS styles with project colors
- [x] Configure Wofi (app launcher)
- [x] Configure Kitty (via integrated script)
- [x] Configure Dunst (notifications)
- [x] Configure swww/hyprpaper (wallpapers)
- [x] Configure wlogout (logout screen)
- [x] Configure hyprlock (lock screen)
- [x] Configure hypridle (idle management)

### Phase 5: Color Schemes
- [x] Create dynamic theme system
- [x] Implement 13 color schemes:
  - [x] X (main theme)
  - [x] Madrid
  - [x] Lahabana
  - [x] Seul
  - [x] Miami
  - [x] Paris
  - [x] Tokio
  - [x] Oslo
  - [x] Helsinki
  - [x] Berlin
  - [x] London
  - [x] Praha
  - [x] Bogota
- [x] Script to switch between themes

### Phase 6: Installation Script
- [x] Create `install.sh` with:
  - [x] Distribution detection (Arch, Fedora, Debian, openSUSE)
  - [x] Base dependencies installation
  - [x] Hyprland and components installation
  - [x] NVIDIA driver configuration:
    - [x] Automatic GPU detection
    - [x] RTX 4060 (and 40xx series)
    - [x] RTX 3060/3070/3080/3090 (30xx series)
    - [x] RTX 2060/2070/2080 (20xx series)
    - [x] GTX 1660/1070/1080 (10xx/16xx series)
    - [x] Support for AMD and Intel
  - [x] Kernel parameters configuration
  - [x] Initramfs configuration
  - [x] Backup of existing configuration
  - [x] Dotfiles installation
  - [x] Systemd services configuration
  - [x] Post-installation verification

### Phase 7: Documentation
- [x] Create complete README.md with:
  - [x] Project description
  - [x] System requirements
  - [x] Installation guide
  - [x] Configuration guide
  - [x] Keybindings
  - [x] Available color schemes
  - [x] Common troubleshooting
  - [x] Credits and license

### Phase 8: Verification and Testing
- [x] Verify file structure (37 files created)
- [ ] Test installation on real system

### Phase 9: Multi-Monitor & GPU Performance
- [x] Create `workspaces.conf` (workspace rules, smart gaps, scratchpads)
- [x] Add multi-monitor workspace binding templates
- [x] Add multi-monitor keybinds (SUPER+ALT combos)
- [x] Create `gpu-mode.sh` (silent/normal/turbo, auto-detect GPU limits)
- [x] Add GPU mode Waybar module with JSON output
- [x] Add GPU mode Rofi/Wofi menu selector
- [x] Add GPU keybinds (SUPER+F9)
- [x] Update `README.md` with full documentation
- [x] Update `hyprland.conf` with multi-monitor examples
- [ ] Test on RTX 5060 laptop
- [ ] Test on RTX 4060 laptop

---

## Available Color Schemes

| Theme | Background | Accent | Description |
|-------|-----------|--------|-------------|
| **X** | `#363537` | `#fc618d` | Main project theme |
| **Madrid** | `#333333` | `#cc0033` | Intense red tones |
| **Lahabana** | `#363537` | `#e5ff9d` | Lime green tones |
| **Seul** | `#1b1b1b` | `#FF4C8B` | Asian neon |
| **Miami** | `#000000` | `#FF4C8B` | Cyberpunk/retrowave |
| **Paris** | `#222222` | `#a3f3ff` | Elegant blue |
| **Tokio** | `#363537` | `#fd9353` | Orange tones |
| **Oslo** | `#3f4451` | `#4aa5f0` | Nordic blue |
| **Helsinki** | `#c0bbae` | `#1faa9e` | Light theme |
| **Berlin** | `#000000` | `#999999` | Dark monochrome |
| **London** | `#000000` | `#555555` | Subtle grayscale |
| **Praha** | `#1A1A1A` | `#BD93F9` | Dracula-inspired |
| **Bogota** | `#222222` | `#47e6ff` | Vibrant cyan |

---

## NVIDIA Hardware Support

### Supported Drivers
- `nvidia-dkms` (recommended for all modern cards)

### Supported Cards
| Series | Examples | Recommended Driver |
|--------|----------|-------------------|
| RTX 50xx | RTX 5090, 5080 | `nvidia-dkms` |
| RTX 40xx | RTX 4090, 4080, 4070, **4060** | `nvidia-dkms` |
| RTX 30xx | RTX 3090, 3080, 3070, 3060 | `nvidia-dkms` |
| RTX 20xx | RTX 2080, 2070, 2060 | `nvidia-dkms` |
| GTX 16xx | GTX 1660, 1650 | `nvidia-dkms` |
| GTX 10xx | GTX 1080, 1070, 1060 | `nvidia-dkms` |

### Critical Configurations
- `nvidia_drm.modeset=1` in kernel parameters
- Suspend/hibernate services enabled
- `NVreg_PreserveVideoMemoryAllocations=1` for suspend

---

## Project Structure

```
hyprland/
├── README.md                 # Main documentation
├── roadmap.md               # This file
├── references.md            # Color schemes
├── install.sh               # Installation script
├── uninstall.sh             # Uninstall script
│
├── config/
│   ├── hypr/
│   │   ├── hyprland.conf    # Main config
│   │   ├── keybinds.conf    # Keybindings
│   │   ├── windowrules.conf # Window rules
│   │   ├── animations.conf  # Animations
│   │   ├── env.conf         # Environment variables
│   │   └── autostart.conf   # Startup apps
│   │
│   ├── waybar/
│   │   ├── config.jsonc     # Configuration
│   │   └── style.css        # Styles
│   │
│   ├── wofi/
│   │   ├── config           # Configuration
│   │   └── style.css        # Styles
│   │
│   ├── dunst/
│   │   └── dunstrc          # Configuration
│   │
│   ├── hyprlock/
│   │   └── hyprlock.conf    # Lock screen
│   │
│   └── hypridle/
│       └── hypridle.conf    # Idle management
│
├── themes/
│   ├── x.conf
│   ├── madrid.conf
│   ├── lahabana.conf
│   ├── seul.conf
│   ├── miami.conf
│   ├── paris.conf
│   ├── tokio.conf
│   ├── oslo.conf
│   ├── helsinki.conf
│   ├── berlin.conf
│   ├── london.conf
│   ├── praha.conf
│   └── bogota.conf
│
├── scripts/
│   ├── theme-switcher.sh    # Change theme
│   ├── wallpaper.sh         # Wallpaper management
│   ├── screenshot.sh        # Screenshots
│   ├── volume.sh            # Volume control
│   └── brightness.sh        # Brightness control
│
└── wallpapers/
    └── default.jpg          # Default wallpaper
```

---

## Main Dependencies

### Core
- `hyprland` - Window manager
- `xdg-desktop-portal-hyprland` - XDG Portal
- `qt5-wayland` / `qt6-wayland` - Qt support
- `polkit-kde-agent` - Authentication

### Bar and Launcher
- `waybar` - Status bar
- `wofi` - App launcher
- `rofi-wayland` - Alternative to wofi

### Terminal and Shell
- `kitty` - Terminal
- `zsh` + `oh-my-zsh` - Enhanced shell
- `starship` - Prompt

### Utilities
- `swww` - Wallpapers
- `dunst` / `mako` - Notifications
- `hyprlock` - Lock screen
- `hypridle` - Idle management
- `wlogout` - Logout menu
- `grim` + `slurp` - Screenshots
- `wl-clipboard` - Clipboard
- `brightnessctl` - Brightness control
- `pamixer` / `pipewire` - Audio

### NVIDIA
- `nvidia-dkms` / `nvidia-open-dkms`
- `nvidia-utils`
- `nvidia-settings`
- `lib32-nvidia-utils`
- `libva-nvidia-driver`

---

*Last updated: 2026-01-21*
