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
		if w.recorder != null:
			w.recorder.till_flow("front:" + str(b.id), seller, total, till_of(b), "sale")     # REC-DIAG
		return
	b = counter_building(seller)                   # a trade counter's sale (B18-DP-01)
	if b.is_empty() or w.holds(w.acting_ref(), b):
		return
	var rec: Dictionary = b.get("counter", {})
	seller.coins -= total
	rec["till"] = int(rec.get("till", 0)) + total
	rec["earned"] = int(rec.get("earned", 0)) + total
	rec["keeper"] = seller.id
	b["counter"] = rec
	w.stat("counter_till_in", total)
	if w.recorder != null:
		w.recorder.till_flow("counter:" + str(b.id), seller, total, int(rec.till), "sale")     # REC-DIAG


## A move between a household's purse and its storefront till, by the rules above or by the player's choice. Nothing
## moves unless all of `amount` can.
func to_till(b: Dictionary, who: Object, amount: int) -> bool:
	if amount <= 0 or not b.has("front") or int(who.coins) < amount:
		return false
	return _move(b.front, who, amount, false, "front:" + str(b.get("id", "")), "contribution")     # LE-04: recorded with the economy on


func from_till(b: Dictionary, who: Object, amount: int) -> bool:
	if amount <= 0 or not b.has("front") or till_of(b) < amount:
		return false
	return _move(b.front, who, amount, true, "front:" + str(b.get("id", "")), "distribution")


## Each morning (Business.daily).
func daily() -> void:
	for b in fronts():
		if till_of(b) <= 0 and not (b.front.has("till") or b.front.has("earned")):
			continue
		var ref := w.holder_of(b)
		if World.is_player_ref(ref) or ref == World.MANOR:
			continue                               # the player's storefront keeps its shop's till (Business); the manor's is not a household's
		_settle(b.front, w.party(front_owner(b)), "front_till", "front:" + str(b.id))
	for b in counter_buildings():
		_settle(b.counter, _payee(b), "counter_till", "counter:" + str(b.id))


# ---------------------------------------------------------------- whose till (one rule) -----
## The one statement of whose money a storefront's till is (ECON-P3), read by daily() to pay it and by the economy
## model (EconActor.controller, "front:<building id>"): the household (or villager) that holds the house; the holder's
## own ref when it is a player or the manor (daily() leaves those tills alone); the manor when the holder is gone (its
## household has ended: escheat). Never "" for a house with a storefront.
func front_owner(b: Dictionary) -> String:
	var ref := w.holder_of(b)
	if World.is_player_ref(ref) or ref == World.MANOR:
		return ref
	return ref if w.party(ref) != null else World.MANOR


## A trade counter's till (B18-DP-01): the household that holds the building, else the keeper who last served at it while
## they live, else the manor (escheat). The same rule _payee pays by.
func counter_owner(b: Dictionary) -> String:
	var ref := w.holder_of(b)
	if ref != World.MANOR and not World.is_player_ref(ref) and w.party(ref) != null:
		return ref
	var k := int(b.get("counter", {}).get("keeper", -1))
	var n: NPC = w.npc(k) if k >= 0 else null
	return World.npc_ref(k) if n != null and n.alive else World.MANOR


## The till a sale by `seller` goes into by after_trade ("front:<building id>" or "counter:<building id>"), else ""
## (a stall's or the seller's own purse). A read: decides nothing, moves nothing.
func till_ref_for(seller: Object) -> String:
	if not (seller is NPC):
		return ""
	var b := keeping(seller)
	if not b.is_empty():
		return "front:" + str(b.id)
	b = counter_building(seller)
	if b.is_empty() or w.holds(w.acting_ref(), b):
		return ""
	return "counter:" + str(b.id)


## Property.household_ended: the storefront tills of the houses an ended household held go to the manor (the rule above:
## "a household that has ended leaves its till to the manor"), before the houses pass to the manor. Without this the
## house became the manor's first, daily() then left the till alone (the manor's is not a household's), and whoever was
## next let or sold the house was paid the dead household's takings.
func household_ended(ref: String) -> void:
	for b in fronts():
		if w.holder_of(b) == ref and till_of(b) > 0:
			_settle(b.front, null, "front_till", "front:" + str(b.id))


## TILL-D1 (owner, 2026-10-28): the household that held house `b` keeps its storefront till: the whole balance goes to its own
## funds (World.party: its head, or the villager), so the next holder starts with an empty till. A player's storefront keeps its
## shop's till (Business) and the manor's is not a household's: unchanged. Nobody of the household left: the escheat
## (household_ended) applies instead. Coins move only from the till to the purse (conserved).
## TILL-D1 (owner: "The household keeps its money. When it moves or gives up the property, its till balance is transferred to its
## own funds. The next occupant receives an empty till"), for every way a house's holder changes (World._handed_over: sale,
## letting, a lease ended, given up or taken back for arrears, a household ending): the previous holder's till goes to its own
## funds: a household's to its head, a villager's to them (one who died: to their household), the manor's to the treasury, a
## player's to that player's purse; with nobody of theirs left, to the manor. Never to the next holder. (LE-04 review item 7.)
func keep_till(b: Dictionary, ref: String) -> void:
	if b.has("front"):
		_keep(b, "front", ref)
	if b.has("counter"):
		# a counter's money was its owner's by counter_owner's rule under the previous holder: the holding household, else
		# (the manor's or a player's building, or nobody left) the keeper serving it, else the manor
		var k := int(b.counter.get("keeper", -1))
		var keeper: NPC = w.npc(k) if k >= 0 else null
		var owner := ref
		if ref == "" or ref == World.MANOR or World.is_player_ref(ref) or w.party(ref) == null:
			owner = World.npc_ref(k) if keeper != null and keeper.alive else World.MANOR
		_keep(b, "counter", owner)


