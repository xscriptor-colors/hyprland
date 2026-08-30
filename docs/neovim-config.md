# Neovim Configuration

Neovim is installed from the **remote repository** [`xscriptor-colors/nvim`](https://github.com/xscriptor-colors/nvim) (it is not bundled in this repo). The installer clones it to `~/.config/nvim`; `git pull` inside that directory updates it.

## Structure (upstream repo)

```
nvim/
  init.lua                  -- Entry point
  lua/
    config/
      autocmds.lua          -- Autocommands
      keymaps.lua           -- Key mappings
      lazy.lua              -- Lazy.nvim bootstrap
      locale.lua            -- Locale settings
      options.lua           -- Neovim options
      theme.lua             -- Theme bootstrapper (upstream)
    plugins/                -- Plugin configs (completion, editor, git, lsp, tools, treesitter, ui)
    themes/
      palettes.lua          -- The 12 palettes (same as dock/palettes/*.json)
      init.lua              -- Theme engine (applies highlight groups)
  colors/<slug>.lua         -- One-liners: require("themes").apply("<slug>")
```

## Theme System

The theme engine in `lua/themes/` applies highlight groups from `palettes.lua`. The plugin/keymap/option config comes from the user's own repo (cloned to `~/.config/nvim`), but **`theme-sync.sh` regenerates** `lua/themes/palettes.lua` and `lua/config/theme.lua` from `dock/palettes` so Neovim follows the same palette as the bar, kitty, starship and VS Code.

## Post-install

1. Open `nvim` → Lazy installs plugins (`:Lazy`).
2. `:Mason` to install LSP servers.
3. Refer to the nvim README / cheatsheet for usage.
