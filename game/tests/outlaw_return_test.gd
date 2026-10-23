extends SceneTree
## BANDIT-RETURN (owner, 2026-10-23): a season after the last bandit dies, 2 or 3 outlaws arrive and make camp;
## nothing arrives sooner or while a bandit lives; the arrivals are the same for a seed; the wait survives a save.
##   godot --headless --path game --script res://tests/outlaw_return_test.gd

const STEP := 0.5

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL: ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	GameData.ensure()
	var map := VillageMap.load_default()
	var a := _fresh(map, 3)
	var wait := Outlaws.wait_days()
	check(wait == ceili(Life.seasons_to_days(1.0)) and wait > 1, "the wait is one calendar season (%d days)" % wait)
	check(a.outlaw_gone_day == -1 and Outlaws.band_alive(a), "a new world has its band and no clock running")
	var band_ids := _bandits(a).map(func(n: NPC) -> int: return n.id)
	check(band_ids.size() == int(GameData.b("bandits")), "the original band is there")

	# the band is not replaced while any bandit lives
	for i in band_ids.size() - 1:
		a.kill(a.npc(band_ids[i]), "test")
	check(a.outlaw_gone_day == -1, "no clock while one bandit lives")
	a.minutes += float(wait * 3) * World.DAY
	check(Outlaws.dawn(a).is_empty() and _bandits(a).size() == 1, "nobody arrives while a bandit lives, however long")

	# the last one dies: the clock starts that day
	a.kill(a.npc(band_ids[band_ids.size() - 1]), "slain by test")
	var gone := a.day()
	check(a.outlaw_gone_day == gone and _bandits(a).is_empty(), "the last death starts the clock (day %d)" % gone)

	# less than a season: none
	a.minutes += float(wait - 1) * World.DAY
	check(Outlaws.dawn(a).is_empty() and _bandits(a).is_empty(), "nobody arrives before the season is out")

	# save and load across the waiting period
	var b := World.new()
	b.load_dict(map, JSON.parse_string(JSON.stringify(a.to_dict(), "", true, true)))
	check(b.outlaw_gone_day == gone, "the clock is saved and loaded")
	check(Outlaws.dawn(b).is_empty(), "still waiting after loading")
	b.minutes += World.DAY
	var came_b := Outlaws.dawn(b)
	check(came_b.size() >= 2 and came_b.size() <= 3, "a season after the last death, 2 or 3 arrive (%d)" % came_b.size())

	# the original world arrives the same way
	a.minutes += World.DAY
	var came := Outlaws.dawn(a)
	check(came.size() >= 2 and came.size() <= 3, "2 or 3 outlaws arrive (%d)" % came.size())
	var camp := Vector2(a.bandit_camp)
	var ok := true
	var ids := {}
	for n: NPC in a.npcs:
		ids[n.id] = int(ids.get(n.id, 0)) + 1
	for n: NPC in came:
		ok = ok and n.role == "bandit" and n.alive and n.sprite.contains("bandit_") and n.inv.count("copper_sword") == 1 and n.name != "" and ids[n.id] == 1 and a.by_id[n.id] == n
		ok = ok and Life.age_years(n.born, a.minutes) >= 20.0 and n.coins >= 5
	check(ok, "they are grown bandits with names, sprites, a sword, a coin purse and fresh ids")
	check(a.outlaw_gone_day == -1 and _bandits(a).size() == came.size(), "the clock stops: they are the band")
	check(a.coin_sources > 0 and a.stats.get("outlaw_coins_in", 0.0) > 0.0, "their purses are recorded as coming from outside")
	a.minutes += float(wait * 4) * World.DAY
	check(Outlaws.dawn(a).is_empty() and _bandits(a).size() == came.size(), "no more arrive while they live")

	# determinism: the same seed, the same newcomers
	check(came_b.size() == came.size(), "the same seed brings the same number (%d)" % came.size())
	var same := came_b.size() == came.size()
	for i in came.size():
		same = same and came[i].name == came_b[i].name and came[i].id == came_b[i].id and came[i].pos.is_equal_approx(came_b[i].pos) and is_equal_approx(came[i].born, came_b[i].born) and came[i].coins == came_b[i].coins
	check(same, "and the same names, ids, entry points, ages and purses")
	var c := _fresh(map, 3)
	c.minutes += float(gone) * World.DAY             # the draw is of the seed and the day the band ended
	_wipe(c)
	c.minutes += float(wait) * World.DAY
	var came_c := Outlaws.dawn(c)
	check(came_c.size() == came.size() and came_c[0].name == came[0].name, "a second world of the seed brings the same band")
	var diff := false
	for sd in [4, 5, 6, 7]:
		var e := _fresh(map, sd)
		_wipe(e)
		e.minutes += float(wait) * World.DAY
		var ce := Outlaws.dawn(e)
		diff = diff or ce.size() != came.size() or ce[0].name != came[0].name
	check(diff, "other seeds do not all bring the same band")

	# through the real daily tick (World._new_day -> Life.dawn)
	var f := _fresh(map, 3)
	f.minutes += 5.0 * World.DAY
	_wipe(f)
	f.outlaw_gone_day = f.day() - wait + 1
	check(_bandits(f).is_empty(), "(real tick) no band")
	var steps := int(2.2 * 1440.0 / float(GameData.b("game_minutes_per_second")) / STEP)
	for i in steps:
		f.update(STEP)
		f.player.hunger = 100.0
	var landed := _bandits(f)
	var arrived := int(f.stats.get("outlaws_arrived", 0))
	# the count that came is the rule; how many are alive two days on is the village's business (with judgment on, a family out
	# of doors shields itself and fetches a guard when a stranger comes near, and a guard may put one down)
	check(arrived >= 2 and arrived <= 3 and landed.size() <= arrived, "(real tick) outlaws arrive at the dawn after the season (%d came, %d alive)" % [arrived, landed.size()])
	var near := landed.filter(func(n: NPC) -> bool: return n.pos.distance_to(camp) < 40.0)
	check(not landed.is_empty(), "(real tick) they are in the world and heading for the camp (%d within 40 tiles)" % near.size())

	# an older save without the key: the clock starts on the load day
	var d: Dictionary = JSON.parse_string(JSON.stringify(_wiped_dict(map), "", true, true))
	d.erase("outlaw_gone_day")
	var g := World.new()
	g.load_dict(map, d)
	check(g.outlaw_gone_day == g.day(), "an older save with no bandits starts the clock on the load day")
	check(Outlaws.dawn(g).is_empty(), "and nobody arrives that day")

	print("outlaw_return_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _fresh(map: VillageMap, sd: int) -> World:
	var w := World.new()
	w.setup(map, sd)
	return w


func _bandits(w: World) -> Array:
	return w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "bandit")


func _wipe(w: World) -> void:
	for n: NPC in _bandits(w):
		w.kill(n, "test")


func _wiped_dict(map: VillageMap) -> Dictionary:
	var w := _fresh(map, 3)
	_wipe(w)
	return w.to_dict()
