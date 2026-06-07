<h1 align="center">Hyprland modernizeX</h1>

<div align="center">

**Hyprland configuration for the X environment (Arch Linux spin)**

*Based on imperative-dots by ilyamiro -- adapted, extended, and customized*



</div>

<a href="https://imgur.com/0fm1MOy">
<img src="https://i.imgur.com/ahSvDyS.gif" width="900" alt="Demo" >
</a>
<p align="center"><em>Gif preview, follow the link to see the details.</em></p>




## Table of Contents

- [About](#about)
- [Status](#status)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Keybindings](#keybindings)
- [Structure](#structure)
- [Customization](#customization)
- [Acknowledgments](#acknowledgments)




## About

This configuration is derived from [imperative-dots](https://github.com/ilyamiro/imperative-dots) by ilyamiro, one of the most comprehensive Hyprland setups available. This fork is being updated and adapted for use in the X environment (an Arch Linux spin) with a mix of upstream changes and custom modifications.

Some features from imperative-dots are preserved and updated. Others have been reworked or replaced with original implementations tailored to this environment. The goal is to maintain compatibility with upstream where possible while introducing variations that suit the X desktop experience.



## Status

This configuration is under active development. Components from imperative-dots are being progressively integrated, tested, and customized. Expect changes as the migration progresses.



## Features

- QuickShell QML-based interface (TopBar, widgets, app launcher, wallpaper picker)
- Dynamic color theming via Matugen (Material You colors from wallpaper)
- App icons displayed on workspace pills
- Wallpaper picker with local files and DuckDuckGo image search
- Network manager, Bluetooth, volume, and battery widgets
- Calendar with weather integration
- Clipboard manager with history
- Music player controls (MPRIS)
- Focus time tracker
- SDDM theme with dynamic colors
- Automated installation script
- Theme switcher for kitty, waybar, and Hyprland colors
- 13 city-inspired color themes
- GPU performance mode switching (NVIDIA)
- Multi-monitor support with monitor manager
- SwayOSD on-screen display for volume and brightness
- Named scratchpads for terminal, files, and apps
- Hyprlock integration with blur and themes



## Requirements

### System

- **Distribution**: Arch Linux or derivatives (EndeavourOS, Manjaro, CachyOS, Garuda, X)
- **Kernel**: Linux 6.x or newer recommended
- **RAM**: 4 GB minimum, 8 GB or more recommended


## Installation

### Quick Install

```bash
git clone https://github.com/xscriptor/hyprland.git
cd hyprland
git checkout modernizex
chmod +x install.sh
./install.sh
```

### Dotfiles Only (no system-wide changes)

```bash
./install.sh --dotfiles-only
```

### NVIDIA Configuration Only

```bash
./install.sh --nvidia-only
```

The installer will:
1. Detect your distribution and GPU
2. Install required packages (via yay or paru on Arch)
3. Configure NVIDIA drivers (if applicable) with kernel parameters
4. Back up existing configurations
5. Deploy all configuration files
6. Optionally download a wallpaper collection
7. Generate initial Matugen color scheme



## Keybindings

### Applications

| Shortcut | Action |
|----------|--------|
| `SUPER + Return` | Terminal (Kitty) |
| `SUPER + D` | App launcher (QuickShell) |
| `SUPER + E` | File manager (Nautilus) |
| `SUPER + F` | Browser (Firefox) |
| `SUPER + period` | Emoji picker |

### QuickShell Widgets

| Shortcut | Action |
|----------|--------|
| `SUPER + Q` | Toggle music player |
| `SUPER + C` | Toggle clipboard manager |
| `SUPER + P` | Toggle movies widget |
| `SUPER + B` | Toggle battery status |
| `SUPER + W` | Toggle wallpaper picker |
| `SUPER + S` | Toggle calendar |
| `SUPER + N` | Toggle network panel |
| `SUPER + V` | Toggle volume control |
| `SUPER + H` | Toggle guide panel |
| `SUPER + SHIFT + S` | Toggle settings panel |
| `SUPER + SHIFT + T` | Toggle focus time tracker |

### Window Management

| Shortcut | Action |
|----------|--------|
| `ALT + F4` | Close active window |
| `SUPER + Space` | Toggle floating |
| `SUPER + SHIFT + Space` | Pin window |
| `SUPER + F` | Fullscreen |
| `SUPER + M` | Maximize (fullscreen, 1) |
| `SUPER + G` | Center floating window |
| `SUPER + J` | Toggle split layout |
| `ALT + Tab` | Cycle through windows |

### Focus and Movement

| Shortcut | Action |
|----------|--------|
| `SUPER + Arrow Keys` | Move focus |
| `SUPER + H/J/K/L` | Move focus (vim-style) |
| `SUPER + SHIFT + Arrows` | Move window |
| `SUPER + SHIFT + H/J/K/L` | Move window (vim-style) |
| `SUPER + CTRL + Arrows` | Resize window |
| `SUPER + CTRL + H/J/K/L` | Resize window (vim-style) |

### Workspaces

| Shortcut | Action |
|----------|--------|
| `SUPER + 1-9,0` | Go to workspace 1-10 |
| `SUPER + SHIFT + 1-9,0` | Move window to workspace |
| `SUPER + Page Up/Down` | Previous / Next workspace |
| `SUPER + Mouse Scroll` | Change workspace |
| `SUPER + Tab` | Previous workspace (current monitor) |
| `SUPER + A` | Toggle files scratchpad |
| `SUPER + SHIFT + A` | Move window to files scratchpad |

### Lock / Power

| Shortcut | Action |
|----------|--------|
| `SUPER + L` | Lock screen |
| `SUPER + Escape` | Exit Hyprland |
| `SUPER + SHIFT + L` | Power menu (wlogout) |
| `SUPER + CTRL + L` | Suspend |
| `SUPER + CTRL + SHIFT + L` | Shutdown |

### Screenshots

| Shortcut | Action |
|----------|--------|
| `Print` | Screenshot (area) |
| `SHIFT + Print` | Screenshot (edit) |
| `SUPER + Print` | Full screenshot |
| `SUPER + SHIFT + Print` | Full screenshot (edit) |

### Multimedia

| Shortcut | Action |
|----------|--------|
| `XF86AudioRaiseVolume` | Volume up |
| `XF86AudioLowerVolume` | Volume down |
| `XF86AudioMute` | Mute toggle |
| `XF86MonBrightnessUp` | Brightness up |
| `XF86MonBrightnessDown` | Brightness down |
| `XF86AudioPlay/Pause` | Play / Pause |
| `XF86AudioNext` | Next track |
| `XF86AudioPrev` | Previous track |

### Theme and Wallpaper

| Shortcut | Action |
|----------|--------|
| `SUPER + W` | Wallpaper picker |
| `SUPER + ALT + T` | Theme switcher |
| `SUPER + Z` | Scale menu (75% / 80% / 100%) |
| `SUPER + R` | Reload QuickShell colors |
| `SUPER + SHIFT + R` | Reload Hyprland config |

### GPU Performance (NVIDIA)

| Shortcut | Action |
|----------|--------|
| `SUPER + ALT + G` | Cycle GPU mode (silent / normal / turbo) |
| `SUPER + ALT + SHIFT + G` | Open GPU mode selector |

### Multi-Monitor

| Shortcut | Action |
|----------|--------|
| `SUPER + ALT + I` | Focus next monitor |
| `SUPER + ALT + U` | Focus previous monitor |
| `SUPER + ALT + SHIFT + I` | Move window to next monitor |
| `SUPER + ALT + SHIFT + U` | Move window to previous monitor |
| `SUPER + ALT + O` | Swap workspaces between monitors |
| `SUPER + ALT + P` | Move workspace to next monitor |
| `SUPER + ALT + M` | Open monitor manager |
| `SUPER + ALT + SHIFT + M` | Show monitor info |



## Structure

```
~/.config/
├── hypr/
│   ├── hyprland.conf          # Main configuration
│   ├── keybinds.conf          # Keybindings
│   ├── animations.conf        # Animation settings
│   ├── windowrules.conf       # Window rules
│   ├── workspaces.conf        # Workspace rules and multi-monitor
│   ├── env.conf               # Environment variables (NVIDIA optimized)
│   ├── autostart.conf         # Startup applications
│   ├── theme.conf             # Current theme link
│   ├── colors.conf            # Matugen-generated colors
│   ├── themes/                # City color themes
│   ├── templates/             # Template files
│   ├── config/                # Additional config (variables, settings, rules)
│   ├── scripts/
│   │   ├── quickshell/        # QML-based UI components
│   │   │   ├── Shell.qml      # Main shell entry point
│   │   │   ├── TopBar.qml     # Top bar with workspaces, clock, system tray
│   │   │   ├── Main.qml       # Widget overlay manager
│   │   │   ├── Floating.qml   # Floating sidebar
│   │   │   ├── wallpaper/     # Wallpaper picker with Matugen integration
│   │   │   ├── applauncher/   # Application launcher
│   │   │   ├── network/       # Network manager widget
│   │   │   ├── volume/        # Volume control widget
│   │   │   ├── battery/       # Battery status widget
│   │   │   ├── music/         # Music player widget
│   │   │   ├── calendar/      # Calendar and weather
│   │   │   ├── clipboard/     # Clipboard manager
│   │   │   └── ...            # Other widgets
│   │   ├── qs_manager.sh      # QuickShell IPC manager
│   │   ├── workspaces.sh      # Workspace data daemon
│   │   ├── init.sh            # Initialization script
│   │   ├── theme-switcher.sh  # Theme switcher
│   │   └── ...                # Other utility scripts
│   └── wallpapers/            # Wallpaper collection
├── kitty/                     # Terminal configuration (with themes)
├── waybar/                    # Status bar (legacy, not auto-started)
├── rofi/                      # Application launcher themes (legacy)
├── wlogout/                   # Logout menu
├── dunst/                     # Notification daemon (legacy)
├── cava/                      # Audio visualizer
├── matugen/                   # Matugen templates and configuration
└── swayosd/                   # On-screen display styles
```



## Customization

### Theme and Wallpaper

- Change wallpaper: `SUPER + W` (opens the QuickShell wallpaper picker)
- Change theme (kitty, waybar, Hyprland): `SUPER + ALT + T`
- Wallpapers are stored in `~/.config/hypr/wallpapers/`

### Modifying Configuration

- Keybindings: edit `~/.config/hypr/keybinds.conf`
- Autostart applications: edit `~/.config/hypr/autostart.conf`
- Environment variables: edit `~/.config/hypr/env.conf`
- UI settings (scale, workspace count): use the settings panel (`SUPER + SHIFT + S`)

### Multi-Monitor Setup

1. Connect your external monitor.
2. Identify your monitors: `hyprctl monitors all`
3. Edit `~/.config/hypr/hyprland.conf` -- uncomment and adjust monitor lines.
4. Edit `~/.config/hypr/workspaces.conf` -- replace `desc:` values with your monitor descriptions.
5. Reload configuration: `SUPER + SHIFT + R`

### GPU Mode Switching (NVIDIA Optimus)

Switch between integrated, hybrid, and NVIDIA-only modes using `envycontrol`:

| Mode | Effect | Use Case |
|------|--------|----------|
| Integrated | NVIDIA powered off | Maximum battery life, browsing, coding |
| Hybrid | iGPU drives display, NVIDIA offloads | Balanced everyday use (default) |
| NVIDIA | Dedicated GPU drives everything | Gaming, rendering, external monitors |

Controls:
- `SUPER + ALT + G` to cycle through modes
- `SUPER + ALT + SHIFT + G` to open the mode selector

Changing modes requires a reboot or logout to take effect.



## Acknowledgments

This configuration is based on [imperative-dots](https://github.com/ilyamiro/imperative-dots) by ilyamiro. The original project provided the foundation for the QuickShell-based UI, Matugen integration, and many of the QML widgets used here. This fork adapts and extends that work for the X environment, incorporating upstream changes where appropriate and introducing custom variations where the original design has been modified or replaced.

- [ilyamiro / imperative-dots](https://github.com/ilyamiro/imperative-dots) -- original project
- [Hyprland](https://hyprland.org/) -- the Wayland compositor
- [QuickShell](https://github.com/Quickshell/Quickshell) -- QML shell environment
- [Matugen](https://github.com/InioX/matugen) -- Material You color generation
- [awww](https://github.com/desuwa/awww) -- wallpaper daemon
- All upstream developers and the Hyprland community



<div align="center">
  <a href="./LICENSE">License</a>
  &nbsp;|&nbsp;
  <a href="./CODE_OF_CONDUCT.md">Code of Conduct</a>
  &nbsp;|&nbsp;
  <a href="./ROADMAP.md">Roadmap</a>
</div>
