extends SceneTree
## ID-01 (owner, 2026-10-23, docs/directives/2026-10-23_identity_foundation_approval.md): every person has one permanent id, never
## reused; the register (World.people) says who and where they are; a migrant is the same person on the way back; an heir keeps
## their own identity while the village's view of the player goes on as in Build 18; a save from before version 20 is given all of it
## once, deterministically, with ambiguity reported, and a save that cannot be is refused and left alone.
##   godot --headless --path game --script res://tests/identity_test.gd

const Census := preload("res://tests/census.gd")

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL: " + what)


func _init() -> void:
	GameData.ensure()
	test_counter()
	test_band()
	test_register()
	test_leave_and_return()
	test_two_settlements_twice()
	test_save_mid_journey()
	test_offmap_birth_then_arrival()
	test_death_in_settlement()
	test_household_changes()
	test_succession_child()
	test_succession_relative()
	test_round_trip()
	test_upgrade_fixture()
	test_upgrade_away_member()
	test_upgrade_ambiguity()
	test_upgrade_failure_leaves_file()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ------------------------------------------------------------------ fixtures ----------------
func _world(seed_ := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed_)
	w.regions.step_day(w.day())
	return w


func _books(w: World) -> Dictionary:
	var goods: Dictionary = Census.goods(w).duplicate()
	var rg := w.regions.goods()
	for k in rg:
		goods[k] = int(goods.get(k, 0)) + int(rg[k])
	return {"coins": w.total_coins() + w.regions.coins() - (w.coin_sources + w.regions.net_paid_by_village()), "goods": goods}


func _same(a: Dictionary, b: Dictionary) -> bool:
	return int(a.coins) == int(b.coins) and a.goods == b.goods


func _plain_adult(w: World, skip := -1) -> NPC:
	for h in range(3, w.households.size()):
		if h == skip or w.households[h].get("ended", false):
			continue
		var ms: Array = w.brain._members(h)
		if ms.is_empty() or Migration._any_barred(w, ms):
			continue
		for o: NPC in ms:
			if o.role == "adult" and Life._may_move(w, o):
				return o
	return null


func _find_member(w: World, id: int) -> Array:
	for s: OffMapSettlement in w.regions.list:
		for hi in s.hh.size():
			var mem: Array = s.hh[hi].mem
			for j in mem.size():
				if OffMapSettlement.member_id(mem[j]) == id:
					return [s, hi, j]
	return []


## The person goes to the settlement as a work move does (nothing is checked but the mechanics).
func _leave(w: World, s: OffMapSettlement, who: NPC) -> void:
	Migration._pre_leave(w, [who])
	var load_ := Migration._pack(w, [who])
	s.receive_person(load_.people[0], int(load_.coins), load_.goods, Migration.hiring(s) if Migration.hiring(s) != "" else "farm")
	Migration._gone(w, s, [who], load_, null, "work")


## The person (settlement member `id`) comes to the village as a work move does.
func _return(w: World, id: int) -> NPC:
	var at := _find_member(w, id)
	var s: OffMapSettlement = at[0]
	var load_ := s.person_load(at[1], at[2])
	var n := Migration._villager(w, Migration._with_who(s, load_.people[0], str(s.hh[at[1]].trade)), int(load_.coins))
	var h := Migration._house(w, [n])
	s.release_person(at[1], at[2])
	Migration._settled(w, s, [n], h, load_.goods, int(load_.coins), "work")
	return n


func _all_ids_unique(w: World) -> bool:
	var seen := {}
	for n: NPC in w.npcs:
		if seen.has(n.id):
			return false
		seen[n.id] = true
	for s: OffMapSettlement in w.regions.list:
		for h in s.hh:
			for m in h.mem:
				var id := OffMapSettlement.member_id(m)
				if id <= 0 or (seen.has(id) and w.by_id.has(id) and (w.by_id[id] as NPC).alive):
					return false
				if seen.has(id) and not w.by_id.has(id):
					return false
				seen[id] = true
	return true


