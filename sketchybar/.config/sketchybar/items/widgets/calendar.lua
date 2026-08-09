local colors = require("colors")
local settings = require("settings")

local weekdays = { "周日", "周一", "周二", "周三", "周四", "周五", "周六" }

local calendar = sbar.add("item", "widgets.calendar", {
  position = "right",
  update_freq = 60,
  width = 92,
  icon = { drawing = false },
  label = {
    string = "周日 --·--",
    width = 92,
    align = "center",
    color = colors.subtext0,
    font = { family = settings.font.text, style = "Semibold", size = 11.0 },
    padding_left = 8,
    padding_right = 4,
  },
  background = { drawing = false },
  click_script = 'open "yuttfu-calendar://toggle"',
})

sbar.add("bracket", "widgets.datetime.bracket", {
  "widgets.calendar",
  "widgets.clock",
}, {
  background = {
    color = colors.with_alpha(colors.surface0, 0.72),
    height = settings.item.height,
    corner_radius = settings.item.corner_radius,
    border_width = 1,
    border_color = colors.with_alpha(colors.surface1, 0.58),
  },
})

local function refresh()
  local weekday = weekdays[tonumber(os.date("%w")) + 1]
  calendar:set({
    label = { string = string.format("%s %s", weekday, os.date("%m·%d")) },
  })
end

calendar:subscribe({ "forced", "routine", "system_woke" }, refresh)
refresh()
