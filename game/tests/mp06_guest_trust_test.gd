extends SceneTree
## MP-GUEST-TRUST (found during MML-MP-06: the host must never trust a guest's figures). A modified guest client sends requests
## straight to the host's gateway (NetActions.apply, the host's own request path), bypassing its interface:
##   (1) experience it names for itself (player_xp) is refused; experience comes only inside the verbs that earn it, on the host
##       (player_feed_pen: the feeding and its Husbandry xp);
##   (2) a blow's damage it names (player_hit_npc, player_hit_animal) is refused; the sword blow is worked out on the host from the
##       guest's own weapon and skills (player_melee_npc, player_melee_animal);
##   (3) a craft is finished (player_craft) only for the recipe the guest began (player_craft_begin) at a station of its kind,
##       still in reach, after its time on the host's clock; begun once, finished once; the same for a repair;
##   (4) its own work record (note_player_work) is refused; the host credits a finished craft's verified time instead;
##   (5) what lies on another level of the world (a villager, loot below the surface at the same x, y) is out of reach;
##   (6) a genuine guest's courier window names the guest as the sender, so its booking is accepted.
## Coins and goods are conserved across every refusal.
##   godot --headless --path game --script res://tests/mp06_guest_trust_test.gd
var checks := 0
var failures := 0
const NOT_YOURS := "That is not yours to decide."
const FAR := "That is too far away."


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		failures += 1


## A request as a modified client sends it: the verb's path and its arguments encoded as the guest's own machine names them.
func verb(w: World, g: PlayerState, path: String, args: Array) -> Dictionary:
	var raw = w.as_actor(g, func(): return NetActions.enc(w, args))
	return NetActions.apply(w, g, "verb", {"path": path, "a": raw})


func coins(w: World) -> int:
	var t := int(w.player.coins) + int(w.treasury) + int(w.chapel.coins)
	for q: PlayerState in w.player_list():
		if not w.is_host(q):
			t += int(q.coins)
	for n: NPC in w.npcs:
		t += int(n.coins)
	for h in w.households:
		t += int(h.get("coins", 0))
	return t


