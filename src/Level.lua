-- imported modules
local Grid = require 'Grid'
local LevelGen = require 'LevelGen'
local S = require 'settings'

local class = require 'engine.oop'
local fontManager = require 'engine.fm'
local map = require 'engine.map' -- todo: rething, I was hoping I'll be able to avoid importing it here

local ffi = require 'ffi'

-- class
local Level = class('Level')

local MODE_GENERATING_LEVEL = 1
local MODE_COPY_TO_GMAP = 2
local MODE_FIXUP = 3
local MODE_HOUSES = 4
local MODE_FINISHED = 10

local Tiles = {
	Water = 16 * 0 + 0
	, Earth = 16 * 1 + 0
	, Grass = 16 * 2 + 0
}
function Level:ctor(rng, depth)
	self.rng = rng
	self.depth = depth

	self.seed = self.rng:random(0, 99999999)
	self.visited = false
	self.fatFont = fontManager.get(32)

	self.mode = MODE_GENERATING_LEVEL

	self.w = S.game.COLS
	self.h = S.game.ROWS

end

function Level:initializeGenerator()
	local temp = { w = self.w, h = self.h }
	self.grid = Grid:new({ w = self.w, h = self.h })
	self.generator = LevelGen:new(self.grid, self.depth, self.rng)
end

local House_W = 32
local House_H = 32
local function addHouse(filename, grid, sx, sy)
	local file = io.open('src/' .. filename, 'rb')
	local data = file:read(House_H * House_W)
	local house = ffi.cast('uint8_t*', data)

	print('adding house at ' .. sx .. "," .. sy)
	local i = 0
	for y = 1, House_H do
		for x = 1, House_W do
			if house[i] ~= 0 then
				grid:set(sx + x - 1, sy + y - 1, house[i] + 1)
			end
			i = i + 1
		end
	end
end

function Level:update(_dt)
	if MODE_GENERATING_LEVEL == self.mode then
		if self.generator:update(dt) then
			self.mode = MODE_COPY_TO_GMAP
		end

	elseif MODE_COPY_TO_GMAP == self.mode then
		local idx = 0
		for y = 0, self.h - 1 do
			for x = 0, self.w - 1 do
				map.setTileId(idx, (self.grid:at(x, y) - 1) * 16)
				idx = idx + 1
			end
		end
		self.mode = MODE_FIXUP
	elseif MODE_FIXUP == self.mode then
		map.fixupTiles(Tiles.Water, Tiles.Earth)
		map.fixupTiles(Tiles.Earth, Tiles.Grass)
		self.mode = MODE_HOUSES

	elseif MODE_HOUSES == self.mode then
		self.grid:fill(0)
		local houseX = map.width() / 2 - 16
		local houseY = map.height() - 29 - 10 - 32
		addHouse('houses/house001.bin', self.grid, houseX, houseY)

		local idx = 0
		for y = 0, self.h - 1 do
			for x = 0, self.w - 1 do
				local v = self.grid:at(x, y)
				if v ~= 0 then
					map.setTileId(idx, v)
				end
				idx = idx + 1
			end
		end
		self.mode = MODE_FINISHED
	else
		return false
	end

	return true
end

function Level:show()
	local msg = love.graphics.newText(self.fatFont, "generating level")
	love.graphics.setColor(0.0, 0.6, 0.0, 1.0)
	love.graphics.draw(msg, (S.resolution.x - msg:getWidth()) / 2, (S.resolution.y - msg:getHeight()) / 2)
end

return Level