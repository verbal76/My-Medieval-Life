extends SceneTree
## MML-SAV-04 (owner decision 2026-11-10, option (a), docs/directives/2026-11-10_blocked_decisions_wp1.md): "A saved game must
## reload deterministically, but exact equivalence with an uninterrupted wildlife or combat simulation is not currently
## required. Document the limitation and verify deterministic repeated reloads. Do not silently discard persistent world state
## that existing gameplay rules require." Seed 1 is run two days, then a fight is set going in the middle of play (a villager
## fighting another, a wolf or bear angered at a villager, a tree half felled) and the world is saved. Checked:
##  1. the persistent state the rules read survives the save (fractions within ND-15's tolerance, as save_continuity_test): every animal (id, species, sex, age, area, alive, health,
##     hunger, position, breeding and product clocks), every pen's owner, tenant and trough, every villager's health, armour,
##     life and place, the hunters' claims (rebuilt from their saved plans);
##  2. what the save documents as not kept (docs/design/SAVE_WILDLIFE_COMBAT_CONTINUITY.md) is reset, not half kept: the fight,
##     the animal's anger, a tree's axe blows, and (Build 42) a struck animal's flight (B25-ANIMAL-HUNT-AI, Build 40: startle_left,
##     alarm, alarm_left, run_dir, zig_left, zig_side, slide, pause_left, breaking, at_bay): an animal saved mid-flight loads calm,
##     with its health and place, and runs again by the ordinary rules when struck after the load;
##  3. the same save loaded twice independently, and loaded, saved again and loaded (reload-save-reload), goes on identically
##     for six game hours: the whole saved world, plus the wildlife and combat transients the save leaves out;
##  4. saving straight after a load writes the same save again (a fixed point of load and save, within ND-15's tolerance).
##   godot --headless --path game -s res://tests/sav04_reload_determinism_test.gd

var checks := 0
var failures := 0


func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("ok   " if ok else "FAIL ") + what)


func run_hours(w: World, hours: float) -> void:
	var gmps := float(GameData.b("game_minutes_per_second"))
	for i in int(60.0 * hours / gmps / 0.5):
		w.update(0.5)


func save_text(w: World) -> String:
	return JSON.stringify(w.to_dict(), "", true, true)


func loaded(text: String) -> World:
	var w := World.new()
	w.load_dict(VillageMap.load_default(), JSON.parse_string(text))
	return w


## What the rules read of each animal, pen and villager (the persistent part).
func persistent(w: World) -> Dictionary:
	var d := {}
	for a: Animal in w.fauna.animals:
		d["animal%d" % a.id] = "%s|%s|%s|%s|%s|%s|%s|%s|%s|%s" % [a.species, a.sex, a.born, a.area, a.alive, a.hp, a.hunger,
			a.pos, a.next_birth, a.next_product]
	var pens := w.fauna.pens.keys()
	pens.sort()
	for id in pens:
		var p: Dictionary = w.fauna.pens[id]
		d["pen_" + str(id)] = "%s|%s|%s" % [p.owner, p.tenant, p.trough]
	for n: NPC in w.npcs:
		d["npc%d" % n.id] = "%s|%s|%s|%s|%s|%s|%s" % [n.alive, n.hp, n.max_hp, n.armor, n.damage, n.pos, n.depth]
	var claims := w.fauna.claims.keys()
	claims.sort()
	d["claims"] = str(claims.map(func(k): return [k, w.fauna.claims[k]]))
	return d


## The wildlife and combat transients the save leaves out (each loaded world makes its own again from its save).
func transients(w: World) -> String:
	var parts := ["move_rng %s" % w.fauna.move_rng.state]
	for a: Animal in w.fauna.animals:
		parts.append("a%d %s %s %s %s %s %s %s %s %s %s" % [a.id, a.goal, a.wait, a.moving, a.hunt, a.anger, a.anger_left, a.bite_cd, a.facing,
			a.act, a.act_left])
		# B25-ANIMAL-HUNT-AI (Build 40): a struck animal's flight, not saved either
		parts.append("f%d %s %s %s %s %s %s %s %s %s %s" % [a.id, a.startle_left, a.alarm, a.alarm_left, a.run_dir, a.zig_left, a.zig_side,
			a.slide, a.pause_left, a.breaking, a.at_bay])
	for n: NPC in w.npcs:
		parts.append("n%d %s %s %s" % [n.id, n.target, n.attack_cd, n.chase_route])
	var trees := w.tree_damage.keys()
	trees.sort()
	for c in trees:
		parts.append("t%s %s" % [c, w.tree_damage[c]])
	return "\n".join(parts)


