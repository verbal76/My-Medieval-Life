extends SceneTree
func _init() -> void:
	GameData.ensure()
	var args := OS.get_cmdline_user_args()
	var w := World.new()
	w.setup(VillageMap.load_default(), int(args[0]))
	var ow: Overworld = w.map.overworld
	for a in args.slice(1):
		var xy := a.split(",")
		var c := Vector2i(int(xy[0]), int(xy[1]))
		print("== ", c)
		for y in range(c.y - 9, c.y + 10):
			var s := ""
			for x in range(c.x - 24, c.x + 25):
				var q := Vector2i(x, y)
				s += "@" if q == c else ("B" if ow.is_bridge(q) else ("f" if ow.is_ford(q) else ("~" if ow.is_water(q) else ("=" if RoadWear.is_way(ow, q) else "."))))
			print(s)
	quit()
