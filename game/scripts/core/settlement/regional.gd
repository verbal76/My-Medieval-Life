class_name RegionalMarket
extends RefCounted
## PROSPECTIVE (Expansion 18, SET-C, with SET-E's competition rules; PROS-18): regional supply and demand over N
## settlements, and the trades it would make.
##
## Spec s.5, a viable trade needs all of:
##   demand     the buyer's unmet need: what its people use over `reserve_days`, less what it holds;
##   supply     the seller's goods beyond its own `reserve_days` of need, less what it bought this round (no resale in
##              the round it arrived: the spec's "prevent circular money printing via ... resale");
##   purchasing the buyer's coins above its cash floor ("need alone does not create wealth"): a starving, cash-poor
##     power   settlement buys nothing, and the failure is recorded (unmet, reason "funds");
##   price and  the delivered price (the seller's asking price, the item's value, plus the route's haulage a unit) must
##   competition not exceed what the buyer will pay (value, raised up to `scarcity_premium` as its store runs out);
##              among sellers the cheapest delivered price wins, ties to the lower settlement id; the others' lost sales
##              are recorded (competition);
##   logistics  a route must exist (no route, no trade) and a seller sends at most its transport capacity a round.
## Cooperation: an agreement between two settlements ("preferred") lets the partner win a sale when its delivered price
## is within `preferred_margin_pct` of the cheapest; it never lowers a price, gives goods or lends coins (no hidden
## rescue, WDR-022; credit and barter are owner question Q18-5).
##
## plan() only reads the ledgers; execute() applies a plan line by line, each atomic and matched (the seller's goods
## and the buyer's coins move in equal and opposite journal lines), and refuses a line that no longer holds.

static func cfg() -> Dictionary:
	return SettlementIndustries.data().market


static func horizon(l: SettlementLedger, item: String) -> int:
	return int(ceil(float(l.needs.get(item, 0.0)) * float(cfg().reserve_days) - 1e-9))


static func demand(l: SettlementLedger, item: String) -> int:
	return maxi(0, horizon(l, item) - l.stock.count(item))


static func supply(l: SettlementLedger, item: String) -> int:
	return maxi(0, l.stock.count(item) - horizon(l, item))


static func ask(item: String) -> int:
	return maxi(1, GameData.value(item))


## What `l` will pay a unit of `item`: its value, plus up to scarcity_premium times it as its store of the horizon
## need runs out (all of it when it holds none).
static func willing(l: SettlementLedger, item: String) -> int:
	var h := horizon(l, item)
	if h <= 0:
		return 0
	var scarcity := clampf(float(demand(l, item)) / float(h), 0.0, 1.0)
	return int(floor(float(ask(item)) * (1.0 + float(cfg().scarcity_premium) * scarcity) + 1e-9))


static func spendable(l: SettlementLedger) -> int:
	return maxi(0, l.coins - int(cfg().cash_floor))


## The region's balance of one good: {item, need (a day), held, demand, supply} summed over settlements, and per
## settlement. A report for the wiki and the simulations; it moves nothing.
static func balance(ledgers: Array, item: String) -> Dictionary:
	var out := {"item": item, "need_per_day": 0.0, "held": 0, "demand": 0, "supply": 0, "by": {}}
	for l: SettlementLedger in _sorted(ledgers):
		var row := {"need_per_day": float(l.needs.get(item, 0.0)), "held": l.stock.count(item),
			"demand": demand(l, item), "supply": supply(l, item)}
		out.by[l.id] = row
		out.need_per_day += row.need_per_day
		out.held += row.held
		out.demand += row.demand
		out.supply += row.supply
	return out


## Every good any settlement needs or holds, sorted.
static func goods_of(ledgers: Array) -> Array:
	var ids := {}
	for l: SettlementLedger in ledgers:
		for k in l.needs:
			ids[k] = true
		for k in l.stock.items:
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


