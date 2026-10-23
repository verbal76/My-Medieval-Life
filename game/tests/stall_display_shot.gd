extends SceneTree
## B18-DP-01: the player's market stall in the real game scene with its goods shown on the counter (existing item icons),
## saved as a screenshot so it is looked at. Needs a display (not --headless):
##   xvfb-run -a godot --rendering-driver opengl3 --path game --script res://tests/stall_display_shot.gd -- OUT.png

var main
var out := "/tmp/stall_display.png"
var frames := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	main.save_path = "user://test_saves/stall_display_shot/save1.json"
	main.new_game()
	process_frame.connect(_wait)


func _place() -> void:
	var w: World = main.world
	w.player.coins = 100
	for k in {"plank": 8, "iron_ore": 5, "pickaxe": 1, "herbal_poultice": 3}:
		w.player.inv.add(k, {"plank": 8, "iron_ore": 5, "pickaxe": 1, "herbal_poultice": 3}[k])
	w.business.rent()
	var s: Dictionary = w.business.mine()
	for k in ["plank", "iron_ore", "pickaxe", "herbal_poultice"]:
		w.business.list_item(s, k, w.player.inv.count(k))
	w.player.pos = w.business.use_cell(s) + Vector2(1.5, 2.0)


func _wait() -> void:
	frames += 1
	if frames == 5:
		_place()
	if frames < 60:
		return
	process_frame.disconnect(_wait)
	var img := root.get_texture().get_image()
	img.save_png(out)
	print("saved ", out, " ", img.get_size())
	quit(0)
