extends SceneTree
## SAV-02 (owner decision 2026-11-08, docs/directives/2026-11-09_overnight_autonomous_development.md): saved economic state is
## preserved through loading and continuation. A world saved in the middle of a day and loaded continues that day: earnings made
## since dawn still count in the day's income, relief labour already done today stays done, the morning's market reading and
## this hour's cached reserves and prices are the saved ones, not a new reading taken at the load.
var checks := 0
var fails := 0


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		fails += 1


func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.minutes = 1440.0 + 6.0 * 60.0
	w.brain.dawn(true)                                   # a morning: earnings counted from here
	w.minutes = 1440.0 + 13.0 * 60.0 + 20.0               # early afternoon of the same day
	var n: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult":
			n = o
			break
	n.earned += 23                                        # earned since dawn
	n.coins += 23
	w.brain.laboured_today[n.id] = true                   # did the day's relief labour already
	var r0 := w.reserve_of(n)                              # this hour's cached reserve
	var price0 := w._market_price("food")
	w.brain.market_wheat_price = 7                        # the morning's reading (made distinct for the test)
	w.brain.market_food_points = 41.5
	var saved: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var b := World.new()
	b.load_dict(VillageMap.load_default(), saved)
	var m: NPC = b.npc(n.id)
	check(int(b.brain.earned_at_dawn.get(n.id, -1)) == int(w.brain.earned_at_dawn[n.id]), "the day's earnings are still measured from dawn (%d), not from the load" % int(w.brain.earned_at_dawn[n.id]))
	check(b.brain.laboured_today.has(n.id), "relief labour done before the save stays done for the day")
	check(b.brain.market_wheat_price == 7 and is_equal_approx(b.brain.market_food_points, 41.5), "the morning's market reading is the saved one")
	check(b.reserve_of(m) == r0 and is_equal_approx(b._market_price("food"), price0), "this hour's cached reserve and price are the saved ones")
	# the next dawn records the same day's income in both worlds
	for x in [w, b]:
		x.minutes = 2.0 * 1440.0 + 6.0 * 60.0
		x.brain.dawn(true)
	var inc_w: int = w.npc(n.id).income_days[-1]
	var inc_b: int = m.income_days[-1]
	check(inc_b == inc_w and inc_w >= 23, "the day's income at the next dawn is the same after a load (%d and %d)" % [inc_w, inc_b])
	# the save loads and saves back the same
	var again: Dictionary = JSON.parse_string(JSON.stringify(b.to_dict()))
	var c := World.new()
	c.load_dict(VillageMap.load_default(), again)
	check(JSON.stringify(c.to_dict().get("brain_day")) == JSON.stringify(b.to_dict().get("brain_day")), "the day state round-trips exactly")
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)
