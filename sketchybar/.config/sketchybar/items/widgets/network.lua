local colors = require("colors")

local network = sbar.add("item", "widgets.network", {
  position = "right",
  update_freq = 30,
  icon = { string = "󰖩", color = colors.teal },
  label = { string = "Wi-Fi" },
  click_script = "open 'x-apple.systempreferences:com.apple.Network-Settings.extension'",
})

local function refresh()
  sbar.exec("ipconfig getifaddr en0", function(address)
    local connected = type(address) == "string" and address:match("%d+%.%d+%.%d+%.%d+") ~= nil
    network:set({
      icon = {
        string = connected and "󰖩" or "󰖪",
        color = connected and colors.teal or colors.red,
      },
      label = {
        string = connected and "Wi-Fi" or "Offline",
        color = connected and colors.text or colors.red,
      },
    })
  end)
end

network:subscribe({ "forced", "routine", "wifi_change", "system_woke" }, refresh)
