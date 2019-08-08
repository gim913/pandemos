-- module

local LoadedSounds = {}

local function soundManager_get(a, b)
	-- local name
	-- if b == nil then
	-- 	name = tostring(a)
	-- else
	-- 	name = tostring(a) .. '_' .. tostring(b)
	-- end

	-- if LoadedSounds[name] == nil then
	-- 	LoadedSounds[name] = love.audio.newSource(a, b)
	-- end

	return love.audio.newSource(a, b)
	--LoadedSounds[name]
end

local soundManager = {
	get = soundManager_get
}

return soundManager
