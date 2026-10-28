class_name EconMarket
extends RefCounted
## Expansion 20 (Living Economy), LE-02: adaptive bids, asks, negotiation and settlement (design s.5; gate "Ledger-safe
## multi-actor trades"). DISABLED and isolated: built by EconomyFoundation only while game/data/economy.json "enabled" is true,
## and it acts only with "market": {"drive": true}. Developer note: docs/expansion20/LE02_IMPLEMENTATION.md.
##
## Owner policies implemented (no others):
##   OD-LE-02   combined market pricing: supply, demand, scarcity and completed transactions inform asking prices; buyers and
##              sellers negotiate actual deals with limited counteroffers, each with their own willingness to compromise
##              (urgency, alternatives, experience, personality); no guaranteed deal.
##   OD-LE-02B  (D01) offers are local to real encounters, stalls and direct dialogue: an offer is seen by meeting its poster
##              (on_encounter, Relations.share's shared hour), said in a negotiation, or told by someone who knew it.
##   OD-LE-10   (D09) price knowledge from observation, direct offers and the existing gossip (on_meeting, on the judgment
##              store's own meetings), with source, age and trust (EconKnowledge.reliability); may be wrong or stale.
##   OD-LE-03   (D02) existing wage and hiring rules untouched; a buyer may offer a price per unit for a quantity of ANY tradable
##              product through CON-01 (Contracts.propose: the one contract record), negotiated in limited rounds.
##   OD-LE-13   context-sensitive renegotiation on CON-01 (Contracts.amend: partial delivery, extension, changed payment; or
##              the buyer's cancellation); no automatic penalty is added.
##   Owner opinion rule 2026-10-26: whether to deal, with whom and at what terms is weighed by the shared
##              JudgmentWeighting.choose (profiles market_buy, market_sell in judgment.json) with need, price, alternatives,
##              surplus and the chooser's opinion of the other; doing without is a valid result; no reputation cutoff.
##
## The five prices are kept apart (design s.5): reference (believed: what an actor's own knowledge says the item goes for),
## advertised bid and ask (the offers, EconOffers), negotiated (the round's quotes and the agreed price) and settled (the
## deal record, made only after World.trade moved the goods and coins). Every limit stays inside the existing band
## value x [price_min, price_max] (balance.json); a bid rises only toward its own ceiling, by a share of the gap, at most
## max_revisions times, and only while the need lasts (never a fixed raise until supply appears, design s.19); nothing summons
## supply; an ask falls toward its floor the same way when unsold, and rises only toward bids its poster knows of.
##
## Settlement (atomic, design s.5 "no double-spending and duplicate fills"): every check first (parties alive, the seller holds
## the units, the buyer's coins cover them net of its other reservations and its OD-19 reserve, both offers still have the
## units open), then World.trade (itself all or nothing), then EconOffers.record_fill on each offer (which refuses more than
## remains), then the deal record. Nothing here moves a coin or a good itself. Remote dealing (direct dialogue at dawn) never
## moves goods at a distance: it opens a CON-01 contract whose seller walks the goods over and is paid on delivery.
##
## Event-driven and bounded (design s.14): an encounter costs two index reads when neither has an offer; dawn work is capped
## (posts_per_dawn, ask_sellers_per_dawn, dialogues_per_dawn) with round-robin cursors; reviews wait review_days.
## Deterministic: sorted iteration, ids counting up, no World.rng; personal choices use the shared engine's seeded hashes.

const BID_KINDS := ["contract", "housing", "input", "tool"]     # food stays with the existing household food rule (LE-03)
const PURPOSE := "market"

var f: EconomyFoundation
var w: World
var cfg := {}
var drive := false
var deals: Array = []           # settled transactions, oldest first (bounded keep_deals)
var next_deal := 0
var stats := {}                 # counters (diagnostics; saved)
var bid_cursor := ""            # the last needs-table actor a bid was posted for (round robin)
var ask_cursor := -1            # index into World.npcs of the last seller reviewed for asks (round robin)
var _busy := false
var _jcfg := {}


func _init(found: EconomyFoundation, world: World, cfg_ := {}) -> void:
	f = found
	w = world
	cfg = cfg_
	drive = bool(cfg.get("drive", false))


func p(key: String, default):
	return cfg.get(key, default)


# ---------------------------------------------------------------- prices -------------------
## [lowest, highest] coins a unit within the existing price band (balance.json price_min, price_max x the item's value).
static func band(item: String) -> Array:
	var v := float(GameData.value(item))
	var lo := maxi(1, roundi(v * float(GameData.b("price_min"))))
	return [lo, maxi(lo, roundi(v * float(GameData.b("price_max"))))]


## What `who` believes `item` goes for, from its own knowledge only (never another's): the reliability-weighted mean of the
## prices it knows others deal at (its own offers left out), else the item's value. {price, sellers, buyers, deals, weight,
## best_bid}: known sellers and buyers (supply and demand as it sees them), completed dealings among them, and the best price
## it knows someone bids.
func believed(who: String, item: String) -> Dictionary:
	var sum := 0.0
	var wt := 0.0
	var out := {"price": float(GameData.value(item)), "sellers": 0, "buyers": 0, "deals": 0, "weight": 0.0, "best_bid": -1}
	var floor_r := float(p("min_reliability", 0.25))
	for e in f.knowledge.known_by(who, item):
		if str(e.subject) == who or int(e.price_each) < 0:
			continue
		var r := f.knowledge.reliability(e)
		if r < floor_r:
			continue
		sum += r * float(e.price_each)
		wt += r
		if e.side == EconKnowledge.SELLS:
			out.sellers += 1
		else:
			out.buyers += 1
			out.best_bid = maxi(int(out.best_bid), int(e.price_each))
		if str(e.latest) == "dealing":
			out.deals += 1
	if wt > 0.0:
		out.price = sum / wt
		out.weight = wt
	return out


