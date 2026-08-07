local colors = require("colors")
local recording_state = require("items.widgets.recording_state")

local recording = sbar.add("item", "widgets.recording", {
  position = "right",
  drawing = false,
  update_freq = 2,
  icon = { string = "󰑋", color = colors.overlay0 },
  label = { string = "OBS", color = colors.overlay0 },
  click_script = "open -a OBS",
})

local function render(state)
  local active = state == "recording"
  local ready = state == "ready"
  local color = active and colors.red or colors.overlay0
  recording:set({
    drawing = active or ready,
    icon = {
      string = active and "󰑋" or "󰕧",
      color = color,
    },
    label = {
      string = active and "REC" or "OBS",
      color = color,
    },
    background = {
      border_color = active and colors.red or colors.surface1,
    },
  })
end

local function refresh()
  sbar.exec("\"$CONFIG_DIR/helpers/recording_status.sh\"", function(output)
    render(recording_state.normalize(output))
  end)
end

recording:subscribe({ "forced", "routine", "system_woke" }, refresh)
