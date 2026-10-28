extends SceneTree
## Expansion 20 LE-02 market (EconMarket): adaptive bids and asks, negotiation with limited counteroffers, atomic settlement
## through World.trade then EconOffers.record_fill, local offers (encounters, direct dialogue), word of mouth on the gossip's
## meetings, CON-01 procurement for any tradable good, OD-LE-13 renegotiation, opinion weighed as one factor, conservation,
## determinism, persistence, and the switch. Gate "Ledger-safe multi-actor trades" (design s.16, s.17).
## Nothing here asserts that a village prospers; trades are asserted only where the scenario's terms overlap.
## Run headless:  godot --headless --path game --script res://tests/le02_market_test.gd

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


func shipped() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/economy.json"))


func cfg_on(drive := true, extra := {}) -> Dictionary:
	var c: Dictionary = shipped()
	c.enabled = true
	c.market.drive = drive
	for k in extra:
		c.market[k] = extra[k]
	return c


func new_world(seed := 1, drive := true, extra := {}) -> World:
	EconomyFoundation.set_override(cfg_on(drive, extra))
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


func _init() -> void:
	test_prices()
	test_shortage_three_actors()
	test_negative_paths()
	test_opinion_weighed()
	test_partial_and_duplicate_fills()
	test_review_adaptive()
	test_knowledge_local_and_word_of_mouth()
	test_procurement_contract()
	test_renegotiation()
	test_dawn_driver()
	test_determinism()
	test_save_mid_negotiation()
	test_switch()
	EconomyFoundation.set_override({})
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ------------------------------------------------------------------------------------------------ helpers
func adults(w: World) -> Array:
	var out := []
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 0:
			out.append(n)
	return out


func job(w: World, j: String, k := 0) -> NPC:
	var i := 0
	for n: NPC in adults(w):
		if n.job == j:
			if i == k:
				return n
			i += 1
	return null


func role(w: World, r: String) -> NPC:
	for n: NPC in adults(w):
		if w.brain.buy_role(n) == r:
			return n
	return null


func ledger(w: World) -> Array:
	return [w.total_coins(), Census.goods(w)]


func clear(w: World, item: String) -> void:
	for n: NPC in w.npcs:
		n.inv.remove(item, n.inv.count(item))


func ref(n: NPC) -> String:
	return World.npc_ref(n.id)


func contract(w: World, seller: NPC, buyer: NPC, item: String, qty: int, price: int, days := 5) -> Dictionary:
	buyer.coins = maxi(buyer.coins, qty * price + 200)
	var c: Dictionary = w.contracts._new_record(ref(buyer), ref(seller), item, qty, price, days, [])
	var ok: bool = w.contracts._open(c)
	assert(ok)
	return c


func day_on(w: World, k := 1) -> void:
	w.minutes += World.DAY * k


## A copy of villager `n` under a new id (identical circumstances, a different person: personality is seeded by id).
func clone(w: World, n: NPC, id: int) -> NPC:
	var c := NPC.from_dict(n.to_dict())
	c.id = id
	c.household = -1
	w.npcs.append(c)
	w.by_id[c.id] = c
	return c


# ------------------------------------------------------------------------------------------------ prices
func test_prices() -> void:
	var w := new_world()
	var m := w.economy.market
	var car := job(w, "carpenter")
	var sm := job(w, "smith")
	var bd := EconMarket.band("leather")
	check(bd == [roundi(6 * 0.6), roundi(6 * 1.8)], "the band is the existing one: value x [price_min, price_max]")
	check(is_equal_approx(float(m.believed(ref(sm), "leather").price), 6.0) and int(m.believed(ref(sm), "leather").sellers) == 0, "with no knowledge an actor believes the item's value")
	w.economy.knowledge.learn(ref(sm), ref(car), "leather", EconKnowledge.SELLS, 9, "dealing")
	w.economy.knowledge.learn(ref(sm), "npc:%d" % job(w, "tanner").id, "leather", EconKnowledge.SELLS, 7, "in_person")
	var b := m.believed(ref(sm), "leather")
	check(is_equal_approx(float(b.price), 8.0) and int(b.sellers) == 2 and int(b.deals) == 1, "believed price: the mean of what it knows (two sellers, one dealing)")
	var lone := m.ask_price(car, "leather", 1)
	var many := m.ask_price(car, "leather", 20)
	check(lone >= many and lone <= int(bd[1]) and many >= int(bd[0]), "an ask falls as stock grows and stays in the band (%d, %d)" % [lone, many])
	for k in 6:
		w.economy.knowledge.learn(ref(car), "npc:%d" % adults(w)[k].id, "leather", EconKnowledge.SELLS, 4, "in_person")
	check(m.ask_price(car, "leather", 1) < lone, "known competing sellers lower the ask (supply)")
	var c := contract(w, sm, job(w, "tanner"), "leather", 4, 9)
	var need := m.need_for(ref(sm), "leather", "contract")
	check(not need.is_empty() and int(m.buyer_ceiling(sm, "leather", need).limit) == roundi(9 * (1.0 - float(m.p("alternatives_discount", 0.1)))),
		"a contract-bound buyer pays at most what the contract pays it (expected benefit), less for knowing two sellers (alternatives)")
	check(m.bid_price(sm, "leather", 9) <= 9 and m.bid_price(sm, "leather", 9) >= int(bd[0]), "the opening bid is under its ceiling and inside the band")
	var fl := m.seller_floor(car, "leather", 1, ref(sm))
	check(fl >= int(bd[0]) and fl <= int(bd[1]), "the seller's floor stays in the band (%d)" % fl)
	w.economy.knowledge.learn(ref(car), ref(job(w, "tanner")), "leather", EconKnowledge.BUYS, int(bd[1]), "dealing")
	check(m.seller_floor(car, "leather", 1, ref(sm)) >= int(bd[1]) - 1, "a better bid the seller knows of raises its floor (opportunity cost)")
	w.contracts.cancel(c, ref(job(w, "tanner")))


