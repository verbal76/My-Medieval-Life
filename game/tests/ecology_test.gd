extends SceneTree
## EQ-03 (owner directive 2026-10-19: "Humans and nature affect each other through real NPC decisions"): hunting changes
## the woods, and wildlife numbers, predators and depletion change what villagers do, by real counts. And the parts of
## EQ-02 (nature sustains itself) not already shown by wildlife_test.gd, refuge_test.gd and aging_test.gd: wild births
## bounded by the breeding interval and the wood's cap (no unlimited instant respawning), and no wood's prey taken below
## its breeding stock by hunters. Run:
##   godot --headless --path game --script res://tests/ecology_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _init() -> void:
	GameData.ensure()
	hunting_changes_the_woods()
	numbers_change_the_hunt()
	no_game_no_hunter()
	predators_change_the_hunt()
	depletion_changes_work()
	wild_births_bounded()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func new_world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.player.pos = Vector2(60, 45)
	return w


func of(w: World, species: String, area := "") -> Array:
	return w.fauna.animals.filter(func(a): return a.alive and a.species == species and (area == "" or a.area == area))


func hunter(w: World) -> NPC:
	for o: NPC in w.npcs:
		if o.alive and o.job == "hunter":
			return o
	return null


## Leave `species` at its breeding stock (keep) of grown females in every wood it lives in: nothing a hunter may take.
func to_floor(w: World, species: String) -> void:
	var areas := []
	for a: Animal in of(w, species):
		if not areas.has(a.area):
			areas.append(a.area)
		w.fauna.remove(a)
	areas.sort()
	for area in areas:
		for i in int(GameData.b("animals")[species].keep):
			w.fauna.spawn(area, species, "f", null).born = w.minutes - 40.0 * 1440.0


## The wild kinds a hunter takes (Fauna.nearest_game's rule: wild, `game` not false).
func game_kinds(w: World) -> Array:
	var out := []
	for a: Animal in w.fauna.animals:
		if a.alive and a.wild() and bool(a.spec().get("game", true)) and not out.has(a.species):
			out.append(a.species)
	out.sort()
	return out


## A hunter's kill takes a real animal out of its wood and its meat or hide into the hunter's pack.
func hunting_changes_the_woods() -> void:
	var w := new_world()
	var n := hunter(w)
	var prey: Animal = w.fauna.nearest_game(n.pos)
	check(prey != null, "the hunter finds game (%s)" % (prey.label() if prey else "none"))
	if prey == null:
		return
	var c0 := w.fauna.count(prey.area, prey.species)
	var inv0: int = n.inv.total()
	n.pos = prey.pos
	w.brain.act(n, "hunt", {"animal": prey.id})
	check(not prey.alive and w.fauna.count(prey.area, prey.species) == c0 - 1, "the kill leaves one %s fewer in %s (%d -> %d)" % [prey.species, prey.area, c0, w.fauna.count(prey.area, prey.species)])
	check(n.inv.total() > inv0, "and its carcass is in the hunter's pack (%d things)" % (n.inv.total() - inv0))


## Wildlife numbers change the hunter's choice: a kind at its breeding stock is left alone and the hunter goes after
## another; with every kind at its floor the hunter lets the game recover.
func numbers_change_the_hunt() -> void:
	var w := new_world()
	var n := hunter(w)
	to_floor(w, "deer")
	var kinds := {}
	for i in 40:
		var a: Animal = w.fauna.nearest_game(Vector2(w.rng.randf_range(0, 120), w.rng.randf_range(0, 90)), 999.0)
		if a != null:
			kinds[a.species] = true
	check(not kinds.has("deer") and not kinds.is_empty(), "deer at their breeding stock are left alone; the hunter takes %s" % str(kinds.keys()))
	for k in game_kinds(w):
		to_floor(w, k)
	check(w.fauna.nearest_game(n.pos, 999.0) == null and w.fauna.takeable_game() == 0, "every kind at its floor: nothing a hunter may take")
	n.inv.items.clear()
	n.hunger = 100.0
	w.brain._hunter(n)
	check(n.doing == "letting the game recover", "the hunter lets the game recover (%s)" % n.doing)
	check(int(w.brain.job_market().hunter.open) == 0, "and the job market offers no hunter's place")


