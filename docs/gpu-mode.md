# GPU Mode Switching (NVIDIA Optimus)

Supported on NVIDIA Optimus laptops. Uses `envycontrol` to switch between GPU power modes.

## Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| Integrated | NVIDIA powered off | Maximum battery life |
| Hybrid | iGPU drives display, NVIDIA offloads | Balanced (default) |
| NVIDIA | Dedicated GPU drives everything | Gaming, rendering |

## Controls

- SUPER + ALT + G -- Cycle through modes
- SUPER + ALT + SHIFT + G -- Open Rofi mode selector

A reboot or logout is required after switching modes.

## Installation

The installer can optionally set up a passwordless sudo rule for envycontrol:

```
%wheel ALL=(ALL) NOPASSWD: /usr/bin/envycontrol -s *
```

This allows the `gpu-mode.sh` script to switch modes without password prompts.

## Status

The `gpu-mode.sh status` command outputs JSON for Waybar integration, showing the current mode, icon, and tooltip.
