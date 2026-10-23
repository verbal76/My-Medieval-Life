class_name RegionalMarket
extends RefCounted
## PROSPECTIVE (Expansion 18, SET-C, with SET-E's competition rules; PROS-18): regional supply and demand over N
## settlements and the parties in them, and the trades it would make. A STAND-IN for the negotiated contracts the live
## game will use (CON-01, Build 17; `to_contract_offer` maps a line to a CON-01 offer); nothing here touches the World.
##
## REG-PARTY-01: the parties are the holders of the five off-map settlements (SettlementParty, over OffMapSettlement's own books)
## or, in analysis and tests, SettlementLedger fixtures and the village's snapshots; this class reads and changes a party only through
## their common interface (held, purse, need_rate, local_yield, sale_cap, can_deal, deal, journal, ...), never its fields.
##
## Spec s.5, a viable trade needs all of:
##   demand     the buyer's unmet need: what its people use over `reserve_days`, less what it holds and what its own
##              workings can still yield (local_supply);
##   supply     the seller's goods beyond its own `reserve_days` of need (within its sale limit); supply is fixed at the
##              start of a round, so goods bought in a round are not resold in it ("prevent circular money printing via
##              ... resale");
##   purchasing the buyer's coins above its cash floor ("need alone does not create wealth"): a starving, cash-poor
##     power   party buys nothing it cannot pay for, and the failure is recorded (unmet, reason "funds");
##   price and  the seller's price at its own door (the item's value) plus the carriage, against what the buyer will pay
##   competition (value, raised up to `scarcity_premium` as its store runs out); the cheapest delivered cost wins, then
##              the shorter trip, then the lower party id; the others' lost sales are recorded;
##   logistics  a route between the two places must exist (no route, no trade).
##
## Who buys and how the goods travel (owner Q18-10, 2026-10-21): ANY party may buy -- a settlement, a household, a
## villager, a merchant or business, a treasury. The buyer either (1) travels to the seller and carries the goods home
## itself ("self": no coin, but only as much as its own transport carries a round, and only if it can travel), or (2)
## pays a willing carter ("carter": a party with carts_for_hire, based at either end of the route, with capacity left;
## its fee is its carters' wages for the round trip spread over a load, TradeRoutes.costed, paid by the buyer to the
## carter as its own matched transfer). There is no free delivery and no carriage folded into the goods' price. Parties
## of the same place do not trade here (the local market). The live game has no rule yet for hiring a carter to haul
## between settlements (Construction.hire covers carrying to one's own building site only), so carters exist only as
## fixtures until the owner answers Q18-12 (DESIGN.md section 10).
##
## Cooperation: an agreement between two places ("preferred") lets a partner's seller win a sale when its delivered cost
## is within `preferred_margin_pct` of the cheapest. It never lowers a price, gives goods or lends coins (no hidden
## rescue, WDR-022; credit and barter are Q18-5).
##
## plan() only reads the parties; execute() applies a plan line by line, each atomic and matched (goods and their price,
## and the carriage fee, each move as equal and opposite journal lines), and refuses a line that no longer holds.

static func cfg() -> Dictionary:
	return SettlementIndustries.data().market


static func horizon(l, item: String) -> int:
	return int(ceil(l.need_rate(item) * float(cfg().reserve_days) - 1e-9))


## What `l` lacks of its horizon need: less what it holds and what its own workings can still yield (local_supply:
## a village with ore in its own reachable seams does not need to import ore; DESIGN.md "Ore demand").
static func demand(l, item: String) -> int:
	return maxi(0, horizon(l, item) - l.held(item) - l.local_yield(item))


static func supply(l, item: String) -> int:
	var n := maxi(0, l.held(item) - horizon(l, item))
	var cap: int = l.sale_cap(item)
	return n if cap < 0 else mini(n, cap)


static func ask(item: String) -> int:
	return maxi(1, GameData.value(item))


