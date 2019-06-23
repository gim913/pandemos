-- imported modules
local class = require 'engine.oop'
local map = require 'engine.map'
local Vec = require 'hump.vector'
local S = require 'settings'

-- class
local Camera = class('Camera')

Camera.Free_Offset = 1

function Camera:ctor()
	self.pos = Vec(-1, -1)
	self.rel = Vec(0, 0)
	self.followedEnt = {}
end

function Camera:follow(entity)
	self.followedEnt = entity

	local VIS_RADIUS = S.game.VIS_RADIUS
	local e = entity
	if e.pos.x <= (VIS_RADIUS - Camera.Free_Offset) then
		self.rel.x = e.pos.x
	elseif e.pos.x >= (map.width() - 1) - (VIS_RADIUS - Camera.Free_Offset) then
		self.rel.x = e.pos.x + (2 * VIS_RADIUS + 1) - map.width()
	else
		self.rel.x = 12
	end

	if e.pos.y <= (VIS_RADIUS - Camera.Free_Offset) then
		self.rel.y = e.pos.y
	elseif e.pos.y >= (map.height() - 1)-(VIS_RADIUS - Camera.Free_Offset) then
		self.rel.y = e.pos.y + (2 * VIS_RADIUS + 1) - map.height()
	else
		self.rel.y = 12
	end
end

function Camera:update()
	local VIS_RADIUS = S.game.VIS_RADIUS
	local e = self.followedEnt

	if e.pos.x <= (VIS_RADIUS - Camera.Free_Offset) then
		self.rel.x = e.pos.x
	elseif e.pos.x >= (map.width()-1)-(VIS_RADIUS - Camera.Free_Offset) then
		self.rel.x = e.pos.x + (2 * VIS_RADIUS + 1) - map.width()
	else
		if self.rel.x >= (VIS_RADIUS - Camera.Free_Offset) and self.rel.x <= (VIS_RADIUS+Camera.Free_Offset) then
			if e.pos.x > self.pos.x then
				if self.rel.x ~= (VIS_RADIUS + Camera.Free_Offset) then
					self.rel.x = self.rel.x + 1
				end
			elseif e.pos.x < self.pos.x then
				if self.rel.x ~= (VIS_RADIUS-Camera.Free_Offset) then
					self.rel.x = self.rel.x - 1
				end
			end
		end
	end

	if e.pos.y <= (VIS_RADIUS - Camera.Free_Offset) then
		self.rel.y = e.pos.y
	elseif e.pos.y >= (map.height() - 1)-(VIS_RADIUS - Camera.Free_Offset) then
		self.rel.y = e.pos.y + (2 * VIS_RADIUS + 1) - map.height()
	else
		if self.rel.y >= (VIS_RADIUS - Camera.Free_Offset) and self.rel.y <= (VIS_RADIUS+Camera.Free_Offset) then
			if e.pos.y > self.pos.y then
				if self.rel.y ~= (VIS_RADIUS + Camera.Free_Offset) then
					self.rel.y = self.rel.y + 1
				end
			elseif e.pos.y < self.pos.y then
				if self.rel.y ~= (VIS_RADIUS-Camera.Free_Offset) then
					self.rel.y = self.rel.y - 1
				end
			end
		end
	end
	self.pos = e.pos:clone()
	print("> REL AND camera POS" .. self.rel.x .. "," .. self.rel.y .. " ; " .. self.pos.x .. "," .. self.pos.y)
end

return Camera