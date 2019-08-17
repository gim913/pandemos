-- imported modules
local Tiles = require 'Tiles'
local elements = require 'engine.elements'
local map = require 'engine.map'

-- module

local minimapData = nil
local minimapImg = nil

local minimap = {}

function minimap.initialize(width, height)
	minimapData = love.image.newImageData(width, height)
	minimapData:mapPixel(function(x, y, r, g, b, a)
		return 0.1, 0.1, 0.1, 1.0
	end)
end

function minimap.getImage()
	return minimapImg
end

function minimap.update()
	minimapImg = love.graphics.newImage(minimapData)
	minimapImg:setFilter("nearest", "nearest")
end

local f = math.floor
function minimap.known(k)
	local tileId = map.getTileId(k)
	local r,g,b = 25,25,25
	if tileId >= Tiles.Water and tileId < Tiles.Earth then
		r,g,b = 0x4c, 0x9a, 0xec
	elseif tileId >= Tiles.Earth and tileId < Tiles.Grass then
		r,g,b = 0x3c, 0x18, 0x00
	elseif tileId >= Tiles.Grass and tileId < Tiles.Bridge then
		r,g,b = 0x08, 0x7c, 0x00
	elseif tileId == Tiles.Bridge then
		r,g,b = 0x78, 0x3c, 0x00
	else
		r,g,b = 64, 64, 64
	end

	local t = elements.getTileId(k)
	if t and t >= Tiles.Trees and t <= Tiles.Tree_Maple then
		r,g,b = 0x8, 0x2c, 0x8
	end

	local x = f(k % map.width())
	local y = f(k / map.width())
	minimapData:setPixel(x, y, r / 255.0, g / 255.0, b / 255.0, 1.0)
end

return minimap
