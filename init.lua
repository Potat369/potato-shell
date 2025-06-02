local App = require("astal.gtk3.app")
local astal = require("astal")

local InfoStack = require("widgets/info_stack")

local function src(path)
	local str = debug.getinfo(2, "S").source:sub(2)
	local s = str:match("(.*/)") or str:match("(.*\\)") or "./"
	astal.write_file("/home/potat369/debug.txt", s .. path)
	return s .. path
end

App:start({
	css = src("style.css"),
	main = function()
		InfoStack()
	end,
})
