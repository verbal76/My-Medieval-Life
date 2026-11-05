extends SceneTree
## B25R1-010 (owner directive 2026-11-03 section 12): the player homesteads outside every settlement's land: finds eligible open
## country, claims it (the same rules and record as anybody's), clears the house's ground and gathers logs with the game's own
## felling, brings the village's house materials (bought in real trades, none given), the house goes up, stores in its chest,
## sleeps in its bed, saves, loads and carries on living there. Coins and goods are conserved throughout; one claim at a time.
## The claim's targets (Main's target list reads Homesteads.player_targets) are checked as Main asks for them. Run:
##   godot --headless --path game --script res://tests/player_homestead_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _kinds(w: World, probe: Vector2, up: bool) -> Array:
	return w.homesteads.player_targets(w.player, probe, up).map(func(t): return str(t.kind))


## Buy `qty` of `id` for the player from whoever in the village holds it, at the seller's own asking price (World.trade).
func _buy(w: World, id: String, qty: int) -> int:
	var got := 0
	for o: NPC in w.npcs:
		if got >= qty or not o.alive:
			continue
		var k := mini(qty - got, o.inv.count(id) - w.brain.reserve(o, id))
		if k <= 0 or w.brain.keeps(o, id):
			continue
		var price := w.sell_price(o, id)
		if w.trade(w.player, o, id, k, price):
			got += k
	return got


