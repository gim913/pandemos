-- imported modules
local color = require 'engine.color'
local console = require 'engine.console'

-- module
local interface = {}

local interface_lineHeight = 22
local interface_font = love.graphics.newFont('fonts/scp.otf', 16, 'light')

local Box_Height = 66

local function interface_drawEnt(ent, x, y, width, height)
	love.graphics.rectangle('line', x, y, width, height)

	local curX = x + 2
	local curY = y + 2
	local maxW = width - 4
	love.graphics.setFont(interface_font)
	love.graphics.print(ent.name, curX, curY)
	love.graphics.print(tostring(ent.id), x + maxW - 20, curY)

	curY = curY + interface_lineHeight

	-- goes from blu-ish to red
	local hpHue = 1.0 - 10 * ent.hp / ent.maxHp / 24.0
	local hpWidth = math.ceil((maxW * ent.hp) / ent.maxHp)

	love.graphics.setColor(color.hsvToRgb(hpHue, 0.7, 0.7, 1.0))
	love.graphics.rectangle('fill', curX, curY, hpWidth, 14)

	curY = curY + 16
end

function interface.drawPlayerInfo(ent, x, y, width)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setLineWidth(1)
	love.graphics.setLineStyle('rough')

	love.graphics.rectangle('line', x, y, width, Box_Height)
	local innerX = x + 2
	local innerY = y + 2

	interface_drawEnt(ent, innerX, innerY, width - 4, Box_Height - 4)
	return Box_Height
end

function interface.drawVisible(ents, x, y, width, isHovered)
	local innerX = x + 2
	local innerY = y + 2
	for ent, _ in pairs(ents) do
		if isHovered(ent) then
			love.graphics.setColor(color.white)
		else
			love.graphics.setColor(color.slategray)
		end
		interface_drawEnt(ent, innerX, innerY, width - 4, Box_Height - 4)
		innerY = innerY + Box_Height - 2
	end

	love.graphics.setColor(color.slategray)
	love.graphics.rectangle('line', x, y, width, innerY - y)
end

return interface