# ------------------------------------------------------------------------------------------------ multi-actor shortage
## Design s.16 "Interaction": at least three actor types respond to the same shortage through actual trades. Planks run short;
## a smith (a trade's input), a raw-goods merchant (stock for resale) and a woodcutter owing planks on a CON-01 contract each bid;
## the carpenter, met in turn, sells what it has. Every coin and plank is accounted for; the shortage leaves one bid part open.
func test_shortage_three_actors() -> void:
	var w := new_world()
	var m := w.economy.market
	clear(w, "plank")
	var car := job(w, "carpenter")
	var sm := job(w, "smith")
	var mr := role(w, "merchant_raw")
	var wc := job(w, "woodcutter")
	car.inv.add("plank", 7)
	sm.inv.add("plank", 7)              # wants 3 more
	mr.inv.add("plank", 18)             # wants 2 more
	wc.coins = 80
	var c := contract(w, wc, job(w, "laborer"), "plank", 3, 3)
	var before := ledger(w)
	var bids := {}
	for n: NPC in [wc, sm, mr]:
		var need := m.need_for(ref(n), "plank")
		bids[n.id] = m.post_bid(n, "plank", need) if not need.is_empty() else -1
	check(bids.values().all(func(x): return int(x) >= 0), "three actor types bid for the scarce planks: %s" % str(bids))
	check(w.economy.offers.get_offer(bids[wc.id]).need == "contract" and w.economy.offers.get_offer(bids[sm.id]).need == "input", "the bids answer their needs (a contract, a trade input)")
	var spent := {}
	for n: NPC in [wc, sm, mr]:
		spent[n.id] = n.coins
	var sold0 := car.coins
	for n: NPC in [wc, sm, mr]:
		m.on_encounter(car.id, n.id)
	var buyers := {}
	var total := 0
	for d in m.deals:
		buyers[d.buyer] = w.npc(World.ref_id(str(d.buyer))).job
		total += int(d.total)
		check(int(d.price_each) >= int(EconMarket.band("plank")[0]) and int(d.price_each) <= int(EconMarket.band("plank")[1]), "deal #%d settled inside the band at %d" % [int(d.id), int(d.price_each)])
	check(buyers.size() == 3 and buyers.values().has("smith") and buyers.values().has("merchant") and buyers.values().has("woodcutter"),
		"three actor types bought in actual trades: %s" % str(buyers))
	check(car.inv.count("plank") == 0 and car.coins - sold0 == total, "the carpenter sold all 7 and was paid exactly what the deals say")
	check(ledger(w) == before, "coins and goods conserved through every settlement")
	check(w.economy.reservations.unbacked().is_empty(), "no reservation left unbacked")
	check(w.economy.events.query("", "trade").size() == m.deals.size(), "every deal is a World.trade (one trade event each)")
	var open := w.economy.offers.open_of(ref(mr))
	check(open.size() == 1 and w.economy.offers.remaining(int(open[0].id)) == 1 and int(open[0].filled) == 1,
		"the merchant's bid was part filled; one unit still wanted (the shortage persists, no supply summoned)")
	check(w.economy.offers.get_offer(bids[wc.id]).state == "filled" and w.economy.offers.get_offer(bids[sm.id]).state == "filled", "filled bids are closed")
	check(wc.inv.count("plank") == 3 and w.economy.needs.needs_of(ref(wc)).filter(func(x): return x.kind == "contract").is_empty(), "the contract-bound woodcutter now holds what it owes")
	w.contracts.cancel(c, ref(wc))


