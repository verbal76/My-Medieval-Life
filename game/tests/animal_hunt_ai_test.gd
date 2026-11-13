extends SceneTree
## B25-ANIMAL-HUNT-AI (owner directive 2026-11-12, section 2): how animals react to the player's melee blows.
## Run: godot --headless --path game --script res://tests/animal_hunt_ai_test.gd
## Struck, an animal stops what it was doing and turns to the one who struck it (a startle); prey then run, away from
## the attacker, facing where they go, in zigzags with an occasional look back, round trees, walls, water and the edge of
## their wood, never back into the attacker; wolves and bears turn and fight; nothing flaps between standing and running;
## a hunter with a sword still kills a deer or a boar in a fair number of swings; death, loot and saves are as before.
## Deterministic: the world's seed, the fauna's own movement stream (Fauna.move_rng), fixed steps.

var failures := 0
var checks := 0
const DT := 1.0 / 30.0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   ", what)
	else:
		failures += 1
		print("FAIL ", what)


func _init() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	test_reaction(w)
	test_chase(w, "deer")
	test_chase(w, "rabbit")
	test_chase(w, "boar")
	test_edge(w)
	test_bear(w)
	test_kill_and_loot(w)
	test_achievable(w, "deer", "copper_sword")
	test_achievable(w, "boar", "copper_sword")
	test_save(w)
	test_deterministic()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _of(w: World, species: String, area := "woods_w") -> Array:
	return w.fauna.animals.filter(func(a): return a.alive and a.species == species and a.area == area and a.adult(w.minutes))


## A cell of the wood with open ground `r` cells round it (deterministic: the first in the wood's own order).
func _open_cell(w: World, area: String, r: int) -> Vector2i:
	for c: Vector2i in w.fauna.cells(area):
		var ok := true
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var q := c + Vector2i(dx, dy)
				if not w.fauna.in_area(area, q) or w.map.is_solid(q):
					ok = false
		if ok:
			return c
	return Vector2i(-1, -1)


## Quiet everything else: fed predators, nobody angry, nobody else close to the scene.
func _calm(w: World) -> void:
	for a: Animal in w.fauna.animals:
		a.hunger = 100.0
		a.anger = ""
		a.hunt = -1


## A grown animal of `species`, standing idle in an open part of its wood, the player `off` tiles from it.
func _stage(w: World, species: String, off: Vector2) -> Animal:
	_calm(w)
	var area := "woods_w"
	var a: Animal = _of(w, species, area)[0]
	var c := _open_cell(w, area, 3)
	a.pos = Vector2(c) + Vector2(0.5, 0.5)
	a.hp = float(a.spec().hp)
	a.goal = Vector2.INF
	a.wait = 5.0                                    # in the middle of an idle pause
	a.moving = false
	a.facing = -off.normalized() if off != Vector2.ZERO else Vector2.RIGHT     # facing away from where the player stands
	a.act = ""
	a.act_left = 0.0
	w.player.pos = a.pos + off
	w.player.alive = true
	w.player.hp = float(GameData.b("player_max_hp"))
	return a


func _step(w: World, t: float) -> void:
	var n := int(round(t / DT))
	for i in n:
		w.fauna.update(DT)


func test_reaction(w: World) -> void:
	var a := _stage(w, "deer", Vector2(-1.0, 0.0))
	w.player_hit_animal(a, 0.5)
	var to_foe := (w.player.pos - a.pos).normalized()
	check(a.goal == Vector2.INF and not a.moving, "struck, a deer stops its idle pause at once")
	check(a.facing.normalized().dot(to_foe) > 0.9, "and turns to face the player who struck it (%.2f)" % a.facing.normalized().dot(to_foe))
	check(a.act == "hit", "the hit animation plays")
	var p0 := a.pos
	_step(w, 0.2)
	check(a.pos.distance_to(p0) < 0.05 and a.facing.normalized().dot((w.player.pos - a.pos).normalized()) > 0.9,
		"for a startled moment it stands facing the attacker")
	_step(w, 1.0)
	var away := (a.pos - w.player.pos).normalized()
	var moved := a.pos - p0
	check(a.moving and moved.length() > 1.0, "then it runs (%.2f tiles in a second)" % moved.length())
	check(moved.normalized().dot((p0 - w.player.pos).normalized()) > 0.5, "away from the player (%.2f)" % moved.normalized().dot((p0 - w.player.pos).normalized()))
	check(a.facing.normalized().dot(away) > 0.3 and a.facing.length() > 0.0, "facing the way it runs, not the player")


