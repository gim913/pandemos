-- imported modules
local color = require 'engine.color'
local console = require 'engine.console'
local fontManager = require 'engine.fontManager'
local graphics = require 'engine.graphics'

-- module
local hud = {}

local hud_lineHeight = 22
local hud_font = fontManager.get('fonts/scp.otf', 16, 'light')

local Box_Height = 66

local hud_regions

-- external events
local hoveredUiEntId = nil

-- returns true if takes over updates
local hud_grabInput = false
function hud.grabInput(value)
	hud_grabInput = value
end

function hud.captureInput()
	return hud_grabInput
end

function hud.update(dt)
	hud_regions = {}

	return hud_grabInput
end

local lastKeyPressed = nil
local lastAction = nil
function hud.input(key, action)
	lastKeyPressed = key
	lastAction = action
end

function hud.getAction()
	local temp = lastAction
	lastAction = nil
	return temp
end

local lastMouseX = -1
local lastMouseY = -1
local lastMousePressedX = -1
local lastMousePressedY = -1

function hud.mousemoved(mouseX, mouseY)
	lastMouseX = mouseX
	lastMouseY = mouseY
	return false
end

function hud.mousepressed(mouseX, mouseY, button)
	lastMousePressedX = mouseX
	lastMousePressedY = mouseY
	return false
end

function hud.mousereleased(mouseX, mouseY, button)
	lastMousePressedX = -1
	lastMousePressedY = -1
	return false
end

local scrollCollectedWheelY = 0
function hud.wheelmoved(deltaX, deltaY)
	scrollCollectedWheelY = scrollCollectedWheelY + deltaY
	-- ugly, but ok for now
	if lastMouseX > 31 * 25 then
		return true
	end
	return false
end

local function is_between(val, lower, upper)
	return val >= lower and val < upper
end

local function hud_hovered(x, y, width, height)
	return is_between(lastMouseX, x, x + width) and is_between(lastMouseY, y, y + height)
end

local function hud_pressed(x, y, width, height)
	return is_between(lastMousePressedX, x, x + width) and is_between(lastMousePressedY, y, y + height)
end

--

local currentX
local currentY

local startX = {}
local startY = {}
function hud.begin(name, x, y)
	love.graphics.setFont(hud_font)
	table.insert(startX, x)
	table.insert(startY, y)
	currentX = x + 3
	currentY = y + 3
	love.graphics.print(name, currentX, currentY)

	currentY = currentY + hud_lineHeight
end

function hud.finish(width, padding)
	love.graphics.setColor(color.slategray)
	local luX = table.remove(startX)
	local luY = table.remove(startY)
	graphics.rectangle('line', luX, luY, width, currentY - luY)
	currentX = luX

	if padding then
		currentY = currentY + padding
	end
end

function hud.hoveredEntId()
	return hoveredUiEntId
end

function hud.lineHeight()
	return hud_lineHeight
end

local function hud_drawEnt(ent, width, colorScheme, displayHovered)
	local locX = currentX
	local locY = currentY
	local maxW = width - 1
	love.graphics.setColor(colorScheme.text)
	love.graphics.print(ent.name, locX, locY)
	love.graphics.print(tostring(ent.id), locX + maxW - 30, locY)

	locY = locY + hud_lineHeight

	-- goes from blu-ish to red
	local hpHue = 1.0 - 10 * ent.hp / ent.maxHp / 24.0
	local hpWidth = math.ceil((maxW * ent.hp) / ent.maxHp)
	local r,g,b,a = color.hsvToRgb(hpHue, unpack(colorScheme.hp))

	love.graphics.setColor(r, g, b, a)
	graphics.rectangle('fill', locX, locY, hpWidth, 14)

	currentY = locY + 18

	-- -- this will work with a delay, but it shouldn't matter much
	-- if imgui.IsItemHovered() then
	-- 	hoveredUiEntId = ent.id
	-- elseif hoveredUiEntId == ent.id then
	-- 	hoveredUiEntId = nil
	-- end
end

function hud.drawPlayerInfo(ent, width, isMouseHovered)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setLineWidth(1)
	love.graphics.setLineStyle('rough')

	local normal = {
		text = color.white
		, border = color.ivory
		, hp = { 0.7, 0.7, 1.0 }
	}
	local hovered = {
		text = { 0.4, 0.85, 0.4 }
		, border = { 0.4, 0.85, 0.4 }
		, hp = { 0.3, 0.7, 1.0 }
	}
	local colorScheme = normal

	if hud_hovered(currentX, currentY, width, Box_Height) then
		hoveredUiEntId = ent.id
	else
		-- hack: player is drawn first, so we can set null here and later only check if any other entity is hovered
		hoveredUiEntId = nil
	end

	if isMouseHovered(ent) or hoveredUiEntId == ent.id then
		colorScheme = hovered
	end

	love.graphics.setColor(colorScheme.border)
	graphics.rectangle('line', currentX, currentY, width, Box_Height)

	currentX = currentX + 3
	local savedY = currentY
	hud_drawEnt(ent, width - 6, colorScheme, isMouseHovered(ent))
	currentX = currentX - 3
	currentY = savedY + Box_Height + 4

	return Box_Height
end

local entsCanvas = nil
local entsQuad = nil
local lastSelected = -2

local originalScrollPos = 0
local scrollPos = 0

local function clamp(val, lower, upper)
	return math.max(lower, math.min(val, upper))
end

