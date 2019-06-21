local class = require 'engine.oop'

Entity = class('Entity')

function Entity:ctor(initPos)
	self.pos = initPos
end

return Entity
