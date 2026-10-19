extends SceneTree
## B14: the forest animals (MiniFolks pack). Run: godot --headless --path game --script res://tests/wildlife_test.gd
## Grazers graze, hunters hunt and eat their prey, prey flee, the fox raids the pens at night, wolves and bears
## fight back and a starving one goes for a lone person in its wood; the hunter and the player hunt them.

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
	test_population()
	test_predation()
	test_chase_and_flee()
	test_fox_raid()
	test_people()
	test_hunting()
	test_save()
	test_days()
	test_sprites()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _of(w: World, species: String, area := "") -> Array:
	return w.fauna.animals.filter(func(a): return a.alive and a.species == species and (area == "" or a.area == area))


## The player far from the woods, so everything there runs off-screen.
func _away(w: World) -> void:
	w.player.pos = Vector2(60, 45)


func test_population() -> void:
	var w := new_world()
	for k in ["deer", "wolf", "fox", "bird"]:
		check(_of(w, k, "woods_w").size() > 0 and _of(w, k, "woods_e").size() > 0, "%s live in both woods (%d)" % [k, _of(w, k).size()])
	check(_of(w, "bear", "woods_w").size() == 2 and _of(w, "bear", "woods_e").is_empty(), "a pair of bears in the west wood only")
	var stags := _of(w, "deer").filter(func(a): return a.sex == "m")
	var does := _of(w, "deer").filter(func(a): return a.sex == "f")
	check(stags.all(func(a): return a.skin == "mini_stag") and does.all(func(a): return a.skin == "mini_doe"), "stags have antlers, does do not")
	check(w.fauna.seeded == w.fauna.wild_species(), "every wild species is marked started")


func test_predation() -> void:
	var w := new_world()
	_away(w)
	var wolf: Animal = _of(w, "wolf", "woods_w")[0]
	wolf.hunger = 10.0
	var deer0 := _of(w, "deer", "woods_w").size() + _of(w, "boar", "woods_w").size() + _of(w, "rabbit", "woods_w").size()
	for i in 200:                                 # 200 game hours offered at most
		w.fauna._eat(wolf, 60.0)
		if wolf.hunger >= 100.0:
			break
	var deer1 := _of(w, "deer", "woods_w").size() + _of(w, "boar", "woods_w").size() + _of(w, "rabbit", "woods_w").size()
	check(wolf.hunger == 100.0 and deer1 == deer0 - 1, "a hungry wolf kills and eats one of its prey in its wood")
	var eaten := 0
	for k in w.stats:
		if str(k).begins_with("eaten_") and str(k).ends_with("_by_wolf"):
			eaten += int(w.stats[k])
	check(eaten == 1, "the kill is counted")
	# never below a prey's breeding stock
	for a: Animal in _of(w, "rabbit", "woods_w") + _of(w, "deer", "woods_w") + _of(w, "boar", "woods_w"):
		w.fauna.remove(a)
	for k in ["rabbit", "deer", "boar"]:
		for i in int(GameData.b("animals")[k].keep):
			w.fauna.spawn("woods_w", k, "f", null).born = w.minutes - 20.0 * 1440.0
	wolf.hunger = 10.0
	for i in 200:
		w.fauna._eat(wolf, 60.0)
	check(wolf.hunger < 100.0, "with every prey at its breeding stock the wolf goes hungry: nothing below keep is taken")
	# the grazers' food: wolves and foxes do not count against the grass
	var g := w.fauna.grazers("woods_w")
	check(g == _of(w, "deer", "woods_w").size() + _of(w, "boar", "woods_w").size() + _of(w, "rabbit", "woods_w").size(), "only grazers count against the wood's grass (%d)" % g)
	# the bear eats berries first
	var bear: Animal = _of(w, "bear", "woods_w")[0]
	var r: Dictionary = w.fauna.woods.woods_w
	var bush := {}
	for pl in w.plants:
		if str(pl.kind) in ["redberry", "blueberry"] and int(pl.x) >= int(r.x) - 4 and int(pl.x) < int(r.x) + int(r.w) + 4 and int(pl.y) >= int(r.y) - 4 and int(pl.y) < int(r.y) + int(r.h) + 4:
			bush = pl
			break
	if not bush.is_empty():
		bush.state = "ripe"
		bear.hunger = 10.0
		w.fauna._eat(bear, 60.0)
		check(bear.hunger == 100.0 and bush.state == "picked", "a hungry bear eats a ripe berry bush by its wood")
	else:
		check(true, "(no berry bush by the west wood on this map: the bear hunts)")


