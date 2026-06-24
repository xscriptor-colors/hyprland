local palettes = require("themes.palettes")

local M = {}

local function strip_alpha(hex)
  if #hex == 9 then
    return hex:sub(1, 7)
  end
  return hex
end

local function hex_to_rgb(hex)
  hex = strip_alpha(hex):gsub("#", "")
  return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
end

local function is_light(hex)
  local r, g, b = hex_to_rgb(hex)
  local luma = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255
  return luma > 0.6
end

local function set_hl(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

function M.apply(name)
  local p = palettes[name]
  if not p then
    return
  end

  if vim.g.colors_name then
    vim.cmd("highlight clear")
  end

  vim.cmd("syntax reset")

  vim.o.termguicolors = true
  vim.o.background = is_light(p.color0) and "light" or "dark"
  vim.g.colors_name = name

  local c = {
    bg = strip_alpha(p.color0),
    fg = strip_alpha(p.color7),
    bg_alt = strip_alpha(p.color8),
    fg_alt = strip_alpha(p.color15),
    comment = strip_alpha(p.color8),
    red = strip_alpha(p.color1),
    green = strip_alpha(p.color2),
    yellow = strip_alpha(p.color3),
    orange = strip_alpha(p.color4),
    purple = strip_alpha(p.color5),
    blue = strip_alpha(p.color6),
    cyan = strip_alpha(p.color6),
    bright_red = strip_alpha(p.color9),
    bright_green = strip_alpha(p.color10),
    bright_yellow = strip_alpha(p.color11),
    bright_orange = strip_alpha(p.color12),
    bright_purple = strip_alpha(p.color13),
    bright_cyan = strip_alpha(p.color14),
  }

  set_hl("Normal", { fg = c.fg, bg = c.bg })
  set_hl("NormalFloat", { fg = c.fg, bg = c.bg })
  set_hl("FloatBorder", { fg = c.comment, bg = c.bg })
  set_hl("CursorLine", { bg = c.bg_alt })
  set_hl("CursorLineNr", { fg = c.fg_alt, bg = c.bg_alt, bold = true })
  set_hl("LineNr", { fg = c.comment })
  set_hl("SignColumn", { bg = c.bg })
  set_hl("VertSplit", { fg = c.bg_alt })
  set_hl("WinSeparator", { fg = c.bg_alt })

  set_hl("Pmenu", { fg = c.fg, bg = c.bg_alt })
  set_hl("PmenuSel", { fg = c.bg, bg = c.bright_cyan, bold = true })
  set_hl("PmenuSbar", { bg = c.bg_alt })
  set_hl("PmenuThumb", { bg = c.comment })

  set_hl("Visual", { bg = c.bg_alt })
  set_hl("Search", { fg = c.bg, bg = c.bright_yellow })
  set_hl("IncSearch", { fg = c.bg, bg = c.bright_orange })
  set_hl("MatchParen", { fg = c.bright_cyan, bold = true })

  set_hl("StatusLine", { fg = c.fg, bg = c.bg_alt })
  set_hl("StatusLineNC", { fg = c.comment, bg = c.bg_alt })
  set_hl("TabLine", { fg = c.comment, bg = c.bg_alt })
  set_hl("TabLineSel", { fg = c.fg, bg = c.bg })
  set_hl("TabLineFill", { fg = c.comment, bg = c.bg_alt })

  set_hl("DiffAdd", { fg = c.green, bg = c.bg })
  set_hl("DiffChange", { fg = c.yellow, bg = c.bg })
  set_hl("DiffDelete", { fg = c.red, bg = c.bg })
  set_hl("DiffText", { fg = c.cyan, bg = c.bg })

  set_hl("DiagnosticError", { fg = c.red })
  set_hl("DiagnosticWarn", { fg = c.yellow })
  set_hl("DiagnosticInfo", { fg = c.cyan })
  set_hl("DiagnosticHint", { fg = c.purple })
  set_hl("DiagnosticVirtualTextError", { fg = c.red })
  set_hl("DiagnosticVirtualTextWarn", { fg = c.yellow })
  set_hl("DiagnosticVirtualTextInfo", { fg = c.cyan })
  set_hl("DiagnosticVirtualTextHint", { fg = c.purple })

  set_hl("LspReferenceText", { bg = c.bg_alt })
  set_hl("LspReferenceRead", { bg = c.bg_alt })
  set_hl("LspReferenceWrite", { bg = c.bg_alt })

  set_hl("Comment", { fg = c.comment, italic = true })
  set_hl("Constant", { fg = c.orange })
  set_hl("String", { fg = c.green })
  set_hl("Character", { fg = c.green })
  set_hl("Number", { fg = c.orange })
  set_hl("Boolean", { fg = c.orange })
  set_hl("Float", { fg = c.orange })

  set_hl("Identifier", { fg = c.cyan })
  set_hl("Function", { fg = c.blue, bold = true })

  set_hl("Statement", { fg = c.purple })
  set_hl("Conditional", { fg = c.purple })
  set_hl("Repeat", { fg = c.purple })
  set_hl("Label", { fg = c.purple })
  set_hl("Operator", { fg = c.red })
  set_hl("Keyword", { fg = c.purple })
  set_hl("Exception", { fg = c.red })

  set_hl("PreProc", { fg = c.yellow })
  set_hl("Include", { fg = c.yellow })
  set_hl("Define", { fg = c.yellow })
  set_hl("Macro", { fg = c.yellow })
  set_hl("PreCondit", { fg = c.yellow })

  set_hl("Type", { fg = c.cyan })
  set_hl("StorageClass", { fg = c.cyan })
  set_hl("Structure", { fg = c.cyan })
  set_hl("Typedef", { fg = c.cyan })

  set_hl("Special", { fg = c.bright_purple })
  set_hl("SpecialChar", { fg = c.bright_purple })
  set_hl("Tag", { fg = c.cyan })
  set_hl("Delimiter", { fg = c.comment })
  set_hl("SpecialComment", { fg = c.comment })
  set_hl("Debug", { fg = c.red })

  set_hl("Underlined", { underline = true })
  set_hl("Error", { fg = c.red, bold = true })
  set_hl("Todo", { fg = c.bright_yellow, bold = true })

  set_hl("@comment", { link = "Comment" })
  set_hl("@string", { link = "String" })
  set_hl("@string.regex", { fg = c.orange })
  set_hl("@string.escape", { fg = c.orange })
  set_hl("@string.special", { fg = c.orange })
  set_hl("@character", { link = "Character" })
  set_hl("@number", { link = "Number" })
  set_hl("@boolean", { link = "Boolean" })
  set_hl("@float", { link = "Float" })
  set_hl("@function", { link = "Function" })
  set_hl("@function.call", { link = "Function" })
  set_hl("@function.builtin", { fg = c.bright_cyan })
  set_hl("@method", { fg = c.cyan })
  set_hl("@method.call", { fg = c.cyan })
  set_hl("@constructor", { fg = c.yellow })
  set_hl("@parameter", { fg = c.fg })
  set_hl("@keyword", { link = "Keyword" })
  set_hl("@keyword.function", { fg = c.purple })
  set_hl("@keyword.operator", { fg = c.red })
  set_hl("@keyword.return", { fg = c.red })
  set_hl("@conditional", { link = "Conditional" })
  set_hl("@repeat", { link = "Repeat" })
  set_hl("@operator", { link = "Operator" })
  set_hl("@punctuation.delimiter", { fg = c.comment })
  set_hl("@punctuation.bracket", { fg = c.comment })
  set_hl("@punctuation.special", { fg = c.bright_purple })
  set_hl("@type", { link = "Type" })
  set_hl("@type.builtin", { fg = c.cyan })
  set_hl("@property", { fg = c.cyan })
  set_hl("@field", { fg = c.cyan })
  set_hl("@variable", { fg = c.fg })
  set_hl("@variable.builtin", { fg = c.bright_orange })
  set_hl("@constant", { link = "Constant" })
  set_hl("@constant.builtin", { fg = c.bright_orange })
  set_hl("@constant.macro", { fg = c.bright_orange })
  set_hl("@module", { fg = c.yellow })
  set_hl("@namespace", { fg = c.yellow })
  set_hl("@label", { fg = c.purple })
  set_hl("@tag", { fg = c.cyan })
  set_hl("@tag.attribute", { fg = c.yellow })
  set_hl("@tag.delimiter", { fg = c.comment })

  set_hl("TelescopeBorder", { fg = c.comment, bg = c.bg })
  set_hl("TelescopePromptBorder", { fg = c.comment, bg = c.bg_alt })
  set_hl("TelescopePromptNormal", { fg = c.fg, bg = c.bg_alt })
  set_hl("TelescopePromptPrefix", { fg = c.cyan, bg = c.bg_alt })

  set_hl("GitSignsAdd", { fg = c.green })
  set_hl("GitSignsChange", { fg = c.yellow })
  set_hl("GitSignsDelete", { fg = c.red })

  vim.g.terminal_color_0 = c.bg
  vim.g.terminal_color_1 = c.red
  vim.g.terminal_color_2 = c.green
  vim.g.terminal_color_3 = c.yellow
  vim.g.terminal_color_4 = c.orange
  vim.g.terminal_color_5 = c.purple
  vim.g.terminal_color_6 = c.cyan
  vim.g.terminal_color_7 = c.fg
  vim.g.terminal_color_8 = c.comment
  vim.g.terminal_color_9 = c.bright_red
  vim.g.terminal_color_10 = c.bright_green
  vim.g.terminal_color_11 = c.bright_yellow
  vim.g.terminal_color_12 = c.bright_orange
  vim.g.terminal_color_13 = c.bright_purple
  vim.g.terminal_color_14 = c.bright_cyan
  vim.g.terminal_color_15 = c.fg_alt
end

M.names = vim.tbl_keys(palettes)

vim.api.nvim_create_user_command("Theme", function(opts)
  M.apply(opts.args)
end, { nargs = 1, complete = function()
  return M.names
end })

return M
