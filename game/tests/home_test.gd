extends SceneTree
## B14: the villagers' home economy. Run: godot --headless --path game --script res://tests/home_test.gd
## Home production (food and medicine for the household's own use, from real plants and stock).

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   ", what)
	else:
		failures += 1
		print("FAIL ", what)


func new_world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


func _init() -> void:
	test_healing()
	test_foraging_and_brewing()
	test_village_days()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## An adult with a household and a home, at the evening hour, fed, free of plans.
func _villager(w: World) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 0 and n.home != "" and n.job != "sage":
			n.plan.clear()
			n.hunger = 100.0
			return n
	return null


func _evening(w: World) -> void:
	w.minutes = float(w.day()) * 1440.0 + 19.0 * 60.0


func test_healing() -> void:
	var w := new_world()
	_evening(w)
	var n := _villager(w)
	var pantry: Inventory = w.households[n.household].pantry
	for m in NPCBrain.MEDICINES:
		n.inv.items.erase(m)
		pantry.items.erase(m)
	n.hp = n.max_hp
	check(not w.brain._plan_heal(n), "a villager at full health does not treat themselves")
	n.hp = n.max_hp * 0.3
	pantry.add("herbal_poultice", 1)
	check(w.brain._plan_heal(n) and n.plan[-1].get("act", "") == "use_medicine", "hurt, they go home to dress the wound: " + n.doing)
	var hp0 := n.hp
	check(w.brain.act(n, "use_medicine", {"pantry": true}) and is_equal_approx(n.hp, minf(n.max_hp, hp0 + float(GameData.item("herbal_poultice").heal))) and not pantry.has("herbal_poultice"),
		"the household's poultice heals them and is used up")
	check(not w.brain.act(n, "use_medicine", {"pantry": true}), "with none left, nothing heals: no medicine from nowhere")
	# none at home: buy from the Apothecary with their own coins
	n.hp = n.max_hp * 0.3
	n.plan.clear()
	var sage := w.npc(w.sage_id)
	sage.plan.clear()
	sage.anim = "idle"
	n.coins = 50
	check(w.brain._plan_heal(n) and n.plan.any(func(s): return s.get("act", "") == "buy_from"), "with none at home they go to buy medicine: " + n.doing)
	var buy: Dictionary = n.plan.filter(func(s): return s.get("act", "") == "buy_from")[0]
	var total := w.total_coins()
	var c0 := n.coins
	var s0 := sage.coins
	check(w.brain.act(n, "buy_from", buy.args) and n.coins < c0 and sage.coins - s0 == c0 - n.coins and w.total_coins() == total, "bought with the villager's own coins (%d)" % (c0 - n.coins))
	var hp1 := n.hp
	check(w.brain.act(n, "use_medicine", {}) and n.hp > hp1, "and used")
	n.hp = n.max_hp * 0.3
	n.coins = 0
	n.plan.clear()
	check(not w.brain._plan_heal(n), "without coins or medicine they cannot treat themselves")


func test_foraging_and_brewing() -> void:
	var w := new_world()
	_evening(w)
	var n := _villager(w)
	n.hp = n.max_hp
	var pantry: Inventory = w.households[n.household].pantry
	for id in ["flower", "herbal_poultice", "red_berries", "blueberries"]:
		pantry.items.erase(id)
		n.inv.items.erase(id)
	check(w.brain._plan_home_work(n) and n.plan.any(func(s): return s.get("act", "") == "forage"), "the household needs medicine: they go to gather wild flowers: " + n.doing)
	var fstep: Dictionary = n.plan.filter(func(s): return s.get("act", "") == "forage")[0]
	var pl := {}
	for p in w.plants:
		if str(p.id) == str(fstep.args.plant):
			pl = p
	check(not pl.is_empty() and pl.kind == "flower" and pl.state == "ripe", "a real ripe flower near home (%s)" % pl.get("id", "?"))
	var dist := Vector2(w.building_door(n.home)).distance_to(Vector2(int(pl.x), int(pl.y)))
	check(dist <= float(NPCBrain.hp_cfg().forage_range), "within reach of home (%.0f tiles)" % dist)
	check(w.brain.act(n, "forage", fstep.args) and n.inv.has("flower") and pl.state == "picked", "picked: the flower is in hand and the plant is bare")
	check(not w.brain.act(n, "forage", fstep.args), "a picked plant gives nothing more")
	w.brain.act(n, "store_home", {})
	check(pantry.has("flower") and not n.inv.has("flower"), "the flower goes into the household's store")
	pantry.add("flower", 1)
	n.plan.clear()
	check(w.brain._plan_home_work(n) and n.plan[-1].get("act", "") == "home_brew", "with flowers enough they brew at home: " + n.doing)
	var f0 := pantry.count("flower")
	check(w.brain.act(n, "home_brew", {}) and pantry.count("herbal_poultice") == 1 and pantry.count("flower") == f0 - int(GameData.recipes.brew_poultice["in"].flower), "two flowers became a poultice at the hearth")
	pantry.items.erase("flower")
	check(not w.brain.act(n, "home_brew", {}), "no flowers, no poultice")
	pantry.add("herbal_poultice", int(NPCBrain.hp_cfg().poultice_keep))
	pantry.add("red_berries", int(NPCBrain.hp_cfg().berries_keep))
	n.plan.clear()
	check(not w.brain._plan_home_work(n), "a household with its poultices and berries in store does no more")


## Eight days of village life: villagers forage, brew and use their own medicine; coins conserved.
func test_village_days() -> void:
	var w := new_world()
	var start := w.total_coins()
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.id % 7 == 0:
			n.hp = n.max_hp * 0.4                   # a few villagers hurt, to see them treat themselves
	var steps := int(8.0 * 1440.0 / float(GameData.b("game_minutes_per_second")) / 0.5)
	for i in steps:
		w.update(0.5)
	var st: Dictionary = w.stats
	var used := 0
	for m in NPCBrain.MEDICINES:
		used += int(st.get("npc_used_" + m, 0))
	print("  home stats: ", {"foraged_flower": st.get("villager_foraged_flower", 0), "foraged_berries": int(st.get("villager_foraged_red_berries", 0)) + int(st.get("villager_foraged_blueberries", 0)),
		"home_brewed": st.get("home_brewed", 0), "medicine_used": used})
	check(int(st.get("villager_foraged_flower", 0)) > 0 and int(st.get("home_brewed", 0)) > 0, "over 8 days villagers gather flowers and brew poultices at home")
	check(used > 0, "and hurt villagers use medicine")
	check(w.total_coins() == start + w.coin_sources, "coins conserved (%d + sources %d = %d)" % [start, w.coin_sources, w.total_coins()])
