local system_metrics_state = {}

local function clamp(value)
  value = tonumber(value) or 0
  return math.max(0, math.min(100, math.floor(value + 0.5)))
end

function system_metrics_state.parse(payload)
  payload = type(payload) == "string" and payload or ""
  return {
    cpu = clamp(payload:match("cpu=([^%s]+)")),
    memory = clamp(payload:match("mem=([^%s]+)")),
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

return system_metrics_state
