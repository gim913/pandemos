-- imported modules
local batch = require 'batch'
local bindings = require 'bindings'
local Camera = require 'Camera'
local GameAction = require 'GameAction'
local GameMenu = require 'GameMenu'
local hud = require 'hud'
local Infected = require 'EInfected'
local Level = require 'Level'
local messages = require 'messages'
local Player = require 'Player'
local S = require 'settings'
local Tiles = require 'Tiles'

local action = require 'engine.action'
local class = require 'engine.oop'
local color = require 'engine.color'
local console = require 'engine.console'
local elements = require 'engine.elements'
local entities = require 'engine.entities'
local fontManager = require 'engine.fontManager'
local graphics = require 'engine.graphics'
local map = require 'engine.map'
local utils = require 'engine.utils'
local Entity = require 'engine.Entity'

local gamestate = require 'hump.gamestate'
local Vec = require 'hump.vector'

-- class
local Game = class('Game')

console.initialize((31 * 25) + 10 + 128, 100, 900)
messages.initialize(31 * 25, 31 * 25)

local function logError(message)
	console.log({ color.red, 'ERROR: ' .. message })
	print('ERROR: ' .. message)
end

local function posToLocation(pos)
	return pos.y * map.width() + pos.x
end

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

			local t = elements.getTileId(k)
			if t and t >= Tiles.Trees and t <= Tiles.Tree_Maple then
				r,g,b = 0x8, 0x2c, 0x8
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

local function createOutlineB(imgData)
	for x = 0, imgData:getWidth() - 1 do
		for y = 0, imgData:getHeight() - 1 do
			local r, g, b, a = imgData:getPixel(x, y)
			if a > 0.01 then
				imgData:setPixel(x, y - 1, 0, 0, 0, 1.0)
				imgData:setPixel(x, y - 2, 0, 0, 0, 1.0)
				break
			end
		end

		for y = imgData:getHeight() - 1, 0, -1 do
			local r, g, b, a = imgData:getPixel(x, y)
			if a > 0.01 then
				imgData:setPixel(x, y + 1, 0, 0, 0, 1.0)
				imgData:setPixel(x, y + 2, 0, 0, 0, 1.0)
				break
			end
		end
	end

	for y = 0, imgData:getHeight() - 1 do
		for x = 0, imgData:getWidth() - 1 do
			local r, g, b, a = imgData:getPixel(x, y)
			if a > 0.01 then
				imgData:setPixel(x - 1, y, 0, 0, 0, 1.0)
				imgData:setPixel(x - 2, y, 0, 0, 0, 1.0)
				break
			end
		end

		for x = imgData:getWidth() - 1, 0, -1 do
			local r, g, b, a = imgData:getPixel(x, y)
			if a > 0.01 then
				imgData:setPixel(x + 1, y, 0, 0, 0, 1.0)
				imgData:setPixel(x + 2, y, 0, 0, 0, 1.0)
				break
			end
		end
	end

	return imgData
end

local function createOutline(imgData)
	return createOutlineB(imgData)
end

local function prepareLetters(letters)
	local font = fontManager.get('fonts/FSEX300.ttf', 64, 'normal')
	love.graphics.setFont(font)

	local images = {}
	for i = 1, #letters do
		local c = letters:sub(i, i)
		canvas = love.graphics.newCanvas(64 + 10, 64 + 10)
		love.graphics.setCanvas(canvas)
		love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
		love.graphics.printf(c, 0, 0, 64, 'center')
		love.graphics.setCanvas()

		images[c] = love.graphics.newImage(createOutline(canvas:newImageData())) --canvas
	end

	return images
end


local classes = {
	Player = 1,
	Infected = 2
}

local Letters

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
	self.ui = {}
	-- self.ui.showGrabMenu
	-- self.ui.showDropMenu
	-- self.ui.examine
	-- self.ui.inventoryActions

	batch.prepare()
	local level = self.levels[self.depthLevel]
	map.initialize(level.w, level.h)

	minimapData = love.image.newImageData(level.w, level.h)
	minimapData:mapPixel(function(x, y, r, g, b, a)
		return 0.1, 0.1, 0.1, 1.0
	end)
	updateMinimap()

	Letters = prepareLetters('@iBCSTM[!')
	local f = math.floor
	player = Player:new(Vec(f(map.width() / 2) + 10, map.height() - 49))
	player.img = Letters['@']
	player.class = classes.Player

	entities.add(player)
	entities.addAttr(player, entities.Attr.Has_Fov)
	entities.addAttr(player, entities.Attr.Has_Move)
	entities.addAttr(player, entities.Attr.Has_Attack)

	-- TODO: get rid of dummies later
	for i = 1, Max_Dummies do
		local rx = self.rng:random(-15, 15)
		local ry = self.rng:random(0, 30)
		local dummy = Infected:new(Vec(f(map.width() / 2 + rx), map.height() - 45 - ry))
		dummy.img = Letters['i']
		dummy.class = classes.Infected

		entities.add(dummy)
		entities.addAttr(dummy, entities.Attr.Has_Fov)
		entities.addAttr(dummy, entities.Attr.Has_Move)
		entities.addAttr(dummy, entities.Attr.Has_Attack)
		entities.addAttr(dummy, entities.Attr.Has_Ai)
		dummy:occupy()

		table.insert(dummies, dummy)
	end

	local elemPos = Vec(f(map.width() / 2 - 5), map.height() - 27)
	local idx = posToLocation(elemPos)
	local go = elements.create(idx)
	go:setTileId(3 * 16)

	camera = Camera:new()
	camera:follow(player)
	camera:update()

	cameraIdx = 0
	--updateTiles()

	---

	self.canvas = love.graphics.newCanvas()
	self.shader = love.graphics.newShader[[
		extern number opacity;
		extern number offsetx;
		extern number offsety;
		float rand(vec2 co)
		{
			return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453123);
		}

		float noisef(vec2 st) {
			vec2 i = floor(st);
			vec2 f = fract(st);

			// Four corners in 2D of a tile
			float a = rand(i);
			float b = rand(i + vec2(1.0, 0.0));
			float c = rand(i + vec2(0.0, 1.0));
			float d = rand(i + vec2(1.0, 1.0));

			// Smooth Interpolation

			// Cubic Hermine Curve.  Same as SmoothStep()
			vec2 u = f*f*(3.0-2.0*f);
			// u = smoothstep(0.,1.,f);

			// Mix 4 coorners percentages
			return mix(a, b, u.x) +
					(c - a)* u.y * (1.0 - u.x) +
					(d - b) * u.x * u.y;
		}

		vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _)
		{
			vec2 pos = vec2((tc.x + offsetx / 5) * 144 * 3, (tc.y - offsety / 5) * 90 * 3);
			return color * Texel(texture, tc)
				* mix(0.0, pow(noisef(pos) + 0.2, 3), opacity);

		}
	]]

	self.shader:send("opacity", .9)
	self.shader:send("offsetx", 0)
	self.shader:send("offsety", 0)
