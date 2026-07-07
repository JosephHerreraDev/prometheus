local activeBorderColor = "rgb({{ accent_rgb }})"

hl.config({
  general = {
    col = {
      active_border = activeBorderColor,
    },
  },

  group = {
    col = {
      border_active = activeBorderColor,
    },
  },
})
