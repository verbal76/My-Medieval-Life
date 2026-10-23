extends SceneTree
## P21-01 (Expansion 21, owner directive 2026-10-23, VP-01): the civic records. Records only, disabled by default, observing
## today's succession without changing it. Checks: stable office ids; disabled builds nothing and writes no key; the reeve's
## death closes the tenure with its cause and the existing succession opens the successor's, never two open; a guard who
## leaves or dies and the replacement; the legacy record survives death and a save/load; a dead holder's reference still
## resolves; an old save loads; the records change no coin and no good; larger-settlement timing.
##   godot --headless --path game --script res://tests/civic_records_test.gd

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


func _init() -> void:
	GameData.ensure()
	ids_are_stable()
	disabled_builds_nothing()
	reeve_succession()
	guards_leave_and_are_replaced()
	legacy_and_references()
	save_and_load()
	records_change_nothing()
	timing()
	CivicRecords.override = -1
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func new_world(civic: bool) -> World:
	CivicRecords.override = 1 if civic else 0
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


func skip_days(w: World, d: int) -> void:
	w.minutes += float(d) * 1440.0


func open_total(c: CivicRecords) -> int:
	return c._open.size()


## No office has two open tenures and no person holds two offices at once.
func one_open_each(c: CivicRecords) -> bool:
	var seen := {}
	var holders := {}
	for t in c.tenures:
		if int(t.to) < 0:
			if seen.has(t.office) or holders.has(t.holder):
				return false
			seen[t.office] = true
			holders[t.holder] = true
	return seen.size() == c._open.size()


func ids_are_stable() -> void:
	var ids := CivicOffices.offices().map(func(o): return o.id)
	check(ids.has("village/reeve") and ids.has("village/sage") and ids.has("village/guard/1"), "offices: village/reeve, village/guard/N, village/sage")
	check(ids.size() == 2 + int(Population.JOBS.guard) and ids.has("village/guard/%d" % int(Population.JOBS.guard)), "the guard posts follow Population.JOBS (%d)" % int(Population.JOBS.guard))
	check(CivicOffices.offices().map(func(o): return o.id) == ids and ids.size() == ids.duplicate().size(), "the same ids in the same order every time")
	var js := CivicOffices.jurisdictions().map(func(j): return j.id)
	check(js == ["village", "wulstead", "netherton", "garton", "higham", "bourton"], "jurisdictions: the village and the five settlements (%s)" % str(js))
	check(CivicOffices.jurisdictions()[1].government == "the mayor and council", "a settlement's government is named, nothing more")
	check(str(CivicOffices.office("village/reeve").authority).length() > 20 and not CivicOffices.office("village/reeve").has("powers"), "authority is descriptive text, with no powers")


func disabled_builds_nothing() -> void:
	var w := new_world(false)
	check(w.civic == null, "disabled: no civic records are built")
	check(not w.to_dict().has("civic"), "disabled: the save has no civic key")
	CivicRecords.override = -1
	check(not CivicRecords.enabled(), "the shipped switch (data/civic.json) is off")


func reeve_succession() -> void:
	var w := new_world(true)
	var c := w.civic
	var old := w.npc(w.reeve_id)
	check(c != null and c.holder_of("village/reeve") == World.npc_ref(old.id), "enabled: the reeve's tenure is seeded, observed from day %d" % w.day())
	check(bool(c.open_tenure_of("village/reeve").observed), "a seeded tenure is marked observed-from, not claimed from the start")
	skip_days(w, 3)
	var dday := w.day()
	w.kill(old, "fever")
	var t: Dictionary = c.tenures_of(World.npc_ref(old.id))[0]
	check(int(t.to) == dday and t.how == "death" and t.cause == "fever", "the reeve dies: the tenure closes with the day and cause")
	check(c.holder_of("village/reeve") == "", "the office is vacant until the existing succession fills it")
	var cand: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job == "":
			cand = o
			break
	if cand == null:
		for o: NPC in w.npcs:
			if o.alive and o.role == "adult" and o.job == "laborer":
				cand = o
				break
	cand.job = ""
	w.last_reeve_day = -1
	w.brain.reeve_day()
	check(c.holder_of("village/reeve") == "", "the office is open (a vacancy), no one holds it")
	skip_days(w, int(GameData.b("succession_days")))
	w.brain.succession_dawn()
	w.last_reeve_day = -1
	w.brain.reeve_day()
	var nr := w.npc(w.reeve_id)
	check(nr != old and c.holder_of("village/reeve") == World.npc_ref(nr.id), "the existing succession installs %s and their tenure opens" % nr.name)
	var ts := c.tenures_of_office("village/reeve")
	check(ts.size() == 2 and int(ts[1]["from"]) >= int(ts[0].to) and int(ts[1].to) == -1, "two tenures in order, the gap between them is the vacancy")
	check(one_open_each(c), "never two open tenures for one office")
	w.brain.reeve_day()
	w.brain._reeve_succession()
	check(c.tenures_of_office("village/reeve").size() == 2, "observing again opens no duplicate")
	check(c.audit().is_empty(), "the records agree with the world (%s)" % str(c.audit()))


