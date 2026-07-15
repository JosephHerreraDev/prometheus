-- Use the palette from Kitty's effective configuration as Neovim's colorscheme.
local defaults = {
  foreground = "#c0c0c0",
  background = "#000000",
  selection_foreground = "#000000",
  selection_background = "#c0c0c0",
  cursor = "#c0c0c0",
  color0 = "#000000",
  color1 = "#800000",
  color2 = "#008000",
  color3 = "#808000",
  color4 = "#000080",
  color5 = "#800080",
  color6 = "#008080",
  color7 = "#c0c0c0",
  color8 = "#808080",
  color9 = "#ff0000",
  color10 = "#00ff00",
  color11 = "#ffff00",
  color12 = "#0000ff",
  color13 = "#ff00ff",
  color14 = "#00ffff",
  color15 = "#ffffff",
}

local palette_keys = vim.tbl_keys(defaults)

local function expand_path(path, parent)
  path = vim.fn.expand(path)
  if not path:match("^/") then
    path = vim.fs.joinpath(parent, path)
  end
  return vim.fs.normalize(path)
end

local function read_kitty_config(path, palette, seen)
  path = vim.fs.normalize(path)
  if seen[path] or vim.fn.filereadable(path) ~= 1 then
    return
  end
  seen[path] = true

  local parent = vim.fs.dirname(path)
  for _, line in ipairs(vim.fn.readfile(path)) do
    local include = line:match("^%s*include%s+(.+)%s*$")
    if include then
      include = include:gsub("%s+#.*$", "")
      local pattern = expand_path(include, parent)
      local matches = vim.fn.glob(pattern, false, true)
      if #matches == 0 then
        matches = { pattern }
      end
      for _, included_path in ipairs(matches) do
        read_kitty_config(included_path, palette, seen)
      end
    else
      local key, value = line:match("^%s*([%w_]+)%s+(#%x%x%x%x%x%x)%s*$")
      if key and vim.tbl_contains(palette_keys, key) then
        palette[key] = value:lower()
      end
    end
  end
end

local palette = vim.deepcopy(defaults)
read_kitty_config(vim.fn.expand("~/.config/kitty/kitty.conf"), palette, {})

local function luminance(hex)
  local r = tonumber(hex:sub(2, 3), 16)
  local g = tonumber(hex:sub(4, 5), 16)
  local b = tonumber(hex:sub(6, 7), 16)
  return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

