# Hyprland Configuration Roadmap

## Research and Planning <!-- phase:research-planning -->

- [x] Research most popular Hyprland configurations (#42)
- [x] Analyze project color references (13 schemes) (#43)
- [x] Research best practices for NVIDIA RTX 4060/Wayland (#44)
- [x] Create roadmap.md (#45)

## Base Structure <!-- phase:base-structure -->

- [x] Create project directory structure (#46)
  - [x] `hypr/` - Main Hyprland configuration
  - [x] `waybar/` - Status bar
  - [x] `wofi/` - App launcher
  - [x] `kitty/` - Terminal (integrated via external script)
  - [x] `dunst/` - Notifications
  - [x] `themes/` - Color schemes
  - [x] `wallpapers/` - Wallpapers
  - [x] `scripts/` - Helper scripts

## Hyprland Configuration <!-- phase:hyprland-config -->

- [x] Create main `hypr/hyprland.conf` (#47)
- [x] Configure monitors and resolution (#48)
- [x] Configure keybindings (#49)
- [x] Configure animations and visual effects (#50)
- [x] Configure window decorations (#51)
- [x] Configure workspaces (#52)
- [x] Configure window rules (#53)
- [x] Configure gestures (touchpad/touchscreen) (#54)
- [x] Configure NVIDIA environment variables (#55)
- [x] Configure autostart applications (#56)

## Additional Components <!-- phase:additional-components -->

- [x] Configure Waybar (status bar) (#57)
  - [x] Modules: workspaces, clock, battery, network, audio, etc.
  - [x] CSS styles with project colors
- [x] Configure Wofi (app launcher) (#58)
- [x] Configure Kitty (via integrated script) (#59)
- [x] Configure Dunst (notifications) (#60)
- [x] Configure swww/hyprpaper (wallpapers) (#61)
- [x] Configure wlogout (logout screen) (#62)
- [x] Configure hyprlock (lock screen) (#63)
- [x] Configure hypridle (idle management) (#64)

## Color Schemes <!-- phase:color-schemes -->

- [x] Create dynamic theme system (#65)
- [x] Implement 13 color schemes: (#66)
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
- [x] Script to switch between themes (#67)

## Installation Script <!-- phase:installation-script -->

- [x] Create `install.sh` with: (#68)
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

- [x] Create complete README.md with: (#69)
  - [x] Project description
  - [x] System requirements
  - [x] Installation guide
  - [x] Configuration guide
  - [x] Keybindings
  - [x] Available color schemes
  - [x] Common troubleshooting
  - [x] Credits and license

## Verification and Testing <!-- phase:verification-testing -->

- [x] Verify file structure (37 files created) (#70)
- [x] Test installation on real system (#71)

## Multi-Monitor & GPU Performance <!-- phase:multi-monitor-gpu -->

- [x] Create `workspaces.conf` (workspace rules, smart gaps, scratchpads) (#72)
- [x] Add multi-monitor workspace binding templates (#73)
- [x] Add multi-monitor keybinds (SUPER+ALT combos) (#74)
- [x] Create `gpu-mode.sh` (silent/normal/turbo, auto-detect GPU limits) (#75)
- [x] Add GPU mode Waybar module with JSON output (#76)
- [x] Add GPU mode Rofi/Wofi menu selector (#77)
- [x] Add GPU keybinds (SUPER+F9) (#78)
- [x] Update `README.md` with full documentation (#79)
- [x] Update `hyprland.conf` with multi-monitor examples (#80)
- [x] Test on RTX 5060 laptop (#81)
- [x] Test on RTX 4060 laptop (#82)

## Installer Robustness <!-- phase:installer-robustness -->

- [ ] Add full Fedora package list (currently missing many packages vs Arch and X) (#83)
- [ ] Add openSUSE support to `install.sh` (#84)
- [ ] Complete distribution detection for Debian-based (build from source flow) (#85)
- [ ] Sync `uninstall.sh` with all installed components (missing rofi, wlogout, hyprlock, hypridle) (#86)
- [ ] Create `update.sh` to pull latest dotfiles without full reinstall (#87)
- [ ] Remove root fix scripts from project root (`fix_hypr.py`, `force_fix.py`, `restore_hypr.py`, `fix_migration_errors.py`) (#88)
- [ ] Add `--dry-run` flag to `install.sh` (preview changes without applying) (#89)
- [ ] Add version pinning/tagging for releases (#90)

## CI & Quality <!-- phase:ci-quality -->

- [ ] Add ShellCheck linting for all `.sh` scripts (#91)
- [ ] Add Python linting for helper scripts (#92)
- [ ] Add CI workflow to validate `install.sh --dry-run` on Arch container (#93)
- [ ] Add CI workflow to validate theme JSON/config syntax (#94)
- [ ] Add CHANGELOG.md auto-generation from commits (#95)

## UX & Desktop Polish <!-- phase:ux-desktop-polish -->

- [ ] Migrate Wofi to Rofi fully (Wofi is unmaintained) (#96)
- [ ] Add clipboard manager integration (cliphist + Rofi picker) (#97)
- [ ] Add media player widget to Waybar (playerctl) (#98)
- [ ] Add power profile integration (power-profiles-daemon or TLP) (#99)
- [ ] Verify XDG portals configuration (file picker, screen sharing) (#100)
- [ ] Add OSD notifications for brightness/volume changes (#101)
- [x] Leave just few wallpapers and add the possibility to add more through the release XWall package (#102)
