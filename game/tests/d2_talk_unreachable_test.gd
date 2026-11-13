extends "res://tests/player_journey_test.gd"
## D2 (Extra Life preview session, 2026-11-12): tapping a villager the player cannot reach (behind a field's fence, across water)
## left the player walking toward them for ever: Main.talk_to stayed set and _talk_step pulled the walk back to them every frame,
## with no word (scripted runs with no key input stood by a fence for game days). Now, without getting nearer for
## Main.TALK_GIVE_UP seconds, the walk is given up and the player is told; a villager who can be reached is still walked up to.
##   godot --headless --path game --script res://tests/d2_talk_unreachable_test.gd


func _run() -> void:
	var ui = main.ui
	_press("New game")
	var edits: Array = ui.panel_body.find_children("*", "LineEdit", true, false)
	if edits.size() >= 2:
		(edits[0] as LineEdit).text = "Ada"
		(edits[1] as LineEdit).text = "Thorne"
	_press("Begin")
	await process_frame
	_press("Begin")
	await process_frame
	var w: World = main.world
	check(w != null and main.running, "fixture: a new world in play")
	if w == null:
		_end()
		return
	var p := w.player
	var target: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.pos.distance_to(p.pos) > 4.0 and n.pos.distance_to(p.pos) < 20.0 and n.depth == w.player_level and not main._covered(n):
			target = n
			break
	check(target != null, "fixture: a villager 4-20 tiles away")
	if target == null:
		_end()
		return
	# an unreachable villager: the player's walk is held where it stands (as a fence would hold it), the villager kept still
	main.talk_to = target
	var hold := p.pos
	var gave_up_at := -1.0
	var t := 0.0
	while t < 10.0:
		target.plan = [w.brain.work(600, "", {}, "idle")]
		main._process(DT)
		p.pos = hold                      # it cannot get nearer
		t += DT
		if main.talk_to == null:
			gave_up_at = t
			break
	check(gave_up_at > 0.0 and gave_up_at <= main.TALK_GIVE_UP + 0.5, "the walk to a villager the player stands still against is given up after about %.0f s (%.1f s)" % [main.TALK_GIVE_UP, gave_up_at])
	check(main.move_to == Vector2.INF, "the player is no longer walked toward them")
	var said := false
	for m in main.ui.find_children("*", "Label", true, false):
		if str((m as Label).text).contains("can't reach"):
			said = true
	check(said, "the player is told they can't reach the villager")
	# a walk on which the player keeps moving (a detour, a villager walking away) is not given up
	main.talk_to = target
	var kept := true
	for i in 50:
		target.plan = [w.brain.work(600, "", {}, "idle")]
		main._process(DT)
		p.pos = hold + Vector2(cos(i * 0.5), sin(i * 0.5))      # the player keeps walking (round a circle, never arriving)
		if main.talk_to == null:
			kept = false
			note("cleared at frame %d: covered %s, dist %.1f" % [i, str(main._covered(target)), target.pos.distance_to(p.pos)])
			break
	check(kept, "a walk on which the player keeps moving is not given up (5 s)")
	main.talk_to = null
	p.pos = hold
	# a reachable villager is still walked up to and talked with
	main.ui.hide_all()
	main.talk_to = target
	var opened := false
	for i in 900:
		target.plan = [w.brain.work(600, "", {}, "idle")]
		main._process(DT)
		if main.ui.modal():
			opened = true
			break
		if main.talk_to == null and not main.ui.modal():
			break
	check(opened, "a villager the player can reach is still walked up to and talked to (%.1f tiles left, talk_to %s)" % [p.pos.distance_to(target.pos), str(main.talk_to)])
	_end()


func _end() -> void:
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
