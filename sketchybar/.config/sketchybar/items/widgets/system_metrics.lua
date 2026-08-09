local colors = require("colors")
local settings = require("settings")
local metrics_state = require("items.widgets.system_metrics_state")

local current = metrics_state.parse("")
local graph_width = 24
local metric_width = 56
local value_width = 32

local function meter_background()
  return {
    color = colors.with_alpha(colors.surface0, 0.68),
    height = settings.item.height,
    corner_radius = settings.item.corner_radius,
    border_width = 1,
    border_color = colors.with_alpha(colors.surface1, 0.58),
  }
end

local memory_graph = sbar.add("graph", "widgets.memory.graph", graph_width, {
  position = "right",
  graph = {
    color = colors.mauve,
    fill_color = colors.with_alpha(colors.mauve, 0.12),
    line_width = 1.5,
  },
  background = { drawing = false },
  padding_left = 0,
  padding_right = 6,
})

local memory = sbar.add("item", "widgets.memory", {
  position = "right",
  width = metric_width,
  padding_left = 0,
  padding_right = 0,
  icon = {
    string = "󰘚",
    color = colors.mauve,
    padding_left = 8,
    padding_right = 3,
    font = { family = settings.font.mono, style = "Semibold", size = 12.5 },
  },
  label = {
    string = "--%",
    align = "right",
    width = value_width,
    padding_left = 0,
    padding_right = 7,
    font = { family = settings.font.mono, style = "Semibold", size = 10.5 },
  },
  background = { drawing = false },
})

local memory_bracket = sbar.add("bracket", "widgets.memory.bracket", {
  "widgets.memory",
  "widgets.memory.graph",
}, {
  padding_left = 0,
  padding_right = 0,
  background = meter_background(),
})

sbar.add("item", "widgets.metrics.gap", {
  position = "right",
  width = settings.item.group_gap,
  padding_left = 0,
  padding_right = 0,
  icon = { drawing = false },
  label = { drawing = false },
  background = { drawing = false },
})

local cpu_graph = sbar.add("graph", "widgets.cpu.graph", graph_width, {
  position = "right",
  graph = {
    color = colors.lavender,
    fill_color = colors.with_alpha(colors.lavender, 0.12),
    line_width = 1.5,
  },
  background = { drawing = false },
  padding_left = 0,
  padding_right = 6,
})

local cpu = sbar.add("item", "widgets.cpu", {
  position = "right",
  update_freq = 5,
  width = metric_width,
  padding_left = 0,
  padding_right = 0,
  icon = {
    string = "󰍛",
    color = colors.lavender,
    padding_left = 8,
    padding_right = 3,
    font = { family = settings.font.mono, style = "Semibold", size = 12.5 },
  },
  label = {
    string = "--%",
    align = "right",
    width = value_width,
    padding_left = 0,
    padding_right = 7,
    font = { family = settings.font.mono, style = "Semibold", size = 10.5 },
  },
  background = { drawing = false },
})

local cpu_bracket = sbar.add("bracket", "widgets.cpu.bracket", {
  "widgets.cpu",
  "widgets.cpu.graph",
}, {
  padding_left = 0,
  padding_right = 0,
  background = meter_background(),
})

sbar.add("item", "widgets.metrics.leading_gap", {
  position = "right",
  width = settings.item.group_gap,
  padding_left = 0,
  padding_right = 0,
  icon = { drawing = false },
  label = { drawing = false },
  background = { drawing = false },
})

local function severity_color(value, normal)
  local severity = metrics_state.severity(value)
  if severity == "critical" then
    return colors.red
  end
  if severity == "warning" then
    return colors.peach
  end
  return normal
end

local function percentage_label(value, valid)
  if not valid then
    return "--%"
  end
  return string.format("%d%%", value)
end

local function render()
  local cpu_color = current.cpu_valid and severity_color(current.cpu, colors.lavender) or colors.overlay0
  local memory_color = current.memory_valid and severity_color(current.memory, colors.mauve) or colors.overlay0

  cpu:set({
    icon = { color = cpu_color },
    label = { string = percentage_label(current.cpu, current.cpu_valid), color = colors.text },
  })
  memory:set({
    icon = { color = memory_color },
    label = { string = percentage_label(current.memory, current.memory_valid), color = colors.text },
  })

  cpu_graph:set({
    graph = {
      color = cpu_color,
      fill_color = colors.with_alpha(cpu_color, 0.12),
    },
  })
  memory_graph:set({
    graph = {
      color = memory_color,
      fill_color = colors.with_alpha(memory_color, 0.12),
    },
  })

  cpu_bracket:set({
    background = {
      border_color = colors.with_alpha(cpu_color, metrics_state.severity(current.cpu) == "normal" and 0.34 or 0.72),
    },
  })
  memory_bracket:set({
    background = {
      border_color = colors.with_alpha(memory_color, metrics_state.severity(current.memory) == "normal" and 0.34 or 0.72),
    },
  })
end

local function refresh()
  sbar.exec("\"$CONFIG_DIR/helpers/system_metrics.sh\"", function(output)
    current = metrics_state.parse(output)
    cpu_graph:push({ current.cpu_valid and metrics_state.ratio(current.cpu) or 0 })
    memory_graph:push({ current.memory_valid and metrics_state.ratio(current.memory) or 0 })
    render()
  end)
end

cpu:subscribe({ "forced", "routine", "system_woke" }, refresh)
render()
