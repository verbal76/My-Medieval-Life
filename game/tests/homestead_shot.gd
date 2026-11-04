extends SceneTree
## B25R1-010 / B25R1-014 polish: the player's homestead works in the real game scene, screenshotted to be looked at, with the
## checks printed (ok / FAIL). Needs a display:
##   xvfb-run -a godot --rendering-driver opengl3 --resolution 1280x720 --path game --script res://tests/homestead_shot.gd -- OUTDIR
## A site where a pen and a smithy both fit beside the house is chosen from the homesteaders' own search; the house's materials,
## the axe and the smith's inputs are put in the pack (scaffolding: this checks the drawing, the prompts and the stations, not
## the economy, which player_homestead_test checks). Shots, at the game's own zoom: 1 the prompts at the door; 2 the pen
## staked out; 3 the pen fenced; 4 the well dug (stone waiting); 5 the well's ring; 6 the well built; 7 the smithy built and
## the anvil's prompt; 8 the outlaws' camp refused, 9 trusted (the trade prompt).

var main
var dir := "/tmp/homestead_shot"
var failures := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		dir = args[0]
	DirAccess.make_dir_recursive_absolute(dir)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(cond: bool, what: String) -> void:
	if not cond:
		failures += 1
		print("FAIL ", what)
	else:
		print("ok   ", what)


func _frames(k: int) -> void:
	for i in k:
		await process_frame


func _shot(name: String, at: Vector2) -> void:
	main.ui.hide_all()
	main.camera.position_smoothing_enabled = false
	main.follow_at = main._in_view(at * main.T)
	await _frames(20)
	var img := root.get_texture().get_image()
	img.save_png("%s/%s.png" % [dir, name])
	print("shot ", name)


func _labels() -> Array:
	return main.target_options.map(func(t): return str(t.get("label", "")))


## A fake claim at `lay` (the shape Homesteads._new_claim gives) to ask where a pen and a smithy would go before claiming.
func _fits(w: World, lay: Dictionary) -> bool:
	var house: Rect2i = lay.house
	var land: Rect2i = lay.land
	var c := {"id": "probe", "owner": "", "x": land.position.x, "y": land.position.y, "w": land.size.x, "h": land.size.y,
		"house": {"x": house.position.x, "y": house.position.y, "w": house.size.x, "h": house.size.y, "door": [lay.door.x, lay.door.y]}}
	return w.wilds._pen_rect(c) != Rect2i() and w.wilds._workshop_rect(c, "workshop_smithy") != Rect2i()


func _fell(w: World, cells: Array) -> void:
	for cell: Vector2i in cells:
		var t := w.tree_at(cell)
		if t.is_empty():
			continue
		for k in 30:
			if not w.player.inv.has("axe"):
				w.player.inv.add("axe", 1)
			if str(w.player_chop(t, 1, "axe").get("result", "")) != "blow":
				break


func _stand(w: World, cell: Vector2i, face: Vector2) -> void:
	w.player.pos = Vector2(cell) + Vector2(0.5, 0.5)
	main.player_sprite.dir = {Vector2.DOWN: 0, Vector2.RIGHT: 2, Vector2.UP: 4, Vector2.LEFT: 6}[face]
	await _frames(3)
	main._find_target()


