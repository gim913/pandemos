-- imported modules
local batch = require 'batch'
local Camera = require 'Camera'
local Infected = require 'EInfected'
local Level = require 'Level'
local Player = require 'Player'
local S = require 'settings'
local Tiles = require 'Tiles'

local action = require 'engine.action'
local class = require 'engine.oop'
local console = require 'engine.console'
local elements = require 'engine.elements'
local entities = require 'engine.entities'
local fontManager = require 'engine.fm'
local map = require 'engine.map'
local utils = require 'engine.utils'

local Entity = require 'engine.Entity'

local gamestate = require 'hump.gamestate'
local Vec = require 'hump.vector'

-- class
local Game = class('Game')

local f = math.floor

console.initialize(800, 100, 900)

local player = nil
local Max_Dummies = 5
local dummies = {}

local minimapData = nil
local minimapImg = nil
local function updateMinimap()
	minimapImg = love.graphics.newImage(minimapData)
	minimapImg:setFilter("nearest", "nearest")
end

local function addLevel(levels, rng, depth)
	local l = Level:new(rng, depth)
	table.insert(levels, l)
	return l
end

local function processEntitiesFov()
	local time1 = love.timer.getTime()
	for _,e in pairs(entities.with(entities.Attr.Has_Fov)) do
		e:recalcVisMap()
	end
	for _,e in pairs(entities.with(entities.Attr.Has_Fov)) do
		e:recalcSeeMap()
	end
	local time2 = love.timer.getTime()
	print(string.format('fov+los took %.5f ms', (time2 - time1) * 1000))

	-- updated fog-of-war

	for k,v in pairs(player.vismap) do
		if v > 0 then
			map.known(k)
			local tileId = map.getTileId(k)
			local r,g,b = 25,25,25
			if tileId >= Tiles.Water and tileId < Tiles.Earth then
				r,g,b = 0x4c, 0x9a, 0xec
			elseif tileId >= Tiles.Earth and tileId < Tiles.Grass then
				r,g,b = 0x3c, 0x18, 0x00
			elseif tileId >= Tiles.Grass and tileId < Tiles.Bridge then
				r,g,b = 0x08, 0x7c, 0x00
			elseif tileId == Tiles.Bridge then
				r,g,b = 0x78, 0x3c, 0x00
			else
				r,g,b = 64, 64, 64
			end

			local x = f(k % map.width())
			local y = f(k / map.width())
			minimapData:setPixel(x, y, r / 255.0, g / 255.0, b / 255.0, 1.0)
		end
	end
	updateMinimap()
end

local function updateTiles()
	local sx, sy = camera:lu()
	batch.update(camera.followedEnt, sx, sy)
end

local Entity_Tile_Size = 64

local function prepareLetters(letters)
	local font = love.graphics.newFont('fonts/FSEX300.ttf', 64, 'normal')
	love.graphics.setFont(font)

	local images = {}
	for i = 1, #letters do
		local c = letters:sub(i, i)
		canvas = love.graphics.newCanvas(64, 64)
		love.graphics.setCanvas(canvas)
		love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
		love.graphics.printf(c, 0, 0, 64, 'center')
		love.graphics.setCanvas()

		images[c] = canvas
	end

	return images
end

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

	minimapData = love.image.newImageData(level.w, level.h)
	minimapData:mapPixel(function(x, y, r, g, b, a)
		return 0.1, 0.1, 0.1, 1.0
	end)
	updateMinimap()

	self.letters = prepareLetters('@IBCSTM')
	local f = math.floor
	player = Player:new(Vec(f(map.width() / 2), map.height() - 59))
	player.img = self.letters['@'] --love.graphics.newImage("player.png")
	player.losRadius = 15
	player.seeDist = 15

	entities.add(player)
	entities.addAttr(player, entities.Attr.Has_Fov)
	entities.addAttr(player, entities.Attr.Has_Move)
	entities.addAttr(player, entities.Attr.Has_Attack)

	-- TODO: get rid of dummies later
	for i = 1, Max_Dummies do
		local rx = self.rng:random(-15, 15)
		local ry = self.rng:random(0, 30)
		local dummy = Infected:new(Vec(f(map.width() / 2 + rx), map.height() - 45 - ry))
		dummy.img = self.letters['I']
		entities.add(dummy)
		entities.addAttr(dummy, entities.Attr.Has_Fov)
		entities.addAttr(dummy, entities.Attr.Has_Move)
		entities.addAttr(dummy, entities.Attr.Has_Ai)
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

function Game:wheelmoved(x, y)
	if love.keyboard.isDown('lctrl') then
		if love.keyboard.isDown('lshift') then
			console.nextFont()
		else
			console.changeFontSize(y)
		end
	else
		S.game.VIS_RADIUS = math.max(12, math.min(63, S.game.VIS_RADIUS + y))

		tileSize = batch.recalc(S.game.VIS_RADIUS)
		camera:follow(player)
		camera:update()
		updateTiles()
	end
end

function Game:keypressed(key)
	local nextAct=action.Action.Blocked, nPos

	if 'escape' == key then
		-- -- TODO: XXX: TODO: devel: quit
		love.event.push("quit")

		gamestate.pop()
	end

	if '`' == key or '~' == key then
		console.toggle()
	end

	-- -- TODO: XXX: TODO: devel: quit
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
	love.window.setTitle("Pandemos - (game in progress)")
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

