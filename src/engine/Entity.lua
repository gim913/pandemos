-- imported modules
local action = require 'engine.action'
local class = require 'engine.oop'
local elements = require 'engine.elements'
local entities = require 'engine.entities'
local map = require 'engine.map'

-- class
local Entity = class('Entity')

function Entity:ctor(initPos)
	self.pos = initPos
	self.attrs = {}
	-- self.id = nil

	self:resetActions()
end

function Entity:resetActions()
	self.action = { progress = 0, need = 0 }
	self.actionState = action.Action.Idle
	self.actionData = {}
	self.actions = {}
end

function Entity:setId(entId)
	self.id = entId
	self.name = ("ent%d"):format(entId)
end

function Entity:onAdd()
end

function Entity:occupy()
	local idx = self.pos.y * map.width() + self.pos.x
	entities.occupy(idx, self.id)
end

function Entity:unoccupy()
	local idx = self.pos.y * map.width() + self.pos.x
	entities.unoccupy(idx, self.id)
end

function Entity:wantGo(dir)
	local nPos = self.pos + dir
	if nPos.x < 0 or nPos.x == map.width() or nPos.y < 0 or nPos.y == map.height() then
		return action.Action.Blocked
	end

	local location = nPos.y * map.width() + nPos.x
	if map.notPassable(location) then
		return action.Action.Blocked
	end

	local prop = elements.property(location)
	if prop == action.Action.Blocked then
		return action.Action.Blocked
	end

	--print("OK new player position: ", nPos)
	return action.Action.Move,nPos
end

function Entity:move()
	local nPos = self.actionData
	self.actionData = nil

	local dir = nPos - self.pos

	self:unoccupy()
	self.pos = nPos
	self:occupy()

	return true
end

return Entity
