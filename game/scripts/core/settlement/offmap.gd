class_name OffMapSettlement
extends RefCounted
## Expansion 18 (SET-C-SIM; owner Q18-3, 2026-10-23: "Those settlements have simulated economies just like this one, it comes
## from their villagers, or village political structure or companies"; follow-up: "same rules, lighter detail"): ONE off-map
## settlement as a small economy of its own, stepped once a day without walking anyone.
##
##   households   members (adults, children), a purse, a pantry; they work for a business or serve the government, buy food
##                and the goods of daily life in the settlement's market, pay tax, eat, and go hungry when they cannot
##                (a household that starves loses its members; an empty one is dissolved and its coins and food pass
##                to the treasury)
##   businesses   farm, herd, forest, quarry, sawyer, mason, smith, tanner, cook, weaver, healer, merchant: each
##                with its own till, stock and workers (households); natural output (fields, woods, a quarry's finite
##                reserve) or the village's real recipes (game/data/recipes.json) from inputs it bought; it pays its
##                workers from its till above its working reserve and pays tax
##   treasury     the manor, abbey or council: collects the village's tax rule (balance.json tax_rate_*, tax_exemption_*)
##                from households and businesses, pays its officials, buys the settlement's upkeep goods and relieves a
##                hungry household with food it buys
##   market       one price per good, floating with yesterday's imbalance inside the village's own band (price_min,
##                price_max); every sale moves goods and coins together
## The merchants are the settlement's TRADER (owner ECON-P1.3, 2026-10-23): the only party that meets the village's
## caravan (Regions, NPCBrain.caravan) and other settlements' traders; it carries only what its own stock holds and pays only
## from its own till.
##
## Conservation (SIM rules): coins and goods change only by the lines in `flows`, so
##   coins(now) = start + coins_from_village - coins_to_village + road_coins_in - road_coins_out + migrated_in
##   goods(now) = start + produced - used + from_village - to_village + road_in - road_out
## and `audit()` checks both. Nothing is created but natural output (fields, woods, quarries, herbs) and nothing is
## destroyed but use (eating, recipes' inputs, upkeep).
##
## Deterministic: a settlement is made once from (world seed, index) and every step after that uses no random numbers.
## Everything is plain Dictionaries and Arrays (saved as they are).

const FORMAT := "mml-offmap/1"
const TRADE_BIZ := {"farmer": "farm", "herder": "herd", "forester": "forest", "miner": "quarry", "sawyer": "sawyer",
	"mason": "mason", "smith": "smith", "tanner": "tanner", "cook": "cook", "weaver": "weaver", "healer": "healer",
	"merchant": "merchant"}
const PREPARED := ["pottage", "roast_meat", "bread", "cheese"]       # foods the cookshop makes (a share of a household's food)
const PREPARED_SHARE := 0.3
const FLOW_GOODS := ["produced", "used", "from_village", "to_village", "road_in", "road_out", "unmet"]
const FLOW_COUNTS := ["coins_from_village", "coins_to_village", "road_coins_in", "road_coins_out", "migrated_in", "deaths",
	"wage_short", "relief_units", "tax_households", "tax_businesses", "wages_paid", "official_pay", "horses_foaled",
	"horses_died", "horses_sold", "horses_start", "tolls", "day_labour", "job_moves"]

static var _data := {}
static var _rules := {}               # _data.rules and _data.business_types, once loaded (the step reads them thousands of times)
static var _types := {}
static var profile := false              # diagnostics (tests/regions_sim.gd --profile): microseconds a phase of the step took
static var laps := {}
static var _pts_cache := {}
static var _val_cache := {}

var id := ""
var name := ""
var kind := ""
var gov_name := ""
var miles := 0
var pos := Vector2i.ZERO
var industries: Array = []
var hh: Array = []                   # households: {id, trade, adults, children, coins, pantry{}, credit, hungry, acc{}, alive}
var biz: Dictionary = {}             # business type -> {type, workers[], till, stock{}, reserves{}, out{}, acc{}, reserve, horses, foal, fed_miss}
var gov: Dictionary = {}             # {coins, granary{}, officials[], acc{}}
var prices: Dictionary = {}          # item -> float, the market price (today's whole-coin price is its rounding)
var flows: Dictionary = {}
var start: Dictionary = {}           # the opening books {coins, goods}
var day := -1
var _dem: Dictionary = {}            # today's requests and offers (not saved)
var _sup: Dictionary = {}
var _offers: Dictionary = {}         # item -> [{b, n}] while the market is open
var _pcache: Dictionary = {}         # today's whole-coin prices (cleared when a day starts and when prices move)
var _avail: Dictionary = {}          # item -> units on offer in all open offers
var _toll_acc := 0.0
var _want_left: Dictionary = {}      # what the settlement still wants this visit (begin_visit)


# ------------------------------------------------------------------ data ----------------
static func data() -> Dictionary:
	if _data.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string("res://data/settlements.json"))
		assert(d is Dictionary, "bad data file settlements.json")
		_data = d
		_rules = d.rules
		_types = d.business_types
	return _data


static func rules() -> Dictionary:
	data()
	return _rules


static func btype(t: String) -> Dictionary:
	return _types.get(t, {})


static func _add(d: Dictionary, k: String, n: int) -> void:
	if n != 0:
		d[k] = int(d.get(k, 0)) + n
		if int(d[k]) == 0:
			d.erase(k)


## Take up to `n` of `k` from `d`; returns how many were taken.
static func _take(d: Dictionary, k: String, n: int) -> int:
	var t := mini(n, int(d.get(k, 0)))
	if t > 0:
		_add(d, k, -t)
	return t


