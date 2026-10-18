extends SceneTree
## Failure-recovery scenarios: each builds a fresh village (seed 1), applies one shock on day 1,
## runs a few days and reports how the people concerned fared. Diagnostics only.
##   godot --headless --path game --script res://tests/scenarios.gd [-- --only name]

const DAYS := 5


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var only := args[args.find("--only") + 1] if "--only" in args else ""
	var all := {
		"newcomer_no_money_no_job": _newcomer,
		"stations_shared": _stations,
		"mine_closes": _mine_closes,
		"food_sellers_empty": _sellers_empty,
		"household_no_money": _household_broke,
		"main_earner_dies": _earner_dies,
		"all_adults_die": _adults_die,
		"harvest_delayed": _harvest_delayed,
		"cut_off_from_village": _cut_off,
		"harvest_fails_day30": _harvest_fails_late,
		"reeve_dies": _reeve_dies,
		"harvest_fails_12_days": _harvest_fails_long,
		"robbed_of_tools": _robbed_of_tools,
	}
	for k in all:
		if only == "" or only == k:
			print("== ", k)
			all[k].call()
	quit()


func _world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


func _run(w: World, days: float, watch: Array, label: String) -> void:
	var steps := int(days * 1440.0 / float(GameData.b("game_minutes_per_second")) / 0.5)
	var low := {}
	for n: NPC in watch:
		low[n.id] = n.hunger
	for i in steps:
		w.update(0.5)
		if i % 60 == 0:
			for n: NPC in watch:
				low[n.id] = minf(low[n.id], n.hunger)
		if i % int(1440.0 / float(GameData.b("game_minutes_per_second")) / 0.5) == 0 and i > 0:
			var alive := 0
			for n: NPC in watch:
				if n.alive:
					alive += 1
			print("   day %d: %s alive %d/%d, village %d" % [int(w.minutes / 1440.0) + 1, label, alive, watch.size(), w.alive_count() - w.alive_count("bandit")])
	for n: NPC in watch:
		print("   %s %s (%s): alive=%s lowest hunger %d, coins %d, job '%s', doing '%s'" % [n.name, n.family, n.role, n.alive, int(low[n.id]), n.coins, n.job, n.doing])


func _household(w: World, n: NPC) -> Array:
	var out := []
	for m in w.households[n.household].members:
		out.append(w.npc(m))
	return out


## 1: someone arrives with no money and no work, lodging at the tavern.
func _newcomer() -> void:
	var w := _world()
	var n := NPC.new()
	n.id = 9000
	n.name = "Newcomer"
	n.family = "Stranger"
	n.household = 0
	n.home = w.households[0].home
	n.pos = Vector2(w.building_door(n.home)) + Vector2(0.5, 0.5)
	n.sprite = w.npcs[0].sprite
	n.hunger = 60.0
	w.npcs.append(n)
	w.by_id[n.id] = n
	w.households[0].members.append(n.id)
	_run(w, DAYS, [n], "newcomer")
	w.dispose()


## 2: how many cooks use the one stove at once (stations have no reservation).
func _stations() -> void:
	var w := _world()
	var most := 0
	for i in int(2 * 1440.0 / 2.0 / 0.5):
		w.update(0.5)
		var at := {}
		for n: NPC in w.npcs:
			if n.alive and not n.plan.is_empty() and n.plan[0].get("act", "") == "craft" and n.plan[0].get("anim", "") == "work":
				var k := str(n.plan[0].get("face", ""))
				at[k] = int(at.get(k, 0)) + 1
		for k in at:
			most = maxi(most, int(at[k]))
	print("   most NPCs crafting at one station at the same moment over 2 days: %d" % most)
	w.dispose()


## 3: the mine is worked out on day 1.
func _mine_closes() -> void:
	var w := _world()
	for d in w.deposits:
		d.amount = 0
	var miners := []
	for n: NPC in w.npcs:
		if n.job in ["miner", "laborer"]:
			miners.append(n)
	_run(w, DAYS, miners.slice(0, 4), "miners")
	var jobs := {}
	for n: NPC in miners:
		jobs[n.job] = int(jobs.get(n.job, 0)) + 1
	print("   miners' jobs after %d days: %s" % [DAYS, jobs])
	w.dispose()


## 7: every food seller is emptied on day 1.
func _sellers_empty() -> void:
	var w := _world()
	for n: NPC in w.npcs:
		if n.job in ["tavernkeeper", "cook"] or w.brain.buy_role(n) == "merchant_food":
			for f in ["pottage", "roast_meat", "ale", "wheat", "meat"]:
				n.inv.remove(f, n.inv.count(f))
	var some := []
	for n: NPC in w.npcs:
		if n.role == "elder" and some.size() < 4:
			some.append(n)
	_run(w, DAYS, some, "elders")
	w.dispose()


## 8/18: a household loses all its money and food on day 1.
func _household_broke() -> void:
	var w := _world()
	var h: Dictionary = w.households[10]
	h.pantry.items.clear()
	var members := []
	for m in h.members:
		var o: NPC = w.npc(m)
		o.coins = 0
		for f in ["pottage", "roast_meat", "ale", "wheat"]:
			o.inv.remove(f, o.inv.count(f))
		members.append(o)
	_run(w, DAYS, members, "the %s household" % h.family)
	w.dispose()


## 13: a household's highest earner dies on day 1.
func _earner_dies() -> void:
	var w := _world()
	var h: Dictionary = w.households[12]
	var best: NPC = null
	for m in h.members:
		var o: NPC = w.npc(m)
		if o.role == "adult" and (best == null or o.coins > best.coins):
			best = o
	w.kill(best, "a fall")
	var rest := []
	for m in h.members:
		if w.npc(m).alive:
			rest.append(w.npc(m))
	_run(w, DAYS, rest, "the %s household" % h.family)
	w.dispose()


