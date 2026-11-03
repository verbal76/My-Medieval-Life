class_name SettlementFolk
extends RefCounted
## REGION-NAV-01 AD-2 (owner 2026-11-02: "the envoy must systematically attempt to meet with every accessible business owner and
## independent crafter ... The information must originate from the actual NPC's inventory, needs, production, business records,
## and willingness to trade"; docs/region_nav/IMPLEMENTATION_PLAN.md): the people of a settlement whom a visitor can meet at its
## site. Each is a member of one of the settlement's own households (OffMapSettlement.hh), speaking for the books they keep:
##
##   keeper    each business's keeper: the eldest adult of the business's longest-serving worker household (its first living
##             worker), at the door of the business's building (Overworld site slot of its trade); speaks for the business's
##             till and stock (SettlementParty "region:<id>/<business>", the merchant business as "region:<id>/trader")
##   official  the eldest adult of the first official household, at the hall's door; speaks for the treasury
##   crafter   (REGION-NAV-01 Q4, owner 2026-11-03, option C) the head of each household working on its own account
##             (OffMapSettlement.own), along the lane under the last row; met while they have their own work to sell; speaks for
##             their own trade's purse and stock (party "region:<id>/own:<household>")
## A settlement's businesses are run by worker households sharing one till (OffMapSettlement), so the keeper IS the business's
## owner in this model; a worker household that is not self-employed speaks through its business's keeper.
##
## Names are drawn from the household and member (the world seed, the settlement, the household id, the member index), so a
## person keeps their name while their household lives; nothing extra is saved. Presence: at their door in working hours
## (work_hours), else at home (not met); a trader is away while on the road to the village (Regions.visiting). A business that is
## closed or has no living worker has nobody at its door.
##
## Trading with a person (REGION-NAV-01 Q5, owner 2026-11-03): the settlement's side is SettlementParty.deal (its checks, its
## outside_* flow line, its journal line naming the other party); the village's side is booked exactly as the courier service's
## edge books it (_village_side: imported_/exported_, coin_sources, caravan_coins_*). At the settlement's market price
## (OffMapSettlement.price), within what the person will sell (sale_cap) or wants (need_rate) and what the buyer's purse pays:
## nothing is created or destroyed. settlement_folk_test proves the books equal to the courier edge's for the same trade.

const WORK_FROM := 7
const WORK_TO := 18
const WANT_DAYS := 7.0          # a want is what the business uses over this many days, less what it holds


static func _settlement(w: World, sid: String) -> OffMapSettlement:
	if w.regions == null or not w.regions.by_id.has(sid):
		return null
	return w.regions.by_id[sid]


## The people of settlement `sid` whom a visitor may meet, in the site's building order: [{ref, role, business, trade, name, sex,
## household, spot: Vector2i, settlement}]. Empty when the settlement or its site is unknown.
static func people(w: World, sid: String) -> Array:
	var s := _settlement(w, sid)
	if s == null or w.map == null or w.map.overworld == null:
		return []
	var st: Dictionary = w.map.overworld.site(sid)
	if st.is_empty():
		return []
	var out := []
	for sl in st.slots:
		var trade := str(sl.trade)
		var hid := -1
		var role := "keeper"
		var holder := ""
		if trade == "official":
			role = "official"
			holder = "treasury"
			for h in s.hh:
				if bool(h.alive) and str(h.trade) == "official":
					hid = int(h.id)
					break
		else:
			var bt: String = OffMapSettlement.TRADE_BIZ.get(trade, "")
			if bt == "" or not s.biz.has(bt):
				continue
			holder = "trader" if bt == "merchant" else bt
			for wid in s.biz[bt].workers:
				if int(wid) < s.hh.size() and bool(s.hh[int(wid)].alive):
					hid = int(wid)
					break
		if hid < 0:
			continue
		var who := _eldest(s.hh[hid])
		if who < 0:
			continue
		var sex := "female" if int(s.hh[hid].mem[who][1]) == 1 else "male"
		out.append({"ref": "region:%s/%s" % [sid, holder], "role": role, "business": holder, "trade": trade,
			"name": name_of(w, sid, hid, who, sex), "sex": sex, "household": hid, "spot": sl.spot, "settlement": sid})
	# REGION-NAV-01 Q4: the self-employed crafters (OffMapSettlement.own), each the head of the household working on its own
	# account, along the lane under the last row of buildings, in household order
	var k := 0
	for key in s._own_ids():
		var hid := int(key)
		if hid >= s.hh.size() or not bool(s.hh[hid].alive):
			continue
		var who := _eldest(s.hh[hid])
		if who < 0:
			continue
		var sex := "female" if int(s.hh[hid].mem[who][1]) == 1 else "male"
		out.append({"ref": "region:%s/own:%d" % [sid, hid], "role": "crafter", "business": "own:%d" % hid,
			"trade": OffMapSettlement._trade_of(str(s.own[key].type)), "name": name_of(w, sid, hid, who, sex), "sex": sex,
			"household": hid, "spot": Vector2i(st.gate) + Vector2i(-9 + 3 * (k % 7), 0), "settlement": sid})
		k += 1
	return out