# ------------------------------------------------------------------------------------------------ negative paths
func test_negative_paths() -> void:
	var w := new_world()
	var m := w.economy.market
	clear(w, "plank")
	var car := job(w, "carpenter")
	var sm := job(w, "smith")
	sm.inv.add("plank", 4)
	var keep := sm.coins
	sm.coins = 0
	check(m.post_bid(sm, "plank", m.need_for(ref(sm), "plank")) == -1 and int(m.stats.get("bid_unaffordable", 0)) == 1, "no funds: no bid is posted")
	car.inv.add("plank", 5)
	check(m.negotiate(sm, car, "plank", 3).outcome == "no_funds", "no funds: no deal")
	sm.coins = keep
	car.inv.remove("plank", 5)
	check(m.negotiate(sm, car, "plank", 3).outcome == "no_stock", "no seller stock: no deal")
	var wc := job(w, "woodcutter")
	check(m.negotiate(sm, wc, "axe", 1).outcome in ["no_need", "not_for_sale"], "a woodcutter's own axe is not for sale")
	var tool := job(w, "miner")
	tool.inv.remove("pickaxe", 1)
	var pmerch := role(w, "merchant_goods")
	check(m.negotiate(tool, wc, "axe", 1).outcome == "no_need", "no need: no deal")
	check(m.negotiate(sm, sm, "plank", 1).outcome == "no_party", "nobody deals with themselves")
	var stats0 := int(m.stats.get("negotiations", 0))
	m.on_encounter(car.id, sm.id)
	check(int(m.stats.get("negotiations", 0)) == stats0, "an encounter with no offers bargains nothing")
	# expiry
	var id := m.post_bid(sm, "plank", m.need_for(ref(sm), "plank"))
	var o := w.economy.offers.get_offer(id)
	check(id >= 0 and w.economy.reservations.reserved(ref(sm), "coins") == int(o.qty) * int(o.price_each), "a bid reserves its coins")
	var rid := int(o.reservation)
	day_on(w, int(m.p("bid_days", 4)))
	w.economy.offers.expire_due(w.day())
	check(w.economy.offers.get_offer(id).state == "expired" and w.economy.reservations.get_record(rid).state != "held" and w.economy.reservations.reserved(ref(sm), "coins") == 0,
		"expiry: the bid lapses and its coins are free again")
	# no agreement: the seller knows of a dearer buyer, the buyer cannot reach it
	var lth := job(w, "tanner")
	lth.inv.add("leather", 3)
	var c := contract(w, sm, job(w, "laborer"), "leather", 2, 5)
	w.economy.knowledge.learn(ref(lth), ref(job(w, "tanner", 1)), "leather", EconKnowledge.BUYS, 10, "dealing")
	var before := ledger(w)
	var res := m.negotiate(sm, lth, "leather", 2)
	check(res.outcome == "no_agreement" and res.rounds == int(m.p("max_rounds", 3)), "limited counteroffers: after %d rounds no deal (floor above the buyer's ceiling)" % int(res.rounds))
	check(w.economy.knowledge.get_entry(ref(sm), ref(lth), "leather", EconKnowledge.SELLS).latest == "in_person", "both learned the other's last quote in the negotiation (in person)")
	check(ledger(w) == before, "a failed negotiation moved no coin and no good")
	w.contracts.cancel(c, ref(sm))


# ------------------------------------------------------------------------------------------------ opinion
## Owner rule 2026-10-26 on the live path: the same strong dislike of the seller, the same moderate need: some buyers refuse,
## others deal (personality); in great need more of them deal (necessity outweighs dislike); without the dislike more deal than
## with it. No assertion that a particular person deals.
func test_opinion_weighed() -> void:
	var w := new_world()
	var m := w.economy.market
	check(w.judgment != null, "the shared judgment store is attached (Build 19 default)")
	clear(w, "plank")
	var car := job(w, "carpenter")
	car.inv.add("plank", 400)
	var sm := job(w, "smith")
	var outcome := func(need_planks: int, dislike: bool) -> Dictionary:
		var out := {}
		for i in 40:
			var c := clone(w, sm, 300000 + i + (need_planks * 1000) + (500 if dislike else 0))
			c.coins = 300
			c.inv.remove("plank", c.inv.count("plank"))
			c.inv.add("plank", need_planks)
			if dislike:
				w.judgment.set_ledger(c.id, car.id, 0, 40000)
			var r := m.negotiate(c, car, "plank", 1)
			out[r.outcome] = int(out.get(r.outcome, 0)) + 1
		return out
	var mild_dis: Dictionary = outcome.call(8, true)
	var great_dis: Dictionary = outcome.call(0, true)
	var mild_neutral: Dictionary = outcome.call(8, false)
	print("  moderate need, disliked seller: ", mild_dis, " | great need, disliked: ", great_dis, " | moderate need, neutral: ", mild_neutral)
	check(int(mild_dis.get("buyer_refused", 0)) > 0 and int(mild_dis.get("settled", 0)) > 0, "same dislike, same circumstances: some refuse, some deal (personality)")
	check(int(great_dis.get("settled", 0)) > int(mild_dis.get("settled", 0)), "in great need more deal with the disliked seller (necessity outweighs the dislike)")
	check(int(mild_neutral.get("settled", 0)) > int(mild_dis.get("settled", 0)), "without the dislike more deal than with it (opinion is weighed)")
	check(not FileAccess.get_file_as_string("res://scripts/core/economy/econ_market.gd").contains("regard >=") and not FileAccess.get_file_as_string("res://scripts/core/economy/econ_market.gd").contains("disposition <"),
		"no reputation cutoff in the market code")


