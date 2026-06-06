if vim.tbl_flatten and vim.iter then
  vim.tbl_flatten = function(t)
    return vim.iter(t):flatten(math.huge):totable()
  end
end

local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true
opt.wrap = false
opt.cursorline = true
opt.signcolumn = "yes"
opt.termguicolors = true
opt.updatetime = 200
opt.timeoutlen = 400
opt.splitright = true
opt.splitbelow = true
opt.ignorecase = true
opt.smartcase = true
opt.clipboard = "unnamedplus"
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.completeopt = "menu,menuone,noselect"
opt.pumheight = 10
opt.undofile = true
opt.swapfile = false
opt.backup = false
opt.confirm = true
opt.laststatus = 3
opt.showmode = false
opt.list = true
opt.listchars = { tab = "->", trail = ".", extends = ">", precedes = "<", nbsp = "+" }
opt.fillchars = { eob = " " }

vim.diagnostic.config({
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded" },
  signs = true,
  virtual_text = { spacing = 2, prefix = "*" },
})
