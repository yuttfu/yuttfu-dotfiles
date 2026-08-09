local colors = require("colors")
local settings = require("settings")

local hovered = false

local clock = sbar.add("item", "widgets.clock", {
  position = "right",
  update_freq = 1,
  width = 76,
  icon = { drawing = false },
  label = {
    string = "--:--",
    width = 76,
    align = "center",
    color = colors.text,
    font = { family = settings.font.mono, style = "Bold", size = 12.0 },
    padding_left = 6,
    padding_right = 8,
  },
  background = { drawing = false },
})

local function refresh()
  clock:set({
    label = {
      string = hovered and os.date("%H:%M:%S") or os.date("%H:%M"),
    },
  })
end

clock:subscribe({ "forced", "routine", "system_woke" }, refresh)
clock:subscribe("mouse.entered", function()
  hovered = true
  refresh()
end)
clock:subscribe("mouse.exited", function()
  hovered = false
  refresh()
end)

refresh()
