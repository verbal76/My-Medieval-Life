extends SceneTree
## WR-01: protected wildlife breeding refuges, offspring cohorts and dispersal (Refuges, balance.json "refuges").
## Run: godot --headless --path game --script res://tests/refuge_test.gd
## The refuge stock is out of everyone's reach; young leave only in season and below capacity, as juveniles, and
## spread out; an overhunted wood stays empty for a while and is then recolonized gradually; saving and loading
## neither duplicates animals nor resets timers; an older save gains its refuges once; the same seed gives the
## same result.

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   ", what)
	else:
		failures += 1
		print("FAIL ", what)


func new_world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.player.pos = Vector2(60, 45)           # away from the woods: everything there runs off-screen
	return w


func _init() -> void:
	test_refuges_exist()
	test_out_of_reach()
	test_season_and_capacity()
	test_dispersal()
	test_migration()
	test_overhunt_and_recolonize()
	test_save_round_trip()
	test_old_save()
	test_determinism()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## What a save file gives back: the game writes JSON at full precision (main.gd save_game).
func _saved(d: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(d, "", true, true))


func _of(w: World, species: String, area := "") -> Array:
	return w.fauna.animals.filter(func(a): return a.alive and a.species == species and (area == "" or a.area == area))


## The animals alone, an hour a step, dawn at 06:00 (the fauna's own rules, without the villagers; fast).
func _run_days(w: World, days: int) -> void:
	for d in days:
		for h in 24:
			w.minutes += 60.0
			w.fauna.update(30.0)
			if int(w.minutes / 60.0) % 24 == 6:
				w.fauna.new_day()


## The game minute of the next dawn (06:00) that falls in `season`.
func _dawn_in(w: World, season: String) -> float:
	var t := floorf(w.minutes / World.DAY) * World.DAY + 360.0
	while t <= w.minutes or Life.season(t) != season:
		t += World.DAY
	return t


## Removes every animal of `species` in a wood (and, with `predators`, the wood's hunters too).
func _clear(w: World, area: String, kinds: Array) -> void:
	for a: Animal in w.fauna.animals.duplicate():
		if a.area == area and kinds.has(a.species):
			w.fauna.remove(a)


func test_refuges_exist() -> void:
	var w := new_world()
	var rs: Array = w.fauna.refuges.list
	var expect := 0
	for area in w.fauna.woods:
		for k in w.fauna.wild_species():
			if Refuges.lives_in(k, area):
				expect += 1
	check(rs.size() == expect and expect == 13, "a refuge per wood and wild species (%d)" % rs.size())
	var sites := {}
	for r in rs:
		sites[r.species] = r.site
		check(w.fauna.cells(r.area).has(Vector2i(int(r.x), int(r.y))), "%s lies in its wood" % r.id)
	check(sites.wolf == "den" and sites.bear == "cave" and sites.rabbit == "burrow" and sites.boar == "concealed shelter"
		and sites.deer == "sheltered habitat" and sites.bird == "nesting area" and sites.fox == "earth", "species-appropriate refuges %s" % [sites])
	check(not rs.any(func(r): return r.species == "bear" and r.area == "woods_e"), "no bear refuge where bears do not live")
	var wiki := Wiki.build()
	var text: String = wiki.pages["animal:rabbit"].text
	check(text.contains("breeding refuge") and text.contains("burrow") and text.contains("spring, summer and autumn") and text.contains("once every 3 days")
			and text.contains("fewer than 8 (50% of the 16"),
		"the wiki's rabbit page describes its refuge with the real numbers")
	check(not str(wiki.pages["animal:cow"].text).contains("breeding refuge"), "livestock have no refuge")


## The stock is a count: no Animal stands for it, so no strike, hunter, poacher or predator can reach it, and
## emptying the wood around it leaves it whole.
func test_out_of_reach() -> void:
	var w := new_world()
	var r: Dictionary = w.fauna.refuges.by_id("refuge_woods_e_deer")
	var at := Vector2(int(r.x), int(r.y)) + Vector2(0.5, 0.5)
	for a: Animal in _of(w, "deer", "woods_e"):
		w.fauna.kill(a)                         # the player overhunts the wood
	check(_of(w, "deer", "woods_e").is_empty(), "the player can kill every deer in a wood")
	var hit = Combat.target(w, at, Vector2.RIGHT)
	check(not (hit is Animal and hit.species == "deer"), "a blow at the refuge finds no deer")
	check(w.fauna.near(at, 6.0).filter(func(a): return a.species == "deer").is_empty(), "nothing near the refuge to strike with an area attack")
	var g: Animal = w.fauna.nearest_game(at, 999.0)
	check(g == null or g.area != "woods_e" or g.species != "deer", "the hunter finds no deer there")
	for a: Animal in _of(w, "wolf", "woods_e"):
		a.hunger = 0.0
	var before := int(r.stock)
	_run_days(w, 3)
	check(int(r.stock) == before and before == 2, "the refuge's breeding pair is untouched by hunting and predation (%d)" % int(r.stock))


