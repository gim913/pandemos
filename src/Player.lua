local class = require 'engine.oop'
local Entity = require 'engine.Entity'

Player = class('Player', Entity)

function Player:ctor(initPos)
	self.base.ctor(self, initPos)
end

function Player:onAdd()
	self.name = 'Player'
	self:occupy()
end

return Player