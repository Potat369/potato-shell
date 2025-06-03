local Widget = require("astal.gtk3.widget")
local gtk = require("astal.gtk3")
local astal = require("astal")
local Anchor = gtk.Astal.WindowAnchor
local Notifd = astal.require("AstalNotifd")

local notifd = Notifd.get_default()

return function()
	return Widget.Window({
		anchor = Anchor.RIGHT + Anchor.TOP,
		layer = "BACKGROUND",
		Widget.Box({
			vertical = true,
			spacing = 4,
		}),
	})
end