end

-- semi constants
local Tile_Size = 30
local Tile_Border = 1
local Tile_Size_Adj = Tile_Size + Tile_Border


-- function love.textinput(t)
--     imgui.TextInput(t)
--     if not imgui.GetWantCaptureKeyboard() then
--         -- Pass event to the game
--     end
-- end

local cursorCell = nil

local function getFirstItemIndex(items)
	for index, item in pairs(items) do
		return index
	end
	return nil
end

local function logItems()
	local pos = cursorCell + camera:lu()
	local locationId = posToLocation(pos)
	local items, itemCount = elements.getItems(locationId)
	local vismap = player.vismap
	if itemCount <= 0 then
		return
	end

	if debug.disableVismap or (vismap[locationId] and vismap[locationId] > 0) then
		if 1 == itemCount then
			console.log({
				{ 1, 1, 1, 1 }, 'There is ',
				color.crimson, items[getFirstItemIndex(items)].desc.blueprint.name,
				{ 1, 1, 1, 1 }, ' lying there'
			})
		else
			local messages = {}
			table.insert(messages, color.white)
			table.insert(messages, 'There are multiple items lying here: ')
			local skipFirst = true
			for k, item in pairs(items) do
				if not skipFirst then
					table.insert(messages, color.white)
					table.insert(messages, ', ')
				end
				table.insert(messages, color.crimson)
				table.insert(messages, item.desc.blueprint.name)

				skipFirst = false
			end
			console.log(messages)
		end
		-- for _, item in ipairs(items) do
		-- 	items[1].desc.name
		-- end
	end
end

function Game:mousemoved(mouseX, mouseY)
	if hud.mousemoved(mouseX, mouseY) then
		return
	end

	if hud.captureInput() then
		return
	end

	-- TODO: limit to case where layer is generated

	local vis = 2 * S.game.VIS_RADIUS + 1
	if mouseX >= 0 and mouseX < (Tile_Size_Adj * vis) and mouseY >= 0 and mouseY < (Tile_Size_Adj * vis) then
		local newMouseCell = Vec(math.floor(mouseX / Tile_Size_Adj), math.floor(mouseY / Tile_Size_Adj))
		if not cursorCell or newMouseCell ~= cursorCell then
			cursorCell = newMouseCell
			logItems()
			if not player.follow_path or player.follow_path == 0 then
				local camLu = camera:lu()
				local destination = camLu + cursorCell
				player.astar_path = player:findPath(destination)
			end
		end
	else
		cursorCell = nil
	end
end

function Game:mousepressed(x, y, button)
	if hud.mousepressed(x, y, button) then
		return
	end

	if hud.captureInput() then
		return
	end

	if player.astar_path then
		player.follow_path = 1
	end
end

function Game:mousereleased(x, y, button)
	if hud.mousereleased(x, y, button) then
		return
	end
end

function Game:wheelmoved(x, y)
	if hud.wheelmoved(x, y) then
		return
	end

	if hud.captureInput() then
		return
	end

	if love.keyboard.isDown('lctrl') then
		if love.keyboard.isDown('lshift') then
			console.nextFont()
		else
			console.changeFontSize(y)
		end
	else
		S.game.VIS_RADIUS = math.max(12, math.min(63, S.game.VIS_RADIUS + y))

		Tile_Size = batch.recalc(S.game.VIS_RADIUS)
		Tile_Size_Adj = Tile_Size + Tile_Border
		camera:follow(player)
		camera:update()
		updateTiles()
	end
end

function Game:examineOnEnter(callback)
	self.ui.examineOnEnterCallback = callback
end

function Game:examineMaxDistance(maxDistance)
	self.ui.examineMaxDistance = maxDistance
end

function Game:examineOn()
	self.ui.examine = true

	if not cursorCell then
		cursorCell = player.pos - camera:lu()
	end
