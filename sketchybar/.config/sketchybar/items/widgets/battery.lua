local colors = require("colors")
local settings = require("settings")
local battery_state = require("items.widgets.battery_state")

local battery = sbar.add("item", "widgets.battery", {
  position = "right",
  update_freq = 60,
  width = 56,
  padding_left = 0,
  padding_right = 0,
  icon = {
    string = "󰁹",
    color = colors.subtext0,
    padding_left = 8,
    padding_right = 3,
    font = { family = settings.font.mono, style = "Semibold", size = 12.5 },
  },
  label = {
    string = "--%",
    color = colors.text,
    width = 32,
    align = "right",
    padding_left = 0,
    padding_right = 7,
    font = { family = settings.font.mono, style = "Semibold", size = 10.5 },
  },
})

local function refresh()
  sbar.exec("pmset -g batt", function(output)
    local snapshot = battery_state.parse(output)
    if not snapshot.available then
      battery:set({ drawing = false })
      return
    end

    local tone = battery_state.tone(snapshot)
    local color = colors.subtext0
    if tone == "charging" then
      color = colors.green
    elseif tone == "critical" then
      color = colors.red
    end

    battery:set({
      drawing = true,
      icon = { string = battery_state.icon(snapshot), color = color },
      label = { string = string.format("%d%%", snapshot.charge), color = colors.text },
    })
  end)
end

battery:subscribe({ "forced", "routine", "power_source_change", "system_woke" }, refresh)
