-- imported modules
local batch = require 'batch'
local S = require 'settings'

local shaders = require 'shaders'

local color = require 'engine.color'

-- remove
local utils = require 'engine.utils'

-- module
local renderer = {}

local renderer_canvasMap
local renderer_fog
local renderer_blur

function renderer.initialize(Tile_Size_Adj)
	local normalVis = 2 * S.game.VIS_RADIUS + 1
	-- allocate one cell more on every side
	local vis = normalVis + 2
	renderer_canvasMap = love.graphics.newCanvas(Tile_Size_Adj * vis, Tile_Size_Adj * vis)

	renderer_fog = shaders.fog()
	renderer_blur = shaders.blur()
end

local renderer_shaderDt = 0
local renderer_shaderTotalDt = 0

function renderer.update(dt)
	renderer_shaderDt = renderer_shaderDt + dt
	renderer_shaderTotalDt = renderer_shaderTotalDt + dt
	if renderer_shaderDt > 1 / 60.0 then
		renderer_fog:set('time', renderer_shaderTotalDt)
		renderer_shaderDt = renderer_shaderDt - 1 / 60.0
	end
end

function renderer.canvasMap()
	return renderer_canvasMap
end

local Tile_Size_Adj
function renderer.initFrame(tileSizeAdj)
	Tile_Size_Adj = tileSizeAdj
end

local function drawDescriptors(itemDescriptors)
	for _, desc in pairs(itemDescriptors) do
		local c = desc.color
		love.graphics.setColor(c[1], c[2], c[3], c[4])
		love.graphics.draw(desc.img, desc.position.x, desc.position.y, 0, desc.scale.x, desc.scale.y)
	end
end

function renderer.renderMap(descriptors)
	love.graphics.setCanvas(renderer_canvasMap)
	love.graphics.clear()

	love.graphics.push()
	-- start drawing whole map at 1,1 not at 0,0, to have 0th column and 0th row for scrolling purposes
	love.graphics.translate(Tile_Size_Adj, Tile_Size_Adj)

		love.graphics.setColor(color.white)
		batch.draw()
		drawDescriptors(descriptors)

	love.graphics.pop()
end

local function drawRectangles(descriptors)
	for _, desc in pairs(descriptors) do
		love.graphics.setColor(desc.color)
		love.graphics.rectangle('fill', desc.position.x, desc.position.y, Tile_Size_Adj, Tile_Size_Adj)
	end
end

function renderer.renderGases(descriptors)
	renderer_fog:render(function()
		renderer_blur:render(function()
			love.graphics.translate(Tile_Size_Adj, Tile_Size_Adj)
			drawRectangles(descriptors)
			love.graphics.translate(-Tile_Size_Adj, -Tile_Size_Adj)
		end)
	end)
end

return renderer