## The player chases a struck animal for 40 seconds, striking (harmlessly) whenever it is in reach, and every frame
## of the animal is checked: where it goes, which way it faces, that it stays on its ground.
func test_chase(w: World, species: String) -> void:
	var a := _stage(w, species, Vector2(-1.0, 0.0))
	var reach := float(Combat.cfg().reach)
	var pspeed := float(GameData.b("player_tiles_per_second"))
	var cd := 0.0
	var strikes := 0
	var into := 0                  # frames it moved toward the player while near them
	var into_cell := 0             # steps that took it into the player's cell
	var wrong_face := 0            # frames it ran facing away from where it ran
	var off_ground := 0            # frames on a solid cell or off its wood
	var still_near := 0            # frames standing within reach outside a startle or a look back
	var moving_frames := 0
	var changes := 0               # state changes (standing / running), per the whole chase
	var looks := 0                 # look-backs (a hesitation while running)
	var was_moving := false
	var was_pause := false
	var dirs := []                 # the heading every half second, to see the zigzag
	var frames := int(40.0 / DT)
	w.player_hit_animal(a, 0.01)
	strikes += 1
	cd = float(Combat.cfg().swing_time)
	for f in frames:
		var before := a.pos
		w.fauna.update(DT)
		var mv := a.pos - before
		var to_p := w.player.pos - before
		var dist := to_p.length()
		if mv.length() > 0.0001:
			moving_frames += 1
			if dist < 3.0 and mv.normalized().dot(to_p.normalized()) > 0.2:
				into += 1
			var pc := Vector2i(floori(w.player.pos.x), floori(w.player.pos.y))
			if a.cell() == pc and Vector2i(floori(before.x), floori(before.y)) != pc:
				into_cell += 1
			if a.facing.normalized().dot(mv.normalized()) < 0.7:
				wrong_face += 1
		if w.map.is_solid(a.cell()) or not w.fauna.in_area(a.area, a.cell()):
			off_ground += 1
		if a.moving != was_moving:
			changes += 1
			was_moving = a.moving
		if a.pause_left > 0.0 and not was_pause:
			looks += 1
		was_pause = a.pause_left > 0.0
		if not a.moving and dist <= reach and a.startle_left <= 0.0 and a.pause_left <= 0.0:
			still_near += 1
		if f % 15 == 0 and mv.length() > 0.0001:
			dirs.append(mv.normalized())
		# the player: runs after it, never closer than 0.8, strikes in reach once a swing
		var gap := a.pos - w.player.pos
		if gap.length() > 0.8:
			w.player.pos += gap.normalized() * minf(pspeed * DT, gap.length() - 0.8)
		cd -= DT
		if cd <= 0.0 and a.pos.distance_to(w.player.pos) <= reach:
			w.player_hit_animal(a, 0.01)
			strikes += 1
			cd = float(Combat.cfg().swing_time)
	var turns := 0
	for i in range(1, dirs.size()):
		if (dirs[i] as Vector2).dot(dirs[i - 1]) < 0.97:
			turns += 1
	print("     %s chase: %d strikes, %d/%d frames moving, %d changes, %d looks back, %d turns, %d standing in reach" % [
		species, strikes, moving_frames, frames, changes, looks, turns, still_near])
	check(into == 0, "%s: never steps toward the player while near them (%d frames)" % [species, into])
	check(into_cell == 0, "%s: never steps into the player's cell" % species)
	check(wrong_face == 0, "%s: faces the way it runs (%d frames otherwise)" % [species, wrong_face])
	check(off_ground == 0, "%s: never runs into a tree, a wall, water or out of its wood" % species)
	check(moving_frames > frames / 2, "%s: keeps running while chased (%d of %d frames)" % [species, moving_frames, frames])
	check(turns >= 3, "%s: runs in zigzags, not one straight line (%d turns)" % [species, turns])
	check(changes <= 80, "%s: no flapping between standing and running (%d changes in 40 s)" % [species, changes])
	check(still_near * 4 < frames, "%s: does not stand idle in reach of the blows (%d frames)" % [species, still_near])


