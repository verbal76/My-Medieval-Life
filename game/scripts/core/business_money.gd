class_name BusinessMoney
extends RefCounted
## ECON-P3 (owner, 2026-10-23, docs/directives/2026-10-23_owner_answers_caravan_purses_skills.md): business money and
## household money are kept apart. "A shop has its own till; the owner pays themselves from it; a failing shop cannot
## silently eat the family's food money and vice versa, though the owner can choose to move money."
##
## The player's stall and shop and the market stalls already keep a till (Business, Stalls). This adds the villagers'
## side: a household's storefront (B14) keeps its sales in its own till, `front.till` in the house's own dict (saved with
## the building; an older save has none, which reads as an empty till, so nothing moves on load). B18-DP-01 / ECON-P3: the
## village's trade counters that sell to customers (the tavern's counter and the skilled-trade counters, Counters) keep
## their takings the same way, in the building's own `counter` record ({till, keeper, earned, paid}; absent reads as empty),
## paid to the household that holds the building, else to the keeper who made the sales. Every morning, in
## the building-id order:
##   1. necessity first (PAR-02A, the existing reserve rule): a household member short of their necessity reserve
##      (World.reserve_of) draws the shortfall from the till, even below the till's working reserve;
##   2. the owner pays themselves: payout_share (the off-map settlements' rule, settlements.json) of what the till holds
##      above `till_reserve` (balance.json business_money, provisional) goes to the household's purse;
##   3. a till below `till_reserve` is topped up from the household's spendable coins (World.spendable: the purse above
##      the necessity reserve), never from the family's food money.
## Coins only move between a till and a purse (conserved; World.total_coins counts the tills). A household that has
## ended leaves its till to the manor, as a stall's net does.

var w: World


func _init(world: World) -> void:
	w = world


static func reserve_coins() -> int:
	return int(GameData.b("business_money").till_reserve)


static func payout_share() -> float:
	return float(OffMapSettlement.rules().payout_share)


## Houses with a storefront, in id order.
func fronts() -> Array:
	var out := []
	var ids: Array = w.buildings.keys()
	ids.sort()
	for id in ids:
		if w.buildings[id].has("front"):
			out.append(w.buildings[id])
	return out


static func till_of(b: Dictionary) -> int:
	return int(b.get("front", {}).get("till", 0))


## Coins in the villagers' storefront tills (counted with the village's money: Business.tills).
func front_tills() -> int:
	var t := 0
	for b in fronts():
		t += till_of(b)
	return t


## The house whose storefront villager `n` is keeping at the counter now, or {}.
func keeping(n: NPC) -> Dictionary:
	if n.home == "" or int(w.front_keepers.get(n.home, -1)) != n.id or not w.buildings.get(n.home, {}).has("front") or not w.at_post(n):
		return {}
	return w.buildings[n.home]


## World.trade's hook: a keeper's sale at the household's storefront goes into the storefront's till, not the keeper's purse.
func after_trade(seller: Object, total: int) -> void:
	if total <= 0 or not (seller is NPC) or int(seller.coins) < total:
		return
	var b := keeping(seller)
	if not b.is_empty():
		seller.coins -= total
		b.front.till = till_of(b) + total
		b.front["earned"] = int(b.front.get("earned", 0)) + total
		w.stat("front_till_in", total)
		return
	b = counter_building(seller)                   # a trade counter's sale (B18-DP-01)
	if b.is_empty() or w.holds(World.PLAYER, b):
		return
	var rec: Dictionary = b.get("counter", {})
	seller.coins -= total
	rec["till"] = int(rec.get("till", 0)) + total
	rec["earned"] = int(rec.get("earned", 0)) + total
	rec["keeper"] = seller.id
	b["counter"] = rec
	w.stat("counter_till_in", total)


## A move between a household's purse and its storefront till, by the rules above or by the player's choice. Nothing
## moves unless all of `amount` can.
func to_till(b: Dictionary, who: Object, amount: int) -> bool:
	if amount <= 0 or not b.has("front") or int(who.coins) < amount:
		return false
	who.coins -= amount
	b.front.till = till_of(b) + amount
	return true


func from_till(b: Dictionary, who: Object, amount: int) -> bool:
	if amount <= 0 or not b.has("front") or till_of(b) < amount:
		return false
	b.front.till = till_of(b) - amount
	who.coins += amount
	return true


