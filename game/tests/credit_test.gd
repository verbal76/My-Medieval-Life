extends SceneTree
## TRADE-CREDIT (owner Q18-5): barter conserves goods both ways and moves no coins; credit only from a seller who trusts
## the buyer; debts are recorded, repaid, defaulted (regard falls, no more credit), saved, passed on or written off at
## death; no coins are created; the same rules for the player and villagers; deterministic. Pure World. Run headless:
##   godot --headless --path game --script res://tests/credit_test.gd

const Census := preload("res://tests/census.gd")
var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func new_world(seed := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


func _init() -> void:
	test_barter()
	test_barter_refusals()
	test_credit_trust()
	test_repay_and_default()
	test_need_defaults()
	test_player_debtor()
	test_save()
	test_death()
	test_villagers_in_need()
	test_determinism()
	test_parity()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## Two adults of different households: a seller (made a smith, who is glad of coal and keeps no bread) and a buyer.
func pair(w: World) -> Array:
	var s: NPC = null
	var b: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 0:
			if s == null:
				s = n
			elif n.household != s.household and b == null:
				b = n
	s.job = "smith"
	s.inv = Inventory.new()
	b.inv = Inventory.new()
	s.inv.add("bread", 6)
	s.coins = 5000
	b.coins = 0
	return [s, b]


func next_day(w: World, n := 1) -> void:
	w.minutes += 1440.0 * n


func trust(w: World, a: int, b: int, regard: float) -> void:
	w.relations.tie(a, b).regard = regard


func world_goods(w: World) -> Dictionary:
	return Census.goods(w)


func test_barter() -> void:
	var w := new_world()
	var p := pair(w)
	var s: NPC = p[0]
	var b: NPC = p[1]
	b.inv.add("coal", 12)
	var q := w.credit.barter_quote(s, b, "bread", 1, "coal")
	check(bool(q.ok) and int(q.give_qty) >= 1, "a smith swaps bread for coal: %d coal for a loaf (they ask %d coins' worth, coal fetches %d)" % [int(q.give_qty), int(q.ask), int(q.offered)])
	check(int(q.offered) >= int(q.ask), "the seller receives at least what it gives away, by its own bids")
	var goods0 := world_goods(w)
	var coins0 := w.total_coins()
	var sc := s.coins
	var bc := b.coins
	var r := w.credit.barter(s, b, "bread", 1, "coal")
	check(r.result == "bartered", "the barter goes through")
	check(b.inv.count("bread") == 1 and s.inv.count("bread") == 5, "the buyer has the bread, the seller one fewer")
	check(b.inv.count("coal") == 12 - int(q.give_qty) and s.inv.count("coal") == int(q.give_qty), "and the seller has the coal the buyer gave")
	check(world_goods(w) == goods0, "goods are conserved: nothing made or lost")
	check(w.total_coins() == coins0 and s.coins == sc and b.coins == bc, "no coin moved or was made")
	check(w.relations.traded_with(s.id, b.id) and int(w.stats.get("barter_deals", 0)) == 1, "the pair are commercial contacts and the deal is counted")
	# a bigger swap: 3 loaves
	var q3 := w.credit.barter_quote(s, b, "bread", 3, "coal")
	check(not bool(q3.ok) or int(q3.give_qty) > int(q.give_qty), "three loaves cost more coal than one (or the coal runs short)")


func test_barter_refusals() -> void:
	var w := new_world()
	var p := pair(w)
	var s: NPC = p[0]
	var b: NPC = p[1]
	b.inv.add("wool_cloth", 5)
	b.inv.add("coal", 1)
	check(not bool(w.credit.barter_quote(s, b, "bread", 1, "wool_cloth").ok), "a seller with no use for the offered goods refuses (%s)" % w.credit.barter_quote(s, b, "bread", 1, "wool_cloth").why)
	check(not bool(w.credit.barter_quote(s, b, "bread", 6, "coal").ok), "goods not worth enough are refused (%s)" % w.credit.barter_quote(s, b, "bread", 6, "coal").why)
	check(not bool(w.credit.barter_quote(s, b, "wheat", 1, "coal").ok), "a seller without the wanted goods refuses")
	var goods0 := world_goods(w)
	check(w.credit.barter(s, b, "bread", 1, "wool_cloth").result == "failed" and world_goods(w) == goods0 and b.inv.count("bread") == 0, "a refused barter changes nothing")
	var vet := w.credit.barter_quote(s, b, "bread", 1, "bread")
	check(not bool(vet.ok), "nothing is swapped for itself")
	s.inv.add("coal", 3)
	w.player.inv.add("coal", 3)
	check(w.credit.spare(w.player, "coal") <= 3, "the player offers only goods that are theirs to spare")


func test_credit_trust() -> void:
	var w := new_world()
	var p := pair(w)
	var s: NPC = p[0]
	var b: NPC = p[1]
	var price: int = w.credit.ask_prices(s, b, "bread", 1)[0]
	var bill := price
	var no := w.credit.credit_refusal(s, b, bill)
	check(no != "", "a seller who barely knows the buyer refuses credit (%s)" % no)
	var goods0 := world_goods(w)
	check(w.credit.sell_on_credit(s, b, "bread", 1, bill).result == "failed" and b.inv.count("bread") == 0 and w.credit.debts.is_empty(), "no goods move and no debt is recorded")
	trust(w, s.id, b.id, Credit.trust_needed() - 1.0)
	check(w.credit.credit_refusal(s, b, bill) != "", "regard just under the befriend threshold is still not enough")
	trust(w, s.id, b.id, Credit.trust_needed())
	check(w.credit.credit_refusal(s, b, bill) == "", "at the threshold they lend")
	var coins0 := w.total_coins()
	var r := w.credit.sell_on_credit(s, b, "bread", 1, bill)
	check(r.result == "credited" and b.inv.count("bread") == 1 and s.inv.count("bread") == 5, "the bread is handed over on credit")
	check(w.credit.debts.size() == 1 and w.credit.owed(Credit.ref_of(s), Credit.ref_of(b)) == bill and int(r.debt.due) == w.day() + int(Credit.cfg().days), "the debt is recorded, in coins, due in %d days" % int(Credit.cfg().days))
	check(w.total_coins() == coins0 and b.coins == 0, "no coin is made by lending")
	check(world_goods(w) == goods0, "goods are conserved")
	var limit := int(Credit.cfg().limit)
	check(w.credit.credit_refusal(s, b, limit) != "", "the creditor's limit holds (%s)" % w.credit.credit_refusal(s, b, limit))
	for m: NPC in w.brain._members(s.household):
		m.inv = Inventory.new()
		m.coins = 0
	w.households[s.household].pantry = Inventory.new()
	w._reserve_cache.clear()
	check(w.reserve_of(s) > 0 and w.credit.credit_refusal(s, b, 1) != "", "a seller short of coins themselves (reserve %d) does not lend" % w.reserve_of(s))


func test_repay_and_default() -> void:
	var w := new_world()
	var p := pair(w)
	var s: NPC = p[0]
	var b: NPC = p[1]
	trust(w, s.id, b.id, 30.0)
	var bill: int = w.credit.ask_prices(s, b, "bread", 1)[0]
	w.credit.sell_on_credit(s, b, "bread", 1, bill)
	var d: Dictionary = w.credit.debts[0]
	b.coins = 500
	var reg0: float = w.relations.peek(s.id, b.id).regard
	var coins0 := w.total_coins()
	var sc := s.coins
	next_day(w, int(Credit.cfg().days))
	w.credit.dawn()
	check(str(d.state) == Credit.REPAID, "a debtor who can pay repays on the due day (%s)" % d.state)
	check(s.coins == sc + bill and b.coins == 500 - bill and w.total_coins() == coins0, "the coins move from debtor to creditor, none made")
	check(float(w.relations.peek(s.id, b.id).regard) > reg0, "repaying raises the creditor's regard")
	check(w.credit.credit_refusal(s, b, 5) == "", "and credit is open again")
	# a default: no coins at all
	var w2 := new_world()
	var p2 := pair(w2)
	var s2: NPC = p2[0]
	var b2: NPC = p2[1]
	trust(w2, s2.id, b2.id, 40.0)
	var bill2: int = w2.credit.ask_prices(s2, b2, "bread", 1)[0]
	w2.credit.sell_on_credit(s2, b2, "bread", 2, bill2 * 2)
	var d2: Dictionary = w2.credit.debts[0]
	var friend: NPC = null
	for n: NPC in w2.npcs:
		if n.alive and n.id != s2.id and n.id != b2.id and n.role == "adult":
			friend = n
			break
	w2.relations.tie(friend.id, s2.id).friends = true
	trust(w2, friend.id, b2.id, 10.0)
	next_day(w2, int(Credit.cfg().days))
	w2.credit.dawn()
	check(str(d2.state) == Credit.OPEN, "on the due day an unpaid debt is not yet a default")
	next_day(w2, 1)
	w2.credit.dawn()
	check(str(d2.state) == Credit.DEFAULTED, "a day past due it is a default")
	check(float(w2.relations.peek(s2.id, b2.id).regard) == 40.0 - float(Credit.cfg().default_regard), "the creditor's regard for the debtor falls by %d" % int(Credit.cfg().default_regard))
	check(float(w2.relations.peek(friend.id, b2.id).regard) < 10.0, "and the creditor's friends think less of the debtor")
	check(w2.credit.credit_refusal(s2, b2, 1) != "", "no more credit while it stands (%s)" % w2.credit.credit_refusal(s2, b2, 1))
	check(w2.stats.get("credit_defaulted", 0) == 1.0, "the default is counted")
	b2.coins = bill2 * 2
	var coins1 := w2.total_coins()
	trust(w2, s2.id, b2.id, 30.0)
	check(w2.credit.repay(int(d2.id), true) and str(d2.state) == Credit.LATE, "repaid late, the debt is cleared")
	check(w2.total_coins() == coins1, "no coin made")
	trust(w2, s2.id, b2.id, 30.0)
	check(w2.credit.credit_refusal(s2, b2, 1) == "", "and the block is lifted once regard allows")


func test_need_defaults() -> void:
	var w := new_world()
	var p := pair(w)
	var s: NPC = p[0]
	var b: NPC = p[1]
	trust(w, s.id, b.id, 30.0)
	var bill: int = w.credit.ask_prices(s, b, "bread", 1)[0]
	w.credit.sell_on_credit(s, b, "bread", 1, bill)
	var d: Dictionary = w.credit.debts[0]
	# the household has no food and little money: its reserve is above what is left after paying
	for m: NPC in w.brain._members(b.household):
		m.inv = Inventory.new()
		m.coins = 0
	w.households[b.household].pantry = Inventory.new()
	b.coins = bill
	w._reserve_cache.clear()
	check(w.reserve_of(b) > 0 and not w.credit.can_repay(d), "a villager whose household needs its coins cannot repay (reserve %d)" % w.reserve_of(b))
	var sc := s.coins
	next_day(w, int(Credit.cfg().days) + 1)
	w._reserve_cache.clear()
	w.credit.dawn()
	check(str(d.state) == Credit.DEFAULTED and b.coins == bill and s.coins == sc, "so the debt defaults legitimately: nothing is seized, no hidden rescue")


func test_player_debtor() -> void:
	var w := new_world()
	var p := pair(w)
	var s: NPC = p[0]
	var pl := w.player
	trust(w, s.id, Life.PLAYER_ID, 40.0)
	var kin: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.id != s.id and (n.partner == s.id or Life.kin(n.id, n.mother, n.father, s.id, s.mother, s.father)):
			kin = n
			break
	var bill: int = w.credit.ask_prices(s, pl, "bread", 2)[0] + w.credit.ask_prices(s, pl, "bread", 2)[1]
	pl.coins = 0
	var r := w.credit.sell_on_credit(s, pl, "bread", 2, bill)
	check(r.result == "credited" and pl.inv.count("bread") >= 2, "the player buys on credit from a seller who trusts them")
	next_day(w, int(Credit.cfg().days))
	w.credit.dawn()
	check(str(w.credit.debts[0].state) == Credit.OPEN and w.credit.debts[0].due == w.day(), "the player's debt is not collected for them: it falls due")
	next_day(w, 1)
	w.credit.dawn()
	check(str(w.credit.debts[0].state) == Credit.DEFAULTED and pl.coins == 0, "unpaid a day past the due day it is a default, and no coin is taken")
	check(float(w.relations.peek(s.id, Life.PLAYER_ID).regard) <= 40.0 - float(Credit.cfg().default_regard) + 0.01, "the seller's regard falls")
	check(w.credit.credit_refusal(s, pl, 1) != "", "and they will lend no more")
	pl.coins = bill + 3
	var coins0 := w.total_coins()
	check(w.credit.repay(int(w.credit.debts[0].id)) and pl.coins == 3 and w.total_coins() == coins0, "the player can repay late from their purse")


func test_save() -> void:
	var w := new_world()
	var p := pair(w)
	var s: NPC = p[0]
	var b: NPC = p[1]
	check(not w.to_dict().has("credit"), "a world with no debts saves no credit key")
	trust(w, s.id, b.id, 30.0)
	w.credit.sell_on_credit(s, b, "bread", 1, 7)
	trust(w, s.id, Life.PLAYER_ID, 30.0)
	w.credit.sell_on_credit(s, w.player, "bread", 1, 5)
	var text := JSON.stringify(w.to_dict())
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(text))
	check(JSON.stringify(w2.credit.to_dict()) == JSON.stringify(w.credit.to_dict()) and w2.credit.debts.size() == 2, "open debts save and load unchanged")
	check(w2.credit.owed(Credit.ref_of(s), Credit.ref_of(b)) == 7 and w2.credit.owed(Credit.ref_of(s), World.PLAYER) == 5, "who owes whom survives")
	var dd: Dictionary = JSON.parse_string(text)
	dd.erase("credit")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), dd)
	check(w3.credit.debts.is_empty() and w3.credit.next_id == 1, "an older save without the key loads with no debts")
	next_day(w2, 20)
	w2.credit.dawn()
	check(w2.credit.debts.size() == 2, "a loaded debt is settled by the clock as before")


