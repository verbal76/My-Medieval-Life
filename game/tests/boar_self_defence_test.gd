extends SceneTree
## B25 boar self-defence (owner 2026-11-13, docs/directives/2026-11-13_b25_boar_livestock_owner_decisions.md, decisions 3
## and 4): "Apply the existing wolf/bear self-defense rules to boars. Killing a boar that qualifies as an active threat
## under those rules should count as self-defense. Do not create a loophole where deliberately provoking an animal
## automatically grants legal immunity." "Add deterministic tests for boar self-defense, including qualifying attacks,
## nonqualifying attacks, and save/load consistency where applicable."
## Run: godot --headless --path game --script res://tests/boar_self_defence_test.gd
## The wolf/bear rules are two: a wild animal fighting someone is a family-danger threat (JudgmentFamily._threats, read
## through Fauna.active_threat), and the player putting one down near villagers is a defence (World.player_hit_animal:
## Relations.defended, the judgment's rescue; Fauna.defence_kill). Killing a wild animal is no crime for anyone, so a
## defence is a classification with social effect only. A boar is a threat only while it charges; killing it counts only
## when its charge was not started by the killer's own blow. Fights are not saved (an animal loads calm), wolf and boar alike.

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
	test_wolf_rules(w)
	test_charging_boar_threat(w)
	test_qualifying_kill(w)
	test_defender_strikes_then_kills(w)
	test_calm_boar(w)
	test_fleeing_boar(w)
	test_at_bay_boar(w)
	test_provoker_no_immunity(w)
	test_provoker_after_switch(w)
	test_save_load(w)
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
		a.charge_by = ""
		a.hunt = -1
		a.alarm = ""
		a.startle_left = 0.0
		a.at_bay = false


## An animal of `species` in the open in the west wood, the player `off` from it, and a grown, awake villager (`witness`)
## two tiles the other way, out of the fight, so a defence there has someone to see it.
var witness: NPC = null
func _stage(w: World, species: String, off: Vector2) -> Animal:
	_calm(w)
	if _of(w, species).is_empty():                      # the kills here use the wood up: a grown one more (test staging only)
		var nb := w.fauna.spawn("woods_w", species, "m", null)
		nb.born = w.minutes - 1440.0 * 400.0
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
	a.breaking = false
	a.pause_left = 0.0
	w.player.pos = a.pos + off
	w.player.alive = true
	w.player.hp = float(GameData.b("player_max_hp"))
	if witness == null:
		for n: NPC in w.npcs:
			if n.alive and n.role == "adult" and n.job != "guard" and n.depth == 0:
				witness = n
				break
	witness.pos = a.pos - off.normalized() * 2.0
	witness.hp = witness.max_hp
	witness.depth = 0
	witness.plan = []
	w.relations.tie(w.acting_id(), witness.id).defend_day = -1
	w.judgment.threat_cache = {}
	return a


## Struck by `who` with the charge chances forced to `p` (the number drawn still comes from the stream).
func _strike(w: World, a: Animal, who: String, p: float) -> void:
	var c := ch()
	var keep := [c.chance, c.hurt_chance, c.cornered_chance]
	c.chance = p
	c.hurt_chance = p
	c.cornered_chance = p
	if who == w.acting_ref():
		w.player_hit_animal(a, 0.5)
	else:
		w.fauna.provoke(a, who)
	c.chance = keep[0]
	c.hurt_chance = keep[1]
	c.cornered_chance = keep[2]


func _threat_listed(w: World, a: Animal) -> bool:
	w.judgment.threat_cache = {}
	for t in JudgmentFamily._threats(w):
		if str(t.kind) == "beast" and t.animal == a:
			return true
	return false


## The player kills `a`: whether it counted as a defence, by the return and by its effect (the witness's tie marks the day).
func _kill(w: World, a: Animal) -> Dictionary:
	var h := w.player_hit_animal(a, 1000.0)
	var seen := int(w.relations.tie(w.acting_id(), witness.id).defend_day) == w.day()
	return {"killed": bool(h.killed), "defence": bool(h.get("defence", false)), "seen": seen}


func _npc_ref() -> String:
	return "npc:%d" % witness.id