local function processAi()
	local ret = false
	for _,e in pairs(entities.with(entities.Attr.Has_Ai)) do
		if e.actionState == action.Action.Idle then
			if e:analyze(player) then
				ret = true
			end
		end
	end

	return ret
end

local mouseCellX = nil
local mouseCellY = nil

function Game:doUpdateLevel(dt)
	local level = self.levels[self.depthLevel]
	self.updateLevel = level:update(dt)

	-- update after updating the map
	if not self.updateLevel then
		-- recalc player fov, after map is generated
		processEntitiesFov()

		-- update batch
		print('updating batch')
		updateTiles()
	end
end

local totalTime = 0
function Game:doUpdate(dt)
	totalTime = totalTime + dt
	if totalTime > 0.5 then
		totalTime = totalTime - 0.5
		if processAi() then
			--self.doActions = true
		end
	end

	if self.doActions then
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
			processEntitiesFov()

			updateTiles()
			updateTilesAfterMove = false
		end
	end

	local mouseX, mouseY = love.mouse.getPosition()

	local ts = (tileSize + tileBorder)
	local vis = 2 * S.game.VIS_RADIUS + 1
	if mouseX >= 0 and mouseX < (ts * vis) and mouseY >= 0 and mouseY < (ts * vis) then
		local newMouseCellX = math.floor(mouseX / ts)
		local newMouseCellY = math.floor(mouseY / ts)

		if newMouseCellX ~= mouseCellX or newMouseCellY ~= mouseCellY then
			mouseCellX = newMouseCellX
			mouseCellY = newMouseCellY
		end
	else
		mouseCellX = nil
		mouseCellY = nil
	end

	console.update(dt)
end

function Game:update(dt)
	-- keep running level update, until level generation is done
	if self.updateLevel then
		self:doUpdateLevel(dt)
	else
		self:doUpdate(dt)
	end
end

function Game:draw()
	if self.updateLevel then
		local level = self.levels[self.depthLevel]
		level:show()
	else
		local cx, cy = camera:lu()
		love.graphics.print("radius: "..S.game.VIS_RADIUS, S.resolution.x - 200 - 10, 30)
		love.graphics.print("player: " .. player.pos.x .. "," .. player.pos.y, S.resolution.x - 200 - 10, 50)
		love.graphics.print("camera: " .. cameraIdx, S.resolution.x - 200 - 10, 70)
		if mouseCellX then
			love.graphics.print("mouse: " .. (cx + mouseCellX) .. "," .. (cy + mouseCellY), S.resolution.x - 200 - 10, 90)
		end
		love.graphics.print("global timestep: " .. g_gameTime, S.resolution.x - 200 - 10, 110)

		batch.draw()

		local scaleFactor = tileSize / Entity_Tile_Size
		local camLuX, camLuY = camera.lu()
		local ts = (tileSize + tileBorder)
		for _,ent in pairs(entities.all()) do
			local rx = ent.pos.x - camLuX
			local ry = ent.pos.y - camLuY

			if ent == player then
				love.graphics.setColor(0.9, 0.9, 0.9, 1.0)
			else
				love.graphics.setColor(0.7, 0.1, 0.1, 1.0)
			end

			if camera.followedEnt == ent or camera.followedEnt.seemap[ent] then
				love.graphics.draw(ent.img, rx * ts, ry * ts, 0, scaleFactor, scaleFactor)
				if rx == mouseCellX and ry == mouseCellY then
					love.graphics.setColor(0.9, 0.9, 0.9, 0.8)
					love.graphics.rectangle('fill', (mouseCellX + 1) * ts, mouseCellY * ts, 2 * tileSize + 1, 16)
					love.graphics.setColor(0.0, 0.0, 0.0, 1.0)
					love.graphics.print(ent.name, (mouseCellX + 1) * ts, mouseCellY * ts)
				end


				-- if ent.astar_visited then
				-- 	for k, v in pairs(ent.astar_visited) do
				-- 		local sx = v.x - camLuX
				-- 		local sy = v.y - camLuY

				-- 		love.graphics.setColor(0.9, 0.9, 0.9, 0.3)
				-- 		love.graphics.rectangle('fill', sx * ts, sy * ts, tileSize + 1, tileSize + 1)
				-- 	end
				-- end
				if ent.astar_path then
					for i, node in pairs(ent.astar_path) do
						local sx = node.x - camLuX
						local sy = node.y - camLuY

						love.graphics.setColor(0.9, 0.9, 0.9, 0.5)
						love.graphics.rectangle('fill', sx * ts, sy * ts, tileSize + 1, tileSize + 1)
						love.graphics.setColor(0.3, 0.1, 0.1, 1.0)
						love.graphics.print(tostring(i), sx * ts, sy * ts)
					end
				end
			end
		end

		if mouseCellX then
			love.graphics.setColor(0.9, 0.9, 0.9, 0.5)
			love.graphics.rectangle('fill', mouseCellX * ts, mouseCellY * ts, tileSize + 1, tileSize + 1)
		end

		local scale = S.resolution.y / minimapImg:getHeight()
		love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
		love.graphics.draw(minimapImg, 900 + 10, 0, 0, 1, scale)

		console.draw(0, 900 - console.height())
	end
end

return Game