class_name CourierService
extends RefCounted
## PROSPECTIVE (Expansion 18, X18-Q12, X18-Q12-BOOTH, X18-Q12-POST; PROS-18): couriers, their booths, regular routes and
## special deliveries, by the owner's decisions of 2026-10-21 (Q18-12 decided; docs/directives/
## 2026-10-21_expansion18_capability_simulations_contracts.md, _courier_booths_known_recipients.md,
## _courier_contract_interface_pricing.md on staging). Rules live here; the courier window (ui/courier_window.gd) only
## shows them and collects choices (DVW-A12 principle). Not wired into the live game loop: tests drive it.
##
## Booths (X18-Q12-BOOTH): a booth is an existing market stall (World.stalls) with no tenant, or a stall its keeper builds
## by the STALL rules (Stalls.build: three planks from the keeper's own pack), kept by a villager the existing job rule
## lets be hired (Construction.can_hire). Each settlement has one; an off-map settlement's booth is its own party.
## Regular-route fees are paid at the booth and scheduled deliveries are booked there.
##
## Regular routes: between two booths, leaving every `every_days`; a flat fee a load (`fee_per_load` for up to
## `load_units`), paid at the booth when booked. Special deliveries: to a chosen person or business, negotiated (an offer,
## the courier's counter, acceptance; CON-01-shaped record, provisional adapter until CON-01 is reconciled), the
## courier's least acceptable fee computed from the work (journey days there and back, loads, stops, notarial service,
## the carriers' day wage). Self-collection needs no courier (RegionalMarket "self").
##
## Recipients (X18-Q12-POST): only people and businesses the sender knows -- people from the existing acquaintance records
## (Relations ties with days_known >= 1) and businesses from a prior trade (Relations.trades, the commercial-contact
## record kept beside the ties; a trade with a business makes it a contact even with no personal tie to its owner; the
## owner represents it), and off-map parties from the regional trade journals (the party's journal, Regions.journal). Locations come
## from world records (a person's home door, a business's stall or workplace, an off-map party's booth): no typed
## addresses. The same rules serve the player and villagers.
##
## Physical execution (tick): the goods leave the sender's pack when booked (handed over at the booth, or to the courier
## for a special delivery) and ride in the courier's own pack; after the journey's days the courier hands them over, takes
## the payment or goods it was told to collect, and travels back to hand them to the sender or deposit them at the
## sender's booth. A contract is fulfilled only when every physical and financial obligation is done. A courier who dies
## or is waylaid interrupts it: what it carried stays in its pack (and passes to its heir by World.kill, like any goods),
## the special fee held at the booth goes back to the payer. Nothing is instant and nothing is invented: every good and
## coin is always in exactly one holder (packs, purses, booth stores and booth coins, off-map ledgers).

const PATH := "res://data/couriers.json"
static var _cfg := {}

var w                      # World (or null in purely abstract tests)
var regions := {}          # off-map party id ("<settlement>/<holder>") -> SettlementParty (a fixture ledger in older tests)
var booths: Array = []     # {id, settlement, stall, keeper, store: Inventory, coins, escrow, deposits: {ref: {coins, items}}, x, y}
var routes: Array = []     # {id, from, to, every_days, fee_per_load, load_units, days, next_day}
var links := {}            # "a>b" -> route dict from TradeRoutes (between settlements)
var jobs: Array = []       # deliveries (see book_route / book_special)
var next_id := 1


static func cfg() -> Dictionary:
	if _cfg.is_empty():
		_cfg = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return _cfg


func _init(world = null) -> void:
	w = world


# ------------------------------------------------------------------------------ parties
func _npc(ref: String):
	if w == null or not ref.begins_with("npc:"):
		return null
	return w.npc(int(ref.trim_prefix("npc:")))


