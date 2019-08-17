-- imported modules
local batch = require 'batch'
local S = require 'settings'

local color = require 'engine.color'



-- remove
local utils = require 'engine.utils'

-- module
local renderer = {}

local renderer_canvasMap

function renderer.initialize(Tile_Size_Adj)
	local normalVis = 2 * S.game.VIS_RADIUS + 1
	-- allocate one cell more on every side
	local vis = normalVis + 2
	renderer_canvasMap = love.graphics.newCanvas(Tile_Size_Adj * vis, Tile_Size_Adj * vis)
end

function renderer.canvasMap()
	return renderer_canvasMap
end

local function drawItems(itemDescriptors)
	for _, desc in pairs(itemDescriptors) do
		local c = desc.color
		love.graphics.setColor(c[1], c[2], c[3], c[4])
		love.graphics.draw(desc.img, desc.position.x, desc.position.y, 0, desc.scale.x, desc.scale.y)
	end
end

function renderer.renderMap(Tile_Size_Adj, itemDescriptors)
	love.graphics.setCanvas(renderer_canvasMap)
	love.graphics.clear()

	love.graphics.push()
	-- start drawing whole map at 1,1 not at 0,0, to have 0th column and 0th row for scrolling purposes
	love.graphics.translate(Tile_Size_Adj, Tile_Size_Adj)

		love.graphics.setColor(color.white)
		batch.draw()
		drawItems(itemDescriptors)
		--drawEntities(camLu)

	love.graphics.pop()
end


return renderer
