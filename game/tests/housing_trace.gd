extends SceneTree
## EQ-07 diagnostic: steps the real World with no player and, each dawn and dusk, prints every household
## that is crowded, building, or lodging without a home: its purse, its site's remaining need and what it
## would cost, whether anyone carries for it today, and what its people are doing. Diagnostics only.
##   godot --headless --path game --script res://tests/housing_trace.gd -- --days 40 [--seed 2]

var w: World


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var days := 40
	var seed := 2
	for i in args.size():
		if args[i] == "--days":
			days = int(args[i + 1])
		elif args[i] == "--seed":
			seed = int(args[i + 1])
	GameData.ensure()
	w = World.new()
	w.setup(VillageMap.load_default(), seed)
	for d in days:
		for m in 1440:
			w.update(0.5)
			w.player.hunger = 100.0
			if m == 1439 or m == 720:
				_report(d, m)
	quit(0)


func _report(d: int, m: int) -> void:
	var c: Construction = w.construction
	for h in w.households.size():
		var hh: Dictionary = w.households[h]
		if hh.get("ended", false):
			continue
		var members: Array = w.brain._members(h)
		var building := str(hh.get("build", ""))
		var is_crowded := c.crowded(h)
		var lodging := str(hh.home) == ""
		if building == "" and not is_crowded and not lodging:
			continue
		var ref := World.hh_ref(h)
		var line := "d%d %s hh%d %s n=%d purse=%d" % [d, "noon" if m == 720 else "eve", h, hh.family, members.size(), w.property.purse(ref)]
		if is_crowded:
			var f := c.founder_of(h)
			line += " CROWDED beds=%d founder=%s" % [c.beds_in(str(hh.home)), "none" if f == null else "%s(%s)" % [f.name, f.job]]
		if lodging:
			line += " LODGING"
		if building != "":
			var p: Dictionary = w.plot(building)
			if not p.is_empty() and not p.site.is_empty():
				line += " SITE need=%s est=%d" % [JSON.stringify(p.site.need), c.estimate(p.site.need)]
				var carrying := []
				for k in c.contracts:
					if str(k.site) == str(p.id):
						carrying.append("%s spent=%d/%d" % [w.npc(int(k.worker)).name, int(k.spent), int(k.budget)])
				line += " carriers=%s" % [carrying]
		var doing := []
		for o: NPC in members:
			doing.append("%s:%s/%s c%d '%s'%s" % [o.name, o.role, o.job, o.coins, o.doing, " axe" if o.inv.has("axe") else ""])
		print(line, " | ", ", ".join(doing))
	if m == 1439:
		var stock := {}
		for o: NPC in w.npcs:
			if o.alive and o.role == "adult":
				for id in ["stone", "plank", "log"]:
					if c._sells(o, id):
						stock[id] = int(stock.get(id, 0)) + o.inv.count(id)
		print("d%d for sale: %s; helper_bought %d" % [d, stock, int(w.stats.get("helper_bought", 0))])
