extends SceneTree
## REC-F1 measurement (diagnostic, changes nothing): steps the real World for N days (no player activity) and prints, per day,
## top-level decisions (total and the five most deciding villagers), actions by kind, sales, coins and deaths.
##   godot --headless --path game --script res://tests/recf1_measure.gd -- --days 10 --seed 1
const STEP := 0.5

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var days := int(args[args.find("--days") + 1]) if "--days" in args else 10
	var seed := int(args[args.find("--seed") + 1]) if "--seed" in args else 1
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	var per_day := int(1440.0 / float(GameData.b("game_minutes_per_second")) / STEP)
	var last_d := 0
	var last_a := {}
	var last_s := {}
	var last_dec := {}
	for d in days:
		for i in per_day:
			w.update(STEP)
			w.player.hunger = 100.0
		var dec: Dictionary = w.brain.decide_calls
		var total := 0
		var top := []
		for id in dec:
			var c := int(dec[id]) - int(last_dec.get(id, 0))
			total += c
			top.append([c, id])
		top.sort()
		top.reverse()
		var acts := {}
		var at := 0
		for k in w.brain.act_calls:
			acts[k] = int(w.brain.act_calls[k]) - int(last_a.get(k, 0))
			at += acts[k]
		var sold := 0.0
		for k in ["sold_items", "trades", "units_sold"]:
			sold += float(w.stats.get(k, 0.0)) - float(last_s.get(k, 0.0))
		var coins := 0
		var alive := 0
		for n in w.npcs:
			if n.alive:
				alive += 1
				coins += n.coins
		print("DAY %d decides %d actions %d alive %d coins %d top5 %s" % [d, total, at, alive, coins, JSON.stringify(top.slice(0, 5))])
		print("  ACTS ", JSON.stringify(acts))
		last_dec = dec.duplicate()
		last_a = w.brain.act_calls.duplicate()
		last_s = w.stats.duplicate()
	var keep := {}
	for k in w.stats:
		if k.begins_with("made_") or k.begins_with("eaten") or k.begins_with("sold") or k.begins_with("missed") or k.begins_with("used_") or k.begins_with("trade"):
			keep[k] = snappedf(float(w.stats[k]), 0.1)
	print("STATS ", JSON.stringify(keep))
	var dead := 0
	for n in w.npcs:
		if not n.alive:
			dead += 1
	print("DEAD ", dead)
	w.dispose()
	quit(0)
