-- imported modules
local Game = require 'Game'
local S = require 'settings'

local rng = nil
local game = nil

function love.load()
	love.keyboard.setKeyRepeat(true)

	love.window.setMode(S.resolution.x, S.resolution.y, { vsync=S.vsync })
	rng = love.math.newRandomGenerator()
	--rng = love.math.newRandomGenerator(love.timer.getTime())

	game = Game:new(rng)
	game:startLevel()
end

function love.wheelmoved(x, y)
	if game then
		game:handleWheel(x, y)
	end
end

local function handleInput(key)
	if key == "escape" then
		love.event.push("quit")
	end
	if game then
		game:handleInput(key)
	end
end

function love.keypressed(key)
	handleInput(key)
end

function love.update(dt)
	game:update(dt)
end

local function draw_info()
	love.graphics.setBlendMode('alpha')
	love.graphics.setColor(1.0, 1.0, 1.0, 1.0)

	local font = love.graphics.getFont()
	local msg = love.graphics.newText(font, "FPS: "..love.timer.getFPS())
	love.graphics.draw(msg, S.resolution.x - msg:getWidth() - 10, 10)
end

function love.draw()
	love.graphics.clear(0.25, 0.25, 0.25, 1.0)
	draw_info()
	game:show()
end
