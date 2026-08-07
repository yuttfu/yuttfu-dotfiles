sbar = require("sketchybar")

sbar.begin_config()

sbar.add("event", "aerospace_workspace_change")
sbar.add("event", "aerospace_focus_change")

require("bar")
require("default")
require("items")

sbar.end_config()
sbar.event_loop()
