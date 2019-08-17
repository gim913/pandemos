-- imported modules
local letters = require 'letters'
local elements = require 'engine.elements'

local Vec = require 'hump.vector'

-- module
local items = {}

function items.prepareDraw(locationId, x, y, Tile_Size_Adj, scaleFactor)
	local items, itemCount = elements.getItems(locationId)
	if itemCount > 0 then
		local firstItemIndex = next(items)
		local itemImg = letters.get(items[firstItemIndex].desc.blueprint.symbol)
		if itemImg == nil then
			print('symbol: "' .. items[firstItemIndex].desc.blueprint.symbol .. '" is not loaded via letters.prepare()')
		end

		local item = items[firstItemIndex]
		local position = Vec(x * Tile_Size_Adj, y * Tile_Size_Adj)
		if item.anim then
			position = position + item.anim
		end

		return {
			color = items[firstItemIndex].desc.blueprint.color
			, img = itemImg
			, position = position
			, scale = Vec(scaleFactor, scaleFactor)
		}
	end
end

return items
