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
		local dir = (player.pos - self.pos):normalizeInplace()

		-- todo, might result in dual
		local dx, dy = math.floor(dir.x + 0.5), math.floor(dir.y + 0.5)
		if dx ~= 0 and dy ~= 0 then
			dx = 0
		end

		if dx == 0 and dy == 0 then
			dx = 1
		end

		nextAct, nPos = self:wantGo(Vec(dx, dy))
		if nextAct ~= action.Action.Blocked then
			if nextAct == action.Action.Attack then
			else
				action.queue(self.actions, 1000, action.Action.Move, nPos)
				self.actionState = action.Action.Processing
				return true
			end
		else

		end
	end

	return false
end

return Infected
