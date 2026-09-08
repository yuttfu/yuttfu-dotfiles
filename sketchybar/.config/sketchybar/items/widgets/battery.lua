local colors = require("colors")
local settings = require("settings")
local battery_state = require("items.widgets.battery_state")

local battery = sbar.add("item", "widgets.battery", {
  position = "right", update_freq = 60, width = 64, y_offset = 0, padding_left = 0, padding_right = 0,
  background = { color = colors.surface0, corner_radius = settings.item.corner_radius, height = settings.item.height },
  icon = { string = "󰁹", color = colors.subtext0, width = 28, align = "left", padding_left = 14, padding_right = 4, y_offset = 0,
    font = { family = settings.font.mono, style = "Semibold", size = 12.5 } },
  label = { string = "--%", color = colors.text, width = 36, align = "right",
    padding_left = 0, padding_right = 8,
    font = { family = settings.font.mono, style = "Semibold", size = 10.5 } },
  popup = { align = "right", drawing = false,
    background = { color = colors.base, border_color = colors.surface1, border_width = 1, corner_radius = 9 } },
})
sbar.add("item", "widgets.battery.gap", {
  position = "right", width = settings.item.group_gap,
  padding_left = 0, padding_right = 0,
  icon = { drawing = false }, label = { drawing = false },
  background = { drawing = false },
})
local status_item = sbar.add("item", "widgets.battery.status", {
  position = "popup.widgets.battery", width = 220, icon = { drawing = false },
  background = { drawing = false },
  label = { string = "读取电池状态…", color = colors.text, padding_left = 12, padding_right = 12,
    font = { family = settings.font.text, style = "Semibold", size = 12 } },
})
local detail_item = sbar.add("item", "widgets.battery.detail", {
  position = "popup.widgets.battery", width = 220, icon = { drawing = false },
  background = { drawing = false },
  label = { string = "", color = colors.subtext0, padding_left = 12, padding_right = 12,
    font = { family = settings.font.text, style = "Regular", size = 11 } },
})

local function refresh()
  sbar.exec("pmset -g batt", function(output)
    local snapshot = battery_state.parse(output)
    if not snapshot.available then
      battery:set({ drawing = false, popup = { drawing = false } })
      return
    end
    local tone = battery_state.tone(snapshot)
    local color = colors.subtext0
    if tone == "charging" then color = colors.green
    elseif tone == "critical" then color = colors.red
    elseif tone == "full" then color = colors.lavender end
    battery:set({ drawing = true,
      icon = { string = battery_state.icon(snapshot), color = color },
      label = { string = string.format("%d%%", snapshot.charge), color = colors.text } })
    status_item:set({ label = { string = battery_state.description(snapshot) } })
    detail_item:set({ label = { string = battery_state.detail(snapshot) } })
  end)
end
battery:subscribe({ "forced", "routine", "power_source_change", "system_woke" }, refresh)
battery:subscribe("mouse.clicked", function()
  refresh()
  battery:set({ popup = { drawing = "toggle" } })
end)
battery:subscribe("mouse.exited.global", function() battery:set({ popup = { drawing = false } }) end)
refresh()

require("theme_runtime").on_change(function()
  battery:set({ background = { color = colors.surface0, border_color = colors.surface1 },
    popup = { background = { color = colors.base, border_color = colors.surface1 } } })
  status_item:set({ label = { color = colors.text } })
  detail_item:set({ label = { color = colors.subtext0 } })
  refresh()
end)
