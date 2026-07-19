local colors = require("colors")

local calendar = sbar.add("item", "widgets.calendar", {
  position = "right",
  update_freq = 30,
  icon = { string = "󰃭", color = colors.lavender },
  label = { string = "--:--" },
  click_script = "open -a Calendar",
})

calendar:subscribe({ "forced", "routine", "system_woke" }, function()
  calendar:set({
    icon = { string = os.date("%a %m/%d") },
    label = { string = os.date("%H:%M") },
  })
end)
