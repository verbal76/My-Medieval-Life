extends SceneTree
## B25R1-Q3: screenshots of the streams in the world beside the player, to look at (CLAUDE.md: visual output is looked at
## before it is reported). Needs a display (not --headless):
##   xvfb-run -a godot --rendering-driver opengl3 --path game --resolution 1280x720 --script res://tests/water_shot.gd -- OUT_DIR
## Shots: a waterfall over a cliff's rim into its pool, a bridge where a road crosses a stream, a stream's bend, a ford's
## stepping stones (the player standing on them), and the Region map with the streams.

var main
var out := "/tmp"
var frames := 0
var queue: Array = []
var current := ""


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	main.save_path = "user://test_saves/water_shot/save1.json"
	main.new_game()
	main.ui.hide_all()
	var w: World = main.world
	w.player.hunger = 100.0
	var ow: Overworld = w.map.overworld
	var fall := Vector2i.ZERO
	var bridge := Vector2i.ZERO
	var bend := Vector2i.ZERO
	var ford := Vector2i.ZERO
	var river := Vector2i.ZERO
	var c0 := Overworld.chunk_of(ow.village.get_center())
	for r in range(1, 22):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var cc := c0 + Vector2i(dx, dy)
				if ow.chunk_in_village(cc):
					continue
				var ch := ow.get_chunk(cc)
				for i in 1024:
					var c := cc * 32 + Vector2i(i % 32, i / 32)
					if ch.water[i] == 3 and fall == Vector2i.ZERO:
						fall = c
					elif ch.water[i] == 2 and bridge == Vector2i.ZERO:
						bridge = c
					elif ch.water[i] == 1 and ch.level[i] == 2 and river == Vector2i.ZERO:
						river = c
					elif ch.water[i] == 4 and ford == Vector2i.ZERO:
						ford = c
					elif ch.water[i] == 1 and bend == Vector2i.ZERO and r > 3:
						bend = c
	print("fall ", fall, " bridge ", bridge, " stream ", bend, " ford ", ford, " river ", river)
	if fall != Vector2i.ZERO:
		queue.append(["waterfall", Vector2(ow.nearest_water_access(fall + Vector2i(0, 3), 6)) + Vector2(0.5, 0.5)])
	if bridge != Vector2i.ZERO:
		queue.append(["bridge", Vector2(bridge) + Vector2(0.5, 0.5)])
	if bend != Vector2i.ZERO:
		queue.append(["stream", Vector2(ow.nearest_water_access(bend, 3)) + Vector2(0.5, 0.5)])
	if ford != Vector2i.ZERO:
		queue.append(["ford", Vector2(ford) + Vector2(0.5, 0.5)])
	if river != Vector2i.ZERO:
		queue.append(["river", Vector2(ow.nearest_water_access(river, 6)) + Vector2(0.5, 0.5)])
	# B25R1-018: the canonical crossings (Upmeads Water's bridge and ford; the stone bridge and fords south of Higham), the
	# player on the road beside each
	var k := 0
	for f in ow._forced:
		var at := Vector2i((f[0] as Vector2).floor())
		var stand := at
		for r in range(0, 9):
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					var c := at + Vector2i(dx, dy)
					if stand == at and ow.is_road(c) and not ow.is_bridge(c) and not ow.is_water(c) and not ow.is_solid(c):
						stand = c
		queue.append(["canon_%d_%s" % [k, str(f[2])], Vector2(stand) + Vector2(0.5, 0.5)])
		k += 1
	queue.append(["map", Vector2(bridge) + Vector2(0.5, 0.5)])
	_next()
	process_frame.connect(_wait)


func _next() -> void:
	if queue.is_empty():
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