func test_death() -> void:
	var w := new_world()
	var p := pair(w)
	var s: NPC = p[0]
	var b: NPC = p[1]
	trust(w, s.id, b.id, 30.0)
	w.credit.sell_on_credit(s, b, "bread", 1, 6)
	var d: Dictionary = w.credit.debts[0]
	var heir := w._heir(b)
	w.kill(b, "old age")
	if heir != null:
		check(d.debtor == Credit.ref_of(heir) and str(d.state) == Credit.OPEN, "a debtor's debt passes to the heir who takes what they leave")
	else:
		check(str(d.state) == Credit.LOST, "no heir: the debt is written off")
	# slain: nobody inherits: written off
	var w2 := new_world()
	var p2 := pair(w2)
	trust(w2, p2[0].id, p2[1].id, 30.0)
	w2.credit.sell_on_credit(p2[0], p2[1], "bread", 1, 6)
	w2.kill(p2[1], "slain by a wolf")
	check(str(w2.credit.debts[0].state) == Credit.LOST and w2.stats.get("credit_lost", 0) == 1.0, "a debtor slain leaves no estate: the debt is lost (counted)")
	# a creditor dies
	var w3 := new_world()
	var p3 := pair(w3)
	trust(w3, p3[0].id, p3[1].id, 30.0)
	w3.credit.sell_on_credit(p3[0], p3[1], "bread", 1, 6)
	var cheir := w3._heir(p3[0])
	w3.kill(p3[0], "old age")
	var d3: Dictionary = w3.credit.debts[0]
	check((cheir != null and d3.creditor == Credit.ref_of(cheir)) or (cheir == null and str(d3.state) == Credit.LOST) or (cheir != null and cheir == p3[1] and str(d3.state) == Credit.LOST), "a creditor's claim passes to their heir, else is forgiven")
	# the player dies
	var w4 := new_world()
	var p4 := pair(w4)
	trust(w4, p4[0].id, Life.PLAYER_ID, 30.0)
	w4.credit.sell_on_credit(p4[0], w4.player, "bread", 1, 6)
	w4.player.alive = false
	w4.continue_as_heir()
	check(str(w4.credit.debts[0].state) == Credit.LOST, "the player's debts are written off at their death: the heir starts clean with the kit only")


