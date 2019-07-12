-- imported modules
local S = require 'settings'

-- module
local console = {
	buffer = {}
}

local console_canvas = love.graphics.newCanvas(S.resolution.x, S.resolution.y)
--local console_font = love.graphics.newFont('fonts/arimo.ttf', 16, 'light')
--local console_font = love.graphics.newFont('fonts/inconsolata.otf', 18, 'light')
local console_fontSize = 16
local console_lineHeight = 18
local console_font = love.graphics.newFont('fonts/scp.otf', console_fontSize, 'normal')
local console_transform = love.math.newTransform()

local console_needRefresh = true
local console_prevData = {}
local console_quad

function console.changeFontSize(deltaY)
	local newSize = math.max(12, math.min(48, console_fontSize + deltaY))
	if newSize ~= console_fontSize then
		console_fontSize = newSize
		console_lineHeight = newSize + 2
		console_font = love.graphics.newFont('fonts/scp.otf', console_fontSize, 'normal')
		console_needRefresh = true
	end
end

function console.log(a)
	if 100 == #console.buffer then
		table.remove(console.buffer, 1)
	end
	table.insert(console.buffer, a)
	console_needRefresh = true
end

local function console_refresh(coords)
	console_transform:reset()

	love.graphics.setCanvas(console_canvas)

	love.graphics.clear(0.1, 0.1, 0.1, 0.9)
	love.graphics.setFont(console_font)
	love.graphics.setColor(1.0, 1.0, 1.0, 1.0)

	local roundedPosY  = math.ceil(coords.y / console_lineHeight) * console_lineHeight
	console_transform:translate(coords.x, roundedPosY)

	local start = 1
	local spaceSkipped = roundedPosY - math.floor(coords.y)
	local spaceLeft = coords.height - spaceSkipped
	if #console.buffer > spaceLeft / console_lineHeight then
		start = #console.buffer - math.floor(spaceLeft / console_lineHeight) + 1
	end

	for lineNo = start, #console.buffer do
		local line = console.buffer[lineNo]

		-- local _, wrappedText = console_font:getWrap(line, coords.width)
		-- for _, linePart in pairs(wrappedText) do
		-- 	love.graphics.print(linePart, console_transform)
		-- 	console_transform:translate(0, 20)
		-- end

		-- do not wrap
		love.graphics.print(line, console_transform)
		console_transform:translate(0, console_lineHeight)
	end
	love.graphics.setCanvas()
end

function console.draw(x, y, width, height)
	if not console_needRefresh then
		if console_prevData.x ~= x or
				console_prevData.y ~= y or
				console_prevData.width ~= width or
				console_prevData.height ~= height then
			console_needRefresh = true
			--print('need refresh')
		end
	end

	if console_needRefresh then
		console_prevData = { x = x, y = y, width = width, height = height }
		console_quad = love.graphics.newQuad(x, y, width, height, S.resolution.x, S.resolution.y)
		console_refresh(console_prevData)
		console_needRefresh = false
	end

	love.graphics.draw(console_canvas, console_quad, x, y)
end

return console