## Driven against the edge of its wood (the player on the inside), a deer runs along the edge, not into it nor back.
func test_edge(w: World) -> void:
	var a := _stage(w, "deer", Vector2(-1.0, 0.0))
	var area := a.area
	# the wood's easternmost open cell on the deer's row
	var c := a.cell()
	while w.fauna.in_area(area, c + Vector2i(1, 0)) and not w.map.is_solid(c + Vector2i(1, 0)):
		c += Vector2i(1, 0)
	a.pos = Vector2(c) + Vector2(0.5, 0.5)
	w.player.pos = a.pos + Vector2(-1.0, 0.0)
	w.player_hit_animal(a, 0.01)
	var start := a.pos
	var bad := 0
	var closer := 0
	for f in int(3.0 / DT):
		var d0 := a.pos.distance_to(w.player.pos)
		w.fauna.update(DT)
		if w.map.is_solid(a.cell()) or not w.fauna.in_area(area, a.cell()):
			bad += 1
		if a.pos.distance_to(w.player.pos) < d0 - 0.001:
			closer += 1
	check(bad == 0, "at the edge of its wood it stays inside it")
	check(closer == 0, "and never moves back toward the player")
	check(a.pos.distance_to(start) > 1.0, "it slips away along the edge (%.2f tiles)" % a.pos.distance_to(start))


func test_bear(w: World) -> void:
	var a := _stage(w, "bear", Vector2(-1.5, 0.0))
	w.player_hit_animal(a, 0.5)
	var to_foe := (w.player.pos - a.pos).normalized()
	check(a.anger != "", "struck, a bear turns on the player")
	check(a.facing.normalized().dot(to_foe) > 0.9, "facing them at once")
	var d0 := a.pos.distance_to(w.player.pos)
	var hp0 := w.player.hp
	var faced := 0
	var n := int(3.0 / DT)
	for f in n:
		w.fauna.update(DT)
		if a.facing.normalized().dot((w.player.pos - a.pos).normalized()) > 0.7:
			faced += 1
	check(a.pos.distance_to(w.player.pos) < d0, "it comes for the player rather than running")
	check(w.player.hp < hp0, "and bites (%.1f)" % (hp0 - w.player.hp))
	check(faced == n, "it faces the player throughout (%d of %d frames)" % [faced, n])
	check(a.startle_left <= 0.0 and a.alarm == "", "a bear is never put to flight")
	var wolf := _stage(w, "wolf", Vector2(-1.5, 0.0))
	w.player_hit_animal(wolf, 0.5)
	check(wolf.anger != "" and wolf.facing.normalized().dot((w.player.pos - wolf.pos).normalized()) > 0.9, "a wolf likewise turns and fights")
	_calm(w)


func test_kill_and_loot(w: World) -> void:
	var a := _stage(w, "deer", Vector2(-1.0, 0.0))
	var loot0 := w.loot.size()
	var hunted0 := int(w.stats.get("hunted_deer", 0))
	w.player_hit_animal(a, 5.0)
	_step(w, 0.5)
	var at := a.pos
	var h := w.player_hit_animal(a, 999.0)
	check(h.killed and not a.alive and not w.fauna.animals.has(a), "a struck, fleeing deer dies of the killing blow")
	check(w.loot.size() == loot0 + 1 and (w.loot[-1].pos as Vector2) == at, "its loot is left where it fell")
	var inv: Inventory = w.loot[-1].inv
	check(inv.count("meat") == int(a.spec().meat) and inv.count("hide") == int(a.spec().hide), "meat and hide as before")
	check(int(w.stats.get("hunted_deer", 0)) == hunted0 + 1, "the kill is counted")


