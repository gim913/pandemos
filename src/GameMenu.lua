-- imported modules
local class = require 'engine.oop'
local color = require 'engine.color'
local Grid = require 'Grid'
local S = require 'settings'

local gamestate = require 'hump.gamestate'

-- class
local GameMenu = class('GameMenu')

local rng = nil
local bigFont = love.graphics.newFont('fonts/FSEX300.ttf', 64, 'normal')

local texts = {
	love.graphics.newText(bigFont, "continue")
	, love.graphics.newText(bigFont, "settings")
	, love.graphics.newText(bigFont, "save")
	, love.graphics.newText(bigFont, "quit")
}

function GameMenu:ctor()
	rng = love.math.newRandomGenerator()

	self.shader = love.graphics.newShader[[
		extern vec2 dims;
		vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
			vec2 r = (vec2(0.5, 0.5) - sc / dims);
			number l = 0.5 + dot(r, r);
			vec4 pix = vec4(1 - l, 1 - l, 1 - l, l);
			return pix;
		}
	]]

end

function GameMenu:enter(from)
	self.from = from
	self.selected = 1
	self.totalTime = 0
end

local quitCounter = 0

function GameMenu:keypressed(key)
	if 'down' == key then
		self.selected = math.min(#texts, self.selected + 1)
	elseif 'up' == key then
		self.selected = math.max(1, self.selected - 1)
	elseif 'return' == key then
		if 1 == self.selected then
			gamestate.pop()
		elseif 2 == self.selected then
		elseif 3 == self.selected then
		else
			love.event.push("quit")
		end
	end
end

function GameMenu:update(dt)
	self.totalTime = self.totalTime + dt
	self.shader:send("dims", { love.graphics.getWidth(), love.graphics.getHeight() })
end

function GameMenu:draw()
	local W, H = love.graphics.getWidth(), love.graphics.getHeight()

    self.from:draw()

	love.graphics.setShader(self.shader)
	love.graphics.setColor(0.25, 0.25, 0.25, 0.8)
	love.graphics.rectangle('fill', 0, 0, W, H)
	love.graphics.setShader()

	love.graphics.setColor(1.0, 1.0, 1.0, 1.0)

	local w2 = S.resolution.x / 2
	local h2 = (S.resolution.y - 70 * 3) / 2
	local off = 0
	for k, text in pairs(texts) do
		if self.selected == k then
			love.graphics.setColor(0.9, 0.7, 0.0, 1.0)
		else
			love.graphics.setColor(0.9, 0.9, 0.9, 1.0)
		end
		love.graphics.draw(text, w2 - text:getWidth() / 2, h2 + off)
		off = off + 70
	end
end

return GameMenu
