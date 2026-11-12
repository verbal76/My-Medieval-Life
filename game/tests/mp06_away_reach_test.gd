extends SceneTree
## MML-MP-06 security: a modified guest client sends requests straight to the host's gateway (NetActions.apply, the host's own
## request path), bypassing its interface. (1) While the guest is away (PlayerState.away, MP-D1: out of active play) only what
## touches its own character is applied (NetActions.AWAY_VERBS); acting on the shared world is refused and nothing changes. (2) The
## verbs whose arguments name no place, which the host's interface offers only beside a counter, a courier booth, the villager a debt
## or an ask is with, the clergy, the tavern keeper, a quest's giver or at home, are refused out of reach (NetActions.place_refusal);
## a courier booking or booth for anyone but the guest is refused. Beside the place the same requests work. (3) A guest still joining
## (welcomed, out of play until it moves) whose request arrives first is put into play by it and acts (NetSession.apply_requests,
## the rejoin case MP-D1 kept); a request of a guest no longer connected is refused.
##   godot --headless --path game --script res://tests/mp06_away_reach_test.gd
var checks := 0
var failures := 0
const AWAY := "You are not in the world now."
const FAR := "That is too far away."


class FakeMain:
	var world: World
	func save_game(_x := false) -> void:
		pass


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		failures += 1


