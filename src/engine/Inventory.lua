-- imported modules
local class = require 'engine.oop'
local utils = require 'engine.utils'

-- class
local Inventory = class('Inventory')

function Inventory:ctor(capacity)
	self.capacity = capacity
	self.inventory = {}
end

function Inventory:add(item)
	if #self.inventory == self.capacity then
		return false
	end

	table.insert(self.inventory, item)
	return true
end

function Inventory:get(index)
	return self.inventory[index]
end

function Inventory:del(item)
	for k, curItem in pairs(self.inventory) do
		if item.desc.uid == curItem.desc.uid then
			table.remove(self.inventory, k)
			break
		end
	end
end

return Inventory