## The holder of `ref` as an Inventory-like store (count, has, add, remove, can_add): a pack, or an off-map party (SettlementParty:
## its goods move with `outside_*` flow lines, so the settlement's audit still balances).
func inv_of(ref: String):
	if ref == "player":
		return w.player.inv
	if ref.begins_with("npc:"):
		var n = _npc(ref)
		return n.inv if n != null else null
	if ref.begins_with("region:"):
		var l = regions.get(ref.trim_prefix("region:"))
		return l.stock if l != null else null
	return null


func coins_of(ref: String) -> int:
	if ref == "player":
		return w.player.coins
	if ref.begins_with("npc:"):
		var n = _npc(ref)
		return n.coins if n != null else 0
	if ref.begins_with("region:"):
		var l = regions.get(ref.trim_prefix("region:"))
		return l.purse() if l != null else 0
	return 0


func add_coins(ref: String, k: int) -> void:
	if ref == "player":
		w.player.coins += k
	elif ref.begins_with("npc:"):
		var n = _npc(ref)
		n.coins += k
		if k > 0:
			n.earned += k
		else:
			n.spent -= k
	elif ref.begins_with("region:"):
		var l = regions[ref.trim_prefix("region:")]
		if l is SettlementParty:
			(l as SettlementParty).outside_coins(k)      # (a party never pays past empty: callers check coins_of first)
		else:
			l.coins += k


func alive(ref: String) -> bool:
	if ref == "player":
		return w.player.alive
	if ref.begins_with("npc:"):
		var n = _npc(ref)
		return n != null and n.alive
	return ref.begins_with("region:") and regions.has(ref.trim_prefix("region:"))


func rel_id(ref: String) -> int:
	return Life.PLAYER_ID if ref == "player" else (int(ref.trim_prefix("npc:")) if ref.begins_with("npc:") else -1)


## The settlement a party is in: "region:<settlement>/<holder>" is in <settlement> (a fixture "region:<id>" is its own place).
func place_of(ref: String) -> String:
	return ref.trim_prefix("region:").split("/")[0] if ref.begins_with("region:") else SettlementFacts.VILLAGE


# ------------------------------------------------------------------------------ booths and routes
## Open a booth at `stall_id` (a stall with no tenant) or, with stall_id "", at a stall the keeper builds by the STALL
## rules. "" when done, else why not.
func open_booth(keeper: String, stall_id := "") -> String:
	var n = _npc(keeper)
	if n == null or not n.alive:
		return "There is nobody to keep the booth."
	var why: String = w.construction.can_hire(n)
	if why != "":
		return why
	if booths.any(func(b): return b.keeper == keeper):
		return "%s keeps a booth already." % n.name
	var at := Vector2i.ZERO
	if stall_id != "":
		var s: Dictionary = w.stalls.get(stall_id, {})
		if s.is_empty() or str(s.get("tenant", "")) != "":
			return "That stall is taken."
		at = Vector2i(int(s.x), int(s.y))
	else:
		var site: Vector2i = w.business.stalls.find_site(keeper)
		var err: String = w.business.stalls.build(keeper, site, n.inv)
		if err != "":
			return err
		var mine: Array = w.business.stalls.built(keeper)
		if mine.is_empty():
			return "The stall was not built."
		stall_id = str(mine[mine.size() - 1].id)
		at = site
	booths.append({"id": "b%d" % next_id, "settlement": SettlementFacts.VILLAGE, "stall": stall_id, "keeper": keeper,
		"store": Inventory.new(), "coins": 0, "escrow": 0, "deposits": {}, "x": at.x, "y": at.y})
	next_id += 1
	return ""


## An off-map settlement's booth, kept by the settlement itself (its own party).
func open_region_booth(region) -> void:
	regions[region.id] = region
	booths.append({"id": "b%d" % next_id, "settlement": region.settlement, "stall": "", "keeper": "region:" + region.id,
		"store": Inventory.new(), "coins": 0, "escrow": 0, "deposits": {}, "x": region.pos.x, "y": region.pos.y})
	next_id += 1