static func _eldest(h: Dictionary) -> int:
	var best := -1
	for j in (h.get("mem", []) as Array).size():
		if best < 0 or int(h.mem[j][0]) < int(h.mem[best][0]):
			best = j
	return best


## A member's name: a first name of their sex and their household's family name, drawn from the world seed, the settlement, the
## household and the member.
static func name_of(w: World, sid: String, hid: int, member: int, sex: String) -> String:
	var salt := sid.hash() & 0xFFFF
	var firsts: Array = Population.FIRST.filter(func(n: String) -> bool: return Life.sex_of_name(n) == sex)
	var first: String = firsts[Overworld.hash32(w.seed, salt, hid, 90 + member) % firsts.size()]
	var family: String = Population.FAMILY[Overworld.hash32(w.seed, salt, hid, 91) % Population.FAMILY.size()]
	return "%s %s" % [first, family]


## Whether they are at their door now: working hours, and a trader not on the road to the village today.
static func present(w: World, person: Dictionary) -> bool:
	var hr := int(w.hour())
	if hr < WORK_FROM or hr >= WORK_TO:
		return false
	if str(person.business) == "trader":
		for s: OffMapSettlement in w.regions.visiting(w.day()):
			if s.id == str(person.settlement):
				return false
	if str(person.role) == "crafter" and offers(w, person).sells.is_empty():
		return false                     # REGION-NAV-01 Q4: a crafter is met while actively offering goods
	return w.regions.party(str(person.ref)) != null


## Why someone cannot be met now, or "" (they can).
static func absent_reason(w: World, person: Dictionary) -> String:
	var hr := int(w.hour())
	if hr < WORK_FROM or hr >= WORK_TO:
		return "%s is at home: they keep their door from %d:00 to %d:00." % [person.name, WORK_FROM, WORK_TO]
	if str(person.business) == "trader" and not present(w, person):
		return "%s is on the road with the caravan today." % person.name
	if str(person.role) == "crafter" and not present(w, person):
		return "%s has nothing of their own work to sell today." % person.name
	return ""


## What a person will sell and wants, from their own books now: {sells: [{item, n, price}], wants: [{item, n, price}]}, items in
## name order. Sells: what they hold beyond their own keep (sale_cap). Wants: what their business uses over WANT_DAYS less what
## it holds. Price: the settlement's market price today.
static func offers(w: World, person: Dictionary) -> Dictionary:
	var p: SettlementParty = w.regions.party(str(person.ref))
	var s := _settlement(w, str(person.settlement))
	var out := {"sells": [], "wants": []}
	if p == null or s == null:
		return out
	var ids: Array = p.held_items().keys()
	ids.sort()
	for id in ids:
		var n: int = p.sale_cap(str(id))
		if n > 0:
			out.sells.append({"item": str(id), "n": n, "price": s.price(str(id))})
	var needs: Array = p.need_items()
	for id in needs:
		var want := ceili(p.need_rate(str(id)) * WANT_DAYS) - p.held(str(id))
		if want > 0:
			out.wants.append({"item": str(id), "n": want, "price": s.price(str(id))})
	return out


