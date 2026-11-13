extends SceneTree
## B25-ANIMAL-BOAR-LIVESTOCK (owner 2026-11-12): "Boars may charge and defend themselves when attacked, but should not
## always charge. Preserve believable flight and defensive responses. Keep current reaction timing provisionally until
## hardware playtesting. Struck livestock should flee naturally within their enclosures without passing through fences.
## Add deterministic regression coverage."
## Run: godot --headless --path game --script res://tests/animal_boar_livestock_test.gd
## A struck boar, after the same startle as every other animal, either charges and fights (Fauna.provoke draws it from the
## fauna's movement stream; more likely hurt or cornered) or runs like a deer; a charging boar stands in reach facing the
## player, gores on its cooldown and gives up after fight_seconds or once the player is give_up_distance away. Struck pen
## animals run inside their pen's cells only, never on its fence or gate. The animals move on the world's ticks (_frame).

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
	test_choice(w)
	test_only_boars(w)
	test_charge(w)
	test_give_up_time(w)
	test_give_up_distance(w)
	test_charging_boar_huntable(w)
	for id in ["pen_cow", "pen_pig", "pen_sheep", "pen_chicken"]:
		test_pen(w, id, true)
		test_pen(w, id, false)
		test_pen_fence_born(w, id)
	test_save(w)
	test_deterministic()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


static func ch() -> Dictionary:
	return GameData.b("wildlife").struck.charge.boar


func _of(w: World, species: String, area := "woods_w") -> Array:
	return w.fauna.animals.filter(func(a): return a.alive and a.species == species and a.area == area and a.adult(w.minutes))


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


func _calm(w: World) -> void:
	for a: Animal in w.fauna.animals:
		a.hunger = 100.0
		a.anger = ""
		a.hunt = -1
		a.alarm = ""
		a.startle_left = 0.0


func _stage(w: World, species: String, off: Vector2) -> Animal:
	_calm(w)
	var a: Animal = _of(w, species)[0]
	var c := _open_cell(w, "woods_w", 3)
	a.pos = Vector2(c) + Vector2(0.5, 0.5)
	a.hp = float(a.spec().hp)
	a.goal = Vector2.INF
	a.wait = 5.0
	a.moving = false
	a.facing = -off.normalized()
	a.act = ""
	a.act_left = 0.0
	a.run_dir = Vector2.ZERO
	a.at_bay = false
	a.breaking = false
	a.pause_left = 0.0
	w.player.pos = a.pos + off
	w.player.alive = true
	w.player.hp = float(GameData.b("player_max_hp"))
	return a


var acc := 0.0
func _frame(w: World) -> void:
	acc += DT
	if acc >= World.TICK - 0.000001:
		acc -= World.TICK
		w.fauna.update(World.TICK)


func _step(w: World, t: float) -> void:
	for i in int(round(t / DT)):
		_frame(w)


## A boar struck with the charge chances forced to `p` (the drawn number still comes from the stream).
func _forced(w: World, p: float, off := Vector2(-1.5, 0.0)) -> Animal:
	var c := ch()
	var keep := [c.chance, c.hurt_chance, c.cornered_chance]
	c.chance = p
	c.hurt_chance = p
	c.cornered_chance = p
	var a := _stage(w, "boar", off)
	w.player_hit_animal(a, 0.5)
	c.chance = keep[0]
	c.hurt_chance = keep[1]
	c.cornered_chance = keep[2]
	return a