func guards_leave_and_are_replaced() -> void:
	var w := new_world(true)
	var c := w.civic
	var guards := w.npcs.filter(func(n): return n.alive and n.job == "guard")
	check(guards.size() == int(Population.JOBS.guard) and open_total(c) == 2 + guards.size(), "all %d guards, the reeve and the sage hold seeded tenures" % guards.size())
	var g: NPC = guards[2]
	var slot := ""
	for t in c.tenures_of(World.npc_ref(g.id)):
		slot = t.office
	skip_days(w, 2)
	w.kill(g, "slain by a bandit")
	check(c.holder_of(slot) == "" and c.tenures_of(World.npc_ref(g.id))[0].cause == "slain by a bandit", "a guard falls: %s is vacant, the cause kept" % slot)
	# the watch is short: the treasury affords a post, an apprentice takes it
	w.treasury = 100000
	w.brain._guard_posts()
	check(w.brain.open_posts("guard") == 1, "the manor opens a guard's post")
	var cand: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job == "":
			cand = o
			break
	if cand == null:
		cand = w.npcs.filter(func(n): return n.alive and n.role == "adult" and n.job == "laborer")[0]
		cand.job = ""
	skip_days(w, int(GameData.b("succession_days")))
	w.brain.succession_dawn()
	var back := w.npcs.filter(func(n): return n.alive and n.job == "guard")
	check(back.size() == guards.size(), "the watch is back at strength")
	var nu := back.filter(func(n): return n.id != guards[0].id and not guards.has(n))
	check(nu.size() == 1 and c.holder_of(slot) == World.npc_ref(nu[0].id), "the replacement takes the vacant post %s" % slot)
	check(one_open_each(c) and c.audit().is_empty(), "one open tenure each, records agree with the world (%s)" % str(c.audit()))
	# one leaves the post for other work
	var h: NPC = guards[0]
	w.brain._post_left(h, "guard", "day")
	var ht := c.tenures_of(World.npc_ref(h.id))
	check(int(ht[0].to) >= 0 and ht[0].how == "left_post", "a guard who leaves the post: tenure closed 'left_post'")
	# a person leaves the village (migration): same path as a death, no death recorded
	var m: NPC = guards[1]
	c.on_departure(m, "wulstead")
	check(c.legacy[World.npc_ref(m.id)].end == "departure" and c.legacy[World.npc_ref(m.id)].destination == "wulstead" and c.tenures_of(World.npc_ref(m.id))[0].how == "migration", "a departure closes the tenure 'migration' and records where to, not a death")


func legacy_and_references() -> void:
	var w := new_world(true)
	var c := w.civic
	var rv := w.npc(w.reeve_id)
	var ref := World.npc_ref(rv.id)
	var family := rv.family
	var name := rv.name
	skip_days(w, 5)
	w.kill(rv, "")
	var l: Dictionary = c.legacy[ref]
	check(l.end == "death" and int(l.day) == w.day() and l.cause == "unknown", "legacy: death day, and cause 'unknown' when none was given")
	check(l.offices == ["village/reeve"], "legacy: offices held (%s)" % str(l.offices))
	check(l.trades.any(func(t): return t.job == "reeve"), "legacy: the trade held at death (%s)" % str(l.trades))
	check(not rv.memory.any(func(m): return "legacy" in str(m)) and w.log_lines.size() <= 300, "kept apart from NPC.memory and the 300-line log")
	check(c.label_of(ref) == "%s %s" % [name, family] and c.tenures_of(ref)[0].name == name and c.tenures_of(ref)[0].family == family, "a reference to the dead reeve still resolves to name and family")
	# a person removed from the world (the heir child) still resolves from the record
	w.npcs.erase(rv)
	w.by_id.erase(rv.id)
	check(c.label_of(ref) == "%s %s" % [name, family], "and still resolves if the person leaves World.npcs")
	var sage := w.npc(w.sage_id)
	w.kill(sage, "old age")
	check(c.legacy.has(World.npc_ref(sage.id)) and c.legacy.size() == 2, "records are never erased: two legacies")


