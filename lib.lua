local M = {}

---@generic T, R
---@param array T[]
---@param func fun(v: T, i: integer): R
---@return R[]
function M.map(array, func)
	local new_arr = {}
	for i, v in ipairs(array) do
		new_arr[i] = func(v, i)
	end
	return new_arr
end

---@param v1 string
---@param v2 string
---@return string
function M.concat(v1, v2)
	return v1 .. " " .. v2
end

---@param path string
---@return string
function M.src(path)
	local str = debug.getinfo(2, "S").source:sub(2)
	local s = str:match("(.*/)") or str:match("(.*\\)") or "./"
	return s .. path
end

return M
