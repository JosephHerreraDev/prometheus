-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--

local transparent_groups = {
  "Normal",
  "NormalNC",
  "NormalFloat",
  "FloatBorder",
  "FloatTitle",
  "SignColumn",
  "LineNr",
  "CursorLineNr",
  "EndOfBuffer",
  "StatusLine",
  "StatusLineNC",
  "WinSeparator",
  "VertSplit",
  "Pmenu",
  "PmenuSel",

  -- LazyVim/plugin windows
  "LazyNormal",
  "MasonNormal",
  "WhichKeyNormal",
  "NeoTreeNormal",
  "NeoTreeNormalNC",
  "SnacksNormal",
  "SnacksNormalNC",
}

local function use_terminal_background()
  for _, group in ipairs(transparent_groups) do
    vim.api.nvim_set_hl(0, group, {
      bg = "NONE",
      update = true,
    })
  end
end

local group = vim.api.nvim_create_augroup("TerminalBackground", {
  clear = true,
})

vim.api.nvim_create_autocmd("ColorScheme", {
  group = group,
  callback = use_terminal_background,
})

vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  callback = use_terminal_background,
})

use_terminal_background()
