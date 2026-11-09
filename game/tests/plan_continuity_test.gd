extends SceneTree
## TEST-AUDIT-Q1 (owner 2026-11-06): "A villager transporting goods, pulling a cart, or traveling to work should not silently
## abandon that activity because the player saved and reloaded." Seed 1: the world is run until a villager is out with a cart
## and another is walking to a work station, saved and loaded. Checked:
##  1. each one's plan comes back (the same steps; only the walk's path is found again), the cart is still theirs with its load,
##     and a reserved station is still reserved;
##  2. after the load the cart run is finished (the cart parked, let go of by the villager themselves) and the walker reaches
##     the station;
##  3. no coin is made or lost over the hours after the load (the economy simulation's account: holders' total against the
##     coins that came in and went out) and no cart or item appears from nowhere;
##  4. the same save loaded twice goes on identically (deterministic from its save);
##  5. a save with no plans (an older one) still loads, its villagers planning afresh and its carts let go of (KI-FR-CARTHITCH).
##   godot --headless --path game -s res://tests/plan_continuity_test.gd

var checks := 0
var failures := 0
var gmps := 1.0


func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("ok   " if ok else "FAIL ") + what)


func run_hours(w: World, hours: float) -> void:
	for i in int(60.0 * hours / gmps / 0.5):
		w.update(0.5)


## The villager out with a cart (holding it, a cart step still ahead) and one walking to a station they will work at.
func _carter(w: World) -> NPC:
	for c in w.carts.carts:
		if str(c.puller).begins_with("npc:"):
			var n := w.npc(int(str(c.puller).trim_prefix("npc:")))
			if n != null and n.plan.any(func(s): return str(s.get("act", "")) == "cart_park"):
				return n
	return null


func _walker(w: World) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and n.plan.size() >= 2 and str(n.plan[0].k) == "go" and w.stations.has(str(n.workplace)) \
				and n.plan.any(func(s): return str(s.get("k", "")) == "work" and str(s.get("args", {}).get("station", "")) == str(n.workplace)) \
				and Vector2(n.cell()).distance_to(Vector2(w.station_use(n.workplace))) > 4.0:
			return n
	return null


func _flows(w: World) -> int:
	var st := func(k): return int(w.stats.get(k, 0))
	return st.call("caravan_coins_in") + st.call("newcomer_coins_in") + st.call("scenario_coins_in") + st.call("outlaw_coins_in") - st.call("caravan_coins_out")


func _state(w: World) -> String:
	var parts := PackedStringArray([str(w.minutes), str(w.total_coins())])
	for n: NPC in w.npcs:
		parts.append("%d|%s|%d|%s|%s" % [n.id, n.pos, n.coins, n.inv.items, var_to_str(n.plan)])
	for c in w.carts.carts:
		parts.append("%s|%s|%s" % [c.id, c.pos, (c.store as Inventory).items])
	return "\n".join(parts)


static func _plan_as_saved(p: Array) -> String:
	var q: Array = p.duplicate(true)
	if not q.is_empty() and str(q[0].get("k", "")) == "go":
		q[0].erase("pathed")
	return var_to_str(q)