## A fractional accumulator or price rounded to a millionth (the fraction as a decimal that prints and parses back to the same
## number), so a saved and reloaded settlement is the same to the last digit and goes on exactly as the original would.
static func _q(v: float) -> float:
	return float(roundi(v * 1000000.0)) / 1000000.0


static func _pts(item: String) -> float:
	if not _pts_cache.has(item):
		_pts_cache[item] = NPCBrain.food_points(item)
	return _pts_cache[item]


static func _val(item: String) -> float:
	if not _val_cache.has(item):
		_val_cache[item] = float(GameData.value(item))
	return _val_cache[item]


# ------------------------------------------------------------------ making ----------------
## A settlement as the data describes it, its people and stocks drawn once from the world seed.
static func create(spec: Dictionary, world_seed: int, index: int) -> OffMapSettlement:
	var s := OffMapSettlement.new()
	s.id = str(spec.id)
	s.name = str(spec.name)
	s.kind = str(spec.kind)
	s.miles = int(spec.miles)
	s.pos = Vector2i(int(spec.get("x", 0)), s.miles * int(data().tiles_per_mile))
	s.industries = (spec.get("industries", []) as Array).duplicate()
	s.gov_name = str(spec.government.name)
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed * 7919 + (index + 1) * 104729 + 17
	var trades: Dictionary = spec.trades
	var tids := trades.keys()
	tids.sort()
	var pantry_per := int(GameData.b("start_household_wheat_per_member"))
	for t in tids:
		for k in int(trades[t]):
			var adults := 1 + (1 if rng.randf() < 0.6 else 0)
			var children := rng.randi_range(0, 3) if adults == 2 else rng.randi_range(0, 1)
			var h := {"id": s.hh.size(), "trade": t, "adults": adults, "children": children,
				"coins": rng.randi_range(int(data().rules.household_coins[0]), int(data().rules.household_coins[1])), "pantry": {"wheat": pantry_per * (adults + children)},
				"credit": 0.0, "hungry": 0, "acc": {}, "alive": true, "inc": 0, "stay": 0}
			s.hh.append(h)
	var quarry_out: Dictionary = spec.get("quarry", {})
	var reserves: Dictionary = spec.get("reserves", {})
	var tills: Dictionary = spec.get("tills", {})
	var starts: Dictionary = spec.get("start", {})
	for h in s.hh:
		if h.trade == "official":
			continue
		var bt: String = TRADE_BIZ[h.trade]
		if not s.biz.has(bt):
			var T := btype(bt)
			var b := {"type": bt, "workers": [], "till": int(tills.get(bt, int(data().rules.business_till))), "stock": {}, "reserves": {},
				"out": (T.get("out", {}) as Dictionary).duplicate(), "acc": {}, "reserve": int(T.get("reserve", 12)),
				"horses": 0, "foal": 0, "fed_miss": 0, "paid": 0, "week": 0}
			if bt == "quarry":
				b.out = quarry_out.duplicate()
				for k in reserves:
					b.reserves[k] = int(reserves[k])
			for k in starts.get(bt, {}):
				b.stock[k] = int(starts[bt][k])
			if bt == "merchant":
				b.reserve = int(float(b.till) * 0.85)         # a trader keeps its trading capital; only the margin above it is paid out
			if bt == "farm":
				b.horses = int(spec.get("horses", 0))          # the settlement's working horses (the traders lead them to the road)
			s.biz[bt] = b
		s.biz[bt].workers.append(h.id)
	for t in s.biz:                                   # every trade starts with the tools it wants in hand
		var T := btype(t)
		for tool in T.get("tools", {}):
			_add(s.biz[t].stock, tool, s._tool_stock(T, tool, s.biz[t].workers.size()))
	s.gov = {"coins": int(spec.government.coins), "granary": {}, "officials": [], "acc": {}}
	for h in s.hh:
		if h.trade == "official":
			s.gov.officials.append(h.id)
	s.flows = _blank_flows()
	s.flows.horses_start = s.horses()
	s.start = {"coins": s.coins(), "goods": s.goods()}
	return s


static func _blank_flows() -> Dictionary:
	var f := {}
	for k in FLOW_GOODS:
		f[k] = {}
	for k in FLOW_COUNTS:
		f[k] = 0
	return f


# ------------------------------------------------------------------ books ----------------
func coins() -> int:
	var n := int(gov.coins)
	for h in hh:
		n += int(h.coins)
	for t in biz:
		n += int(biz[t].till)
	return n


func goods() -> Dictionary:
	var g := {}
	for h in hh:
		for k in h.pantry:
			_add(g, k, int(h.pantry[k]))
	for t in biz:
		for k in biz[t].stock:
			_add(g, k, int(biz[t].stock[k]))
	for k in gov.granary:
		_add(g, k, int(gov.granary[k]))
	return g


func horses() -> int:
	return int(biz.farm.horses) if biz.has("farm") else 0


func population() -> int:
	var n := 0
	for h in hh:
		if h.alive:
			n += int(h.adults) + int(h.children)
	return n


func households() -> int:
	var n := 0
	for h in hh:
		if h.alive:
			n += 1
	return n


func treasury() -> int:
	return int(gov.coins)


func trader() -> Dictionary:
	return biz.get("merchant", {})


