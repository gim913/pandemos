-- module

local LoadedFonts = {}

local function fontManager_get(a, b, c)
	local name
	if c == nil then
		if b == nil then
			name = tostring(a)
		else
			name = tostring(a) .. '_' .. tostring(b)
		end
	else
		-- no need for tostring() here
		name = a .. '_' .. tostring(b) .. '_'.. c
	end

	if LoadedFonts[name] == nil then
		LoadedFonts[name] = love.graphics.newFont(a, b, c)
		print(LoadedFonts[name])
	end

	return LoadedFonts[name]
end

local fontManager = {
	get = fontManager_get
}

return fontManager
