class_name EconClaims
extends RefCounted
## Expansion 20 (Living Economy), LE-03: the ONE validation of what a village actor may part with (design s.5 "Prevent
## double-spending and duplicate fills with atomic settlement", s.6 "cannot silently divert committed stock", s.19 "Build a
## second authoritative ledger or inventory service" refused). DISABLED with the rest of the economy: World builds it only
## when game/data/economy.json "enabled" is true, and every World entry point (trade, can_afford, purchase_qty,
## claims_allow / claims_release) does nothing new while World.economy is null. Developer note:
## docs/expansion20/LE03_IMPLEMENTATION.md.
##
## A CLAIM is a hold on an actor's own coins or goods that another use must not silently consume:
##   - contract holds (Contracts.held_for_ref: finished goods a seller still owes on an open CON-01 contract; never yield);
##   - reservations (EconReservations): an ask's goods, a bid's coins (offer:<id>), any other earmark (never yield).
## It moves nothing and keeps no ledger: holdings are read from the existing owners through EconActor, claims from
## Contracts and EconReservations. What it changes is only the offer record, and only by cutting an actor's OWN offer:
##   - a transfer of goods out of a seller may cut that seller's own open ASKS for the item (any sale answers an ask's purpose);
##   - a transfer of coins out of a buyer may cut that buyer's own open BIDS for the same item (the purchase answers the
##     bid's purpose), or any of its bids when the purchase is a household necessity (World.is_necessity: food, firewood,
##     medicine; design s.8 household needs; an agent decision, docs/DECISIONS.md 2026-10-30 LE-03);
##   - nothing else yields: contract holds and other reservations refuse the transfer.
## A cut is the offer's poster changing its own offer (EconOffers.resize, or withdraw when under its lot): recorded as an
## event, never hidden. Offers whose backing has already gone by an outflow nobody can refuse (tax, rent, eating, crafting,
## a death) are STALE; reconcile() cuts them to what is held (dawn, and before any validation that reads the actor), so a
## stale offer can never be filled.
##
## Validate-then-commit: plan() is pure (reads only); World.trade validates both parties and every other precondition, then
## applies the cuts, then moves the goods and coins, so a refused transfer changes nothing at all and an accepted one cannot
## fail half way. Deterministic: offers cut newest first (highest id), refs and items sorted; no RNG, no wall clock.
## Bounded: every read is the actor's own held reservations (EconReservations' owner index) or its own open offers.

var f: EconomyFoundation
var stats := {}                     # counters (diagnostics; saved with the economy key when non-empty)


func _init(found: EconomyFoundation) -> void:
	f = found


## All claims on `ref`'s `item` ("coins" for money): contract holds plus held reservations, less the reservations in
## `exempt` (the offers a settlement is filling).
func claims(ref: String, item: String, exempt := []) -> int:
	var k := f.reservations.contract_held(ref, item) + f.reservations.reserved(ref, item)
	for rid in exempt:
		var r := f.reservations.get_record(int(rid))
		if not r.is_empty() and str(r.state) == EconReservations.HELD and str(r.owner) == ref and str(r.item) == item:
			k -= int(r.qty)
	return k


## The actor's own open offers whose reservation backs `item` (asks for goods, bids for coins), newest first:
## [{id, side, item, reserved, price_each, remaining, min_lot}]. `exempt` reservations are left out.
func own_offers(ref: String, item: String, exempt := []) -> Array:
	var out := []
	for o in f.offers.open_of(ref):
		var backs := str(o.item) if o.side == EconOffers.ASK else EconReservations.COINS
		if backs != item or exempt.has(int(o.reservation)):
			continue
		var res := f.reservations.get_record(int(o.reservation)) if int(o.reservation) >= 0 else {}
		var held := int(res.qty) if not res.is_empty() and str(res.state) == EconReservations.HELD else 0
		out.append({"id": int(o.id), "side": str(o.side), "item": str(o.item), "reserved": held, "price_each": int(o.price_each),
			"remaining": f.offers.remaining(int(o.id)), "min_lot": int(o.min_lot)})
	out.sort_custom(func(a, b): return int(a.id) > int(b.id))
	return out


