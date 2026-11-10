extends SceneTree
## B25-INV-P100-FULLPACK (owner 2026-11-10, docs/directives/2026-11-10_continued_investigation_merge_prep.md 2A). Found in the
## recorded campaign 42788018729 (fbfd6ad, seed 1, F020/F021): p:100 was refused ale 45 times in a row on day 220 (08:12 to
## 08:56), recorded as "buyer_inventory_full", planning "buying a meal" from the tavernkeeper p:40 every minute. A villager's
## pack has no kind limit (Inventory.max_stacks 0), so the pack was never full: p:40 held 3 ale, all earmarked since 06:00 for
## CON-01 contract 592 (LE-03 claims), and World.trade's claims check (EconClaims.check_trade) refused every sale; the recorder
## names any refusal it cannot classify "buyer_inventory_full". At 08:57 p:40 brewed 2 more ale and the sale went through. The
## meal planner (_vendor_with_food, _meal_choice, _affordable_meal, _cheapest_meal) counted a vendor's promised stock as for
## sale, and buy_food keeps no failure memo, so the plan was made again each minute. buy_qty (every buy_from planner's rule)
## counted the seller's stock and the buyer's purse the same way. Now planning reads the claims rule the trade applies
## (World.claims_allow, World.claims_free_coins), and the recorder names a claims refusal as such. Checked:
##   1 a hungry villager is not sent to buy a meal whose only stock is promised (60 decisions), nothing changes hands
##   2 with unpromised stock as well, they buy it, at the deal price, and the promised units stay with the seller
##   3 buy_qty sells only the unpromised units (and none of the buyer's committed coins)
##   4b B25-INV-P52-BLOCKS (seed 1 F003/F005/F006: the merchant p:52 refused 472 times on day 358 buying building blocks for
##      contract 963, every minute, its coins held by its own open bids): a contract's "buy" step (Contracts.plan) checked the
##      raw purse above the reserve, not the coins the claims leave free; it now plans buy_qty's quantity, and none while the
##      coins are all promised
##   4 a refused sale of promised stock is recorded as "seller_stock_reserved", not "buyer_inventory_full"
##   5 save/load and two identical worlds give the same plan (deterministic)
##   godot --headless --path game --script res://tests/meal_claims_test.gd

var checks := 0
var fails := 0


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		fails += 1


func _init() -> void:
	GameData.ensure()
	var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy.json"))
	c.enabled = true
	c.market.drive = true
	EconomyFoundation.set_override(c)               # the Living Economy on, as in the recorded campaigns
	case_promised_only()
	case_some_free()
	case_buy_qty()
	case_recorded_reason()
	case_contract_buy()
	case_save_load_and_replay()
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)


## A world with tavernkeeper `v` holding `ale` ale (`promised` of it earmarked for a contract) and no other cooked food in the
## village, and a hungry adult `n` of another household with coins and nothing to eat at home. Returns {w, v, n}.
func setup(ale := 3, promised := 3, seed := 1) -> Dictionary:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	var v: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.job == "tavernkeeper" and o.household >= 0:
			v = o
			break
	var n: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o != v and o.household >= 0 and o.household != v.household and o.role in ["adult", "elder"] \
				and o.job not in ["tavernkeeper", "guard", "cook", "farmer", "merchant"] and not w.brain._can_roast(o):
			n = o
			break
	for o: NPC in w.npcs:
		for f in NPCBrain.EDIBLE:
			o.inv.remove(f, o.inv.count(f))
		if o != n:
			o.hunger = 100.0
	for h in w.households:
		(h.pantry as Inventory).items.clear()
	v.inv.add("ale", ale)
	if promised > 0:
		w.economy.reservations.reserve(Contracts.ref_of(v), "ale", promised, "test: contract 592's ale")
	w.treasury += n.coins - 20
	n.coins = 20
	n.skills.erase("trading")
	n.hunger = 10.0
	n.plan.clear()
	n.pos = v.pos + Vector2(2, 0)
	for m in w.households[n.household].members:
		var o := w.npc(m)
		if o != null and o != n:
			w.treasury += o.coins
			o.coins = 0
	return {"w": w, "v": v, "n": n}


func _step(n: NPC, act: String) -> Dictionary:
	for st in n.plan:
		if str(st.get("act", "")) == act:
			return st
	return {}


func _coins(w: World) -> int:
	var t := w.treasury
	for o: NPC in w.npcs:
		t += o.coins
	return t


func case_promised_only() -> void:
	var s := setup()
	var w: World = s.w
	var v: NPC = s.v
	var n: NPC = s.n
	check(w.economy != null and not w.claims_allow(v, "ale", 1), "fixture: the tavernkeeper's 3 ale are all promised (claims refuse a sale)")
	var c0 := _coins(w)
	var planned := 0
	var refused := 0
	for i in 60:
		n.plan.clear()
		n.hunger = 10.0
		w.brain._plan_eat(n)
		var st := _step(n, "buy_food")
		if not st.is_empty() and int(st.args.vendor) == v.id:
			planned += 1
			if not w.brain.act(n, "buy_food", st.args):
				refused += 1
		w.minutes += 1.0
	check(planned == 0, "a hungry villager is not sent to buy a meal whose only stock is promised, in 60 decisions (%d planned, %d refused)" % [planned, refused])
	check(_coins(w) == c0 and v.inv.count("ale") == 3, "and nothing changes hands (the promised ale stays: %d)" % v.inv.count("ale"))
	w.dispose()