# ------------------------------------------------------------------ ids are never reused ----------------
func test_counter() -> void:
	var w := _world()
	var top := 0
	for n: NPC in w.npcs:
		top = maxi(top, n.id)
	check(w.next_person_id > top and w.next_person_id < World.BAND_START, "the counter starts above every villager's id, in the village range")
	var ids := []
	for i in 60:
		ids.append(w.brain._next_npc_id())
	var inc := true
	for i in range(1, ids.size()):
		inc = inc and int(ids[i]) > int(ids[i - 1])
	check(inc and not w.by_id.has(int(ids[0])), "many creations: every id is new and higher than the last")
	# a record made and erased: its id is not issued again
	var x := NPC.new()
	x.id = w.new_person_id()
	w.npcs.append(x)
	w.by_id[x.id] = x
	Identity.register_npc(w, x)
	w.npcs.erase(x)
	w.by_id.erase(x.id)
	var next := w.new_person_id()
	check(next > x.id and w.people.has(x.id), "an erased record's id is not issued again, and the register keeps them")
	# a killed villager keeps the record and the id
	var v := _plain_adult(w)
	w.kill(v, "test")
	check(w.new_person_id() > v.id and w.npc(v.id) != null and not v.alive, "a death leaves the record and the id")
	# a record added by hand with a high id lifts the counter over it
	var h := NPC.new()
	h.id = w.next_person_id + 500
	w.npcs.append(h)
	w.by_id[h.id] = h
	check(w.new_person_id() > h.id, "a record added without the counter lifts it, so its id is never handed out")


# ------------------------------------------------------------------ the register ----------------
## ID-D2 option B: the two ranges, their counters and the guard.
func test_band() -> void:
	var w := _world()
	var members := 0
	var lowest := 1 << 60
	var highest := 0
	for s: OffMapSettlement in w.regions.list:
		for h in s.hh:
			for m in h.mem:
				var id := OffMapSettlement.member_id(m)
				members += 1
				lowest = mini(lowest, id)
				highest = maxi(highest, id)
	check(lowest == World.BAND_START and highest < w.next_band_id, "a new world's members take ids from 1,000,000 upward (%d members, %d to %d)" % [members, lowest, highest])
	check(w.player.pid > lowest and w.player.pid < w.next_band_id and w.player.pid >= World.BAND_START, "the founder's id is in the band; the band counter is above all")
	var top := 0
	for n: NPC in w.npcs:
		top = maxi(top, n.id)
	check(top < World.BAND_START and w.next_person_id == top + 1, "every villager is below the band, the village counter is highest plus one, as in Build 18")
	var a := w.new_band_id()
	var v := w.new_person_id()
	var b := w.new_band_id()
	check(a >= World.BAND_START and b == a + 1 and v < World.BAND_START and v == top + 1, "the counters are independent")
	# a record holding a band id (a settlement-born arrival) lifts the band counter, never the village's
	var h := NPC.new()
	h.id = w.next_band_id + 40
	w.npcs.append(h)
	w.by_id[h.id] = h
	check(w.new_band_id() > h.id and w.new_person_id() < World.BAND_START, "a band-id record lifts only the band counter")
	# the village range never reaches the band: the last id is issued, the next is refused (-1) rather than colliding
	w.next_person_id = World.BAND_START - 1
	w.npcs.erase(h)
	w.by_id.erase(h.id)
	var last := w.new_person_id()
	var refused := w.new_person_id()
	check(last == World.BAND_START - 1 and refused == -1, "village ids stop at 999,999: the next request is refused, not issued from the band")
	w.dispose()


func test_register() -> void:
	var w := _world()
	var covered := true
	for n: NPC in w.npcs:
		covered = covered and w.people.has(n.id) and str(w.people[n.id].where) == "village" and w.people[n.id].name == n.name
	check(covered, "every villager is in the register, in the village")
	var members := 0
	var members_ok := true
	for s: OffMapSettlement in w.regions.list:
		for h in s.hh:
			for m in h.mem:
				members += 1
				var id := OffMapSettlement.member_id(m)
				members_ok = members_ok and id > 0 and w.people.has(id) and str(w.people[id].where) == s.id
	check(members > 100 and members_ok and _all_ids_unique(w), "every settlement member has a unique id and a register entry in their settlement (%d people)" % members)
	check(w.player.pid > 0 and str(w.people[w.player.pid].where) == "player", "the player has an id and is entered as the player")
	var total := w.people.size()
	check(total == w.npcs.size() + members + 1, "the register holds each person once (%d)" % total)
	var v := _plain_adult(w)
	w.kill(v, "test")
	check(str(w.people[v.id].where) == "dead", "a death marks the register")
	var born := Life.birth(w, v, null, v.household)
	check(w.people.has(born.id) and int(w.people[born.id].mother) == v.id and str(w.people[born.id].where) == "village", "a birth enters the register with its mother")
	var kid := Life.birth(w, w.npc(born.mother), w.player, born.household)
	check(int(w.people[kid.id].father) == w.player.pid, "a child of the player is entered with the player's own id as parent")
	var nc: NPC = w.brain._newcomer_for({"job": "guard", "workplace": w.brain._guard_shift(null), "home": "", "household": -1, "day": 0, "who": "a guard", "heir": -1})
	check(w.people.has(nc.id), "a newcomer is entered")


