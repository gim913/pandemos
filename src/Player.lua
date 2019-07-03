-- imported modules
local action = require 'engine.action'
local class = require 'engine.oop'
local elements = require 'engine.elements'
local Entity = require 'engine.Entity'
local map = require 'engine.map'

-- class
local Player = class('Player', Entity)

Player.Base_Speed = 1200
Player.Bash_Speed = 700

function Player:ctor(initPos)
	self.base.ctor(self, initPos)
end

function Player:onAdd()
	self.name = 'Player'
	self:occupy()
end

return Player