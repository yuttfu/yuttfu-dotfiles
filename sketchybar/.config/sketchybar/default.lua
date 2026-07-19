local colors = require("colors")
local settings = require("settings")

sbar.default({
  updates = "when_shown",
  padding_left = 3,
  padding_right = 3,
  icon = {
    color = colors.text,
    font = {
      family = settings.font.mono,
      style = "Semibold",
      size = 13.0,
    },
    padding_left = settings.item.padding,
    padding_right = settings.item.padding,
  },
  label = {
    color = colors.text,
    font = {
      family = settings.font.text,
      style = "Semibold",
      size = 12.0,
    },
    padding_left = settings.item.padding,
    padding_right = settings.item.padding,
  },
  background = {
    color = colors.surface0,
    height = settings.item.height,
    corner_radius = settings.item.corner_radius,
    border_width = 1,
    border_color = colors.surface1,
  },
  popup = {
    background = {
      color = colors.with_alpha(colors.mantle, 0.96),
      corner_radius = 12,
      border_width = 1,
      border_color = colors.surface1,
    },
    blur_radius = 20,
  },
})