func differing(a: Dictionary, b: Dictionary) -> Array:
	var out := []
	for k in a:
		if str(a[k]) != str(b.get(k, "<missing>")):
			out.append(k)
	for k in b:
		if not a.has(k):
			out.append(k)
	return out


## Two texts agree when every number in them agrees, whole numbers exactly and fractions within 1e-12 of their size, and the
## rest is the same (ND-15, B25-ND15-TOL-01: the game's full-precision JSON may bring a fraction back one unit in the last place
## off; save_continuity_test's rule).
func _within(x: String, y: String) -> bool:
	if x == y:
		return true
	var rx := RegEx.create_from_string("-?[0-9]+(\\.[0-9]+)?(e-?[0-9]+)?")
	var mx := rx.search_all(x)
	var my := rx.search_all(y)
	if mx.size() != my.size() or rx.sub(x, "#", true) != rx.sub(y, "#", true):
		return false
	for i in mx.size():
		var p := float(mx[i].get_string())
		var q := float(my[i].get_string())
		if p == q:
			continue
		if p == floorf(p) or absf(p - q) > 1e-12 * maxf(absf(p), 1.0):
			return false
	return true


func _init() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	run_hours(w, 48.0)
	# a fight in the middle of play: two awake adults on the surface, the first fighting the second, side by side
	var fighters := w.npcs.filter(func(n: NPC): return n.alive and n.role == "adult" and n.depth == 0 and n.journey.is_empty() \
		and n.target == -1 and n.job != "guard")
	check(fighters.size() >= 2, "seed 1 has two adults at home to set fighting (%d)" % fighters.size())
	var f1: NPC = fighters[0]
	var f2: NPC = fighters[1]
	f2.pos = f1.pos + Vector2(1, 0)
	f1.target = f2.id
	f1.attack_cd = 0.0
	# a wild animal that fights people, angered at a villager
	var biters := w.fauna.animals.filter(func(a: Animal): return a.alive and bool(a.spec().get("people", false)))
	check(not biters.is_empty(), "seed 1 has a wolf or bear in the woods (%d)" % biters.size())
	var beast: Animal = biters[0] if not biters.is_empty() else null
	if beast != null:
		w.fauna.provoke(beast, "npc:%d" % f2.id)
	# and a tree with axe blows in it (World.tree_damage)
	w.tree_damage[Vector2i(3, 3)] = {"hits": 2, "side": 1, "at": w.minutes}
	run_hours(w, 0.25)                 # a quarter of an hour into the fight
	# and a struck animal running from its attacker (B25-ANIMAL-HUNT-AI): a villager strikes a grazer and it is saved mid-flight
	var prey := w.fauna.animals.filter(func(a: Animal): return a.alive and not bool(a.spec().get("people", false)) \
		and not w.fauna.pens.has(a.area))
	check(not prey.is_empty(), "seed 1 has a wild grazer to strike (%d)" % prey.size())
	var runner: Animal = prey[0] if not prey.is_empty() else null
	if runner != null:
		var striker: NPC = fighters[2] if fighters.size() > 2 else f1
		w.fauna.provoke(runner, "npc:%d" % striker.id)
		for i in 3:
			w.update(0.5)              # past the startle (startle_seconds 0.35), into the flight (flee_seconds 6)
		check(runner.alive and runner.alarm != "" and runner.alarm_left > 0.0 and runner.startle_left == 0.0, \
			"the world is saved with a struck %s mid-flight (alarm '%s', %.1f s left)" % [runner.species, runner.alarm, runner.alarm_left])
	var mid_fight := f1.target != -1 or (beast != null and beast.anger != "")
	check(mid_fight, "the world is saved with a fight going on (villager target %d, animal anger '%s')" % [f1.target, beast.anger if beast != null else ""])
	var hp_before := f2.hp
	var s := save_text(w)
	var before := persistent(w)

	# 1 and 2: what is kept and what is not
	var l1 := loaded(s)
	var after := persistent(l1)
	var lost := differing(before, after).filter(func(k): return not _within(str(before[k]), str(after.get(k, ""))))
	check(lost.is_empty(), "every animal, pen, villager's health and place and hunter's claim survives the save (%d differ: %s)" % [lost.size(), str(lost.slice(0, 6))])
	check(l1.fauna.animals.size() == w.fauna.animals.size() and l1.npcs.size() == w.npcs.size(), "no animal or villager is dropped")
	check(is_equal_approx(l1.npc(f2.id).hp, hp_before), "the wounds of the fight are kept (health %.2f, saved %.2f)" % [l1.npc(f2.id).hp, hp_before])
	check(l1.npc(f1.id).target == -1, "the fight itself is not kept (documented): the fighter decides again after loading")
	if beast != null:
		var lb: Animal = null
		for a: Animal in l1.fauna.animals:
			if a.id == beast.id:
				lb = a
		check(lb != null and lb.anger == "" and lb.alive == beast.alive and lb.hp == beast.hp, "the animal is kept with its health; its anger is not (documented)")
	check(l1.tree_damage.is_empty(), "a tree's axe blows are not kept (documented: they heal)")
	if runner != null:
		var lr: Animal = null
		for a: Animal in l1.fauna.animals:
			if a.id == runner.id:
				lr = a
		var fresh := Animal.new()
		var calm := lr != null and lr.startle_left == fresh.startle_left and lr.alarm == fresh.alarm and lr.alarm_left == fresh.alarm_left \
			and lr.run_dir == fresh.run_dir and lr.zig_left == fresh.zig_left and lr.zig_side == fresh.zig_side and lr.slide == fresh.slide \
			and lr.pause_left == fresh.pause_left and lr.breaking == fresh.breaking and lr.at_bay == fresh.at_bay
		check(calm and lr.alive == runner.alive and _within(str(lr.pos), str(runner.pos)) and _within(str(lr.hp), str(runner.hp)), \
			"the animal saved mid-flight loads calm (its ten flight fields at their defaults, documented), alive, with its health and place")
		# loads sensibly: in a separate copy, struck again after the load it is startled and runs by the ordinary rules
		var l4 := loaded(s)
		var r4: Animal = null
		for a: Animal in l4.fauna.animals:
			if a.id == runner.id:
				r4 = a
		var striker4: NPC = l4.npc(fighters[2].id if fighters.size() > 2 else f1.id)
		var p0 := r4.pos
		l4.fauna.provoke(r4, "npc:%d" % striker4.id)
		for i in 6:
			l4.update(0.5)
		check(r4.alarm != "" and r4.pos.distance_to(p0) > 0.1, "struck again after the load it runs by the ordinary rules (moved %.2f tiles)" % r4.pos.distance_to(p0))
		for i in 40:
			l4.update(0.5)             # 20 s: past flee_seconds; it calms down unless still within calm_distance of its attacker
		check(r4.alarm == "" or r4.pos.distance_to(striker4.pos) <= float(GameData.b("wildlife").struck.calm_distance) + 1.0, \
			"and its flight ends by the ordinary rules (alarm '%s')" % r4.alarm)

	# 4: a save is a fixed point of load and save
	var s2 := save_text(l1)
	var c1 := JSON.stringify(JSON.parse_string(s), "", true, true)
	var c2 := JSON.stringify(JSON.parse_string(s2), "", true, true)
	check(_within(c1, c2), "saving straight after loading writes the same save again (every text and whole number exact, fractions within ND-15's 1e-12; %s)" % ("identical" if c1 == c2 else "some fractions one unit in the last place off"))

	# 3: repeated reloads go on identically
	var l2 := loaded(s)
	var l3 := loaded(s2)               # reload-save-reload
	for x: World in [l1, l2, l3]:
		run_hours(x, 6.0)
	var t1 := save_text(l1)
	check(t1 == save_text(l2), "the same save loaded twice goes on identically for six hours (the whole saved world)")
	check(t1 == save_text(l3), "loaded, saved again and loaded, it goes on identically too")
	check(transients(l1) == transients(l2) and transients(l1) == transients(l3), "and so do the wildlife and combat transients the save leaves out (animals' strolls, anger, bites, flights; villagers' fights; trees)")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
