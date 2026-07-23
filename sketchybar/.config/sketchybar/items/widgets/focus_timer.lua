local colors = require("colors")
local settings = require("settings")
local timer = require("items.widgets.focus_timer_state")

local state = timer.normalize(nil)
local hovered = false
local popup_visible = false
local state_path = "$HOME/Library/Application Support/yuttfu-sketchybar/study-timer.json"
local popup_width = 152

local function now()
  return os.time()
end

local function state_label()
  local elapsed = timer.elapsed(state, now())
  if state.running then
    return "学习中", "󱎫", colors.green
  end
  if elapsed == 0 then
    return "未开始", "󰔟", colors.overlay0
  end
  return "已暂停", "󰏤", colors.peach
end

local focus_timer = sbar.add("item", "focus_timer", {
  position = "right",
  update_freq = 1,
  width = 64,
  icon = { string = "󰔟", color = colors.overlay0 },
  label = { string = "00m" },
  popup = {
    align = "right",
    drawing = false,
    background = {
      color = colors.with_alpha(colors.mantle, 0.96),
      corner_radius = 12,
      border_width = 1,
      border_color = colors.surface1,
    },
  },
})

local popup_status = sbar.add("item", "focus_timer.status", {
  position = "popup.focus_timer",
  width = popup_width,
  icon = { drawing = false },
  label = {
    string = "未开始",
    width = popup_width,
    align = "center",
    font = { family = settings.font.text, style = "Semibold", size = 12.0 },
  },
  background = { drawing = false },
})

local popup_readout = sbar.add("item", "focus_timer.readout", {
  position = "popup.focus_timer",
  width = popup_width,
  icon = { drawing = false },
  label = {
    string = "00:00:00",
    width = popup_width,
    align = "center",
    font = { family = settings.font.mono, style = "Bold", size = 30.0 },
  },
  background = { drawing = false },
})

local start_control = sbar.add("item", "focus_timer.start", {
  position = "popup.focus_timer",
  width = popup_width,
  icon = { drawing = false },
  label = { string = "开始", width = popup_width, align = "center" },
})

local pause_control = sbar.add("item", "focus_timer.pause", {
  position = "popup.focus_timer",
  width = popup_width,
  icon = { drawing = false },
  label = { string = "暂停", width = popup_width, align = "center" },
  drawing = false,
})

local reset_control = sbar.add("item", "focus_timer.reset", {
  position = "popup.focus_timer",
  width = popup_width,
  icon = { drawing = false },
  label = { string = "复位", width = popup_width, align = "center" },
})

local function encode_state(snapshot)
  local started_at = snapshot.started_at and tostring(snapshot.started_at) or "null"
  return string.format(
    '{"elapsed_seconds":%d,"started_at":%s,"running":%s}',
    snapshot.elapsed_seconds,
    started_at,
    snapshot.running and "true" or "false"
  )
end

local function persist()
  local payload = encode_state(state)
  local command = string.format(
    "mkdir -p \"$HOME/Library/Application Support/yuttfu-sketchybar\" && printf %%s %q > \"%s\"",
    payload,
    state_path
  )
  sbar.exec(command)
end

local function refresh()
  local name, icon, color = state_label()
  local expanded = hovered
  local label = expanded and string.format("%s · %s", name, timer.precise(state, now()))
    or timer.compact(state, now())

  focus_timer:set({
    icon = { string = icon, color = color },
    label = { string = label },
    width = expanded and 132 or 64,
    background = {
      color = colors.with_alpha(colors.surface0, expanded and 0.98 or 0.88),
      border_color = color,
      border_width = 1,
      height = settings.item.height,
      corner_radius = settings.item.corner_radius,
    },
    popup = { drawing = popup_visible },
  })
  popup_status:set({ label = { string = name, color = color } })
  popup_readout:set({ label = { string = timer.precise(state, now()), color = colors.text } })
  start_control:set({ drawing = not state.running })
  pause_control:set({ drawing = state.running })
end

local function close_popup()
  popup_visible = false
end

local function pause_and_persist()
  state = timer.pause(state, now())
  persist()
  close_popup()
  refresh()
end

focus_timer:subscribe({ "forced", "routine", "system_woke" }, refresh)

focus_timer:subscribe("system_will_sleep", function()
  if state.running then
    state = timer.pause(state, now())
    persist()
  end
  refresh()
end)

focus_timer:subscribe("mouse.entered", function()
  hovered = true
  refresh()
end)

focus_timer:subscribe("mouse.exited", function()
  hovered = false
  refresh()
end)

focus_timer:subscribe("mouse.clicked", function(env)
  if env.BUTTON == "left" then
    popup_visible = not popup_visible
    refresh()
  end
end)

start_control:subscribe("mouse.clicked", function()
  state = timer.start(state, now())
  persist()
  close_popup()
  refresh()
end)

pause_control:subscribe("mouse.clicked", pause_and_persist)

reset_control:subscribe("mouse.clicked", function()
  state = timer.reset(state)
  persist()
  close_popup()
  refresh()
end)

sbar.exec(string.format("cat \"%s\" 2>/dev/null", state_path), function(output)
  state = timer.from_persisted(output)
  if state.running then
    state = timer.pause(state, now())
    persist()
  end
  refresh()
end)
