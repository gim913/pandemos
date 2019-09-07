local components = {}

local components_all = {}

function components.register(component)
	table.insert(components_all, component)
	component.uid = #components_all

	print('registered component ' .. component.name .. '/' .. component.uid)
end

return components
