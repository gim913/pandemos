-- imported modules
local class = require 'engine.oop'
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
end

return Camera