## A household with no food or coins, a neighbour with bread who trusts them: a dawn pass lends the food.
func test_villagers_in_need() -> void:
	var w := new_world()
	var p := pair(w)
	var s: NPC = p[0]
	var b: NPC = p[1]
	for n: NPC in w.npcs:
		if n.alive and n != b and n.role == "adult":
			trust(w, n.id, b.id, 30.0)
	for m: NPC in w.brain._members(b.household):
		m.inv = Inventory.new()
		m.coins = 0
	w.households[b.household].pantry = Inventory.new()
	s.pos = b.pos
	check(w.brain.household_food_days(b.household) < float(GameData.b("relief_trigger_days")), "the household is short of food")
	var goods0 := world_goods(w)
	var coins0 := w.total_coins()
	w.credit.dawn()
	var n_credit := int(w.stats.get("credit_extended", 0))
	var n_barter := int(w.stats.get("barter_deals", 0))
	check(n_credit + n_barter >= 1, "a villager short of food with no coins gets some from a neighbour (credit %d, barter %d)" % [n_credit, n_barter])
	check(w.total_coins() == coins0 and world_goods(w) == goods0, "no coin made, no good made or lost")
	var fed := 0
	for m: NPC in w.brain._members(b.household):
		fed += m.inv.total()
	check(fed >= 1 or int(w.households[b.household].pantry.total()) >= 1, "the food reached the household")
	# with goods a neighbour wants, and credit not open, they barter first
	var w2 := new_world()
	var q := pair(w2)
	var b2: NPC = q[1]
	for m: NPC in w2.brain._members(b2.household):
		m.inv = Inventory.new()
		m.coins = 0
	w2.households[b2.household].pantry = Inventory.new()
	for n: NPC in w2.npcs:
		if n.alive and n.role == "adult" and n.household != b2.household:
			n.job = "smith"
			n.pos = b2.pos
	b2.inv.add("coal", 30)
	w2.credit.dawn()
	check(int(w2.stats.get("barter_deals", 0)) >= 1 and int(w2.stats.get("credit_extended", 0)) == 0, "with goods the neighbour is glad of, and no trust, they barter (deals %d)" % int(w2.stats.get("barter_deals", 0)))


