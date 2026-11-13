extends SceneTree
## ND-28 (MP-GUEST-TRUST follow-up): a modified guest client sends its gathering and sword verbs straight to the host's gateway
## (NetActions.apply, the host's own request path), bypassing its interface's timers and reach:
##   (1) swings at a seam (player_mine) faster than the single-player swing takes are refused; at the player's own pace each is
##       taken, so legitimate mining goes on; over many requests the guest gets no more swings than the time allows;
##   (2) the same for the blows of a felling (player_chop: the felling's time over its blows);
##   (2b) a cell tilled (farm.till) faster than the till takes is refused; at its pace it is tilled, and the host credits the
##       guest's farming work record with the till's time (the guest names no figure);
##   (3) sword blows (player_melee_npc, player_melee_animal) faster than a swing are refused; at a swing's pace they land;
##   (4) a seam or tree more than the single-player cell reach away (World.player_reach_cell), but within the screen's 24 tiles,
##       is refused; a pickaxe or axe the guest does not hold is refused;
##   (5) a sword blow at a villager or animal 6 tiles off (inside the old 24-tile screen check) is refused; one beside it lands.
## Coins and goods are conserved across every refusal.
##   godot --headless --path game --script res://tests/nd28_guest_pace_test.gd
var checks := 0
var failures := 0
var now := 1000.0          # the host's pacing clock, in seconds (NetActions.clock)
const FAR := "That is too far away."


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		failures += 1


func verb(w: World, g: PlayerState, path: String, args: Array) -> Dictionary:
	var raw = w.as_actor(g, func(): return NetActions.enc(w, args))
	return NetActions.apply(w, g, "verb", {"path": path, "a": raw})


func _open(w: World, c: Vector2i) -> bool:
	return not w.map.is_solid(c) and w.place_of(Vector2(c) + Vector2(0.5, 0.5)) == ""


func _beside(w: World, c: Vector2i) -> Vector2:
	for off in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
		if _open(w, c + off):
			return Vector2(c + off) + Vector2(0.5, 0.5)
	return Vector2(c) + Vector2(0.5, 0.5)


