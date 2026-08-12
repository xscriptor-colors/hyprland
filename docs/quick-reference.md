# Quick Reference

## Applications

| Shortcut | Action |
|----------|--------|
| SUPER + Return | Terminal (Kitty) |
| SUPER + D | App launcher |
| SUPER + E | File manager (Nautilus) |
| SUPER + F | Browser (Firefox) |
| SUPER + period | Emoji picker |
| SUPER + T | Spare terminal |
| SUPER + SHIFT + C | Color picker (hyprpicker) |

## QuickShell Widgets

| Shortcut | Action |
|----------|--------|
| SUPER + M | Toggle music player |
| SUPER + C | Toggle clipboard manager |
| SUPER + P | Toggle movie widget |
| SUPER + B | Toggle battery status |
| SUPER + W | Toggle wallpaper picker |
| SUPER + S | Toggle calendar |
| SUPER + N | Toggle network panel |
| SUPER + V | Toggle volume control |
| SUPER + H | Toggle guide panel |
| SUPER + SHIFT + S | Toggle settings panel |
| SUPER + SHIFT + E | Toggle settings panel on the Topbar tab |
| SUPER + SHIFT + T | Toggle focus time tracker |
| SUPER + U | Toggle system updater |
| SUPER + X | Toggle Stewart (ambient visualizer) |
| SUPER + Y | Toggle quick notes |
| SUPER + I | Toggle system monitor (CPU/RAM/disk) |
| SUPER + O | Toggle RSS reader |
| SUPER + ' | Toggle file search |

## Window Management

| Shortcut | Action |
|----------|--------|
| ALT + F4 | Close active window |
| SUPER + Space | Toggle floating |
| SUPER + SHIFT + Space | Pin window |
| SUPER + J | Toggle split layout |
| SUPER + G | Center floating window |
| ALT + Tab | Cycle through windows |

## Focus and Movement

| Shortcut | Action |
|----------|--------|
| SUPER + Arrow Keys | Move focus |
| SUPER + H/J/K/L | Move focus (vim-style) |
| SUPER + SHIFT + Arrows | Move window |
| SUPER + SHIFT + H/J/K/L | Move window (vim-style) |
| SUPER + CTRL + Arrows | Resize window |
| SUPER + CTRL + H/J/K/L | Resize window (vim-style) |

## Workspaces

| Shortcut | Action |
|----------|--------|
| SUPER + 1-9,0 | Go to workspace 1-10 |
| SUPER + SHIFT + 1-9,0 | Move window to workspace |
| SUPER + Page Up/Down | Previous / Next workspace |
| SUPER + Mouse Scroll | Change workspace |
| SUPER + Tab | Previous workspace (current monitor) |
| SUPER + A | Toggle files scratchpad |
| SUPER + SHIFT + A | Move window to files scratchpad |

## Lock / Power

| Shortcut | Action |
|----------|--------|
| SUPER + L | Lock screen |
| SUPER + Escape | Exit Hyprland |
| SUPER + SHIFT + L | Power menu |
| SUPER + CTRL + L | Suspend |
| SUPER + CTRL + SHIFT + L | Shutdown |

## Screenshots

| Shortcut | Action |
|----------|--------|
| Print | Screenshot overlay (area) |
| SHIFT + Print | Screenshot overlay (edit mode) |
| SUPER + Print | Full screenshot |
| SUPER + SHIFT + Print | Full screenshot (edit) |

## Multimedia

| Shortcut | Action |
|----------|--------|
| XF86AudioRaiseVolume | Volume up |
| XF86AudioLowerVolume | Volume down |
| XF86AudioMute | Mute toggle |
| XF86MonBrightnessUp | Brightness up |
| XF86MonBrightnessDown | Brightness down |
| XF86AudioPlay/Pause | Play / Pause |
| XF86AudioNext | Next track |
| XF86AudioPrev | Previous track |

## Display

| Shortcut | Action |
|----------|--------|
| SUPER + W | Wallpaper picker |
| SUPER + Z | Display scale picker (80% - 200%, scales apps and shell) |
| SUPER + SHIFT + Z | Display scale: one step up |
| SUPER + CTRL + Z | Display scale: one step down |
| SUPER + R | Reload QuickShell colors |
| SUPER + SHIFT + R | Reload Hyprland config |

## GPU (NVIDIA)

| Shortcut | Action |
|----------|--------|
| SUPER + ALT + G | Cycle GPU mode (silent / normal / turbo) |
| SUPER + ALT + SHIFT + G | Open GPU mode selector |

## Multi-Monitor

| Shortcut | Action |
|----------|--------|
| SUPER + ALT + I | Focus next monitor |
| SUPER + ALT + U | Focus previous monitor |
| SUPER + ALT + SHIFT + I | Move window to next monitor |
| SUPER + ALT + SHIFT + U | Move window to previous monitor |
| SUPER + ALT + O | Swap workspaces between monitors |
| SUPER + ALT + P | Move workspace to next monitor |
| SUPER + ALT + M | Open monitor manager |
| SUPER + ALT + SHIFT + M | Show monitor info |

## Key Scripts

| Script | Location | Purpose |
|--------|----------|---------|
| `qs_manager.sh` | `~/.config/hypr/scripts/` | IPC manager for QuickShell widgets |
| `screenshot.sh` | `~/.config/hypr/scripts/` | Screenshot + recording with virtual audio |
| `gpu-mode.sh` | `~/.config/hypr/scripts/` | NVIDIA Optimus mode switcher |
| `monitor-manager.sh` | `~/.config/hypr/scripts/` | Multi-monitor layout management |
| `workspaces.sh` | `~/.config/hypr/scripts/` | Workspace event listener daemon |
| `init.sh` | `~/.config/hypr/scripts/` | First-run wallpaper and color init |
