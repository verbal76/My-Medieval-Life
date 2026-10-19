extends SceneTree
## Long-run economy simulation with no player activity: builds the village for a seed, steps the
## real World for N game days and samples, every D days and at the end, people, food, work and
## money, materials, wildlife, building, trade and the currency, then checks the flow accounts:
## currency (end = start + caravan coins in + newcomers' purses - caravan coins out), each item (start + produced +
## imported - consumed - exported = end), each deposit (start - mined = end) and each animal kind
## (start + born - killed - starved = end). Any difference is printed as a leak, never hidden.
## Diagnostics only: the only thing it changes in the world is the player's hunger, kept full so
## the inert player (left where it starts, as in households_sim) never starves.
##   godot --headless --path game --script res://tests/economy_sim.gd -- --days 30 [--seed 1] [--every 1] [--out path.json]
##       [--set key=value]...   (override a top-level balance.json number for a comparison run, e.g. --set manor_job_reserve_days=10)
## Steps of 0.5 s (one game minute), as households_sim, econ_report and earn_sim do; the abstract tier
## of World.update runs a distant NPC once per 0.5 s, so a larger step would change the rules applied.
## Exit code 1 if the currency or any item does not balance.

const STEP := 0.5
const MATERIALS := ["iron_ore", "copper_ore", "gold_ore", "coal", "stone", "log", "plank", "iron_bar", "copper_bar",
	"wheat", "meat", "hide", "leather", "pottage", "roast_meat", "ale", "pickaxe", "axe", "hammer"]
const MARKET_ROLES := ["merchant_raw", "merchant_food", "merchant_goods", "tavernkeeper"]

var w: World
var deaths := {}               # cause -> count (villagers)
var deaths_by_job := {}        # job or role -> count
var bandit_deaths := 0
var death_log: Array = []      # [day, name, job, cause]
var first_starvation_day := -1
var pending_cause := ""
var events := {"sites_started": 0, "sites_finished": 0, "sites_given_up": 0, "seams_worked_out": 0,
	"no_firewood_nights": 0, "caravans": 0, "tools_broke": 0}
var exhausted_day := {}        # deposit index -> day it reached 0
var starving_hours := 0        # villager-hours at zero hunger
var min_hunger := 100.0        # lowest villager hunger since the last sample
var player_min_hp := 0.0
var player_attacked := 0       # hours in which the player's health fell
var flows := {}                # "buyer_role>seller_role" -> {n, coins, items}: every sale (World.trade_hook)


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var arg := func(name: String, fallback: String) -> String:
		return args[args.find(name) + 1] if name in args and args.find(name) + 1 < args.size() else fallback
	var days := int(arg.call("--days", "30"))
	var seed := int(arg.call("--seed", "1"))
	var every := maxi(1, int(arg.call("--every", "1")))
	var out := str(arg.call("--out", ""))
	GameData.ensure()
	for i in args.size():                 # comparison runs: --set key=value overrides a balance number
		if args[i] == "--set" and i + 1 < args.size() and "=" in args[i + 1]:
			var kv: PackedStringArray = args[i + 1].split("=", true, 1)
			GameData.balance[kv[0]] = float(kv[1])
			print("balance override: %s = %s" % [kv[0], kv[1]])
	var t0 := Time.get_ticks_msec()
	w = World.new()
	w.setup(VillageMap.load_default(), seed)
	w.event.connect(_on_event)
	w.brain.track_misses = true
	w.trade_hook = _on_trade
	w.npc_died.connect(_on_died)
	player_min_hp = w.player.hp
	var start := {"stats": w.stats.duplicate(), "goods": _all_goods(), "coins": _coins(), "coin_sources": w.coin_sources,
		"deposits": w.deposits.map(func(d): return int(d.amount)), "animals": _animal_counts(), "alive": _villagers().size(),
		"households": w.households.size(), "npcs": w.npcs.size()}
	var samples: Array = [_sample(start)]
	_print_sample(samples[0])
	var per_day := int(1440.0 / float(GameData.b("game_minutes_per_second")) / STEP)
	var hp_before := w.player.hp
	for d in days:
		for i in per_day:
			w.update(STEP)
			w.player.hunger = 100.0            # the inert player is fed; it is not part of what is measured
			if i % 60 == 59:
				_hourly()
				if w.player.hp < hp_before:
					player_attacked += 1
				hp_before = w.player.hp
				player_min_hp = minf(player_min_hp, w.player.hp)
		if (d + 1) % every == 0 or d + 1 == days:
			samples.append(_sample(start))
			_print_sample(samples[-1])
			min_hunger = 100.0
	var secs := (Time.get_ticks_msec() - t0) / 1000.0
	var final: Dictionary = samples[-1]
	_print_final(final, start, seed, days, secs)
	if out != "":
		var f := FileAccess.open(out, FileAccess.WRITE)
		f.store_string(JSON.stringify({"format": "economy-sim/1", "seed": seed, "days": days, "every": every, "step": STEP,
			"seconds": secs, "start": _jsonable(start), "samples": samples, "deaths": death_log,
			"fingerprint": _fingerprint(), "misses": _miss_summary(), "flows": flows}, " ", false))
		f.close()
	var ok: bool = int(final.currency.leak) == 0 and (final.ledger.items as Dictionary).is_empty()
	w.dispose()
	quit(0 if ok else 1)


