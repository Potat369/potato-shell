local App = require("astal.gtk3.app")
local astal = require("astal")
local scss = "./style.scss"
local css = "/tmp/style.css"

local InfoStack = require("widgets/info_stack")

astal.exec(string.format("sass %s %s", scss, css))

App:start({
	css = css,
	main = function()
		InfoStack()
	end,
})
