class_name SettlementTrips
extends RefCounted
## B25R1-019 and B25R1-018 section 9 (owner 2026-11-03: "trade between places is carried by real walkers on the route network,
## never by an abstract transfer"; "No teleporting between settlements merely because they have economic relationships"): every
## errand of a settlement's people to another place is ONE trip record on their settlement (OffMapSettlement.trips, saved):
##
##   {tx, who: the walker's person id (ID-01), hid: the walker's household, owner: the holder whose errand it is (hh:<n>, trader,
##    a business type, treasury), from, to, purpose: {kind: market | wholesale | food | dues, ...}, leg: out | back,
##    depart: the game minute the current leg's walk began, pace, pack: {item: n}, coins, sent: day}
##
## The route is Overworld.site_route(from, to) (a pure function of the seed, never saved); the position at minute m is the route
## indexed by road_tiles(depart, m, pace): the shared walking rule (Presence.road_tiles; 1.3 tiles a game minute, resting 20:00-06:00),
## the same for every traveller on the road. The pack's coins and goods are the owner's all the way and are counted in the
## settlement's books (OffMapSettlement.coins / goods); the walker deals at the destination through SettlementParty.deal (party
## "trip:<tx>"), so a sale or purchase there is a matched regional line on both settlements (Regions.audit). On the way home they
## unpack into the owner's books. Nothing is created: a walker who finds nothing to buy brings the coins home; one whose household
## is gone hands the pack to the treasury; one who dies on the road leaves the pack to their household (WDR-022: the errand failed).
##
## Calculated and live are the same record: while the walker is a live NPC (SettlementPeople) the trip waits (its pack is with the
## NPC); when the NPC is folded back, `depart` is rewritten so that road_tiles(depart, now) is the distance reached.

const PACE := Presence.PACE      # the road's one pace and walking hours are Presence's (EA-01: road_tiles, arrival, along live there)
const REST_FROM := Presence.REST_FROM             # Journeys.REST_FROM, Presence.REST_FROM
const REST_TO := Presence.REST_TO
const DAY := 1440.0


static func cfg() -> Dictionary:
	return OffMapSettlement.data().get("trips", {})


static func hcfg() -> Dictionary:
	return OffMapSettlement.data().get("hamlets", {})


# ------------------------------------------------------------------ the shared walking rule ----------------
## The departure minute that puts a walker `tiles` along at minute `now` (a fold rewrites `depart` with it): the latest d with
## road_tiles(d, now) == tiles.
static func depart_for(now: float, tiles: float, pace := PACE) -> float:
	var need := tiles / maxf(0.0001, pace)
	if need <= 0.0:
		return now
	var from := float(REST_TO) * 60.0
	var to := float(REST_FROM) * 60.0
	var t := now
	var base := floorf(t / DAY) * DAY
	var tod := t - base
	if tod > to:
		t = base + to
	elif tod < from:
		t = base - DAY + to
	while true:
		base = floorf(t / DAY) * DAY
		var avail := t - (base + from)
		if need <= avail:
			return t - need
		need -= avail
		t = base - DAY + to
	return t


static func length(path: PackedVector2Array) -> float:
	var n := 0.0
	for i in range(1, path.size()):
		n += path[i - 1].distance_to(path[i])
	return n


## The distance along `path` of the cell nearest `p` (a fold: how far the live walker got).
static func reached(path: PackedVector2Array, p: Vector2) -> float:
	var best := INF
	var at := 0.0
	var run := 0.0
	for i in path.size():
		if i > 0:
			run += path[i - 1].distance_to(path[i])
		var d := (path[i] + Vector2(0.5, 0.5)).distance_squared_to(p)
		if d < best:
			best = d
			at = run
	return at


# ------------------------------------------------------------------ a trip ----------------
static func find(s: OffMapSettlement, tx: String) -> Dictionary:
	for t in s.trips:
		if str(t.tx) == tx:
			return t
	return {}


static func of_person(s: OffMapSettlement, pid: int) -> Dictionary:
	for t in s.trips:
		if int(t.who) == pid:
			return t
	return {}