# ---------------------------------------------------------------- listeners ------------------
func _on_event(t: String) -> void:
	var at := t.find("has died (")
	if at >= 0:
		pending_cause = t.substr(at + 10, t.rfind(")") - at - 10)
	if " marks out " in t:
		events.sites_started += 1
	elif t.ends_with(" is finished."):
		events.sites_finished += 1
	elif "was given up" in t:
		events.sites_given_up += 1
	elif "seam at the mine is worked out" in t:
		events.seams_worked_out += 1
	elif "had no firewood last night" in t:
		events.no_firewood_nights += int(t.substr(t.find("] ") + 2).split(" ")[0])
	elif "merchant caravan passes through" in t:
		events.caravans += 1
	elif t.ends_with(" broke."):
		events.tools_broke += 1


func _on_died(n: NPC) -> void:
	var cause := pending_cause.split(" by ")[0] if pending_cause.begins_with("slain") else pending_cause
	pending_cause = ""
	if n.role == "bandit":
		bandit_deaths += 1
		return
	deaths[cause] = int(deaths.get(cause, 0)) + 1
	var job: String = n.job if n.job != "" else n.role
	deaths_by_job[job] = int(deaths_by_job.get(job, 0)) + 1
	death_log.append([w.day() + 1, "%s %s" % [n.name, n.family], job, cause])
	if cause == "starvation" and first_starvation_day < 0:
		first_starvation_day = w.day() + 1


func _hourly() -> void:
	for n: NPC in _villagers():
		min_hunger = minf(min_hunger, n.hunger)
		if n.hunger <= 0.0:
			starving_hours += 1
	for i in w.deposits.size():
		if int(w.deposits[i].amount) <= 0 and not exhausted_day.has(i):
			exhausted_day[i] = w.day() + 1


# ---------------------------------------------------------------- sampling -------------------
func _villagers() -> Array:
	return w.npcs.filter(func(o: NPC) -> bool: return o.alive and o.role != "bandit")


func _st(k: String) -> float:
	return float(w.stats.get(k, 0.0))