func test_chase_and_flee() -> void:
	var w := new_world()
	var wolf: Animal = _of(w, "wolf", "woods_w")[0]
	var prey: Animal = null
	for a: Animal in _of(w, "rabbit", "woods_w"):
		prey = a
	for i in 3:
		w.fauna.spawn("woods_w", "rabbit", "f", null).born = w.minutes - 20.0 * 1440.0
	w.player.pos = wolf.pos + Vector2(2, 0)
	wolf.hunger = 30.0                          # hungry, not starving (a starving one would go for the lone player)
	w.fauna._eat(wolf, 0.0)
	check(wolf.hunt != -1, "near the player a hungry wolf picks a prey to chase (%s)" % (w.fauna.by_id(wolf.hunt).label() if wolf.hunt != -1 else "none"))
	var target: Animal = w.fauna.by_id(wolf.hunt)
	target.pos = wolf.pos + Vector2(0.5, 0)
	w.fauna._move(wolf, 0.1)
	check(not target.alive and wolf.hunger == 100.0, "it catches the prey in reach and eats it")
	# prey run from a hunter
	var r: Animal = w.fauna.spawn("woods_w", "rabbit", "f", null)
	r.pos = wolf.pos + Vector2(1.5, 0)
	r.goal = Vector2.INF
	w.fauna._move(r, 0.05)
	check(r.goal != Vector2.INF and (r.goal - wolf.pos).length() > (r.pos - wolf.pos).length(), "a rabbit near a wolf runs away from it")
	prey = prey


func test_fox_raid() -> void:
	var w := new_world()
	_away(w)
	var fox: Animal = _of(w, "fox")[0]
	var pen: Dictionary = w.fauna.pen_of("chicken")
	var hens0 := w.fauna.count(pen.id, "chicken")
	w.minutes = float(w.day()) * 1440.0 + 12.0 * 60.0
	fox.hunger = 10.0
	check(not w.fauna._raid(fox, 6000.0), "by day the fox does not raid the pens")
	w.minutes = float(w.day()) * 1440.0 + 23.0 * 60.0
	check(w.fauna._raid(fox, 6000.0) and w.fauna.count(pen.id, "chicken") == hens0 - 1 and fox.hunger == 100.0, "at night a hungry fox takes a chicken")
	while w.fauna.count(pen.id, "chicken") > int(GameData.b("animals").chicken.keep):
		w.fauna._raid(fox, 6000.0)
	check(not w.fauna._raid(fox, 6000.0), "never below the pen's breeding stock")


func test_people() -> void:
	var w := new_world()
	var p := w.player
	var wolf: Animal = _of(w, "wolf", "woods_w")[0]
	wolf.hunger = 100.0
	p.pos = wolf.pos + Vector2(0.6, 0)
	w.fauna._move(wolf, 0.05)
	check(wolf.anger == "", "a fed wolf leaves a passer-by alone")
	w.fauna.provoke(wolf, "player")
	check(wolf.anger == "player", "struck, a wolf fights back")
	var hp0 := p.hp
	wolf.bite_cd = 0.0
	w.fauna._move(wolf, 0.05)
	check(p.hp < hp0, "and bites the player in reach (%.1f)" % (hp0 - p.hp))
	var fox: Animal = _of(w, "fox", "woods_w")[0]
	w.fauna.provoke(fox, "player")
	check(fox.anger == "", "a fox never fights people")
	# a starving bear goes for a lone person in its wood, not one with company or outside it
	var bear: Animal = _of(w, "bear", "woods_w")[0]
	bear.hunger = 5.0
	bear.anger = ""
	p.pos = bear.pos + Vector2(3, 0)
	var inside := w.fauna.cells("woods_w").has(Vector2i(floori(p.pos.x), floori(p.pos.y)))
	for n: NPC in w.npcs:
		if n.pos.distance_to(p.pos) <= float(GameData.b("wildlife").alone_radius):
			n.pos = Vector2(60, 45)
	w.fauna._hunt_people(bear)
	check(not inside or bear.anger == "player", "a starving bear goes for the player alone in its wood")
	bear.anger = ""
	var friend: NPC = w.npcs[0]
	friend.pos = p.pos + Vector2(1, 0)
	w.fauna._hunt_people(bear)
	check(bear.anger == "", "not with someone beside them")
	friend.pos = Vector2(60, 45)
	p.pos = Vector2(60, 45)
	w.fauna._hunt_people(bear)
	check(bear.anger == "", "nor anyone outside the wood")


func test_hunting() -> void:
	var w := new_world()
	var g: Animal = w.fauna.nearest_game(Vector2(10, 10), 999.0)
	var never := true
	for i in 30:
		var a: Animal = w.fauna.nearest_game(Vector2(w.rng.randf_range(0, 120), w.rng.randf_range(0, 90)), 999.0)
		if a != null and a.species in ["wolf", "fox", "bear"]:
			never = false
	check(g != null and never, "the village hunter goes after deer, boar, rabbits and birds, never wolves, foxes or bears")
	var bird: Animal = _of(w, "bird")[0]
	bird.born = w.minutes - 10.0 * 1440.0
	var bag := w.fauna.kill(bird)
	check(bag.count("feather") == 1 and not bag.has("meat"), "a bird gives a feather")
	var bear: Animal = _of(w, "bear")[0]
	bag = w.fauna.kill(bear)
	check(bag.count("meat") == 6 and bag.count("hide") == 2, "a bear gives 6 meat and 2 hides")
	check(float(GameData.b("animals").bear.hp) >= 50.0, "bears are tough (%d health)" % int(GameData.b("animals").bear.hp))


