local fog = require 'shaders.fog'
local blur = require 'shaders.blur'

local shaders = {}
shaders.__index = shaders

setmetatable(fog, shaders)
setmetatable(blur, shaders)

function shaders.fog()
	local instance = {}
	fog.ctor(instance)
	setmetatable(instance, { __index = fog })
	return instance
end

function shaders.blur()
	local instance = {}
	fog.ctor(instance)
	setmetatable(instance, { __index = blur })
	return instance
end

function shaders.renderShader(shader, canvas, func)
	local prevShader = love.graphics.getShader()
	local prevCanvas = love.graphics.getCanvas()
	love.graphics.setCanvas(canvas)
	love.graphics.clear()

	-- draw to canvas
	func()

	-- apply shader
	love.graphics.setCanvas(prevCanvas)
	love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
	love.graphics.setShader(shader)
	local b = love.graphics.getBlendMode()
	love.graphics.setBlendMode('alpha', 'premultiplied')
	love.graphics.draw(canvas, 0, 0)
	love.graphics.setBlendMode(b)
	love.graphics.setShader(prevShader)
end

return shaders
