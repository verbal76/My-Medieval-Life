extends SceneTree
## TEST-AUDIT-01 coverage gap G2: villagers go to their place of work. Mutation M6 (NPCBrain._workplace_cell answering the
## villager's own cell, so no plan led anywhere) passed nine suites (job_board, health_jobs, business, stalls, desk,
## courier_desk, contracts, elder_provision, discovery). Here, on seeds 1 and 2, every working adult whose workplace is a work
## station or a market stall comes within REACH tiles of it during the first working day. The place is read from the world's
## own records (World.station_use, the stall's use cell), never from the brain's answer, so a wrong answer cannot pass.
##   godot --headless --path game -s res://tests/workplace_reach_test.gd

const REACH := 2.0
var checks := 0
var failures := 0


func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("ok   " if ok else "FAIL ") + what)


## The cell a workplace is worked from, from the world's records alone ({} when it is not a station or a stall).
static func place_of(w: World, workplace: String) -> Variant:
	if w.stations.has(workplace):
		return w.station_use(workplace)
	if w.stalls.has(workplace):
		var s: Dictionary = w.stalls[workplace]
		return Vector2i(int(s.use[0]), int(s.use[1]))
	return null


func _init() -> void:
	GameData.ensure()
	for seed in [1, 2]:
		var w := World.new()
		w.setup(VillageMap.load_default(), seed)
		var nearest := {}
		var gmps := float(GameData.b("game_minutes_per_second"))
		for i in int(1440.0 / gmps / 0.5):            # one game day
			w.update(0.5)
			if i % 20 != 0:
				continue
			for n: NPC in w.npcs:
				if not n.alive or n.role != "adult":
					continue
				var at = place_of(w, str(n.workplace))
				if at == null:
					continue
				var d := Vector2(n.cell()).distance_to(Vector2(at))
				nearest[n.id] = minf(float(nearest.get(n.id, INF)), d)
		var far := nearest.keys().filter(func(k): return float(nearest[k]) > REACH)
		check(nearest.size() >= 10, "seed %d: working adults with a station or stall to work at (%d)" % [seed, nearest.size()])
		check(far.is_empty(), "seed %d: every one comes within %d tiles of it on the first day (%d do not: %s)" % [seed, int(REACH),
				far.size(), str(far.slice(0, 5).map(func(k): return "%s at %s, %.0f tiles" % [w.npc(k).job, w.npc(k).workplace, float(nearest[k])]))])
		w.dispose()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
