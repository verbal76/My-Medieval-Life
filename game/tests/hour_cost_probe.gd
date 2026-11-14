extends SceneTree
## B25-MOVE-STUTTER-INV probe (diagnostics only, changes nothing): the cost of each world tick (World.TICK, 0.5 s of play) over
## whole game days, the world alone (no scene, no drawing), seed 1, the player standing at the village. Every tick over SPIKE_MS
## is printed with its game time and the World.prof parts it spent most in (with the hourly parts: "hour: ..."), and a summary
## of the tick costs (p50/p90/p99/max) and of the costliest hours is printed at the end.
##   godot --headless --path game -s res://tests/hour_cost_probe.gd [-- days=2 seed=1]

const SPIKE_MS := 25.0


func _init() -> void:
	GameData.ensure()
	var days := 2
	var seed := 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("days="):
			days = int(a.substr(5))
		elif a.begins_with("seed="):
			seed = int(a.substr(5))
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	w.profiling = true
	var costs: Array = []
	var by_hour := {}
	var n := int(days * 24 * 60 / (World.TICK * float(GameData.b("game_minutes_per_second"))))
	for i in n:
		var p0: Dictionary = w.prof.duplicate(true)
		var m0 := w.minutes
		var t := Time.get_ticks_usec()
		w.update(World.TICK)
		var ms := (Time.get_ticks_usec() - t) / 1000.0
		costs.append(ms)
		var hh := int(m0 / 60.0 + 0.0001) % 24
		var hk := "%02d:00" % (int(w.minutes / 60.0) % 24) if int(w.minutes / 60.0) != int(m0 / 60.0) else ""
		if hk != "":
			by_hour[hk] = maxf(float(by_hour.get(hk, 0.0)), ms)
		if ms > SPIKE_MS:
			var top := []
			for k in w.prof:
				var us := int(w.prof[k].us) - int(p0.get(k, {}).get("us", 0))
				if us > 2000 and k != "hourly (incl. daily)":
					top.append([us / 1000.0, k])
			top.sort()
			top.reverse()
			print("TICK %.1f ms day %d %02d:%02d%s: %s" % [ms, w.day(), hh, int(m0) % 60, (" (hour " + hk + ")") if hk != "" else "",
					", ".join(top.slice(0, 7).map(func(e): return "%s %.1f" % [e[1], e[0]]))])
	for e in w.slow_npcs:
		print("SLOW villager %02d:%02d id %d %s %.0f ms (step before %s; now %s; travelling %s)" % [int(e[0] / 60.0) % 24, int(e[0]) % 60, e[1], e[2], e[3], e[4], e[5], str(e[6])])
	var s := costs.duplicate()
	s.sort()
	print("ticks %d: p50 %.2f p90 %.2f p99 %.2f max %.2f ms; first tick %.1f ms" % [s.size(), s[s.size() / 2], s[s.size() * 9 / 10],
			s[s.size() * 99 / 100], s[s.size() - 1], costs[0]])
	var hrs := by_hour.keys()
	hrs.sort()
	print("costliest tick at each hour change: %s" % ", ".join(hrs.map(func(k): return "%s %.0f" % [k, by_hour[k]])))
	quit(0)
