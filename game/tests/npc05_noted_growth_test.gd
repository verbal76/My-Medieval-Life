extends SceneTree
## NPC-05 (Build 25 audit, WP-1): NPCBrain.noted keeps every once-a-day note key ("no_work_<id>_<day>", "hungry_<id>_<day>",
## ...) and never prunes it, so it grows with the length of a world. This is a measurement: run the real World for DAYS game days
## at the economy run's step, record the key count and serialized size each day, split day-stamped keys from lasting ones, and
## extrapolate the growth to day 365. The checks guard the reading (growth is linear in days and stays small at day 365); they do
## not change the game.
##   godot --headless --path game --script res://tests/npc05_noted_growth_test.gd [-- --days 10]

const STEP := 0.5
const BOUND_365_BYTES := 16 * 1024 * 1024    # a guard far above the measured figure, not a target

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL: ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	GameData.ensure()
	var days := 6
	var args := OS.get_cmdline_user_args()
	var i := args.find("--days")
	if i >= 0 and i + 1 < args.size():
		days = int(args[i + 1])
	measure(days)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func split(noted: Dictionary, today: int) -> Array:
	var stamped := 0
	var stale := 0
	for k in noted:
		var parts := str(k).split("_")
		var last := parts[parts.size() - 1]
		if last.is_valid_int() and parts.size() >= 3:
			stamped += 1
			if int(last) < today:
				stale += 1
	return [stamped, stale]


func measure(days: int) -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var per_day := int(1440.0 / float(GameData.b("game_minutes_per_second")) / STEP)
	var counts := []
	var t0 := Time.get_ticks_msec()
	for d in days:
		for s in per_day:
			w.update(STEP)
		var n: Dictionary = w.brain.noted
		var sp := split(n, w.day())
		var bytes := var_to_bytes(n).size()
		counts.append([n.size(), bytes])
		print("day %d: %d keys (%d day-stamped, %d from earlier days), %d bytes serialized" % [w.day(), n.size(), sp[0], sp[1], bytes])
	print("measured %d days in %.1f s" % [days, (Time.get_ticks_msec() - t0) / 1000.0])
	check(counts.size() == days and days >= 3, "fixture: %d days measured" % days)
	if counts.size() < 3:
		return
	# growth per day over the measured days after the first (the first day sets up the lasting keys)
	var first: Array = counts[0]
	var last: Array = counts[counts.size() - 1]
	var span := counts.size() - 1
	var keys_per_day := float(last[0] - first[0]) / span
	var bytes_per_day := float(last[1] - first[1]) / span
	var keys_365 := int(first[0] + keys_per_day * 364)
	var bytes_365 := int(first[1] + bytes_per_day * 364)
	print("NPC-05 measurement: %.0f keys and %.0f bytes a day; extrapolated to day 365: %d keys, %.2f MB serialized" % [keys_per_day, bytes_per_day, keys_365, bytes_365 / 1048576.0])
	var monotone := true
	for j in range(1, counts.size()):
		if counts[j][0] < counts[j - 1][0]:
			monotone = false
	check(monotone, "noted is never pruned: the key count never falls (the audit's reading)")
	check(bytes_365 < BOUND_365_BYTES, "extrapolated to day 365 the notes stay under %d MB (%.2f MB)" % [BOUND_365_BYTES / 1048576, bytes_365 / 1048576.0])
