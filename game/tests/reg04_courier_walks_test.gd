extends SceneTree
## MML-REG-04 (owner 2026-11-08, docs/directives/2026-11-08_recovered_owner_messages.md "REG-04 - Couriers physically travel"):
## "A delivery cannot be completed merely because an abstract elapsed-day counter reaches its destination while its carrier
## remains somewhere else"; "One courier cannot simultaneously occupy several different routes"; actual road movement,
## departure and arrival, cargo ownership and conservation, carrier capacity, interrupted trips, death and hazards, save/load
## continuity, returning to the origin, several deliveries on one physical journey. With REG-03 F2/F3 (B42 reconciliation): a
## sender who migrated is sent what comes home, carried there by the next walk. FAILING FIRST on 0bbee94 (deliveries completed by
## the day count, the keeper never leaving the village). Pure World. Run headless:
##   godot --headless --path game --script res://tests/reg04_courier_walks_test.gd

const ITEM := "copper_ring"
const STEP_MIN := 10.0                       # game minutes in one test step (World.update(5.0): 2 game minutes a second)
const STEP_TILES := 1.3 * STEP_MIN + 1.0     # the most a walker covers in one step at the road's pace (Presence.PACE), and a tile

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL: ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	GameData.ensure()
	test_walk_and_save()
	test_death_on_the_road()
	test_turned_back()
	test_migrated_sender()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func coin_gap(x: World) -> int:
	return x.total_coins() + x.regions.coins() - (x.coin_sources + x.regions.net_paid_by_village())


## Rings anywhere in the village's books or on the road (packs, booth stores, loads, loot), and those that crossed the boundary.
func rings(x: World) -> int:
	var n := 0
	for o: NPC in x.npcs:
		n += o.inv.count(ITEM)
	n += x.player.inv.count(ITEM)
	for b in x.couriers.booths:
		if str(b.settlement) == "village":
			n += (b.store as Inventory).count(ITEM)
	for j in x.couriers.jobs:
		if str(j.state) in ["in_transit", "returning"]:
			n += int((j.cargo as Dictionary).get(ITEM, 0))
	for l in x.loot:
		n += (l.inv as Inventory).count(ITEM)
	# what crossed the village's boundary (a delivery handed over, a merchant's own trade with the caravan) is counted where it went
	# and what was made or used up meanwhile (a smith may make rings), as reg08_stranded_route_job_test's items() counts
	var made := 0
	for k in ["made_", "mined_", "felled_", "dug_", "cut_", "farm_harvest_"]:
		made += int(x.stats.get(k + ITEM, 0))
	var used := 0
	for k in ["eaten_", "used_", "used_building_", "used_works_", "used_repairs_", "burned_", "broke_", "spoiled_"]:
		used += int(x.stats.get(k + ITEM, 0))
	return n + int(x.stats.get("exported_" + ITEM, 0)) - int(x.stats.get("imported_" + ITEM, 0)) - made + used


func step(x: World, minutes: float, each := Callable()) -> void:
	var until := x.minutes + minutes
	while x.minutes < until:
		x.player.hp = x.player.max_hp
		x.player.hunger = 100.0
		x.update(5.0)
		if each.is_valid():
			each.call()


## A world with the village booth, a merchant who knows Wulstead's trader, and the route there. [w, merchant, route, keeper]
func fixture() -> Array:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.couriers.daily()
	var cs := w.couriers
	var vb := cs.booth_of("village")
	var m: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job == "merchant" and str(vb.keeper) != World.npc_ref(o.id):
			m = o
			break
	var route := {}
	for r in cs.routes:
		if str(r.from) == str(vb.id) and str(cs.booth(str(r.to)).settlement) == "wulstead":
			route = r
	w.note_settlement_trade(m, w.regions.by_id["wulstead"])
	m.inv.add(ITEM, 10)
	m.coins = maxi(m.coins, 100)
	var keeper: NPC = cs._npc(str(vb.keeper))
	keeper.hunger = 100.0
	w.households[keeper.household].pantry.add("bread", 40)       # food for the keeper's road (Journeys.provision)
	return [w, m, route, keeper]


## Step until the walking keeper is out of the village on the road.
func _until_out(w: World, k: NPC) -> void:
	var guard := 0
	while w.map.in_village(k.cell()) and guard < 2000:
		w.update(5.0)
		guard += 1
	step(w, 20.0)


func book(w: World, m: NPC, route: Dictionary, n: int, ask: int) -> Dictionary:
	return w.couriers.book_route({"sender": World.npc_ref(m.id), "recipient": "region:wulstead/trader", "recipient_kind": "business",
		"settlement": "wulstead", "items": {ITEM: n}, "route": route.id, "collect": {"kind": "coins", "amount": ask}, "proceeds": "purse"})