static func from_dict(d: Dictionary) -> Dictionary:
	var t: Dictionary = d.duplicate(true)
	for k in ["who", "hid", "coins", "sent"]:
		t[k] = int(t.get(k, 0))
	t.depart = float(t.depart)
	t.pace = float(t.get("pace", PACE))
	t.pack = OffMapSettlement._ints(t.get("pack", {}))
	var pu: Dictionary = t.get("purpose", {})
	if pu.has("buy"):
		pu.buy = OffMapSettlement._ints(pu.buy)
	for k in ["pay"]:                                    # B25-ECON-P6: {business type: coins}
		if pu.has(k):
			pu[k] = OffMapSettlement._ints(pu[k])
	for k in ["give", "got"]:                            # B25-ECON-P6: {item: {business type: n}}
		if pu.has(k):
			var c := {}
			for item in pu[k]:
				c[str(item)] = OffMapSettlement._ints(pu[k][item])
			pu[k] = c
	if pu.has("lines"):
		pu.lines = (pu.lines as Array).map(func(l): return {"holder": str(l.holder), "item": str(l.item), "n": int(l.n), "unit": int(l.unit)})
	t.purpose = pu
	return t


## The leg's road: out from -> to, back to -> from.
static func leg_path(r: Regions, t: Dictionary) -> PackedVector2Array:
	return r.trip_route(str(t.from), str(t.to)) if str(t.leg) == "out" else r.trip_route(str(t.to), str(t.from))


## Where the walker is at minute `m` (overworld cells; the village's frame when the settlements have no world).
static func pos(r: Regions, t: Dictionary, m: float) -> Vector2:
	var path := leg_path(r, t)
	return Presence.along(path, minf(Presence.road_tiles(float(t.depart), m, float(t.pace)), length(path)))[0]


static func arrives(r: Regions, t: Dictionary) -> float:
	return Presence.arrival(float(t.depart), length(leg_path(r, t)), float(t.pace))


## An adult member of one of `hids` (in that order, eldest first) who is home and not live: [hid, member index], or [] nobody.
static func walker(s: OffMapSettlement, hids: Array) -> Array:
	var busy := {}
	for t in s.trips:
		busy[int(t.who)] = true
	for hid in hids:
		if int(hid) < 0 or int(hid) >= s.hh.size():
			continue
		var h: Dictionary = s.hh[int(hid)]
		if not bool(h.alive) or not h.has("mem"):
			continue
		var order := range(h.mem.size())
		order.sort_custom(func(a, b): return int(h.mem[a][0]) < int(h.mem[b][0]) or (int(h.mem[a][0]) == int(h.mem[b][0]) and a < b))
		for j in order:
			var m: Array = h.mem[j]
			var id := OffMapSettlement.member_id(m)
			if s._age(m) >= s._lim and s._age(m) < 70.0 and not busy.has(id) and not s.live.has(id):
				return [int(hid), j]
	return []


## The households whose members may go on the owner's errand: the household itself, a business's workers, the treasury's
## officials (a hamlet's: its elder, the household of its eldest member).
static func owner_hids(s: OffMapSettlement, owner: String) -> Array:
	if owner.begins_with("hh:"):
		return [int(owner.trim_prefix("hh:"))]
	if owner == "treasury":
		if not s.gov.officials.is_empty():
			return (s.gov.officials as Array).duplicate()
		return [elder(s)] if elder(s) >= 0 else []
	var b: Dictionary = s.biz.get("merchant" if owner == "trader" else owner, {})
	return (b.get("workers", []) as Array).duplicate() if not b.is_empty() else []


## A hamlet's elder: the living household with the eldest member (ties by id).
static func elder(s: OffMapSettlement) -> int:
	var best := -1
	var born := 1 << 40
	for h in s.hh:
		if not bool(h.alive) or not h.has("mem"):
			continue
		for m in h.mem:
			if int(m[0]) < born:
				born = int(m[0])
				best = int(h.id)
	return best


