extends SceneTree
## LIFE-01: an adult's permanent employment must end when the NPC retires at 55.
## Retirement should return owed materials and release paid employment/capacity.
var checks := 0
var failures := 0

func check(ok: bool, what: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + what)
	if not ok:
		failures += 1

func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 8111)
	var start = w.map.data.spawns.player
	var r: Rect2i = w.construction.find_ground("house", Vector2i(int(start[0]), int(start[1])), World.PLAYER)
	w.player.coins += w.property.land_price(r.size.x, r.size.y) + 3000
	var site: Dictionary = w.construction.place("house", r, World.PLAYER)
	check(not site.is_empty(), "LIFE-01: player has a construction site for home")
	if site.is_empty():
		w.dispose()
		quit(1)
		return
	for id in site.site.need.duplicate():
		w.player.inv.add(id, int(site.site.need[id]))
	w.deliver(site, w.player.inv)
	w.property.set_home(str(site.building))
	var store: Inventory = w.construction.store_of(World.PLAYER)
	check(store != null, "LIFE-01: employer has valid home store")
	var employee: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 0 and n.job in Construction.HIRABLE and w.employment.obligation(n) == "":
			employee = n
			break
	check(employee != null, "LIFE-01: independent adult eligible for permanent employment")
	if employee == null or store == null:
		w.dispose()
		quit(1)
		return
	var hired := w.employment.employ(employee, "miner")
	check(hired == "" and w.employment.is_employed(employee), "LIFE-01: player hires a paid permanent employee")
	if hired != "":
		w.dispose()
		quit(1)
		return
	var rec: Dictionary = w.employment.record_of(employee)
	var wage: int = int(rec.wage)
	employee.inv.add("plank", 2)
	rec.owed["plank"] = 2
	var old_store := store.count("plank")
	var year := Life.year_minutes()
	employee.born = w.minutes - year * 54.95
	w.minutes += year * 0.10
	Life.sync_roles(w)
	check(employee.role == "elder" and employee.job == "", "LIFE-01: employee retires at 55")
	check(not w.employment.is_employed(employee), "LIFE-01: retirement closes permanent employment")
	check(store.count("plank") == old_store + 2 and employee.inv.count("plank") == 0, "LIFE-01: outstanding employer goods handed over on retirement")
	var before := w.player.coins
	var employee_coins := employee.coins
	w.minutes = float(w.day() + 1) * 1440.0 + 12.0 * 60.0
	w.employment.daily()
	check(w.player.coins == before and employee.coins == employee_coins, "LIFE-01: retired villager receives no next-day wage")
	check(w.employment.of_employer(World.PLAYER).is_empty(), "LIFE-01: retirement frees employer staff capacity")
	check(w.total_coins() >= wage, "LIFE-01: world remains funded after retirement")
	w.dispose()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
