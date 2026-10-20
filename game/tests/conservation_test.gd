extends SceneTree
## DVW-A6: coins and goods are conserved across saving and loading, and across the near and far
## simulation tiers. A seeded village runs two game days (villagers far from the player run on the
## abstract tier, near ones in full), is saved through JSON as the game saves it and loaded into a new
## World; every coin and every good (the same census as economy_sim.gd), each deposit, each animal kind
## and every villager must be there after loading. Then the loaded world runs on, and its currency still
## balances against what came in from outside.
##   godot --headless --path game --script res://tests/conservation_test.gd

const Census := preload("res://tests/census.gd")
const STEP := 0.5

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL: " + what)


func _init() -> void:
	GameData.ensure()
	var map := VillageMap.load_default()
	var w := World.new()
	w.setup(map, 3)
	_run(w, 2.0)
	var tiers := _tiers(w)
	check(tiers.near > 0 and tiers.far > 0, "the village runs on both tiers (%d near the player, %d far)" % [tiers.near, tiers.far])
	var before := _state(w)
	var text := JSON.stringify(w.to_dict(), "", true, true)              # as main.gd saves
	var w2 := World.new()
	w2.load_dict(map, JSON.parse_string(text))
	var after := _state(w2)
	check(after.coins == before.coins, "every coin is there after loading (%d before, %d after)" % [before.coins, after.coins])
	check(after.coin_sources == before.coin_sources, "and the record of coins from outside (%d)" % before.coin_sources)
	check(after.goods == before.goods, "every good is there after loading (%d kinds, %d items)%s" % [before.goods.size(), _sum(before.goods), _diff(before.goods, after.goods)])
	check(after.deposits == before.deposits, "every deposit holds what it held")
	check(after.animals == before.animals, "every animal kind is there (%s)" % str(before.animals))
	check(after.people == before.people, "every villager is there, alive or dead (%s)" % str(before.people))
	# the loaded world runs on: its currency still balances (start + in - out = now), across both tiers
	var stats0 := w2.stats.duplicate()
	var coins0 := w2.total_coins()
	_run(w2, 1.0)
	var d := func(k: String) -> int: return int(w2.stats.get(k, 0)) - int(stats0.get(k, 0))
	var c_in: int = d.call("caravan_coins_in") + d.call("newcomer_coins_in")
	var c_out: int = d.call("caravan_coins_out")
	var leak := w2.total_coins() - coins0 - c_in + c_out
	check(leak == 0, "a day after loading the currency balances (leak %d)" % leak)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _run(w: World, days: float) -> void:
	var steps := int(days * 1440.0 / float(GameData.b("game_minutes_per_second")) / STEP)
	for i in steps:
		w.update(STEP)
		w.player.hunger = 100.0             # the idle player is fed, as in economy_sim


func _state(w: World) -> Dictionary:
	var animals := {}
	for a: Animal in w.fauna.animals:
		if a.alive:
			animals[a.species] = int(animals.get(a.species, 0)) + 1
	var people := {"alive": 0, "dead": 0}
	for n: NPC in w.npcs:
		people["alive" if n.alive else "dead"] += 1
	return {"coins": w.total_coins(), "coin_sources": w.coin_sources, "goods": Census.goods(w),
		"deposits": w.deposits.map(func(x): return int(x.amount)), "animals": animals, "people": people}


## How many living villagers are near the player (full simulation) and far (the abstract tier).
func _tiers(w: World) -> Dictionary:
	var out := {"near": 0, "far": 0}
	for n: NPC in w.npcs:
		if n.alive:
			out["near" if n.pos.distance_to(w.player.pos) < w.detail_radius else "far"] += 1
	return out


func _sum(g: Dictionary) -> int:
	var s := 0
	for id in g:
		s += int(g[id])
	return s


func _diff(a: Dictionary, b: Dictionary) -> String:
	var out := []
	var ids := a.keys() + b.keys()
	ids.sort()
	for id in ids:
		if int(a.get(id, 0)) != int(b.get(id, 0)) and not out.has(id):
			out.append("%s %d->%d" % [id, int(a.get(id, 0)), int(b.get(id, 0))])
	return "" if out.is_empty() else ": " + ", ".join(out)
