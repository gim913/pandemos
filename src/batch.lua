-- imported modules
local map = require 'engine.map'

-- module

local tileSize = 30
local tilesCount = { x = 25, y = 25 }
local Tile_Real_Size = 32
local tileQuads = {}
local batchData = {}

local function prepare_tileset(filename)
	local d = love.image.newImageData(filename)
	return love.graphics.newImage(d)
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
		for x=0, tilesCount.x - 1 do
			batchData:setColor(1.0, 1.0, 1.0)
			batchData:add(tileQuads[map.get(xa + x, ya + y)], x * (tileSize + 1), y * (tileSize + 1), 0, scale, scale)
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
}

return batch