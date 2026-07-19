local colors = require("colors")
local settings = require("settings")

sbar.add("item", "apple.yuttfu", {
  position = "left",
  icon = {
    string = "",
    color = colors.lavender,
    font = { family = settings.font.text, style = "Bold", size = 15.0 },
    padding_left = 7,
    padding_right = 3,
  },
  label = {
    string = settings.identity,
    color = colors.text,
    padding_left = 3,
    padding_right = 7,
  },
  background = {
    color = colors.surface0,
    border_color = colors.with_alpha(colors.lavender, 0.55),
  },
  click_script = "open -a 'System Settings'",
})

sbar.add("item", "apple.yuttfu.gap", {
  position = "left",
  width = settings.item.group_gap,
  icon = { drawing = false },
  label = { drawing = false },
  background = { drawing = false },
})
