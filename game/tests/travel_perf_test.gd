extends SceneTree
## B25R2 playtest repair (owner directive 2026-11-06, item 3, "Repeated long-distance travel stuttering"): a repeatable journey and
## its frame times. Seed 1, the player walks (at the game's walking speed) the planned route from the home village to the farthest
## settlement; each frame is the world's own update and the overworld chunks the view builds round the player (OverworldView.follow:
## a 5 x 5 chunk window, at most BUILD_PER_FRAME new chunks a frame, Overworld.get_chunk; on a frame with none, one chunk of the next
## ring prepared ahead in the direction of travel, OverworldView._prefetch). Mirrors the view's scheduling: keep the two in step. Every frame over SPIKE_MS is recorded with
## the game time, the player's cell and what happened on it: chunks generated, and whether one of the caches that empty themselves
## when full was emptied (Overworld._segments, _alive, _ford_ok; Countryside._chunks). Rendering is not here (headless): this is the
## game's own work. Prints counts and the worst frames; with --assert, fails on a frame over FAIL_MS or a recurring cache-emptying
## spike.
##   godot --headless --path game -s res://tests/travel_perf_test.gd [-- seed=1 --assert]

const SPIKE_MS := 33.0              # a frame missed at 30 fps
const FAIL_MS := 100.0              # a pause a player sees as a hitch
const RADIUS := 2                   # OverworldView.radius (its default)


var checks := 0
var failures := 0


func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("ok   " if ok else "FAIL ") + what)


