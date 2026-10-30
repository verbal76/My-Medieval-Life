class_name SettlementParty
extends RefCounted
## Expansion 18 (REG-PARTY-01; owner Q18-10, 2026-10-21: "Anyone may purchase goods from another settlement, including
## individual villagers, households, merchants, businesses, and settlement treasuries"): ONE trading-party interface over the
## five off-map settlements. A party is a HANDLE on one holder of an `OffMapSettlement`; it keeps no coins or goods of its own:
## every read and every change goes to the settlement's own books (the trader's till and stock, a business's till and stock,
## the treasury's coins and granary, a household's purse and pantry). The regional market (RegionalMarket) and the courier
## service (CourierService) address parties only through this interface, so a regional trade moves the same coins and goods
## the settlement's own day does, and `OffMapSettlement.audit()` / `Regions.audit()` check it.
##
## Reference: "region:<settlement>/<holder>" (id "<settlement>/<holder>"), holder one of
##   trader      the settlement's merchant business (the only party the village's caravan meets)
##   <business>  a business type: farm, herd, forest, quarry, sawyer, mason, smith, tanner, cook, weaver, healer
##   treasury    the manor, abbey or council: its coins and granary
##   hh:<n>      the household with that id (living households only)
## `Regions.party(ref)` makes one, `Regions.parties()` lists them all; a handle is cheap and is made fresh for each plan.
##
## Every change is one SIDE of a matched exchange, made through `deal` (a sale, a purchase, a carriage fee paid or earned) or
## through the Inventory-like `add`/`remove`/`outside_coins` (the courier service's hand-overs):
##   * the other party is a holder of ANOTHER of the five settlements -> `regional_*` flow lines on both settlements (goods
##     and coins; the two sides must cancel, which Regions.audit checks);
##   * the other party is in the same settlement -> no flow line (the settlement's own total does not change);
##   * the other party is not a holder of the five (the courier service's booths and packs, the village's people, an analysis
##     fixture) -> `outside_*` flow lines, whose other end is booked in that party's own books.
## Nothing is created or destroyed by an exchange; a side that cannot be met is refused whole (`can_deal`).
##
## What a party WANTS and OFFERS (read by RegionalMarket; deterministic, derived from the settlement's own rules, never random):
##   need_rate    units a day it uses: the trader, the settlement's whole shortfall (OffMapSettlement.wants()); a business, the
##                inputs its recipes use; the treasury, its upkeep goods; a household, wheat for its food and its basket
##   local_yield  what the rest of the settlement holds of a good it needs: the region supplies only what the settlement as a
##                whole lacks (the local market comes first)
##   sale_cap     the most it will sell of a good: what it holds beyond the stock it keeps (the trader's carry_keep, a
##                business's working stock, a household's three days' food twice over, the treasury's granary beyond a
##                reserve); the caravan and the local market use the same keeps
##   transport    what it carries on its own trips: the trader a handcart if its settlement has horses, else a pack; a household
##                a pack; a business or the treasury cannot travel and must hire a carter (Q18-12, still open: no party hires
##                out carts unless a test sets `option("carts_for_hire", true)`)

var regions: Regions
var s: OffMapSettlement
var holder := ""                  # trader | <business type> | treasury | hh:<n>
var id := ""                      # "<settlement>/<holder>"
var _needs := {}                  # item -> units a day, once per handle (a handle is made fresh for each plan)
var _local := {}
var _have := false
## X20-SETTLE-FOOD: when set (the food round's buyers), what this party BUYS from a holder of another place goes on the road home and
## arrives after a trip: place id -> days there and back (OffMapSettlement.ship_in, delivered by the settlement's own step). Unset,
## a purchase is in hand at once, as before.
var ship_days := {}
## X20-SETTLE-FOOD, the food round's sellers: `sells_only` -- it offers but wants nothing (no need, no demand: it is not a buyer in
## this round); `release` -- when set, the most of each good it may sell ({item: units}, OffMapSettlement.food_release: its
## settlement's rules for releasing food), on top of its own sale cap.
var sells_only := false
var release = null