func booth(id: String) -> Dictionary:
	for b in booths:
		if b.id == id:
			return b
	return {}


func booth_of(settlement: String) -> Dictionary:
	for b in booths:
		if b.settlement == settlement:
			return b
	return {}


## A regular route between two booths, its journey days from the settlements' link (TradeRoutes) or `days`.
func add_route(from_booth: String, to_booth: String, days := -1.0, first_day := 0) -> Dictionary:
	var c: Dictionary = cfg().routes
	var a := booth(from_booth)
	var b := booth(to_booth)
	var link: Dictionary = links.get("%s>%s" % [a.settlement, b.settlement], {})
	var r := {"id": "r%d" % next_id, "from": from_booth, "to": to_booth, "every_days": int(c.every_days),
		"fee_per_load": int(c.fee_per_load), "load_units": int(c.load_units),
		"days": days if days >= 0.0 else float(link.get("days", 1.0)), "next_day": first_day}
	next_id += 1
	routes.append(r)
	return r


func route(id: String) -> Dictionary:
	for r in routes:
		if r.id == id:
			return r
	return {}


# ------------------------------------------------------------------------------ recipients
## Record a trade between two parties as a commercial contact (the minimal record X18-Q12-POST asks for, kept with the
## acquaintance records in Relations). The live World.trade calls this through Relations.note_trade.
func note_trade(a: String, b: String) -> void:
	if w != null and rel_id(a) != -1 and rel_id(b) != -1:
		w.relations.note_trade(rel_id(a), rel_id(b), w.day())


## The people and businesses `sender` knows, each with where to find it: [{ref, kind: person|business, name, owner,
## settlement, x, y, why}], sorted by name. Unknown parties never appear.
func known_recipients(sender: String) -> Array:
	var out := []
	if w != null:
		var me := rel_id(sender)
		for n: NPC in w.npcs:
			var ref := "npc:%d" % n.id
			if not n.alive or ref == sender or n.role == "bandit":
				continue
			var t: Dictionary = w.relations.peek(me, n.id)
			var traded: bool = w.relations.traded_with(me, n.id)
			if int(t.days_known) >= 1:
				out.append(_entry(ref, "person", "knows them"))
			if traded and is_business(ref):
				out.append(_entry(ref, "business", "has traded there"))
		if sender != "player" and w.player.alive:
			var tp: Dictionary = w.relations.peek(me, Life.PLAYER_ID)
			if int(tp.days_known) >= 1:
				out.append(_entry("player", "person", "knows them"))
	for id in regions:
		var l = regions[id]
		if l.journal.any(func(e): return str(e.with) == sender or str(e.with).ends_with("/" + sender)):
			out.append(_entry("region:" + id, "business", "has traded with them"))
	out.sort_custom(func(a, b): return a.name < b.name or (a.name == b.name and a.kind < b.kind))
	return out


func is_known(sender: String, ref: String, kind := "") -> bool:
	return known_recipients(sender).any(func(e): return e.ref == ref and (kind == "" or e.kind == kind))


## A business: a villager whose trade buys and sells (NPCBrain.BUYS: merchants, smith, carpenter, tanner, cook, sage,
## tavernkeeper) or who keeps a stall; the owner represents it.
func is_business(ref: String) -> bool:
	var n = _npc(ref)
	if n == null:
		return false
	if NPCBrain.BUYS.has(w.brain.buy_role(n)):
		return true
	return not w.business.stalls.built(ref).is_empty()


func _entry(ref: String, kind: String, why: String) -> Dictionary:
	var loc := location(ref, kind)
	var name := ""
	if ref == "player":
		name = w.player.name
	elif ref.begins_with("npc:"):
		var n = _npc(ref)
		name = "%s %s" % [n.name, n.family]
		if kind == "business":
			name = "%s's %s" % [n.name, str(w.brain.buy_role(n)).replace("merchant_", "").replace("_", " ")]
	else:
		name = regions[ref.trim_prefix("region:")].name
	return {"ref": ref, "kind": kind, "name": name, "owner": ref, "settlement": loc.settlement, "x": loc.x, "y": loc.y,
		"where": loc.what, "why": why}


