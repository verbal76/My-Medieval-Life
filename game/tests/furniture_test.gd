extends SceneTree
## Furniture (PL1-07 poses, PL2-013 player housing): villagers lie ON their beds and eat seated on their
## chairs, then stand; the player sits on chairs (any input stands up), sleeps in their own bed and wakes
## beside it, cooks at a home oven (no smelting) and prepares food at a home table; all of it by spot kind,
## so a new room gets it. Run: godot --headless --path game --script res://tests/furniture_test.gd

var main
var failures := 0


func check(cond: bool, what: String) -> void:
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://test_saves/furniture_test/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _sprite(n: NPC) -> ActorSprite:
	var s := ActorSprite.new()
	s.setup(n.sprite)
	main.add_child(s)
	s.scale = Vector2.ONE * Life.npc_scale(n, main.world.minutes)
	return s


func _centre(c) -> Vector2:
	return Vector2(int(c[0]), int(c[1])) + Vector2(0.5, 0.5)


func _run() -> void:
	main.new_game()
	var w: World = main.world
	var T: int = main.T
	# --- chairs are spots like any other, found in the stool tiles of every home; each is reachable
	var chairs := 0
	var unreachable := []
	for id in w.interiors:
		var door: Vector2i = w.building_door(id)
		for sp in w.interiors[id].spots:
			if sp.kind == "chair":
				chairs += 1
				var use := Vector2i(int(sp.use[0]), int(sp.use[1]))
				if use != door and w.map.find_path(door, use).is_empty():
					unreachable.append("%s %s" % [id, sp.use])
	check(chairs >= 30, "the map's interiors have chair spots (%d)" % chairs)
	check(unreachable.is_empty(), "every chair's use cell can be reached from its door %s" % [unreachable.slice(0, 3)])
	var manor_chairs: int = w.interiors["b_manor"].spots.filter(func(s): return s.kind == "chair").size()
	check(manor_chairs >= 4, "the manor has its dining chairs (%d)" % manor_chairs)
	# the generic rule: a stool tile in any interior, at any origin, becomes a chair facing the adjacent table
	var it := {"area": [[10, 10], [11, 10], [12, 10]], "floor": [[10, 10], [12, 10]], "spots": [{"kind": "table", "at": [12, 10], "use": [12, 10]}]}
	var got := Furniture.with_chairs(it, {"below1": [-1, Furniture.CHAIR_TILES[0], -1]}, 3, Vector2i(10, 10))
	var gc: Array = got.spots.filter(func(s): return s.kind == "chair")
	check(gc.size() == 1 and gc[0].at == [11, 10] and gc[0].face == "E" and gc[0].use == [10, 10], "a stool tile in a new interior becomes a chair facing its table, used from the free cell beside it")
	# --- villagers asleep lie on their bed, not in it
	var manor_family := w.npcs.filter(func(n: NPC): return n.alive and n.home == "b_manor")
	check(manor_family.size() >= 2, "the manor has a family (%d)" % manor_family.size())
	var lying := 0
	var off := []
	var zbad := []
	for n: NPC in manor_family.slice(0, 4):
		var bed := w.home_spot(n, "bed")
		n.pos = _centre(bed.use)
		n.anim = "sleep"
		var s := _sprite(n)
		if main._show_sleeper(n, s):
			lying += 1
			var body := s.position + Vector2(0, ActorSprite.LIE_BODY_Y).rotated(s.rotation) * s.scale.x
			if body.distance_to(_centre(bed.at) * T) > ActorSprite.LIE_FOOT_SHIFT + 0.5:
				off.append(n.name)
			if s.z_index < 1 or s.pose != "lie":
				zbad.append(n.name)
			var want_row := 6 if str(bed.get("head", "left")) == "right" else 2
			check(s.pose_row == want_row, "%s lies with the head toward the pillow (%s: row %d)" % [n.name, bed.get("head"), s.pose_row])
		s.queue_free()
	check(lying == mini(4, manor_family.size()), "every sleeping family member is drawn lying on their bed (%d)" % lying)
	check(off.is_empty(), "the lying body is centred on the bed %s" % [off])
	check(zbad.is_empty(), "the sleeper is drawn above the bed's tiles %s" % [zbad])
	# up again
	var n0: NPC = manor_family[0]
	var s0 := _sprite(n0)
	n0.anim = "sleep"
	n0.pos = _centre(w.home_spot(n0, "bed").use)
	main._show_sleeper(n0, s0)
	n0.anim = "idle"
	check(not main._show_sleeper(n0, s0), "awake, they are no longer drawn in bed")
	s0.stand()
	check(s0.pose == "" and s0.rotation == 0.0 and s0.z_index == 0, "standing again resets the pose, rotation and layer")
	# --- eating seated, then standing
	var meal: Array = main.world.brain._home_meal(n0)
	var chair := w.home_spot(n0, "chair")
	check(not chair.is_empty() and str(meal[1].anim) == "sit" and meal[0].k == "go", "a family member with a chair eats seated: walks to it, then a sitting work step")
	check(meal[1].min == 15.0 and meal[1].act == "eat_home", "the meal's length and effect are unchanged")
	n0.pos = _centre(chair.use)
	n0.anim = "sit"
	check(main._show_sitter(n0, s0) and s0.pose == "sit" and s0.z_index == 1, "seated on the chair, drawn over its tile")
	var feet: float = _centre(chair.at).y * T + ActorSprite.SIT_DROP * s0.scale.x
	check(absf(s0.position.y - feet) < 0.01 and s0.material is ShaderMaterial, "the sitter's hips are on the seat and the lower legs are cut away")
	n0.anim = "idle"
	check(not main._show_sitter(n0, s0), "after the meal they are not drawn seated")
	s0.stand()
	check(s0.material == null, "standing restores the whole body")
	n0.anim = "sit"
	n0.plan.clear()
	w.brain.decide(n0)
	check(n0.anim != "sit", "deciding what to do next stands them up")
	# a home with no chair eats standing at the table as before
	var nochair := w.npcs.filter(func(n: NPC): return n.alive and n.home != "" and w.home_spot(n, "chair").is_empty() and not w.home_spot(n, "table").is_empty())
	if not nochair.is_empty():
		var m2: Array = w.brain._home_meal(nochair[0])
		check(str(m2[1].anim) == "idle", "no chair: eating at the table standing, as before")
	# --- the player: a house of their own (the first home with a chair, a bed, a hearth and a table)
	var p := w.player
	var home := ""
	for id in w.interiors:
		var kinds := {}
		for sp in w.interiors[id].spots:
			kinds[sp.kind] = true
		if kinds.has("chair") and kinds.has("bed") and kinds.has("hearth") and kinds.has("table") and id != "b_manor":
			home = id
			break
	check(home != "", "a home with a chair, a bed, a hearth and a table exists (%s)" % home)
	p.home = home
	var spots: Array = w.interiors[home].spots
	var cs: Dictionary = spots.filter(func(s): return s.kind == "chair")[0]
	p.pos = _centre(cs.use)
	var opts := Furniture.options(w, w.place_of(p.pos), _centre(cs.at))
	check(opts.any(func(o): return o.kind == "sit"), "facing a chair in your own home offers Sit")
	p.home = ""
	check(Furniture.options(w, home, _centre(cs.at)).is_empty(), "someone else's house offers nothing")
	p.home = home
	main.sit_down(cs)
	main._sync_player_pose()
	check(main.furn.kind == "sit" and p.pos == _centre(cs.at) and main.player_sprite.pose == "sit", "the player is seated on the chair")
	Input.action_press("move_left")
	main._player_step(0.1)
	Input.action_release("move_left")
	check(main.furn.is_empty() and p.pos == _centre(cs.use), "a movement stands the player up beside the chair")
	main._sync_player_pose()
	check(main.player_sprite.pose == "", "the player is drawn standing again")
	main.sit_down(cs)
	Input.action_press("attack")
	await process_frame
	main._player_step(0.1)
	Input.action_release("attack")
	check(main.furn.is_empty(), "pressing a button stands the player up (keyboard, pad and touch buttons alike)")
	main.sit_down(cs)
	main._tap(Vector2(640, 360))
	check(main.furn.is_empty(), "a tap stands the player up")
	# --- the player's bed
	var bed: Dictionary = spots.filter(func(s): return s.kind == "bed")[0]
	p.pos = _centre(bed.use)
	w.minutes = 20.0 * 60.0
	p.hp = 10.0
	main.rest()
	main._sync_player_pose()
	check(main.furn.kind == "lie" and not main.action.is_empty() and p.pos == _centre(bed.at) and main.player_sprite.pose == "lie", "resting in your own home lies the player in the bed")
	main.action.left = 0.0
	main._player_step(0.1)
	check(main.furn.is_empty() and p.pos == _centre(bed.use), "they wake standing beside the bed")
	check(p.hp == p.hp_cap() and w.hour() >= 6.0 and w.hour() < 8.0, "the night passed: full health, morning (%s)" % w.clock_text())
	w.minutes = 20.0 * 60.0
	p.pos = _centre(bed.use)
	main.rest()
	main.cancel_action("You stop.")
	check(main.furn.is_empty() and w.hour() >= 19.9 and p.pos == _centre(bed.use), "waking early gets up beside the bed with the night unslept")
	# --- the home oven and the food table
	var hearth: Dictionary = spots.filter(func(s): return s.kind == "hearth")[0]
	var table: Dictionary = spots.filter(func(s): return s.kind == "table")[0]
	var oven_id := Furniture.station_id(home, hearth)
	var table_id := Furniture.station_id(home, table)
	check(Furniture.station_def(oven_id).type == "oven" and Furniture.station_def(table_id).type == "prep", "a hearth is an oven and a table a food-preparation station, by spot kind")
	check(w.station_refusal(oven_id) == "" and w.station_refusal(table_id) == "", "your own home's oven and table are yours to use")
	p.home = ""
	check(w.station_refusal(oven_id) != "", "another household's oven is not")
	p.home = home
	var oven_rs := GameData.recipes_at("oven")
	check(oven_rs.has("roast_meat") and not oven_rs.any(func(r): return str(r).begins_with("smelt")), "the oven cooks and does not smelt")
	check(GameData.recipes_at("prep") == ["bake_egg_bread", "knead_flatbread", "press_cheese"], "the food table has its own preparation recipes (flatbread, and PL2-015: cheese and egg bread)")
	var ex := Furniture.options(w, home, _centre(hearth.at))
	check(ex.any(func(o): return o.kind == "station" and o.id == oven_id), "facing the hearth offers the oven")
	p.inv.add("wheat", 3)
	var bread := p.inv.count("bread")
	var wheat := p.inv.count("wheat")
	p.pos = _centre(table.use)
	main.craft("knead_flatbread", table_id)
	var guard := 0
	while not main.action.is_empty() and guard < 400:
		main._player_step(0.25)
		guard += 1
	check(p.inv.count("bread") == bread + 1 and p.inv.count("wheat") == wheat - 3, "preparing flatbread at the table turns 3 wheat into a loaf")
	main.ui.show_craft(table_id)
	check(main.ui.panel_body.get_child_count() > 0, "the craft window opens for a home station")
	# --- the wiki
	var wiki := Wiki.build()
	for id in ["sys:sitting", "sys:sleeping", "sys:home_oven", "sys:food_table", "station:prep"]:
		check(wiki.pages.has(id), "wiki page " + id)
	check(wiki.broken_links().is_empty(), "wiki links resolve %s" % [wiki.broken_links().slice(0, 3)])
	print("furniture_test: %s" % ("FAILED %d" % failures if failures else "all passed"))
	quit(1 if failures else 0)
