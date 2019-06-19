local S = require 'settings'

function love.load()
	love.window.setMode(S.resolution.x, S.resolution.y, { vsync=false })
end

local function handleInput(key)
	if key == "escape" then
		love.event.push("quit")
	end
end

function love.keypressed(key)
	handleInput(key)
end

function love.update(dt)
end

function love.draw()
end