## Whether an own offer may yield to this transfer (see the header).
static func _yields(o: Dictionary, item: String, for_item: String, necessity: bool) -> bool:
	if o.side == EconOffers.ASK:
		return true                                  # a sale of the goods answers the ask
	return necessity or (for_item != "" and str(o.item) == for_item)


## Pure. Whether `ref` may part with `qty` of `item` ("coins": `qty` coins) for a purchase of `for_item` (coins only;
## `necessity` a household necessity), with the reservations in `exempt` not counted. {ok, reason, cuts: [[offer id, units]]}:
## the own offers that must yield, newest first, and by how many units each.
func plan(ref: String, item: String, qty: int, for_item := "", necessity := false, exempt := []) -> Dictionary:
	var held := f.actors.holding(ref, item)
	if qty <= 0:
		return {"ok": true, "reason": "", "cuts": []}
	if held < qty:
		return {"ok": false, "reason": "not held", "cuts": []}
	var short := claims(ref, item, exempt) - (held - qty)
	if short <= 0:
		return {"ok": true, "reason": "", "cuts": []}
	var cuts := []
	for o in own_offers(ref, item, exempt):
		if short <= 0:
			break
		if not _yields(o, item, for_item, necessity) or int(o.reserved) <= 0:
			continue
		var per := 1 if o.side == EconOffers.ASK else maxi(1, int(o.price_each))
		var units := mini(int(o.remaining), ceili(float(mini(short, int(o.reserved))) / float(per)))
		if units <= 0:
			continue
		cuts.append([int(o.id), units])
		short -= mini(int(o.reserved), units * per)
	if short > 0:
		return {"ok": false, "reason": "claimed", "cuts": []}
	return {"ok": true, "reason": "", "cuts": cuts}


## Applies a plan's cuts: each offer loses `units` of what remains (EconOffers.resize), or is withdrawn when what is left is
## under its lot. Returns the ids cut.
func apply(cuts: Array, why := "yield") -> Array:
	var done := []
	for c in cuts:
		if _cut(int(c[0]), int(c[1]), why):
			done.append(int(c[0]))
	return done


func _cut(id: int, units: int, why: String) -> bool:
	var o := f.offers.get_offer(id)
	if o.is_empty() or o.state != EconOffers.OPEN or units <= 0:
		return false
	var keep := f.offers.remaining(id) - units
	var ok := false
	if keep <= 0 or keep < int(o.min_lot):
		ok = f.offers.withdraw(id)
	else:
		ok = f.offers.resize(id, int(o.filled) + int(o.committed) + keep)
	if ok:
		_stat("offers_cut_" + why)
	return ok


## Cuts `ref`'s own offers (newest first) until every claim on `item` is backed by what it holds; returns the ids cut. Only
## offers are cut: contract holds and other reservations stay as they are (EconReservations.unbacked reports them).
func reconcile(ref: String, item: String) -> Array:
	var short := claims(ref, item) - f.actors.holding(ref, item)
	if short <= 0:
		return []
	var cuts := []
	for o in own_offers(ref, item):
		if short <= 0:
			break
		if int(o.reserved) <= 0:
			continue
		var per := 1 if o.side == EconOffers.ASK else maxi(1, int(o.price_each))
		var units := mini(int(o.remaining), ceili(float(mini(short, int(o.reserved))) / float(per)))
		cuts.append([int(o.id), units])
		short -= mini(int(o.reserved), units * per)
	return apply(cuts, "stale")


## reconcile for every owner with held reservations (dawn): bounded by the held reservations.
func reconcile_all() -> Array:
	var cut := []
	var owners: Array = f.reservations._by_owner.keys()
	owners.sort()
	for ref in owners:
		var items := {}
		for r in f.reservations.held_of(ref):
			items[str(r.item)] = true
		var names: Array = items.keys()
		names.sort()
		for it in names:
			cut.append_array(reconcile(ref, it))
	return cut


## The units of `item` ("coins") `ref` may part with for this purpose without breaking a claim that cannot yield (stale
## offers reconciled first). The holding itself when nothing is claimed.
func free_units(ref: String, item: String, for_item := "", necessity := false) -> int:
	if f.reservations._by_owner.has(ref):
		reconcile(ref, item)
	var held := f.actors.holding(ref, item)
	var k := claims(ref, item)
	if k <= 0:
		return held
	var give := 0
	for o in own_offers(ref, item):
		if _yields(o, item, for_item, necessity):
			give += int(o.reserved)
	return maxi(0, held - maxi(0, k - give))


