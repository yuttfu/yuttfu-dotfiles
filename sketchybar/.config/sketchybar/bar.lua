local colors = require("colors")
local settings = require("settings")

sbar.bar({
  position = "top",
  topmost = "window",
  sticky = true,
  height = settings.bar.height,
  margin = settings.bar.margin,
  corner_radius = settings.bar.corner_radius,
  y_offset = settings.bar.y_offset,
  blur_radius = settings.bar.blur_radius,
  color = colors.bar_bg,
  border_width = 1,
  border_color = colors.with_alpha(colors.lavender, 0.28),
  padding_left = 6,
  padding_right = 6,
  shadow = true,
})
