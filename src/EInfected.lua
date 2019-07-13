 --imported modules
local action = require 'engine.action'
local class = require 'engine.oop'
local console = require 'engine.console'
local Entity = require 'engine.Entity'

local Vec = require 'hump.vector'

-- class
local Infected = class('Infected', Entity)

function Infected:analyze(player)
	if self.seemap[player] then
		local path, visited = self:findPath(player.pos)
		self.astar_path = path
		self.astar_visited = visited

		if path then
			local dir = path[1] - self.pos
			nextAct, nPos = self:wantGo(dir)
			if nextAct ~= action.Action.Blocked then
				if nextAct == action.Action.Attack then
					print(self.name .. 'queued action move(0,0)')
					action.queue(self.actions, 1700, action.Action.Move, self.pos)
					self.actionState = action.Action.Processing
					return true
				else
					print(self.name .. 'queued action move')
					action.queue(self.actions, 1700, action.Action.Move, nPos)
					self.actionState = action.Action.Processing
					return true
				end
			else

			end
		end
	else
		-- idle
		action.queue(self.actions, 1000, action.Action.Move, self.pos)
	end

	return false
end

return Infected
