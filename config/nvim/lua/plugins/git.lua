return {
  {
    "lewis6991/gitsigns.nvim",
    event = "BufReadPost",
    opts = {},
  },
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },
}
