extends SceneTree
## B25R1-018 sections 5-7 and 9, B25R1-019 (owner 2026-11-03): the hamlets in the real economy, trips carried by walkers on the
## roads, and the residents as one record whether calculated or live (SettlementTrips, SettlementPeople). Checked here:
##   * founding: ten hamlets and thorps of 5-6 households, no trader, no officials, books balanced, no duplicated person
##   * a settlement with no trader runs: food, market trips, tolls and dues to the lord, day labour; Rushford pays no toll or tax
##   * a trip's position at any minute, the night's rest, the fold's inverse (depart_for)
##   * a full errand with goods and coins conserved
##   * materialise and fold round trips across many residents: people, coins and items counted on both ledgers
##   * a walker met on the road becomes live, walks, is folded, and the errand still completes
##   * save and load mid-trip; deterministic replay
##   * a live resident's injury and skills carry over a fold, a later live spell and a save; an older save loads with defaults
##   * a household that leaves, or a member who is lost, while live: folded first, nothing left in the world without a record
##   * the wells: a whole-world census before and after (village holders and every settlement)
##   godot --headless --path game --script res://tests/hamlet_test.gd

var checks := 0
var failures := 0
const HAMLETS := ["rushford", "ashcombe", "fallowley", "wendholt", "ewedean", "brookhurst", "elmcote", "cressbrook", "mileham", "milton"]


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL: " + what)


func _init() -> void:
	GameData.ensure()
	test_founding()
	test_no_trader_runs()
	test_trip_position()
	test_errand_conserved()
	test_world_people()
	test_replay()
	test_well_census()
	test_carry_over()
	test_leaving_while_live()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _totals(r: Regions) -> String:
	var g := r.goods()
	var ks := g.keys()
	ks.sort()
	var o := {}
	for k in ks:
		o[k] = g[k]
	return "%d %s" % [r.coins(), JSON.stringify(o)]


## The whole world's coins less those that came from outside it (regions_test's measure): constant through any trade or crossing.
func _net(w: World) -> int:
	return w.total_coins() + w.regions.coins() - (w.coin_sources + w.regions.net_paid_by_village())


func test_founding() -> void:
	var r := Regions.create(1)
	var hs: Array = r.list.filter(func(s): return s.hamlet)
	check(hs.map(func(s): return s.id) == HAMLETS, "ten small places are founded (%d)" % hs.size())
	for s: OffMapSettlement in hs:
		check(s.households() >= 5 and s.households() <= 6 and s.trader().is_empty() and s.gov.officials.is_empty() and s.biz.size() >= 2,
			"%s: %d households, %d people, no trader, no officials, businesses %s" % [s.name, s.households(), s.population(), str(s.biz.keys())])
		check(s.audit() == "" and int(s.start.coins) == s.coins(), "%s: its opening books are its founding endowment and balance" % s.name)
	check(r.audit() == "", "the region's audit holds at the founding")
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var seen := {}
	var dup := 0
	var n := 0
	for s: OffMapSettlement in w.regions.list:
		for h in s.hh:
			for m in h.mem:
				var id := OffMapSettlement.member_id(m)
				n += 1
				if seen.has(id) or id <= 0 or w.by_id.has(id):
					dup += 1
				seen[id] = true
	check(dup == 0 and n > 0, "every one of %d settlement people has one id of their own, none a villager's" % n)
	check(w.regions.people != null, "the residents' presence provider is attached")
	w.dispose()


func test_no_trader_runs() -> void:
	var r := Regions.create(2)
	var c0 := _totals(r)
	var bad := ""
	for d in 60:
		r.step_day(d)
		var a := r.audit()
		if a != "" and bad == "":
			bad = "day %d: %s" % [d, a]
	check(bad == "", "sixty days with the hamlets: every audit holds (%s)" % bad)
	var ru: OffMapSettlement = r.by_id["rushford"]
	check(int(ru.flows.tolls) == 0 and int(ru.flows.tax_households) + int(ru.flows.tax_businesses) == 0, "Rushford, with no lord, pays no toll and no tax")
	var bk: OffMapSettlement = r.by_id["brookhurst"]
	check(int(bk.flows.regional_coins_out) > 0, "Brookhurst's walkers spent or carried coins to other places (%d)" % int(bk.flows.regional_coins_out))
	var dues := r.trip_journal.filter(func(e): return str(e.kind) == "carriage_earned" and str(e.party).begins_with("higham/treasury"))
	check(not dues.is_empty(), "the Abbot's treasury received the hamlets' dues by a walker (%d times)" % dues.size())
	var markets := 0
	for s: OffMapSettlement in r.list:
		if s.hamlet:
			markets += r.trip_journal.filter(func(e): return str(e.party).begins_with(s.id + "/trip:")).size()
	check(markets > 0, "the hamlet folk dealt at their markets (%d exchanges)" % markets)
	for s: OffMapSettlement in r.list:
		if s.hamlet:
			print("      %s: %d people, %d coins, food bought %d, deaths %d" % [s.name, s.population(), s.coins(), int(s.flows.food_bought), int(s.flows.deaths)])
	print("      the region began with %s" % c0.left(12))


