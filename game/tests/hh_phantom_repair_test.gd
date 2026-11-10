extends SceneTree
## B25-SAVE-PHANTOM-D2 (owner decision 2026-11-10, docs/directives/2026-11-10_contract_commitments_legacy_save_repair.md,
## "Decision 2: APPROVED WITH SAFEGUARDS"): saves written before household member ids were whole numbers on load (cdfa395)
## hold phantom members: a villager who moved household, an orphan placed elsewhere, a band adult who left the camp, still
## listed where they had been (the old build's Array.erase with an int id never removed the float read from JSON). On load,
## World.repair_household_members removes an entry only when the records prove it a phantom, adds a living villager missing
## from their own household only when nothing else lists them, and leaves every other mismatch as it is, flagged in the saved
## `membership_report`.
##
## The older save is made the way the old build made it: a world is loaded, its member ids put back to floats (as the old
## World.load_dict left them), then real household changes run (Guardianship.dawn for orphans and the band, Guardianship.move),
## and the world is saved. Ambiguous records an older save might hold are then written into a copy of that save by hand.
## Checked:
##   1 a fresh save loads with nothing repaired and no report
##   2 the old save holds the phantoms (the failure this repairs)
##   3 phantoms removed: a band adult (as p:142), orphans placed elsewhere (as household 27's), a moved villager; a duplicate
##     entry kept once; a living villager missing from every list put back in their own household
##   4 legitimate entries kept: a dead member in their own household, the band household's other members, every other member
##   5 ambiguous entries kept as they are and flagged: an unknown id, a dead person listed in a second household, a living person
##     with no household, conflicting records, an ended household listing someone else's member
##   6 the orphans' old household offers no orphans any more (no re-placement every dawn)
##   7 coins and items unchanged by the repair
##   8 idempotent: save -> load -> save is identical, the second load repairs and flags nothing new
##   9 deterministic: two loads of the same old save agree
##   godot --headless --path game --script res://tests/hh_phantom_repair_test.gd

var checks := 0
var fails := 0


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		fails += 1


func _count(list: Array, id: int) -> int:
	var c := 0
	for m in list:
		if int(m) == id:
			c += 1
	return c


func _has_entry(rep: Dictionary, part: String, kind: String, h: int, id: int) -> bool:
	for e in rep.get(part, []):
		if str(e.kind) == kind and int(e.h) == h and int(e.id) == id:
			return true
	return false


func _report(w: World) -> Dictionary:
	var r = w.get("membership_report")       # (read by name: the failing-first run is on a build without it)
	return r if r is Dictionary else {}


func _items(w: World) -> int:
	var n := w.granary.total()
	for hh in w.households:
		n += (hh.pantry as Inventory).total()
	for o: NPC in w.npcs:
		n += o.inv.total()
	for l in w.loot:
		n += (l.inv as Inventory).total()
	return n


func _household(w: World, family: String, band := false) -> int:
	for i in w.households.size():
		if str(w.households[i].family) == family and bool(w.households[i].get("band", false)) == band:
			return i
	return -1


