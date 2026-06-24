local locale = vim.g.keymap_locale or "system"

local function apply_langmap(value)
  if value == "es" and type(vim.g.langmap_es) == "string" then
    vim.opt.langmap = vim.g.langmap_es
  elseif value == "en" and type(vim.g.langmap_en) == "string" then
    vim.opt.langmap = vim.g.langmap_en
  else
    vim.opt.langmap = ""
  end
end

apply_langmap(locale)

vim.api.nvim_create_user_command("KeymapLocale", function(opts)
  vim.g.keymap_locale = opts.args
  apply_langmap(opts.args)
end, { nargs = 1, complete = function()
  return { "system", "es", "en" }
end })
