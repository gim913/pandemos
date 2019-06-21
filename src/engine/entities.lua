-- module

local entities_data = {}
local entities_location = {}

local function entities_add(ent)
	table.insert(entities_data, ent)
	ent:setId(#entities_data)
	ent:onAdd()
end

local function entities_occupy(idx, entId)
	entities_location[idx] = entId
end

local function entities_unoccupy(idx, entId)
	entities_location[idx] = nil
end

local entities = {
	add = entities_add
	, occupy = entities_occupy
	, unoccupy = entities_unoccupy
}

return entities
