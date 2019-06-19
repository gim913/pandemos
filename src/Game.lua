local class = require 'engine.oop'
local Level = require 'Level'
local S = require 'settings'

local Game = class('Game')

local function addLevel(levels, rng)
	local l = Level:new(rng)
	table.insert(levels, l)
	return l
end

function Game:ctor(rng)
	self.rng = rng
	self.seed = 0

	self.fatFont = love.graphics.newFont(32)

	self.levels = {}
	addLevel(self.levels, self.rng)

	self.depthLevel = 1
	self.updateLevel = false
end

function Game:startLevel()
	local level = self.levels[self.depthLevel]
	if not level.visited then
		level:initializeGenerator()
		self.updateLevel = true
	end
end

function Game:update(dt)
	-- keep running level update, until level generation is done
	if self.updateLevel then
		local level = self.levels[self.depthLevel]
		self.updateLevel = level:update(dt)
	end
end

function Game:show()
	local msg
	if self.updateLevel then
		msg = love.graphics.newText(self.fatFont, "generating level")
	else
		msg = love.graphics.newText(self.fatFont, "level generated")
	end
	love.graphics.setColor(0.0, 0.6, 0.0, 1.0)
	love.graphics.draw(msg, (S.resolution.x - msg:getWidth()) / 2, (S.resolution.y - msg:getHeight()) / 2)
end

return Game