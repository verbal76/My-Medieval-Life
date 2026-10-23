extends SceneTree
## WORLD-LIFE-01: the countryside's ambient life (Countryside): wild animals outside the village, travellers on the trails,
## the caravan's wagon on its visit days; deterministic from the seed, culled, and touching no ledger.
## Run: godot --headless --path game --script res://tests/countryside_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   ", what)
	else:
		failures += 1
		print("FAIL ", what)


func _init() -> void:
	var m := VillageMap.load_default()
	var o := Overworld.create(1, m)
	var c := Countryside.new(o)
	test_trails(o, c)
	test_animals(o, c, m)
	test_travellers(o, c)
	test_caravan(o, c)
	test_determinism(m, c)
	test_ledgers(m)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = TEST_SAVE
	process_frame.connect(_run_scene, CONNECT_ONE_SHOT)


const TEST_SAVE := "user://test_saves/countryside_test/save1.json"
var main


## The real game scene: the view draws what Countryside returns, only near the camera, frees what leaves, and a saved game
## carries nothing of it.
func _run_scene() -> void:
	main.new_game()
	var w: World = main.world
	var gate := Vector2(w.map.overworld.gates[3].out)
	w.minutes = 792.0
	w.player.pos = gate + Vector2(-8.0, -5.0)
	main.camera.position_smoothing_enabled = false
	main.camera.position = w.player.pos * MapView.T
	main.camera.force_update_scroll()
	main._sync_countryside()
	var n0: int = main.country_sprites.size()
	var kinds := {"a": 0, "t": 0}
	for id in main.country_sprites:
		kinds[str(id)[0]] += 1
	check(kinds.a >= 1 and kinds.t >= 1, "the scene draws animals (%d) and travellers (%d) beside the player" % [kinds.a, kinds.t])
	check(n0 <= 12, "only a few are drawn at once (%d)" % n0)
	var animals: Array = main.country_sprites.values().filter(func(x): return x is AnimalSprite)
	var folk: Array = main.country_sprites.values().filter(func(x): return x is ActorSprite)
	check(animals.all(func(x: AnimalSprite): return x.texture != null and x.visible) and folk.all(func(x: ActorSprite): return x.texture != null), "with their sheets")
	# a great way off nothing is drawn, and what was drawn is freed
	w.player.pos = Vector2(4000.0, 4000.0)
	main.camera.position = w.player.pos * MapView.T
	main._sync_countryside()
	for i in 3:
		main._sync_countryside()
	check(main.country_sprites.size() <= n0, "far away only what lives there is drawn (%d)" % main.country_sprites.size())
	var d: Dictionary = w.to_dict()
	check(not JSON.stringify(d).contains("countryside"), "a save carries no countryside")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func test_trails(o: Overworld, c: Countryside) -> void:
	var tr := o.gate_trails()
	check(tr.size() == 3 * o.gates.size() and c.trail_count() == tr.size(), "three trails run to each of the %d gates (%d)" % [o.gates.size(), tr.size()])
	var ok := true
	var joined := true
	for t in tr:
		var cells: Array = t.cells
		ok = ok and cells.size() > 20 and not o.village.has_point(cells[cells.size() - 1])
		var gate: Dictionary = o.gates[int(t.gate)]
		joined = joined and cells[cells.size() - 1] == gate.out
		for i in cells.size() - 1:
			if absi(cells[i].x - cells[i + 1].x) + absi(cells[i].y - cells[i + 1].y) != 1:
				joined = false
				break
	check(ok, "each trail is a long run of cells outside the village")
	check(joined, "each trail is unbroken and ends on its gate's outside cell")