## Over 60 seeded blows a healthy boar in the open both charges and runs, neither always; a badly hurt one charges more
## often than a healthy one; one with its back to the edge of its wood more often still.
func test_choice(w: World) -> void:
	var n := 60
	var charges := 0
	var flights := 0
	for i in n:
		var a := _stage(w, "boar", Vector2(-1.5, 0.0))
		w.player_hit_animal(a, 0.5)
		if a.anger != "":
			charges += 1
		elif a.alarm != "":
			flights += 1
	var hurt := 0
	for i in n:
		var a := _stage(w, "boar", Vector2(-1.5, 0.0))
		w.player_hit_animal(a, float(a.spec().hp) * (1.0 - float(ch().hurt_below)) + 1.0)
		if a.anger != "":
			hurt += 1
	var cornered := 0
	var cornered_seen := 0
	for i in n:
		var a := _stage(w, "boar", Vector2(-1.0, 0.0))
		var c := a.cell()                                   # its back to the wood's east edge, the player to the west
		while w.fauna.in_area(a.area, c + Vector2i(1, 0)) and not w.map.is_solid(c + Vector2i(1, 0)):
			c += Vector2i(1, 0)
		a.pos = Vector2(c) + Vector2(0.7, 0.5)
		w.player.pos = a.pos + Vector2(-1.0, 0.0)
		if w.fauna.cornered(a, w.player.pos):
			cornered_seen += 1
		w.player_hit_animal(a, 0.5)
		if a.anger != "":
			cornered += 1
	print("     boar: %d charges, %d flights in %d; hurt %d; at the edge %d (%d cornered)" % [charges, flights, n, hurt, cornered, cornered_seen])
	check(charges > 0 and flights > 0 and charges + flights == n, "a struck boar sometimes charges, sometimes runs (%d / %d)" % [charges, flights])
	check(charges < n * 3 / 4 and flights > n / 3, "a healthy boar in the open runs more often than it charges (%d charges)" % charges)
	check(hurt > charges, "badly hurt, it charges more often (%d against %d)" % [hurt, charges])
	check(cornered_seen == n and cornered > charges, "with its back to the edge of its wood, more often still (%d against %d)" % [cornered, charges])


## Deer, rabbits and foxes are never put to a charge, whatever the draw.
func test_only_boars(w: World) -> void:
	var bad := 0
	for sp in ["deer", "rabbit", "fox"]:
		for i in 20:
			var a := _stage(w, sp, Vector2(-1.0, 0.0))
			w.player_hit_animal(a, 0.01)
			if a.anger != "" or a.alarm == "":
				bad += 1
	check(bad == 0, "deer, rabbits and foxes always run when struck (%d otherwise)" % bad)
	var bear := _stage(w, "bear", Vector2(-1.5, 0.0))
	w.player_hit_animal(bear, 0.5)
	check(bear.anger != "" and bear.startle_left == 0.0, "a bear still turns and fights at once")


## A charging boar: startled as long as any struck animal, then comes for the player facing them, stands in reach (never on
## them), gores on its cooldown.
func test_charge(w: World) -> void:
	var a := _forced(w, 1.0, Vector2(-3.0, 0.0))
	check(a.anger == w.acting_ref() and a.alarm == "", "forced, a struck boar takes up the fight")
	check(is_equal_approx(a.startle_left, float(GameData.b("wildlife").struck.startle_seconds)), "after the same startle as a fleeing animal")
	var p0 := a.pos
	_step(w, 0.2)
	check(a.pos.distance_to(p0) < 0.001, "it stands startled for that moment")
	var hp0 := w.player.hp
	var faced := 0
	var overlap := 0
	var attacks := 0
	var was_attack := false
	var hits := []
	var t := 0.0
	var last_hp := hp0
	var n := int(4.0 / DT)
	for f in n:
		_frame(w)
		t += DT
		if a.facing.normalized().dot((w.player.pos - a.pos).normalized()) > 0.7:
			faced += 1
		if a.pos.distance_to(w.player.pos) < float(ch().standoff) - 0.01:
			overlap += 1
		if a.act == "attack" and not was_attack:
			attacks += 1
		was_attack = a.act == "attack"
		if w.player.hp < last_hp - 0.001:
			hits.append(t)
			last_hp = w.player.hp
	var gap := 99.0
	for i in range(1, hits.size()):
		gap = minf(gap, hits[i] - hits[i - 1])
	print("     charge: %d gores in 4 s, %.1f damage, nearest %.2f s apart, %.2f tiles off" % [hits.size(), hp0 - w.player.hp, gap, a.pos.distance_to(w.player.pos)])
	check(a.pos.distance_to(p0) > 1.5, "then it charges at the player (%.2f tiles)" % a.pos.distance_to(p0))
	check(faced == n, "facing them throughout (%d of %d frames)" % [faced, n])
	check(overlap == 0, "never on top of them (%d frames within %.2f)" % [overlap, float(ch().standoff)])
	check(a.pos.distance_to(w.player.pos) <= 1.0 and a.cell() != Vector2i(floori(w.player.pos.x), floori(w.player.pos.y)),
		"it stands in reach, not in their cell (%.2f)" % a.pos.distance_to(w.player.pos))
	check(hits.size() >= 2 and attacks >= hits.size(), "it gores the player, the attack playing (%d gores, %d attacks)" % [hits.size(), attacks])
	check(is_equal_approx(hp0 - w.player.hp, float(ch().gore) * hits.size()), "each gore its own damage (%.1f)" % (hp0 - w.player.hp))
	check(gap >= float(ch().gore_seconds) - World.TICK - 0.01, "on its cooldown (%.2f s)" % gap)
	check(a.alarm == "" and a.startle_left <= 0.0, "a charging boar does not run")