## Send a walker on `owner`'s errand to `to`, with `coins` and `pack` from the owner's books (the same settlement: no flow line).
## {} when nobody can go, the owner cannot spare it, or there is no road (nothing moves).
static func start(r: Regions, s: OffMapSettlement, owner: String, to: String, purpose: Dictionary, coins: int, pack: Dictionary, now: float) -> Dictionary:
	if not r.by_id.has(to) or to == s.id or r.trip_route(s.id, to).size() < 2:
		return {}
	var op := SettlementParty.make(r, s, owner)
	if not op.alive() or op.purse() < coins or coins < 0:
		return {}
	for k in pack:
		if op.held(str(k)) < int(pack[k]) or int(pack[k]) < 0:
			return {}
	var wk := walker(s, owner_hids(s, owner))
	if wk.is_empty():
		return {}
	var rec: Dictionary = op.record()
	rec[op._purse_key()] = int(rec[op._purse_key()]) - coins
	for k in pack:
		OffMapSettlement._take(op._goods(), str(k), int(pack[k]))
	s.trip_seq += 1
	var t := {"tx": "%s:%d" % [s.id, s.trip_seq], "who": OffMapSettlement.member_id(s.hh[wk[0]].mem[wk[1]]), "hid": int(wk[0]),
		"owner": owner, "from": s.id, "to": to, "purpose": purpose.duplicate(true), "leg": "out", "depart": now,
		"pace": float(cfg().get("pace", PACE)), "pack": OffMapSettlement._ints(pack), "coins": coins, "sent": s.day}
	s.trips.append(t)
	r.trip_event("journey_begin", s, t, {"action": str(purpose.get("kind", "")), "detail": "coins=%d; pack=%s" % [coins, str(t.pack)]})
	return t


## Bring every calculated trip up to minute `now`: arrivals deal and turn home, homecomings unpack. A live walker's trip waits.
static func advance(r: Regions, now: float) -> void:
	for s: OffMapSettlement in r.list:
		for t in s.trips.duplicate():
			if not s.live.has(int(t.who)):
				progress(r, s, t, now)


static func progress(r: Regions, s: OffMapSettlement, t: Dictionary, now: float) -> void:
	for _guard in 3:
		if _member(s, int(t.who)).is_empty():
			finish(r, s, t, "walker_gone")
			return
		var arr := arrives(r, t)
		if now < arr:
			return
		if str(t.leg) == "out":
			errand(r, s, t, arr)
			t.leg = "back"
			t.depart = arr + float(cfg().get("errand_minutes", 60))
		else:
			finish(r, s, t, "home")
			return


## [household, member index] of person `pid` in `s`, or [].
static func _member(s: OffMapSettlement, pid: int) -> Array:
	for h in s.hh:
		if not bool(h.alive) or not h.has("mem"):
			continue
		for j in h.mem.size():
			if OffMapSettlement.member_id(h.mem[j]) == pid:
				return [int(h.id), j]
	return []


## Home (or the errand ends where it is): the pack into the owner's books, the owner gone: the treasury's.
static func finish(r: Regions, s: OffMapSettlement, t: Dictionary, how: String) -> void:
	var op := SettlementParty.make(r, s, str(t.owner))
	if not op.alive():
		op = SettlementParty.make(r, s, "treasury")
	var rec: Dictionary = op.record()
	if str(t.purpose.get("kind", "")) == "consign":
		_consign_home(s, t, op)                         # B25-ECON-P6: the goods and pay stay owed to the other place's sources
	rec[op._purse_key()] = int(rec[op._purse_key()]) + int(t.coins)
	for k in t.pack:
		OffMapSettlement._add(op._goods(), str(k), int(t.pack[k]))
	if str(t.purpose.get("kind", "")) == "food":         # X20-SETTLE-FOOD as before: food brought home is the trader's import
		var n := 0
		for k in t.pack:
			if OffMapSettlement.rules().foods.has(str(k)):
				n += int(t.pack[k])
				if op.kind == "trader":
					var m: Dictionary = op.record()
					if not m.has("imported"):
						m["imported"] = {}
					OffMapSettlement._add(m.imported, str(k), mini(int(t.pack[k]), int(m.stock.get(str(k), 0))))
		s.flows.food_delivered += n
		if n > 0:
			s.note("Our walker brought home %d food bought in %s." % [n, OffMapSettlement.place_name(str(t.to))])
		if s.trade_hook.is_valid():
			s.trade_hook.call("delivered", {"settlement": s.id, "entry": {"item": "food", "n": n, "tx": str(t.tx), "from": str(t.to)},
				"state": "delivered" if n > 0 else "failed", "households": s.households()})
	t.coins = 0
	t.pack = {}
	s.trips.erase(t)
	r.trip_event("journey_end", s, t, {"action": how, "detail": "owner=%s" % str(t.owner)})


