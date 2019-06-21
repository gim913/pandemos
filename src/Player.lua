local class = require 'engine.oop'
local Entity = require 'engine.Entity'

Player = class('Player', Entity)

function Player:ctor(initPos)
	self.base.ctor(self, initPos)
end

return Player