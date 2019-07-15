-- imported modules
local batch = require 'batch'
local Camera = require 'Camera'
local GameMenu = require 'GameMenu'
local Infected = require 'EInfected'
local interface = require 'interface'
local Level = require 'Level'
local Player = require 'Player'
local S = require 'settings'
local Tiles = require 'Tiles'

local action = require 'engine.action'
local class = require 'engine.oop'
local console = require 'engine.console'
local elements = require 'engine.elements'
local entities = require 'engine.entities'
local fontManager = require 'engine.fontManager'
local map = require 'engine.map'
local utils = require 'engine.utils'

local Entity = require 'engine.Entity'

local gamestate = require 'hump.gamestate'
local Vec = require 'hump.vector'

-- class
local Game = class('Game')

console.initialize((31 * 25) + 10 + 128, 100, 900)

local f = math.floor
local camera = nil
local player
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
	local camLu = camera:lu()
	batch.update(camera.followedEnt, camLu.x, camLu.y)
end

local Entity_Tile_Size = 64

local function prepareLetters(letters)
	local font = fontManager.get('fonts/FSEX300.ttf', 64, 'normal')
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
	map.initialize(level.w, level.h)

	minimapData = love.image.newImageData(level.w, level.h)
	minimapData:mapPixel(function(x, y, r, g, b, a)
		return 0.1, 0.1, 0.1, 1.0
	end)
	updateMinimap()

	self.letters = prepareLetters('@IBCSTM')
	local f = math.floor
	player = Player:new(Vec(f(map.width() / 2), map.height() - 29))
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
		entities.addAttr(dummy, entities.Attr.Has_Attack)
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
local tileSizeAdj = tileSize + tileBorder

function Game:mousepressed(x, y)
	if player.astar_path then
		player.follow_path = 1
	end
end

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
		tileSizeAdj = tileSize + tileBorder
		camera:follow(player)
		camera:update()
		updateTiles()
	end
end

local function playerMoveAction(moveVec)
	local nextAct,nPos = player:wantGo(moveVec)
	if nextAct ~= action.Action.Blocked then
		--print('action ', nextAct)
		if nextAct == action.Action.Attack then
			action.queue(player.actions, Player.Bash_Speed, action.Action.Attack, nPos)
		else
			action.queue(player.actions, Player.Base_Speed, action.Action.Move, nPos)
		end
		return true, nextAct
	end

	return false
end

local Move_Vectors = {
	Vec( 0, -1), -- up
	Vec( 0,  1), -- down
	Vec(-1,  0), -- left
	Vec( 1,  0), -- right
	Vec( 0,  0) -- rest
}

local function checkKeyPress(pressedKey, keyNames)
	for _, keyName in pairs(keyNames) do
		if keyName == pressedKey then
			return true
		end
	end

	return false
end

local function movementKeyToVector(pressedKey)
	for index = 1, #Move_Vectors do
		if checkKeyPress(pressedKey, S.keyboard[index]) then
			return Move_Vectors[index]
		end
	end

	return nil
end

function Game:keypressed(key)
	local nextAct=action.Action.Blocked, nPos

	if 'escape' == key then
		gamestate.push(GameMenu:new())

		-- TODO: XXX: TODO: devel: quit
		-- love.event.push("quit")
		-- gamestate.pop()
	end

	if '`' == key or '~' == key then
		console.toggle()
	end

	-- TODO: XXX: TODO: devel: quit
	if love.keyboard.isDown('lctrl') then
		if key == "1" then
			-- toggle flag
			current = batch.debug('disableVismap') or false
			batch.debug({ disableVismap = not current })
			updateTiles()
		end
	end

	local moveVec = nil
	if #(player.actions) == 0 then
		-- ignore keyboard controls if following the path
		if not player.follow_path then
			moveVec = movementKeyToVector(key)
			print(tostring(moveVec))
		end

		-- TODO: remove this before releasing ^^
		if key == "tab" then
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

	if moveVec and playerMoveAction(moveVec) then
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

local updateTilesAfterMove = false
-- returns true when there was any move
-- will require some recalculations later
local function processMoves()
	local ret = false
	for _,e in pairs(entities.with(entities.Attr.Has_Move)) do
		if e.actionState == action.Action.Move then
			e:move()
			e.actionState = action.Action.Idle

			-- fire up ai to queue next action item
			e:analyze(player)

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
			e:attack()
			e.actionState = action.Action.Idle

			-- fire up ai to queue next action item
			e:analyze(player)

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

local function pathPlayerMovement()
	local ret = false

	if player.astar_path and player.follow_path and player.follow_path > 0 then
		local moveVec = player.astar_path[player.follow_path] - player.pos
		local nextAction

		ret, nextAction = playerMoveAction(moveVec)
		if ret and action.Action.Move == nextAction then
			player.follow_path = player.follow_path + 1
			if player.follow_path > #player.astar_path then
				player.follow_path = nil
				player.astar_path = nil
			end
		end
	end

	return ret
end

