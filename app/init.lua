local App = require("astal.gtk3.app")
local astal = require("astal")
local css = "./style.css"

local InfoStack = require("widgets/info_stack")

App:start({
	css = css,
	main = function()
		InfoStack()
	end,
})
