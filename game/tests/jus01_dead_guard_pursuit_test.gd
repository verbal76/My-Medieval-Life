extends SceneTree
## JUS-01: dead pursuing guards must not leave a ghost active-pursuit flag.
var checks := 0
var fails := 0
func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		fails += 1

func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 8311)
	var ref := w.acting_ref()
	var g: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.job == "guard":
			g = n
			break
	check(g != null, "JUS-01: a living guard is available")
	if g == null:
		w.dispose()
		quit(1)
		return
	w.justice.record(ref, "killing", null, w.player.pos, 1)
	w.justice.learn(g, ref, [0])
	# Explicitly stage a pursuit record; test the world death hook, not AI pathfinding.
	g.pursuit = {"ref": ref, "state": "pursuing", "at": [w.player.pos.x, w.player.pos.y], "t": w.minutes}
	w.justice.case_of(ref).pursuers[str(g.id)] = true
	check(w.justice.status(ref) == "pursued" and bool(w.justice.alert(ref).get("hunted", false)), "JUS-01: living guard is an active pursuer")
	w.kill(g, "old age")
	check(not g.alive, "JUS-01: guard has died")
	check(not w.justice.case_of(ref).pursuers.has(str(g.id)), "JUS-01: dead guard removed from case pursuers")
	check(w.justice.status(ref) == "wanted", "JUS-01: unresolved crime remains wanted, not pursued")
	check(not bool(w.justice.alert(ref).get("hunted", true)), "JUS-01: indicator stops claiming a live guard hunt")
	w.dispose()
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)
