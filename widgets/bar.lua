local Widget = require("astal.gtk3.widget")
local gtk = require("astal.gtk3")
local astal = require("astal")
local Hyprland = astal.require("AstalHyprland")
local Anchor = gtk.Astal.WindowAnchor
local astalify = gtk.astalify
local Gtk = gtk.Gtk
local Gdk = gtk.Gdk
local bind = astal.bind
local Variable = astal.Variable
local map = require("lib").map

return function()
	local hypr = Hyprland.get_default()

	local function empty_workspace(id)
		for _, client in ipairs(hypr.clients) do
			if client.workspace.id == id then
				return false
			end
		end
		return true
	end

	return Widget.Window({
		monitor = 0,
		anchor = Anchor.TOP,
		exclusivity = "EXCLUSIVE",
		Widget.Box({
			class_name = "workspaces",
			map({ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }, function(id)
				return Widget.Button({
					class_name = bind(hypr, "focused-workspace"):as(function(focused)
						local class = "workspace"
						local _, w = pcall(function()
							return hypr:get_workspace(id)
						end)
						if focused.id == id then
							class = class .. " focused"
						elseif w == nil or empty_workspace(id) then
							class = class .. " empty"
						end
						return class
					end),
					on_clicked = function()
						if hypr.focused_workspace.id ~= id then
							hypr:dispatch("workspace", tostring(id))
						end
					end,
					label = (id == 10 and 0 or id),
				})
			end),
		}),
	})
end
