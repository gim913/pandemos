-- imported modules
local S = require 'settings'

-- module

local mapdata = {
	width = 0
	, height = 0
	, tiles = {}
	, known = {}
}

local function map_init(width, height)
	mapdata.width = width
	mapdata.height = height
	mapdata.tiles = {}
	mapdata.noPass = {}
	mapdata.known = {}
end

local function map_getTileId(x, y)
	local t = mapdata.tiles[y * mapdata.width + x]
	if t ~= nil then
		return t
	end

	return (x + y) % 2
end

local function map_setTileId(idx, tileId)
	mapdata.tiles[idx] = tileId
end


local function map_getTileIdBounded(f, x, y)
	if x < 0 or x >= mapdata.width or y < 0 or y >= mapdata.height then
		return 0
	end
	local i = y * mapdata.width + x
	if f(mapdata.tiles[i]) then
		return 1
	end
	return 0
end

-- calculate 8-bit code for a cell, based on neighbours
local function getCode(f, x,y)
	return
		map_getTileIdBounded(f,x-1,y-1) +
		map_getTileIdBounded(f,x  ,y-1)*2 +
		map_getTileIdBounded(f,x+1,y-1)*4 +
		map_getTileIdBounded(f,x-1,y  )*8 +
		map_getTileIdBounded(f,x+1,y  )*16 +
		map_getTileIdBounded(f,x-1,y+1)*32 +
		map_getTileIdBounded(f,x  ,y+1)*64 +
		map_getTileIdBounded(f,x+1,y+1)*128
end


local function map_fixupTiles(y1, y2)
	-- magic code to tile mapping
	local mapping = {
		[0x0] = 0,

		-- small corners
		[0x1] = 3,
		[0x4] = 5,
		[0x20] = 1,
		[0x80] = 7,

		-- big corners
		[0x16] = 2,
		[0x17] = 2,
		[0x96] = 2,
		[0x97] = 2,

		[0xd0] = 4,
		[0xd4] = 4,
		[0xf0] = 4,
		[0xf4] = 4,

		[0x68] = 6,
		[0x69] = 6,
		[0xe8] = 6,
		[0xe9] = 6,

		[0x0b] = 8,
		[0x0f] = 8,
		[0x2b] = 8,
		[0x2f] = 8,

		-- "sides"
		[0x2] = 9,
		[0x3] = 9,
		[0x6] = 9,
		[0x7] = 9,

		[0x40] = 10,
		[0x60] = 10,
		[0xc0] = 10,
		[0xe0] = 10,

		[0x10] = 11,
		[0x14] = 11,
		[0x90] = 11,
		[0x94] = 11,

		[0x08] = 12,
		[0x09] = 12,
		[0x28] = 12,
		[0x29] = 12,
	}

	-- local outp = io.open('transitions.txt', 'a')
	-- outp:write ( ("Currently mapping transition from %d -> %d\n"):format(y1, y2))
	-- for y = 0, mapdata.height - 1 do
	-- 	for x = 0, mapdata.width - 1 do
	-- 		local i = y * mapdata.width + x
	-- 		if (mapdata.data[i] == y1) then
	-- 			local v = getCode(function(code) return code == y2 end, x, y)
	-- 			if mapping[v] ~= nil then
	-- 				outp:write('XX')
	-- 			else
	-- 				outp:write(("%02x"):format(v))
	-- 			end
	-- 		else
	-- 			outp:write('..')
	-- 		end
	-- 	end
	-- 	outp:write('\n')
	-- end
	-- outp:close()

	local mapTiles ={}
	for y = 0, mapdata.height - 1 do
		for x = 0, mapdata.width - 1 do
			local i = y * mapdata.width + x
			if (mapdata.tiles[i] == y1) then
				local v = getCode(function(code) return code == y2 end, x, y)
				if mapping[v] ~= nil then
					mapTiles[i] = y1 + mapping[v]
				else
					mapTiles[i] = y1
				end
			else
				mapTiles[i] = mapdata.tiles[i]
			end
		end
	end

	mapdata.tiles = mapTiles
end

local function map_width()
	return mapdata.width
end

local function map_height()
	return mapdata.height
end

local function map_inside(pos)
	return (pos.x >=0 and pos.x < mapdata.width and pos.y >= 0 and pos.y < mapdata.height)
end

local function map_known(idx)
	mapdata.known[idx] = 1
end

local function map_isKnown(idx)
	if S.game.debug and S.game.debug.no_fog_of_war then
		return true
	else
		return mapdata.known[idx] == 1
	end
end

local function map_setPassable(idx, value)
	-- store reverse for easier comparison later
	mapdata.noPass[idx] = not value
end

local function map_notPassable(idx)
	return mapdata.noPass[idx]
end

local function map_notPassLight(idx)
	return false
end

local map = {
	init = map_init
	, getTileId = map_getTileId
	, setTileId = map_setTileId
	, fixupTiles = map_fixupTiles
	, width = map_width
	, height = map_height
	, inside = map_inside

	, known = map_known
	, isKnown = map_isKnown
	, setPassable = map_setPassable
	, notPassable = map_notPassable
	, notPassLight = map_notPassLight
}

return map