# ------------------------------------------------------------------ leaving and returning ----------------
func test_leave_and_return() -> void:
	var w := _world()
	var s: OffMapSettlement = w.regions.by_id["higham"]
	var who := _plain_adult(w)
	var friend: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.id != who.id and o.household != who.household and o.household >= 3:
			friend = o
			break
	var t := w.relations.tie(who.id, friend.id)
	t.regard = 42.0
	t.friends = true
	t.days_known = 9
	who.remember("befriended somebody")
	who.skills = {"mining": 321}
	who.coins = 30
	who.inv.add("axe")
	var id := who.id
	var count := w.npcs.size()
	var before := _books(w)
	_leave(w, s, who)
	check(not who.alive and who.away == "higham" and str(w.people[id].where) == "higham", "leaving: the register says the settlement")
	var at := _find_member(w, id)
	check(not at.is_empty() and at[0] == s, "the member in the settlement carries the villager's id")
	check(_same(before, _books(w)) and w.regions.audit() == "", "nothing made or lost on the way out")
	var back := _return(w, id)
	check(back == who and back.alive and back.away == "" and w.npcs.size() == count, "returning: the same record is alive again, no new villager was made")
	check(back.id == id and str(w.people[id].where) == "village" and _find_member(w, id).is_empty(), "the same id; the register says the village; the settlement no longer has them")
	check(float(w.relations.peek(id, friend.id).regard) == 42.0 and w.relations.friends(id, friend.id), "the old tie is back as it was (regard 42, friends)")
	check(back.skills.get("mining", 0) == 321 and back.coins > 0, "with what they carried: their skills and their share of the purse")
	check(back.memory.has("befriended somebody"), "and their memories")
	var listed := 0
	for hh in w.households:
		listed += (hh.members as Array).count(id)
	check(listed == 1 and back.household >= 0, "they are in exactly one household's list")
	check(_same(before, _books(w)) and w.regions.audit() == "", "nothing made or lost on the way back")
	# the move that did not go through (no home): the person is as they were
	_leave(w, s, back)
	var at2 := _find_member(w, id)
	var load_ := s.person_load(at2[1], at2[2])
	var n2 := Migration._villager(w, Migration._with_who(s, load_.people[0], "farmer"), int(load_.coins))
	check(n2 == back and n2.alive, "(reactivated for a move)")
	Migration._undo_villager(w, n2)
	check(not back.alive and back.away == "higham" and str(w.people[id].where) == "higham", "a move that falls through puts them back as they were")


func test_two_settlements_twice() -> void:
	var w := _world()
	var a: OffMapSettlement = w.regions.list[0]
	var b: OffMapSettlement = w.regions.list[1]
	var who := _plain_adult(w)
	var id := who.id
	var friend: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.household != who.household and o.household >= 3:
			friend = o
			break
	w.relations.tie(id, friend.id).regard = 17.5
	var count := w.npcs.size()
	var ok := true
	for round in 2:
		_leave(w, a, who)
		ok = ok and str(w.people[id].where) == a.id
		_return(w, id)
		_leave(w, b, who)
		ok = ok and str(w.people[id].where) == b.id and not _find_member(w, id).is_empty() and _find_member(w, id)[0] == b
		_return(w, id)
		ok = ok and str(w.people[id].where) == "village" and who.alive
	check(ok and w.npcs.size() == count and w.by_id[id] == who, "to a settlement and back, to another and back, twice: one person, one record, one id")
	check(float(w.relations.peek(id, friend.id).regard) == 17.5, "the tie survived all four journeys")
	check(_all_ids_unique(w) and w.regions.audit() == "", "ids are still unique and the settlements' books balance")


