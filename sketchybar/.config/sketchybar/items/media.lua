local colors = require("colors")

local media = sbar.add("item", "media", {
  position = "center",
  drawing = false,
  updates = true,
  icon = {
    string = "󰎆",
    color = colors.mauve,
  },
  label = {
    max_chars = 32,
  },
  background = {
    color = colors.with_alpha(colors.surface0, 0.88),
  },
})

media:subscribe("media_change", function(env)
  local info = env.INFO
  if type(info) ~= "table" then
    media:set({ drawing = false })
    return
  end

  local playing = info.state == "playing"
  local artist = info.artist or ""
  local title = info.title or ""
  local text = artist ~= "" and title ~= "" and (artist .. " — " .. title) or title

  media:set({
    drawing = playing and text ~= "",
    label = { string = text },
  })
end)
