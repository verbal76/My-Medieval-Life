extends SceneTree
## BIZ-06 (Build 25 audit, WP-1): Ventures.close hands a closing business's till to its household (BusinessMoney._keep,
## TILL-D1, B25-BIZ-D1) and then erases the venture record. With the Living Economy on, that hand-over is a recorded transfer
## (EconTransactions.transfer_coins, LE-04) and its result was not checked: if the transfer were refused, the coins left in the
## till were erased with the record. Reachability: in normal play the transfer does not fail (the till holds exactly the amount,
## its owner is a living head); the test forces a refusal (a transaction authority that refuses the till's hand-over) and asserts
## the coins are conserved and still reach the household. A normal close is checked too.
##   godot --headless --path game --script res://tests/biz06_venture_close_till_test.gd

var checks := 0
var failures := 0


## The transaction authority with one refusal: every coin transfer out of a venture's till is refused (as the authority refuses
## a party it cannot resolve), so the close's hand-over fails.
class Refusing extends EconTransactions:
	var refused := 0

	func transfer_coins(txid: String, from: String, to: String, amount: int, purpose: String, books := false) -> Dictionary:
		if from.begins_with("venture:"):
			refused += 1
			return {"ok": false, "code": "party_unavailable", "txid": txid}
		return super.transfer_coins(txid, from, to, amount, purpose, books)


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL: ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	GameData.ensure()
	test_close(false)
	test_close(true)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func world(seed := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	w.judgment.cfg.decision.integration.work_accept = false
	return w


## The fixtures of biz05_hand_not_hired_test.gd: the village's best smith founds, builds and opens a smithy.
func founder(w: World) -> NPC:
	var s: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job == "smith" and (s == null or Skills.level(o, "smithing") > Skills.level(s, "smithing")):
			s = o
	var key := World.npc_ref(s.id)
	if not w.experience.minutes.has(key):
		w.experience.minutes[key] = {}
	w.experience.minutes[key]["smithing"] = 480.0 * 60.0
	s.coins += 3000
	w.brain.evaluate_household(s.household)
	return s


func smithy_full(w: World) -> void:
	var day := (NPCBrain.WORK_END - NPCBrain.WORK_START) * 60.0
	var past := []
	for i in int(GameData.b("skilled_places").window_days):
		var d := {}
		for kind in NPCBrain.TRADE_STATIONS.smith:
			for st in w.stations_of(kind):
				if w.ventures.venture_at(st).is_empty():
					d[st] = {"smith": day}
		past.append(d)
	w.station_load = {"day": w.day(), "today": {}, "past": past}


func open_one(w: World) -> Dictionary:
	var s := founder(w)
	smithy_full(w)
	w.ventures.found(s, w.ventures.eligible(s))
	var hh: Dictionary = w.households[s.household]
	var p: Dictionary = w.plot(str(hh.build))
	var pantry: Inventory = hh.pantry
	for id in p.site.need.duplicate():
		pantry.add(id, int(p.site.need[id]))
	w.deliver(p, pantry)
	var b: Dictionary = w.buildings.get(str(p.get("building", "")), {})
	w.minutes += 1440.0
	w.station_load = {}
	w.ventures.daily()
	return b


func coins_of(w: World) -> int:
	var t := w.treasury
	for o: NPC in w.npcs:
		t += o.coins
	for b in w.buildings.values():
		for k in ["front", "venture", "counter", "shop"]:
			if (b as Dictionary).has(k):
				t += int(b[k].get("till", 0))
	return t


func test_close(refuse: bool) -> void:
	var tag := "refused hand-over" if refuse else "normal close"
	var w := world()
	check(w.economy != null and w.economy.market.drive, "%s fixture: the Living Economy drives (the recorded-transfer path)" % tag)
	var b := open_one(w)
	check(b.has("venture"), "%s fixture: the smithy is open" % tag)
	if not b.has("venture"):
		return
	var owner_ref: String = w.business.money.venture_owner(b)
	var head: NPC = w.party(owner_ref)
	check(head != null, "%s fixture: the business's household has a head (%s)" % [tag, owner_ref])
	if head == null:
		return
	# 500 coins of the business's own, taken from the treasury so the world's coins are unchanged
	w.treasury -= 500
	b.venture.till = int(b.venture.get("till", 0)) + 500
	var till := int(b.venture.till)
	var before := coins_of(w)
	var purse := head.coins
	var refusing: Refusing = null
	var saved: EconTransactions = w.transactions
	if refuse:
		refusing = Refusing.new(w)
		w.transactions = refusing
	w.ventures.close(b, "the test closes it")
	if refuse:
		w.transactions = saved
		check(refusing.refused >= 1, "%s fixture: the till's recorded hand-over was refused (%d)" % [tag, refusing.refused])
	check(not b.has("venture"), "%s: the business is closed" % tag)
	check(coins_of(w) == before, "%s: no coin is lost or made (%d before, %d after)" % [tag, before, coins_of(w)])
	check(head.coins == purse + till, "%s: the till's %d coins reach the household's head (%d -> %d)" % [tag, till, purse, head.coins])
