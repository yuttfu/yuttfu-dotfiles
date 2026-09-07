sbar = require("sketchybar")

sbar.begin_config()

sbar.add("event", "aerospace_workspace_change")
sbar.add("event", "aerospace_focus_change")
sbar.add("event", "desktop_theme_changed")

require("bar")
require("default")
require("items")

require("theme_runtime").start()

sbar.end_config()
sbar.event_loop()
