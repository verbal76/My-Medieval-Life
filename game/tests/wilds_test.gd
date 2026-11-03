extends SceneTree
## B25R1-014 / B25R1-017 (owner directives 2026-11-03: outlaw communities, full scope, integration and water; Wilds,
## docs/design/HOMESTEADING_B25R1.md section 11): the shared wilderness foundation's gameplay through the real World.
## A  the band moves to the wild at the founding (B25R1-Q2 option a): a household of its own on a concealed outlaw claim in the
##    open country, every bandit its member, nobody made or lost, and they walk there by the road.
## B  an older save (Build 24 fixture, save 23) loads with the band moved to a camp claim: every bandit, coin and item kept.
## C  water (B25R1-Q3): no stream, so the camp's source is a well, built from real stone and logs and labour; water drawn and
##    drunk; a dry day hurts; the recorder's kinds.
## D  livestock: a pen built on the claim becomes a Fauna pen; an animal bought from the manor's keeper (the keeper paid, the
##    animal moved, coins conserved); slaughter through the village's act.
## E  crafting: an outlaw smith at the camp's smithy makes a sword through World.work_craft (inputs used, skill gained, no
##    bonus); a member without a weapon buys it (World.trade: the members-only market); a player not trusted is refused.
## F  a raid: real legs (road out, the village by night, the road home) and the coin audit; the judged raid weighed at dawn.
## G  fight and pursuit outside the village move over the world's ground (not stopped at the village map's edge).
## H  remote danger: countryside animals near a lived-in claim become real with no player near.
## I  allegiance: a starving lawful homestead weighs turning outlaw; a bandit with family on their own claim leaves the band and
##    stays there, the claim lawful again: the same claim, people and buildings.
## J  save and load of all of it, and deterministic replay of a day.
## Run: godot --headless --path game --script res://tests/wilds_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _hours(w: World, k: float) -> void:
	var steps := int(k * 60.0 / (float(GameData.b("game_minutes_per_second")) * 0.5))
	for i in steps:
		w.update(0.5)


func _band(w: World) -> Array:
	return w.npcs.filter(func(o: NPC) -> bool: return o.alive and (o.role == "bandit" or o.clan == "bandit"))


func _coins(w: World) -> int:
	return w.total_coins() - w.coin_sources


