extends SceneTree
## B25R1-010 (owner directive 2026-11-03, docs/directives/2026-11-03_b25r1_homesteading.md; docs/design/HOMESTEADING_B25R1.md):
## a villager's homestead from the moment they set out to a house standing in the open country and a life there, through the
## real World (World.update in game-minute steps, as economy_sim). WHO goes is LifeDecisions' judged choice (tested in
## life_decisions_test); here the brake is checked first, then one household is started explicitly (Homesteads.begin), the
## entry the choice calls. Checked: land eligibility (the village's and the settlements' land, roads, other claims), the
## gates, the sequence (outfit, travel, claim, clearing, materials bought and delivered, the house built, sleeping in its beds,
## the pantry), identity kept, the posts left, the claim persistent and unique, the house solid in the overworld, coins and the
## goods ledger conserved (economy_sim's flow rule over the materials, food and logs), a save and load in the middle of the
## build, nobody duplicated. Run:
##   godot --headless --path game --script res://tests/homestead_test.gd

var failures := 0
var checks := 0
const ITEMS := ["plank", "building_block", "log", "wheat", "pottage", "axe", "stone", "wheat_seed", "carrot_seed", "carrot"]


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _days(w: World, k: float) -> void:
	var steps := int(k * 1440.0 / (float(GameData.b("game_minutes_per_second")) * 0.5))
	for i in steps:
		w.update(0.5)


## The claims of the village's homesteaders (the band's camp, B25R1-Q2 (a), is a claim of its own from the founding).
func _mine(hs: Homesteads) -> Array:
	return hs.claims.filter(func(c) -> bool: return str(c.get("path", "")) != "band")


func _goods(w: World) -> Dictionary:
	return SettlementHoldings.goods(w)


## economy_sim's flow rule for `ITEMS`: held(now) = held(start) + produced + imported - consumed - exported. {} when it balances.
func _leaks(w: World, g0: Dictionary, st0: Dictionary) -> Dictionary:
	var d := func(k: String) -> int: return int(w.stats.get(k, 0)) - int(st0.get(k, 0))
	var now := _goods(w)
	var bad := {}
	for id in ITEMS:
		var produced: int = d.call("made_" + id) + d.call("mined_" + id) + d.call("felled_" + id) + d.call("farm_harvest_" + id) + d.call("dug_" + id) + d.call("cut_" + id)
		var consumed: int = d.call("eaten_" + id) + d.call("used_" + id) + d.call("used_building_" + id) + d.call("used_works_" + id) \
			+ d.call("used_repairs_" + id) + d.call("feed_eaten_" + id) + d.call("burned_" + id) + d.call("broke_" + id) + d.call("poached_lost_" + id) \
			+ d.call("spoiled_" + id) + d.call("wild_eaten_" + id) + d.call("backfilled_" + id) + d.call("filled_" + id)
		if id == "wheat":
			consumed += d.call("farm_seed_saved")
		var res: int = int(now.get(id, 0)) - (int(g0.get(id, 0)) + produced + d.call("imported_" + id) - consumed - d.call("exported_" + id))
		if res != 0:
			bad[id] = res
	return bad


