class_name SettlementPeople
extends RefCounted
## B25R1-019 (owner decisions B25R1-Q6, Q7; docs/design/REGION_RECONSTRUCTION_B25R1.md (e), (i)): the settlements' and hamlets'
## residents as ONE record per person. Out of view a resident is a member of their settlement's household (OffMapSettlement.hh, the
## person id at mem[i][5], ID-01), calculated by the settlement's day; in view (Presence's live range plus its margin) the same person
## is a live NPC in World.npcs with the same id. Never a copy, never a respawn: materialise makes the NPC from the record and marks the
## record live; fold writes the changes back and removes the NPC in the same call.
##
## The presence provider protocol (Presence.register; wip/b25r1-presence):
##   presence_candidates() -> [{id, pos}]   every living member: on a trip at SettlementTrips.pos(now) (the shared walking rule),
##                                           else at their station by the hour: work (7-18, their trade's building door), else home
##                                           (their household's house on the site; the gate when it has none)
##   materialise(id) -> NPC                  the person with their name, age, sex, trade and household, their trip's pack and coins and
##                                           the rest of their route; World.npcs and by_id hold them, the member is marked live
##   fold(npc)                               the pack and position back into the trip (depart rewritten so road_tiles(depart, now) is the
##                                           distance reached), anything they carry home into their household, a death into the
##                                           household's record; out of World.npcs in the same call
## While live, the settlement's step skips the member's own acts (their trip waits: SettlementTrips.advance; an old-age death waits)
## but the household's books stay where they are: one purse, one pantry, one till.
##
## Two ledgers, one set of coins: a pack handed to a live NPC leaves the settlement's books as an outside line and enters the
## village's as coin_sources / imported_ (the courier edge's booking, SettlementFolk._village_side), and comes back the same way on
## fold, so Regions.audit and the village's ledgers both balance across any number of round trips.

const WORK_FROM := 7
const WORK_TO := 18

var w                                    # World (untyped: World preloads the settlement classes)
var r: Regions
var live := {}                           # person id -> {npc, sid}; not saved (World.to_dict folds everyone first: fold_all)
var _stations := []                      # [{id, pos}] of members at their stations, for the bucket below
var _bucket := -1


static func attach(world, regions: Regions) -> SettlementPeople:
	var p := SettlementPeople.new()
	p.w = world
	p.r = regions
	var pr = world.get("presence")
	if pr != null:
		pr.register(p)
	return p


# ------------------------------------------------------------------ finding a person ----------------
## {s, h, j, m} of person `pid`, or {}.
func find(pid: int) -> Dictionary:
	for s: OffMapSettlement in r.list:
		for h in s.hh:
			if not bool(h.alive) or not h.has("mem"):
				continue
			for j in h.mem.size():
				if OffMapSettlement.member_id(h.mem[j]) == pid:
					return {"s": s, "h": h, "j": j, "m": h.mem[j]}
	return {}


func _site(sid: String) -> Dictionary:
	if w == null or w.map == null or w.map.overworld == null:
		return {}
	return w.map.overworld.site(sid)


## Where a member who is not travelling stands at game hour `hr`: their trade's building in working hours (an adult of a household
## with a trade that has one), else their household's house; the site's gate when neither stands.
func station(s: OffMapSettlement, h: Dictionary, adult: bool, hr: int) -> Vector2:
	var st := _site(s.id)
	if st.is_empty():
		return Vector2.INF
	var at := Vector2i(st.gate)
	var work := Vector2i(-1048576, 0)
	for sl in st.slots:
		if str(sl.get("kind", "")) == "home" and int(sl.get("hh", -1)) == int(h.id):
			at = Vector2i(sl.spot)
		elif str(sl.get("kind", "")) == "work" and str(sl.trade) == str(h.trade):
			work = Vector2i(sl.spot)
	if adult and hr >= WORK_FROM and hr < WORK_TO and work.x > -524288:
		at = work
	return Vector2(at) + Vector2(0.5, 0.5)


# ------------------------------------------------------------------ the provider protocol ----------------
func presence_candidates() -> Array:
	if w == null or w.map == null or w.map.overworld == null:
		return []
	var bucket := int(float(w.minutes) / 10.0)
	if bucket != _bucket:
		_bucket = bucket
		_stations = []
		var hr := int(w.hour())
		for s: OffMapSettlement in r.list:
			var busy := {}
			for t in s.trips:
				busy[int(t.who)] = true
			for h in s.hh:
				if not bool(h.alive) or not h.has("mem"):
					continue
				for m in h.mem:
					var id := OffMapSettlement.member_id(m)
					if id > 0 and not busy.has(id):
						var p := station(s, h, s._age(m) >= s._lim, hr)
						if p != Vector2.INF:
							_stations.append({"id": id, "pos": p})
	var out := _stations.duplicate()
	for e in r.all_trips():
		out.append({"id": int(e[1].who), "pos": SettlementTrips.pos(r, e[1], float(w.minutes))})
	return out