## "" when every coin and good is accounted for by a flow line, else what is not.
func audit() -> String:
	var f := flows
	var want_c: int = int(start.coins) + int(f.coins_from_village) - int(f.coins_to_village) + int(f.road_coins_in) \
		- int(f.road_coins_out) + int(f.migrated_in)
	if want_c != coins():
		return "%s coins %d, books say %d" % [id, coins(), want_c]
	var have := goods()
	var ids := {}
	for k in start.goods:
		ids[k] = true
	for k in have:
		ids[k] = true
	for k in ids:
		var w := int(start.goods.get(k, 0)) + int(f.produced.get(k, 0)) - int(f.used.get(k, 0)) + int(f.from_village.get(k, 0)) \
			- int(f.to_village.get(k, 0)) + int(f.road_in.get(k, 0)) - int(f.road_out.get(k, 0))
		if w != int(have.get(k, 0)):
			return "%s %s %d, books say %d" % [id, k, int(have.get(k, 0)), w]
	var hs := int(f.horses_start) + int(f.horses_foaled) - int(f.horses_died) - int(f.horses_sold)
	if hs != horses():
		return "%s horses %d, books say %d" % [id, horses(), hs]
	return ""


# ------------------------------------------------------------------ prices ----------------
func price(item: String) -> int:
	var p = _pcache.get(item)
	if p == null:
		p = maxi(1, roundi(float(prices.get(item, _val(item)))))
		_pcache[item] = p
	return p


func _need_pts(h: Dictionary) -> float:
	return (float(h.adults) + float(h.children) * float(GameData.b("child_food_factor"))) * 24.0 * float(GameData.b("hunger_per_hour"))


## What a day's food costs a household at today's price of wheat, the cheapest staple.
func _day_food_cost(h: Dictionary) -> int:
	return ceili(_need_pts(h) / _pts("wheat")) * price("wheat")


func _pantry_pts(h: Dictionary) -> float:
	var p := 0.0
	for f in _rules.foods:
		p += float(h.pantry.get(f, 0)) * _pts(f)
	return p + float(h.credit)


func _update_prices() -> void:
	var step := float(_rules.price_step)
	var lo := float(GameData.b("price_min"))
	var hi := float(GameData.b("price_max"))
	var ids := {}
	for k in _dem:
		ids[k] = true
	for k in _sup:
		ids[k] = true
	var keys := ids.keys()
	keys.sort()
	for k in keys:
		var d := float(_dem.get(k, 0))
		var s := float(_sup.get(k, 0))
		var v := float(_val(k))
		var p := float(prices.get(k, v)) * (1.0 + step * (d - s) / maxf(1.0, maxf(d, s)))
		prices[k] = _q(clampf(p, v * lo, v * hi))


# ------------------------------------------------------------------ the day ----------------
func step_day(d: int) -> void:
	data()
	day = d
	_dem = {}
	_sup = {}
	_pcache = {}
	var t0 := Time.get_ticks_usec() if profile else 0
	_market()
	if profile:
		t0 = _lap("market", t0)
	_produce()
	if profile:
		t0 = _lap("produce", t0)
	_pay_wages()
	_taxes_and_officials()
	if profile:
		t0 = _lap("wages+tax", t0)
	_eat()
	_stable()
	if profile:
		t0 = _lap("eat", t0)
	_update_prices()
	_pcache = {}
	_move_jobs()
	if profile:
		t0 = _lap("prices", t0)


func _lap(what: String, t0: int) -> int:
	var t := Time.get_ticks_usec()
	laps[what] = int(laps.get(what, 0)) + t - t0
	return t


# --- market
func _keep(b: Dictionary) -> Dictionary:
	var keep := {}
	var T := btype(b.type)
	var n := _workers(b)
	for rid in T.get("runs", {}):
		var r: Dictionary = GameData.recipes[rid]
		for i in r["in"]:
			keep[i] = int(keep.get(i, 0)) + ceili(float(T.runs[rid]) * n * int(r["in"][i]) * float(_rules.input_days_ahead))
	for tool in T.get("tools", {}):
		keep[tool] = int(keep.get(tool, 0)) + _tool_stock(T, tool, n)
	if b.type == "merchant":
		for i in _rules.carry_keep:
			keep[i] = int(_rules.carry_keep[i])
	return keep


## The tools of one kind a business keeps in hand: one, or the wear of twenty days if that is more.
func _tool_stock(T: Dictionary, tool: String, workers: int) -> int:
	return maxi(1, ceili(float(T.tools[tool]) * float(workers) * 20.0)) if workers > 0 else 0


func _workers(b: Dictionary) -> int:
	var n := 0
	for i in b.workers:
		if hh[i].alive:
			n += 1
	return n


func _open_offers() -> void:
	_offers = {}
	_avail = {}
	var types := biz.keys()
	types.sort()
	var rot := day % maxi(1, types.size())
	for k in types.size():
		var b: Dictionary = biz[types[(k + rot) % types.size()]]
		var keep := _keep(b)
		var items: Array = b.stock.keys()
		items.sort()
		for item in items:
			var n := int(b.stock[item]) - int(keep.get(item, 0))
			if n > 0:
				if not _offers.has(item):
					_offers[item] = []
				_offers[item].append({"b": b, "n": n})
				_sup[item] = int(_sup.get(item, 0)) + n
				_avail[item] = int(_avail.get(item, 0)) + n


## Buy up to `want` of `item` for the buyer (its purse `key` pays) into `store` (null: used at once). Returns the units bought.
func _purchase(buyer: Dictionary, key: String, store, item: String, want: int, budget := -1, self_b = null) -> int:
	if want <= 0:
		return 0
	var p := price(item)
	var cash := int(buyer[key]) if budget < 0 else mini(int(buyer[key]), budget)
	var n := mini(want, cash / p)
	_dem[item] = int(_dem.get(item, 0)) + n                  # what it would buy with the coins it has: a price follows paying demand
	if int(_avail.get(item, 0)) <= 0:
		_add(flows.unmet, item, want)
		return 0
	var got := 0
	for o in _offers.get(item, []):
		if got >= n:
			break
		if o.b == self_b:
			continue
		var take := mini(n - got, int(o.n))
		if take <= 0:
			continue
		o.n -= take
		_avail[item] = int(_avail.get(item, 0)) - take
		_take(o.b.stock, item, take)
		if store != null:
			_add(store, item, take)
		else:
			_add(flows.used, item, take)
		var toll := _toll(take * p)
		o.b.till += take * p - toll
		gov.coins += toll
		buyer[key] = int(buyer[key]) - take * p
		got += take
	if want > got:
		_add(flows.unmet, item, want - got)
	return got


