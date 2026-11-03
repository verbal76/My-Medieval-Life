extends SceneTree
## B25R1-Q1: screenshots of the three road types in the world, in the real game scene, to look at (CLAUDE.md: visual output is
## looked at before it is reported). Needs a display (not --headless):
##   xvfb-run -a godot --rendering-driver opengl3 --path game --resolution 1280x720 --script res://tests/road_types_shot.gd -- OUT_DIR
## Shots: a settlement's paved street and approach (stone), where the stone road out of the village meets the dirt road, a
## dirt road out in the country, and a trail.

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
	main.save_path = "user://test_saves/road_types_shot/save1.json"
	main.new_game()
	main.ui.hide_all()
	var w: World = main.world
	w.player.hunger = 100.0
	var ow: Overworld = w.map.overworld
	var st: Dictionary = ow.site("wulstead")
	queue.append(["stone_settlement", Vector2(st.gate) + Vector2(0.5, -1.5)])
	# along the south road: where stone gives way to dirt road, a dirt stretch, and a trail
	var road := ow.road_route(Journeys.gate_index(w), "wulstead")
	var kinds := RegionRoads.main_kinds(ow)
	var last := "stone"
	var dirt_at := -1
	for q in road.size():
		var k := str(kinds.get(Vector2i(road[q]), "trail"))
		if k != last and last == "stone" and dirt_at < 0:
			queue.append(["stone_to_dirt", road[q] + Vector2(0.5, 0.5)])
			dirt_at = q
		last = k
	if dirt_at >= 0:
		queue.append(["dirt_road", road[mini(dirt_at + 60, road.size() - 1)] + Vector2(0.5, 0.5)])
	for seg in RegionRoads.segments(ow, Rect2i(-200, 100, 400, 300)):
		var c: PackedInt32Array = seg.cells
		var mid := Vector2i(c[(c.size() / 4) * 2], c[(c.size() / 4) * 2 + 1])
		if RegionRoads.cell_kind(ow, mid) == "trail" and not ow.village.grow(30).has_point(mid):
			queue.append(["trail", Vector2(mid) + Vector2(0.5, 0.5)])
			break
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
	frames = 0


func _wait() -> void:
	frames += 1
	if frames < 40:
		return
	var path := "%s/road_%s.png" % [out, current]
	root.get_viewport().get_texture().get_image().save_png(path)
	print("saved ", path, " at ", main.world.player.pos, " kind ", RegionRoads.cell_kind(main.world.map.overworld, Vector2i(main.world.player.pos.floor())))
	_next()