## The wolf/bear rules, unchanged: fighting someone, a threat; calm, not; killed by the player, a defence either way.
func test_wolf_rules(w: World) -> void:
	var wolf := _stage(w, "wolf", Vector2(-1.5, 0.0))
	check(not Fauna.active_threat(wolf) and not _threat_listed(w, wolf), "a calm wolf is no threat")
	w.fauna.provoke(wolf, _npc_ref())
	check(Fauna.active_threat(wolf) and _threat_listed(w, wolf), "a wolf fighting a villager is a family-danger threat")
	var k := _kill(w, wolf)
	check(k.killed and k.defence and k.seen, "the player killing it is a defence the villager saw")
	var wolf2 := _stage(w, "wolf", Vector2(-1.5, 0.0))
	var k2 := _kill(w, wolf2)
	check(k2.killed and k2.defence, "a wolf put down near villagers is a defence even calm, as before (CRT-10)")


## A boar charging a villager (who struck it) is a family-danger threat, from the startle on.
func test_charging_boar_threat(w: World) -> void:
	var a := _stage(w, "boar", Vector2(-1.5, 0.0))
	_strike(w, a, _npc_ref(), 1.0)
	check(a.anger == _npc_ref() and a.charge_by == _npc_ref(), "forced, the struck boar charges the villager who struck it")
	check(Fauna.active_threat(a) and _threat_listed(w, a), "a charging boar is an active threat, listed as a beast")
	_step(w, 1.0)
	check(a.anger != "" and _threat_listed(w, a), "still a threat as it closes in")


## Qualifying: the player kills a boar charging someone else: a defence, the witness sees it, as for a wolf.
func test_qualifying_kill(w: World) -> void:
	var a := _stage(w, "boar", Vector2(-1.5, 0.0))
	_strike(w, a, _npc_ref(), 1.0)
	var k := _kill(w, a)
	check(k.killed and k.defence, "killing a boar that charges a villager is a defence")
	check(k.seen, "the villager nearby counts it (Relations.defended)")


## Qualifying, with a blow first: the player strikes a boar charging a villager (the fight turns on the player) and then
## kills it: still a defence, the charge was the villager's.
func test_defender_strikes_then_kills(w: World) -> void:
	var a := _stage(w, "boar", Vector2(-1.5, 0.0))
	_strike(w, a, _npc_ref(), 1.0)
	w.player_hit_animal(a, 0.5)
	check(a.anger == w.acting_ref() and a.charge_by == _npc_ref(), "struck by the player, it turns on them; the charge stays the villager's")
	var k := _kill(w, a)
	check(k.killed and k.defence and k.seen, "killing it then is still a defence")


## Non-qualifying: a calm boar is no threat; killing it is a hunt.
func test_calm_boar(w: World) -> void:
	var a := _stage(w, "boar", Vector2(-1.5, 0.0))
	check(not Fauna.active_threat(a) and not _threat_listed(w, a), "a calm (grazing) boar is no threat")
	var k := _kill(w, a)
	check(k.killed and not k.defence and not k.seen, "killing a calm boar is no defence")


## Non-qualifying: a boar running from a blow is no threat; killing it is no defence.
func test_fleeing_boar(w: World) -> void:
	var a := _stage(w, "boar", Vector2(-1.5, 0.0))
	_strike(w, a, _npc_ref(), 0.0)
	check(a.anger == "" and a.alarm == _npc_ref(), "forced not to charge, it runs")
	_step(w, 1.0)
	check(not Fauna.active_threat(a) and not _threat_listed(w, a), "a fleeing boar is no threat")
	var k := _kill(w, a)
	check(k.killed and not k.defence and not k.seen, "killing a fleeing boar is no defence")


## Non-qualifying: a boar standing at bay without charging is no threat.
func test_at_bay_boar(w: World) -> void:
	var a := _stage(w, "boar", Vector2(-1.5, 0.0))
	a.alarm = _npc_ref()
	a.alarm_left = 5.0
	a.at_bay = true
	check(not Fauna.active_threat(a) and not _threat_listed(w, a), "a boar at bay that does not charge is no threat")
	var k := _kill(w, a)
	check(k.killed and not k.defence, "killing it is no defence")


## Non-qualifying (the loophole): the player strikes a calm boar, it charges them, they kill it: a danger to families while
## it charges, but the kill gains the player nothing, however close it came.
func test_provoker_no_immunity(w: World) -> void:
	var a := _stage(w, "boar", Vector2(-1.5, 0.0))
	_strike(w, a, w.acting_ref(), 1.0)
	check(a.anger == w.acting_ref() and a.charge_by == w.acting_ref(), "the player's blow starts its charge at them")
	check(Fauna.active_threat(a) and _threat_listed(w, a), "charging, it is still a danger to those nearby")
	_step(w, 1.5)
	var hp_before := w.player.hp
	check(a.anger == w.acting_ref(), "still charging the player")
	var k := _kill(w, a)
	check(k.killed and not k.defence and not k.seen, "the provoker killing it gains no defence (%.1f health left)" % hp_before)