# ------------------------------------------------------------------------------------------------ partial and duplicate fills
func test_partial_and_duplicate_fills() -> void:
	var w := new_world()
	var m := w.economy.market
	var of := w.economy.offers
	clear(w, "plank")
	var car := job(w, "carpenter")
	car.inv.add("plank", 5)
	var a := of.post(EconOffers.ASK, ref(car), "plank", 5, 2, w.day() + 3, "", "market")
	check(a.ok and w.economy.reservations.reserved(ref(car), "plank") == 5, "an ask reserves the goods it offers")
	var sm := job(w, "smith")
	sm.inv.add("plank", 7)
	var mr := role(w, "merchant_raw")
	var before := ledger(w)
	var b1 := m.post_bid(sm, "plank", m.need_for(ref(sm), "plank"))
	var r1 := m.negotiate(sm, car, "plank", of.remaining(b1), b1, int(a.id))
	check(r1.outcome == "settled" and int(r1.qty) == 3 and of.remaining(int(a.id)) == 2 and int(of.get_offer(int(a.id)).filled) == 3, "a partial fill: 3 of the ask's 5, 2 still offered")
	check(w.economy.reservations.reserved(ref(car), "plank") == 2 and car.inv.count("plank") == 2, "the ask's reservation shrank to what it still offers")
	check(not of.record_fill(int(a.id), 3) and of.remaining(int(a.id)) == 2, "a fill beyond what remains is refused (no duplicate fill)")
	var dup := m._settle({"rounds": 0, "ok": false, "deal": {}}, sm, car, "plank", 1, 2, b1, int(a.id), "test")
	check(dup.outcome == "cannot_perform" and m.deals.size() == 1, "settling a filled bid again does nothing")
	var b2 := m.post_bid(mr, "plank", m.need_for(ref(mr), "plank"))
	var r2 := m.negotiate(mr, car, "plank", 10, b2, int(a.id))
	check(r2.outcome == "settled" and int(r2.qty) == 2 and of.get_offer(int(a.id)).state == "filled", "the rest fills the ask; it closes")
	check(m.deals.size() == 2 and int(m.deals[0].id) != int(m.deals[1].id), "two deals, two ids")
	check(ledger(w) == before and w.economy.reservations.unbacked().is_empty(), "conserved; nothing unbacked")
	m._busy = true
	check(m._settle({"rounds": 0, "ok": false, "deal": {}}, mr, car, "plank", 1, 2, -1, -1, "test").outcome == "cannot_perform", "no settlement while another is under way (atomic)")
	m._busy = false


