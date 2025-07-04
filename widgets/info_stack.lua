local Widget = require("astal.gtk3.widget")
local gtk = require("astal.gtk3")
local astal = require("astal")
local lgi = require("lgi")
local Gdk = lgi.Gdk
local GTop = lgi.GTop
local GLib = astal.require("GLib")
local Variable = astal.Variable
local Anchor = gtk.Astal.WindowAnchor
local Battery = astal.require("AstalBattery")
local Network = astal.require("AstalNetwork")
local Wp = astal.require("AstalWp")
local bind = astal.bind
local exec = astal.exec
local concat = require("lib").concat

local function User()
	return Widget.Label({
		label = concat(" ", exec('sh -c "echo $USER"')),
	})
end

local function NetworkUsage()
	local network = Network.get_default()
	local wifi = network.wifi
	local wired = network.wired
	local wifiv = Variable.derive({
		bind(wifi, "strength"),
		bind(wifi, "ssid"),
		bind(wifi, "internet"),
	}, function(strength, ssid, internet)
		return {
			strength = strength,
			ssid = ssid,
			internet = internet,
		}
	end)

	return {
		Id = bind(network, "primary"):as(function(p)
			if p == "WIFI" then
				return Widget.Label({
					label = wifiv():as(function(wi)
						local function get_icon()
							local connected = wi.internet == "CONNECTED"
							if wi.internet == "CONNECTING" then
								return "󱛇 "
							elseif wi.strength < 20 then
								return connected and "󰤯 " or "󰤫 "
							elseif wi.strength < 40 then
								return connected and "󰤟 " or "󰤠 "
							elseif wi.strength < 60 then
								return connected and "󰤢 " or "󰤣 "
							elseif wi.strength < 80 then
								return connected and "󰤥 " or "󰤦 "
							else
								return connected and "󰤨 " or "󰤩 "
							end
						end
						return concat(get_icon(), wi.ssid)
					end),
				})
			elseif p == "WIRED" then
				return Widget.Label({
					label = bind(wired, "internet"):as(function(i)
						return concat(i == "CONNECTED" and "󱐥" or "󱐤", "Wired")
					end),
				})
			else
				return Widget.Label({
					label = concat(" ", "Unknown"),
				})
			end
		end),
		Speed = bind(network, "primary"):as(function(p)
			if p == "WIFI" then
				return Widget.Label({
					label = bind(wifi, "bandwidth"):as(function(s)
						return concat(" ", s)
					end),
				})
			else
				return Widget.Label({
					label = bind(wired, "speed"):as(function(s)
						return concat(" ", s)
					end),
				})
			end
		end),
	}
end

local function CpuUsage()
	local prev = GTop.glibtop_cpu()
	GTop.glibtop_get_cpu(prev)

	local function get_cpu_usage()
		local now = GTop.glibtop_cpu()
		GTop.glibtop_get_cpu(now)

		local total_diff = now.total - prev.total
		local used_diff = (now.user - prev.user)
			+ (now.nice - prev.nice)
			+ (now.sys - prev.sys)
			+ (now.irq - prev.irq)
			+ (now.softirq - prev.softirq)

		prev = now

		if total_diff == 0 then
			return 0
		end
		return (used_diff / total_diff) * 100
	end

	local usage = Variable(0):poll(2000, get_cpu_usage)

	return Widget.Label({
		label = bind(usage):as(function(u)
			return concat(" ", string.format("%.1f%%", u))
		end),
	})
end

local function Brightness()
	local total = tonumber(exec("brightnessctl max"))
	local curr = Variable(tonumber(exec("brightnessctl get")))

	return Widget.EventBox({
		on_scroll_event = function(_, event)
			exec("brightnessctl set 5" .. (tonumber(event.delta_y) < 0 and "%+" or "%-"))
			curr:set(tonumber(exec("brightnessctl get")))
		end,
		Widget.Label({
			label = bind(curr):as(function(c)
				return concat(" ", math.floor(c / total * 100) .. "%")
			end),
		}),
	})
end

local function Memory()
	local mem = GTop.glibtop_mem()
	GTop.glibtop_get_mem(mem)

	local free = Variable(0):poll(2000, function()
		GTop.glibtop_get_mem(mem)
		return GLib.format_size(mem.total - mem.free - mem.cached)
	end)

	return Widget.Label({
		label = bind(free):as(function(f)
			return concat(" ", string.format("%s / %s", f, GLib.format_size(mem.total)))
		end),
	})
end

local function Swap()
	local swap = GTop.glibtop_swap()
	GTop.glibtop_get_swap(swap)

	local used = Variable(0):poll(2000, function()
		GTop.glibtop_get_swap(swap)
		return GLib.format_size(swap.used)
	end)

	return Widget.Label({
		-- visible = bind(used):as(function(u)
		-- 	return u > 0
		-- end),
		label = bind(used):as(function(u)
			return concat("󰾴", string.format("%s / %s", u, GLib.format_size(swap.total)))
		end),
	})
end

