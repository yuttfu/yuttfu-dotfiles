local colors = require("colors")

local hovered = false

local clock = sbar.add("item", "widgets.clock", {
  position = "right",
  update_freq = 1,
  icon = { string = "󰥔", color = colors.mauve },
  label = { string = "--/-- · --:--" },
})

local function refresh()
  clock:set({
    label = {
      string = hovered and os.date("%a %m/%d · %H:%M:%S") or os.date("%m/%d · %H:%M"),
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