func _init() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 2)
	var hs: Homesteads = w.homesteads
	var p := w.player
	var o: Overworld = w.map.overworld
	check(hs.player_claim_refusal(p) != "", "in the village the player cannot claim land (%s)" % hs.player_claim_refusal(p))
	# a piece of open country: the first eligible land a homesteader's search finds (the same rules)
	var site := hs.find_site(w.npcs[10])
	check(not site.is_empty(), "eligible open country exists outside every settlement's land")
	if site.is_empty():
		_end(w)
		return
	var step: Vector2i = Vector2i(site.lay.door) + Vector2i(0, 1)
	p.pos = Vector2(step) + Vector2(0.5, 0.5)
	check(hs.player_claim_refusal(p) == "", "standing there, facing north, the player may claim it")
	check(_kinds(w, p.pos + Vector2(0, -0.6), true).has("homestead_claim") and not _kinds(w, p.pos + Vector2(0, 0.6), false).has("homestead_claim"),
		"the target list offers the claim when facing north (not otherwise)")
	var coins_base := w.total_coins() - w.coin_sources
	var goods0 := SettlementHoldings.goods(w)
	check(hs.player_claim(p) == "", "the player claims the land and marks out a house")
	var c: Dictionary = hs.claims[-1]
	check(str(c.owner) == w.player_ref(p) and str(c.status) == "claimed" and (c.known as Array).has(p.pid), "the claim is the player's, recorded and known to them")
	check(hs.player_claim_refusal(p) != "", "one unfinished homestead at a time (%s)" % hs.player_claim_refusal(p))
	check(hs.refusal(Homesteads.rect_of(c)).begins_with("Someone has claimed"), "nobody else can claim the same land")
	check(not hs.known_markers(p).is_empty() and bool(hs.known_markers(p)[0].own), "the region map's hook lists it for the player (%s)" % hs.known_markers(p))
	check(SettlementHoldings.goods(w) == goods0 and w.total_coins() - w.coin_sources == coins_base, "claiming wilderness costs nothing and makes nothing")
	check(_kinds(w, p.pos + Vector2(0, -0.6), true).has("homestead_site"), "at the frame the player can bring materials")
	var empty := Inventory.new()
	var keep := p.inv
	p.inv = empty
	check(hs.player_deliver(p, str(c.id)) == "You have nothing the house still needs.", "with nothing in the pack nothing is delivered (no free materials)")
	p.inv = keep
	# ---- clear the house's ground and gather logs: the player's own felling, an axe bought in the village
	if not p.inv.has("axe"):
		w.treasury -= 40
		p.coins += 40                        # (savings for the axe: a conserved transfer)
		_buy(w, "axe", 1)
	check(p.inv.has("axe"), "the player has an axe")
	var standing := hs.clear_ground(c)
	var felled := 0
	for cell: Vector2i in standing:
		var t := w.tree_at(cell)
		for k in 20:
			var r := w.player_chop(t, 1, "axe")
			if str(r.get("result", "")) != "blow":
				break
		felled += 1
	check(hs.clear_ground(c).is_empty(), "the trees on the house's ground are felled (%d) and their stumps grubbed up" % felled)
	var tries := 0
	while p.inv.count("log") < 10 and tries < 30:
		tries += 1
		var best := Vector2i(1 << 30, 0)
		for t in o.chunk_trees(Overworld.chunk_of(step)):
			if str(t.state) == "grown" and not o.is_top(Vector2i(int(t.x), int(t.y))) and not Homesteads.rect_of(c).has_point(Vector2i(int(t.x), int(t.y))):
				best = Vector2i(int(t.x), int(t.y))
				break
		if best.x == 1 << 30:
			break
		var tr := w.tree_at(best)
		for k in 20:
			if str(w.player_chop(tr, 1, "axe").get("result", "")) != "blow":
				break
		if not p.inv.has("axe"):
			w.treasury -= 40
			p.coins += 40
			_buy(w, "axe", 1)
	check(p.inv.count("log") >= 10, "the player gathered logs from the trees round the homestead (%d)" % p.inv.count("log"))
	# ---- the rest of the house bought in the village (coins first moved from the manor: a conserved transfer)
	w.treasury -= 400
	p.coins += 400
	var planks := _buy(w, "plank", 30)
	var blocks := _buy(w, "building_block", 20)
	var done := hs.player_deliver(p, str(c.id))
	print("     deliver: '%s'; still needs %s" % [done, Homesteads.need_text(c)])
	if not bool(c.site.done):
		# the village's sellers did not hold enough today: their own makers' stock tomorrow (time passes, nothing is given)
		for day in 4:
			for k in 2880:
				w.update(0.5)
			p.pos = Vector2(step) + Vector2(0.5, 0.5)
			p.hunger = 100.0
			planks += _buy(w, "plank", int(c.site.need.get("plank", 0)))
			blocks += _buy(w, "building_block", int(c.site.need.get("building_block", 0)))
			hs.player_deliver(p, str(c.id))
			if bool(c.site.done):
				break
	check(planks == 30 and blocks == 20, "the planks (%d) and building blocks (%d) were bought from the village's sellers" % [planks, blocks])
	check(bool(c.site.done) and str(c.building) != "" and str(c.status) == "built", "the last load is in and the house stands (%s)" % c.status)
	var mine_h := o.homes.filter(func(hm) -> bool: return str(hm.id) == str(c.id))     # (the band's camp is drawn too, B25R1-Q2 a)
	check(mine_h.size() == 1 and str(mine_h[0].stamp) == "house" and o.is_solid(Homesteads.house_of(c).position), "the house is drawn and solid in the overworld")
	var bed: Dictionary = hs.spots_of(c, "bed")[0]
	check(not w.map.find_path_world(step, bed.use).is_empty(), "the player can walk in through its door to the beds")
	p.pos = Vector2(bed.use) + Vector2(0.5, 0.5)
	var at_bed := Vector2(bed.at) + Vector2(0.5, 0.5)
	check(_kinds(w, at_bed, false).has("rest"), "beside a bed the target list offers sleep")
	var chest_spot: Dictionary = hs.spots_of(c, "chest")[0]
	p.pos = Vector2(chest_spot.use) + Vector2(0.5, 0.5)
	check(_kinds(w, Vector2(chest_spot.at) + Vector2(0.5, 0.5), false).has("chest"), "beside the chest the target list offers it")
	var u := w.chests.unit("homestead:" + str(c.id))
	check(str(w.chests.info(u).access) == "own", "the homestead chest is the player's own store")
	var g1 := SettlementHoldings.goods(w)
	var item := "log" if p.inv.has("log") else "axe"
	var have := p.inv.count(item)
	check(w.chests.store(u, item, 1) == "" and (c.store as Inventory).count(item) == 1 and p.inv.count(item) == have - 1, "the player stores a %s in it" % item)
	check(SettlementHoldings.goods(w) == g1, "the goods in the homestead chest are counted (the census unchanged)")
	var coins_now := w.total_coins() - w.coin_sources
	check(coins_now == coins_base, "coins conserved through the whole build (%d)" % (coins_now - coins_base))
	# ---- a field on the homestead's own land: the village's farming rules in the open country (B25R1-014)
	var field := Vector2i(1 << 30, 0)       # none yet (the open country runs to negative cells: -1 is a real cell)
	var land := Homesteads.rect_of(c)
	for y in range(land.position.y, land.end.y):
		for x in range(land.position.x, land.end.x):
			var fc := Vector2i(x, y)
			if field.x == 1 << 30 and w.farm.land_refusal(fc) == "" and w.farm.obstacle(fc).is_empty():
				field = fc
	check(field.x != 1 << 30, "the homestead's land beside the house can be farmed (%s)" % field)
	check(w.farm.land_refusal(Homesteads.door_of(c)) != "" and w.farm.land_refusal(step + Vector2i(40, 0)) != "", "but not the house's ground, nor land that is not the player's")
	var seeds := 0
	if field.x != 1 << 30:
		p.pos = Vector2(field) + Vector2(0.5, 1.5)
		p.stamina = 100.0
		check(w.farm.till(field, p) == "" and w.farm.cells.has(field), "the player tills it by hand, with the stamina it costs")
		for crop_seed in ["wheat_seed", "carrot_seed", "potato_seed"]:
			if seeds == 0 and _buy(w, crop_seed, 1) == 1:
				seeds = 1
				while not w.farm.can_sow_now():
					w.minutes += 1440.0
				var crop := Farming.crop_of_seed(crop_seed)
				check(w.farm.sow(field, crop, p) == "", "sows %s bought from a village seller" % crop)
				var hours := 0
				while str(w.farm.cells[field].state) != "ripe" and hours < 24 * 60:
					w.minutes += 60.0
					w.farm.hour()
					hours += 1
				var got := w.farm.harvest(field, p)
				check(not got.is_empty(), "it ripens and is harvested into the pack: %s (after %d hours)" % [got, hours])
		check(seeds == 1, "(a seed was to be had)")
	# ---- a well on the homestead's land (B25R1-Q3 "Both": the same well record and add_well path as an NPC claim's), its stone and
	# logs bought in the village, its digging begun before the save and finished after it (below)
	var wcell := Vector2i(1 << 30, 0)
	for y in range(land.position.y, land.end.y):
		for x in range(land.position.x, land.end.x):
			var cand := Vector2i(x, y)
			if wcell.x != 1 << 30 or cand == field or o.is_solid(cand) or w.map.find_path_world(step, cand).is_empty():
				continue
			p.pos = Vector2(cand) + Vector2(0.5, 0.5)
			if w.wilds.player_targets(p, p.pos).any(func(t) -> bool: return str(t.kind) == "wild_well_mark"):
				wcell = cand
	check(wcell.x != 1 << 30, "standing on the homestead's land the target list offers Mark out a well (%s)" % wcell)
	var pwl := {}
	if wcell.x != 1 << 30:
		p.pos = Vector2(wcell) + Vector2(0.5, 0.5)
		check(not _kinds(w, p.pos, false).is_empty() and hs.player_targets(p, p.pos, false).any(func(t) -> bool: return str(t.kind) == "wild_well_mark"),
			"Main's target list (Homesteads.player_targets) carries the well target")
		p.pos = Vector2(step + Vector2i(60, 60)) + Vector2(0.5, 0.5)
		check(not w.wilds.player_targets(p, p.pos).any(func(t) -> bool: return str(t.kind) == "wild_well_mark"), "off the homestead's land no well is offered")
		p.pos = Vector2(wcell) + Vector2(0.5, 0.5)
		var n_wells := w.wilds.wells.size()
		check(w.wilds.player_well(p, "wild_well_mark", str(c.id)) == "", "the player marks out a well on their own land")
		pwl = w.wilds.work_of(c, "well")
		check(w.wilds.wells.size() == n_wells + 1 and str(pwl.owner) == "claim:" + str(c.id) and Vector2i(int(pwl.cell[0]), int(pwl.cell[1])) == wcell,
			"one record in the wells registry, the claim's, at the marked cell (%s)" % pwl.get("id", ""))
		var wcost: Dictionary = w.wilds.cfg().well_cost
		check(pwl.cost == {"stone": int(wcost.stone), "log": int(wcost.log)} and not bool(pwl.done) and float(pwl.labour) == float(w.wilds.cfg().well_labour),
			"its cost and labour are an NPC claim's well's (%s, %d minutes)" % [pwl.cost, int(pwl.labour)])
		check(w.wilds.player_well(p, "wild_well_mark", str(c.id)) != "", "one well a homestead")
		var pack := p.inv
		p.inv = Inventory.new()
		check(w.wilds.player_well(p, "wild_well", str(pwl.id)) != "" and pwl.need == pwl.cost, "with nothing in the pack nothing is delivered (no free materials)")
		p.inv = pack
		var stone_bought := _buy(w, "stone", maxi(0, int(wcost.stone) - p.inv.count("stone")))
		if p.inv.count("log") < int(wcost.log):
			_buy(w, "log", int(wcost.log) - p.inv.count("log"))
		var g_well := SettlementHoldings.goods(w)
		var coins_well := w.total_coins() - w.coin_sources
		check(w.wilds.player_well(p, "wild_well", str(pwl.id)) == "" and (pwl.need as Dictionary).is_empty(), "the player brings its stone (%d bought) and logs" % stone_bought)
		check(SettlementHoldings.goods(w) == g_well, "the materials on the dig are counted (the census unchanged)")
		check(not o.is_solid(wcell), "the dig is walkable ground")
		for i in 3:
			w.wilds.player_well(p, "wild_well", str(pwl.id))
		check(not bool(pwl.done) and float(pwl.labour) == float(w.wilds.cfg().well_labour) - 3.0 * float(w.wilds.cfg().player_dig_minutes),
			"each Use digs for a while (%d minutes left)" % int(pwl.labour))
		check(w.total_coins() - w.coin_sources == coins_well, "coins conserved at the well")
	# ---- sleep there, save, load, carry on
	p.pos = Vector2(bed.use) + Vector2(0.5, 0.5)
	var r := w.player_rest()
	check(float(r.get("minutes", 0.0)) > 0.0, "the player rests at home in the country")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var pos0 := w.player.pos
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), saved)
	check(w2.load_error == "", "the save loads")
	var c2: Dictionary = w2.homesteads.claim(str(c.id))
	check(not c2.is_empty() and str(c2.status) == "built" and str(c2.owner) == w2.player_ref(w2.player), "the homestead is still the player's after loading")
	check(w2.player.pos.distance_to(pos0) < 0.01 and not w2.map.in_village(Vector2i(w2.player.pos.floor())), "the player is back at home in the country")
	check(w2.map.overworld.is_solid(Homesteads.house_of(c2).position) and w2.map.overworld.homes.filter(func(hm) -> bool: return str(hm.id) == str(c.id)).size() == 1, "the house stands again")
	var u2 := w2.chests.unit("homestead:" + str(c.id))
	check((c2.store as Inventory).count(item) == 1 and str(w2.chests.info(u2).access) == "own", "the chest still holds what was stored")
	var t2 := w2.chests.take(u2, item, 1)
	check(bool(t2.ok) and w2.player.inv.count(item) >= 1, "and the player takes it back out")
	check(w2.homesteads.player_claim_refusal(w2.player) != "", "their own land is not claimable again")
	if field.x != 1 << 30:
		check(w2.farm.cells.has(field), "the homestead's field is still there after loading")
	if not pwl.is_empty():
		var wl2: Dictionary = w2.wilds.well(str(pwl.id))
		check(not wl2.is_empty() and not bool(wl2.done) and float(wl2.labour) == float(pwl.labour) and (wl2.need as Dictionary).is_empty()
			and w2.wilds.work_of(c2, "well").get("id", "") == pwl.id, "the half-dug well is still the homestead's after loading (%d minutes left)" % int(wl2.get("labour", 0)))
		var p2 := w2.player
		p2.pos = Vector2(wcell) + Vector2(0.5, 0.5)
		check(w2.wilds.player_targets(p2, p2.pos).any(func(t) -> bool: return str(t.kind) == "wild_well" and str(t.id) == str(pwl.id)), "standing at it the target list offers Dig your well")
		var used0 := float(w2.stats.get("used_building_stone", 0.0))
		var g_dig := SettlementHoldings.goods(w2)
		var uses := 0
		while not bool(wl2.done) and uses < 20:
			w2.wilds.player_well(p2, "wild_well", str(pwl.id))
			uses += 1
		check(bool(wl2.done) and w2.wilds.source_of(c2) != Wilds.NONE, "dug by the player's own work the well stands (%d more Uses) and is the homestead's water" % uses)
		var stone_used := float(w2.stats.get("used_building_stone", 0.0)) - used0
		check(int(stone_used) == int(wl2.cost.stone) and int(g_dig.get("stone", 0)) - int(SettlementHoldings.goods(w2).get("stone", 0)) == int(wl2.cost.stone),
			"its stone leaves the census and is booked as used in building (%d)" % int(stone_used))
		check(not w2.map.overworld.is_solid(wcell) and not w2.map.find_path_world(step, wcell).is_empty(), "the finished well is walkable, reached from the door")
		check(w2.map.overworld.homes.any(func(hm) -> bool: return str(hm.id) == "%s_%s" % [c.id, pwl.id]), "the well is drawn in the overworld")
		var saved3: Dictionary = JSON.parse_string(JSON.stringify(w2.to_dict()))
		var w3 := World.new()
		w3.load_dict(VillageMap.load_default(), saved3)
		check(w3.load_error == "" and bool(w3.wilds.well(str(pwl.id)).get("done", false)) and w3.wilds.well_at(wcell).get("id", "") == pwl.id,
			"the finished well is saved and loads standing")
		w3.dispose()
	w2.dispose()
	_end(w)


func _end(w: World) -> void:
	w.dispose()
	print("player_homestead_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