# ------------------------------------------------------------------------------------------------ adaptive review
func test_review_adaptive() -> void:
	var w := new_world()
	var m := w.economy.market
	var of := w.economy.offers
	clear(w, "leather")
	var sm := job(w, "smith")
	var c := contract(w, sm, job(w, "laborer"), "leather", 3, 10, 9)
	var need := m.need_for(ref(sm), "leather", "contract")
	var ceiling := int(m.buyer_ceiling(sm, "leather", need).limit)
	var id := m.post_bid(sm, "leather", need)
	var prices := [int(of.get_offer(id).price_each)]
	for k in 6:
		day_on(w)
		m.review(w.day())
		prices.append(int(of.get_offer(id).price_each))
	print("  unmet bid over days: ", prices, " ceiling ", ceiling)
	var rising := true
	for i in range(1, prices.size()):
		rising = rising and prices[i] >= prices[i - 1]
	check(rising and prices[-1] <= ceiling and prices[-1] > prices[0], "an unmet bid rises toward its ceiling, never past it")
	check(int(of.get_offer(id).revisions) <= int(m.p("max_revisions", 3)), "at most max_revisions price moves (no raise until supply appears)")
	check(w.economy.reservations.reserved(ref(sm), "coins") == of.remaining(id) * int(of.get_offer(id).price_each), "the bid's coins are reserved at its current price")
	sm.inv.add("leather", 3)
	day_on(w)
	m.review(w.day())
	check(of.get_offer(id).state == "withdrawn" and int(m.stats.get("bid_withdrawn_need_met", 0)) == 1, "the need met, the bid is withdrawn")
	w.contracts.cancel(c, ref(sm))
	# an unsold ask falls toward its floor and no lower
	var tn := job(w, "tanner")
	tn.inv.add("leather", 10)
	var aid := int(of.post(EconOffers.ASK, ref(tn), "leather", 6, int(EconMarket.band("leather")[1]), w.day() + 20, "", "market").id)
	var fl := m.seller_floor(tn, "leather", 6, "")
	var ap := [int(of.get_offer(aid).price_each)]
	for k in 5:
		day_on(w)
		m.review(w.day())
		ap.append(int(of.get_offer(aid).price_each))
	print("  unsold ask over days: ", ap, " floor ", fl)
	check(ap[-1] < ap[0] and ap.all(func(x): return int(x) >= fl), "an unsold ask falls toward its floor, never under it (prices may fall)")
	tn.inv.remove("leather", 8)
	day_on(w)
	m.review(w.day())
	check(of.get_offer(aid).state == "open" and of.remaining(aid) == 2 and w.economy.reservations.unbacked().is_empty(), "goods gone by other means: the ask is cut to what is held")


# ------------------------------------------------------------------------------------------------ knowledge: local, word of mouth
func test_knowledge_local_and_word_of_mouth() -> void:
	var w := new_world()
	var m := w.economy.market
	var k := w.economy.knowledge
	var car := job(w, "carpenter")
	var sm := job(w, "smith")
	var fm := job(w, "farmer")
	var hn := job(w, "hunter")
	car.inv.add("plank", 4)
	var a := w.economy.offers.post(EconOffers.ASK, ref(car), "plank", 4, 3, w.day() + 3, "", "market")
	check(k.knowers_of(ref(car), "plank") == [ref(car)], "posting tells nobody but the poster (no offer board)")
	m.on_encounter(car.id, fm.id)
	check(k.knows(ref(fm), ref(car), "plank", EconKnowledge.SELLS) and k.get_entry(ref(fm), ref(car), "plank", EconKnowledge.SELLS).source == "in_person", "meeting the poster, a villager sees the offer (in person)")
	check(not k.knows(ref(sm), ref(car), "plank", EconKnowledge.SELLS), "someone who never met the carpenter does not know")
	day_on(w, 3)
	m.on_meeting(fm.id, sm.id)
	var e := k.get_entry(ref(sm), ref(car), "plank", EconKnowledge.SELLS)
	check(not e.is_empty() and e.latest == "word_of_mouth" and e.via == ref(fm) and int(e.seen_day) == w.day() - 3, "word of mouth: the smith heard it from the farmer, with its age")
	var rel := k.reliability(e)
	check(rel > 0.0 and rel < k.reliability(k.get_entry(ref(fm), ref(car), "plank", EconKnowledge.SELLS)), "heard news is believed less than seen news (trust in the teller, from the shared model) (%.3f)" % rel)
	m.on_meeting(sm.id, hn.id)
	check(not k.knows(ref(hn), ref(car), "plank", EconKnowledge.SELLS), "hearsay is not retold: only what a villager learned firsthand passes on")
	w.judgment.set_ledger(fm.id, hn.id, 0, 90000)
	m.on_meeting(fm.id, hn.id)
	check(not w.judgment.would_tell(fm.id, hn.id) and not k.knows(ref(hn), ref(car), "plank", EconKnowledge.SELLS), "the gossip's own rule: the farmer, who strongly dislikes the hunter, tells it nothing")
	check(not k.learn(ref(hn), ref(car), "plank", "sells", 3, "notice") and not k.learn(ref(hn), ref(car), "plank", "sells", 3, "rumour"), "no notice board, no rumour engine")
	k.learn(ref(sm), ref(car), "plank", EconKnowledge.SELLS, 2, "in_person")
	check(not k.learn(ref(sm), ref(car), "plank", EconKnowledge.SELLS, 9, "word_of_mouth", -1, "", w.day() - 1, ref(fm)) and int(k.get_entry(ref(sm), ref(car), "plank", EconKnowledge.SELLS).price_each) == 2,
		"older hearsay does not overwrite fresher firsthand knowledge")
	var big := 0
	for i in 60:
		if k.learn(ref(hn), "npc:%d" % adults(w)[i % adults(w).size()].id, "item_%d" % i, EconKnowledge.SELLS, 1, "word_of_mouth", -1, "", w.day(), ref(fm)):
			big += 1
	check(k.known_by(ref(hn)).filter(func(x): return x.latest == "word_of_mouth").size() == int(k.max_hearsay) and k.forgotten > 0, "hearsay is bounded per villager; the oldest is forgotten")