func test_animals(o: Overworld, c: Countryside, m: VillageMap) -> void:
	var found := 0
	var species := {}
	var bad := 0
	for cy in range(-4, 6):
		for cx in range(-4, 6):
			for e: Dictionary in c.chunk_animals(Vector2i(cx, cy)):
				found += 1
				species[e.species] = true
				var cell: Vector2i = e.home
				if o.village.has_point(cell) or o.is_solid(cell):
					bad += 1
				for h in range(0, 1440, 37):
					var st := c.animal_state(e, float(h))
					var p: Vector2 = st.pos
					if o.village.has_point(Vector2i(floori(p.x), floori(p.y))) or o.is_solid(Vector2i(floori(p.x), floori(p.y))):
						bad += 1
	check(found >= 20, "wild animals roam the countryside outside the village (%d in 100 chunks)" % found)
	check(species.size() >= 3, "of several species (%s)" % ", ".join(species.keys()))
	check(not species.has("wolf") and not species.has("bear"), "no wolf or bear (nothing in the countryside bites yet)")
	check(bad == 0, "no animal stands in the village or in a tree, rock or cliff (%d bad)" % bad)
	# near the village gate the player sees some, with sprites' data in place
	var seen := c.animals_near(Vector2(-20, 45), 60.0, 600.0)
	check(not seen.is_empty(), "animals are found within 60 tiles of the west gate (%d)" % seen.size())
	check(seen.all(func(a: Animal): return a.wild() and a.skin != "" and a.adult(600.0)), "each is an ordinary wild Animal with its sheet, grown")
	var moving := false
	for h in range(0, 600, 3):
		for a: Animal in c.animals_near(Vector2(-20, 45), 60.0, float(h)):
			moving = moving or a.moving
	check(moving, "they walk about, and rest")
	var far := c.animals_near(Vector2(-20, 45), 8.0, 600.0)
	check(far.size() <= seen.size(), "a smaller radius shows no more")


func test_travellers(o: Overworld, c: Countryside) -> void:
	var peak := 0
	var kinds := {}
	var total := 0
	var seen_near_gate := false
	var left := true                   # nobody beyond the culling radius is returned
	var gate: Vector2 = Vector2(o.gates[0].out)
	for day in 3:
		for h in range(0, 1440, 5):
			var now := float(day * 1440 + h)
			var list := c.travellers_near(gate, 40.0, now)
			peak = maxi(peak, list.size())
			total += list.size()
			for e in list:
				kinds[e.kind] = true
				seen_near_gate = seen_near_gate or (e.pos as Vector2).distance_to(gate) < 6.0
				left = left and (e.pos as Vector2).distance_to(gate) <= 40.0
	check(total > 0 and kinds.has("pedlar") and kinds.has("pilgrim"), "pedlars and pilgrims walk the trails (%s, over 3 days)" % ", ".join(kinds.keys()))
	check(seen_near_gate, "some reach the village gate")
	check(peak <= 6, "few at a time near a gate (peak %d)" % peak)
	check(left, "only those within the radius are returned")
	# a journey: in from the road node, to the gate, and out of the world again
	var trail := 0
	var started := -1.0
	for s in 200:
		var t0 := float(s) * 120.0
		var mid := c.travellers_near(Vector2.ZERO, 100000.0, t0 + 60.0)
		if not mid.is_empty():
			started = t0
			break
	check(started >= 0.0, "a traveller is out on the trails at some time")
	var night := c.travellers_near(Vector2.ZERO, 100000.0, 2.0 * 1440.0 + 22.0 * 60.0)
	var dawn_n := c.travellers_near(Vector2.ZERO, 100000.0, 2.0 * 1440.0 + 3.0 * 60.0)
	check(night.size() <= 3 and dawn_n.size() <= 3, "the trails are quiet in the small hours (%d, %d)" % [dawn_n.size(), night.size()])
	# the whole life of one: enters at the far end, ends gone
	var first := {}
	var last_pos := Vector2.ZERO
	var key := -1
	var moved := 0.0
	for h in range(1440 + 360, 3 * 1440, 2):          # from 6 in the morning: yesterday's last journeys are over
		for e in c.travellers_near(Vector2.ZERO, 100000.0, float(h)):
			if e.kind == "wagon" or e.kind == "driver":
				continue
			if key == -1:
				key = e.key
				first = e
			if e.key == key:
				moved += (e.pos as Vector2).distance_to(last_pos) if last_pos != Vector2.ZERO else 0.0
				last_pos = e.pos
		if key != -1 and c.travellers_near(Vector2.ZERO, 100000.0, float(h)).filter(func(e): return e.key == key).is_empty() and moved > 0.0:
			break
	var d_node := (first.pos as Vector2).distance_to(Vector2(o.village.get_center()))
	check(key != -1 and d_node > 60.0, "a traveller first appears far out on a trail (%.0f tiles from the village centre)" % d_node)
	check(moved > 60.0, "and walks a long way before leaving (%.0f tiles)" % moved)
	check(last_pos.distance_to(Vector2(o.village.get_center())) > 60.0, "and is gone from the far end of the trail, not at the gate")