## The seller's advertised ask for a unit: the existing scarcity rule (World.sell_price_at: dearer as its own stock runs low)
## with the supply and demand it knows of (known other sellers lower it, known buyers raise it; supply_weight, demand_weight,
## at most knowledge_cap each), blended with the prices it has seen paid (txn_weight), never under its floor, inside the band.
func ask_price(seller: NPC, item: String, stock: int, floor_ := -1) -> int:
	var b := believed(World.npc_ref(seller.id), item)
	var cap := int(p("knowledge_cap", 5))
	var m := clampf(1.5 - 0.05 * stock - float(p("supply_weight", 0.05)) * mini(int(b.sellers), cap) + float(p("demand_weight", 0.05)) * mini(int(b.buyers), cap),
			float(GameData.b("price_min")) + 0.2, float(GameData.b("price_max")))
	var price := float(GameData.value(item)) * m
	if float(b.weight) > 0.0:
		price = lerpf(price, float(b.price), float(p("txn_weight", 0.5)))
	var bd := band(item)
	return clampi(maxi(roundi(price), floor_), int(bd[0]), int(bd[1]))


## The least the seller takes a unit for (design s.5: labour and material cost, household needs, other bids, stock, opportunity
## cost): the band's floor or what the cheapest recipe it can make the item by costs in inputs at their value, whichever is
## more; at least the best bid it knows of elsewhere (opportunity); times CON-01's household factors (needy_factor when its
## purse is at or under its OD-19 reserve, else comfortable_factor), less the friend's price for a friend, partner or kin
## (Relations friend_price, as CON-01's price_terms), plus scarcity_floor when the sale would leave it under scarce_left.
func seller_floor(seller: NPC, item: String, qty: int, buyer_ref: String) -> int:
	var bd := band(item)
	var base := float(bd[0])
	for r in w.contracts._recipes_for(item):
		if w.brain._can_make(seller, r):
			var rec: Dictionary = GameData.recipes[r]
			var cost := 0.0
			for i in rec["in"]:
				cost += float(GameData.value(i)) * float(rec["in"][i])
			base = maxf(base, cost / maxf(1.0, float(rec.out[item])))
			break
	var kb := int(believed(World.npc_ref(seller.id), item).best_bid)
	if kb > 0:
		base = maxf(base, float(kb))
	var cc := Contracts.cfg()
	var factor := float(cc.needy_factor) if w.spendable(seller) <= 0 else float(cc.comfortable_factor)
	var rid := Contracts.rel_id(buyer_ref)
	if rid != -1 and w.contracts.close_to(seller, rid):
		factor -= float(Relations.cfg().friend_price)
	if seller.inv.count(item) - qty < int(p("scarce_left", 2)):
		factor += float(p("scarcity_floor", 0.1))
	return clampi(roundi(base * factor), int(bd[0]), int(bd[1]))


## The most the buyer pays a unit, from what the need is worth to it (design s.5: expected benefit, urgency, alternatives,
## contract obligations): a contract's own price (it will be paid no more for the units it owes), a trade's tool the band's top,
## an input or a housing material between the value and the band's top by urgency; less alternatives_discount when it knows two
## or more sellers. {limit, urgency 0..1}. Cash is not here (cash_for).
func buyer_ceiling(buyer: NPC, item: String, need: Dictionary) -> Dictionary:
	var bd := band(item)
	var v := float(GameData.value(item))
	var u := 0.5
	var benefit := v
	match str(need.get("kind", "")):
		"contract":
			var days := maxi(0, int(need.deadline) - w.day())
			u = clampf(1.0 - float(days) / float(Contracts.cfg().max_days), 0.0, 1.0)
			benefit = INF
			for c in w.contracts.open_of(World.npc_ref(buyer.id), "seller"):
				if str(c.item) == item:
					benefit = minf(benefit, float(c.price_each))
			if benefit == INF:
				benefit = v
		"tool":
			u = 1.0
			benefit = float(bd[1])
		"housing":
			u = float(p("housing_urgency", 0.75))
			benefit = v * lerpf(1.0, float(GameData.b("price_max")), u)
		_:
			u = clampf(float(need.get("shortfall", 0.0)) / maxf(1.0, float(need.get("target", 1.0))), 0.0, 1.0)
			benefit = v * lerpf(1.0, float(GameData.b("price_max")), u)
	if int(believed(World.npc_ref(buyer.id), item).sellers) >= 2:
		benefit *= 1.0 - float(p("alternatives_discount", 0.1))
	var lim := roundi(benefit)
	return {"limit": mini(lim, int(bd[1])) if lim >= int(bd[0]) else lim, "urgency": u}


## The buyer's opening bid: what it believes the item goes for, times bid_open, inside [band floor, ceiling].
func bid_price(buyer: NPC, item: String, ceiling: int) -> int:
	var bd := band(item)
	return mini(maxi(int(bd[0]), roundi(float(believed(World.npc_ref(buyer.id), item).price) * float(p("bid_open", 0.85)))), ceiling)


