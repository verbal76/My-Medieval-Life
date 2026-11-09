extends SceneTree
## REC-D1..D4 (repair 2026-11-04, gate run 41770724025 det_s1): the flight recorder never changes the world, not even its derived
## hour caches. Found: seed 1 recorded and unrecorded parted on day 15, because NPCBrain._record_refused_buy (a recorder-only
## record of a refused purchase) read World.reserve_of and so filled its hour cache first; the game's own later reads in that
## hour got the earlier value. The same seed is run with and without the recorder, and every game hour the world and the hour
## caches (World._reserve_cache, World._price_cache) must be the same, key for key and value for value.
##   godot --headless --path game --script res://tests/recorder_neutrality_test.gd

const DAYS := 2

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


## economy_sim's fingerprint (PERF-03): every villager, animal, deposit and pantry, the clock, the treasury and the RNG state.
func _fingerprint(w: World) -> String:
	var parts := PackedStringArray([str(w.minutes), str(w.treasury), str(w.coin_sources), str(w.rng.state), str(w.granary.items)])
	for n: NPC in w.npcs:
		parts.append("%d|%s|%d|%s|%s|%s|%s" % [n.id, n.alive, n.coins, n.pos, n.hunger, n.job, n.inv.items])
	for a: Animal in w.fauna.animals:
		parts.append("%d|%s|%s" % [a.id, a.pos, a.hunger])
	for dp in w.deposits:
		parts.append(str(dp.amount))
	for hh in w.households:
		parts.append(str(hh.pantry.items))
	return "|".join(parts).md5_text()


func _caches(w: World) -> String:
	return JSON.stringify([w._reserve_cache, w._price_cache]).md5_text()


func _init() -> void:
	var dir := OS.get_user_data_dir().path_join("recorder_neutrality")
	var plain := World.new()
	plain.setup(VillageMap.load_default(), 1)
	var rec := World.new()
	rec.setup(VillageMap.load_default(), 1)
	WorldRecorder.attach(rec, {"root": dir})
	check(rec.recorder != null and plain.recorder == null, "one world records, the other does not")
	var steps := int(60.0 / (float(GameData.b("game_minutes_per_second")) * 0.5))
	var world_diff := -1
	var cache_diff := -1
	for hour in DAYS * 24:
		for i in steps:
			plain.update(0.5)
			rec.update(0.5)
		if world_diff < 0 and _fingerprint(plain) != _fingerprint(rec):
			world_diff = hour
		if cache_diff < 0 and _caches(plain) != _caches(rec):
			cache_diff = hour
	check(world_diff < 0, "the world is the same with and without the recorder, hour by hour for %d days (first difference: hour %d)" % [DAYS, world_diff])
	check(cache_diff < 0, "and so are the world's hour caches: the recorder's reads never fill them (first difference: hour %d)" % cache_diff)
	# the guard itself: an observer's read is worked out but not kept
	var n: NPC = plain.npcs[0]
	plain.minutes += 60.0 * 24.0 * 30.0                           # a game hour nobody has read yet
	var before := plain._reserve_cache.size()
	plain.observing += 1
	var r1 := plain.reserve_of(n)
	var u1: Array = plain.cheapest_food_unit()
	plain.observing -= 1
	check(plain._reserve_cache.size() == before and not plain._price_cache.has("unit@" + str(int(plain.minutes / 60.0))),
		"World.observing: a read while observing leaves the hour caches as they were")
	check(plain.reserve_of(n) == r1 and plain.cheapest_food_unit() == u1, "and gives the value the game's own read then gives")
	plain.dispose()
	rec.dispose()
	print("recorder_neutrality_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
