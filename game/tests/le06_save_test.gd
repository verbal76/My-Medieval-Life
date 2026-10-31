extends SceneTree
## Expansion 20 LE-06, the owner's first item (2026-10-30): the economy's save storage bounded without changing the intended
## knowledge and market behaviour. Knowledge is saved as rows over a string table (format 2; format 1 still loads) and entries
## are forgotten only past the age at which no decision can act on them (forget_unusable). Checks: lossless encoding, old format,
## the forgetting window is exactly the action threshold, what every decision reads is unchanged by forgetting, the record stays
## bounded over time, and a save/load continues identically (determinism) at several checkpoints.
## Run headless:  godot --headless --path game --script res://tests/le06_save_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func cfg(forget := true) -> Dictionary:
	var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy.json"))
	c.enabled = true
	c.knowledge.forget_unusable = forget
	return c


func new_world(forget := true, seed := 1) -> World:
	EconomyFoundation.set_override(cfg(forget))
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


func _init() -> void:
	test_encoding()
	test_window()
	test_decisions_unchanged()
	test_bounded()
	test_continuation()
	test_build24_save()
	EconomyFoundation.set_override({})
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func people(w: World) -> Array:
	var out := []
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult":
			out.append(World.npc_ref(n.id))
	return out


## Fill the record: every adult learns of a few others at several ages, firsthand and by word of mouth.
func fill(w: World, days := 20) -> void:
	var k := w.economy.knowledge
	var ps := people(w)
	var items := ["wheat", "plank", "log", "leather", "iron_bar"]
	for i in ps.size():
		for j in 6:
			var s: String = ps[(i * 7 + j * 13 + 1) % ps.size()]
			if s == ps[i]:
				continue
			var item: String = items[(i + j) % items.size()]
			var seen := maxi(0, w.day() - ((i * 3 + j * 5) % days))
			if j % 2 == 0:
				k.learn(ps[i], s, item, EconKnowledge.SELLS, 2 + (i + j) % 5, "in_person", -1, "", seen)
			else:
				k.learn(ps[i], s, item, EconKnowledge.BUYS, 3 + (i * j) % 4, "word_of_mouth", -1, "", seen, ps[(i + 2) % ps.size()])


func test_encoding() -> void:
	var w := new_world()
	w.minutes += World.DAY * 25
	fill(w)
	var k := w.economy.knowledge
	var d := k.to_dict()
	check(int(d.get("format", 0)) == 2 and d.has("rows") and d.has("strings") and not d.has("entries"), "saved as rows over a string table (format 2)")
	var k2 := EconKnowledge.new(k.actors, {})
	k2.load_dict(JSON.parse_string(JSON.stringify(d)))
	check(JSON.stringify(k2.entries) == JSON.stringify(k.entries) and k2.size() == k.size(), "lossless: every field of every entry comes back (%d entries)" % k.size())
	var ks: Array = k.entries.keys()
	ks.sort()
	var old := {"entries": ks.map(func(x): return k.entries[x].duplicate())}
	var k3 := EconKnowledge.new(k.actors, {})
	k3.load_dict(JSON.parse_string(JSON.stringify(old)))
	check(JSON.stringify(k3.entries) == JSON.stringify(k.entries), "an older save's format 1 (\"entries\") loads to the same record")
	var small := JSON.stringify(d).length()
	var big := JSON.stringify(old).length()
	check(small * 3 < big, "about a fifth of the bytes (%d vs %d)" % [small, big])


func test_window() -> void:
	var w := new_world()
	var k := w.economy.knowledge
	var floor_r := float(w.economy.market.p("min_reliability", 0.25))
	check(k.forget_after == int(floor(k.half_life_days * log(1.0 / floor_r) / log(2.0))) and k.forget_after == 14, "the window is the action threshold's own age (half life 7, threshold 0.25: 14 days)")
	w.minutes += World.DAY * 30
	var ps := people(w)
	for age in [13, 14, 15, 16]:
		k.learn(ps[0], ps[age % 5 + 1], "wheat", EconKnowledge.SELLS, 3, "dealing", -1, "", w.day() - age)
	var max_kept := 1.0
	for e in k.known_by(ps[0], "wheat"):
		if k.age(e) > k.forget_after:
			max_kept = minf(max_kept, k.reliability(e))
	check(max_kept < floor_r, "every entry past the window is below the threshold even with full trust (%.3f < %.2f)" % [max_kept, floor_r])
	var gone := k.forget_unusable(w.day())
	var ages: Array = k.known_by(ps[0], "wheat").map(func(e): return k.age(e))
	ages.sort()
	check(gone >= 2 and ages == [13, 14], "forgotten: ages 15 and 16; kept: 13 and 14 (still usable at exactly the threshold)")


