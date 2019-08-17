return {
	resolution = { x = 1440, y=900 }
	, vsync = false
	, disable_movement_animation = true
	-- throw, etc
	, disable_action_animation = false
	, animation_time = 0.15

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