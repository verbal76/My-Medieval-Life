extends SceneTree
## X20-BANDIT-AI (owner directive 2026-10-31, SJD-H C4): controlled encounters for the bandits' threat assessment
## (JudgmentBandit). Each sets the scene by hand in a real World and runs the live fight step (NPCBrain.fight):
##   1. an outnumbered bandit breaks off its robbery and falls back to the camp, and a fall-back holds while the way is open
##   2. a cornered bandit strikes the one barring the way to the camp
##   3. a fellow bandit goes to the aid of a friend under attack, and leaves a stranger in the band to it
##   4. a victim striking back is fought, never "robbed" again and again (the re-robbing loop of the SJD-G soak)
##   5. villagers can still organise and win: three of them run a lone bandit down
##   6. no repeated hopeless combat: a hurt, outnumbered bandit struck again and again never turns back into the fight
##   7. off (decision.integration.bandit_danger false): the Build 24 behaviour, unchanged
## Nothing is added to health, damage or speed anywhere.
##   godot --headless --path game --script res://tests/bandit_ai_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _init() -> void:
	test_outnumbered_retreats()
	test_cornered_breaks_out()
	test_companion_aid()
	test_no_rerobbing()
	test_villagers_win()
	test_no_hopeless_combat()
	test_off_is_unchanged()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func world(seed := 1) -> World:
	JudgmentLive.test_disabled = false
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


func bandits(w: World) -> Array:
	return w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "bandit")


func adults(w: World) -> Array:
	return w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.job != "guard" and n.household >= 0)


## An open spot with open ground for `d` tiles in some direction; the camp is moved to the far end for the scene (a test
## stage: the real camp lies in the woods, where a straight chase is soon blocked). Returns [spot, unit vector to the camp].
func spot(w: World, d: float) -> Array:
	for y in range(8, w.map.h - 8, 3):
		for x in range(8, w.map.w - 8, 3):
			var p := Vector2(x, y) + Vector2(0.5, 0.5)
			if not _open_box(w, p) or w.place_of(p) != "":
				continue
			for q in 8:
				var dir := Vector2.RIGHT.rotated(deg_to_rad(q * 45.0))
				var c := p + dir * d
				if _open_box(w, c) and _open_line(w, p - dir * 4.0, c):
					w.bandit_camp = Vector2i(floori(c.x), floori(c.y))
					return [p, dir]
	push_error("no open ground %d tiles long" % int(d))
	return [Vector2(w.bandit_camp) + Vector2(d, 0), Vector2.LEFT]


func _open_box(w: World, p: Vector2) -> bool:
	for k in range(-3, 4):
		for s in range(-3, 4):
			if w.map.is_solid(Vector2i(floori(p.x + k), floori(p.y + s))):
				return false
	return true


## Open ground all the way to the camp (a chase in the open, not one a fence ends).
func _open_line(w: World, a: Vector2, b: Vector2) -> bool:
	var n := int(a.distance_to(b) * 2.0)
	for i in n:
		var q := a.lerp(b, float(i) / float(maxi(1, n)))
		for o in [Vector2.ZERO, Vector2(0.6, 0), Vector2(-0.6, 0), Vector2(0, 0.6), Vector2(0, -0.6)]:
			if w.map.is_solid(Vector2i(floori(q.x + o.x), floori(q.y + o.y))):
				return false
	return true


func _clear(w: World, p: Vector2) -> bool:
	for o: NPC in w.npcs:
		if o.alive and o.pos.distance_to(p) < 14.0:
			return false
	return true


## Park everyone else far off, so only the scene's people are in sight.
func clear_stage(w: World, keep: Array) -> void:
	var far := Vector2(-500, -500)
	for o: NPC in w.npcs:
		if not keep.has(o):
			o.pos = far
			o.target = -1
			o.plan = []


func stage(w: World, who: Array, at: Vector2) -> void:
	for o: NPC in who:
		o.pos = at
		o.plan = []
		o.attack_cd = 0.0
		o.hp = o.max_hp


func test_outnumbered_retreats() -> void:
	var w := world()
	var b: NPC = bandits(w)[0]
	var ppl := adults(w)
	var v: NPC = ppl[0]
	var s := spot(w, 20.0)
	var p: Vector2 = s[0]
	var back: Vector2 = s[1]
	clear_stage(w, [b, v, ppl[1], ppl[2], ppl[3]])
	stage(w, [b], p)
	v.pos = p - back * 1.0                                       # the prey, away from the camp side
	for i in 3:                                                  # three come at it, from the far side too
		stage(w, [ppl[1 + i]], p - back * 2.0 + back.orthogonal() * float(i - 1))
		ppl[1 + i].target = b.id
	b.target = v.id
	w.brain.bandit_prey[b.id] = v.id
	w.brain.fight(b, 0.5)
	check(b.target == -1 and w.brain.bandit_retreat.has(b.id), "one bandit, three coming at it: it breaks off and falls back")
	check(not b.plan.is_empty() and Vector2(b.plan[0].to).distance_to(Vector2(w.bandit_camp)) < 1.0, "...to the camp, where the band is")
	b.target = ppl[1].id                                         # struck on the way: the blow turns it towards the striker
	w.brain.fight(b, 0.5)
	check(b.target == -1 and w.brain.bandit_retreat.has(b.id), "...struck while falling back with the way open, it keeps falling back")
	w.dispose()