## Where a recipient is found, from world records: a business at its stall or workplace, a person at their home's door,
## the player at their home or where they stand, an off-map party at its booth. {settlement, x, y, what}.
func location(ref: String, kind := "person") -> Dictionary:
	if ref.begins_with("region:"):
		var b := booth_of(place_of(ref))
		return {"settlement": place_of(ref), "x": int(b.get("x", 0)), "y": int(b.get("y", 0)), "what": "the booth of " + place_of(ref)}
	if ref == "player":
		var at: Vector2 = w.player.pos
		return {"settlement": SettlementFacts.VILLAGE, "x": int(at.x), "y": int(at.y), "what": "where you are"}
	var n = _npc(ref)
	if kind == "business":
		for sid in w.stalls:
			if str(w.stalls[sid].get("tenant", "")) == ref or str(w.stalls[sid].get("tenant", "")) == str(n.id):
				return {"settlement": SettlementFacts.VILLAGE, "x": int(w.stalls[sid].x), "y": int(w.stalls[sid].y), "what": "the stall"}
		var built: Array = w.business.stalls.built(ref)
		if not built.is_empty():
			return {"settlement": SettlementFacts.VILLAGE, "x": int(built[0].x), "y": int(built[0].y), "what": "their stall"}
		if w.stations.has(n.workplace):
			var st: Dictionary = w.stations[n.workplace]
			return {"settlement": SettlementFacts.VILLAGE, "x": int(st.use[0]), "y": int(st.use[1]), "what": "the " + str(st.type)}
	if w.buildings.has(str(n.home)):
		var d: Vector2i = w.building_door(n.home)
		return {"settlement": SettlementFacts.VILLAGE, "x": d.x, "y": d.y, "what": "their home"}
	return {"settlement": SettlementFacts.VILLAGE, "x": int(n.pos.x), "y": int(n.pos.y), "what": "where they are"}


## Every place a recipient can be reached, from world records: a business's stall or workplace, a person's home door, an
## off-map party's booth. The courier window offers these, never a typed address.
func locations(ref: String) -> Array:
	var out := []
	if ref.begins_with("region:") or ref == "player":
		return [location(ref)]
	if is_business(ref):
		var b := location(ref, "business")
		if str(b.what) != "their home":
			out.append(b)
	out.append(location(ref, "person"))
	return out


# ------------------------------------------------------------------------------ fees
func capacity(courier: String) -> int:
	if courier.begins_with("region:"):
		return TradeRoutes.capacity(regions[courier.trim_prefix("region:")].transport)
	var n = _npc(courier)
	if n == null:
		return 0
	var carts := 0
	if n.household >= 0:
		carts = w.carts.of(World.hh_ref(n.household)).size()
	return TradeRoutes.capacity({"handcart": carts, "carry": 1})


## Journey days one way between two settlements (a local errand within one settlement takes local_days).
func journey_days(a: String, b: String) -> float:
	if a == b:
		return 0.25
	return float((links.get("%s>%s" % [a, b], {}) as Dictionary).get("days", 1.0))


static func units_of(items: Dictionary) -> int:
	var n := 0
	for k in items:
		n += int(items[k])
	return n


