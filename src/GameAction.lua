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
	, Equip_or_Swap = 11

	, Equip1 = 21
	, Equip2 = 22
	, Equip3 = 23

	, Inventory1 = 31
	, Inventory2 = 32
	, Inventory3 = 33
	, Inventory4 = 34
	, Inventory5 = 35
	, Inventory6 = 36

	, Confirm = 40
	, Escape = 41
	, Close_Modal = 42
	, Toggle_Console = 43

	, Experimental_Camera_Switch = 51
	, Debug_Toggle_Vismap = 101
	, Debug_Toggle_Astar = 102

	, Toggle_Window_Size = 201
}

return GameAction
