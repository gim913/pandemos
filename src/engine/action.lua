local Action = {
	Invalid = 0
	, Idle = 1
	, Blocked = 2
	, Move = 3
	, Attack = 4
}

local Action_rev = nil

local function action_queue(tbl, time_needed, id, val)
	local t = { time = time_needed, state = id, val = val }
	tbl[#tbl + 1] = t
end

local function action_name(state)
	if nil == Action_rev then
		Action_rev = {}
		for k,e in pairs(Action) do
			Action_rev[e] = k
		end
	end
	return Action_rev[state]
end

return {
	queue = action_queue
	, name = action_name
	, Action = Action
}