func _init() -> void:
	GameData.ensure()
	var seed := 1
	var strict := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("seed="):
			seed = int(a.substr(5))
		elif a == "--assert":
			strict = true
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	var ow: Overworld = w.map.overworld
	var home := Vector2(ow.village.get_center())
	var far: Dictionary = ow.sites[0]
	for st in ow.sites:
		if Vector2(st.center).distance_to(home) > Vector2(far.center).distance_to(home):
			far = st
	var start := Vector2i(ow.gates[0].out)
	var r := RegionTravel.plan(w, start, Vector2i(far.center))
	if not bool(r.ok):
		check(false, "the journey to %s is planned (%s)" % [far.name, str(r.get("why", ""))])
		print("%d checks, %d failures" % [checks, failures])
		quit(1)
		return
	var route: PackedVector2Array = r.cells
	# the view's own scheduling, read from it, so the same test measures any version of the view: how many chunks it builds a frame,
	# and whether it prepares one ahead on a frame with none (B25R2)
	var build_per_frame: int = OverworldView.BUILD_PER_FRAME
	var prefetch: bool = (load("res://scripts/view/overworld_view.gd") as Script).get_script_method_list().any(func(m): return str(m.name) == "_prefetch")
	print("     the view builds %d chunk(s) a frame%s" % [build_per_frame, ", and prepares one ahead on a frame with none" if prefetch else ""])
	w.profiling = true                             # World.prof: microseconds per subsystem, read round each spike (changes nothing)
	var cs := Countryside.new(ow)                  # Main's countryside: the wild animals and the travellers drawn round the view
	cs.taken = w.country_taken
	var view_tiles := float(Countryside.cfg().cull_radius)   # Main: the countryside drawn this far round the view
	var dt := 1.0 / 60.0
	var speed := float(GameData.b("player_tiles_per_second"))
	var p := w.player
	p.pos = route[0] + Vector2(0.5, 0.5)
	var idx := 1
	var have := {}
	var pending: Array = []
	var center := Vector2i(1 << 30, 0)
	var frames := 0
	var over := 0
	var worst: Array = []                        # [ms, line]
	var total_ms := 0.0
	var chunk_frames := 0
	var empties := {"segments": 0, "alive": 0, "ford_ok": 0, "countryside": 0}
	var spike_causes := {}
	var t_game := 0.0
	var last_pos := Vector2.INF
	print("     seed %d: walking %d waypoints from the gate at %s to %s at %s" % [seed, route.size(), str(start), far.name, str(far.center)])
	var limit := 1e9
	for a in OS.get_cmdline_user_args():
		if a.begins_with("seconds="):
			limit = float(a.substr(8))
	while idx < route.size() and frames < 200000 and t_game < limit:
		# the walk: on towards the next waypoint at walking speed
		var target := route[idx] + Vector2(0.5, 0.5)
		var step := speed * dt
		if p.pos.distance_to(target) <= step:
			p.pos = target
			idx += 1
		else:
			p.pos += (target - p.pos).normalized() * step
		var before := [ow._segments.size(), ow._alive.size(), ow._ford_ok.size(), cs._chunks.size()]
		var prof0 := {}
		for k in w.prof:
			prof0[k] = int(w.prof[k].us)
		var t0 := Time.get_ticks_usec()
		w.update(dt)
		cs.animals_near(p.pos, view_tiles, w.minutes)     # Main: the animals and the travellers round the view, each frame
		cs.travellers_near(p.pos, view_tiles, w.minutes)
		var t1 := Time.get_ticks_usec()
		# the view: the chunk window round the player, at most BUILD_PER_FRAME new chunks a frame
		var cc: Vector2i = Overworld.chunk_of(Vector2i(p.pos.floor()))
		if cc != center:
			center = cc
			pending.clear()
			var want: Array = []
			for dy in range(-RADIUS, RADIUS + 1):
				for dx in range(-RADIUS, RADIUS + 1):
					var c: Vector2i = cc + Vector2i(dx, dy)
					if not have.has(c) and not ow.chunk_in_village(c):
						want.append([dx * dx + dy * dy, c.y, c.x, c])
			want.sort()
			for x in want:
				pending.append(x[3])
			for c: Vector2i in have.keys():
				if maxi(absi(c.x - cc.x), absi(c.y - cc.y)) > RADIUS + 1:
					have.erase(c)
		var built := 0
		while not pending.is_empty() and built < build_per_frame:
			var c: Vector2i = pending.pop_front()
			if not have.has(c):
				ow.get_chunk(c)
				have[c] = true
				built += 1
		if built == 0 and prefetch:
			# OverworldView._prefetch: one chunk of the next ring out, nearest the point ahead in the direction of travel
			var heading := Vector2.ZERO if last_pos == Vector2.INF else p.pos - last_pos
			if heading.length() > 0.01:
				var ahead := p.pos + heading.normalized() * float(Overworld.CHUNK * (RADIUS + 1))
				var best := Vector2i(1 << 30, 0)
				var bd := INF
				for dy in range(-RADIUS - 1, RADIUS + 2):
					for dx in range(-RADIUS - 1, RADIUS + 2):
						if maxi(absi(dx), absi(dy)) != RADIUS + 1:
							continue
						var c: Vector2i = cc + Vector2i(dx, dy)
						if ow.cache.has(c) or ow.chunk_in_village(c):
							continue
						var d := (Vector2(c * Overworld.CHUNK) + Vector2(Overworld.CHUNK, Overworld.CHUNK) * 0.5).distance_to(ahead)
						if d < bd:
							bd = d
							best = c
				if bd < INF:
					ow.get_chunk(best)
					built = -1                         # (a chunk prepared ahead, not drawn)
		last_pos = p.pos
		var t2 := Time.get_ticks_usec()
		var after := [ow._segments.size(), ow._alive.size(), ow._ford_ok.size(), cs._chunks.size()]
		var emptied := []
		for k in 4:
			if int(after[k]) < int(before[k]):
				var name: String = ["segments", "alive", "ford_ok", "countryside"][k]
				empties[name] += 1
				emptied.append(name)
		frames += 1
		t_game += dt
		var ms := float(t2 - t0) / 1000.0
		total_ms += ms
		if built != 0:
			chunk_frames += 1
		if ms > SPIKE_MS:
			over += 1
			# the world's subsystem that took most of this frame (World.prof's growth over the frame)
			var top := ""
			var top_us := 0
			for k in w.prof:
				var dus := int(w.prof[k].us) - int(prof0.get(k, 0))
				if dus > top_us and not str(k).begins_with("hourly (incl") and str(k) != "villagers (all)":
					top_us = dus
					top = str(k)
			var cause := ("emptied " + "+".join(emptied)) if not emptied.is_empty() else (("chunks %d" % built if built > 0 else "chunk prepared ahead") if built != 0 and float(t2 - t1) > float(t1 - t0) else "world: " + top)
			spike_causes[cause] = int(spike_causes.get(cause, 0)) + 1
			worst.append([ms, "%.1f ms at %.1f s (game %s), cell %s: world %.1f ms (most: %s %.1f ms), chunks %d in %.1f ms%s" % [ms, t_game,
				"%02d:%02d" % [int(fmod(w.minutes, 1440.0) / 60.0), int(fmod(w.minutes, 60.0))], str(Vector2i(p.pos.floor())),
				float(t1 - t0) / 1000.0, top, top_us / 1000.0, built, float(t2 - t1) / 1000.0, (", emptied " + "+".join(emptied)) if not emptied.is_empty() else ""]])
	worst.sort_custom(func(a, b): return a[0] > b[0])
	var worst_ms: float = worst[0][0] if not worst.is_empty() else 0.0
	print("     %d frames (%.0f s of walking), mean %.2f ms; %d over %.0f ms; worst %.1f ms" % [frames, t_game, total_ms / maxf(1.0, frames), over, SPIKE_MS, worst_ms])
	print("     frames building chunks: %d; caches emptied: %s; spikes by cause: %s" % [chunk_frames, str(empties), str(spike_causes)])
	for k in mini(12, worst.size()):
		print("       ", worst[k][1])
	if limit < 1e9:
		print("%d checks, %d failures" % [checks, failures])
		quit(0)
		return
	check(idx >= route.size(), "the walk reached %s (%d of %d waypoints)" % [far.name, idx, route.size()])
	if strict:
		check(worst_ms <= FAIL_MS, "no frame of the journey over %.0f ms (worst %.1f ms)" % [FAIL_MS, worst_ms])
		var recurring := int(spike_causes.keys().filter(func(c): return str(c).begins_with("emptied")).map(func(c): return spike_causes[c]).reduce(func(a, b): return a + b, 0))
		check(recurring == 0, "no spike from a cache emptying itself (%d)" % recurring)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
