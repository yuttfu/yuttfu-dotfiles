local aliases = {
  ["App Store"] = ":app_store:",
  ["Arc"] = ":arc:",
  ["Code"] = ":code:",
  ["Discord"] = ":discord:",
  ["Finder"] = ":finder:",
  ["Google Chrome"] = ":google_chrome:",
  ["Music"] = ":music:",
  ["Neovide"] = ":neovide:",
  ["Notion"] = ":notion:",
  ["Safari"] = ":safari:",
  ["Spotify"] = ":spotify:",
  ["WeChat"] = ":wechat:",
  ["WezTerm"] = ":wezterm:",
  ["wezterm-gui"] = ":wezterm:",
  ["Zotero"] = ":zotero:",
}

return function(app_name)
  return aliases[app_name] or ":default:"
end