end

function Game:examineOff()
	self.ui.examine = false
	self.ui.examineMaxDistance = nil
	self.ui.examineOnEnterCallback = nil
	cursorCell = nil
end

local function keyToAction(lctrl, key)
	local bindingName = ''
	if lctrl then
		bindingName = bindingName .. 'lctrl+'
	end

	bindingName = bindingName .. key
	return bindings[bindingName]
end

local Move_Vectors = {
	Vec( 0, -1), -- up
	Vec( 0,  1), -- down
	Vec(-1,  0), -- left
	Vec( 1,  0), -- right
	Vec( 0,  0) -- rest
}

local function movementActionToVector(uiAction)
	if uiAction <= #Move_Vectors then
		return Move_Vectors[uiAction]
	end
	return nil
end

function Game:examineActionConfirm()
	if self.ui.examineOnEnterCallback then
		local cb = self.ui.examineOnEnterCallback[1]
		cb(self, cursorCell:clone(), select(2, unpack(self.ui.examineOnEnterCallback)))
	end
end

function Game:examineActionEscape()
	self:examineOff()
end

local function moveExamine(moveVec, maxDistance)
	local newCursorCell = cursorCell + moveVec
	local vis = 2 * S.game.VIS_RADIUS + 1

	--
	if newCursorCell.x >= 0 and newCursorCell.y >= 0 and newCursorCell.x < vis and newCursorCell.y < vis then
		local pos = newCursorCell + camera:lu() - player.pos

		if not maxDistance or pos:len() < maxDistance then
			cursorCell = newCursorCell
			logItems()
		end
	end
end

function Game:examineActionMovement(uiAction)
	local moveVec = movementActionToVector(uiAction)
	if moveVec then
		moveExamine(moveVec, self.ui.examineMaxDistance)
	end
end

function Game:actionConfirm()
end

function Game:actionEscape()
	-- in game menu
	gamestate.push(GameMenu:new())
end

function Game:grabItem(locationId, items, ordinalIndex)
	local _ordinalIndex = 1
	for itemId, item in pairs(items) do
		if _ordinalIndex == ordinalIndex then
			if not player.inventory:add(item) then
				console.log('Inventory is full!')
				return false
			end

			elements.del(locationId, itemId)

			console.log({
				{ 1, 1, 1, 1 }, 'Picked up ',
				color.crimson, item.desc.blueprint.name
			})

			return true
		end

		_ordinalIndex = _ordinalIndex + 1
	end

	return false
end

function Game:actionGrab()
	-- if single item on the ground and there is a space in inventory, just grab it
	-- if more items show menu

	local locationId = posToLocation(player.pos)
	local items, itemCount = elements.getItems(locationId)
	if items then
		if itemCount == 1 then
			self:grabItem(locationId, items, 1)
			updateTiles()
		else
			hud.grabInput(true)
			self.ui.showGrabMenu = true
			console.log('Game:handleGrabUpdate() more items inside the cell')
		end
	else
		console.log('There\'s nothing lying here')
	end
end

function Game:actionDrop()
	hud.grabInput(true)
	self.ui.showDropMenu = true
end

function Game:actionExamine()
	self:examineOn()
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

function Game:actionMovement(uiAction)
	local moveVec = movementActionToVector(uiAction)

	-- ignore keyboard controls if following the path
	if #(player.actions) == 0 and not player.follow_path then
		-- if move and move or attack allowed
		if moveVec and playerMoveAction(moveVec) then
			self.doActions = true
		end
	end
end

local Inventory_Types = { ["melee"] = 1, ["light"] = 2, ["heavy"] = 3 }
local Index_To_InventoryType = { "melee", "light", "heavy" }

function Game:activateEquipment(equipmentIndex)
	player.equipmentActive = equipmentIndex

	local item = player.equipment:get(Index_To_InventoryType[equipmentIndex])
	console.log({
		color.white, 'Yielding ',
		color.crimson, item.desc.blueprint.name
	})
end

function Game:actionActivate(uiAction)
	local equipmentIndex = uiAction  - GameAction.Equip1 + 1
	self:activateEquipment(equipmentIndex)
end

function Game:actionInventory(uiAction)
	local inventoryIndex = uiAction  - GameAction.Inventory1 + 1
	local item = player.inventory:get(inventoryIndex)
	if item then
		hud.grabInput(true)
		self.ui.itemActions = { item = item, inventoryIndex = inventoryIndex, visible = true }
	else
		console.log({ color.lightcoral, 'Item no.' .. (inventoryIndex + 3) .. ' not in inventory' })
	end
end

local function actionExperimentalCameraSwitch()
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

local function actionDebugToggleVismap()
	-- toggle flag
	current = batch.debug('disableVismap') or false
	batch.debug({ disableVismap = not current })
	updateTiles()
end

local function actionDebugToggleAstar()
	S.game.debug.show_astar_paths = not S.game.debug.show_astar_paths
end

