local App = require("astal.gtk3.app")
local astal = require("astal")
local src = require("lib").src

local InfoStack = require("widgets/info_stack")
local Bar = require("widgets/bar")

App:start({
	css = src("style.css"),
	main = function()
		Bar()
		InfoStack()
	end,
})