func test_season_and_capacity() -> void:
	var w := new_world()
	var rf: Refuges = w.fauna.refuges
	var r: Dictionary = rf.by_id("refuge_woods_e_boar")
	_clear(w, "woods_e", ["boar", "wolf", "fox"])
	_clear(w, "woods_w", ["boar"])
	# out of season: nothing, and the timer waits
	w.minutes = _dawn_in(w, "Winter")
	r.next_birth = w.minutes - 10.0
	rf.new_day()
	check(r.cohort.is_empty() and float(r.next_birth) == w.minutes - 10.0, "no young out of season; the timer is not reset")
	# a wood at capacity: nothing
	w.minutes = _dawn_in(w, "Spring")
	for i in w.fauna.cap("woods_e", "boar"):
		w.fauna.spawn("woods_e", "boar", "m" if i % 2 == 0 else "f", null)
	for i in w.fauna.cap("woods_w", "boar"):
		w.fauna.spawn("woods_w", "boar", "m" if i % 2 == 0 else "f", null)
	rf.new_day()
	check(r.cohort.is_empty(), "no young while the woods are at capacity")
	# in season, an empty wood: a litter is born inside, and leaves only when juvenile
	_clear(w, "woods_e", ["boar"])
	rf.new_day()
	var litter := int(GameData.b("animals").boar.litter)
	check(int(r.cohort.get("n", 0)) == litter, "in season, below capacity: a litter of %d in the refuge" % litter)
	check(float(r.next_birth) == w.minutes + float(Refuges.spec("boar").interval_days) * World.DAY, "the next litter waits the reproductive interval")
	check(_of(w, "boar", "woods_e").is_empty(), "newborns stay in the refuge")
	_clear(w, "woods_w", ["boar"])
	var born_before := int(w.stats.get("born_boar", 0))
	w.minutes += World.DAY
	rf.new_day()
	var young := _of(w, "boar", "woods_e")
	check(young.size() == litter and young.all(func(a): return a.stage(w.minutes) == "juvenile" and a.origin == r.id),
		"a day later they leave as juveniles (%s)" % [young.map(func(a): return a.stage(w.minutes))])
	check(int(w.stats.get("born_boar", 0)) - born_before == _of(w, "boar").size(), "each young that leaves a refuge is counted as born for the ledger")
	check(r.cohort.is_empty(), "the refuge's cohort is gone out")
	# releases stay under release_below of the cap: never instant abundance
	var limit := floori(float(w.fauna.cap("woods_e", "boar")) * float(Refuges.cfg().release_below))
	for i in 40:
		w.minutes += World.DAY
		rf.new_day()
	var most := maxi(_of(w, "boar", "woods_e").size(), _of(w, "boar", "woods_w").size())
	check(most <= limit + litter and most >= limit, "refuges fill a wood only to about %d of a cap of %d, then stop (%d and %d boar)"
		% [limit, w.fauna.cap("woods_e", "boar"), _of(w, "boar", "woods_e").size(), _of(w, "boar", "woods_w").size()])


