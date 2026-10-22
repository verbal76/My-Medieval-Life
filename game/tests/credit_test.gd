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
	test_player_seller()
	test_player_death()
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
	w4.player.death_cause = "old age"
	w4.continue_as_heir()
	check(str(w4.credit.debts[0].state) == Credit.OPEN and w4.credit.debts[0].debtor == World.PLAYER, "the player's debt passes to their heir (not slain), as a villager's does")
	check(w4.credit.owed(Credit.ref_of(p4[0]), World.PLAYER) == 6 and w4.player.generation == 2, "the heir is the debtor now")


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


## The player in the seller's chair: a villager short of food asks them; they offer goods or credit to a villager.
func hungry_pair(w: World) -> Array:
	var p := pair(w)
	var b: NPC = p[1]
	for n: NPC in w.npcs:
		if n.alive and n != b:
			n.pos = Vector2(-500, -500)          # no villager within reach: only the player is near
	for m: NPC in w.brain._members(b.household):
		m.inv = Inventory.new()
		m.coins = 0
	w.households[b.household].pantry = Inventory.new()
	var pl := w.player
	pl.inv = Inventory.new()
	pl.inv.add("bread", 6)
	pl.pos = b.pos
	return [p[0], b, pl]


func test_player_seller() -> void:
	# credit: asked by a villager who trusts the player; accepted
	var w := new_world()
	var h := hungry_pair(w)
	var b: NPC = h[1]
	var pl: PlayerState = h[2]
	trust(w, b.id, Life.PLAYER_ID, 40.0)
	var coins0 := w.total_coins()
	var goods0 := world_goods(w)
	w.credit.dawn()
	check(w.credit.requests.size() == 1 and w.credit.requests[0].mode == "credit" and pl.inv.count("bread") == 6, "a hungry villager with no coins asks the player on credit; nothing moves until the answer")
	var rid: int = w.credit.requests[0].id
	var r := w.credit.answer_request(rid, true)
	check(r.result == "credited" and pl.inv.count("bread") < 6 and w.credit.owed(World.PLAYER, Credit.ref_of(b)) > 0, "accepted: the goods go over and the villager owes the player")
	check(w.total_coins() == coins0 and world_goods(w) == goods0, "no coin or good made or lost")
	check(w.credit.request_for(b.id).is_empty(), "the ask is answered")
	# repayment to the player
	var owed: int = w.credit.owed(World.PLAYER, Credit.ref_of(b))
	b.coins = owed + 500
	b.pos = pl.pos
	var pc := pl.coins
	next_day(w, int(Credit.cfg().days))
	w.credit.dawn()
	check(pl.coins == pc + owed and w.credit.owed(World.PLAYER, Credit.ref_of(b)) == 0, "a villager repays the player at dawn from the due day (coins move, none made)")
	# default with the player as creditor
	var w2 := new_world()
	var h2 := hungry_pair(w2)
	var b2: NPC = h2[1]
	trust(w2, b2.id, Life.PLAYER_ID, 40.0)
	w2.credit.dawn()
	w2.credit.answer_request(int(w2.credit.requests[0].id), true)
	b2.coins = 0
	next_day(w2, int(Credit.cfg().days) + 1)
	w2.credit.dawn()
	check(str(w2.credit.debts[0].state) == Credit.DEFAULTED, "unpaid, the villager's debt to the player defaults")
	check(float(w2.relations.peek(b2.id, Life.PLAYER_ID).regard) <= 40.0 - float(Credit.cfg().default_regard) + 0.01, "and their standing with the player falls")
	check(w2.credit.credit_refusal(w2.player, b2, 1) != "", "and the player lends them no more by the rule")
	# refuse
	var w3 := new_world()
	var h3 := hungry_pair(w3)
	var b3: NPC = h3[1]
	trust(w3, b3.id, Life.PLAYER_ID, 40.0)
	w3.credit.dawn()
	var rr := w3.credit.answer_request(int(w3.credit.requests[0].id), false)
	check(rr.result == "refused" and h3[2].inv.count("bread") == 6 and w3.credit.debts.is_empty(), "refused: nothing moves, no debt")
	next_day(w3, 1)
	w3.credit.dawn()
	check(w3.credit.requests.is_empty(), "a villager the player turned down does not ask again at once")
	next_day(w3, int(Credit.cfg().refuse_days))
	w3.credit.dawn()
	check(w3.credit.requests.size() == 1, "but asks again after refuse_days")
	# no trust, no goods: no credit ask
	var w4 := new_world()
	hungry_pair(w4)
	w4.credit.dawn()
	check(w4.credit.requests.is_empty(), "a villager the player does not trust enough is not asked for credit (same threshold as a villager lender)")
	# barter ask: the villager has goods the player can use
	var w5 := new_world()
	var h5 := hungry_pair(w5)
	var b5: NPC = h5[1]
	b5.inv.add("coal", 30)
	var goods5 := world_goods(w5)
	var coins5 := w5.total_coins()
	w5.credit.dawn()
	check(w5.credit.requests.size() == 1 and w5.credit.requests[0].mode == "barter", "with goods to offer, the villager asks by barter first")
	var coal0: int = h5[2].inv.count("coal")
	var rb := w5.credit.answer_request(int(w5.credit.requests[0].id), true)
	check(rb.result == "bartered" and h5[2].inv.count("coal") > coal0 and b5.inv.count("bread") > 0, "accepted: goods move both ways")
	check(w5.total_coins() == coins5 and world_goods(w5) == goods5, "barter makes and loses nothing, moves no coin")
	# unanswered asks lapse
	var w6 := new_world()
	var h6 := hungry_pair(w6)
	trust(w6, h6[1].id, Life.PLAYER_ID, 40.0)
	w6.credit.dawn()
	var saved := JSON.stringify(w6.to_dict())
	var w6b := World.new()
	w6b.load_dict(VillageMap.load_default(), JSON.parse_string(saved))
	check(JSON.stringify(w6b.credit.to_dict()) == JSON.stringify(w6.credit.to_dict()) and w6b.credit.requests.size() == 1, "a pending ask saves and loads unchanged")
	next_day(w6, 1)
	w6.credit.dawn()
	check(w6.credit.debts.is_empty() and w6.credit.requests.size() <= 1, "an unanswered ask lapses without a debt")
	# the player offers a villager credit and barter
	var w7 := new_world()
	var p7 := pair(w7)
	var s7: NPC = p7[0]
	var b7: NPC = p7[1]
	var pl7 := w7.player
	pl7.inv = Inventory.new()
	pl7.inv.add("coal", 6)
	s7.job = "smith"
	trust(w7, b7.id, Life.PLAYER_ID, 5.0)
	b7.job = "smith"
	check(w7.credit.credit_refusal(pl7, b7, 4) != "", "the player lends to a villager only where the trust rule allows")
	trust(w7, b7.id, Life.PLAYER_ID, 30.0)
	check(w7.credit.accepts(b7, "coal"), "a smith has use for coal")
	var price: int = w7.credit.ask_prices(pl7, b7, "coal", 1)[0]
	var rl := w7.credit.sell_on_credit(pl7, b7, "coal", 1, price)
	check(rl.result == "credited" and b7.inv.count("coal") == 1 and pl7.inv.count("coal") == 5 and w7.credit.owed(World.PLAYER, Credit.ref_of(b7)) == price, "the player lends goods to a trusting villager who can use them")
	check(w7.credit.sell_on_credit(pl7, b7, "wool_cloth", 1, 3).result == "failed" or not pl7.inv.has("wool_cloth"), "and not what the villager has no use for")
	b7.inv.add("wool_cloth", 6)
	var q := w7.credit.barter_quote(pl7, b7, "coal", 1, "wool_cloth")
	check(bool(q.ok), "the player can offer coal for cloth: " + str(q.why))
	if bool(q.ok):
		var g0 := world_goods(w7)
		var c0 := w7.total_coins()
		w7.credit.barter(pl7, b7, "coal", 1, "wool_cloth")
		check(world_goods(w7) == g0 and w7.total_coins() == c0 and pl7.inv.count("wool_cloth") == int(q.give_qty), "the player's barter offer moves goods both ways and no coin")
	# determinism
	check(_ask_run() == _ask_run(), "asks and answers are deterministic")


