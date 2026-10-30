class_name Regions
extends RefCounted
## Expansion 18 (SET-C-FIVE, ECON-P1.3): the five off-map settlements around the village and their traders, who ARE the
## caravan (owner 2026-10-23: "Their traders: the caravan is merchants from those settlements, carrying only what they
## actually have and paying with their actual coins; the daily allowance goes away").
##
## One `OffMapSettlement` each (data: game/data/settlements.json; the places and why: docs/expansion18/SETTLEMENTS.md). This
## class steps them a day at a time (World._new_day), keeps the traders' trade among themselves (a wholesale round every few
## days, so the forge at Higham can have Garton's ore), decides which traders are on the road to the village on a given
## visit day, and answers the village's side of the caravan (NPCBrain.caravan, Farming.buy_horse): who sells an item, who
## wants one. It holds no coins or goods of its own: those are the settlements'.
##
## Saved in the save dictionary under "regions" (optional key; a save without it founds the settlements from the world
## seed and steps them to the saved day, so no save version changes).

const FORMAT := "mml-regions-world/1"
const TX_KEEP := 64                  # X20-SETTLE-FOOD stand-in: closed shipments and outcomes kept (the authority's keep_* default)

var list: Array = []                 # OffMapSettlement, in data order
var by_id: Dictionary = {}
var day := -1                        # the last day stepped
var migrated_coins := 0              # coins an older save's caravan purse brought (traders' tills): outside coins that existed
var world_seed := 0
var moves: Array = []                # MIGRATE-18: the last Migration.LOG_MAX moves between the village and a settlement: {day, settlement, dir ("in" = into the village), reason, people, coins, goods}
var move_counts: Dictionary = {}     # "<dir>:<reason>" -> people moved, for good
var suits: Dictionary = {}           # MIGRATE-18 marriage across the road: "<settlement>|<dir>" -> {pair, since}, the pair meeting at the caravan and the day they began
var journal: Array = []              # the parties' exchange lines (SettlementParty.deal): {day, party, kind, item, n, coins, with}; not saved
var party_options := {}              # fixtures' settings per party id (SettlementParty.option); not saved
var food_seq: Dictionary = {}        # X20-SETTLE-FOOD: the last transaction sequence number used per namespace "settle_food/<place>" (saved)
var food_custody := {"marks": {}, "outcomes": {}, "shipments": []}   # the TEMPORARY stand-in authority's state (ship_line; saved)
var food_last: Dictionary = {}       # X20-SETTLE-FOOD: the last food round's result (food_round), for reports and tests; not saved
var _world: WeakRef = null           # the world the settlements live in (bind_world), for its flight recorder; not saved


static func create(seed_: int) -> Regions:
	var r := Regions.new()
	r.world_seed = seed_
	var specs: Array = OffMapSettlement.data().settlements
	for i in specs.size():
		r._add(OffMapSettlement.create(specs[i], seed_, i))
	return r


func _add(s: OffMapSettlement) -> void:
	list.append(s)
	by_id[s.id] = s
	s.arrive_hook = Callable(self, "_arrive")


# ------------------------------------------------------------------ people's identities (ID-01) ----------------
## The settlements now live in world `w`: a birth takes its id from the world's settlement band and enters the register, a death marks it.
func bind_world(w: World) -> void:
	var hook := Callable(w, "offmap_person")
	_world = weakref(w)
	for s: OffMapSettlement in list:
		s.person_hook = hook
		s.trade_hook = Callable(self, "_food_event")


## Give every member that has no id one, in settlement, household and member order (so two worlds from the same data agree), and
## enter them in the register. Returns how many were given. Members that have an id are not touched.
func assign_member_ids(w: World) -> int:
	var n := 0
	for s: OffMapSettlement in list:
		for h in s.hh:
			if not h.has("mem"):
				continue
			for m in h.mem:
				if OffMapSettlement.member_id(m) > 0:
					continue
				var id := w.new_offmap_person_id()
				OffMapSettlement.set_member_id(m, id)
				Identity.register_member(w, id, s.id, int(m[OffMapSettlement.M_SEX]), int(m[OffMapSettlement.M_BORN]), OffMapSettlement.who_of(m))
				n += 1
	return n


## Step every settlement through day `d` (one step a day, in order), then the traders' wholesale round on its day.
func step_day(d: int) -> void:
	if d <= day:
		return
	for s: OffMapSettlement in list:
		if s.day < d:
			s.step_day(d)
	var every := int(OffMapSettlement.rules().road_trade_every_days)
	if every > 0 and d % every == every - 1:
		road_trade()
		food_round(d)
	day = d


## One settlement a game hour from six o'clock, each stepping its day once (the village's own morning is at six too): a
## phone does a fifth of the work in a frame. A hand that cannot be there at the hour finds the settlement stepped at the
## next call: a settlement behind its day is stepped when asked. The traders' round follows the last.
func step_hour(d: int, h: int) -> void:
	if h < 6:
		return
	var upto := mini(list.size() - 1, h - 6)
	var done := true
	for i in upto + 1:
		var s: OffMapSettlement = list[i]
		if s.day < d:
			s.step_day(d)
	for s: OffMapSettlement in list:
		if s.day < d:
			done = false
	if done and d > day:
		day = d
		var every := int(OffMapSettlement.rules().road_trade_every_days)
		if every > 0 and d % every == every - 1:
			road_trade()
			food_round(d)


