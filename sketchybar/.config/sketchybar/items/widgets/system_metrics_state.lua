local system_metrics_state = {}

local function clamp(value)
  value = tonumber(value) or 0
  return math.max(0, math.min(100, math.floor(value + 0.5)))
end

local function parse_value(value)
  local numeric = tonumber(value)
  if not numeric then
    return 0, false
  end
  return clamp(numeric), true
end

function system_metrics_state.parse(payload)
  payload = type(payload) == "string" and payload or ""
  local cpu, cpu_valid = parse_value(payload:match("cpu=([^%s]+)"))
  local memory, memory_valid = parse_value(payload:match("mem=([^%s]+)"))
  return {
    cpu = cpu,
    memory = memory,
    cpu_valid = cpu_valid,
    memory_valid = memory_valid,
  }
end

function system_metrics_state.compact(snapshot)
  snapshot = snapshot or { cpu = 0, memory = 0 }
  return string.format("%d%% · %d%%", snapshot.cpu, snapshot.memory)
end

function system_metrics_state.expanded(snapshot)
  snapshot = snapshot or { cpu = 0, memory = 0 }
  return string.format("CPU %d%% · RAM %d%%", snapshot.cpu, snapshot.memory)
end

function system_metrics_state.cpu_label(snapshot)
  if not snapshot or snapshot.cpu_valid == false then
    return "CPU --"
  end
  return string.format("CPU %d%%", clamp(snapshot.cpu))
end

function system_metrics_state.memory_label(snapshot)
  if not snapshot or snapshot.memory_valid == false then
    return "RAM --"
  end
  return string.format("RAM %d%%", clamp(snapshot.memory))
end

function system_metrics_state.ratio(value)
  return clamp(value) / 100
end

function system_metrics_state.severity(value)
  value = clamp(value)
  if value >= 90 then
    return "critical"
  end
  if value >= 70 then
    return "warning"
  end
  return "normal"
end

return system_metrics_state