func test_walk_and_save() -> void:
	var f := fixture()
	var w: World = f[0]
	var m: NPC = f[1]
	var route: Dictionary = f[2]
	var k: NPC = f[3]
	var cs := w.couriers
	var gap0 := coin_gap(w)
	var rings0 := rings(w)
	var a := book(w, m, route, 3, 4)
	var b := book(w, m, route, 2, 3)
	check(not a.has("error") and not b.has("error"), "fixture: two route deliveries to Wulstead booked (%s, %s)" % [str(a.get("error", "ok")), str(b.get("error", "ok"))])
	# a load for another settlement waits while the keeper walks to Wulstead
	var garton := {}
	for r in cs.routes:
		if str(r.from) == str(route.from) and str(cs.booth(str(r.to)).settlement) == "garton":
			garton = r
	w.note_settlement_trade(m, w.regions.by_id["garton"])
	var c: Dictionary = cs.book_route({"sender": World.npc_ref(m.id), "recipient": "region:garton/trader", "recipient_kind": "business",
		"settlement": "garton", "items": {ITEM: 1}, "route": garton.id, "proceeds": "purse"})
	check(not c.has("error"), "fixture: a delivery to Garton booked too (%s)" % str(c.get("error", "ok")))
	route.next_day = w.day()
	garton.next_day = w.day() + 100
	step(w, 70.0)
	garton.next_day = w.day()                          # due now, while the keeper is on the Wulstead road
	check(str(a.state) == "in_transit" and str(b.state) == "in_transit", "both Wulstead loads leave (%s, %s)" % [str(a.state), str(b.state)])
	check(str(a.get("walker", "")) == World.npc_ref(k.id) and Journeys.active(k) and str(k.journey.get("to", "")) == "wulstead",
		"carried by the keeper %s, who walks to Wulstead (journey %s)" % [k.name, str(k.journey)])
	check(Journeys.active(k) and (k.journey.purpose.get("jobs", []) as Array).has(str(a.id)) and (k.journey.purpose.get("jobs", []) as Array).has(str(b.id)), "both deliveries on the one walk")
	check(rings(w) == rings0 and coin_gap(w) == gap0, "nothing lost or made at departure (rings %d of %d)" % [rings(w), rings0])
	step(w, 30.0)
	check(str(a.state) == "in_transit" and Journeys.active(k) and str(k.journey.get("leg", "")) == "out", "fixture: on the road out when saved (at %s)" % k.cell())
	# save on the road out, reload and go on
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var k2: NPC = w2.npc(k.id)
	var a2: Dictionary = w2.couriers.job(str(a.id))
	var b2: Dictionary = w2.couriers.job(str(b.id))
	var c2: Dictionary = w2.couriers.job(str(c.id))
	check(k2 != null and Journeys.active(k2) and str(k2.journey.purpose.kind) == "courier" and str(a2.get("walker", "")) == World.npc_ref(k.id),
		"saved and loaded mid-walk: the keeper still carries the deliveries (leg %s, at %s)" % [str(k2.journey.get("leg", "")), k2.cell()])
	check(coin_gap(w2) == gap0 and rings(w2) == rings0, "the load survives the save (rings %d of %d)" % [rings(w2), rings0])
	var tr2 := {"handed_at": Vector2i(-1, -1), "handed_leg": "", "garton_left": false, "max": 0.0, "last": k2.pos, "home_state": ""}
	step(w2, 8 * 1440.0, func() -> void:
		tr2.max = maxf(float(tr2.max), k2.pos.distance_to(tr2.last))
		tr2.last = k2.pos
		if str(a2.state) != "in_transit" and Vector2i(tr2.handed_at) == Vector2i(-1, -1):
			tr2.handed_at = k2.cell()
			tr2.handed_leg = str(k2.journey.get("leg", "none"))
		if str(c2.state) == "in_transit" and str(a2.state) in ["in_transit", "returning"]:
			tr2.garton_left = true
		if str(a2.state) == "fulfilled" and str(tr2.home_state) == "":
			tr2.home_state = "journey active %s, in village %s" % [str(Journeys.active(k2) and str(k2.journey.get("to", "")) == "wulstead"), str(w2.map.in_village(k2.cell()))])
	var spot := Vector2(w2.map.overworld.site("wulstead").slots[0].spot)
	check(Vector2(tr2.handed_at).distance_to(spot) <= STEP_TILES and str(tr2.handed_leg) in ["there", "back"],
		"the hand-over happened at Wulstead, where the keeper stood on arrival (seen at %s, %.1f tiles from the arrival spot %s within one %d-minute test step)" % [str(tr2.handed_at), Vector2(tr2.handed_at).distance_to(spot), str(spot), int(STEP_MIN)])
	check(str(a2.state) == "fulfilled" and str(b2.state) == "fulfilled", "both deliveries fulfilled (%s, %s)" % [str(a2.state), str(b2.state)])
	check(str(tr2.home_state).begins_with("journey active false, in village true"), "fulfilled only once the keeper was home (%s)" % str(tr2.home_state))
	check(not bool(tr2.garton_left), "the Garton load never left while the keeper was on the Wulstead road")
	check(str(c2.state) in ["in_transit", "returning", "fulfilled"], "the Garton load left once the keeper was home (%s)" % str(c2.state))
	check(float(tr2.max) <= STEP_TILES, "no jump: the largest move in one %d-minute test step was %.2f tiles (walking pace allows %.0f)" % [int(STEP_MIN), float(tr2.max), STEP_TILES])
	check(coin_gap(w2) == gap0, "coins conserved through the walk (gap %d, was %d)" % [coin_gap(w2), gap0])
	check(float(w2.stats.get("courier_walks", 0.0)) >= 1.0, "the walks are counted")


