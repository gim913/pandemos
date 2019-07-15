-- imported modules
local bit = require 'bit'
local fontManager = require 'engine.fontManager'

-- module
local band, bor, bxor,bshl,bshr = bit.band, bit.bor, bit.bxor, bit.lshift, bit.rshift
local popups_canvas = nil

local popups_fonts = {}
local function popups_initialize(width, height)
	popups_canvas = love.graphics.newCanvas(width, height)
	for i=0,4 do
		popups_fonts[i] = fontManager.get(20 - i)
	end
end

local function popups_getCanvas()
	return popups_canvas
end

local data = 0x12345
local lfsr = {
	next = function()
		local o = band(bxor(bshl(bxor(bshl(bxor(bshl(data, 3), data), 1), data), 1), data), (0x7ffff))
        data = bor(bshl(data, 14), band(bshr(o, (19 - 14)), (0x3fff)))
		return o
	end
}

local popups_data = {}
local function popups_queue(entry)
	local idx = lfsr.next()
	entry.t = 0
	popups_data[idx] = entry
	return entry
end

local function popups_update(dt, viewPos, tileSize)
	local displayTime = 0.9

	love.graphics.setCanvas(popups_canvas)
		love.graphics.clear(0, 0, 0, 0)
		for k,p in pairs(popups_data) do
			if p.fading then
				if p.t < p.delay then
					p.t = p.t + dt
				elseif p.t < p.delay + displayTime then
					local perc = (p.t - p.delay) / displayTime
					local pos = (p.getWorldPos() - viewPos) * tileSize
					p.t = p.t + dt
					love.graphics.setFont(popups_fonts[math.floor(4 * perc)])
					love.graphics.setColor(1.0, perc, perc, 1 - perc / 3)
					local x = pos.x - (tileSize / 6) * math.sin(k + perc * 6)
					local y = pos.y - tileSize * perc
					love.graphics.print(p.txt, x, y)
				else
					popups_data[k] = nil
				end
			else
				local pos = (p.getWorldPos() - viewPos) * tileSize
				love.graphics.setFont(popups_fonts[0])
				love.graphics.setColor(192, 160, 128, 255)
				love.graphics.print(p.txt, pos.x, pos.y - tileSize / 2)
			end
		end
	love.graphics.setCanvas()
end

local popups = {
	 getCanvas = popups_getCanvas
	, queue = popups_queue
}

local function messages_initialize()
	popups_initialize()
end

local function messages_update(dt, viewPos, tileSize)
	popups_update(dt, viewPos, tileSize)
end

local messages = {
	initialize = messages_initialize
	, update = messages_update
	, popups = popups
}

return messages
