extends SceneTree
## Early-economy measurement (docs/release/EARLY_ECONOMY_REVIEW.md): a scripted new player earns money by one method for
## N days in the real World simulation. Walking time is ignored (an optimistic upper bound);
## work time per unit follows main.gd's action timings. The player eats bought food when hungry.
## idle buys and eats food but earns nothing; observe keeps the player fed to watch the village alone.
##   godot --headless --path game --script res://tests/earn_sim.gd -- --strategy mine|harvest|hunt|idle|observe --days 10 --seed 1

var w: World
var p: PlayerState
var busy_until := 0.0
var log := []
var food_spent := 0
var earned := 0
var day_coins := []

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var strat := "observe"
	var days := 10
	var seed := 1
	for i in args.size():
		if args[i] == "--strategy": strat = args[i + 1]
		elif args[i] == "--days": days = int(args[i + 1])
		elif args[i] == "--seed": seed = int(args[i + 1])
	w = World.new()
	w.setup(VillageMap.load_default(), seed)
	p = w.player
	print("start coins=%d inv=%s pos=%s" % [p.coins, p.inv.items, p.pos])
	var reached := {}
	var last_h := -1
	var stats := {"hires": 0, "hire_wages": 0, "unpaid": 0, "ore": 0, "unsold": {}, "kills": 0, "no_offer_hours": 0}
	for i in int(days * 1440):
		w.update(0.5)   # one game minute
		var h := w.hour()
		if strat == "observe":
			p.hunger = 100.0
		_eat()
		if w.minutes >= busy_until and h >= 8.0 and h < 17.0:
			match strat:
				"mine": _mine(stats)
				"harvest": _harvest(stats)
				"hunt": _hunt(stats)
		if int(h) != last_h:
			last_h = int(h)
			if last_h == 17 and strat != "observe":
				_sell_all(stats)
			if last_h == 12 or last_h == 17:
				_observe(strat)
		for goal in [60, 150]:
			if p.coins >= goal and not reached.has(goal):
				reached[goal] = w.clock_text()
		if not p.alive:
			print("player died at ", w.clock_text())
			break
		if int(w.minutes) % 1440 == 0:
			day_coins.append(p.coins)
	print("strategy=%s days=%d end coins=%d food_spent=%d earned=%d stats=%s" % [strat, days, p.coins, food_spent, earned, stats])
	print("coins at each dawn: ", day_coins)
	print("reached: ", reached)
	print("inv: ", p.inv.items)
	var left := {}
	for d in w.deposits:
		left[d.ore] = int(left.get(d.ore, 0)) + int(d.amount)
	print("deposits left: ", left)
	var dead := {}
	for n: NPC in w.npcs:
		if not n.alive:
			dead[n.job if n.job != "" else n.role] = int(dead.get(n.job if n.job != "" else n.role, 0)) + 1
	print("dead by job: ", dead, " wild animals: ", w.fauna.animals.filter(func(a): return a.wild()).size())
	for l in log:
		print(l)
	quit()


func _eat() -> void:
	if p.hunger >= 55.0:
		return
	for id in ["bread", "apple", "pottage", "roast_meat", "wheat"]:
		if p.inv.has(id):
			w.player_eat(id)
			return
	# buy the cheapest food per point from a food seller
	var best: NPC = null
	var best_id := ""
	var best_cost := 999.0
	for n: NPC in w.npcs:
		if not n.alive or not (n.job == "tavernkeeper" or w.brain.buy_role(n) == "merchant_food" or n.job == "cook"):
			continue
		for id in ["pottage", "roast_meat", "wheat"]:
			if n.inv.has(id):
				var c := float(w.sell_price(n, id)) / float(GameData.item(id).food)
				if c < best_cost and p.coins >= w.sell_price(n, id):
					best_cost = c; best = n; best_id = id
	if best:
		var pr := w.sell_price(best, best_id)
		if w.trade(p, best, best_id, 1, pr):
			food_spent += pr
			w.player_eat(best_id)


func _mine(st: Dictionary) -> void:
	var pick := p.tool_of("pickaxe")
	if pick == "":
		# buy a pickaxe if anyone sells one
		for n: NPC in w.npcs:
			if n.alive and n.inv.has("pickaxe") and w.brain.for_sale(n).has("pickaxe") and p.coins >= w.sell_price(n, "pickaxe"):
				var pr := w.sell_price(n, "pickaxe")
				if w.trade(p, n, "pickaxe", 1, pr):
					log.append("%s bought pickaxe for %d" % [w.clock_text(), pr])
					return
		return
	var dep := {}
	for d in w.deposits:
		if d.ore == "iron_ore" and int(d.amount) > 0:
			dep = d; break
	if dep.is_empty():
		return
	var speed := float(GameData.item(pick).get("speed", 1.0))
	busy_until = w.minutes + float(GameData.b("mine_minutes")) * 0.6 / speed   # main.gd: secs*gmps
	var ore := w.mine_unit(dep)
	if ore != "":
		p.inv.add(ore)
		st.ore += 1
		if p.inv.wear(pick, 1):
			log.append("%s %s broke after %d ore" % [w.clock_text(), pick, st.ore])
		p.gain("mining", 8)


