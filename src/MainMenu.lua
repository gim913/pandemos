-- imported modules
local class = require 'engine.oop'
local color = require 'engine.color'
local Game = require 'Game'
local Grid = require 'Grid'
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

local Fire = class("Fire")
Fire.Width = 200
Fire.Height = 100
Fire.Progress = 20
Fire.Rng = love.math.newRandomGenerator(love.timer.getTime())

function Fire:ctor()
	self.fireImg1 = nil
	self.data1 = love.image.newImageData(Fire.Width, Fire.Height)
	self.grid = Grid:new({ w = Fire.Width, h = Fire.Height })

	self.grid:fill(0)
	for x = 0, Fire.Width - 1 do
		self.grid:set(x, Fire.Height - 1, 255)
	end

	self.prev = 1
	for i = 1, 200 do
		while self:update() do
		end
	end
	self:updateImg()
end

function Fire:updateImg()
	self.data1:mapPixel(function(x,y, r,g,b,a)
		local act = self.grid:at(x, y)
		local base = act / 255.0
		local sat = math.sqrt(1.0 - base)
		return color.hsvToRgb(act / 255.0 / 5.5, sat, math.sqrt(base) * 0.4, 255.0)
	end)
	self.fireImg1 = love.graphics.newImage(self.data1)
	self.fireImg1:setFilter("nearest", "nearest")
end

function Fire:initFadeOut()
	for x = 0, Fire.Width - 1 do
		self.grid:set(x, Fire.Height - 1, 0)
	end
end

-- idea from http://fabiensanglard.net/doom_fire_psx/index.html
function Fire:update(quitting)
	for x = 0, Fire.Width - 1 do
		for y = self.prev, math.min(Fire.Height - 1, self.prev + Fire.Progress) do
			local intensity = self.grid:at(x, y)
			local rand = Fire.Rng:random(0, 3)
			local v = intensity
			if quitting then
				v = math.max(0.1, v * 0.8)
			else
				if rand == 1 then
					v = math.max(0.1, v * 0.9)
				end
			end
			-- local tempX = x
			-- local adjustY = 0
			local tempX = x - Fire.Rng:random(-1, 1)
			local adjustY = 0
			if tempX < 0 then
				tempX = tempX + Fire.Width - 1
				adjustY = 1
			elseif tempX >= Fire.Width then
				adjustY = -1
				tempX = tempX - (Fire.Width - 1)
			end
			if y - adjustY - 1 > 0 then
				self.grid:set(tempX, y - adjustY - 1, v)
			end
		end
	end
	self.prev = self.prev + Fire.Progress
	if Fire.Height - 1 < self.prev then
		self.prev = 1
		return false
	end

	return true
end

function MainMenu:ctor()
	rng = love.math.newRandomGenerator()
	--rng = love.math.newRandomGenerator(love.timer.getTime())

	fire = Fire:new()
	self.fireReady = true
end

function MainMenu:enter()
	self.selected = 1
	self.totalTime = 0
end

local quitCounter = 0
local Desired_Fire_Fps = 12
local Fire_Refresh_Speed = 1.0 / Desired_Fire_Fps
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
			fire:initFadeOut()

			quitCounter = 20
			Fire_Refresh_Speed = 1.0 / 60
		end
	end
end

function MainMenu:update(dt)
	self.totalTime = self.totalTime + dt

	if not self.fireReady and not fire:update(quitCounter > 0) then
		self.fireReady = true
	end

	if self.fireReady and self.totalTime >= Fire_Refresh_Speed then
		fire:updateImg()
		self.totalTime = self.totalTime - Fire_Refresh_Speed
		if quitCounter > 0 then
			quitCounter = quitCounter - 1
			if 0 == quitCounter then
				love.event.push("quit")
			end
		end
		self.fireReady = false
	end
end

function MainMenu:draw()
	love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
	love.graphics.draw(fire.fireImg1, 0, 0, 0, S.resolution.x / Fire.Width, S.resolution.y / Fire.Height)

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
