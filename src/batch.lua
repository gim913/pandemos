-- imported modules
local map = require 'engine.map'
local elements = require 'engine.elements'

-- module

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
	tileSize = (900 / tc) - tileBorder --math.floor(800 / tc)
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
	batchData = love.graphics.newSpriteBatch(tilesetImage, tilesCount.x * tilesCount.y * 2)
end

local function batch_update(ent, cx, cy)
	local scale = tileSize / Tile_Real_Size
	batchData:clear()

	local xa = cx
	local ya = cy
	--print("==========" .. xa .. " / " .. ya)

	for y=0, tilesCount.y - 1 do
		-- this might happen when zooming out
		if ya + y > map.height() then
			break
		end

		-- relative
		local relativeIdx = (ya + y) * map.width() + xa
		for x=0, tilesCount.x - 1 do
			batchData:setColor(1.0, 1.0, 1.0)
			batchData:add(tileQuads[map.get(xa + x, ya + y)], x * (tileSize + tileBorder), y * (tileSize + tileBorder), 0, scale, scale)

			-- mind that these is accessing ONLY elements that are visible
			local e = elements.getTileId(relativeIdx)
			if e ~= nil then
				batchData:add(tileQuads[e], x * (tileSize + tileBorder), y * (tileSize + tileBorder), 0, scale, scale)
			end
			relativeIdx = relativeIdx + 1
		end
	end
end

local function batch_draw()
	love.graphics.draw(batchData, 0, 0)
end

local batch = {
	prepare = batch_prepare
	, update = batch_update
	, draw = batch_draw
	, recalc = batch_recalc
}

return batch