local function actionNone()
end
function Game:keypressed(key)
	local hasLctrl = love.keyboard.isDown('lctrl')
	local uiAction = keyToAction(hasLctrl, key)

	if hud.captureInput() then
		hud.input(key, uiAction)
		return
	end

	-- unknown action
	if not uiAction then
		return
	end

	local actionDispatcher
	local logOnError = true

	if self.ui.examine then
		logOnError = false
		actionDispatcher = {
			[GameAction.Up] = Game.examineActionMovement
			, [GameAction.Down] = Game.examineActionMovement
			, [GameAction.Left] = Game.examineActionMovement
			, [GameAction.Right] = Game.examineActionMovement

			, [GameAction.Confirm] = Game.examineActionConfirm
			, [GameAction.Escape] = Game.examineActionEscape
			, [GameAction.Examine] = Game.examineActionEscape

			, [GameAction.Toggle_Console] = console.toggle
		}
	else
		-- general / UI
		actionDispatcher = {
			[GameAction.Up] = Game.actionMovement
			, [GameAction.Down] = Game.actionMovement
			, [GameAction.Left] = Game.actionMovement
			, [GameAction.Right] = Game.actionMovement
			, [GameAction.Rest] = Game.actionMovement
			, [GameAction.Confirm] = Game.actionConfirm
			, [GameAction.Escape] = Game.actionEscape
			, [GameAction.Grab] = Game.actionGrab
			, [GameAction.Drop] = Game.actionDrop
			, [GameAction.Examine] = Game.actionExamine

			, [GameAction.Equip1] = Game.actionActivate
			, [GameAction.Equip2] = Game.actionActivate
			, [GameAction.Equip3] = Game.actionActivate
			, [GameAction.Inventory1] = Game.actionInventory
			, [GameAction.Inventory2] = Game.actionInventory
			, [GameAction.Inventory3] = Game.actionInventory
			, [GameAction.Inventory4] = Game.actionInventory
			, [GameAction.Inventory5] = Game.actionInventory
			, [GameAction.Inventory6] = Game.actionInventory

			, [GameAction.Close_Modal] = Game.actionNone
			, [GameAction.Toggle_Console] = console.toggle

			-- TODO: XXX: TODO: devel: comment out before releasing ^^
			, [GameAction.Experimental_Camera_Switch] = actionExperimentalCameraSwitch
			, [GameAction.Debug_Toggle_Vismap] = actionDebugToggleVismap
			, [GameAction.Debug_Toggle_Astar] = actionDebugToggleAstar
		}
	end

	if actionDispatcher[uiAction] then
		actionDispatcher[uiAction](self, uiAction)
	else
		if logOnError then
			logError('no handler for action ' .. uiAction)
		end
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

local updateTilesAfterAction = false
-- returns true when there was any move
-- will require some recalculations later
local function executeActions(attribute, expectedAction, cb)
	local ret = false
	for _,e in pairs(entities.with(attribute)) do
		if e.actionState == expectedAction then
			cb(e)
			e.actionState = action.Action.Idle

			-- fire up ai to queue next action item
			e:analyze(player)

			if camera:isFollowing(e) then
				updateTilesAfterAction = true
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

function Game:throw(desc)
	console.log('throwing onto '.. tostring(desc.destPos) .. ' item ' .. desc.itemIndex)
	local locationId =  posToLocation(desc.destPos + camera:lu())
	local elem = elements.create(locationId)
	--elem:set
	elem:setTileId(nil)
	elem:setPassable(true)
	elem:setItem({
		uid = 12345,
		blueprint = { symbol = '!', name = 'GOO', type = 'gas'
			, flags = { }, color = { color.hsvToRgb(0.08, 0.58, 0.0, 1.0) } }
	})
	elem:setOpaque(true)

	print(' created object at location ' .. locationId .. ' ' .. utils.repr(elem))
end

local initializeAi = true
local shaderDt = 0
local shaderTotalDt = 0
function Game:updateGameLogic(dt)
	shaderDt = shaderDt + dt
	shaderTotalDt = shaderTotalDt + dt
	if shaderDt > 1 / 60.0 then
		self.shader:send("offsetx", math.sin(shaderTotalDt / 10.0) / 5.0)
		self.shader:send("offsety", shaderTotalDt / 40.0)
		shaderDt = shaderDt - 1 / 60.0
	end


	-- at this point map should be ready, fire up AI once,
	-- afterwards it should be fired after finishing actions
	if initializeAi then
		processAi()
		initializeAi = false
	end

	-- 'execute' planned path
	if #(player.actions) == 0 then
		self.doActions = pathPlayerMovement()
	end

	-- not yet sure if it should be here
	messages.update(dt, camera:lu(), Tile_Size_Adj)

	if self.doActions then
		self.doActions = entities.processActions(player)
		local movementDone = executeActions(entities.Attr.Has_Move, action.Action.Move, function(e) e:move() end)
		executeActions(entities.Attr.Has_Attack, action.Action.Attack, function(e) e:attack() end)
		executeActions(entities.Attr.Has_Attack, action.Action.Throw, function(e)
			local desc = e:throw()
			self:throw(desc)
		end)

		elements.process()

		-- if movementDone then
		-- 	elements.refresh()
		-- end

		if updateTilesAfterAction then
			camera:update()

			-- not needed here anymore
			--processAi()

			-- TODO: probably wrong location
			processEntitiesFov()

			updateTiles()
			updateTilesAfterAction = false
		end
	end
end

local tempDropAnimate
function Game:doUpdate(dt)
	hud.update(dt)
	if self.ui.showDropMenu then
		tempDropAnimate = tempDropAnimate + dt
	end

	if not hud.captureInput()  then
		self:updateGameLogic(dt)
		tempDropAnimate = 0
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

