# Multi-Monitor Setup

## Manual Configuration

1. Connect your external monitor
2. Identify your monitors: `hyprctl monitors all`
3. Edit `~/.config/hypr/hyprland.conf` -- uncomment and adjust monitor lines
4. Edit `~/.config/hypr/workspaces.conf` -- replace `desc:` values with your monitor descriptions
5. Reload configuration: SUPER + SHIFT + R

## Monitor Manager

Use the Rofi-based monitor manager: SUPER + ALT + M

Available actions:
- Position external display (left, right, above, below)
- Mirror displays
- Use only primary or only external display
- Change refresh rate per monitor
- View monitor info

## Keybindings

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

## Workspace Binding

Workspaces can be bound to specific monitors in `~/.config/hypr/workspaces.conf`:

```
workspace = 1, monitor:desc:Your Monitor Description, default:true
workspace = 2, monitor:desc:Your Monitor Description
```

Use `hyprctl monitors all` to get the description string for each monitor.