func _init() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var hs: Homesteads = w.homesteads
	var o: Overworld = w.map.overworld
	# ---- land eligibility
	var lay_v := hs._layout(Vector2i(60, 60))
	check(hs.refusal(lay_v.land) != "", "the village's own ground cannot be claimed (%s)" % hs.refusal(lay_v.land))
	var near_v := hs._layout(o.village.get_center() + Vector2i(0, o.village.size.y / 2 + 12))
	check(hs.refusal(near_v.land).begins_with("This is the village's land"), "land within the village's control area is refused")
	var st: Dictionary = o.sites[0]
	var lay_s := hs._layout((st.rect as Rect2i).get_center() + Vector2i(0, (st.rect as Rect2i).size.y / 2 + 20))
	check(hs.refusal(lay_s.land).begins_with("This land is"), "land within a settlement's control area is refused (%s)" % hs.refusal(lay_s.land))
	var road := hs._road(str(st.id))
	var lay_r := hs._layout(Vector2i(road[60]) + Vector2i(0, 5))
	check(hs.refusal(lay_r.land) != "", "land on the road is refused (%s)" % hs.refusal(lay_r.land))
	# ---- nobody decides in the game while the decision model awaits the owner
	var hh0 := w.households.size()
	for h in w.households.size():
		if w.construction.founder_of(h) != null:
			w.construction._found(h)
			break
	check(_mine(hs).is_empty() and hs.decider.is_valid() and int(w.life.counts.get("brake_young", 0)) >= 1,
		"the first household formations found no homestead: the population brake (2 %% of formations) allows none yet (%s)" % w.life.counts)
	check(w.households.size() >= hh0, "(household formation goes on as before)")
	# ---- a young adult sets out (an explicit start, the entry the decision model will use)
	var cands := []
	for h in w.households.size():
		var f: NPC = w.construction.founder_of(h)
		if f != null and Life.npc_age(w, f) <= 30.0 and hs.gate(h, [f]) == "":
			cands.append([w.property.purse(World.hh_ref(h)), h, f])
	cands.sort()
	check(not cands.is_empty(), "a household has a young adult the village can spare (%d)" % cands.size())
	if cands.is_empty():
		_end(w)
		return
	var h: int = cands[-1][1]
	var who: NPC = cands[-1][2]
	var coins_base := w.total_coins() - w.coin_sources
	check(not hs.begin(h, who, [who]), "without the coins for a start (%d in the family) nobody sets out (counted %s)" % [cands[-1][0], hs.counts.get("gate_coins", 0)])
	w.treasury -= 300
	who.coins += 300                        # the family's savings: a conserved transfer from the manor, so the start can be paid
	check(w.total_coins() - w.coin_sources == coins_base, "(the savings fixture moves coins only)")
	var site := hs.find_site(who)
	check(not site.is_empty() and hs.refusal(site.lay.land) == "", "a site is found on eligible land (%s, %s)" % [site.get("lay", {}).get("house", ""), site.get("why", "")])
	var id0 := who.id
	var name0 := "%s %s" % [who.name, who.family]
	var born0 := who.born
	var job0 := who.job
	var people0: int = w.people.size()
	var npcs0 := w.npcs.size()
	var g0 := _goods(w)
	var st0: Dictionary = w.stats.duplicate()
	check(hs.begin(h, who, [who]), "the young adult sets out to found a homestead (%s)" % name0)
	var c: Dictionary = _mine(hs)[0]
	var nh := who.household
	check(w.households[nh].get("homestead", "") == str(c.id) and int(w.households[nh].founded_from) == h, "they found a household of their own, from the family's (homestead %s)" % c.id)
	check(who.id == id0 and "%s %s" % [who.name, who.family] == name0 and who.born == born0, "the same person: id, name and birth kept")
	check(who.job == "" and str(c.trade) == job0 and w.people[who.id].where == "village", "their village post is left, their trade kept on the claim (%s), their civic record the village's" % job0)
	check(str(c.status) == "intended" and c.site.is_empty(), "the land is chosen, not yet claimed (nobody is there)")
	check(w.total_coins() - w.coin_sources == coins_base, "the start is the family's coins, moved, none made")
	var claimed := false
	var built := false
	var slept_inside := false
	var trips0 := 0
	var spent0 := who.spent
	var saved := {}
	var w2: World = w
	for day in 9:
		for k in 24:
			_days(w2, 1.0 / 24.0)
			var cc: Dictionary = _mine(w2.homesteads)[0]
			if not claimed and str(cc.status) == "claimed":
				claimed = true
				# the first of them to reach it claims it (Homesteads._arrive), standing there (they may be off again within the hour)
				var near_d := Vector2i(int(cc.claimed_at[0]), int(cc.claimed_at[1])).distance_to(Homesteads.step_of(cc)) if cc.has("claimed_at") else 1e9
				check(near_d < 20.0, "the land is claimed only once they have walked there (%s from the door; members %s at %s, door %s, counts %s)" % [near_d, cc.members,
					cc.members.map(func(m): return w2.npc(int(m)).cell()), Homesteads.step_of(cc), w2.homesteads.counts])
				check(JSON.stringify(cc.site.cost) == JSON.stringify(_ints(w2.construction.cost_of("house"))), "the house is the village's house, at its cost %s" % cc.site.cost)
				var fr := o.homes.filter(func(hm) -> bool: return str(hm.id) == str(cc.id))
				check(fr.size() == 1 and str(fr[0].stamp) == "", "its frame stands in the overworld")
			if not built and str(cc.get("building", "")) != "":
				built = true
			if built and w2.hour() >= 23.0:
				var who_n: NPC = w2.npc(id0)
				slept_inside = slept_inside or (who_n.anim == "sleep" and Homesteads.house_of(cc).has_point(who_n.cell()))
		if day == 2 and saved.is_empty():
			# ---- saved and loaded in the middle of the build: the claim, its frame and the household carry on
			check(_leaks(w2, g0, st0).is_empty(), "the goods ledger balances up to the save (%s)" % _leaks(w2, g0, st0))
			saved = JSON.parse_string(JSON.stringify(w2.to_dict()))
			var w3 := World.new()
			w3.load_dict(VillageMap.load_default(), saved)
			check(w3.load_error == "", "the save loads (%s)" % w3.load_error)
			var c3: Dictionary = w3.homesteads.claim(str(c.id))
			check(not c3.is_empty() and str(c3.owner) == str(c.owner) and Homesteads.rect_of(c3) == Homesteads.rect_of(_mine(w2.homesteads)[0]),
				"the claim comes back with its owner and bounds")
			check(Dictionary(c3.site.get("need", {})) == Dictionary(_mine(w2.homesteads)[0].site.get("need", {})), "and what its house still needs %s" % c3.site.get("need", {}))
			check(w3.map.overworld.homes.size() == w2.map.overworld.homes.size(), "its frame or house stands again in the loaded overworld")
			check(w3.npcs.size() == w2.npcs.size() and w3.people.size() == w2.people.size(), "nobody is duplicated by the load (%d villagers)" % w3.npcs.size())
			var tb := w3.total_coins() - w3.coin_sources
			check(tb == w2.total_coins() - w2.coin_sources, "the coins are the same after the load")
			g0 = _goods(w3)
			st0 = w3.stats.duplicate()
			coins_base = tb
			w2.dispose()
			w2 = w3
			o = w3.map.overworld
	var cl: Dictionary = _mine(w2.homesteads)[0]
	var me: NPC = w2.npc(id0)
	check(claimed, "the homesteader reached the land and claimed it")
	check(built, "the house went up (%s; trips %s)" % [cl.status, w2.homesteads.counts.get("trips", 0)])
	check(w2.homesteads.trees_on(Homesteads.house_of(cl)).filter(func(x): return o.tree_at(x).get("state", "") == "grown").is_empty(), "the house's ground was cleared (felled and grubbed: %s grubbed)" % w2.stats.get("homestead_grubbed", 0))
	var solid := 0
	var hr := Homesteads.house_of(cl)
	for y in range(hr.position.y, hr.end.y):
		for x in range(hr.position.x, hr.end.x):
			if o.is_solid(Vector2i(x, y)):
				solid += 1
	check(solid > 20 and not o.is_solid(Homesteads.door_of(cl)) and not o.is_solid(Homesteads.door_of(cl) - Vector2i(0, 1)), "the house is solid in the world, its doorway open (%d wall cells)" % solid)
	check(not w2.map.find_path_world(Homesteads.step_of(cl), w2.homesteads.spots_of(cl, "bed")[0].use).is_empty(), "its beds are reached through its door")
	check(slept_inside, "they sleep in their own house at night")
	check(int(w2.homesteads.counts.get("trips", 0)) >= 2 and me.spent > spent0, "they traded at the village market: bought what they needed (%d coins spent, %d trips)" % [me.spent - spent0, w2.homesteads.counts.get("trips", 0)])
	check(me.alive and me.household == nh and w2.homesteads.claim_of(me) == cl, "they live on, a member of the homestead household")
	check(not w2.map.in_village(me.cell()) or w2.homesteads.trips.has(str(me.id)), "they live out in the country (at %s)" % me.cell())
	check(_mine(w2.homesteads).size() == 1 and w2.homesteads.claims_of(str(cl.owner)).size() == 1, "one claim, one owner: no duplicate claim")
	check(w2.people.size() >= people0 and w2.people.has(id0), "the register still holds them (%d people)" % w2.people.size())
	var ids := {}
	var dup := false
	for n: NPC in w2.npcs:
		dup = dup or ids.has(n.id)
		ids[n.id] = true
	check(not dup, "no villager record is duplicated")
	check(w2.total_coins() - w2.coin_sources == coins_base, "coins conserved since the load (%d)" % (w2.total_coins() - w2.coin_sources - coins_base))
	check(_leaks(w2, g0, st0).is_empty(), "the goods ledger balances (plank, blocks, logs, food, tools: %s)" % _leaks(w2, g0, st0))
	var rep := w2.homesteads.report()
	check(int(rep.rural) >= 1 and int(rep.rural_households) == 1, "the report counts the rural household (%s)" % rep)
	# ---- the homestead's own field (B25R1-014): a farmer's household tills, sows its own seed and grows a crop by Farming's rules
	cl.trade = "farmer"
	cl.trades[str(me.id)] = "farmer"
	var seller: NPC = null
	for so: NPC in w2.npcs:
		if so.alive and so.inv.count("wheat_seed") >= 3 and w2.farm.sells_seed(so):
			seller = so
	if seller == null:
		for so: NPC in w2.npcs:
			if so.alive and so.inv.count("wheat_seed") >= 3:
				seller = so
	var g2 := _goods(w2)
	var s2: Dictionary = w2.stats.duplicate()
	var coins2 := w2.total_coins() - w2.coin_sources
	if seller != null:
		w2.treasury -= 20
		me.coins += 20
		w2.trade(me, seller, "wheat_seed", 3, w2.sell_price(seller, "wheat_seed"))
		w2.transfer(me.inv, w2.households[me.household].pantry, "wheat_seed", 3)
	while not w2.farm.can_sow_now():
		_days(w2, 1.0)
	_days(w2, 3.0)
	var fcells := w2.homesteads.field_cells(cl)
	var sown := fcells.filter(func(x): return str(w2.farm.cells[x].state) in ["growing", "ripe"])
	check(seller != null and fcells.size() >= 1 and sown.size() >= 1, "the household breaks ground on its claim and sows its own seed (%d cells, %d sown)" % [fcells.size(), sown.size()])
	check(fcells.all(func(x): return not Homesteads.house_of(cl).grow(1).has_point(x) and Homesteads.rect_of(cl).has_point(x)), "its field lies on its own land, clear of the house")
	check(_leaks(w2, g2, s2).is_empty() and w2.total_coins() - w2.coin_sources == coins2, "the seed bought and sown, the goods and coins balance (%s)" % _leaks(w2, g2, s2))
	# ---- a second claim may not overlap the first
	check(w2.homesteads.refusal(Homesteads.rect_of(cl)).begins_with("Someone has claimed"), "the claimed land cannot be claimed again")
	# ---- giving up: the people walk back, the delivered materials go to their stores (a fresh start on another world)
	_end(w2)


func _ints(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d:
		out[str(k)] = int(d[k])
	return out


func _end(w: World) -> void:
	w.dispose()
	print("homestead_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
