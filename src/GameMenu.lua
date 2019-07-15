-- imported modules
local Grid = require 'Grid'
local Menu = require 'Menu'
local S = require 'settings'

local class = require 'engine.oop'
local color = require 'engine.color'
local fontManager = require 'engine.fontManager'

local gamestate = require 'hump.gamestate'

-- class
local GameMenu = class('GameMenu', Menu)

local bigFont = fontManager.get('fonts/FSEX300.ttf', 64, 'normal')

function GameMenu:ctor()
	local texts = {
		love.graphics.newText(bigFont, "continue")
		, love.graphics.newText(bigFont, "settings")
		, love.graphics.newText(bigFont, "save")
		, love.graphics.newText(bigFont, "quit")
	}
	self.base.ctor(self, texts)

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
	self.base.enter(self, from)
	self.from = from
end

local quitCounter = 0

function GameMenu:keypressed(key)
	self.base.keypressed(self, key)

	if 'return' == key then
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
	self.base.update(self, dt)

	self.shader:send("dims", { love.graphics.getWidth(), love.graphics.getHeight() })
end

function GameMenu:draw()
	local W, H = love.graphics.getWidth(), love.graphics.getHeight()

    self.from:draw()

	love.graphics.setShader(self.shader)
	love.graphics.setColor(0.25, 0.25, 0.25, 0.8)
	love.graphics.rectangle('fill', 0, 0, W, H)
	love.graphics.setShader()

	self.base.draw(self)
end

return GameMenu