## Bring a freshly founded set of settlements to day `to` (an older save), no trade with the village.
func catch_up(to: int) -> void:
	for d in range(day + 1, to + 1):
		step_day(d)


# ------------------------------------------------------------------ the trading parties (REG-PARTY-01) ----------------
## Every holder of every settlement as a trading party (SettlementParty), by id: each settlement's trader, its other businesses,
## its treasury and its living households. `place` limits it to one settlement.
func parties(place := "") -> Array:
	var out := []
	for s: OffMapSettlement in list:
		if place != "" and s.id != place:
			continue
		var types := s.biz.keys()
		types.sort()
		for t in types:
			out.append(SettlementParty.make(self, s, "trader" if t == "merchant" else str(t)))
		out.append(SettlementParty.make(self, s, "treasury"))
		for h in s.hh:
			if h.alive:
				out.append(SettlementParty.make(self, s, "hh:%d" % int(h.id)))
	out.sort_custom(func(a, b): return a.id < b.id)
	return out


## The party a reference names ("region:<settlement>/<holder>" or "<settlement>/<holder>"); null when there is none (an unknown
## settlement or holder, a dissolved household): nothing is guessed.
func party(ref: String) -> SettlementParty:
	var key := ref.trim_prefix("region:")
	var at := key.find("/")
	if at <= 0 or not by_id.has(key.substr(0, at)):
		return null
	var p := SettlementParty.make(self, by_id[key.substr(0, at)], key.substr(at + 1))
	return p if p.alive() and p.holder != "" else null


## The roads between the settlements for RegionalMarket, between places: {"a>b": route}, both ways. The way between two is
## the straight distance of their places on the regional map, along roads (provisional: the settlements are linked by road).
func route_table() -> Dictionary:
	var out := {}
	for a: OffMapSettlement in list:
		for b: OffMapSettlement in list:
			if a.id == b.id:
				continue
			var tiles := maxi(1, roundi(Vector2(a.pos).distance_to(Vector2(b.pos))))
			out[a.id + ">" + b.id] = TradeRoutes.abstract_route(a.id, b.id, tiles, {"road": 1.0}, "carrier")
	return out


## The roads from the village to each settlement and back, for the courier service: {"village>a": route, "a>village": route}.
## The length is the settlement's distance from the village in tiles (settlements.json: its miles times tiles_per_mile, and its
## offset), hauled by a carrier along roads, the same rule as route_table (provisional: the village is at the map's origin).
func village_route_table() -> Dictionary:
	var out := {}
	for a: OffMapSettlement in list:
		var tiles := maxi(1, roundi(Vector2(a.pos).length()))
		out[SettlementFacts.VILLAGE + ">" + a.id] = TradeRoutes.abstract_route(SettlementFacts.VILLAGE, a.id, tiles, {"road": 1.0}, "carrier")
		out[a.id + ">" + SettlementFacts.VILLAGE] = TradeRoutes.abstract_route(a.id, SettlementFacts.VILLAGE, tiles, {"road": 1.0}, "carrier")
	return out


# ------------------------------------------------------------------ who is on the road ----------------
## Visits a settlement's trader makes: every `cadence` visit days of the caravan (the village's visit days are the odd
## days), the nearer sooner (a day's ride in 20 miles). Visit number v = day / 2, so day 0 and 1 are the first: everyone.
static func cadence(s: OffMapSettlement) -> int:
	return maxi(1, ceili(float(s.miles) / 20.0))


func visiting(d: int) -> Array:
	var out := []
	var v := d / 2
	for s: OffMapSettlement in list:
		if v % cadence(s) == 0:
			out.append(s)
	return out


## Open the visit on day `d`: the traders now on the road say what their settlements want. Returns them.
func begin_visit(d: int) -> Array:
	var v := visiting(d)
	for s: OffMapSettlement in v:
		s.begin_visit()
	return v


## The trader, among `from`, that sells `item` (the most stock, then the nearer, then by id); null if none holds any.
func seller_for(item: String, from: Array) -> OffMapSettlement:
	var best: OffMapSettlement = null
	for s: OffMapSettlement in from:
		if s.trader_has(item) <= 0:
			continue
		if best == null or s.trader_has(item) > best.trader_has(item) or (s.trader_has(item) == best.trader_has(item) and s.miles < best.miles):
			best = s
	return best