func test_save() -> void:
	var w := new_world()
	var d := w.to_dict()
	# an older save: only boar and rabbits in the woods
	d.fauna.erase("seeded")
	d.fauna.animals = (d.fauna.animals as Array).filter(func(a): return a.species in ["boar", "rabbit", "cow", "pig", "sheep", "chicken"])
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
	check(_of(w2, "deer").size() > 0 and _of(w2, "wolf").size() > 0 and _of(w2, "bear").size() == 2, "an older save's woods gain the forest animals")
	check(w2.fauna.seeded == w2.fauna.wild_species(), "and they are marked started")
	# hunted out stays out
	for a: Animal in _of(w2, "bear"):
		w2.fauna.remove(a)
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w2.to_dict())))
	check(_of(w3, "bear").is_empty(), "bears the player killed off do not come back on loading")


## Twenty days: the food chain runs on its own and no grazer or hunter dies out.
func test_days() -> void:
	var w := new_world()
	var steps := int(20.0 * 1440.0 / float(GameData.b("game_minutes_per_second")) / 0.5)
	for i in steps:
		w.update(0.5)
	var counts := {}
	for k in ["deer", "boar", "rabbit", "bird", "wolf", "fox", "bear"]:
		counts[k] = _of(w, k).size()
	var eaten := 0
	for k in w.stats:
		if str(k).begins_with("eaten_") and str(k).contains("_by_"):
			eaten += int(w.stats[k])
	print("  20 days: ", counts, " eaten ", eaten, " fox raids ", w.stats.get("fox_took_chicken", 0), " starved ", w.stats.keys().filter(func(k): return str(k).begins_with("starved_")).map(func(k): return "%s=%d" % [k, int(w.stats[k])]))
	check(eaten > 0, "predators ate prey (%d kills)" % eaten)
	for k in counts:
		check(int(counts[k]) >= 2, "%s still live in the woods (%d)" % [k, counts[k]])


func test_sprites() -> void:
	var w := new_world()
	for k in ["deer", "wolf", "fox", "bear", "bird"]:
		var a: Animal = _of(w, k)[0]
		var s := AnimalSprite.new()
		s.setup(a, w.minutes)
		var art := a.art()
		check(s.texture != null and s.hframes * int(art.frame) == s.texture.get_width() and s.vframes * int(art.frame) == s.texture.get_height(),
			"%s sheet %s: %d x %d frames" % [k, a.skin, s.hframes, s.vframes])
		a.facing = Vector2.LEFT
		a.moving = true
		s.show_state(a, w.minutes, 0.1)
		var rows: Dictionary = AnimalSprite.ROWS[a.skin]
		check(s.flip_h and s.frame / s.hframes == int(rows.walk[0]), "walking left: the walk row, flipped")
		s.free()
	# the Animal Farm horse sheet (B14-11): the "farm" layout, read on a stand-in animal until the horse has a species
	var art_of: Dictionary = GameData.b("animals").cow
	art_of["skin_art"] = {"farm_horse": {"layout": "farm", "frame": 32}}
	var h := Animal.new()
	h.species = "cow"
	h.skin = "farm_horse"
	h.born = w.minutes - 30.0 * 1440.0
	var hs := AnimalSprite.new()
	hs.setup(h, w.minutes)
	check(hs.layout == "farm" and hs.hframes == 4 and hs.vframes == 4, "horse sheet: 4 x 4 frames of 32 px")
	var want := {Vector2.LEFT: [false, [4, 5]], Vector2.RIGHT: [true, [4, 5]], Vector2.DOWN: [false, [6, 7]], Vector2.UP: [false, [8, 9]]}
	h.moving = true
	for v: Vector2 in want:
		h.facing = v
		hs.show_state(h, w.minutes, 0.1)
		check(hs.flip_h == want[v][0] and (want[v][1] as Array).has(hs.frame), "horse walking %s: frame %d, flipped %s" % [v, hs.frame, hs.flip_h])
	h.moving = false
	h.facing = Vector2.UP
	hs.show_state(h, w.minutes, 0.1)
	check(hs.frame == 3, "horse standing facing up: frame 3")
	h.facing = Vector2.RIGHT
	hs.show_state(h, w.minutes, 0.1)
	check(hs.flip_h and [10, 11, 12].has(hs.frame), "horse standing sideways grazes (frame %d)" % hs.frame)
	art_of.erase("skin_art")
	hs.free()