## `buyer` (a player or villager reference) buys `n` of `item` from `person`: "" when done, else why not. Goods and coins move
## through the courier service's edge on the settlement's books (see the header).
static func buy_from(w: World, buyer: String, person: Dictionary, item: String, n: int) -> String:
	if not present(w, person):
		return absent_reason(w, person)
	var p: SettlementParty = w.regions.party(str(person.ref))
	var s := _settlement(w, str(person.settlement))
	if p == null or n <= 0:
		return "There is nobody to deal with."
	if p.sale_cap(item) < n:
		return "%s will not sell that many (%d)." % [person.name, maxi(0, p.sale_cap(item))]
	var total := s.price(item) * n
	var cs: CourierService = w.couriers
	if cs.coins_of(buyer) < total:
		return "That costs %d coins." % total
	var to = cs.inv_of(buyer)
	if to == null or not to.can_add(item):
		return "You have no room for it."
	if not p.deal("sell", {"id": buyer}, item, n, total, w.day()):
		return "%s cannot hand it over." % person.name
	_village_side(w, buyer, item, n, -total)
	w.stat("region_bought_" + item, float(n))
	return ""


## `seller` sells `n` of `item` to `person`, who buys only what their business wants and their purse pays.
static func sell_to(w: World, seller: String, person: Dictionary, item: String, n: int) -> String:
	if not present(w, person):
		return absent_reason(w, person)
	var p: SettlementParty = w.regions.party(str(person.ref))
	var s := _settlement(w, str(person.settlement))
	if p == null or n <= 0:
		return "There is nobody to deal with."
	var want := 0
	for e in offers(w, person).wants:
		if str(e.item) == item:
			want = int(e.n)
	if want < n:
		return "%s wants no more than %d of that." % [person.name, want]
	var total := s.price(item) * n
	if not p.can_deal("buy", item, n, total):
		return "%s cannot pay %d coins for it." % [person.name, total]
	var cs: CourierService = w.couriers
	var from = cs.inv_of(seller)
	if from == null or from.count(item) < n:
		return "You do not have that many."
	if not p.deal("buy", {"id": seller}, item, n, total, w.day()):
		return "%s cannot take it." % person.name
	_village_side(w, seller, item, -n, total)
	w.stat("region_sold_" + item, float(n))
	return ""


## REGION-NAV-01 Q5 (owner 2026-11-03): the village's side of a trade with a settlement's person. The settlement's side is
## SettlementParty.deal (its checks, its outside_* flow lines, its journal line naming the other party); this books the village's
## side exactly as the courier service's edge does (CourierService._Edge, add_coins): the goods into or out of the village
## person's pack with an imported_ or exported_ count, and the coins out of or into their purse with coin_sources and
## caravan_coins_out / _in, so both audits balance. `goods` > 0: into the village; `coins` > 0: into the village.
static func _village_side(w: World, who: String, item: String, goods: int, coins: int) -> void:
	var cs: CourierService = w.couriers
	var inv = cs.inv_of(who)
	if goods > 0:
		inv.add(item, goods)
		w.stat("imported_" + item, float(goods))
	elif goods < 0:
		inv.remove(item, -goods)
		w.stat("exported_" + item, float(-goods))
	cs.add_coins(who, coins)
	if coins != 0:
		w.coin_sources += coins
		w.stat("caravan_coins_in" if coins > 0 else "caravan_coins_out", float(absi(coins)))