static func make(regions_: Regions, s_: OffMapSettlement, holder_: String) -> SettlementParty:
	var p := SettlementParty.new()
	p.regions = regions_
	p.s = s_
	p.holder = holder_
	p.id = "%s/%s" % [s_.id, holder_]
	return p


# ------------------------------------------------------------------ what it is ----------------
var settlement: String:
	get:
		return s.id

var pos: Vector2i:
	get:
		return s.pos

var kind: String:
	get:
		if holder == "trader":
			return "trader"
		if holder == "treasury":
			return "treasury"
		return "household" if holder.begins_with("hh:") else "business"

var name: String:
	get:
		match kind:
			"trader":
				return "the traders of %s" % s.name
			"treasury":
				return "%s of %s" % [s.gov_name, s.name]
			"household":
				return "household %s of %s" % [holder.trim_prefix("hh:"), s.name]
		return "the %s of %s" % [holder, s.name]

var ref: String:
	get:
		return "region:" + id

var coins: int:
	get:
		return purse()

var stock: SettlementParty:
	get:
		return self                # an Inventory-like view of itself (count, has, add, remove, can_add, items)

var items: Dictionary:
	get:
		return held_items()

var transport: Dictionary:
	get:
		if bool(option("no_travel", false)):
			return {"carry": 0}
		match kind:
			"trader":
				return {"carry": 1, "handcart": 1 if s.horses() > 0 else 0}
			"household":
				var h := _hh()
				return {"carry": 1 if not h.is_empty() and int(h.adults) > 0 else 0}
		return {"carry": 0}

var can_travel: bool:
	get:
		return int(transport.get("carry", 0)) > 0 and kind in ["trader", "household"]

var carts_for_hire: bool:
	get:
		return bool(option("carts_for_hire", false))

var capabilities: Dictionary:
	get:
		return option("capabilities", {})

var profile: String:
	get:
		return str(option("profile", ""))

var journal: Array:
	get:
		return regions.journal.filter(func(e): return str(e.party) == id)


## A test or fixture setting that lives with the Regions object only (never saved): "carts_for_hire", "no_travel",
## "capabilities", "profile".
func option(key: String, default = null):
	return (regions.party_options.get(id, {}) as Dictionary).get(key, default)


func set_option(key: String, value) -> void:
	if not regions.party_options.has(id):
		regions.party_options[id] = {}
	regions.party_options[id][key] = value


# ------------------------------------------------------------------ its books ----------------
func _hh() -> Dictionary:
	if not holder.begins_with("hh:"):
		return {}
	if not holder.trim_prefix("hh:").is_valid_int():
		return {}
	var n := int(holder.trim_prefix("hh:"))
	for h in s.hh:
		if int(h.id) == n:
			return h
	return {}


func _biz() -> Dictionary:
	return s.biz.get("merchant" if holder == "trader" else holder, {})


## The holder's own record: the household, the business or the treasury.
func record() -> Dictionary:
	match kind:
		"treasury":
			return s.gov
		"household":
			return _hh()
	return _biz()


func _goods() -> Dictionary:
	match kind:
		"treasury":
			return s.gov.granary
		"household":
			return _hh().pantry
	return _biz().stock


func _purse_key() -> String:
	return "till" if kind in ["trader", "business"] else "coins"


## Whether the holder exists now (a business that is gone, a household that is dissolved: no party).
func alive() -> bool:
	if kind == "household":
		var h := _hh()
		return not h.is_empty() and bool(h.alive)
	return not record().is_empty()


func purse() -> int:
	var r := record()
	return int(r.get(_purse_key(), 0)) if not r.is_empty() else 0


func held(item: String) -> int:
	return int(_goods().get(item, 0)) if alive() else 0


func count(item: String) -> int:
	return held(item)


func has(item: String, n := 1) -> bool:
	return held(item) >= n


func held_items() -> Dictionary:
	return (_goods() as Dictionary).duplicate() if alive() else {}


## A settlement's store has no slot limit (its books are counts).
func can_hold(_item: String) -> bool:
	return alive()


func can_add(item: String) -> bool:
	return can_hold(item)


