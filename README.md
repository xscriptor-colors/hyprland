<h1 align="center">Hyprland for X</h1>

<p align="center">
  <img src="https://img.shields.io/github/license/xscriptor/hyprland?style=flat-square&color=blue" alt="License">
  <img src="https://img.shields.io/github/last-commit/xscriptor/hyprland?style=flat-square&color=blueviolet" alt="Last Commit">
  <img src="https://img.shields.io/github/repo-size/xscriptor/hyprland?style=flat-square&color=success" alt="Repo Size">
  <img src="https://img.shields.io/badge/Hyprland-v0.53+-8A2BE2?style=flat-square" alt="Hyprland">
  <img src="https://img.shields.io/badge/Arch_Linux-supported-1793D1?style=flat-square&logo=arch-linux" alt="Arch">
  <img src="https://img.shields.io/badge/X_Linux-supported-000000?style=flat-square" alt="X Linux">
  <img src="https://img.shields.io/badge/QuickShell-QML-FF6F00?style=flat-square" alt="QuickShell">
  <img src="https://img.shields.io/badge/Matugen-dynamic-FF69B4?style=flat-square" alt="Matugen">
</p>

<p align="center">
  <em>
  QuickShell QML shell + Matugen dynamic theming for Hyprland on X.
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

<a href="https://imgur.com/0fm1MOy">
<img src="https://i.imgur.com/ahSvDyS.gif" width="900" alt="Demo" >
</a>
<p align="center"><em>Gif preview, follow the link to see the details.</em></p>

<details>
  <summary>Old Previews</summary>
  <br>
  <table>
    <tr>
      <td><img src="assets/previews/preview01.png" width="400" alt="Desktop"></td>
      <td><img src="assets/previews/preview02.png" width="400" alt="Widgets"></td>
    </tr>
    <tr>
      <td><img src="assets/previews/preview03.png" width="400" alt="Wallpaper Picker"></td>
      <td><img src="assets/previews/preview04.png" width="400" alt="Lock Screen"></td>
    </tr>
  </table>
</details>

---

## Quick Install

<pre><code>git clone https://github.com/xscriptor/hyprland.git
cd hyprland
chmod +x install.sh
./install.sh</code></pre>

<p><strong>Options:</strong> <code>--dotfiles-only</code> (config only), <code>--nvidia-only</code> (NVIDIA setup only).</p>

<p>The installer detects your distro and GPU, installs packages (Hyprland, QuickShell, Matugen, SwayOSD, kitty, rofi, and more), backs up existing configs, deploys all dotfiles, optionally configures NVIDIA Optimus, installs the SDDM theme, and generates initial colors from your wallpaper.</p>

<hr>

<h2>Features</h2>

<ul>
  <li><strong>QuickShell QML Interface</strong> -- Animated popup widgets, persistent top bar with workspaces and system tray, notification center, floating sidebar, wallpaper picker with DuckDuckGo search, app launcher, clipboard manager, network/Bluetooth panel, audio controls, calendar with weather, music player (MPRIS), focus time tracker, screen recording overlay with virtual audio routing, QR scanner, and more.</li>
  <li><strong>Matugen Dynamic Theming</strong> -- Every component (Hyprland, Kitty, Neovim, Cava, SwayOSD, GTK, Qt, SDDM) gets colors from the current wallpaper. Change wallpaper, colors update everywhere.</li>
  <li><strong>Modular Hyprland Config</strong> -- Split across focused files (keybinds, animations, window rules, autostart, workspaces, env, colors). Template-based dynamic reload from <code>settings.json</code>.</li>
  <li><strong>NVIDIA Optimus Support</strong> -- <code>envycontrol</code>-based GPU mode switching (integrated/hybrid/nvidia) with keybind shortcuts and Rofi selector.</li>
  <li><strong>Multi-Monitor</strong> -- Workspace binding per monitor, Rofi-based monitor manager with position/resolution/refresh rate control.</li>
  <li><strong>Custom SDDM Theme</strong> -- <code>matugen-minimal</code> with user switching, session selection, Matugen colors, and wallpaper blur.</li>
  <li><strong>Screen Recording</strong> -- GPU-accelerated capture with independent desktop/mic audio channels via virtual PipeWire sinks.</li>
  <li><strong>Neovim Config Included</strong> -- lazy.nvim, LSP via Mason, Treesitter, custom theme engine with Matugen color integration.</li>
</ul>

<hr>

<h2>Customization</h2>

<ul>
  <li><strong>Wallpaper:</strong> <code>SUPER + W</code> opens the wallpaper picker. Colors update automatically.</li>
  <li><strong>Keybindings:</strong> Edit <code>~/.config/hypr/keybinds.conf</code></li>
  <li><strong>Autostart:</strong> Edit <code>~/.config/hypr/autostart.conf</code></li>
  <li><strong>Settings UI:</strong> <code>SUPER + SHIFT + S</code> opens the settings panel (scale, workspace count, language, startup behavior). Changes are applied live.</li>
  <li><strong>Environment:</strong> Edit <code>~/.config/hypr/env.conf</code></li>
</ul>

<hr>

<h2>Quick Reference</h2>

<p><strong>Applications</strong><br>
<code>SUPER + Return</code> Terminal &middot; <code>SUPER + D</code> App launcher &middot; <code>SUPER + E</code> Files &middot; <code>SUPER + F</code> Browser</p>

<p><strong>Widgets</strong><br>
<code>SUPER + M</code> Music &middot; <code>SUPER + C</code> Clipboard &middot; <code>SUPER + B</code> Battery &middot; <code>SUPER + W</code> Wallpaper &middot; <code>SUPER + S</code> Calendar &middot; <code>SUPER + N</code> Network &middot; <code>SUPER + V</code> Volume &middot; <code>SUPER + H</code> Guide &middot; <code>SUPER + SHIFT + S</code> Settings &middot; <code>SUPER + SHIFT + T</code> Focus Time</p>

