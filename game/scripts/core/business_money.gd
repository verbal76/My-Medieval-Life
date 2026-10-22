class_name BusinessMoney
extends RefCounted
## ECON-P3 (owner, 2026-10-23, docs/directives/2026-10-23_owner_answers_caravan_purses_skills.md): business money and
## household money are kept apart. "A shop has its own till; the owner pays themselves from it; a failing shop cannot
## silently eat the family's food money and vice versa, though the owner can choose to move money."
##
## The player's stall and shop and the market stalls already keep a till (Business, Stalls). This adds the villagers'
## side: a household's storefront (B14) keeps its sales in its own till, `front.till` in the house's own dict (saved with
## the building; an older save has none, which reads as an empty till, so nothing moves on load). Every morning, in
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
	if total <= 0 or not (seller is NPC):
		return
	var b := keeping(seller)
	if b.is_empty() or int(seller.coins) < total:
		return
	seller.coins -= total
	b.front.till = till_of(b) + total
	b.front["earned"] = int(b.front.get("earned", 0)) + total
	w.stat("front_till_in", total)


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
		var who: Object = w.party(ref)
		var f: Dictionary = b.front
		if who == null:
			if till_of(b) > 0:
				w.treasury += till_of(b)           # nobody of the household is left: to the manor
				w.stat("front_till_escheat", till_of(b))
				f.till = 0
			continue
		var short := maxi(0, w.reserve_of(who) - int(who.coins))
		var draw := mini(short, till_of(b))
		if draw > 0 and from_till(b, who, draw):
			w.stat("front_till_necessity", draw)
		var surplus := till_of(b) - reserve_coins()
		var pay := int(float(surplus) * payout_share()) if surplus > 0 else 0
		if pay > 0 and from_till(b, who, pay):
			f["paid"] = int(f.get("paid", 0)) + pay
			w.stat("front_till_owner_pay", pay)
		elif till_of(b) < reserve_coins():
			var top := mini(reserve_coins() - till_of(b), w.spendable(who))
			if top > 0 and to_till(b, who, top):
				w.stat("front_till_topup", top)