## Standing their ground, the player is left alone after fight_seconds: the boar stops, rests and goes back to its wood's
## ways, and nothing more is lost.
func test_give_up_time(w: World) -> void:
	var a := _forced(w, 1.0)
	var t := 0.0
	var gave := -1.0
	while t < float(ch().fight_seconds) + 3.0:
		_frame(w)
		t += DT
		if gave < 0.0 and a.anger == "":
			gave = t
	var hp := w.player.hp
	_step(w, 5.0)
	print("     charge: gave up after %.1f s" % gave)
	check(gave > 0.0 and gave <= float(ch().fight_seconds) + World.TICK + 0.01, "a boar gives up the fight within fight_seconds (%.1f s)" % gave)
	check(is_equal_approx(w.player.hp, hp) and a.anger == "" and a.alarm == "", "and leaves the player be (no more gores, no flight)")


## Run from, a charging boar chases no further than give_up_distance (no endless chase).
func test_give_up_distance(w: World) -> void:
	var a := _forced(w, 1.0)
	_step(w, 0.5)
	var start := a.pos
	var t := 0.0
	var away := Vector2(-1.0, 0.0)
	while a.anger != "" and t < float(ch().fight_seconds):
		_frame(w)
		t += DT
		w.player.pos += away * float(GameData.b("player_tiles_per_second")) * DT
	var d := a.pos.distance_to(w.player.pos)
	print("     charge: given up %.1f s into the run, %.1f tiles off, %.1f tiles from its start" % [t, d, a.pos.distance_to(start)])
	check(a.anger == "" and t < float(ch().fight_seconds) - 1.0, "outrun, the boar gives up before its time is out (%.1f s)" % t)
	check(d >= float(ch().give_up_distance) - 0.5 and d <= float(ch().give_up_distance) + 2.5, "once the player is give_up_distance off (%.1f)" % d)
	check(w.fauna.in_area(a.area, a.cell()), "it never leaves its wood")


## A charging boar can still be killed with a copper sword in a fair number of swings, at a price in health.
func test_charging_boar_huntable(w: World) -> void:
	var a := _forced(w, 1.0)
	var p := w.player
	p.inv.add("copper_sword", 1)
	p.weapon = "copper_sword"
	var cfg := Combat.cfg()
	var swings := 0
	var t := 0.0
	var swing_t := -1.0
	var landed := false
	while a.alive and t < 60.0 and p.hp > 0.0:
		_frame(w)
		t += DT
		if not a.alive:
			break
		if swing_t < 0.0 and a.pos.distance_to(p.pos) <= float(cfg.reach):
			swing_t = 0.0
			swings += 1
			landed = false
		if swing_t >= 0.0:
			swing_t += DT
			if not landed and swing_t >= float(cfg.windup):
				landed = true
				if Combat.in_reach(w, p.pos, a.pos - p.pos, a.pos):
					w.player_melee_animal(a)
			if swing_t >= float(cfg.swing_time):
				swing_t = -1.0
	print("     charging boar with a copper sword: %s after %.1f s, %d swings, player at %.0f" % ["killed" if not a.alive else "alive", t, swings, p.hp])
	check(not a.alive and p.hp > 0.0, "a charging boar can be fought and killed (%.1f s)" % t)
	p.inv.remove("copper_sword", 1)
	p.weapon = ""


