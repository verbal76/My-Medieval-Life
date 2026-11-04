extends SceneTree
## B25R1-019 / B25R1-020 (Presence): the live range, its hysteresis, the road's one pace, observation neutrality (the same
## seed with the view parked or sweeping the village gives the same villagers), a traveller met on the road (materialised at
## the point its walk reached, gone again past the ring, the errand finished as in an unwatched twin), a trade with them
## mid-road kept to the errand's end, conservation of people and coins across many transitions, save and load with people
## live, and the crowd exception's rules (protected people untouched, pastimes only).
## Run: godot --headless --path game --script res://tests/presence_test.gd

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		print("FAIL ", what)
	else:
		print("ok   ", what)


func _world(s := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), s)
	return w


func _adult(w: World) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 0 and n.home != "" and n.job != "sage" and n.job != "guard":
			return n
	return null


## Everything the rules hold about the villagers, as text: identical text = identical villagers.
func _people(w: World) -> String:
	var out := []
	for n: NPC in w.npcs:
		out.append([n.id, n.alive, snappedf(n.pos.x, 0.0001), snappedf(n.pos.y, 0.0001), n.coins, n.inv.to_dict(), snappedf(n.hunger, 0.0001),
			snappedf(n.hp, 0.0001), n.doing, n.plan.size(), n.journey])
	return JSON.stringify([out, w.total_coins(), w.rng.state])


func _park(w: World, at: Vector2) -> void:
	w.presence.set_view(w.host_player().pid, Presence.DEFAULT_VIEW, at)


