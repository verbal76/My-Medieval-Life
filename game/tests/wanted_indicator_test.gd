extends SceneTree
## GP-WANTED-INDICATOR (owner, 2026-10-26: "a red circle around our body so I know when I am being hunted by guards ...
## somewhere out of the way on the screen where it tells me why"), in the real game scene, driven only by the existing
## case and pursuit records (Justice; no new rule):
##   - nothing shows with no case, or with a crime no guard knows of;
##   - a guard in a chase: the red ring round the player and the note "Pursued", with the crime, its victim and place;
##   - a guard coming to where the player was reported: "coming"; searching: "searching"; the ring stays while hunted;
##   - the search given up: "Wanted" with no ring; the crime settled (a fine, a yield) or the case closed: all gone;
##   - the note sits under the status box, clear of the prompt and the touch buttons, on a phone too;
##   - per player: a guest's case shows on the guest's machine (its local player) and not on the host's.
##   godot --headless --path game --script res://tests/wanted_indicator_test.gd

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
	main.save_path = "user://test_saves/wanted_indicator_test/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func frames(n := 3) -> void:
	for i in n:
		await process_frame


func ring() -> WantedRing:
	return main.player_sprite.get_node_or_null("WantedRing")


func hud() -> WantedHud:
	return main.ui.wanted_hud


func _run() -> void:
	main.new_game()
	main.ui.hide_all()
	var w: World = main.world
	var p := w.player
	var j: Justice = w.justice
	var ref := w.acting_ref()
	var guards: Array = w.npcs.filter(func(n): return n.alive and n.job == "guard")
	var victim: NPC = w.npcs.filter(func(n): return n.alive and n.role == "adult" and n.job != "guard")[0]
	var g: NPC = guards[0]
	main.paused = true                          # the world holds still; the view and the HUD still follow it
	await frames()
	check(not hud().visible and not ring().visible, "no case: no ring, no note")
	var ci := j.record(ref, "assault", victim, p.pos, 0)
	await frames()
	check(not hud().visible and not ring().visible, "a crime no guard knows of: nothing shown (the player is not hunted)")
	j.learn(g, ref, [ci], p.pos)
	j.engage(g, ref, "pursuing")
	await frames()
	var who := "%s %s" % [victim.name, victim.family]
	check(ring().visible and hud().visible and hud().title.text == WantedHud.STATE_TEXT.pursued, "a guard in a chase: the red ring and the note 'Pursued' (%s)" % hud().title.text)
	check(hud().why.text.begins_with("For attacking " + who) and hud().why.text.length() > ("For attacking " + who).length(), "the note names the crime, its victim and where (%s)" % hud().why.text)
	check(not hud().why.text.contains(g.name) and not hud().title.text.contains(g.name), "it names no guard")
	j.search(g)
	await frames()
	check(ring().visible and hud().title.text == WantedHud.STATE_TEXT.searched, "the guard lost sight and searches: 'searching', the ring stays (%s)" % hud().title.text)
	j.release(g, "searched")
	await frames()
	check(not ring().visible and hud().visible and hud().title.text == WantedHud.STATE_TEXT.wanted, "the search given up: 'Wanted', and no ring (nobody hunting now)")
	if guards.size() > 1:
		j.learn(guards[1], ref, [ci], p.pos)
		j.engage(guards[1], ref, "responding", p.pos)
		await frames()
		check(ring().visible and hud().title.text == WantedHud.STATE_TEXT.coming, "a guard sent to where the player was reported: 'coming' (%s)" % hud().title.text)
	var k := j.record(ref, "killing", victim, p.pos, 1)
	j.learn(g, ref, [k], p.pos)
	await frames()
	check(hud().why.text.begins_with("For killing " + who), "the gravest crime the guards know is named (%s)" % hud().why.text)
	# out of the way: under the status box, clear of the prompt and the touch buttons, desktop and phone
	for phone in [false, true]:
		main.settings.phone = phone
		main.ui.fit_safe_area()
		await frames(4)
		var r := hud().get_global_rect()
		var sb: Rect2 = main.ui.status_box.get_global_rect()
		var clear := not r.intersects(main.ui.prompt_box.get_global_rect()) and r.position.y >= sb.end.y
		for b in main.ui.touch_buttons():
			if (b as Control).is_visible_in_tree() and r.intersects((b as Control).get_global_rect()):
				clear = false
		check(clear and r.end.y < main.get_viewport().get_visible_rect().size.y * 0.6, "%s: the note is under the status box, clear of the prompt and buttons (%s)" % ["phone" if phone else "desktop", r])
	main.settings.phone = false
	main.ui.fit_safe_area()
	# settled: everything goes
	for x in guards:
		if not x.pursuit.is_empty():
			j.release(x, "settled")
	j.settle(ref, [], "fined")
	await frames()
	check(not hud().visible and not ring().visible, "the crimes settled (a fine paid): no note, no ring")
	# a closed case (the offender died) shows nothing either
	var ci2 := j.record(ref, "theft", victim, p.pos, 1)
	j.learn(g, ref, [ci2], p.pos)
	j.engage(g, ref, "pursuing")
	await frames()
	check(ring().visible and hud().why.text.begins_with("For stealing from " + who), "a theft: 'stealing from' its victim (%s)" % hud().why.text)
	for x in guards:
		if not x.pursuit.is_empty():
			j.release(x, "closed")
	j.close(ref, "died")
	await frames()
	check(not hud().visible and not ring().visible, "a closed case: nothing shown")
	# per player: a guest's case is the guest's alone
	var gu := PlayerState.new()
	gu.name = "Gwen"
	gu.family = "Fairlight"
	Identity.register_player(w, gu)
	w.give_start_kit(gu)
	w.add_guest(gu)
	gu.pos = p.pos + Vector2(2, 0)
	var gref := w.player_ref(gu)
	var gi := j.record(gref, "assault", victim, gu.pos, 1)
	j.learn(g, gref, [gi], gu.pos)
	j.engage(g, gref, "pursuing")
	await frames()
	check(not hud().visible and not ring().visible, "the host's screen: a guest's crime shows nothing on the host's own player")
	w.set_local_player(gu)                       # as on the guest's machine, whose local player is the guest
	await frames()
	check(hud().visible and ring().visible and hud().title.text == WantedHud.STATE_TEXT.pursued, "the guest's screen: its own case, ring and note")
	w.set_local_player(null)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
