-- imported modules
local utils = require 'engine/utils'

-- module

local function class(s, base)
	local c = {}
	if base ~= nil then
		c = utils.deepcopy(base)
	end
	c.__toString = function() return s end
	c.__index = c
	c.new = function(arg, ...)
		local t = {}
		t.base = base
		t = setmetatable(t, c)
		c.ctor(t, ...)
		return t
	end
	return c
end

return class