func test_save_mid_journey() -> void:
	var w := _world()
	var s: OffMapSettlement = w.regions.by_id["higham"]
	var who := _plain_adult(w)
	var id := who.id
	var friend: NPC = w.npcs.filter(func(o: NPC) -> bool: return o.alive and o.household != who.household and o.household >= 3)[0]
	w.relations.tie(id, friend.id).regard = 61.0
	_leave(w, s, who)
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	check(w2.load_error == "" and w2.identity_report.is_empty(), "a version 20 save loads without any upgrade")
	var at := _find_member(w2, id)
	check(not at.is_empty() and str(w2.people[id].where) == "higham" and not w2.npc(id).alive and w2.npc(id).away == "higham", "saved while away: the id, the member and the register are as they were")
	var back := _return(w2, id)
	check(back == w2.npc(id) and back.alive and float(w2.relations.peek(id, friend.id).regard) == 61.0, "and after loading they come back as the same person with the same tie")
	check(w2.next_person_id == w.next_person_id, "the counter was saved")
	w2.dispose()


# ------------------------------------------------------------------ people born and dying in a settlement ----------------
func test_offmap_birth_then_arrival() -> void:
	var w := _world()
	var s: OffMapSettlement = w.regions.by_id["higham"]
	var known := {}
	for h in s.hh:
		for m in h.mem:
			known[OffMapSettlement.member_id(m)] = true
	var guard := 0
	var born_id := 0
	var born_h := -1
	while born_id == 0 and guard < 900:
		guard += 1
		w.minutes += World.DAY
		w.regions.step_day(w.day())
		for hi in s.hh.size():
			for m in s.hh[hi].mem:
				var id := OffMapSettlement.member_id(m)
				if id > 0 and not known.has(id):
					born_id = id
					born_h = hi
					break
			if born_id > 0:
				break
	check(born_id > 0, "a child is born in a settlement (day %d)" % w.day())
	if born_id == 0:
		return
	var e: Dictionary = w.people[born_id]
	check(str(e.where) == "higham" and born_id >= World.BAND_START and born_id < w.next_band_id and not w.by_id.has(born_id), "the newborn has an id from the settlement band and a register entry in the settlement, no villager record")
	check(int(e.mother) > 0 and w.people.has(int(e.mother)), "and their mother's id")
	var nid := w.new_band_id()
	check(nid > born_id and w.new_person_id() < World.BAND_START, "the band counter moved past it, and the village's sequence is untouched")
	# the household comes to the village: the child's first villager record is under the id they were born with
	var h: Dictionary = s.hh[born_h]
	var size: int = h.mem.size()
	var alive0 := w.alive_count()
	var arrived := Migration._household_in(w, s, born_h, "hunger")
	check(arrived and w.alive_count() == alive0 + size, "the household arrives (%d people)" % size)
	var n: NPC = w.npc(born_id)
	check(n != null and n.alive and n.name != "" and str(w.people[born_id].where) == "village" and w.people[born_id].name == n.name, "the settlement-born child's first villager record has the id they were born with")
	check(n != null and n.id == born_id and n.id >= World.BAND_START, "a settlement-born arrival keeps their band id")
	check(_all_ids_unique(w) and w.regions.audit() == "", "ids stay unique")


func test_death_in_settlement() -> void:
	var w := _world()
	var s: OffMapSettlement = w.regions.by_id["higham"]
	var h: Dictionary = s.hh[0]
	var ids: Array = h.mem.map(func(m): return OffMapSettlement.member_id(m))
	s._lose_member(h)
	var gone := 0
	for id in ids:
		if str(w.people[id].where) == "dead":
			gone += 1
	check(gone == 1 and _find_member(w, ids[0]).size() + 0 >= 0, "a death in a settlement marks the register: exactly one of the household is dead")
	var dead_id := 0
	for id in ids:
		if str(w.people[id].where) == "dead":
			dead_id = id
	check(_find_member(w, dead_id).is_empty() and w.people.has(dead_id), "and the dead are no longer members, but are never removed from the register")
	check(w.new_band_id() > dead_id, "their id is not issued again")
	# a person away who dies in the settlement stays one person
	var who := _plain_adult(w)
	_leave(w, s, who)
	var at := _find_member(w, who.id)
	s._died(s.hh[at[1]].mem[at[2]])
	check(str(w.people[who.id].where) == "dead", "a villager who died in a settlement is dead in the register under the same id")


