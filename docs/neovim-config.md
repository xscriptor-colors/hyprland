# Neovim Configuration

A full Neovim setup is included in `config/nvim/`. It uses a custom Lua-based plugin manager via `lazy.nvim`.

## Structure

```
config/nvim/
  init.lua                  -- Entry point
  lua/
    config/
      autocmds.lua          -- Autocommands
      keymaps.lua           -- Key mappings
      lazy.lua              -- Lazy.nvim bootstrap
      locale.lua            -- Locale settings
      options.lua           -- Neovim options
      theme.lua             -- Theme bootstrapper
    plugins/
      completion.lua        -- Autocompletion (nvim-cmp, snippets)
      editor.lua            -- Editor enhancement plugins
      git.lua               -- Git integration (gitsigns, fugitive)
      lsp.lua               -- LSP configuration (mason, mason-lspconfig)
      tools.lua             -- Utility plugins
      treesitter.lua        -- Treesitter parsers and config
      ui.lua                -- UI enhancements (bufferline, lualine, etc.)
    themes/
      init.lua              -- Theme engine
  colors/
    colors.lua              -- Color scheme overrides
  docs/
    cheatsheet.md           -- Keybinding reference
    troubleshooting.md      -- Common issues
```

## Theme System

The custom theme engine in `lua/themes/` loads `matugen_colors.lua` (generated from wallpaper via Matugen) as the color source. The engine sets highlight groups for syntax, UI elements, and plugin integrations.