## The market toll (or the abbey's tithe) on a sale of `amount` coins: whole coins as the fractions add up.
func _toll(amount: int) -> int:
	_toll_acc = _q(_toll_acc + float(amount) * float(_rules.toll_rate))
	var t := int(floor(_toll_acc + 1e-9))
	_toll_acc = _q(_toll_acc - float(t))
	flows.tolls += t
	return mini(t, amount)


func _market() -> void:
	var t0 := Time.get_ticks_usec() if profile else 0
	_open_offers()
	if profile:
		t0 = _lap("m:offers", t0)
	var n := hh.size()
	var rot := day % maxi(1, n)
	for k in n:
		var h: Dictionary = hh[(k + rot) % n]
		if h.alive and (day + int(h.id)) % int(_rules.shop_every_days) == 0:        # market days: each household every other day
			_household_buys(h)
	if profile:
		t0 = _lap("m:households", t0)
	_relief()
	_upkeep()
	if profile:
		t0 = _lap("m:relief+upkeep", t0)
	var types := biz.keys()
	types.sort()
	for t in types:
		_business_buys(biz[t])
	if profile:
		t0 = _lap("m:businesses", t0)
	_trader_collects()
	if profile:
		t0 = _lap("m:trader", t0)


func _household_buys(h: Dictionary) -> void:
	var need := _need_pts(h)
	var want := float(_rules.food_days_ahead) * need - _pantry_pts(h)
	# a share of the food is prepared food from the cookshop (a household's own hearth does the rest), cheapest first
	var prep := want * PREPARED_SHARE
	_buy_food(h, prep, PREPARED)
	_buy_food(h, want - prep + maxf(0.0, prep - 0.0) * 0.0, _rules.foods)
	var members := float(h.adults) + float(h.children)
	var items: Array = _rules.basket.keys()
	items.sort()
	for item in items:
		h.acc[item] = _q(minf(4.0, float(h.acc.get(item, 0.0)) + float(_rules.basket[item]) * members))
		var n := int(floor(float(h.acc[item]) + 1e-9))
		if n > 0:
			var got := _purchase(h, "coins", null, item, n)
			h.acc[item] = _q(float(h.acc[item]) - float(got))
	# a household with savings above what it keeps spends some of it on the comforts of the settlement's market
	var keep_cash := int(_rules.keep_cash_base) + int(_rules.keep_cash_per_member) * int(members)
	var budget := int(float(int(h.coins) - keep_cash) * float(_rules.spend_rate))
	var wish: Array = _rules.wish
	var left := int(_rules.wishes_a_day)
	for k in wish.size():
		if budget <= 0 or left <= 0:
			break
		var item: String = wish[(k + day + int(h.id)) % wish.size()]
		if price(item) <= budget:
			var before := int(h.coins)
			if _purchase(h, "coins", null, item, 1) > 0:
				budget -= before - int(h.coins)
				left -= 1


## Food worth `pts` points from the listed foods on offer, the cheapest per point first, while the purse lasts.
func _buy_food(h: Dictionary, pts: float, foods: Array) -> void:
	var guard := 0
	while pts > 0.5 and guard < 6:
		guard += 1
		var best := ""
		var best_cost := INF
		for f in foods:
			if int(_avail.get(f, 0)) > 0 and price(f) <= int(h.coins):
				var cost := float(price(f)) / maxf(1.0, _pts(f))
				if cost < best_cost:
					best_cost = cost
					best = f
		if best == "":
			return
		var units := ceili(pts / _pts(best))
		var got := _purchase(h, "coins", h.pantry, best, units)
		if got == 0:
			return
		pts -= float(got) * _pts(best)


## A household with under a day of food gets wheat the treasury buys for it, while the treasury keeps a day's wages.
func _relief() -> void:
	var floor_coins: int = int(_rules.official_wage) * gov.officials.size() + 2
	for h in hh:
		if not h.alive:
			continue
		var need := _need_pts(h)
		if _pantry_pts(h) >= need or int(gov.coins) <= floor_coins:
			continue
		var units := ceili((2.0 * need - _pantry_pts(h)) / _pts("wheat"))
		var got := _purchase(gov, "coins", h.pantry, "wheat", units, int(gov.coins) - floor_coins)
		flows.relief_units += got


func _obligations() -> int:
	return int(_rules.official_wage) * gov.officials.size() + 2


func _upkeep() -> void:
	var reserve := _obligations() * int(_rules.gov_reserve_days)
	var budget := int(maxf(0.0, float(int(gov.coins) - reserve)) * float(_rules.gov_budget_share))
	var items: Array = _rules.gov_upkeep.keys()
	items.sort()
	for item in items:
		gov.acc[item] = _q(minf(6.0, float(gov.acc.get(item, 0.0)) + float(_rules.gov_upkeep[item]) * float(households())))
		var n := int(floor(float(gov.acc[item]) + 1e-9))
		if n > 0 and budget > 0:
			var before := int(gov.coins)
			var got := _purchase(gov, "coins", null, item, n, budget)
			budget -= before - int(gov.coins)
			gov.acc[item] = _q(float(gov.acc[item]) - float(got))


