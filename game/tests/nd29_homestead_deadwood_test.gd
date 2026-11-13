extends SceneTree
## ND-29, owner 2026-11-12 23:10: "Approve deadwood gathering without an axe for ordinary homesteaders. Approve equivalent player
## gathering using existing interaction systems. Provisionally accept 60 minutes per log, one log per tree every four days, and a
## 40-tile gathering radius. Protect three reserved hearth logs from nonessential building consumption. Verify resource
## conservation, determinism, save/load persistence, and long-term sustainability."
##   1 an ordinary homesteader (not the band) with no axe gathers a log of deadwood for the claim's hearth, one of a household at a
##     time; a village household's people do not (they buy firewood in the village)
##   2 the player, with no axe, gathers deadwood (World.player_deadwood_plan / player_gather_deadwood): deadwood_minutes converted
##     as the player's other timed work (/ game_minutes_per_second x 0.6), one log into the pack counted made_log (the goods
##     ledger balances), the same tree's timer as a villager's (a tree gathered by anyone gives nothing for deadwood_seasons), kept
##     over a save and load, given again on its day; a sapling or a stump gives nothing; a full pack takes nothing
##   3 two worlds of one seed gather the same (determinism)
##   4 a claim's workshop leaves keep_logs on the hearth unless it cooks food (Wilds.craft_spare)
##   5 a guest's gathering goes through the host (NetActions, as the guest): one log to the guest, the host's timer, the work
##     credited to the guest's record; a second at once, or from afar, refused
##   6 the interface: Use on a mature tree without an axe starts "Gathering deadwood" for the plan's time and gives one log; with
##     the tree's wood gathered, it starts nothing and says why
##   godot --headless --path game --script res://tests/nd29_homestead_deadwood_test.gd

var checks := 0
var failures := 0
var main
const NONE := Vector2i(1 << 30, 0)


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL: ") + what)
	if not cond:
		failures += 1


## A seed's world with one ordinary homestead claimed (Homesteads.begin, then the claimant arrives, as homestead_test's fixture
## does): {w, n (the homesteader, no axe, no logs, hearth bare), c}.
func homestead(seed := 1) -> Dictionary:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	var hs: Homesteads = w.homesteads
	var cands := []
	for h in w.households.size():
		var o: NPC = w.construction.founder_of(h)
		if o != null and Life.npc_age(w, o) <= 30.0 and hs.gate(h, [o]) == "":
			cands.append([w.property.purse(World.hh_ref(h)), h, o])
	cands.sort()
	if cands.is_empty():
		return {}
	var n: NPC = cands[-1][2]
	w.treasury -= 300
	n.coins += 300
	hs.begin(int(cands[-1][1]), n, [n])
	var c := hs.claim_of(n)
	if c.is_empty():
		return {}
	n.pos = Vector2(Homesteads.step_of(c)) + Vector2(0.5, 0.5)
	n.plan.clear()
	hs._arrive(n, c)
	n.inv.remove("axe", n.inv.count("axe"))
	n.inv.remove("log", n.inv.count("log"))
	var pantry: Inventory = w.households[n.household].pantry
	pantry.remove("log", pantry.count("log"))
	n.hunger = 100.0
	w.minutes = float(w.day()) * 1440.0 + 9.0 * 60.0
	return {"w": w, "n": n, "c": c}


## A mature tree in the village (not the open country) the player can stand beside, or {}.
func village_tree(w: World, skip := []) -> Dictionary:
	for t in w.trees:
		if str(t.state) == "grown" and not t.get("ow", false) and not skip.has(Vector2i(int(t.x), int(t.y))):
			var at := beside(w, Vector2i(int(t.x), int(t.y)))
			if at != Vector2.INF:
				return t
	return {}


func beside(w: World, cell: Vector2i) -> Vector2:
	for dd in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
		var at := Vector2(cell + dd) + Vector2(0.5, 0.5)
		if not w.map.is_solid_world(cell + dd) and w.reaches(at, Vector2(cell) + Vector2(0.5, 0.5)):
			return at
	return Vector2.INF


func logs_held(w: World) -> int:
	return int(SettlementHoldings.goods(w).get("log", 0))


func _init() -> void:
	GameData.ensure()
	var cf: Dictionary = Homesteads.cfg()
	var days := roundi(Life.seasons_to_days(float(cf.deadwood_seasons)))
	case_homesteader(cf)
	case_player(cf, days)
	case_determinism()
	case_workshop(cf)
	case_guest(days)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://test_saves/nd29_homestead_deadwood_test/save1.json"
	process_frame.connect(case_interface, CONNECT_ONE_SHOT)


