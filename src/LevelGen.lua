-- modules
local class = require 'engine.oop'

-- class
local LevelGen = class('LevelGen')

function LevelGen:ctor(grid, depth)
	self.depth = depth
	print(depth)
end

function LevelGen:update(dt)
	return true
end

return LevelGen
