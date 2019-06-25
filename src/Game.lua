-- imported modules
local action = require 'engine.action'
local class = require 'engine.oop'
local entities = require 'engine.entities'
local Entity = require 'engine.Entity'
local fontManager = require 'engine.fm'
local map = require 'engine.map'
local utils = require 'engine.utils'
local Vec = require 'hump.vector'
local batch = require 'batch'
local Camera = require 'Camera'
local Level = require 'Level'
local Player = require 'Player'
local S = require 'settings'

-- class
local Game = class('Game')

local player = nil
local dummy = nil

local function addLevel(levels, rng, depth)
	local l = Level:new(rng, depth)
	table.insert(levels, l)
	return l
end

local function playerPosChanged()
	batch.update(camera.followedEnt, camera.pos.x - camera.rel.x, camera.pos.y - camera.rel.y)
end

function Game:ctor(rng)
	self.rng = rng
	self.seed = 0
	self.fatFont = fontManager.get(32)

	self.at = love.graphics.newImage("player.png")

	self.levels = {}
	for depth = 1, S.game.DEPTH do
		addLevel(self.levels, self.rng, depth)
	end

	self.depthLevel = 1
	self.updateLevel = false
	self.doActions = false

	batch.prepare()
	local level = self.levels[self.depthLevel]
	map.init(level.w, level.h)
	self.mapdata = map.getData()

	local f = math.floor
	player = Player:new(Vec(f(map.width() / 2), map.height() - 29))
	entities.add(player)
	entities.addAttr(player, entities.Attr.Has_Move)

	-- todo: remove dummy
	dummy = Entity:new(Vec(f(map.width() / 2 - 10), map.height() - 25))
	entities.add(dummy)
	entities.addAttr(dummy, entities.Attr.Has_Move)

	camera = Camera:new()
	camera:follow(player)
	camera:update()
	--playerPosChanged()
end

function Game:handleInput(key)
	local nextAct=action.Action.Blocked, nPos
	if #(player.actions) == 0 then
		if key == "up" or key == "kp8" then
			nextAct,nPos = player:wantGo(Vec( 0,-1))
		elseif key == "kp7" then
			nextAct,nPos = player:wantGo(Vec(-1,-1))
		elseif key == "kp9" then
			nextAct,nPos = player:wantGo(Vec( 1,-1))
		elseif key == "down" or key == "kp2" then
			nextAct,nPos = player:wantGo(Vec( 0, 1))
		elseif key == "kp1" then
			nextAct,nPos = player:wantGo(Vec(-1, 1))
		elseif key == "kp3" then
			nextAct,nPos = player:wantGo(Vec( 1, 1))
		elseif key == "left" or key == "kp4" then
			nextAct,nPos = player:wantGo(Vec(-1, 0))
		elseif key == "right" or key == "kp6" then
			nextAct,nPos = player:wantGo(Vec( 1, 0))
		elseif key == "." or key == "kp5" then
			nextAct,nPos = player:wantGo(Vec( 0, 0))

		-- todo: remove this
		elseif key == "tab" then
			if camera:isFollowing(player) then
				camera:follow(dummy)
			else
				camera:follow(player)
			end
			camera:update()
			playerPosChanged()
		end
	end

	-- todo: remove debug
	if #(dummy.actions) == 0 then
		if dummy.pos.y ~= map.height() - 1 then
			action.queue(dummy.actions, 1500, action.Action.Move, dummy.pos + Vec(0, 1))
		end
	end

	if nextAct ~= action.Action.Blocked then
		--print('action ', nextAct)
		if nextAct == action.Action.Attack then
			action.queue(player.actions, Player.Bash_Speed, action.Action.Attack, nPos)
		else
			action.queue(player.actions, Player.Base_Speed, action.Action.Move, nPos)
		end
		self.doActions = true
	end
end

function Game:startLevel()
	local level = self.levels[self.depthLevel]
	if not level.visited then
		level:initializeGenerator()
		self.updateLevel = true
	end
end

local Action_Step = 60
local function processActions()
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
			--print ('action progress: ' .. e.name .. " " .. e.action.progress .. " " .. utils.repr(currentAction))

			if e.action.progress >= e.action.need then
				e.action.progress = e.action.progress - e.action.need
				e.action.need = 0

				-- finalize action
				e.actionState = currentAction.state
				e.actionData = currentAction.val
				--print ('action ended ' .. currentAction.val.x .. "," .. currentAction.val.y)
				table.remove(e.actions, 1)
				if (e == player) then
					return false
				end
			end
		end
	end

	return true
end

local updateTilesAfterMove = false
-- returns true when there was any move
-- will require some recalculations later
local function processMoves()
	local ret = false
	for _,e in pairs(entities.with(entities.Attr.Has_Move)) do
		if e.actionState == action.Action.Move then
			e:move()

			-- reset action
			e.actionState = action.Action.Idle

			if camera:isFollowing(e) then
				updateTilesAfterMove = true
			end

			ret = true
		end
	end
	return ret
end

function Game:update(dt)
	-- keep running level update, until level generation is done
	if self.updateLevel then
		local level = self.levels[self.depthLevel]
		self.updateLevel = level:update(dt, self.mapdata)

		-- temporary: update after updating the map
		print('updating batch')
		playerPosChanged()

	elseif self.doActions then
		self.doActions = processActions()

		local movementDone = processMoves()
		if updateTilesAfterMove then
			camera:update()
			playerPosChanged()
			updateTilesAfterMove = false
		end
	end
end

local tileSize = 30

function Game:show()
	if self.updateLevel then
		local level = self.levels[self.depthLevel]
		level:show()
	else
		batch.draw()

		love.graphics.setColor(0.25, 0.25, 0.25, 1.0)

		local scaleFactor = tileSize / self.at:getWidth()
		-- TODO: draw only entities in range
		for _,ent in pairs(entities.all()) do
			local rx = ent.pos.x - camera.pos.x + camera.rel.x
			local ry = ent.pos.y - camera.pos.y + camera.rel.y
			love.graphics.draw(self.at, rx * (tileSize + 1), ry * (tileSize + 1), 0, scaleFactor, scaleFactor)
		end
	end
end

return Game