func materialise(id: int):
	if live.has(id):
		return live[id].npc
	var f := find(id)
	if f.is_empty():
		return null
	var s: OffMapSettlement = f.s
	var h: Dictionary = f.h
	var m: Array = f.m
	var t := SettlementTrips.of_person(s, id)
	var n := NPC.new()
	n.id = id
	n.sex = "female" if int(m[OffMapSettlement.M_SEX]) == 1 else "male"
	var who := OffMapSettlement.who_of(m)
	var full := SettlementFolk.name_of(w, s.id, int(h.id), int(f.j), n.sex)
	n.name = str(who.get("name", full.get_slice(" ", 0)))
	n.family = str(who.get("family", full.get_slice(" ", 1)))
	n.born = float(int(m[OffMapSettlement.M_BORN])) * 1440.0
	n.role = "adult" if s._age(m) >= s._lim else "child"
	n.job = str(h.trade) if n.role == "adult" else ""
	n.household = -1                     # not a village household: their household is h in s (journey.settlement, journey.hh)
	for k in who.get("skills", {}):
		n.skills[str(k)] = int(who.skills[k])
	n.sprite = "res://assets/characters/villager_%02d.png" % (absi(id) % 48)
	n.hunger = 100.0
	if not t.is_empty():
		n.pos = SettlementTrips.pos(r, t, float(w.minutes))
		_hand(s, n, t, true)
		n.journey = {"to": str(t.to), "settlement": s.id, "hh": int(h.id), "trip": str(t.tx), "leg": str(t.leg), "since": w.day(), "gate": -1}
	else:
		n.pos = station(s, h, n.role == "adult", int(w.hour()))
		n.journey = {"to": s.id, "settlement": s.id, "hh": int(h.id), "trip": "", "leg": "station", "since": w.day(), "gate": -1}
	n.doing = "on the road" if not t.is_empty() else "at home"
	s.live[id] = true
	w.npcs.append(n)
	w.by_id[id] = n
	live[id] = {"npc": n, "sid": s.id, "hh": int(h.id)}
	return n


func fold(n) -> void:
	if not live.has(int(n.id)):
		return
	var s: OffMapSettlement = r.by_id.get(str(live[int(n.id)].sid))
	var live_hh := int(live[int(n.id)].hh)
	live.erase(int(n.id))
	if s != null:
		s.live.erase(int(n.id))
		var t := SettlementTrips.of_person(s, int(n.id))    # (n.journey may be cleared already: a death ends a journey)
		if not t.is_empty():
			var path := SettlementTrips.leg_path(r, t)
			var got := minf(SettlementTrips.reached(path, n.pos), SettlementTrips.length(path))
			t.depart = SettlementTrips.depart_for(float(w.minutes), got, float(t.pace))
			_take_back(s, n, t)
		else:
			var hp := SettlementParty.make(r, s, "hh:%d" % int(live_hh))
			_take_back(s, n, {} if not hp.alive() else hp.record(), hp)
		if not n.alive:
			_died(s, int(n.id))
	w.npcs.erase(n)
	w.by_id.erase(n.id)


## Fold every live resident (World.to_dict before saving; a save holds records only). They come back live at the next update.
func fold_all() -> void:
	var ids := live.keys()
	ids.sort()
	for id in ids:
		fold(live[id].npc)


