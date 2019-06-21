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
	return mapdata.data[y*mapdata.width + x]
end

local function map_width()
	return mapdata.width
end

local function map_height()
	return mapdata.height
end

local function map_inside(pos)
	return (pos.x>=0 and pos.x < mapdata.width and pos.y>=0 and pos.y < mapdata.height)
end

local function map_getData()
	return mapdata
end

local function map_known(idx)
	mapdata.known[idx] = 1
end

local function map_isKnown(idx)
	return true -- (mapdata.known[idx] == 1)
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
}

return map