## World.trade (LE-03): validate both parties of a sale of `qty` `id` for `total` coins. Stale offers of both are reconciled
## first (a correction, not part of the sale). {ok, reason, cuts}: the cuts to apply before the transfer.
func check_trade(buyer: Object, seller: Object, id: String, qty: int, total: int, exempt := []) -> Dictionary:
	var br := Contracts.ref_of(buyer)
	var sr := Contracts.ref_of(seller)
	if f.reservations._by_owner.has(br):
		reconcile(br, EconReservations.COINS)
	if f.reservations._by_owner.has(sr) or f.reservations.contract_held(sr, id) > 0:
		reconcile(sr, id)
	var s := plan(sr, id, qty, "", false, exempt)
	if not s.ok:
		_stat("trade_refused_seller_" + str(s.reason).replace(" ", "_"))
		return s
	var b := plan(br, EconReservations.COINS, total, id, World.is_necessity(id), exempt)
	if not b.ok:
		_stat("trade_refused_buyer_" + str(b.reason).replace(" ", "_"))
		return b
	return {"ok": true, "reason": "", "cuts": s.cuts + b.cuts}


## Units on open (accepted) or agreed-in-principle (signing) CON-01 contracts still to come TO `ref` (as buyer) of `item`.
func inbound(ref: String, item: String) -> int:
	var cs: Contracts = f.actors.w.contracts
	if cs == null:
		return 0
	var k := 0
	for c in cs.list:
		if c.buyer == ref and c.item == item and str(c.state) in ["accepted", "signing"] and str(c.get("kind", "goods")) != "service":
			k += Contracts.left(c)
	return k


## LE-03 production (design s.6: "An accepted order creates a real obligation ... Explicitly reserve or earmark material while
## retaining physical ownership and location"): when a CON-01 goods contract the seller will craft opens (route "craft"), the
## seller earmarks the inputs it holds for the units still owed (EconContractLinks.earmark: purpose "contract:<id>", expiring
## with the contract's deadline, released by the dawn sweep whatever ends it). Only what is free of other claims; what it
## lacks it must still buy. Market driving only. Returns the reservation ids made.
func on_contract_open(c: Dictionary) -> Array:
	var made := []
	if not f.market.drive or str(c.get("route", "")) != "craft" or str(c.get("recipe", "")) == "" or not GameData.recipes.has(str(c.recipe)):
		return made
	var rec: Dictionary = GameData.recipes[str(c.recipe)]
	var per := maxi(1, int((rec.out as Dictionary).get(str(c.item), 1)))
	var batches := ceili(float(Contracts.left(c)) / float(per))
	var ins: Array = (rec["in"] as Dictionary).keys()
	ins.sort()
	for i in ins:
		if str(i) == str(c.item):
			continue
		var q := mini(batches * int(rec["in"][i]), f.reservations.available(str(c.seller), str(i)))
		if q > 0:
			var r := f.contract_links.earmark(int(c.id), str(i), q)
			if r.ok:
				made.append(int(r.id))
				_stat("inputs_earmarked")
	return made


## The seller's input earmarks a recipe making `outputs` may draw on: those of its open contracts for one of the outputs.
func _earmarks_for(ref: String, outputs: Dictionary) -> Array:
	var out := []
	for r in f.reservations.held_of(ref):
		var purpose := str(r.purpose)
		if not purpose.begins_with(EconContractLinks.PURPOSE):
			continue
		var c: Dictionary = f.actors.w.contracts.get_contract(int(purpose.substr(EconContractLinks.PURPOSE.length())))
		if not c.is_empty() and outputs.has(str(c.item)):
			out.append(int(r.id))
	return out