## The trader, among `from`, who sells `item` food at the lowest price of its settlement (then the most stock, the nearer, by
## id); null if none holds any. Settlements' food prices float, so the village's buyers take the cheapest on the road
## (REG-BUY-01).
func food_seller(item: String, from: Array) -> OffMapSettlement:
	var best: OffMapSettlement = null
	for s: OffMapSettlement in from:
		if s.trader_has(item) <= 0:
			continue
		if best == null or s.food_price(item) < best.food_price(item) \
				or (s.food_price(item) == best.food_price(item) and (s.trader_has(item) > best.trader_has(item)
				or (s.trader_has(item) == best.trader_has(item) and s.miles < best.miles))):
			best = s
	return best


## The trader, among `from`, who takes one `item` at `unit` coins: its settlement still wants it and its till pays (the
## one that wants it most, then the nearer, then by id).
func buyer_for(item: String, unit: int, from: Array) -> OffMapSettlement:
	var best: OffMapSettlement = null
	for s: OffMapSettlement in from:
		if not s.wants_item(item) or s.trader_cash() < unit:
			continue
		if best == null or s.want_left(item) > best.want_left(item) or (s.want_left(item) == best.want_left(item) and s.miles < best.miles):
			best = s
	return best


## The settlement that sells the plough horse on a visit day `d`: its trader is on the road with a horse to lead, the
## nearest first. null when none of the traders on the road today has one.
func horse_dealer(d: int) -> OffMapSettlement:
	var best: OffMapSettlement = null
	for s: OffMapSettlement in visiting(d):
		if s.has_horse() and (best == null or s.miles < best.miles):
			best = s
	return best


# ------------------------------------------------------------------ the traders among themselves ----------------
## A wholesale round: a trader whose settlement has no use for a carried good sells it, at its base value, to a trader
## whose settlement wants it and whose till pays, up to a load. Coins and goods move together; nothing is created.
func road_trade() -> void:
	var carry: Dictionary = OffMapSettlement.rules().carry
	var keep: Dictionary = OffMapSettlement.rules().carry_keep
	var items: Array = carry.keys()
	items.sort()
	var wants := {}
	for s: OffMapSettlement in list:
		wants[s.id] = s.wants()
	for buyer: OffMapSettlement in list:
		var m: Dictionary = buyer.trader()
		if m.is_empty():
			continue
		for item in items:
			var need: int = int(wants[buyer.id].get(item, 0))
			if need <= 0:
				continue
			for seller: OffMapSettlement in list:
				if seller == buyer or need <= 0:
					continue
				var sm: Dictionary = seller.trader()
				if sm.is_empty() or int(wants[seller.id].get(item, 0)) > 0:
					continue
				var spare := int(sm.stock.get(item, 0)) - int(keep.get(item, 0))
				var unit := GameData.value(item)
				# a trader keeps half its trading capital for the village's caravan; only the rest goes on wholesale buying
				var cash := maxi(0, int(m.till) - int(OffMapSettlement.rules().trader_reserve_floor) - int(m.reserve) / 2)
				var n := mini(mini(need, spare), cash / unit)
				n = mini(n, int(OffMapSettlement.rules().carry[item]) - int(m.stock.get(item, 0)))
				if n <= 0:
					continue
				OffMapSettlement._take(sm.stock, item, n)
				OffMapSettlement._add(m.stock, item, n)
				sm.till += n * unit
				m.till -= n * unit
				OffMapSettlement._add(seller.flows.road_out, item, n)
				OffMapSettlement._add(buyer.flows.road_in, item, n)
				seller.flows.road_coins_in += n * unit
				buyer.flows.road_coins_out += n * unit
				need -= n