func test_household_changes() -> void:
	var w := _world()
	var s: OffMapSettlement = w.regions.by_id["higham"]
	var wi := -1
	var mi := -1
	var wj := -1
	var mj := -1
	for hi in s.hh.size():
		var h: Dictionary = s.hh[hi]
		for j in h.mem.size():
			var m: Array = h.mem[j]
			if int(m[OffMapSettlement.M_PAIR]) == 0 and s._is_adult(m):
				if int(m[OffMapSettlement.M_SEX]) == 1 and wi < 0:
					wi = hi
					wj = j
				elif int(m[OffMapSettlement.M_SEX]) == 0 and mi < 0 and hi != wi:
					mi = hi
					mj = j
	if wi < 0 or mi < 0:
		_add_pair(s)
		return test_household_changes()
	var wid := OffMapSettlement.member_id(s.hh[wi].mem[wj])
	var mid := OffMapSettlement.member_id(s.hh[mi].mem[mj])
	var nh0 := s.hh.size()
	s._marry(s.hh[wi], wj, s.hh[mi], mj)
	var f1 := _find_member(w, wid)
	var f2 := _find_member(w, mid)
	check(s.hh.size() == nh0 + 1 and not f1.is_empty() and not f2.is_empty() and f1[1] == nh0 and f2[1] == nh0, "a marriage forms a household; both keep their ids")
	check(str(w.people[wid].where) == "higham" and str(w.people[mid].where) == "higham", "and the register is unchanged")
	check(_all_ids_unique(w), "ids stay unique")


func _add_pair(s: OffMapSettlement) -> void:
	s.hh[0].mem.append([s.day - roundi(24.0 * s._yd), 1, 0, 0])
	s.hh[1].mem.append([s.day - roundi(26.0 * s._yd), 0, 0, 0])
	s._recount(s.hh[0])
	s._recount(s.hh[1])


# ------------------------------------------------------------------ succession ----------------
func _player_with_children(w: World, grown: bool) -> Array:
	var p := w.player
	p.sex = "male"
	var mother: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.sex == "female" and n.partner < 0 and n.household >= 3 and Life.npc_age(w, n) >= 18.0)[0]
	var h := mother.household
	var k1 := Life.birth(w, mother, p, h)
	var k2 := Life.birth(w, mother, p, h)
	var Y := Life.year_minutes()
	k1.born = w.minutes - (17.0 if grown else 3.0) * Y
	k2.born = w.minutes - (19.0 if grown else 2.0) * Y
	p.born = w.minutes - 60.0 * Y
	return [k1, k2]