## The fee of a delivery and how it was worked out. Regular route: the flat fee a load. Special: the courier's least
## acceptable fee from the work. {fee, loads, days, legs, parts: {name: coins}}.
func quote(order: Dictionary) -> Dictionary:
	var units := units_of(order.get("items", {}))
	if str(order.get("kind", "special")) == "route":
		var r := route(str(order.route))
		var loads := maxi(1, int(ceil(float(units) / float(r.load_units))))
		return {"fee": loads * int(r.fee_per_load), "loads": loads, "days": float(r.days), "legs": 1,
			"parts": {"flat fee a load x %d" % loads: loads * int(r.fee_per_load)}}
	var c: Dictionary = cfg().special
	var cap := maxi(1, capacity(str(order.courier)))
	var loads := maxi(1, int(ceil(float(units) / float(cap))))
	var days := journey_days(place_of(str(order.sender)), str(order.get("settlement", place_of(str(order.recipient)))))
	var legs := 2                                    # there and back: home, or with payment or proceeds
	var day_wage := float(GameData.b("helper_wage"))
	var parts := {"labour (%.2f days x %d legs x %d loads)" % [days, legs, loads]: int(ceil(day_wage * days * legs * loads - 1e-9))}
	if loads > 1:
		parts["extra loads"] = (loads - 1) * int(c.per_extra_load)
	var stops := int(order.get("stops", 1))
	parts["stops x %d" % stops] = stops * int(c.per_stop)
	if bool(order.get("notarise", false)):
		parts["notarial service"] = int(c.notary_fee)
	var fee := 0
	for k in parts:
		fee += int(parts[k])
	fee = maxi(fee, int(c.minimum))
	return {"fee": fee, "loads": loads, "days": days, "legs": legs, "parts": parts}


# ------------------------------------------------------------------------------ booking
## Why an order cannot be booked, "" if it can: the sender holds the goods, the recipient is known and found, the
## courier can carry it, the fee is affordable.
func refusal(order: Dictionary) -> String:
	var sender := str(order.sender)
	var recipient := str(order.recipient)
	if not alive(sender):
		return "There is nobody to send it."
	if not is_known(sender, recipient):
		return "You do not know them: a courier delivers only to people and businesses you know."
	if not alive(recipient):
		return "They cannot be found."
	var inv = inv_of(sender)
	var items: Dictionary = order.get("items", {})
	if items.is_empty():
		return "There is nothing to send."
	for id in items:
		if int(items[id]) <= 0 or inv == null or not inv.has(id, int(items[id])):
			return "You do not have %d %s." % [int(items[id]), GameData.item_name(str(id))]
	var q := quote(order)
	if str(order.get("kind", "special")) == "route":
		var r := route(str(order.route))
		if r.is_empty():
			return "There is no such route."
		var to: Dictionary = booth(str(r.to))
		if str(order.get("settlement", place_of(recipient))) != str(to.settlement):
			return "That route does not go where they are."
		if units_of(items) > int(r.load_units) * int(cfg().routes.loads_per_departure):
			return "That is more than the route carries in one departure (%d)." % (int(r.load_units) * int(cfg().routes.loads_per_departure))
	else:
		if not alive(str(order.courier)):
			return "That courier cannot be found."
		if units_of(items) > capacity(str(order.courier)) * 1:
			return "That is more than the courier can carry (%d)." % capacity(str(order.courier))
	if coins_of(sender) < int(order.get("fee", q.fee)):
		return "You cannot pay the fee (%d coins)." % int(order.get("fee", q.fee))
	if order.has("collect") and str((order.collect as Dictionary).get("kind", "")) == "":
		return "Say what is to be collected."
	return ""


