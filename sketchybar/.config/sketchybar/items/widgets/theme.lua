local colors = require("colors")
local settings = require("settings")
local runtime = require("theme_runtime")
local theme = runtime.current()
local busy = false
local rows = {}

local picker = sbar.add("item", "widgets.theme", {
  position = "right", width = 96, align = "center", y_offset = 0,
  icon = { string = "◈", color = colors.lavender, width = 18, align = "center", padding_left = 0, padding_right = 0 },
  label = { string = theme.label, color = colors.text, align = "center", padding_left = 4,
    font = { family = settings.font.text, style = "Medium", size = 11 }, padding_right = 0 },
  background = { color = colors.surface0, border_color = colors.surface1, height = 26, corner_radius = 9 },
  popup = { align = "right", drawing = false },
})
local heading = sbar.add("item", "widgets.theme.heading", {
  position = "popup.widgets.theme", width = 238,
  icon = { drawing = false }, background = { drawing = false },
  label = { string = "桌面配色", color = colors.subtext0, padding_left = 12,
    font = { family = settings.font.text, style = "Semibold", size = 11 } },
})
local footer

local function choose(id)
  if busy then return end
  picker:set({ popup = { drawing = false } })
  busy = true
  picker:set({ icon = { string = "…" }, label = { string = "切换中…" } })
  sbar.exec('"$HOME/.local/bin/terminal-theme" ' .. id, function(_, exit_code)
    busy = false
    if exit_code == 0 then
      -- The CLI also sends the event; reload is idempotent if it already arrived.
      runtime.reload()
      picker:set({ icon = { string = "◈" }, label = { string = theme.label } })
      footer:set({ label = { string = "已应用 · 终端重载 ⌘⇧," } })
    else
      picker:set({ icon = { string = "!", color = colors.red }, label = { string = "切换失败" } })
      footer:set({ label = { string = "切换失败，请检查 terminal-theme" } })
    end
  end)
end

for _, option in ipairs(theme.themes) do
  assert(option.id:match("^[a-z0-9-]+$"), "Invalid theme ID")
  local selected = option.id == theme.id
  local row = sbar.add("item", "widgets.theme." .. option.id, {
    position = "popup.widgets.theme", width = 238,
    icon = { string = "●", width = 24, align = "center", padding_left = 8,
      color = option.accent, font = { family = settings.font.text, style = "Regular", size = 13 } },
    label = { string = (selected and "✓  " or "    ") .. option.label,
      color = selected and colors.lavender or colors.text,
      font = { family = settings.font.text, style = "Medium", size = 11 }, padding_right = 10 },
    background = { drawing = true, color = selected and colors.surface0 or colors.base,
      border_width = 0, corner_radius = 6 },
  })
  rows[option.id] = row
  row:subscribe("mouse.clicked", function() choose(option.id) end)
  row:subscribe("mouse.entered", function()
    row:set({ background = { color = colors.surface1 } })
  end)
  row:subscribe("mouse.exited", function()
    row:set({ background = { color = option.id == theme.id and colors.surface0 or colors.base } })
  end)
end
footer = sbar.add("item", "widgets.theme.footer", {
  position = "popup.widgets.theme", width = 238,
  icon = { drawing = false }, background = { drawing = false },
  label = { string = "桌面即时生效 · 终端 ⌘⇧,", color = colors.subtext0, padding_left = 12,
    font = { family = settings.font.text, style = "Regular", size = 10 } },
})
picker:subscribe("mouse.clicked", function()
  if not busy then picker:set({ popup = { drawing = "toggle" } }) end
end)
picker:subscribe("mouse.exited.global", function()
  picker:set({ popup = { drawing = false } })
end)
runtime.on_change(function(updated)
  theme = updated
  picker:set({ icon = { string = "◈", color = colors.lavender },
    label = { string = theme.label, color = colors.text },
    background = { color = colors.surface0, border_color = colors.surface1 },
    popup = { background = { color = colors.with_alpha(colors.mantle, 0.96), border_color = colors.surface1 } } })
  heading:set({ label = { color = colors.subtext0 } })
  footer:set({ label = { color = colors.subtext0 } })
  for _, option in ipairs(updated.themes) do
    local selected = option.id == updated.id
    rows[option.id]:set({ icon = { color = option.accent },
      label = { string = (selected and "✓  " or "    ") .. option.label,
        color = selected and colors.lavender or colors.text },
      background = { color = selected and colors.surface0 or colors.base } })
  end
end)
