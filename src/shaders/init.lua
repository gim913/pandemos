local fog = require 'shaders.fog'
local blur = require 'shaders.blur'

local shaders = {}
shaders.__index = shaders

setmetatable(fog, shaders)
setmetatable(blur, shaders)

function shaders.foo()
	print('foo')
end

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