# ------------------------------------------------------------------ food between the settlements (X20-SETTLE-FOOD) ----------------
## The food round, on the traders' wholesale day (every road_trade_every_days, after road_trade): the owner's REG-BUY-D1 (2026-10-23)
## through the settlements' existing regional market, never a third purchasing path and never a rescue.
##   want     a settlement whose people hold under three days of food, counting food already bought and on the road
##            (OffMapSettlement.wants "_food_pts"), sends its trader to buy; its demand is that shortfall in the traded food
##            (rules.food_trade_items), SettlementParty's trader need;
##   offer    in each other settlement, the farms (and any food business) that grew it sell what their place lets go by the rules
##            it releases food to the village's caravan by (OffMapSettlement.food_release, REG-BUY-P1: only food above its own
##            households' claim over reserve_days, or a business with a demonstrated cash shortfall selling no more than that
##            shortfall), and its trader what it already carries (never food it imported itself); a place that is itself short
##            sells none;
##   price    the seller's own floating price (ask_of) against what the buyer will pay (RegionalMarket.willing: the item's value,
##            up to scarcity_premium more as its store runs out); too dear: no deal ("price");
##   pay      from the buyer trader's own till above its floor and half its trading capital (spend_limit): no coins, no food
##            ("funds");
##   carry    the buyer's trader fetches it itself, one load a round (a pack, or a handcart where its place keeps horses;
##            RegionalMarket.self_capacity); the goods are the buyer's from the sale and arrive after the trip there and back
##            (2 x the route's days, at least 1), at the buyer's first step on or after that day (OffMapSettlement._deliver);
##   books    each line through `transfer` (the one goods-for-coins call, to become the shared LE-03 transaction authority):
##            whole or refused with a code, idempotent by its transaction id, the coins and goods as matched regional_* lines on
##            both settlements (Regions.audit). Nothing is created; nobody pays for anyone else.
## A settlement that cannot find, afford or carry enough food still goes hungry (WDR-022). Returns {lines, unmet, refused, day}.
func food_round(d: int) -> Dictionary:
	var rl := OffMapSettlement.rules()
	var items: Array = rl.get("food_trade_items", [])
	food_last = {"day": d, "lines": [], "unmet": [], "refused": []}
	if items.is_empty():
		return food_last
	var short := []
	var spare := []
	for s: OffMapSettlement in list:
		if float(s.wants().get("_food_pts", 0.0)) > 0.0:
			if not s.trader().is_empty():
				short.append(s)                    # (a place with no trader has nobody to send)
		else:
			if s.trader().has("imported") and s.transit.is_empty():
				s.release_imported()               # its people are provided for: what it imported is ordinary stock again
			spare.append(s)
	if short.is_empty() or spare.is_empty():
		return food_last
	var ls: Array = []
	var routes := route_table()
	for s: OffMapSettlement in short:
		ls.append(SettlementParty.make(self, s, "trader"))
	for o: OffMapSettlement in spare:
		if not o.trader().is_empty():
			var t := SettlementParty.make(self, o, "trader")
			t.sells_only = true                    # food its trader already carries (never food it imported: sale_cap)
			ls.append(t)
		var rel := o.food_release(items)
		var types: Array = rel.keys()
		types.sort()
		for bt in types:
			var f := SettlementParty.make(self, o, "trader" if bt == "merchant" else str(bt))
			f.sells_only = true
			f.release = rel[bt]
			ls.append(f)
	var p := RegionalMarket.plan(ls, routes, [], false, items)
	var e := {"done": [], "refused": []}
	for line in p.lines:
		var sb: OffMapSettlement = by_id[str(line.buyer).get_slice("/", 0)]
		var ss: OffMapSettlement = by_id[str(line.seller).get_slice("/", 0)]
		var due := d + trip_days(ss.id, sb.id, routes)
		var res := ship_line(line, d, due)
		line["tx"] = str(res.get("txid", ""))
		if bool(res.ok):
			sb.await_shipment(str(line.tx), "trader", str(line.item), int(line.units), "region:" + str(line.seller), d, due, int(line.total))
			line["due"] = due
			e.done.append(line)
		else:
			line["code"] = str(res.code)
			e.refused.append(line)
	for line in e.done:
		var sb: OffMapSettlement = by_id[str(line.buyer).get_slice("/", 0)]
		var ss: OffMapSettlement = by_id[str(line.seller).get_slice("/", 0)]
		sb.flows.food_bought += int(line.units)
		ss.flows.food_sold += int(line.units)
		sb.note("Our traders bought %d %s in %s for %d coins; it is on the road, %d days from home." % [int(line.units),
			GameData.item_name(str(line.item)).to_lower(), ss.name, int(line.total), int(line.due) - d])
		ss.note("Our traders sold %d %s to %s for %d coins, paid when it arrives." % [int(line.units), GameData.item_name(str(line.item)).to_lower(), sb.name, int(line.total)])
		_food_event("bought", {"line": line, "due": int(line.due)})
	for u in p.unmet:
		var su: OffMapSettlement = by_id[str(u.buyer).get_slice("/", 0)]
		su.flows.food_unmet += int(u.units)
		su.note("Our traders could not buy %d %s for our people: %s." % [int(u.units), GameData.item_name(str(u.item)).to_lower(),
			{"price": "it was too dear", "funds": "they had no money to spare", "no supplier": "no other place had any to spare",
			"no carriage": "they could carry no more"}.get(str(u.reason), str(u.reason))])
		_food_event("unmet", {"unmet": u})
	for line in e.refused:
		_food_event("refused", {"line": line})
	food_last = {"day": d, "lines": e.done, "unmet": p.unmet, "refused": e.refused}
	return food_last


## Days from a purchase in `from` to its arrival in `to`: the buyer's trader goes there and back (2 x the route's days, at least 1).
func trip_days(from: String, to: String, routes := {}) -> int:
	var rt: Dictionary = (routes if not routes.is_empty() else route_table()).get(from + ">" + to, {})
	return maxi(1, ceili(2.0 * float(rt.get("days", 0.5)) - 1e-9))