## Each morning (Business.daily).
func daily() -> void:
	for b in fronts():
		if till_of(b) <= 0 and not (b.front.has("till") or b.front.has("earned")):
			continue
		var ref := w.holder_of(b)
		if ref == World.PLAYER or ref == World.MANOR:
			continue                               # the player's storefront keeps its shop's till (Business); the manor's is not a household's
		_settle(b.front, w.party(ref), "front_till")
	for b in counter_buildings():
		_settle(b.counter, _payee(b), "counter_till")


## Necessity first, the owner's pay, then the float, for one till record (`rec` holds `till`, `earned`, `paid`), paid to and
## topped up from `who`. Nobody left: the till goes to the manor.
func _settle(rec: Dictionary, who: Object, key: String) -> void:
	var till := int(rec.get("till", 0))
	if who == null:
		if till > 0:
			w.treasury += till                     # nobody of the household is left: to the manor
			w.stat(key + "_escheat", till)
			rec.till = 0
		return
	var short := maxi(0, w.reserve_of(who) - int(who.coins))
	var draw := mini(short, till)
	if draw > 0 and _move(rec, who, draw, true):
		w.stat(key + "_necessity", draw)
	till = int(rec.get("till", 0))
	var surplus := till - reserve_coins()
	var pay := int(float(surplus) * payout_share()) if surplus > 0 else 0
	if pay > 0 and _move(rec, who, pay, true):
		rec["paid"] = int(rec.get("paid", 0)) + pay
		w.stat(key + "_owner_pay", pay)
	elif till < reserve_coins():
		var top := mini(reserve_coins() - till, w.spendable(who))
		if top > 0 and _move(rec, who, top, false):
			w.stat(key + "_topup", top)


## Coins between a till record and a purse: out of the till (`out`) or into it. Nothing moves unless all of `amount` can.
func _move(rec: Dictionary, who: Object, amount: int, out: bool) -> bool:
	if amount <= 0:
		return false
	if out:
		if int(rec.get("till", 0)) < amount:
			return false
		rec.till = int(rec.till) - amount
		who.coins += amount
	else:
		if int(who.coins) < amount:
			return false
		who.coins -= amount
		rec.till = int(rec.get("till", 0)) + amount
	return true


# ---------------------------------------------------------------- trade counters (B18-DP-01) -----
## The building a trade counter's sale belongs to, when `seller` is serving at one now (the tavern's counter for the
## tavernkeeper, a skilled-trade counter for the keeper who came to it), else {}. A market stall's merchant (Stalls) and a
## household's storefront keeper (above) have their own tills.
func counter_building(seller: Object) -> Dictionary:
	if not (seller is NPC) or not w.at_post(seller) or not keeping(seller).is_empty():
		return {}
	var station := ""
	for id in w.counters.serving:
		if int(w.counters.serving[id]) == seller.id:
			station = str(id)
	if station == "" and seller.job == "tavernkeeper" and w.stations.has(seller.workplace):
		station = str(seller.workplace)
	if station == "" or not w.stations.has(station):
		return {}
	return w.buildings.get(str(w.stations[station].get("building", "")), {})


## Buildings holding a counter till record, in id order.
func counter_buildings() -> Array:
	var out := []
	var ids: Array = w.buildings.keys()
	ids.sort()
	for id in ids:
		if w.buildings[id].has("counter"):
			out.append(w.buildings[id])
	return out


static func counter_till_of(b: Dictionary) -> int:
	return int(b.get("counter", {}).get("till", 0))


## Coins in the trade counters' tills (counted with the village's money: Business.tills).
func counter_tills() -> int:
	var t := 0
	for b in counter_buildings():
		t += counter_till_of(b)
	return t


## Who is paid from a counter's till: the household that holds the building, else the keeper who last served at it.
func _payee(b: Dictionary) -> Object:
	var ref := w.holder_of(b)
	if ref != World.MANOR and ref != World.PLAYER:
		var o: Object = w.party(ref)
		if o != null:
			return o
	var k := int(b.counter.get("keeper", -1))
	var n: NPC = w.npc(k) if k >= 0 else null
	return n if n != null and n.alive else null
