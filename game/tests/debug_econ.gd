extends SceneTree
func _init() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var bandit_deaths := []
	w.npc_died.connect(func(n): if n.role == "bandit": bandit_deaths.append("%s at %s, %s" % [n.name, w.clock_text(), n.pos]))
	for i in int(4 * 1440 / 2.0 / 0.5):
		w.update(0.5)
	print("bandit deaths: ", bandit_deaths)
	for n: NPC in w.npcs:
		if n.role != "bandit" and (not n.alive or n.hunger < 30):
			var hh: Dictionary = w.households[n.household]
			print("%s %s %s/%s alive=%s hunger=%d coins=%d doing=%s pantry=%s inv=%s" % [n.name, n.family, n.role, n.job, n.alive, n.hunger, n.coins, n.doing, hh.pantry.items, n.inv.items])
	print("--- vendors")
	for n: NPC in w.npcs:
		if n.alive and (n.job in ["tavernkeeper", "cook", "merchant", "smith", "carpenter", "farmer", "miner"]):
			print("%s %s: coins=%d inv=%s doing=%s" % [n.job, n.name, n.coins, n.inv.items, n.doing])
	quit()
