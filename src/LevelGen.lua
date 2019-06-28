-- imported modules
local class = require 'engine.oop'
local map = require 'engine.map'
local utils = require 'engine.utils'

-- class
local LevelGen = class('LevelGen')

function LevelGen:ctor(grid, depth, rng)
	self.grid = grid
	self.depth = depth
	self.rng = rng
end

local f = math.floor
function LevelGen:update(dt)
	-- fill with grass and ground
	local sx = self.rng:random(10000)
	local sy = self.rng:random(10000)
	self.grid:fill(function(x, y)
		local n = 10 * love.math.noise((sx + x) / 20.0, (sy + y) / 20.0)
		if n < 8 then
			return 3
		else
			return 2
		end
	end)

	-- player starts 29 from the screen bottom
	-- generate river at 29 - 10

	local riverY = map.height() - 29 - 10
	for x = 0, map.width() - 1 do
		local n = f(4 * love.math.noise(x / 40.0))
		local slowVariation1 = f(2 * love.math.noise((1 * map.width() + x) / 60.0))
		local slowVariation2 = 1 + f(3 * love.math.noise((2 * map.width() + x) / 70.0))
		local slowVariation3 = 1 + f(2 * love.math.noise((3 * map.width() + x) / 60.0))

		local start = riverY - n
		local riverEnd = start + 4 + slowVariation1

		-- shore, river, shore
		for y = start - 1 - slowVariation2, start - 1 do
			self.grid:set(x, y, 2)
		end
		for y = start, riverEnd do
			self.grid:set(x, y, 1)
		end
		for y = riverEnd + 1, riverEnd + 1 + slowVariation3 do
			self.grid:set(x, y, 2)
		end
	end

	-- create a bridge
	local cx = map.width() / 2
	for x = cx - 3, cx + 3 do
		-- calculate exactly same values as above
		local n = f(4 * love.math.noise(x / 40.0))
		local slowVariation1 = f(2 * love.math.noise((1 * map.width() + x) / 60.0))
		local slowVariation2 = 1 + f(3 * love.math.noise((2 * map.width() + x) / 70.0))
		local slowVariation3 = 1 + f(2 * love.math.noise((3 * map.width() + x) / 60.0))

		local start = riverY - n
		local riverEnd = start + 4 + slowVariation1

		for y = start - 1 - slowVariation2, riverEnd + 1 + slowVariation3 do
			self.grid:set(x, y, 4)
		end
	end

	return true
end

return LevelGen
