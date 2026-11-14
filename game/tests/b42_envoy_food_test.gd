extends SceneTree
## B42 (Agent I's flight-recorder finding, run 43332151718 seed 1, p:168 and p:1000650; 23 of the 47 starvation deaths of the
## chain 12 year-long runs): a traveller with an empty purse was provisioned for ONE leg (Journeys.start: trip_minutes +
## MARGIN_MINUTES), could buy nothing at the site and starved on the road home. Lead decision (engineering correction within
## REGION-NAV-01 AD-4): a round trip is provisioned from the household's own pantry for the whole way (there, the stay, back),
## within the existing half-pantry cap; one who still could not get home fed and cannot pay for the rest is not sent.
## Failing first on 0bbee94 (the coinless traveller starves; the unprovisionable one is sent). Pure World. Run headless:
##   godot --headless --path game --script res://tests/b42_envoy_food_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _run(w: World, cond: Callable, max_minutes: float) -> bool:
	var until := w.minutes + max_minutes
	while w.minutes < until:
		w.update(0.5)
		if cond.call():
			return true
	return false


## A world at day 1 06:30 and a coinless adult (not an officer) with an empty pack whose household pantry holds `bread` loaves.
func _fixture(bread: int) -> Array:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.minutes = 1440.0 + 6.0 * 60.0 + 30.0
	var n: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 3 and o.home != "" and not o.job in ["sage", "guard", "reeve"] and o.id != w.reeve_id:
			n = o
			break
	n.coins = 0
	n.inv = Inventory.new()
	n.hunger = 100.0
	var p: Inventory = w.households[n.household].pantry
	p.items.clear()
	if bread > 0:
		p.add("bread", bread)
	return [w, n]


## The settlement farthest by road (the longest walk home).
func _far(w: World) -> String:
	var best := ""
	var bm := -1.0
	for st in w.map.overworld.sites:
		var m := Journeys.trip_minutes(w, str(st.id))
		if m > bm and not w.map.overworld.road_route(Journeys.gate_index(w), str(st.id)).is_empty():
			bm = m
			best = str(st.id)
	return best


func _init() -> void:
	GameData.ensure()
	test_coinless_round_trip()
	test_unprovisionable_not_sent()
	test_envoy_not_sent_without_food()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func test_coinless_round_trip() -> void:
	var f := _fixture(200)
	var w: World = f[0]
	var n: NPC = f[1]
	var sid := _far(w)
	var p: Inventory = w.households[n.household].pantry
	var pantry0 := p.count("bread")
	check(Journeys.start(w, n, sid, {"kind": "visit"}) == "", "a coinless villager with food at home sets off for %s (%.0f minutes a leg)" % [sid, Journeys.trip_minutes(w, sid)])
	var taken := pantry0 - p.count("bread")
	check(taken == n.inv.count("bread") and taken > 0, "food conserved: the %d loaves that left the pantry are the %d in the pack" % [taken, n.inv.count("bread")])
	var need := (2.0 * Journeys.trip_minutes(w, sid) + 1440.0) / 60.0 * float(GameData.b("hunger_per_hour")) * NPCBrain.food_factor(n)
	check(Journeys.food_in(n.inv) >= need, "provisioned for the round trip: %.0f food points for %.0f needed" % [Journeys.food_in(n.inv), need])
	# a save on the way home, then on to the end
	var back := _run(w, func() -> bool: return not n.alive or str(n.journey.get("leg", "")) == "back", 6 * 1440.0)
	check(back and n.alive, "they reach %s and start home alive (hunger %.0f, %d loaves left)" % [sid, n.hunger, n.inv.count("bread")])
	_run(w, func() -> bool: return not n.alive or w.map.overworld.site_at(n.cell()).is_empty(), 600.0)
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	var n2: NPC = w2.npc(n.id)
	check(n2 != null and Journeys.active(n2) and str(n2.journey.leg) == "back" and n2.inv.count("bread") == n.inv.count("bread"),
		"saved and loaded on the road home: still on the way, the same %d loaves in the pack" % n.inv.count("bread"))
	var home := _run(w2, func() -> bool: return not n2.alive or not Journeys.active(n2), 6 * 1440.0)
	check(home and n2.alive and float(w2.stats.get("journey_ended_home", 0.0)) >= 1.0, "they come home alive (alive %s, hunger %.0f, day %d)" % [str(n2.alive), n2.hunger, w2.day()])


func test_unprovisionable_not_sent() -> void:
	var f := _fixture(0)
	var w: World = f[0]
	var n: NPC = f[1]
	var sid := _far(w)
	var why := Journeys.start(w, n, sid, {"kind": "visit"})
	check(why != "" and not Journeys.active(n), "with no food at home and no coins they are not sent (%s)" % why)
	check(float(w.stats.get("journey_refused_no_food", 0.0)) == 1.0, "the refusal is counted")
	n.coins = 1000
	check(Journeys.start(w, n, sid, {"kind": "visit"}) == "", "with coins to buy food at the site they may go")


func test_envoy_not_sent_without_food() -> void:
	var f := _fixture(0)
	var w: World = f[0]
	var n: NPC = f[1]
	var sid := _far(w)
	var j := {"kind": "envoy", "sid": sid, "qty": 1, "wage": 0, "stage": "go", "days_allowed": 20, "carried": [], "met": []}
	w.manor_work._post(j)
	check(w.manor_work.take(j, World.npc_ref(n.id)), "fixture: the coinless villager with an empty pantry takes the envoy job")
	var planned := Envoys.plan(w, n, j)
	check(not planned and not Journeys.active(n), "the envoy is not sent without food for the road home")
	check(not w.manor_work.jobs.has(j), "the job is given up (the reeve posts it again)")
	check(not (Envoys.book(w).visits as Dictionary).has(sid), "the settlement is not marked as visited")
	check(float(w.stats.get("envoy_refused_no_food", 0.0)) == 1.0, "the refusal is counted")