## The order as a readable delivery instruction (the window shows it before confirmation).
func describe(order: Dictionary) -> String:
	var parts := []
	for id in order.get("items", {}):
		parts.append("%d %s" % [int(order.items[id]), GameData.item_name(str(id))])
	var who := _entry(str(order.recipient), str(order.get("recipient_kind", "person")), "")
	var q := quote(order)
	var s := "Carry %s to %s at %s" % [", ".join(parts), who.name, who.where]
	if str(order.get("kind", "special")) == "route":
		s += ", on the regular route (next departure day %d)" % int(route(str(order.route)).next_day)
	else:
		s += ", as a special delivery by %s" % _entry(str(order.courier), "person", "").name
	var col: Dictionary = order.get("collect", {})
	if not col.is_empty():
		if str(col.kind) == "coins":
			s += "; collect %d coins" % int(col.amount)
		else:
			s += "; collect %d %s" % [int(col.amount), GameData.item_name(str(col.item))]
		s += " and %s" % ("bring them to you" if str(order.get("proceeds", "deliver")) == "deliver" else "deposit them at your booth")
	s += ". Fee: %d coins (%s)." % [int(order.get("fee", q.fee)), "; ".join(q.parts.keys().map(func(k): return "%s: %d" % [k, int(q.parts[k])]))]
	return s


## A regular-route booking: the flat fee is paid at the booth (to its keeper) and the goods handed over into the booth's
## store until the courier leaves. Returns the job, or {error}.
func book_route(order: Dictionary) -> Dictionary:
	order.kind = "route"
	var why := refusal(order)
	if why != "":
		return {"error": why}
	var r := route(str(order.route))
	var b := booth(str(r.from))
	var q := quote(order)
	var inv = inv_of(str(order.sender))
	for id in order.items:
		inv.remove(id, int(order.items[id]))
		(b.store as Inventory).add(id, int(order.items[id]))
	add_coins(str(order.sender), -int(q.fee))
	add_coins(str(b.keeper), int(q.fee))
	var job := _job(order, q, str(b.keeper))
	job.route = r.id
	job.state = "at_booth"
	job.history.append([_day(), "booked at the booth; flat fee %d paid" % int(q.fee)])
	return job


## The negotiation of a special delivery (CON-01-shaped; provisional adapter): the sender offers `offer`, the courier
## accepts at that price if it covers the computed work, else counters with its least acceptable fee.
## {answer: accept|counter|refuse, fee, quote, record}.
func negotiate(order: Dictionary, offer: int) -> Dictionary:
	order.kind = "special"
	var q := quote(order)
	var least := int(q.fee)
	var rec := {"buyer": str(order.sender), "seller": str(order.courier), "service": "special_delivery", "qty": units_of(order.items),
		"price": offer, "terms": {"pay": "held at the booth, released when every obligation is done"}}
	if not alive(str(order.courier)):
		return {"answer": "refuse", "fee": 0, "quote": q, "record": rec, "say": "There is nobody to carry it."}
	if offer >= least:
		return {"answer": "accept", "fee": offer, "quote": q, "record": rec}
	rec.price = least
	return {"answer": "counter", "fee": least, "quote": q, "record": rec, "say": "I'll carry it for %d coins." % least}


## A special delivery, at an agreed fee: the fee is held at the sender's booth until the contract is fulfilled; the
## goods go into the courier's own pack. Returns the job, or {error}.
func book_special(order: Dictionary, fee: int) -> Dictionary:
	order.kind = "special"
	order.fee = fee
	var why := refusal(order)
	if why != "":
		return {"error": why}
	var b := booth_of(place_of(str(order.sender)))
	if b.is_empty():
		return {"error": "There is no courier booth here to hold the fee."}
	var q := quote(order)
	var courier_inv = inv_of(str(order.courier))
	var inv = inv_of(str(order.sender))
	for id in order.items:
		if not courier_inv.can_add(id):
			return {"error": "The courier's pack is full."}
	for id in order.items:
		inv.remove(id, int(order.items[id]))
		courier_inv.add(id, int(order.items[id]))
	add_coins(str(order.sender), -fee)
	b.escrow = int(b.escrow) + fee
	var job := _job(order, q, str(order.courier))
	job.fee = fee
	job.held_at = b.id
	job.state = "in_transit"
	job.depart = _day()
	job.arrive = _day() + float(q.days)
	job.history.append([_day(), "agreed at %d coins; fee held at the booth; the courier takes the goods" % fee])
	return job