# ------------------------------------------------------------------ a live walker's road ----------------
## Journeys.resume for a live resident (n.journey.trip set): the rest of the trip's leg as a path, or a short stand at their station.
## true: the plan is laid.
func resume(n) -> bool:
	n.hunger = 100.0                     # their meals are their household's, booked by the settlement's day (not eaten twice)
	var s: OffMapSettlement = r.by_id.get(str(n.journey.get("settlement", "")))
	if s == null:
		return false
	var t := SettlementTrips.find(s, str(n.journey.get("trip", "")))
	if t.is_empty():
		var f := find(int(n.id))
		if f.is_empty():
			return false
		var to := station(s, f.h, n.role == "adult", int(w.hour()))
		if to == Vector2.INF or n.pos.distance_to(to) < 1.0:
			n.plan = [{"k": "work", "min": 30.0, "anim": "idle"}]
			n.work_left = 30.0
			n.doing = "at work" if n.role == "adult" and int(w.hour()) >= WORK_FROM and int(w.hour()) < WORK_TO else "at home"
			return true
		n.plan = [{"k": "go", "to": Vector2i(to)}, {"k": "work", "min": 30.0, "anim": "idle"}]
		return true
	var path := SettlementTrips.leg_path(r, t)
	if path.size() < 2:
		return false
	var best := 0
	var bd := INF
	for i in path.size():
		var d := (path[i] + Vector2(0.5, 0.5)).distance_squared_to(n.pos)
		if d < bd:
			bd = d
			best = i
	var rest := PackedVector2Array()
	for i in range(best, path.size()):
		rest.append(path[i])
	n.path = rest
	n.path_i = 0
	n.plan = [{"k": "go", "to": Vector2i(rest[rest.size() - 1]), "pathed": true}, {"k": "do", "act": "journey_leg", "args": {}}]
	n.doing = ("on the road to %s" if str(t.leg) == "out" else "on the road home from %s") % OffMapSettlement.place_name(str(t.to))
	return true


## Journeys.leg_done for a live resident: at the destination the errand is done (the pack is booked back to the trip, dealt with and
## handed over again); at home the trip ends and they keep to their station.
func leg_done(n) -> void:
	var s: OffMapSettlement = r.by_id.get(str(n.journey.get("settlement", "")))
	n.plan.clear()
	if s == null:
		return
	var t := SettlementTrips.find(s, str(n.journey.get("trip", "")))
	if t.is_empty():
		return
	_take_back(s, n, t)
	if str(t.leg) == "out":
		SettlementTrips.errand(r, s, t, float(w.minutes))
		t.leg = "back"
		t.depart = float(w.minutes)
		_hand(s, n, t, true)
		n.journey.leg = "back"
	else:
		SettlementTrips.finish(r, s, t, "home")
		n.journey.trip = ""
		n.journey.leg = "station"


# ------------------------------------------------------------------ the two ledgers ----------------
## The trip's pack to the live NPC: out of the settlement's books (outside lines), into the village's (coin_sources, imported_).
func _hand(s: OffMapSettlement, n, t: Dictionary, _from_trip: bool) -> void:
	var c := int(t.coins)
	if c > 0:
		t.coins = 0
		n.coins += c
		s.flows.outside_coins_out += c
		w.coin_sources += c
	var ids: Array = (t.pack as Dictionary).keys()
	ids.sort()
	for k in ids:
		var q := int(t.pack[k])
		if q <= 0:
			continue
		n.inv.add(str(k), q)
		OffMapSettlement._add(s.flows.outside_out, str(k), q)
		w.stat("imported_" + str(k), float(q))
	t.pack = {}


## The NPC's coins and goods back into `rec` (a trip's pack, or a household's purse and pantry through `hp`): the reverse lines.
func _take_back(s: OffMapSettlement, n, rec: Dictionary, hp: SettlementParty = null) -> void:
	if rec.is_empty():
		var tp := SettlementParty.make(r, s, "treasury")      # their household is gone: the treasury takes what they carried
		rec = tp.record()
		hp = tp
	var c := int(n.coins)
	if c > 0:
		n.coins = 0
		if hp == null:
			rec.coins = int(rec.coins) + c
		else:
			rec[hp._purse_key()] = int(rec[hp._purse_key()]) + c
		s.flows.outside_coins_in += c
		w.coin_sources -= c
	var goods: Dictionary = rec.pack if hp == null else hp._goods()
	var items: Dictionary = n.inv.items.duplicate()
	var ids: Array = items.keys()
	ids.sort()
	for k in ids:
		var q: int = n.inv.count(str(k))
		if q <= 0:
			continue
		n.inv.remove(str(k), q)
		OffMapSettlement._add(goods, str(k), q)
		OffMapSettlement._add(s.flows.outside_in, str(k), q)
		w.stat("exported_" + str(k), float(q))


## A live resident died: the member leaves the household's record (the register already knows: World.kill moved them to DEAD).
func _died(s: OffMapSettlement, pid: int) -> void:
	for h in s.hh:
		if not h.has("mem"):
			continue
		for j in h.mem.size():
			if OffMapSettlement.member_id(h.mem[j]) == pid:
				s._remove_member(h, j)
				s._after_loss(h)
				return