-- dragons ahead :P
function hud.drawVisible(ents, width, height, isMouseHovered)
	local normal = {
		text = color.lightgray
		, border = color.slategray
		, hp = { 0.7, 0.7, 1.0 }
	}
	local hovered = {
		text = { 0.4, 0.85, 0.4 }
		, border = { 0.4, 0.85, 0.4 }
		, hp = { 0.3, 0.7, 1.0 }
	}

	local Scroll_Padding = 3
	height = height - Scroll_Padding

	-- calculate size
	local cnt = 0
	local selected = -1
	for ent, _ in pairs(ents) do
		if isMouseHovered(ent) or hoveredUiEntId == ent.id then
			selected = cnt
		end
		cnt = cnt + 1
	end

	local entryHeight = (hud_lineHeight + 18 + 4)
	local newHeight = entryHeight * cnt + 10

	-- create canvas if needed
	if not entsCanvas or newHeight > entsCanvas:getHeight() then
		entsCanvas = love.graphics.newCanvas(width, newHeight)
	end

	local quadOffsetY
	if selected ~= lastSelected then
		local ffsetY

		-- calculate quad of canvas that we will show
		-- 1. if entity selected on the map, calculate proper offset, and calculate scroll button position
		-- 2. otherwise just use scroll button position
		if selected ~= -1 then
			quadOffsetY = clamp(selected * entryHeight, 0, entsCanvas:getHeight() - height)
			scrollPos = math.floor((height - 20) * quadOffsetY / (entsCanvas:getHeight() - height))
		else
			quadOffsetY = math.floor((newHeight - height) * scrollPos / (height - 20))
		end
		entsQuad = love.graphics.newQuad(0, quadOffsetY, width, height, entsCanvas:getWidth(), entsCanvas:getHeight())
	end

	local scrollbarAwareWidth = width
	if newHeight > height then
		scrollbarAwareWidth = width - 20
	end

	love.graphics.setCanvas(entsCanvas)
	love.graphics.clear(0, 0, 0, 0)

	local tempX, tempY = currentX, currentY
	currentX = 0
	currentY = 0
	for ent,_ in pairs(ents) do
		local colorScheme = normal

		if hud_hovered(tempX, tempY + currentY - quadOffsetY, scrollbarAwareWidth, hud_lineHeight + 18 + 4) then
			hoveredUiEntId = ent.id
		end

		if isMouseHovered(ent) or hoveredUiEntId == ent.id then
			colorScheme = hovered
		end

		hud_drawEnt(ent, scrollbarAwareWidth, colorScheme, isMouseHovered(ent))

		love.graphics.setColor(colorScheme.border)
		love.graphics.line(currentX, currentY, currentX + scrollbarAwareWidth, currentY)
		currentY = currentY + 4
	end
	love.graphics.setCanvas()

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setBlendMode('alpha', 'premultiplied')
	love.graphics.draw(entsCanvas, entsQuad, tempX, tempY)
	love.graphics.setBlendMode('alpha')

	if newHeight > height then
		love.graphics.setColor(color.dimgray)
		graphics.rectangle('fill', tempX + scrollbarAwareWidth + 4, tempY, 10, height, 5, 5)

		-- if mouse button pressed in scrollbar button
		--  => calculate mouse movement and alter
		if lastMousePressedY ~= -1 then
			if hud_pressed(tempX + scrollbarAwareWidth + 4, tempY + originalScrollPos, 10, 20) then
				scrollPos = originalScrollPos + (lastMouseY - lastMousePressedY)
				scrollPos = clamp(scrollPos, 0, height - 20)
			end
		else
			originalScrollPos = scrollPos
		end

		if hud_hovered(tempX, tempY, width, height + Scroll_Padding) then
			scrollPos = scrollPos - 4 * scrollCollectedWheelY
			scrollPos = clamp(scrollPos, 0, height - 20)
			scrollCollectedWheelY = 0
		else
			scrollCollectedWheelY = 0
		end

		-- scroll button
		if hud_hovered(tempX + scrollbarAwareWidth + 4, tempY + scrollPos, 10, 20) then
			love.graphics.setColor(color.lightgray)
		else
			love.graphics.setColor(color.gray)
		end
		graphics.rectangle('fill', tempX + scrollbarAwareWidth + 4, tempY + scrollPos, 10, 20, 5, 5)
	end

	currentX = tempX + currentX
	currentY = tempY + height + Scroll_Padding

	love.graphics.setColor(color.white)
end

local function dashedLine(width)
	for i = 0, width - 1, 10 do
		love.graphics.line(currentX + i, currentY, currentX + i + 5, currentY)
	end
end

function hud.drawMenu(width, items)
	currentY = currentY + 4
	love.graphics.setColor(color.slategray)
	dashedLine(width)
	currentY = currentY + 4

	local normal = {
		bind = color.ivory
		, text = color.lightgray
	}
	local hovered = {
		bind = color.black
		, text = color.black
	}
	local colorScheme

	for _,item in pairs(items) do
		if hud_hovered(currentX, currentY, width, hud_lineHeight) then
			love.graphics.setColor(color.ivory)
			graphics.rectangle('fill', currentX + 2, currentY, width - 4 - 6, hud_lineHeight - 2)
			colorScheme = hovered
		else
			colorScheme = normal
		end

		if item.key then
			love.graphics.setColor(colorScheme.bind)
			love.graphics.print(item.key .. ')', currentX + 6, currentY)
			love.graphics.setColor(colorScheme.text)
			love.graphics.print(item.item, currentX + math.max(30, 16 * #item.key), currentY)

			currentY = currentY + hud_lineHeight
		else
			local halfHeight = math.floor(hud_lineHeight / 2)
			currentX = currentX + 10
			currentY = currentY + halfHeight
			dashedLine(width - 20)
			currentX = currentX - 10
			currentY = currentY + (hud_lineHeight - halfHeight)
		end
	end
end

return hud
