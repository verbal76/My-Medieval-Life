extends SceneTree
## DVW-B3-FEAST (owner, 2026-10-23): wedding feasts and seasonal feasts at the tavern: real food and ale bought from the keeper's
## stock and eaten, coins paid to the seller and conserved, a household that cannot pay holds none, the player's feast, saves and
## determinism. Run:
##   godot --headless --path game --script res://tests/feast_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func new_world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


func _init() -> void:
	test_purchase()
	test_affordability()
	test_triggers()
	test_player()
	test_save()
	test_determinism()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## A household (index >= 3) with at least two living members who can come, its host the richest adult.
func household(w: World, skip := -1) -> int:
	for h in range(3, w.households.size()):
		if h != skip and w.feast._members_of(h).size() >= 2 and w.feast._richest(w.feast._members_of(h)) != null:
			return h
	return -1


func stock_keeper(w: World) -> NPC:
	var k: NPC = w.tavern_keeper()
	k.inv.items.clear()
	for id in ["pottage", "roast_meat", "bread", "cheese", "ale"]:
		k.inv.add(id, 40)
	return k


func evening(w: World, hour := 20.0) -> void:
	w.minutes = float(w.day() * 1440) + hour * 60.0


func gather(w: World, ids: Array) -> void:
	for id in ids:
		var n: NPC = w.npc(int(id))
		n.pos = Vector2(w.feast.venue())
		n.anim = "idle"
		n.hunger = 20.0


func food_stat(w: World) -> int:
	var n := 0
	for id in ["pottage", "roast_meat", "bread", "cheese", "ale"]:
		n += int(w.stats.get("eaten_" + id, 0))
	return n


func test_purchase() -> void:
	var w := new_world()
	var keeper := stock_keeper(w)
	var hi := household(w)
	var ids: Array = w.feast._members_of(hi)
	var host: NPC = w.feast._richest(ids)
	host.coins = 400
	var coins0 := w.total_coins()
	var keeper_coins := keeper.coins
	var keeper_items := keeper.inv.total()
	var host_items := host.inv.total()
	var eaten0 := food_stat(w)
	gather(w, ids)
	evening(w)
	w.feast.planned_day = w.day()
	w.feast.plans = [{"kind": "wedding", "host": host.id, "invited": ids, "wedding": -1}]
	w.feast.resolve()
	var paid := keeper.coins - keeper_coins
	check(paid > 0 and host.coins == 400 - paid, "the host paid the keeper (%d coins)" % paid)
	check(w.total_coins() == coins0, "coins are conserved by a feast")
	var gone := keeper_items - keeper.inv.total()
	check(gone > 0 and gone == food_stat(w) - eaten0, "the plates and ale came out of the keeper's stock and were eaten (%d items)" % gone)
	check(host.inv.total() == host_items, "nothing is left in the host's pack")
	var fed := 0
	for id in ids:
		if w.npc(int(id)).hunger > 20.0:
			fed += 1
	check(fed == ids.size(), "every guest at the table ate (%d)" % fed)
	check(keeper.inv.count("roast_meat") < 40 and keeper.inv.count("ale") < 40, "the wedding menu is roast meat and ale")
	check(int(w.stats.get("feast_wedding", 0)) == 1 and int(w.stats.get("feast_coins", 0)) == paid, "the feast is counted")
	check(w.feast.plans.is_empty(), "the day's plans are cleared")


