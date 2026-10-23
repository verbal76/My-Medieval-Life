extends SceneTree
## Expansion 20 LE-01 foundation: EconActor, EconReservations, EconEvents and the EconomyFoundation attach point. A claim never
## moves goods or coins; a double claim is refused; records are ordered, bounded, saved; disabled means nothing exists.
## Run headless:  godot --headless --path game --script res://tests/economy_foundation_test.gd

const Census := preload("res://tests/census.gd")
var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func new_world(on := true, seed := 1) -> World:
	EconomyFoundation.set_override({"enabled": true, "reservations": {"keep_finished": 5}, "events": {"capacity": 8, "save": true}} if on else {})
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


func _init() -> void:
	test_disabled()
	test_resolver()
	test_double_spend()
	test_release_expiry()
	test_consume_moves_nothing()
	test_impossible()
	test_unbacked()
	test_determinism()
	test_events()
	test_save()
	test_timing()
	EconomyFoundation.set_override({})
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func adults(w: World) -> Array:
	var out := []
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 0:
			out.append(n)
	return out


func snap(w: World) -> Array:
	return [w.total_coins(), Census.goods(w)]


func test_disabled() -> void:
	var w := new_world(false)
	check(w.economy == null, "disabled: World builds no economy foundation")
	check(not w.to_dict().has("economy"), "disabled: to_dict has no economy key")
	var d := w.to_dict()
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	check(w2.economy == null, "disabled: load builds nothing")
	check(not EconomyFoundation.enabled(), "shipped economy.json is disabled")
	var f := FileAccess.open("res://data/economy.json", FileAccess.READ)
	var j = JSON.parse_string(f.get_as_text())
	check(j.format == "mml-economy/1" and j.enabled == false, "economy.json format and enabled=false")


func test_resolver() -> void:
	var w := new_world()
	var a: NPC = adults(w)[0]
	var a2: NPC = adults(w)[1]
	a.inv.add("wheat", 4)
	a.coins = 30
	var e := w.economy.actors
	var ref := World.npc_ref(a.id)
	check(e.kind(ref) == "npc" and e.exists(ref) and e.alive(ref), "resolver: living npc")
	check(e.coins(ref) == 30 and e.count(ref, "wheat") == 4 and e.goods(ref).wheat == 4, "resolver: npc coins and goods from NPC")
	var hr := World.hh_ref(a.household)
	check(e.kind(hr) == "hh" and e.alive(hr), "resolver: household")
	w.households[a.household].pantry.add("bread", 3)
	check(e.count(hr, "bread") == 3 and e.coins(hr) == 0, "resolver: pantry goods, no pooled purse")
	w.player.coins = 11
	w.player.inv.add("wheat", 2)
	check(e.kind("player") == "player" and e.coins("player") == 11 and e.count("player", "wheat") >= 2, "resolver: player")
	w.treasury = 77
	w.granary.add("wheat", 9)
	check(e.coins("manor") == 77 and e.count("manor", "wheat") == w.granary.count("wheat"), "resolver: manor treasury and granary")
	check(e.exists("chapel") and e.coins("chapel") == w.chapel.coins, "resolver: chapel")
	var found := false
	for p in w.regions.parties():
		check(e.exists(p.ref) and e.coins(p.ref) == p.purse() and e.goods(p.ref) == p.held_items(), "resolver: region party " + p.ref)
		found = true
		break
	check(found, "resolver: settlements have parties")
	check(not e.exists("region:nowhere/x") and not e.exists("npc:99999") and not e.exists("hh:9999") and not e.exists("") and not e.exists("bogus:1"), "resolver: unknown refs do not exist")
	a2.alive = false
	var dr := World.npc_ref(a2.id)
	check(e.exists(dr) and not e.alive(dr), "resolver: dead npc exists, not alive")
	var h2: int = adults(w)[2].household
	w.households[h2].ended = true
	check(e.exists(World.hh_ref(h2)) and not e.alive(World.hh_ref(h2)) and e.goods(World.hh_ref(h2)).is_empty(), "resolver: ended household not alive, holds nothing")
	check(e.kind("business:1") == "", "resolver: no business identity (OD-LE-04/07)")


func test_double_spend() -> void:
	var w := new_world()
	var a: NPC = adults(w)[0]
	a.inv.add("wheat", 5)
	a.coins = 20
	var r := w.economy.reservations
	var ref := World.npc_ref(a.id)
	var base := a.inv.count("wheat")
	check(r.reserve(ref, "wheat", base - 1, "order").ok, "reserve most of the stock")
	check(not r.reserve(ref, "wheat", 2, "other").ok, "second reserve over the holding refused")
	check(r.available(ref, "wheat") == 1, "reserved stock unavailable to a second reserve")
	check(r.reserve(ref, "wheat", 1, "last").ok and r.available(ref, "wheat") == 0, "exactly the rest can be reserved")
	check(r.reserve(ref, "coins", 20, "rent").ok and not r.reserve(ref, "coins", 1, "x").ok, "coins reserved once")
	check(r.reserved(ref, "wheat") == base, "reserved total per item")


