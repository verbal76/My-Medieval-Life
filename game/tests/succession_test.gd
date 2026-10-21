extends SceneTree
## EQ-04 (owner directive 2026-10-19: "A functioning society survives individual losses"): focused checks of what is
## verifiable without a long run. Leadership: when the reeve dies the manor's business goes on, the office opens, an adult
## of the village takes it after succession_days (the late reeve's household first) or a newcomer comes with the caravan,
## and the new reeve keeps the manor (public works resume). Households: a provider's death is answered at once (the
## household's position recomputed, the heir holding what the provider left). The trades' own succession (B8-016) is
## tested in world_test.gd (_succession).
##   godot --headless --path game --script res://tests/succession_test.gd

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
	GameData.ensure()
	reeve_from_the_village()
	reeve_from_the_caravan()
	provider_lost()
	guards_replaced()
	guards_unaffordable()
	failed_business()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func new_world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


## Advance the world's clock by whole days (the calendar only; nothing else runs).
func skip_days(w: World, d: int) -> void:
	w.minutes += float(d) * 1440.0


func reeve_from_the_village() -> void:
	var w := new_world()
	var b: NPCBrain = w.brain
	var old := w.npc(w.reeve_id)
	var t0 := w.treasury
	w.kill(old, "fever")
	check(w.treasury == t0, "the reeve dies; the treasury is the manor's and untouched (%d)" % w.treasury)
	# someone to take the office: an adult without a trade
	var cand: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job == "":
			cand = o
			break
	if cand == null:
		for o: NPC in w.npcs:
			if o.alive and o.role == "adult" and o.job == "laborer":
				cand = o
				break
	check(cand != null, "an adult who could take the office")
	if cand == null:
		return
	cand.job = ""
	w.last_reeve_day = -1
	b.reeve_day()
	check(b.open_posts("reeve") == 1, "the evening's business opens the office of reeve")
	b.reeve_day()
	check(b.open_posts("reeve") == 1, "and only once")
	b.succession_dawn()
	check(w.npc(w.reeve_id) == old, "not at once: the office waits %d days" % int(GameData.b("succession_days")))
	skip_days(w, int(GameData.b("succession_days")))
	b.succession_dawn()
	var heir: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.job == "reeve":
			heir = o
	check(heir != null and b.open_posts("reeve") == 0, "after %d days an adult of the village takes the office (%s)" % [int(GameData.b("succession_days")), heir.name if heir else "none"])
	b.reeve_day()
	check(heir != null and w.reeve_id == heir.id and heir.workplace == "manor", "the new reeve keeps the manor (reeve_id %d)" % w.reeve_id)
	# public works go on with a reeve: money beyond the holiday level is spent again
	w.treasury = 100000
	var m: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.job == "carpenter":
			m = o
			break
	m.inv.add("plank", 40)
	var used: int = b._public_works(b.daily_obligations())
	check(used > 0, "with the new reeve, public works resume (%d loads)" % used)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	check(int(saved.reeve_id) == heir.id, "the new reeve is saved")


func reeve_from_the_caravan() -> void:
	var w := new_world()
	var b: NPCBrain = w.brain
	w.kill(w.npc(w.reeve_id), "fever")
	for o: NPC in w.npcs:                     # nobody free to take the office
		if o.alive and o.role == "adult" and o.job in NPCBrain.APPRENTICE_FROM:
			o.job = "woodcutter"
	var n0 := w.npcs.size()
	var c0 := w.total_coins()
	var src0 := w.coin_sources
	w.last_reeve_day = -1
	b.reeve_day()
	skip_days(w, int(GameData.b("succession_days")))
	b.succession_caravan()
	b.reeve_day()
	var r := w.npc(w.reeve_id)
	check(r != null and r.alive and r.job == "reeve" and w.npcs.size() == n0 + 1, "with nobody free, a newcomer comes with the caravan to be reeve (%s)" % (r.name if r else "none"))
	check(w.total_coins() - c0 == w.coin_sources - src0, "the newcomer's purse is counted as coming from outside (%d)" % (w.coin_sources - src0))