## Coins the buyer may still spend: above its OD-19 reserve (World.spendable) and net of what its other offers have reserved
## (its bid `own` is not counted against itself).
func cash_for(buyer: NPC, own_bid := -1) -> int:
	var ref := World.npc_ref(buyer.id)
	var own := 0
	if own_bid >= 0:
		var o := f.offers.get_offer(own_bid)
		var rid := int(o.get("reservation", -1))
		if rid >= 0:
			own = int(f.reservations.get_record(rid).get("qty", 0))
	return maxi(0, w.spendable(buyer) - f.reservations.reserved(ref, EconReservations.COINS) + own)


## Units the seller would sell of `item` from what it holds: none of its trade's tools (NPCBrain.keeps) or its trade's own
## materials (a merchant excepted: World.local_supply's rule), and not what contracts or other claims hold (available).
func for_sale(seller: NPC, item: String, own_ask := -1) -> int:
	if w.brain.keeps(seller, item):
		return 0
	if NPCBrain.BUYS.get(w.brain.buy_role(seller), {}).has(item) and seller.job != "merchant":
		return 0
	var ref := World.npc_ref(seller.id)
	var n := f.reservations.available(ref, item) - maxi(0, w.brain.reserve(seller, item) - w.contracts.held_for(seller, item))
	if own_ask >= 0:
		n += f.offers.remaining(own_ask)
	return maxi(0, n)


## A trader's willingness to give ground in one round (OD-LE-02: individual willingness to compromise): concession, spread per
## person by the shared personality weighting (JudgmentWeighting.trait_weight), more with urgency (urgency_concession), less
## with Trading experience (its price_bonus).
func concession(n: NPC, urgency: float) -> float:
	var base := JudgmentWeighting.trait_weight(_judgment_cfg(), w.judgment.world_seed if w.judgment != null else 0, n.id, "concession",
			roundi(float(p("concession", 0.35)) * 1000.0), w.judgment)
	var c := float(base) / 1000.0 + urgency * float(p("urgency_concession", 0.3)) - Skills.value(n, "trading", "price_bonus")
	return clampf(c, 0.05, 0.9)


# ---------------------------------------------------------------- choices (opinion as one factor) --
func _judgment_cfg() -> Dictionary:
	if w.judgment != null:
		return w.judgment.cfg
	if _jcfg.is_empty():
		_jcfg = JudgmentStore.default_cfg()
	return _jcfg


## One yes-or-forgo choice through the shared engine: `chooser` weighs dealing with `other_ref` (its opinion read by the engine
## from the judgment store) against doing without. Returns the engine's result.
func _weigh(chooser: NPC, profile: String, other_ref: String, factors: Dictionary, key: Array) -> Dictionary:
	var cand := {"id": "deal", "counterparty": f.actors.judged_person(other_ref), "factors": factors}
	return JudgmentWeighting.choose(w.judgment, _judgment_cfg(), chooser.id, profile, [cand], key)


static func _milli(x: float) -> int:
	return clampi(roundi(x * 100000.0), 0, 100000)


# ---------------------------------------------------------------- negotiation ----------------
## The buyer's need for `item` answered by a bid (the first of BID_KINDS, or `kind`), from the need record; {} when none.
func need_for(ref: String, item: String, kind := "") -> Dictionary:
	if f.actors.kind(ref) != "npc":
		return {}
	for x in f.needs.needs_of(ref):
		if str(x.item) == item and int(x.qty) > 0 and (str(x.kind) == kind if kind != "" else str(x.kind) in BID_KINDS):
			return x
	var n: NPC = w.npc(World.ref_id(ref))
	if n != null and n.household >= 0 and w.construction.responsible_adult(n.household) == n:
		for x in f.needs.needs_of(World.hh_ref(n.household)):
			if str(x.kind) == "housing" and str(x.item) == item and int(x.qty) > 0:
				return x
	return {}


