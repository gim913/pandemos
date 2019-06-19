local class = require 'engine.oop'

local Level = class('Level')

local MODE_GENERATING_LEVEL = 1
local MODE_FINISHED = 10

function Level:ctor(rng)
	self.rng = rng
	self.seed = self.rng:random(0, 99999999)
	self.visited = false

	self.mode = MODE_GENERATING_LEVEL

	self.w = 40
	self.h = 80
end

function Level:initializeGenerator()
	--self.grid = Grid:new()
end

function Level:update(_dt)
	if MODE_GENERATING_LEVEL == self.mode then
		--if self.generator:update(dt) then
		--	self.mode = MODE_COPY_TO_PMAP
		--end
		self.mode = MODE_FINISHED
	else
		return false
	end

	return true
end

return Level