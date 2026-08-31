<h1 align="center"> Hyperland <em>XShell</em> <img src="https://raw.githubusercontent.com/xscriptor-colors/web/main/public/svg/icons/hyprland.svg?v=2" width="20" alt="Xscriptor logo" />
</h1>

<p align="center">
  <img src="https://img.shields.io/github/license/xscriptor-colors/hyprland?style=flat-square&color=blue" alt="License">
  <img src="https://img.shields.io/github/last-commit/xscriptor-colors/hyprland?style=flat-square&color=blueviolet" alt="Last Commit">
  <img src="https://img.shields.io/github/repo-size/xscriptor-colors/hyprland?style=flat-square&color=success" alt="Repo Size">
  <img src="https://img.shields.io/badge/Hyprland-v0.53+-8A2BE2?style=flat-square" alt="Hyprland">
  <img src="https://img.shields.io/badge/Arch_Linux-supported-1793D1?style=flat-square&logo=arch-linux" alt="Arch">
  <img src="https://img.shields.io/badge/X_Linux-supported-000000?style=flat-square" alt="X Linux">
  <img src="https://img.shields.io/badge/QuickShell-QML-FF6F00?style=flat-square" alt="QuickShell">
  <img src="https://img.shields.io/badge/Palettes-12-FF69B4?style=flat-square" alt="Palettes">
</p>

<p align="center">
  <em>
  QuickShell QML shell + 12-palette theming for Hyprland on X.
  </em>
</p>

<h2 align="center">Content</h2>

<p align="center">
  <a href="#quick-install">Quick Install</a> &middot;
  <a href="#features">Features</a> &middot;
  <a href="#customization">Customization</a> &middot;
  <a href="#quick-reference">Quick Reference</a> &middot;
  <a href="#structure">Structure</a> &middot;
  <a href="#documentation">Documentation</a> &middot;
  <a href="#acknowledgments">Acknowledgments</a> &middot;
  <a href="#x">X</a>
</p>

<img src="https://xscriptor-colors.github.io/web/images/gifs/hyprland/hyprland-demo-1.gif" width="900" alt="Demo">

<details>
  <summary>More...</summary>
  <br>
  <p align="center">
    <img src="https://xscriptor-colors.github.io/web/images/gifs/hyprland/hyprland-demo-2.gif" width="880" alt="demo">
  </p>
  <p align="center">
    <img src="https://xscriptor-colors.github.io/web/images/gifs/hyprland/hyprland-demo-4.gif" width="880" alt="demo">
  </p>
  <p align="center">
    <img src="https://xscriptor-colors.github.io/web/images/gifs/hyprland/hyprland-demo-3.gif" width="880" alt="demo">
  </p>
   <p align="center">
    <img src="https://xscriptor-colors.github.io/web/images/gifs/hyprland/hyprland-demo-4.gif" width="880" alt="demo">
  </p>
   <p align="center">
    <img src="https://xscriptor-colors.github.io/web/images/gifs/hyprland/hyprland-demo-5.gif" width="880" alt="demo">
  </p>
   <p align="center">
    <img src="https://xscriptor-colors.github.io/web/images/gifs/hyprland/hyprland-demo-6.gif" width="880" alt="demo">
  </p>
</details>

---

## Quick Install

<pre><code>git clone https://github.com/xscriptor-colors/hyprland.git
cd hyprland
chmod +x install.sh
./install.sh</code></pre>

<p><strong>Options:</strong> <code>--dotfiles-only</code> (config only), <code>--nvidia-only</code> (NVIDIA setup only).</p>

<p>The installer detects your distro and GPU, installs packages (Hyprland, QuickShell, SwayOSD, kitty, rofi, and more), backs up existing configs, deploys all dotfiles, optionally configures NVIDIA Optimus, installs the SDDM theme, and installs kitty / Neovim from their own repos (`xscriptor-colors/terminal`, `xscriptor-colors/nvim`).</p>

<hr>

<h2>Features</h2>

<ul>
  <li><strong>QuickShell QML UI</strong> -- App launcher, clipboard, calendar/weather, network, audio, battery, music (MPRIS), wallpaper picker, system monitor, RSS reader, file search, quick notes, focus timer, screen recording, QR scanner.</li>
  <li><strong>Lua Config</strong> -- Hyprland 0.55+ <code>hyprland.lua</code> modular config (env, colors, keybinds, animations, rules, autostart) with the active palette.</li>
  <li><strong>12-Palette Theming</strong> -- `dock/palettes` drive the bar, window borders, kitty, starship, VS Code (color + icons), SDDM and Neovim in real time via `theme-sync.sh`.</li>
  <li><strong>Modular Config</strong> -- Split across focused Lua modules. QuickShell reads <code>settings.json</code> for its widgets.</li>
  <li><strong>NVIDIA Optimus</strong> -- GPU mode switching (integrated/hybrid/nvidia) via keybind or Rofi.</li>
  <li><strong>Multi-Monitor</strong> -- Auto-detection at max refresh rate (Lua wildcard), Rofi-based position/resolution/refresh rate manager.</li>
  <li><strong>SDDM Theme</strong> -- <code>x</code> theme synced to the active palette with dynamic wallpaper background.</li>
  <li><strong>Screen Recording</strong> -- GPU capture with separate desktop/mic audio channels.</li>
  <li><strong>Neovim Config</strong> -- lazy.nvim, LSP (Mason), Treesitter; palette data from `dock/palettes`, config from `xscriptor-colors/nvim`.</li>
