# Changelog

## [Unreleased]

## [1.0.4] - 2026-01-25

### Fixed
- Migrated `windowrules.conf` to Hyprland v0.53 syntax standards.
  - Replaced deprecated `windowrulev2` with `windowrule`.
  - Updated regex matching to use `match:field criteria` syntax.
  - Added explicit boolean values (e.g., `float 1`) to all rules.
  - Removed unsupported `floating` matchers and unstable xwayland rules.

### Pending Tasks
- [x] Change notification background (Dunst) to black
- [x] Set wallpaper selector search bar background to black
- [x] Implement randomized wallpaper transition animations
- [x] Implement wallpaper selector with thumbnails (Super+W)
- [x] Update Waybar icons and add new modules (hostname, gpu, memory, etc.)
- [x] Implement theme name island in Waybar
- [x] Ensure Waybar styling follows "island" design with black backgrounds
- [x] Verify solutions are up-to-date and optimal
- [x] Ensure installer includes new Waybar/Wofi scripts and dependencies
- [x] Reorganize Waybar islands (clock far right; battery before; IP+theme left)
- [x] Update wallpaper picker behavior (keep Super+W)
- [x] Update Sofi behavior and dimensions
- [x] Update logout menu and add a new shortcut
- [x] Update installer for any new dependencies
- [x] Evaluate and apply 120fps animations where possible
- [x] Reduce Waybar font size slightly and add scale menu (75%/80%)
- [x] Fix wallpaper picker thumbnails layout (style cards)
- [x] Fix rofi launcher theming ( readable text)
- [x] Improve logout menu layout and icons (wlogout)
- [x] Improve wallpaper cards (single background + no search bar) and fix selection
- [x] Make rofi drun icons rounded and ensure white text on black
- [x] Fix logout icons rendering (remove red background issue)
- [x] Add required deps for rofi/wlogout thumbnails (jq, imagemagick, librsvg)

### Completed
- [x] Update Waybar icons to user-specified icons
- [x] Add theme name island to Waybar
- [x] Wallpaper selector opens correctly

---

## [1.0.3] - 2026-01-22

### Added
- Theme name island in Waybar
- New Waybar icons

---

## [1.0.2] - 2026-01-22

### Added
- Kitty theme integration
- KDE kwallet support

---

## [1.0.0] - 2026-01-21

### Added
- Initial release