func _harvest(st: Dictionary) -> void:
	for n: NPC in w.npcs:
		if not n.alive or n.job != "farmer":
			continue
		var job := w.quests.hire_offer(n)
		if job.is_empty():
			continue
		var q := w.quests.accept(n, job.id)
		if q.is_empty():
			continue
		var f := w.quests.field_of(n)
		var cut := 0
		while cut < 24:
			var got := w.player_harvest(f)
			if got <= 0: break
			cut += got
		var paid: int = w.quests.complete(q)
		if paid > 0:
			st.hires += 1; st.hire_wages += paid; earned += paid
		elif paid == -2:
			st.unpaid += 1
		# 4 handfuls x 2.5 s = 5 game min each, plus ~10 game min to find the farmer
		busy_until = w.minutes + 30.0
		return
	st.no_offer_hours += 1
	busy_until = w.minutes + 30.0


func _hunt(st: Dictionary) -> void:
	var best: Animal = null
	for a: Animal in w.fauna.animals:
		if a.alive and a.wild() and a.adult(w.minutes) and (best == null or (a.species == "boar" and best.species != "boar")):
			best = a
	if best == null:
		busy_until = w.minutes + 60.0
		return
	var bag: Inventory = w.fauna.kill(best)
	for id in bag.ids():
		p.inv.add(id, bag.count(id))
	st.kills += 1
	busy_until = w.minutes + 30.0     # find, chase and strike (guess; walking not modelled)


func _sell_all(st: Dictionary) -> void:
	for id in p.inv.ids():
		if id in ["rusty_sword", "rusty_pickaxe", "pickaxe", "plain_clothes", "bread", "rotten_apple"]:
			continue
		var guard := 0
		while p.inv.has(id) and guard < 200:
			guard += 1
			var buyer: NPC = null
			for n: NPC in w.npcs:
				if n.alive and w.brain.wants(n, id) > 0 and n.coins >= w.buy_price(n, id) and (buyer == null or w.buy_price(n, id) > w.buy_price(buyer, id)):
					buyer = n
			if buyer == null:
				break
			var pr := maxi(1, roundi(w.buy_price(buyer, id) * w.player_price_factor(false)))
			var r: Dictionary = w.player_sell(buyer, id, pr)
			if r.result != "sold":
				break
			earned += pr
		if p.inv.has(id):
			st.unsold[id] = p.inv.count(id)


func _observe(strat: String) -> void:
	var parts := []
	for job in ["smith", "carpenter", "tanner", "cook", "tavernkeeper"]:
		var c := []
		for n: NPC in w.npcs:
			if n.alive and n.job == job:
				c.append(n.coins)
		parts.append("%s%s" % [job, c])
	for k in ["raw", "food", "goods"]:
		var c := []
		for n: NPC in w.npcs:
			if n.alive and w.brain.buy_role(n) == "merchant_" + k:
				c.append(n.coins)
		parts.append("m_%s%s" % [k, c])
	var hire := {"farmer": [0, 0], "woodcutter": [0, 0], "miner": [0, 0]}
	for n: NPC in w.npcs:
		if n.alive and hire.has(n.job):
			hire[n.job][1] += 1
			if not w.quests.hire_offer(n).is_empty():
				hire[n.job][0] += 1
	var ripe := 0
	for f in w.fields:
		if f.state == "ripe": ripe += 1
	var offers := []
	for id in w.quests.offers:
		offers.append(w.quests.offers[id])
	var dl := {}
	for d in w.deposits:
		dl[d.ore] = int(dl.get(d.ore, 0)) + int(d.amount)
	var grown := w.trees.filter(func(t): return t.state == "grown").size()
	print("%s deposits=%s grown_trees=%d" % [w.clock_text(), dl, grown])
	print("%s player=%d hunger=%d | %s | hire(avail/total)=%s ripe_fields=%d/%d | offers=%s | treasury=%d" % [w.clock_text(), p.coins, p.hunger, " ".join(parts), hire, ripe, w.fields.size(), offers, w.treasury])
