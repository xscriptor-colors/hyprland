# Matugen Integration

Matugen (Material You color generator) is the sole theming engine. It analyzes the current wallpaper and generates a cohesive color palette applied across all UI components.

## Configuration

Main config: `~/.config/matugen/config.toml`. It defines templates mapping each application to an `input_path` (template with placeholders) and `output_path` (rendered file).

## Color Flow

1. Wallpaper changed (via wallpaper picker or `awww`)
2. `matugen_reload.sh` copies wallpaper to persistent cache, runs `matugen image <wallpaper> --source-color-index 0`
3. Matugen renders all templates
4. `reload.sh` triggers QuickShell color reload and SDDM color sync

## File: matugen_reload.sh

Located at `config/hypr/scripts/quickshell/wallpaper/matugen_reload.sh`. This script:
- Copies the current wallpaper to `~/.cache/quickshell/wallpaper_picker/current_wallpaper.png` for persistence across reboots
- Runs `matugen image` against the cached wallpaper
- Triggers `reload.sh` for QuickShell and SDDM update

## Affected Components

- **QuickShell QML widgets** -- `qs_colors.json` loaded by `MatugenColors.qml` singleton
- **Kitty terminal** -- `kitty-matugen-colors.conf` sourced from main kitty.conf
- **Neovim** -- `matugen_colors.lua` loaded by theme system
- **Cava** -- `colors` file for audio visualizer palette
- **SwayOSD** -- `style.css` for on-screen display styling
- **GTK** -- `colors-gtk.css` for GTK3/4 applications
- **Qt5/Qt6** -- `matugen.conf` and `matugen-style.qss` for Qt application theming
- **Hyprland** -- `colors.conf` for window decorations, borders
- **SDDM** -- `sddm-colors.qml` for the login screen theme

## Template Directory

All templates are at `config/matugen/templates/`. Each uses `{{key}}` placeholders that Matugen fills with extracted colors.