# ------------------------------------------------------------------------------------------------ CON-01 procurement
## OD-LE-03 (D02): a buyer offers a price per unit for a quantity of ANY tradable product through CON-01 (here planks, which the
## carpenter saws from logs: no mining or farming), with counteroffers inside its ceiling; the bid's units are committed, not filled.
func test_procurement_contract() -> void:
	var w := new_world()
	var m := w.economy.market
	var of := w.economy.offers
	clear(w, "plank")
	var car := job(w, "carpenter")
	var sm := job(w, "smith")
	sm.inv.add("plank", 4)
	car.inv.add("log", 6)
	var before := ledger(w)
	var id := m.post_bid(sm, "plank", m.need_for(ref(sm), "plank"))
	var want := of.remaining(id)
	check(m.dialogues(w.day()).is_empty(), "a bid is not taken to anyone the day it is posted")
	day_on(w)
	var none := m.dialogues(w.day())
	check(none.is_empty() and int(m.stats.get("bid_no_known_seller", 0)) == 1, "a buyer who knows no seller waits (it may miss the opportunity)")
	w.economy.knowledge.learn(ref(sm), ref(car), "plank", EconKnowledge.SELLS, 3, "dealing")
	day_on(w)
	var made := m.dialogues(w.day())
	var c: Dictionary = w.contracts.get_contract(int(made[0])) if not made.is_empty() else {}
	check(not c.is_empty() and c.item == "plank" and c.seller == ref(car) and c.buyer == ref(sm) and str(c.route) == "craft", "direct dialogue opened a CON-01 contract for planks (crafted, not mined): %s" % str(c.get("history", [])))
	check(not c.is_empty() and int(c.price_each) >= int(EconMarket.band("plank")[0]) and int(c.price_each) <= int(EconMarket.band("plank")[1]), "at a negotiated price per unit inside the band")
	var o := of.get_offer(id)
	check(not c.is_empty() and int(o.committed) == int(c.qty) and int(o.filled) == 0 and (o.contracts as Array).has(int(c.id)), "the bid's units are committed to the contract (a commitment, not a sale)")
	check(not c.is_empty() and int(c.reserved) == int(c.qty) * int(c.price_each) and ledger(w) == before, "the contract escrows the buyer's coins; nothing made or lost")
	check(w.economy.reservations.unbacked().is_empty(), "the bid's coin reservation never doubled the contract's escrow")
	# a counter inside the ceiling is met; one beyond it is not
	var tn := job(w, "tanner")
	var ld := job(w, "laborer")
	ld.coins = 200
	var cc := contract(w, ld, job(w, "farmer"), "leather", 2, int(EconMarket.band("leather")[1]))
	before = ledger(w)
	var id2 := m.post_bid(ld, "leather", m.need_for(ref(ld), "leather", "contract"))
	tn.inv.add("leather", 4)
	before = ledger(w)
	of.revise(id2, int(EconMarket.band("leather")[0]))
	var r := m.procure(id2, ld, tn)
	print("  procurement with counter: ", r)
	check(r.outcome in ["contract", "counter_beyond_limit", "contract_refused", "buyer_refused"] and (r.outcome != "contract" or int(r.rounds) >= 2), "a low offer meets a counteroffer, met inside the ceiling or refused beyond it (%s, %d rounds)" % [r.outcome, int(r.rounds)])
	check(ledger(w) == before, "still conserved")
	w.contracts.cancel(cc, ref(ld))


