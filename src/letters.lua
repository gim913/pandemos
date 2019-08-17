-- imported modules
local fontManager = require 'engine.fontManager'

-- module

local letters = {}

-- dumb outline for "char" sprites
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

-- preapre "char" sprites
function letters.prepare(letters)
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

return letters