func _sample(start: Dictionary) -> Dictionary:
	var s := {"day": w.day(), "clock": w.clock_text()}
	# people
	var by_role := {}
	var by_job := {}
	for n: NPC in w.npcs:
		if n.alive:
			by_role[n.role] = int(by_role.get(n.role, 0)) + 1
			if n.role != "bandit":
				var j: String = n.job if n.job != "" else "(" + n.role + ")"
				by_job[j] = int(by_job.get(j, 0)) + 1
	var vill := _villagers()
	s.people = {"alive": vill.size(), "by_role": by_role, "by_job": by_job, "deaths": deaths.duplicate(),
		"deaths_by_job": deaths_by_job.duplicate(), "bandit_deaths": bandit_deaths, "births": w.npcs.size() - int(start.npcs),
		"households": w.households.size(), "households_founded": int(_st("households_founded"))}
	# food
	var groups := _holders()
	var pts := {}
	var total_pts := 0.0
	for g in groups:
		var p := 0.0
		for f in NPCBrain.FOOD:
			p += int(groups[g].get(f, 0)) * float(GameData.item(f).food)
		pts[g] = roundi(p)
		total_pts += p
	var need := maxf(1.0, w.brain.village_day_food())
	var hunger_sum := 0.0
	var at_zero := 0
	for n: NPC in vill:
		hunger_sum += n.hunger
		if n.hunger <= 0.0:
			at_zero += 1
	s.food = {"points_by_holder": pts, "days_of_need": snappedf(total_pts / need, 0.01), "game_food_days": snappedf(w.food_days, 0.01),
		"day_need_points": roundi(need), "granary_wheat": w.granary.count("wheat"), "famine": w.famine(),
		"made": _keys_with("made_", ["wheat", "pottage", "roast_meat", "ale", "meat"]),
		"eaten_points": int(_st("eaten_food")), "starvation_deaths": int(deaths.get("starvation", 0)), "first_starvation_day": first_starvation_day,
		"starving_villager_hours": starving_hours, "at_zero_hunger_now": at_zero,
		"mean_hunger": snappedf(hunger_sum / maxf(1.0, vill.size()), 0.1), "min_hunger_since_last": snappedf(min_hunger, 0.1),
		"missed_meal_no_money": int(_st("missed_meal_no_money")), "missed_meal_no_food_for_sale": int(_st("missed_meal_no_food_for_sale")),
		"relief_grain": int(_st("gov_relief_grain")), "relief_bought_coins": int(_st("gov_relief_bought"))}
	# work
	var adults := 0
	var with_job := 0
	var with_place := 0
	var lost := 0
	for n: NPC in vill:
		if n.role == "adult":
			adults += 1
			if n.job != "":
				with_job += 1
			if n.workplace != "":
				with_place += 1
			if n.doing == "lost":
				lost += 1
	s.work = {"adults": adults, "with_job": with_job, "with_workplace": with_place, "unemployed": adults - with_job,
		"lost": lost, "job_changes": int(_st("job_changes"))}
	# money
	var cash := []
	for h in w.households.size():
		if not w.brain._members(h).is_empty():
			cash.append(w.property.purse(World.hh_ref(h)))
	cash.sort()
	var cash_total := 0
	for c in cash:
		cash_total += int(c)
	var trade := {}
	for n: NPC in vill:
		var r: String = w.brain.buy_role(n)
		if not NPCBrain.BUYS.has(r):
			continue
		var cheapest := 1 << 30
		for id in NPCBrain.BUYS[r]:
			cheapest = mini(cheapest, w.buy_price(n, id))
		if not trade.has(r):
			trade[r] = {"n": 0, "coins": 0, "min": 1 << 30, "below_price": 0, "below_floor": 0, "zero": 0}
		var t: Dictionary = trade[r]
		t.n += 1
		t.coins += n.coins
		t.min = mini(int(t.min), n.coins)
		if n.coins < cheapest:
			t.below_price += 1
		if n.coins - cheapest < int(GameData.b("trader_cash_floor")):
			t.below_floor += 1            # cannot buy anything: sales to it need coins - price >= the cash floor
		if n.coins == 0:
			t.zero += 1
	var merchants := 0
	for n: NPC in vill:
		if n.job == "merchant":
			merchants += n.coins
	s.money = {"household_cash": {"n": cash.size(), "min": cash[0] if not cash.is_empty() else 0, "median": cash[cash.size() / 2] if not cash.is_empty() else 0,
		"max": cash[-1] if not cash.is_empty() else 0, "total": cash_total}, "traders": trade, "treasury": w.treasury, "merchant_funds": merchants,
		"gov": _keys_with("gov_", ["tax", "wages", "rent", "land_sales", "repairs", "public_works", "procurement", "relief_bought", "fines"])}
	# materials
	var held := {}
	for g in groups:
		var row := {}
		for id in MATERIALS:
			if int(groups[g].get(id, 0)) != 0:
				row[id] = int(groups[g][id])
		held[g] = row
	var left := {}
	for d in w.deposits:
		left[d.ore] = int(left.get(d.ore, 0)) + int(d.amount)
	var tree_states := {}
	for t in w.trees:
		tree_states[t.state] = int(tree_states.get(t.state, 0)) + 1
	var by_job_held := {}             # what villagers carry, by job: who holds the stock
	for n: NPC in vill:
		var j: String = n.job if n.job != "" else n.role
		if not by_job_held.has(j):
			by_job_held[j] = {}
		for id in n.inv.items:
			if id in MATERIALS:
				by_job_held[j][id] = int(by_job_held[j].get(id, 0)) + int(n.inv.items[id])
	s.materials = {"held": held, "held_by_job": by_job_held, "deposit_left": left, "deposits": w.deposits.map(func(d): return [d.ore, int(d.amount)]),
		"deposits_exhausted": w.deposits.filter(func(d): return int(d.amount) <= 0).size(), "trees": tree_states,
		"mined": _keys_with("mined_", ["iron_ore", "copper_ore", "gold_ore", "coal", "stone"]),
		"felled_trees": int(_st("trees_felled")), "felled_logs": int(_st("felled_log")), "burned_logs": int(_st("burned_log")),
		"broke": _keys_with("broke_", ["pickaxe", "axe", "hammer"])}
	# wildlife
	var sp := {}
	for a: Animal in w.fauna.animals:
		if not a.alive:
			continue
		if not sp.has(a.species):
			sp[a.species] = {"wild": 0, "penned": 0, "adult": 0, "young": 0}
		sp[a.species]["wild" if a.wild() else "penned"] += 1
		sp[a.species]["adult" if a.adult(w.minutes) else "young"] += 1
	var kinds: Array = GameData.b("animals").keys().filter(func(k): return k != "_note")
	s.wildlife = {"species": sp, "hunted": _keys_with("hunted_", kinds), "slaughtered": _keys_with("slaughtered_", kinds),
		"poached": _keys_with("poached_", kinds), "starved": _keys_with("starved_", kinds), "born": _keys_with("born_", kinds)}
	# building
	var open := 0
	var done := 0
	for p in w.plots:
		if not p.site.is_empty():
			if p.site.get("done", false):
				done += 1
			else:
				open += 1
	var houses := 0
	var workshops := 0
	for b in w.buildings.values():
		if World.is_built(b):
			if str(b.get("kind", "house")) == "house":
				houses += 1
			else:
				workshops += 1
	s.building = {"sites_started": events.sites_started, "sites_finished": events.sites_finished, "sites_given_up": events.sites_given_up,
		"open_sites": open, "finished_sites": done, "houses_built": houses, "workshops_built": workshops,
		"households": w.households.size(), "households_split": int(_st("households_founded")), "helpers_now": w.construction.contracts.size(),
		"helper_wages": int(_st("helper_wages")), "helper_bought": int(_st("helper_bought"))}
	s.growth = _growth()
	# trade
	var exp := {}
	var imp := {}
	for k in w.stats:
		if str(k).begins_with("exported_"):
			exp[str(k).substr(9)] = int(w.stats[k])
		elif str(k).begins_with("imported_"):
			imp[str(k).substr(9)] = int(w.stats[k])
	var mw: ManorWork = w.manor_work
	var open_kinds := {}
	for j in mw.jobs:
		var k := "%s_%s" % [j.kind, "taken" if j.taker != "" else "open"]
		open_kinds[k] = int(open_kinds.get(k, 0)) + 1
	s.manor_work = {"jobs_now": open_kinds, "taken": int(_st("manor_jobs_taken")), "done": int(_st("manor_jobs_done")),
		"done_by_kind": {"haul": int(_st("manor_job_haul")), "quarry": int(_st("manor_job_quarry")), "mend": int(_st("manor_job_mend"))},
		"wages": int(_st("gov_manor_jobs")), "lots": mw.lots.size(), "lot_goods": mw.goods(), "yard": mw.yard.total(), "mended": int(_st("works_mended"))}
	s.trade = {"caravans": events.caravans, "exported": exp, "imported": imp, "coins_in": int(_st("caravan_coins_in")),
		"coins_out": int(_st("caravan_coins_out")), "coin_sources": w.coin_sources}
	# currency and flow accounts
	var c := _coins()
	# coins from outside: the caravan's purchases, and newcomers' purses (they come in from outside)
	var c_in := int(_st("caravan_coins_in")) - int(start.stats.get("caravan_coins_in", 0)) \
			+ int(_st("newcomer_coins_in")) - int(start.stats.get("newcomer_coins_in", 0))
	var c_out := int(_st("caravan_coins_out")) - int(start.stats.get("caravan_coins_out", 0))
	var src_delta := w.coin_sources - int(start.coin_sources)
	s.currency = {"holders": c, "total": c.total, "world_total_coins": w.total_coins(), "start_total": start.coins.total,
		"external_in": c_in, "external_out": c_out, "leak": int(c.total) - int(start.coins.total) - c_in + c_out,
		"coin_sources_delta": src_delta, "coin_sources_mismatch": src_delta - (c_in - c_out),
		"holders_mismatch": int(c.total) - w.total_coins()}
	s.ledger = _ledger(start)
	s.player = {"alive": w.player.alive, "hp": snappedf(w.player.hp, 0.1), "min_hp": snappedf(player_min_hp, 0.1), "hours_hurt": player_attacked}
	s.events = events.duplicate()
	return s