func _init() -> void:
	GameData.ensure()
	gmps = float(GameData.b("game_minutes_per_second"))
	var a := World.new()
	a.setup(VillageMap.load_default(), 1)
	# the walker: under way to their station (found within the first days; work steps follow the walk)
	var walker: NPC = null
	for q in 24 * 8:
		run_hours(a, 0.25)
		walker = _walker(a)
		if walker != null:
			break
	check(walker != null, "a villager walking to the station they work at (%s)" % ("%s, %s" % [walker.job, walker.workplace] if walker else "none"))
	if walker == null:
		_end()
		return
	# --- scenario 1: saved while the walker is on the way to their station
	var save_w: Dictionary = JSON.parse_string(JSON.stringify(a.to_dict(), "", true, true))
	var bw_world := World.new()
	bw_world.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(save_w, "", true, true)))
	var bw := bw_world.npc(walker.id)
	check(_plan_as_saved(bw.plan) == _plan_as_saved(walker.plan), "the walker's plan comes back step for step, its destination %s" % str(walker.plan[0].to))
	var reserved_a: Dictionary = a.stations.get(str(walker.workplace), {}).get("users", {})
	var reserved_b: Dictionary = bw_world.stations.get(str(walker.workplace), {}).get("users", {})
	check(reserved_a.get(walker.id) == reserved_b.get(walker.id), "the walker's station reservation is as it was (%s)" % str(reserved_a.get(walker.id)))
	var at: Vector2i = bw_world.station_use(bw.workplace)
	var arrived := false
	for q in 4 * 6:
		run_hours(bw_world, 0.25)
		if Vector2(bw.cell()).distance_to(Vector2(at)) <= 2.0:
			arrived = true
			break
	check(arrived, "after the load the walker reaches the station (%s)" % str(walker.workplace))
	# --- scenario 2: saved while a villager is out with the household's cart. No household of seed 1 owns a cart in its first
	# days, so one is set down for a household by its house (as a bought cart stands) with apples in its pantry to sell, and
	# the game's own planner (NPCBrain._plan_market_run) sends a member to market; the save is made once they hold the cart.
	# (Setup only: the coins and items below are counted from the load on.)
	while a.hour() < 8.0 or a.hour() >= 11.0:            # the market is open (no run starts within two hours of closing)
		run_hours(a, 0.25)
	var carter: NPC = null
	var tried := {}
	for n: NPC in a.npcs:
		if carter == null and n.alive and n.role == "adult" and n.household >= 0 and a.buildings.has(n.home) and not tried.has(n.household):
			tried[n.household] = true
			a.carts.place(World.hh_ref(n.household), Vector2(a.brain.cart_spot(n.home)) + Vector2(0.5, 0.5))
			a.households[n.household].pantry.add("apple", 40)
			if a.brain._plan_market_run(n, a.buildings[n.home]):
				carter = n
	check(carter != null, "a villager the game sends to market with the household's cart (%s)" % ("%s %s" % [carter.name, carter.family] if carter else "none"))
	if carter == null:
		_end()
		return
	for q in 6 * 60:                                      # until the cart is hitched and loaded (at most six hours)
		for i in int(1.0 / gmps / 0.5):
			a.update(0.5)
		var held: Dictionary = a.carts.pulled_by("npc:%d" % carter.id)
		if not held.is_empty() and (held.store as Inventory).total() > 0:
			break
	check(not a.carts.pulled_by("npc:%d" % carter.id).is_empty() and carter.plan.any(func(st): return str(st.get("act", "")) == "cart_park"),
			"the carter holds the cart, the run under way (a park step ahead)")
	var cart: Dictionary = a.carts.pulled_by("npc:%d" % carter.id)
	if cart.is_empty():
		_end()
		return
	var load_before: Dictionary = (cart.store as Inventory).items.duplicate()
	var carts_before := a.carts.carts.size()
	var save: Dictionary = JSON.parse_string(JSON.stringify(a.to_dict(), "", true, true))
	var b := World.new()
	b.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(save, "", true, true)))
	var bc := b.npc(carter.id)
	check(_plan_as_saved(bc.plan) == _plan_as_saved(carter.plan), "the carter's plan comes back step for step (%d steps)" % carter.plan.size())
	var bcart: Dictionary = b.carts.pulled_by("npc:%d" % bc.id)
	check(not bcart.is_empty() and int(bcart.id) == int(cart.id), "the carter still holds the same cart (cart %s)" % str(cart.id))
	check(not bcart.is_empty() and (bcart.store as Inventory).items == load_before, "with the same load (%s)" % str(load_before))
	var t0 := b.total_coins()
	var f0 := _flows(b)
	var parked := false
	for h in 48:                                           # up to twelve hours
		run_hours(b, 0.25)
		if b.carts.pulled_by("npc:%d" % bc.id).is_empty():
			parked = true
			break
	check(parked and not bc.plan.any(func(st): return str(st.get("act", "")) == "cart_park"), "after the load the carter finishes the run and parks the cart (the villager lets go of it)")
	var leak := (b.total_coins() - t0) - (_flows(b) - f0)
	check(leak == 0, "no coin made or lost after the load (holders %+d, flows %+d)" % [b.total_coins() - t0, _flows(b) - f0])
	check(b.carts.carts.size() == carts_before, "no cart appears or goes (%d)" % carts_before)
	# --- the same save loaded twice goes on identically; saved again straight after a load, the save is the same
	var c1 := World.new()
	c1.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(save, "", true, true)))
	var c2 := World.new()
	c2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(save, "", true, true)))
	run_hours(c1, 6.0)
	run_hours(c2, 6.0)
	check(_state(c1) == _state(c2), "the same save loaded twice goes on identically for six hours")
	var b2 := World.new()
	b2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(save, "", true, true)))
	var resaved: Dictionary = JSON.parse_string(JSON.stringify(b2.to_dict(), "", true, true))
	var differ := []
	for k in save:
		if JSON.stringify(save[k], "", true) != JSON.stringify(resaved.get(k), "", true):
			differ.append(k)
	if differ.has("npcs"):
		for i in mini(save.npcs.size(), resaved.npcs.size()):
			for f in save.npcs[i]:
				if JSON.stringify(save.npcs[i][f], "", true) != JSON.stringify(resaved.npcs[i].get(f), "", true):
					print("DIFF npc %s %s: %s -> %s" % [str(save.npcs[i].id), f, JSON.stringify(save.npcs[i][f]).left(300), JSON.stringify(resaved.npcs[i].get(f)).left(300)])
			for f in resaved.npcs[i]:
				if not save.npcs[i].has(f):
					print("DIFF npc %s new key %s" % [str(save.npcs[i].id), f])
	check(differ.is_empty(), "saved again straight after loading, the save is the same (%s differ)" % str(differ))
	# --- an older save: no plans kept
	var old: Dictionary = JSON.parse_string(JSON.stringify(save, "", true, true))
	for nd in old.npcs:
		nd.erase("plan_b")
		nd.erase("work_left")
	old.erase("station_users")
	var o := World.new()
	o.load_dict(VillageMap.load_default(), old)
	check(o.npc(carter.id).plan.is_empty() and o.carts.pulled_by("npc:%d" % carter.id).is_empty(),
			"an older save (no plans) loads: its villagers plan afresh and let go of their carts, as before")
	_end()


func _end() -> void:
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
