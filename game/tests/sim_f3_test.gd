extends SceneTree
## SIM-F3 (owner D18, answer C, ENGINEERING): a bandit stalking at night keeps a lasting plan instead of deciding again
## every tick. Root cause: NPCBrain._bandit set `n.target` and returned with an empty plan; fight() dropped a target beyond
## CHASE_RANGE on the next tick (out_of_range) and a chase blocked by a wall sent the bandit to the camp, where it chose the
## same prey again, so decide() ran again and again (recorder run 1: 400+ empty decisions a day a bandit).
## Checks: an out-of-range prey gives a watch step that lasts with no decision while nothing changes and ends when the prey
## comes within range (then the chase starts as before); a blocked chase is not repeated while the prey stands in the same
## cell; the watch ends at dawn, when the prey goes indoors, and after STALK_WATCH_MINUTES.
##   godot --headless --path game --script res://tests/sim_f3_test.gd

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL: " + what)


## An open (outdoor, walkable) cell at about `dist` tiles east of `from`, or the nearest one found around it.
func _open_cell(w: World, from: Vector2, dist: float) -> Vector2:
	for r in 12:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var c := Vector2i(floori(from.x + dist) + dx, floori(from.y) + dy)
				var p := Vector2(c) + Vector2(0.5, 0.5)
				if not w.map.is_solid(c) and w.place_of(p) == "":
					return p
	return from + Vector2(dist, 0)


func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var b: NPCBrain = w.brain
	var bandit: NPC = null
	var prey: NPC = null
	for n: NPC in w.npcs:
		if bandit == null and n.alive and n.role == "bandit":
			bandit = n
		if prey == null and n.alive and n.role == "adult" and n.job != "guard" and n.clan == "":
			prey = n
	check(bandit != null and prey != null, "a bandit and a villager")
	for n: NPC in w.npcs:                         # only `prey` can be stalked: everyone else is out of reach (another level)
		if n != prey and n.role != "bandit":
			n.depth = 9
	for pl: PlayerState in w.active_players():
		pl.pos = Vector2(-500, -500)
	prey.coins = maxi(prey.coins, 10)
	w.minutes = float(w.day() + 1) * World.DAY + 22.0 * 60.0     # 22:00, night
	var camp := Vector2(w.bandit_camp) + Vector2(0.5, 0.5)
	bandit.pos = camp
	bandit.hp = bandit.max_hp
	bandit.target = -1

	# 1. the prey beyond CHASE_RANGE (but near enough the camp to be chosen): a watch, not an empty plan
	prey.pos = _open_cell(w, camp, NPCBrain.CHASE_RANGE + 8.0)
	check(prey.pos.distance_to(bandit.pos) > NPCBrain.CHASE_RANGE and prey.pos.distance_to(camp) < 40.0, "the prey is out of chase range (%.1f tiles)" % prey.pos.distance_to(bandit.pos))
	bandit.plan.clear()
	b.decide(bandit)
	check(bandit.target == -1, "no chase is started that fight() would drop at once")
	check(bandit.plan.size() == 1 and bandit.plan[0].k == "watch" and int(bandit.plan[0].prey) == prey.id, "the stalk is a watch step on the prey")
	check(bandit.doing == "stalking", "and the bandit is shown stalking")
	var before := int(b.decide_calls.get(bandit.id, 0))
	for i in 20:
		w._run_plan(bandit, 0.5, 1.0)
	check(not bandit.plan.is_empty() and int(b.decide_calls.get(bandit.id, 0)) == before, "20 ticks with nothing changed: the watch stands, no decision")

	# 2. the prey comes within range: the watch ends, and the next decision chases as before
	prey.pos = _open_cell(w, camp, 10.0)
	w._run_plan(bandit, 0.5, 1.0)
	check(bandit.plan.is_empty(), "the prey within range ends the watch")
	b.decide(bandit)
	check(bandit.target == prey.id, "and the chase starts (the live rule)")
	bandit.target = -1

	# 3. a blocked chase (SIM-F4's give-up) is not repeated while the prey stands in the same cell
	b.stalk_lost[bandit.id] = {"prey": prey.id, "cell": NPCBrain._cell_of(prey)}
	bandit.plan.clear()
	b.decide(bandit)
	check(bandit.target == -1 and not bandit.plan.is_empty() and bandit.plan[0].k == "watch", "the same prey in the same cell: a watch, not the same blocked chase")
	for i in 10:
		w._run_plan(bandit, 0.5, 1.0)
	check(not bandit.plan.is_empty(), "held while the prey stays put")
	prey.pos += Vector2(1.0, 0.0)
	if w.map.is_solid(NPCBrain._cell_of(prey)):
		prey.pos -= Vector2(2.0, 0.0)
	w._run_plan(bandit, 0.5, 1.0)
	check(bandit.plan.is_empty(), "the prey moving to another cell ends it")
	b.decide(bandit)
	check(bandit.target == prey.id, "and the chase is tried again")
	bandit.target = -1
	b.stalk_lost.erase(bandit.id)

	# 4. the watch ends on real changes: time, dawn, the prey indoors
	prey.pos = _open_cell(w, camp, NPCBrain.CHASE_RANGE + 8.0)
	bandit.plan.clear()
	b.decide(bandit)
	var s: Dictionary = bandit.plan[0]
	check(not b.watch_over(bandit, s), "a fresh watch is not over")
	w.minutes += NPCBrain.STALK_WATCH_MINUTES
	check(b.watch_over(bandit, s), "over after STALK_WATCH_MINUTES (the prey is chosen afresh)")
	w.minutes -= NPCBrain.STALK_WATCH_MINUTES
	var night := w.minutes
	w.minutes = float(w.day() + 1) * World.DAY + 6.0 * 60.0
	s.until = w.minutes + 30.0
	check(b.watch_over(bandit, s), "over at dawn")
	w.minutes = night
	prey.depth = 9
	check(b.watch_over(bandit, s), "over when the prey is out of reach")
	prey.depth = bandit.depth

	# 5. the whole loop: an hour of night ticks with the prey out of range costs a decision or two, not one a tick
	bandit.plan.clear()
	before = int(b.decide_calls.get(bandit.id, 0))
	for i in 60:
		if bandit.target != -1:
			b.fight(bandit, 0.5)
		elif bandit.plan.is_empty():
			b.decide(bandit)
		w._run_plan(bandit, 0.5, 1.0)
		w.minutes += 1.0
	var made := int(b.decide_calls.get(bandit.id, 0)) - before
	check(made <= 3, "60 night ticks, prey out of range: %d decisions (was one every other tick)" % made)

	print("\nsim_f3_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
