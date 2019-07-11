-- imported modules
local action = require 'engine.action'
local class = require 'engine.oop'
local Color = require 'engine.Color'
local console = require 'engine.console'
local elements = require 'engine.elements'
local Entity = require 'engine.Entity'
local map = require 'engine.map'


-- class
local Player = class('Player', Entity)

Player.Base_Speed = 1200
Player.Bash_Speed = 700

function Player:ctor(initPos)
	self.base.ctor(self, initPos)
	self.displaySee = false
end

function Player:onAdd()
	self.name = 'Player'
	self:occupy()
end

function Player:recalcSeeMap()
	self.displaySee = true
	self.base.recalcSeeMap(self)
	self.displaySee = false
end

function Player:checkEntVis(oth, dist)
	self.base.checkEntVis(self, oth, dist)

	if self.displaySee then
		local gray = { Color.hsvToRgb(0.0, 0.0, 0.8, 1.0) }
		if self.seemap[oth] then
			console.log({
				gray,
				'You see ',
				{ Color.hsvToRgb(0.00, 0.8, 1.0, 1.0) },
				oth.name,
			})
		end
	end
end

return Player