# ------------------------------------------------------------------ at the destination ----------------
## The errand at the destination, at minute `m`: what the purpose says, each exchange through SettlementParty.deal on both sides.
static func errand(r: Regions, s: OffMapSettlement, t: Dictionary, m: float) -> void:
	var dest: OffMapSettlement = r.by_id.get(str(t.to))
	if dest == null:
		return
	var me := SettlementParty.make(r, s, "trip:" + str(t.tx))
	var p: Dictionary = t.purpose
	var lines := []
	match str(p.get("kind", "")):
		"wholesale":
			var tr := SettlementParty.make(r, dest, "trader")
			var keep: Dictionary = OffMapSettlement.rules().carry_keep
			var ids: Array = (p.get("buy", {}) as Dictionary).keys()
			ids.sort()
			for item in ids:
				var unit := GameData.value(str(item))
				var spare := tr.held(str(item)) - int(keep.get(item, 0))
				var n := mini(mini(int(p.buy[item]), spare), int(t.coins) / maxi(1, unit))
				if n > 0 and exchange(me, tr, str(item), n, n * unit, dest.day):
					lines.append([str(item), n, n * unit])
		"food":
			var short := float(dest.wants().get("_food_pts", 0.0)) > 0.0
			for l in p.get("lines", []):
				if short:
					break                                      # the place is itself short now: it sells none (REG-BUY-P1)
				var sp := SettlementParty.make(r, dest, str(l.holder))
				if str(l.holder) != "trader":
					sp.release = dest.food_release([str(l.item)]).get(str(l.holder), {})
				var unit := sp.ask_price(str(l.item))
				if unit > int(l.unit):
					continue                                   # dearer than when they set out: they do not pay it
				var n := mini(mini(int(l.n), sp.sale_cap(str(l.item))), int(t.coins) / maxi(1, unit))
				if n > 0 and exchange(me, sp, str(l.item), n, n * unit, dest.day):
					lines.append([str(l.item), n, n * unit])
					s.flows.food_bought += n
					dest.flows.food_sold += n
		"market":
			lines = market(r, dest, me, p, t)
		"consign":
			lines = consign_errand(r, s, dest, me, t)
		"dues":
			var lord := SettlementParty.make(r, dest, "treasury")
			var c := int(t.coins)
			if c > 0 and me.deal("carriage_paid", lord, "", 0, c, dest.day) and lord.deal("carriage_earned", me, "", 0, c, dest.day):
				_journal(r, 2)
				lines.append(["coins", 0, c])
				s.note("Our elder carried %d coins of tolls and tax to %s." % [c, dest.name])
	r.trip_event("journey_purchase" if not lines.is_empty() else "journey_errand_failed", s, t,
		{"action": str(p.get("kind", "")), "place": dest.id, "detail": str(lines) if not lines.is_empty() else "nothing to be had"})


## Buyer `b` (paying) and seller `sl` exchange `n` of `item` for `total` coins: both sides or neither.
static func exchange(b: SettlementParty, sl: SettlementParty, item: String, n: int, total: int, day: int) -> bool:
	if n <= 0 or not b.can_deal("buy", item, n, total) or not sl.can_deal("sell", item, n, total):
		return false
	b.deal("buy", sl, item, n, total, day)
	sl.deal("sell", b, item, n, total, day)
	_journal(b.regions, 2)
	return true


## The walkers' exchanges are both sides at once (exchange, the dues), so they are kept apart from the regional market's journal (whose
## two-party ledgers RegionalMarket.matched checks): the last `n` lines move to Regions.trip_journal.
static func _journal(r: Regions, n: int) -> void:
	for i in n:
		r.trip_journal.append(r.journal[r.journal.size() - n + i])
	r.journal.resize(r.journal.size() - n)
	if r.trip_journal.size() > 4000:
		r.trip_journal = r.trip_journal.slice(r.trip_journal.size() - 2000)


