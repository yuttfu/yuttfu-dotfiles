local colors = require("colors")

local battery = sbar.add("item", "widgets.battery", {
  position = "right",
  update_freq = 60,
  icon = { string = "󰁹", color = colors.green },
  label = { string = "--%" },
})

local function refresh()
  sbar.exec("pmset -g batt", function(output)
    if type(output) ~= "string" then
      battery:set({ drawing = false })
      return
    end

    local charge = tonumber(output:match("(%d+)%%"))
    if not charge then
      battery:set({ drawing = false })
      return
    end

    local charging = output:find("AC Power", 1, true) ~= nil
    local icon = charging and "󰂄" or "󰁹"
    local color = colors.green
    if not charging and charge <= 20 then
      icon = "󰂎"
      color = colors.red
    elseif not charging and charge <= 50 then
      icon = "󰁾"
      color = colors.yellow
    end

    battery:set({
      drawing = true,
      icon = { string = icon, color = color },
      label = { string = string.format("%02d%%", charge) },
    })
  end)
end

battery:subscribe({ "forced", "routine", "power_source_change", "system_woke" }, refresh)