local function drawItems(ent, camLu)
	local scaleFactor = Tile_Size / Entity_Tile_Size
	local ya = camLu.y
	local xa = camLu.x

	local tc = 2 * S.game.VIS_RADIUS + 1
	for y = 0, tc - 1 do
		if ya + y > map.height() then
			break
		end

		local locationId = (ya + y) * map.width() + xa
		for x = 0, tc - 1 do
			local items, itemCount = elements.getItems(locationId)
			if itemCount > 0 then
				local vismap = ent.vismap
				if debug.disableVismap or (vismap[locationId] and vismap[locationId] > 0) then
					local firstItemIndex = getFirstItemIndex(items)
					local c = items[firstItemIndex].desc.blueprint.color
					love.graphics.setColor(c[1], c[2], c[3], c[4])

					local itemImg = Letters[items[firstItemIndex].desc.blueprint.symbol]
					love.graphics.draw(itemImg, x * Tile_Size_Adj, y * Tile_Size_Adj, 0, scaleFactor, scaleFactor)
				end
			end
			locationId = locationId + 1
		end
	end

	-- description
	if not cursorCell then
		return
	end

	for y = 0, tc - 1 do
		if ya + y > map.height() then
			break
		end

		local locationId = (ya + y) * map.width() + xa
		for x = 0, tc - 1 do
			local items, itemCount = elements.getItems(locationId)
			if itemCount > 0 then
				local vismap = ent.vismap
				if debug.disableVismap or (vismap[locationId] and vismap[locationId] > 0) then
					if cursorCell and Vec(x, y) == cursorCell then
						love.graphics.setColor(0.9, 0.9, 0.9, 0.6)
						love.graphics.rectangle('fill', (cursorCell.x + 1) * Tile_Size_Adj, cursorCell.y * Tile_Size_Adj, 2.5 * Tile_Size + 1, 32)
						love.graphics.setColor(0.0, 0.0, 0.0, 1.0)
						local firstItemIndex = getFirstItemIndex(items)
						love.graphics.printf(
							items[firstItemIndex].desc.blueprint.name,
							(cursorCell.x + 1) * Tile_Size_Adj, cursorCell.y * Tile_Size_Adj, 2.5 * Tile_Size + 1)
					end
				end
			end
			locationId = locationId + 1
		end
	end
end

local function drawWeaponDistanceOverlay(maxDistance)
	if not maxDistance then
		return
	end

	local lu = camera:lu()
	local ya = lu.y
	local xa = lu.x
	local tc = 2 * S.game.VIS_RADIUS + 1

	love.graphics.setColor(1.0, 0.0, 0.0, 0.5)
	for y = 0, tc - 1 do
		if ya + y > map.height() then
			break
		end
		local circ = (player.pos - lu) - Vec(0, y)
		for x = 0, tc - 1 do
			if circ:len() < maxDistance then
				love.graphics.rectangle('fill', x * Tile_Size_Adj, y * Tile_Size_Adj, Tile_Size, Tile_Size)
			end
			circ.x = circ.x - 1
		end
	end
end

local function drawGas()
	love.graphics.setColor(color.lime)
	love.graphics.rectangle('fill', 10 * Tile_Size_Adj, 10 * Tile_Size_Adj, Tile_Size, Tile_Size)
end

local function drawEntityPath(ent, camLu)
	if ent ~= player and S.game.debug and not S.game.debug.show_astar_paths then
		return
	end

	if not ent.astar_path then
		return
	end

	for i, node in pairs(ent.astar_path) do
		local relPos = node - camLu
		if camera.followedEnt == ent then
			love.graphics.setColor(0.1, 0.1, 0.1, 0.5)
			love.graphics.rectangle('fill', relPos.x * Tile_Size_Adj, relPos.y * Tile_Size_Adj, Tile_Size + 1, Tile_Size + 1)
			love.graphics.setColor(0.9, 0.9, 0.9, 1.0)
			love.graphics.print(tostring(i), relPos.x * Tile_Size_Adj + 10, relPos.y * Tile_Size_Adj + 10)
		else
			love.graphics.setColor(0.9, 0.7, 0.7, 0.5)
			love.graphics.rectangle('fill', relPos.x * Tile_Size_Adj, relPos.y * Tile_Size_Adj, Tile_Size + 1, Tile_Size + 1)
			love.graphics.setColor(0.3, 0.1, 0.1, 1.0)
			love.graphics.print(tostring(i), relPos.x * Tile_Size_Adj, relPos.y * Tile_Size_Adj)
		end
	end
end

