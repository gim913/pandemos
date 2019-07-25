-- imported modules
local color = require 'engine.color'
local console = require 'engine.console'
local fontManager = require 'engine.fontManager'

-- module
local hud = {}

local hud_lineHeight = 22
local hud_font = fontManager.get('fonts/scp.otf', 16, 'light')

imgui.AddFontFromFileTTF('fonts/scp.otf', 20)

local Box_Height = 66

function hud.begin(name, x, y)
	imgui.SetNextWindowPos(x, y, 'ImGuiCond_Always')

	imgui.PushStyleColor('ImGuiCol_ChildBg', 0, 0, 0, 0)
	imgui.PushStyleColor('ImGuiCol_WindowBg', 0, 0, 0, 0)

	imgui.PushStyleColor('ImGuiCol_Border', 0.439, 0.502, 0.565, 1)
	imgui.PushStyleColor('ImGuiCol_TitleBg', 0.25, 0.25, 0.25, 1.0)
	imgui.PushStyleColor('ImGuiCol_TitleBgHovered', 0.9, 0.9, 0.97, 1.0)
	imgui.PushStyleColor('ImGuiCol_TitleBgActive', 0.25, 0.25, 0.25, 1.0)

	imgui.PushStyleVar('ImGuiStyleVar_WindowBorderSize', 1)
	imgui.PushStyleVar_2('ImGuiStyleVar_FramePadding', 10, 3)
	imgui.PushStyleVar_2('ImGuiStyleVar_WindowPadding', 3, 3)
	imgui.PushStyleVar('ImGuiStyleVar_WindowRounding', 0)

	imgui.Begin(name, nil, {
		'ImGuiWindowFlags_AlwaysAutoResize',
		'ImGuiWindowFlags_NoMove',
		'ImGuiWindowFlags_NoCollapse'
	});
end

function hud.finish()
	imgui.End()
	imgui.PopStyleVar(4)
	imgui.PopStyleColor(6);
end


local hoveredUiEntId = nil

function hud.hoveredEntId()
	return hoveredUiEntId
end

local function hud_drawEnt(ent, width, displayHovered)
	imgui.PushID(ent.id)
	imgui.BeginGroup()

	imgui.Text(ent.name)
	imgui.SameLine(width - 80)
	imgui.Text("(" .. ent.id .. ")")

	local hpHue = 1.0 - 10 * ent.hp / ent.maxHp / 24.0
	local hpWidth = ent.hp / ent.maxHp
	local r,g,b,a = color.hsvToRgb(hpHue, 0.7, 0.7, 1.0)

	if displayHovered or hoveredUiEntId == ent.id then
		imgui.SetScrollHere(1 * 0.25)
		r,g,b,a = color.hsvToRgb(hpHue, 0.3, 0.7, 1.0)
	end

	imgui.PushStyleColor('ImGuiCol_PlotHistogram', r, g, b, a)
	imgui.ProgressBar(hpWidth, width, 16, '')
	imgui.PopStyleColor(1);
	imgui.EndGroup()

	-- this will work with a delay, but it shouldn't matter much
	if imgui.IsItemHovered() then
		hoveredUiEntId = ent.id
	elseif hoveredUiEntId == ent.id then
		hoveredUiEntId = nil
	end

	imgui.PopID()
end

function hud.drawPlayerInfo(ent, width, isMouseHovered)
	imgui.BeginGroup()

	if isMouseHovered(ent) or hoveredUiEntId == ent.id then
		imgui.PushStyleColor('ImGuiCol_Border', 0.4, 0.85, 0.4, 1)
		imgui.PushStyleColor('ImGuiCol_Text', 0.4, 0.85, 0.4, 1)
	else
		imgui.PushStyleColor('ImGuiCol_Border', 1, 1, 1, 1)
		imgui.PushStyleColor('ImGuiCol_Text', 1, 1, 1, 1)
	end
	imgui.PushStyleVar_2('ImGuiStyleVar_FramePadding', 10, 10)

	imgui.BeginChild_2(10001, width, Box_Height, true, 'ImGuiWindowFlags_None');
	hud_drawEnt(ent, width, isMouseHovered(ent))
	imgui.EndChild()

	imgui.PopStyleVar(1);
	imgui.PopStyleColor(2);
	imgui.EndGroup()

	imgui.Spacing()
	imgui.Separator()
	imgui.Separator()
	imgui.Spacing()

	return Box_Height
end

function hud.drawVisible(ents, width, height, isMouseHovered)
	imgui.BeginGroup()

	imgui.PushStyleColor('ImGuiCol_ScrollbarBg', 0.25,0.25,0.25, 1.0)
	imgui.PushStyleColor('ImGuiCol_ScrollbarGrab', 0.5,0.5,0.5, 1.0)
	imgui.PushStyleColor('ImGuiCol_ScrollbarGrabHovered', 0.7, 0.7, 0.7, 1.0)
	imgui.PushStyleColor('ImGuiCol_ScrollbarGrabActive', 0.97, 0.97, 0.97, 1.0)

	imgui.PushStyleVar('ImGuiStyleVar_WindowBorderSize', 1)
	imgui.PushStyleVar_2('ImGuiStyleVar_FramePadding', 3, 3)
	imgui.PushStyleVar_2('ImGuiStyleVar_WindowPadding', 3, 3)
	imgui.PushStyleVar('ImGuiStyleVar_WindowRounding', 0)

	imgui.BeginChild_2(10002, width, height, false, "ImGuiWindowFlags_None");

	local track_item = 33
	local sliderVal = 10
	for ent,_ in pairs(ents) do
		if isMouseHovered(ent) or hoveredUiEntId == ent.id then
			imgui.PushStyleColor('ImGuiCol_Separator', 0.4, 0.85, 0.4, 1)
			imgui.PushStyleColor('ImGuiCol_Border', 0.4, 0.85, 0.4, 1)
			imgui.PushStyleColor('ImGuiCol_Text', 0.4, 0.85, 0.4, 1)
		else
			imgui.PushStyleColor('ImGuiCol_Separator', 0.439, 0.502, 0.565, 1)
			imgui.PushStyleColor('ImGuiCol_Border', 1, 1, 1, 1)
			imgui.PushStyleColor('ImGuiCol_Text', 1, 1, 1, 1)
		end

		hud_drawEnt(ent, width, isMouseHovered(ent))
		imgui.Separator()

		if isMouseHovered(ent) or hoveredUiEntId == ent.id then
			imgui.PopStyleColor(7);
		end
	end

	imgui.EndChild()
	imgui.PopStyleVar(4);
	imgui.PopStyleColor(4);
	imgui.EndGroup()
end

return hud
