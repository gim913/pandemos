-- imported modules
local action = require 'engine.action'
local console = require 'engine.console'
local Color = require 'engine.Color'

-- module

local entities_data = {}
local entities_location = {}
local entities_with_attrs = {}

local function entities_addAttr(ent, attr)
	if not entities_with_attrs[attr] then
		entities_with_attrs[attr] = {}
	end
	entities_with_attrs[attr][ent.id] = ent
	ent.attrs[attr] = true
end

local function entities_clearAttrs(ent)
	for k,_ in pairs(entities_with_attrs) do
		entities_with_attrs[k][ent.id] = nil
	end
end

local function entities_add(ent)
	table.insert(entities_data, ent)
	ent:setId(#entities_data)
	ent:onAdd()
end

local function entities_del(ent)
	for k, e in pairs(entities_location) do
		if e == ent then
			entities_location[k] = nil
			break
		end
	end
	entities_data[ent.id] = nil
	entities_clearAttrs(ent)
	--ent:onDel()
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

local function entities_check(idx, actor)
	if entities_location[idx] then
		local entId = entities_location[idx]
		local ent = entities_data[entId]

		-- hmm probably should be other way around actor:reactionTowards(ent)...
		if ent:reactionTowards(actor) < 0 then
			return action.Action.Attack,ent
		end

		return action.Action.Blocked
	end
end

local function entities_attack(who, whom)
	local gray = { Color.hsvToRgb(0.0, 0.0, 0.8, 1.0) }

	console.log({
		{ Color.hsvToRgb(0.33, 0.8, 1.0, 1.0) },
		who.name .. "_" .. tostring(who.pos),
		gray,
		' hits ',
		{ Color.hsvToRgb(0.00, 0.8, 1.0, 1.0) },
		whom.name,
		gray,
		' giving ',
		{ 0.6, 0.8, 1.0, 1.0 },
		string.format('%s', who:getDamage()),
		gray,
		' damage'
	})

	whom:takeHit(who:getDamage())
end

local entities = {
	add = entities_add
	, del = entities_del
	, addAttr = entities_addAttr
	, occupy = entities_occupy
	, unoccupy = entities_unoccupy
	, all = entities_all
	, with = entities_with
	, check = entities_check
	, attack = entities_attack

	, Attr = {
		Has_Fov = 1
		, Has_Move = 2
		, Has_Attack = 3
		, Has_Ai = 4
	}
}

return entities