func test_cornered_breaks_out() -> void:
	var w := world()
	var b: NPC = bandits(w)[0]
	var x: NPC = adults(w)[4]
	var s := spot(w, 20.0)
	var p: Vector2 = s[0]
	var back: Vector2 = s[1]
	clear_stage(w, [b, x])
	stage(w, [b], p)
	stage(w, [x], p + back * 1.5)                                # between it and the camp
	x.target = b.id
	w.brain.bandit_retreat[b.id] = w.judgment.now_minute()
	b.target = x.id
	w.brain.fight(b, 0.5)
	check(b.target == x.id and not w.brain.bandit_retreat.has(b.id), "a bandit falling back finds one barring the way to the camp: it strikes that one")
	w.dispose()


func test_companion_aid() -> void:
	var w := world()
	var bs := bandits(w)
	var hit: NPC = bs[0]
	var friend: NPC = bs[1]
	var stranger: NPC = bs[2]
	var v: NPC = adults(w)[5]
	var s := spot(w, 20.0)
	var p: Vector2 = s[0]
	clear_stage(w, [hit, friend, stranger, v])
	stage(w, [hit], p)
	stage(w, [friend, stranger], p + Vector2(3, 0))
	stage(w, [v], p + Vector2(-1, 0))
	var t := w.relations.tie(friend.id, hit.id)
	t.regard = 60.0
	t.friends = true
	w.relations.tie(stranger.id, hit.id).regard = 0.0
	v.target = hit.id
	w.brain.fight(v, 0.5)                                        # the villager's blow lands on the bandit
	check(friend.target == v.id, "a bandit sees its friend struck: it goes to its aid")
	check(stranger.target == -1, "...one who thinks nothing of the struck bandit leaves it to it (no universal loyalty)")
	w.dispose()


func test_no_rerobbing() -> void:
	var w := world()
	var b: NPC = bandits(w)[0]
	var v: NPC = adults(w)[6]
	var s := spot(w, 20.0)
	var p: Vector2 = s[0]
	clear_stage(w, [b, v])
	stage(w, [b], p)
	stage(w, [v], p + Vector2(0.9, 0))
	v.coins = 40
	b.target = v.id
	w.brain.bandit_prey[b.id] = v.id
	w.brain.fight(b, 0.5)
	check(v.coins == 20 and b.target == -1, "the bandit robs the prey it chose, once, and makes off")
	var coins_after := v.coins
	for i in 6:                                                  # the victim strikes back, again and again
		v.target = b.id
		v.attack_cd = 0.0
		w.brain.fight(v, 0.5)
		b.attack_cd = 0.0
		if b.target != -1:
			w.brain.fight(b, 0.5)
	check(v.coins == coins_after, "a victim striking back is never robbed again in the same encounter (was a robbery every two minutes)")
	w.dispose()


func test_villagers_win() -> void:
	var w := world()
	var b: NPC = bandits(w)[0]
	var ppl := adults(w)
	var s := spot(w, 22.0)
	var p: Vector2 = s[0]
	var back: Vector2 = s[1]
	var hunters := [ppl[7], ppl[8], ppl[9]]
	clear_stage(w, [b] + hunters)
	stage(w, [b], p)
	for i in 3:
		stage(w, [hunters[i]], p - back * 1.0 + back.orthogonal() * float(i - 1))
		hunters[i].target = b.id
	for t in 600:
		for h: NPC in hunters:
			if h.alive and h.target != -1:
				w.brain.fight(h, 0.5)
			h.attack_cd = maxf(0.0, h.attack_cd - 0.5)
		if not b.alive:
			break
		if b.target != -1:
			w.brain.fight(b, 0.5)
		elif not b.plan.is_empty():
			w._run_plan(b, 0.5, 1.0)
		b.attack_cd = maxf(0.0, b.attack_cd - 0.5)
	check(not b.alive, "three villagers who mean it run a lone bandit down and kill it (retaliation can still succeed)")
	w.dispose()


func test_no_hopeless_combat() -> void:
	var w := world()
	var b: NPC = bandits(w)[0]
	var ppl := adults(w)
	var s := spot(w, 20.0)
	var p: Vector2 = s[0]
	var back: Vector2 = s[1]
	clear_stage(w, [b, ppl[10], ppl[11]])
	stage(w, [b], p)
	b.hp = b.max_hp * 0.45
	stage(w, [ppl[10], ppl[11]], p - back * 1.2)
	ppl[10].target = b.id
	ppl[11].target = b.id
	b.target = ppl[10].id
	var pressed := 0
	var j: JudgmentStore = w.judgment
	for i in 10:
		var before := int(j.stats.get("bandit_press", 0))
		b.target = ppl[10 + i % 2].id                            # each blow it takes turns it towards the striker
		w.brain.fight(b, 0.5)
		pressed += int(j.stats.get("bandit_press", 0)) - before
	check(pressed == 0 and w.brain.bandit_retreat.has(b.id), "hurt and two against one, struck ten times: it never turns back into the fight (%d)" % pressed)
	w.dispose()


func test_off_is_unchanged() -> void:
	var w := world()
	w.judgment.cfg.decision.integration.bandit_danger = false
	var b: NPC = bandits(w)[0]
	var v: NPC = adults(w)[12]
	var s := spot(w, 20.0)
	var p: Vector2 = s[0]
	clear_stage(w, [b, v])
	stage(w, [b], p)
	stage(w, [v], p + Vector2(0.9, 0))
	v.coins = 40
	b.target = v.id
	w.brain.fight(b, 0.5)
	v.target = b.id
	b.target = v.id                                              # the old rule: struck back, it robs again
	b.attack_cd = 0.0
	w.brain.fight(b, 0.5)
	check(v.coins == 10, "off: the Build 24 rule is untouched (a second robbery, 40 -> 20 -> 10)")
	check(int(w.judgment.stats.get("bandit_press", 0)) + int(w.judgment.stats.get("bandit_retreat", 0)) == 0, "...and nothing is weighed")
	w.dispose()
