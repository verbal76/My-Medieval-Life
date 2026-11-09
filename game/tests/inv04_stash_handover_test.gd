extends SceneTree
## INV-04 (owner decision 2026-11-08, docs/directives/2026-11-09_overnight_autonomous_development.md): goods a player left in the
## containers of a building that passes to someone else go to that new holder (a household's pantry, the manor's granary),
## subject to tenant rights: they are never stranded out of reach, never lost and never doubled.
var checks := 0
var fails := 0


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		fails += 1


func all_of(w: World, id: String) -> int:
	var n: int = w.granary.count(id) + w.player.inv.count(id) + w.player.chest.count(id)
	for hh in w.households:
		n += (hh.pantry as Inventory).count(id)
	for k in w.chests.stash:
		n += (w.chests.stash[k] as Inventory).count(id)
	for l in w.loot:
		n += (l.inv as Inventory).count(id)
	for o: NPC in w.npcs:
		n += o.inv.count(id)
	return n


func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 8906)
	var me := w.acting_ref()
	# a house with chest spots that is not the player's home (its chests are a stash, not the family chest)
	var b: Dictionary = {}
	var hh := -1
	for o: NPC in w.npcs:
		if o.alive and o.household >= 0 and o.home != "" and w.buildings.has(o.home) and o.home != w.player.home \
				and not w.chests.units_in(o.home).is_empty() and w.owner_of(w.buildings[o.home]) == World.hh_ref(o.household):
			b = w.buildings[o.home]
			hh = o.household
			break
	check(not b.is_empty(), "fixture: a house with chests")
	var u: Dictionary = w.chests.units_in(str(b.id))[0]
	w.set_owner(b, me)
	var i: Dictionary = w.chests.info(u)
	check(str(i.access) == "own" and i.store != null and not bool(i.family), "the player now holds it: the chest is their own stash")
	var st: Inventory = i.store
	st.add("log", 7)
	st.add("bread", 3)
	var logs0 := all_of(w, "log")
	var bread0 := all_of(w, "bread")
	var pan: Inventory = w.households[hh].pantry
	var pl0 := pan.count("log")
	w.set_owner(b, World.hh_ref(hh))                  # the house passes to a household
	var j: Dictionary = w.chests.info(u)
	check(j.store == pan, "the chest now reads the household's own store")
	check(pan.count("log") >= pl0 + 7 or w.loot.size() > 0, "the 7 logs left in it went to the household (or to the ground if full)")
	check(not w.chests.stash.has(str(u.id)), "nothing is left stranded in the old stash")
	check(all_of(w, "log") == logs0 and all_of(w, "bread") == bread0, "no goods made or lost")
	# to the manor
	w.set_owner(b, me)
	var st2: Inventory = w.chests.info(u).store
	st2.add("log", 4)
	var g0 := w.granary.count("log")
	logs0 = all_of(w, "log")
	w.set_owner(b, World.MANOR)
	check(w.granary.count("log") == g0 + 4 and not w.chests.stash.has(str(u.id)), "sold back to the manor: the logs go to the granary")
	check(all_of(w, "log") == logs0, "no goods made or lost")
	# a tenant keeps the place: an owner's change does not empty a let house's containers
	w.set_owner(b, me)
	w.set_tenant(b, World.hh_ref(hh), 3)
	w.set_tenant(b, "")
	w.set_owner(b, me)
	var st3: Inventory = w.chests.info(u).store
	st3.add("log", 2)
	w.set_tenant(b, me, 0)
	w.set_owner(b, World.MANOR)                         # the player still holds it as tenant: the stash stays theirs
	check(w.chests.stash.has(str(u.id)) and (w.chests.stash[str(u.id)] as Inventory).count("log") == 2, "a change of owner under a tenant leaves the tenant's goods alone")
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)
