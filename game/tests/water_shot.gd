extends SceneTree
## B25R1-Q3: screenshots of the streams in the world beside the player at normal zoom, to look at (CLAUDE.md: visual output is
## looked at before it is reported). Needs a display (not --headless):
##   xvfb-run -a godot --rendering-driver opengl3 --path game --resolution 1280x720 --script res://tests/water_shot.gd -- OUT_DIR [SHOT,...]
## Shots (all by default, or those named): ford (the Upmeads Ford, B25R1-018), stone_bridge (the fair bridge), plank_bridge
## (a wooden bridge where a road crosses a stream), waterfall (a fall over a cliff's rim into its pool), river (a bend of
## Upmeads Water), map (the Region map with the streams). Targets come from the layout's crossings and the courses, so no
## wide chunk scan is needed (a few chunks each).

var main
var out := "/tmp"
var only: Array = []
var frames := 0
var queue: Array = []
var current := ""


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.size() > 1:
		only = Array(args[1].split(","))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _want(name: String) -> bool:
	return only.is_empty() or only.has(name)


## A road cell beside `at` that is dry land (where the player stands to look at a crossing), else `at`.
func _stand(ow: Overworld, at: Vector2i) -> Vector2i:
	for r in range(1, 10):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var c := at + Vector2i(dx, dy)
				if ow.is_road(c) and not ow.is_bridge(c) and not ow.is_water(c) and not ow.is_solid(c):
					return c
	return at


func _setup() -> void:
	main.save_path = "user://test_saves/water_shot/save1.json"
	main.new_game()
	main.ui.hide_all()
	var w: World = main.world
	w.player.hunger = 100.0
	var ow: Overworld = w.map.overworld
	var plank := Vector2i.ZERO
	for f in ow._forced:
		var at := Vector2i((f[0] as Vector2).floor())
		if str(f[2]) == "ford" and _want("ford") and not queue.any(func(q): return q[0] == "ford"):
			queue.append(["ford", Vector2(_stand(ow, at)) + Vector2(0.5, 0.5)])
		elif str(f[2]) == "stone_bridge" and _want("stone_bridge") and not queue.any(func(q): return q[0] == "stone_bridge"):
			queue.append(["stone_bridge", Vector2(_stand(ow, at)) + Vector2(0.5, 0.5)])
	if _want("plank_bridge") or _want("map"):
		var c0 := Overworld.chunk_of(ow.village.get_center())
		for r in range(1, 9):
			if plank != Vector2i.ZERO:
				break
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					var cc := c0 + Vector2i(dx, dy)
					if maxi(absi(dx), absi(dy)) != r or ow.chunk_in_village(cc) or plank != Vector2i.ZERO:
						continue
					var ch := ow.get_chunk(cc)
					for i in 1024:
						var c := cc * 32 + Vector2i(i % 32, i / 32)
						if ch.water[i] == 2 and ow.forced_crossing(c) == "" and not RoadWear.visual(ow, c).begins_with("stone"):
							plank = c
							break
		if plank != Vector2i.ZERO and _want("plank_bridge"):
			queue.append(["plank_bridge", Vector2(_stand(ow, plank)) + Vector2(0.5, 0.5)])
	if _want("waterfall"):
		var fall := Overworld.NO_WATER
		for crs in ow.streams_in(Rect2i(-700, -450, 1400, 1600)):
			var pts: Array = crs.pts
			for pi in range(0, pts.size(), 2):
				if fall == Overworld.NO_WATER:
					fall = ow.nearest_fall(Vector2i(pts[pi]), 7)
		if fall != Overworld.NO_WATER:
			queue.append(["waterfall", Vector2(ow.nearest_water_access(fall + Vector2i(0, 3), 6)) + Vector2(0.5, 0.5)])
	if _want("river"):
		for crs in ow.anchored_courses():
			if str(crs.id) == "canon:upmeads_water":
				var pts: Array = crs.pts
				var p := Vector2i(pts[pts.size() / 3])
				queue.append(["river", Vector2(ow.nearest_water_access(p, 8)) + Vector2(0.5, 0.5)])
	if _want("map"):
		queue.append(["map", Vector2(plank) + Vector2(0.5, 0.5)])
	print("shots ", queue.map(func(q): return "%s %s" % [q[0], q[1]]))
	_next()
	process_frame.connect(_wait)


func _next() -> void:
	if queue.is_empty():
		print("shots done")
		quit(0)
		return
	var e: Array = queue.pop_front()
	current = e[0]
	main.world.player.pos = e[1]
	main.camera.zoom = Vector2(3, 3) * main.view_scale
	main.recenter()
	if current == "map":
		main.ui.show_map("region")
	frames = 0


func _wait() -> void:
	frames += 1
	if frames < 40:
		return
	if current == "map":
		var found: Array = main.ui.panel_body.find_children("*", "RegionMapPanel", true, false)
		if not found.is_empty() and frames == 40:
			found[0].centre_on_player()
			found[0].zoom = 2.5
			return
		if frames < 60:
			return
	var path := "%s/water_%s.png" % [out, current]
	root.get_viewport().get_texture().get_image().save_png(path)
	print("saved ", path)
	_next()
