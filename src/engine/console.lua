-- imported modules
local S = require 'settings'

-- module
local console = {
	buffer = {}
}

local console_canvas = love.graphics.newCanvas(S.resolution.x, S.resolution.y)
--local console_font = love.graphics.newFont('fonts/arimo.ttf', 16, 'light')
--local console_font = love.graphics.newFont('fonts/inconsolata.otf', 18, 'light')
local console_font = love.graphics.newFont('fonts/scp.otf', 16, 'normal')
local console_transform = love.math.newTransform()

local console_need_refresh = true
local console_last_data = {}
local console_quad

function console.log(a)
	if 100 == #console.buffer then
		table.remove(console.buffer, 1)
	end
	table.insert(console.buffer, a)
	console_need_refresh = true
end

local function console_refresh(coords)
	console_transform:reset()

	love.graphics.setCanvas(console_canvas)

	love.graphics.clear(0.1, 0.1, 0.1, 1.0)
	love.graphics.setFont(console_font)
	love.graphics.setColor(1.0, 1.0, 1.0, 1.0)

	console_transform:translate(coords.x, coords.y)

	local start = 1
	if #console.buffer >= coords.height / 18 then
		start = #console.buffer - math.floor(coords.height / 18) + 1
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
		console_transform:translate(0, 18)
	end
	love.graphics.setCanvas()
end

function console.draw(x, y, width, height)
	if not console_need_refresh then
		if console_last_data.x ~= x or
				console_last_data.y ~= y or
				console_last_data.width ~= width or
				console_last_data.height ~= height then
			console_need_refresh = true
			--print('need refresh')
		end
	end

	if console_need_refresh then
		console_last_data = { x = x, y = y, width = width, height = height }
		console_quad = love.graphics.newQuad(x, y, width, height, S.resolution.x, S.resolution.y)
		console_refresh(console_last_data)
		console_need_refresh = false
	end

	love.graphics.draw(console_canvas, console_quad, x, y)
end

return console