## A pen animal struck and chased (the player inside the pen, `inside`, or along its fence outside) for 40 s: every tick
## it is on one of its pen's cells (the inside of the fence), never on the fence, the gate or out; it runs; then, left
## alone, it calms down and strolls on inside the pen.
func test_pen(w: World, id: String, inside: bool) -> void:
	_calm(w)
	var pen: Dictionary = w.fauna.pens[id]
	var herd: Array = w.fauna.animals.filter(func(b): return b.alive and b.area == id)
	if herd.is_empty():
		check(false, "%s has animals" % id)
		return
	var a: Animal = herd[0]
	var cs: Array = w.fauna.cells(id)
	var rect := Rect2i(int(pen.x), int(pen.y), int(pen.w), int(pen.h))
	var mid: Vector2i = cs[cs.size() / 2]
	a.pos = Vector2(mid) + Vector2(0.5, 0.5)
	a.goal = Vector2.INF
	a.wait = 5.0
	a.hp = float(a.spec().hp)
	var pp: Vector2
	if inside:
		pp = a.pos + Vector2(-1.0, 0.0)
	else:
		pp = Vector2(a.pos.x, float(rect.position.y + rect.size.y) + 0.4)      # just outside the fence's bottom side
		a.pos = Vector2(a.pos.x, float(rect.position.y + rect.size.y - 2) + 0.5)
	w.player.pos = pp
	w.player.alive = true
	w.player.hp = 100.0
	var reach := float(Combat.cfg().reach)
	var off := 0
	var on_fence := 0
	var moved := 0
	var crossed := 0
	var cd := 0.0
	var strikes := 0
	var gate := Vector2i(int(pen.gate[0]), int(pen.gate[1]))
	w.player_hit_animal(a, 0.01)
	for f in int(40.0 / DT):
		var before := a.cell()
		_frame(w)
		var c := a.cell()
		if not w.fauna.in_area(id, c):
			off += 1
		var border := c.x <= rect.position.x or c.y <= rect.position.y or c.x >= rect.end.x - 1 or c.y >= rect.end.y - 1
		if border or c == gate or not rect.has_point(c):
			on_fence += 1
		if absi(c.x - before.x) + absi(c.y - before.y) > 1 and not (w.fauna.in_area(id, c + Vector2i(0, 0))):
			crossed += 1
		if c != before:
			moved += 1
		# the player: inside, follows it round the pen; outside, walks along the fence below it
		var tgt := a.pos + (w.player.pos - a.pos).normalized() * 0.9
		if not inside:
			tgt = Vector2(clampf(a.pos.x, float(rect.position.x), float(rect.end.x)), pp.y)
		var g := tgt - w.player.pos
		w.player.pos += g.limit_length(4.5 * DT)
		cd -= DT
		if cd <= 0.0 and a.pos.distance_to(w.player.pos) <= reach + 0.5:
			w.player_hit_animal(a, 0.01)
			strikes += 1
			cd = float(Combat.cfg().swing_time)
	w.player.pos = Vector2(float(rect.end.x) + 12.0, float(rect.end.y) + 12.0)       # the player leaves
	var calm_t := -1.0
	var t := 0.0
	var strolled := 0
	var off2 := 0
	while t < 40.0:
		var b := a.pos
		_frame(w)
		t += DT
		if calm_t < 0.0 and a.alarm == "" and a.startle_left <= 0.0:
			calm_t = t
		if calm_t >= 0.0 and a.pos.distance_to(b) > 0.0001:
			strolled += 1
		if not w.fauna.in_area(id, a.cell()):
			off2 += 1
	var where := "inside" if inside else "from outside"
	print("     %s (%s): %d strikes, %d cell changes, calm after %.1f s, %d frames strolling" % [id, where, strikes, moved, calm_t, strolled])
	check(off == 0 and on_fence == 0 and crossed == 0, "%s struck %s: never leaves its pen, never on the fence or gate (%d off, %d on the fence)" % [id, where, off, on_fence])
	check(moved >= 3, "%s struck %s: it runs about inside the pen (%d cell changes)" % [id, where, moved])
	check(calm_t >= 0.0 and strolled > 0 and off2 == 0, "%s: left alone it calms and strolls on in its pen (calm after %.1f s)" % [id, calm_t])


