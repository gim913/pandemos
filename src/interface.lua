-- imported modules
local color = require 'engine.color'
local console = require 'engine.console'
local fontManager = require 'engine.fontManager'

-- module
local interface = {}

local interface_lineHeight = 22
local interface_font = fontManager.get('fonts/scp.otf', 16, 'light')

imgui.AddFontFromFileTTF('fonts/scp.otf', 20)

local Box_Height = 66

function interface.begin(x, y)
	imgui.SetNextWindowPos(x, y, "ImGuiCond_FirstUseEver")
	imgui.Begin("Entities", true, { "ImGuiWindowFlags_AlwaysAutoResize" });
end

function interface.finish()
	imgui.End()
end


local function interface_drawEnt(ent, x, y, width, height, hovered)
	-- love.graphics.rectangle('line', x, y, width, height)

	-- local curX = x + 2
	-- local curY = y + 2
	-- local maxW = width - 4
	-- love.graphics.setFont(interface_font)
	-- love.graphics.print(ent.name, curX, curY)
	-- love.graphics.print(tostring(ent.id), x + maxW - 20, curY)

	-- curY = curY + interface_lineHeight

	-- -- goes from blu-ish to red
	-- local hpHue = 1.0 - 10 * ent.hp / ent.maxHp / 24.0
	-- local hpWidth = math.ceil((maxW * ent.hp) / ent.maxHp)

	-- love.graphics.setColor(color.hsvToRgb(hpHue, 0.7, 0.7, 1.0))
	-- love.graphics.rectangle('fill', curX, curY, hpWidth, 14)

	-- curY = curY + 16

	if hovered then
		imgui.TextColored(0.3, 0.9, 0.3, 1, ent.name)
		imgui.SetScrollHere(1 * 0.25)
		imgui.SameLine(width - 80)
		imgui.Text(ent.id)

	else
		imgui.Text(ent.name)
		imgui.SameLine(width - 80)
		imgui.Text(ent.id)
	end

	local hpHue = 1.0 - 10 * ent.hp / ent.maxHp / 24.0
	local hpWidth = ent.hp / ent.maxHp
	local r,g,b,a = color.hsvToRgb(hpHue, 0.7, 0.7, 1.0)

	imgui.PushID(ent.id);
	imgui.PushStyleColor('ImGuiCol_FrameBg', 0.3,0.3,0.3, 1.0)
	imgui.PushStyleColor('ImGuiCol_PlotHistogram', r,g,b,a)
	imgui.ProgressBar(hpWidth, width, 16, '')
	imgui.PopStyleColor(1);
	imgui.PopID();
end

function interface.drawPlayerInfo(ent, x, y, width)
	-- love.graphics.setColor(1, 1, 1, 1)
	-- love.graphics.setLineWidth(1)
	-- love.graphics.setLineStyle('rough')

	-- love.graphics.rectangle('line', x, y, width, Box_Height)
	-- local innerX = x + 2
	-- local innerY = y + 2

	imgui.BeginGroup()
	imgui.BeginChild_2(1, width, Box_Height, true, "ImGuiWindowFlags_None");

	interface_drawEnt(ent, innerX, innerY, width - 4, Box_Height - 4)

	imgui.EndChild()
	imgui.EndGroup()
	return Box_Height
end

function interface.drawVisible(ents, x, y, width, isHovered)
	-- local innerX = x + 2
	-- local innerY = y + 2

	-- local visibleEnts = {}
	-- local hovered = 0
	-- local id = 1
	-- for ent, _ in pairs(ents) do
	-- 	table.insert(visibleEnts, ent)
	-- 	if isHovered(ent) then
	-- 		hovered = id
	-- 	end
	-- 	id = id + 1
	-- end

	-- local start
	-- if #visibleEnts > 5 then
	-- 	start = math.max(1, math.min(hovered - 1, #visibleEnts - 5))
	-- end

	-- for index = start, start + 5 do
	-- 	local ent = visibleEnts[index]
	-- 	--print(index .. tostring(ent))
	-- 	if isHovered(ent) then
	-- 		love.graphics.setColor(color.white)
	-- 	else
	-- 		love.graphics.setColor(color.slategray)
	-- 	end
	-- 	interface_drawEnt(ent, innerX, innerY, width - 4, Box_Height - 4)
	-- 	innerY = innerY + Box_Height - 2
	-- end

	-- love.graphics.setColor(color.slategray)
	-- love.graphics.rectangle('line', x, y, width, innerY - y)

	--imgui.ShowDemoWindow(true)


	imgui.BeginGroup()
	imgui.PushStyleColor('ImGuiCol_ScrollbarBg', 0.25,0.25,0.25, 1.0)
	imgui.PushStyleColor('ImGuiCol_ScrollbarGrab', 0.5,0.5,0.5, 1.0)
	imgui.PushStyleColor('ImGuiCol_ScrollbarGrabHovered', 0.7, 0.7, 0.7, 1.0)
	imgui.PushStyleColor('ImGuiCol_ScrollbarGrabActive', 0.97, 0.97, 0.97, 1.0)
	imgui.BeginChild_2(2, width, 200, true, "ImGuiWindowFlags_None");

	local track_item = 33
	local sliderVal = 10
	for ent,_ in pairs(ents) do
		interface_drawEnt(ent, 0, 0, width, 0, isHovered(ent))
	end

	imgui.EndChild()
	imgui.PopStyleColor(4);
	imgui.EndGroup()
end

return interface
