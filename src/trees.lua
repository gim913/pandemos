-- module

local PI = math.pi

local trees = {
	{ name="Oak {Quercus robur}",               h={20,40,50}, s=9.85/PI, c=20 },
	{ name="Ash {Fraxinus excelsior}",          h={25,35,35}, s=6.16/PI, c=20 },
	{ name="Beech {Fagus sylvatica}",           h={25,30,45}, s=6.78/PI, c=30 },
	{ name="Elm {Ulmus glabra}",                h={20,40,40}, s=4.3/PI, c=12  },
	{ name="Scots Pine {Pinus sylvestris}",     h={28,32,40}, s=3.8/PI, c=30 },
	{ name="Small-leaved Lime {Tilia cordata}", h={20,30,37}, s=5/PI, c=20 },
	{ name="Black Alder {Alnus glutinosa}",     h={20,37,40}, s=3/PI, c=30 },
	{ name="Norway maple {Acer platanoides}",   h={20,30,37}, s=4.16/PI, c=15 }
}

return trees
