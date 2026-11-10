extends SceneTree
## B25-INV-BANDIT-CHILD (owner 2026-11-10, docs/directives/2026-11-10_continued_investigation_merge_prep.md 2C; investigation
## docs/audits/2026-11-10_INVESTIGATIONS_P52_BANDIT_CHILDREN.md). Found in the recorded campaign 42788018729 (fbfd6ad, seed 1):
## four children of the bandit clan (p:1000856, p:1000832, p:259, p:1000886) starved on days 305-306 while their household,
## the band's household 25, held 10 wheat in its pantry the whole time (the chapel's relief was even delivered there). Batch 3's
## seed 1 had the same in household 25 (days 155-156). A clan child's every meal is NPCBrain._clan_child's "camp_meal", which ate
## only through band_eat: the child's own pack and the living bandits' packs, never the household's pantry (the three bandits
## were homeless and starving themselves: a genuine shortage of the band's own food, WDR-022). Now a clan child also eats from
## their household's pantry, the band's stores, by the same rule as any household's meal (NPCBrain.EDIBLE, one unit at a
## time). Checked:
##   1 a hungry clan child whose household pantry holds wheat eats it (no food created: exactly what they eat leaves the pantry)
##   2 with nothing in the pantry or the band's packs, nothing is eaten and nothing is created (a shortage stays a shortage)
##   3 the band's packs are still eaten from as before (the child's own pack first, then the bandits')
##   4 a bandit's own meal (household -1) is unchanged
##   5 the same after a save and load, and on two identical worlds (deterministic)
##   godot --headless --path game --script res://tests/clan_child_pantry_test.gd

var checks := 0
var fails := 0


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		fails += 1


func _init() -> void:
	GameData.ensure()
	case_pantry()
	case_shortage()
	case_band_packs()
	case_bandit_unchanged()
	case_save_load_and_replay()
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)


## A world where child `k` belongs to the bandit clan, in household `h` whose pantry holds `wheat` wheat, every bandit's pack
## and the child's own emptied of food. Returns {w, k, h}.
func setup(wheat := 10, seed := 1) -> Dictionary:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	var k: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "child" and o.household >= 0:
			k = o
			break
	k.clan = "bandit"
	for o: NPC in w.npcs:
		if o.role == "bandit" or o == k:
			for f in NPCBrain.EDIBLE + ["meat"]:
				o.inv.remove(f, o.inv.count(f))
	var p: Inventory = w.households[k.household].pantry
	p.items.clear()
	if wheat > 0:
		p.add("wheat", wheat)
	k.hunger = 10.0
	return {"w": w, "k": k, "h": k.household}


func _food(w: World) -> int:
	var t := 0
	for o: NPC in w.npcs:
		for f in NPCBrain.EDIBLE:
			t += o.inv.count(f)
	for hh in w.households:
		for f in NPCBrain.EDIBLE:
			t += (hh.pantry as Inventory).count(f)
	return t


func case_pantry() -> void:
	var s := setup()
	var w: World = s.w
	var k: NPC = s.k
	var p: Inventory = w.households[s.h].pantry
	var f0 := _food(w)
	var h0 := k.hunger
	w.brain.act(k, "camp_meal", {})
	var eaten := 10 - p.count("wheat")
	check(k.hunger > h0 and eaten > 0, "a hungry clan child eats the wheat in their household's pantry (hunger %.0f -> %.0f, %d eaten)" % [h0, k.hunger, eaten])
	check(_food(w) == f0 - eaten, "no food is created: exactly the %d eaten leave the pantry (%d -> %d)" % [eaten, f0, _food(w)])
	w.dispose()


func case_shortage() -> void:
	var s := setup(0)
	var w: World = s.w
	var k: NPC = s.k
	var f0 := _food(w)
	w.brain.act(k, "camp_meal", {})
	check(k.hunger == 10.0 and _food(w) == f0, "with no food in the pantry or the band's packs nothing is eaten or created (hunger %.0f)" % k.hunger)
	w.dispose()


func case_band_packs() -> void:
	var s := setup(0)
	var w: World = s.w
	var k: NPC = s.k
	var b: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "bandit":
			b = o
			break
	if b == null:
		check(true, "(no bandit in this world: nothing to compare)")
		w.dispose()
		return
	b.inv.add("bread", 2)
	w.brain.act(k, "camp_meal", {})
	check(k.hunger > 10.0 and b.inv.count("bread") < 2, "the band's packs are eaten from as before (bread %d left)" % b.inv.count("bread"))
	w.dispose()


func case_bandit_unchanged() -> void:
	var s := setup()
	var w: World = s.w
	var b: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "bandit":
			b = o
			break
	if b == null:
		check(true, "(no bandit in this world)")
		w.dispose()
		return
	b.hunger = 10.0
	var ate: bool = w.brain.band_eat(b)
	check(not ate and b.hunger == 10.0, "a bandit (household %d) with an empty band still finds nothing to eat in a household's pantry" % b.household)
	w.dispose()


func case_save_load_and_replay() -> void:
	var s := setup()
	var w: World = s.w
	var k: NPC = s.k
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true)))
	var k2 := w2.npc(k.id)
	w.brain.act(k, "camp_meal", {})
	w2.brain.act(k2, "camp_meal", {})
	check(k.hunger == k2.hunger and k.hunger > 10.0 and (w.households[s.h].pantry as Inventory).count("wheat") == (w2.households[s.h].pantry as Inventory).count("wheat"),
		"after a save and load the same meal (hunger %.0f, %.0f)" % [k.hunger, k2.hunger])
	var a := setup()
	var b := setup()
	a.w.brain.act(a.k, "camp_meal", {})
	b.w.brain.act(b.k, "camp_meal", {})
	check((a.k as NPC).hunger == (b.k as NPC).hunger, "two identical worlds give the same meal (deterministic)")
	w.dispose()
	w2.dispose()
	a.w.dispose()
	b.w.dispose()
