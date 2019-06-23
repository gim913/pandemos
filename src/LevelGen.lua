-- imported modules
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
	self.grid:fill(function(x, y)
		return math.floor(1 + love.math.noise(x / 10.0, y / 10.0) * 3)
	end)
	return true
end

return LevelGen
