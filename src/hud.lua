-- imported modules
local color = require 'engine.color'
local console = require 'engine.console'
local fontManager = require 'engine.fontManager'

-- module
local hud = {}

local hud_lineHeight = 22
local hud_font = fontManager.get('fonts/scp.otf', 16, 'light')

local Box_Height = 66

local currentX
local currentY

local startX
local startY
function hud.begin(name, x, y)
	love.graphics.setFont(hud_font)
	startX = x
	startY = y
	currentX = startX + 3
	currentY = startY + 3
	love.graphics.print(name, startX, startY)

	currentY = startY + hud_lineHeight
end

function hud.finish(width)
	love.graphics.setColor(color.slategray)
	love.graphics.rectangle('line', startX, startY, width, currentY)
end

local hoveredUiEntId = nil

function hud.hoveredEntId()
	return hoveredUiEntId
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
	love.graphics.rectangle('fill', locX, locY, hpWidth, 14)

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
	if isMouseHovered(ent) or hoveredUiEntId == ent.id then
		colorScheme = hovered
	end

	love.graphics.setColor(colorScheme.border)
	love.graphics.rectangle('line', currentX, currentY, width, Box_Height)

	currentX = currentX + 3
	local savedY = currentY
	hud_drawEnt(ent, width - 6, colorScheme, isMouseHovered(ent))
	currentX = currentX - 3
	currentY = savedY + Box_Height + 4

	return Box_Height
end

local entsCanvas = nil
local entsQuad = nil
local lastSelected = -1

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

	-- calculate size
	local cnt = 0
	local selected = 0
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
	if selected ~= lastSelected then
		local offsetY = selected * entryHeight -- math.max(0, math.min(selected * entryHeight, entsCanvas:getHeight() - height))
		entsQuad = love.graphics.newQuad(0, offsetY, width, height, entsCanvas:getWidth(), entsCanvas:getHeight())
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
		love.graphics.rectangle('fill', tempX + scrollbarAwareWidth + 4, tempY, 10, height, 5, 5)

		love.graphics.setColor(color.gray)
		local offsetY = math.floor((height - 20) * (selected / (cnt - 6)))
		love.graphics.rectangle('fill', tempX + scrollbarAwareWidth + 4, tempY + offsetY, 10, 20, 5, 5)
	end

	currentX = tempX + currentX
	currentY = tempY + height
end

return hud
