local recording_state = {}

function recording_state.normalize(payload)
  local value = type(payload) == "string" and payload:match("^%s*(.-)%s*$") or ""
  if value == "recording" or value == "ready" then
    return value
  end
  return "off"
end

return recording_state