# ------------------------------------------------------------------ what it wants and offers ----------------
func _derive() -> void:
	if _have:
		return
	_have = true
	_needs = {}
	_local = {}
	if not alive():
		return
	var rl := OffMapSettlement.rules()
	var all := s.goods()
	match kind:
		"trader":
			var w := s.wants()
			var wd := float(rl.want_days)
			for item in w:
				if str(item).begins_with("_"):
					continue
				_needs[item] = float(int(w[item]) + int(all.get(item, 0))) / wd
			var fp := float(w.get("_food_pts", 0.0))
			if fp > 0.0:
				var units := ceili(fp / OffMapSettlement._pts("wheat"))
				_needs["wheat"] = maxf(float(_needs.get("wheat", 0.0)), float(units + int(all.get("wheat", 0))) / wd)
		"business":
			var b := _biz()
			var T := OffMapSettlement.btype(holder)
			var n := s._workers(b)
			for rid in T.get("runs", {}):
				var r: Dictionary = GameData.recipes[rid]
				for i in r["in"]:
					if not (T.get("out", {}) as Dictionary).has(i):
						_needs[i] = float(_needs.get(i, 0.0)) + float(T.runs[rid]) * n * int(r["in"][i])
		"treasury":
			for item in rl.gov_upkeep:
				_needs[item] = float(rl.gov_upkeep[item]) * float(s.households())
		"household":
			var h := _hh()
			var members := float(h.adults) + float(h.children)
			for item in rl.basket:
				_needs[item] = float(rl.basket[item]) * members
			_needs["wheat"] = s._need_pts(h) / OffMapSettlement._pts("wheat")
	for item in _needs:
		_local[item] = maxi(0, int(all.get(item, 0)) - held(item))


func refresh() -> void:
	_have = false


func need_items() -> Array:
	if sells_only:
		return []
	_derive()
	var out := _needs.keys()
	out.sort()
	return out


func need_rate(item: String) -> float:
	if sells_only:
		return 0.0
	_derive()
	return float(_needs.get(item, 0.0))


func local_yield(item: String) -> int:
	if sells_only:
		return 0
	_derive()
	return int(_local.get(item, 0))


## The most it will sell of `item`; -1 is no cap of its own. A trader never sells on the food it bought for its own place
## (X20-SETTLE-FOOD: its `imported` mark).
func sale_cap(item: String) -> int:
	if not alive():
		return 0
	if release != null:
		return mini(_sale_cap(item), int((release as Dictionary).get(item, 0)))
	return _sale_cap(item)


func _sale_cap(item: String) -> int:
	var rl := OffMapSettlement.rules()
	var have := held(item)
	match kind:
		"trader":
			return maxi(0, have - int(s._keep(_biz()).get(item, 0)) - int((_biz().get("imported", {}) as Dictionary).get(item, 0)))
		"business":
			return maxi(0, have - int(s._keep(_biz()).get(item, 0)))
		"household":
			var keep := 0
			if rl.foods.has(item):
				keep = ceili(2.0 * float(rl.food_days_ahead) * s._need_pts(_hh()) / OffMapSettlement._pts(item))
			elif _needs_basket(item):
				keep = ceili(float(rl.basket[item]) * 4.0 * (float(_hh().adults) + float(_hh().children)))
			return maxi(0, have - keep)
		"treasury":
			var keep := 0
			if rl.foods.has(item):
				var pts := 0.0
				for h in s.hh:
					if h.alive:
						pts += s._need_pts(h)
				keep = ceili(3.0 * pts / OffMapSettlement._pts(item))
			elif rl.gov_upkeep.has(item):
				keep = ceili(float(rl.gov_upkeep[item]) * 6.0 * float(s.households()))
			return maxi(0, have - keep)
	return 0


## X20-SETTLE-FOOD: what it asks for a unit of `item` at its own door: its settlement's own floating price (the price it charges
## the village's caravan and its own market), not a fixed value (RegionalMarket.ask_of).
func ask_price(item: String) -> int:
	return s.price(item)


## X20-SETTLE-FOOD: the coins it may spend in regional trade (RegionalMarket.spendable). A trader keeps its floor and half its
## trading capital for the village's caravan, as in the traders' own wholesale round (Regions.road_trade); anyone else keeps the
## market's cash floor.
func spend_limit() -> int:
	if kind == "trader":
		var m := _biz()
		return maxi(0, int(m.get("till", 0)) - int(OffMapSettlement.rules().trader_reserve_floor) - int(m.get("reserve", 0)) / 2)
	return maxi(0, purse() - int(RegionalMarket.cfg().cash_floor))