func test_dispersal() -> void:
	var w := new_world()
	var rf: Refuges = w.fauna.refuges
	var r: Dictionary = rf.by_id("refuge_woods_w_rabbit")
	_clear(w, "woods_w", ["rabbit", "wolf", "fox", "bear"])
	r.stock = 6                                 # three breeding pairs: a cohort of six, to see them spread
	w.minutes = _dawn_in(w, "Spring")
	r.next_birth = 0.0
	rf.new_day()
	var n := int(r.cohort.get("n", 0))
	w.minutes += World.DAY
	rf.new_day()
	var young := _of(w, "rabbit", "woods_w")
	var entrance := Vector2(int(r.x), int(r.y)) + Vector2(0.5, 0.5)
	check(n == 6 and young.size() == 6, "six young leave the burrow (%d)" % young.size())
	check(young.all(func(a): return a.pos.distance_to(entrance) < 1.0 and a.dest != Vector2.INF), "they come out at the entrance, each with a place to settle")
	var s := Refuges.spec("rabbit")
	var dests := young.map(func(a): return a.dest)
	var apart := true
	for i in dests.size():
		for j in range(i + 1, dests.size()):
			if (dests[i] as Vector2).distance_to(dests[j]) < 1.0:
				apart = false
	check(apart, "littermates choose different places")
	var dirs := {}
	for d: Vector2 in dests:
		var v := d - entrance
		dirs[Vector2i(signi(roundi(v.x)), signi(roundi(v.y)))] = true
	check(dirs.size() >= 2, "in more than one direction (%d)" % dirs.size())
	_run_days(w, 1)
	var settled := young.filter(func(a): return a.alive and a.dest == Vector2.INF)
	check(settled.size() == young.size(), "within a day all have settled (%d of %d)" % [settled.size(), young.size()])
	var far := young.filter(func(a): return a.pos.distance_to(entrance) >= float(s.disperse[0]) - 1.0 and a.pos.distance_to(entrance) <= float(s.disperse[1]) + 1.0)
	check(far.size() >= 5, "away from the entrance, within the rabbit's dispersal range %s (%s)" % [s.disperse, young.map(func(a): return snappedf(a.pos.distance_to(entrance), 0.1))])
	var spread := 0.0
	for a: Animal in young:
		for b: Animal in young:
			spread = maxf(spread, a.pos.distance_to(b.pos))
	check(spread >= 6.0, "spread over the wood (%.1f tiles between the farthest)" % spread)


## The own wood is fuller than another wood: the young go there, travelling unseen, and enter from its edge.
func test_migration() -> void:
	var w := new_world()
	var rf: Refuges = w.fauna.refuges
	GameData.balance.refuges.transit_loss = 0.0
	var r: Dictionary = rf.by_id("refuge_woods_w_deer")
	_clear(w, "woods_e", ["deer", "wolf", "bear"])
	_clear(w, "woods_w", ["deer"])
	for i in 3:
		w.fauna.spawn("woods_w", "deer", "m" if i == 0 else "f", null)
	w.minutes = _dawn_in(w, "Spring")
	r.next_birth = 0.0
	rf.new_day()
	w.minutes += World.DAY
	var before := int(w.stats.get("born_deer", 0))
	rf.new_day()
	check(rf.migrants.size() == 1 and rf.migrants[0].to == "woods_e", "a fawn sets off for the emptier east wood")
	check(int(w.stats.get("born_deer", 0)) == before and _of(w, "deer", "woods_e").is_empty(), "on the way it is in no wood and not yet counted")
	_run_days(w, 1)
	var there := _of(w, "deer", "woods_e")
	check(rf.migrants.is_empty() and there.size() == 1 and there[0].origin == r.id, "it arrives in the east wood")
	check(int(w.stats.get("migrated_deer", 0)) == 1 and int(w.stats.get("born_deer", 0)) == before + 1, "counted once, on arrival")
	GameData.balance.refuges.transit_loss = 0.1


## The player empties a wood of deer: it stays empty until the refuge's young come, and then fills only gradually.
func test_overhunt_and_recolonize() -> void:
	var w := new_world()
	_clear(w, "woods_e", ["wolf", "fox"])      # no predators there, so the counting is the refuge's alone
	for a: Animal in _of(w, "deer", "woods_e"):
		w.fauna.kill(a)
	var r: Dictionary = w.fauna.refuges.by_id("refuge_woods_e_deer")
	r.next_birth = w.minutes + 3.0 * World.DAY  # the refuge has just had young
	var empty_days := 0
	var first := -1
	var counts := []
	for d in 24:
		_run_days(w, 1)
		var n := _of(w, "deer", "woods_e").size()
		counts.append(n)
		if n == 0:
			empty_days += 1
		elif first < 0:
			first = d + 1
	print("  east wood deer by day: ", counts)
	check(counts[0] == 0 and empty_days >= 2, "the overhunted wood stays without deer for a while (%d days)" % empty_days)
	check(first > 0, "then young deer from the refuge recolonize it (day %d)" % first)
	check(counts[first - 1] <= int(GameData.b("animals").deer.litter) * 2, "gradually: %d at first" % [counts[first - 1]])
	check(int(r.stock) == 2, "the refuge keeps its breeding pair")


