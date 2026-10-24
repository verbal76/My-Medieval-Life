extends SceneTree
## B7-006 (owner, 2026-10-21: closed as working as designed once a practical early-game earning route is verified): a
## new player starts with 20 coins, a rusty pickaxe and a rusty sword and no axe; the starting pickaxe mines a real
## deposit, and what it mines sells to a real buyer for coins that buyer actually had; a bandit drops only what they
## carried; the manor's board lists work a new player can take without an axe. Opportunities, not guarantees: the
## checks are on mechanisms, and what the routes yield is printed as a measurement. Run headless:
##   godot --headless --path game --script res://tests/early_game_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		print("FAIL ", what)
	else:
		print("ok   ", what)


func _init() -> void:
	GameData.ensure()
	for s in [1, 2]:
		_test_start(s)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _test_start(seed_value: int) -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed_value)
	var p := w.player
	var coins0 := w.total_coins()
	check(p.coins == int(GameData.b("start_coins_player")) and p.coins == 20, "seed %d: the player starts with 20 coins" % seed_value)
	check(p.inv.has("rusty_pickaxe") and p.inv.has("rusty_sword") and p.inv.has("rusty_axe") and not p.inv.has("axe"), "seed %d: a rusty pickaxe, a rusty axe and a rusty sword, no axe" % seed_value)
	check(p.tool_of("pickaxe") == "rusty_pickaxe", "seed %d: the rusty pickaxe serves as a pickaxe" % seed_value)
	# GP-START-RUSTY-AXE (owner 2026-10-24): the rusty axe fells, more slowly than an axe
	check(p.tool_of("axe") == "rusty_axe", "seed %d: the rusty axe serves as an axe" % seed_value)
	var tree := {}
	for t in w.trees:
		if str(t.state) == "grown":
			tree = t
			break
	if not tree.is_empty():
		var pos0 := p.pos
		p.pos = Vector2(int(tree.x), int(tree.y) + 1) + Vector2(0.5, 0.5)
		var plan := w.player_fell_plan(tree)
		check(plan.get("ok", false) and str(plan.get("tool", "")) == "rusty_axe", "seed %d: a grown tree can be felled with the rusty axe: %s" % [seed_value, str(plan)])
		p.inv.add("axe")
		var plan2 := w.player_fell_plan(tree)
		check(str(plan2.get("tool", "")) == "axe" and float(plan2.get("secs", 0.0)) < float(plan.get("secs", 0.0)), "seed %d: a proper axe is preferred and quicker" % seed_value)
		p.inv.remove("axe")
		p.pos = pos0
	check(FarmPlots.has_axe(p.inv), "seed %d: the rusty axe digs out a plot's stumps (FarmPlots.has_axe)" % seed_value)
	# mining route: the starting pickaxe on a real deposit, then a sale to a real buyer
	var got := {}
	for ore in ["stone", "iron_ore", "coal"]:
		var d := w.nearest_deposit(Vector2i(p.pos), [ore])
		if d.is_empty():
			continue
		for i in 6:
			var r := w.work_mine(p, d, p.inv, "pickaxe")
			if str(r.result) != "ok":
				break
			got[r.ore] = int(got.get(r.ore, 0)) + int(r.n)
	check(not got.is_empty(), "seed %d: the starting pickaxe mines a real deposit (%s)" % [seed_value, got])
	var earned := 0
	for id in got:
		for n: NPC in w.npcs:
			if not n.alive or not p.inv.has(id):
				continue
			if not NPCBrain.BUYS.get(w.brain.buy_role(n), {}).has(id):
				continue
			var purse := n.coins
			var r := w.player_sell_many(n, id, p.inv.count(id))
			if str(r.result) != "failed" and int(r.paid) > 0:
				check(n.coins == purse - int(r.paid), "seed %d: %s paid %d for %d %s from their own purse" % [seed_value, n.name, int(r.paid), int(r.sold), id])
				earned += int(r.paid)
	check(earned > 0, "seed %d: mined goods sold for %d coins" % [seed_value, earned])
	check(w.total_coins() == coins0, "seed %d: no coin made or lost by mining and selling" % seed_value)
	# combat route: a bandit carries only what they have
	var carry := []
	for n: NPC in w.npcs:
		if n.alive and n.role == "bandit":
			carry.append("%d coins, %s" % [n.coins, n.inv.ids()])
	print("     seed %d: bandits carry: %s" % [seed_value, "; ".join(carry) if not carry.is_empty() else "no bandits at the start"])
	# manor route: board work a new player may take without an axe
	w.treasury = maxi(w.treasury, 0)
	w.manor_work.refresh()
	var kinds := w.manor_work.open_for(World.PLAYER).map(func(j): return str(j.kind))
	print("     seed %d: day 0 board work open to the player: %s (treasury %d)" % [seed_value, kinds, w.treasury])
