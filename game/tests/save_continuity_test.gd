extends SceneTree
## B25 save continuity (2026-11-01): what a save holds comes back exactly (every part of the economy simulation's fingerprint: time,
## treasury, coin sources, the random stream, granary, each villager's coins, position, hunger, job and pack, each animal, each
## deposit, each household's pantry), and the same save loaded twice goes on identically. A save is not a snapshot of movement in
## progress (an animal's or a villager's current heading, plan and path are not saved), so a loaded world does not go on exactly as
## the one that was never saved; it is deterministic from its save.
## Run: godot --headless --path game --script res://tests/save_continuity_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func parts(w: World) -> Dictionary:
	var d := {"minutes": str(w.minutes), "treasury": str(w.treasury), "coin_sources": str(w.coin_sources), "rng": str(w.rng.state), "granary": str(w.granary.items)}
	# TEST-AUDIT-01: the player too (before, "every part" left the player out: a save that loaded the player's coins wrong
	# passed here; mutation M2_save_coins)
	var p: PlayerState = w.player
	d["player"] = "%s|%d|%s|%s|%s|%s|%s" % [p.alive, p.coins, p.pos, p.hunger, p.stamina, p.inv.items, p.skills]
	for n: NPC in w.npcs:
		d["npc%d" % n.id] = "%s|%d|%s|%s|%s|%s" % [n.alive, n.coins, n.pos, n.hunger, n.job, n.inv.items]
	for a: Animal in w.fauna.animals:
		d["animal%d" % a.id] = "%s|%s" % [a.pos, a.hunger]
	for i in w.deposits.size():
		d["deposit%d" % i] = str(w.deposits[i].amount)
	for i in w.households.size():
		d["household%d" % i] = str(w.households[i].pantry.items)
	return d


func differing(a: Dictionary, b: Dictionary) -> Array:
	var out := []
	var keys := a.keys()
	keys.sort()
	for k in keys:
		if str(a[k]) != str(b.get(k, "<missing>")):
			out.append(k)
	for k in b:
		if not a.has(k):
			out.append(k)
	return out


func run_days(w: World, days: int) -> void:
	for m in 1440 * days:
		w.update(0.5)


func _init() -> void:
	var a := World.new()
	a.setup(VillageMap.load_default(), 1)
	run_days(a, 3)
	var b := World.new()
	b.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(a.to_dict())))
	var d0 := differing(parts(a), parts(b))
	check(d0.is_empty(), "right after loading, the world is the same in every part (%d differ: %s)" % [d0.size(), str(d0.slice(0, 6))])
	var inv := Inventory.new()
	inv.add("wheat", 2)
	inv.add("bread", 1)
	inv.add("apple", 3)
	var back := Inventory.from_dict(JSON.parse_string(JSON.stringify(inv.to_dict())))
	check(back.items.keys() == inv.items.keys() and back.items == inv.items, "a pack keeps its items in the order they were held")
	var old := Inventory.from_dict({"items": {"bread": 1, "apple": 3}})
	check(old.count("bread") == 1 and old.count("apple") == 3, "a pack saved before the order was kept still loads")
	var b2 := World.new()
	b2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(a.to_dict())))
	run_days(b, 3)
	run_days(b2, 3)
	var d1 := differing(parts(b), parts(b2))
	check(d1.is_empty(), "the same save loaded twice goes on identically for three days (%d differ: %s)" % [d1.size(), str(d1.slice(0, 6))])
	var od := a.to_dict()
	od.erase("rng_state")
	var c := World.new()
	c.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(od)))
	check(c.minutes == a.minutes and c.npcs.size() == a.npcs.size(), "a save without the random state still loads")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