## A pen animal standing on its fence line (a newborn dropped beside its mother at the edge can be) struck by a player
## inside the pen: it runs into the pen, never out over the fence, though straight away from the player is outside.
func test_pen_fence_born(w: World, id: String) -> void:
	_calm(w)
	var pen: Dictionary = w.fauna.pens[id]
	var a: Animal = w.fauna.animals.filter(func(b): return b.alive and b.area == id)[0]
	var rect := Rect2i(int(pen.x), int(pen.y), int(pen.w), int(pen.h))
	a.pos = Vector2(float(rect.position.x) + 1.5, float(rect.end.y - 1) + 0.3)     # on the fence's bottom side, by a corner
	a.goal = Vector2.INF
	a.wait = 5.0
	w.player.pos = a.pos + Vector2(0.4, -1.0)                                     # inside the pen, above it
	w.player_hit_animal(a, 0.01)
	var out := 0
	for f in int(8.0 / DT):
		_frame(w)
		if not rect.has_point(a.cell()) or (a.cell().y >= rect.end.y - 1 and a.pos.y > float(rect.end.y - 1) + 0.31):
			out += 1
	print("     %s from its fence line: ends at %s, %d frames beyond the fence" % [id, str(a.cell()), out])
	check(out == 0, "%s: struck on its fence line, it never runs out of the pen (%d frames)" % [id, out])
	check(w.fauna.in_area(id, a.cell()), "%s: it gets off the fence into its pen" % id)


## A charging boar saved mid-charge loads where it was, with its wounds, calm (a fight is not saved), and reacts to the
## next blow (charging or running).
func test_save(w: World) -> void:
	var a := _forced(w, 1.0)
	_step(w, 1.0)
	check(a.anger != "", "mid-charge before saving")
	var d := w.to_dict()
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
	var b: Animal = w2.fauna.by_id(a.id)
	check(b != null and b.alive and b.pos.distance_to(a.pos) < 0.001 and is_equal_approx(b.hp, a.hp), "a charging boar saves and loads where it was, with its wounds")
	check(b != null and b.anger == "" and b.alarm == "" and b.startle_left == 0.0, "it loads calm")
	if b == null:
		return
	w2.player.pos = b.pos + Vector2(-1.5, 0.0)
	w2.player_hit_animal(b, 0.5)
	check(b.anger != "" or b.alarm != "", "struck again after loading, it charges or runs")
	_calm(w)


## Two worlds from the same seed, the same blows: the same choices and the same frames.
func test_deterministic() -> void:
	var trace := []
	for k in 2:
		var w := World.new()
		w.setup(VillageMap.load_default(), 7)
		var s := ""
		for i in 6:
			var a := _stage(w, "boar", Vector2(-1.5, 0.0))
			w.player_hit_animal(a, 0.5)
			s += "%s|" % ("C" if a.anger != "" else "F")
			for f in int(3.0 / DT):
				_frame(w)
				if f % 10 == 0:
					s += "%.4f,%.4f,%.1f;" % [a.pos.x, a.pos.y, w.player.hp]
		var pa: Animal = w.fauna.animals.filter(func(b): return b.alive and b.area == "pen_cow")[0]
		w.player.pos = pa.pos + Vector2(-1.0, 0.0)
		w.player_hit_animal(pa, 0.01)
		for f in int(6.0 / DT):
			_frame(w)
			if f % 10 == 0:
				s += "%.4f,%.4f;" % [pa.pos.x, pa.pos.y]
		trace.append(s)
	check(trace[0].contains("C|") and trace[0].contains("F|"), "the run holds both a charge and a flight (%s)" % trace[0].substr(0, 0))
	check(trace[0] == trace[1], "the same seed and blows give the same choices and frames")
