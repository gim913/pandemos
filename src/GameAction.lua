local GameAction = {
	-- movement
	Up = 1
	, Down = 2
	, Left = 3
	, Right = 4
	, Rest = 5

	-- actions
	, Grab = 6
	, Drop = 7
	, Examine = 8
	, Throw = 9
	, Swap_Ground = 10
	, Swap_Equipment = 11

	, Equip1 = 21
	, Equip2 = 22
	, Equip3 = 23

	, Inventory1 = 31
	, Inventory2 = 32
	, Inventory3 = 33
	, Inventory4 = 34
	, Inventory5 = 35
	, Inventory6 = 36

	, Escape = 40
	, Toggle_Console = 41

	, Experimental_Camera_Switch = 51
	, Debug_Toggle_Vismap = 101
	, Debug_Toggle_Astar = 102
}

return GameAction