func test_trip_position() -> void:
	var r := Regions.create(3)
	r.step_day(0)
	var s: OffMapSettlement = r.by_id["fallowley"]
	var t := SettlementTrips.start(r, s, "hh:0", "wulstead", {"kind": "market", "buy": {"ale": 1}}, 5, {}, 8.0 * 60.0)
	check(not t.is_empty() and str(t.leg) == "out", "a walker sets out from Fallowley for Wulstead")
	var path := SettlementTrips.leg_path(r, t)
	var arr := SettlementTrips.arrives(r, t)
	check(SettlementTrips.pos(r, t, 8.0 * 60.0) == path[0] + Vector2(0.5, 0.5), "at the minute of departure they stand at the start")
	check(SettlementTrips.pos(r, t, arr).distance_to(path[path.size() - 1] + Vector2(0.5, 0.5)) < 0.01, "at the arrival minute (%d) they stand at the end" % int(arr))
	var mono := true
	var last := -1.0
	for m in range(480, int(arr) + 1, 7):
		var k := SettlementTrips.road_tiles(float(t.depart), float(m))
		mono = mono and k >= last
		last = k
	check(mono, "every minute they are no further back than the minute before")
	check(SettlementTrips.road_tiles(0.0, 20.0 * 60.0) == SettlementTrips.road_tiles(0.0, 30.0 * 60.0 - 1.0), "nobody walks between 20:00 and 06:00")
	check(is_equal_approx(SettlementTrips.road_tiles(6.0 * 60.0, 7.0 * 60.0), 78.0), "1.3 tiles a game minute (78 in an hour)")
	var ok := true
	for now in [500.0, 1300.0, 2000.0, 5000.0, 9000.5]:
		for tiles in [0.0, 10.0, 300.0, 1100.0]:
			var d := SettlementTrips.depart_for(now, tiles)
			ok = ok and absf(SettlementTrips.road_tiles(d, now) - tiles) < 0.001
	check(ok, "depart_for is road_tiles' inverse: a folded walker is put back exactly as far along")


func test_errand_conserved() -> void:
	var r := Regions.create(4)
	for d in 3:
		r.step_day(d)
	var ew: OffMapSettlement = r.by_id["ewedean"]
	var wu: OffMapSettlement = r.by_id["wulstead"]
	for k in {"wool": 30, "hide": 20}:                # the flocks' clip and hides, booked as the herd's own output
		var add: int = {"wool": 30, "hide": 20}[k] - int(ew.biz.herd.stock.get(k, 0))
		OffMapSettlement._add(ew.biz.herd.stock, k, add)
		OffMapSettlement._add(ew.flows.produced, k, add)
	var before := _totals(r)
	var till := int(ew.biz.herd.till)
	var t := SettlementTrips.start(r, ew, "herd", "wulstead", {"kind": "market", "buy": {}}, 0, {"wool": 20, "hide": 10}, 3.0 * 1440.0 + 400.0)
	check(not t.is_empty() and int(ew.biz.herd.stock.get("wool", 0)) == 10 and _totals(r) == before, "the walker's pack leaves the herd's stock but stays in Ewedean's books")
	var m := float(t.depart)
	while not SettlementTrips.find(ew, str(t.tx)).is_empty() and m < float(t.depart) + 10000.0:
		m += 60.0
		SettlementTrips.advance(r, m)
	check(SettlementTrips.find(ew, str(t.tx)).is_empty(), "the errand is done and the walker home")
	var sold := r.trip_journal.filter(func(e): return str(e.party) == "ewedean/trip:" + str(t.tx) and str(e.kind) == "sell")
	print("      sold at Wulstead: %s" % str(sold.map(func(e): return [e.item, e.n, e.coins])))
	check(_totals(r) == before, "goods and coins of the whole region are what they were (%s)" % _totals(r).left(10))
	check(ew.audit() == "" and wu.audit() == "" and r.audit() == "", "both places' books and the regional lines balance (%s)" % r.audit())
	var got := 0
	for e in sold:
		got += int(e.coins)
	check(int(ew.biz.herd.till) == till + got, "what was sold came home as coins in the herd's till (%d)" % got)