func case_some_free() -> void:
	var s := setup(5, 3)
	var w: World = s.w
	var v: NPC = s.v
	var n: NPC = s.n
	w.brain._plan_eat(n)
	var st := _step(n, "buy_food")
	check(not st.is_empty() and int(st.args.vendor) == v.id, "with 2 unpromised ale as well, the villager is sent to buy (doing %s)" % n.doing)
	if st.is_empty():
		w.dispose()
		return
	var nc := n.coins
	var up := w.deal_price(w.sell_price(v, "ale"), n, v)
	var c0 := _coins(w)
	var ok: bool = w.brain.act(n, "buy_food", st.args)
	check(ok and nc - n.coins == up and v.inv.count("ale") == 4 and _coins(w) == c0,
		"and buys one at the deal price %d (ale %d -> %d, the 3 promised still held; coins conserved)" % [up, 5, v.inv.count("ale")])
	w.dispose()


func case_buy_qty() -> void:
	var s := setup(5, 3)
	var w: World = s.w
	var v: NPC = s.v
	var n: NPC = s.n
	var q: int = w.brain.buy_qty(n, v, "ale", 5, true)
	check(q == 2, "buy_qty sells only the 2 unpromised units of 5 (%d)" % q)
	w.economy.reservations.reserve(Contracts.ref_of(n), EconReservations.COINS, n.coins, "test: the buyer's coins promised")
	q = w.brain.buy_qty(n, v, "ale", 5, true)
	check(q == 0, "and none when the buyer's coins are all promised elsewhere (%d)" % q)
	w.dispose()


func case_recorded_reason() -> void:
	var s := setup()
	var w: World = s.w
	var v: NPC = s.v
	var n: NPC = s.n
	var root := OS.get_cache_dir() + "/mml_meal_claims_%d" % int(Time.get_unix_time_from_system())
	DirAccess.make_dir_recursive_absolute(root)
	var rec := WorldRecorder.attach(w, {"root": root})
	var up := w.deal_price(w.sell_price(v, "ale"), n, v)
	var ok := w.trade(n, v, "ale", 1, up)
	w.dispose()
	var reason := ""
	for e in RecorderArchive.read_table(FlightRecorder._abs(rec.dir), "event"):
		if str(e.get("subtype", "")) == "trade" and str(e.get("outcome", "")) == "refused":
			reason = str(e.get("reason", ""))
	check(not ok and reason == "seller_stock_reserved", "a refused sale of promised stock is recorded as seller_stock_reserved (recorded: %s)" % reason)
	check(rec.unknown_codes.is_empty(), "the reason is in the recorder's code table (%s)" % str(rec.unknown_codes))


func case_contract_buy() -> void:
	var s := setup(0, 0)
	var w: World = s.w
	var n: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job == "merchant":
			n = o
			break
	var v: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o != n and o.job in ["laborer", "stonecutter"]:
			v = o
			break
	if n == null or v == null:
		check(false, "fixture: a merchant and a block seller (%s, %s)" % [str(n), str(v)])
		w.dispose()
		return
	for o: NPC in w.npcs:
		if o != v:
			o.inv.remove("building_block", o.inv.count("building_block"))
	v.inv.add("building_block", 10)
	w.treasury += n.coins - 200
	n.coins = 200
	var c: Dictionary = w.contracts._new_record("player", World.npc_ref(n.id), "building_block", 6, 9, 3, [])
	c.state = "accepted"
	c.route = "buy"
	w.contracts.list.append(c)
	var held: Dictionary = w.economy.reservations.reserve(Contracts.ref_of(n), EconReservations.COINS, n.coins, "test: the merchant's own open bids")
	check(not held.is_empty() and w.claims_free_coins(n, "building_block") == 0, "fixture: the merchant's 200 coins are all held by its own bids")
	var planned := 0
	var refused := 0
	for i in 60:
		n.plan.clear()
		w.contracts.plan(n)
		var st := _step(n, "buy_from")
		if not st.is_empty() and str(st.args.item) == "building_block":
			planned += 1
			if not w.brain.act(n, "buy_from", st.args):
				refused += 1
		w.minutes += 1.0
	check(planned == 0, "a contract's purchase is not planned while the buyer's coins are all promised, in 60 decisions (%d planned, %d refused)" % [planned, refused])
	w.economy.reservations.release(int(held.id))
	n.plan.clear()
	w.contracts.plan(n)
	var st := _step(n, "buy_from")
	var q := int(st.args.qty) if not st.is_empty() else 0
	check(q > 0 and w.brain.act(n, "buy_from", st.args) and n.inv.count("building_block") == q, "with the coins free again it is planned and the act sells all %d planned" % q)
	w.dispose()


func case_save_load_and_replay() -> void:
	var s := setup(5, 3)
	var w: World = s.w
	var n: NPC = s.n
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true)))
	var n2 := w2.npc(n.id)
	w.brain._plan_eat(n)
	w2.brain._plan_eat(n2)
	check(JSON.stringify(n.plan) == JSON.stringify(n2.plan) and not _step(n, "buy_food").is_empty(), "after a save and load the same plan (%s)" % n2.doing)
	var a := setup()
	var b := setup()
	a.w.brain._plan_eat(a.n)
	b.w.brain._plan_eat(b.n)
	check(JSON.stringify((a.n as NPC).plan) == JSON.stringify((b.n as NPC).plan), "two identical worlds give the same plan (deterministic)")
	w.dispose()
	w2.dispose()
	a.w.dispose()
	b.w.dispose()
