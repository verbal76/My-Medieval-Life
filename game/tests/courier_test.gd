extends SceneTree
## PROSPECTIVE (Expansion 18, X18-Q12, X18-Q12-BOOTH, X18-Q12-POST; PROS-18): courier booths, regular routes, special
## deliveries, known recipients, fees, payment collection, deposits, refusals and interrupted journeys, on a real seeded
## village. Every check of goods and coins counts every holder: the World's (census and World.total_coins), the booths'
## stores, coins and held fees, and the off-map settlement's ledger. Smoke tests of the owner's 2026-10-21 rules; not
## wired into the live game.
##   godot --headless --path game --script res://tests/courier_test.gd

const Census := preload("res://tests/census.gd")

var checks := 0
var failures := 0
var w: World
var cs: CourierService
var east: SettlementLedger


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL: " + what)


func _init() -> void:
	GameData.ensure()
	w = World.new()
	w.setup(VillageMap.load_default(), 1)
	cs = CourierService.new(w)
	test_booths()
	test_recipients()
	test_fees()
	test_route_delivery()
	test_special_delivery()
	test_deposit_and_rejection()
	test_unavailable_and_interrupted()
	test_player_same_rules()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func ref(n: NPC) -> String:
	return "npc:%d" % n.id


func hirable() -> Array:
	return w.npcs.filter(func(n): return n.alive and w.construction.can_hire(n) == "")


## Villagers to send, carry and receive in the tests: living adults of no trading business (fixture pool).
func people() -> Array:
	return w.npcs.filter(func(n): return n.alive and n.role == "adult" and n.job in ["", "laborer", "manor_hand", "farmer", "woodcutter", "miner"] \
			and not cs.booths.any(func(b): return b.keeper == "npc:%d" % n.id))


func trader(role: String) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and w.brain.buy_role(n) == role:
			return n
	return null


func totals() -> Dictionary:
	var coins := w.total_coins() + cs.held_coins()
	var goods := Census.goods(w)
	for src in [cs.held_goods()] + cs.regions.values().map(func(l): return l.stock.items):
		for id in src:
			goods[id] = int(goods.get(id, 0)) + int(src[id])
	for id in cs.regions:
		coins += (cs.regions[id] as SettlementLedger).coins
	return {"coins": coins, "goods": goods}


func know(a: NPC, b: NPC) -> void:
	w.relations.tie(a.id, b.id).days_known = 2


func test_booths() -> void:
	var busy: NPC = trader("merchant_goods")
	check(cs.open_booth(ref(busy)) != "", "a villager with work of their own cannot be hired to keep the booth (Construction.can_hire)")
	var keeper: NPC = hirable()[0]   # the booth keeper: the job rule
	var free := ""
	for sid in w.stalls:
		if str(w.stalls[sid].get("tenant", "")) == "":
			free = sid
	var err := ""
	if free != "":
		err = cs.open_booth(ref(keeper), free)
	else:
		keeper.inv.add("plank", 3)                  # fixture: the keeper's own planks for the stall (STALL rules)
		err = cs.open_booth(ref(keeper))
	var b := cs.booth_of("village")
	check(err == "" and not b.is_empty() and str(b.keeper) == ref(keeper),
		"the village has a courier booth kept by a hirable villager (%s)" % ("a free market stall" if free != "" else "a stall they built by the STALL rules"))
	check(free != "" or not w.business.stalls.built(ref(keeper)).is_empty(), "the booth is a stall of the existing stall system")
	east = SettlementLedger.make({"id": "eastmarch", "name": "Eastmarch", "pos": [900, 0], "coins": 500,
		"stock": {"iron_ore": 50}, "needs": {"wheat": 5.0}, "transport": {"handcart": 1}})
	cs.open_region_booth(east)
	var village := SettlementLedger.make({"id": "village"})
	cs.links = TradeRoutes.table([village, east], [["village", "eastmarch", 900, {"road": 1.0}]])
	var r := cs.add_route(str(b.id), str(cs.booth_of("eastmarch").id), -1.0, 1)
	check(not r.is_empty() and float(r.days) > 0.0 and int(r.fee_per_load) > 0, "a regular route runs from the village booth to Eastmarch's (%.1f days, %d coins a load)" % [float(r.days), int(r.fee_per_load)])


