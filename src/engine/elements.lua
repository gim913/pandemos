local action = require 'engine.action'
local class = require 'engine.oop'
local utils = require 'engine.utils'

local Gobject = class('Gobject')

function Gobject:ctor()
	self.tileId = 0
	-- state descriptor
	self.sd = { state = 0 }

	-- additional unset properties
	-- self.opaque
end

function Gobject:setTileId(id)
	self.tileId = id
end

function Gobject:setOpaque(b)
	self.opaque = b
end

function Gobject:setPassable(b)
	self.passable = b
end

-- -- -- -- --

local elements_data = {}
local elements_location = {}

local function elements_add(location, element)
	-- this allows multiple elements per location, although I'm not yet sure if this is good idea
	if not elements_location[location] then
		elements_location[location] = {}
	end
	table.insert(elements_location[location], element)
end

local function elements_create(location)
	local r = Gobject:new()
	table.insert(elements_data, r)
	if location ~= nil then
		elements_add(location, r)
	end
	return r
end

local function elements_property(location)
	if elements_location[location] then
		-- not sure what to do with this, check only first element
		if elements_location[location][1].passable then
			return nil
		end
		return action.Action.Blocked
	end
	return nil
end

local function elements_getTileId(location)
	if elements_location[location] then
		-- always return first element...
		return elements_location[location][1].tileId
	end
	return nil
end

local function elements_process()
	-- nothing to do
end

local function elements_notPassLight(idx)
	if elements_location[idx] and elements_location[idx][1].opaque then
		return true
	end
	return false
end

local elements = {
	create = elements_create
	, property = elements_property
	, getTileId = elements_getTileId
	, process = elements_process

	, notPassLight = elements_notPassLight
}

return elements