vim.o.termguicolors = true
vim.o.background = luminance(palette.background) > 127.5 and "light" or "dark"
vim.cmd.highlight("clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd.syntax("reset")
end
vim.g.colors_name = "terminal"

for index = 0, 15 do
  vim.g["terminal_color_" .. index] = palette["color" .. index]
end

local c = {
  bg = palette.background,
  fg = palette.foreground,
  black = palette.color0,
  red = palette.color1,
  green = palette.color2,
  yellow = palette.color3,
  blue = palette.color4,
  magenta = palette.color5,
  cyan = palette.color6,
  white = palette.color7,
  bright_black = palette.color8,
  bright_red = palette.color9,
  bright_green = palette.color10,
  bright_yellow = palette.color11,
  bright_blue = palette.color12,
  bright_magenta = palette.color13,
  bright_cyan = palette.color14,
  bright_white = palette.color15,
}

local function set(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

local function link(group, target)
  set(group, { link = target })
end

-- Editor UI. Normal stays transparent so Kitty owns the actual background.
set("Normal", { fg = c.fg, bg = "NONE" })
set("NormalNC", { fg = c.fg, bg = "NONE" })
set("NormalFloat", { fg = c.fg, bg = c.black })
set("FloatBorder", { fg = c.bright_black, bg = c.black })
set("FloatTitle", { fg = c.bright_blue, bg = c.black, bold = true })
set("ColorColumn", { bg = c.black })
set("Cursor", { fg = c.bg, bg = palette.cursor })
set("CursorColumn", { bg = c.black })
set("CursorLine", { bg = c.black })
set("CursorLineNr", { fg = c.bright_yellow, bg = "NONE", bold = true })
set("LineNr", { fg = c.bright_black, bg = "NONE" })
set("SignColumn", { fg = c.bright_black, bg = "NONE" })
set("FoldColumn", { fg = c.bright_black, bg = "NONE" })
set("Folded", { fg = c.bright_black, bg = c.black })
set("EndOfBuffer", { fg = c.bg, bg = "NONE" })
set("NonText", { fg = c.bright_black })
set("Whitespace", { fg = c.bright_black })
set("SpecialKey", { fg = c.bright_black })
set("WinSeparator", { fg = c.bright_black, bg = "NONE" })
set("Visual", { fg = palette.selection_foreground, bg = palette.selection_background })
set("Search", { fg = c.bg, bg = c.yellow, bold = true })
set("IncSearch", { fg = c.bg, bg = c.bright_yellow, bold = true })
link("CurSearch", "IncSearch")
set("MatchParen", { fg = c.bright_cyan, bold = true, underline = true })
set("Pmenu", { fg = c.fg, bg = c.black })
set("PmenuSel", { fg = c.bg, bg = c.blue, bold = true })
set("PmenuSbar", { bg = c.black })
set("PmenuThumb", { bg = c.bright_black })
set("StatusLine", { fg = c.fg, bg = c.black })
set("StatusLineNC", { fg = c.bright_black, bg = c.black })
set("TabLine", { fg = c.bright_black, bg = c.black })
set("TabLineFill", { bg = c.black })
set("TabLineSel", { fg = c.bright_blue, bg = c.black, bold = true })
set("WinBar", { fg = c.fg, bg = "NONE", bold = true })
set("WinBarNC", { fg = c.bright_black, bg = "NONE" })
set("Title", { fg = c.bright_blue, bold = true })
set("Directory", { fg = c.bright_blue })
set("Question", { fg = c.bright_green })
set("MoreMsg", { fg = c.bright_green })
set("ModeMsg", { fg = c.bright_yellow, bold = true })
set("WarningMsg", { fg = c.bright_yellow })
set("ErrorMsg", { fg = c.bright_red, bold = true })

-- Vim syntax groups. Tree-sitter captures below link back to these groups.
set("Comment", { fg = c.bright_black, italic = true })
set("Constant", { fg = c.bright_magenta })
set("String", { fg = c.green })
set("Character", { fg = c.bright_green })
set("Number", { fg = c.bright_magenta })
set("Boolean", { fg = c.bright_magenta, bold = true })
set("Float", { fg = c.bright_magenta })
set("Identifier", { fg = c.fg })
set("Function", { fg = c.bright_blue })
set("Statement", { fg = c.magenta, bold = true })
set("Conditional", { fg = c.magenta, bold = true })
set("Repeat", { fg = c.magenta, bold = true })
set("Label", { fg = c.bright_yellow })
set("Operator", { fg = c.bright_cyan })
set("Keyword", { fg = c.magenta, bold = true })
set("Exception", { fg = c.bright_red, bold = true })
set("PreProc", { fg = c.cyan })
set("Include", { fg = c.cyan })
set("Define", { fg = c.cyan })
set("Macro", { fg = c.bright_cyan })
set("PreCondit", { fg = c.cyan })
set("Type", { fg = c.yellow })
set("StorageClass", { fg = c.yellow })
set("Structure", { fg = c.yellow })
set("Typedef", { fg = c.yellow })
set("Special", { fg = c.bright_cyan })
set("SpecialChar", { fg = c.bright_cyan })
set("Tag", { fg = c.bright_blue })
set("Delimiter", { fg = c.white })
set("SpecialComment", { fg = c.bright_cyan, italic = true })
set("Debug", { fg = c.bright_red })
set("Underlined", { fg = c.bright_blue, underline = true })
set("Ignore", { fg = c.bright_black })
set("Error", { fg = c.bright_red, bold = true })
set("Todo", { fg = c.bg, bg = c.bright_yellow, bold = true })

local treesitter_links = {
  ["@attribute"] = "PreProc",
  ["@boolean"] = "Boolean",
  ["@character"] = "Character",
  ["@comment"] = "Comment",
  ["@comment.error"] = "DiagnosticError",
  ["@comment.note"] = "DiagnosticInfo",
  ["@comment.todo"] = "Todo",
  ["@comment.warning"] = "DiagnosticWarn",
  ["@constant"] = "Constant",
  ["@constant.builtin"] = "Special",
  ["@constructor"] = "Special",
  ["@function"] = "Function",
  ["@function.builtin"] = "Special",
  ["@function.call"] = "Function",
  ["@function.macro"] = "Macro",
  ["@function.method"] = "Function",
  ["@function.method.call"] = "Function",
  ["@keyword"] = "Keyword",
  ["@keyword.conditional"] = "Conditional",
  ["@keyword.exception"] = "Exception",
  ["@keyword.function"] = "Keyword",
  ["@keyword.import"] = "Include",
  ["@keyword.operator"] = "Operator",
  ["@keyword.repeat"] = "Repeat",
  ["@keyword.return"] = "Keyword",
  ["@label"] = "Label",
  ["@markup.emphasis"] = "Comment",
  ["@markup.heading"] = "Title",
  ["@markup.link"] = "Underlined",
  ["@markup.link.label"] = "Special",
  ["@markup.list"] = "Special",
  ["@markup.raw"] = "String",
  ["@markup.strong"] = "Statement",
  ["@module"] = "Include",
  ["@number"] = "Number",
  ["@number.float"] = "Float",
  ["@operator"] = "Operator",
  ["@property"] = "Identifier",
  ["@punctuation.bracket"] = "Delimiter",
  ["@punctuation.delimiter"] = "Delimiter",
  ["@punctuation.special"] = "Special",
  ["@string"] = "String",
  ["@string.escape"] = "SpecialChar",
  ["@string.regexp"] = "Special",
  ["@tag"] = "Tag",
  ["@tag.attribute"] = "Identifier",
  ["@tag.delimiter"] = "Delimiter",
  ["@type"] = "Type",
  ["@type.builtin"] = "Type",
  ["@type.definition"] = "Typedef",
  ["@variable"] = "Identifier",
  ["@variable.builtin"] = "Special",
  ["@variable.member"] = "Identifier",
  ["@variable.parameter"] = "Identifier",
  ["@variable.parameter.builtin"] = "Special",
}
for group, target in pairs(treesitter_links) do
  link(group, target)
end

for _, semantic_type in ipairs({
  "class",
  "decorator",
  "enum",
  "enumMember",
  "event",
  "function",
  "interface",
  "keyword",
  "macro",
  "method",
  "namespace",
  "number",
  "operator",
  "parameter",
  "property",
  "regexp",
  "string",
  "struct",
  "type",
  "typeParameter",
  "variable",
}) do
  local target = treesitter_links["@" .. semantic_type] or treesitter_links["@variable." .. semantic_type]
  target = target or ({
    class = "Type",
    decorator = "PreProc",
    enum = "Type",
    enumMember = "Constant",
    event = "Special",
    interface = "Type",
    method = "Function",
    namespace = "Include",
    parameter = "Identifier",
    regexp = "Special",
    struct = "Structure",
    typeParameter = "Type",
  })[semantic_type] or "Identifier"
  link("@lsp.type." .. semantic_type, target)
end

set("DiagnosticError", { fg = c.bright_red })
set("DiagnosticWarn", { fg = c.bright_yellow })
set("DiagnosticInfo", { fg = c.bright_blue })
set("DiagnosticHint", { fg = c.bright_cyan })
set("DiagnosticOk", { fg = c.bright_green })
set("DiagnosticUnderlineError", { undercurl = true, sp = c.bright_red })
set("DiagnosticUnderlineWarn", { undercurl = true, sp = c.bright_yellow })
set("DiagnosticUnderlineInfo", { undercurl = true, sp = c.bright_blue })
set("DiagnosticUnderlineHint", { undercurl = true, sp = c.bright_cyan })
set("Added", { fg = c.bright_green })
set("Changed", { fg = c.bright_yellow })
set("Removed", { fg = c.bright_red })
link("DiffAdd", "Added")
link("DiffChange", "Changed")
link("DiffDelete", "Removed")
set("DiffText", { fg = c.bg, bg = c.bright_yellow, bold = true })
link("GitSignsAdd", "Added")
link("GitSignsChange", "Changed")
link("GitSignsDelete", "Removed")

vim.api.nvim_create_user_command("TerminalColorsReload", function()
  vim.cmd.colorscheme("terminal")
end, { desc = "Reload colors from Kitty's configuration", force = true })

local reload_group = vim.api.nvim_create_augroup("TerminalColorsReload", { clear = true })
vim.api.nvim_create_autocmd("FocusGained", {
  group = reload_group,
  desc = "Reload Neovim colors when Kitty's palette changes",
  callback = function()
    local current = vim.deepcopy(defaults)
    read_kitty_config(vim.fn.expand("~/.config/kitty/kitty.conf"), current, {})
    if not vim.deep_equal(current, palette) then
      vim.schedule(function()
        vim.cmd.colorscheme("terminal")
      end)
    end
  end,
})
