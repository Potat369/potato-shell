local M = {}

---@param objects table
---@param func function(object)
---@return table
function M.map(objects, func)
	local result = {}
	for index, value in ipairs(objects) do
		result[index] = func(value)
	end
	return result
end

return M
