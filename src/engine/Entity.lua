local class = require 'engine.oop'
local entities = require 'engine.entities'
local map = require 'engine.map'

Entity = class('Entity')

function Entity:ctor(initPos)
	self.pos = initPos
	-- self.id = nil
end

function Entity:setId(entId)
	self.id = entId
	self.name = ("ent%d"):format(entId)
end

function Entity:onAdd()
end

function Entity:occupy()
	local idx = self.pos.y*map.width() + self.pos.x
	entities.occupy(idx, self.id)
end

return Entity