local function drawEntities(camLu)
	local scaleFactor = Tile_Size / Entity_Tile_Size

	local hoveredUiEntId = hud.hoveredEntId()
	for _,ent in pairs(entities.all()) do
		local relPos = ent.pos - camLu

		if hoveredUiEntId == ent.id then
			love.graphics.setColor(0.5, 0.9, 0.5, 0.5)
			love.graphics.rectangle('fill', relPos.x * Tile_Size_Adj, relPos.y * Tile_Size_Adj, Tile_Size_Adj, Tile_Size_Adj)
		end

		if ent == player then
			love.graphics.setColor(0.9, 0.9, 0.9, 1.0)
		else
			love.graphics.setColor(0.7, 0.1, 0.1, 1.0)
		end

		-- drawEntity
		if camera.followedEnt == ent or camera.followedEnt.seemap[ent] then
			love.graphics.draw(ent.img, relPos.x * Tile_Size_Adj, relPos.y * Tile_Size_Adj, 0, scaleFactor, scaleFactor)

			-- show entity name on hover -- TODO: remove
			if cursorCell and relPos == cursorCell then
				love.graphics.setColor(0.9, 0.9, 0.9, 0.8)
				love.graphics.rectangle('fill', (cursorCell.x + 1) * Tile_Size_Adj, cursorCell.y * Tile_Size_Adj, 2.5 * Tile_Size + 1, 16)
				love.graphics.setColor(0.0, 0.0, 0.0, 1.0)
				love.graphics.print(ent.name, (cursorCell.x + 1) * Tile_Size_Adj, cursorCell.y * Tile_Size_Adj)
			end

			-- if ent.astar_visited then
			-- 	for k, v in pairs(ent.astar_visited) do
			-- 		local sx = v.x - camLuX
			-- 		local sy = v.y - camLuY

			-- 		love.graphics.setColor(0.9, 0.9, 0.9, 0.3)
			-- 		love.graphics.rectangle('fill', sx * ts, sy * ts, Tile_Size + 1, Tile_Size + 1)
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

local function isMouseOverEntity(ent, camLu)
	local relPos = ent.pos - camLu
	if cursorCell and relPos == cursorCell then
		return true
	end
	return false
end

local function findKey(uiAction)
	for name, action in pairs(bindings) do
		if uiAction == action then
			return name
		end
	end

	return nil
end

-- helper
function Game:dropItem(item)
	-- remove from inventory
	player.inventory:del(item)

	-- add to elements
	local idx = posToLocation(player.pos)
	local gobj = elements.create(idx)
	gobj:setTileId(nil)
	gobj:setPassable(true)
	gobj:setItem(item.desc)

	console.log({
		{ 1, 1, 1, 1 }, 'Dropped ',
		color.crimson, item.desc.blueprint.name
	})
end

function Game:itemActionClose()
	hud.grabInput(false)
	self.ui.itemActions = nil
end

function Game:itemActionDrop(item)
	self:dropItem(item)
	self:itemActionClose()
end

function Game:itemActionSwapEquipment(item, itemIndex)
	if not Inventory_Types[item.desc.blueprint.type] then
		return
	end

	local itemType = item.desc.blueprint.type
	if player.equipment:get(itemType).desc then
		-- swap
		player.inventory:set(itemIndex, player.equipment:get(itemType))
		player.equipment:add(item)
	else
		-- move
		player.inventory:del(item)
		player.equipment:add(item)
	end

	console.log({
		{ 1, 1, 1, 1 }, 'Moved ',
		color.crimson, item.desc.blueprint.name,
		{ 1, 1, 1, 1 }, ' into equipment'
	})

	if 0 == player.equipmentActive then
		self:activateEquipment(Inventory_Types[item.desc.blueprint.type])
	end

	self:itemActionClose()
end

local function playerThrowOnEnter(gameSelf, destPos, itemIndex)
	action.queue(player.actions, Player.Throw_Speed, action.Action.Throw, { destPos = destPos, itemIndex = itemIndex })

	gameSelf.doActions = true
	gameSelf:examineOff()
end

function Game:itemActionThrow(item, itemIndex)
	console.log('Select target')
	self:itemActionClose()

	self:examineOnEnter({ playerThrowOnEnter, itemIndex })
	self:examineMaxDistance(5)
	self:examineOn()
end

function Game:dropActionClose()
	hud.grabInput(false)
	self.ui.showDropMenu = nil
end

function Game:dropActionNum(uiAction)
	if uiAction >= GameAction.Equip1 and uiAction <= GameAction.Equip3 then
		-- TODO:
		console.log('handle equipment drop')
	end

	if uiAction >= GameAction.Inventory1 and uiAction <= GameAction.Inventory6 then
		local inventoryIndex = uiAction  - GameAction.Inventory1 + 1
		local item = player.inventory:get(inventoryIndex)
		if item then
			self:dropItem(item)
			if player.inventory:empty() then
				self:dropActionClose()
			end
		end
	end
end

function Game:grabActionClose()
	hud.grabInput(false)
	self.ui.showGrabMenu = nil
end

function Game:grabActionGrab(locationId, items, ordinalIndex)
	return self:grabItem(locationId, items, ordinalIndex)
end

local function calculateCenteredWindowPosition(width, height)
	local Board_Size = (2 * S.game.VIS_RADIUS + 1) * Tile_Size_Adj
	local posX = math.floor((Board_Size - width) / 2)
	-- '- 100' cause it feels bit nicer
	local posY = math.floor((Board_Size - height) / 2) - 100

	return posX, posY
end

local function menuWindowHeight(numItems)
	return (numItems + 1) * hud.lineHeight() + 8 + 3
end

local function interpolate(val1, val2, delta, maxDelta)
	local u = math.min(delta, maxDelta) / maxDelta
	local diff = val2 - val1
	return val1 + u * diff
end

local function createEquipmentEntry(gameAction, name, active)
	local item = player.equipment:get(name)
	if item.desc then
		return { key = findKey(gameAction),  item = item.desc.blueprint.name, active = active }
	else
		return { key = findKey(gameAction),  item = '(' .. name .. ')', disabled = true }
	end
end

