return {
	resolution = { x = 1440, y=900 }
	, vsync = false
	, keyboard = {
		-- movement
		{ 'up', 'kp8' },
		{ 'down', 'kp2' },
		{ 'left', 'kp4' },
		{ 'right', 'kp6' },
		{ '.', 'kp5' }
	}

	-- not meant to be modified
	, game = {
		COLS = 128
		, ROWS = 1024
		, DEPTH = 1
		, VIS_RADIUS = 12
		, debug = {
			no_fog_of_war = false,
			show_astar_paths = false
		}
	}
}