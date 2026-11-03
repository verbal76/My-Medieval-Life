extends SceneTree
## B25R1-011: screenshots of worn and paved ways in the world, to look at. Needs a display (not --headless):
##   xvfb-run -a godot --rendering-driver opengl3 --path game --resolution 1280x720 --script res://tests/road_wear_shot.gd -- OUT_DIR
## Shots: a path worn across the grass beside the south road (a trail turning to dirt road) with a paved stretch of the road
## next to it, then the same place 30 days later (the worn path faded, the dirt road grown over) and 330 days later (the
## stone broken by age alone).

var main
var out := "/tmp"
var frames := 0
var step := 0
var spot := Vector2.ZERO


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	main.save_path = "user://test_saves/road_wear_shot/save1.json"
	main.new_game()
	main.ui.hide_all()
	var w: World = main.world
	w.player.hunger = 100.0
	var ow: Overworld = w.map.overworld
	var road := ow.road_route(Journeys.gate_index(w), "wulstead")
	var kinds := RegionRoads.main_kinds(ow)
	var at := 0
	for q in road.size():
		if kinds.get(Vector2i(road[q]), "") == "road":
			at = q + 30
			break
	var c0 := Vector2i(road[at])
	spot = Vector2(c0) + Vector2(0.5, 0.5)
	# a path worn off the road: east for 10 cells then south, the first part walked more (dirt road), the rest a trail
	var cells: Array[Vector2i] = []
	for k in range(1, 11):
		cells.append(c0 + Vector2i(k, 0))
	for k in range(1, 7):
		cells.append(c0 + Vector2i(10, k))
	for i in cells.size():
		if ow.is_solid(cells[i]):
			continue
		for n in (45 if i < 6 else 22):
			RoadWear.foot(ow, cells[i])
	# a paved stretch of the road, 6 cells before the turn-off
	for q in range(at - 6, at):
		RoadWear.pave(ow, Vector2i(road[q]))
	w.player.pos = spot + Vector2(3, 2)
	main.camera.zoom = Vector2(3, 3) * main.view_scale
	main.recenter()
	process_frame.connect(_wait)


func _wait() -> void:
	frames += 1
	if frames < 40:
		return
	frames = 0
	var w: World = main.world
	if step == 0:
		root.get_viewport().get_texture().get_image().save_png(out + "/wear_worn_and_paved.png")
		w.minutes += 30.0 * 1440.0
		w.map.overworld.clock = w.minutes
		w.player.pos = spot + Vector2(3, 2)     # standing still: the cells round stay unwalked
	elif step == 1:
		root.get_viewport().get_texture().get_image().save_png(out + "/wear_30_days_later.png")
		w.minutes += 300.0 * 1440.0               # 330 days on (about 40 years): the paved stretch's stone broken by age alone
		w.map.overworld.clock = w.minutes
	elif step == 2:
		root.get_viewport().get_texture().get_image().save_png(out + "/wear_330_days_later.png")
		quit(0)
	step += 1
