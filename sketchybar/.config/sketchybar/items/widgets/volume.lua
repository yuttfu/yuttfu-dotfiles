local colors = require("colors")

local volume = sbar.add("item", "widgets.volume", {
  position = "right",
  update_freq = 60,
  icon = { string = "󰕾", color = colors.teal },
  label = { string = "--%" },
  click_script = "osascript -e 'set volume output muted not (output muted of (get volume settings))'",
})

local function update(level)
  level = tonumber(level)
  if not level then
    return
  end

  local icon = "󰕾"
  if level == 0 then
    icon = "󰖁"
  elseif level < 35 then
    icon = "󰕿"
  elseif level < 70 then
    icon = "󰖀"
  end

  volume:set({
    icon = { string = icon },
    label = { string = string.format("%02d%%", level) },
  })
end

volume:subscribe("volume_change", function(env)
  update(env.INFO)
end)

volume:subscribe({ "forced", "routine", "system_woke" }, function()
  sbar.exec("osascript -e 'output volume of (get volume settings)'", update)
end)
