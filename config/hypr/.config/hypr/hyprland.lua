require("hyprland/monitors")
require("hyprland/programs")
require("hyprland/autostart")
require("hyprland/variables")
require("hyprland/permissions")
require("hyprland/looknfeel")

local themeConfig = os.getenv("HOME") .. "/.config/prometheus/current/theme/hyprland.lua"
local themeFile = io.open(themeConfig, "r")
if themeFile ~= nil then
  themeFile:close()
  dofile(themeConfig)
end

require("hyprland/input")
require("hyprland/keybindings")
require("hyprland/windowsnworkspaces")