func _run() -> void:
	main.save_path = "user://test_saves/homestead_shot/save1.json"
	main.new_game()
	main.ui.hide_all()
	await _frames(5)
	var w: World = main.world
	var hs: Homesteads = w.homesteads
	var p := w.player
	# ---- a site where the pen and the smithy both fit
	var lay := {}
	var seen := 0
	var v := Rect2i(0, 0, w.map.w, w.map.h)
	var from := Vector2.ZERO
	for ring in range(4, 40, 3):                 # open country round the village, nearest first, as a player would walk out
		for k in 24:
			if not lay.is_empty():
				break
			var a := TAU * k / 24.0
			var at := Vector2(v.get_center()) + Vector2(cos(a), sin(a)) * (maxf(v.size.x, v.size.y) / 2.0 + ring * 2.0)
			var l := hs.player_layout(at)
			if hs.refusal(l.land) != "":
				continue
			seen += 1
			if _fits(w, l):
				lay = l
				from = at
	print("     eligible sites looked at: ", seen)
	check(not lay.is_empty(), "a site with room for a pen and a smithy")
	if lay.is_empty():
		_end()
		return
	p.pos = from
	check(hs.player_claim(p) == "", "the player claims it")
	var c: Dictionary = hs.claims[-1]
	_fell(w, hs.clear_ground(c))
	for id in c.site.need:
		p.inv.add(str(id), int(c.site.need[id]))
	hs.player_deliver(p, str(c.id))
	check(bool(c.site.done), "the house stands")
	# ---- 1: the prompts at the door
	await _stand(w, Homesteads.step_of(c), Vector2.DOWN)
	var labs := _labels()
	print("     targets at the door: ", labs)
	check(labs.any(func(l): return l.begins_with("Fence a pen")) and labs.any(func(l): return l.begins_with("Mark out a smithy")), "the door offers the pen and the smithy")
	await _shot("1_door_prompts", p.pos)
	# ---- 2, 3: the pen
	check(w.wilds.player_work(p, "wild_work_begin", "%s|pen" % c.id) == "", "the pen is marked out")
	var pen := w.wilds.work_of(c, "pen")
	var pr := Rect2i(int(pen.rect[0]), int(pen.rect[1]), int(pen.rect[2]), int(pen.rect[3]))
	await _stand(w, Vector2i(pr.position.x + pr.size.x / 2, pr.end.y), Vector2.UP)
	print("     targets at the pen: ", _labels())
	await _shot("2_pen_staked", Vector2(pr.get_center()))
	for id in pen.need:
		p.inv.add(str(id), int(pen.need[id]))
	var tries := 0
	while not bool(pen.done) and tries < 50:
		tries += 1
		w.wilds.player_work(p, "wild_work", "%s|%s" % [c.id, pen.id])
	check(bool(pen.done) and not w.wilds.pen_of_claim(c).is_empty(), "the pen is fenced (%d uses) and is a pen" % tries)
	var gate := Vector2i(pr.position.x + pr.size.x / 2, pr.end.y - 1)
	check(w.map.overworld.is_solid(pr.position) and not w.map.overworld.is_solid(gate), "its fence is solid, its gate open")
	await _stand(w, gate + Vector2i(0, 1), Vector2.UP)
	await _shot("3_pen_fenced", Vector2(pr.get_center()))
	# ---- 4, 5, 6: the well
	var wc := Homesteads.door_of(c) + Vector2i(3, 1)        # where a homesteader's well goes (Wilds._well_cell_of)
	var land := Homesteads.rect_of(c)
	if w.map.overworld.is_solid(wc) or pr.grow(1).has_point(wc):
		_fell(w, [wc])
	print("     land ", land, " house ", Homesteads.house_of(c), " pen ", pr, " well at ", wc)
	await _stand(w, wc, Vector2.DOWN)
	check(w.wilds.player_well(p, "wild_well_mark", str(c.id)) == "", "the well is marked out at %s" % wc)
	var wl := w.wilds.work_of(c, "well")
	p.inv.add("stone", 2)
	w.wilds.player_well(p, "wild_well", str(wl.id))
	await _stand(w, wc + Vector2i(-2, 1), Vector2.RIGHT)           # out of the way of the well in the shots
	await _shot("4_well_dig", Vector2(wc))
	for id in wl.need:
		p.inv.add(str(id), int(wl.need[id]))
	w.wilds.player_well(p, "wild_well", str(wl.id))
	w.wilds.player_well(p, "wild_well", str(wl.id))
	await _stand(w, wc + Vector2i(-2, 1), Vector2.RIGHT)
	check((wl.need as Dictionary).is_empty() and not bool(wl.done), "the well's materials are in, digging begun")
	await _shot("5_well_ring", Vector2(wc))
	tries = 0
	while not bool(wl.done) and tries < 50:
		tries += 1
		w.wilds.player_well(p, "wild_well", str(wl.id))
	check(bool(wl.done), "the well is dug (%d uses)" % tries)
	await _stand(w, wc + Vector2i(-2, 1), Vector2.RIGHT)
	await _shot("6_well_built", Vector2(wc))
	# ---- 7: the smithy, its stations, crafting at its anvil
	await _stand(w, Homesteads.step_of(c), Vector2.DOWN)
	check(w.wilds.player_work(p, "wild_work_begin", "%s|workshop_smithy" % c.id) == "", "the smithy is marked out")
	var sm := w.wilds.work_of(c, "workshop_smithy")
	var sr := Rect2i(int(sm.rect[0]), int(sm.rect[1]), int(sm.rect[2]), int(sm.rect[3]))
	for id in sm.need:
		p.inv.add(str(id), int(sm.need[id]))
	w.wilds.player_work(p, "wild_work", "%s|%s" % [c.id, sm.id])
	_fell(w, w.wilds.clear_rect(sr))
	await _stand(w, Vector2i(sr.position.x + sr.size.x / 2, sr.end.y), Vector2.UP)
	print("     targets at the smithy's frame: ", _labels())
	tries = 0
	while not bool(sm.done) and tries < 200:
		tries += 1
		var why: String = w.wilds.player_work(p, "wild_work", "%s|%s" % [c.id, sm.id])
		if why != "":
			print("     ", why)
			break
	check(bool(sm.done), "the smithy is built (%d uses)" % tries)
	var mine := w.stations.keys().filter(func(id) -> bool: return str(id).begins_with("cs_%s_" % c.id))
	check(mine.size() == 2, "its forge and anvil are registered stations (%s)" % [mine])
	var anvil := ""
	for id in mine:
		if str(w.stations[id].type) == "anvil":
			anvil = str(id)
	if anvil != "":
		var use := Vector2i(w.station_use(anvil))
		await _stand(w, use, Vector2.LEFT)
		print("     targets at the anvil: ", _labels())
		check(_labels().any(func(l): return "nvil" in l), "the anvil is offered at its place")
		p.inv.add("iron_bar", 1)
		for t in ["hammer", "tongs"]:
			if not p.inv.has(t):
				p.inv.add(t, 1)
		while p.level("smithing") < 1:
			p.gain("smithing", 50)
		var b: Dictionary = w.player_craft_begin("forge_chisel", anvil)
		print("     craft begin: ", b)
		var r: Dictionary = w.player_craft("forge_chisel") if bool(b.get("ok", false)) else {}
		check(str(r.get("result", "")) == "ok" and p.inv.has("chisel"), "a chisel forged at the homestead's anvil (%s)" % r)
		await _shot("7_smithy", Vector2(sr.get_center()))
	# ---- 8, 9: the outlaws' camp
	var bandit: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "bandit" and str(hs.claim_of(n).get("faction", "")) == "outlaw":
			bandit = n
			break
	check(bandit != null, "an outlaw of the camp")
	if bandit != null:
		var cc := hs.claim_of(bandit)
		var at := Homesteads.step_of(cc)
		bandit.pos = Vector2(at) + Vector2(0.5, 0.5)
		bandit.plan = []
		await _stand(w, at + Vector2i(0, 1), Vector2.UP)
		print("     remote: ", hs.remote(bandit), " target ", bandit.target, "; targets at the camp: ", _labels())
		check(_labels().any(func(l): return "eyes you warily" in l), "a stranger is refused at the camp")
		await _shot("8_camp_refused", bandit.pos)
		var cf: Dictionary = GameData.b("wilds")
		var keep := int(cf.trust_at)
		cf.trust_at = 0                             # (scaffolding: a trusted friend)
		bandit.pos = Vector2(at) + Vector2(0.5, 0.5)
		await _stand(w, at + Vector2i(0, 1), Vector2.UP)
		print("     targets trusted: ", _labels(), "; ", bandit.name, " carries ", bandit.inv.to_dict() if bandit.inv.has_method("to_dict") else bandit.inv)
		bandit.inv.add("axe", 2)                     # (scaffolding: the camp's crafter made two axes)
		check(w.brain.for_sale(bandit).has("axe"), "the outlaw offers a spare axe at the camp (%s)" % [w.brain.for_sale(bandit)])
		var shop: Array = main.target_options.filter(func(t): return str(t.get("kind", "")) == "shop")
		check(not shop.is_empty(), "a trusted friend is offered trade at the camp")
		if not shop.is_empty():
			main.target = shop[0]
			main._use()
			await _frames(5)
			var img := root.get_texture().get_image()
			img.save_png("%s/9_camp_trade.png" % dir)
			print("shot 9_camp_trade")
			p.coins += 100
			var bought: Dictionary = w.player_buy_many(bandit, "axe", 1)
			check(str(bought.result) == "bought", "the player buys the spare axe from the outlaw (%s)" % bought)
		cf.trust_at = keep
	_end()


func _end() -> void:
	print("homestead_shot: %d failures" % failures)
	quit(1 if failures > 0 else 0)