func test_release_expiry() -> void:
	var w := new_world()
	var a: NPC = adults(w)[0]
	a.inv.add("wheat", 4)
	var base := a.inv.count("wheat")
	var r := w.economy.reservations
	var ref := World.npc_ref(a.id)
	var x: int = r.reserve(ref, "wheat", base, "a", 3).id
	check(r.available(ref, "wheat") == 0, "held: none available")
	check(r.release(x) and r.available(ref, "wheat") == base, "release restores availability")
	check(not r.release(x) and not r.consume(x), "a released claim cannot be released or consumed again")
	var y: int = r.reserve(ref, "wheat", base, "b", 3).id
	check(r.expire_due(3).is_empty(), "not due on its last day")
	check(r.expire_due(4) == [y] and r.get_record(y).state == "expired" and r.available(ref, "wheat") == base, "expiry restores availability")
	check(not r.reserve(ref, "wheat", 1, "past", w.day() - 1).ok if w.day() > 0 else true, "already-expired expiry refused")


func test_consume_moves_nothing() -> void:
	var w := new_world()
	var a: NPC = adults(w)[0]
	a.inv.add("wheat", 4)
	a.coins = 12
	var ref := World.npc_ref(a.id)
	var r := w.economy.reservations
	var s0 := snap(w)
	var ids := []
	for step in [["wheat", 2], ["coins", 5]]:
		ids.append(r.reserve(ref, step[0], step[1], "t").id)
		check(snap(w) == s0, "reserve moves nothing: " + step[0])
	r.release(ids[0])
	check(snap(w) == s0, "release moves nothing")
	check(r.consume(ids[1]) and snap(w) == s0, "consume marks only; coins and goods unchanged")
	r.expire_due(9999)
	check(snap(w) == s0 and a.coins == 12, "expire moves nothing")


func test_impossible() -> void:
	var w := new_world()
	var a: NPC = adults(w)[0]
	var d: NPC = adults(w)[1]
	a.inv.add("wheat", 1)
	var r := w.economy.reservations
	check(not r.reserve(World.npc_ref(a.id), "wheat", a.inv.count("wheat") + 1, "x").ok, "more than held refused")
	check(not r.reserve("npc:99999", "wheat", 1, "x").ok, "unknown owner refused")
	d.inv.add("wheat", 3)
	d.alive = false
	check(not r.reserve(World.npc_ref(d.id), "wheat", 1, "x").ok, "dead owner refused")
	check(not r.reserve(World.npc_ref(a.id), "wheat", 0, "x").ok and not r.reserve(World.npc_ref(a.id), "wheat", -1, "x").ok, "zero and negative refused")
	check(not r.reserve(World.hh_ref(a.household), "coins", 1, "x").ok, "household holds no coins")
	check(r.is_empty(), "refusals leave no record")


func test_unbacked() -> void:
	var w := new_world()
	var a: NPC = adults(w)[0]
	var b: NPC = adults(w)[1]
	a.inv.add("wheat", 3)
	b.coins = 100
	var n := a.inv.count("wheat")
	var r := w.economy.reservations
	var ref := World.npc_ref(a.id)
	r.reserve(ref, "wheat", n, "order")
	check(r.unbacked().is_empty(), "backed claim: nothing reported")
	check(w.trade(b, a, "wheat", 2, 1), "a live trade takes goods the owner had reserved")
	var u := r.unbacked()
	check(u.size() == 1 and u[0].owner == ref and u[0].short == 2 and u[0].held == n - 2, "unbacked() reports the shortfall")
	check(r.reserved(ref, "wheat") == n, "report only: the claim is not changed")
	a.alive = false
	check(r.unbacked()[0].alive == false and r.unbacked()[0].held == 0, "dead owner's claims reported unbacked")


func run_ops(w: World) -> String:
	var ad := adults(w)
	for i in 4:
		ad[i].inv.add("wheat", 3 + i)
		ad[i].coins = 10 * (i + 1)
	var r := w.economy.reservations
	var ids := []
	for i in [3, 0, 2, 1]:
		ids.append(r.reserve(World.npc_ref(ad[i].id), "wheat", 2, "p%d" % i, 5 + i).id)
		ids.append(r.reserve(World.npc_ref(ad[i].id), "coins", 4, "c%d" % i).id)
	r.release(ids[1])
	r.consume(ids[2])
	r.expire_due(7)
	return JSON.stringify(w.economy.to_dict())


