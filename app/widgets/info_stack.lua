local Widget = require("astal.gtk3.widget")
local gtk = require("astal.gtk3")
local astal = require("astal")
local lgi = require("lgi")
local Gdk = lgi.Gdk
local GTop = lgi.GTop
local Variable = astal.Variable
local Anchor = gtk.Astal.WindowAnchor
local Battery = astal.require("AstalBattery")
local bind = astal.bind
local exec = astal.exec

local function repr(icon, value)
	return icon .. " " .. value
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
			return repr(" ", string.format("%.1f%%", u))
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
				return repr(" ", math.floor(c / total * 100) .. "%")
			end),
		}),
	})
end

local function Memory()
	local mem = GTop.glibtop_mem()
	GTop.glibtop_get_mem(mem)

	local total = string.format("%.2f", mem.total / 1073741824)
	local free = Variable(0):poll(2000, function()
		GTop.glibtop_get_mem(mem)
		return (mem.total - mem.free - mem.cached) / 1073741824
	end)

	return Widget.Label({
		label = bind(free):as(function(f)
			return repr(" ", string.format("%s GiB / %s Gib", string.format("%.2f", f), total))
		end),
	})
end

local function Swap()
	local swap = GTop.glibtop_swap()
	GTop.glibtop_get_swap(swap)

	local total = string.format("%.2f", swap.total / 1073741824)
	local used = Variable(0):poll(2000, function()
		GTop.glibtop_get_swap(swap)
		return swap.used / 1073741824
	end)

	return Widget.Label({
		-- visible = bind(used):as(function(u)
		-- 	return u > 0
		-- end),
		label = bind(used):as(function(u)
			return repr("󰾴", string.format("%s GiB / %s Gib", string.format("%.2f", u), total))
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
			return repr(" ", string.format("%.1f GiB / %.1f GiB", u / 2 ^ 30, total / 2 ^ 30))
		end),
	})
end

local function BatteryLevel()
	local bat = Battery.get_default()

	return Widget.Label({
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
		label = bind(bat, "percentage"):as(function(p)
			return repr("󰁿", tostring(math.floor(p * 100)) .. "%")
		end),
	})
end

-- TODO: Network, Volume, Temperature, Clock/Data/Calendar, GPU Usage, Uptime?

return function()
	return Widget.Window({
		anchor = Anchor.RIGHT + Anchor.BOTTOM + Anchor.LEFT,
		layer = "BACKGROUND",
		exclusivity = 0,
		Widget.Box({
			vertical = true,
			spacing = 4,
			Widget.Box({
				spacing = 4,
				Widget.Box({ hexpand = true }),
			}),
			Widget.Box({
				spacing = 4,
				Brightness(),
				Widget.Box({ hexpand = true }),
				BatteryLevel(),
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
