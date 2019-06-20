-- modules
local class = require 'engine.oop'

-- class
local Grid = class('Grid')

local function initialize(w, h)
	local tbl = {}
	for i = 1, w do
		table.insert(tbl, {})
		for j = 1, h do
			table.insert(tbl[i], 0)
		end
	end

	return
end

function Grid:ctor(desc)
	if desc ~= nil then
		if desc.w ~= nil then
			self.tbl = initialize(desc.w, desc.h)
		end
	end
end

return Grid