-- this is some serious mess, don't look
function Game:drawInterface()
	local Board_Size = (2 * S.game.VIS_RADIUS + 1) * Tile_Size_Adj
	local startX = (31 * 25) + 10 + minimapImg:getWidth() + 10
	local camLu = camera:lu()

	-- dim map
	if self.ui.itemActions or self.ui.showDropMenu then
		love.graphics.setColor(0.25, 0.25, 0.25, 0.7)
		graphics.rectangle('fill', 0, 0, Board_Size, Board_Size)
	end

	love.graphics.setColor(color.white)
	hud.begin('Entities', startX, 10)
	local h = hud.drawPlayerInfo(player, 260, function(ent)
		return isMouseOverEntity(ent, camLu)
	end)

	hud.drawVisible(player.seemap, 260, 260, function(ent)
		return isMouseOverEntity(ent, camLu)
	end)
	hud.finish(266)

	local equipmentPosX = startX
	local equipmentPosY = 260 + 20 + h + 50
	local equipmentPadding = 0

	if self.ui.showDropMenu then
		local Size_X = 280
		local headerHeight = hud.lineHeight() + 10
		local additionalOptions = hud.lineHeight() + 8
		local parentHeight = headerHeight + additionalOptions + 3
		local Size_Y = menuWindowHeight(3) + menuWindowHeight(6) + 20 + parentHeight
		local centerX, centerY = calculateCenteredWindowPosition(Size_X, Size_Y)

		equipmentPosX = interpolate(startX, centerX, tempDropAnimate, 0.3)
		equipmentPosY = interpolate(260 + 20 + h + 50, centerY, tempDropAnimate, 0.3)
		equipmentPadding = 3

		love.graphics.setColor(color.indigo)
		love.graphics.rectangle('fill', equipmentPosX - 1, equipmentPosY - 1, Size_X + 2, Size_Y + 2)

		love.graphics.setColor(color.white)
		hud.begin('Drop item, select: ', equipmentPosX, equipmentPosY)

		equipmentPosX = equipmentPosX + 10
		equipmentPosY = equipmentPosY + headerHeight
	end

	love.graphics.setColor(color.white)
	hud.begin('Equipment', equipmentPosX, equipmentPosY)
	local active = player.equipmentActive
	local menu = {
		createEquipmentEntry(GameAction.Equip1, 'melee', 1 == active),
		createEquipmentEntry(GameAction.Equip2, 'light', 2 == active),
		createEquipmentEntry(GameAction.Equip3, 'heavy', 3 == active)
	}
	hud.drawMenu(260, menu)
	hud.finish(260)

	love.graphics.setColor(color.white)
	hud.begin('Inventory', equipmentPosX, equipmentPosY + menuWindowHeight(3) + 20)
	menu = {}
	for i = 1, 6 do
		local item = player.inventory:get(i)
		if item then
			local itemLine = item.desc.blueprint.name
			if item.desc.blueprint.type then
				itemLine = itemLine .. ' ' .. item.desc.blueprint.type
			end

			table.insert(menu, { key = findKey(GameAction.Inventory1 + i - 1), item =  itemLine })
		else
			table.insert(menu, { key = findKey(GameAction.Inventory1 + i - 1), item = '' })
		end
	end
	hud.drawMenu(260, menu)
	hud.finish(260, equipmentPadding)

	if self.ui.showDropMenu then
		local menu = {
			{ key = findKey(GameAction.Close_Modal), item = 'close window' }
		}
		hud.drawMenu(260, menu)

		hud.finish(280)

		local itemDispatcher = {
			[GameAction.Close_Modal] = Game.dropActionClose
			, [GameAction.Escape] = Game.dropActionClose

			, [GameAction.Equip1] = Game.dropActionNum
			, [GameAction.Equip2] = Game.dropActionNum
			, [GameAction.Equip3] = Game.dropActionNum
			, [GameAction.Inventory1] = Game.dropActionNum
			, [GameAction.Inventory2] = Game.dropActionNum
			, [GameAction.Inventory3] = Game.dropActionNum
			, [GameAction.Inventory4] = Game.dropActionNum
			, [GameAction.Inventory5] = Game.dropActionNum
			, [GameAction.Inventory6] = Game.dropActionNum
		}

		local action = hud.getAction()
		if action and itemDispatcher[action] then
			itemDispatcher[action](self, action)
		end
	end

	-- show item actions
	if self.ui.itemActions then
		local item = self.ui.itemActions.item
		menu = {}
		table.insert(menu, { key = findKey(GameAction.Drop), item = 'drop' })
		local throwable = item.desc.blueprint.flags and item.desc.blueprint.flags.throwable
		table.insert(menu, { key = findKey(GameAction.Throw), item = 'throw', disabled = not throwable })

		local replacable = Inventory_Types[item.desc.blueprint.type]
		local className = item.desc.blueprint.type and (item.desc.blueprint.type .. ' class ') or ''
		table.insert(menu, {
				key = findKey(GameAction.Equip_or_Swap),
				item = 'replace ' .. className .. 'in equipement',
				disabled = not replacable
		})
		-- TODO: display item name
		table.insert(menu, { key = findKey(GameAction.Swap_Ground), item = 'swap with item(XXX) on the ground' })
		-- 	imgui.Text('eat/drink/consume')
		-- 	imgui.Text('use')
		table.insert(menu, { separator = '' })
		table.insert(menu, { key = findKey(GameAction.Close_Modal), item = 'close window' })

		local Size_X = 400
		local Size_Y = menuWindowHeight(#menu)
		local centerX, centerY = calculateCenteredWindowPosition(Size_X, Size_Y)

		love.graphics.setColor(color.indigo)
		love.graphics.rectangle('fill', centerX - 1, centerY - 1, Size_X + 2, Size_Y + 2)

		love.graphics.setColor(color.white)
		hud.begin(item.desc.blueprint.name, centerX, centerY)
		hud.drawMenu(Size_X, menu)
		hud.finish(Size_X)

		local itemDispatcher = {
			[GameAction.Close_Modal] = Game.itemActionClose
			, [GameAction.Escape] = Game.itemActionClose
			, [GameAction.Drop] = Game.itemActionDrop
			, [GameAction.Equip_or_Swap] = Game.itemActionSwapEquipment
			, [GameAction.Throw] = Game.itemActionThrow
		}

		local action = hud.getAction()
		if action and itemDispatcher[action] then
			itemDispatcher[action](self, item, self.ui.itemActions.inventoryIndex)
		end
	end

	if self.ui.showGrabMenu then
		local locationId = posToLocation(player.pos)
		local items, itemCount = elements.getItems(locationId)

		menu = {}
		local ordinalIndex = 1
		for k, item in pairs(items) do
			if k < 10 then
				table.insert(menu, { key = tostring(ordinalIndex), item = item.desc.blueprint.name })
			else
				table.insert(menu, { key = nil, item = item.desc.blueprint.name })
			end

			ordinalIndex = ordinalIndex + 1
		end
		table.insert(menu, { separator = '' })
		table.insert(menu, { key = 'a', item = 'Grab ALL' })
		table.insert(menu, { key = findKey(GameAction.Close_Modal), item = 'close window' })

		local Size_X = 400
		local Size_Y = menuWindowHeight(#menu)
		local centerX, centerY = calculateCenteredWindowPosition(Size_X, Size_Y)

		love.graphics.setColor(color.indigo)
		love.graphics.rectangle('fill', centerX - 1, centerY - 1, Size_X + 2, Size_Y + 2)

		love.graphics.setColor(color.white)
		hud.begin('Grab item(s): ', centerX, centerY)
		hud.drawMenu(Size_X, menu)
		hud.finish(Size_X)

		local itemDispatcher = {
			[GameAction.Close_Modal] = Game.itemActionClose
			, [GameAction.Escape] = Game.itemActionClose
			, [GameAction.Drop] = Game.itemActionDrop
		}

		local action = hud.getAction()
		local key = hud.getKey()
		if GameAction.Escape == action or GameAction.Close_Modal == action then
			self:grabActionClose()
		end

		if key and key >= '1' and key <= '9' then
			local index = tonumber(key)
			print(tostring(action) .. ' ' .. tostring(key) .. ' ' .. tostring(index))
			self:grabActionGrab(locationId, items, index)
		end
		if key == 'a' then
			while self:grabActionGrab(locationId, items, 1) do
				items, itemCount = elements.getItems(locationId)
				if 0 == itemCount then
					break
				end
			end

			self:grabActionClose()
		end
	end
end

function Game:show()
	-- TODO: debug info
	local camLu = camera:lu()
	love.graphics.print("radius: "..S.game.VIS_RADIUS, S.resolution.x - 200 - 10, 30)
	love.graphics.print("player: " .. player.pos.x .. "," .. player.pos.y, S.resolution.x - 200 - 10, 50)
	love.graphics.print("camera: " .. cameraIdx, S.resolution.x - 200 - 10, 70)
	if cursorCell then
		local mapCoords = camLu + cursorCell
		love.graphics.print("mouse: " .. tostring(mapCoords), S.resolution.x - 200 - 10, 90)
	end

	local uiElements = '{ '
	for key, value in pairs(self.ui) do
		if value then
			uiElements = uiElements .. key .. ', '
		end
	end
	uiElements = uiElements .. '}'

	love.graphics.print("self.ui: " .. uiElements, S.resolution.x - 200 - 10, 110)

	-- draw map

	batch.draw()

	drawItems(camera.followedEnt, camLu)

	-- ^^
	drawEntities(camLu)

		-- begin part 1
		local s = love.graphics.getShader()
		local co = {love.graphics.getColor()}

		local old_canvas = love.graphics.getCanvas()
		love.graphics.setCanvas(self.canvas)
		love.graphics.clear()
		-- end part 1

		drawGas()

		-- begin part 2
		love.graphics.setCanvas(old_canvas)

		-- apply shader to canvas
		love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
		love.graphics.setShader(self.shader)
		local b = love.graphics.getBlendMode()
		love.graphics.setBlendMode('alpha', 'premultiplied')
		love.graphics.draw(self.canvas, 0, 0)
		love.graphics.setBlendMode(b)
		love.graphics.setShader(s)
		-- end part 2

	drawWeaponDistanceOverlay(self.ui.examineMaxDistance)

	if cursorCell then
		love.graphics.setColor(0.5, 0.9, 0.5, 0.9)
		love.graphics.rectangle('line', cursorCell.x * Tile_Size_Adj, cursorCell.y * Tile_Size_Adj, Tile_Size + 1, Tile_Size + 1)
	end

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(messages.popups.getCanvas())
	drawMinimap()
	self:drawInterface()
	console.draw(0, 900 - console.height())
end

function Game:draw()
	if self.updateLevel then
		local level = self.levels[self.depthLevel]
		level:show()
	else
		self:show()
	end
end

return Game