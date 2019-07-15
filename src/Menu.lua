-- imported modules
local S = require 'settings'

local class = require 'engine.oop'
local color = require 'engine.color'

-- class
local Menu = class('Menu')

local Line_Height = 80

function Menu:ctor(texts)
	self.texts = texts
end

function Menu:enter()
	self.selected = 1
	self.totalTime = 0
end

function Menu:keypressed(key)
	if 'down' == key then
		self.selected = math.min(#self.texts, self.selected + 1)
	elseif 'up' == key then
		self.selected = math.max(1, self.selected - 1)
	end
end

function Menu:update(dt)
	self.totalTime = self.totalTime + dt
end

local function drawCorner(id, x, y, cs)
	for i = 1, 5 do
		local base = (6 - i) / 5.0
		local sat = math.sqrt(1.0 - base)
		love.graphics.setColor(color.hsvToRgb(base / 5.0, sat, math.sqrt(base) * 0.8, 1.0))
		--love.graphics.rectangle('line', x + i * i, y + i * i, cs - 2 * i * i, cs - 2 * i * i)

		local shift = cs - i * i
		local curve = love.math.newBezierCurve({
			x + shift, y + shift,
			x - shift * 2, y + shift,
			x - shift * 2, y - shift * 2,
			x + shift, y - shift * 2,
			x + shift, y + shift
		})
		curve:rotate(id * math.pi / 2, x + cs, y + cs)


		local dx = -cs * ((id == 1 or id == 2) and 1 or 0)
		local dy = -cs * (bit.band(id, 2) / 2)
		curve:translate(dx, dy)

		-- deliberately make the subdivision 'low'
		love.graphics.line(curve:render(2))
		--love.graphics.polygon('fill', curve:render())
	end
end

local function drawFrame(x, y, width, height)
	love.graphics.setLineWidth(2)
	love.graphics.setLineStyle('rough')

	local padding = 50
	local sx, sy = x - padding, y - padding
	local sw, sh = width + padding * 2, height + padding * 2
	for i = 1, 5 do
		local base = (6 - i) / 5.0
		local sat = math.sqrt(1.0 - base)
		love.graphics.setColor(color.hsvToRgb(base / 5.0, sat, math.sqrt(base) * 0.8, 1.0))

		love.graphics.rectangle('line', sx - i * i, sy - i * i, sw + 2 * i * i, sh + 2 * i * i)
	end

	local Corner_Size = 60
	drawCorner(0, sx - Corner_Size, sy - Corner_Size, Corner_Size)
	drawCorner(1, sx + sw, sy - Corner_Size, Corner_Size)
	drawCorner(2, sx +sw, sy + sh, Corner_Size)
	drawCorner(3, sx - Corner_Size, sy + sh, Corner_Size)
end

function Menu:draw()
	local w2 = S.resolution.x / 2
	local h2 = (S.resolution.y - Line_Height * 3) / 2
	local off = 0
	local maxWidth = 0
	for _, text in pairs(self.texts) do
		maxWidth = math.max(maxWidth, text:getWidth())
	end

	drawFrame(w2 - maxWidth / 2, h2, maxWidth, Line_Height * #self.texts)

	for k, text in pairs(self.texts) do
		if self.selected == k then
			love.graphics.setColor(0.9, 0.7, 0.0, 1.0)
		else
			love.graphics.setColor(0.9, 0.9, 0.9, 1.0)
		end
		love.graphics.draw(text, w2 - text:getWidth() / 2, h2 + off)
		off = off + Line_Height
	end
end

return Menu
