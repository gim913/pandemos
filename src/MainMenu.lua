-- imported modules
local class = require 'engine.oop'
local Game = require 'Game'
local S = require 'settings'

local gamestate = require 'hump.gamestate'

-- class
local MainMenu = class('MainMenu')

local fireData = nil
local fireImg = nil

local rng = nil
local bigFont = love.graphics.newFont(48)
local texts = {
	love.graphics.newText(bigFont, "new game")
	, love.graphics.newText(bigFont, "settings")
	, love.graphics.newText(bigFont, "quit")
}

local Fire_Width = 200
local Fire_Height = 100
local Refresh_Speed = 0.15
local Progress = 20
local function updateFireImg()
	fireImg = love.graphics.newImage(fireData)
	fireImg:setFilter("nearest", "nearest")
end

local fireReady = true
local prev = 1
local function updateFire(quitting)
	for x = 0, Fire_Width - 1 do
		for y = prev, math.min(Fire_Height - 1, prev + Progress) do
			local r,g,b,a = fireData:getPixel(x, y)
			local rand = rng:random(0, 3)
			local v = r
			if quitting then
				v = math.max(0.1, v * 0.8)
			else
				if rand == 1 then
					v = math.max(0.1, math.sin(v * 0.9))
				end
			end
			local tempX = x - rng:random(-1, 1)
			--(rand - 1)
			local adjustY = 0
			if tempX < 0 then
				tempX = tempX + Fire_Width - 1
				adjustY = 1
			elseif tempX >= Fire_Width then
				adjustY = -1
				tempX = tempX - (Fire_Width - 1)
			end
			if y - adjustY - 1 > 0 then
				fireData:setPixel(tempX, y - adjustY - 1, v, v, v, 1.0)
			end
		end
	end
	prev = prev + Progress
	if Fire_Height - 1 < prev then
		prev = 1
		return false
	end

	return true
end

function MainMenu:ctor()
	rng = love.math.newRandomGenerator()
	--rng = love.math.newRandomGenerator(love.timer.getTime())

	fireData = love.image.newImageData(Fire_Width, Fire_Height)
	fireData:mapPixel(function(x, y, r, g, b, a)
		if Fire_Height - 1 <= y then
			return 1.0, 1.0, 1.0, 1.0
		else
			return 0.25, 0.25, 0.25, 1.0
		end
	end)

	for i = 1, 200 do
		while updateFire() do
		end
	end
	updateFireImg()
end

function MainMenu:enter()
	self.selected = 1
	self.totalTime = 0
end

local quitCounter = 0
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
			for x = 0, Fire_Width - 1 do
				fireData:setPixel(x, Fire_Height - 1, 0.0, 0.0, 0.0, 1.0)
			end
			quitCounter = 20
			Refresh_Speed = 0.04
		end
	end
end


function MainMenu:update(dt)
	self.totalTime = self.totalTime + dt

	if not fireReady and not updateFire(quitCounter > 0) then
		fireReady = true
	end

	if fireReady and self.totalTime >= Refresh_Speed then
		updateFireImg()
		self.totalTime = self.totalTime - Refresh_Speed
		if quitCounter > 0 then
			quitCounter = quitCounter - 1
			if 0 == quitCounter then
				love.event.push("quit")
			end
		end
		fireReady = false
	end
end

function MainMenu:draw()
	love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
	love.graphics.draw(fireImg, 0, 0, 0, S.resolution.x / Fire_Width, S.resolution.y / Fire_Height)

	love.graphics.setBlendMode('alpha')
	love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
	love.graphics.print("FPS: "..love.timer.getFPS(), S.resolution.x - 100, 10)

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
