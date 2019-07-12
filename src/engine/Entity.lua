-- imported modules
local action = require 'engine.action'
local class = require 'engine.oop'
local console = require 'engine.console'
local elements = require 'engine.elements'
local entities = require 'engine.entities'
local los = require 'engine.los'
local map = require 'engine.map'

-- class
local Entity = class('Entity')

-- max LoS radius, modify if required
-- every entity must have los below this value
local Max_Los_Radius = 24

local Max_Los_Radius_2 = Max_Los_Radius * Max_Los_Radius
local sqrt = math.sqrt

function Entity:ctor(initPos)
	self.pos = initPos
	self.attrs = {}

	self.doRecalc = true
	self.vismap = {}
	self.seemap = {}

	-- those two probably should not differ, so it might make sense
	-- to turn them into single var later
	self.seeDist = 10
	self.losRadius = 10
	-- self.id = nil

	self.life = 100

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
	print('entity ' .. self.name .. ' is occupying ' .. idx)
	entities.occupy(idx, self.id)
end

function Entity:unoccupy()
	local idx = self.pos.y * map.width() + self.pos.x
	entities.unoccupy(idx, self.id)
end

function Entity:reactionTowards(other)
	return -1
end

function Entity:getDamage()
	return 10
end

function Entity:takeHit(dmg)
	print(self.name .. ' is taking '..dmg..' damage')
	self.life = self.life - dmg

	if self.life <= 0 then
		self:die()
	end
end

function Entity:die()
	self:unoccupy()
	entities.del(self)
end

function Entity:wantGo(dir)
	-- check map
	local nPos = self.pos + dir
	if nPos.x < 0 or nPos.x == map.width() or nPos.y < 0 or nPos.y == map.height() then
		return action.Action.Blocked
	end

	local location = nPos.y * map.width() + nPos.x
	if map.notPassable(location) then
		return action.Action.Blocked
	end

	-- check entities
	local entProp = entities.check(location, self)
	if entProp == action.Action.Blocked then
		print('entProp blocked')
		return action.Action.Blocked
	elseif entProp == action.Action.Attack then
		print('entProp attack')
		return action.Action.Attack, nPos
	end

	-- check elements
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
	local idx = nPos.y * map.width() + nPos.x
	local entProperty = entities.check(idx, self)
	if action.Action.Attack == entProperty then
		-- if we're here, it means npc moved onto the field before us, there are few options:
		--  * do nothing (current)
		--  * shift enemy further and move the player
		--  * attack - probably not fair, cause move speed might be != attack speed
		return false
	end

	self:unoccupy()
	self.pos = nPos
	self:occupy()

	self.doRecalc = true
	return true
end

function Entity:attack()
	local nPos = self.actionData
	self.actionData = nil

	local idx = nPos.y * map.width() + nPos.x
	local entProp, ent = entities.check(idx, self)
	if entProp == action.Action.Attack then
		entities.attack(self, ent)
		self.doRecalc = true
		return 0,0
	end

	self.doRecalc = true
	return 0,0
end

function Entity:analyze()
end

function Entity:recalcVisMap()
	if not self.doRecalc then
		return
	end

	--print('calc' .. self.name)

	local r = self.losRadius
	local r2 = r*r

	local idx = self.pos.y * map.width() + self.pos.x

	self.vismap = {}
	self.vismap[idx] = 1

	los.calcVismapSquare(self.pos, self.vismap, -1,  1, r2)
	los.calcVismapSquare(self.pos, self.vismap, -1, -1, r2)
	los.calcVismapSquare(self.pos, self.vismap, 1,  1, r2)
	los.calcVismapSquare(self.pos, self.vismap, 1, -1, r2)
end

-- NOTE: seemap only contains ents in seeDist range, not all ents
function Entity:checkEntVis(oth, dist)
	if dist <= self.seeDist then
		if not self.seemap[oth] then
			local idx = oth.pos.y * map.width() + oth.pos.x
			--print('log: vis '.. tostring(self.pos) .. " " .. tostring(oth.pos) .. " " .. idx .. " : " .. self.vismap[idx])
			if self.vismap[idx] and self.vismap[idx] > 0 then
				self.seemap[oth] = 1
			end
		end
	else
		if self.seemap[oth] then
			self.seemap[oth] = nil
		end
	end
end

function Entity:recalcSeeMap()
	if not self.doRecalc then
		return
	end

	-- TODO: should there be some Attr?
	for _,e in pairs(entities.all()) do
		if e ~= self then
			local d2 = (e.pos - self.pos):len2()
			if d2 < Max_Los_Radius_2 then
				local d = sqrt(d2)
				self:checkEntVis(e, d)
				e:checkEntVis(self, d)
			end
		end
	end

	self.doRecalc = false
end

return Entity