## What `l` will pay a unit of `item`, carriage included: its value, plus up to scarcity_premium times it as its store of
## the horizon need runs out (all of it when it holds none).
static func willing(l, item: String) -> int:
	var h := horizon(l, item)
	if h <= 0:
		return 0
	var scarcity := clampf(float(demand(l, item)) / float(h), 0.0, 1.0)
	return int(floor(float(ask(item)) * (1.0 + float(cfg().scarcity_premium) * scarcity) + 1e-9))


static func spendable(l) -> int:
	return maxi(0, l.purse() - int(cfg().cash_floor))


## What a party can carry home itself in one round: its own transport, if it can travel at all.
static func self_capacity(l) -> int:
	return TradeRoutes.capacity(l.transport) if l.can_travel else 0


## The region's balance of one good: {item, need (a day), held, demand, supply} summed over parties, and per party.
## A report for the wiki and the simulations; it moves nothing.
static func balance(ledgers: Array, item: String) -> Dictionary:
	var out := {"item": item, "need_per_day": 0.0, "held": 0, "demand": 0, "supply": 0, "by": {}}
	for l in _sorted(ledgers):
		var row := {"need_per_day": l.need_rate(item), "held": l.held(item),
			"demand": demand(l, item), "supply": supply(l, item)}
		out.by[l.id] = row
		out.need_per_day += row.need_per_day
		out.held += row.held
		out.demand += row.demand
		out.supply += row.supply
	return out


## Every good any party needs or holds, sorted.
static func goods_of(ledgers: Array) -> Array:
	var ids := {}
	for l in ledgers:
		for k in l.need_items():
			ids[k] = true
		for k in l.held_items():
			ids[k] = true
	var out := ids.keys()
	out.sort()
	return out


static func _sorted(ledgers: Array) -> Array:
	var ls := ledgers.duplicate()
	ls.sort_custom(func(a, b): return a.id < b.id)
	return ls


static func _key(a: String, b: String) -> String:
	return a + ">" + b if a < b else b + ">" + a


## The cheapest way to get goods from seller `s` to buyer `b` over route `r` now: [fee_each, mode, carrier id,
## capacity left] or [] when there is none (the buyer cannot travel or carry more, and no willing carter has room).
static func _carriage(s, b, r: Dictionary, room: Dictionary, carters: Array) -> Array:
	if int(room.get(b.id, 0)) > 0:
		return [0, "self", "", int(room[b.id])]
	var best: Array = []
	for c in carters:
		if c.id == b.id or int(room.get(c.id, 0)) <= 0:      # (a seller may cart its own goods: a separate, paid service)
			continue
		if c.settlement != s.settlement and c.settlement != b.settlement:
			continue
		var fee := int(TradeRoutes.costed(s.settlement, b.settlement, int(r.tiles), float(r.effective),
			TradeRoutes.mode_for(c.transport)).cost_per_unit)
		fee = int(ceil(float(fee) * SettlementIndustries.pay_multiplier("trade", int(c.capabilities.get("trade", 0)), c.profile) - 1e-9))
		if best.is_empty() or fee < int(best[0]) or (fee == int(best[0]) and c.id < str(best[2])):
			best = [fee, "carter", c.id, int(room[c.id])]
	return best