func _business_buys(b: Dictionary) -> void:
	if b.type == "merchant":
		return                                   # a trader buys leftovers (_trader_collects) and the village's goods; its horses' feed is bought there
	var T := btype(b.type)
	var n := _workers(b)
	if n == 0:
		return
	var need := {}
	for rid in T.get("runs", {}):
		var r: Dictionary = GameData.recipes[rid]
		for i in r["in"]:
			if not (T.get("out", {}) as Dictionary).has(i):
				need[i] = int(need.get(i, 0)) + ceili(float(T.runs[rid]) * n * int(r["in"][i]) * float(_rules.input_days_ahead))
	for tool in T.get("tools", {}):
		need[tool] = int(need.get(tool, 0)) + _tool_stock(T, tool, n)
	var items: Array = need.keys()
	items.sort()
	for item in items:
		# an input a recipe of its own makes is not bought (the smith's iron bars for its forging)
		var made := false
		for rid in T.get("runs", {}):
			if (GameData.recipes[rid].out as Dictionary).has(item):
				made = true
		var short := int(need[item]) - int(b.stock.get(item, 0))
		if short > 0 and (not made or int(b.stock.get(item, 0)) < int(need[item]) / 2):
			_purchase(b, "till", b.stock, item, short, -1, b)


## The trader buys what the producers have left over of the goods it carries (ore, stone, bars, seed, medicine), at the
## price the glut left them, from its own till above its floor.
func _trader_collects() -> void:
	var m := trader()
	if m.is_empty():
		return
	var items: Array = _rules.carry.keys()
	items.sort()
	var share := float(_rules.trader_pays_share)
	for item in items:
		var room := int(_rules.carry[item]) - int(m.stock.get(item, 0))
		var p := maxi(1, roundi(float(price(item)) * share))
		for o in _offers.get(item, []):
			if room <= 0:
				break
			if o.b == m:
				continue
			var cash := int(m.till) - maxi(int(_rules.trader_reserve_floor), int(m.reserve))
			var take := mini(mini(room, int(o.n)), cash / p)
			if take <= 0:
				continue
			o.n -= take
			_avail[item] = int(_avail.get(item, 0)) - take
			_take(o.b.stock, item, take)
			_add(m.stock, item, take)
			o.b.till += take * p
			m.till -= take * p
			room -= take


# --- production
func _produce() -> void:
	var types := biz.keys()
	types.sort()
	for t in types:
		var b: Dictionary = biz[t]
		var T := btype(t)
		var n := _workers(b)
		if n == 0:
			continue
		var cap := int(T.get("cap", 150))
		var pace := 1.0
		for item in (b.out as Dictionary).keys():
			b.acc[item] = _q(float(b.acc.get(item, 0.0)) + float(b.out[item]) * n * pace)
			var q := int(floor(float(b.acc[item]) + 1e-9))
			q = mini(q, maxi(0, cap - int(b.stock.get(item, 0))))
			if b.reserves.has(item):
				q = mini(q, int(b.reserves[item]))
			if q > 0:
				b.acc[item] = _q(float(b.acc[item]) - float(q))
				if b.reserves.has(item):
					b.reserves[item] = int(b.reserves[item]) - q
				_add(b.stock, item, q)
				_add(flows.produced, item, q)
			else:
				b.acc[item] = minf(float(b.acc[item]), 1.0)
		var runs: Dictionary = T.get("runs", {})
		var rids := runs.keys()
		for rid in rids:
			var key: String = "r:" + rid
			b.acc[key] = _q(minf(float(b.acc.get(key, 0.0)) + float(runs[rid]) * n * pace, float(runs[rid]) * n * 2.0 + 1.0))
			var r: Dictionary = GameData.recipes[rid]
			while float(b.acc[key]) >= 1.0 - 1e-9:
				if not _run_recipe(b, T, r):
					break
				b.acc[key] = _q(float(b.acc[key]) - 1.0)
			if float(b.acc[key]) >= 1.0:
				b.acc[key] = 0.0                    # no inputs or no room: the day's work is not saved up
		_wear_tools(b, T, n)


func _wear_tools(b: Dictionary, T: Dictionary, n: int) -> void:
	for tool in T.get("tools", {}):
		var key: String = "t:" + tool
		b.acc[key] = _q(minf(float(b.acc.get(key, 0.0)) + float(T.tools[tool]) * n, 2.0))
		if float(b.acc[key]) >= 1.0 and int(b.stock.get(tool, 0)) > 0:
			_take(b.stock, tool, 1)
			_add(flows.used, tool, 1)
			b.acc[key] = _q(float(b.acc[key]) - 1.0)


func _run_recipe(b: Dictionary, T: Dictionary, r: Dictionary) -> bool:
	var targets: Dictionary = T.get("targets", {})
	for o in r.out:
		if int(b.stock.get(o, 0)) >= int(targets.get(o, 60)):
			return false
	for i in r["in"]:
		if int(b.stock.get(i, 0)) < int(r["in"][i]):
			return false
	for i in r["in"]:
		_take(b.stock, i, int(r["in"][i]))
		_add(flows.used, i, int(r["in"][i]))
	for o in r.out:
		_add(b.stock, o, int(r.out[o]))
		_add(flows.produced, o, int(r.out[o]))
	return true


# --- wages, tax, officials
func _wage_bill(b: Dictionary) -> int:
	return _workers(b) * int(btype(b.type).get("wage", 8))


