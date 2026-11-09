extends SceneTree
## INV-05 (owner decision 2026-11-08, docs/directives/2026-11-09_overnight_autonomous_development.md): rubble may serve as stone
## (STONE-04), but taking a fitting up or giving a building site up never turns that rubble into dressed stone: what was laid as
## rubble comes back as rubble, and nothing is made or lost.
var checks := 0
var fails := 0


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		fails += 1


func finish(w: World, pl: Dictionary) -> void:
	for id in pl.site.need.duplicate():
		w.player.inv.add(id, int(pl.site.need[id]))
	w.deliver(pl, w.player.inv, World.PLAYER)


func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 7002)
	w.player.coins = 5000
	var plot: Dictionary = w.plots[0]
	check(w.property.lease(plot, World.PLAYER) == "", "fixture: the player leases land")
	w.start_site(plot, "house", World.PLAYER)
	finish(w, plot)
	var box := Rect2i(int(plot.x) - 40, int(plot.y) - 40, int(plot.w) + 80, int(plot.h) + 80)
	for tree in w.trees:
		if box.has_point(Vector2i(int(tree.x), int(tree.y))):
			tree.state = "cleared"
			w.map.set_solid(Vector2i(int(tree.x), int(tree.y)), false)
	var c: Construction = w.construction
	var slot := c.find_module_slot("storage", plot, World.PLAYER)
	var module: Dictionary = c.place("storage", slot, World.PLAYER, false, plot)
	check(not module.is_empty(), "fixture: a room of the player's")
	if module.is_empty():
		quit(1)
		return
	finish(w, module)
	var b: Dictionary = w.property.building_on(module)
	# a stone-costing piece, paid with rubble only
	var kind := ""
	for k in Fitting.KINDS:
		if int(Fitting.cost(k).get("stone", 0)) > 0:
			kind = k
			break
	check(kind != "", "fixture: a fitting that costs stone (%s)" % kind)
	var cost := Fitting.cost(kind)
	var stone := int(cost.stone)
	for id in cost:
		if id != "stone":
			w.player.inv.add(id, int(cost[id]))
	w.player.inv.remove("stone", w.player.inv.count("stone"))
	w.player.inv.remove("rubble", w.player.inv.count("rubble"))
	w.player.inv.add("rubble", stone)
	var cell := Vector2i(-1, -1)
	var cells: Array = w.fitting.floor_set(b).keys()
	cells.sort_custom(func(x: Vector2i, y: Vector2i): return x.y < y.y or (x.y == y.y and x.x < y.x))
	for cc: Vector2i in cells:
		if w.fitting.why_not(b, kind, cc) == "":
			cell = cc
			break
	check(cell != Vector2i(-1, -1), "fixture: the piece can be placed")
	check(w.fitting.place(b, kind, cell) == "", "the %s is fitted with %d rubble for its %d stone" % [kind, stone, stone])
	check(w.player.inv.count("rubble") == 0 and w.player.inv.count("stone") == 0, "the rubble was spent")
	check(w.fitting.remove(b, kind) == "", "the %s is taken up" % kind)
	check(w.player.inv.count("stone") == 0, "no dressed stone came back for rubble (%d stone)" % w.player.inv.count("stone"))
	check(w.player.inv.count("rubble") == stone, "the %d rubble came back as rubble" % stone)
	# a building site given up after rubble was delivered as stone
	var p2: Dictionary = {}
	for p in w.plots:
		if p != plot and (p.site as Dictionary).is_empty() and w.owner_of(p) == World.MANOR and w.tenant_of(p) == "":
			p2 = p
			break
	if p2.is_empty():
		check(true, "(no second free plot on this map: the site case is covered by the delivery path below)")
	else:
		w.property.lease(p2, World.PLAYER)
		w.start_site(p2, "house", World.PLAYER)
	var site: Dictionary = p2 if not p2.is_empty() else {}
	if not site.is_empty() and not (site.site as Dictionary).is_empty():
		var cst: Dictionary = (site.site.get("cost", w.site_cost(site)) as Dictionary).duplicate()
		cst["stone"] = 4                                 # a site whose work takes stone
		site.site.cost = cst
		site.site.need["stone"] = 4
	check(not site.is_empty() and int(site.site.need.get("stone", 0)) > 0, "fixture: a building site that needs stone")
	if not site.is_empty() and int(site.site.need.get("stone", 0)) > 0:
		var need_stone := int(site.site.need.stone)
		w.player.inv.remove("stone", w.player.inv.count("stone"))
		w.player.inv.remove("rubble", w.player.inv.count("rubble"))
		w.player.inv.add("rubble", need_stone)
		w.deliver(site, w.player.inv, World.PLAYER)
		check(int(site.site.get("rubble", 0)) == need_stone, "the site records the %d stone laid as rubble" % need_stone)
		var back: Dictionary = w.cancel_site(site, w.player.inv)
		check(int(back.get("stone", 0)) == 0 and int(back.get("rubble", 0)) == need_stone, "given up, the site returns rubble, not stone (%s)" % str(back))
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)