## Stats `prefix + id` for each id with a non-zero value.
func _keys_with(prefix: String, ids: Array) -> Dictionary:
	var out := {}
	for id in ids:
		var v := _st(prefix + str(id))
		if v != 0.0:
			out[id] = int(v)
	return out


## Every coin, by who holds it. World.total_coins counts the same holders.
func _coins() -> Dictionary:
	var out := {"villagers": 0, "bandits": 0, "dead": 0, "player": w.player.coins, "treasury": w.treasury, "loot": 0,
		"quest_reserves": w.quests.reserved_total(), "manor_wages_reserved": w.manor_work.reserved_total()}
	for n: NPC in w.npcs:
		out["dead" if not n.alive else ("bandits" if n.role == "bandit" else "villagers")] += n.coins
	for l in w.loot:
		out.loot += int(l.coins)
	var t := 0
	for k in out:
		t += int(out[k])
	out.total = t
	return out


## Every item, by holder group: id -> count. The groups together are run_tests' _all_goods plus the
## pens' troughs (wheat put out as feed).
func _holders() -> Dictionary:
	var g := {"npcs": {}, "markets": {}, "households": {}, "granary": {}, "troughs": {}, "sites": {}, "player": {}, "loot": {}, "manor_work": {}}
	var add := func(to: Dictionary, inv: Inventory) -> void:
		for id in inv.items:
			to[id] = int(to.get(id, 0)) + int(inv.items[id])
	for n: NPC in w.npcs:
		add.call(g.markets if w.brain.buy_role(n) in MARKET_ROLES else g.npcs, n.inv)
	for hh in w.households:
		add.call(g.households, hh.pantry)
	for c in w.containers:
		if c.kind == "table":
			add.call(g.markets, c.inv)
	add.call(g.granary, w.granary)
	add.call(g.player, w.player.inv)
	add.call(g.player, w.player.chest)
	for l in w.loot:
		add.call(g.loot, l.inv)
	var mg: Dictionary = w.manor_work.goods()      # the manor's lots, works yard and job loads
	for id in mg:
		g.manor_work[id] = int(g.manor_work.get(id, 0)) + int(mg[id])
	for src in [w.site_goods(), w.construction.carried()]:
		for id in src:
			g.sites[id] = int(g.sites.get(id, 0)) + int(src[id])
	g["carts"] = {}
	for c in w.carts.carts:                        # goods riding in carts (B14)
		add.call(g.carts, c.store)
	for s in w.business.premises():                # the player's stall and shops: sale stock and back store
		for src in [s.get("stock", {}), s.get("store", {})]:
			for id in src:
				g.player[id] = int(g.player.get(id, 0)) + int(src[id])
	for id in w.fauna.pens:
		var tr := int(w.fauna.pens[id].trough)
		if tr > 0:
			g.troughs.wheat = int(g.troughs.get("wheat", 0)) + tr
	return g