func _init() -> void:
	GameData.ensure()
	var map := VillageMap.load_default()
	var w := World.new()
	w.setup(map, 1)
	var t0 := JSON.stringify(w.to_dict(), "", true, true)

	# 1 a fresh save: nothing to repair
	var wf := World.new()
	wf.load_dict(map, JSON.parse_string(t0))
	var tf: Dictionary = wf.to_dict()
	check(not tf.has("membership_report") and float(wf.stats.get("household_members_repaired", 0.0)) == 0.0,
			"a fresh save loads with nothing repaired and no membership report")
	wf.dispose()

	# the old build: a load left the member ids as floats; household changes after it left phantoms behind
	var w1 := World.new()
	w1.load_dict(map, JSON.parse_string(t0))
	for hh in w1.households:
		hh.members = (hh.members as Array).map(func(x): return float(x))
	var band := _household(w1, "Outlaw", true)
	var orph := _household(w1, "Oakley")          # adults 23, 24, 25; children 26, 27 (seed 1)
	var marsh := _household(w1, "Marsh")          # 33-35 adults, 36 child, 37 elder
	var lore := _household(w1, "Lorekeeper")      # 12, alone
	var brook := 21
	check(band >= 0 and orph >= 0 and marsh >= 0 and lore >= 0, "the households of the scenario exist (band %d, orphans %d, Marsh %d, Lorekeeper %d)" % [band, orph, marsh, lore])
	var lead: NPC = w1.npc(int((w1.households[band].members as Array)[0]))
	Guardianship.move(w1, lead, brook, "villager")    # as p:142: a band adult moved into a village household
	for id in [23, 24, 25]:
		w1.kill(w1.npc(id), "illness")
	var kids := [26, 27]
	Guardianship.dawn(w1)                               # the orphans are placed (a household, or the band's camp)
	Guardianship.dawn(w1)                               # the old build places them again: their old household still lists them
	var kid_h := {}
	for id in kids:
		kid_h[id] = w1.npc(id).household                # (where the last placement put them)
	Guardianship.move(w1, w1.npc(33), marsh + 1, "villager")    # a moved villager (Marsh -> Lambert)
	Guardianship.move(w1, w1.npc(36), marsh + 2, "villager")    # a child out and back: a duplicate in Marsh
	Guardianship.move(w1, w1.npc(36), marsh, "villager")
	w1.kill(w1.npc(37), "old age")                      # a dead member stays listed in their own household (by design)
	w1.kill(w1.npc(12), "old age")                      # Lorekeeper ends
	check(bool(w1.households[lore].get("ended", false)), "the Lorekeeper household ended with its last member")
	var coins0 := w1.total_coins()
	var items0 := _items(w1)
	var d1: Dictionary = JSON.parse_string(JSON.stringify(w1.to_dict(), "", true, true))

	# 2 the old save holds the phantoms
	var hs: Array = d1.households
	check(_count(hs[band].members, lead.id) == 1 and _count(hs[orph].members, 26) == 1 and _count(hs[orph].members, 27) == 1
			and _count(hs[marsh].members, 33) == 1 and _count(hs[marsh].members, 36) == 2,
			"the old save holds the phantoms (band adult %d, orphans 26 and 27, moved 33, duplicate 36)" % lead.id)

	# ambiguous records an older save may hold, written by hand into a copy of it
	var by := {}
	for nd in d1.npcs:
		by[int(nd.id)] = nd
	hs[10].members.append(999999)                       # an id no villager has
	hs[11].members.append(23)                           # a dead person (Oakley's) listed in a second household
	by[46].household = -1                               # a living person of household 10 with no household on record
	(hs[11].members as Array).erase(50.0)
	(hs[11].members as Array).erase(50)
	hs[12].members.append(50)                           # 50 says household 11, which does not list them; 12 lists them
	hs[lore].members.append(54)                         # an ended household lists household 12's 54
	(hs[13].members as Array).erase(58.0)
	(hs[13].members as Array).erase(58)                 # 58 (household 13) listed nowhere
	var t1 := JSON.stringify(d1, "", true, true)

	var w2 := World.new()
	w2.load_dict(map, JSON.parse_string(t1))
	check(w2.load_error == "", "the old save loads (%s)" % w2.load_error)
	var h2: Array = w2.households
	# 3 phantoms removed
	check(_count(h2[band].members, lead.id) == 0 and _count(h2[brook].members, lead.id) == 1, "the band adult who left is no longer listed in the band household (as p:142), only in their own")
	check(_count(h2[orph].members, 26) == 0 and _count(h2[orph].members, 27) == 0, "the placed orphans are no longer listed in their old household")
	for id in kids:
		var hk: int = w2.npc(id).household
		check(hk == int(kid_h[id]) and _count(h2[hk].members, id) == 1, "orphan %d is listed once, in the household that took them (%d)" % [id, hk])
	check(_count(h2[marsh].members, 33) == 0 and _count(h2[marsh + 1].members, 33) == 1, "the moved villager is listed only in their new household")
	check(_count(h2[marsh].members, 36) == 1, "a duplicate entry is kept once")
	check(_count(h2[13].members, 58) == 1, "a living villager listed nowhere is put back in their own household")
	# 4 legitimate entries kept
	check(_count(h2[marsh].members, 37) == 1, "a dead member stays in their own household")
	check(_count(h2[orph].members, 23) == 1 and _count(h2[orph].members, 24) == 1 and _count(h2[orph].members, 25) == 1, "the orphans' dead parents stay in their household")
	var bandits_ok := true
	for m in hs[band].members:
		if int(m) != lead.id and _count(h2[band].members, int(m)) != 1:
			bandits_ok = false
	check(bandits_ok, "the band household's other members are kept")
	# 5 ambiguous entries kept and flagged
	var rep: Dictionary = _report(w2)
	check(_count(h2[10].members, 999999) == 1 and _has_entry(rep, "flagged", "unknown_id", 10, 999999), "an unknown id is kept and flagged")
	check(_count(h2[11].members, 23) == 1 and _count(h2[orph].members, 23) == 1 and _has_entry(rep, "flagged", "dead_elsewhere", 11, 23), "a dead person listed in a second household is kept and flagged")
	check(_count(h2[10].members, 46) == 1 and w2.npc(46).household == -1 and _has_entry(rep, "flagged", "no_household", 10, 46), "a living person with no household on record is kept and flagged")
	check(_count(h2[12].members, 50) == 1 and _count(h2[11].members, 50) == 0 and _has_entry(rep, "flagged", "conflict", 12, 50) and _has_entry(rep, "flagged", "unlisted", 11, 50),
			"conflicting records (50 says 11, only 12 lists them) are kept and flagged")
	check(_count(h2[lore].members, 54) == 1 and _count(h2[12].members, 54) == 1 and _has_entry(rep, "flagged", "ended_household", lore, 54), "an ended household listing another's member is kept and flagged")
	check(_has_entry(rep, "repaired", "phantom", band, lead.id) and _has_entry(rep, "repaired", "phantom", orph, 26) and _has_entry(rep, "repaired", "phantom", orph, 27)
			and _has_entry(rep, "repaired", "phantom", marsh, 33) and _has_entry(rep, "repaired", "duplicate", marsh, 36) and _has_entry(rep, "repaired", "missing", 13, 58),
			"every repair is in the report")
	check((rep.get("repaired", []) as Array).size() == 6 and (rep.get("flagged", []) as Array).size() == 6,
			"6 repaired and 6 flagged (%d, %d)" % [(rep.get("repaired", []) as Array).size(), (rep.get("flagged", []) as Array).size()])
	# every other living villager is listed once, in their own household only
	var flagged_ids := {46: true, 50: true, 54: true}
	var bad := []
	for o: NPC in w2.npcs:
		if not o.alive or flagged_ids.has(o.id) or o.household < 0:
			continue
		for i in h2.size():
			if _count(h2[i].members, o.id) != (1 if i == o.household else 0):
				bad.append(o.id)
	check(bad.is_empty(), "every other living villager is listed once, in their own household only (%s)" % [bad])
	# 6 no re-placement
	check(Guardianship.orphans(w2, orph).is_empty(), "the orphans' old household offers no orphans to place again")
	# 7 coins and items
	check(w2.total_coins() == coins0, "coins unchanged (%d -> %d)" % [coins0, w2.total_coins()])
	check(_items(w2) == items0, "items unchanged (%d -> %d)" % [items0, _items(w2)])
	# 8 idempotent
	var s2 := JSON.stringify(w2.to_dict(), "", true, true)
	var w3 := World.new()
	w3.load_dict(map, JSON.parse_string(s2))
	var s3 := JSON.stringify(w3.to_dict(), "", true, true)
	check(s2 == s3, "save -> load -> save is identical after the repair")
	check(float(w2.stats.get("household_members_repaired", 0.0)) == 6.0 and float(w3.stats.get("household_members_repaired", 0.0)) == 0.0
			and float(w3.stats.get("household_members_flagged", 0.0)) == 0.0,
			"the first load counts 6 repairs, the second load repairs and flags nothing (%s, %s)" % [w2.stats.get("household_members_repaired", 0.0), w3.stats.get("household_members_repaired", 0.0)])
	check(JSON.stringify(_report(w3)) == JSON.stringify(_report(w2)), "the second load flags nothing new")
	# 9 deterministic
	var w4 := World.new()
	w4.load_dict(map, JSON.parse_string(t1))
	check(JSON.stringify(w4.to_dict(), "", true, true) == s2, "two loads of the same old save agree")
	for x in [w, w1, w2, w3, w4]:
		x.dispose()
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)