func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 8807)
	var g := PlayerState.new()
	g.name = "Gwen"
	g.family = "Forge"
	g.sex = "female"
	g.born = w.player.born
	Identity.register_player(w, g)
	w.give_start_kit(g)
	g.net_key = "b".repeat(32)
	w.add_guest(g)
	g.pos = w.player.pos
	g.coins = 200
	var gref: String = w.player_ref(g)
	var gm := float(GameData.b("game_minutes_per_second"))

	# 1. Experience: named by the guest, refused; earned by a verified verb, given by the host.
	var xp0 := JSON.stringify(g.skills)
	var c0 := coins(w)
	var r := verb(w, g, "player_xp", ["combat", 99999])
	check(not r.ok and r.text == NOT_YOURS and JSON.stringify(g.skills) == xp0, "a guest's own experience figure (player_xp combat 99999) is refused, its skills unchanged")
	r = verb(w, g, "player_xp", ["mining", 500])
	check(not r.ok and JSON.stringify(g.skills) == xp0, "and so for any skill")
	var pen := {}
	for id in w.fauna.pens:
		pen = w.fauna.pens[id]
		break
	check(not pen.is_empty(), "setup: the village has a pen")
	if not pen.is_empty():
		var at = NetActions._pos_of(pen)
		g.pos = at if at != null else Vector2(float(pen.get("x", g.pos.x)), float(pen.get("y", g.pos.y)))
		g.inv.add("wheat", 3)
		var hb0 := int(g.skills.get("husbandry", 0))
		var tr0 := int(pen.trough)
		r = verb(w, g, "player_feed_pen", [pen, 5])
		check(r.ok and g.inv.count("wheat") == 0 and int(pen.trough) == tr0 + 3, "feeding a pen (player_feed_pen) puts the guest's wheat in the trough (%s)" % r.text)
		check(int(g.skills.get("husbandry", 0)) == hb0 + Skills.action_xp("feed_pen") and int(w.player.skills.get("husbandry", 0)) == int(w.player.skills.get("husbandry", 0)),
			"and the host gives the feeding's Husbandry xp to the guest (+%d)" % Skills.action_xp("feed_pen"))
		r = verb(w, g, "player_feed_pen", [pen, 5])
		check(r.ok and int(g.skills.get("husbandry", 0)) == hb0 + Skills.action_xp("feed_pen"), "with no wheat to put in, no xp")
	check(coins(w) == c0, "coins conserved (experience requests)")

	# 2. The damage of a blow: named by the guest, refused; a sword blow worked out on the host.
	var beast: Animal = null
	for a: Animal in w.fauna.animals:
		if a.alive and a.wild():
			beast = a
			break
	check(beast != null, "setup: a wild animal")
	var villager: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.depth == 0:
			villager = n
			break
	g.pos = villager.pos + Vector2(0.5, 0)
	var hp0 := villager.hp
	r = verb(w, g, "player_hit_npc", [villager, 9999.0])
	check(not r.ok and r.text == NOT_YOURS and villager.hp == hp0 and villager.alive and g.crimes.is_empty(), "a blow of the guest's own damage (player_hit_npc 9999) on a villager is refused: unharmed, no crime")
	if beast != null:
		g.pos = beast.pos + Vector2(0.5, 0)
		var bhp := beast.hp
		r = verb(w, g, "player_hit_animal", [beast, 9999.0])
		check(not r.ok and r.text == NOT_YOURS and beast.hp == bhp and beast.alive, "a blow of the guest's own damage (player_hit_animal 9999) on an animal is refused: unharmed")
		var dmg := g.damage()
		r = verb(w, g, "player_melee_animal", [beast])
		var res: Dictionary = r.get("result", {}) if r.get("result", {}) is Dictionary else {}
		var dealt := bhp - beast.hp if beast.alive else bhp
		check(r.ok and (is_equal_approx(float(res.get("dmg", -1.0)), dmg) or is_equal_approx(float(res.get("dmg", -1.0)), dmg * 2.0)) and dealt > 0.0 and dealt <= dmg * 2.0 + 0.001,
			"the guest's sword blow on the animal (player_melee_animal) deals the host's figure from its own weapon and skills (%.1f, weapon %.1f)" % [float(res.get("dmg", -1.0)), dmg])
	g.pos = villager.pos + Vector2(0.5, 0)
	var vhp := villager.hp
	var vdmg := g.damage()
	r = verb(w, g, "player_melee_npc", [villager])
	var vres: Dictionary = r.get("result", {}) if r.get("result", {}) is Dictionary else {}
	check(r.ok and float(vres.get("dealt", 0.0)) > 0.0 and float(vres.get("dealt", 0.0)) <= vdmg * 2.0 + 0.001 and is_equal_approx(vhp - villager.hp, float(vres.get("dealt", 0.0))),
		"the guest's sword blow on a villager (player_melee_npc) deals the host's figure (%.1f of at most %.1f)" % [float(vres.get("dealt", 0.0)), vdmg * 2.0])

	# 3. Crafting: finished only for what was begun, at its station, in reach, after its time.
	var recipe := "tan_pelts"
	var rd: Dictionary = GameData.recipes[recipe]
	var bench := ""
	for id in w.stations_of(str(rd.station)):
		var at := Vector2(w.station_use(id)) + Vector2(0.5, 0.5)
		var why = w.as_actor(g, func():
			var keep := g.pos
			g.pos = at
			var no := w.station_refusal(id)
			g.pos = keep
			return no)
		if str(why) == "":
			bench = str(id)
			break
	check(bench != "", "setup: a workbench the guest may use")
	var other := ""
	for id in w.stations:
		if str(w.stations[id].type) != str(rd.station) and not Furniture.is_home_station(str(id)):
			other = str(id)
			break
	g.inv.add("rabbit_pelt", 6)
	var bench_at := Vector2(w.station_use(bench)) + Vector2(0.5, 0.5)
	g.pos = bench_at
	var pelts0 := g.inv.count("rabbit_pelt")
	var leather0 := g.inv.count("leather")
	var ex0 := w.experience.days(gref, CapabilityHook.recipe_industry(recipe))
	r = verb(w, g, "player_craft", [recipe])
	check(not r.ok and g.inv.count("rabbit_pelt") == pelts0 and g.inv.count("leather") == leather0, "a craft finished without being begun is refused, nothing made (%s)" % r.text)
	if other != "":
		r = verb(w, g, "player_craft_begin", [recipe, other])
		check(not r.ok and r.text == "That is not made here.", "a craft begun at a station of another kind (%s) is refused" % str(w.stations[other].type))
	r = verb(w, g, "player_craft_begin", [recipe, "no_such_station_" + bench])
	r = verb(w, g, "player_craft_begin", ["no_such_recipe", bench])
	check(not r.ok and r.text == "That cannot be made.", "a recipe the host does not know is refused")
	r = verb(w, g, "player_craft_begin", [recipe, bench])
	var res2: Dictionary = r.get("result", {}) if r.get("result", {}) is Dictionary else {}
	check(r.ok and bool(res2.get("ok", false)) and str(res2.get("station", "")) == bench, "the craft is begun at the workbench (%s)" % str(res2))
	var mins := float(res2.get("secs", 0.0)) * gm
	r = verb(w, g, "player_craft", [recipe])
	check(not r.ok and r.text == "That is not finished yet." and g.inv.count("leather") == leather0, "finished at once, before its time on the host's clock: refused, nothing made")
	w.minutes += mins * 0.5
	r = verb(w, g, "player_craft", [recipe])
	check(not r.ok and g.inv.count("leather") == leather0, "finished at half its time: refused")
	r = verb(w, g, "player_craft", ["make_" + recipe])
	check(not r.ok and r.text == "You have not begun that.", "finishing another recipe than the one begun is refused")
	w.minutes += mins
	r = verb(w, g, "player_craft", [recipe])
	check(r.ok and g.inv.count("leather") == leather0 + int(rd.out.leather) and g.inv.count("rabbit_pelt") == pelts0 - int(rd.in.rabbit_pelt),
		"after its time, at the workbench: the leather is made from the guest's pelts (%s)" % r.text)
	var ex1 := w.experience.days(gref, CapabilityHook.recipe_industry(recipe))
	check(ex1 > ex0, "and the host credits the craft's verified time to the guest's work record (%s %.4f -> %.4f days)" % [CapabilityHook.recipe_industry(recipe), ex0, ex1])
	w.minutes += mins * 2.0
	r = verb(w, g, "player_craft", [recipe])
	check(not r.ok and g.inv.count("leather") == leather0 + int(rd.out.leather), "a craft begun once is finished once: a second finish is refused")
	r = verb(w, g, "player_craft_begin", [recipe, bench])
	check(r.ok, "begun again")
	g.pos = bench_at + Vector2(6, 0)
	w.minutes += mins * 2.0
	r = verb(w, g, "player_craft", [recipe])
	check(not r.ok and r.text == "That is out of reach." and g.inv.count("leather") == leather0 + int(rd.out.leather), "walked away from the workbench: finishing is refused")
	# a home's food table (not a village station): begun and finished beside it, in the guest's own home
	var home := ""
	var table := ""
	var spot := {}
	for bid in w.buildings:
		for sp in w.interiors.get(bid, {}).get("spots", []):
			if sp.kind == "table" and str(w.buildings[bid].get("type", "")) == "house":
				home = str(bid)
				spot = sp
				table = Furniture.station_id(home, sp)
				break
		if table != "":
			break
	check(table != "", "setup: a house with a food table")
	if table != "":
		var old_home := g.home
		g.home = home
		g.inv.add("wheat", 6)
		var bread_id := "knead_flatbread"
		var out_id: String = GameData.recipes[bread_id].out.keys()[0]
		var made0 := g.inv.count(out_id)
		g.pos = Vector2(int(spot.at[0]), int(spot.at[1])) + Vector2(0.5, 1.5)
		r = verb(w, g, "player_craft_begin", ["tan_pelts", table])
		check(not r.ok and r.text == "That is not made here.", "a workbench recipe begun at a home's food table is refused")
		g.pos = Vector2(int(spot.at[0]), int(spot.at[1])) + Vector2(20.5, 0.5)
		r = verb(w, g, "player_craft_begin", [bread_id, table])
		check(not r.ok and r.text == "That is out of reach.", "begun at the guest's own food table from across the village: refused")
		g.pos = Vector2(int(spot.at[0]), int(spot.at[1])) + Vector2(0.5, 1.5)
		r = verb(w, g, "player_craft_begin", [bread_id, table])
		var hb: Dictionary = r.get("result", {}) if r.get("result", {}) is Dictionary else {}
		check(r.ok and bool(hb.get("ok", false)), "begun beside the guest's own food table (%s)" % str(hb))
		w.minutes += float(hb.get("secs", 0.0)) * gm + 1.0
		r = verb(w, g, "player_craft", [bread_id])
		check(r.ok and g.inv.count(out_id) == made0 + int(GameData.recipes[bread_id].out[out_id]), "and finished there after its time: the food is made (%s)" % r.text)
		g.home = old_home
	g.pos = bench_at
	r = verb(w, g, "player_repair", ["iron_sword"])
	check(not r.ok and r.text == "You have not begun that.", "a repair finished without being begun is refused")

	# 4. The work record: named by the guest, refused.
	var exm0 := w.experience.days(gref, "mining")
	r = verb(w, g, "note_player_work", ["mining", 100000.0])
	check(not r.ok and r.text == NOT_YOURS and w.experience.days(gref, "mining") == exm0, "a guest's own work figure (note_player_work mining 100000 s) is refused, its record unchanged")

	# 5. Levels: below the surface at the same x, y is out of reach.
	var deep: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n != villager:
			deep = n
			break
	g.pos = deep.pos + Vector2(0.5, 0)
	g.map_level = 0
	deep.depth = -1
	var dhp := deep.hp
	r = verb(w, g, "player_melee_npc", [deep])
	check(not r.ok and r.text == FAR and deep.hp == dhp, "a villager below the surface at the guest's x, y is out of reach of a guest above (no blow)")
	deep.depth = 0
	g.inv.add("bread", 2)
	w.loot.append({"pos": g.pos, "inv": Inventory.new(), "coins": 7, "from": "a test", "t": w.minutes, "level": -1})
	var pile: Dictionary = w.loot[w.loot.size() - 1]
	var gc0 := int(g.coins)
	r = verb(w, g, "player_loot", [pile])
	check(not r.ok and r.text == FAR and int(g.coins) == gc0 and w.loot.has(pile), "loot below the surface at the guest's x, y is out of reach of a guest above")
	g.map_level = -1
	r = verb(w, g, "player_loot", [pile])
	check(r.ok and int(g.coins) == gc0 + 7, "on its level, the same loot is taken (%s)" % r.text)
	g.map_level = 0

	# 6. Couriers: a genuine guest's window names the guest; its booking is accepted.
	var cs := w.couriers
	cs.daily()
	w.set_local_player(g)                      # the guest's own machine: the interface acts as the guest
	var cw := CourierWindow.new(null, cs)
	w.set_local_player(null)
	check(cw.sender == gref, "the courier window on a guest's machine names the guest as the sender (%s)" % cw.sender)
	var hw := CourierWindow.new(null, cs)
	check(hw.sender == "player", "on the host's machine it names the host, as before")
	var vb: Dictionary = cs.booth_of("village")
	var rt := {}
	for x in cs.routes:
		if str(x.from) == str(vb.id) and str(cs.booth(str(x.to)).settlement) == "wulstead":
			rt = x
	check(not rt.is_empty(), "setup: a route to Wulstead")
	w.note_settlement_trade(g, w.regions.by_id["wulstead"])
	g.inv.add("copper_ring", 2)
	g.pos = Vector2(float(vb.x) + 0.5, float(vb.y) + 1.5)
	cw.booth_id = str(vb.id)
	cw.choice.kind = 0
	var items: Array = w.as_actor(g, func(): return cs.inv_of(cw.sender).ids())
	cw.choice.item = maxi(0, items.find("copper_ring"))
	cw.choice.qty = 2
	var recs: Array = cs.known_recipients(cw.sender)
	var ri := -1
	for i in recs.size():
		if str(recs[i].ref) == "region:wulstead/trader":
			ri = i
	cw.choice.recipient = maxi(0, ri)
	var order: Dictionary = cw.order()
	var c6 := coins(w)
	var g6 := int(g.coins)
	r = verb(w, g, "couriers.book_route", [order])
	var job: Dictionary = r.get("result", {}) if r.get("result", {}) is Dictionary else {}
	check(r.ok and not job.has("error") and job.has("fee") and g.inv.count("copper_ring") == 0 and int(g.coins) == g6 - int(job.get("fee", 0)),
		"the guest's window booking (sender %s) is accepted by the host: the goods leave its pack, the fee its purse (%s)" % [str(order.sender), str(job.get("error", r.text))])
	check(coins(w) == c6, "coins conserved by the booking")
	order.sender = "player"
	r = verb(w, g, "couriers.book_route", [order])
	check(not r.ok and r.text == "That is not yours.", "a booking naming the host as sender is still refused")

	print("mp06_guest_trust_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
