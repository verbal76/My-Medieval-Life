extends SceneTree
## Diagnostics: follows one villager (by name, default the first to die) through the simulation.
##   godot --headless --path game --script res://tests/debug_econ.gd -- --name Bartholomew --days 8
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var who := "Bartholomew"
	var days := 8
	for i in args.size():
		if args[i] == "--name":
			who = args[i + 1]
		elif args[i] == "--days":
			days = int(args[i + 1])
	var w := World.new()
	w.setup(VillageMap.load_default(), int(args[args.find("--seed") + 1]) if "--seed" in args else 1)
	var deaths := []
	var events := []
	w.event.connect(func(t): events.append(t))
	w.npc_died.connect(func(n): deaths.append("%s %s at %s" % [n.name, n.family, w.clock_text()]))
	var last_hour := -1
	for i in int(days * 1440 / 2.0 / 0.5):
		w.update(0.5)
		var h := int(w.minutes / 60.0)
		if h != last_hour and (h % 3 == 0 or "--hourly" in args):
			last_hour = h
			for n: NPC in w.npcs:
				if "%s %s" % [n.name, n.family] == who or (n.name == who and n.role != "bandit"):
					var hh: Dictionary = w.households[n.household]
					print("%s %s %s alive=%s hp=%d hunger=%d coins=%d doing=%s pantry=%s inv=%s" % [w.clock_text(), n.family, n.job, n.alive, n.hp, n.hunger, n.coins, n.doing, hh.pantry.items, n.inv.items])
	print("deaths: ", deaths)
	if "--grep" in args:
		var pat: String = args[args.find("--grep") + 1]
		for l in events:
			if pat in l:
				print(l)
	if "--household" in args:
		var fam: String = args[args.find("--household") + 1]
		for hh in w.households:
			if hh.family == fam:
				for m in hh.members:
					var o: NPC = w.npc(m)
					print("  %s %s %s/%s alive=%s coins=%d earned=%d spent=%d hunger=%d doing=%s inv=%s" % [o.name, o.family, o.role, o.job, o.alive, o.coins, o.earned, o.spent, o.hunger, o.doing, o.inv.items])
	if "--animals" in args:
		var meat := 0
		for n: NPC in w.npcs:
			meat += n.inv.count("meat") + n.inv.count("roast_meat")
		print("meat and roast meat held: ", meat)
		for l in events:
			if "pen" in l or "starved" in l or "slaughter" in l or "game" in l:
				print(l)
		for id in w.fauna.pens:
			var pen: Dictionary = w.fauna.pens[id]
			var k := w.npc(int(pen.owner))
			print(id, " trough=", pen.trough, " need=", w.fauna.daily_need(pen), " keeper=", k.name, " ", k.family, " ", k.doing, " inv=", k.inv.items)
	quit()
