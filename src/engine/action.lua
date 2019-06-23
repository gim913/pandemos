local Action = {
	Invalid = 0
	, Blocked = 1
	, Move = 2
	, Attack = 3
}

local Action_rev = nil

function action_queue(tbl, time_needed, id, val)
	local t = { time=time_needed, state=id, val=val }
	tbl[#tbl + 1] = t
end

function action_name(state)
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
