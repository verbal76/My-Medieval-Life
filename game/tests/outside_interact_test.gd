extends SceneTree
## B25R1-002 (owner 2026-11-03, release blocker: "interaction stopped working after leaving the starting village"): the
## player's own actions outside the village, driven through the real main scene the way a phone plays it (taps, frames),
## not the background simulation. Scenarios of the directive: A (a tree and a rock outside: walked to, worked, the goods in
## the pack), B (a traveller on the road: tapped, walked up to, talked to), C (a countryside animal: real near the player,
## flees, hunted in attack mode, a carcass), D (a settlement's keeper: tapped, walked up to, their window), F (saved
## outside and loaded: the countryside's dead stay dead, a tree felled stays felled, interaction still works). Run:
##   godot --headless --path game --script res://tests/outside_interact_test.gd

var failures := 0
var checks := 0
var main


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://test_saves/outside_interact"))
	main.save_path = "user://test_saves/outside_interact/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _frames(n: int) -> void:
	for i in n:
		main._process(1.0 / 30.0)


func _reset_hands() -> void:
	if not main.action.is_empty():
		main.cancel_action("")
	main.stop_gather("")
	main.move_to = Vector2.INF
	main.talk_to = null
	main.talk_traveller = -1
	main.reach_to = Vector2.INF
	main.attack_mode = false
	main.ui.hide_all()


func _tap_at(wpos: Vector2) -> void:
	main._tap(main.get_canvas_transform() * (wpos * main.T))