## Buyer and seller meet and bargain over up to `want` units (OD-LE-02). {ok, outcome, qty, price_each, rounds, quotes, deal}.
## outcome: "settled" (traded), "agreed" (settle false), or why not: no_party, no_need, not_for_sale, no_stock, lot, no_funds,
## no_agreement, buyer_refused, seller_refused, cannot_perform. Both learn what was said (in_person).
func negotiate(buyer: NPC, seller: NPC, item: String, want: int, bid_id := -1, ask_id := -1, via := "encounter", settle := true) -> Dictionary:
	var out := {"ok": false, "outcome": "", "qty": 0, "price_each": 0, "rounds": 0, "quotes": [], "deal": {}}
	if buyer == null or seller == null or buyer == seller or not buyer.alive or not seller.alive or buyer.role != "adult" or seller.role != "adult":
		return _out(out, "no_party")
	var br := World.npc_ref(buyer.id)
	var sr := World.npc_ref(seller.id)
	var bid := f.offers.get_offer(bid_id) if bid_id >= 0 else {}
	var ask := f.offers.get_offer(ask_id) if ask_id >= 0 else {}
	if (bid_id >= 0 and (bid.is_empty() or bid.state != EconOffers.OPEN)) or (ask_id >= 0 and (ask.is_empty() or ask.state != EconOffers.OPEN)):
		return _out(out, "cannot_perform")
	var need := need_for(br, item, str(bid.get("need", "")))
	if need.is_empty():
		return _out(out, "no_need")
	var units := for_sale(seller, item, ask_id)
	if units <= 0:
		return _out(out, "not_for_sale" if f.actors.count(sr, item) > 0 else "no_stock")
	var lot := maxi(int(bid.get("min_lot", 1)), int(ask.get("min_lot", 1)))
	var q := mini(want, units)
	if bid_id >= 0:
		q = mini(q, f.offers.remaining(bid_id))
	if ask_id >= 0:
		q = mini(q, f.offers.remaining(ask_id))
	if q < lot:
		return _out(out, "lot")
	var ce := buyer_ceiling(buyer, item, need)
	var ceiling := int(ce.limit)
	var cash := cash_for(buyer, bid_id)
	if cash < lot * int(band(item)[0]):
		return _out(out, "no_funds")
	var floor_ := seller_floor(seller, item, q, br)
	var b := mini(int(bid.price_each) if bid_id >= 0 else bid_price(buyer, item, ceiling), ceiling)
	var s := maxi(int(ask.price_each) if ask_id >= 0 else ask_price(seller, item, seller.inv.count(item), floor_), floor_)
	out.quotes.append([b, s])
	var agreed := -1
	if b >= s:
		agreed = b if bid_id >= 0 and ask_id < 0 else s           # the standing offer's terms are taken
	else:
		var cb := concession(buyer, float(ce.urgency))
		var cs := concession(seller, float(JudgmentLive.coin_need(seller)) / 100000.0)
		while int(out.rounds) < int(p("max_rounds", 3)):
			out.rounds = int(out.rounds) + 1
			b = mini(ceiling, b + ceili(float(maxi(0, ceiling - b)) * cb))
			if b >= s:
				agreed = s
				out.quotes.append([b, s])
				break
			s = maxi(floor_, s - ceili(float(maxi(0, s - floor_)) * cs))
			out.quotes.append([b, s])
			if s <= b:
				agreed = b
				break
	f.knowledge.learn(br, sr, item, EconKnowledge.SELLS, s, "in_person", ask_id, f.actors.location(sr))
	f.knowledge.learn(sr, br, item, EconKnowledge.BUYS, b, "in_person", bid_id, f.actors.location(br))
	_stat("negotiations")
	if agreed < 0:
		return _out(out, "no_agreement", br, sr, item)
	q = mini(q, cash / maxi(1, agreed))
	if q < lot:
		return _out(out, "no_funds", br, sr, item)
	var bd := band(item)
	var key := [w.day(), item.hash(), buyer.id, seller.id]
	var known := believed(br, item)
	var bf := {"necessity": _milli(float(ce.urgency)), "price": _milli(float(ceiling - agreed) / float(maxi(1, ceiling - int(bd[0])))),
		"sole_source": 100000 / maxi(1, int(known.sellers))}
	if str(_weigh(buyer, "market_buy", sr, bf, key).chosen) != "deal":
		return _out(out, "buyer_refused", br, sr, item)
	var sf := {"necessity": JudgmentLive.coin_need(seller), "price": _milli(float(agreed - floor_) / float(maxi(1, int(bd[1]) - floor_))),
		"surplus": 100000 if ask_id >= 0 else 50000}
	if str(_weigh(seller, "market_sell", br, sf, key).chosen) != "deal":
		return _out(out, "seller_refused", br, sr, item)
	out.qty = q
	out.price_each = agreed
	if not settle:
		out.ok = true
		return _out(out, "agreed")
	return _settle(out, buyer, seller, item, q, agreed, bid_id, ask_id, via)


func _out(out: Dictionary, outcome: String, br := "", sr := "", item := "") -> Dictionary:
	out.outcome = outcome
	_stat(outcome)
	if br != "" and f.events != null and outcome in ["no_agreement", "buyer_refused", "seller_refused", "no_funds"]:
		f.events.record_at(w.day(), int(fmod(w.minutes, World.DAY)), "note", br, sr, item, 0, 0, "market " + outcome)
	return out


## Atomic settlement: re-check, World.trade, record_fill on each offer, the deal record. Nothing booked unless the trade happened.
func _settle(out: Dictionary, buyer: NPC, seller: NPC, item: String, q: int, price: int, bid_id: int, ask_id: int, via: String) -> Dictionary:
	if _busy:
		return _out(out, "cannot_perform")
	var ok := seller.inv.has(item, q) and buyer.coins >= q * price and buyer.inv.can_add(item) and q * price <= cash_for(buyer, bid_id) \
			and (bid_id < 0 or f.offers.remaining(bid_id) >= q) and (ask_id < 0 or f.offers.remaining(ask_id) >= q)
	if not ok:
		return _out(out, "cannot_perform")
	_busy = true
	ok = w.trade(buyer, seller, item, q, price)
	if ok:
		if ask_id >= 0:
			f.offers.record_fill(ask_id, q)
		if bid_id >= 0:
			f.offers.record_fill(bid_id, q)
		var d := {"id": next_deal, "day": w.day(), "minute": int(fmod(w.minutes, World.DAY)), "buyer": World.npc_ref(buyer.id),
			"seller": World.npc_ref(seller.id), "item": item, "qty": q, "price_each": price, "total": q * price, "bid": bid_id, "ask": ask_id,
			"rounds": int(out.rounds), "via": via}
		next_deal += 1
		deals.append(d)
		if deals.size() > int(p("keep_deals", 200)):
			deals = deals.slice(deals.size() - int(p("keep_deals", 200)))
		out.deal = d.duplicate()
		out.ok = true
	_busy = false
	return _out(out, "settled" if ok else "cannot_perform")