## The trades the region would make in one round. `routes`: TradeRoutes.table keyed by place ("a>b"); `agreements`:
## [[place_a, place_b, "preferred"]]. Returns {lines: [{seller, buyer, item, units, unit_price, total, carriage,
## carrier, fee_each, fee_total, days}], unmet: [{buyer, item, units, reason}], lost: [{seller, buyer, item, units, to}]}.
## `local` (analysis): also let parties of the same place buy from each other first, as the local market does (carriage
## "local", no trip, no fee), so demand the place can meet itself is not sent abroad. Reads only.
static func plan(ledgers: Array, routes: Dictionary, agreements: Array = [], local := false) -> Dictionary:
	var ls := _sorted(ledgers)
	var partners := {}
	for a in agreements:
		if str(a[2]) == "preferred":
			partners[_key(str(a[0]), str(a[1]))] = true
	var carters := ls.filter(func(l): return l.carts_for_hire)
	var left := {}            # seller id -> {item: units still for sale}
	var room := {}            # party id -> units it can still carry this round (its own trips, or as a carter)
	var cash := {}            # buyer id -> coins it can still spend
	for l in ls:
		left[l.id] = {}
		room[l.id] = TradeRoutes.capacity(l.transport) if l.carts_for_hire else self_capacity(l)
		cash[l.id] = spendable(l)
	var lines := []
	var unmet := []
	var lost := []
	var margin := float(cfg().preferred_margin_pct) / 100.0
	for item in goods_of(ls):
		for l in ls:
			left[l.id][item] = supply(l, item)
		# the neediest buyer first (the share of its horizon it lacks), ties to the lower id
		var buyers := []
		for l in ls:
			if demand(l, item) > 0:
				buyers.append(l)
		buyers.sort_custom(func(x, y):
			var sx := float(demand(x, item)) / float(maxi(1, horizon(x, item)))
			var sy := float(demand(y, item)) / float(maxi(1, horizon(y, item)))
			return sx > sy or (sx == sy and x.id < y.id))
		for b in buyers:
			var want := demand(b, item)
			var pay := willing(b, item)
			var reason := ""
			while want > 0:
				var offers := []      # [delivered each, seller id, carriage, route]
				var no_carriage := false
				for s in ls:
					if s.id == b.id or int(left[s.id][item]) <= 0 or (s.settlement == b.settlement and not local):
						continue
					if s.settlement == b.settlement:
						offers.append([ask(item), s.id, [0, "local", "", 1 << 30], {"days": 0.0}])
						continue
					var r: Dictionary = routes.get(s.settlement + ">" + b.settlement, {})
					if r.is_empty():
						continue
					var car := _carriage(s, b, r, room, carters)
					if car.is_empty():
						no_carriage = true
						continue
					offers.append([ask(item) + int(car[0]), s.id, car, r])
				if offers.is_empty():
					if reason == "":
						reason = "no carriage" if no_carriage else "no supplier"
					break
				# the cheapest delivered cost; at equal cost the shorter trip (a buyer fetching its own goods spends days,
				# not coins); then the lower id
				offers.sort_custom(func(x, y):
					var dx := float((x[3] as Dictionary).days)
					var dy := float((y[3] as Dictionary).days)
					return x[0] < y[0] or (x[0] == y[0] and (dx < dy - 1e-9 or (absf(dx - dy) <= 1e-9 and x[1] < y[1]))))
				var pick: Array = offers[0]
				for o in offers:            # cooperation: a partner's seller close enough to the cheapest wins
					var sp: String = _place(ls, str(o[1]))
					if partners.has(_key(sp, b.settlement)) and float(o[0]) <= float(offers[0][0]) * (1.0 + margin) + 1e-9:
						pick = o
						break
				var each := int(pick[0])
				if each > pay:
					reason = "price"
					break
				var afford := int(cash[b.id]) / each
				if afford <= 0:
					reason = "funds"
					break
				var sid := str(pick[1])
				var car: Array = pick[2]
				var n := mini(mini(want, int(left[sid][item])), mini(int(car[3]), afford))
				var fee_each := int(car[0])
				lines.append({"seller": sid, "buyer": b.id, "item": item, "units": n, "unit_price": ask(item),
					"total": n * ask(item), "carriage": str(car[1]), "carrier": str(car[2]), "fee_each": fee_each,
					"fee_total": n * fee_each, "days": float((pick[3] as Dictionary).days)})
				for o in offers:            # competition: the others that could have sold these units lost them
					if str(o[1]) != sid:
						lost.append({"seller": str(o[1]), "buyer": b.id, "item": item, "units": mini(n, int(left[str(o[1])][item])), "to": sid})
				left[sid][item] = int(left[sid][item]) - n
				if str(car[1]) != "local":
					var carrier_id: String = b.id if str(car[1]) == "self" else str(car[2])
					room[carrier_id] = int(room[carrier_id]) - n
				cash[b.id] = int(cash[b.id]) - n * each
				want -= n
			if want > 0:
				unmet.append({"buyer": b.id, "item": item, "units": want, "reason": reason})
	return {"lines": lines, "unmet": unmet, "lost": lost}