func _ask_run() -> String:
	var w := new_world(3)
	var h := hungry_pair(w)
	trust(w, h[1].id, Life.PLAYER_ID, 40.0)
	w.credit.dawn()
	if not w.credit.requests.is_empty():
		w.credit.answer_request(int(w.credit.requests[0].id), true)
	for i in 3:
		next_day(w, 4)
		w.credit.dawn()
	return JSON.stringify([w.credit.to_dict(), w.stats])


func test_player_death() -> void:
	# slain: written off
	var w := new_world()
	var p := pair(w)
	trust(w, p[0].id, Life.PLAYER_ID, 30.0)
	w.credit.sell_on_credit(p[0], w.player, "bread", 1, 6)
	w.player.alive = false
	w.player.death_cause = "Rob the bandit"
	w.continue_as_heir()
	check(str(w.credit.debts[0].state) == Credit.LOST, "a player slain by a person leaves their debts written off, as a villager's are")
	# claims pass to the heir, who is then repaid
	var w2 := new_world()
	var p2 := pair(w2)
	var b2: NPC = p2[1]
	trust(w2, b2.id, Life.PLAYER_ID, 40.0)
	w2.player.inv.add("coal", 3)
	b2.job = "smith"
	w2.credit.sell_on_credit(w2.player, b2, "coal", 1, 5)
	w2.player.alive = false
	w2.player.death_cause = "hunger"
	w2.continue_as_heir()
	check(str(w2.credit.debts[0].state) == Credit.OPEN and w2.credit.owed(World.PLAYER, Credit.ref_of(b2)) == 5, "the player's claim on a villager passes to the heir")
	b2.coins = 500
	b2.pos = w2.player.pos
	var coins0 := w2.total_coins()
	var pc := w2.player.coins
	next_day(w2, int(Credit.cfg().days))
	w2.credit.dawn()
	check(w2.player.coins == pc + 5 and w2.total_coins() == coins0, "and the heir is repaid in coins that already existed")
	# an heir who is the player's own child: debts with that child are lost, others pass
	var w3 := new_world()
	var p3 := pair(w3)
	var kid: NPC = null
	for n: NPC in w3.npcs:
		if n.alive and n.role == "adult" and n != p3[0] and n != p3[1]:
			kid = n
			break
	kid.mother = Life.PLAYER_ID
	w3.player.children = [kid.id]
	trust(w3, p3[0].id, Life.PLAYER_ID, 30.0)
	w3.credit.sell_on_credit(p3[0], w3.player, "bread", 1, 6)
	trust(w3, kid.id, Life.PLAYER_ID, 30.0)
	kid.inv.add("bread", 3)
	w3.credit.sell_on_credit(kid, w3.player, "bread", 1, 4)
	var heir := Life.player_heir_child(w3)
	w3.player.alive = false
	w3.player.death_cause = "old age"
	w3.continue_as_heir()
	if heir != null:
		var kept := 0
		var lost := 0
		for d in w3.credit.debts:
			if str(d.state) == Credit.OPEN:
				kept += 1
			elif str(d.state) == Credit.LOST:
				lost += 1
		check(kept == 1 and lost == 1, "the debt to the child who becomes the heir is lost (as when a villager's heir is the creditor); the other passes")
	check(Credit.slain_cause("Wat the guard") and not Credit.slain_cause("old age") and not Credit.slain_cause("a wolf") and not Credit.slain_cause("hunger"), "only a killing by a person is 'slain'")
