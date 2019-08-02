local fog = require 'shaders.fog'
local blur = require 'shaders.blur'

local shaders = {}
setmetatable(fog, shaders)

function shaders.fog()
	local instance = {}
	fog.ctor(instance)
	setmetatable(instance, { __index = fog })
	return instance
end

function shaders.blur()
	local instance = {}
	fog.ctor(instance)
	setmetatable(instance, { __index = blur })
	return instance
end

return shaders