# 1 ------------------------------------------------------------------------------------------------------------------------
func case_homesteader(cf: Dictionary) -> void:
	var f := homestead()
	check(not f.is_empty(), "fixture: an ordinary homestead claimed")
	if f.is_empty():
		return
	var w: World = f.w
	var n: NPC = f.n
	var c: Dictionary = f.c
	check(not w.households[n.household].get("band", false) and str(c.get("path", "")) != "band", "fixture: the claim is not the band's camp")
	var t: Vector2i = w.homesteads.deadwood_tree(c, n)
	check(t != NONE, "a mature tree stands within deadwood_radius (%s) of the claim (%s)" % [cf.deadwood_radius, t])
	check(w.homesteads.plan_deadwood(n, c) and n.doing == "gathering deadwood", "a homesteader without an axe sets out to gather deadwood (doing: %s)" % n.doing)
	var mins := 0.0
	var acts := []
	for s in n.plan:
		if str(s.k) == "work":
			mins += float(s.min)
		if s.has("args") and (s.args as Dictionary).has("step"):
			acts.append(str(s.args.step))
	check(mins >= float(cf.deadwood_minutes) and acts == ["deadwood", "store_logs"], "the same work as the band's: %.0f minutes, %s" % [mins, acts])
	var o := NPC.new()
	o.id = 999999
	o.household = n.household
	check(not w.homesteads.plan_deadwood(o, c), "one of a household gathers at a time")
	var made0 := int(w.stats.get("made_log", 0))
	var held0 := logs_held(w)
	n.pos = Vector2(t.x + 1, t.y) + Vector2(0.5, 0.5)
	check(w.homesteads.act(n, {"step": "deadwood", "x": t.x, "y": t.y}) and n.inv.count("log") == 1, "at the tree the homesteader gathers one log")
	check(int(w.stats.get("made_log", 0)) == made0 + 1 and logs_held(w) == held0 + 1, "counted produced: made_log +1 and the logs held +1 (no leak)")
	check(not w.homesteads.act(n, {"step": "deadwood", "x": t.x, "y": t.y}) and n.inv.count("log") == 1, "the same tree gives no more")
	n.pos = Vector2(Homesteads.step_of(c)) + Vector2(0.5, 0.5)
	var pantry: Inventory = w.households[n.household].pantry
	check(w.homesteads.act(n, {"step": "store_logs"}) and pantry.count("log") == 1, "the log goes onto the claim's hearth")
	pantry.add("log", int(cf.keep_logs) - 1)
	n.plan.clear()
	n.doing = ""
	check(not w.homesteads.plan_deadwood(n, c), "with keep_logs (%s) on the hearth nobody gathers" % cf.keep_logs)
	pantry.remove("log", pantry.count("log"))
	n.inv.add("axe", 1)
	check(not w.homesteads.plan_deadwood(n, c), "a homesteader with an axe does not gather deadwood (they fell)")
	n.inv.remove("axe", n.inv.count("axe"))
	var v: NPC = null
	for x: NPC in w.npcs:
		if x.alive and x.household >= 0 and not w.households[x.household].has("homestead") and x.role == "adult" and not x.inv.has("axe"):
			v = x
			break
	check(v != null and not w.homesteads.plan_deadwood(v, c) and not w.homesteads.plan_deadwood(v, {}), "a village household's adult does not gather deadwood")
	# by itself: a day of the claim's life; the homesteader gathers and the night's fire burns
	var w2: World = homestead().w
	var g0 := int(w2.stats.get("homestead_deadwood", 0))
	var d0 := w2.day()
	while w2.day() == d0:
		w2.update(1.0)
	check(int(w2.stats.get("homestead_deadwood", 0)) > g0, "in a day the homesteader gathers deadwood by itself (%d)" % (int(w2.stats.get("homestead_deadwood", 0)) - g0))


