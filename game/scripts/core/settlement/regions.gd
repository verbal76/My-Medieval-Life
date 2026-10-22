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

var list: Array = []                 # OffMapSettlement, in data order
var by_id: Dictionary = {}
var day := -1                        # the last day stepped
var migrated_coins := 0              # coins an older save's caravan purse brought (traders' tills): outside coins that existed
var world_seed := 0
var journal: Array = []              # the parties' exchange lines (SettlementParty.deal): {day, party, kind, item, n, coins, with}; not saved
var party_options := {}              # fixtures' settings per party id (SettlementParty.option); not saved


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


# ------------------------------------------------------------------ books ----------------
func coins() -> int:
	var n := 0
	for s: OffMapSettlement in list:
		n += s.coins()
	return n


func goods() -> Dictionary:
	var g := {}
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
	return ""


## Coins that crossed the village's boundary: what the village paid the settlements, less what they paid it (the
## village's own coin_sources moves the opposite way).
func net_paid_by_village() -> int:
	var n := 0
	for s: OffMapSettlement in list:
		n += int(s.flows.coins_from_village) - int(s.flows.coins_to_village)
	return n


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


# ------------------------------------------------------------------ saving ----------------
func to_dict() -> Dictionary:
	return {"format": FORMAT, "day": day, "migrated_coins": migrated_coins, "settlements": list.map(func(s): return s.to_dict())}


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
	return r