func test_succession_child() -> void:
	var w := _world()
	var kids := _player_with_children(w, true)
	var k1: NPC = kids[0]
	var k2: NPC = kids[1]
	var villager: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.household >= 3 and n.id != k2.id)[0]
	w.relations.tie(Life.PLAYER_ID, villager.id).regard = 37.0
	w.relations.tie(Life.PLAYER_ID, villager.id).friends = true
	w.relations.tie(k2.id, villager.id).regard = 5.0                # the child's own tie
	k2.coins = 25
	var old_pid := w.player.pid
	var heir_name := k2.name
	var before := w.total_coins() - w.coin_sources
	w.player.alive = false
	w.player.death_cause = "test"
	w.continue_as_heir()
	var heir := w.player
	check(heir.name == heir_name and heir.generation == 2 and heir.pid == k2.id, "the heir is the child and keeps the child's own id (%d)" % k2.id)
	var rec := w.npc(k2.id)
	check(rec != null and not rec.alive and rec.became_player and rec.name == heir_name and not w.brain._members(k2.household).has(rec), "the child's record is kept, not alive and in no household's living members")
	check(str(w.people[k2.id].where) == "player" and str(w.people[old_pid].where) == "ancestor" and old_pid != k2.id, "the register: the heir is the player, the predecessor an ancestor under their own id")
	check(w.new_person_id() > k2.id and k2.id < World.BAND_START and heir.pid == k2.id, "the child's id is never issued again (a village id, kept by the heir)")
	check(w.npc(k1.id) != null and w.npc(k1.id).alive, "the other child stays a villager")
	check(float(w.relations.peek(Life.PLAYER_ID, villager.id).regard) == 37.0 and w.relations.friends(Life.PLAYER_ID, villager.id), "Build 18's baseline: the village's view of the player goes on to the heir (regard 37, friends)")
	check(float(w.relations.peek(k2.id, villager.id).regard) == 5.0, "and the heir's own tie as a villager is still theirs (regard 5): the two opinions are separate records")
	var hist: Dictionary = w.tie_history.get(str(old_pid), {})
	check(not hist.is_empty() and float(hist.ties[str(villager.id)].regard) == 37.0 and bool(hist.ties[str(villager.id)].friends), "a snapshot of the predecessor's ties is kept under their id")
	w.relations.peek(Life.PLAYER_ID, villager.id).regard = 90.0       # (peek returns the stored tie)
	check(float(w.tie_history[str(old_pid)].ties[str(villager.id)].regard) == 37.0, "and it is history: later changes to the live tie do not touch it")
	check(w.total_coins() - w.coin_sources == before, "conservation: the coins the child carried lie in the loot, the heir's kit is new money counted as such; the world's coins are unchanged")
	# no loop treats the kept child as a living villager
	var living := 0
	for n: NPC in w.npcs:
		if n.alive:
			living += 1
	check(living == w.alive_count() and not w.npcs.any(func(n: NPC) -> bool: return n.alive and n.id == k2.id), "the child is not counted as a living villager")
	check(rec.coins == 0 and rec.inv.total() == 0, "empty-handed: what they carried lies in the loot, nothing counted twice")
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	check(w2.load_error == "" and w2.npc(k2.id).became_player and not w2.npc(k2.id).alive and w2.player.pid == k2.id and str(w2.people[old_pid].where) == "ancestor" and w2.tie_history.has(str(old_pid)), "all of it survives save and load")
	w2.dispose()
	w.dispose()


func test_succession_relative() -> void:
	var w := _world()
	var old_pid := w.player.pid
	var count := w.npcs.size()
	w.player.alive = false
	w.continue_as_heir()
	check(w.player.pid >= World.BAND_START and w.player.pid != old_pid and str(w.people[w.player.pid].where) == "player" and str(w.people[old_pid].where) == "ancestor", "a relative heir gets a new id; the predecessor is an ancestor")
	check(w.npcs.size() == count and w.next_band_id > w.player.pid, "no villager record was made or lost")
	w.player.alive = false
	w.continue_as_heir()
	check(str(w.people[old_pid].where) == "ancestor" and w.people.size() >= 3, "the next succession keeps every earlier ancestor")
	w.dispose()


func test_round_trip() -> void:
	var w := _world(2)
	var who := _plain_adult(w)
	_leave(w, w.regions.list[2], who)
	var a: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), a)
	var b: Dictionary = JSON.parse_string(JSON.stringify(w2.to_dict(), "", true, true))
	check(JSON.stringify(a.people, "", true, true) == JSON.stringify(b.people, "", true, true) and a.next_person_id == b.next_person_id and JSON.stringify(a.regions, "", true, true) == JSON.stringify(b.regions, "", true, true), "save, load, save: the register, counter and members are identical")
	w2.dispose()


# ------------------------------------------------------------------ an older save ----------------
## A world as Build 18 (version 19) saved it: no register, counter, ids, became_player.
func _as_v19(d: Dictionary) -> Dictionary:
	var o: Dictionary = JSON.parse_string(JSON.stringify(d, "", true, true))
	for k in ["people", "next_person_id", "identity_report", "tie_history"]:
		o.erase(k)
	(o.player as Dictionary).erase("pid")
	for n in o.npcs:
		(n as Dictionary).erase("became_player")
	for s in o.regions.settlements:
		for h in s.hh:
			for m in h.mem:
				while (m as Array).size() > 5:
					m.pop_back()
				if m.size() == 5 and (m[4] as Dictionary).is_empty():
					m.pop_back()
	o.save_version = 19
	return o


func _load(d: Dictionary) -> World:
	var w := World.new()
	w.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d, "", true, true)))
	return w


