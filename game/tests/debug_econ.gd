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
	w.setup(VillageMap.load_default(), 1)
	var deaths := []
	w.npc_died.connect(func(n): deaths.append("%s %s at %s" % [n.name, n.family, w.clock_text()]))
	var last_hour := -1
	for i in int(days * 1440 / 2.0 / 0.5):
		w.update(0.5)
		var h := int(w.minutes / 60.0)
		if h != last_hour and h % 3 == 0:
			last_hour = h
			for n: NPC in w.npcs:
				if "%s %s" % [n.name, n.family] == who or (n.name == who and n.role != "bandit"):
					var hh: Dictionary = w.households[n.household]
					print("%s %s %s alive=%s hp=%d hunger=%d coins=%d doing=%s pantry=%s inv=%s" % [w.clock_text(), n.family, n.job, n.alive, n.hp, n.hunger, n.coins, n.doing, hh.pantry.items, n.inv.items])
	print("deaths: ", deaths)
	quit()