func test_affordability() -> void:
	var w := new_world()
	var keeper := stock_keeper(w)
	var hi := household(w)
	var ids: Array = w.feast._members_of(hi)
	var host: NPC = w.feast._richest(ids)
	for id in ids:
		w.npc(int(id)).coins = 0
	var coins0 := w.total_coins()
	var k0 := keeper.inv.total()
	gather(w, ids)
	evening(w)
	w.feast.planned_day = w.day()
	w.feast.plans = [{"kind": "seasonal", "host": host.id, "invited": ids, "wedding": -1}]
	w.feast.resolve()
	check(keeper.inv.total() == k0 and w.total_coins() == coins0 and int(w.stats.get("feast_called_off_cost", 0)) == 1, "a household without the coins holds no feast and nothing moves")
	# a smaller purse: a smaller table
	var big: Array = ids.duplicate()
	for i in 5:
		big.append(w.npcs[i + 40].id)
	host.coins = w.reserve_of(host) + 30
	var share := w.feast._budget(host, "seasonal")
	gather(w, big)
	w.feast.plans = [{"kind": "seasonal", "host": host.id, "invited": big, "wedding": -1}]
	var before := host.coins
	w.feast.resolve()
	var spent := before - host.coins
	check(spent <= share and spent > 0, "a modest purse buys a smaller feast (%d of a budget of %d)" % [spent, share])
	check(int(w.stats.get("feast_guests", 0)) < big.size(), "fewer guests than were asked were fed (%d of %d)" % [int(w.stats.get("feast_guests", 0)), big.size()])
	# the host absent: called off
	var w2 := new_world()
	stock_keeper(w2)
	var ids2: Array = w2.feast._members_of(household(w2))
	var host2: NPC = w2.feast._richest(ids2)
	host2.coins = 300
	gather(w2, ids2)
	host2.pos = Vector2(1, 1)
	evening(w2)
	w2.feast.planned_day = w2.day()
	w2.feast.plans = [{"kind": "seasonal", "host": host2.id, "invited": ids2, "wedding": -1}]
	w2.feast.resolve()
	check(host2.coins == 300 and int(w2.stats.get("feast_called_off", 0)) == 1, "a host who is not there calls the feast off")
	# the keeper's stock is only partly sold
	var w3 := new_world()
	var k3 := stock_keeper(w3)
	k3.inv.items.clear()
	k3.inv.add("pottage", 3)
	k3.inv.add("ale", 3)
	var ids3: Array = w3.feast._members_of(household(w3))
	var host3: NPC = w3.feast._richest(ids3)
	host3.coins = 300
	gather(w3, ids3)
	evening(w3)
	w3.feast.planned_day = w3.day()
	w3.feast.plans = [{"kind": "seasonal", "host": host3.id, "invited": ids3, "wedding": -1}]
	w3.feast.resolve()
	check(k3.inv.count("pottage") >= 2 and int(w3.stats.get("feast_guests", 0)) <= 1 or int(w3.stats.get("feast_called_off_cost", 0)) == 1, "the keeper keeps most of a thin stock back (a feast needs at least two at the table)")


func test_triggers() -> void:
	var w := new_world()
	stock_keeper(w)
	var c: Dictionary = GameData.b("feast")
	var old := float(c.seasonal_chance)
	c["seasonal_chance"] = 1.0
	for h in range(3, w.households.size()):                  # everyone can pay and is fed
		for id in w.feast._members_of(h):
			w.npc(int(id)).coins = 300
			(w.households[h].pantry as Inventory).add("wheat", 40)
	w.minutes = 4.0 * 1440 + 17.0 * 60.0                     # day 4: the first day of autumn
	check(w.season() == "Autumn" and w.feast._is_season_start(4), "day 4 is the first day of autumn")
	w.feast.plan_day()
	var seasonal := w.feast.plans.filter(func(p): return p.kind == "seasonal")
	check(seasonal.size() > 0 and seasonal.size() <= int(c.max_feasts_a_day), "autumn's first day brings seasonal feasts (%d, at most %d a day)" % [seasonal.size(), int(c.max_feasts_a_day)])
	var w2 := new_world()
	stock_keeper(w2)
	w2.minutes = 2.0 * 1440 + 17.0 * 60.0                    # day 2: summer, not a feast season
	w2.feast.plan_day()
	check(w2.feast.plans.is_empty(), "no seasonal feast on a day that is not a feast season's first")
	c["seasonal_chance"] = old
	# a wedding: the partnership owes one, held on a later evening
	var w3 := new_world()
	stock_keeper(w3)
	var hi := household(w3)
	var ids: Array = w3.feast._members_of(hi)
	var a: NPC = w3.npc(int(ids[0]))
	var b: NPC = w3.npc(int(ids[1]))
	a.partner = b.id
	b.partner = a.id
	for id in ids:
		w3.npc(int(id)).coins = 300
	(w3.households[hi].pantry as Inventory).add("wheat", 40)
	w3.minutes = 2.0 * 1440 + 9.0 * 60.0
	w3.feast.on_partnered(a.id, b.id)
	check(w3.feast.weddings.size() == 1 and int(w3.stats.get("feast_weddings_due", 0)) == 1, "becoming partners owes a wedding feast")
	w3.minutes = 2.0 * 1440 + 17.0 * 60.0
	w3.feast.plan_day()
	check(w3.feast.plans.is_empty(), "not on the day itself")
	w3.minutes = 3.0 * 1440 + 17.0 * 60.0
	w3.feast.plan_day()
	check(w3.feast.plans.size() == 1 and w3.feast.plans[0].kind == "wedding" and (w3.feast.plans[0].invited as Array).has(a.id), "the next evening the household holds it")
	# a death before the feast: none is held
	var w4 := new_world()
	stock_keeper(w4)
	var ids4: Array = w4.feast._members_of(household(w4))
	w4.minutes = 2.0 * 1440 + 9.0 * 60.0
	w4.feast.on_partnered(int(ids4[0]), int(ids4[1]))
	w4.npc(int(ids4[1])).alive = false
	w4.minutes = 3.0 * 1440 + 17.0 * 60.0
	w4.feast.plan_day()
	check(w4.feast.plans.is_empty() and bool(w4.feast.weddings[0].done), "a wedding feast is not held when one of the couple has died")
	# the proposal path: a courting pair who propose owe one
	var w5 := new_world()
	var pair := _courting_pair(w5)
	if pair.size() == 2:
		var r: String = w5.relations.propose(pair[0].id, pair[1])
		check(r == "" and w5.feast.weddings.size() == 1, "Relations.propose, accepted, owes the wedding feast (%s)" % r)
	else:
		check(false, "found a pair to court")