<p><strong>Windows</strong><br>
<code>ALT + F4</code> Close &middot; <code>SUPER + Space</code> Toggle float &middot; <code>SUPER + G</code> Center &middot; <code>SUPER + J</code> Toggle split</p>

<p><strong>Workspaces</strong><br>
<code>SUPER + 1-0</code> Switch &middot; <code>SUPER + SHIFT + 1-0</code> Move to &middot; <code>SUPER + Tab</code> Previous &middot; <code>SUPER + A</code> Scratchpad</p>

<p><strong>Lock / Power</strong><br>
<code>SUPER + L</code> Lock &middot; <code>SUPER + Escape</code> Exit &middot; <code>SUPER + CTRL + L</code> Suspend &middot; <code>SUPER + CTRL + SHIFT + L</code> Shutdown</p>

<p><strong>Screenshots</strong><br>
<code>Print</code> Area &middot; <code>SUPER + Print</code> Full &middot; <code>SHIFT + Print</code> Area + edit &middot; <code>SUPER + SHIFT + Print</code> Full + edit</p>

<p><strong>Display</strong><br>
<code>SUPER + Z</code> Scale menu &middot; <code>SUPER + R</code> Reload QML &middot; <code>SUPER + SHIFT + R</code> Reload Hyprland</p>

<p><strong>Multi-Monitor</strong><br>
<code>SUPER + ALT + I/U</code> Focus monitor &middot; <code>SUPER + ALT + M</code> Monitor manager &middot; <code>SUPER + ALT + O</code> Swap workspaces</p>

<p><strong>GPU (NVIDIA)</strong><br>
<code>SUPER + ALT + G</code> Cycle mode &middot; <code>SUPER + ALT + SHIFT + G</code> Mode selector</p>

<p>See <a href="docs/quick-reference.md">Quick Reference</a> for the full keybinding table.</p>

<hr>

<h2>Structure</h2>

<pre><code>hyprland/
  install.sh                  Automated installer
  uninstall.sh                Config removal
  config/hypr/                Hyprland modular configs + QuickShell QML widgets
  config/kitty/               Terminal config + Matugen colors
  config/rofi/                Launcher themes
  config/dunst/               Notification daemon
  config/cava/                Audio visualizer
  config/hypridle/            Idle management (dim, lock, suspend)
  config/matugen/             Matugen templates for all apps
  config/sddm/                SDDM login theme (matugen-minimal)
  config/nvim/                Neovim config with lazy.nvim
  scripts/                    Shell scripts and daemons
  assets/previews/            Screenshots</code></pre>

<hr>

<h2>Documentation</h2>

<ul>
  <li><a href="docs/installation.md">Installation</a> -- Full install, uninstall, and post-install guide</li>
  <li><a href="docs/quick-reference.md">Quick Reference</a> -- All keybindings, widgets, and scripts at a glance</li>
  <li><a href="docs/quickshell-widgets.md">QuickShell Widgets</a> -- Widget architecture, IPC system, and QML components</li>
  <li><a href="docs/scripts.md">Scripts</a> -- All shell scripts and daemons</li>
  <li><a href="docs/hyprland-config.md">Hyprland Configuration</a> -- Modular config structure and dynamic reload</li>
  <li><a href="docs/matugen-integration.md">Matugen Integration</a> -- Dynamic color pipeline</li>
  <li><a href="docs/screenshot-recording.md">Screenshots &amp; Recording</a> -- Capture system with virtual audio</li>
  <li><a href="docs/neovim-config.md">Neovim Configuration</a> -- Included editor setup</li>
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
  <li><a href="https://github.com/xscriptor/terminal">Terminal </a> <img src="https://xscriptor.github.io/icons/icons/code/product-design/xsvg/terminal-bash.svg" /></li>
  <li><a href="https://github.com/xscriptor/nvim">Nvim </a><img src="https://xscriptor.github.io/icons/icons/code/product-design/xsvg/file-text.svg"/></li>
  <li><a href="https://github.com/xscriptor/jetbrains">Jetbrains </a><img src="https://xscriptor.github.io/icons/icons/code/product-design/xsvg/project.svg"/></li>
  <li><a href="https://github.com/xscriptor/vscode">VSCode </a><img src="https://xscriptor.github.io/icons/icons/code/product-design/xsvg/vscode-insiders.svg"/></li>
  <li><a href="https://github.com/xscriptor/obsidian">Obsidian </a><img src="https://xscriptor.github.io/icons/icons/code/product-design/xsvg/markdown.svg"/></li>
  <li><a href="https://github.com/xscriptor/xfetch">XFetch </a><img src="https://xscriptor.github.io/icons/icons/code/product-design/xsvg/git-fetch.svg"/></li>
</ul>

<div id="x" align="center">
<h2>X</h2>
<p><em>Based on imperative-dots by ilyamiro -- adapted, extended, and customized</em></p>
<a href="https://dev.xscriptor.com">
  <img src="https://xscriptor.github.io/icons/icons/code/product-design/xsvg/verified-filled.svg" width="24" alt="X Web" />
</a>
 & 
<a href="https://github.com/xscriptor">
  <img src="https://xscriptor.github.io/icons/icons/code/product-design/xsvg/github.svg" width="24" alt="X Github Profile" />
</a>
 & 
<a href="https://www.xscriptor.com">
  <img src="https://xscriptor.github.io/icons/icons/code/product-design/xsvg/quotes.svg" width="24" alt="Xscriptor web" />
</a>

</div>