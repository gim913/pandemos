-- imported modules
local action = require 'engine.action'
local console = require 'engine.console'
local color = require 'engine.color'
local utils = require 'engine.utils'

local Vec = require 'hump.vector'

-- module

--  n -> entity
local entities_data = {}

--  position -> entId
local entities_location = {}

-- attribute -> entId -> ent
local entities_with_attrs = {}

local entities = {
	Attr = {
		Has_Fov = 1
		, Has_Move = 2
		, Has_Attack = 3
		, Has_Ai = 4
	}
}

function entities.add(ent)
	table.insert(entities_data, ent)
	ent:setId(#entities_data)
	ent:onAdd()
end

function entities.addAttr(ent, attr)
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

function entities.del(ent)
	for k, entId in pairs(entities_location) do
		if entId == ent.id then
			entities_location[k] = nil
			break
		end
	end

	entities_data[ent.id] = nil
	entities_clearAttrs(ent)
	--ent:onDel()
end


function entities.occupy(idx, entId)
	entities_location[idx] = entId
end

function entities.unoccupy(idx, entId)
	entities_location[idx] = nil
end

function entities.all()
	return entities_data
end

function entities.with(attr)
	return entities_with_attrs[attr]
end

function entities.check(idx, initiatior)
	if entities_location[idx] then
		local entId = entities_location[idx]
		local ent = entities_data[entId]

		if initiatior:reactionTowards(ent) < 0 then
			return action.Action.Attack,ent
		end

		return action.Action.Blocked
	end
end

function entities.attack(who, whom)
	local gray = { color.hsvToRgb(0.0, 0.0, 0.8, 1.0) }

	console.log({
		{ color.hsvToRgb(0.33, 0.8, 1.0, 1.0) },
		who.name .. "_" .. tostring(who.pos),
		gray,
		' hits ',
		{ color.hsvToRgb(0.00, 0.8, 1.0, 1.0) },
		whom.name,
		gray,
		' giving ',
		{ 0.6, 0.8, 1.0, 1.0 },
		string.format('%s', who:getDamage()),
		gray,
		' damage'
	})

	local alive = whom:takeHit(who:getDamage())
	if not alive then
		-- TODO: ugly
		who.seemap[whom] = nil
	end
end

local g_gameTime = 0
local Action_Step = 60
function entities.processActions(player)
	-- this is only justifiable place where .all() should be called
	-- if entity has no 'actions', than probably it doesn't need to be
	-- entity
	for _,e in pairs(entities.all()) do
		if #e.actions ~= 0 then
			local currentAction = e.actions[1]
			if e.action.need == 0 then
				--print ("SETTING TO: " .. currentAction.time)
				e.action.need = currentAction.time
			end

			e.action.progress = e.action.progress + Action_Step
			--console.log('action progress: ' .. e.name .. " " .. e.action.progress .. " " .. utils.repr(currentAction))

			if e.action.progress >= e.action.need then
				e.action.progress = e.action.progress - e.action.need
				-- debug
				if (e == player) then
					g_gameTime = g_gameTime + e.action.need
				end
				-- end debug
				e.action.need = 0

				-- finalize action
				e.actionState = currentAction.state
				e.actionData = currentAction.val
				--console.log('action ended ' .. currentAction.val.x .. "," .. currentAction.val.y)
				table.remove(e.actions, 1)
				if (e == player) then
					g_gameTime = g_gameTime + e.action.need
					return false
				end
			end
		end
	end

	return true
end

function entities.prepareDraw(descriptors, followedEnt, camLu, Tile_Size_Adj, scaleFactor)
	local followedEntPos = followedEnt.pos
	for _,ent in pairs(entities.all()) do
		local dist = (ent.pos - followedEntPos):len()

		-- this won't work nicely with animation, but since entity will show up after seemap update, I will ignore it
		if followedEnt == ent or followedEnt.seemap[ent] then
			local relPos = ent.pos - camLu

			table.insert(descriptors, {
				color = ent.color
				, img = ent.img
				, position = relPos * Tile_Size_Adj + ent.anim
				, scale = Vec(scaleFactor, scaleFactor)
			})
		end
	end
end

return entities