# ------------------------------------------------------------------ the transaction step (X20-SETTLE-FOOD; LE-03 authority) ----------------
## The settlement food trade's ONE goods-for-coins step: a plan line becomes a shipment through the transaction authority
## (docs/expansion20/TRANSACTION_AUTHORITY.md, Worker A, LE-03): `ship` takes the seller's goods into transit custody (still the
## seller's) and the buyer's price into escrow (still the buyer's), together or not at all; the buyer's settlement later asks for
## `deliver` (goods to the buyer, escrow to the seller) or, when it cannot be, `fail` (goods back, price refunded). Each attempt has a
## new id "settle_food/<buyer settlement>:<seq>" (`food_seq`, saved), so an id executes at most once whatever retries, reloads or
## replays follow. Rejection codes are the authority's (no_stock, no_funds, party_unavailable, ...), nothing moved.
##
## When the world has the authority (`World.transactions`) every call goes to it. Until that lands on this branch, and for the
## settlements alone (tests, regions_sim), a TEMPORARY stand-in with the same calls, codes and holdings (`food_custody`, saved) does
## the same; it is removed when the branch is integrated with LE-03 (owner direction 2026-10-30: no second permanent path).
func ship_line(line: Dictionary, d: int, due: int) -> Dictionary:
	var place := str(line.buyer).get_slice("/", 0)
	var ns := "settle_food/" + place
	food_seq[ns] = int(food_seq.get(ns, 0)) + 1
	var txid := "%s:%d" % [ns, int(food_seq[ns])]
	return tx_ship(txid, "region:" + str(line.buyer), "region:" + str(line.seller), str(line.item), int(line.units), int(line.total), due)


func _authority():
	var w = _world.get_ref() if _world != null else null
	if w != null and "transactions" in w and w.get("transactions") != null:
		return w.get("transactions")
	return null


func tx_ship(txid: String, buyer: String, seller: String, item: String, qty: int, total: int, due_day: int) -> Dictionary:
	var a = _authority()
	if a != null:
		return a.ship(txid, buyer, seller, item, qty, total, due_day)
	var seen = _tx_seen(txid)
	if seen != null:
		return seen
	var res := _tx_check(txid, buyer, seller, item, qty, total)
	if bool(res.ok):
		var b := party(buyer)
		var s := party(seller)
		s.remove(item, qty)
		b.outside_coins(-total)
		food_custody.shipments.append({"txid": txid, "buyer": buyer, "seller": seller, "item": item, "qty": qty, "total": total,
			"due_day": due_day, "state": "open"})
		res.state = "open"
	return _tx_record(txid, res)


func tx_deliver(txid: String) -> Dictionary:
	var a = _authority()
	if a != null:
		return a.deliver(txid)
	return _tx_close(txid, "delivered", "")


func tx_fail(txid: String, why: String) -> Dictionary:
	var a = _authority()
	if a != null:
		return a.fail(txid, why)
	return _tx_close(txid, "failed", why)


## Goods and coins in transit custody and escrow between two settlements (the authority's in_transit() less its village part):
## held by nobody's books but the authority's, so Regions.coins/goods count them as a holder.
func tx_in_transit() -> Dictionary:
	var a = _authority()
	if a != null:
		var t: Dictionary = a.in_transit()
		var g := {}
		for k in t.get("goods", {}):
			var n := int(t.goods[k]) - int(t.get("village_goods", {}).get(k, 0))
			if n != 0:
				g[k] = n
		return {"coins": int(t.get("coins", 0)) - int(t.get("village_coins", 0)), "goods": g}
	var out := {"coins": 0, "goods": {}}
	for sh in food_custody.shipments:
		if str(sh.state) == "open":
			out.coins += int(sh.total)
			OffMapSettlement._add(out.goods, str(sh.item), int(sh.qty))
	return out


func tx_shipment(txid: String) -> Dictionary:
	var a = _authority()
	if a != null:
		return a.get_shipment(txid)
	for sh in food_custody.shipments:
		if str(sh.txid) == txid:
			return (sh as Dictionary).duplicate()
	return {}


# --- the stand-in's own rules (the authority's sections 4 to 6, for settlement parties)
func _tx_seen(txid: String):
	var at := txid.rfind(":")
	if at <= 0 or not txid.substr(at + 1).is_valid_int() or int(txid.substr(at + 1)) <= 0:
		return {"ok": false, "code": "bad_id", "txid": txid, "replay": false, "state": ""}
	var ns := txid.substr(0, at)
	if int(txid.substr(at + 1)) <= int(food_custody.marks.get(ns, 0)):
		var o = food_custody.outcomes.get(txid)
		if o == null:
			return {"ok": false, "code": "stale_id", "txid": txid, "replay": true, "state": ""}
		var r: Dictionary = (o as Dictionary).duplicate()
		r.replay = true
		return r
	return null


func _tx_check(txid: String, buyer: String, seller: String, item: String, qty: int, total: int) -> Dictionary:
	var res := {"ok": false, "code": "", "txid": txid, "replay": false, "state": ""}
	if qty <= 0 or total < 0 or item == "" or item == "coins":
		res.code = "invalid_quantity"
	elif buyer == seller:
		res.code = "same_party"
	elif not buyer.begins_with("region:") or not seller.begins_with("region:"):
		res.code = "unsupported_party"
	else:
		var b := party(buyer)
		var s := party(seller)
		if b == null or s == null:
			res.code = "unknown_party" if not by_id.has(buyer.trim_prefix("region:").get_slice("/", 0)) or not by_id.has(seller.trim_prefix("region:").get_slice("/", 0)) else "party_unavailable"
		elif s.held(item) < qty:
			res.code = "no_stock"
		elif b.purse() < total:
			res.code = "no_funds"
		elif not b.can_hold(item):
			res.code = "no_room"
		else:
			res.ok = true
	return res


