local Widget = require("astal.gtk3.widget")
local gtk = require("astal.gtk3")
local astal = require("astal")
local Anchor = gtk.Astal.WindowAnchor
local astalify = gtk.astalify
local Gtk = gtk.Gtk
local Gdk = gtk.Gdk
local bind = astal.bind
local Variable = astal.Variable

local Popover = astalify(Gtk.Popover)

return function()
	local button = Widget.Button({
		label = "sdf",
	})

	local popover = Popover({
		position = gtk.PositionType.BOTTOM,
		Widget.Label({
			label = "Hello",
		}),
	})
	button.on_click_release = function(_, _)
		if button:get_realized() then
			popover:set_relative_to(button)
			popover:show()
		end
	end

	return Widget.Window({
		monitor = 0,
		anchor = Anchor.LEFT + Anchor.TOP + Anchor.RIGHT,
		exclusivity = "EXCLUSIVE",
		tooltip_text = "asdf",
		button,
	})
end