func _run() -> void:
	main.new_game()
	await process_frame
	main.ui.hide_all()
	var w: World = main.world
	var o: Overworld = w.map.overworld
	# ---- A: a tree outside the village, tapped from a few tiles off, as on a phone
	var tree := {}
	for y in range(o.village.end.y + 2, o.village.end.y + 60):
		for x in range(o.village.position.x, o.village.end.x):
			var t := o.tree_at(Vector2i(x, y))
			if not t.is_empty() and str(t.state) == "grown" and not o.is_solid(Vector2i(x, y + 1)) and not o.is_solid(Vector2i(x, y + 4)):
				tree = t
				break
		if not tree.is_empty():
			break
	check(not tree.is_empty(), "A: a grown tree stands outside the village")
	var logs0: int = w.player.inv.count("log")
	_reset_hands()
	w.player.pos = Vector2(int(tree.x) + 0.5, int(tree.y) + 4.5)
	_tap_at(Vector2(int(tree.x) + 0.5, int(tree.y) + 0.5))
	var chopping := false
	for i in 40:
		_frames(15)
		if str(main.action.get("label", "")).begins_with("Chopping"):
			chopping = true
		if w.player.inv.count("log") > logs0:
			break
	check(chopping, "A: the tapped tree outside is walked to and chopped (before the fix: 'You can't reach it from here.')")
	check(w.player.inv.count("log") > logs0, "A: its logs go into the pack (%d -> %d)" % [logs0, w.player.inv.count("log")])
	# a rock outside the village
	var rock := Vector2i(-9999, 0)
	for y in range(o.village.end.y + 2, o.village.end.y + 120):
		for x in range(o.village.position.x - 40, o.village.end.x + 40):
			if not o.boulder_at(Vector2i(x, y)).is_empty() and not o.is_solid(Vector2i(x, y + 1)) and not o.is_solid(Vector2i(x, y + 4)):
				rock = Vector2i(x, y)
				break
		if rock.x != -9999:
			break
	check(rock.x != -9999, "A: a rock lies outside the village")
	var stone0: int = w.player.inv.count("stone")
	_reset_hands()
	w.player.pos = Vector2(rock.x + 0.5, rock.y + 4.5)
	_tap_at(Vector2(rock.x + 0.5, rock.y + 0.5))
	for i in 40:
		_frames(15)
		if w.player.inv.count("stone") > stone0:
			break
	check(w.player.inv.count("stone") > stone0, "A: the tapped rock outside is walked to and mined, stone in the pack (%d -> %d)" % [stone0, w.player.inv.count("stone")])
	# ---- C: a countryside animal becomes real near the player, flees, and is hunted
	var cs: Countryside = main.countryside
	var home := Vector2i.ZERO
	var found := false
	for cy in range(2, 14):
		for cx in range(-3, 7):
			for e in cs.chunk_animals(Vector2i(cx, cy)):
				if str(e.species) in ["deer", "rabbit"] and not cs.taken.has(str(e.key)):
					home = e.home
					found = true
					break
			if found:
				break
		if found:
			break
	check(found, "C: the countryside has deer or rabbits")
	_reset_hands()
	w.player.pos = Vector2(home) + Vector2(0.5, 4.5)
	_frames(30)
	var adopted: Array = w.fauna.animals.filter(func(a): return a.area == Fauna.COUNTRY)
	check(not adopted.is_empty(), "C: near the player the countryside's animals are real animals of the fauna (%d)" % adopted.size())
	if not adopted.is_empty():
		var a: Animal = adopted[0]
		var p0 := a.pos
		w.player.pos = a.pos + Vector2(0, 1.5)
		_frames(45)
		check(a.pos.distance_to(p0) > 0.5, "C: it moves over the open country (flees from the player: %.1f tiles)" % a.pos.distance_to(p0))
		main.ui.hide_all()
		main._find_target()
		w.player.pos = a.pos + Vector2(0, 0.9)
		main.player_sprite.face(Vector2.UP)
		main._find_target()
		var offered: Array = (main.target_options as Array).filter(func(t): return str(t.get("kind", "")) == "animal" and t.animal == a)
		check(not offered.is_empty() and str(offered[0].label).contains("attack to hunt it"), "C: it is among what Use offers: %s" % (str(offered[0].label) if not offered.is_empty() else "nothing"))
		main.attack_mode = true
		var piles0: int = w.loot.size()
		for k in 60:
			if not a.alive:
				break
			_tap_at(a.pos + Vector2(0, -0.4))
			_frames(15)
		check(not a.alive, "C: hunted in attack mode, it falls")
		check(w.loot.size() > piles0, "C: it leaves a carcass to take (%d piles)" % w.loot.size())
		_frames(2)
		var dead := 0
		for k in w.country_taken:
			if int(w.country_taken[k]) < 0:
				dead += 1
		check(dead >= 1, "C: the countryside remembers it is dead (it does not walk again)")
		main.attack_mode = false
	# ---- D: a settlement's keeper, tapped
	var st: Dictionary = o.sites[0]
	var people: Array = SettlementFolk.people(w, str(st.id)).filter(func(pp): return SettlementFolk.present(w, pp))
	check(not people.is_empty(), "D: %s has keepers at their doors" % str(st.name))
	if not people.is_empty():
		var pp: Dictionary = people[0]
		_reset_hands()
		w.player.pos = Vector2(pp.spot) + Vector2(0.5, 4.5)
		_frames(5)
		_tap_at(Vector2(pp.spot) + Vector2(0.5, 0.4))
		for i in 30:
			_frames(10)
			if main.ui.is_open("keeper"):
				break
		check(main.ui.is_open("keeper"), "D: tapping %s walks up to them and opens their window (before: only a walk)" % str(pp.name))
		main.ui.hide_all()
	# ---- B: a traveller on the road: find one, tap them, talk
	var tv := {}
	var t0: float = w.minutes
	for step in 600:
		var list: Array = cs.travellers_near(Vector2(60, 45), 400.0, w.minutes).filter(func(e): return str(e.kind) != "wagon")
		if not list.is_empty():
			tv = list[0]
			break
		w.minutes += 5.0
	check(not tv.is_empty(), "B: travellers walk the trails")
	if not tv.is_empty():
		_reset_hands()
		w.player.pos = (tv.pos as Vector2) + Vector2(0, 3.0)
		_frames(1)
		var now: Array = cs.travellers_near(w.player.pos, 6.0, w.minutes).filter(func(e): return int(e.key) == int(tv.key))
		if not now.is_empty():
			_tap_at((now[0].pos as Vector2) + Vector2(0, -0.4))
		for i in 40:
			_frames(5)
			if main.ui.is_open("traveller"):
				break
		check(main.ui.is_open("traveller"), "B: tapping a %s walks up to them and talks" % str(tv.kind))
		w.player.places.clear()
		main.ui.show_traveller(tv)
		main.ui.panel_body.find_children("*", "Button", true, false).filter(func(b): return str(b.text).begins_with("Ask about the roads"))[0].pressed.emit()
		check(w.player.places.size() == o.sites.size(), "B: asked about the roads, they tell the way to every settlement (%d)" % w.player.places.size())
		main.ui.hide_all()
		var tv2 := tv.duplicate()
		w.player.pos = (tv.pos as Vector2)
		for e in cs.travellers_near(w.player.pos, 3.0, w.minutes):
			if int(e.key) == int(tv.key):
				w.player.pos = (e.pos as Vector2) + Vector2(0, 1.0)
		main.player_sprite.face(Vector2.UP)
		main._find_target()
		var opts: Array = main.target_options if "target_options" in main else []
		check(str(main.target.get("kind", "")) == "traveller" or opts.any(func(t): return str(t.get("kind", "")) == "traveller"), "B: with keys or a pad, Use offers to talk to them")
	w.minutes = maxf(w.minutes, t0)
	# ---- F: save outside the village, load, and it all still works
	_reset_hands()
	var taken_before: Dictionary = w.country_taken.duplicate()
	var felled_cell := Vector2i(int(tree.x), int(tree.y))
	var felled_state := str(o.tree_at(felled_cell).get("state", ""))
	w.player.pos = Vector2(int(tree.x) + 2.5, int(tree.y) + 3.5)
	main.save_game(false)
	main.continue_game()
	await process_frame
	main.ui.hide_all()
	w = main.world
	o = w.map.overworld
	check(w.player.pos.distance_to(Vector2(int(tree.x) + 2.5, int(tree.y) + 3.5)) < 0.1, "F: loaded where it was saved, outside the village")
	var same := true
	for k in taken_before:
		same = same and w.country_taken.has(k) and int(w.country_taken[k]) == int(taken_before[k])
	check(same and taken_before.size() > 0, "F: the countryside's adopted and dead animals come back as they were (%d)" % taken_before.size())
	check(str(o.tree_at(felled_cell).get("state", "")) == felled_state, "F: the tree worked outside is as it was left (%s)" % felled_state)
	var logs1: int = w.player.inv.count("log")
	var tree2 := {}
	for y in range(int(tree.y) - 20, int(tree.y) + 40):
		for x in range(int(tree.x) - 30, int(tree.x) + 30):
			var t := o.tree_at(Vector2i(x, y))
			if not t.is_empty() and str(t.state) == "grown" and not o.is_solid(Vector2i(x, y + 1)) and not o.is_solid(Vector2i(x, y + 4)) and Vector2i(x, y) != felled_cell:
				tree2 = t
				break
		if not tree2.is_empty():
			break
	_reset_hands()
	w.player.pos = Vector2(int(tree2.x) + 0.5, int(tree2.y) + 4.5)
	_tap_at(Vector2(int(tree2.x) + 0.5, int(tree2.y) + 0.5))
	for i in 40:
		_frames(15)
		if w.player.inv.count("log") > logs1:
			break
	check(w.player.inv.count("log") > logs1, "F: after loading, a tree outside is chopped as before (%d -> %d)" % [logs1, w.player.inv.count("log")])
	_frames(30)
	check(w.fauna.animals.any(func(a): return a.area == Fauna.COUNTRY and a.alive), "F: after loading, the countryside's animals near the player are real again")
	print("%d checks, %d failures" % [checks, failures])
	main.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures > 0 else 0)