## The loophole through someone else: the player provokes it, a villager then strikes it (it turns on them), and the
## player kills it: the charge was the player's, so still no defence.
func test_provoker_after_switch(w: World) -> void:
	var a := _stage(w, "boar", Vector2(-1.5, 0.0))
	_strike(w, a, w.acting_ref(), 1.0)
	w.fauna.provoke(a, _npc_ref())
	check(a.anger == _npc_ref() and a.charge_by == w.acting_ref(), "struck by a villager, it fights them; the charge stays the player's")
	var k := _kill(w, a)
	check(k.killed and not k.defence and not k.seen, "the player who started it killing it gains no defence")


## Save and load in the middle of a charge: a fight is not saved (wolves and boars alike), so it loads calm, no threat,
## its kill no defence, with no stale charge; loading the same save twice gives the same classification and outcome; the
## save holds no new key; struck again by the player after loading, it is the player's charge again (no immunity).
func test_save_load(w: World) -> void:
	var a := _stage(w, "boar", Vector2(-1.5, 0.0))
	_strike(w, a, _npc_ref(), 1.0)
	_step(w, 0.8)
	check(Fauna.active_threat(a), "mid-charge before saving")
	var d := w.to_dict()
	var text := JSON.stringify(d)
	check(not text.contains("charge_by"), "the save holds no charge (fights are not saved)")
	var outs := []
	for i in 2:
		var w2 := World.new()
		w2.load_dict(VillageMap.load_default(), JSON.parse_string(text))
		var b: Animal = w2.fauna.by_id(a.id)
		var listed := false
		for t in JudgmentFamily._threats(w2):
			if str(t.kind) == "beast" and t.animal == b:
				listed = true
		var o := {"anger": b.anger, "by": b.charge_by, "threat": Fauna.active_threat(b), "listed": listed,
			"defence": Fauna.defence_kill(b, w2.acting_ref())}
		w2.player.pos = b.pos + Vector2(-1.5, 0.0)
		var c := ch()
		var keep: float = c.chance
		c.chance = 1.0
		w2.player_hit_animal(b, 0.5)
		c.chance = keep
		o["re_by"] = b.charge_by
		o["re_threat"] = Fauna.active_threat(b)
		o["re_defence"] = bool(w2.player_hit_animal(b, 1000.0).get("defence", true))
		outs.append(o)
	var o0: Dictionary = outs[0]
	check(o0.anger == "" and o0.by == "" and not o0.threat and not o0.listed, "loaded, it is calm and no threat (as a wolf's fight, not saved)")
	check(not o0.defence, "killed straight after loading, no defence")
	check(o0.re_by == w.acting_ref() and o0.re_threat and not o0.re_defence, "struck by the player after loading, it is their charge: killing it no defence")
	check(outs[0] == outs[1], "the same save loaded twice gives the same classification and outcome")
	_calm(w)


## Two worlds from the same seed, the same blows and kills: the same classifications.
func test_deterministic() -> void:
	var trace := []
	for k in 2:
		var w := World.new()
		w.setup(VillageMap.load_default(), 7)
		witness = null
		var s := ""
		for i in 8:
			var a := _stage(w, "boar", Vector2(-1.5, 0.0))
			var who := w.acting_ref() if i % 2 == 0 else _npc_ref()
			if who == w.acting_ref():
				w.player_hit_animal(a, 0.5)
			else:
				w.fauna.provoke(a, who)
			s += "%s%s|" % ["C" if a.anger != "" else "F", "T" if Fauna.active_threat(a) else "-"]
			for f in int(1.0 / DT):
				_frame(w)
			var kk := _kill(w, a)
			s += "%s;" % ("D" if kk.defence else "h")
		trace.append(s)
	witness = null
	print("     trace: %s" % trace[0])
	check(trace[0].contains("D") and trace[0].contains("h"), "the run holds both a defence and a plain kill")
	check(trace[0] == trace[1], "the same seed, blows and kills give the same classifications")


var acc := 0.0
func _frame(w: World) -> void:
	acc += DT
	if acc >= World.TICK - 0.000001:
		acc -= World.TICK
		w.fauna.update(World.TICK)


func _step(w: World, t: float) -> void:
	for i in int(round(t / DT)):
		_frame(w)
