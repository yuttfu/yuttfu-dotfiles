local colors = require("colors")
local settings = require("settings")
local timer = require("items.widgets.focus_timer_state")

local state = timer.normalize(nil)
local hovered = false
local popup_visible = false
local state_path = "$HOME/Library/Application Support/yuttfu-sketchybar/study-timer.json"

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
  position = "e",
  update_freq = 1,
  width = 26,
  icon = { string = "󰔟", color = colors.overlay0 },
  label = { drawing = false },
  background = {
    color = colors.with_alpha(colors.overlay0, 0.22),
    height = 26,
    corner_radius = 13,
    border_width = 1,
    border_color = colors.overlay0,
  },
  popup = {
    align = "center",
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
  icon = { drawing = false },
  label = {
    string = "未开始",
    font = { family = settings.font.text, style = "Semibold", size = 12.0 },
  },
  background = { drawing = false },
})

local popup_readout = sbar.add("item", "focus_timer.readout", {
  position = "popup.focus_timer",
  icon = { drawing = false },
  label = {
    string = "00:00:00",
    font = { family = settings.font.mono, style = "Bold", size = 30.0 },
  },
  background = { drawing = false },
})

local start_control = sbar.add("item", "focus_timer.start", {
  position = "popup.focus_timer",
  icon = { string = "󰐊", color = colors.green },
  label = { string = "开始" },
})

local pause_control = sbar.add("item", "focus_timer.pause", {
  position = "popup.focus_timer",
  icon = { string = "󰏤", color = colors.peach },
  label = { string = "暂停" },
  drawing = false,
})

local reset_control = sbar.add("item", "focus_timer.reset", {
  position = "popup.focus_timer",
  icon = { string = "󰑓", color = colors.subtext0 },
  label = { string = "复位" },
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

  focus_timer:set({
    icon = { string = icon, color = color },
    width = expanded and 32 or 26,
    background = {
      color = colors.with_alpha(color, expanded and 0.32 or 0.22),
      border_color = color,
      border_width = expanded and 2 or 1,
      height = expanded and 32 or 26,
      corner_radius = expanded and 16 or 13,
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