## The trades the region would make in one round. `routes`: TradeRoutes.table; `agreements`: [[a, b, "preferred"]].
## Returns {lines: [{seller, buyer, item, units, unit_price, haul, total}], unmet: [{buyer, item, units, reason}],
## lost: [{seller, buyer, item, units, to}]}. Reads only.
static func plan(ledgers: Array, routes: Dictionary, agreements: Array = []) -> Dictionary:
	var ls := _sorted(ledgers)
	var by := {}
	for l: SettlementLedger in ls:
		by[l.id] = l
	var partners := {}
	for a in agreements:
		if str(a[2]) == "preferred":
			partners[_key(str(a[0]), str(a[1]))] = true
	var left := {}            # seller id -> {item: units still for sale}
	var cap := {}             # seller id -> units its transport can still carry this round
	var cash := {}            # buyer id -> coins it can still spend
	for l: SettlementLedger in ls:
		left[l.id] = {}
		cap[l.id] = TradeRoutes.capacity(l.transport)
		cash[l.id] = spendable(l)
	var lines := []
	var unmet := []
	var lost := []
	var margin := float(cfg().preferred_margin_pct) / 100.0
	for item in goods_of(ls):
		for l: SettlementLedger in ls:
			left[l.id][item] = supply(l, item)
		# the neediest buyer first (the share of its horizon it lacks), ties to the lower id
		var buyers := []
		for l: SettlementLedger in ls:
			if demand(l, item) > 0:
				buyers.append(l)
		buyers.sort_custom(func(x, y):
			var sx := float(demand(x, item)) / float(maxi(1, horizon(x, item)))
			var sy := float(demand(y, item)) / float(maxi(1, horizon(y, item)))
			return sx > sy or (sx == sy and x.id < y.id))
		for b: SettlementLedger in buyers:
			var want := demand(b, item)
			var pay := willing(b, item)
			var reason := ""
			while want > 0:
				var offers := []      # [delivered, seller id, haul]
				for s: SettlementLedger in ls:
					if s.id == b.id or int(left[s.id][item]) <= 0 or int(cap[s.id]) <= 0:
						continue
					var r: Dictionary = routes.get(s.id + ">" + b.id, {})
					if r.is_empty():
						continue
					offers.append([ask(item) + int(r.cost_per_unit), s.id, int(r.cost_per_unit)])
				if offers.is_empty():
					reason = "no supplier" if reason == "" else reason
					break
				offers.sort_custom(func(x, y): return x[0] < y[0] or (x[0] == y[0] and x[1] < y[1]))
				var pick: Array = offers[0]
				for o in offers:            # cooperation: a partner close enough to the cheapest wins
					if partners.has(_key(str(o[1]), b.id)) and float(o[0]) <= float(offers[0][0]) * (1.0 + margin) + 1e-9:
						pick = o
						break
				var price := int(pick[0])
				if price > pay:
					reason = "price"
					break
				var afford := int(cash[b.id]) / price
				if afford <= 0:
					reason = "funds"
					break
				var sid := str(pick[1])
				var n := mini(mini(want, int(left[sid][item])), mini(int(cap[sid]), afford))
				lines.append({"seller": sid, "buyer": b.id, "item": item, "units": n, "unit_price": price,
					"haul": int(pick[2]), "total": n * price})
				for o in offers:            # competition: the others that could have sold these units lost them
					if str(o[1]) != sid:
						lost.append({"seller": str(o[1]), "buyer": b.id, "item": item, "units": mini(n, int(left[str(o[1])][item])), "to": sid})
				left[sid][item] = int(left[sid][item]) - n
				cap[sid] = int(cap[sid]) - n
				cash[b.id] = int(cash[b.id]) - n * price
				want -= n
			if want > 0:
				unmet.append({"buyer": b.id, "item": item, "units": want, "reason": reason})
	return {"lines": lines, "unmet": unmet, "lost": lost}


## Apply a plan: for each line, the seller's goods go to the buyer and the buyer's coins to the seller, recorded as a
## matched pair of journal lines (sell/buy, same item, units and coins). A line whose goods or coins are no longer
## there is refused whole and reported. Returns {done: [line], refused: [line]}.
static func execute(plan_d: Dictionary, ledgers: Array, day := 0) -> Dictionary:
	var by := {}
	for l: SettlementLedger in ledgers:
		by[l.id] = l
	var done := []
	var refused := []
	for line in plan_d.lines:
		var s: SettlementLedger = by.get(line.seller)
		var b: SettlementLedger = by.get(line.buyer)
		var n := int(line.units)
		var total := int(line.total)
		if s == null or b == null or n <= 0 or s.stock.count(line.item) < n or b.coins < total or not b.stock.can_add(line.item):
			refused.append(line)
			continue
		s.stock.remove(line.item, n)
		b.stock.add(line.item, n)
		b.coins -= total
		s.coins += total
		s._log(day, "sell", line.item, n, total, b.id)
		b._log(day, "buy", line.item, n, total, s.id)
		done.append(line)
	return {"done": done, "refused": refused}


## Whether a set of journals pairs up: every sale has the buyer's matching purchase (same day, item, units, coins and
## counterparties) and every purchase a sale. "" when they do.
static func matched(ledgers: Array) -> String:
	var sales := {}
	for l: SettlementLedger in ledgers:
		for e in l.journal:
			if e.kind == "sell" or e.kind == "buy":
				var seller: String = l.id if e.kind == "sell" else str(e.with)
				var buyer: String = str(e.with) if e.kind == "sell" else l.id
				var k := "%d|%s|%s|%s|%d|%d" % [int(e.day), seller, buyer, str(e.item), int(e.n), int(e.coins)]
				sales[k] = int(sales.get(k, 0)) + (1 if e.kind == "sell" else -1)
	for k in sales:
		if int(sales[k]) != 0:
			return "unmatched transfer " + k
	return ""
