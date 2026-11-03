extends SceneTree
## B25R1-018 (e), measurement only: what one full village NPC and one off-map settlement member cost on this machine, the data
## the population-architecture choice in docs/design/REGION_RECONSTRUCTION_B25R1.md section (e) rests on. Builds the real World
## for a seed, steps it as economy_sim does (0.5 s steps, one game minute each) for `--days` game days with World.profiling on,
## and prints: villagers alive, settlement members alive, the microseconds the villagers' update and the settlements' step took
## per game minute and per person, and the static memory the world took. Changes nothing; nothing saved.
##   godot --headless --path game --script res://tests/region_pop_probe.gd -- [--seed 1] [--days 2] [--far]
## --far moves the player out of the village (every villager in the abstract tier, as when the player is in another settlement).

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var seed := 1
	var days := 2
	for i in args.size():
		if args[i] == "--seed":
			seed = int(args[i + 1])
		elif args[i] == "--days":
			days = int(args[i + 1])
	var mem0 := Performance.get_monitor(Performance.MEMORY_STATIC)
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	var mem1 := Performance.get_monitor(Performance.MEMORY_STATIC)
	if "--far" in args:
		w.player.pos = Vector2(60, 45 + 20 * 12)
	w.profiling = true
	# warm up an hour so first-use caches are not counted
	for i in 60:
		w.update(0.5)
	w.prof.clear()
	var t0 := Time.get_ticks_usec()
	var steps := days * 24 * 60
	for i in steps:
		w.player.hunger = 100.0
		w.update(0.5)
	var wall := Time.get_ticks_usec() - t0
	var alive := 0
	for n: NPC in w.npcs:
		if n.alive:
			alive += 1
	var members := 0
	for s: OffMapSettlement in w.regions.list:
		for h in s.hh:
			if h.alive:
				members += (h.mem as Array).size()
	var vil: Dictionary = w.prof.get("villagers (all)", {"us": 0, "n": 1})
	var reg: Dictionary = w.prof.get("neighbouring settlements (a step an hour, mornings)", {"us": 0, "n": 1})
	var hourly: Dictionary = w.prof.get("hourly (incl. daily)", {"us": 0, "n": 1})
	var out := {"seed": seed, "days": days, "far": "--far" in args, "villagers": alive, "settlement_members": members,
		"wall_s": wall / 1e6, "us_per_game_minute_total": float(wall) / steps,
		"villagers_us_per_minute": float(vil.us) / steps, "villagers_us_per_npc_minute": float(vil.us) / steps / maxf(1, alive),
		"hourly_us_per_hour_incl_regions": float(hourly.us) / (days * 24),
		"regions_us_per_day": float(reg.us) / days, "regions_us_per_member_day": float(reg.us) / days / maxf(1, members),
		"mem_world_mb": (mem1 - mem0) / 1048576.0, "prof": w.prof}
	print("PROBE " + JSON.stringify(out))
	quit(0)
