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

	return tbl
end

function Grid:ctor(desc)
	if desc ~= nil then
		if desc.w ~= nil then
			self.tbl = initialize(desc.w, desc.h)
			self.w = desc.w
			self.h = desc.h
		end
	end
end

function Grid:fill(value)
	local tv = type(value)
	if tv == "function" then
		for i = 1, self.w do
			for j = 1, self.h do
				self.tbl[i][j] = value(i, j)
			end
		end
	elseif tv == "number" then
		for i = 1, self.w do
			for j = 1, self.h do
				self.tbl[i][j] = value
			end
		end
	end
end

-- we'll be using 0-based numbering for grid, I'll probably regret that
function Grid:at(x, y)
	if y == nil then
		local pos = x
		return self.tbl[pos.x + 1][pos.y + 1]
	end
	return self.tbl[x + 1][y + 1]
end

function Grid:set(x, y, val)
	if val == nil then
		local pos = x
		self.tbl[pos.x + 1][pos.y + 1] = y
	else
		self.tbl[x + 1][y + 1] = val
	end
end


return Grid