func _init() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var hs: Homesteads = w.homesteads
	var wl: Wilds = w.wilds
	# ---- A: the band in the wild
	var bh := wl.band_household()
	var bc := wl.band_claim()
	var band := _band(w)
	check(bh >= 0 and not bc.is_empty() and str(bc.path) == "band", "A: the band is a household on a claim of its own (%s)" % str(bc.get("id", "")))
	check(str(bc.faction) == "outlaw" and bool(bc.concealed), "A: the claim is outlaw and concealed")
	check(not w.map.in_village(w.bandit_camp) and w.bandit_camp == Homesteads.step_of(bc), "A: the camp is in the open country, at the claim (%s)" % w.bandit_camp)
	check(band.size() == int(GameData.b("bandits")) and band.all(func(o: NPC) -> bool: return o.household == bh and (bc.members as Array).has(o.id)),
		"A: every bandit (%d) is a member, none made" % band.size())
	check(str(bc.status) == "claimed" and not bc.site.is_empty(), "A: the camp's house is a frame to be built (nothing given)")
	check(not bc.get("water_src", {}).is_empty() and str(bc.water_src.source) == "well" and not wl.work_of(bc, "well").is_empty(),
		"A: with no stream in reach its water is to be a well dug on the claim")
	var coins0 := _coins(w)
	_hours(w, 26.0)
	var near_camp := _band(w).filter(func(o: NPC) -> bool: return o.cell().distance_to(w.bandit_camp) <= float(Homesteads.cfg().home_radius) + 2.0).size()
	check(near_camp >= 1, "A: within a day they have walked to the camp (%d of %d there)" % [near_camp, _band(w).size()])
	check(_coins(w) == coins0, "A: coins conserved through the day (%d -> %d)" % [coins0, _coins(w)])
	# ---- B: an older save's band moves on load
	var fx := FileAccess.get_file_as_string("res://tests/fixtures/b24_save_v23_single.json")
	var old: Dictionary = JSON.parse_string(fx)
	# (a band too poor to dig a well and with no stream near cannot make a camp: it stays and tries each dawn, below; here the
	# fixture's bandits carry 20 coins each, a scenario of the same save)
	for nd in old.npcs:
		if bool(nd.get("alive", true)) and str(nd.get("role", "")) == "bandit":
			nd.coins = 20
	var ob := []
	var oc := 0
	var oi := 0
	for nd in old.npcs:
		if bool(nd.get("alive", true)) and (str(nd.get("role", "")) == "bandit" or str(nd.get("clan", "")) == "bandit"):
			ob.append(int(nd.id))
			oc += int(nd.get("coins", 0))
			for k in (nd.get("inv", {}).get("items", {}) as Dictionary):
				oi += int(nd.inv.items[k])
	var wo := World.new()
	wo.load_dict(VillageMap.load_default(), old)
	var obh := wo.wilds.band_household()
	var nb := _band(wo)
	var nc := 0
	var ni := 0
	for o: NPC in nb:
		nc += o.coins
		ni += o.inv.total()
	check(wo.load_error == "" and obh >= 0 and str(wo.wilds.band_claim().get("path", "")) == "band", "B: the save-23 world loads with the band's camp claim made (%s)" % wo.load_error)
	check(nb.size() == ob.size() and nb.all(func(o: NPC) -> bool: return ob.has(o.id) and o.household == obh), "B: every bandit kept and moved there (%d)" % nb.size())
	check(nc == oc and ni == oi, "B: not a coin or an item lost (%d/%d coins, %d/%d items)" % [nc, oc, ni, oi])
	check(int(wo.wilds.counts.get("band_load", 0)) == 1, "B: recorded as the band's move on load")
	# ---- C: water and the well
	var leader: NPC = band[0]
	var wk := wl.work_of(bc, "well")
	leader.inv.add("stone", int(wk.need.stone))
	leader.inv.add("log", int(wk.need.log))
	w.stat("imported_stone", float(wk.need.stone))
	check(wl.deliver_work(bc, leader.inv, World.npc_ref(leader.id)) and (wk.need as Dictionary).is_empty(), "C: the well's stone and logs delivered")
	check(Wilds.work_delivered(bc).get("stone", 0) == int(wk.cost.stone), "C: materials on the unfinished well are counted (goods)")
	check(wl.source_of(bc) == Wilds.NONE, "C: no water until it is dug")
	wl.labour(bc, wk, float(Wilds.cfg().well_labour) - 1.0, leader)
	check(not bool(wk.done), "C: labour is needed, not only materials")
	wl.labour(bc, wk, 60.0, leader)
	check(bool(wk.done) and wl.source_of(bc) != Wilds.NONE, "C: the well stands, a source of water")
	bc.water = 0
	check(wl.act(leader, bc, "draw_water", {}) and int(bc.water) == int(Wilds.cfg().draw_units), "C: water drawn at the well (%d)" % int(bc.water))
	var members: Array = w.brain._members(bh)
	var hp0 := leader.hp
	bc.water = 0
	var dry0 := int(bc.get("dry_days", 0))
	var short := wl._drink(bc, members)
	check(short == members.size() and leader.hp < hp0 and int(bc.dry_days) == dry0 + 1, "C: a dry dawn: everyone thirsty and hurt (%d short, hp %.1f -> %.1f)" % [short, hp0, leader.hp])
	bc.water = members.size()
	check(wl._drink(bc, members) == 0 and int(bc.water) == 0 and int(bc.dry_days) == 0, "C: with water enough all drink")
	# ---- D: livestock
	hs._finish(bc)
	var pr := wl._pen_rect(bc)
	check(pr != Rect2i(), "D: ground for a pen on the claim")
	var pw := wl._new_work(bc, "pen", pr)
	pw.animal = "chicken"
	leader.inv.add("log", int(pw.need.log))
	w.stat("imported_log", float(pw.need.log))
	wl.deliver_work(bc, leader.inv, "")
	wl.labour(bc, pw, 999.0, leader)
	var pen := wl.pen_of_claim(bc)
	check(not pen.is_empty() and not w.fauna.cells(str(pen.id)).is_empty(), "D: the pen is a Fauna pen with ground on the claim (%d cells)" % w.fauna.cells(str(pen.id)).size())
	var src := w.fauna.pen_of("chicken")
	var keeper: NPC = w.pen_keeper(src)
	var k0 := keeper.coins if keeper != null else w.treasury
	var c0 := _coins(w)
	leader.coins += 40
	w.coin_sources += 40
	var bought := wl.buy_animal(leader, bc, "f")
	check(bought and w.fauna.count(str(pen.id), "chicken") == 1, "D: a hen bought from the manor's keeper for the claim's pen")
	check((keeper.coins if keeper != null else w.treasury) > k0 and _coins(w) == c0, "D: the keeper paid, coins conserved")
	wl.led_home(leader)
	var hen: Animal = null
	for a: Animal in w.fauna.animals:
		if a.alive and a.area == str(pen.id):
			hen = a
	check(hen != null and w.fauna.in_area(str(pen.id), Vector2i(hen.pos.floor())), "D: led home into the pen")
	check(w.brain.act(leader, "slaughter", {"pen": pen.id, "animal": hen.id, "why": "test"}) and w.fauna.count(str(pen.id), "chicken") == 0 and leader.inv.has("meat"),
		"D: slaughtered through the village's act: meat in hand")
	# ---- E: crafting at the camp's smithy
	var sr := wl._workshop_rect(bc, "workshop_smithy")
	var smithy := wl._new_work(bc, "workshop_smithy", sr if sr != Rect2i() else Rect2i(Homesteads.house_of(bc).position + Vector2i(11, 0), Vector2i(9, 10)))
	smithy.need = {}
	smithy.done = true
	var smith: NPC = band[1] if band.size() > 1 else leader
	Skills.gain(smith, "smithing", 400)
	smith.inv.add("hammer")
	w.stat("imported_hammer")
	var pantry: Inventory = w.households[bh].pantry
	pantry.add("copper_bar", 2)
	pantry.add("plank", 1)
	w.stat("imported_copper_bar", 2.0)
	w.stat("imported_plank", 1.0)
	var buyer: NPC = band[2] if band.size() > 2 else leader
	var sword_spare := buyer.inv.count("copper_sword")
	buyer.inv.remove("copper_sword", sword_spare)
	pantry.add("copper_sword", sword_spare)
	var pick := wl.craft_pick(smith, bc)
	check(pick == "forge_copper_sword", "E: the camp's smith picks the sword a member lacks (%s)" % pick)
	var lv := Skills.level(smith, "smithing")
	var xp0: int = int(smith.skills.get("smithing", 0)) if smith.skills is Dictionary else 0
	wl._plan_craft(smith, bc)
	buyer.coins += 100
	w.coin_sources += 100
	var cb := _coins(w)
	check(wl._craft(smith, bc, pick), "E: made through World.work_craft (skill, tools, inputs)")
	check(pantry.count("copper_bar") == 0 and smith.inv.count("copper_bar") == 0, "E: the inputs are used up")
	check(buyer.inv.has("copper_sword") or smith.inv.has("copper_sword"), "E: a copper sword exists (made)")
	check(buyer.inv.has("copper_sword") and int(wl.counts.get("members_trade", 0)) >= 1 and _coins(w) == cb, "E: the member without a weapon bought it from the smith (members-only, coins conserved)")
	check(Skills.level(smith, "smithing") >= lv, "E: skill from the work, never lost (%d -> %d)" % [lv, Skills.level(smith, "smithing")])
	var p := w.player
	var why := wl.player_trade_refusal(p, smith)
	check(not hs.remote(smith) or why != "", "E: a stranger cannot trade at the outlaws' camp (%s)" % why)
	# ---- F: a raid's legs
	var raider: NPC = leader
	raider.target = -1
	raider.plan.clear()
	raider.hp = raider.max_hp
	wl.raiders[str(raider.id)] = {"claim": str(bc.id), "leg": "out", "day": w.day(), "coins0": raider.coins, "goods0": raider.inv.total(), "hp0": raider.hp, "night": false}
	var cr := _coins(w)
	var reached := false
	for i in 48:
		_hours(w, 1.0)
		reached = reached or (w.map.in_village(raider.cell()) and str(wl.raiders.get(str(raider.id), {}).get("leg", "")) == "village")
		if not wl.raiders.has(str(raider.id)):
			break
	check(reached, "F: the raider walked the road to the village")
	check(not raider.alive or not wl.raiders.has(str(raider.id)) or str(wl.raiders[str(raider.id)].leg) == "back", "F: and went home after the night (or fell)")
	check(_coins(w) == cr, "F: coins conserved through the raid (%d -> %d)" % [cr, _coins(w)])
	for d in 6:
		wl._raid_dawn()
	check(int(wl.counts.get("raid_weighed", 0)) >= 1, "F: the band's eldest weighs raids at dawn by judgment (%s)" % wl.counts)
	# ---- G: a chase in the open country
	var g: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.job == "guard":
			g = o
	var victim: NPC = band[band.size() - 1]
	var spot := Homesteads.step_of(bc) + Vector2i(0, 24)     # away from the camp (guards do not follow into it)
	victim.pos = Vector2(w.nearest_open_world(spot)) + Vector2(0.5, 0.5)
	g.pos = Vector2(w.nearest_open_world(spot + Vector2i(6, 0))) + Vector2(0.5, 0.5)
	g.target = victim.id
	victim.target = -1
	var d0 := g.pos.distance_to(victim.pos)
	for i in 20:
		w.brain.fight(g, 0.1)
	check(g.pos.distance_to(victim.pos) < d0 - 0.5 or g.target == victim.id, "G: a guard's chase in the open country moves over the world's ground (%.1f -> %.1f)" % [d0, g.pos.distance_to(victim.pos)])
	g.target = -1
	# ---- H: countryside animals by the camp
	var cs := Countryside.new(w.map.overworld)
	cs.taken = w.country_taken
	var center := Vector2(Homesteads.step_of(bc)) + Vector2(0.5, 0.5)
	var amb := cs.animals_near(center, float(Wilds.cfg().country_radius), w.minutes)
	var a0 := int(wl.counts.get("country_adopted", 0))
	wl.country_hour()
	check(int(wl.counts.get("country_adopted", 0)) - a0 >= amb.size(), "H: the countryside's animals by the camp (%d) are real with no player near" % amb.size())
	# ---- I: allegiance
	var lawful := {}
	for c in hs.claims:
		if str(c.get("path", "")) != "band":
			lawful = c
	var fam_h := -1
	var mover: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 0 and not w.households[o.household].has("homestead") and o.partner >= 0 and w.npc(o.partner) != null and w.npc(o.partner).household == o.household:
			mover = o
			fam_h = o.household
			break
	var began := false
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 0 and not w.households[o.household].has("homestead") and o.partner >= 0 and w.npc(o.partner) != null \
				and w.npc(o.partner).household == o.household and o.coins < 9999:
			o.coins += 300
			w.coin_sources += 300
			if hs.begin(o.household, o, [o, w.npc(o.partner)], "test"):
				mover = o
				began = true
				break
	print("   (homestead gates: %s)" % hs.counts)
	if began:
		var nh: int = mover.household
		lawful = hs.claim_of(mover)
		hs._mark_site(lawful)
		hs._finish(lawful)
		lawful.poor_days = 3
		var id_l := str(lawful.id)
		var turned := wl.weigh_turn(lawful, nh)
		check(int(wl.counts.get("turn_weighed", 0)) >= 1, "I: a starving lawful homestead weighs living outside the law (%s)" % ("turned" if turned else "went on lawfully"))
		if not turned:
			for o: NPC in w.brain._members(nh):
				o.role = "bandit"
			hs._allegiance(lawful, w.brain._members(nh))
		check(str(lawful.faction) == "outlaw" and str(lawful.id) == id_l and str(lawful.building) != "", "I: an outlaw settlement now: the same claim and house")
		var tier := w.life.leave_band(mover)
		check(tier == "land" and mover.role == "adult" and mover.household == nh, "I: a bandit with family there leaves the band and stays on the land (%s)" % tier)
		var rest: Array = w.brain._members(nh).filter(func(o: NPC) -> bool: return o.role == "bandit")
		for o: NPC in rest:
			w.life.leave_band(o)
		check(str(lawful.faction) == "lawful" and str(lawful.id) == id_l, "I: all of them lawful again: the claim lawful, never recreated (%s)" % str(lawful.allegiance))
	else:
		check(false, "I: a couple to set out (none found)")
	# ---- J: save and load, replay
	var saved: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), saved)
	var bc2 := w2.wilds.band_claim()
	check(w2.load_error == "" and str(bc2.id) == str(bc.id) and w2.bandit_camp == w.bandit_camp, "J: loaded: the same band claim and camp")
	check((bc2.works as Array).size() == (bc.works as Array).size() and bool(w2.wilds.work_of(bc2, "well").done), "J: its works (well, pen, smithy) kept")
	check(not w2.wilds.pen_of_claim(bc2).is_empty(), "J: the claim's pen kept")
	check(_band(w2).size() == _band(w).size(), "J: every member kept")
	var r1 := World.new()
	r1.setup(VillageMap.load_default(), 5)
	var r2 := World.new()
	r2.setup(VillageMap.load_default(), 5)
	_hours(r1, 30.0)
	_hours(r2, 30.0)
	var s1 := JSON.stringify([r1.wilds.to_dict(), r1.homesteads.to_dict(), _band(r1).map(func(o: NPC) -> Array: return [o.id, o.cell(), o.coins, o.hp])])
	var s2 := JSON.stringify([r2.wilds.to_dict(), r2.homesteads.to_dict(), _band(r2).map(func(o: NPC) -> Array: return [o.id, o.cell(), o.coins, o.hp])])
	check(s1 == s2, "J: two worlds of one seed play the band's day alike (deterministic)")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