# ------------------------------------------------------------------------------------------------ renegotiation
func test_renegotiation() -> void:
	var w := new_world()
	var m := w.economy.market
	clear(w, "plank")
	var car := job(w, "carpenter")
	var sm := job(w, "smith")
	sm.inv.add("plank", 4)            # still wants planks
	car.inv.add("log", 6)
	car.inv.remove("plank", car.inv.count("plank"))
	var c := contract(w, car, sm, "plank", 4, 3, 1)       # due today, nothing in hand, the carpenter can saw them
	var before := ledger(w)
	var esc := int(c.reserved)
	var done := m.renegotiate(w.day())
	print("  renegotiation (extend): ", done, " ", c.history[-1])
	check(done.size() == 1 and str(done[0][1]) == "extend" and int(c.deadline_day) > w.day() and int(c.reserved) == esc, "extension: the deadline moves, the escrow stays (OD-LE-13)")
	check(ledger(w) == before, "conserved")
	# partial delivery: two delivered, one held, no more to be had
	var c2 := contract(w, car, job(w, "smith", 1), "plank", 6, 3, 1)
	car.inv.add("plank", 2)
	w.contracts.deliver(c2, 2, job(w, "smith", 1).inv)
	car.inv.add("plank", 1)
	car.inv.remove("log", car.inv.count("log"))
	var before2 := ledger(w)
	var coins_b := job(w, "smith", 1).coins
	done = m.renegotiate(w.day())
	print("  renegotiation (partial): ", done)
	var amended := done.any(func(x): return int(x[0]) == int(c2.id) and str(x[1]) == "partial")
	check(amended and (int(c2.qty) == 3 and int(c2.reserved) == 3 and job(w, "smith", 1).coins == coins_b + 9), "partial delivery: the quantity cut to delivered and held, the rest of the escrow back to the buyer")
	check(ledger(w) == before2, "conserved")
	# cancellation when the buyer no longer needs the goods
	var c3 := contract(w, car, role(w, "merchant_raw"), "plank", 2, 3, 1)
	car.inv.remove("plank", car.inv.count("plank"))
	role(w, "merchant_raw").inv.add("plank", 40)
	m.renegotiate(w.day())
	check(str(c3.state) == "cancelled" and str(c3.history[-1].by) == c3.buyer and int(c3.reserved) == 0, "a buyer with no need left cancels on the last day instead of letting it lapse (no fee, no penalty)")
	# amend directly: a dearer price sets more aside from the buyer, refused when it cannot pay
	var c4 := contract(w, car, sm, "plank", 2, 3, 3)
	sm.coins = int(c4.reserved) * 0
	check(w.contracts.amend(c4, ref(car), 2, 4, 0) != "" and int(c4.price_each) == 3, "a dearer price the buyer cannot set aside is refused; nothing changes")
	sm.coins = 200
	var t0 := w.total_coins()
	check(w.contracts.amend(c4, ref(car), 2, 4, 0) == "" and int(c4.reserved) == 8 and w.total_coins() == t0, "changed payment: the escrow follows the new price; coins conserved")
	check(w.contracts.amend(c4, ref(sm), 1, 4, 0) == "" and int(c4.reserved) == 4, "either party records an agreed change")
	check(w.contracts.amend(c4, "npc:999", 1, 4, 0) != "", "only the parties can change a contract")


# ------------------------------------------------------------------------------------------------ dawn driver
func test_dawn_driver() -> void:
	var w := new_world()
	var m := w.economy.market
	for n: NPC in adults(w):
		w.economy.needs.mark(ref(n))           # as trades and dawns mark them in play
	var before := ledger(w)
	w.economy.dawn(w.day())
	var bids := 0
	var asks := 0
	for id in w.economy.offers.records:
		var o: Dictionary = w.economy.offers.records[id]
		if o.side == EconOffers.BID:
			bids += 1
		else:
			asks += 1
	print("  first dawn: %d bids, %d asks; stats %s" % [bids, asks, str(m.stats)])
	check(bids > 0 and asks > 0, "a dawn posts bids from needs and asks from traders' stock")
	check(int(m.stats.get("asks_posted", 0)) <= int(m.p("ask_sellers_per_dawn", 6)) * int(m.p("ask_items_per_seller", 3)), "asks bounded by the dawn budget")
	check(ledger(w) == before and w.economy.reservations.unbacked().is_empty(), "posting moves nothing")
	var t0 := Time.get_ticks_usec()
	for i in 2000:
		m.on_encounter(adults(w)[i % 7].id, adults(w)[(i + 3) % 7 + 10].id)
	print("  timing: %.1f us per encounter" % (float(Time.get_ticks_usec() - t0) / 2000.0))
	check(ledger(w) == before and w.economy.reservations.unbacked().is_empty(), "encounters at the dawn's offers settle only conserved trades (%d deals)" % m.deals.size())


# ------------------------------------------------------------------------------------------------ determinism
func scenario(seed: int) -> String:
	var w := new_world(seed)
	var m := w.economy.market
	for n: NPC in adults(w):
		w.economy.needs.mark(ref(n))
	w.economy.dawn(w.day())
	for i in 300:
		var ad := adults(w)
		m.on_encounter(ad[(i * 7) % ad.size()].id, ad[(i * 13 + 5) % ad.size()].id)
		if i % 50 == 49:
			day_on(w)
			w.economy.dawn(w.day())
	for i in 40:
		var ad := adults(w)
		m.on_meeting(ad[i % ad.size()].id, ad[(i + 9) % ad.size()].id)
	return JSON.stringify(w.economy.to_dict()) + JSON.stringify([w.total_coins(), Census.goods(w)])