func _all_goods() -> Dictionary:
	var out := {}
	var g := _holders()
	for k in g:
		for id in g[k]:
			out[id] = int(out.get(id, 0)) + int(g[k][id])
	return out


func _animal_counts() -> Dictionary:
	var out := {}
	for a: Animal in w.fauna.animals:
		if a.alive:
			out[a.species] = int(out.get(a.species, 0)) + 1
	return out


## The flow accounts since `start`. Items: held(start) + produced + imported - consumed - exported
## = held(now); produced = made_ (recipes, harvest, kills, home cooking) + mined_ + felled_;
## consumed = eaten_ + used_ (recipes, home cooking) + used_building_ + used_works_ + used_repairs_
## + feed_eaten_ (troughs) + burned_ (firewood) + broke_ (tools) + poached_lost_ (the bandits' game).
## Only non-zero residuals are kept, with their terms.
func _ledger(start: Dictionary) -> Dictionary:
	var st0: Dictionary = start.stats
	var d := func(k: String) -> int: return int(_st(k)) - int(st0.get(k, 0))
	var now := _all_goods()
	var ids := {}
	for id in now:
		ids[id] = true
	for id in start.goods:
		ids[id] = true
	for k in w.stats:
		for p in ["made_", "mined_", "felled_", "imported_", "exported_", "eaten_", "used_building_", "used_works_", "used_repairs_", "used_", "feed_eaten_", "burned_", "broke_", "poached_lost_", "wild_eaten_", "farm_harvest_"]:
			if str(k).begins_with(p):
				ids[str(k).substr(p.length())] = true
				break
	ids.erase("food")                     # eaten_food is points, not an item
	for id in ids.keys():
		if not GameData.items.has(id):
			ids.erase(id)                     # counters that are not goods, e.g. eaten_deer_by_wolf (predation)
	var bad := {}
	var flows := {}
	var keys := ids.keys()
	keys.sort()
	for id in keys:
		var produced: int = d.call("made_" + id) + d.call("mined_" + id) + d.call("felled_" + id) + d.call("farm_harvest_" + id)
		var consumed: int = d.call("eaten_" + id) + d.call("used_" + id) + d.call("used_building_" + id) + d.call("used_works_" + id) \
			+ d.call("used_repairs_" + id) + d.call("feed_eaten_" + id) + d.call("burned_" + id) + d.call("broke_" + id) + d.call("poached_lost_" + id) \
			+ d.call("wild_eaten_" + id)
		if id == "wheat":                     # farmers keep seed back from the grain they cut (Farming.save_seed)
			consumed += d.call("farm_seed_saved")
		elif id == "wheat_seed":
			produced += d.call("farm_seed_saved")
		var imported: int = d.call("imported_" + id)
		var exported: int = d.call("exported_" + id)
		var s0 := int(start.goods.get(id, 0))
		var s1 := int(now.get(id, 0))
		var residual := s1 - (s0 + produced + imported - consumed - exported)
		var row := {"start": s0, "produced": produced, "imported": imported, "consumed": consumed, "exported": exported, "end": s1}
		if id in MATERIALS or residual != 0:
			flows[id] = row
		if residual != 0:
			row.residual = residual
			bad[id] = row
	var dep := []
	var mined_by_ore := {}
	for i in w.deposits.size():
		var ore: String = w.deposits[i].ore
		mined_by_ore[ore] = int(mined_by_ore.get(ore, 0)) + int(start.deposits[i]) - int(w.deposits[i].amount)
	for ore in mined_by_ore:
		var counted: int = d.call("mined_" + ore)
		if counted != int(mined_by_ore[ore]):
			dep.append({"ore": ore, "taken_from_deposits": mined_by_ore[ore], "mined_counted": counted})
	var animals := {}
	var now_a := _animal_counts()
	var kinds: Array = GameData.b("animals").keys().filter(func(k): return k != "_note")
	for k in kinds:
		var preyed := 0                       # B14 forest animals: kills by predators and the fox's raids
		for sk in w.stats:
			if str(sk).begins_with("eaten_%s_by_" % k):
				preyed += d.call(str(sk))
		var expect: int = int(start.animals.get(k, 0)) + d.call("born_" + k) - d.call("hunted_" + k) - d.call("slaughtered_" + k) \
			- d.call("poached_" + k) - d.call("starved_" + k) - preyed - d.call("fox_took_" + k) - d.call("old_age_" + k)
		if expect != int(now_a.get(k, 0)):
			animals[k] = {"expected": expect, "counted": int(now_a.get(k, 0))}
	return {"items": bad, "flows": flows, "deposits": dep, "animals": animals}