local mouseCell = nil

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
	-- at this point map should be ready, fire up AI once,
	-- afterwards it should be fired after finishing actions
	if totalTime == 0 then
		processAi()
		totalTime = 1
	end

	if #(player.actions) == 0 then
		self.doActions = pathPlayerMovement()
	end

	if self.doActions then
		self.doActions = entities.processActions(player)
		local movementDone = processMoves()
		processAttacks()

		elements.process()

		-- if movementDone then
		-- 	elements.refresh()
		-- end

		if updateTilesAfterMove then
			camera:update()

			--processAi()

			-- TODO: XXX: TODO: IMPORTANT: probably wrong location
			processEntitiesFov()

			updateTiles()
			updateTilesAfterMove = false
		end
	end

	local mouseX, mouseY = love.mouse.getPosition()

	local vis = 2 * S.game.VIS_RADIUS + 1
	if mouseX >= 0 and mouseX < (tileSizeAdj * vis) and mouseY >= 0 and mouseY < (tileSizeAdj * vis) then
		local newMouseCell = Vec(math.floor(mouseX / tileSizeAdj), math.floor(mouseY / tileSizeAdj))
		if not mouseCell or newMouseCell ~= mouseCell then
			mouseCell = newMouseCell
			if not player.follow_path or player.follow_path == 0 then
				local camLu = camera:lu()
				local destination = camLu + mouseCell
				player.astar_path = player:findPath(destination)
			end
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

local function drawEntityPath(ent, camLu)
	if S.game.debug and not S.game.debug.show_astar_paths then
		return
	end

	if not ent.astar_path then
		return
	end

	for i, node in pairs(ent.astar_path) do
		local relPos = node - camLu
		if camera.followedEnt == ent then
			love.graphics.setColor(0.1, 0.1, 0.1, 0.5)
			love.graphics.rectangle('fill', relPos.x * tileSizeAdj, relPos.y * tileSizeAdj, tileSize + 1, tileSize + 1)
			love.graphics.setColor(0.9, 0.9, 0.9, 1.0)
			love.graphics.print(tostring(i), relPos.x * tileSizeAdj + 10, relPos.y * tileSizeAdj + 10)
		else
			love.graphics.setColor(0.9, 0.7, 0.7, 0.5)
			love.graphics.rectangle('fill', relPos.x * tileSizeAdj, relPos.y * tileSizeAdj, tileSize + 1, tileSize + 1)
			love.graphics.setColor(0.3, 0.1, 0.1, 1.0)
			love.graphics.print(tostring(i), relPos.x * tileSizeAdj, relPos.y * tileSizeAdj)
		end
	end
end

local function drawEntities()
	local scaleFactor = tileSize / Entity_Tile_Size
	local camLu = camera:lu()
	for _,ent in pairs(entities.all()) do
		local relPos = ent.pos - camLu
		if ent == player then
			love.graphics.setColor(0.9, 0.9, 0.9, 1.0)
		else
			love.graphics.setColor(0.7, 0.1, 0.1, 1.0)
		end

		-- drawEntity
		if camera.followedEnt == ent or camera.followedEnt.seemap[ent] then
			love.graphics.draw(ent.img, relPos.x * tileSizeAdj, relPos.y * tileSizeAdj, 0, scaleFactor, scaleFactor)

			-- show entity name on hover -- TODO: remove
			if mouseCell and relPos == mouseCell then
				love.graphics.setColor(0.9, 0.9, 0.9, 0.8)
				love.graphics.rectangle('fill', (mouseCell.x + 1) * tileSizeAdj, mouseCell.y * tileSizeAdj, 2 * tileSize + 1, 16)
				love.graphics.setColor(0.0, 0.0, 0.0, 1.0)
				love.graphics.print(ent.name, (mouseCell.x + 1) * tileSizeAdj, mouseCell.y * tileSizeAdj)
			end

			-- if ent.astar_visited then
			-- 	for k, v in pairs(ent.astar_visited) do
			-- 		local sx = v.x - camLuX
			-- 		local sy = v.y - camLuY

			-- 		love.graphics.setColor(0.9, 0.9, 0.9, 0.3)
			-- 		love.graphics.rectangle('fill', sx * ts, sy * ts, tileSize + 1, tileSize + 1)
			-- 	end
			-- end

			drawEntityPath(ent, camLu)
		end
	end
end

local function drawMinimap()
	local scale = (31 * 25) / minimapImg:getHeight()
	love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
	love.graphics.draw(minimapImg, (31 * 25) + 10, 0, 0, 1, scale)
end

local function drawInterface()
	local startX = (31 * 25) + 10 + minimapImg:getWidth() + 10
	local h = interface.drawPlayerInfo(player, startX, 10, 260)

	local camLu = camera.lu()
	interface.drawVisible(player.seemap, startX, 10 + h + 10, 260, function(ent)
		local relPos = ent.pos - camLu
		if mouseCell and relPos == mouseCell then
			return true
		end
		return false
	end)
end

function Game:draw()
	if self.updateLevel then
		local level = self.levels[self.depthLevel]
		level:show()
	else
		-- TODO: debug info
		local camLu = camera:lu()
		love.graphics.print("radius: "..S.game.VIS_RADIUS, S.resolution.x - 200 - 10, 30)
		love.graphics.print("player: " .. player.pos.x .. "," .. player.pos.y, S.resolution.x - 200 - 10, 50)
		love.graphics.print("camera: " .. cameraIdx, S.resolution.x - 200 - 10, 70)
		if mouseCell then
			local mapCoords = camLu + mouseCell
			love.graphics.print("mouse: " .. tostring(mapCoords), S.resolution.x - 200 - 10, 90)
		end


		-- draw map
		batch.draw()

		-- ^^
		drawEntities()

		if mouseCell then
			love.graphics.setColor(0.5, 0.9, 0.5, 0.9)
			love.graphics.rectangle('line', mouseCell.x * tileSizeAdj, mouseCell.y * tileSizeAdj, tileSize + 1, tileSize + 1)
		end

		drawInterface()
		drawMinimap()
		console.draw(0, 900 - console.height())
	end
end

return Game