# ---------------------------------------------------------------- live entry points ------------
## Relations.share: villagers `a` and `b` spent an hour together (a real encounter, within the meeting radius). Each sees the
## other's open offers (in_person, OD-LE-02B D01) and, if one bids for what the other asks for or holds for sale, they bargain
## once (the lower id's bids first). Nothing when neither has an offer.
func on_encounter(a: int, b: int) -> void:
	if not drive or _busy:
		return
	var na: NPC = w.npc(a)
	var nb: NPC = w.npc(b)
	if na == null or nb == null or not na.alive or not nb.alive:
		return
	var ar := World.npc_ref(a)
	var brf := World.npc_ref(b)
	var oa := f.offers.open_of(ar)
	var ob := f.offers.open_of(brf)
	if oa.is_empty() and ob.is_empty():
		return
	for pair in [[oa, brf, ar], [ob, ar, brf]]:
		for o in pair[0]:
			f.knowledge.learn(pair[1], pair[2], str(o.item), EconKnowledge.SELLS if o.side == EconOffers.ASK else EconKnowledge.BUYS,
					int(o.price_each), "in_person", int(o.id), str(o.location))
	_stat("encounters")
	var order := [[na, nb, oa, ob], [nb, na, ob, oa]] if a < b else [[nb, na, ob, oa], [na, nb, oa, ob]]
	for pr in order:
		var buyer: NPC = pr[0]
		var seller: NPC = pr[1]
		for o in pr[2]:
			if o.side != EconOffers.BID:
				continue
			var ask := -1
			for x in pr[3]:
				if x.side == EconOffers.ASK and x.item == o.item:
					ask = int(x.id)
					break
			if ask >= 0 or for_sale(seller, str(o.item)) > 0:
				negotiate(buyer, seller, str(o.item), f.offers.remaining(int(o.id)), int(o.id), ask, "encounter")
				return


## JudgmentStore._meet_now (the gossip's own meetings, OD-LE-10 D09): each tells the other up to word_of_mouth_per_meeting
## prices it genuinely learned firsthand (freshest first) that the listener lacks or holds older, only when the gossip system
## would let it tell that listener anything (JudgmentStore.would_tell). The age travels with the news; the teller is recorded.
func on_meeting(a: int, b: int) -> void:
	if not drive:
		return
	var lo := mini(a, b)
	var hi := maxi(a, b)
	_tell(lo, hi)
	_tell(hi, lo)


func _tell(teller: int, listener: int) -> void:
	var t: NPC = w.npc(teller)
	var l: NPC = w.npc(listener)
	if t == null or l == null or not t.alive or not l.alive:
		return
	if w.judgment != null and not w.judgment.would_tell(teller, listener):
		return
	var tr := World.npc_ref(teller)
	var lr := World.npc_ref(listener)
	var told := 0
	for e in f.knowledge.firsthand_of(tr):
		if told >= int(p("word_of_mouth_per_meeting", 2)):
			break
		if str(e.subject) == lr:
			continue
		if f.knowledge.learn(lr, str(e.subject), str(e.item), str(e.side), int(e.price_each), "word_of_mouth", -1, str(e.location), int(e.seen_day), tr):
			told += 1
	if told > 0:
		_stat("word_of_mouth", told)


## EconomyFoundation.dawn, after expiries and needs: review offers, post bids from needs and asks from traders' stock, take a few
## standing bids to sellers the buyers know (CON-01 contracts), and let parties renegotiate contracts on their last day.
func dawn(day: int) -> void:
	if not drive:
		return
	review(day)
	post_bids(day)
	post_asks(day)
	dialogues(day)
	if bool(p("renegotiate", true)):
		renegotiate(day)


# ---------------------------------------------------------------- dawn work ------------------
## Reconsider each open offer at most every review_days (anti-oscillation, design s.5): a bid whose need is met is withdrawn, one
## the buyer can no longer cover is cut or withdrawn, an unmet one rises by revise_share of the gap to its ceiling while
## revisions remain (or falls to the ceiling when the need has eased); an ask whose goods went is cut or withdrawn, an unsold one
## falls by revise_share toward its floor, one under a bid its poster knows of rises toward it. Returns ids reviewed.
func review(day: int) -> Array:
	var ids: Array = []
	for id in f.offers.records:
		var o: Dictionary = f.offers.records[id]
		if o.state == EconOffers.OPEN and day - int(o.reviewed_day) >= int(p("review_days", 1)):
			ids.append(int(id))
	ids.sort()
	var maxrev := int(p("max_revisions", 3))
	var share := float(p("revise_share", 0.34))
	for id in ids:
		var o: Dictionary = f.offers.records[id]
		var ref := str(o.actor)
		var n: NPC = w.npc(World.ref_id(ref)) if f.actors.kind(ref) == "npc" else null
		if n == null or not n.alive:
			f.offers.withdraw(id)
			continue
		var item := str(o.item)
		var price := int(o.price_each)
		if o.side == EconOffers.BID:
			var need := need_for(ref, item, str(o.need))
			if need.is_empty():
				f.offers.withdraw(id)
				_stat("bid_withdrawn_need_met")
				continue
			var left := f.offers.remaining(id)
			var cover := cash_for(n, id) / maxi(1, price)
			if mini(left, int(need.qty)) > cover or left > int(need.qty):
				var keep := mini(mini(left, int(need.qty)), cover)
				if keep < int(o.min_lot) or not f.offers.resize(id, int(o.filled) + int(o.committed) + keep):
					f.offers.withdraw(id)
					_stat("bid_withdrawn_cover")
					continue
			var ceiling := int(buyer_ceiling(n, item, need).limit)
			if price < ceiling and int(o.revisions) < maxrev:
				var up := mini(ceiling, price + ceili(float(ceiling - price) * share))
				if f.offers.remaining(id) * up <= cash_for(n, id) and f.offers.revise(id, up):
					_stat("bid_raised")
					continue
			elif price > ceiling and int(o.revisions) < maxrev and ceiling >= int(band(item)[0]):
				if f.offers.revise(id, ceiling):
					_stat("bid_lowered")
					continue
		else:
			var have := for_sale(n, item, id)
			var left := f.offers.remaining(id)
			if have < left:
				if have < int(o.min_lot) or not f.offers.resize(id, int(o.filled) + int(o.committed) + have):
					f.offers.withdraw(id)
					_stat("ask_withdrawn_stock")
					continue
			var floor_ := seller_floor(n, item, mini(have, left), "")
			var kb := int(believed(ref, item).best_bid)
			if kb > price and int(o.revisions) < maxrev:
				if f.offers.revise(id, mini(int(band(item)[1]), price + ceili(float(kb - price) * share))):
					_stat("ask_raised")
					continue
			elif int(o.filled) == int(o.get("seen_filled", 0)) and price > floor_ and int(o.revisions) < maxrev:
				if f.offers.revise(id, maxi(floor_, price - ceili(float(price - floor_) * share))):
					f.offers.records[id].seen_filled = int(o.filled)
					_stat("ask_lowered")
					continue
			f.offers.records[id].seen_filled = int(o.filled)
		f.offers.records[id].reviewed_day = day
	return ids