func _tx_record(txid: String, res: Dictionary) -> Dictionary:
	if str(res.code) in ["bad_id"]:
		return res
	var at := txid.rfind(":")
	var ns := txid.substr(0, at)
	food_custody.marks[ns] = maxi(int(food_custody.marks.get(ns, 0)), int(txid.substr(at + 1)))
	food_custody.outcomes[txid] = res.duplicate()
	return res


func _tx_close(txid: String, to_state: String, why: String) -> Dictionary:
	for sh in food_custody.shipments:
		if str(sh.txid) != txid:
			continue
		if str(sh.state) != "open":
			return {"ok": str(sh.state) == to_state, "code": "duplicate" if str(sh.state) == to_state else "not_open", "txid": txid, "replay": true, "state": str(sh.state)}
		var b := party(str(sh.buyer))
		var s := party(str(sh.seller))
		# delivered: goods to the buyer, escrow to the seller; failed: goods back to the seller, escrow back to the buyer
		var gets_goods: SettlementParty = b if to_state == "delivered" else s
		var gets_coins: SettlementParty = s if to_state == "delivered" else b
		if gets_goods == null or gets_coins == null:
			return {"ok": false, "code": "party_unavailable", "txid": txid, "replay": false, "state": "open"}
		gets_goods.add(str(sh.item), int(sh.qty))
		gets_coins.outside_coins(int(sh.total))
		sh.state = to_state
		if why != "":
			sh["why"] = why
		_tx_prune()
		return {"ok": true, "code": "", "txid": txid, "replay": false, "state": to_state}
	return {"ok": false, "code": "not_found", "txid": txid, "replay": false, "state": ""}


## Keep every open shipment and the last TX_KEEP closed ones; the last TX_KEEP outcomes a namespace (the authority's keep_outcomes).
func _tx_prune() -> void:
	var closed: Array = food_custody.shipments.filter(func(x): return str(x.state) != "open")
	while closed.size() > TX_KEEP:
		food_custody.shipments.erase(closed.pop_front())
	var keys: Array = food_custody.outcomes.keys()
	if keys.size() > TX_KEEP * maxi(1, list.size()):
		keys.sort_custom(func(x, y): return _tx_order(x) < _tx_order(y))
		for k in keys.slice(0, keys.size() - TX_KEEP * maxi(1, list.size())):
			food_custody.outcomes.erase(k)


static func _tx_order(txid: String) -> String:
	var at := txid.rfind(":")
	return "%s:%012d" % [txid.substr(0, at), int(txid.substr(at + 1))]


## The buyer's settlement asks for its shipment at the due day's step (OffMapSettlement._deliver): delivered when it can be; a
## shipment whose buyer can no longer take it is failed (goods back to the seller, price refunded) once it is `food_lapse_days` late.
func _arrive(e: Dictionary, today: int) -> Dictionary:
	var res := tx_deliver(str(e.tx))
	if not bool(res.ok) and str(res.code) == "party_unavailable" and today - int(e.due) >= int(OffMapSettlement.rules().get("food_lapse_days", 6)):
		res = tx_fail(str(e.tx), "undeliverable")
	return res


## The flight recorder's record of the food trade (REC-DIAG), when the settlements live in a world that records: a purchase, a buyer
## left short (with the reason), a refused line, and a delivery (to the trader, or to the granary of a place whose trader is gone).
func _food_event(what: String, info: Dictionary) -> void:
	var w = _world.get_ref() if _world != null else null
	if w == null or w.recorder == null:
		return
	var rec = w.recorder
	match what:
		"bought":
			var l: Dictionary = info.line
			var b := "settlement:" + str(l.buyer).get_slice("/", 0)
			var sl := "settlement:" + str(l.seller).get_slice("/", 0)
			rec.occurrence("world", "settlement", "transaction", "settlement_food_purchase", b, [[b, "buyer"], [sl, "seller"]], [], "ok", "",
				"item=%s; units=%d; coins=%d; due=%d" % [str(l.item), int(l.units), int(l.total), int(info.due)])
		"unmet":
			var u: Dictionary = info.unmet
			var b := "settlement:" + str(u.buyer).get_slice("/", 0)
			var why := str({"price": "refused_by_rules", "funds": "buyer_short_of_coins", "no supplier": "seller_lacks_item",
				"no carriage": "pack_full"}.get(str(u.reason), "not_feasible"))
			rec.occurrence("world", "settlement", "transaction", "settlement_food_unmet", b, [[b, "buyer"]], [], "failed", why,
				"item=%s; units=%d; reason=%s" % [str(u.item), int(u.units), str(u.reason)])
		"refused":
			var l: Dictionary = info.line
			var b := "settlement:" + str(l.buyer).get_slice("/", 0)
			var code := str(l.get("code", ""))
			rec.occurrence("world", "settlement", "transaction", "settlement_food_purchase", b, [[b, "buyer"]], [], "refused",
				{"no_stock": "seller_lacks_item", "no_funds": "buyer_short_of_coins", "no_room": "to_cannot_take"}.get(code, "invalid_trade"),
				"item=%s; units=%d; seller=%s" % [str(l.item), int(l.units), str(l.seller)])
		"delivered":
			var e: Dictionary = info.entry
			var b := "settlement:" + str(info.settlement)
			# a delivery to a place with no household left is the trade meeting abandonment (interrupted); a shipment failed and
			# refunded is a failed delivery
			var st := str(info.state)
			var outcome := "failed" if st != "delivered" else ("ok" if int(info.households) > 0 else "interrupted")
			rec.occurrence("world", "settlement", "transaction", "settlement_food_delivery", b, [[b, "buyer"]], [],
				outcome, "" if outcome == "ok" else ("target_gone" if outcome == "interrupted" else "not_reached"),
				"item=%s; units=%d; tx=%s; from=%s; state=%s; households=%d" % [str(e.item), int(e.n), str(e.tx), str(e.from), st, int(info.households)])