func _pay_wages() -> void:
	var types := biz.keys()
	types.sort()
	for t in types:
		var b: Dictionary = biz[t]
		var wage := int(btype(t).get("wage", 8))
		var live := []
		for i in b.workers:
			if hh[i].alive:
				live.append(i)
		if live.is_empty():
			continue
		# the business keeps its working reserve; of what it has above it, it pays out at least the wages and up to its
		# payout share, equally among its worker households (the owners' and workers' living is its profit)
		var surplus := maxi(0, int(b.till) - int(b.reserve))
		var due := wage * live.size()
		var total := mini(surplus, maxi(due, int(float(surplus) * float(_rules.payout_share))))
		var each: int = total / live.size()
		var rem: int = total - each * live.size()
		for k in live.size():
			var h: Dictionary = hh[live[k]]
			var pay: int = each + (rem if k == 0 else 0)
			b.till -= pay
			h.coins += pay
		b.paid = int(b.get("paid", 0)) + total
		b.week = int(b.get("week", 0)) + total
		for k in live.size():
			hh[live[k]].inc = int(hh[live[k]].inc) + each + (rem if k == 0 else 0)
		# PAR-02A (owner, OD-19): a reserve protects necessities, it never keeps them from being met. A worker household
		# already hungry that cannot buy a day's food is paid its wage from the till even below the working reserve.
		var need_paid := 0
		for i in live:
			var h: Dictionary = hh[i]
			var paid_now: int = each + (rem if i == live[0] else 0)
			var short := wage - paid_now
			if short <= 0 or int(h.hungry) <= 0 or int(h.coins) >= _day_food_cost(h) or int(b.till) <= 0:
				continue
			var pay := mini(short, int(b.till))
			b.till -= pay
			h.coins += pay
			h.inc = int(h.inc) + pay
			need_paid += pay
		total += need_paid
		b.paid = int(b.paid) + need_paid
		b.week = int(b.week) + need_paid
		flows.wages_paid += total
		flows.wage_short += maxi(0, due - total)


func _taxes_and_officials() -> void:
	var ob := _obligations()
	var holiday := float(ob) * float(GameData.b("treasury_tax_holiday_days"))
	var reserve := float(ob) * float(GameData.b("treasury_reserve_days"))
	if float(gov.coins) < holiday:
		var rate := float(GameData.b("tax_rate_low_treasury")) if float(gov.coins) < reserve else float(GameData.b("tax_rate_normal"))
		for h in hh:
			if not h.alive:
				continue
			var members := int(h.adults) + int(h.children)
			var exempt := int(GameData.b("tax_exemption_base")) + int(GameData.b("tax_exemption_per_member")) * members
			var t := int(maxi(0, int(h.coins) - exempt) * rate)
			h.coins -= t
			gov.coins += t
			flows.tax_households += t
		var types := biz.keys()
		types.sort()
		for tp in types:
			var b: Dictionary = biz[tp]
			var t := int(maxi(0, int(b.till) - int(b.reserve) - int(_rules.business_tax_exempt)) * rate)
			b.till -= t
			gov.coins += t
			flows.tax_businesses += t
	for i in gov.officials:
		var h: Dictionary = hh[i]
		if h.alive:
			var pay := mini(int(_rules.official_wage), int(gov.coins))
			gov.coins -= pay
			h.coins += pay
			flows.official_pay += pay
	# day labour on the settlement's works (the village's own rule, balance.json day_labour_wage) for a household nearly out
	# of coins, while the treasury holds more than three days of its wages
	var wage := int(_rules.day_labour_wage)
	for h in hh:
		if h.alive and int(h.coins) < int(_rules.day_labour_below) and int(gov.coins) - wage >= 3 * ob:
			gov.coins -= wage
			h.coins += wage
			flows.day_labour += wage


## Once a week a household whose trade pays it next to nothing takes up a trade that pays well (the village's own job
## changes): it joins the business that paid its workers most this week, if that is at least `switch_to_at_least` a worker a
## day and at least twice its own pay, after `switch_stay_days` in its trade. Officials stay officials, and every
## business keeps at least one household. No coin or good moves; the settlement's trades follow what pays.
func _move_jobs() -> void:
	for h in hh:
		h.stay = int(h.stay) + 1
	var every := int(_rules.switch_every_days)
	if every <= 0 or day % every != every - 1:
		return
	var types := biz.keys()
	types.sort()
	var pay := {}
	for t in types:
		var b: Dictionary = biz[t]
		pay[t] = float(b.week) / 7.0 / maxf(1.0, float(_workers(b)))
	var best := ""
	for t in types:
		if t != "merchant" and _workers(biz[t]) > 0 and float(pay[t]) >= float(_rules.switch_to_at_least) and (best == "" or float(pay[t]) > float(pay[best])):
			best = t
	if best != "":
		for t in types:
			var b: Dictionary = biz[t]
			if t == best or _workers(b) <= 1:
				continue                       # a trade is never left with no household: the settlement keeps its character
			for i in b.workers.duplicate():
				var h: Dictionary = hh[i]
				if h.alive and int(h.stay) >= int(_rules.switch_stay_days) and float(h.inc) / 7.0 < float(_rules.switch_below) \
						and float(pay[best]) >= 2.0 * float(h.inc) / 7.0:
					b.workers.erase(i)
					biz[best].workers.append(i)
					h.trade = _trade_of(best)
					h.stay = 0
					flows.job_moves += 1
					break                      # one household a business a week
	for t in types:
		biz[t].week = 0
	for h in hh:
		h.inc = 0


static func _trade_of(bt: String) -> String:
	for k in TRADE_BIZ:
		if TRADE_BIZ[k] == bt:
			return k
	return bt


# --- eating, hunger, the stable
func _eat() -> void:
	var foods: Array = _rules.foods.duplicate()
	foods.sort_custom(func(a, b): return float(GameData.value(a)) / _pts(a) < float(GameData.value(b)) / _pts(b))
	for h in hh:
		if not h.alive:
			continue
		var need := _need_pts(h)
		var have := float(h.credit)
		for f in foods:
			while have < need and int(h.pantry.get(f, 0)) > 0:
				_take(h.pantry, f, 1)
				_add(flows.used, f, 1)
				have += _pts(f)
		h.credit = _q(maxf(0.0, have - need))
		if have < need * float(_rules.hungry_below):
			h.hungry += 1
			if int(h.hungry) >= int(_rules.hungry_days_to_death):
				_lose_member(h)
				h.hungry = int(_rules.hungry_days_to_death) - 3
		else:
			h.hungry = 0


