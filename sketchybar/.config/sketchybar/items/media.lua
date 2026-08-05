local colors = require("colors")

local title = ""
local artist = ""
local artwork = ""
local state = "unavailable"
local permission = "granted"
local hovered = false
local auto_expanded = false
local track_generation = 0

local cover = sbar.add("item", "media.cover", {
  position = "center",
  drawing = false,
  width = 24,
  icon = { drawing = false },
  label = { drawing = false },
  background = {
    color = colors.transparent,
    border_width = 0,
    height = 22,
    corner_radius = 5,
    image = {
      drawing = false,
      scale = 0.10,
      corner_radius = 5,
    },
  },
})

local media = sbar.add("item", "media", {
  position = "center",
  drawing = false,
  updates = true,
  icon = {
    string = "󰎆",
    color = colors.green,
  },
  label = {
    max_chars = 28,
  },
  background = {
    drawing = false,
  },
})

sbar.add("bracket", "media.bracket", { "media.cover", "media" }, {
  background = {
    color = colors.with_alpha(colors.surface0, 0.88),
    border_color = colors.surface1,
    border_width = 1,
  },
})

local function render()
  local expanded = hovered or auto_expanded
  local has_artwork = artwork ~= ""
  local label = title
  if expanded and artist ~= "" then
    label = title .. "  ·  " .. artist
  end
  media:set({
    drawing = title ~= "" and state ~= "stopped" and state ~= "unavailable",
    icon = {
      drawing = not has_artwork,
      string = permission == "missing" and "󰌾" or (state == "paused" and "󰐊" or "󰎆"),
      color = state == "playing" and colors.green or colors.overlay1,
    },
    label = {
      string = label,
      color = state == "playing" and colors.text or colors.overlay1,
      max_chars = expanded and 32 or 18,
    },
  })
  cover:set({
    drawing = title ~= "" and has_artwork and state ~= "stopped" and state ~= "unavailable",
    background = {
      image = {
        drawing = has_artwork,
        string = artwork,
      },
    },
  })
end

media:subscribe("yuttfu_media_changed", function(env)
  local next_title = env.TITLE or ""
  local next_artist = env.ARTIST or ""
  local next_artwork = env.ARTWORK or ""
  local track_changed = next_title ~= "" and (next_title ~= title or next_artist ~= artist)

  title = next_title
  artist = next_artist
  artwork = next_artwork
  state = env.STATE or "unavailable"
  permission = env.PERMISSION or "granted"

  if track_changed then
    track_generation = track_generation + 1
    local generation = track_generation
    auto_expanded = true
    sbar.delay(5, function()
      if generation == track_generation then
        auto_expanded = false
        render()
      end
    end)
  end
  render()
end)

media:subscribe("mouse.entered", function()
  hovered = true
  render()
end)

cover:subscribe("mouse.entered", function()
  hovered = true
  render()
end)

media:subscribe("mouse.exited", function()
  hovered = false
  render()
end)

cover:subscribe("mouse.exited", function()
  hovered = false
  render()
end)

media:subscribe("mouse.clicked", function()
  sbar.exec("/usr/bin/open -g 'yuttfu-media://toggle-panel'")
end)

cover:subscribe("mouse.clicked", function()
  sbar.exec("/usr/bin/open -g 'yuttfu-media://toggle-panel'")
end)