func test_caravan(o: Overworld, c: Countryside) -> void:
	var every := int(GameData.b("caravan_every_days"))
	var ch: Dictionary = GameData.b("farming").caravan_horse
	var day := every * 3 + 1
	var wagon_times := []
	for h in range(0, 1440, 5):
		var now := float(day * 1440 + h)
		if not c.travellers_near(Vector2.ZERO, 100000.0, now).filter(func(e): return e.kind == "wagon").is_empty():
			wagon_times.append(float(h) / 60.0)
	check(not wagon_times.is_empty(), "the caravan's wagon travels a trail on its visit day")
	check(wagon_times.max() >= float(ch.from_hour) + float(ch.hours) - 0.5 or wagon_times.min() < float(ch.from_hour), "before the visit and after it, not during it (%s .. %s h)" % [wagon_times.min(), wagon_times.max()])
	var during := c.travellers_near(Vector2.ZERO, 100000.0, float(day * 1440) + (float(ch.from_hour) + 1.0) * 60.0).filter(func(e): return e.kind == "wagon")
	check(during.is_empty(), "while the caravan is in the village its wagon is not on the trail")
	var off := c.travellers_near(Vector2.ZERO, 100000.0, float((day + 1) * 1440 + 12 * 60 - 120)).filter(func(e): return e.kind == "wagon")
	check(off.is_empty(), "no wagon on the days it does not visit")
	var drivers := c.travellers_near(Vector2.ZERO, 100000.0, float(day * 1440) + float(wagon_times[0]) * 60.0).filter(func(e): return e.kind == "driver")
	check(drivers.size() == 1, "a driver walks ahead of the wagon")


func _snap(c: Countryside, centre: Vector2, now: float) -> Array:
	var out := []
	for a: Animal in c.animals_near(centre, 60.0, now):
		out.append([a.id, a.species, a.skin, snappedf(a.pos.x, 0.001), snappedf(a.pos.y, 0.001), a.moving])
	for e in c.travellers_near(centre, 60.0, now):
		out.append([e.key, e.kind, snappedf((e.pos as Vector2).x, 0.001), snappedf((e.pos as Vector2).y, 0.001)])
	return out


func test_determinism(m: VillageMap, c: Countryside) -> void:
	var c2 := Countryside.new(Overworld.create(1, m))
	var same := true
	var any := false
	for h in range(0, 4 * 1440, 97):
		var a := _snap(c, Vector2(-20, 45), float(h))
		any = any or not a.is_empty()
		same = same and a == _snap(c2, Vector2(-20, 45), float(h))
	check(any and same, "a second countryside of the same seed gives the same animals and walkers at every minute")
	# time order does not matter (pure in the clock): ask backwards
	var c3 := Countryside.new(Overworld.create(1, m))
	var back := true
	for h in range(4 * 1440, 0, -211):
		back = back and _snap(c, Vector2(-20, 45), float(h)) == _snap(c3, Vector2(-20, 45), float(h))
	check(back, "asking in any order gives the same answers")
	var other := Countryside.new(Overworld.create(2, m))
	check(_snap(c, Vector2(-20, 45), 700.0) != _snap(other, Vector2(-20, 45), 700.0), "another seed has another countryside")


func test_ledgers(m: VillageMap) -> void:
	var w := World.new()
	w.setup(m, 1)
	var c := Countryside.new(w.map.overworld)
	var animals0 := w.fauna.animals.size()
	var ids0 := w.fauna.next_id
	var coins0 := w.coin_sources
	var npcs0 := w.npcs.size()
	var inv0 := w.player.inv.to_dict() if w.player.inv.has_method("to_dict") else {}
	var pos0 := w.player.pos
	var rng0 := w.rng.state
	for h in range(0, 2 * 1440, 13):
		c.animals_near(Vector2(-20, 45), 30.0, float(h))
		c.travellers_near(Vector2(-20, 45), 30.0, float(h))
	check(w.fauna.animals.size() == animals0 and w.fauna.next_id == ids0, "the village's animal ledger is untouched")
	check(w.coin_sources == coins0 and w.npcs.size() == npcs0 and w.player.pos == pos0, "no coins made, nobody added to the population")
	check(w.player.inv.to_dict() == inv0 if w.player.inv.has_method("to_dict") else true, "no item made")
	check(w.rng.state == rng0, "the world's random stream is not drawn from")
	check(not w.to_dict().has("countryside"), "nothing of it is saved (it is a function of the seed and the clock)")