func _courting_pair(w: World) -> Array:
	var adults: Array = w.npcs.filter(func(n): return n.alive and n.role == "adult" and n.partner == -1 and n.household >= 3)
	for i in adults.size():
		for j in range(i + 1, adults.size()):
			var a: NPC = adults[i]
			var b: NPC = adults[j]
			if w.relations.can_court(a.id, b.id):
				var t: Dictionary = w.relations.tie(a.id, b.id)
				t.stage = "courting"
				t.since = -20
				t.attraction = 95.0
				t.regard = 95.0
				t.days_known = 99
				w.relations.unwilling_override(b.id) if w.relations.has_method("unwilling_override") else null
				if w.relations.refusal(a.id, b) == "" and w.relations.willing(b):
					w.minutes = 30.0 * 1440
					return [a, b]
	return []


func test_player() -> void:
	var w := new_world()
	var keeper := stock_keeper(w)
	w.minutes = 1.0 * 1440 + 19.0 * 60.0
	var near: Array = []
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.job != "guard" and n.job != "tavernkeeper" and n.household >= 3 and near.size() < 6:
			near.append(n.id)
	gather(w, near)
	w.player.coins = 500
	var coins0 := w.total_coins()
	var k0 := keeper.coins
	var opts: Array = w.feast.player_choices()
	check(opts.size() >= 1 and opts[0].kind == "seasonal", "the keeper offers a feast for the room in the evening")
	var r: Dictionary = w.feast.player_feast("seasonal", 4)
	check(r.ok and w.player.coins < 500 and keeper.coins - k0 == 500 - w.player.coins, "the player paid the keeper: %s" % str(r.get("text")))
	check(w.total_coins() == coins0, "the player's feast conserves coins")
	var fed := 0
	for id in near:
		if w.npc(int(id)).hunger > 20.0:
			fed += 1
	check(fed >= 2 and fed <= 4, "the guests nearest the counter ate (%d)" % fed)
	w.player.coins = 1
	check(not w.feast.player_feast("seasonal", 4).ok, "a player without the coins cannot hold one")
	w.minutes = 1.0 * 1440 + 10.0 * 60.0
	check(not w.feast.player_feast("seasonal", 4).ok and w.feast.player_choices().is_empty(), "nor in the morning")
	# the player's wedding
	var w2 := new_world()
	var k2 := stock_keeper(w2)
	var hi := household(w2)
	var ids: Array = w2.feast._members_of(hi)
	var partner: NPC = w2.npc(int(ids[0]))
	w2.player.partner = partner.id
	partner.partner = -2
	w2.minutes = 1.0 * 1440 + 9.0 * 60.0
	w2.feast.on_partnered(-2, partner.id)
	w2.minutes = 2.0 * 1440 + 17.0 * 60.0
	w2.feast.plan_day()
	check(w2.feast.plans.size() == 1 and int(w2.feast.plans[0].host) == -2, "the player's wedding is planned, paid for by the player")
	w2.player.coins = 500
	w2.minutes = 2.0 * 1440 + 19.0 * 60.0
	check(not w2.feast.player_feast("wedding", 0).ok, "the family must have come first")
	gather(w2, ids)
	var c2 := w2.total_coins()
	var wr: Dictionary = w2.feast.player_feast("wedding", 0)
	check(wr.ok and w2.total_coins() == c2 and w2.player.coins < 500 and bool(w2.feast.weddings[0].done), "the player pays for the wedding feast: %s" % str(wr.get("text")))
	var c3 := w2.total_coins()
	w2.minutes = 2.0 * 1440 + 20.0 * 60.0
	w2.feast.resolve()
	check(w2.total_coins() == c3 and int(w2.stats.get("feast_player_unhosted", 0)) == 0, "a paid wedding is not bought twice at the day's end")