## A world: residents made live and folded back, many times; a walker met on the road; save and load mid-trip.
func test_world_people() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var r := w.regions
	var p: SettlementPeople = r.people
	var s: OffMapSettlement = r.by_id["brookhurst"]
	var t := SettlementTrips.start(r, s, "hh:1", "higham", {"kind": "market", "buy": {"ale": 2, "wheat": 4}}, 30, {}, float(w.minutes))
	check(not t.is_empty() and r.trip_route("brookhurst", "higham").size() > 10, "a Brookhurst walker sets out on the road to Higham (%d cells)" % r.trip_route("brookhurst", "higham").size())
	var cands := p.presence_candidates()
	check(cands.size() > 300 and cands.any(func(c): return int(c.id) == int(t.who)), "every resident is a candidate, the walker at their place on the road (%d)" % cands.size())
	var npcs0 := w.npcs.size()
	var net0 := _net(w)
	var reg0 := _totals(r)
	var ids := cands.slice(0, 120).map(func(c): return int(c.id))
	if not ids.has(int(t.who)):
		ids.append(int(t.who))
	var bad := ""
	for round in 3:
		for id in ids:
			var n = p.materialise(id)
			if n == null:
				bad = "no NPC for %d" % id
		var live := w.npcs.size()
		if live != npcs0 + ids.size():
			bad = "live %d, expected %d" % [live, npcs0 + ids.size()]
		if _net(w) != net0:
			bad = "coins moved while live"
		for id in ids:
			p.fold(w.by_id[id])
	check(bad == "", "three rounds of %d residents made live and folded: one NPC each, the coins counted once (%s)" % [ids.size(), bad])
	check(w.npcs.size() == npcs0 and p.live.is_empty() and s.live.is_empty(), "folded, nobody is left in the world's people or marked live")
	check(_totals(r) == reg0 and _net(w) == net0 and r.audit() == "", "the settlements' coins and goods are as before (%s)" % r.audit())
	# met on the road: live for an hour of walking, folded, then the errand completes calculated
	var mid := (float(t.depart) + SettlementTrips.arrives(r, t)) / 2.0
	while float(w.minutes) < mid:
		w.update(0.5)
		w.player.hunger = 100.0
	var n = p.materialise(int(t.who))
	check(n != null and int(n.coins) == 30 and int(t.coins) == 0 and n.pos.distance_to(SettlementTrips.pos(r, t, float(w.minutes))) < 0.01, "met on the road: live with the trip's 30 coins, where the record had them")
	var at0: Vector2 = n.pos
	var m0 := float(w.minutes)
	while float(w.minutes) < m0 + 30.0:
		w.update(0.5)
		w.player.hunger = 100.0
	check(n.pos.distance_to(at0) > 5.0, "live, they walk on along the road (%.0f tiles)" % n.pos.distance_to(at0))
	p.fold(n)
	var back := SettlementTrips.pos(r, t, float(w.minutes))
	check(back.distance_to(n.pos) < 1.5 and int(t.coins) == 30 and not w.by_id.has(int(t.who)), "folded: the record has them where they stood, with their coins")
	check(r.audit() == "" and _net(w) == net0, "and both ledgers balance (%s)" % r.audit())
	# save and load mid-trip, with the walker live at the moment of saving
	p.materialise(int(t.who))
	var saved: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	check(not w.by_id.has(int(t.who)), "a save folds the live residents first")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), saved)
	check(JSON.stringify(w2.regions.to_dict()) == JSON.stringify(r.to_dict()), "loaded mid-trip, the settlements are exactly as saved")
	var end := SettlementTrips.arrives(r, t) + 4000.0
	var m := float(w.minutes)
	while m < end:
		m += 60.0
		SettlementTrips.advance(r, m)
		SettlementTrips.advance(w2.regions, m)
	var s2: OffMapSettlement = w2.regions.by_id["brookhurst"]
	check(SettlementTrips.find(s, str(t.tx)).is_empty() and SettlementTrips.find(s2, str(t.tx)).is_empty(), "the errand completes after they left view, in both")
	check(r.trip_journal.any(func(e): return str(e.party) == "brookhurst/trip:" + str(t.tx) and str(e.kind) == "buy"), "and they bought at Higham")
	check(JSON.stringify(w2.regions.to_dict()) == JSON.stringify(r.to_dict()) and r.audit() == "" and w2.regions.audit() == "", "the loaded world ends exactly as the original")
	w.dispose()
	w2.dispose()