## Pure. Whether villager `n` may work `recipe` from its own pack without consuming inputs earmarked for a contract the recipe
## does not serve (design s.6: "cannot silently divert committed stock to unrelated products"). True when nothing is earmarked.
func craft_ok(n: NPC, recipe: String) -> bool:
	var ref := World.npc_ref(n.id)
	if not f.reservations._by_owner.has(ref) or not GameData.recipes.has(recipe):
		return true
	var rec: Dictionary = GameData.recipes[recipe]
	var exempt := _earmarks_for(ref, rec.out)
	for i in rec["in"]:
		if not bool(plan(ref, str(i), int(rec["in"][i]), "", false, exempt).ok):
			_stat("craft_refused_earmarked")
			return false
	return true


## After `recipe` was worked from the pack: the earmarks it drew on (contracts for its outputs) shrink by what was used and
## stay backed (consumed, the rest earmarked again within what is held).
func after_craft(n: NPC, recipe: String) -> void:
	var ref := World.npc_ref(n.id)
	if not f.reservations._by_owner.has(ref) or not GameData.recipes.has(recipe):
		return
	var rec: Dictionary = GameData.recipes[recipe]
	var used := {}
	for i in rec["in"]:
		used[str(i)] = int(rec["in"][i])
	for rid in _earmarks_for(ref, rec.out):
		var r := f.reservations.get_record(rid)
		var it := str(r.item)
		if int(used.get(it, 0)) <= 0:
			continue
		var take := mini(int(used[it]), int(r.qty))
		used[it] = int(used[it]) - take
		var cid := int(str(r.purpose).substr(EconContractLinks.PURPOSE.length()))
		f.reservations.consume(rid)
		var left := mini(int(r.qty) - take, f.reservations.available(ref, it))
		if left > 0:
			f.contract_links.earmark(cid, it, left)
	f.contract_links.sweep()


## LE-03 audit (tests, economy_sim): every integrity breach found now, sorted. Empty when consistent. Checks: no negative
## coins or goods for any villager, household pantry or the player; every open priced offer holds a reservation covering
## exactly what remains (asks: units; bids: units x price); no reservation is unbacked except by an outflow not yet
## reconciled (reported, kind "unbacked"); no offer's fills and commitments exceed its quantity.
func audit() -> Array:
	var out := []
	var w := f.actors.w
	for n: NPC in w.npcs:
		if n.coins < 0:
			out.append({"kind": "negative_coins", "who": World.npc_ref(n.id), "value": n.coins})
		for id in n.inv.items:
			if int(n.inv.items[id]) < 0:
				out.append({"kind": "negative_goods", "who": World.npc_ref(n.id), "item": id, "value": int(n.inv.items[id])})
	for h in w.households.size():
		var p: Inventory = w.households[h].pantry
		for id in p.items:
			if int(p.items[id]) < 0:
				out.append({"kind": "negative_goods", "who": World.hh_ref(h), "item": id, "value": int(p.items[id])})
	if w.player != null and w.player.coins < 0:
		out.append({"kind": "negative_coins", "who": World.PLAYER, "value": w.player.coins})
	var ids: Array = f.offers.records.keys()
	ids.sort()
	for id in ids:
		var o: Dictionary = f.offers.records[id]
		if int(o.filled) + int(o.get("committed", 0)) > int(o.qty):
			out.append({"kind": "overfilled", "offer": int(id)})
		if o.state != EconOffers.OPEN:
			continue
		var want := f.offers.remaining(int(id)) * (1 if o.side == EconOffers.ASK else int(o.price_each))
		var res := f.reservations.get_record(int(o.reservation)) if int(o.reservation) >= 0 else {}
		var have := int(res.qty) if not res.is_empty() and str(res.state) == EconReservations.HELD else 0
		if want > 0 and have != want:
			out.append({"kind": "offer_not_backed", "offer": int(id), "want": want, "reserved": have})
	for u in f.reservations.unbacked():
		out.append({"kind": "unbacked", "who": str(u.owner), "item": str(u.item), "short": int(u.short)})
	return out


func _stat(k: String, n := 1) -> void:
	stats[k] = int(stats.get(k, 0)) + n


func is_empty() -> bool:
	return stats.is_empty()


func to_dict() -> Dictionary:
	var keys: Array = stats.keys()
	keys.sort()
	var d := {}
	for k in keys:
		d[k] = int(stats[k])
	return {"stats": d}


func load_dict(d: Dictionary) -> void:
	stats = {}
	var s: Dictionary = d.get("stats", {})
	for k in s:
		stats[str(k)] = int(s[k])
