extends SceneTree
## GP-HARVEST-CONT (owner, 2026-10-24), in the real game scene: Settings, Interface, "Harvesting": manual (the default:
## Use works a resource once; Gather mode, on every platform, for more) or continuous (Use on a resource gathers it until
## it runs out, through the same gather loop and the same action a cycle). Continuous gives exactly what as many manual
## uses give (yield, depletion, tool wear, the same game time a cycle); moving stops it; the choice is saved.
##   godot --headless --path game --script res://tests/harvest_setting_test.gd

var main
var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL " + what)


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://test_saves/harvest_setting_test/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


## A seam with plenty left, and the player beside it facing it.
func at_seam(w: World) -> Dictionary:
	for d in w.deposits:
		if int(d.get("level", 0)) == 0 and int(d.get("amount", 0)) >= 8:
			var cell := Vector2i(int(d.x), int(d.y))
			var c: Vector2i = w.brain.beside(cell, cell + Vector2i(0, 1))
			w.player.pos = Vector2(c) + Vector2(0.5, 0.5)
			main.player_sprite.face(Vector2(cell) + Vector2(0.5, 0.5) - w.player.pos)
			main._find_target()
			return d
	return {}


## Play until the current gather and action are done (or `most` steps of a quarter second).
func play(most: int) -> int:
	var n := 0
	while n < most and (not main.gather.is_empty() or not main.action.is_empty()):
		main._player_step(0.25)
		n += 1
	return n


func _run() -> void:
	main.new_game()
	main.ui.hide_all()
	var w: World = main.world
	var p := w.player
	p.inv.add("pickaxe")
	p.tool = "pickaxe"
	p.hunger = 100.0
	check(main.settings.harvest == "manual", "manual is the default")
	var d := at_seam(w)
	check(not d.is_empty() and not main.target.is_empty() and str(main.target.kind) == "deposit", "beside a seam")
	# manual: one Use, one cycle
	var ore := str(d.get("ore", "stone"))
	var a0 := int(d.amount)
	var s0 := p.inv.count(ore)
	main.interact()
	var steps1 := play(400)
	var one_stone := p.inv.count(ore) - s0
	check(int(d.amount) == a0 - 1 and one_stone >= 1 and main.gather.is_empty(), "manual: Use works it once (%d ore in %d quarter seconds)" % [one_stone, steps1])
	# continuous: Use gathers until stopped; three cycles give what three manual uses give
	main.settings.harvest = "continuous"
	at_seam(w)
	var a1 := int(d.amount)
	var s1 := p.inv.count(ore)
	main.interact()
	check(not main.gather.is_empty() and bool(main.gather.continuous), "continuous: Use starts gathering it until it runs out")
	var guard := 0
	while int(d.amount) > a1 - 3 and guard < 1200:
		main._player_step(0.25)
		guard += 1
	var per := float(guard) / 3.0
	check(int(d.amount) == a1 - 3 and p.inv.count(ore) - s1 == 3 * one_stone, "three cycles: three units taken from the seam, three times one use's ore (%d)" % (p.inv.count(ore) - s1))
	check(absf(per - float(steps1)) <= 2.0, "the same time a cycle (%.1f against %d quarter seconds: the same action)" % [per, steps1])
	# moving stops it
	Input.action_press("move_left")
	main._player_step(0.1)
	Input.action_release("move_left")
	check(main.gather.is_empty(), "walking away stops it")
	# saved
	main.settings.save_file()
	var again := GameSettings.new()
	again.load_file()
	check(again.harvest == "continuous", "the choice is saved")
	main.settings.harvest = "manual"
	main.settings.save_file()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