func _lose_member(h: Dictionary) -> void:
	if int(h.children) > 0:
		h.children -= 1
	else:
		h.adults -= 1
	flows.deaths += 1
	if int(h.adults) + int(h.children) <= 0:
		h.alive = false
		gov.coins += int(h.coins)
		h.coins = 0
		for k in h.pantry:
			_add(gov.granary, k, int(h.pantry[k]))
		h.pantry = {}


## The settlement's working horses eat the farms' wheat (from their own stock: grain they grew), and a fed pair breeds.
func _stable() -> void:
	if not biz.has("farm"):
		return
	var b: Dictionary = biz.farm
	var T := btype("farm")
	if int(b.horses) <= 0 or _workers(b) == 0:
		return
	b.acc["feed"] = _q(float(b.acc.get("feed", 0.0)) + float(T.feed) * int(b.horses))
	var units := int(floor(float(b.acc.feed) + 1e-9))
	if units > 0:
		var ate := _take(b.stock, "wheat", units)
		_add(flows.used, "wheat", ate)
		b.acc["feed"] = _q(float(b.acc.feed) - float(units))
		if ate < units:
			b.fed_miss += 1
		else:
			b.fed_miss = 0
	if int(b.fed_miss) >= 10:
		b.horses -= 1
		b.fed_miss = 5
		flows.horses_died += 1
	elif int(b.fed_miss) == 0 and int(b.horses) >= 2 and int(b.horses) < int(T.horses_max):
		b.foal += 1
		if int(b.foal) >= int(T.foal_days):
			b.foal = 0
			b.horses += 1
			flows.horses_foaled += 1


# ------------------------------------------------------------------ trade with the village ----------------
## Open a visit: what the settlement wants from the village this time (begin_visit) and nothing else.
func begin_visit() -> void:
	_want_left = wants()


func want_left(item: String) -> int:
	return int(_want_left.get(item, 0))


func trader_cash() -> int:
	var m := trader()
	return 0 if m.is_empty() else maxi(0, int(m.till) - int(_rules.trader_reserve_floor))


func trader_has(item: String) -> int:
	var m := trader()
	return 0 if m.is_empty() else int(m.stock.get(item, 0))


## The trader sells `n` of `item` to the village at `unit` coins each: the goods leave its stock, the coins enter its till.
func sell_to_village(item: String, n: int, unit: int) -> bool:
	var m := trader()
	if m.is_empty() or n <= 0 or int(m.stock.get(item, 0)) < n:
		return false
	_take(m.stock, item, n)
	m.till += n * unit
	_add(flows.to_village, item, n)
	flows.coins_from_village += n * unit
	return true


## The trader buys `n` of `item` from the village at `unit` each: the coins leave its till (never past its floor), the goods
## enter its stock.
func buy_from_village(item: String, n: int, unit: int) -> bool:
	var m := trader()
	if m.is_empty() or n <= 0 or trader_cash() < n * unit:
		return false
	m.till -= n * unit
	_add(m.stock, item, n)
	_add(flows.from_village, item, n)
	flows.coins_to_village += n * unit
	_want_left[item] = maxi(0, int(_want_left.get(item, 0)) - n)
	if _rules.foods.has(item) or item == "meat":
		_want_left["_food_pts"] = maxf(0.0, float(_want_left.get("_food_pts", 0.0)) - float(n) * _pts(item))
	return true


## The plough horse a farm of the settlement sells (a trader leads it to the road): price in coins, into the farm's till.
func sell_horse(unit: int) -> bool:
	if not biz.has("farm") or int(biz.farm.horses) <= 0:
		return false
	biz.farm.horses -= 1
	biz.farm.till += unit
	flows.horses_sold += 1
	flows.coins_from_village += unit
	return true


func has_horse() -> bool:
	return horses() > 0


## Units of each good the settlement would take now: a few days' use that neither its stocks nor its own workings cover
## (the demand of its people, its businesses and its treasury, less what its workers make), and food when its people hold
## under three days of it. Only things it can use; never more than it can pay for is decided at the till.
func wants() -> Dictionary:
	data()
	var daily := {}
	var made := {}
	var members := float(population())
	var rl := rules()
	for item in rl.basket:
		daily[item] = float(daily.get(item, 0.0)) + float(rl.basket[item]) * members
	for item in rl.gov_upkeep:
		daily[item] = float(daily.get(item, 0.0)) + float(rl.gov_upkeep[item]) * float(households())
	for t in biz:
		var b: Dictionary = biz[t]
		var T := btype(t)
		var n := float(_workers(b))
		if n == 0.0:
			continue
		for item in b.out:
			if not b.reserves.has(item) or int(b.reserves[item]) > 0:
				made[item] = float(made.get(item, 0.0)) + float(b.out[item]) * n
		for rid in T.get("runs", {}):
			var r: Dictionary = GameData.recipes[rid]
			for i in r["in"]:
				daily[i] = float(daily.get(i, 0.0)) + float(T.runs[rid]) * n * int(r["in"][i])
			for o in r.out:
				made[o] = float(made.get(o, 0.0)) + float(T.runs[rid]) * n * int(r.out[o])
		for tool in T.get("tools", {}):
			daily[tool] = float(daily.get(tool, 0.0)) + float(T.tools[tool]) * n
	var have := goods()
	var out := {}
	for item in daily:
		var gap := float(daily[item]) - float(made.get(item, 0.0))
		if gap <= 0.0:
			continue
		var w := ceili(gap * float(rl.want_days)) - int(have.get(item, 0))
		if w > 0:
			out[item] = w
	var pts := 0.0
	var need := 0.0
	for h in hh:
		if h.alive:
			need += _need_pts(h)
			pts += _pantry_pts(h)
	for b in biz.values():
		for f in rl.foods:
			pts += float(b.stock.get(f, 0)) * _pts(f)
	for f in rl.foods:
		pts += float(gov.granary.get(f, 0)) * _pts(f)
	out["_food_pts"] = maxf(0.0, 3.0 * need - pts)
	return out


