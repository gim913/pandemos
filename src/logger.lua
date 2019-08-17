-- imported modules
local color = require 'engine.color'

-- module

local logger = {}

function logger.logItems(items, itemCount)
	local messages = {}
	if 1 == itemCount then
		messages = {
			{ 1, 1, 1, 1 }, 'There is ',
			color.crimson, items[next(items)].desc.blueprint.name,
			{ 1, 1, 1, 1 }, ' lying there'
		}
	else
		table.insert(messages, color.white)
		table.insert(messages, 'There are multiple items lying here: ')
		local skipFirst = true
		for k, item in pairs(items) do
			if not skipFirst then
				table.insert(messages, color.white)
				table.insert(messages, ', ')
			end
			table.insert(messages, color.crimson)
			table.insert(messages, item.desc.blueprint.name)

			skipFirst = false
		end
	end

	return messages
end

return logger