func _needs_basket(item: String) -> bool:
	return OffMapSettlement.rules().basket.has(item)


# ------------------------------------------------------------------ exchanges ----------------
## The flow channel of an exchange with `other`: "" (same settlement: no line), "regional" (a holder of another of the five)
## or "outside" (anything else).
func channel(other) -> String:
	if other is SettlementParty:
		return "" if (other as SettlementParty).s == s else "regional"
	return "outside"


## Whether this side of an exchange can be met: "sell" needs the goods, "buy" a purse that pays `coins` and room, "carriage_paid"
## the coins, "carriage_earned" nothing.
func can_deal(role: String, item: String, n: int, coins_: int) -> bool:
	if not alive() or n < 0 or coins_ < 0:
		return false
	match role:
		"sell":
			return held(item) >= n
		"buy":
			return purse() >= coins_ and can_hold(item)
		"carriage_paid":
			return purse() >= coins_
	return role == "carriage_earned"


## This party's side of an exchange with `other` (a SettlementParty or an analysis fixture with the same interface), one of
## "sell" (goods out, coins in), "buy" (goods in, coins out), "carriage_paid" (coins out), "carriage_earned" (coins in), with its
## flow line and journal line. false (nothing changed) when this side cannot be met.
func deal(role: String, other, item: String, n: int, coins_: int, day := 0) -> bool:
	if not can_deal(role, item, n, coins_):
		return false
	var ch := channel(other)
	var goods_dir := 0
	var coin_dir := 0
	match role:
		"sell":
			goods_dir = -1
			coin_dir = 1
		"buy":
			goods_dir = 1
			coin_dir = -1
		"carriage_paid":
			coin_dir = -1
		"carriage_earned":
			coin_dir = 1
	if goods_dir > 0 and n > 0 and ch == "regional" and ship_days.has(str(other.settlement)):
		# X20-SETTLE-FOOD: bought and paid for, it is this settlement's now (its regional_in line), but it is on the road home
		OffMapSettlement._add(s.flows.regional_in, item, n)
		s.ship_in(holder, item, n, str(other.id), day, day + maxi(1, int(ship_days[str(other.settlement)])), coins_)
	elif goods_dir != 0 and n > 0:
		_move_goods(item, goods_dir * n, ch)
	if coin_dir != 0 and coins_ > 0:
		_move_coins(coin_dir * coins_, ch)
	regions.journal.append({"day": day, "party": id, "kind": role, "item": item, "n": n, "coins": coins_, "with": str(other.id)})
	_have = false
	if other is SettlementParty:
		(other as SettlementParty)._have = false
	return true


func _move_goods(item: String, delta: int, ch: String) -> void:
	OffMapSettlement._add(_goods(), item, delta)
	if ch == "":
		return
	var key := ch + ("_in" if delta > 0 else "_out")
	OffMapSettlement._add(s.flows[key], item, absi(delta))


func _move_coins(delta: int, ch: String) -> void:
	var r := record()
	r[_purse_key()] = int(r[_purse_key()]) + delta
	if ch != "":
		s.flows[ch + "_coins_" + ("in" if delta > 0 else "out")] += absi(delta)


## Goods handed over by the courier service (it adds to, or takes from, this party's holder; the courier's own books carry the
## other end): Inventory-like, so the service treats a party as it treats a villager's pack.
func add(item: String, n := 1) -> bool:
	if n < 0 or not can_hold(item):
		return false
	if n > 0:
		_move_goods(item, n, "outside")
		_have = false
	return true


func remove(item: String, n := 1) -> bool:
	if n < 0 or held(item) < n:
		return false
	if n > 0:
		_move_goods(item, -n, "outside")
		_have = false
	return true


## Coins paid to (k > 0) or by (k < 0) the courier service. Never past empty.
func outside_coins(k: int) -> bool:
	if not alive() or purse() + k < 0:
		return false
	if k != 0:
		_move_coins(k, "outside")
	return true
