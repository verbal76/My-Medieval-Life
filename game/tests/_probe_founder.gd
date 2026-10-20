extends SceneTree
func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 2)
	for m in 30 * 1440:
		w.update(0.5)
		w.player.hunger = 100.0
	var who: NPC = null
	for h in w.households.size():
		if str(w.households[h].get("build", "")) != "":
			who = w.construction.responsible_adult(h)
	if who == null:
		print("no builder"); quit(0); return
	print("builder ", who.name, " job ", who.job, " home ", who.home, " hh ", who.household)
	var last := ""
	var e0 := who.earned
	var s0 := who.spent
	for m in 2 * 1440:
		w.update(0.5)
		w.player.hunger = 100.0
		var line := "%s c%d inv=%s" % [who.doing, who.coins, who.inv.to_dict()]
		if line != last and m % 10 == 0:
			print("d%d %02d:%02d %s hunger %d" % [w.day(), int(w.hour()), int(w.minutes) % 60, line, int(who.hunger)])
			last = line
	print("earned ", who.earned - e0, " spent ", who.spent - s0, " income_days ", who.income_days)
	quit(0)