func test_recipients() -> void:
	var a: NPC = people()[1]
	var stranger: NPC = null
	var friend: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n != a and n.role == "adult" and int(w.relations.peek(a.id, n.id).days_known) == 0 and not w.relations.traded_with(a.id, n.id):
			if stranger == null:
				stranger = n
			elif friend == null:
				friend = n
	know(a, friend)
	var known := cs.known_recipients(ref(a))
	check(known.any(func(e): return e.ref == ref(friend) and e.kind == "person"), "someone the sender has come to know is a recipient")
	check(not known.any(func(e): return e.ref == ref(stranger)), "a stranger is not offered")
	var m: NPC = trader("merchant_food")
	a.coins += 5                                    # fixture: a few coins to buy with
	var had := a.coins
	if not m.inv.has("bread"):
		m.inv.add("bread", 1)                       # fixture: something on the stall
	var ok := w.trade(a, m, "bread", 1, 1)
	check(ok and w.relations.traded_with(a.id, m.id), "buying from a merchant records them as a commercial contact (Relations.trades)")
	var be := cs.known_recipients(ref(a)).filter(func(e): return e.ref == ref(m) and e.kind == "business")
	check(be.size() == 1, "so the merchant's business is a recipient, even with no personal tie to its owner (days known %d)" % int(w.relations.peek(a.id, m.id).days_known))
	var loc := cs.location(ref(m), "business")
	check(str(loc.what) in ["the stall", "their stall"] or str(loc.what).begins_with("the "), "a business is found at its stall or workplace (%s at %d,%d)" % [str(loc.what), int(loc.x), int(loc.y)])
	var ploc := cs.location(ref(friend), "person")
	check(str(ploc.what) == "their home" and Vector2i(int(ploc.x), int(ploc.y)) == w.building_door(friend.home), "a person is found at their home's door, from the world's records")
	check(had - a.coins == 1, "(the trade itself was an ordinary sale: 1 coin)")


func test_fees() -> void:
	var r: Dictionary = cs.routes[0]
	var q := cs.quote({"kind": "route", "route": r.id, "items": {"wheat": 30}})
	check(int(q.loads) == 2 and int(q.fee) == 2 * int(r.fee_per_load), "a regular route charges a flat fee a load: 30 wheat = 2 loads = %d coins" % int(q.fee))
	var a: NPC = people()[1]
	var c: NPC = people()[2]
	var base := cs.quote({"kind": "special", "sender": ref(a), "recipient": "region:eastmarch", "courier": ref(c), "items": {"wheat": 10}})
	var heavy := cs.quote({"kind": "special", "sender": ref(a), "recipient": "region:eastmarch", "courier": ref(c), "items": {"wheat": cs.capacity(ref(c)) * 2}})
	var notary := cs.quote({"kind": "special", "sender": ref(a), "recipient": "region:eastmarch", "courier": ref(c), "items": {"wheat": 10}, "notarise": true})
	var near := cs.quote({"kind": "special", "sender": ref(a), "recipient": ref(c), "courier": ref(c), "items": {"wheat": 10}})
	check(int(heavy.fee) > int(base.fee) and int(heavy.loads) == 2, "a special delivery costs more for more loads (%d -> %d)" % [int(base.fee), int(heavy.fee)])
	check(int(notary.fee) - int(base.fee) == int(CourierService.cfg().special.notary_fee), "and the notarial service adds its fee")
	check(int(near.fee) < int(base.fee), "and a local errand costs less than a journey to Eastmarch (%d < %d)" % [int(near.fee), int(base.fee)])
	var sum := 0
	for k in base.parts:
		sum += int(base.parts[k])
	check(sum == int(base.fee) or int(base.fee) == int(CourierService.cfg().special.minimum), "the fee is the sum of its parts (labour, stops, loads, notary): %s" % str(base.parts))