func test_replay() -> void:
	var a := Regions.create(7)
	var b := Regions.create(7)
	for d in 40:
		a.step_day(d)
		b.step_day(d)
	check(JSON.stringify(a.to_dict()) == JSON.stringify(b.to_dict()), "two runs of the same seed with hamlets and trips are identical over 40 days")
	var trips := 0
	for s: OffMapSettlement in a.list:
		trips += int(s.trip_seq)
	print("      trips set out in 40 days: %d" % trips)
	check(trips > 0, "walkers set out (%d trips)" % trips)


## Wilds.add_well as the homestead branch has it (wip/b25r1-homestead 5236f89): built=true counts the cost as used_building_ in the
## world's stats unless count is false.
class WellStub:
	var w
	var wells := []
	func add_well(owner: String, cell: Vector2i, built := false, cost := {}, count := true) -> Dictionary:
		var wl := {"id": "wl%d" % (wells.size() + 1), "owner": owner, "cell": [cell.x, cell.y], "done": built, "cost": cost.duplicate(), "count": count}
		wells.append(wl)
		if built and count:
			for id in cost:
				w.stat("used_building_" + str(id), float(cost[id]))
		return wl


const Census := preload("res://tests/census.gd")


## The hamlets' wells, census of the whole world (the village's holders and every settlement) before and after: the stone and logs
## that went into the wells are exactly what the hamlets' own books count used; the village's goods, its imported_ and used_building_
## figures and every coin are untouched.
func test_well_census() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var r := w.regions
	var stub := WellStub.new()
	stub.w = w
	r.wilds_override = stub
	var vg0 := Census.goods(w)
	var rg0 := r.goods()
	var coins0 := w.total_coins() + r.coins()
	var st0 := w.stats.duplicate()
	var used0 := {}
	for s: OffMapSettlement in r.list:
		for k in ["stone", "log"]:
			used0[s.id + k] = int(s.flows.used.get(k, 0))
	r._wells()
	var wells: Array = stub.wells
	var hamlet_wells := r.list.filter(func(s): return s.water == "well")
	check(wells.size() == hamlet_wells.size() and hamlet_wells.all(func(s): return s.well != ""), "every hamlet without a stream has its well (%d)" % wells.size())
	var vg1 := Census.goods(w)
	var rg1 := r.goods()
	var ok := true
	for k in ["stone", "log"]:
		var used := 0
		for s: OffMapSettlement in hamlet_wells:
			used += int(s.flows.used.get(k, 0)) - int(used0.get(s.id + k, 0))
		var vb := int(w.stats.get("used_building_" + k, 0)) - int(st0.get("used_building_" + k, 0))
		var imp := int(w.stats.get("imported_" + k, 0)) - int(st0.get("imported_" + k, 0))
		var world_drop := (int(vg0.get(k, 0)) + int(rg0.get(k, 0))) - (int(vg1.get(k, 0)) + int(rg1.get(k, 0)))
		print("      %s: world %d less, hamlets used %d, village %d -> %d, village used_building %d, imported %d" % [k, world_drop, used, int(vg0.get(k, 0)), int(vg1.get(k, 0)), vb, imp])
		ok = ok and world_drop == used and used > 0 and int(vg0.get(k, 0)) == int(vg1.get(k, 0)) and imp == 0 and vb == 0
	check(ok, "the world holds exactly the wells' stone and logs less, as the hamlets' own books say; the village's goods and figures are unchanged")
	check(stub.wells.all(func(x): return x.count == false), "the registry is told not to count them in the village's ledger")
	check(w.total_coins() + r.coins() == coins0, "no coin moved")
	check(r.audit() == "", "the settlements' books balance: the materials are their own use (%s)" % r.audit())
	r._wells()
	check(stub.wells.size() == wells.size(), "a well is built once")
	w.dispose()