## Bids from needs (design s.4-5): up to posts_per_dawn actors of the need table after the cursor, each of its needs of
## BID_KINDS without an open bid for that item gets one: quantity the need's, min lot a trade's batch for an input, price the
## opening bid, as many units as its cash covers (none posted below the lot). A household's housing need is bid by its
## responsible adult. The player's needs are never derived (OD-LE-14). Returns the ids posted.
func post_bids(day: int) -> Array:
	var refs: Array = f.needs.table.keys()
	refs.sort()
	var start := refs.bsearch(bid_cursor, false) if bid_cursor != "" else 0
	var posted := []
	var done := 0
	for i in refs.size():
		if done >= int(p("posts_per_dawn", 6)):
			break
		var ref: String = refs[(start + i) % refs.size()]
		bid_cursor = ref
		done += 1
		for need in f.needs.table[ref].needs:
			if not str(need.kind) in BID_KINDS or int(need.qty) <= 0:
				continue
			var bidder: NPC = null
			if f.actors.kind(ref) == "npc":
				bidder = w.npc(World.ref_id(ref))
			elif str(need.kind) == "housing":
				bidder = w.construction.responsible_adult(World.ref_id(ref))
			if bidder == null or not bidder.alive or bidder.role != "adult":
				continue
			var br := World.npc_ref(bidder.id)
			if f.offers.open_of(br).any(func(x): return x.side == EconOffers.BID and x.item == need.item):
				continue
			var id := post_bid(bidder, str(need.item), need)
			if id >= 0:
				posted.append(id)
	return posted


## One bid for `need` (the need record of `item`). The id, or -1 when the buyer cannot cover a lot inside the band.
func post_bid(buyer: NPC, item: String, need: Dictionary) -> int:
	var ce := buyer_ceiling(buyer, item, need)
	if int(ce.limit) < int(band(item)[0]):
		_stat("bid_not_worthwhile")
		return -1
	var price := bid_price(buyer, item, int(ce.limit))
	var lot := maxi(1, w.brain.batch_unit(buyer, item)) if str(need.kind) == "input" else 1
	var qty := mini(int(need.qty), cash_for(buyer) / maxi(1, price))
	if qty < lot:
		_stat("bid_unaffordable")
		return -1
	var r := f.offers.post(EconOffers.BID, World.npc_ref(buyer.id), item, qty, price, w.day() + int(p("bid_days", 4)) - 1, "", PURPOSE, lot, str(need.kind))
	if not r.ok:
		return -1
	_stat("bids_posted")
	return int(r.id)


## Asks from traders' stock: up to ask_sellers_per_dawn villagers after the cursor (World.npcs order) whose trade sells to
## others (local_supply.jobs, the existing list of who keeps goods for sale), each posting up to ask_items_per_seller asks
## (item id order) for what it holds for sale and has no open ask for, at its ask price. Returns the ids posted.
func post_asks(day: int) -> Array:
	var jobs: Array = GameData.b("local_supply").jobs
	var posted := []
	var looked := 0
	var tries := 0
	while looked < int(p("ask_sellers_per_dawn", 6)) and tries < w.npcs.size():
		tries += 1
		ask_cursor = (ask_cursor + 1) % maxi(1, w.npcs.size())
		var n: NPC = w.npcs[ask_cursor]
		if not n.alive or n.role != "adult" or not n.job in jobs:
			continue
		looked += 1
		var ref := World.npc_ref(n.id)
		var have := f.actors.goods(ref)
		var ids: Array = have.keys()
		ids.sort()
		var made := 0
		for item in ids:
			if made >= int(p("ask_items_per_seller", 3)):
				break
			if f.offers.open_of(ref).any(func(x): return x.side == EconOffers.ASK and x.item == item):
				continue
			var q := for_sale(n, str(item))
			if q <= 0:
				continue
			var fl := seller_floor(n, str(item), 1, "")
			var r := f.offers.post(EconOffers.ASK, ref, str(item), q, ask_price(n, str(item), n.inv.count(str(item)), fl), day + int(p("ask_days", 4)) - 1, "", PURPOSE)
			if r.ok:
				posted.append(int(r.id))
				made += 1
				_stat("asks_posted")
	return posted


