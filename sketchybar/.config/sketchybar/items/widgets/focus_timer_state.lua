local focus_timer_state = {}

local function non_negative_integer(value)
  value = tonumber(value)
  if not value or value < 0 then
    return 0
  end
  return math.floor(value)
end

function focus_timer_state.normalize(snapshot)
  snapshot = type(snapshot) == "table" and snapshot or {}
  local elapsed_seconds = non_negative_integer(snapshot.elapsed_seconds)
  local started_at = tonumber(snapshot.started_at)
  local running = snapshot.running == true and started_at ~= nil

  return {
    elapsed_seconds = elapsed_seconds,
    started_at = running and math.floor(started_at) or nil,
    running = running,
  }
end

function focus_timer_state.from_persisted(payload)
  if type(payload) == "table" then
    return focus_timer_state.normalize(payload)
  end
  if type(payload) ~= "string" then
    return focus_timer_state.normalize(nil)
  end

  return focus_timer_state.normalize({
    elapsed_seconds = tonumber(payload:match('"elapsed_seconds"%s*:%s*(%d+)')),
    started_at = tonumber(payload:match('"started_at"%s*:%s*(%d+)')),
    running = payload:match('"running"%s*:%s*(true|false)') == "true",
  })
end

function focus_timer_state.elapsed(snapshot, now)
  snapshot = focus_timer_state.normalize(snapshot)
  if not snapshot.running then
    return snapshot.elapsed_seconds
  end

  now = tonumber(now) or snapshot.started_at
  return snapshot.elapsed_seconds + math.max(0, math.floor(now) - snapshot.started_at)
end

function focus_timer_state.start(snapshot, now)
  snapshot = focus_timer_state.normalize(snapshot)
  if snapshot.running then
    return snapshot
  end

  snapshot.started_at = math.floor(tonumber(now) or os.time())
  snapshot.running = true
  return snapshot
end

function focus_timer_state.pause(snapshot, now)
  snapshot = focus_timer_state.normalize(snapshot)
  snapshot.elapsed_seconds = focus_timer_state.elapsed(snapshot, now)
  snapshot.started_at = nil
  snapshot.running = false
  return snapshot
end

function focus_timer_state.reset(_)
  return focus_timer_state.normalize(nil)
end

function focus_timer_state.compact(snapshot, now)
  return string.format("%02dm", math.floor(focus_timer_state.elapsed(snapshot, now) / 60))
end

function focus_timer_state.precise(snapshot, now)
  local seconds = focus_timer_state.elapsed(snapshot, now)
  local hours = math.floor(seconds / 3600)
  local minutes = math.floor((seconds % 3600) / 60)
  return string.format("%02d:%02d:%02d", hours, minutes, seconds % 60)
end

return focus_timer_state