func _job(order: Dictionary, q: Dictionary, courier: String) -> Dictionary:
	var j := {"id": "d%d" % next_id, "kind": str(order.kind), "sender": str(order.sender), "recipient": str(order.recipient),
		"recipient_kind": str(order.get("recipient_kind", "person")), "settlement": str(order.get("settlement", place_of(str(order.recipient)))),
		"items": (order.items as Dictionary).duplicate(), "courier": courier, "fee": int(q.fee), "days": float(q.days),
		"collect": (order.get("collect", {}) as Dictionary).duplicate(), "proceeds": str(order.get("proceeds", "deliver")),
		"carried_coins": 0, "carried_items": {}, "returned_items": {}, "state": "", "route": "", "held_at": "", "depart": -1.0,
		"arrive": -1.0, "back": -1.0, "outcome": "", "history": [], "notarise": bool(order.get("notarise", false))}
	next_id += 1
	jobs.append(j)
	return j


func _day() -> float:
	return float(w.minutes) / World.DAY if w != null else 0.0


# ------------------------------------------------------------------------------ the journey
## Advance every delivery to day `day` (fractional days): departures on the route schedule, hand-overs on arrival,
## the return leg, deposits, fulfilment. Each step moves real goods and coins between holders.
func tick(day: float) -> void:
	for r in routes:
		while float(r.next_day) <= day:
			_depart(r, float(r.next_day))
			r.next_day = int(r.next_day) + int(r.every_days)
	for j in jobs:
		match str(j.state):
			"in_transit":
				if day >= float(j.arrive):
					_arrive(j, day)
			"returning":
				if day >= float(j.back):
					_home(j, day)


func _depart(r: Dictionary, day: float) -> void:
	var b := booth(str(r.from))
	for j in jobs:
		if str(j.route) != str(r.id) or str(j.state) != "at_booth":
			continue
		if not alive(str(j.courier)):
			continue                                   # no courier today: the goods wait at the booth
		var cinv = inv_of(str(j.courier))
		for id in j.items:
			(b.store as Inventory).remove(id, int(j.items[id]))
			cinv.add(id, int(j.items[id]))
		j.state = "in_transit"
		j.depart = day
		j.arrive = day + float(r.days)
		j.history.append([day, "left on the route"])


func _arrive(j: Dictionary, day: float) -> void:
	var courier := str(j.courier)
	if not alive(courier):
		interrupt(j, "the courier did not arrive")
		return
	var cinv = inv_of(courier)
	j.back = day + float(j.days)
	if not alive(str(j.recipient)):
		j.returned_items = (j.items as Dictionary).duplicate()
		j.outcome = "recipient unavailable"
		j.state = "returning"
		j.history.append([day, "nobody to receive it: the goods come back"])
		return
	var rinv = inv_of(str(j.recipient))
	var col: Dictionary = j.collect
	# a delivery that asks for payment is refused when the recipient cannot or will not pay
	if not col.is_empty():
		var can_pay: bool = (coins_of(str(j.recipient)) >= int(col.amount)) if str(col.kind) == "coins" else rinv.has(str(col.item), int(col.amount))
		if not can_pay or bool(j.get("refuse", false)):
			j.returned_items = (j.items as Dictionary).duplicate()
			j.outcome = "rejected by the recipient"
			j.state = "returning"
			j.history.append([day, "the recipient would not take it on those terms: the goods come back"])
			return
	for id in j.items:
		if not rinv.can_add(id):
			j.returned_items = (j.items as Dictionary).duplicate()
			j.outcome = "recipient could not take it"
			j.state = "returning"
			return
	for id in j.items:
		cinv.remove(id, int(j.items[id]))
		rinv.add(id, int(j.items[id]))
	if not col.is_empty():
		if str(col.kind) == "coins":
			add_coins(str(j.recipient), -int(col.amount))
			add_coins(courier, int(col.amount))
			j.carried_coins = int(col.amount)
		else:
			rinv.remove(str(col.item), int(col.amount))
			cinv.add(str(col.item), int(col.amount))
			j.carried_items = {str(col.item): int(col.amount)}
	j.outcome = "delivered"
	j.state = "returning"
	j.history.append([day, "handed over%s" % (" and payment collected" if not col.is_empty() else "")])