func _init() -> void:
	GameData.ensure()
	NetActions.clock = func(): return now
	var w := World.new()
	w.setup(VillageMap.load_default(), 8807)
	var g := PlayerState.new()
	g.name = "Gwen"
	g.family = "Forge"
	g.sex = "female"
	g.born = w.player.born
	Identity.register_player(w, g)
	w.give_start_kit(g)
	g.net_key = "b".repeat(32)
	w.add_guest(g)
	g.pos = w.player.pos
	g.inv.add("pickaxe", 1)
	g.inv.add("axe", 1)
	g.skills["combat"] = 0

	# 1. Mining: paced by the single-player swing.
	var seam := {}
	for dp in w.deposits:
		if World.level_of(dp) == 0 and int(dp.amount) > 12 and str(dp.ore) == "stone":
			seam = dp
			break
	check(not seam.is_empty(), "setup: a stone seam with ore to spare")
	if not seam.is_empty():
		var cell := Vector2i(int(seam.x), int(seam.y))
		g.pos = _beside(w, cell)
		var plan: Dictionary = w.player_mine_plan(seam, g)
		check(bool(plan.get("ok", false)), "setup: the guest may swing at the seam (%s)" % str(plan.get("why", "")))
		var secs := float(plan.get("secs", 1.0))
		var s0 := g.inv.count("stone")
		var r := verb(w, g, "player_mine", [seam, "pickaxe"])
		check(r.ok and g.inv.count("stone") > s0, "the first swing at the seam is taken (%s)" % r.text)
		var s1 := g.inv.count("stone")
		var taken := 0
		for i in 10:                                  # a forged client: ten swings in the same instant
			if bool(verb(w, g, "player_mine", [seam, "pickaxe"]).ok):
				taken += 1
		check(taken == 0 and g.inv.count("stone") == s1, "ten more swings sent at once are refused (taken %d), no ore" % taken)
		now += secs
		r = verb(w, g, "player_mine", [seam, "pickaxe"])
		check(r.ok and g.inv.count("stone") > s1, "after the swing's own time (%.2f s) the next is taken" % secs)
		# jitter: a late request and then a prompt one are both taken (the slack), and the pace holds over many
		now += secs * 1.2
		var a := bool(verb(w, g, "player_mine", [seam, "pickaxe"]).ok)
		now += secs * 0.85
		var b := bool(verb(w, g, "player_mine", [seam, "pickaxe"]).ok)
		check(a and b, "a swing that arrives late and the next close behind it are both taken (network jitter)")
		var t0 := now
		var n := 0
		for i in 40:                                  # a forged client sending every half swing
			now += secs * 0.5
			if bool(verb(w, g, "player_mine", [seam, "pickaxe"]).ok):
				n += 1
		var allowed := int((now - t0) / secs) + 1
		check(n <= allowed and n >= allowed - 2, "sending twice as fast earns no more swings than the time allows (%d taken in %.1f s, %d allowed)" % [n, now - t0, allowed])
		# reach: the single-player cell reach, not the screen
		now += secs * 2.0
		g.pos = Vector2(cell) + Vector2(0.5, 6.5)
		var s2 := g.inv.count("stone")
		r = verb(w, g, "player_mine", [seam, "pickaxe"])
		check(not r.ok and g.inv.count("stone") == s2, "a seam 6 cells off (within the screen's 24 tiles) is out of reach (%s)" % r.text)
		g.pos = _beside(w, cell)
		r = verb(w, g, "player_mine", [seam, "steel_pickaxe" if not g.inv.has("steel_pickaxe") else "nonesuch"])
		check(not r.ok and g.inv.count("stone") == s2, "a pickaxe the guest does not hold is refused (%s)" % r.text)
		r = verb(w, g, "player_mine", [seam, "pickaxe"])
		check(r.ok and g.inv.count("stone") > s2, "beside it with its own pickaxe, the swing is taken")

	# 2. Felling: each blow paced by its share of the felling's time.
	var tree := {}
	for t in w.trees:
		if str(t.state) == "grown" and _open(w, Vector2i(int(t.x), int(t.y) + 1)):
			tree = t
			break
	check(not tree.is_empty(), "setup: a grown tree")
	if not tree.is_empty():
		var tc := Vector2i(int(tree.x), int(tree.y))
		g.pos = Vector2(tc) + Vector2(0.5, 1.5)
		var fp: Dictionary = w.player_fell_plan(tree, g)
		check(bool(fp.get("ok", false)), "setup: the guest may fell the tree (%s)" % str(fp.get("why", "")))
		var blow := float(fp.get("secs", 1.0)) / float(Trees.cfg().chops)
		now += 100.0
		var logs0 := g.inv.count("log")
		var res := []
		for i in 12:                                  # a forged client: every blow at once
			var r := verb(w, g, "player_chop", [tree, 1, "axe"])
			res.append(str(r.get("result", {}).get("result", "")) if r.ok and r.get("result") is Dictionary else "refused")
		check(res.count("refused") == 11 and g.inv.count("log") == logs0 and str(tree.state) == "grown",
			"twelve blows sent at once: one taken, the tree still standing (%s)" % ", ".join(res.slice(0, 3)))
		var felled := false
		for i in int(Trees.cfg().chops) + 2:
			now += blow
			var r := verb(w, g, "player_chop", [tree, 1, "axe"])
			check(r.ok, "a blow at the felling's pace (%.2f s) is taken (%s)" % [blow, r.text])
			if r.ok and r.get("result") is Dictionary and str(r.result.get("result", "")) == "felled":
				felled = true
				break
		check(felled and g.inv.count("log") > logs0, "at the player's pace the tree is felled and its logs are the guest's")
		var far_tree := {}
		for t in w.trees:
			if str(t.state) == "grown" and Vector2(int(t.x), int(t.y)).distance_to(g.pos) > 5.0 and Vector2(int(t.x), int(t.y)).distance_to(g.pos) < 20.0:
				far_tree = t
				break
		if not far_tree.is_empty():
			now += 100.0
			var r := verb(w, g, "player_chop", [far_tree, 1, "axe"])
			check(not r.ok and str(far_tree.state) == "grown" and int(w.tree_hits(Vector2i(int(far_tree.x), int(far_tree.y)))) == 0,
				"a tree more than 5 tiles off (within the screen's 24) takes no blow (%s)" % r.text)

	# 2b. Farm work: a cell tilled is paced by the till's time and credited to the guest's work record by the host.
	g.coins = 3000
	var gref: String = w.player_ref(g)
	var rect: Rect2i = w.construction.find_ground("house", Vector2i(30, 30), gref)
	var land: Dictionary = w.property.claim(rect, gref, false)
	check(not land.is_empty() and w.holds(gref, land), "setup: the guest holds a parcel of open ground (%s)" % w.property.why)
	if not land.is_empty():
		var cells := []
		for j in range(1, int(land.h) - 1):
			for i in range(1, int(land.w) - 1):
				var c := Vector2i(int(land.x) + i, int(land.y) + j)
				if cells.size() < 3 and str(w.as_actor(g, func(): return w.farm.till_refusal(c, g))) == "":
					cells.append(c)
		check(cells.size() == 3, "setup: three cells the guest may till")
		if cells.size() == 3:
			g.pos = Vector2(cells[0]) + Vector2(0.5, 1.5)
			g.stamina = g.stamina_cap()
			var till_secs := float(w.farm.till_cost(g).seconds)
			var gm := float(GameData.b("game_minutes_per_second"))
			var fd0 := w.experience.days(gref, "farming")
			now += 100.0
			var r1 := verb(w, g, "farm.till", [cells[0], g])
			var r2 := verb(w, g, "farm.till", [cells[1], g])
			check(r1.ok and w.farm.cells.has(cells[0]) and not r2.ok and not w.farm.cells.has(cells[1]),
				"a cell tilled is taken; a second sent at once is refused (%s)" % r2.text)
			now += till_secs
			g.stamina = g.stamina_cap()
			var r3 := verb(w, g, "farm.till", [cells[1], g])
			check(r3.ok and w.farm.cells.has(cells[1]), "a till's time later (%.1f s) the next cell is tilled (%s)" % [till_secs, r3.text])
			var want := 2.0 * till_secs * gm / float(WorkExperience.cfg().get("minutes_per_day", 480))
			var got := w.experience.days(gref, "farming") - fd0
			check(absf(got - want) < want * 0.01 + 0.00001, "the two cells are credited to the guest's farming record by the host (+%.5f days, want %.5f)" % [got, want])

	# 3 and 5. The sword: a swing's pace, a sword's reach.
	var villager: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.job != "guard" and n.depth == 0:
			villager = n
			break
	var beast: Animal = null
	for a: Animal in w.fauna.animals:
		if a.alive and a.wild():
			beast = a
			break
	var swing := Combat.swing_secs(g)
	now += 100.0
	g.pos = villager.pos + Vector2(6.0, 0)
	var hp0 := villager.hp
	var r := verb(w, g, "player_melee_npc", [villager])
	check(not r.ok and r.text == FAR and villager.hp == hp0 and g.crimes.is_empty(), "a sword blow at a villager 6 tiles off (inside the screen's 24) is refused: unharmed, no crime (%s)" % r.text)
	g.pos = villager.pos + Vector2(0.5, 0)
	r = verb(w, g, "player_melee_npc", [villager])
	check(r.ok and villager.hp < hp0, "beside the villager the blow lands (%.1f -> %.1f)" % [hp0, villager.hp])
	var hp1 := villager.hp
	var landed := 0
	for i in 8:
		if bool(verb(w, g, "player_melee_npc", [villager]).ok):
			landed += 1
	check(landed == 0 and villager.hp == hp1, "eight more blows sent in the same instant are refused (landed %d)" % landed)
	now += swing
	r = verb(w, g, "player_melee_npc", [villager])
	check(r.ok, "a swing's time later (%.2f s) the next blow lands" % swing)
	if beast != null:
		now += swing
		g.pos = beast.pos + Vector2(6.0, 0)
		var bhp := beast.hp
		r = verb(w, g, "player_melee_animal", [beast])
		check(not r.ok and r.text == FAR and beast.hp == bhp, "a blow at an animal 6 tiles off is refused, unharmed")
		g.pos = beast.pos + Vector2(0.5, 0)
		r = verb(w, g, "player_melee_animal", [beast])
		check(r.ok and (beast.hp < bhp or not beast.alive), "beside it the blow lands")
		r = verb(w, g, "player_melee_animal", [beast])
		check(not r.ok, "and a second at once is refused (one sword: villagers and animals share the pace)")
	else:
		check(false, "setup: a wild animal")
	print("nd28_guest_pace_test: %d checks, %d failures" % [checks, failures])
	NetActions.clock = Callable()
	w.dispose()
	quit(1 if failures > 0 else 0)