## A household loses its provider: the heir holds what they left, the household's position is recomputed at once, and
## its food stays in its pantry; nothing is made or lost.
func provider_lost() -> void:
	var w := new_world()
	var p: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 3 and o.job != "" and w.brain._members(o.household).size() >= 2:
			p = o
			break
	check(p != null, "a household with a working provider")
	if p == null:
		return
	var h := p.household
	p.coins = 120
	p.inv.add("bread", 3)
	var heir := w._heir(p)
	var hc0 := heir.coins
	var pantry0: int = w.households[h].pantry.count("bread")
	var c0 := w.total_coins()
	w.kill(p, "fever")
	var econ: Dictionary = w.households[h].get("econ", {})
	check(heir.coins == hc0 + 120 and w.households[h].pantry.count("bread") == pantry0 + 3, "the heir holds the provider's coins and the food goes to the pantry")
	check(int(econ.get("members", -1)) == w.brain._members(h).size(), "the household's position is recomputed at once (%d members)" % int(econ.get("members", -1)))
	check(w.total_coins() == c0, "no coin made or lost")


func free_adult(w: World) -> NPC:
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job in NPCBrain.APPRENTICE_FROM:
			return o
	return null


## EQ-04: the watch. A slain guard's post opens while the treasury can pay a guard, and is taken up through the
## succession of posts; the new guard takes the thinner shift and a guard's training; nothing else is given.
func guards_replaced() -> void:
	var w := new_world()
	var b: NPCBrain = w.brain
	var guards: Array = w.npcs.filter(func(o): return o.alive and o.job == "guard")
	check(guards.size() == int(Population.JOBS.guard), "the village begins with its watch of %d" % guards.size())
	w.last_reeve_day = -1
	b.reeve_day()
	check(b.open_posts("guard") == 0, "a full watch opens no post")
	var dead: NPC = guards[0]
	var shift := dead.workplace
	w.kill(dead, "slain by Rob")
	w.treasury = 100000
	b.reeve_day()
	b.reeve_day()
	check(b.open_posts("guard") == 1 and str(w.vacancies.filter(func(v): return v.job == "guard")[0].workplace) == shift,
		"the evening's business opens one guard's post, on the thinned %s shift" % shift)
	var cand := free_adult(w)
	check(cand != null, "an adult free to take it")
	b.succession_dawn()
	check(b.living_in("guard") == guards.size() - 1, "not at once")
	skip_days(w, int(GameData.b("succession_days")))
	b.succession_dawn()
	var newg: Array = w.npcs.filter(func(o): return o.alive and o.job == "guard" and not guards.has(o))
	check(newg.size() == 1 and b.open_posts("guard") == 0 and b.living_in("guard") == int(Population.JOBS.guard),
		"after %d days an adult takes the post: the watch is whole again" % int(GameData.b("succession_days")))
	if newg.is_empty():
		return
	var g: NPC = newg[0]
	var items0: int = g.inv.total()
	b.decide(g)
	check(g.workplace == shift and g.max_hp >= 45.0 and g.damage >= 8.0, "the new guard takes the %s shift and a guard's training (%s, hp %d, blow %d)" % [shift, g.workplace, int(g.max_hp), int(g.damage)])
	check(g.inv.total() <= items0, "and is given no goods by taking the post (%d things)" % g.inv.total())


## A watch the treasury cannot pay is not filled (a village may fail: no hidden rescue).
func guards_unaffordable() -> void:
	var w := new_world()
	var b: NPCBrain = w.brain
	var g: NPC = w.npcs.filter(func(o): return o.alive and o.job == "guard")[0]
	w.kill(g, "slain by Rob")
	w.treasury = 0
	w.last_reeve_day = -1
	b.reeve_day()
	check(b.open_posts("guard") == 0 and float(w.stats.get("guard_post_unaffordable", 0)) >= 1.0, "with an empty treasury no guard's post opens")


## A business that fails: its tanner leaves the trade for other work (seek_work's path: _change_job, then _post_left);
## the post re-opens and, after succession_days, another villager takes the trade up at the same workplace.
func failed_business() -> void:
	var w := new_world()
	var b: NPCBrain = w.brain
	var tanners: Array = w.npcs.filter(func(o): return o.alive and o.job == "tanner")
	var t: NPC = tanners[0]
	var place := t.workplace
	b._change_job(t, "woodcutter", "the tannery did not keep the household fed")
	b._post_left(t, "tanner", place)
	check(b.open_posts("tanner") == 1, "the failed tannery's post re-opens (%s)" % place)
	skip_days(w, int(GameData.b("succession_days")))
	b.succession_dawn()
	var now: Array = w.npcs.filter(func(o): return o.alive and o.job == "tanner")
	var newt: Array = now.filter(func(o): return not tanners.has(o))
	check(newt.size() == 1 and (newt[0] as NPC).workplace == place and b.open_posts("tanner") == 0,
		"another villager takes up the trade at the same workplace (%s)" % ((newt[0] as NPC).name if not newt.is_empty() else "none"))
