extends SceneTree
## Expansion 20 LE-05 (design s.17 "Construction, ecology, mining, bandits and regional links", gate "Integration matrix covered"):
## travel in a delivered contract's price (design s.5), and the switch. Nothing asserts that anyone prospers.
## Run headless:  godot --headless --path game --script res://tests/le05_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func new_world(on := true) -> World:
	if on:
		var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy.json"))
		c.enabled = true
		EconomyFoundation.set_override(c)
	else:
		EconomyFoundation.set_override({})
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


func _init() -> void:
	test_travel()
	test_market_journal()
	EconomyFoundation.set_override({})
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func adults(w: World) -> Array:
	return w.npcs.filter(func(n): return n.alive and n.role == "adult" and n.household >= 0)


func test_travel() -> void:
	var off := new_world(false)
	var w := new_world(true)
	var ps := adults(w)
	var s: NPC = ps[0]
	s.income_days = [40, 40, 40, 40, 40]
	var near: NPC = null
	var far: NPC = null
	var best := INF
	var worst := -1.0
	for o: NPC in ps:
		if o == s:
			continue
		var d := Vector2(w.brain._workplace_cell(s)).distance_to(Vector2(w.brain._workplace_cell(o)))
		if d > 2.0 and d < best:
			best = d
			near = o
		if d > worst:
			worst = d
			far = o
	var tn: float = w.contracts.travel_per_unit(s, World.npc_ref(near.id))
	var tf: float = w.contracts.travel_per_unit(s, World.npc_ref(far.id))
	check(tn > 0.0 and tf > tn, "a farther buyer costs the seller more walking a unit (%.2f near, %.2f far)" % [tn, tf])
	var m: Dictionary = w.contracts.means(s, "plank", 3)
	var t: Dictionary = w.contracts.price_terms(s, World.npc_ref(far.id), "plank", m)
	check(is_equal_approx(float(t.travel), tf) and int(t.min) >= roundi(maxf(float(t.going), maxf(float(t.cost), float(t.alternatives))) * (float(t.household) - float(t.relationship) + float(t.risk))),
		"the minimum price carries the travel term (%s)" % str(t.min))
	var idle: NPC = ps[1]
	idle.income_days = []
	check(w.contracts.travel_per_unit(idle, World.npc_ref(far.id)) == 0.0, "a seller earning nothing values its walk at nothing (its own measure)")
	var so: NPC = off.npc(s.id)
	so.income_days = [40, 40, 40, 40, 40]
	check(off.contracts.travel_per_unit(so, World.npc_ref(far.id)) == 0.0 and not off.contracts.price_terms(so, World.npc_ref(far.id), "plank", off.contracts.means(so, "plank", 3)).get("travel", 0.0) > 0.0,
		"economy off: CON-01's price exactly as before (no travel term)")


# ------------------------------------------------------------------------------------------------ the player's market journal (OD-LE-14 D13)
func market_lines(w: World) -> Array:
	return w.messages.entries(w.player_ref(w.player)).filter(func(e): return str(e[1]) == "market")


func test_market_journal() -> void:
	var w := new_world(true)
	var n: NPC = adults(w)[0]
	n.inv.add("plank", 4)
	var a := w.economy.offers.post(EconOffers.ASK, World.npc_ref(n.id), "plank", 3, 4, w.day() + 3, "", "market")
	check(a.ok, "a villager has an open ask")
	check(market_lines(w).is_empty() and not w.economy.knowledge.knows("player", World.npc_ref(n.id), "plank", "sells"), "the player knows nothing of it before meeting (no marketplace feed)")
	w.relations.talked(n)
	var lines := market_lines(w)
	check(lines.size() == 1 and str(lines[0][2]).contains("sells plank at 4") and str(lines[0][2]).contains("seen day"), "talking with the villager: a journal line with what, price, day and place (%s)" % (str(lines[0][2]) if lines.size() == 1 else "none"))
	check(w.economy.knowledge.knows("player", World.npc_ref(n.id), "plank", "sells"), "and the player now knows the price (in person)")
	w.relations.talked(n)
	check(market_lines(w).size() == 1, "talking again the same day adds nothing")
	w.economy.offers.revise(int(a.id), 3)
	w.relations.talked(n)
	check(market_lines(w).size() == 2, "a changed price is a new line")
	var off := new_world(false)
	var n2: NPC = adults(off)[0]
	off.relations.talked(n2)
	check(market_lines(off).is_empty() and off.economy == null, "economy off: no market lines")