# ------------------------------------------------------------------ books ----------------
## The settlements' coins, and the price of food shipments between them held in escrow (X20-SETTLE-FOOD: still the buyers', in the
## transaction authority's hands while the goods travel: a holder like the courier booths).
func coins() -> int:
	var n := int(tx_in_transit().coins)
	for s: OffMapSettlement in list:
		n += s.coins()
	return n


## The settlements' goods, and the food on the road between them (still the sellers', in transit custody).
func goods() -> Dictionary:
	var g := (tx_in_transit().goods as Dictionary).duplicate()
	for s: OffMapSettlement in list:
		var sg := s.goods()
		for k in sg:
			g[k] = int(g.get(k, 0)) + int(sg[k])
	return g


func population() -> int:
	var n := 0
	for s: OffMapSettlement in list:
		n += s.population()
	return n


## "" when every settlement's books balance and the coins among them are conserved (what the traders pay each other
## balances: the road coins and the parties' regional coins and goods in and out cancel), else the first thing that does not.
func audit() -> String:
	var rin := 0
	var rout := 0
	var gin := {}
	var gout := {}
	var xin := 0
	var xout := 0
	var xgin := {}
	var xgout := {}
	for s: OffMapSettlement in list:
		var e := s.audit()
		if e != "":
			return e
		xin += int(s.flows.regional_coins_in)
		xout += int(s.flows.regional_coins_out)
		for k in s.flows.regional_in:
			xgin[k] = int(xgin.get(k, 0)) + int(s.flows.regional_in[k])
		for k in s.flows.regional_out:
			xgout[k] = int(xgout.get(k, 0)) + int(s.flows.regional_out[k])
		rin += int(s.flows.road_coins_in)
		rout += int(s.flows.road_coins_out)
		for k in s.flows.road_in:
			gin[k] = int(gin.get(k, 0)) + int(s.flows.road_in[k])
		for k in s.flows.road_out:
			gout[k] = int(gout.get(k, 0)) + int(s.flows.road_out[k])
	if rin != rout:
		return "road coins in %d, out %d" % [rin, rout]
	if gin != gout:
		return "road goods in %s, out %s" % [str(gin), str(gout)]
	if xin != xout:
		return "regional coins in %d, out %d" % [xin, xout]
	if xgin != xgout:
		return "regional goods in %s, out %s" % [str(xgin), str(xgout)]
	return _shipments_audit()


## X20-SETTLE-FOOD: every open food shipment is awaited by its buyer's settlement and every awaited one is open (no orphan: goods
## that would never be delivered or refunded), and nothing in transit is negative.
func _shipments_audit() -> String:
	var t := tx_in_transit()
	if int(t.coins) < 0:
		return "escrow %d" % int(t.coins)
	for k in t.goods:
		if int(t.goods[k]) < 0:
			return "in transit %s %d" % [k, int(t.goods[k])]
	var awaited := {}
	for s: OffMapSettlement in list:
		for e in s.transit:
			awaited[str(e.tx)] = s.id
			var sh := tx_shipment(str(e.tx))
			if sh.is_empty() or str(sh.state) != "open":
				return "%s awaits shipment %s, which is %s" % [s.id, str(e.tx), "unknown" if sh.is_empty() else str(sh.state)]
	for sh in food_custody.shipments:
		if str(sh.state) == "open" and not awaited.has(str(sh.txid)):
			return "shipment %s is open but no settlement awaits it" % str(sh.txid)
	return ""


## Coins that crossed the village's boundary: what the village paid the settlements, less what they paid it (the
## village's own coin_sources moves the opposite way).
func net_paid_by_village() -> int:
	var n := 0
	for s: OffMapSettlement in list:
		n += int(s.flows.coins_from_village) - int(s.flows.coins_to_village)
		n += int(s.flows.outside_coins_in) - int(s.flows.outside_coins_out)     # REG-COURIER-01: coins the couriers carried across
	return n + int(tx_in_transit().coins)      # X20-SETTLE-FOOD: escrow left a settlement's books as an outside line but never left the region


