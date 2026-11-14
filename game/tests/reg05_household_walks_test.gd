extends SceneTree
## MML-REG-05 (owner 2026-11-08, docs/directives/2026-11-08_recovered_owner_messages.md "REG-05 - Households physically migrate"):
## "Migrating villagers and households must physically travel between settlements. They cannot instantly disappear from one
## settlement and appear in another." Preserve identities, family and household membership, carried possessions and coins,
## property and the approved surrender rules (PROP-06: "at the appropriate actual departure point"), physical location during
## travel, ageing and mortality, interrupted journeys, save/load continuity, economic conservation; "Population transfers must occur
## at appropriate departure and arrival points." Register acceptance: "arrival-triggered adoption; one journey system shared with
## REG-04; PROP-06 settlement where the walk starts". The village -> settlement direction. FAILING FIRST on 0bbee94 (the household is
## in the settlement the moment it decides). Pure World. Run headless:
##   godot --headless --path game --script res://tests/reg05_household_walks_test.gd

const Census := preload("res://tests/census.gd")

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL: ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	GameData.ensure()
	test_household_walks()
	test_death_on_the_road()
	test_bride_walks()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _books(w: World) -> Dictionary:
	var goods: Dictionary = Census.goods(w).duplicate()
	var rg := w.regions.goods()
	for k in rg:
		goods[k] = int(goods.get(k, 0)) + int(rg[k])
	var alive := 0
	for n: NPC in w.npcs:
		if n.alive and n.role != "bandit":
			alive += 1
	return {"coins": w.total_coins() + w.regions.coins() - (w.coin_sources + w.regions.net_paid_by_village()), "goods": goods,
		"people": alive + w.regions.population()}


func _world() -> World:
	Migration.enabled = false                         # no other move on the caravan days: this test's party is the only one
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.minutes = 1440.0 + 7.0 * 60.0
	w.regions.step_day(w.day())
	return w


## A plain household (no office, no player tie, no barred member) of two or more.
func _plain(w: World) -> int:
	for h in range(3, w.households.size()):
		var ms: Array = w.brain._members(h)
		if ms.size() >= 2 and not Migration._any_barred(w, ms) and not Life.is_couple(w.households[h]):
			return h
	return -1


## The settlement farthest from the village by road (the longest walk).
func _far(w: World) -> OffMapSettlement:
	var best: OffMapSettlement = null
	for st: OffMapSettlement in w.regions.list:
		if not w.map.overworld.site(st.id).is_empty() and (best == null or Journeys.trip_minutes(w, st.id) > Journeys.trip_minutes(w, best.id)):
			best = st
	return best


func step(w: World, minutes: float, each := Callable()) -> void:
	var until := w.minutes + minutes
	while w.minutes < until:
		w.player.hp = w.player.max_hp
		w.player.hunger = 100.0
		w.update(5.0)
		if each.is_valid():
			each.call()


func _in_settlement(s: OffMapSettlement, ids: Array) -> int:
	var n := 0
	for id in ids:
		if not SettlementTrips._member(s, int(id)).is_empty():
			n += 1
	return n