func test_death_on_the_road() -> void:
	var f := fixture()
	var w: World = f[0]
	var m: NPC = f[1]
	var route: Dictionary = f[2]
	var k: NPC = f[3]
	var gap0 := coin_gap(w)
	var rings0 := rings(w)
	var a := book(w, m, route, 4, 5)
	route.next_day = w.day()
	step(w, 70.0)
	_until_out(w, k)
	check(str(a.state) == "in_transit" and not w.map.in_village(k.cell()), "fixture: the keeper is on the road with the load (at %s)" % k.cell())
	var at := k.pos
	var loot0 := w.loot.size()
	w.kill(k, "slain by a test")
	check(str(a.state) == "interrupted", "the delivery stops with the courier (%s: %s)" % [str(a.state), str(a.outcome)])
	var pile := {}
	for i in range(loot0, w.loot.size()):
		if str(w.loot[i].get("from", "")) == "A courier's load":
			pile = w.loot[i]
	check(not pile.is_empty() and (pile.inv as Inventory).count(ITEM) == 4 and Vector2(pile.pos).distance_to(at) < 0.01,
		"the load lies where the courier fell (%s)" % str(pile.get("pos", "none")))
	check(rings(w) == rings0 and coin_gap(w) == gap0, "nothing lost or made (rings %d of %d, gap %d of %d)" % [rings(w), rings0, coin_gap(w), gap0])


func test_turned_back() -> void:
	var f := fixture()
	var w: World = f[0]
	var m: NPC = f[1]
	var route: Dictionary = f[2]
	var k: NPC = f[3]
	var gap0 := coin_gap(w)
	var rings0 := rings(w)
	var m_rings := m.inv.count(ITEM)
	var a := book(w, m, route, 2, 3)
	route.next_day = w.day()
	step(w, 70.0)
	_until_out(w, k)
	check(str(a.state) == "in_transit", "fixture: on the road")
	var ow: Overworld = w.map.overworld
	for nd in (ow._site_end("wulstead").nodes as Dictionary).keys():
		ow.close_node(nd)
	step(w, 4 * 1440.0)
	check(str(a.state) == "returned" and not Journeys.active(k), "the road closed: the keeper turned back and the delivery came home (%s, %s)" % [str(a.state), str(a.outcome)])
	check(m.inv.count(ITEM) == m_rings, "the sender has their goods back (%d of %d)" % [m.inv.count(ITEM), m_rings])
	check(rings(w) == rings0 and coin_gap(w) == gap0, "nothing lost or made (rings %d of %d, coin gap %d of %d)" % [rings(w), rings0, coin_gap(w), gap0])
	for nd in (ow._site_end("wulstead").nodes as Dictionary).keys():
		ow.close_node(nd, false)


func test_migrated_sender() -> void:
	var f := fixture()
	var w: World = f[0]
	var m: NPC = f[1]
	var route: Dictionary = f[2]
	var cs := w.couriers
	var a := book(w, m, route, 3, 6)
	route.next_day = w.day()
	step(w, 70.0)
	check(str(a.state) == "in_transit", "fixture: on the road")
	# the sender moves to Wulstead (the instant move's own pieces: the walk itself is REG-05's test)
	var s: OffMapSettlement = w.regions.by_id["wulstead"]
	var ms := [m]
	Migration._pre_leave(w, ms)
	var load_ := Migration._pack(w, ms)
	s.receive_person(load_.people[0], int(load_.coins), load_.goods, "farm")
	Migration._gone(w, s, ms, load_, null, "work")
	check(not m.alive and str(m.away) == "wulstead", "fixture: the sender now lives in Wulstead")
	var gap0 := coin_gap(w)
	step(w, 10 * 1440.0)
	var fwd := {}
	for j in cs.jobs:
		if str(j.recipient).begins_with("region:wulstead/hh:") and str(j.sender) == World.npc_ref(m.id):
			fwd = j
	check(str(a.state) == "fulfilled" and str(a.get("forwarded", "")) != "", "the payment came home and was sent on to the sender's new home (%s)" % str(a.get("forwarded", "")))
	check(not fwd.is_empty() and str(fwd.state) == "fulfilled", "the next walk carried it there (%s)" % str(fwd.get("state", "none")))
	check(not fwd.is_empty() and int(fwd.get("send_coins_out", 0)) == 6 and str(fwd.outcome) == "delivered" and int(fwd.carried_coins) == 0,
		"the 6 coins were handed to the sender's household in Wulstead (%s)" % str(fwd.get("history", [])))
	var dep: Dictionary = (cs.booth_of("village").deposits as Dictionary).get(World.npc_ref(m.id), {})
	check(dep.is_empty() or int(dep.get("coins", 0)) == 0, "nothing left at a booth the sender cannot reach (%s)" % str(dep))
	check(coin_gap(w) == gap0, "coins conserved (gap %d, was %d)" % [coin_gap(w), gap0])
