local colors = require("colors")
local settings = require("settings")
local app_icon = require("helpers.app_icons")

local spaces = {}
local focused_workspace = settings.workspaces[1]

local function trim(value)
  if type(value) ~= "string" then
    return ""
  end
  return value:match("^%s*(.-)%s*$") or ""
end

local function app_labels(output)
  if type(output) ~= "string" then
    return ""
  end

  local labels = {}
  local seen = {}
  for app in output:gmatch("[^\r\n]+") do
    local app_name = trim(app)
    if app_name ~= "" and not seen[app_name] then
      seen[app_name] = true
      table.insert(labels, app_icon(app_name))
    end
  end
  return table.concat(labels, " ")
end

local function refresh_space(workspace)
  local item = spaces[workspace]
  sbar.exec("aerospace list-windows --workspace " .. workspace .. " --format '%{app-name}'", function(output)
    local labels = app_labels(output)
    local occupied = labels ~= ""
    local focused = workspace == focused_workspace

    item:set({
      icon = {
        string = workspace,
        color = focused and colors.base or colors.text,
      },
      label = {
        string = labels,
        drawing = occupied,
        color = focused and colors.base or colors.subtext0,
        font = { family = settings.font.app, style = "Regular", size = 14.0 },
      },
      background = {
        color = focused and colors.lavender or (occupied and colors.surface0 or colors.transparent),
        border_color = focused and colors.lavender or colors.surface1,
      },
    })
  end)
end

local function refresh_all(workspace)
  focused_workspace = trim(workspace) ~= "" and trim(workspace) or focused_workspace
  for _, name in ipairs(settings.workspaces) do
    refresh_space(name)
  end
end

for _, workspace in ipairs(settings.workspaces) do
  spaces[workspace] = sbar.add("item", "space." .. workspace, {
    position = "left",
    icon = {
      string = workspace,
      padding_left = 7,
      padding_right = 7,
    },
    label = {
      drawing = false,
      padding_left = 0,
      padding_right = 7,
    },
    click_script = "aerospace workspace " .. workspace,
  })
end

local observer = sbar.add("item", "aerospace.observer", {
  drawing = false,
  updates = true,
})

observer:subscribe({ "aerospace_workspace_change", "aerospace_focus_change", "system_woke" }, function(env)
  if env.FOCUSED_WORKSPACE then
    refresh_all(env.FOCUSED_WORKSPACE)
    return
  end

  sbar.exec("aerospace list-workspaces --focused --format '%{workspace}'", function(workspace)
    refresh_all(workspace)
  end)
end)

sbar.exec("aerospace list-workspaces --focused --format '%{workspace}'", function(workspace)
  refresh_all(workspace)
end)
