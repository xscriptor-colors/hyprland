<h1 align="center"> Hyprland X Configuration</h1>

<div align="center">

![Hyprland](https://xscriptordev.github.io/badges/desktops/hyprland.svg)
![NVIDIA](https://xscriptordev.github.io/badges/hardware/nvidia.svg)
![Arch](https://xscriptordev.github.io/badges/os/arch.svg) ![X](https://xscriptordev.github.io/badges/os/x.svg) ![shell](https://xscriptordev.github.io/badges/languages/shell.svg) ![mit](https://xscriptordev.github.io/badges/licenses/mit.svg) 

**A premium, modern, and complete configuration for Hyprland**

*13 color schemes - Optimized NVIDIA support - Automated installation*

</div>

<p align="center"><img src="./assets/icon.png" width="100" alt="Xscriptor logo" /></p>

---


<h1 align="center"> Previews </h1>

<p align="center">
  <a href="./assets/previews/preview02.png">
    <img src="./assets/previews/preview02.png" alt="Main preview" width="850"/>
  </a>
</p>

<details>
  <summary>More previews</summary>

  <table>
    <tr>
      <td align="center">
        <a href="./assets/previews/preview01.png">
          <img src="./assets/previews/preview01.png" alt="Preview 2" width="380"/>
        </a>
      </td>
      <td align="center">
        <a href="./assets/previews/preview03.png">
          <img src="./assets/previews/preview03.png" alt="Preview 3" width="380"/>
        </a>
      </td>
      <td align="center">
        <a href="./assets/previews/preview04.png">
          <img src="./assets/previews/preview04.png" alt="Preview 4" width="380"/>
        </a>
      </td>
    </tr>
  </table>
</details>

## Features

- **13 Color Themes** - From neon cyberpunk to elegant minimalism
- **NVIDIA Support** - Optimized for RTX 50xx, 40xx, 30xx, 20xx, and GTX series
- **GPU Performance Modes** - Switch between silent, normal, and turbo (NVIDIA)
- **Multi-Monitor** - Per-monitor workspace binding, smart workspace transitions
- **Monitor Manager** - Rofi menu to change layout, position, and refresh rate
- **Automated Installation** - Single command to configure everything
- **Premium Design** - Glassmorphism, smooth animations, and blur effects
- **Intuitive Keybindings** - GNOME/Windows style for easy transition
- **Smart Gaps** - Borders and gaps auto-hide with single window
- **Named Scratchpads** - Quick-toggle terminal, files, and music
- **Hyprlock** - Lock screen with blur and themes
- **Modular** - Configuration split into files for easy customization

---

## Color Schemes

| Theme | Preview | Description |
|-------|---------|-------------|
| **X** | Purple/Pink/Green | Main theme with magenta accents |
| **Miami** | Black/Pink/Cyan | Cyberpunk/Retrowave |
| **Seul** | Black/Pink/Cyan | Asian neon |
| **Paris** | Black/Pink/Blue | Elegant pastel blue |
| **Tokio** | Brown/Orange/Purple | Warm orange accents |
| **Oslo** | Blue/Red/Green | Nordic blue |
| **Praha** | Black/Red/Purple | Dracula-inspired |
| **Bogota** | Black/Cyan/Green | Vibrant cyan |
| **Madrid** | Black/Red/Green | Intense Spanish red |
| **Lahabana** | Brown/Pink/Green | Tropical lime green |
| **Helsinki** | White/Teal/Purple | Light Nordic theme |
| **Berlin** | Black/White/White | Elegant monochrome |
| **London** | Black/Gray/Gray | Subtle grayscale |

---

## Requirements

### System
- **Distribution**: Arch Linux (or derivatives: EndeavourOS, Manjaro, CachyOS, etc.)
- **Kernel**: Linux 6.x+ recommended
- **RAM**: 4GB minimum, 8GB+ recommended

### GPU
| GPU | Status | Notes |
|-----|--------|-------|
| **NVIDIA RTX 50xx** | Supported | `nvidia-dkms` driver recommended |
| **NVIDIA RTX 40xx** | Supported | `nvidia-dkms` driver recommended |
| **NVIDIA RTX 30xx** | Supported | `nvidia-dkms` driver recommended |
| **NVIDIA RTX 20xx** | Supported | `nvidia-dkms` driver |
| **NVIDIA GTX 16xx/10xx** | Supported | `nvidia-dkms` driver |
| **AMD** | Supported | Open source drivers |
| **Intel** | Supported | Open source drivers |

---

## Installation

### Quick Install

```bash
git clone https://github.com/xscriptordev/hyprland.git
cd hyprland
chmod +x install.sh
./install.sh
```

### Dotfiles Only (no system changes)

```bash
./install.sh --dotfiles-only
```

### NVIDIA Configuration Only

```bash
./install.sh --nvidia-only
```

---

## Keybindings

### Applications
| Shortcut | Action |
|----------|--------|
| `SUPER + Return` | Terminal (Kitty) |
| `SUPER + T` | Terminal (Kitty) |
| `SUPER + Q` | Close window |
| `SUPER + SHIFT + Q` | Exit Hyprland |
| `SUPER + D` | App launcher (Rofi, fallback to Wofi) |
| `SUPER + R` | Run command (Rofi, fallback to Wofi) |
| `SUPER + E` | File manager (Nautilus) |
| `SUPER + B` | Browser (Firefox) |
| `SUPER + C` | Code editor (VSCode) |
| `SUPER + .` | Emoji picker |

### Window Management
| Shortcut | Action |
|----------|--------|
| `SUPER + V` | Toggle floating |
| `SUPER + Space` | Toggle floating |
| `SUPER + F` | Fullscreen |
| `SUPER + M` | Maximize |
| `SUPER + G` | Center window |
| `SUPER + SHIFT + Space` | Pin window |
| `SUPER + P` | Pseudo-tile |
| `SUPER + J` | Toggle split |
| `ALT + Tab` | Cycle windows (bring to top) |

### Focus and Movement
| Shortcut | Action |
|----------|--------|
| `SUPER + Arrow Keys` | Move focus |
| `SUPER + H/J/K/L` | Move focus (vim) |
| `SUPER + SHIFT + Arrows` | Move window |
| `SUPER + CTRL + Arrows` | Resize window |

### Workspaces
| Shortcut | Action |
|----------|--------|
| `SUPER + 1-9,0` | Go to workspace 1-10 |
| `SUPER + SHIFT + 1-9,0` | Move window to workspace |
| `SUPER + CTRL + 1-9,0` | Move window silently (stay on current) |
| `SUPER + Page Up/Down` | Previous/Next workspace |
| `SUPER + Mouse Scroll` | Change workspace |
| `SUPER + Tab` | Previous workspace (stays on current monitor) |
| `SUPER + S` | Toggle terminal scratchpad |
| `SUPER + SHIFT + S` | Move window to terminal scratchpad |
| `SUPER + A` | Toggle file manager scratchpad |
| `SUPER + SHIFT + A` | Move window to file manager scratchpad |

### Multi-Monitor
| Shortcut | Action |
|----------|--------|
| `SUPER + ALT + I` | Focus next monitor |
| `SUPER + ALT + U` | Focus previous monitor |
| `SUPER + ALT + SHIFT + I` | Move window to next monitor |
| `SUPER + ALT + SHIFT + U` | Move window to previous monitor |
| `SUPER + ALT + O` | Swap workspaces between monitors |
| `SUPER + ALT + P` | Move workspace to next monitor |
| `SUPER + ALT + M` | Monitor manager (position/frequency) |
| `SUPER + ALT + SHIFT + M` | Show monitor info |

### GPU Performance (NVIDIA)
| Shortcut | Action |
|----------|--------|
| `SUPER + ALT + G` | Cycle GPU mode: silent / normal / turbo |
| `SUPER + ALT + SHIFT + G` | Open GPU mode selector (Rofi) |

### Screenshots
| Shortcut | Action |
|----------|--------|
| `Print` | Full screenshot |
| `SUPER + Print` | Area screenshot |
| `SUPER + SHIFT + S` | Area screenshot |
| `SUPER + SHIFT + Print` | Window screenshot |

### Power and Lock
| Shortcut | Action |
|----------|--------|
| `SUPER + L` | Lock screen |
| `SUPER + Escape` | Power menu (logout/reboot/shutdown/etc.) |
| `SUPER + SHIFT + L` | Power menu (wlogout) |
| `SUPER + CTRL + L` | Suspend |
| `SUPER + CTRL + SHIFT + L` | Shutdown |

### Brightness
| Shortcut | Action |
|----------|--------|
| `XF86MonBrightnessUp` | Brightness up |
| `XF86MonBrightnessDown` | Brightness down |
| `SUPER + F3` | Brightness up (fallback shortcut) |
| `SUPER + F2` | Brightness down (fallback shortcut) |

**Notes**
- Laptop/internal display: uses `brightnessctl`.
- External monitors: supports DDC/CI via `ddcutil` (may require enabling DDC/CI in the monitor OSD and I2C permissions).

### Utilities
| Shortcut | Action |
|----------|--------|
| `SUPER + ALT + T` | Theme switcher |
| `SUPER + W` | Wallpaper selector |
| `SUPER + Z` | Scale menu (75%/80%/100%) |
| `SUPER + SHIFT + C` | Color picker |
| `SUPER + SHIFT + V` | Clipboard history |
| `SUPER + N` | Show notification |
| `SUPER + SHIFT + N` | Clear notifications |
| `SUPER + SHIFT + B` | Reload Waybar |
| `SUPER + SHIFT + R` | Reload Hyprland |

### Volume (without media keys)
| Shortcut | Action |
|----------|--------|
| `SUPER + =` | Volume up |
| `SUPER + -` | Volume down |
| `SUPER + Backspace` | Mute |

---

## Structure

```
~/.config/
├── hypr/
│   ├── hyprland.conf    # Main config
│   ├── keybinds.conf    # Keybindings
│   ├── animations.conf  # Animations
│   ├── windowrules.conf # Window rules
│   ├── workspaces.conf  # Workspace rules & multi-monitor
│   ├── env.conf         # Variables (NVIDIA optimized)
│   ├── autostart.conf   # Startup apps
│   ├── theme.conf       # Current theme
│   ├── themes/          # All themes
│   ├── scripts/         # Helper scripts
│   └── wallpapers/      # Wallpapers
├── waybar/              # Status bar
├── wofi/                # App launcher
├── rofi/                # App launcher themes
├── wlogout/             # Logout menu (layout/style/icons)
└── dunst/               # Notifications
```

---

## Customization

### Change Theme
```bash
~/.config/hypr/scripts/theme-switcher.sh
# Or use: SUPER + ALT + T
```

### Change Wallpaper
```bash
~/.config/hypr/scripts/wallpaper.sh
# Or use: SUPER + W
```

### Modify Keybindings
Edit `~/.config/hypr/keybinds.conf`

### Add Autostart Apps
Edit `~/.config/hypr/autostart.conf`

### Multi-Monitor Setup

1. Connect your external monitor
2. Identify your monitors:
   ```bash
   hyprctl monitors all
   ```
3. Edit `~/.config/hypr/hyprland.conf` — uncomment and adjust the monitor lines
4. Edit `~/.config/hypr/workspaces.conf` — uncomment the workspace bindings and replace the `desc:` values with your monitor descriptions
5. Reload: `SUPER + SHIFT + R`

**Example for laptop (eDP-1) + external (HDMI-A-1):**
```ini
# hyprland.conf
monitor = eDP-1, preferred, 0x0, 1
monitor = HDMI-A-1, 1920x1080@60, 1920x0, 1

# workspaces.conf
workspace = 1, monitor:desc:BOE 0x0BCA (eDP-1), default:true
workspace = 6, monitor:desc:Samsung Electric Company ... (HDMI-A-1), default:true
```

### GPU Optimus Modes (EnvyControl)

Safely switch between three graphics modes using `envycontrol` for NVIDIA Optimus laptops:

| Mode | Effect | Use Case |
|------|--------|----------|
| **Integrated** | NVIDIA completely powered off | Maximum battery life, coding, browsing |
| **Hybrid** | Intel/AMD drives display, NVIDIA offloads | Balanced everyday use (Default) |
| **NVIDIA** | NVIDIA drives everything | Gaming, rendering, external monitors |

> **Note:** Changing modes requires a **reboot** or logging out to take effect.

**Control options:**
- **Waybar**: Click the GPU mode indicator to cycle, right-click for menu
- **Rofi menu**: `SUPER + ALT + SHIFT + G`
- **Keybind**: `SUPER + ALT + G` to cycle modes
- **Terminal**:
  ```bash
  ~/.config/hypr/scripts/gpu-mode.sh integrated
  ~/.config/hypr/scripts/gpu-mode.sh hybrid
  ~/.config/hypr/scripts/gpu-mode.sh nvidia
  ```

### Monitor Management

Manage monitor position, layout, and refresh rate with a Rofi menu:

| Feature | Options |
|---------|--------|
| **Layout** | External on right / left / above / below |
| **Mirror** | Mirror both displays |
| **Single** | Only primary / only external |
| **Refresh Rate** | 60 / 90 / 120 / 144 / 165 / 240 Hz |

**Control options:**
- **Keybind**: `SUPER + ALT + M` to open menu
- **Info**: `SUPER + ALT + SHIFT + M` to show current monitor details
- **Terminal**:
  ```bash
  ~/.config/hypr/scripts/monitor-manager.sh
  ~/.config/hypr/scripts/monitor-manager.sh info
  ```

---

## Troubleshooting

### NVIDIA: Black screen or flickering
1. Verify that `nvidia_drm.modeset=1` is in kernel params
2. Make sure to reboot after installing drivers
3. Check services: `systemctl status nvidia-suspend`

### Waybar not showing
```bash
killall waybar
waybar &
```

### Wofi not responding
```bash
killall wofi
```

### Hyprlock not working
Verify hyprlock is installed:
```bash
pacman -S hyprlock
```

---

## Credits

- Inspired by [ML4W Dotfiles](https://github.com/mylinuxforwork/dotfiles)
- [Hyprland](https://hyprland.org/) - The window manager
- Color schemes based on world cities

---

## License

(MIT License)[./LICENSE]

---

<div align="center">

**[X](https://github.com/xscriptordev)**

</div>
