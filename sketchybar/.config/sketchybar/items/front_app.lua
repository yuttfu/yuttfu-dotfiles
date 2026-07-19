local colors = require("colors")
local settings = require("settings")

sbar.add("item", "front_app.gap", {
  position = "left",
  width = settings.item.group_gap,
  icon = { drawing = false },
  label = { drawing = false },
  background = { drawing = false },
})

local front_app = sbar.add("item", "front_app", {
  position = "left",
  display = "active",
  updates = true,
  icon = {
    string = "󰘔",
    color = colors.teal,
  },
  label = {
    string = "Desktop",
    max_chars = 22,
  },
})

front_app:subscribe("front_app_switched", function(env)
  front_app:set({ label = { string = env.INFO or "Desktop" } })
end)
