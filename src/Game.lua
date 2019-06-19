local class = require 'engine.oop'

local Game = class('Game')

function Game:ctor(rng)
	self.rng = rng
	self.seed = 0
end

function Game:startLevel()
end

function Game:update(dt)
end

function Game:show()
end

return Game