## Saving and loading keep every refuge, cohort, timer, dispersing animal and migrant exactly once.
func test_save_round_trip() -> void:
	var w := new_world()
	var rf: Refuges = w.fauna.refuges
	_clear(w, "woods_e", ["rabbit"])
	_clear(w, "woods_w", ["rabbit"])
	var r: Dictionary = rf.by_id("refuge_woods_e_rabbit")
	w.minutes = _dawn_in(w, "Spring")
	r.next_birth = 0.0
	rf.new_day()                                # a cohort inside
	var wolf_r: Dictionary = rf.by_id("refuge_woods_w_deer")
	rf.migrants.append({"species": "deer", "sex": "f", "born": w.minutes - 1440.0, "from": wolf_r.id, "to": "woods_e", "x": 66, "y": 5, "arrive": w.minutes + 500.0})
	var disp: Animal = _of(w, "boar", "woods_w")[0]
	disp.dest = Vector2(10.5, 10.5)
	disp.settle_by = w.minutes + 999.0
	disp.origin = "refuge_woods_w_boar"
	var d := w.to_dict()
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), _saved(d))
	var rf2: Refuges = w2.fauna.refuges
	check(rf2.list.size() == rf.list.size(), "the same refuges after loading (%d)" % rf2.list.size())
	var same := true
	for i in rf.list.size():
		var a: Dictionary = rf.list[i]
		var b: Dictionary = rf2.list[i]
		if a.id != b.id or float(a.next_birth) != float(b.next_birth) or int(a.stock) != int(b.stock) or a.x != b.x or a.y != b.y \
				or a.cohort.size() != b.cohort.size() or (not a.cohort.is_empty() and (int(a.cohort.n) != int(b.cohort.n) or float(a.cohort.born) != float(b.cohort.born))):
			same = false
	check(same, "identity, place, stock, cohorts and breeding timers are kept exactly")
	check(rf2.migrants.size() == 1 and float(rf2.migrants[0].arrive) == w.minutes + 500.0, "a migrant on its way is kept, arrival time and all")
	check(w2.fauna.animals.size() == w.fauna.animals.size(), "no animal duplicated or lost (%d = %d)" % [w2.fauna.animals.size(), w.fauna.animals.size()])
	var d2: Animal = w2.fauna.by_id(disp.id)
	check(d2 != null and d2.dest == disp.dest and d2.settle_by == disp.settle_by and d2.origin == disp.origin, "a dispersing animal keeps its destination")
	# loading twice in a row adds nothing either
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), _saved(w2.to_dict()))
	check(w3.fauna.refuges.list.size() == rf.list.size() and w3.fauna.animals.size() == w.fauna.animals.size() and w3.fauna.refuges.migrants.size() == 1,
		"saved and loaded again: still no duplicates")
	# the cohort comes out once, after loading, as it would have
	w3.minutes = w.minutes + World.DAY
	w3.fauna.refuges.new_day()
	var out := _of(w3, "rabbit")
	check(out.size() == int(r.cohort.n) and w3.fauna.refuges.by_id(r.id).cohort.is_empty(), "the loaded cohort leaves once (%d young)" % out.size())


## A save from before the refuges (Build 13/14: no "refuges" in its fauna block, animals without dest/origin).
func test_old_save() -> void:
	var w := new_world()
	var d := w.to_dict()
	d.fauna.erase("refuges")
	for ad in d.fauna.animals:
		ad.erase("dest")
		ad.erase("settle_by")
		ad.erase("origin")
	var n_animals := (d.fauna.animals as Array).size()
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), _saved(d))
	check(w2.fauna.refuges.list.size() == 13, "an older save gains its refuges on loading (%d)" % w2.fauna.refuges.list.size())
	check(w2.fauna.animals.size() == n_animals, "and its animals are unchanged (%d)" % w2.fauna.animals.size())
	var timers := w2.fauna.refuges.list.map(func(r): return float(r.next_birth))
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), _saved(w2.to_dict()))
	check(w3.fauna.refuges.list.size() == 13 and w3.fauna.refuges.list.map(func(r): return float(r.next_birth)) == timers,
		"once: saved and loaded again it has the same refuges and timers")


func test_determinism() -> void:
	var a := new_world()
	var b := new_world()
	_run_days(a, 30)
	_run_days(b, 30)
	check(JSON.stringify(a.fauna.to_dict()) == JSON.stringify(b.fauna.to_dict()), "the same seed gives the same woods and refuges after 30 days")
	var counts := {}
	for k in a.fauna.wild_species():
		counts[k] = _of(a, k).size()
	print("  30 days, animals alone: ", counts, " refuge young out ", a.fauna.wild_species().map(func(k): return int(a.stats.get("refuge_released_" + k, 0))))
