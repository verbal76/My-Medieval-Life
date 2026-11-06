extends SceneTree
## B25R2 (owner directive 2026-11-06, completion: "save/reload integrity"): the 365-day campaign on F2 (run 42154260748) found its
## segment saves did not load back exactly. Two causes were genuine defects, fixed here; this test reproduces each and checks the
## world's save, loaded into a fresh world and saved again, is the same.
##  1. Trees: a cleared tree has no "born" (clearing erases it, nothing grows there), but the load gave one to every tree that was
##     not a stump (World.load_dict), so cleared ground came back with a birth time (seed 2, days 0-100: three orchard trees).
##  2. Couriers: a shop booth opened at the first stall its keeper was found at and was linked to the last (CourierService.
##     open_shop_booth); a load seats every booth at its stall (seat_at_desks), so it moved (seed 1, days 100-300: one booth,
##     47 -> 52). Booths are now seated by that one rule when a shop booth opens and each day.
##  3. Carts: villagers let go of the carts they pull on load (KI-FR-CARTHITCH, decision 2026-11-02: their plans are not saved);
##     an intended difference, checked to be the only one in the carts section.
##   godot --headless --path game -s res://tests/save_exact_test.gd

var checks := 0
var failures := 0


func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("ok   " if ok else "FAIL ") + what)


func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var gmps := float(GameData.b("game_minutes_per_second"))
	for i in int(1440.0 / gmps / 0.5) * 2:              # two days: the village courier booth is open
		w.update(0.5)
	# 1. a village tree felled and its stump dug out, as Farming.clear_tree leaves it
	var cleared := {}
	for t in w.trees:
		if str(t.state) == "grown" and not t.get("ow", false):
			w.fell(t, 0)
			t.state = "cleared"
			w.map.set_solid(Vector2i(int(t.x), int(t.y)), false)
			cleared = t
			break
	check(not cleared.is_empty() and not cleared.has("born"), "a cleared tree has no birth time")
	# 2. a merchant holding two market stalls opens a booth of their own
	var cs: CourierService = w.couriers
	check(not cs.booth_of(SettlementFacts.VILLAGE).is_empty(), "the village courier booth is open")
	var merchant: NPC = null
	for n: NPC in w.npcs:
		if n.alive and cs.is_business("npc:%d" % n.id) and cs.booth_of_keeper("npc:%d" % n.id).is_empty() \
				and not w.stalls.values().any(func(s): return str(s.get("tenant", "")) in ["npc:%d" % n.id, str(n.id)]):
			merchant = n
			break
	check(merchant != null, "a merchant with no stall and no booth")
	if merchant == null:
		_end()
		return
	var held := []
	for sid in ["stall2", "stall3"]:
		if w.stalls.has(sid):
			w.stalls[sid].tenant = "npc:%d" % merchant.id
			held.append(sid)
	check(held.size() == 2, "the merchant holds two stalls (%s)" % str(held))
	var why := cs.open_shop_booth("npc:%d" % merchant.id)
	var b := cs.booth_of_keeper("npc:%d" % merchant.id)
	check(why == "" and not b.is_empty(), "the merchant opens a booth (%s)" % why)
	check(_seated(cs), "the new booth stands where a load would seat it (%s, at %d,%d)" % [str(b.get("stall", "")), int(b.get("x", 0)), int(b.get("y", 0))])
	# the campaign's case: the keeper gives up the stalls later; the day's round seats the booth as a load would
	for sid in held:
		w.stalls[sid].tenant = ""
	check(not _seated(cs), "with the stalls given up a load would move the booth (the defect's condition)")
	cs.daily()
	check(_seated(cs), "after the day's round every booth stands where a load would seat it")
	# 3. a villager pulling a cart
	var pulled := 0
	for n: NPC in w.npcs:
		if n.alive and n.household >= 0 and w.carts.pulled_by("npc:%d" % n.id).is_empty():
			var c: Dictionary = w.carts.place(World.hh_ref(n.household), n.pos)
			c.puller = "npc:%d" % n.id                 # (as Carts.hitch leaves it, mid market run)
			pulled += 1
			break
	check(pulled == 1, "a villager pulls their household's cart")
	# the save, loaded into a fresh world and saved again
	var a = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(a)))
	var z = JSON.parse_string(JSON.stringify(w2.to_dict()))
	for k in ["trees", "couriers"]:
		check(JSON.stringify(a.get(k), "", true) == JSON.stringify(z.get(k), "", true), "the %s load back exactly" % k)
	var differ := []
	for k in a:
		if JSON.stringify(a[k], "", true) != JSON.stringify(z.get(k), "", true):
			differ.append(str(k))
	check(differ == ["carts"] if pulled > 0 else differ.is_empty(), "the only section that differs is the carts a villager let go of (%s)" % str(differ))
	if pulled > 0:
		for c in a.carts.carts:
			if str(c.puller).begins_with("npc:"):
				c.puller = ""
		check(JSON.stringify(a.carts, "", true) == JSON.stringify(z.carts, "", true), "and in the carts nothing but the villagers' hold differs")
	# 4. a homestead's water source chosen when its claim is marked, saved before its claimant arrives (365-day campaign on
	# 832f711, seed 2, days 200-300: Wilds.choose_water met the cell as the text "(x, y)" a JSON save makes of a Vector2i, a
	# script error, and the homestead got no water source)
	var acc := {"source": "well", "cell": Vector2i(17, 23), "distance": 2}
	for form in [["save form", Wilds.save_form(acc)], ["an older save's form", acc]]:
		var claim := {"id": "hs_test", "works": []}
		var back = JSON.parse_string(JSON.stringify({"pending_water": form[1]}))
		w2.wilds.choose_water(claim, back.pending_water)
		check(claim.has("water_src") and claim.water_src.cell == [17, 23] and str(claim.water_src.source) == "well",
				"a pending water source loaded from a save (%s) is recorded at its cell (%s)" % [form[0], str(claim.get("water_src", {}))])
	_end()


## Whether seating the booths again (the rule a load applies, CourierService.seat_at_desks) would move none of them.
func _seated(cs: CourierService) -> bool:
	var before := cs.booths.map(func(x): return Vector2i(int(x.x), int(x.y)))
	var saved := cs.booths.map(func(x): return [x.x, x.y])
	cs.seat_at_desks()
	var after := cs.booths.map(func(x): return Vector2i(int(x.x), int(x.y)))
	for i in cs.booths.size():
		cs.booths[i].x = saved[i][0]
		cs.booths[i].y = saved[i][1]
	return before == after


func _end() -> void:
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
