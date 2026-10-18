extends SceneTree
func _init() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var c := w.construction
	var h := w.household_in("b5")
	var hh: Dictionary = w.households[h]
	var from := w.household_in("b10")
	var moved := 0
	for m in (w.households[from].members as Array).duplicate():
		var o: NPC = w.npc(int(m))
		if o.role == "child" and moved < 2:
			(w.households[from].members as Array).erase(o.id)
			(hh.members as Array).append(o.id)
			o.household = h
			o.home = "b5"
			moved += 1
	w.party(World.hh_ref(h)).coins += 600
	w.minutes = float(w.day()) * World.DAY + 6.0 * 60.0
	w.last_hour = int(w.minutes / 60.0)
	c.daily()
	var n0 := w.households.size() - 1
	var nh: Dictionary = w.households[n0]
	var site: Dictionary = w.plot(str(nh.get("build", "")))
	print("site ", site.id, " ", site.site.need, " purse ", w.property.purse(World.hh_ref(n0)))
	for i in int(8 * 1440 / 1.0):
		w.update(0.5)
		if i % 120 == 0:
			var k := c.contracts.filter(func(x): return x.site == site.id)
			var info := ""
			for x in k:
				var n := w.npc(int(x.worker))
				info += " worker %s (%s) doing '%s' spent %d/%d load %s" % [n.name, n.job, n.doing, int(x.spent), int(x.budget), x.load.items]
			print(w.clock_text(), " need ", site.site.need, " purse ", w.property.purse(World.hh_ref(n0)), info)
		if site.site.get("done", false):
			print("done ", w.clock_text())
			break
	var sellers := []
	for o: NPC in w.npcs:
		if o.alive and (o.inv.has("plank") or o.inv.has("stone") or o.inv.has("log")):
			sellers.append("%s %s/%s p%d s%d l%d" % [o.name, o.job, w.brain.buy_role(o), o.inv.count("plank"), o.inv.count("stone"), o.inv.count("log")])
	print(sellers)
	for l in w.log_lines:
		if "carr" in l or "hire" in l or "build" in l or "site" in l or "found" in l:
			print(l)
	quit()
