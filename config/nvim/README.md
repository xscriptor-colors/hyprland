<h1 align="center"> NVIM </h1>

Complete and modern Neovim configuration with essential plugins, LSP, DAP, formatting, linting, and custom themes with the same scheme than <em><a href="https://github.com/xscriptor/terminal"> terminal X repo</a>. </em>

<h2><em>Index</em></h2>

<ul>
  <li><a href="#requirements">Requirements</a></li>
  <li><a href="#installation">Installation</a></li>
  <li><a href="#themes">Themes</a></li>
  <li><a href="#keybindings">Keybindings</a></li>
  <li><a href="#included-plugins">Included Plugins</a></li>
  <li><a href="#notes">Notes</a></li>
  <li><a href="#x">X</a></li>
</ul>


<h2 id="requirements" align="center">Requirements</h2>

<ul>
  <li>Latest stable Neovim</li>
  <li>git</li>
  <li>ripgrep</li>
  <li>fd</li>
  <li>node (for LSP servers and Prettier)</li>
  <li>python (for Python tools)</li>
</ul>

<h2 id="installation" align="center">Installation</h2>

<ol>
  <li>Clone this repository into your nvim config:</li>
</ol>

```bash
git clone [https://github.com/nvim](https://github.com/nvim) ~/.config/nvim
```

<ol start="2">
  <li>Open Neovim and run:</li>
</ol>

```vim
   :Lazy sync
   :Mason
```

<ol start="3">
  <li>To generate a reproducible lockfile, run <code>:Lazy sync</code> and confirm that <code>lazy-lock.json</code> is created before pushing changes.</li>
</ol>

<h2 id="themes" align="center">Themes</h2>

<p>All themes from <code>references.md</code> are available as colorschemes:</p>

<ul>
  <li>x</li>
  <li>madrid</li>
  <li>lahabana</li>
  <li>seul</li>
  <li>miami</li>
  <li>paris</li>
  <li>tokio</li>
  <li>oslo</li>
  <li>helsinki</li>
  <li>berlin</li>
  <li>london</li>
  <li>praha</li>
  <li>bogota</li>
</ul>

<p>Use any of them with:</p>

```vim
:colorscheme tokio
```

<p>Or using the command:</p>

```vim
:Theme tokio
```

<p>The default theme is <code>x</code>. Change it by adjusting <code>vim.g.theme</code> in <code>init.lua</code>.</p>

<h2 id="keybindings" align="center">Keybindings</h2>

<p>Shortcuts use the leader key and letters to avoid layout dependencies. You can change the leader in <code>init.lua</code>.</p>

<p>If you want to force keyboard mappings, you can define the following in <code>init.lua</code>:</p>

```lua
vim.g.langmap_es = ""
vim.g.langmap_en = ""
```

<p>And then use <code>:KeymapLocale es|en|system</code>.</p>

<h2 id="included-plugins" align="center">Included Plugins</h2>

<ul>
  <li><strong>LSP:</strong> mason, lspconfig, lazydev, fidget</li>
  <li><strong>Treesitter:</strong> + textobjects + context</li>
  <li><strong>Completion:</strong> nvim-cmp + LuaSnip</li>
  <li><strong>UI:</strong> lualine, bufferline, alpha, indent-blankline, colorizer</li>
  <li><strong>Tools:</strong> telescope, trouble, todo-comments, conform, nvim-lint, oil, toggleterm, dap</li>
  <li><strong>Git:</strong> gitsigns, diffview</li>
</ul>

<h2 id="notes" align="center">Notes</h2>

<p>If a formatter or linter binary is not installed, <code>conform</code> and <code>nvim-lint</code> will skip it without failing. Use Mason or your preferred package manager to install them.</p>


<h2 align="center">Related documents</h2>

<ul>
  <li><a href="./docs/cheatsheet.md">Cheatsheet</a></li>
  <li><a href="./docs/troubleshooting.md">Troubleshooting</a></li>
  <li><a href="./CONTRIBUTING.md">Contributing</a></li>
  <li><a href="./SECURITY.md">Security</a></li>
  <li><a href="./SUPPORT.md">Support</a></li>
  <li><a href="./CODE_OF_CONDUCT.md">Code of conduct</a></li>
</ul>


<br>

<div id="x" align="center">
<h2>X</h2>

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