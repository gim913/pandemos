-- module

local astar_Big = 2000000000

local function astar_bestOpen(open, fScore)
	local min = astar_Big
	local minNode = nil
	local minId = -1
	for id, node in pairs(open) do
		-- if fScore[id] == min then
		-- 	print('got dup ' .. tostring(node) .. ' vs ' .. tostring(minNode))
		-- end
		if fScore[id] < min then
			min = fScore[id]
			minId = id
			minNode = node
		end
	end

	return minNode, minId, min
end

local function getGScore(gScore, node)
	return gScore[node] or astar_Big
end

local function astar_construct(cameFrom, node, nodeId)
	local path = {}
	while cameFrom[nodeId] do
		local t = cameFrom[nodeId]
		node = t.node
		nodeId = t.id
		table.insert(path, node)
	end

	return table.reverse(path)
end

-- handlers:
--  + heuristic(node1, destination)
--  + neigbors(source, node1)
--  + cost(node1, node2)
local function astar(source, destination, handlers)
	local open = {}
	local openCount = 0
	local closed = {}
	local gScore = {}
	local fScore = {}
	local cameFrom = {}

	local toId = handlers.toId
	local dId = toId(destination)

	open[toId(source)] = source
	openCount = openCount + 1

	gScore[toId(source)] = 0
	fScore[toId(source)] = handlers.heuristic(source, destination)


	-- pick best node
	while openCount > 0 do
		local current, cId = astar_bestOpen(open, fScore)
		--print('  bestOpen ' .. tostring(current) .. " " .. cId)
		open[cId] = nil
		openCount = openCount - 1
		closed[cId] = current

		--print(tostring(current) .. ' removed from open, added to closed ' .. tostring(closed[cId]))
		if cId == dId then
			return astar_construct(cameFrom, current, cId)
		end

		for _, neighbor in pairs(handlers.neighbors(source, current)) do
			nId = toId(neighbor)
			--print('  checking ' .. tostring(neighbor) .. " " .. tostring(closed[nId]))
			if closed[nId] == nil then
				temp_gScore = gScore[cId] + handlers.cost(current, neighbor)
				if temp_gScore < getGScore(gScore, neighbor) then
					cameFrom[nId] = { node = neighbor, id = cId }
					gScore[nId] = temp_gScore
					fScore[nId] = gScore[nId] + handlers.heuristic(neighbor, destination)

					if open[nId] == nil then
						open[nId] = neighbor
						--print('  ' .. tostring(neighbor) .. ' added to open')
						openCount = openCount + 1
					end
				end
			end
		end
	end

	return nil, closed
end

return astar