func test_household_walks() -> void:
	var w := _world()
	var s := _far(w)
	var h := _plain(w)
	check(h >= 0, "fixture: a plain household")
	var ms: Array = w.brain._members(h)
	var ids := ms.map(func(o): return o.id)
	var ref := World.hh_ref(h)
	var owned := []
	for r in w.property.records():
		if w.owner_of(r) == ref:
			owned.append(r)
	w.treasury = maxi(w.treasury, 100000)
	w.households[h].pantry.add("bread", 30)
	var b0 := _books(w)
	var pop0 := s.population()
	var bt := Migration.hiring(s)
	if bt == "":
		bt = "farm"
	check(Migration._household_out(w, s, ms, true, "work", bt), "the household decides to leave for %s (%.0f minutes' walk)" % [s.name, Journeys.trip_minutes(w, s.id)])
	# departure: walking, still the village's people; PROP-06 done now; nothing in the settlement yet
	check(ms.all(func(o): return o.alive and o.away == "" and Journeys.active(o) and str(o.journey.purpose.kind) == "migrate"),
		"every member sets out on foot, alive and still of the village")
	check(_in_settlement(s, ids) == 0 and s.population() == pop0, "nobody is in the settlement yet (population %d, was %d)" % [s.population(), pop0])
	check(owned.all(func(r): return w.owner_of(r) != ref), "PROP-06: the %d properties it owned were settled as it set out" % owned.size())
	check((w.households[h].pantry as Inventory).items.is_empty(), "the pantry was packed: its food is carried")
	check(float(w.stats.get("migrants_out", 0.0)) == 0.0, "no migrant is counted out before arrival")
	var b1 := _books(w)
	check(int(b1.coins) == int(b0.coins) and b1.goods == b0.goods and int(b1.people) == int(b0.people), "nothing lost or made at departure")
	step(w, 600.0)
	check(ms.all(func(o): return Journeys.active(o) and not w.map.in_village(o.cell())), "half a day later they are on the road")
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var s2: OffMapSettlement = w2.regions.by_id[s.id]
	var ms2 := ids.map(func(id): return w2.npc(int(id)))
	check(ms2.all(func(o): return o != null and o.alive and Journeys.active(o) and str(o.journey.purpose.party) == str(ms[0].journey.purpose.party)),
		"saved and loaded on the road: the same party walks on")
	check(_in_settlement(s2, ids) == 0, "still nobody in %s after the load" % s.name)
	check(ms2.all(func(o): return int(o.household) == h), "family and household membership kept on the road")
	var tr := {"jump": 0.0, "last": ms2[0].pos}
	step(w2, 8 * 1440.0, func() -> void:
		if ms2[0].alive:
			tr.jump = maxf(float(tr.jump), ms2[0].pos.distance_to(tr.last))
			tr.last = ms2[0].pos)
	for o: NPC in ms2:
		print("  member %d %s role %s alive %s away '%s' journey %s doing '%s' at %s hunger %.0f" % [o.id, o.name, o.role, str(o.alive), o.away, str(o.journey), o.doing, o.cell(), o.hunger])
	check(ms2.all(func(o): return not o.alive and str(o.away) == s.id), "on arrival they leave the village's living (away in the settlement)")
	check(_in_settlement(s2, ids) == ids.size(), "all %d are members in %s now" % [ids.size(), s.name])
	var hids := {}
	for id in ids:
		hids[int(SettlementTrips._member(s2, int(id))[0])] = true
	check(hids.size() == 1, "one household there, as they were one here")
	check(float(w2.stats.get("migrants_out", 0.0)) == float(ids.size()) and float(w2.stats.get("migration_arrived", 0.0)) == 1.0, "counted out on arrival, once")
	check(float(tr.jump) <= 14.0 and float(tr.jump) > 0.0, "walked, never moved at once (largest 10-minute step %.2f tiles)" % float(tr.jump))
	var b2 := _books(w2)
	check(int(b2.coins) == int(b0.coins), "coins conserved departure to arrival (gap %d, was %d)" % [int(b2.coins), int(b0.coins)])
	check(w2.regions.audit() == "", "the settlements' books balance (%s)" % w2.regions.audit())


func test_death_on_the_road() -> void:
	var w := _world()
	var s := _far(w)
	var h := _plain(w)
	var ms: Array = w.brain._members(h)
	w.treasury = maxi(w.treasury, 100000)
	w.households[h].pantry.add("bread", 30)        # food for the road (without it a member may starve too: the road's hunger is theirs)
	var b0 := _books(w)
	check(Migration._household_out(w, s, ms, true, "work", "farm"), "fixture: the household sets out")
	step(w, 600.0)
	check(not w.map.in_village(ms[0].cell()) and Journeys.active(ms[0]), "fixture: on the road")
	var lost: NPC = ms[ms.size() - 1]
	w.kill(lost, "test: died on the road")
	check(not Journeys.active(lost) and lost.away == "", "one dies on the road: their walk ends, they never reach the settlement")
	step(w, 8 * 1440.0)
	var rest := ms.filter(func(o): return o != lost)
	for o: NPC in rest:
		print("  member %d %s role %s alive %s away '%s' journey %s at %s hunger %.0f" % [o.id, o.name, o.role, str(o.alive), o.away, str(o.journey), o.cell(), o.hunger])
	check(rest.all(func(o): return not o.alive and str(o.away) == s.id), "the others go on and join the settlement")
	check(int(_books(w).coins) == int(b0.coins), "coins conserved (what the dead carried passed by the death rules)")


func test_bride_walks() -> void:
	var w := _world()
	var s := _far(w)
	var bride: NPC = null
	for n: NPC in w.npcs:
		if n.sex == "female" and Migration._marriageable(w, n) and Life._may_move(w, n):
			bride = n
			break
	var gi := -1
	var gj := -1
	for i in s.hh.size():
		for j in (s.hh[i].mem as Array).size():
			if gi < 0 and bool(s.hh[i].alive) and int(s.hh[i].mem[j][OffMapSettlement.M_SEX]) == 0 and int(s.hh[i].mem[j][OffMapSettlement.M_PAIR]) == 0:
				gi = i
				gj = j
	check(bride != null and gi >= 0, "fixture: a village bride and a groom in the settlement")
	if bride == null or gi < 0:
		return
	var groom := OffMapSettlement.member_id(s.hh[gi].mem[gj])
	check(Migration._set_out(w, s, [bride], "marriage", {"mode": "wed", "gi": gi, "groom": groom}), "she sets out to marry him")
	check(bride.alive and Journeys.active(bride) and int(s.hh[gi].mem[gj][OffMapSettlement.M_PAIR]) == 0, "not married before she arrives")
	step(w, 8 * 1440.0)
	var me := SettlementTrips._member(s, bride.id)
	check(not bride.alive and not me.is_empty() and int(s.hh[int(me[0])].mem[int(me[1])][OffMapSettlement.M_PAIR]) == 1, "married on arrival")