## A digest of the world's state: equal digests mean the same run (used to check that the ledger
## counters change nothing).
func _fingerprint() -> String:
	var parts := PackedStringArray([str(w.minutes), str(w.treasury), str(w.coin_sources), str(w.rng.state), str(w.granary.items)])
	for n: NPC in w.npcs:
		parts.append("%d|%s|%d|%s|%s|%s|%s" % [n.id, n.alive, n.coins, n.pos, n.hunger, n.job, n.inv.items])
	for a: Animal in w.fauna.animals:
		parts.append("%d|%s|%s" % [a.id, a.pos, a.hunger])
	for dp in w.deposits:
		parts.append(str(dp.amount))
	for hh in w.households:
		parts.append(str(hh.pantry.items))
	return "|".join(parts).md5_text()


func _jsonable(d: Dictionary) -> Dictionary:
	return {"coins": d.coins, "goods": d.goods, "deposits": d.deposits, "animals": d.animals, "alive": d.alive, "households": d.households}


# ---------------------------------------------------------------- output ---------------------
func _print_sample(s: Dictionary) -> void:
	var tr: Dictionary = s.money.traders
	var insolvent := 0
	for r in tr:
		insolvent += int(tr[r].below_floor)
	var held: Dictionary = s.materials.held
	var sum := func(id: String) -> int:
		var n := 0
		for g in held:
			n += int(held[g].get(id, 0))
		return n
	var wild := 0
	var penned := 0
	for k in s.wildlife.species:
		wild += int(s.wildlife.species[k].wild)
		penned += int(s.wildlife.species[k].penned)
	print("day %3d: alive %d (starved %d, other deaths %d), food %.1f days, mean hunger %.0f, unemployed %d, hh cash min/med/max %d/%d/%d, treasury %d, traders unable to buy %d, ore left %s, logs %d planks %d trees %d, wild %d penned %d, sites %d/%d houses %d hh %d, coins %d (leak %d), item leaks %d" % [
		s.day, s.people.alive, s.food.starvation_deaths, _sumd(s.people.deaths) - int(s.food.starvation_deaths), s.food.days_of_need, s.food.mean_hunger,
		s.work.unemployed, s.money.household_cash.min, s.money.household_cash.median, s.money.household_cash.max, s.money.treasury, insolvent,
		s.materials.deposit_left, sum.call("log"), sum.call("plank"), int(s.materials.trees.get("grown", 0)), wild, penned,
		s.building.sites_finished, s.building.sites_started, s.building.houses_built, s.building.households, s.currency.total, s.currency.leak, (s.ledger.items as Dictionary).size()])
	print("  growth: %s" % JSON.stringify(s.growth))