## EQ-03: with no game left above its floors a hunter has no work and looks for other work, as an adult out of work does;
## with game, the same hunter keeps the trade.
func no_game_no_hunter() -> void:
	for scarce in [false, true]:
		var w := new_world()
		var n := hunter(w)
		if scarce:
			for k in game_kinds(w):
				to_floor(w, k)
		n.coins = 500                              # enough for another trade's tool
		w.treasury = 100000                        # the manor hires, so there is work to go to
		w.brain.evaluate_household(n.household)
		w.brain.seek_work()
		if scarce:
			check(n.job != "hunter", "no game above its floors: the hunter takes other work (%s)" % n.job)
		else:
			check(n.job == "hunter", "with game in the woods the hunter keeps the trade")


## Predators change villagers' work by real counts: a wolf's kill lowers the game a hunter may take.
func predators_change_the_hunt() -> void:
	var w := new_world()
	var wolf: Animal = of(w, "wolf", "woods_w")[0]
	var g0 := w.fauna.takeable_game()
	var kills := 0
	for round in 6:
		wolf.hunger = 10.0
		for i in 200:
			w.fauna._eat(wolf, 60.0)
			if wolf.hunger >= 100.0:
				kills += 1
				break
	var g1 := w.fauna.takeable_game()
	check(kills > 0 and g1 < g0, "wolves' kills (%d) leave less game for hunters (%d -> %d)" % [kills, g0, g1])


## Depletion changes work: felled trees and worked-out seams close the woodcutters' and miners' openings.
func depletion_changes_work() -> void:
	var w := new_world()
	var m0: Dictionary = w.brain.job_market()
	for t in w.trees:
		if t.state == "grown":
			t.state = "stump"
	for d in w.deposits:
		d.amount = 0
	var m1: Dictionary = w.brain.job_market()
	check(int(m1.woodcutter.open) == 0 and int(m1.miner.open) == 0, "no grown trees and no ore: no woodcutter's or miner's place (were %d and %d)" % [int(m0.woodcutter.open), int(m0.miner.open)])


## EQ-02: wild births need a fed pair and wait the breeding interval; a litter never takes a wood past its cap. No
## unlimited or instant respawning.
func wild_births_bounded() -> void:
	var w := new_world()
	var area := "woods_e"
	for a: Animal in of(w, "deer", area):
		w.fauna.remove(a)
	var doe := w.fauna.spawn(area, "deer", "f", null)
	doe.born = w.minutes - 40.0 * 1440.0
	var stag := w.fauna.spawn(area, "deer", "m", null)
	stag.born = doe.born
	doe.next_birth = 0.0
	for a in [doe, stag]:
		a.hunger = 100.0
	# alone in the wood with a mate, fed, below the cap: a birth within a few mornings (a day's chance as the wood fills)
	var born := 0
	for d in 10:
		var c0 := w.fauna.count(area, "deer")
		w.fauna.new_day()
		born += w.fauna.count(area, "deer") - c0
		if born > 0:
			break
		doe.hunger = 100.0
		stag.hunger = 100.0
	check(born > 0 and born <= int(GameData.b("animals").deer.litter), "a fed pair has young: %d, at most a litter" % born)
	var c1 := w.fauna.count(area, "deer")
	doe.hunger = 100.0
	stag.hunger = 100.0
	w.fauna.new_day()
	check(w.fauna.count(area, "deer") == c1 or doe.next_birth <= w.minutes, "the next morning the doe does not give birth again: the breeding interval")
	# a full wood: no births at all
	var cap := w.fauna.cap(area, "deer")
	while w.fauna.count(area, "deer") < cap:
		w.fauna.spawn(area, "deer", "f", null).born = doe.born
	for a: Animal in of(w, "deer", area):
		a.hunger = 100.0
		a.next_birth = 0.0
	w.fauna.new_day()
	check(w.fauna.count(area, "deer") <= cap, "at its cap a wood breeds no more deer (%d of %d)" % [w.fauna.count(area, "deer"), cap])