func _keep(b: Dictionary, key: String, ref: String) -> void:
	var rec: Dictionary = b[key]
	var till := int(rec.get("till", 0))
	var tref := key + ":" + str(b.get("id", ""))
	if till <= 0 or ref == "":
		return
	if ref == World.MANOR:                       # LE-04 review 7 (TILL-D1): the manor keeps its money: to the treasury
		rec.till = 0
		w.treasury += till
		w.stat(key + "_till_kept", till)
		if w.recorder != null:
			w.recorder.till_flow(tref, null, -till, 0, "kept")
		return
	if World.is_player_ref(ref):                 # and a player its own: to that player's purse
		var pl: PlayerState = w.player_of_ref(ref)
		if pl != null and _move(rec, pl, till, true, tref, "kept"):
			w.stat(key + "_till_kept", till)
			_rec(tref, rec, pl, -till, "kept")
		return
	var who: NPC = w.party(ref)
	if who == null and ref.begins_with("npc:"):  # a holder who died: to their household (the stall payee's rule)
		var o := w.npc(World.ref_id(ref))
		if o != null and o.household >= 0:
			who = w.party(World.hh_ref(o.household))
	if who == null:                              # nobody of theirs left: to the manor (ECON-P3), never to the next holder
		rec.till = 0
		w.treasury += till
		w.stat(key + "_till_escheat", till)
		if w.recorder != null:
			w.recorder.till_flow(tref, null, -till, 0, "escheat")
		return
	if _move(rec, who, till, true, tref, "kept"):
		w.stat(key + "_till_kept", till)
		_rec(tref, rec, who, -till, "kept")


## TILL-D1: every storefront till of the houses `ref` holds goes to its own funds now (a whole household leaving the village:
## Migration takes the coins with it).
func keep_tills_of(ref: String) -> void:
	for b in fronts():
		if w.holder_of(b) == ref:
			keep_till(b, ref)


## Necessity first, the owner's pay, then the float, for one till record (`rec` holds `till`, `earned`, `paid`), paid to and
## topped up from `who`. Nobody left: the till goes to the manor.
func _settle(rec: Dictionary, who: Object, key: String, ref := "") -> void:
	var till := int(rec.get("till", 0))
	if who == null:
		if till > 0:
			w.treasury += till                     # nobody of the household is left: to the manor
			w.stat(key + "_escheat", till)
			rec.till = 0
			if w.recorder != null:
				w.recorder.till_flow(ref, null, -till, 0, "escheat")     # REC-DIAG
		return
	var short := maxi(0, w.reserve_of(who) - int(who.coins))
	var draw := mini(short, till)
	if draw > 0 and _move(rec, who, draw, true, ref, "necessity"):
		w.stat(key + "_necessity", draw)
		_rec(ref, rec, who, -draw, "necessity")
	till = int(rec.get("till", 0))
	var surplus := till - reserve_coins()
	var pay := int(float(surplus) * payout_share()) if surplus > 0 else 0
	if pay > 0 and _move(rec, who, pay, true, ref, "owner_pay"):
		rec["paid"] = int(rec.get("paid", 0)) + pay
		w.stat(key + "_owner_pay", pay)
		_rec(ref, rec, who, -pay, "owner_pay")
	elif till < reserve_coins():
		var top := mini(reserve_coins() - till, w.spendable(who))
		if top > 0 and _move(rec, who, top, false, ref, "topup"):
			w.stat(key + "_topup", top)
			_rec(ref, rec, who, top, "topup")


## REC-DIAG: a settlement move as the flight recorder's till event (nothing when it is off).
func _rec(ref: String, rec: Dictionary, who: Object, amount: int, why: String) -> void:
	if w.recorder != null and ref != "":
		w.recorder.till_flow(ref, who, amount, int(rec.get("till", 0)), why)


## Coins between a till record and a purse: out of the till (`out`) or into it. Nothing moves unless all of `amount` can.
func _move(rec: Dictionary, who: Object, amount: int, out: bool, tref := "", purpose := "") -> bool:
	if amount <= 0:
		return false
	if w.economy != null and w.economy.market.drive and tref != "" and who != null:
		# LE-04 (OD-LE-07 D06): with the Living Economy on, a move between a business's till and its owner is a recorded transfer
		# through the transaction authority (explicit contribution or distribution, never silent pooling)
		var me := Contracts.ref_of(who)
		var r: Dictionary = w.transactions.transfer_coins(w.transactions.next_txid("business"), tref if out else me, me if out else tref, amount,
				purpose if purpose != "" else ("distribution" if out else "contribution"))
		return bool(r.ok)
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
	return w.party(counter_owner(b))