func test_upgrade_fixture() -> void:
	var text := FileAccess.get_file_as_string("res://tests/fixtures/b17_save_seed7.json")
	var d: Dictionary = JSON.parse_string(text)
	var npcs: int = d.npcs.size()
	var w := _load(d)
	check(w.load_error == "" and w.npcs.size() == npcs, "the Build 17 fixture loads and upgrades with every villager kept (%d)" % npcs)
	var covered := true
	var top := 0
	for n: NPC in w.npcs:
		covered = covered and w.people.has(n.id)
		top = maxi(top, n.id)
	var members := 0
	for s: OffMapSettlement in w.regions.list:
		for h in s.hh:
			members += h.mem.size()
	check(covered and w.player.pid > 0 and w.people.size() == npcs + members + 1, "the register covers every villager, every member and the player (%d + %d + 1)" % [npcs, members])
	check(w.next_person_id > top and w.next_person_id < World.BAND_START and _all_ids_unique(w), "the village counter is above every villager id (and below the band), and the ids are unique")
	var band_ok := w.player.pid >= World.BAND_START and w.next_band_id > w.player.pid
	var prev := w.player.pid
	var order_ok := true
	for s: OffMapSettlement in w.regions.list:
		for h in s.hh:
			for m in h.mem:
				var mid := OffMapSettlement.member_id(m)
				band_ok = band_ok and mid >= World.BAND_START and mid < w.next_band_id and not w.by_id.has(mid)
	var first_member := OffMapSettlement.member_id(w.regions.list[0].hh[0].mem[0])
	check(band_ok and first_member == World.BAND_START, "every settlement member and the player have band ids, from 1,000,000 in settlement, household, member order")
	check(w.player.pid == w.next_band_id - 1, "the player's id follows the members' in the band")
	check(int(w.identity_report.from_version) == 17 and int(w.identity_report.counts.villagers) == npcs, "the report names the save's version and counts")
	var ids_a := JSON.stringify(w._people_to_dict(), "", true, true)
	var rep_a := JSON.stringify(w.identity_report, "", true, true)
	var again := _load(d)
	check(ids_a == JSON.stringify(again._people_to_dict(), "", true, true) and rep_a == JSON.stringify(again.identity_report, "", true, true) and again.next_person_id == w.next_person_id, "deterministic: two loads give identical ids, register and report")
	var back := _load(w.to_dict())
	check(back.load_error == "" and JSON.stringify(back._people_to_dict(), "", true, true) == ids_a, "the upgraded world saves as version 20 and reloads the same")
	# existing ids unchanged
	var same := true
	for nd in d.npcs:
		same = same and w.npc(int(nd.id)) != null and w.npc(int(nd.id)).name == str(nd.name)
	check(same, "every existing villager keeps their id")
	w.dispose()
	again.dispose()
	back.dispose()
	var m := SaveTransfer.migrate(d, VillageMap.load_default())
	check(m.ok and int(m.data.save_version) == 20 and m.data.has("people"), "an imported old save migrates to version 20 (%s)" % m.get("reason", ""))


func test_upgrade_away_member() -> void:
	var w := _world()
	var s: OffMapSettlement = w.regions.by_id["higham"]
	var who := _plain_adult(w)
	var other := _plain_adult(w, who.household)
	var id := who.id
	_leave(w, s, who)
	_leave(w, w.regions.by_id[w.regions.list[3].id], other)
	var old := _as_v19(w.to_dict())
	var count: int = old.npcs.size()
	var v := _load(old)
	check(v.load_error == "", "a Build 18 world with two migrants away loads (%s)" % v.load_error)
	check(v.npcs.size() == count and v.npc(id) != null and not v.npc(id).alive and v.npc(id).away == "higham", "no villager record dropped or changed")
	var at := _find_member(v, id)
	check(not at.is_empty() and v.identity_report.counts.reunited == 2, "each away villager is matched to exactly one member, and the member takes the villager's id (reunited: %s)" % str(v.identity_report.counts.reunited))
	check(str(v.people[id].where) == "higham" and v.people.has(other.id) and str(v.people[other.id].where) == v.regions.list[3].id, "and the register says where they are")
	check(_all_ids_unique(v) and (v.identity_report.notes as Array).is_empty(), "ids are unique, and nothing needed reporting")
	# and they can come home as the same person
	var n := _return(v, id)
	check(n == v.npc(id) and n.alive and v.npcs.size() == count, "the reunited member comes back as the same villager")
	v.dispose()
	w.dispose()