func save_and_load() -> void:
	var w := new_world(true)
	var c := w.civic
	skip_days(w, 4)
	w.kill(w.npc(w.reeve_id), "fever")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	check(saved.has("civic") and saved.save_version == World.SAVE_VERSION and World.SAVE_VERSION == 19, "enabled: the save has the civic key; SAVE_VERSION is unchanged (19)")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), saved)
	var c2 := w2.civic
	check(c2 != null and JSON.stringify(c2.tenures) == JSON.stringify(c.tenures), "tenures round-trip exactly")
	check(JSON.stringify(c2.legacy) == JSON.stringify(c.legacy), "the legacy record survives death and save/load")
	check(c2.holder_of("village/reeve") == "" and c2.tenures_of_office("village/reeve").size() == 1, "the vacancy survives the load, no tenure invented")
	check(one_open_each(c2), "one open tenure each after loading")
	# an old save (no key) loads, and with the records on is seeded from that day
	var old: Dictionary = saved.duplicate(true)
	old.erase("civic")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), old)
	check(w3.civic != null and w3.civic.seeded_day == w3.day() and w3.civic.legacy.is_empty(), "an old save loads; the records begin there, observed from that day")
	CivicRecords.override = 0
	var w4 := World.new()
	w4.load_dict(VillageMap.load_default(), saved)
	check(w4.civic == null and w4.to_dict().has("civic") and JSON.stringify(w4.to_dict().civic) == JSON.stringify(saved.civic), "disabled again: nothing built, yet the saved records are kept unchanged, never erased")
	var w5 := World.new()
	w5.load_dict(VillageMap.load_default(), old)
	check(w5.civic == null and not w5.to_dict().has("civic"), "disabled with an old save: no key")


func records_change_nothing() -> void:
	var a := new_world(false)
	var b := new_world(true)
	check(a.total_coins() == b.total_coins() and JSON.stringify(Census.goods(a)) == JSON.stringify(Census.goods(b)) and a.rng.state == b.rng.state, "setup: same coins, goods and RNG state with the records on")
	for w in [a, b]:
		skip_days(w, 2)
		w.kill(w.npc(w.reeve_id), "fever")
		w.kill(w.npcs.filter(func(n): return n.alive and n.job == "guard")[0], "slain by a bandit")
		w.last_reeve_day = -1
		w.brain.reeve_day()
		w.brain._guard_posts()
	check(a.total_coins() == b.total_coins() and a.treasury == b.treasury and JSON.stringify(Census.goods(a)) == JSON.stringify(Census.goods(b)), "after deaths and succession: coins, treasury and goods identical (%d coins)" % b.total_coins())
	check(a.rng.state == b.rng.state and a.vacancies == b.vacancies, "no rng draw and the same vacancies")


## Larger settlement: 600 people through 6 guard slots and the reeve, thousands of events. The cost per event does not grow
## with the history (indexes, nothing scanned) and the world's update never calls the records.
func timing() -> void:
	var w := new_world(true)
	var c := w.civic
	for g: NPC in w.npcs.filter(func(n): return n.alive and n.job == "guard"):
		c.on_post_left(g, "guard")                       # the seeded watch steps down, so the slots are free for the cycle
	var t0 := Time.get_ticks_usec()
	var made: Array = []
	for i in 600:
		var n := NPC.new()
		n.id = 10000 + i
		n.name = "P%d" % i
		n.family = "F%d" % (i % 40)
		n.job = "guard"
		made.append(n)
	for round in 5:
		for n: NPC in made:
			c.on_installed(n, "guard")
			c.on_death(n, "fever") if round == 4 else c.on_post_left(n, "guard")
	var first := Time.get_ticks_usec() - t0
	var events := 600 * 5 * 2
	var t1 := Time.get_ticks_usec()
	for i in 600:
		c.on_installed(made[i], "guard")
		c.on_post_left(made[i], "guard")
	var late := float(Time.get_ticks_usec() - t1) / 1200.0
	var per := float(first) / float(events)
	print("timing: %d events on 600 people in %.1f ms (%.1f us each); %d tenures, then %.1f us each" % [events, first / 1000.0, per, c.tenures.size(), late])
	check(one_open_each(c) and c.unslotted == 0 and c.tenures.size() > 3000, "600 people, %d tenures, never two open" % c.tenures.size())
	check(late < 200.0 and first < 3_000_000, "event cost stays small as history grows (%.1f us per event on a long history)" % late)
	var src := FileAccess.get_file_as_string("res://scripts/core/world.gd")
	var upd := src.substr(src.find("func update("), 6000)
	check(not "civic" in upd, "World.update never touches the records")