## Whether the settlement still wants `n` of `item` this visit (a food counts against the food it still lacks).
func wants_item(item: String, n := 1) -> bool:
	if _rules.foods.has(item):
		return float(_want_left.get("_food_pts", 0.0)) >= _pts(item) * float(n) * 0.5
	return int(_want_left.get(item, 0)) >= n


# ------------------------------------------------------------------ a report ----------------
func summary() -> Dictionary:
	var hungry := 0
	var food_pts := 0.0
	var need := 0.0
	for h in hh:
		if h.alive:
			need += _need_pts(h)
			food_pts += _pantry_pts(h)
			if int(h.hungry) > 0:
				hungry += 1
	var cash := 0
	for h in hh:
		cash += int(h.coins)
	var tills := 0
	for t in biz:
		tills += int(biz[t].till)
	return {"id": id, "population": population(), "households": households(), "hungry": hungry, "deaths": int(flows.deaths),
		"coins": coins(), "household_coins": cash, "tills": tills, "treasury": int(gov.coins),
		"trader": int(trader().get("till", 0)), "pantry_days": food_pts / maxf(1.0, need), "horses": horses(),
		"wage_short": int(flows.wage_short), "relief": int(flows.relief_units)}


# ------------------------------------------------------------------ saving ----------------
## Take the present coins, goods and horses as the opening books and clear the flow lines (a test that sets a purse or a
## stock by hand does this so audit() measures from there).
func reopen_books() -> void:
	flows = _blank_flows()
	flows.horses_start = horses()
	start = {"coins": coins(), "goods": goods()}


## Float accumulators with the arithmetic's dust (1e-17, minus zero) taken off, so a saved and loaded settlement is the same
## to the last digit.
static func _clean(d: Dictionary) -> void:
	for k in d:
		if d[k] is float and absf(d[k]) < 1e-9:
			d[k] = 0.0


func to_dict() -> Dictionary:
	var hs: Array = hh.duplicate(true)
	for h in hs:
		_clean(h.acc)
		if absf(float(h.credit)) < 1e-9:
			h.credit = 0.0
	var bs: Dictionary = biz.duplicate(true)
	for t in bs:
		_clean(bs[t].acc)
	var gv: Dictionary = gov.duplicate(true)
	_clean(gv.acc)
	return {"id": id, "name": name, "kind": kind, "gov_name": gov_name, "miles": miles, "x": pos.x, "y": pos.y,
		"industries": industries.duplicate(), "hh": hs, "biz": bs, "gov": gv,
		"prices": prices.duplicate(), "toll_acc": _toll_acc, "flows": flows.duplicate(true), "start": start.duplicate(true), "day": day}


static func from_dict(d: Dictionary) -> OffMapSettlement:
	data()
	var s := OffMapSettlement.new()
	s.id = str(d.id)
	s.name = str(d.name)
	s.kind = str(d.kind)
	s.gov_name = str(d.gov_name)
	s.miles = int(d.miles)
	s.pos = Vector2i(int(d.x), int(d.y))
	s.industries = (d.industries as Array).duplicate()
	s.day = int(d.day)
	for h in d.hh:
		var c: Dictionary = h.duplicate(true)
		for k in ["id", "adults", "children", "coins", "hungry"]:
			c[k] = int(c[k])
		c.inc = int(c.get("inc", 0))
		c.stay = int(c.get("stay", 0))
		c.credit = float(c.credit)
		c.pantry = _ints(c.pantry)
		var acc := {}
		for k in c.acc:
			acc[k] = float(c.acc[k])
		c.acc = acc
		s.hh.append(c)
	for t in d.biz:
		var b: Dictionary = (d.biz[t] as Dictionary).duplicate(true)
		for k in ["till", "reserve", "horses", "foal", "fed_miss"]:
			b[k] = int(b[k])
		b.paid = int(b.get("paid", 0))
		b.week = int(b.get("week", 0))
		b.workers = (b.workers as Array).map(func(x): return int(x))
		b.stock = _ints(b.stock)
		b.reserves = _ints(b.reserves)
		var acc := {}
		for k in b.acc:
			acc[k] = float(b.acc[k])
		b.acc = acc
		s.biz[t] = b
	var g: Dictionary = (d.gov as Dictionary).duplicate(true)
	g.coins = int(g.coins)
	g.granary = _ints(g.granary)
	g.officials = (g.officials as Array).map(func(x): return int(x))
	var gacc := {}
	for k in g.acc:
		gacc[k] = float(g.acc[k])
	g.acc = gacc
	s.gov = g
	for k in d.prices:
		s.prices[k] = float(d.prices[k])
	s.flows = _blank_flows()
	for k in FLOW_GOODS:
		s.flows[k] = _ints(d.flows.get(k, {}))
	for k in FLOW_COUNTS:
		s.flows[k] = int(d.flows.get(k, 0))
	s._toll_acc = float(d.get("toll_acc", 0.0))
	s.start = {"coins": int(d.start.coins), "goods": _ints(d.start.goods)}
	return s


static func _ints(d: Dictionary) -> Dictionary:
	var o := {}
	for k in d:
		o[k] = int(d[k])
	return o