local function DiskUsage()
	local usage = GTop.glibtop_fsusage()
	GTop.glibtop_get_fsusage(usage, "/")

	local used = Variable(0):poll(10000, function()
		GTop.glibtop_get_fsusage(usage, "/")
		return (usage.blocks - usage.bfree) * usage.block_size
	end)

	local total = usage.blocks * usage.block_size

	return Widget.Label({
		label = bind(used):as(function(u)
			return concat(" ", string.format("%s / %s", GLib.format_size(u), GLib.format_size(total)))
		end),
	})
end

local function getTime(seconds)
	if seconds < 60 then
		return math.floor(seconds) .. "s"
	elseif seconds < 3600 then
		return math.floor(seconds / 60) .. "m"
	else
		return string.format("%.1f", seconds / 3600) .. "h"
	end
end

local function Time(format, icon)
	local time = Variable(""):poll(1000, function()
		return concat(icon, GLib.DateTime.new_now_local():format(format))
	end)

	return Widget.Label({
		label = time(),
	})
end

local function Uptime()
	local uptime = GTop.glibtop_uptime()
	GTop.glibtop_get_uptime(uptime)
	local upt = Variable(0):poll(1000, function()
		GTop.glibtop_get_uptime(uptime)
		return concat(" ", getTime(uptime.uptime))
	end)

	return Widget.Label({
		label = upt(),
	})
end

local function Volume()
	local speaker = Wp.get_default().audio.default_speaker

	return Widget.EventBox({
		on_scroll_event = function(_, event)
			speaker.volume =
				math.min(math.max(speaker.volume + (tonumber(event.delta_y) < 0 and 0.05 or -0.05), 0), 150)
		end,
		Widget.Label({
			label = bind(speaker, "volume"):as(function(v)
				local function get_icon()
					if v <= 0.01 then
						return " "
					elseif v <= 0.25 then
						return " "
					elseif v <= 0.75 then
						return " "
					else
						return " "
					end
				end
				return concat(get_icon(), math.floor(v * 100 + 0.5) .. "%")
			end),
		}),
	})
end

local function BatteryLevel()
	local bat = Battery.get_default()

	local b = Variable.derive({ bind(bat, "percentage"), bind(bat, "state") }, function(p, s)
		return {
			percentage = p,
			state = s,
		}
	end)

	return Widget.Label({
		class_name = b():as(function(baby)
			local class = "battery_level"
			local is_charging = (baby.state == "CHARGING" or baby.state == "PENDING_CHARGE")

			if is_charging then
				class = concat(class, "charging")
			else
				if baby.percentage < 0.1 then
					class = concat(class, "10")
				elseif baby.percentage < 0.2 then
					class = concat(class, "20")
				elseif baby.percentage < 0.3 then
					class = concat(class, "30")
				end
			end
			return class
		end),
		visible = bind(bat, "is-present"),
		tooltip_text = bind(bat, "state"):as(function(s)
			if s == "CHARGING" then
				return bat.time_to_full .. " to Full"
			elseif s == "DISCHARGING" then
				return bat.time_to_empty .. " to Empty"
			elseif s == "FULLY_CHARGED" then
				return "Full"
			end
		end),
		label = b():as(function(baby)
			local p = baby.percentage
			local state = baby.state
			local is_charging = (state == "CHARGING" or state == "PENDING_CHARGE")

			local function get_icon()
				if p < 0.1 then
					return is_charging and "󰢜 " or "󰁺"
				elseif p < 0.2 then
					return is_charging and "󰂆 " or "󰁻"
				elseif p < 0.3 then
					return is_charging and "󰂇 " or "󰁼"
				elseif p < 0.4 then
					return is_charging and "󰂈 " or "󰁽"
				elseif p < 0.5 then
					return is_charging and "󰂉 " or "󰁾"
				elseif p < 0.6 then
					return is_charging and "󰂊 " or "󰁿"
				elseif p < 0.7 then
					return is_charging and "󰂋 " or "󰂀"
				elseif p < 0.8 then
					return is_charging and "󰂊 " or "󰂁"
				elseif p < 0.9 then
					return is_charging and "󰂋 " or "󰂂"
				else
					return is_charging and "󰂅 " or "󰁹"
				end
			end
			return concat(get_icon(), tostring(math.floor(p * 100)) .. "%")
		end),
	})
end

return function()
	local network = NetworkUsage()
	return Widget.Window({
		anchor = Anchor.RIGHT + Anchor.BOTTOM + Anchor.LEFT,
		layer = "BACKGROUND",
		exclusivity = 0,
		Widget.Box({
			class_name = "info_stack",
			vertical = true,
			spacing = 4,
			Widget.Box({
				spacing = 4,
				Uptime(),
				Widget.Box({ hexpand = true }),
				Time("%r", " "),
				Time("%F", " "),
			}),
			Widget.Box({
				spacing = 4,
				Brightness(),
				BatteryLevel(),
				Volume(),
				Widget.Box({ hexpand = true }),
				network.Speed,
				network.Id,
				User(),
			}),
			Widget.Box({
				spacing = 4,
				Memory(),
				DiskUsage(),
				Widget.Box({ hexpand = true }),
				CpuUsage(),
				Swap(),
			}),
		}),
	})
end
