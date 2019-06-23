-- imported modules
local action = require 'engine.action'
local class = require 'engine.oop'
local Entity = require 'engine.Entity'
local map = require 'engine.map'

-- class
Player = class('Player', Entity)

function Player:ctor(initPos)
	self.base.ctor(self, initPos)
end

function Player:onAdd()
	self.name = 'Player'
	self:occupy()
end

function Player:wantGo(dir)
	local nPos = self.pos + dir
	if nPos.x < 0 or nPos.x == map.width() or nPos.y < 0 or nPos.y == map.height() then
		return action.Action.Blocked
	end

	print("OK new player position: ", nPos)
	return action.Action.Move,nPos
end

return Player