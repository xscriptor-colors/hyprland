# Hyprland Configuration Roadmap

## Research and Planning <!-- phase:research-planning -->

- [x] Research most popular Hyprland configurations
- [x] Analyze project color references (13 schemes)
- [x] Research best practices for NVIDIA RTX 4060/Wayland
- [x] Create roadmap.md

## Base Structure <!-- phase:base-structure -->

- [x] Create project directory structure
  - [x] `hypr/` - Main Hyprland configuration
  - [x] `waybar/` - Status bar
  - [x] `wofi/` - App launcher
  - [x] `kitty/` - Terminal (integrated via external script)
  - [x] `dunst/` - Notifications
  - [x] `themes/` - Color schemes
  - [x] `wallpapers/` - Wallpapers
  - [x] `scripts/` - Helper scripts

## Hyprland Configuration <!-- phase:hyprland-config -->

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

## Additional Components <!-- phase:additional-components -->

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

## Color Schemes <!-- phase:color-schemes -->

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

## Installation Script <!-- phase:installation-script -->

- [x] Create `install.sh` with:
  - [ ] Distribution detection (Arch, Fedora, Debian, openSUSE)
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

## Documentation <!-- phase:documentation -->

- [x] Create complete README.md with:
  - [x] Project description
  - [x] System requirements
  - [x] Installation guide
  - [x] Configuration guide
  - [x] Keybindings
  - [x] Available color schemes
  - [x] Common troubleshooting
  - [x] Credits and license

## Verification and Testing <!-- phase:verification-testing -->

- [x] Verify file structure (37 files created)
- [ ] Test installation on real system

## Multi-Monitor & GPU Performance <!-- phase:multi-monitor-gpu -->

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