## An older save's caravan purse: its coins become the traders' (spread evenly over the traders, the rest to the first).
func add_migrated(coins_: int) -> void:
	var traders := []
	for s: OffMapSettlement in list:
		if not s.trader().is_empty():
			traders.append(s)
	var each: int = coins_ / maxi(1, traders.size())
	for i in traders.size():
		var s: OffMapSettlement = traders[i]
		var n: int = each + (coins_ - each * traders.size() if i == 0 else 0)
		s.trader().till += n
		s.flows.migrated_in += n
	migrated_coins += coins_


## Test hook (never used by the game): the trader of settlement `id` can spend `coins_` (above its floor) and every other trader
## nothing, so a test can give the caravan exactly the purse it wants; every settlement's books are reopened from there. The
## coins this makes or removes are outside the village's accounts: a test that uses it measures the village's side only.
func fund_only(id: String, coins_: int) -> void:
	var floor_coins := int(OffMapSettlement.rules().trader_reserve_floor)
	for s: OffMapSettlement in list:
		if not s.trader().is_empty():
			s.trader().till = floor_coins + (coins_ if s.id == id else 0)
		s.reopen_books()


## Test hook (never used by the game): every trader can spend an equal share of `total` coins (above its floor).
func fund_traders(total: int) -> void:
	var floor_coins := int(OffMapSettlement.rules().trader_reserve_floor)
	var n := 0
	for s: OffMapSettlement in list:
		if not s.trader().is_empty():
			n += 1
	for s: OffMapSettlement in list:
		if not s.trader().is_empty():
			s.trader().till = floor_coins + total / maxi(1, n)
		s.reopen_books()


func summary() -> Array:
	return list.map(func(s): return s.summary())


## A move between the village and a settlement (Migration): into the log and the counts.
func log_move(m: Dictionary) -> void:
	moves.append(m)
	if moves.size() > Migration.LOG_MAX:
		moves.pop_front()
	var k := "%s:%s" % [m.dir, m.reason]
	move_counts[k] = int(move_counts.get(k, 0)) + int(m.people)


## People who moved from the village to the settlements, net, as the settlements' books say (their `migrants_in` less `migrants_out`).
func net_migrants_from_village() -> int:
	var n := 0
	for s: OffMapSettlement in list:
		n += int(s.flows.migrants_in) - int(s.flows.migrants_out)
	return n


## The same, as the log's counts say (people out of the village less people into it): must equal net_migrants_from_village.
func net_migrants_counted() -> int:
	var n := 0
	for k in move_counts:
		n += int(move_counts[k]) * (1 if str(k).begins_with("out:") else -1)
	return n


# ------------------------------------------------------------------ saving ----------------
func to_dict() -> Dictionary:
	return {"format": FORMAT, "day": day, "migrated_coins": migrated_coins, "settlements": list.map(func(s): return s.to_dict()),
		"moves": moves.duplicate(true), "move_counts": move_counts.duplicate(), "suits": suits.duplicate(true),
		"food_seq": food_seq.duplicate(), "food_custody": food_custody.duplicate(true)}


## The settlements of a save's "regions" section; an unknown format is refused (null), never reinterpreted.
static func from_dict(d: Dictionary, seed_: int) -> Regions:
	if str(d.get("format", "")) != FORMAT:
		return null
	var r := Regions.new()
	r.world_seed = seed_
	r.day = int(d.day)
	r.migrated_coins = int(d.get("migrated_coins", 0))
	for sd in d.settlements:
		r._add(OffMapSettlement.from_dict(sd))
	for m in d.get("moves", []):                              # MIGRATE-18 (optional keys: an older save has no moves)
		r.moves.append({"day": int(m.day), "settlement": str(m.settlement), "dir": str(m.dir), "reason": str(m.reason),
			"people": int(m.people), "coins": int(m.coins), "goods": int(m.goods)})
	for k in d.get("move_counts", {}):
		r.move_counts[str(k)] = int(d.move_counts[k])
	for k in d.get("food_seq", {}):                           # X20-SETTLE-FOOD (optional keys)
		r.food_seq[str(k)] = int(d.food_seq[k])
	var fc: Dictionary = d.get("food_custody", {})
	for k in fc.get("marks", {}):
		r.food_custody.marks[str(k)] = int(fc.marks[k])
	for k in fc.get("outcomes", {}):
		var o: Dictionary = fc.outcomes[k]
		r.food_custody.outcomes[str(k)] = {"ok": bool(o.ok), "code": str(o.code), "txid": str(o.txid), "replay": bool(o.get("replay", false)), "state": str(o.get("state", ""))}
	for sh in fc.get("shipments", []):
		var x: Dictionary = (sh as Dictionary).duplicate()
		for k in ["qty", "total", "due_day"]:
			x[k] = int(x[k])
		r.food_custody.shipments.append(x)
	for k in d.get("suits", {}):
		r.suits[str(k)] = {"pair": str(d.suits[k].pair), "since": int(d.suits[k].since)}
	return r
