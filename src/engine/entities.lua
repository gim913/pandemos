-- module

local entities_data = {}
local entities_location = {}
local entities_with_attrs = {}

local function entities_add(ent)
	table.insert(entities_data, ent)
	ent:setId(#entities_data)
	ent:onAdd()
end

local function entities_addAttr(ent, attr)
	if not entities_with_attrs[attr] then
		entities_with_attrs[attr] = {}
	end
	entities_with_attrs[attr][ent.id] = ent
	ent.attrs[attr] = true
end

local function entities_occupy(idx, entId)
	entities_location[idx] = entId
end

local function entities_unoccupy(idx, entId)
	entities_location[idx] = nil
end

local function entities_all()
	return entities_data
end

local function entities_with(attr)
	return entities_with_attrs[attr]
end

local entities = {
	add = entities_add
	, addAttr = entities_addAttr
	, occupy = entities_occupy
	, unoccupy = entities_unoccupy
	, all = entities_all
	, with = entities_with
	, Attr = {
		Has_Move = 4
	}
}

return entities
