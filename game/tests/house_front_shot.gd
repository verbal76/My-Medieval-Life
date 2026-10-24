extends SceneTree
## GP-DRAW-UNDER-HOUSE: the player and a villager standing on the ground just in front of building fronts (as close as
## their feet let them), in the real game scene, saved as screenshots so the drawing order is looked at: both must be
## drawn whole, over the wall's bottom row. Needs a display (not --headless):
##   xvfb-run -a godot --rendering-driver opengl3 --path game --script res://tests/house_front_shot.gd -- OUT_DIR [count]

var main
var out := "/tmp"
var count := 6
var frames := 0
var queue: Array = []
var current: Dictionary = {}
var spots: Array = []          # [player pos, npc pos]
var inside := false            # third argument "inside": the player stands just inside the door (the roof lifts)


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.size() > 1:
		count = int(args[1])
	inside = args.size() > 2 and args[2] == "inside"
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	main.save_path = "user://test_saves/house_front_shot/save1.json"
	main.new_game()
	main.ui.hide_all()
	var ids: Array = main.world.buildings.keys()
	ids.sort()
	for id in ids:
		var b: Dictionary = main.world.buildings[id]
		if b.has("door") and queue.size() < count:
			queue.append(b)
	_next()
	process_frame.connect(_wait)


## The row just below the building's drawn front in column x: the first cell going down with no roof-layer tile.
func _below_front(x: int, b: Dictionary) -> int:
	var lays: Array = []
	for n in main.map.data.get("roof_layers", []):
		lays.append(main.view.layer(str(n)))
	for y in range(int(b.y) + int(b.h), int(b.y) - 1, -1):
		for l in lays:
			if main.view.tile_value(l, Vector2i(x, y)) >= 0:
				return y + 1
	return int(b.y) + int(b.h)


func _next() -> void:
	current = queue.pop_front()
	var door := Vector2i(int(current.door[0]), int(current.door[1]))
	var px := door.x + 1
	var nx := door.x - 1
	# the nearest the feet can come to the wall: the body's top edge (Main.BODY) on the row's top edge
	spots = [Vector2(px + 0.5, _below_front(px, current) + 0.16), Vector2(nx + 0.5, _below_front(nx, current) + 0.16)]
	if inside and current.has("interior"):
		var d0: Array = current.interior.doors[0]
		spots[0] = Vector2(int(d0[0]) + 0.5, int(d0[1]) - 0.5)
	main.world.player.pos = spots[0]
	main.camera.zoom = Vector2(6, 6) * main.view_scale
	main.camera.position_smoothing_enabled = false
	main.follow_at = main._in_view(Vector2(door) * main.T)
	frames = 0


func _wait() -> void:
	frames += 1
	main.world.player.pos = spots[0]
	if not main.world.npcs.is_empty():
		var n: NPC = main.world.npcs[0]
		n.pos = spots[1]
		n.path = PackedVector2Array()
	if frames == 3:
		main.ui.hide_all()
	if frames < (40 if inside else 20):
		return
	var img := root.get_texture().get_image()
	var path := "%s/%s_%s.png" % [out, "inside" if inside else "front", str(current.id)]
	img.save_png(path)
	print("saved ", path, " player ", spots[0], " npc ", spots[1])
	if queue.is_empty():
		process_frame.disconnect(_wait)
		quit(0)
		return
	_next()
