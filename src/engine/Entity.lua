-- imported modules
local messages = require 'messages'

local action = require 'engine.action'
local astar = require 'engine.astar'
local class = require 'engine.oop'
local console = require 'engine.console'
local elements = require 'engine.elements'
local entities = require 'engine.entities'
local los = require 'engine.los'
local map = require 'engine.map'
local soundManager = require 'engine.soundManager'

local Vec = require 'hump.vector'

-- class
local Entity = class('Entity')

Entity.Base_Speed = 1200
Entity.Bash_Speed = 720

local sqrt = math.sqrt

function Entity:ctor(initPos)
	self.pos = initPos
	self.anim = Vec.zero
	self.attrs = {}

	self.components = {}

	self.doRecalc = true
	self.vismap = {}
	self.seemap = {}

	-- those two probably should not differ, so it might make sense
	-- to turn them into single var later
	self.seeDist = 10
	self.losRadius = 10
	-- self.id = nil
	self.class = 0

	self.hp = 100
	self.maxHp = 100
	self.damage = 5

	self:resetActions()

	self.rng = love.math.newRandomGenerator(self.pos.x + self.pos.y)

	self.sounds = {
		walk = {
			soundManager.get('sounds/zombie-19.wav', 'static')
			, soundManager.get('sounds/zombie-20.wav', 'static')
			, soundManager.get('sounds/zombie-21.wav', 'static')
		}
	}
end

function Entity:addComponent(component)
	self.components[component.uid] = component
	component.init(self)
end

function Entity:c(uid)
	return self.components[uid]
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
	entities.occupy(idx, self.id)
end

function Entity:unoccupy()
	local idx = self.pos.y * map.width() + self.pos.x
	entities.unoccupy(idx, self.id)
end

function Entity:reactionTowards(other)
	if self.class ~= other.class then
		return -1
	end

	return 0
end

function Entity:getDamage()
	return self.damage
end

function Entity:takeHit(dmg)
	--print(self.name .. ' is taking '..dmg..' damage')
	self.hp = self.hp - dmg

	messages.popups.queue({
		txt=('-%d'):format(dmg), delay=0, fading=true,
		getWorldPos=function() return self.pos end
	})

	if self.hp <= 0 then
		self:die()
		return false
	end

	return true
end

function Entity:die()
	self:unoccupy()
	entities.del(self)
end

function Entity:_checkMap(nPos, location)
	-- check map
	if nPos.x < 0 or nPos.x == map.width() or nPos.y < 0 or nPos.y == map.height() then
		return action.Action.Blocked
	end
	if map.notPassable(location) then
		return action.Action.Blocked
	end

	return nil
end

function Entity:_checkElements(nPos, location)
	-- check elements
	local prop = elements.check(location)
	if prop == action.Action.Blocked then
		return action.Action.Blocked
	end
	if prop == action.Action.Attack then
		return action.Action.Attack,nPos
	end

	--print("OK new player position: ", nPos)
	return action.Action.Move, nPos
end

function Entity:wantGo(dir)
	local nPos = self.pos + dir
	local location = nPos.y * map.width() + nPos.x
	if action.Action.Blocked == self:_checkMap(nPos, location) then
		return action.Action.Blocked
	end

	-- check entities
	if dir.x ~= 0 or dir.y ~= 0 then
		local entProp = entities.check(location, self)
		if entProp == action.Action.Blocked then
			console.log('wantGo' .. tostring(dir) .. ' ' .. self.name .. ' entProp blocked')
			return action.Action.Blocked
		elseif entProp == action.Action.Attack then
			console.log('wantGo' .. tostring(dir) .. ' ' .. self.name .. ' entProp attack ' .. tostring(nPos))
			return action.Action.Attack, nPos
		end
	end

	return self:_checkElements(nPos, location)
end

function Entity:sound(_actionId)

	local rnd = self.rng:random(#self.sounds.walk)
	if self.sounds.walk[rnd]:isPlaying() then
		--self.sounds.walk[rnd]:stop()
		return
	end

	self.sounds.walk[rnd]:setVolume(0.2 + self.rng:random()*0.3 )
	if self.rng:random() > 0.3 then
		self.sounds.walk[rnd]:setPitch(1.0 + self.rng:random())
	end

	self.sounds.walk[rnd]:play()
	--console.log('playing ' .. rnd .. ' with pitch ' .. self.sounds.walk[rnd]:getPitch() .. ' and volume ' .. self.sounds.walk[rnd]:getVolume())
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
		-- console.log('move() ' .. self.name .. ' specialCase')
		return false

	elseif action.Action.Blocked == entProperty then
		-- one ent that have self has non-negative reaction towards blocked the field earlier,
		-- really nothing to do in this case
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

	local prop = elements.check(idx)
	-- TODO : element might have already been destroyed here (by someone else)
	if prop == action.Action.Attack then
		elements.smash(idx)
	end

	self.doRecalc = true
	return 0,0
end

function Entity:analyze()
end

function Entity:__tostring()
	return self.name .. '[' .. self.id .. ']' .. tostring(self.pos)
end

function Entity:checkDirLight(position, dir)
	local nPos = position + dir
	local location = nPos.y * map.width() + nPos.x
	-- if self.vismap[location] == 0 then
	-- 	return action.Action.Blocked
	-- end

	-- TODO: need to disable this for non-player entities (currently hack using id=1)
	if 1 == self.id and not map.isKnown(location) then
		return action.Action.Blocked
	end

	if action.Action.Blocked == self:_checkMap(nPos, location) then
		return action.Action.Blocked
	end

	return self:_checkElements(nPos, location)
end

-- planning limited to 12 cells in both directions
local Plan_Limit = 9
function Entity:findPath(destination)
	local time1 = love.timer.getTime()

	local normalCost = math.floor(self.Base_Speed / 60)
	local bashCost = math.floor((self.Base_Speed + self.Bash_Speed) / 60)
	local result, subres = astar(self.pos, destination, {
		toId = function(pos)
			return pos.y * map.width() + pos.x
		end,
		heuristic = function(a, b)
			return 7 * normalCost * a:dist(b)
		end,
		neighbors = function(source, node)
			local n = {}
			if node.x > source.x - Plan_Limit then
				local r, nPos = self:checkDirLight(node, Vec(-1, 0))
				if action.Action.Blocked  ~= r then
					table.insert(n, nPos)
				end
			end

			if node.x < source.x + Plan_Limit then
				local r, nPos = self:checkDirLight(node, Vec(1, 0))
				if action.Action.Blocked  ~= r then
					table.insert(n, nPos)
				end
			end

			if node.y > source.y - Plan_Limit then
				local r, nPos = self:checkDirLight(node, Vec(0, -1))
				if action.Action.Blocked  ~= r then
					table.insert(n, nPos)
				end
			end

			if node.y < source.y + Plan_Limit then
				local r, nPos = self:checkDirLight(node, Vec(0, 1))
				if action.Action.Blocked  ~= r then
					table.insert(n, nPos)
				end
			end

			--print('neighbors ' .. tostring(node) .. ' ' .. #n)
			return n
		end,
		cost = function(a, b)
			local dir = b - a
			local r, nPos = self:checkDirLight(a, dir)
			if r == action.Action.Attack then
				return bashCost
			end
			return normalCost
		end
	})

	-- local time2 = love.timer.getTime()
	-- if result then
	-- 	print(string.format(tostring(self) .. 'astar success took %.5f ms', (time2 - time1) * 1000))
	-- else
	-- 	print(string.format(tostring(self) .. 'astar failed took %.5f ms', (time2 - time1) * 1000))
	-- end
	return result, subres
end

return Entity
