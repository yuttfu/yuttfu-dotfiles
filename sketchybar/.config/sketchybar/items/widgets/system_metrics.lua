local colors = require("colors")
local metrics_state = require("items.widgets.system_metrics_state")

local hovered = false
local current = metrics_state.parse("")

local metrics = sbar.add("item", "widgets.system_metrics", {
  position = "right",
  update_freq = 5,
  icon = { string = "󰍛", color = colors.lavender },
  label = { string = metrics_state.compact(current) },
})

local function render()
  local pressure = math.max(current.cpu, current.memory)
  local color = colors.lavender
  if pressure >= 90 then
    color = colors.red
  elseif pressure >= 70 then
    color = colors.peach
  end

  metrics:set({
    icon = { color = color },
    label = {
      string = hovered and metrics_state.expanded(current) or metrics_state.compact(current),
    },
    background = { border_color = colors.with_alpha(color, 0.72) },
  })
end

local function refresh()
  sbar.exec("\"$CONFIG_DIR/helpers/system_metrics.sh\"", function(output)
    current = metrics_state.parse(output)
    render()
  end)
end

metrics:subscribe({ "forced", "routine", "system_woke" }, refresh)
metrics:subscribe("mouse.entered", function()
  hovered = true
  render()
end)
metrics:subscribe("mouse.exited", function()
  hovered = false
  render()
end)