## Direct dialogue (OD-LE-02B D01; OD-LE-03 D02): up to dialogues_per_dawn standing bids at least a day old, not taken to anyone
## today, are taken by their buyer to a seller it KNOWS of (its own knowledge, reliable enough): the buyer chooses among them
## through the shared engine (price it knows, their number, its opinion of each) or does without; with the chosen one it
## negotiates a CON-01 procurement contract (procure). A buyer who knows nobody waits (it may miss the opportunity).
func dialogues(day: int) -> Array:
	var ids: Array = []
	for id in f.offers.records:
		var o: Dictionary = f.offers.records[id]
		if o.state == EconOffers.OPEN and o.side == EconOffers.BID and int(o.made_day) < day and int(o.get("dialogue_day", -1)) < day:
			ids.append(int(id))
	ids.sort()
	var made := []
	for id in ids.slice(0, int(p("dialogues_per_dawn", 4))):
		var o: Dictionary = f.offers.records[id]
		o.dialogue_day = day
		var br := str(o.actor)
		var buyer: NPC = w.npc(World.ref_id(br))
		if buyer == null or not buyer.alive:
			continue
		var item := str(o.item)
		var need := need_for(br, item, str(o.need))
		if need.is_empty():
			f.offers.withdraw(id)
			_stat("bid_withdrawn_need_met")
			continue
		var urg := _milli(float(buyer_ceiling(buyer, item, need).urgency))
		var cands := []
		var people := {}
		for e in f.knowledge.known_by(br, item, EconKnowledge.SELLS):
			var s: NPC = w.npc(World.ref_id(str(e.subject))) if f.actors.kind(str(e.subject)) == "npc" else null
			if s == null or not s.alive or s == buyer or s.role != "adult" or f.knowledge.reliability(e) < float(p("min_reliability", 0.25)):
				continue
			people[s.id] = s
			var bd := band(item)
			cands.append({"id": s.id, "counterparty": f.actors.judged_person(str(e.subject)),
				"factors": {"necessity": urg,
					"price": _milli(float(int(bd[1]) - clampi(int(e.price_each), int(bd[0]), int(bd[1]))) / float(maxi(1, int(bd[1]) - int(bd[0]))))}})
		if cands.is_empty():
			_stat("bid_no_known_seller")
			continue
		cands.sort_custom(func(x, y): return int(x.id) < int(y.id))
		var r := JudgmentWeighting.choose(w.judgment, _judgment_cfg(), buyer.id, "market_buy", cands, [day, item.hash(), id])
		if r.chosen == null or str(r.chosen) == "forgo":
			_stat("dialogue_forgone")
			continue
		var res := procure(id, buyer, people[int(r.chosen)])
		if res.ok:
			made.append(int(res.contract))
	return made


## OD-LE-03 (D02): the buyer of bid `bid_id` offers seller `s` a CON-01 contract for the bid's remaining units at its price per
## unit, any tradable product, deadline contract_days; the seller answers by CON-01's own evaluation (accept, counter, reject);
## a counter is met when it stays inside the buyer's ceiling, its lot and its cash, and the buyer still weighs it worth dealing
## (market_buy), up to max_rounds offers in all. On a contract (or a formal one awaiting signing face to face) the units are
## committed on the bid (EconOffers.commit). The bid's coin reservation is lifted for the offer only (CON-01 escrows the coins
## itself) and restored when nothing is agreed. {ok, outcome, contract, rounds}.
func procure(bid_id: int, buyer: NPC, s: NPC) -> Dictionary:
	var out := {"ok": false, "outcome": "", "contract": -1, "rounds": 0}
	var o: Dictionary = f.offers.records.get(bid_id, {})
	if o.is_empty() or o.state != EconOffers.OPEN or o.side != EconOffers.BID or s == null or not s.alive:
		out.outcome = "cannot_perform"
		return out
	var br := World.npc_ref(buyer.id)
	var item := str(o.item)
	var need := need_for(br, item, str(o.need))
	if need.is_empty():
		f.offers.withdraw(bid_id)
		out.outcome = "no_need"
		_stat("no_need")
		return out
	var ceiling := int(buyer_ceiling(buyer, item, need).limit)
	var cash := cash_for(buyer, bid_id)
	var qty := mini(f.offers.remaining(bid_id), cash / maxi(1, int(o.price_each)))
	var price := int(o.price_each)
	var days := int(p("contract_days", 3))
	var lot := int(o.min_lot)
	if qty < lot:
		out.outcome = "no_funds"
		_stat("no_funds")
		return out
	if int(o.reservation) >= 0:
		f.reservations.release(int(o.reservation))
		o.reservation = -1
	var hist := []
	var cid := -1
	while int(out.rounds) < int(p("max_rounds", 3)):
		out.rounds = int(out.rounds) + 1
		var r: Dictionary = w.contracts.propose(br, s, item, qty, price, days, hist)
		f.knowledge.learn(br, World.npc_ref(s.id), item, EconKnowledge.SELLS, int(r.get("price_each", price)), "in_person")
		if r.has("contract") or r.has("signing"):
			cid = int((r.contract if r.has("contract") else r.signing).id)
			break
		if str(r.get("answer", "")) != "counter":
			out.outcome = "contract_refused"
			break
		hist = r.get("history", [])
		var cq := int(r.qty)
		var cp := int(r.price_each)
		if cq < lot or cp > ceiling or cq * cp > cash or int(r.days) > int(Contracts.cfg().max_days):
			out.outcome = "counter_beyond_limit"
			break
		var key := [w.day(), item.hash(), buyer.id, s.id, int(out.rounds)]
		var bf := {"necessity": _milli(float(buyer_ceiling(buyer, item, need).urgency)), "price": _milli(float(ceiling - cp) / float(maxi(1, ceiling - int(band(item)[0])))),
			"sole_source": 100000 / maxi(1, int(believed(br, item).sellers))}
		if str(_weigh(buyer, "market_buy", World.npc_ref(s.id), bf, key).chosen) != "deal":
			out.outcome = "buyer_refused"
			break
		qty = cq
		price = cp
		days = int(r.days)
	if cid >= 0:
		f.offers.records[bid_id].price_each = price
		f.offers.commit(bid_id, mini(qty, f.offers.remaining(bid_id)), cid)
		out.ok = true
		out.contract = cid
		out.outcome = "contract"
		_stat("contracts_opened")
		return out
	if out.outcome == "":
		out.outcome = "no_agreement"
	f.offers._rebook(f.offers.records[bid_id])        # the bid stands as it was
	_stat(str(out.outcome))
	return out


