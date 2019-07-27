-- imported modules
local action = require 'engine.action'
local class = require 'engine.oop'
local color = require 'engine.color'
local console = require 'engine.console'
local elements = require 'engine.elements'
local Entity = require 'engine.Entity'
local Inventory = require 'engine.Inventory'
local map = require 'engine.map'

-- class
local Player = class('Player', Entity)

Player.Base_Speed = 1200
Player.Bash_Speed = 720

function Player:ctor(initPos)
	self.base.ctor(self, initPos)
	self.displaySee = false

	self.losRadius = 15
	self.seeDist = 15

	self.inventory = Inventory:new(6)
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

return Player