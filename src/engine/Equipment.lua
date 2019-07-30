-- imported modules
local class = require 'engine.oop'

-- class
local Equipment = class('Equipment')

function Equipment:ctor(itemTypes)
	self.items = {}
	for _, itemType in pairs(itemTypes) do
		self.items[itemType] = {}
	end
end

function Equipment:get(itemType)
	return self.items[itemType]
end

function Equipment:add(item)
	local itemType = item.desc.blueprint.type
	self.items[itemType] = item
end

return Equipment