func _home(j: Dictionary, day: float) -> void:
	var courier := str(j.courier)
	if not alive(courier):
		interrupt(j, "the courier did not come back")
		return
	var cinv = inv_of(courier)
	var sender := str(j.sender)
	var b := booth_of(place_of(sender))
	var deposit: bool = str(j.proceeds) == "deposit" or not alive(sender)
	# goods that came back, and goods collected as payment
	for src in [j.returned_items, j.carried_items]:
		for id in src:
			cinv.remove(id, int(src[id]))
			if deposit:
				_deposit_item(b, sender, id, int(src[id]))
			else:
				inv_of(sender).add(id, int(src[id]))
	if int(j.carried_coins) > 0:
		add_coins(courier, -int(j.carried_coins))
		if deposit:
			b.coins = int(b.coins) + int(j.carried_coins)
			var dep: Dictionary = (b.deposits as Dictionary).get(sender, {"coins": 0, "items": {}})
			dep.coins = int(dep.coins) + int(j.carried_coins)
			b.deposits[sender] = dep
		else:
			add_coins(sender, int(j.carried_coins))
	if str(j.kind) == "special":
		var hb := booth(str(j.held_at))
		hb.escrow = int(hb.escrow) - int(j.fee)
		add_coins(courier, int(j.fee))                # the work is done: the courier is paid
	j.state = "fulfilled" if str(j.outcome) == "delivered" else "returned"
	j.history.append([day, "back: %s" % ("every obligation done" if j.state == "fulfilled" else "goods returned to the sender")])


func _deposit_item(b: Dictionary, sender: String, id: String, n: int) -> void:
	(b.store as Inventory).add(id, n)
	var dep: Dictionary = (b.deposits as Dictionary).get(sender, {"coins": 0, "items": {}})
	dep.items[id] = int(dep.items.get(id, 0)) + n
	b.deposits[sender] = dep


## The sender takes out what was deposited for them at a booth (at the booth itself).
func withdraw(booth_id: String, who: String) -> Dictionary:
	var b := booth(booth_id)
	var dep: Dictionary = (b.deposits as Dictionary).get(who, {})
	if dep.is_empty():
		return {}
	for id in dep.items:
		(b.store as Inventory).remove(id, int(dep.items[id]))
		inv_of(who).add(id, int(dep.items[id]))
	b.coins = int(b.coins) - int(dep.coins)
	add_coins(who, int(dep.coins))
	(b.deposits as Dictionary).erase(who)
	return dep


## The journey stops: the courier died or was waylaid. What it carried stays in its pack (its estate's, if it died);
## a special fee held at the booth goes back to the payer; the contract is not fulfilled.
func interrupt(j: Dictionary, why: String) -> void:
	if str(j.state) in ["fulfilled", "returned", "interrupted"]:
		return
	if str(j.kind) == "special" and str(j.held_at) != "":
		var hb := booth(str(j.held_at))
		hb.escrow = int(hb.escrow) - int(j.fee)
		add_coins(str(j.sender), int(j.fee))
	j.state = "interrupted"
	j.outcome = why
	j.history.append([_day(), "interrupted: " + why])


## Coins the courier service holds (booth coins and fees held), for conservation checks.
func held_coins() -> int:
	var n := 0
	for b in booths:
		n += int(b.coins) + int(b.escrow)
	return n


func held_goods() -> Dictionary:
	var out := {}
	for b in booths:
		for id in (b.store as Inventory).items:
			out[id] = int(out.get(id, 0)) + int(b.store.items[id])
	return out