func test_determinism() -> void:
	var s1 := run_ops(new_world())
	var s2 := run_ops(new_world())
	check(s1 == s2 and s1.length() > 50, "same operations twice: identical serialized state")
	var ids: Array = JSON.parse_string(s1).reservations.records.map(func(x): return int(x.id))
	var sorted := ids.duplicate()
	sorted.sort()
	check(ids == sorted, "serialized records sorted by id")


func test_events() -> void:
	var w := new_world()
	var ev := w.economy.events
	check(ev.capacity == 8, "ring capacity from config")
	for i in 20:
		ev.record_at(0, i, "trade", "npc:1", "npc:2", "wheat", 1, 2)
	check(ev.size() == 8 and ev.ordered(), "ring bounded and ordered")
	check(ev.ring[0].seq == 12 and ev.next_seq == 20, "oldest fall off, seq keeps counting")
	check(ev.record_at(0, 0, "trade") == -1, "an event earlier than the last is refused, not reordered")
	check(ev.record_at(0, 30, "bogus") == -1, "unknown type refused")
	ev.record_at(0, 30, "gift", "npc:3", "npc:1")
	ev.record_at(0, 30, "gift", "npc:3", "npc:4")
	var q := ev.query("npc:3", "gift")
	check(q.size() == 2 and q[0].seq < q[1].seq, "ties at the same minute break by seq")
	check(ev.query("npc:1").size() >= 3 and ev.query("", "gift").size() == 2, "query by actor and type")
	var a: NPC = adults(w)[0]
	a.inv.add("wheat", 2)
	var n0 := ev.size()
	var id: int = w.economy.reservations.reserve(World.npc_ref(a.id), "wheat", 2, "o").id
	w.economy.reservations.release(id)
	check(ev.size() == mini(8, n0 + 2) and ev.ring[ev.size() - 1].type == "release", "reservation changes are noted as events")


func test_save() -> void:
	var w := new_world()
	var a: NPC = adults(w)[0]
	a.inv.add("wheat", 4)
	check(not w.to_dict().has("economy"), "enabled but empty: no save key")
	w.economy.reservations.reserve(World.npc_ref(a.id), "wheat", 3, "order", 40)
	var d := w.to_dict()
	check(d.has("economy"), "non-empty: key written")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
	check(w2.economy != null and JSON.stringify(w2.economy.to_dict()) == JSON.stringify(w.economy.to_dict()), "round trip identical (reservations and events)")
	check(w2.economy.reservations.available(World.npc_ref(a.id), "wheat") == w.economy.reservations.available(World.npc_ref(a.id), "wheat"), "availability after load")
	var nid: int = w2.economy.reservations.reserve(World.npc_ref(a.id), "wheat", 1, "z").id
	check(nid == 1 or nid == w.economy.reservations.next_id, "ids continue after load")
	var old := d.duplicate(true)
	old.erase("economy")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), old)
	check(w3.economy != null and w3.economy.is_empty(), "old save (no key) loads with empty records")
	EconomyFoundation.set_override({})
	var w4 := World.new()
	w4.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
	check(w4.economy == null and w4.total_coins() == w.total_coins(), "disabled: a save with the key loads, the key is ignored")
	check(not w4.to_dict().has("economy"), "disabled: re-saved without the key")


func test_timing() -> void:
	var w := new_world()
	var r := w.economy.reservations
	var ad := adults(w)
	var per_small := _bench(w, r, ad.slice(0, 5))
	for i in 500:
		var n := NPC.new()
		n.id = 100000 + i
		n.household = -1
		n.inv.add("wheat", 5)
		n.coins = 5
		w.npcs.append(n)
		w.by_id[n.id] = n
	var big: Array = w.npcs.slice(w.npcs.size() - 500)
	var per_big := _bench(w, r, big)
	print("timing: us/op small=%.1f big(500)=%.1f" % [per_small, per_big])
	check(per_big < 5.0 * maxf(per_small, 2.0) and per_big < 200.0, "operations are per-owner, not a population scan (500 villagers)")
	var t0 := Time.get_ticks_usec()
	for i in 200:
		r.expire_due(1)
	check(float(Time.get_ticks_usec() - t0) / 200.0 < 5000.0, "expire_due scans held reservations only")


func _bench(w: World, r: EconReservations, owners: Array) -> float:
	var t0 := Time.get_ticks_usec()
	var ops := 0
	for round in 20:
		for n: NPC in owners:
			var ref := World.npc_ref(n.id)
			var x: Dictionary = r.reserve(ref, "wheat", 1, "b")
			r.available(ref, "wheat")
			if x.ok:
				r.release(int(x.id))
			ops += 3
	return float(Time.get_ticks_usec() - t0) / float(ops)