# 2 ------------------------------------------------------------------------------------------------------------------------
func case_player(cf: Dictionary, days: int) -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var p := w.player
	p.inv = Inventory.new()
	p.tool = ""
	var t := village_tree(w)
	check(not t.is_empty(), "fixture: a mature village tree")
	if t.is_empty():
		return
	var cell := Vector2i(int(t.x), int(t.y))
	p.pos = beside(w, cell)
	var dp := w.player_deadwood_plan(t)
	var want := float(cf.deadwood_minutes) / float(GameData.b("game_minutes_per_second")) * 0.6
	check(dp.ok and is_equal_approx(float(dp.secs), want), "the player may gather it, in %s s (deadwood_minutes %s / %s x 0.6)" % [dp.get("secs"), cf.deadwood_minutes, GameData.b("game_minutes_per_second")])
	var made0 := int(w.stats.get("made_log", 0))
	var held0 := logs_held(w)
	var got := w.player_gather_deadwood(t)
	check(got == {"log": 1} and p.inv.count("log") == 1, "one log into the pack (%s)" % got)
	check(int(w.stats.get("made_log", 0)) == made0 + 1 and int(w.stats.get("player_deadwood", 0)) == 1 and logs_held(w) == held0 + 1,
		"counted produced (made_log +1): the logs held rise by exactly that")
	check(t.state == "grown", "the tree stands")
	var key := "%d,%d" % [cell.x, cell.y]
	check(int(w.homesteads.deadwood.get(key, -1)) == w.day() + days, "the tree's wood is back on day %d (today + %d)" % [w.day() + days, days])
	var dp2 := w.player_deadwood_plan(t)
	check(not dp2.ok and str(dp2.why).contains("gathered") and w.player_gather_deadwood(t).is_empty() and p.inv.count("log") == 1,
		"the same tree gives nothing again (%s)" % dp2.get("why"))
	check(not w.homesteads.take_deadwood(cell), "nor to a villager: one timer for everyone")
	# a tree a villager gathered gives the player nothing
	var t2 := village_tree(w, [cell])
	var c2 := Vector2i(int(t2.x), int(t2.y))
	check(w.homesteads.take_deadwood(c2), "fixture: a villager's gathering of a second tree")
	p.pos = beside(w, c2)
	check(not w.player_deadwood_plan(t2).ok and w.player_gather_deadwood(t2).is_empty(), "a tree a villager gathered gives the player nothing")
	# out of reach
	p.pos = beside(w, cell) + Vector2(12, 0)
	var t3 := village_tree(w, [cell, c2])
	check(not w.player_deadwood_plan(t3).ok and w.player_gather_deadwood(t3).is_empty(), "nothing from out of reach")
	# save and load: the day is kept; the tree gives again on it
	p.pos = beside(w, cell)
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d.duplicate(true))
	var tl := w2.tree_at(cell)
	check(int(w2.homesteads.deadwood.get(key, -1)) == w.day() + days and not w2.player_deadwood_plan(tl).ok, "after a save and load the tree's day holds")
	w2.minutes += float(days - 1) * 1440.0
	check(not w2.player_deadwood_plan(tl).ok, "a day before its day it still gives nothing")
	w2.minutes += 1440.0
	var n0 := w2.player.inv.count("log")
	check(w2.player_deadwood_plan(tl).ok and w2.player_gather_deadwood(tl) == {"log": 1} and w2.player.inv.count("log") == n0 + 1, "on its day it gives one log again")
	# a stump, a sapling: nothing
	var t4 := village_tree(w, [cell, c2])
	var c4 := Vector2i(int(t4.x), int(t4.y))
	p.pos = beside(w, c4)
	w.fell(t4, 0)
	check(not w.player_deadwood_plan(w.tree_at(c4)).ok and w.player_gather_deadwood(w.tree_at(c4)).is_empty(), "a stump gives no deadwood")
	# a full pack: nothing taken, the tree's wood left
	var t5 := village_tree(w, [cell, c2, c4])
	var c5 := Vector2i(int(t5.x), int(t5.y))
	p.pos = beside(w, c5)
	p.inv = Inventory.new()
	p.inv.add("stone", 1)
	p.inv.max_stacks = 1                            # a pack with no room for a new kind (world_test's DVW-A7 fixture)
	check(not p.inv.can_add("log"), "fixture: the pack has no room for a log")
	var lf := p.inv.count("log")
	check(not w.player_deadwood_plan(t5).ok and w.player_gather_deadwood(t5).is_empty() and p.inv.count("log") == lf and not w.homesteads.deadwood.has("%d,%d" % [c5.x, c5.y]),
		"a full pack takes nothing and the tree's wood stays")


# 3 ------------------------------------------------------------------------------------------------------------------------
func case_determinism() -> void:
	var a := homestead()
	var b := homestead()
	if a.is_empty() or b.is_empty():
		check(false, "fixture: two homestead worlds")
		return
	var wa: World = a.w
	var wb: World = b.w
	for i in 2 * 1440:
		wa.update(1.0)
		wb.update(1.0)
	var ga := int(wa.stats.get("gathered_deadwood", 0))
	check(ga > 0 and ga == int(wb.stats.get("gathered_deadwood", 0)) and JSON.stringify(wa.homesteads.to_dict().get("deadwood", {})) == JSON.stringify(wb.homesteads.to_dict().get("deadwood", {}))
		and int(wa.stats.get("made_log", 0)) == int(wb.stats.get("made_log", 0)),
		"two worlds of one seed gather the same deadwood from the same trees (%d logs)" % ga)