## A market errand: sell what was carried to sell to whoever there wants it (the trader, then the businesses that use it), then buy
## what was wanted from whoever there sells it (the trader, then the businesses), at the place's own prices, within the pack's coins.
static func market(r: Regions, dest: OffMapSettlement, me: SettlementParty, p: Dictionary, t: Dictionary) -> Array:
	var lines := []
	var parties := []
	if not dest.trader().is_empty():
		parties.append(SettlementParty.make(r, dest, "trader"))
	var types: Array = dest.biz.keys()
	types.sort()
	for bt in types:
		if bt != "merchant":
			parties.append(SettlementParty.make(r, dest, str(bt)))
	var sell: Array = (t.pack as Dictionary).keys()
	sell.sort()
	var dw := dest.wants()
	for item in sell:
		var price := dest.price(str(item))
		for bp: SettlementParty in parties:
			var have := me.held(str(item))
			if have <= 0:
				break
			var want := 0
			if bp.kind == "trader":
				want = int(dw.get(item, 0))
			elif bp.need_items().has(item):
				want = ceili(bp.need_rate(str(item)) * SettlementFolk.WANT_DAYS) - bp.held(str(item))
			var n := mini(mini(have, want), bp.spend_limit() / maxi(1, price))
			if n > 0 and exchange(bp, me, str(item), n, n * price, dest.day):
				lines.append(["sold", str(item), n, n * price])
	var buy: Array = (p.get("buy", {}) as Dictionary).keys()
	buy.sort()
	for item in buy:
		var left := int(p.buy[item])
		var price := dest.price(str(item))
		for sp: SettlementParty in parties:
			if left <= 0:
				break
			var n := mini(mini(left, sp.sale_cap(str(item))), int(t.coins) / maxi(1, price))
			if n > 0 and exchange(me, sp, str(item), n, n * price, dest.day):
				lines.append(["bought", str(item), n, n * price])
				left -= n
	return lines


# ------------------------------------------------------------------ another place's ore on consignment (B25-ECON-P6) ----------------
## B25-ECON-P6 (owner 2026-11-05, question 27, "Other traders consign": any neighbour trader may carry ANOTHER settlement's real ore on
## consignment through the existing wholesale trips, paying that source when the village buys; no change to who keeps trading).
## One walker's errand (purpose {kind: consign, pay: {type: coins}, give: {item: {type: n}}, got: {item: {type: n}}}), sent by
## Regions.consign_round on the traders' wholesale day:
##   pay      the coins the trader set aside when the village bought the source's goods (OffMapSettlement._consign_sold) are handed to
##            each source business at its place (a source closed meanwhile: its place's treasury);
##   give     the source's goods held past rules.consign_hold_days unsold go back to it (closed: to the treasury's granary);
##   collect  a trader's walker (never a treasury's) takes along, unpaid, the goods of rules.consign the place's businesses hold above
##            their keep, then its treasury granary's spare (B25-ECON-P7, OffMapSettlement.granary_spare, owed to "<place>/treasury"), up to the trader's carry room, only from a place with no trader of its own (its own trader carries them,
##            B25-ECON-P4); they stay the source's (`got`, then the trader's `consign` under "<place>/<type>") until the village buys
##            them or they go back.
## Every hand-over is a matched regional line on both places (SettlementParty.deal; goods for no coins, coins for no goods); nothing is
## created. Returns the errand's lines.
static func consign_errand(r: Regions, s: OffMapSettlement, dest: OffMapSettlement, me: SettlementParty, t: Dictionary) -> Array:
	var lines := []
	var p: Dictionary = t.purpose
	var pay: Dictionary = p.get("pay", {})
	var types: Array = pay.keys()
	types.sort()
	for bt in types:
		var c := mini(int(pay[bt]), int(t.coins))
		var src := _consign_source(r, dest, str(bt))
		if c > 0 and me.deal("carriage_paid", src, "", 0, c, dest.day) and src.deal("carriage_earned", me, "", 0, c, dest.day):
			_journal(r, 2)
			lines.append(["paid", src.holder, c])
	var give: Dictionary = p.get("give", {})
	var items: Array = give.keys()
	items.sort()
	for item in items:
		var bts: Array = (give[item] as Dictionary).keys()
		bts.sort()
		for bt in bts:
			var src := _consign_source(r, dest, str(bt))
			var n := mini(int(give[item][bt]), me.held(str(item)))
			if n > 0 and exchange(src, me, str(item), n, 0, dest.day):
				lines.append(["returned", str(item), n, src.holder])
	p["got"] = {}
	var m := s.trader()
	if str(t.owner) != "trader" or m.is_empty() or not dest.trader().is_empty():
		return lines
	var rl := OffMapSettlement.rules()
	var bts: Array = dest.biz.keys()
	bts.sort()
	for item in rl.get("consign", []):
		var room := int(rl.carry.get(item, 0)) - int(m.stock.get(item, 0)) - me.held(str(item))
		for bt in bts:
			if room <= 0:
				break
			if bt == "merchant":
				continue
			var b: Dictionary = dest.biz[bt]
			var n := mini(room, int(b.stock.get(item, 0)) - int(dest._keep(b).get(item, 0)))
			if n > 0 and exchange(me, SettlementParty.make(r, dest, str(bt)), str(item), n, 0, dest.day):
				if not (p.got as Dictionary).has(item):
					p.got[item] = {}
				OffMapSettlement._add(p.got[item], str(bt), n)
				lines.append(["consigned", str(item), n, str(bt)])
				room -= n
		# B25-ECON-P7: then the ore a closed quarry, mine or trader left in the treasury's granary, above what it must keep
		var g := mini(room, dest.granary_spare(str(item)))
		if g > 0 and exchange(me, SettlementParty.make(r, dest, "treasury"), str(item), g, 0, dest.day):
			if not (p.got as Dictionary).has(item):
				p.got[item] = {}
			OffMapSettlement._add(p.got[item], "treasury", g)
			OffMapSettlement._add(dest.granary_ore.out, str(item), g)
			lines.append(["consigned", str(item), g, "treasury"])
	return lines


