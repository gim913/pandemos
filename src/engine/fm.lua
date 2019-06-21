-- module

local LoadedFonts = {}

local function fontManager_get(name)
	if LoadedFonts[name] == nil then
		LoadedFonts[name] = love.graphics.newFont(name)
	end

	return LoadedFonts[name]
end

local fontManager = {
	get = fontManager_get
}

return fontManager
