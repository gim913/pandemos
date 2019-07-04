-- imported modules
local batch = require 'batch'
local Camera = require 'Camera'
local Level = require 'Level'
local Player = require 'Player'
local S = require 'settings'

local action = require 'engine.action'
local class = require 'engine.oop'
local elements = require 'engine.elements'
local entities = require 'engine.entities'
local Entity = require 'engine.Entity'
local fontManager = require 'engine.fm'
local map = require 'engine.map'
local utils = require 'engine.utils'
local Vec = require 'hump.vector'

-- class
local Game = class('Game')

local player = nil
local Max_Dummies = 5
local dummies = {}

local function addLevel(levels, rng, depth)
	local l = Level:new(rng, depth)
	table.insert(levels, l)
	return l
end

local function processPlayerFov()
	local time1 = love.timer.getTime()
	for _,e in pairs(entities.with(entities.Attr.Has_Fov)) do
		e:recalcVisMap()
	end
	for _,e in pairs(entities.with(entities.Attr.Has_Fov)) do
		e:recalcSeeMap()
	end
	local time2 = love.timer.getTime()
	print(string.format('fov+los took %.5f ms', (time2 - time1) * 1000))
end

local function updateTiles()
	batch.update(camera.followedEnt, camera.pos.x - camera.rel.x, camera.pos.y - camera.rel.y)
end

local Entity_Tile_Size = 32
local evilTurtleImg

function Game:ctor(rng)
	self.rng = rng
	self.seed = 0
	self.fatFont = fontManager.get(32)

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

	local f = math.floor
	player = Player:new(Vec(f(map.width() / 2), map.height() - 59))
	player.img = love.graphics.newImage("player.png")
	player.losRadius = 15
	player.seeDist = 15

	entities.add(player)
	entities.addAttr(player, entities.Attr.Has_Fov)
	entities.addAttr(player, entities.Attr.Has_Move)
	entities.addAttr(player, entities.Attr.Has_Attack)

	-- TODO: get rid of dummies later

	evilTurtleImg = love.graphics.newImage("evilturtle.png")
	for i = 1, Max_Dummies do
		local rx = self.rng:random(-15, 15)
		local ry = self.rng:random(0, 30)
		local dummy = Entity:new(Vec(f(map.width() / 2 + rx), map.height() - 45 - ry))
		dummy.img = evilTurtleImg
		entities.add(dummy)
		entities.addAttr(dummy, entities.Attr.Has_Fov)
		entities.addAttr(dummy, entities.Attr.Has_Move)
		dummy:occupy()

		table.insert(dummies, dummy)
	end

	local elemPos = Vec(f(map.width() / 2 - 5), map.height() - 27)
	local idx = elemPos.y * map.width() + elemPos.x
	local go = elements.create(idx)
	go:setTileId(3 * 16)

	camera = Camera:new()
	camera:follow(player)
	camera:update()

	cameraIdx = 0
	--updateTiles()
end

local tileSize = 30
local tileBorder = 1

function Game:handleWheel(x, y)
	S.game.VIS_RADIUS = math.max(12, math.min(63, S.game.VIS_RADIUS + y))

	tileSize = batch.recalc(S.game.VIS_RADIUS)
	camera:follow(player)
	camera:update()
	updateTiles()
end

function Game:handleInput(key)
	local nextAct=action.Action.Blocked, nPos

	if love.keyboard.isDown('lctrl') then
		if key == "1" then
			-- toggle flag
			current = batch.debug('disableVismap') or false
			batch.debug({ disableVismap = not current })
			updateTiles()
		end
	end

	if #(player.actions) == 0 then
		if key == "up" or key == "kp8" then
			nextAct,nPos = player:wantGo(Vec( 0,-1))
		elseif key == "down" or key == "kp2" then
			nextAct,nPos = player:wantGo(Vec( 0, 1))
		elseif key == "left" or key == "kp4" then
			nextAct,nPos = player:wantGo(Vec(-1, 0))
		elseif key == "right" or key == "kp6" then
			nextAct,nPos = player:wantGo(Vec( 1, 0))
		elseif key == "." or key == "kp5" then
			nextAct,nPos = player:wantGo(Vec( 0, 0))

		-- TODO: remove this before releasing ^^
		elseif key == "tab" then
			if cameraIdx == Max_Dummies then
				camera:follow(player)
				cameraIdx = 0
			else
				cameraIdx = cameraIdx + 1
				camera:follow(dummies[cameraIdx])
			end
			camera:update()
			updateTiles()
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

local g_gameTime = 0
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
				-- debug
				if (e == player) then
					g_gameTime = g_gameTime + e.action.need
				end
				-- end debug
				e.action.need = 0

				-- finalize action
				e.actionState = currentAction.state
				e.actionData = currentAction.val
				--print ('action ended ' .. currentAction.val.x .. "," .. currentAction.val.y)
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

local function processAttacks()
	local ret = false
	for _,e in pairs(entities.with(entities.Attr.Has_Attack)) do
		if e.actionState == action.Action.Attack then
			print('processing attack')
			e:attack(0, 0)
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
		self.updateLevel = level:update(dt)

		-- update after updating the map
		if not self.updateLevel then
			-- recalc player fov, after map is generated
			processPlayerFov()

			-- update batch
			print('updating batch')
			updateTiles()
		end

	elseif self.doActions then
		self.doActions = processActions()

		local movementDone = processMoves()
		processAttacks()

		elements.process()

		-- if movementDone then
		-- 	elements.refresh()
		-- end

		if updateTilesAfterMove then
			camera:update()

			-- TODO: XXX: TODO: IMPORTANT: probably wrong location
			processPlayerFov()

			updateTiles()
			updateTilesAfterMove = false
		end
	end
end

function Game:show()
	if self.updateLevel then
		local level = self.levels[self.depthLevel]
		level:show()
	else
		love.graphics.print("radius: "..S.game.VIS_RADIUS, S.resolution.x - 200 - 10, 30)
		love.graphics.print("player: " .. player.pos.x .. "," .. player.pos.y, S.resolution.x - 200 - 10, 50)
		love.graphics.print("camera: " .. cameraIdx, S.resolution.x - 200 - 10, 70)
		love.graphics.print("global timestep: " .. g_gameTime, S.resolution.x - 200 - 10, 90)

		batch.draw()

		love.graphics.setColor(1.0, 1.0, 1.0, 1.0)

		local scaleFactor = tileSize / Entity_Tile_Size
		for _,ent in pairs(entities.all()) do
			local rx = ent.pos.x - camera.pos.x + camera.rel.x
			local ry = ent.pos.y - camera.pos.y + camera.rel.y

			if camera.followedEnt == ent or camera.followedEnt.seemap[ent] then
				love.graphics.draw(ent.img, rx * (tileSize + tileBorder), ry * (tileSize + tileBorder), 0, scaleFactor, scaleFactor)
			end
		end
	end
end

return Game