## The party a consignment's source business stands for at `dest`: the business, or, closed, the place's treasury.
static func _consign_source(r: Regions, dest: OffMapSettlement, bt: String) -> SettlementParty:
	return SettlementParty.make(r, dest, bt if dest.biz.has(bt) else "treasury")


## A consign walker home (or the errand ended on the road): the goods and coins stay owed to the other place's sources. Before the
## errand (leg out) what was to be paid is set aside again and what was to go back is consigned again; after it, what was collected
## (`got`) is consigned. The pack's goods then go into the owner's books as any walker's (finish), the coins set aside are not.
static func _consign_home(s: OffMapSettlement, t: Dictionary, op: SettlementParty) -> void:
	var rec: Dictionary = op.record()
	var p: Dictionary = t.purpose
	var src := str(t.to)
	var marks: Dictionary = p.get("give", {}) if str(t.leg) == "out" else p.get("got", {})
	if str(t.leg) == "out":
		var pay: Dictionary = p.get("pay", {})
		var bts: Array = pay.keys()
		bts.sort()
		for bt in bts:
			var c := mini(int(pay[bt]), int(t.coins))
			if c > 0:
				if not rec.has("consign_due"):
					rec["consign_due"] = {}
				OffMapSettlement._add(rec.consign_due, src + "/" + str(bt), c)
				t.coins = int(t.coins) - c
	var left := (t.pack as Dictionary).duplicate()
	var items: Array = marks.keys()
	items.sort()
	var any := false
	for item in items:
		var bts: Array = (marks[item] as Dictionary).keys()
		bts.sort()
		for bt in bts:
			var n := mini(int(marks[item][bt]), int(left.get(item, 0)))
			if n <= 0:
				continue
			OffMapSettlement._add(left, str(item), -n)
			if not rec.has("consign"):
				rec["consign"] = {}
			if not (rec.consign as Dictionary).has(item):
				rec.consign[item] = {}
			OffMapSettlement._add(rec.consign[item], src + "/" + str(bt), n)
			any = true
	if any:
		if not rec.has("consign_since"):
			rec["consign_since"] = {}
		if not (rec.consign_since as Dictionary).has(src):
			rec.consign_since[src] = s.day


