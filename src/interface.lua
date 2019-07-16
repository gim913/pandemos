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

function interface.begin(name, x, y)
	imgui.SetNextWindowPos(x, y, 'ImGuiCond_Always')
	imgui.Begin(name, true, { 'ImGuiWindowFlags_AlwaysAutoResize', 'ImGuiWindowFlags_NoMove' });
end

function interface.finish()
	imgui.End()
end


local function interface_drawEnt(ent, width, hovered)
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

function interface.drawPlayerInfo(ent, width)
	imgui.BeginGroup()
	imgui.BeginChild_2(1, width, Box_Height, true, "ImGuiWindowFlags_None");

	interface_drawEnt(ent, width)

	imgui.EndChild()
	imgui.EndGroup()
	return Box_Height
end

function interface.drawVisible(ents, width, height, isHovered)
	--imgui.ShowDemoWindow(true)

	imgui.BeginGroup()
	imgui.PushStyleColor('ImGuiCol_ScrollbarBg', 0.25,0.25,0.25, 1.0)
	imgui.PushStyleColor('ImGuiCol_ScrollbarGrab', 0.5,0.5,0.5, 1.0)
	imgui.PushStyleColor('ImGuiCol_ScrollbarGrabHovered', 0.7, 0.7, 0.7, 1.0)
	imgui.PushStyleColor('ImGuiCol_ScrollbarGrabActive', 0.97, 0.97, 0.97, 1.0)
	imgui.BeginChild_2(2, width, height, true, "ImGuiWindowFlags_None");

	local track_item = 33
	local sliderVal = 10
	for ent,_ in pairs(ents) do
		interface_drawEnt(ent, width, isHovered(ent))
	end

	imgui.EndChild()
	imgui.PopStyleColor(4);
	imgui.EndGroup()
end

return interface