func test_route_delivery() -> void:
	var a: NPC = people()[1]
	a.inv.add("wheat", 30)                          # fixture: goods to send
	a.coins += 40
	# a regional trade with Eastmarch makes it a known business for this sender (its journal)
	var vp := SettlementLedger.make({"id": "village/npc:%d" % a.id, "settlement": "village", "coins": 50, "transport": {"carry": 1}, "needs": {"iron_ore": 1.0}})
	var rm := RegionalMarket.plan([vp, east], cs.links)
	RegionalMarket.execute(rm, [vp, east], 0)
	check(cs.is_known(ref(a), "region:eastmarch"), "a villager who has traded with Eastmarch can send to it")
	var before := totals()
	var r: Dictionary = cs.routes[0]
	var keeper := str(cs.booth_of("village").keeper)
	var k0 := cs.coins_of(keeper)
	var too_much := cs.book_route({"route": r.id, "sender": ref(a), "recipient": "region:eastmarch", "items": {"wheat": 999}})
	check(too_much.has("error"), "booking goods the sender does not have is refused (%s)" % str(too_much.get("error", "")))
	var j := cs.book_route({"route": r.id, "sender": ref(a), "recipient": "region:eastmarch", "items": {"wheat": 30}, "recipient_kind": "business"})
	check(not j.has("error") and str(j.state) == "at_booth" and cs.coins_of(keeper) - k0 == int(j.fee), "booked at the booth: the flat fee (%d) is paid to the booth's keeper, the wheat handed over" % int(j.fee))
	check(totals() == before, "booking moves goods and coins, creates none")
	var e0 := east.stock.count("wheat")
	cs.tick(float(r.next_day))
	check(str(j.state) == "in_transit", "the courier leaves on the route's day with the wheat in its pack")
	cs.tick(float(j.arrive) + 0.01)
	check(east.stock.count("wheat") - e0 == 30, "and hands it over at Eastmarch after the journey")
	check(str(j.state) == "returning", "then travels back (the contract is not fulfilled yet)")
	cs.tick(float(j.back) + 0.01)
	check(str(j.state) == "fulfilled" and totals() == before, "back home: fulfilled; every good and coin accounted for")


func test_special_delivery() -> void:
	var a: NPC = people()[1]
	var courier: NPC = people()[2]
	var rec: NPC = trader("merchant_raw")
	know(a, rec)
	know(a, courier)
	a.inv.add("plank", 8)
	a.coins += 60
	rec.coins += 50
	var order := {"sender": ref(a), "recipient": ref(rec), "courier": ref(courier), "items": {"plank": 8},
		"collect": {"kind": "coins", "amount": 16}, "proceeds": "deliver"}
	var text := cs.describe(order)
	check("8 Plank" in text and "collect 16 coins" in text and "Fee:" in text, "the instruction reads plainly: \"%s\"" % text)
	var low := cs.negotiate(order, 1)
	check(str(low.answer) == "counter" and int(low.fee) == int(low.quote.fee), "a low offer is countered with the courier's least fee for the work (%d)" % int(low.fee))
	var before := totals()
	var a0 := a.coins
	var j := cs.book_special(order, int(low.fee))
	check(not j.has("error") and courier.inv.count("plank") >= 8 and int(cs.booth_of("village").escrow) >= int(low.fee),
		"agreed: the planks go into the courier's own pack; the fee is held at the booth")
	check(totals() == before, "nothing created by booking")
	cs.tick(float(j.arrive) + 0.01)
	check(str(j.state) == "returning" and int(j.carried_coins) == 16, "delivered; the 16 coins collected ride back with the courier")
	var c0 := courier.coins
	cs.tick(float(j.back) + 0.01)
	check(str(j.state) == "fulfilled" and a.coins - a0 == 16 - int(low.fee) and courier.coins - c0 == int(low.fee) - 16,
		"back: the 16 coins handed to the sender, the held fee (%d) paid to the courier; fulfilled" % int(low.fee))
	check(totals() == before, "every good and coin accounted for across sender, recipient, courier and booth")
	var unknown: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n != a and int(w.relations.peek(a.id, n.id).days_known) == 0 and not w.relations.traded_with(a.id, n.id):
			unknown = n
			break
	a.inv.add("plank", 1)
	var bad2 := cs.book_special({"sender": ref(a), "recipient": ref(unknown), "courier": ref(courier), "items": {"plank": 1}}, 10)
	check(bad2.has("error") and "do not know" in str(bad2.error), "an unknown recipient cannot be chosen (%s)" % str(bad2.get("error", "")))
	a.inv.add("plank", cs.capacity(ref(courier)) + 1)      # fixture: more than one pack holds
	var big := cs.book_special({"sender": ref(a), "recipient": ref(rec), "courier": ref(courier), "items": {"plank": cs.capacity(ref(courier)) + 1}}, 99)
	check(big.has("error") and "carry" in str(big.error), "more than the courier can carry is refused (%s)" % str(big.get("error", "")))
	a.inv.remove("plank", cs.capacity(ref(courier)) + 1)


