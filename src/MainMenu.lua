-- imported modules
local class = require 'engine.oop'
local Game = require 'Game'
local S = require 'settings'

local gamestate = require 'hump.gamestate'

-- class
local MainMenu = class('MainMenu')

local rng = nil
local bigFont = love.graphics.newFont(48)
local texts = {
	love.graphics.newText(bigFont, "new game")
	, love.graphics.newText(bigFont, "settings")
	, love.graphics.newText(bigFont, "quit")
}

function MainMenu:ctor()
	rng = love.math.newRandomGenerator()
	--rng = love.math.newRandomGenerator(love.timer.getTime())
end

function MainMenu:enter()
	self.selected = 1
end

function MainMenu:keypressed(key)
	if 'down' == key then
		self.selected = math.min(3, self.selected + 1)
	elseif 'up' == key then
		self.selected = math.max(1, self.selected - 1)
	elseif 'return' == key then
		if 1 == self.selected then
			self.game = Game:new(rng)
			self.game:startLevel()
			gamestate.push(self.game)

		else
			love.event.push("quit")
		end
	end
end

function MainMenu:draw()
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

return MainMenu