func test_save() -> void:
	var w := new_world()
	w.feast.weddings = [{"a": 5, "b": 9, "day": 2, "done": false}, {"a": -2, "b": 7, "day": 1, "done": true}]
	w.feast.plans = [{"kind": "wedding", "host": 5, "invited": [5, 9, 11], "wedding": 0}]
	w.feast.planned_day = 3
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	check(JSON.stringify(w2.feast.to_dict()) == JSON.stringify(w.feast.to_dict()), "weddings owed and the day's plans survive a save")
	check(int(w2.feast.plans[0].host) == 5 and (w2.feast.plans[0].invited as Array).has(11) and w2.feast.planned_day == 3, "with their ids as integers")
	d.erase("feast")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), d)
	check(w3.feast.weddings.is_empty() and w3.feast.plans.is_empty() and w3.feast.planned_day == -1, "a save from before feasts loads with none owed")


func run_world() -> Dictionary:
	var w := new_world()
	var hi := household(w)
	var ids: Array = w.feast._members_of(hi)
	w.feast.on_partnered(int(ids[0]), int(ids[1]))           # one wedding owed from the first day
	w.npc(int(ids[0])).partner = int(ids[1])
	w.npc(int(ids[1])).partner = int(ids[0])
	var c: Dictionary = GameData.b("feast")
	var old := float(c.seasonal_chance)
	c["seasonal_chance"] = 1.0
	var coins0 := w.total_coins()
	for d in 8:
		for m in 1440:
			w.update(0.5)
			w.player.hunger = 100.0
	c["seasonal_chance"] = old
	var inflow := 0
	for k in ["caravan_coins_in", "newcomer_coins_in", "scenario_coins_in", "outlaw_coins_in"]:
		inflow += int(w.stats.get(k, 0))
	inflow -= int(w.stats.get("caravan_coins_out", 0))
	return {"stats": {"wedding": int(w.stats.get("feast_wedding", 0)), "seasonal": int(w.stats.get("feast_seasonal", 0)), "guests": int(w.stats.get("feast_guests", 0)),
		"coins": int(w.stats.get("feast_coins", 0)), "off": int(w.stats.get("feast_called_off", 0)), "off_cost": int(w.stats.get("feast_called_off_cost", 0)),
		"unaffordable": int(w.stats.get("feast_unaffordable", 0))}, "feast": JSON.stringify(w.feast.to_dict()), "total": w.total_coins(), "expected": coins0 + inflow, "day": w.day()}


func test_determinism() -> void:
	var a := run_world()
	var b := run_world()
	print("8 days: ", a.stats)
	check(a.total == a.expected, "coins stay accounted for over 8 days with feasts (%d = %d)" % [a.total, a.expected])
	check(int(a.stats.wedding) + int(a.stats.seasonal) > 0 and int(a.stats.coins) > 0, "feasts were held and paid for (%d weddings, %d seasonal, %d coins)" % [int(a.stats.wedding), int(a.stats.seasonal), int(a.stats.coins)])
	check(JSON.stringify(a) == JSON.stringify(b), "two runs of the same village agree exactly")