func _init() -> void:
	_pure()
	_range()
	_neutral()
	_traveller()
	_transitions()
	_crowd()
	print("presence_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ---------------------------------------------------------------- the road's one pace --------------
func _pure() -> void:
	var d := 1440.0 + 7.0 * 60.0                                   # day 1, 07:00
	check(is_equal_approx(Presence.road_tiles(d, d + 60.0), 78.0), "an hour's walk by day is 78 tiles (1.3 a game minute)")
	check(is_equal_approx(Presence.walking_minutes(1440.0 + 19.0 * 60.0, 2880.0 + 7.0 * 60.0), 120.0),
		"19:00 to 07:00 next day walks two hours: the night stop (20:00-06:00) is not walked")
	var tiles := 2000.0
	var arr := Presence.arrival(d, tiles)
	check(absf(Presence.road_tiles(d, arr) - tiles) < 0.01, "arrival() is road_tiles()'s inverse over several days (%.1f -> %.1f)" % [d, arr])
	var path := PackedVector2Array([Vector2(0, 0), Vector2(3, 0), Vector2(3, 4)])
	var p: Array = Presence.along(path, 5.0)
	check((p[0] as Vector2).distance_to(Vector2(3.5, 2.5)) < 0.001 and (p[1] as Vector2).y > 0.0, "along() finds the point 5 tiles down a bent path, heading on")


# ---------------------------------------------------------------- the live range ---------------------
func _range() -> void:
	var w := _world()
	var at := Vector2(40, 40)
	_park(w, at)
	w.presence.refresh()
	check(w.presence.in_live_range(at + Vector2(15 + 3.5, 0)), "inside the view plus the 4-tile margin is live")
	check(not w.presence.in_live_range(at + Vector2(15 + 4.5, 0)), "past the margin is calculated")
	check(w.presence.keeps_live(at + Vector2(15 + 5.5, 0), true) and not w.presence.keeps_live(at + Vector2(15 + 5.5, 0), false),
		"hysteresis: what is live stays live to 6 tiles; nothing new becomes live past 4")
	var v0 := w.presence.version
	w.presence.set_view(w.host_player().pid, Presence.DEFAULT_VIEW * 2.0, at)      # zoomed out on a phone
	w.presence.refresh()
	check(w.presence.version > v0 and w.presence.in_live_range(at + Vector2(30, 0)), "zooming out widens the live range at once")
	check(w.presence.rect_live(Rect2(at + Vector2(33, -2), Vector2(4, 4))), "rect_live: a chunk touching the range is live")
	var headless := _world()
	headless.presence.refresh()
	check(headless.presence.in_live_range(headless.player.pos), "headless (no view reported): the default view round the player")


# ---------------------------------------------------------------- observation neutrality ----------------
## Two worlds, one seed, crowd management off: in one the view stays parked over the player, in the other it sweeps the
## village every tick (the player stands still in both, so only who is live differs). The villagers must be identical.
func _neutral() -> void:
	var a := _world()
	var b := _world()
	a.presence.crowd_enabled = false
	b.presence.crowd_enabled = false
	var c0 := a.player.pos
	var swept := {}
	for i in 720:                                               # six game hours
		_park(a, c0)
		_park(b, Vector2(20 + (i * 7) % 90, 20 + (i * 3) % 70))
		a.update(World.TICK)
		b.update(World.TICK)
		for n: NPC in b.npcs:
			if n.live:
				swept[n.id] = true
	check(swept.size() > 20, "the sweeping view made %d villagers live at some point" % swept.size())
	check(_people(a) == _people(b), "the villagers, the coins and the world's random numbers are identical whoever was watched")
	var moved := 0
	for i in a.fauna.animals.size():
		if i < b.fauna.animals.size() and (a.fauna.animals[i] as Animal).pos != (b.fauna.animals[i] as Animal).pos:
			moved += 1
	print("info  animals standing elsewhere after the sweep (live ones stroll): %d of %d" % [moved, a.fauna.animals.size()])


# ---------------------------------------------------------------- a traveller met on the road ---------
func _traveller() -> void:
	var runs := {}
	for mode in ["unwatched", "met", "traded"]:
		var w := _world()
		w.minutes = 1440.0 + 6.0 * 60.0 + 30.0
		w.presence.crowd_enabled = false
		var n := _adult(w)
		n.inv.add("bread", 4)
		var base := w.total_coins() - w.coin_sources
		Journeys.start(w, n, "wulstead", {"kind": "visit"})
		var far := Vector2(-5000, -5000)
		_park(w, far)
		var met_at := Vector2.INF
		var was_live := false
		var left_after := false
		var predicted_ok := false
		var traded := false
		var t_out := -1.0
		var p_out := PackedVector2Array()
		var ended := -1.0
		var guard := 0
		while guard < 4 * 1440 * 2:
			guard += 1
			if mode != "unwatched" and met_at == Vector2.INF and t_out < 0.0 and not n.journey.is_empty() and str(n.journey.leg) == "out" \
					and not w.map.in_village(n.cell()) and n.path.size() > 0 and n.path_i > 0:
				t_out = w.minutes                               # on the road: from here its place is the path at the pace
				p_out = n.path.slice(n.path_i)
				p_out.insert(0, n.pos - Vector2(0.5, 0.5))
			if t_out >= 0.0 and met_at == Vector2.INF and w.minutes >= t_out + 90.0 and w.hour() < 19.0:
				var pred: Vector2 = Presence.along(p_out, Presence.road_tiles(t_out, w.minutes) * Life.walk_factor(n))[0]
				predicted_ok = pred.distance_to(n.pos) < 2.0
				print("info  %s: predicted %s, on the road at %s" % [mode, pred, n.pos])
				_park(w, pred)                                  # the player's view reaches the predicted point
				met_at = pred
				if mode == "traded":
					w.player.pos = n.pos
					w.player.coins += 10
					base += 10                                  # the test's own coins for the purchase
					traded = w.trade(w.player, n, "bread", 1, 3)
			if met_at != Vector2.INF and was_live and not left_after and not n.live:
				left_after = true                                # it walked on out of the ring
			was_live = was_live or n.live
			w.update(World.TICK)
			if n.journey.is_empty():
				ended = w.minutes
				break
		runs[mode] = {"ended": ended, "coins": n.coins, "inv": n.inv.to_dict(), "player_bread": w.player.inv.count("bread"),
			"conserved": w.total_coins() - w.coin_sources == base, "home": n.cell()}
		check(ended > 0.0, "%s: the errand to Wulstead and back finished (minute %d)" % [mode, int(ended)])
		check(runs[mode].conserved, "%s: coins conserved over the errand" % mode)
		if mode != "unwatched":
			check(predicted_ok, "%s: the traveller was where its route and the pace put it" % mode)
			check(was_live, "%s: the traveller materialised in view on the road" % mode)
			check(left_after, "%s: it walked on and went back to calculation" % mode)
		if mode == "traded":
			check(traded, "traded: the player bought a bread from the traveller mid-road")
	check(runs.met.ended == runs.unwatched.ended and runs.met.coins == runs.unwatched.coins and runs.met.inv == runs.unwatched.inv,
		"met vs unwatched twin: same arrival home (%d vs %d), same coins, same pack" % [int(runs.met.ended), int(runs.unwatched.ended)])
	print("info  traded vs unwatched: ended %d vs %d, coins %d vs %d, pack %s vs %s" % [int(runs.traded.ended), int(runs.unwatched.ended),
		runs.traded.coins, runs.unwatched.coins, JSON.stringify(runs.traded.inv), JSON.stringify(runs.unwatched.inv)])
	check(runs.traded.player_bread >= 1, "traded: the bread stayed with the player to the errand's end")


# ---------------------------------------------------------------- many transitions, save and load -------
func _transitions() -> void:
	var w := _world()
	w.presence.crowd_enabled = false
	var people := w.npcs.size()
	var base := w.total_coins() - w.coin_sources
	var flips := [0]                                            # an Array: a lambda captures locals by value
	w.presence.entered.connect(func(_k, _id): flips[0] += 1)
	w.presence.left.connect(func(_k, _id): flips[0] += 1)
	for i in 600:
		_park(w, Vector2(10 + (i * 13) % 100, 10 + (i * 5) % 80))       # a view jumping about: many entries and exits
		w.update(World.TICK)
	var ids := {}
	for n: NPC in w.npcs:
		ids[n.id] = true
	check(flips[0] > 200, "%d transitions in 300 game minutes" % flips[0])
	check(w.npcs.size() >= people - 2 and ids.size() == w.npcs.size(), "nobody copied or lost (%d people, %d ids)" % [w.npcs.size(), ids.size()])
	check(w.total_coins() - w.coin_sources == base, "coins conserved across the transitions")
	var live := 0
	for n: NPC in w.npcs:
		live += 1 if n.live else 0
	var b := World.new()
	b.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	var live_b := 0
	for n: NPC in b.npcs:
		live_b += 1 if n.live else 0
	check(live > 0 and live_b == 0, "a save keeps no presence: %d live before, everyone calculated on load" % live)
	_park(b, b.player.pos)
	b.update(World.TICK)
	var after := 0
	for n: NPC in b.npcs:
		after += 1 if n.live else 0
	check(after > 0 and b.npcs.size() == w.npcs.size(), "the first update after loading makes the view's people live again (%d)" % after)


# ---------------------------------------------------------------- crowds (B25R1-020) ---------------------
func _crowd() -> void:
	var w := _world()
	w.minutes = 1440.0 + 13.0 * 60.0
	w.presence.refresh()
	var n := _adult(w)
	n.target = -1
	n.pursuit = {}
	n.journey = {}
	n.plan = [w.brain.loose(w.brain.work(30.0, "", {}, "idle"))]
	n.work_left = 15.0
	check(w.presence._loose_step(n), "a pastime is loose")
	n.pos = w.player.pos + Vector2(2, 0)
	check(w.presence.crowd_protected(n), "someone within 5 tiles of the player is protected")
	n.pos = w.player.pos + Vector2(12, 0)
	w.presence.lock(n.id, w.minutes)
	check(w.presence.crowd_protected(n), "an availability lock protects them")
	w.presence.locks.clear()
	var j := _adult(w)
	n.plan = [w.brain.work(30.0, "", {}, "idle")]
	check(not w.presence._loose_step(n), "a step not marked loose (work, a wait at a workplace) is never ended for a crowd")
	print("info  crowd stats after the checks: %s" % JSON.stringify(w.presence.crowd_stats))
	check(j != null, "an adult to test with")