</ul>

<hr>

<h2>Customization</h2>

<p><code>SUPER + W</code> wallpaper picker &middot; <code>SUPER + SHIFT + S</code> settings panel (scale, language, startup) &middot; <code>SUPER + SHIFT + D</code> dock editor (palette, borders, zones) &middot; <code>SUPER + SHIFT + B</code> window effects (opacity, blur, rounding)</p>
<p>See <a href="docs/hyprland-config.md">Hyprland Config</a> for file structure, <a href="docs/quick-reference.md">Quick Reference</a> for all keybinds, and <a href="docs/quickshell-widgets.md">Widgets</a> for widget details.</p>

<hr>

<h2>Quick Reference</h2>

<p><code>SUPER + Return</code> Terminal &middot; <code>SUPER + D</code> Apps &middot; <code>SUPER + W</code> Wallpaper &middot; <code>SUPER + S</code> Calendar &middot; <code>SUPER + Space</code> Float &middot; <code>SUPER + L</code> Lock &middot; <code>Print</code> Screenshot &middot; <code>SUPER + Escape</code> Exit</p>

<p>See <a href="docs/quick-reference.md">full keybinding table</a>.</p>

<hr>

<h2>Structure</h2>

<pre><code>hyprland/
  install.sh                  Automated installer (installs kitty/nvim from their repos)
  uninstall.sh                Config removal
  config/hypr/                Hyprland Lua configs (hyprland.lua + modules) + QuickShell QML widgets
  config/hypr/.../dock/palettes   12 palettes (single source of truth)
  config/rofi/                Launcher themes
  config/dunst/               Notification daemon
  config/cava/                Audio visualizer
  config/hypridle/            Idle management (dim, lock, suspend)
  config/sddm/                SDDM login theme (x, palette-synced)
  scripts/                    Shell scripts and daemons (theme-sync.sh, sddm-colors.sh)
  assets/previews/            Screenshots</code></pre>

<hr>

<h2>Documentation</h2>

<ul>
  <li><a href="docs/installation.md">Installation</a> -- Full install, uninstall, and post-install guide</li>
  <li><a href="docs/quick-reference.md">Quick Reference</a> -- All keybindings, widgets, and scripts at a glance</li>
  <li><a href="docs/quickshell-widgets.md">QuickShell Widgets</a> -- Widget architecture, IPC system, and QML components</li>
  <li><a href="docs/scripts.md">Scripts</a> -- All shell scripts and daemons</li>
  <li><a href="docs/dock.md">Dock System</a> -- Position-agnostic dock: architecture, config schema, customization hooks</li>
  <li><a href="docs/dock-modules.md">Dock Modules</a> -- Module contract, ModulePill API, adding/customizing modules</li>
  <li><a href="docs/hyprland-config.md">Hyprland Configuration</a> -- Modular config structure and dynamic reload</li>
  <li><a href="docs/themes.md">Palette System</a> -- The 12 palettes, `Colors.qml` roles, live border sync</li>
  <li><a href="docs/screenshot-recording.md">Screenshots &amp; Recording</a> -- Capture system with virtual audio</li>
  <li><a href="docs/neovim-config.md">Neovim Configuration</a> -- Editor setup from `xscriptor-colors/nvim` (palettes from the panel)</li>
  <li><a href="docs/multi-monitor.md">Multi-Monitor Setup</a> -- Display configuration guide</li>
  <li><a href="docs/gpu-mode.md">GPU Mode Switching</a> -- NVIDIA Optimus control</li>
</ul>

<p align="center">
  <a href="LICENSE">License</a> &middot;
  <a href="CODE_OF_CONDUCT.md">Code of Conduct</a> &middot;
  <a href="ROADMAP.md">Roadmap</a> &middot;
  <a href="CHANGELOG.md">Changelog</a> &middot;
  <a href="SECURITY.md">Security</a>
</p>


<h2 align="center" id="related-repos">Related Repos</h2>
<ul>
  <li><a href="https://github.com/xscriptor-colors/terminal">Terminal </a> - Kitty synchronized dotfiles</li>
  <li><a href="https://github.com/xscriptor-colors/nvim">Nvim </a> - synchronized dotfiles</li>
  <li><a href="https://github.com/xscriptor-colors/jetbrains">Jetbrains </a></li>
  <li><a href="https://github.com/xscriptor-colors/vscode">VSCode </a> - synchronized dotfiles</li>
  <li><a href="https://github.com/xscriptor-colors/obsidian">Obsidian </a></li>
  <li><a href="https://github.com/xfetch-cli/">XFetch </a> - terminal tool shown in the previews</li>
</ul>

<div id="x" align="center">
<h2>X</h2>
<p><em>Xshell Based on Imperative -- adapted, extended, and customized</em></p>
<a href="https://xscriptor.io">Dev</a>
 & 
<a href="https://github.com/xscriptor">Github</a>
 & 
<a href="https://www.xscriptor.com">X</a>

</div>