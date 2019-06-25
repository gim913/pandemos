-- imported modules
local Grid = require 'Grid'
local LevelGen = require 'LevelGen'
local S = require 'settings'

local class = require 'engine.oop'
local fontManager = require 'engine.fm'

-- class
local Level = class('Level')

local MODE_GENERATING_LEVEL = 1
local MODE_COPY_TO_GMAP = 2
local MODE_FINISHED = 10

function Level:ctor(rng, depth)
	self.rng = rng
	self.depth = depth

	self.seed = self.rng:random(0, 99999999)
	self.visited = false
	self.fatFont = fontManager.get(32)

	self.mode = MODE_GENERATING_LEVEL

	self.w = S.game.COLS
	self.h = S.game.ROWS

end

function Level:initializeGenerator()
	local temp = { w = self.w, h = self.h }
	self.grid = Grid:new({ w = self.w, h = self.h })
	self.generator = LevelGen:new(self.grid, self.depth, self.rng)
end

function Level:update(_dt, mapdata)
	if MODE_GENERATING_LEVEL == self.mode then
		if self.generator:update(dt) then
			self.mode = MODE_COPY_TO_GMAP
		end
	elseif MODE_COPY_TO_GMAP == self.mode then
		-- todo: requires serious rework...
		local idx = 0
		for y = 0, self.h - 1 do
			for x = 0, self.w - 1 do
				mapdata.data[idx] = (self.grid:at(x, y) - 1) * 16
				idx = idx + 1
			end
		end
		self.mode = MODE_FINISHED
	else
		return false
	end

	return true
end

function Level:show()
	local msg = love.graphics.newText(self.fatFont, "generating level")
	love.graphics.setColor(0.0, 0.6, 0.0, 1.0)
	love.graphics.draw(msg, (S.resolution.x - msg:getWidth()) / 2, (S.resolution.y - msg:getHeight()) / 2)
end

return Level