func verb(w: World, g: PlayerState, path: String, raw: Array) -> Dictionary:
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
	w.setup(VillageMap.load_default(), 8806)
	var g := PlayerState.new()
	g.name = "Gwen"
	g.family = "Forge"
	g.sex = "female"
	g.born = w.player.born
	Identity.register_player(w, g)
	w.give_start_kit(g)
	g.net_key = "a".repeat(32)
	w.add_guest(g)
	g.pos = w.player.pos
	g.coins = 200
	g.inv.add("bread", 4)
	var gref: String = w.player_ref(g)
	var far_pos: Vector2 = w.player.pos + Vector2(80, 0)
	var clergy: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.job in Chapel.JOBS:
			clergy = n
			break
	check(clergy != null, "setup: the village has its clergy")

	# 1. Away: acting on the shared world is refused, the world unchanged.
	g.away = true
	g.pos = clergy.pos
	var c0 := coins(w)
	var bread0 := g.inv.count("bread")
	var loot0 := w.loot.size()
	var r := verb(w, g, "player_drop", ["bread", 1])
	check(not r.ok and r.text == AWAY and g.inv.count("bread") == bread0 and w.loot.size() == loot0, "away: dropping goods onto the map is refused (%s)" % r.text)
	r = verb(w, g, "chapel.player_offer_coins", [5])
	check(not r.ok and r.text == AWAY and coins(w) == c0 and int(g.coins) == 200, "away: an offering to the chapel beside the clergy is refused, coins unchanged")
	var victim_inv := JSON.stringify(clergy.inv.to_dict()) if clergy.inv.has_method("to_dict") else str(clergy.inv.ids())
	r = verb(w, g, "pickpocket", [{"$npc": clergy.id}])
	check(not r.ok and r.text == AWAY and (JSON.stringify(clergy.inv.to_dict()) if clergy.inv.has_method("to_dict") else str(clergy.inv.ids())) == victim_inv
		and g.crimes.is_empty(), "away: picking a pocket is refused, nothing taken, no crime")
	r = verb(w, g, "player_buy_many", [{"$npc": clergy.id}, "bread", 1])
	check(not r.ok and r.text == AWAY and coins(w) == c0, "away: buying from a villager is refused")
	var plant := {}
	for pl in w.plants:
		if str(pl.state) == "ripe":
			plant = pl
			break
	if not plant.is_empty():
		g.pos = Vector2(int(plant.x) + 0.5, int(plant.y) + 1.5)
		r = NetActions.apply(w, g, "pick_plant", {"x": int(plant.x), "y": int(plant.y)})
		check(not r.ok and r.text == AWAY and str(plant.state) == "ripe", "away: picking a wild plant (A2 kind) is refused, the plant still ripe")
	g.pos = clergy.pos
	r = NetActions.apply(w, g, "eat", {"id": "bread"})
	check(r.ok and g.inv.count("bread") == bread0 - 1, "away: eating its own food (kind eat) is still applied")
	r = verb(w, g, "player_eat", ["bread"])
	check(r.ok and g.inv.count("bread") == bread0 - 2, "away: eating its own food (verb) is still applied")
	r = verb(w, g, "asset_share_revoke", [w.player.pid])
	check(r.ok, "away: withdrawing an asset-sharing agreement is still applied (per verb, not the whole gateway)")
	check(coins(w) == c0, "away: coins conserved across every refused request (%d -> %d)" % [c0, coins(w)])

	# 2. In play, in reach: the same requests work (controls).
	g.away = false
	r = verb(w, g, "player_drop", ["bread", 1])
	check(r.ok and g.inv.count("bread") == bread0 - 3 and w.loot.size() >= loot0, "in play: dropping goods works")
	var ch0 := coins(w)
	r = verb(w, g, "chapel.player_offer_coins", [5])
	check(r.ok and int(g.coins) == 195 and coins(w) == ch0, "in play beside the clergy: the offering is made (%s), coins conserved" % r.text)

	# 3. Out of reach: the verbs whose arguments name no place.
	g.pos = far_pos
	var c1 := coins(w)
	r = verb(w, g, "chapel.player_offer_coins", [5])
	check(not r.ok and r.text == FAR and int(g.coins) == 195 and coins(w) == c1, "far from the clergy: a chapel offering is refused")
	r = verb(w, g, "chapel.player_ask", [])
	check(not r.ok and r.text == FAR, "far from the clergy: asking the church for food is refused")
	r = verb(w, g, "feast.player_feast", ["seasonal", 4])
	check(not r.ok and r.text == FAR and coins(w) == c1, "far from the tavern keeper: paying for a feast is refused")
	var counter := ""
	for id in w.counters.all():
		counter = str(id)
		break
	if counter != "":
		var serving0 := w.counters.serving.duplicate()
		r = verb(w, g, "counters.summon", [counter])
		check(not r.ok and r.text == FAR and w.counters.serving == serving0, "far from the counter: ringing for its keeper is refused, nobody sent")
		g.pos = Vector2(w.station_use(counter)) + Vector2(0.5, 0.5)
		r = verb(w, g, "counters.summon", [counter])
		check(r.ok and r.text != FAR, "at the counter: ringing works (%s)" % r.text)
		g.pos = far_pos
	# a villager's ask of the guest, answered only beside them
	var asker: NPC = w.npcs.filter(func(n): return n.alive and n.role == "adult" and n != clergy)[0]
	w.credit.requests.append({"id": 9901, "npc": asker.id, "to": gref, "item": "bread", "qty": 1, "mode": "credit", "give": "", "value": 3, "day": w.day()})
	r = verb(w, g, "credit.answer_request", [9901, false])
	check(not r.ok and r.text == FAR and w.credit.requests.any(func(x): return int(x.id) == 9901), "far from the villager: answering their ask is refused, the ask kept")
	g.pos = asker.pos
	r = verb(w, g, "credit.answer_request", [9901, false])
	check(r.ok and not w.credit.requests.any(func(x): return int(x.id) == 9901), "beside the villager: the ask is answered")
	# a debt the guest owes a villager, repaid only beside them
	var did := int(w.credit.next_id)
	w.credit.next_id += 1
	w.credit.debts.append({"id": did, "creditor": World.npc_ref(asker.id), "debtor": gref, "item": "bread", "qty": 1, "value": 4,
		"made": w.day(), "due": w.day() + 5, "state": Credit.OPEN, "ended": -1})
	g.pos = far_pos
	var lender0 := int(asker.coins)
	var c2 := coins(w)
	r = verb(w, g, "credit.repay", [did, true])
	check(not r.ok and r.text == FAR and int(asker.coins) == lender0 and int(g.coins) == 195, "far from the lender: repaying is refused, purses unchanged")
	g.pos = asker.pos
	r = verb(w, g, "credit.repay", [did, true])
	check(r.ok and int(asker.coins) == lender0 + 4 and int(g.coins) == 191 and coins(w) == c2, "beside the lender: the debt is repaid, coins conserved")
	# a quest handed back only to its giver
	g.quests.append({"id": "mp06_q", "giver": asker.id, "item": "bread", "qty": 1})
	g.pos = far_pos
	r = verb(w, g, "quests.complete", [{"$r": "quest", "k": "mp06_q"}])
	check(not r.ok and r.text == FAR, "far from the giver: handing a quest in is refused")
	g.quests.clear()
	# the home chest, only at home
	g.pos = far_pos
	r = verb(w, g, "player_home_move", ["bread", false, 1])
	check(not r.ok and g.chest.count("bread") == 0, "without a home: moving goods into the home chest is refused (%s)" % r.text)
	var house := ""
	for id in w.buildings:
		if str(w.buildings[id].get("type", "")) == "house":
			house = str(id)
			break
	g.home = house
	var bread1 := g.inv.count("bread")
	r = verb(w, g, "player_home_move", ["bread", false, 1])
	check(not r.ok and r.text == FAR and g.chest.count("bread") == 0 and g.inv.count("bread") == bread1, "far from home: moving goods into the home chest is refused")
	g.pos = Vector2(w.building_door(house)) + Vector2(0.5, 0.5)
	r = verb(w, g, "player_home_move", ["bread", false, 1])
	check(r.ok and g.chest.count("bread") == 1 and g.inv.count("bread") == bread1 - 1, "at home: the goods go into the chest")
	# couriers: only for the guest itself
	var booth: Dictionary = w.couriers.booth_of(SettlementFacts.VILLAGE)
	g.pos = Vector2(float(booth.x) + 0.5, float(booth.y) + 0.5)
	var c3 := coins(w)
	r = verb(w, g, "couriers.book_route", [{"sender": World.npc_ref(asker.id), "items": {"bread": 1}, "kind": "route", "booth": str(booth.id)}])
	check(not r.ok and r.text == "That is not yours." and coins(w) == c3, "a courier booking sending a villager's goods is refused")
	r = verb(w, g, "couriers.open_shop_booth", [World.npc_ref(asker.id)])
	check(not r.ok and r.text == "That is not yours.", "opening a courier booth for a villager is refused")
	g.pos = far_pos
	r = verb(w, g, "couriers.book_route", [{"sender": gref, "items": {"bread": 1}, "kind": "route", "booth": str(booth.id)}])
	check(not r.ok and r.text == FAR, "far from any courier booth: booking is refused")

	# 4. The rejoin window (MP-D1): a guest still joining is put into play by its first request; a gone guest's request refused.
	var ns := NetSession.new()
	var fm := FakeMain.new()
	fm.world = w
	ns.main = fm
	g.pos = clergy.pos
	g.away = true                                     # welcomed, building the world (c_hello)
	ns.by_peer[7] = g.pid
	ns.joining[7] = true
	var bread2 := g.inv.count("bread")
	ns.queue.append({"pid": g.pid, "peer": 7, "rid": 1, "kind": "verb", "args": {"path": "player_drop", "a": ["bread", 1]}, "t": 0.0, "seq": 1})
	ns.apply_requests()
	check(not g.away and not ns.joining.has(7) and g.inv.count("bread") == bread2 - 1, "a rejoining guest's first request, ahead of its first move, puts it in play and is applied")
	ns.by_peer.erase(7)
	g.away = true                                     # left (NetSession._drop_peer)
	ns.queue.append({"pid": g.pid, "peer": 7, "rid": 2, "kind": "verb", "args": {"path": "player_drop", "a": ["bread", 1]}, "t": 0.0, "seq": 2})
	ns.apply_requests()
	check(g.away and g.inv.count("bread") == bread2 - 1, "a request applied for a guest no longer connected (away) is refused")
	ns.free()

	print("mp06_away_reach_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
