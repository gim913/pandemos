-- imported modules
local action = require 'engine.action'
local class = require 'engine.oop'
local color = require 'engine.color'
local console = require 'engine.console'
local elements = require 'engine.elements'
local Entity = require 'engine.Entity'
local Equipment = require 'engine.Equipment'
local Inventory = require 'engine.Inventory'
local soundManager = require 'engine.soundManager'
local utils = require 'engine.utils'
local map = require 'engine.map'

-- class
local Player = class('Player', Entity)

Player.Base_Speed = 1200
Player.Bash_Speed = 720
Player.Throw_Speed = 720

function Player:ctor(initPos)
	self.base.ctor(self, initPos)
	self.displaySee = false

	self.losRadius = 15
	self.seeDist = 15

	self.inventory = Inventory:new(6)
	self.equipment = Equipment:new({ 'melee', 'light', 'heavy' })
	self.equipmentActive = 0

	self.color = { 0.9, 0.9, 0.9, 1.0 }
	self.sounds = {
		walk = {
			soundManager.get('sounds/stepdirt_1.wav', 'static')
			, soundManager.get('sounds/stepdirt_2.wav', 'static')
			, soundManager.get('sounds/stepdirt_3.wav', 'static')
			, soundManager.get('sounds/stepdirt_4.wav', 'static')
			, soundManager.get('sounds/stepdirt_5.wav', 'static')
			, soundManager.get('sounds/stepdirt_6.wav', 'static')
			, soundManager.get('sounds/stepdirt_7.wav', 'static')
			, soundManager.get('sounds/stepdirt_8.wav', 'static')
		}
	}

end

function Player:onAdd()
	self.name = 'Player'
	self:occupy()

	self.maxHp = 1200
	self.hp = 1200
	self.damage = 10
end

function Player:recalcSeeMap()
	self.displaySee = true
	self.base.recalcSeeMap(self)
	self.displaySee = false
end

function Player:checkEntVis(oth, dist)
	self.base.checkEntVis(self, oth, dist)

	if self.displaySee then
		-- local gray = { color.hsvToRgb(0.0, 0.0, 0.8, 1.0) }
		-- if self.seemap[oth] then
		-- 	console.log({
		-- 		gray,
		-- 		'You see ',
		-- 		{ color.hsvToRgb(0.00, 0.8, 1.0, 1.0) },
		-- 		oth.name,
		-- 	})
		-- end
	end
end

function Player:move()
	self.base.move(self)
end

local function play(src)
	if src:isPlaying() then
		src:stop()
	end

	src:play()
end

function Player:sound(actionId)
	if action.Action.Move == actionId then
		local rnd = self.rng:random(#self.sounds.walk)
		play(self.sounds.walk[rnd])
	end
end

function Player:throw()
	local desc = self.actionData
	self.actionData = nil

	local item = self.inventory:get(desc.itemIndex)
	self.inventory:del(item)

	self.doRecalc = true
	return desc, item
end

return Player