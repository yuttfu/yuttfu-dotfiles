local battery = {}

function battery.parse(output)
  if type(output) ~= "string" then
    return { available = false, charge = 0, charging = false }
  end

  local charge = tonumber(output:match("(%d+)%%"))
  if not charge then
    return { available = false, charge = 0, charging = false }
  end

  return {
    available = true,
    charge = math.max(0, math.min(100, math.floor(charge))),
    charging = output:find("AC Power", 1, true) ~= nil,
  }
end

function battery.tone(snapshot)
  if not snapshot.available then
    return "unavailable"
  end
  if snapshot.charge <= 20 then
    return "critical"
  end
  if snapshot.charging then
    return "charging"
  end
  return "neutral"
end

function battery.icon(snapshot)
  local tone = battery.tone(snapshot)
  if tone == "critical" then
    return "󰂎"
  end
  if tone == "charging" then
    return "󱐋"
  end
  return "󰁹"
end

return battery