## OD-LE-13 (APPROVED): on a villager contract's last day with goods still owed, the seller puts what its circumstances allow
## (CON-01 means): more days when its work can manage the rest within max_extend_days (extension); a higher price when it must
## buy the goods dearer than the contract pays (changed payment, inside the band and the buyer's ceiling); else, holding or
## having delivered some, the quantity cut to what it has delivered and holds, with a day to bring it (partial delivery). The
## buyer weighs it (market_buy) and agrees (Contracts.amend), or, no longer needing the goods, cancels (Contracts.cancel: no
## fee); otherwise the contract lapses under CON-01's own rule. No penalty is added. Returns [contract id, what] pairs.
func renegotiate(day: int) -> Array:
	var done := []
	for c in w.contracts.list.duplicate():
		if not Contracts.is_open(c) or Contracts.is_service(c) or int(c.deadline_day) != day or Contracts.left(c) <= 0:
			continue
		if not str(c.buyer).begins_with("npc:") or not str(c.seller).begins_with("npc:"):
			continue
		if (c.history as Array).any(func(h): return str(h.what) == "amend" and int(h.day) == day):
			continue
		var s: NPC = w.npc(World.ref_id(str(c.seller)))
		var b: NPC = w.npc(World.ref_id(str(c.buyer)))
		if s == null or b == null or not s.alive or not b.alive:
			continue
		var item := str(c.item)
		var owed := Contracts.left(c)
		var held := s.inv.count(item)
		if held >= owed:
			continue
		var what := ""
		var qty := int(c.qty)
		var price := int(c.price_each)
		var extra := 0
		for d in range(1, int(p("max_extend_days", 3)) + 1):
			var m := w.contracts.means(s, item, d, price)
			if str(m.route) in ["mine", "chop", "craft", "harvest"] and held + int(m.cap) >= owed:
				what = "extend"
				extra = d
				break
		if what == "":
			var m := w.contracts.means(s, item, 1, 1 << 30)
			if str(m.route) == "buy" and int(m.cost) > price and int(m.cap) + held >= owed:
				what = "price"
				price = mini(int(band(item)[1]), int(m.cost) + 1)
			elif int(c.delivered) + held > 0:
				what = "partial"
				qty = int(c.delivered) + held
				extra = 1 if held > 0 else 0
		if what == "":
			continue
		var need := need_for(str(c.buyer), item)
		if need.is_empty():
			if w.contracts.cancel(c, str(c.buyer)) == "":
				done.append([int(c.id), "cancel"])
				_stat("renegotiated_cancel")
			continue
		var ce := buyer_ceiling(b, item, need)
		if what == "price" and (price > int(ce.limit) or (price - int(c.price_each)) * owed > cash_for(b)):
			_stat("renegotiation_refused")
			continue
		var bf := {"necessity": _milli(float(ce.urgency)), "price": _milli(float(int(ce.limit) - price) / float(maxi(1, int(ce.limit) - int(band(item)[0])))),
			"sole_source": 100000 / maxi(1, int(believed(str(c.buyer), item).sellers))}
		if str(_weigh(b, "market_buy", str(c.seller), bf, [day, int(c.id)]).chosen) != "deal":
			_stat("renegotiation_refused")
			continue
		if w.contracts.amend(c, str(c.seller), qty, price, extra) == "":
			done.append([int(c.id), what])
			_stat("renegotiated_" + what)
	return done


# ---------------------------------------------------------------- record -------------------
func _stat(k: String, n := 1) -> void:
	stats[k] = int(stats.get(k, 0)) + n


func is_empty() -> bool:
	return deals.is_empty() and stats.is_empty() and next_deal == 0 and bid_cursor == "" and ask_cursor == -1


func to_dict() -> Dictionary:
	var ks: Array = stats.keys()
	ks.sort()
	var st := {}
	for k in ks:
		st[k] = int(stats[k])
	return {"deals": deals.duplicate(true), "next_deal": next_deal, "stats": st, "bid_cursor": bid_cursor, "ask_cursor": ask_cursor}


func load_dict(d: Dictionary) -> void:
	deals = []
	for x in d.get("deals", []):
		deals.append({"id": int(x.id), "day": int(x.day), "minute": int(x.minute), "buyer": str(x.buyer), "seller": str(x.seller), "item": str(x.item),
			"qty": int(x.qty), "price_each": int(x.price_each), "total": int(x.total), "bid": int(x.bid), "ask": int(x.ask), "rounds": int(x.rounds), "via": str(x.via)})
	next_deal = int(d.get("next_deal", 0))
	stats = {}
	var st: Dictionary = d.get("stats", {})
	for k in st:
		stats[str(k)] = int(st[k])
	bid_cursor = str(d.get("bid_cursor", ""))
	ask_cursor = int(d.get("ask_cursor", -1))
