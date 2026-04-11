local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

require("vim-options")
local specs = { { import = "plugins" } }

local theme_path = vim.fn.expand("~/.config/prometheus/current/theme/neovim.lua")
if vim.loop.fs_stat(theme_path) then
  local ok, theme_spec = pcall(dofile, theme_path)
  if ok and type(theme_spec) == "table" then
    vim.list_extend(specs, theme_spec)
  end
end
require("lazy").setup("plugins")