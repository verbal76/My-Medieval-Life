extends SceneTree
## FARM-YIELD-D1 Phase 2 (agent decision, docs/DECISIONS.md 2026-11-02): a save made before the shared, seasonal field model
## (shared_manor_farming 0: no "shared_farming_start" key, its fields sown without seed) moves to the model once on load, as a
## new world starts (World.start_shared_farming): each manor field's farmers get its seed corn (a field's worth, as Population
## gives at world setup), a field growing under the old model counts as sown whole and keeps the share of its growth already
## done; it is recorded in the save and never repeated. Off, nothing changes; a guest's copy of a host's world is not moved.
## Uses the real Build 24 save (tests/fixtures/b24_save_v23_single.json, save version 23).
## Run headless:  godot --headless --path game --script res://tests/farm_shared_save_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func fixture() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/b24_save_v23_single.json"))


func loaded(d: Dictionary) -> World:
	var w := World.new()
	w.load_dict(VillageMap.load_default(), d.duplicate(true))
	return w


func seed_by_npc(w: World) -> Dictionary:
	var out := {}
	for n: NPC in w.npcs:
		out[n.id] = n.inv.count("wheat_seed")
	return out


func _init() -> void:
	GameData.ensure()                              # (the balance is read lazily: load it before keeping its values)
	var keep := [GameData.balance.get("shared_manor_farming", 0), GameData.balance.get("seasonal_village_farming", 0)]
	check(Farming.shared_manor() and Farming.seasonal_fields() and is_equal_approx(Farming.wheat_yield(), 1.75),
			"the game's settings: shared and seasonal manor fields, wheat %.2f a cell" % Farming.wheat_yield())
	var fx := fixture()
	var old_shape := not fx.has("shared_farming_start")
	for f in fx.fields:
		old_shape = old_shape and not (f as Dictionary).has("sown") and not (f as Dictionary).has("progress")
	check(int(fx.save_version) == 23 and old_shape, "the Build 24 fixture is an old-model save: no shared_farming_start, no field sown by the cell")
	# one field growing under the old model, half way to ripe (the shape the old model saves: a ready time, no sown, no progress)
	var span := Life.seasons_to_days(float(GameData.b("field_grow_seasons"))) * World.DAY
	var g: Dictionary = fx.fields[1]
	g.state = "growing"
	g.ready = float(fx.minutes) + span * 0.5
	g.erase("crop")

	# the baseline: the same save loaded with the old model, nothing moved
	GameData.balance["shared_manor_farming"] = 0
	GameData.balance["seasonal_village_farming"] = 0
	var off := loaded(fx)
	var before := seed_by_npc(off)
	var off_out := off.to_dict()
	check(not off.shared_farming_start and not off_out.has("shared_farming_start") and float(off.stats.get("shared_farming_seed_corn", 0.0)) == 0.0,
			"old model: the save loads as before, no seed corn given, no key written")
	check(not (off.fields[1] as Dictionary).has("sown") and float(off.fields[1].ready) == float(g.ready), "old model: the growing field is left as saved")
	GameData.balance["shared_manor_farming"] = keep[0]
	GameData.balance["seasonal_village_farming"] = keep[1]

	# the game's settings: moved once
	var w := loaded(fx)
	var after := seed_by_npc(w)
	var cells := 0
	var fields_ok := true
	var split_ok := true
	for f: Dictionary in w.fields:
		var c := Farming.field_cells(f)
		cells += c
		var ws: Array = w.field_workers(f)
		var got := 0
		for n: NPC in ws:
			got += int(after[n.id]) - int(before[n.id])
		fields_ok = fields_ok and got == c and not ws.is_empty()
		for n: NPC in ws:
			split_ok = split_ok and absi((int(after[n.id]) - int(before[n.id])) - c / ws.size()) <= 1
	var others_same := true
	var workers := {}
	for f: Dictionary in w.fields:
		for n: NPC in w.field_workers(f):
			workers[n.id] = true
	for id in after:
		if not workers.has(id):
			others_same = others_same and int(after[id]) == int(before[id])
	check(fields_ok and split_ok, "each manor field's farmers are given its seed corn, a field's worth (%d cells), split evenly among them" % cells)
	check(others_same, "nobody else is given seed")
	check(w.shared_farming_start and float(w.stats.get("shared_farming_seed_corn", 0.0)) == float(cells),
			"recorded: the world is marked and the stat counts the %d seed given" % cells)
	var noted := false
	for l in w.log_lines:
		noted = noted or str(l).contains("seed corn")
	check(noted, "and the log says so (not a silent change)")
	var ok_seed := true
	for f: Dictionary in w.fields:
		ok_seed = ok_seed and w.farm.field_seed(f) >= Farming.field_cells(f)
	check(ok_seed, "every manor field now has seed enough to be sown whole")
	var gf: Dictionary = w.fields[1]
	check(int(gf.sown) == Farming.field_cells(gf) and absf(float(gf.progress) - 0.5) < 0.01 and float(gf.ready) > 1.0e17,
			"the field growing under the old model counts as sown whole (%d cells) and keeps its growth (%.2f)" % [int(gf.sown), float(gf.progress)])
	var ripe: Dictionary = w.fields[0]
	check(str(ripe.state) == "ripe" and int(ripe.crop) == int(fx.fields[0].crop), "a ripe field keeps the crop it was saved with (%d)" % int(ripe.crop))

	# saved and loaded again: never repeated
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	check(d.get("shared_farming_start", false) == true, "the save records that the seed corn was given")
	var w2 := loaded(d)
	check(JSON.stringify(seed_by_npc(w2)) == JSON.stringify(after) and float(w2.stats.get("shared_farming_seed_corn", 0.0)) == 0.0 and w2.shared_farming_start,
			"loaded again, nobody is given seed a second time")
	check(int(w2.fields[1].sown) == int(gf.sown) and is_equal_approx(float(w2.fields[1].progress), float(gf.progress)), "and the growing field is as it was saved")

	# a guest's copy of a host's world is the host's to move
	var gd := fx.duplicate(true)
	gd.net_pid = 2
	var guest := loaded(gd)
	check(not guest.shared_farming_start and JSON.stringify(seed_by_npc(guest)) == JSON.stringify(before), "a guest's copy of a host's world is not moved on its own")

	# a new world starts with the seed corn and the mark: a load never gives it again
	var nw := World.new()
	nw.setup(VillageMap.load_default(), 3)
	var nd: Dictionary = JSON.parse_string(JSON.stringify(nw.to_dict()))
	var n_before := seed_by_npc(nw)
	var nw2 := loaded(nd)
	check(nw.shared_farming_start and nd.get("shared_farming_start", false) == true and JSON.stringify(seed_by_npc(nw2)) == JSON.stringify(n_before),
			"a new world is marked at setup, and loading its save gives nothing more")

	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