static func _place(ls: Array, id: String) -> String:
	for l in ls:
		if l.id == id:
			return l.settlement
	return id


## Apply a plan: for each line, the seller's goods go to the buyer and the price to the seller; with a carter, the fee
## goes from the buyer to the carter. Each is a matched pair of journal lines (and, between holders of two settlements, of
## `regional_*` flow lines the settlements' audit checks: SettlementParty.deal). A line whose goods or coins are no longer
## there is refused whole and reported. Returns {done: [line], refused: [line]}.
static func execute(plan_d: Dictionary, ledgers: Array, day := 0) -> Dictionary:
	var by := {}
	for l in ledgers:
		by[l.id] = l
	var done := []
	var refused := []
	for line in plan_d.lines:
		var s = by.get(line.seller)
		var b = by.get(line.buyer)
		var c = by.get(line.carrier) if str(line.carriage) == "carter" else null
		var n := int(line.units)
		var total := int(line.total)
		var fee := int(line.get("fee_total", 0))
		var pays_fee: bool = c != null and fee > 0
		# every side is checked before any is made: a line is applied whole or refused whole
		if s == null or b == null or n <= 0 or (str(line.carriage) == "carter" and c == null) \
				or not s.can_deal("sell", line.item, n, total) or not b.can_deal("buy", line.item, n, total + fee) \
				or (pays_fee and not c.can_deal("carriage_earned", line.item, n, fee)):
			refused.append(line)
			continue
		s.deal("sell", b, line.item, n, total, day)
		b.deal("buy", s, line.item, n, total, day)
		if pays_fee:
			b.deal("carriage_paid", c, line.item, n, fee, day)
			c.deal("carriage_earned", b, line.item, n, fee, day)
		done.append(line)
	return {"done": done, "refused": refused}


## Whether a set of journals pairs up: every sale has the buyer's matching purchase and every carriage payment the
## carter's receipt (same day, item, units, coins and counterparties). "" when they do. `day` >= 0 looks at that day's
## lines only (when some of the parties are snapshots made for that day).
static func matched(ledgers: Array, day := -1) -> String:
	var pairs := {}
	for l in ledgers:
		for e in l.journal:
			if day >= 0 and int(e.day) != day:
				continue
			var k := ""
			var sign := 0
			match str(e.kind):
				"sell":
					k = "goods|%s|%s" % [l.id, str(e.with)]
					sign = 1
				"buy":
					k = "goods|%s|%s" % [str(e.with), l.id]
					sign = -1
				"carriage_earned":
					k = "carriage|%s|%s" % [l.id, str(e.with)]
					sign = 1
				"carriage_paid":
					k = "carriage|%s|%s" % [str(e.with), l.id]
					sign = -1
			if sign == 0:
				continue
			k += "|%d|%s|%d|%d" % [int(e.day), str(e.item), int(e.n), int(e.coins)]
			pairs[k] = int(pairs.get(k, 0)) + sign
	for k in pairs:
		if int(pairs[k]) != 0:
			return "unmatched transfer " + k
	return ""


## A planned line as a CON-01 procurement offer (Build 17 `Contracts`, goods only: buyer, seller, item, qty,
## price_each, deadline_day, terms), the record the live game will negotiate instead of this stand-in's execute. 
## ids map to CON-01 refs at integration ("npc:<id>", "manor", "player"; off-map parties need a ref CON-01 does not
## have yet). The carriage is NOT part of it: CON-01 has no service contracts (Q18-12).
static func to_contract_offer(line: Dictionary, day: int) -> Dictionary:
	return {"buyer": str(line.buyer), "seller": str(line.seller), "item": str(line.item), "qty": int(line.units),
		"price_each": int(line.unit_price), "deadline_day": day + maxi(1, int(ceil(float(line.get("days", 1.0)) * 2.0))),
		"terms": {"pay": "on_delivery", "partial": true, "all_at_once": false, "deposit": 0},
		"carriage": {"mode": str(line.carriage), "carrier": str(line.carrier), "fee_each": int(line.fee_each)}}
