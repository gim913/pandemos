-- modules
local class = require 'engine.oop'
local utils = require 'engine.utils'

-- class
local LevelGen = class('LevelGen')

function LevelGen:ctor(grid, depth, rng)
	self.grid = grid
	self.depth = depth
	self.rng = rng
end

function LevelGen:update(dt)
	self.grid:fill(function(i,j) return utils.randPercent(self.rng, 10) and 1 or 2 end)
	return true
end

return LevelGen
