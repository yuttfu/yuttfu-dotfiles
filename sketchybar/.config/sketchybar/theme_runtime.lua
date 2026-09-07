-- Recolor existing items without restarting Lua or losing graph history.
local colors = require("colors")
local current = require("desktop-theme")
local callbacks = {}
local runtime = {}

function runtime.current() return current end
function runtime.on_change(callback) callbacks[#callbacks + 1] = callback end

function runtime.reload()
  local path = assert(package.searchpath("desktop-theme", package.path))
  local updated = dofile(path)
  assert(type(updated.colors) == "table" and type(updated.id) == "string")
  local changed = updated.id ~= current.id
  for key, value in pairs(updated.colors) do
    if colors[key] ~= value then changed = true end
  end
  if not changed then return end
  for key, value in pairs(updated.colors) do colors[key] = value end
  current = updated
  package.loaded["desktop-theme"] = updated
  sbar.animate("tanh", 12, function()
    for _, callback in ipairs(callbacks) do callback(updated) end
  end)
end

function runtime.start()
  local observer = sbar.add("item", "theme.observer", { drawing = false, updates = true })
  observer:subscribe("desktop_theme_changed", runtime.reload)
end
return runtime
