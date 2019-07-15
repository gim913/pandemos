 --imported modules
local action = require 'engine.action'
local class = require 'engine.oop'
local console = require 'engine.console'
local Entity = require 'engine.Entity'

local Vec = require 'hump.vector'

-- class
local Infected = class('Infected', Entity)

Infected.Base_Speed = 1620
Infected.Bash_Speed = 720

function Infected:ctor(initPos)
	self.base.ctor(self, initPos)
end

function Infected:onAdd()
	self.name = 'Infected'
end

function Infected:analyze(player)
	if self.seemap[player] or (self.astar_path and self.astar_index < #self.astar_path) then
		if self.seemap[player] then
			local path, visited = self:findPath(player.pos)
			self.astar_path = path
			self.astar_visited = visited
			self.astar_index = 1
		else
			if self.astar_path[self.astar_index] == self.pos then
				self.astar_index = self.astar_index + 1
			end
		end

		if self.astar_path then
			local dir = self.astar_path[self.astar_index] - self.pos
			nextAct, nPos = self:wantGo(dir)
			console.log(action.name(nextAct))
			if nextAct ~= action.Action.Blocked then
				if nextAct == action.Action.Attack then
					--print(self.name .. 'queued action attack(0,0)')
					action.queue(self.actions, self.Bash_Speed, action.Action.Attack, nPos)
					self.actionState = action.Action.Processing
					return true
				else
					action.queue(self.actions, self.Base_Speed, action.Action.Move, nPos)
					self.actionState = action.Action.Processing
					return true
				end
			else
				-- action blocked
				-- idle
				action.queue(self.actions, 1000, action.Action.Move, self.pos)
			end
		else
			-- path towards player not found (maybe blocked by obstacles)
			-- idle
			action.queue(self.actions, 1000, action.Action.Move, self.pos)
		end
	else
		-- nothing to do
		-- idle
		action.queue(self.actions, 1000, action.Action.Move, self.pos)
	end

	return false
end

return Infected