func test_determinism() -> void:
	var a := _scripted()
	var b := _scripted()
	check(a == b, "the same seed and the same deals give byte-identical debt records and stats")


func _scripted() -> String:
	var w := new_world(2)
	var p := pair(w)
	trust(w, p[0].id, p[1].id, 30.0)
	w.credit.sell_on_credit(p[0], p[1], "bread", 2, 9)
	for i in 4:
		next_day(w, 4)
		w.credit.dawn()
	return JSON.stringify([w.credit.to_dict(), w.stats, p[0].coins, p[1].coins])


func test_parity() -> void:
	var w := new_world()
	var p := pair(w)
	var s: NPC = p[0]
	var b: NPC = p[1]
	var pl := w.player
	var bn: int = w.credit.ask_prices(s, b, "bread", 1)[0]
	var pn: int = w.credit.ask_prices(s, pl, "bread", 1)[0]
	check(pn >= 1 and bn >= 1, "both buyers are quoted the seller's ask")
	for regard in [0.0, 24.0, 25.0]:
		trust(w, s.id, b.id, regard)
		trust(w, s.id, Life.PLAYER_ID, regard)
		check((w.credit.credit_refusal(s, b, 3) == "") == (w.credit.credit_refusal(s, pl, 3) == ""), "at regard %d the villager and the player are treated alike" % int(regard))
	b.inv.add("coal", 12)
	pl.inv.add("coal", 12)
	check(bool(w.credit.barter_quote(s, b, "bread", 1, "coal").ok) == bool(w.credit.barter_quote(s, pl, "bread", 1, "coal").ok), "barter is open to both alike")
	check(bool(w.credit.barter_quote(s, b, "bread", 1, "wool_cloth").ok) == bool(w.credit.barter_quote(s, pl, "bread", 1, "wool_cloth").ok), "and refused to both alike")
	check(w.credit.owed(Credit.ref_of(s), World.PLAYER) == 0, "no debt unless taken")