## The first adult at home in `sid` (not travelling), as [household, member index, person id].
func _resident(r: Regions, sid: String) -> Array:
	var s: OffMapSettlement = r.by_id[sid]
	for h in s.hh:
		if not bool(h.alive):
			continue
		for j in h.mem.size():
			var id := OffMapSettlement.member_id(h.mem[j])
			if s._age(h.mem[j]) >= 16.0 and SettlementTrips.of_person(s, id).is_empty():
				return [int(h.id), j, id]
	return []


func test_carry_over() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var r := w.regions
	var p: SettlementPeople = r.people
	var who := _resident(r, "elmcote")
	var n = p.materialise(int(who[2]))
	check(n != null and is_equal_approx(float(n.hp), float(n.max_hp)), "a resident never hurt comes live at full health (%.0f)" % float(n.hp))
	n.hp = 11.5
	Skills.gain(n, "masonry", 400)
	var xp := int(n.skills.get("masonry", 0))
	p.fold(n)
	var m: Array = r.by_id["elmcote"].hh[int(who[0])].mem[int(who[1])]
	var body := OffMapSettlement.body_of(m)
	check(is_equal_approx(float(body.get("hp", 0.0)), 11.5) and int(body.get("sk", {}).get("masonry", 0)) == xp and xp > 0,
		"folded, the record keeps the injury (11.5 hp) and the skill learned (masonry %d xp)" % xp)
	var n2 = p.materialise(int(who[2]))
	check(is_equal_approx(float(n2.hp), 11.5) and int(n2.skills.get("masonry", 0)) == xp, "made live again, they are still hurt and still skilled")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), saved)
	var m2: Array = w2.regions.by_id["elmcote"].hh[int(who[0])].mem[int(who[1])]
	check(OffMapSettlement.body_of(m2) == OffMapSettlement.body_of(m), "a save carries them (folded first) and loads them as they were")
	var n3 = w2.regions.people.materialise(int(who[2]))
	check(is_equal_approx(float(n3.hp), 11.5) and int(n3.skills.get("masonry", 0)) == xp, "and live again in the loaded world, the same")
	var old: Dictionary = JSON.parse_string(JSON.stringify(saved))
	for sd in old.regions.settlements:
		for h in sd.hh:
			h.mem = (h.mem as Array).map(func(x): return x.slice(0, 6))
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), old)
	var n4 = w3.regions.people.materialise(int(who[2]))
	check(n4 != null and is_equal_approx(float(n4.hp), float(n4.max_hp)) and w3.regions.audit() == "", "an older settlement save (no seventh entry) loads with full health and no recorded skills")
	w.dispose()
	w2.dispose()
	w3.dispose()


func test_leaving_while_live() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var r := w.regions
	var p: SettlementPeople = r.people
	var s: OffMapSettlement = r.by_id["cressbrook"]
	var who := _resident(r, "cressbrook")
	var npcs0 := w.npcs.size()
	var net0 := _net(w)
	var n = p.materialise(int(who[2]))
	n.coins += 0
	n.hp = 20.0
	var load := s.release_household(int(who[0]))
	check(not w.by_id.has(int(who[2])) and p.live.is_empty() and s.live.is_empty() and w.npcs.size() == npcs0,
		"a household leaving while one of them is live: they are folded first, no NPC is left behind")
	check(load.people.any(func(x): return int(x.id) == int(who[2])), "and they go with their household, as a record")
	# a member lost while live (the settlement's own rule removing them): folded first, then removed
	var who2 := _resident(r, "milton")
	var s2: OffMapSettlement = r.by_id["milton"]
	var n2 = p.materialise(int(who2[2]))
	s2._remove_member(s2.hh[int(who2[0])], int(who2[1]))
	check(not w.by_id.has(int(who2[2])) and p.live.is_empty() and p.find(int(who2[2])).is_empty(), "a member lost while live is folded, then removed: no NPC without a record")
	# one member leaves on their own while live
	var who3 := _resident(r, "ewedean")
	var s3: OffMapSettlement = r.by_id["ewedean"]
	p.materialise(int(who3[2]))
	var l3 := s3.release_person(int(who3[0]), int(who3[1]))
	check(not w.by_id.has(int(who3[2])) and int(l3.people[0].id) == int(who3[2]) and p.live.is_empty(), "a person leaving alone while live is folded first and leaves as a record")
	check(r.audit() == "", "the settlements' books balance (%s)" % r.audit())
	w.dispose()