# ------------------------------------------------------------------ the hamlets' errands ----------------
## A hamlet's day (after its step): its households and businesses go to market every market_every_days (staggered by id) when they
## have something to buy there or to sell, and its elder carries the lord's box to the lord every dues_every_days.
static func plan_hamlet(r: Regions, s: OffMapSettlement, now: float) -> void:
	if not s.hamlet or s.market == "" or not r.by_id.has(s.market):
		return
	var hc := hcfg()
	var every := maxi(1, int(hc.get("market_every_days", 6)))
	var rl := OffMapSettlement.rules()
	var dest: OffMapSettlement = r.by_id[s.market]
	for h in s.hh:
		if bool(h.alive) and (s.day + int(h.id)) % every == 0:
			_household_market(r, s, dest, h, now, rl, hc)
	var types: Array = s.biz.keys()
	types.sort()
	for k in types.size():
		if (s.day + k + 3) % every == 0:
			_business_market(r, s, dest, str(types[k]), now)
	var de := maxi(1, int(hc.get("dues_every_days", 7)))
	if s.lord != "" and r.by_id.has(s.lord) and s.day % de == de - 1:
		var c := int(s.gov.coins) - int(hc.get("dues_keep", 15))
		if c > 0:
			start(r, s, "treasury", s.lord, {"kind": "dues"}, c, {}, now)


static func _household_market(r: Regions, s: OffMapSettlement, dest: OffMapSettlement, h: Dictionary, now: float, rl: Dictionary, hc: Dictionary) -> void:
	var members := int(h.adults) + int(h.children)
	var keep := int(rl.keep_cash_base) + int(rl.keep_cash_per_member) * members
	var budget := int(h.coins) - keep
	if budget <= 0:
		return
	var buy := {}
	var est := 0
	var need := s._need_pts(h) * float(hc.get("market_food_days", 6))
	var have := s._pantry_pts(h)
	var local := 0.0                                         # food the hamlet's own businesses can spare
	for bt in s.biz:
		for item in s.food_items():
			local += float(s._food_spare(s.biz[bt], item, s._keep(s.biz[bt]))) * OffMapSettlement._pts(item)
	if have < need and local < need - have:
		var n := ceili((need - have) / OffMapSettlement._pts("wheat"))
		buy["wheat"] = n
		est += n * dest.price("wheat")
	var wishes := 0
	for item in rl.wish:
		if wishes >= int(hc.get("market_wish", 2)) or not rl.basket.has(item) or int(h.pantry.get(item, 0)) > 0:
			continue
		var local_has := false
		for bt in s.biz:
			if int(s.biz[bt].stock.get(item, 0)) > int(s._keep(s.biz[bt]).get(item, 0)):
				local_has = true
		if not local_has and est + dest.price(str(item)) <= budget:
			buy[str(item)] = 1
			est += dest.price(str(item))
			wishes += 1
	if buy.is_empty():
		return
	start(r, s, "hh:%d" % int(h.id), dest.id, {"kind": "market", "buy": buy}, mini(budget, est + est / 4), {}, now)


static func _business_market(r: Regions, s: OffMapSettlement, dest: OffMapSettlement, bt: String, now: float) -> void:
	var b: Dictionary = s.biz[bt]
	var keep := s._keep(b)
	var pack := {}
	var load := 0
	var cap := 40
	var dw := dest.wants()
	var ids: Array = (b.stock as Dictionary).keys()
	ids.sort()
	for item in ids:
		var spare := int(b.stock[item]) - int(keep.get(item, 0))
		if spare <= 0 or load >= cap:
			continue
		var wanted := int(dw.get(item, 0)) > 0
		for ot in dest.biz:
			if not wanted and ot != "merchant" and SettlementParty.make(r, dest, str(ot)).need_items().has(item):
				wanted = true
		if wanted:
			var n := mini(spare, cap - load)
			pack[str(item)] = n
			load += n
	var buy := {}
	var est := 0
	var short := s._inputs_short(b)
	var sids: Array = short.keys()
	sids.sort()
	for item in sids:
		if int(short[item]) > 0:
			buy[str(item)] = int(short[item])
			est += int(short[item]) * dest.price(str(item))
	var coins := mini(est, maxi(0, int(b.till) - int(b.reserve)))
	if coins <= 0:
		buy = {}
	if pack.is_empty() and buy.is_empty():
		return
	start(r, s, bt, dest.id, {"kind": "market", "buy": buy}, coins if not buy.is_empty() else 0, pack, now)