## What holds back births, partnering and new households (EQ-07; read only): beds against people, couples
## who could have a child and what stops them, single adults, crowded households and whether they can pay
## for a new home, and empty houses on the market.
func _growth() -> Dictionary:
	var c := Life.cfg()
	var con := w.construction
	var fp := con.footprint("house")
	var house_cost := w.property.land_price(fp.x, fp.y) + ceili(con.estimate(con.cost_of("house")) * float(GameData.b("found_start_share")))
	var beds := 0
	var living := 0
	var full := 0
	for h in w.households.size():
		var hh: Dictionary = w.households[h]
		if hh.get("ended", false) or w.brain._members(h).is_empty():
			continue
		living += Life._living_in(w, h)
		if w.buildings.has(str(hh.home)):
			beds += con.beds_in(str(hh.home))
			if not Life.has_room(w, h):
				full += 1
	var couples := {"fertile": 0, "full_house": 0, "low_food": 0, "recent_child": 0, "could": 0}
	var single := {"female": 0, "male": 0, "female_room": 0, "male_room": 0}
	for n: NPC in w.npcs:
		if not n.alive or n.role != "adult":
			continue
		var a := Life.npc_age(w, n)
		if not Life.has_partner(w, n):
			if a >= float(c.partner_min_age) and a <= float(c.partner_max_age):
				single[n.sex] += 1
				if Life.has_room(w, n.household):
					single[n.sex + "_room"] += 1
			continue
		if n.sex != "female" or a < float(c.birth_mother_min_age) or a > float(c.birth_mother_max_age):
			continue
		couples.fertile += 1
		var recent := false
		for cid in n.children:
			var k := w.npc(int(cid))
			if k != null and Life.age_years(k.born, w.minutes) < float(c.birth_min_gap_years):
				recent = true
		if not Life.has_room(w, n.household):
			couples.full_house += 1                  # no longer a bar to a birth (EQ-08); counted for crowding
		if w.brain.household_food_days(n.household) < float(c.birth_min_food_days):
			couples.low_food += 1
		elif recent:
			couples.recent_child += 1
		else:
			couples.could += 1
	var crowded := 0
	var can_split := 0
	var best_spare: int = -1000000000
	for h in w.households.size():
		if con.crowded(h):
			crowded += 1
			var spare: int = w.property.purse(World.hh_ref(h)) - con._keep(h, w.brain._members(h).size() - 1)
			best_spare = maxi(best_spare, spare)
			if spare >= house_cost:
				can_split += 1
	var empty_houses := 0
	for r in w.property.market():
		if w.property.is_home(r) or w.property.is_home(w.property.unit(r).back()):
			empty_houses += 1
	return {"beds": beds, "living": living, "households_full": full, "fertile_couples": couples, "single_adults": single,
		"crowded_households": crowded, "crowded_can_afford_home": can_split, "best_crowded_spare": best_spare if crowded > 0 else 0,
		"house_start_cost": house_cost, "house_materials": con.estimate(con.cost_of("house")), "couples_needing_home": con.couples_needing_home().size(),
		"courtships": int(_st("courtships")), "gifts_given": int(_st("gifts_given")), "house_price": int(GameData.b("house_price")), "empty_houses_for_sale": empty_houses,
		"partnerships": int(_st("partnerships")), "households_founded": int(_st("households_founded"))}


