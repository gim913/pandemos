-- imported modules
local Grid = require 'Grid'
local LevelGen = require 'LevelGen'
local S = require 'settings'

local class = require 'engine.oop'
local elements = require 'engine.elements'
local fontManager = require 'engine.fm'
local map = require 'engine.map'

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
	, House_Wall = 16 * 2 + 1
	, Bridge = 16 * 3 + 0
	, House_Temporary = 16 * 3 + 1
	, House_Door = 16 * 4 + 0
	, House_Window = 16 * 4 + 1
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

local House_Mapping = {
	[0x10] = Tiles.House_Temporary -- bed
	, [0x17] = Tiles.House_Wall
	, [0x27] = Tiles.House_Temporary
	, [0x2C] = Tiles.House_Window -- garage door
	, [0x37] = Tiles.House_Door
}
local House_W = 32
local House_H = 32
local function loadHouse(filename, grid)
	local file = io.open('src/' .. filename, 'rb')
	local data = file:read(House_H * House_W)
	local house = ffi.cast('uint8_t*', data)

	local i = 0
	for y = 0, House_H - 1 do
		for x = 0, House_W - 1 do
			if house[i] ~= 0 then
				grid:set(x, y, House_Mapping[house[i]])
			end
			i = i + 1
		end
	end
end

local mapping = {
	-- neighbour twos
	[64 + 8] = 1,
	[8 + 2] = 2,
	[2 + 16] = 3,
	[16 + 64] = 4,

	-- ones
	[64] = 5,
	[2] = 5,
	[8] = 6,
	[16] = 6,

	-- simple twos
	[64 + 2] = 5,
	[8 + 16] = 6,

	--
	[64 + 2 + 16] = 8,
	[64 + 2 +  8] = 9,
	[8 + 16 + 2] = 10,
	[8 + 16 +  64] = 11,

	-- four
	[64 + 8 + 16 + 2] = 7
}

local function grid_getBounded(grid, f, x, y)
	if x < 0 or x >= grid.w or y < 0 or y >= grid.h then
		return 0
	end
	if f(grid:at(x, y)) then
		return 1
	end
	return 0
end

local function getCode4(grid, f, x, y)
	return
		grid_getBounded(grid, f,x  ,y-1)*2 +
		grid_getBounded(grid, f,x-1,y  )*8 +
		grid_getBounded(grid, f,x+1,y  )*16 +
		grid_getBounded(grid, f,x  ,y+1)*64
end

function Level:fixupWallsAndCreateAsElements(grid, sx, sy)
	for y = 0, grid.h - 1 do
		local idx = (sy + y) * self.w + sx
		for x = 0, grid.w - 1 do
			if (grid:at(x, y) == Tiles.House_Wall) then
				local v = getCode4(grid, function(code) return (code==Tiles.House_Wall or code == Tiles.House_Window or code == Tiles.House_Door) end, x, y)
				local gobj = elements.create(idx)
				print((sx + x) .. "," .. (sy + y) .. " : ")
				gobj:setTileId(Tiles.House_Wall - 1 + mapping[v])
				gobj:setOpaque(true)
			elseif (grid:at(x, y) == Tiles.House_Window) then
				local v = getCode4(grid, function(code) return (code==Tiles.House_Wall or code == Tiles.House_Window or code == Tiles.House_Door) end, x, y)
				local gobj = elements.create(idx)
				print((sx + x) .. "," .. (sy + y) .. " : ")
				gobj:setTileId(Tiles.House_Window - 1 + mapping[v])
				--gobj:setSmash() - later
			elseif (grid:at(x, y) == Tiles.House_Temporary) then
				local gobj = elements.create(idx)
				gobj:setTileId(Tiles.House_Temporary)
			elseif (grid:at(x, y) == Tiles.House_Door) then
				local gobj = elements.create(idx)
				gobj:setTileId(Tiles.House_Door)
				gobj:setPassable(true)
			end

			idx = idx + 1
		end
	end
end

local function isPassable(tileId)
	return Tiles.Water ~= tileId
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
				local tileId = (self.grid:at(x, y) - 1) * 16
				map.setTileId(idx, tileId)
				map.setPassable(idx, isPassable(tileId))
				idx = idx + 1
			end
		end
		self.mode = MODE_FIXUP
	elseif MODE_FIXUP == self.mode then
		map.fixupTiles(Tiles.Water, Tiles.Earth)
		map.fixupTiles(Tiles.Earth, Tiles.Grass)
		self.mode = MODE_HOUSES

	elseif MODE_HOUSES == self.mode then
		local houseGrid = Grid:new({ w = House_W, h = House_H })
		loadHouse('houses/house001.bin', houseGrid)
		local houseX = map.width() / 2 - 16
		local houseY = map.height() - 29 - 10 - 40
		houseGrid = self:fixupWallsAndCreateAsElements(houseGrid, houseX, houseY)
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