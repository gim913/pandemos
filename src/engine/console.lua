-- imported modules
local fontManager = require 'engine.fontManager'

-- module
local console = {
	buffer = {}
}

-- semi-constants
local console_Width = 900
local console_Min_Height = 100
local console_Max_Height = 900
local console_canvas = nil

local function createCanvas()
	console_canvas = love.graphics.newCanvas(console_Width, console_Max_Height)
end
createCanvas()

local console_fontSize = 16
local console_lineHeight = 18
local console_transform = love.math.newTransform()

local console_needRefresh = true
local console_prevData = {}
local console_quad
local console_fontId = 1
local console_fonts = {
	-- 'fonts/anon.ttf',
	-- 'fonts/arimo.ttf',
	-- 'fonts/FSEX300.ttf',
	-- 'fonts/inconsolata.otf',
	-- 'fonts/mf.ttf',
	-- 'fonts/mfb.ttf',
	'fonts/scp.otf',
	-- 'fonts/tinos.ttf',
}
local console_font = fontManager.get(console_fonts[console_fontId], console_fontSize, 'light')

-- region console folding/unfolding

local ConsoleState = {
	Small = 0
	, Full = 1
	, Unfold = 2
	, Fold = 3
}
local console_state = ConsoleState.Small
local console_height = console_Min_Height

local simWorld = love.physics.newWorld(0, 0, true)
local conShape = love.physics.newCircleShape(1)
local conBody = nil
local conFixture = nil

local function createConBody()
	conBody = love.physics.newBody(simWorld, 0, console_height / console_Max_Height, 'dynamic')
	conFixture = love.physics.newFixture(conBody, conShape, 1)
	conFixture:setRestitution(0.0)
end

function console.initialize(width, minHeight, maxHeight)
	if console_Width ~= width or console_Min_Height ~= minHeight or console_Max_Height ~= maxHeight then
		console_Width = width
		console_Min_Height = minHeight
		console_Max_Height = maxHeight

		console_height = console_Min_Height
		createCanvas()
		createConBody()
	end
end

local debugStartTime = nil
function console.toggle()
	if ConsoleState.Small == console_state then
		console_state = ConsoleState.Unfold
		-- 3m / sec
		conBody:setLinearVelocity(0, 3)

		debugStartTime = love.timer.getTime()
	elseif ConsoleState.Full == console_state then
		console_state = ConsoleState.Fold
		-- 3m / sec
		conBody:setLinearVelocity(0, -3)

		debugStartTime = love.timer.getTime()
	end
end

local function debugTime()
	return math.floor((love.timer.getTime() - debugStartTime) * 1000)
end

function console.update(dt)
	if console_state >= ConsoleState.Unfold then
		simWorld:update(dt)
		_, py = conBody:getPosition()
		_, ay = conBody:getLinearVelocity()

		if ConsoleState.Unfold == console_state then
			if ay > 0.2 then
				conBody:applyForce(0, -0.017)
			else
				conBody:setLinearVelocity(0, 0.19)
			end

			console_height =  math.floor(py * console_Max_Height)
			if console_height > console_Max_Height then
				console_height = console_Max_Height
				console_state = ConsoleState.Full

				-- print(debugTime() .. " " .. ay)
			end
		elseif ConsoleState.Fold == console_state then
			if ay < -0.2 then
				conBody:applyForce(0, 0.017)
			else
				conBody:setLinearVelocity(0, -0.19)
			end

			console_height =  math.floor(py * console_Max_Height)
			if console_height < console_Min_Height then
				console_height = console_Min_Height
				console_state = ConsoleState.Small

				-- print(debugTime() .. " " .. ay)
			end
		end
	end
end

function console.height()
	return console_height
end

-- endregion

-- region console helper methods

function console.changeFontSize(deltaY)
	local newSize = math.max(12, math.min(48, console_fontSize + deltaY))
	if newSize ~= console_fontSize then
		console_fontSize = newSize
		console_lineHeight = newSize + 2
		console_font = fontManager.get(console_fonts[console_fontId], console_fontSize, 'light')
		console_needRefresh = true
	end
end

function console.nextFont()
	console_fontId = console_fontId + 1
	if console_fontId > #console_fonts then
		console_fontId = 1
	end

	console_font = fontManager.get(console_fonts[console_fontId], console_fontSize, 'light')
	console_needRefresh = true
	print(console_fonts[console_fontId] .. " " .. console_fontSize)
end

-- endregion

-- region main console methods

function console.log(a)
	if 100 == #console.buffer then
		table.remove(console.buffer, 1)
	end
	table.insert(console.buffer, a)
	console_needRefresh = true
end

local function console_refresh(coords)
	console_transform:reset()

	love.graphics.setCanvas(console_canvas)

	love.graphics.clear(0.1, 0.1, 0.1, 0.9)
	love.graphics.setFont(console_font)
	love.graphics.setColor(1.0, 1.0, 1.0, 1.0)

	local roundedPosY  = math.ceil(coords.y / console_lineHeight) * console_lineHeight
	console_transform:translate(coords.x, roundedPosY)

	local start = 1
	local spaceSkipped = roundedPosY - math.floor(coords.y)
	local spaceLeft = coords.height - spaceSkipped
	if #console.buffer > spaceLeft / console_lineHeight then
		start = #console.buffer - math.floor(spaceLeft / console_lineHeight) + 1
	end

	for lineNo = start, #console.buffer do
		local line = console.buffer[lineNo]

		-- local _, wrappedText = console_font:getWrap(line, coords.width)
		-- for _, linePart in pairs(wrappedText) do
		-- 	love.graphics.print(linePart, console_transform)
		-- 	console_transform:translate(0, 20)
		-- end

		-- do not wrap
		love.graphics.print(line, console_transform)
		console_transform:translate(0, console_lineHeight)
	end
	love.graphics.setCanvas()
end

function console.draw(x, y)
	if not console_needRefresh then
		if console_prevData.x ~= x or
				console_prevData.y ~= y or
				console_prevData.width ~= width or
				console_prevData.height ~= height then
			console_needRefresh = true
			--print('need refresh')
		end
	end

	if console_needRefresh then
		console_prevData = { x = x, y = y, width = console_Width, height = console_height }
		console_quad = love.graphics.newQuad(x, y, console_Width, console_height, console_Width, console_Max_Height)
		console_refresh(console_prevData)
		console_needRefresh = false
	end

	love.graphics.draw(console_canvas, console_quad, x, y)
end

-- endregion

return console