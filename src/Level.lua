-- imported modules
local Grid = require 'Grid'
local LevelGen = require 'LevelGen'
local S = require 'settings'
local Tiles = require 'Tiles'
local trees = require 'trees'

local class = require 'engine.oop'
local color = require 'engine.color'
local elements = require 'engine.elements'
local fontManager = require 'engine.fontManager'
local map = require 'engine.map'

local ffi = require 'ffi'

-- class
local Level = class('Level')

local Mode = {
	GENERATING_LEVEL = 1
	, COPY_TO_GMAP = 2
	, TREES = 3
	, HOUSES = 4
	, FIXUP = 5
	, FINISHED = 10
}

function Level:ctor(rng, depth)
	self.rng = rng
	self.depth = depth

	self.seed = self.rng:random(0, 99999999)
	self.visited = false
	self.fatFont = fontManager.get(32)

	self.mode = Mode.GENERATING_LEVEL

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
	local minX = grid.w - 1
	local maxX = 0
	local minY = grid.h - 1
	local maxY = 0

	for y = 0, grid.h - 1 do
		for x = 0, grid.w - 1 do
			if grid:at(x, y) ~= 0 then
				minX = math.min(minX, x)
				maxX = math.max(maxX, x)
				minY = math.min(minY, y)
				maxY = math.max(maxY, y)
			end
		end
	end

	for y = 0, grid.h - 1 do
		local idx = (sy + y) * self.w + sx
		for x = 0, grid.w - 1 do
			if (grid:at(x, y) == Tiles.House_Wall) then
				local v = getCode4(grid, function(code) return (code==Tiles.House_Wall or code == Tiles.House_Window or code == Tiles.House_Door) end, x, y)
				local gobj = elements.create(idx)
				gobj:setTileId(Tiles.House_Wall - 1 + mapping[v])
				gobj:setOpaque(true)
			elseif (grid:at(x, y) == Tiles.House_Window) then
				local v = getCode4(grid, function(code) return (code==Tiles.House_Wall or code == Tiles.House_Window or code == Tiles.House_Door) end, x, y)
				local gobj = elements.create(idx)
				gobj:setTileId(Tiles.House_Window - 1 + mapping[v])
				gobj:setSmashable({ state = 1, smashedTiles = { Tiles.House_Window_Broken } })

			elseif (grid:at(x, y) == Tiles.House_Temporary) then
				local gobj = elements.create(idx)
				gobj:setTileId(Tiles.House_Temporary)
			elseif (grid:at(x, y) == Tiles.House_Door) then
				local gobj = elements.create(idx)
				local v = getCode4(grid, function(code) return (code==Tiles.House_Wall or code == Tiles.House_Window) end, x, y)
				if 64 + 2 == v then
					gobj:setTileId(Tiles.House_Door_V2)
				else
					gobj:setTileId(Tiles.House_Door_H2)
				end
				gobj:setPassable(true)
			end

			idx = idx + 1
		end
	end

	return minX, maxX, minY, maxY
end

local items = {
	{ symbol = '[', name = 'Bo', type = 'melee'
		, flags = { ['throwable'] = true }, color = { color.hsvToRgb(0.058, 0.67, 0.60, 1.0) } },
	{ symbol = '[', name = 'Baseball bat', type = 'melee'
		, flags = { ['throwable'] = true }, color = { color.hsvToRgb(0.1, 0.36, 0.55, 1.0) } },
	{ symbol = '[', name = 'Crowbar', type = 'melee'
		, flags = { ['throwable'] = true }, color = { color.hsvToRgb(0.0, 1.0, 0.38, 1.0) } },
	{ symbol = '[', name = 'Machete', type = 'melee'
		, flags = { ['throwable'] = true }, color = { color.hsvToRgb(0.56, 0.24, 0.72, 1.0) } },

	{ symbol = '[', name = 'Beretta M9', type = 'light'
		, flags = { ['throwable'] = true }, color = color.dimgray },
	{ symbol = '[', name = 'Grand Power K100', type = 'light'
		, flags = { ['throwable'] = true }, color = { color.gray } },

	{ symbol = '!', name = 'Goo'
		, flags = { ['throwable'] = true }, color = color.lime },
}

