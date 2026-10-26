extends SceneTree
## GP-LOCKPICK (owner directive 2026-10-24 section 2 and its acceptance; amendment 2026-10-26 section 13): the pin-tumbler
## minigame in place of the passive meter, in the real game scene.
##   Rules (LockpickPlay): an easy lock (level 1) is 4 tumblers, one unstable at a time, opened with 6 to 8 catches; harder
##   locks 5 and 6 tumblers, more unstable at once, shorter windows for a weaker hand; the same lock plays the same way;
##   a press touches only its own pin; a player who never presses fails; routine misses are not punished.
##   Window (LockpickWindow): every tumbler has its own column, the same size at every difficulty, never overlapping, with
##   its own pad button (A B X Y LB RB), key (1-6) and prompt; rapid alternating pad presses are each taken once; a pad
##   B is a tumbler, never the window's Back; the world is not paused.
##   Outcomes (existing rules, World.player_pick_lock): stopped or closed: no attempt, the lock and the crime record as they
##   were; a won game opens the lock (until dawn); a lost game leaves it locked and may snap the pick; a second player
##   finishing on a lock already opened gets nothing (no xp, nothing taken).
##   godot --headless --path game --script res://tests/lockpick_test.gd

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
	main.save_path = "user://test_saves/lockpick_test/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func frames(n := 3) -> void:
	for i in n:
		await process_frame


## Play a game to its end at 60 steps a second: `skill` "perfect" catches each pin 0.3 s into its wobble, "idle" never
## presses, "sloppy" also presses a pin that is not ready now and then. Returns the game.
static func play_out(g: LockpickPlay, skill: String) -> LockpickPlay:
	var dt := 1.0 / 60.0
	var k := 0
	while g.result == "" and g.t < 300.0:
		g.step(dt)
		k += 1
		if skill == "idle":
			continue
		for i in g.n:
			if g.state[i] == LockpickPlay.WOBBLE and g.t_in[i] >= 0.3:
				g.press(i)
		if skill == "sloppy" and k % 97 == 0:
			g.press(k % g.n)
	return g


