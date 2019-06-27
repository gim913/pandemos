-- imported modules
local S = require 'settings'

-- module

local mapdata = {
	width = 0
	, height = 0
	, data = {}
	, known = {}
}

local function map_init(width, height)
	mapdata.width = width
	mapdata.height = height
	mapdata.data = {}
	mapdata.known = {}
end

local function map_get(x, y)
	local t = mapdata.data[y * mapdata.width + x]
	if t ~= nil then
		return t
	end

	return (x + y) % 2
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

local function map_getData()
	return mapdata
end

local function map_known(idx)
	mapdata.known[idx] = 1
end

local function map_isKnown(idx)
	if S.game.debug and S.game.debug.fog_of_war then
		return mapdata.known[idx] == 1
	else
		return true
	end
end

local function map_getBounded(f, x, y)
	if x < 0 or x >= mapdata.width or y < 0 or y >= mapdata.height then
		return 0
	end
	local i = y * mapdata.width + x
	if f(mapdata.data[i]) then
		return 1
	end
	return 0
end

-- calculate 8-bit code for a cell, based on neighbours
local function getCode(f, x,y)
	return
		map_getBounded(f,x-1,y-1) +
		map_getBounded(f,x  ,y-1)*2 +
		map_getBounded(f,x+1,y-1)*4 +
		map_getBounded(f,x-1,y  )*8 +
		map_getBounded(f,x+1,y  )*16 +
		map_getBounded(f,x-1,y+1)*32 +
		map_getBounded(f,x  ,y+1)*64 +
		map_getBounded(f,x+1,y+1)*128
end


local function map_fixup(y1, y2)
	-- magic code to tile mapping
	local mapping = {
		[0x0] = 0,
		[0x1] = 3,
		[0x3] = 9,
		[0x4] = 5,
		[0x6] = 9,
		[0x7] = 9,
		[0xf] = 8,
		[0x10] = 11,
		[0x14] = 11,
		[0x17] = 2,
		[0x20] = 1,
		[0x28] = 12,
		[0x29] = 12,
		[0x60] = 10,
		[0x68] = 6,
		[0x69] = 6,
		[0x80] = 7,
		[0x96] = 2,
		[0xd4] = 4,
		[0xc0] = 10,
		[0xd0] = 4,
		[0xe0] = 10,
		[0xe8] = 6,
		[0xe9] = 6,
		[0xf0] = 4
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

	local newMapData={}
	for y = 0, mapdata.height - 1 do
		for x = 0, mapdata.width - 1 do
			local i = y * mapdata.width + x
			if (mapdata.data[i] == y1) then
				local v = getCode(function(code) return code == y2 end, x, y)
				if mapping[v] ~= nil then
					newMapData[i] = y1 + mapping[v]
				else
					newMapData[i] = y1 --+ mapping[v]
				end
			else
				newMapData[i] = mapdata.data[i]
			end
		end
	end

	mapdata.data = newMapData
end

local map = {
	init = map_init
	, get = map_get
	, width = map_width
	, height = map_height
	, inside = map_inside
	, getData  = map_getData

	, known = map_known
	, isKnown = map_isKnown

	, fixup = map_fixup
}

return map