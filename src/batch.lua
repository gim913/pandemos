-- imported modules
local elements = require 'engine.elements'
local map = require 'engine.map'
local utils = require 'engine.utils'

-- module

local debug = {}
local batch_debug = utils.createGetterSetter(debug)

local tileSize = 30
local tilesCount = { x = 25, y = 25 }
local tileBorder = 1
local Tile_Real_Size = 32
local tileQuads = {}
local batchData = {}

local function prepare_tileset(filename)
	local d = love.image.newImageData(filename)
	return love.graphics.newImage(d)
end

local function batch_recalc(visRadius)
	local tc = 2 * visRadius + 1
	tileSize = (((30 + tileBorder) * 25) / tc) - tileBorder
	tilesCount.x = tc
	tilesCount.y = tc

	return tileSize
end

local function batch_prepare()
	local tilesetImage = prepare_tileset("tileset.png")
	print(tilesetImage)
	tilesetImage:setFilter("nearest", "linear")

	local tiw = tilesetImage:getWidth()
	local tih = tilesetImage:getHeight()
	local i = 0
	for y = 0,15 do
		for x = 0,15 do
			tileQuads[i] = love.graphics.newQuad(x * Tile_Real_Size, y * Tile_Real_Size, Tile_Real_Size, Tile_Real_Size, tiw, tih)
			i = i + 1
		end
	end

	-- * 2 cause we need to include elements and maybe later some other stuff
	batchData = love.graphics.newSpriteBatch(tilesetImage, (tilesCount.x + 2) * (tilesCount.y + 2) * 2)
end

local function loopMap(xa, ya, cb)
	for y = -1, tilesCount.y do
		if ya + y >= 0 and ya + y < map.height() then
			local idx = (ya + y) * map.width() + xa - 1
			for x = -1, tilesCount.x do
				if xa + x >= 0 and xa + x < map.width() then
					cb(idx, x, y)
				end
				idx = idx + 1
			end
		end
	end
end

local function batch_update(ent, cam)
	local xa, ya = cam.x, cam.y
	local scale = tileSize / Tile_Real_Size
	local tileSizeAdj = tileSize + tileBorder
	batchData:clear()

	batchData:setColor(1.0, 1.0, 1.0)
	loopMap(xa, ya, function(idx, x, y)
		if not debug.disableVismap then
			local vismap = ent.vismap
			if vismap[idx] and vismap[idx] > 0 then
				batchData:setColor(1.0, 1.0, 1.0)
			elseif map.isKnown(idx) then
				batchData:setColor(0.5, 0.5, 0.5)
			else
				batchData:setColor(0, 0, 0)
			end
		end

		--print('drawing tile ' .. (xa + x) ..",".. (ya + y) .. " at pos " .. x .. ",".. y)
		batchData:add(tileQuads[map.getTileId(xa + x, ya + y)], x * tileSizeAdj, y * tileSizeAdj, 0, scale, scale)

		-- mind that these is accessing ONLY elements that are visible
		local e = elements.getTileId(idx)
		if e ~= nil then
			batchData:add(tileQuads[e], x * tileSizeAdj, y * tileSizeAdj, 0, scale, scale)
		end
	end)
end

local function batch_draw()
	love.graphics.draw(batchData, 0, 0)
end

local batch = {
	prepare = batch_prepare
	, update = batch_update
	, draw = batch_draw
	, recalc = batch_recalc
	, debug = batch_debug
}

return batch