func _run() -> void:
	# --- the rules ---
	var easy := play_out(LockpickPlay.from(1, 0.5, 1234), "perfect")
	check(easy.n == 4 and easy.concurrent == 1 and easy.result == "open" and easy.caught >= 6 and easy.caught <= 8,
		"an easy lock: 4 tumblers, one unstable at a time, opened with %d catches (six to eight)" % easy.caught)
	var opened := []
	for lv in [1, 2, 3]:
		for ch in [0.1, 0.5, 0.9]:
			for seed in [1, 2, 3]:
				var g := play_out(LockpickPlay.from(lv, ch, seed), "perfect")
				if g.result != "open":
					opened.append("%d/%s/%d" % [lv, ch, seed])
	check(opened.is_empty(), "every lock, level 1 to 3, any skill, opens for a hand that catches every pin %s" % [opened])
	var l2 := LockpickPlay.from(2, 0.5, 1)
	var l3 := LockpickPlay.from(3, 0.5, 1)
	check(l2.n == 5 and l3.n == 6 and l2.concurrent == 2 and l3.concurrent == 2, "harder locks: 5 and 6 tumblers, two unstable at once")
	var weak := LockpickPlay.from(2, 0.1, 1)
	var strong := LockpickPlay.from(2, 0.9, 1)
	check(weak.window < strong.window and weak.rise < strong.rise and weak.gap < strong.gap, "a weaker hand against the lock (the existing chance) gets faster pins and shorter windows")
	var idle := play_out(LockpickPlay.from(1, 0.9, 7), "idle")
	check(idle.result == "fail" and idle.caught == 0, "never pressing: the pins fall and the attempt fails")
	var sloppy := play_out(LockpickPlay.from(1, 0.5, 7), "sloppy")
	check(sloppy.result == "open" and sloppy.mistaps > 0, "presses on pins that are not ready are not punished (%d of them; still opens)" % sloppy.mistaps)
	var a := play_out(LockpickPlay.from(2, 0.4, 99), "perfect")
	var b := play_out(LockpickPlay.from(2, 0.4, 99), "perfect")
	check(a.caught == b.caught and is_equal_approx(a.t, b.t) and a.order == b.order, "the same lock plays the same way (no hidden randomness)")
	var g1 := LockpickPlay.from(3, 0.5, 5)
	while not g1.state.has(LockpickPlay.WOBBLE):
		g1.step(0.05)
	var w0: int = g1.state.find(LockpickPlay.WOBBLE)
	var before := g1.state.duplicate()
	g1.press(w0)
	var others_same := true
	for i in g1.n:
		if i != w0 and g1.state[i] != before[i]:
			others_same = false
	check(g1.state[w0] == LockpickPlay.SET and others_same, "a press sets its own pin and touches no other")
	# --- the window ---
	var w4 := LockpickWindow.new().setup(LockpickPlay.from(1, 0.5, 1), "touch")
	var w6 := LockpickWindow.new().setup(LockpickPlay.from(3, 0.1, 1), "touch")
	var sizes_same := true
	for c in w4.columns + w6.columns:
		sizes_same = sizes_same and (c as Button).size == (w4.columns[0] as Button).size
	check(sizes_same and (w4.columns[0] as Button).size.x >= 88.0, "every tumbler's target is the same size at every difficulty (%s)" % (w4.columns[0] as Button).size)
	var overlap := false
	for i in w6.columns.size():
		for j in range(i + 1, w6.columns.size()):
			if Rect2((w6.columns[i] as Button).position, (w6.columns[i] as Button).size).intersects(Rect2((w6.columns[j] as Button).position, (w6.columns[j] as Button).size)):
				overlap = true
	var hits := {}
	for x in range(0, int(6 * 102 + 48), 2):
		hits[w6.column_at(Vector2(x, 100))] = true
	check(not overlap and hits.has(-1) and hits.size() == 7, "the six columns never overlap, with a gap between them: one touch, one tumbler")
	w4.free()
	w6.free()
	# --- in the game ---
	main.new_game()
	main.ui.hide_all()
	await frames()
	var w: World = main.world
	var p := w.player
	var u := _foreign(w)
	check(not u.is_empty(), "a villager's chest to pick")
	w.chests.locks[u.id] = {"level": 1, "locked": true}
	p.pos = u.at + Vector2(0, 1)
	p.inv.add("lockpick", 3)
	var crimes0 := p.crimes.size()
	main.pick_lock(str(u.id))
	await frames()
	var win: LockpickWindow = main.ui.panel_body.find_child("LockpickWindow", true, false)
	check(win != null and main.ui.panel_kind == "lockpick" and not main.paused, "Pick the lock opens the minigame, and the world is not paused")
	main.ui.set_scheme("gamepad")
	# rapid alternating pad presses: each one taken once, B is a tumbler (not Back)
	var g: LockpickPlay = win.play
	var presses0 := g.caught + g.mistaps
	for k in 8:
		var e := InputEventJoypadButton.new()
		e.button_index = [JOY_BUTTON_A, JOY_BUTTON_B][k % 2]
		e.pressed = true
		root.push_input(e)
		var up := InputEventJoypadButton.new()
		up.button_index = e.button_index
		up.pressed = false
		root.push_input(up)
	await frames(1)
	check(g.caught + g.mistaps - presses0 == 8 and main.ui.panel_kind == "lockpick", "eight rapid alternating A / B presses: eight presses taken, none dropped or doubled, and B did not close the window")
	var ek := InputEventKey.new()
	ek.physical_keycode = KEY_3
	ek.pressed = true
	root.push_input(ek)
	await frames(1)
	check(g.caught + g.mistaps - presses0 == 9, "keyboard 3 is the third tumbler")
	# stop: no attempt
	var esc := InputEventKey.new()
	esc.physical_keycode = KEY_ESCAPE
	esc.pressed = true
	root.push_input(esc)
	await frames()
	check(main.ui.panel_kind != "lockpick" and w.chests.is_locked(u) and p.crimes.size() == crimes0 and p.inv.count("lockpick") == 3,
		"stopped: the window closes, the lock is as it was, nothing on the record, the pick kept")
	# closed by something else mid-game: still no attempt
	main.pick_lock(str(u.id))
	await frames()
	main.ui.hide_all()
	await frames()
	check(w.chests.is_locked(u) and p.crimes.size() == crimes0, "closed by anything else mid-game: no attempt")
	# a won game: the existing outcome
	main.pick_lock(str(u.id))
	await frames()
	win = main.ui.panel_body.find_child("LockpickWindow", true, false)
	var done := [0]
	win.finished.connect(func(_r): done[0] += 1)
	play_out(win.play, "perfect")
	await frames(3)
	check(done[0] == 1 and not w.chests.is_locked(u) and main.ui.panel_kind == "chest", "a won game opens the lock (the chest opens), once")
	main.ui.hide_all()
	# a lost game: locked, maybe a snapped pick, never open
	var u2 := _foreign(w, [u.id])
	w.chests.locks[u2.id] = {"level": 2, "locked": true}
	p.pos = u2.at + Vector2(0, 1)
	var picks := p.inv.count("lockpick")
	main.pick_lock(str(u2.id))
	await frames()
	win = main.ui.panel_body.find_child("LockpickWindow", true, false)
	play_out(win.play, "idle")
	await frames(3)
	check(w.chests.is_locked(u2) and main.ui.panel_kind != "chest" and p.inv.count("lockpick") >= picks - 1, "a lost game: the lock holds (the pick may snap: %d -> %d)" % [picks, p.inv.count("lockpick")])
	# two players on one lock: the second finishing after it was opened gets nothing
	var gu := PlayerState.new()
	gu.name = "Gwen"
	gu.family = "Fairlight"
	Identity.register_player(w, gu)
	w.add_guest(gu)
	gu.inv.add("lockpick", 1)
	gu.pos = u.at + Vector2(0, 1)
	var r: Dictionary = w.player_pick_lock(u, "open", gu)
	check(str(r.result) == "cant" and gu.inv.count("lockpick") == 1, "a second player finishing on a lock already opened: nothing (%s)" % str(r.text))
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _foreign(w: World, skip := []) -> Dictionary:
	for id in w.buildings:
		var b: Dictionary = w.buildings[id]
		if str(b.type) == "house" and w.holder_of(b).begins_with("hh:"):
			for cu in w.chests.units_in(str(id)):
				if not skip.has(cu.id) and w.chests.info(cu).access == "foreign":
					return cu
	return {}