func test_upgrade_ambiguity() -> void:
	var w := _world()
	var s: OffMapSettlement = w.regions.by_id["higham"]
	var who := _plain_adult(w)
	var id := who.id
	_leave(w, s, who)
	var old := _as_v19(w.to_dict())
	# a second member that looks the same as the one the villager became
	var members := 0
	for sd in old.regions.settlements:
		if sd.id != "higham":
			continue
		for h in sd.hh:
			for m in h.mem:
				if m.size() == 5 and str(m[4].n) == who.name:
					var twin: Array = JSON.parse_string(JSON.stringify(m))
					h.mem.append(twin)
					members += 1
					break
			if members > 0:
				break
	check(members == 1, "(a twin member was added)")
	var v := _load(old)
	check(v.load_error == "", "the world loads (%s)" % v.load_error)
	var notes: Array = v.identity_report.notes
	var amb: Array = notes.filter(func(x): return x.kind == "away_ambiguous")
	check(amb.size() == 1 and int(amb[0].npc) == id and amb[0].members.size() == 2, "two identical-looking members: the case is reported, not guessed")
	check(v.identity_report.counts.reunited == 0 and _find_member(v, id).is_empty(), "neither member takes the villager's id")
	check(v.npc(id) != null and not v.npc(id).alive and str(v.people[id].where) == "higham" and _all_ids_unique(v), "the villager keeps their id and record, each member has a separate id")
	# an away villager no member matches
	var old2 := _as_v19(w.to_dict())
	for sd in old2.regions.settlements:
		for h in sd.hh:
			for m in h.mem:
				if m.size() == 5 and str(m[4].n) == who.name:
					m[4].n = "Somebody Else"
	var v2 := _load(old2)
	var un: Array = (v2.identity_report.notes as Array).filter(func(x): return x.kind == "away_unmatched")
	check(v2.load_error == "" and un.size() == 1 and int(un[0].npc) == id, "a villager no member matches is reported, and both records are kept")
	# a returned migrant an older build replaced by a new person
	var old3 := _as_v19(w.to_dict())
	var copy: Dictionary = JSON.parse_string(JSON.stringify(old3.npcs.filter(func(n): return int(n.id) == id)[0]))
	copy.id = 9999
	copy.erase("away")
	copy.alive = true
	old3.npcs.append(copy)
	var v3 := _load(old3)
	var rr: Array = (v3.identity_report.notes as Array).filter(func(x): return x.kind == "returned_as_new_record")
	check(v3.load_error == "" and rr.size() == 1 and int(rr[0].old) == id and int(rr[0].new) == 9999 and v3.npc(id) != null and v3.npc(9999) != null, "a returned migrant an older build replaced is reported; both records are kept, nothing merged")
	v.dispose()
	v2.dispose()
	v3.dispose()
	w.dispose()


func test_upgrade_failure_leaves_file() -> void:
	var w := _world()
	var old := _as_v19(w.to_dict())
	old.npcs[1].id = old.npcs[0].id                        # two villagers with one id: it cannot be told who is who
	var text := JSON.stringify(old, "", true, true)
	var path := "user://identity_test_save.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	var r := SaveStore.inspect(path, World.SAVE_VERSION)
	check(r.state == "ok", "(the damaged older save is readable)")
	var v := World.new()
	v.load_dict(VillageMap.load_default(), r.data)
	check(v.load_error != "" and v.load_error.contains("share the id"), "the load is refused with a clear reason: %s" % v.load_error)
	check(FileAccess.get_file_as_string(path) == text, "and the file is byte for byte as it was")
	var m := SaveTransfer.migrate(old, VillageMap.load_default())
	check(not m.ok and str(m.reason).contains("share the id"), "importing it fails with the same reason and changes nothing")
	var target := "user://identity_test_target.json"
	var g := FileAccess.open(target, FileAccess.WRITE)
	g.store_string("{\"keep\": true}")
	g.close()
	var imp := SaveTransfer.import_save(path, target, VillageMap.load_default())
	check(not imp.ok and FileAccess.get_file_as_string(target) == "{\"keep\": true}", "an import that cannot be migrated leaves the existing save as it was")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(target))
	w.dispose()
