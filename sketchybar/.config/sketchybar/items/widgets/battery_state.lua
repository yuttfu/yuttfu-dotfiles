local battery = {}
local levels = { "󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹" }

function battery.parse(output)
  if type(output) ~= "string" then output = "" end
  local charge = tonumber(output:match("(%d+)%%"))
  if not charge then return { available = false, charge = 0, charging = false } end
  charge = math.max(0, math.min(100, math.floor(charge)))
  local ac_power = output:find("AC Power", 1, true) ~= nil
  local status = output:match("%%;%s*([^;\n]+)") or "unknown"
  status = status:match("^%s*(.-)%s*$")
  local charging = status == "charging"
  local state = "battery"
  if charging then state = "charging"
  elseif ac_power and status == "charged" and charge == 100 then state = "full"
  elseif ac_power and (status == "not charging" or status == "charged") then state = "hold"
  elseif ac_power and status == "discharging" then state = "plugged_discharge"
  elseif status ~= "discharging" then state = "unknown" end
  return {
    available = true, charge = charge, ac_power = ac_power, charging = charging, state = state,
    remaining = output:match("(%d+:%d+)%s+remaining"),
  }
end

function battery.tone(snapshot)
  if not snapshot.available then return "unavailable" end
  if snapshot.charging then return "charging" end
  if snapshot.charge <= 20 then return "critical" end
  if snapshot.state == "full" then return "full" end
  return "neutral"
end

function battery.icon(snapshot)
  if snapshot.charging then return "󰂄" end
  if snapshot.state == "hold" then return "󰚥" end
  return levels[math.floor(snapshot.charge / 10) + 1]
end

function battery.description(snapshot)
  local labels = { battery = "电池供电", charging = "正在充电", full = "已充满 · 接电",
    hold = "接电 · 暂未充电", plugged_discharge = "接电 · 电池仍在放电", unknown = "电源状态未知" }
  return labels[snapshot.state] or "电池不可用"
end

function battery.detail(snapshot)
  if snapshot.state == "full" or snapshot.state == "hold" then return "由电源供电" end
  if snapshot.remaining and snapshot.remaining ~= "0:00" then
    return (snapshot.charging and "预计充满 " or "预计续航 ") .. snapshot.remaining
  end
  return "剩余时间暂不可用"
end

return battery