local itemUid = 1
local function createTreesAsElements(grid)
	local idx = 0
	for y = 0, grid.h - 1 do
		for x = 0, grid.w - 1 do
			local v = grid:at(x, y)
			if v > 0 then
				if v <= 16 then
					local gobj = elements.create(idx)
					gobj:setTileId(Tiles.Trees + v - 1)
					gobj:setOpaque(true)
				else
					local itemId = v - 100
					local gobj = elements.create(idx)
					gobj:setTileId(nil)
					gobj:setPassable(true)
					gobj:setItem({ uid = itemUid, blueprint = items[itemId] })
					itemUid = itemUid + 1
				end
			end

			idx = idx +1
		end
	end
end

local function isPassable(tileId)
	return Tiles.Water ~= tileId
end

function Level:update(_dt)
	if Mode.GENERATING_LEVEL == self.mode then
		if self.generator:update(dt) then
			self.mode = Mode.COPY_TO_GMAP
		end

	elseif Mode.COPY_TO_GMAP == self.mode then
		local idx = 0
		for y = 0, self.h - 1 do
			for x = 0, self.w - 1 do
				local tileId = (self.grid:at(x, y) - 1) * 16
				map.setTileId(idx, tileId)
				map.setPassable(idx, isPassable(tileId))
				idx = idx + 1
			end
		end
		self.mode = Mode.TREES

	elseif Mode.TREES == self.mode then
		self.grid:fill(0)

		-- forest
		local randShiftX = self.rng:random(10000)
		local randShiftY = self.rng:random(10000)

		local treeCount = self.grid.w * self.grid.h * 6 / 100
		local actualTreeCount = 0
		local forestItemCount = 0
		for i = 1, treeCount do
			local tx = self.rng:random(0, self.grid.w - 1)
			local ty = self.rng:random(0, self.grid.h - 1)

			local m = 10 * love.math.noise((randShiftX + tx) / 55.0, (randShiftY + ty) / 55.0)
			if m > 7 then
				self.grid:set(tx, ty, self.rng:random(1, #trees))
				actualTreeCount = actualTreeCount + 1
			else
				self.grid:set(tx, ty, 100 + self.rng:random(#items))
				forestItemCount = forestItemCount + 1
			end
		end

		print('wanted to generate ' .. treeCount .. ' trees, generated ' .. actualTreeCount .. ", items: " .. forestItemCount)
		self.mode = Mode.HOUSES

	elseif Mode.HOUSES == self.mode then
		local houseGrid = Grid:new({ w = House_W, h = House_H })
		loadHouse('houses/house001.bin', houseGrid)
		local houseX = map.width() / 2 - 12
		local houseY = map.height() - 29 - 10 - 40

		minX, maxX, minY, maxY = self:fixupWallsAndCreateAsElements(houseGrid, houseX, houseY)

		-- make floor under whole house, remove any trees
		for y = houseY + minY, houseY + maxY do
			for x = houseX + minX, houseX + maxX do
				local idx = y * map.width() + x
				map.setTileId(idx, Tiles.House_Floor)
				self.grid:set(x, y, 0)
			end
		end

		local houseGrid = Grid:new({ w = House_W, h = House_H })
		loadHouse('houses/house004.bin', houseGrid)
		local houseX = map.width() / 2 + 12
		local houseY = map.height() - 29 - 10 - 40
		minX, maxX, minY, maxY = self:fixupWallsAndCreateAsElements(houseGrid, houseX, houseY)
		self.mode = Mode.FIXUP

		-- make floor under whole house
		for y = houseY + minY, houseY + maxY do
			for x = houseX + minX, houseX + maxX do
				local idx = y * map.width() + x
				map.setTileId(idx, Tiles.House_Floor)
				self.grid:set(x, y, 0)
			end
		end

		createTreesAsElements(self.grid)

	elseif Mode.FIXUP == self.mode then
		map.fixupTiles(Tiles.Water, Tiles.Earth)
		map.fixupTiles(Tiles.Earth, Tiles.Grass)
		self.mode = Mode.FINISHED

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