## What believed() (asks, bids, floors), dialogues and speculation read is the same with and without forgetting.
func test_decisions_unchanged() -> void:
	var a := new_world(true)
	var b := new_world(false)
	for w in [a, b]:
		w.minutes += World.DAY * 25
		fill(w)
	a.economy.knowledge.forget_unusable(a.day())
	check(a.economy.knowledge.size() < b.economy.knowledge.size(), "forgetting dropped stale entries (%d vs %d)" % [a.economy.knowledge.size(), b.economy.knowledge.size()])
	var same := true
	for r in people(a):
		for item in ["wheat", "plank", "log", "leather", "iron_bar"]:
			if JSON.stringify(a.economy.market.believed(r, item)) != JSON.stringify(b.economy.market.believed(r, item)):
				same = false
	check(same, "every villager's believed price, sellers, buyers and best bid are identical with and without forgetting")
	var reliable := func(w: World) -> Array:
		var out := []
		for r in people(w):
			for e in w.economy.knowledge.known_by(r):
				if w.economy.knowledge.reliability(e) >= float(w.economy.market.p("min_reliability", 0.25)):
					out.append(EconKnowledge.key(e.knower, e.subject, e.item, e.side))
		out.sort()
		return out
	check(reliable.call(a) == reliable.call(b), "the entries any decision can act on are exactly the same")


func test_bounded() -> void:
	var w := new_world()
	var k := w.economy.knowledge
	var sizes := []
	for d in 60:
		w.minutes += World.DAY
		fill(w, 1)                      # fresh news every day: the unforgetting record would only grow with new pairs
		k.forget_unusable(w.day())
		if d % 15 == 14:
			sizes.append(k.size())
	check(sizes[sizes.size() - 1] <= sizes[1] + 5, "the record stays bounded over 60 days (%s)" % str(sizes))


## At several checkpoints of a market-driven world: the economy section comes back exactly after a load (lossless), and two worlds
## loaded from the same save run on identically, economy and whole world (deterministic replay). (The whole world is not identical
## to the never-saved one right after a load even with the economy off: a pre-existing property of World.load_dict, reported
## separately; the economy adds nothing to it.)
func test_continuation() -> void:
	var w := new_world()
	var step := 0.5
	var per_day := int(1440.0 / float(GameData.b("game_minutes_per_second")) / step)
	for cp in 3:
		for i in per_day / 3:
			w.update(step)
		var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
		var w2 := World.new()
		w2.load_dict(VillageMap.load_default(), d)
		var w3 := World.new()
		w3.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
		check(JSON.stringify(w2.economy.to_dict()) == JSON.stringify(w.economy.to_dict()), "checkpoint %d: the economy section loads exactly as saved" % (cp + 1))
		for i in per_day / 6:
			w2.update(step)
			w3.update(step)
		check(JSON.stringify(w2.to_dict()) == JSON.stringify(w3.to_dict()), "checkpoint %d: two worlds loaded from the save run on identically (economy and world)" % (cp + 1))
		w = w2


## A real Build 24 save (tests/fixtures/b24_save_v23_single.json, written by gen_b22_save_fixture.gd run unmodified in a checkout of
## 4611d86): it loads with the economy off as before, and with it on the economy starts empty, runs, saves and loads exactly.
func test_build24_save() -> void:
	var fx: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/b24_save_v23_single.json"))
	check(int(fx.save_version) == 23 and not fx.has("economy") and not fx.has("transactions"), "the Build 24 fixture: save version 23, no economy or transactions key")
	EconomyFoundation.set_override({})
	var off := World.new()
	off.load_dict(VillageMap.load_default(), fx.duplicate(true))
	check(off.economy == null and not off.to_dict().has("economy") and not off.to_dict().has("transactions"), "economy off: it loads and writes no new key")
	EconomyFoundation.set_override(cfg(true))
	var w := World.new()
	w.load_dict(VillageMap.load_default(), fx.duplicate(true))
	check(w.economy != null and w.economy.knowledge.is_empty() and w.transactions.is_empty(), "economy on: it loads with an empty economy")
	for i in 600:
		w.update(0.5)
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	check(w.economy.knowledge.size() > 0 and JSON.stringify(w2.economy.to_dict()) == JSON.stringify(w.economy.to_dict()), "it runs, and its economy saves and loads exactly (%d knowledge entries)" % w.economy.knowledge.size())