func test_deposit_and_rejection() -> void:
	var a: NPC = people()[1]
	var courier: NPC = people()[2]
	var rec: NPC = trader("merchant_raw")
	a.inv.add("plank", 4)
	a.coins += 40
	rec.coins += 20
	var before := totals()
	var j := cs.book_special({"sender": ref(a), "recipient": ref(rec), "courier": ref(courier), "items": {"plank": 4},
		"collect": {"kind": "coins", "amount": 8}, "proceeds": "deposit"}, 30)
	cs.tick(float(j.arrive) + 0.01)
	cs.tick(float(j.back) + 0.01)
	var b := cs.booth_of("village")
	check(str(j.state) == "fulfilled" and int((b.deposits as Dictionary).get(ref(a), {}).get("coins", 0)) == 8, "proceeds deposited at the sender's booth (8 coins)")
	var a0 := a.coins
	cs.withdraw(str(b.id), ref(a))
	check(a.coins - a0 == 8 and totals() == before, "the sender takes them out at the booth; all accounted")
	# rejected: the recipient cannot pay what is asked
	a.inv.add("plank", 2)
	var before_r := totals()
	var poor_ask := rec.coins + 1000
	var r := cs.book_special({"sender": ref(a), "recipient": ref(rec), "courier": ref(courier), "items": {"plank": 2},
		"collect": {"kind": "coins", "amount": poor_ask}}, 30)
	var p0 := a.inv.count("plank")
	cs.tick(float(r.arrive) + 0.01)
	check(str(r.outcome) == "rejected by the recipient" and str(r.state) == "returning", "a recipient who cannot pay what is asked refuses the delivery")
	cs.tick(float(r.back) + 0.01)
	check(str(r.state) == "returned" and a.inv.count("plank") - p0 == 2 and totals() == before_r, "the goods come back to the sender; the courier is paid for the work; nothing lost or made")


func test_unavailable_and_interrupted() -> void:
	var a: NPC = people()[1]
	var courier: NPC = people()[2]
	var victim: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n != a and n != courier and n.job == "laborer":
			victim = n
			break
	if victim == null:
		victim = people()[3]
	know(a, victim)
	a.inv.add("plank", 3)
	a.coins += 40
	var before := totals()
	var j := cs.book_special({"sender": ref(a), "recipient": ref(victim), "courier": ref(courier), "items": {"plank": 3}}, 20)
	w.kill(victim, "fever")
	cs.tick(float(j.arrive) + 0.01)
	check(str(j.outcome) == "recipient unavailable", "a recipient who has died cannot receive it: the goods come back")
	cs.tick(float(j.back) + 0.01)
	check(str(j.state) == "returned" and totals() == before, "returned to the sender; all accounted")
	# interrupted: the courier is waylaid and killed on the road
	var c2: NPC = people()[2]
	var rec: NPC = trader("merchant_raw")
	a.inv.add("plank", 5)
	var a0 := a.coins
	var before2 := totals()
	var k := cs.book_special({"sender": ref(a), "recipient": ref(rec), "courier": ref(c2), "items": {"plank": 5}}, 25)
	w.kill(c2, "waylaid on the road")
	cs.tick(float(k.arrive) + 0.01)
	check(str(k.state) == "interrupted" and a.coins == a0, "the courier waylaid: the contract is interrupted, not fulfilled; the held fee goes back to the sender")
	check(totals() == before2, "the planks it carried passed with its estate (heir or loot), not lost or duplicated")
	var again := cs.book_special({"sender": ref(a), "recipient": ref(rec), "courier": ref(c2), "items": {"plank": 1}}, 25)
	check(again.has("error"), "a dead courier cannot be booked (%s)" % str(again.get("error", "")))


func test_player_same_rules() -> void:
	var courier: NPC = people()[2]
	var friend: NPC = null
	var stranger: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n != courier:
			if int(w.relations.peek(Life.PLAYER_ID, n.id).days_known) >= 1 and friend == null:
				friend = n
			elif int(w.relations.peek(Life.PLAYER_ID, n.id).days_known) == 0 and not w.relations.traded_with(Life.PLAYER_ID, n.id) and stranger == null:
				stranger = n
	if friend == null:
		friend = courier
		w.relations.tie(Life.PLAYER_ID, friend.id).days_known = 1
	w.player.inv.add("plank", 2)
	var u := cs.book_special({"sender": "player", "recipient": ref(stranger), "courier": ref(courier), "items": {"plank": 1}}, 20)
	check(u.has("error"), "the player cannot send to a stranger either")
	check(cs.is_known("player", ref(friend)), "and can send to someone they know, by the same rule as villagers")