# 4 ------------------------------------------------------------------------------------------------------------------------
func case_workshop(cf: Dictionary) -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var pantry := Inventory.new()
	pantry.add("log", int(cf.keep_logs) + 1)
	var saw: Dictionary = GameData.recipes.get("saw_planks", {})
	var roast: Dictionary = GameData.recipes.get("roast_meat", {})
	check(w.wilds.craft_spare(pantry, "log", saw) == 1, "a claim's sawhorse takes only the log beyond the hearth's %s (%d)" % [cf.keep_logs, w.wilds.craft_spare(pantry, "log", saw)])
	pantry.remove("log", 1)
	check(w.wilds.craft_spare(pantry, "log", saw) == 0 and w.wilds.craft_spare(pantry, "log", GameData.recipes.get("make_mallet", {})) == 0,
		"with keep_logs on the hearth, no planks or mallet from them")
	check(w.wilds.craft_spare(pantry, "log", roast) == int(cf.keep_logs), "an oven cooking food may still use the hearth's logs")


# 5 ------------------------------------------------------------------------------------------------------------------------
func verb(w: World, g: PlayerState, path: String, args: Array) -> Dictionary:
	var raw = w.as_actor(g, func(): return NetActions.enc(w, args))
	return NetActions.apply(w, g, "verb", {"path": path, "a": raw})


func case_guest(days: int) -> void:
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
	g.inv.remove("axe", g.inv.count("axe"))
	g.inv.remove("rusty_axe", g.inv.count("rusty_axe"))
	g.inv.remove("log", g.inv.count("log"))
	var gref: String = w.player_ref(g)
	check(NetActions.VERBS.has("player_gather_deadwood"), "the verb is one a guest's interface may send (NetActions.VERBS)")
	var t := village_tree(w)
	var cell := Vector2i(int(t.x), int(t.y))
	g.pos = beside(w, cell)
	var host_logs := w.player.inv.count("log")
	var made0 := int(w.stats.get("made_log", 0))
	var ex0 := w.experience.days(gref, "forestry")
	var r := verb(w, g, "player_gather_deadwood", [t])
	check(r.ok and g.inv.count("log") == 1 and w.player.inv.count("log") == host_logs, "the host gathers for the guest: one log in the guest's pack, none in the host's (%s)" % r.get("text", ""))
	check(int(w.stats.get("made_log", 0)) == made0 + 1 and int(w.homesteads.deadwood.get("%d,%d" % [cell.x, cell.y], -1)) == w.day() + days,
		"counted produced on the host and the host's tree timer set")
	check(w.experience.days(gref, "forestry") > ex0, "the host credits the gathering's time to the guest's work record")
	r = verb(w, g, "player_gather_deadwood", [t])
	check(not r.ok and g.inv.count("log") == 1, "a second request at once is refused by the host (%s)" % r.get("text", ""))
	var t2 := village_tree(w, [cell])
	g.pos = beside(w, Vector2i(int(t2.x), int(t2.y))) + Vector2(10, 0)
	r = verb(w, g, "player_gather_deadwood", [t2])
	check(not r.ok and g.inv.count("log") == 1 and not w.homesteads.deadwood.has("%d,%d" % [int(t2.x), int(t2.y)]), "from afar it is refused (%s)" % r.get("text", ""))


# 6 ------------------------------------------------------------------------------------------------------------------------
func case_interface() -> void:
	main.new_game()
	var w: World = main.world
	var p: PlayerState = w.player
	p.inv = Inventory.new()
	p.tool = ""
	var t := village_tree(w)
	var cell := Vector2i(int(t.x), int(t.y))
	p.pos = beside(w, cell)
	main.target = {"kind": "tree", "tree": t, "label": ""}
	main._use()
	var secs := float(w.player_deadwood_plan(t).get("secs", 0.0)) if main.action.is_empty() else 0.0
	check(not main.action.is_empty() and str(main.action.get("label", "")) == "Gathering deadwood", "Use on a mature tree without an axe starts Gathering deadwood (%s)" % main.action.get("label", ""))
	var dur := float(main.action.get("total", main.action.get("secs", main.action.get("time", -1.0))))
	var want := float(Homesteads.cfg().deadwood_minutes) / float(GameData.b("game_minutes_per_second")) * 0.6
	check(dur < 0.0 or is_equal_approx(dur, want), "for the plan's time (%s s, want %s)" % [dur, want])
	var guard := 0
	while not main.action.is_empty() and guard < 4000:
		main._player_step(0.05)
		guard += 1
	check(p.inv.count("log") == 1 and t.state == "grown", "when done, one log in the pack and the tree standing")
	main.target = {"kind": "tree", "tree": t, "label": ""}
	main._use()
	check(main.action.is_empty() and main.ui.toast.text.contains("gathered") and main.ui.toast.text.contains("Requires an axe"),
		"again at once: nothing starts, and it says the wood is gathered and felling needs an axe (%s)" % main.ui.toast.text)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
