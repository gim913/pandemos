-- imported modules
require "imgui"

local Game = require 'Game'
local MainMenu = require 'MainMenu'
local S = require 'settings'

local gamestate = require 'hump.gamestate'

local game = nil
local mainMenu = nil

function love.load()
	love.keyboard.setKeyRepeat(true)
	love.window.setMode(S.resolution.x, S.resolution.y, { vsync=S.vsync })
	love.window.setTitle("Pandemos")

	-- create objects
	mainMenu = MainMenu:new()

	gamestate.registerEvents()
	gamestate.switch(mainMenu)

	-- -- TODO: XXX: TODO: devel: skip menu
	mainMenu:keypressed('return')
end

local defaultFont = love.graphics.getFont()

function love.update(dt)
	imgui.NewFrame()
end

local function draw_info()
	love.graphics.setBlendMode('alpha')
	love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
	love.graphics.setFont(defaultFont)
	love.graphics.print("FPS: "..love.timer.getFPS(), S.resolution.x - 100, 10)
end

function love.draw()
	love.graphics.clear(0.25, 0.25, 0.25, 1.0)
	draw_info()
end



function love.quit()
    imgui.ShutDown();
end


function love.textinput(t)
    imgui.TextInput(t)
    if not imgui.GetWantCaptureKeyboard() then
        -- Pass event to the game
    end
end

function love.keypressed(key)
    imgui.KeyPressed(key)
    if not imgui.GetWantCaptureKeyboard() then
        -- Pass event to the game
    end
end

function love.keyreleased(key)
    imgui.KeyReleased(key)
    if not imgui.GetWantCaptureKeyboard() then
        -- Pass event to the game
    end
end

function love.mousemoved(x, y)
    imgui.MouseMoved(x, y)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end

function love.mousepressed(x, y, button)
    imgui.MousePressed(button)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end

function love.mousereleased(x, y, button)
    imgui.MouseReleased(button)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end

function love.wheelmoved(x, y)
    imgui.WheelMoved(y)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end