func _sumd(d: Dictionary) -> int:
	var n := 0
	for k in d:
		n += int(d[k])
	return n


func _print_final(s: Dictionary, start: Dictionary, seed: int, days: int, secs: float) -> void:
	print("=== seed %d, %d days, %.1f s (%.2f s per game day)" % [seed, days, secs, secs / maxf(1.0, days)])
	print("people: alive %d of %d; by job %s; deaths %s (by job %s); bandits killed %d; births %d; households %d -> %d (split %d)" % [
		s.people.alive, start.alive, s.people.by_job, s.people.deaths, s.people.deaths_by_job, s.people.bandit_deaths, s.people.births,
		start.households, s.people.households, s.people.households_founded])
	print("food: %s" % JSON.stringify(s.food))
	print("work: %s" % JSON.stringify(s.work))
	print("money: %s" % JSON.stringify(s.money))
	print("materials: %s" % JSON.stringify(s.materials))
	print("deposits exhausted on day: %s" % JSON.stringify(exhausted_day))
	print("wildlife: %s" % JSON.stringify(s.wildlife))
	print("building: %s" % JSON.stringify(s.building))
	print("growth: %s" % JSON.stringify(s.growth))
	print("trade: %s" % JSON.stringify(s.trade))
	print("manor work: %s" % JSON.stringify(s.manor_work))
	print("currency: %s" % JSON.stringify(s.currency))
	print("player: %s" % JSON.stringify(s.player))
	print("events: %s" % JSON.stringify(s.events))
	print("ledger flows: %s" % JSON.stringify(s.ledger.flows))
	print("LEAKS: currency %d; items %s; deposits %s; animals %s" % [s.currency.leak, JSON.stringify(s.ledger.items),
		JSON.stringify(s.ledger.deposits), JSON.stringify(s.ledger.animals)])
	print("trade flows (buyer>seller): %s" % JSON.stringify(flows))
	print("missed meals: %s" % JSON.stringify(_miss_summary()))
	print("deaths: %s" % JSON.stringify(death_log))
	print("fingerprint %s" % _fingerprint())


## Missed meals (NPCBrain.miss_log): counts by job, by hour of day, by cause, and the first day.
func _miss_summary() -> Dictionary:
	var by_job := {}
	var by_hour := {}
	var by_cause := {}
	var by_day := {}
	for m in w.brain.miss_log:
		by_job[m[2]] = int(by_job.get(m[2], 0)) + 1
		var hr := str(int(m[1]))
		by_hour[hr] = int(by_hour.get(hr, 0)) + 1
		by_cause[m[3]] = int(by_cause.get(m[3], 0)) + 1
		var dk := str(int(m[0]) / 30)
		by_day[dk] = int(by_day.get(dk, 0)) + 1
	return {"total": w.brain.miss_log.size(), "by_job": by_job, "by_hour": by_hour, "by_cause": by_cause, "by_30_days": by_day, "first": w.brain.miss_log.slice(0, 12)}


func _role_of(o: Object) -> String:
	if o is NPC:
		var r: String = w.brain.buy_role(o)
		return r if r != "" else (o.role as String)
	return "player"


func _on_trade(buyer: Object, seller: Object, id: String, qty: int, total: int) -> void:
	var k := "%s>%s" % [_role_of(buyer), _role_of(seller)]
	if not flows.has(k):
		flows[k] = {"n": 0, "coins": 0, "items": {}}
	flows[k].n += qty
	flows[k].coins += total
	flows[k].items[id] = int(flows[k].items.get(id, 0)) + qty
