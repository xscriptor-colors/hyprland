return {
  {
    "williamboman/mason.nvim",
    cmd = { "Mason" },
    opts = {},
  },
  {
    "williamboman/mason-lspconfig.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = {
        "bashls",
        "cssls",
        "html",
        "jsonls",
        "lua_ls",
        "pyright",
        "rust_analyzer",
        "ts_ls",
        "yamlls",
      },
    },
  },
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {},
  },
  {
    "j-hui/fidget.nvim",
    tag = "v1.4.5",
    event = "LspAttach",
    opts = {},
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      local function on_attach(_, bufnr)
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end
        map("n", "gd", vim.lsp.buf.definition, "LSP definition")
        map("n", "gI", vim.lsp.buf.implementation, "LSP implementation")
        map("n", "gr", vim.lsp.buf.references, "LSP references")
        map("n", "K", vim.lsp.buf.hover, "LSP hover")
        map("n", "<leader>rn", vim.lsp.buf.rename, "LSP rename")
        map("n", "<leader>ca", vim.lsp.buf.code_action, "LSP code action")
        map("n", "<leader>ds", vim.lsp.buf.document_symbol, "LSP document symbols")
        map("n", "<leader>ws", vim.lsp.buf.workspace_symbol, "LSP workspace symbols")
      end

      local servers = {
        bashls = {},
        cssls = {},
        html = {},
        jsonls = {},
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = { globals = { "vim" } },
              workspace = { checkThirdParty = false },
            },
          },
        },
        pyright = {},
        rust_analyzer = {},
        ts_ls = {},
        yamlls = {},
      }

      local function with_defaults(config)
        return vim.tbl_extend("force", config, {
          capabilities = capabilities,
          on_attach = on_attach,
        })
      end

      for server, config in pairs(servers) do
        vim.lsp.config(server, with_defaults(config))
      end
      vim.lsp.enable(vim.tbl_keys(servers))
    end,
  },
}