func test_determinism() -> void:
	var a := scenario(3)
	var b := scenario(3)
	check(a == b, "same seed, same operations: identical market, knowledge, offers and ledger")
	check(scenario(4) != a, "another seed differs")
	check(a.contains("\"negotiations\"") and a.contains("\"bids_posted\""), "the scenario posted bids and bargained (the market saved its state)")
	EconomyFoundation.set_override(cfg_on(true))
	var x := World.new()
	x.setup(VillageMap.load_default(), 5)
	var y := World.new()
	y.setup(VillageMap.load_default(), 5)
	var steps := int(1440.0 / float(GameData.b("game_minutes_per_second")) / 0.5)
	for i in steps:
		x.update(0.5)
		y.update(0.5)
	check(JSON.stringify(x.to_dict()) == JSON.stringify(y.to_dict()), "a full day with the market driving, twice: byte-identical saves")
	print("  a driven day: deals %d, stats %s" % [x.economy.market.deals.size(), str(x.economy.market.stats)])
	check(x.economy.events.ordered(), "events in order")


# ------------------------------------------------------------------------------------------------ persistence
func test_save_mid_negotiation() -> void:
	var w := new_world()
	var m := w.economy.market
	var of := w.economy.offers
	clear(w, "plank")
	var car := job(w, "carpenter")
	var sm := job(w, "smith")
	sm.inv.add("plank", 4)
	car.inv.add("plank", 3)
	car.inv.add("log", 4)
	var bid := m.post_bid(sm, "plank", m.need_for(ref(sm), "plank"))
	var ask := int(of.post(EconOffers.ASK, ref(car), "plank", 3, 3, w.day() + 5, "", "market").id)
	m.negotiate(sm, car, "plank", 2, bid, ask)
	day_on(w)
	m.review(w.day())
	w.economy.knowledge.learn(ref(sm), ref(car), "plank", EconKnowledge.SELLS, 3, "dealing")
	w.economy.market.on_meeting(sm.id, job(w, "farmer").id)
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	check(d.has("economy") and d.economy.has("market") and d.economy.has("offers"), "saved: the economy key carries the market and the open offers")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	check(JSON.stringify(w2.economy.to_dict()) == JSON.stringify(w.economy.to_dict()), "round trip: market, offers, knowledge identical")
	var r1 := m.negotiate(sm, car, "plank", 1, bid, ask)
	var r2 := w2.economy.market.negotiate(w2.npc(sm.id), w2.npc(car.id), "plank", 1, bid, ask)
	check(r1.outcome == r2.outcome and int(r1.price_each) == int(r2.price_each) and JSON.stringify(w.economy.to_dict()) == JSON.stringify(w2.economy.to_dict()),
		"a negotiation continued after load ends exactly as without the save (%s)" % r1.outcome)
	# an LE-01 save: offers without the LE-02 fields, no market section
	var old: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	old.economy.erase("market")
	for o in old.economy.get("offers", {}).get("records", []):
		for k in ["min_lot", "committed", "contracts", "revisions", "reviewed_day", "need", "seen_filled", "dialogue_day"]:
			o.erase(k)
	for e in old.economy.get("knowledge", {}).get("entries", []):
		e.erase("latest")
		e.erase("via")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), old)
	check(w3.economy != null and w3.economy.market.is_empty() and w3.economy.offers.records.size() == of.records.size(), "an LE-01 economy section loads (market empty, offers kept)")
	check(w3.economy.offers.remaining(bid) == of.get_offer(bid).qty - of.get_offer(bid).filled, "LE-01 offers read with nothing committed")
	EconomyFoundation.set_override({})
	var w4 := World.new()
	w4.load_dict(VillageMap.load_default(), d)
	check(w4.economy == null and JSON.stringify(w4.to_dict().economy) == JSON.stringify(d.economy), "switched off: the market section is carried untouched (D2)")


# ------------------------------------------------------------------------------------------------ the switch
func fingerprint(w: World) -> String:
	var d := w.to_dict()
	d.erase("economy")
	return JSON.stringify(d)


func test_switch() -> void:
	var f: Dictionary = shipped()
	check(f.enabled == false and f.market.drive == true, "shipped: the economy off (activation is the owner's); its market would drive when switched on")
	EconomyFoundation.set_override({})
	var off := World.new()
	off.setup(VillageMap.load_default(), 2)
	EconomyFoundation.set_override(cfg_on(false))
	var quiet := World.new()
	quiet.setup(VillageMap.load_default(), 2)
	var steps := int(1440.0 / float(GameData.b("game_minutes_per_second")) / 0.5)
	for i in steps:
		off.update(0.5)
		quiet.update(0.5)
	check(off.economy == null and not off.to_dict().has("economy"), "off: nothing built, no save key")
	check(fingerprint(off) == fingerprint(quiet), "a day: economy on with the market not driving is identical to off (the hooks change nothing)")
	check(quiet.economy.market.is_empty() and quiet.economy.offers.is_empty(), "not driving: no offers, no deals")
