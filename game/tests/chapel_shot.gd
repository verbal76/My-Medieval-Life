extends SceneTree
## DVW-B3-CHAPEL: the chapel and the church's plot in the real game scene beside the player, saved as a screenshot so it is looked at.
## Needs a display (not --headless):
##   xvfb-run -a godot --rendering-driver opengl3 --path game --script res://tests/chapel_shot.gd -- OUT.png

var main
var out := "/tmp/chapel.png"
var frames := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	main.save_path = "user://test_saves/chapel_shot/save1.json"
	main.new_game()
	process_frame.connect(_wait)


func _place() -> void:
	var w: World = main.world
	var c: Chapel = w.chapel
	var pr: NPC = w.npcs.filter(func(n): return n.alive and n.job == "preacher")[0]
	var asst: NPC = w.npcs.filter(func(n): return n.alive and n.job == "church_assistant")[0]
	w.player.pos = Vector2(78.5, 36.5)
	pr.pos = Vector2(c.door_cell()) + Vector2(-1.5, 1.5)
	pr.plan.clear()
	var fp := w.farm_plots
	for y in range(int(c.plot.y) + 1, int(c.plot.y) + int(c.plot.h) - 1):
		for x in range(int(c.plot.x) + 1, int(c.plot.x) + int(c.plot.w) - 1):
			var cell := Vector2i(x, y)
			if x < int(c.plot.x) + 5:
				fp.cells[cell] = {"crop": "wheat", "state": "growing", "progress": 0.5, "plot": "church"}
			else:
				fp.cells[cell] = {"crop": "", "state": "tilled", "progress": 0.0, "plot": "church"}
			fp._show_around(cell)
	asst.pos = Vector2(int(c.plot.x) + 5, int(c.plot.y) + 3) + Vector2(0.5, 0.5)
	asst.plan.clear()


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