## A scripted hunt: the player (4.5 tiles a second, no sprint) runs after a grown animal with a copper sword, starts a
## swing whenever it is within reach, the blow landing after the windup only if it is still in reach and in front.
func test_achievable(w: World, species: String, weapon: String) -> void:
	var a := _stage(w, species, Vector2(-1.2, 0.0))
	var p := w.player
	p.inv.add(weapon, 1)
	p.weapon = weapon
	var cfg := Combat.cfg()
	var pspeed := float(GameData.b("player_tiles_per_second"))
	var swings := 0
	var hits := 0
	var t := 0.0
	var swing_t := -1.0
	var landed := false
	while a.alive and t < 60.0:
		w.fauna.update(DT)
		t += DT
		if not a.alive:
			break
		var gap := a.pos - p.pos
		if gap.length() > 0.8:
			p.pos += gap.normalized() * minf(pspeed * DT, gap.length() - 0.8)
		if swing_t < 0.0 and a.pos.distance_to(p.pos) <= float(cfg.reach):
			swing_t = 0.0
			swings += 1
			landed = false
		if swing_t >= 0.0:
			swing_t += DT
			if not landed and swing_t >= float(cfg.windup):
				landed = true
				if Combat.in_reach(w, p.pos, a.pos - p.pos, a.pos):
					hits += 1
					w.player_melee_animal(a)
			if swing_t >= float(cfg.swing_time):
				swing_t = -1.0
	print("     %s with a %s: %s after %.1f s, %d swings, %d hits" % [species, weapon, "killed" if not a.alive else "alive", t, swings, hits])
	check(not a.alive, "a %s can be hunted down with a %s (%.1f s)" % [species, weapon, t])
	check(swings <= 15, "in a fair number of swings (%d)" % swings)
	p.inv.remove(weapon, 1)
	p.weapon = ""


func test_save(w: World) -> void:
	var a := _stage(w, "deer", Vector2(-1.0, 0.0))
	w.player_hit_animal(a, 1.0)
	_step(w, 1.0)
	check(a.alarm != "" and a.moving, "mid-flight before saving")
	var d := w.to_dict()
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
	var b: Animal = w2.fauna.by_id(a.id)
	check(b != null and b.alive and b.pos.distance_to(a.pos) < 0.001 and is_equal_approx(b.hp, a.hp), "a fleeing deer saves and loads where it was, with its wounds")
	check(b != null and b.alarm == "" and b.startle_left == 0.0 and b.pause_left == 0.0, "its flight is not saved (as a fight is not): it loads calm")
	if b == null:
		return
	w2.player.pos = b.pos + Vector2(-1.0, 0.0)
	b.facing = Vector2.RIGHT
	w2.player_hit_animal(b, 0.5)
	check(b.facing.normalized().dot(Vector2.LEFT) > 0.9 and b.alarm != "", "struck again after loading, it reacts as before")


## Two worlds from the same seed, the same hunt: the same frames.
func test_deterministic() -> void:
	var trace := []
	for k in 2:
		var w := World.new()
		w.setup(VillageMap.load_default(), 7)
		var a := _stage(w, "deer", Vector2(-1.0, 0.0))
		w.player_hit_animal(a, 0.01)
		var s := ""
		for f in int(10.0 / DT):
			w.fauna.update(DT)
			var gap := a.pos - w.player.pos
			if gap.length() > 0.8:
				w.player.pos += gap.normalized() * minf(4.5 * DT, gap.length() - 0.8)
			if f % 10 == 0:
				s += "%.4f,%.4f;" % [a.pos.x, a.pos.y]
		trace.append(s)
	check(trace[0] == trace[1], "the same seed and hunt give the same flight, frame for frame")