## 17: every adult of a household dies, leaving children and elders.
func _adults_die() -> void:
	var w := _world()
	var h: Dictionary = {}
	for hh in w.households:
		var kids := 0
		for m in hh.members:
			if w.npc(m).role != "adult":
				kids += 1
		if kids >= 2 and hh.members.size() >= 4:
			h = hh
			break
	var rest := []
	for m in h.members:
		var o: NPC = w.npc(m)
		if o.role == "adult":
			w.kill(o, "fever")
		else:
			rest.append(o)
	_run(w, DAYS, rest, "the %s dependants" % h.family)
	w.dispose()


## 14: every field's harvest is 4 days late (the crop is only just sown on day 1).
func _harvest_delayed() -> void:
	var w := _world()
	for f in w.fields:
		w.set_field(f, "growing")
		f.ready = w.minutes + 4.0 * 1440.0
	var some := []
	for n: NPC in w.npcs:
		if n.role == "child" and some.size() < 4:
			some.append(n)
	_run(w, 8, some, "children")
	print("   (a village-wide total is in the day lines)")
	w.dispose()


## 19: a villager is stranded on a cell with no path to anywhere.
func _cut_off() -> void:
	var w := _world()
	var n: NPC = null
	for o: NPC in w.npcs:
		if o.job == "woodcutter":
			n = o
			break
	# a walkable cell walled in on all sides by solid cells, found by search
	for y in range(1, w.map.h - 1):
		for x in range(1, w.map.w - 1):
			var c := Vector2i(x, y)
			if w.map.is_solid(c):
				continue
			var shut := true
			for dc in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
				if not w.map.is_solid(c + dc):
					shut = false
			if shut and n.pos == n.pos:
				n.pos = Vector2(c) + Vector2(0.5, 0.5)
				n.plan.clear()
				print("   stranded %s %s at %s" % [n.name, n.family, c])
				_run(w, 3, [n], "stranded woodcutter")
				w.dispose()
				return
	print("   no walled-in walkable cell on this map; scenario not run")
	w.dispose()


## A 4-day harvest failure on day 30, once the economy (and any granary) has had time to build up.
func _harvest_fails_late() -> void:
	var w := _world()
	for i in int(29 * 1440.0 / float(GameData.b("game_minutes_per_second")) / 0.5):
		w.update(0.5)
	var g = w.get("granary")
	print("   day 30: village %d, granary %s wheat" % [w.alive_count() - w.alive_count("bandit"), str(g.count("wheat")) if g != null else "none"])
	for f in w.fields:
		w.set_field(f, "growing")
		f.ready = w.minutes + 4.0 * 1440.0
	var some := []
	for n: NPC in w.npcs:
		if n.role == "child" and some.size() < 4:
			some.append(n)
	_run(w, 8, some, "children")
	w.dispose()


## The reeve dies on day 2: the manor's treasury, taxes, wages and relief must carry on.
func _reeve_dies() -> void:
	var w := _world()
	for i in int(1440.0 / float(GameData.b("game_minutes_per_second")) / 0.5):
		w.update(0.5)
	var t0: int = w.treasury
	w.kill(w.npc(w.reeve_id), "a fever")
	print("   reeve dead on day 2 with the treasury at %d" % t0)
	var guards := []
	for n: NPC in w.npcs:
		if n.job == "guard":
			guards.append(n)
	var g0 := 0
	for g: NPC in guards:
		g0 += g.coins
	var tax0 := float(w.stats.get("gov_tax", 0.0))
	_run(w, 5, guards.slice(0, 2), "guards")
	var g1 := 0
	for g: NPC in guards:
		g1 += g.coins
	print("   after 5 days: treasury %d, tax collected %d, guards' coins %d -> %d" % [w.treasury, int(float(w.stats.get("gov_tax", 0.0)) - tax0), g0, g1])
	w.dispose()


## A 12-day crop failure from day 1: longer than the settlers' stores can bridge.
func _harvest_fails_long() -> void:
	var w := _world()
	for f in w.fields:
		w.set_field(f, "growing")
		f.ready = w.minutes + 12.0 * 1440.0
	var some := []
	for n: NPC in w.npcs:
		if n.role == "child" and some.size() < 4:
			some.append(n)
	_run(w, 14, some, "children")
	print("   granary left: %d wheat" % w.granary.count("wheat"))
	w.dispose()


## A temporary loss of income: a household's earners are robbed of their tools and coins on day 3.
func _robbed_of_tools() -> void:
	var w := _world()
	for i in int(2 * 1440.0 / float(GameData.b("game_minutes_per_second")) / 0.5):
		w.update(0.5)
	var h := -1
	for i in w.households.size():
		for m in w.households[i].members:
			if w.npc(m).job in ["woodcutter", "miner"]:
				h = i
		if h >= 0:
			break
	var members := []
	for m in w.households[h].members:
		var o: NPC = w.npc(m)
		members.append(o)
		o.coins = 0
		for t in ["axe", "pickaxe"]:
			o.inv.remove(t, o.inv.count(t))
	print("   robbed: the %s household (%s)" % [w.households[h].family, ", ".join(members.map(func(o): return o.job if o.job != "" else o.role))])
	_run(w, 6, members, "the %s household" % w.households[h].family)
	for o: NPC in members:
		if o.role == "adult":
			print("   %s: tools %s, earnings last days %s" % [o.name, [o.inv.has("axe"), o.inv.has("pickaxe")], o.income_days])
	w.dispose()
