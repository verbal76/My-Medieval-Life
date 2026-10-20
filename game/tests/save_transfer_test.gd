extends SceneTree
## SAVE-00..09 (owner 2026-10-20): carrying a save between installs and builds. Copying out and reading
## back; importing with a byte-for-byte backup of the original, migration and validation before an atomic
## swap; the save it replaces kept; refusals that change nothing (damaged, newer, too old, a failed
## migration or validation); unknown sections kept; every kind of persistent world data intact. Run:
##   godot --headless --path game --script res://tests/save_transfer_test.gd

var failures := 0
var checks := 0
const DIR := "user://test_saves/save_transfer/"


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _init() -> void:
	GameData.ensure()
	_wipe(DIR)
	_wipe(SaveTransfer.BACKUP_DIR)
	test_export()
	test_import_round_trip()
	test_import_keeps_existing_save()
	test_refusals()
	test_unknown_sections()
	_wipe(DIR)
	_wipe(SaveTransfer.BACKUP_DIR)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _wipe(dir: String) -> void:
	var abs := ProjectSettings.globalize_path(dir)
	if not DirAccess.dir_exists_absolute(abs):
		return
	for f in DirAccess.get_files_at(abs):
		DirAccess.remove_absolute(abs.path_join(f))
	for sub in DirAccess.get_directories_at(abs):
		_wipe(dir.path_join(sub))
		DirAccess.remove_absolute(abs.path_join(sub))


## Numbers compared by value: a whole number may be written 1780 by one save and 1780.0 by the next.
func _norm(v):
	if v is float and v == floorf(v) and absf(v) < 1e15:
		return int(v)
	if v is Array:
		return v.map(func(x): return _norm(x))
	if v is Dictionary:
		var o := {}
		for k in v:
			o[k] = _norm(v[k])
		return o
	return v


func _raw(path: String) -> String:
	return FileAccess.get_file_as_string(path)


## A world played for a few hours, with a friendship, a gift, a felled tree and a pen, saved as a game
## would (meta with its identity) at `path`.
func _game_save(path: String, seed: int, id: String) -> Dictionary:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	for i in 2400:                                  # ten game hours in half-second steps
		w.update(0.5)
	var n: NPC = w.npcs.filter(func(o: NPC) -> bool: return o.alive and o.role == "adult")[0]
	w.player.inv.add("flower", 2)
	w.relations.give(Life.PLAYER_ID, n, "flower")
	w.relations.befriend(Life.PLAYER_ID, n.id)
	w.player.coins += 77
	var d := w.to_dict()
	d["meta"] = {"save_id": id, "created": 1000, "saved_at": 2000, "builds": ["0.1.14-test"], "character": w.player.name}
	w.dispose()
	SaveStore.write_text(path, JSON.stringify(d, "", true, true))
	return JSON.parse_string(_raw(path))


func test_export() -> void:
	var save := DIR + "game/save1.json"
	_game_save(save, 3, "world-A")
	var out := DIR + "outside/copy.json"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
	var r := SaveTransfer.export_save(save, out)
	check(r.ok and _raw(out) == _raw(save), "a copy of the save is written to the chosen file and reads back the same")
	check(SaveTransfer.export_save(DIR + "nothing/save1.json", out + "2").ok == false, "with no save there is nothing to copy")
	check(SaveTransfer.suggested_name(JSON.parse_string(_raw(save))).begins_with("MyMedievalLife-"), "the suggested file name names the game")


## Requirement 12: every kind of persistent world data comes through an import intact.
func test_import_round_trip() -> void:
	var source := DIR + "outside/copy.json"
	var src: Dictionary = JSON.parse_string(_raw(source))
	var local := DIR + "newinstall/save1.json"
	var r := SaveTransfer.import_save(source, local, VillageMap.load_default())
	check(r.ok, "a copied save imports into a fresh install (%s)" % r.get("reason", ""))
	var got: Dictionary = JSON.parse_string(_raw(local))
	check(str(got.meta.save_id) == "world-A" and got.meta.builds == ["0.1.14-test"], "its world identity and build history carry over")
	var same := []
	var differ := []
	for t in src.trees:                          # a stump's birth time reads as its regrow time until a load writes it down (Trees.born_of)
		if not t.has("born"):
			t.born = Trees.born_of(t)
	for k in ["seed", "minutes", "npcs", "households", "relations", "buildings", "plots", "trees", "plants", "deposits", "boulders",
			"fields", "fauna", "farm", "overworld", "player", "treasury", "granary", "construction", "manor_work", "chests", "carts", "containers", "stalls"]:
		if JSON.stringify(_norm(got.get(k)), "", true, true) == JSON.stringify(_norm(src.get(k)), "", true, true):
			same.append(k)
		else:
			differ.append(k)
			print("  differs: ", k)
	check(differ.is_empty(), "terrain, resources, people, households, relationships, buildings, inventories, animals and the economy all come through with the same values (differ: %s)" % [differ])
	check(_raw(source) == _raw(DIR + "outside/copy.json"), "the file imported from is never changed")
	var backup: String = r.backup
	check(FileAccess.file_exists(backup) and _raw(backup) == _raw(source), "the original was first copied byte for byte into the save backups (%s)" % backup.get_file())
	check(SaveStore.inspect(local, World.SAVE_VERSION).state == "ok", "the imported save loads")
	check(r.from_version == World.SAVE_VERSION and str(r.info).contains("day"), "the result says whose world and how far in (%s)" % r.info)


func test_import_keeps_existing_save() -> void:
	var local := DIR + "phone/save1.json"
	_game_save(local, 5, "world-B")
	var before := _raw(local)
	var r := SaveTransfer.import_save(DIR + "outside/copy.json", local, VillageMap.load_default())
	check(r.ok and JSON.parse_string(_raw(local)).meta.save_id == "world-A", "importing replaces the game's save with the imported world")
	check(r.replaced != "" and _raw(r.replaced) == before, "the save it replaced was kept in the save backups first, unchanged")
	check(FileAccess.file_exists(local + SaveStore.BAK), "and the atomic swap keeps the usual backup as well")


func test_refusals() -> void:
	var local := DIR + "keep/save1.json"
	_game_save(local, 4, "world-C")
	var before := _raw(local)
	var bad := DIR + "outside/bad.json"
	var put := func(path: String, text: String) -> void:
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(text)
		f.close()
	put.call(bad, "{\"save_version\": 14, \"seed\": 1, \"minutes\"")
	var r := SaveTransfer.import_save(bad, local, VillageMap.load_default())
	check(not r.ok and r.reason.contains("damaged") and _raw(local) == before, "a damaged file is refused and nothing changes (%s)" % r.reason)
	var src: Dictionary = JSON.parse_string(_raw(DIR + "outside/copy.json"))
	src.save_version = World.SAVE_VERSION + 1
	put.call(bad, JSON.stringify(src))
	r = SaveTransfer.import_save(bad, local, VillageMap.load_default())
	check(not r.ok and r.reason.contains("newer") and _raw(local) == before, "a save from a newer build is refused and nothing changes")
	src.save_version = SaveStore.MIN_VERSION - 1
	put.call(bad, JSON.stringify(src))
	r = SaveTransfer.import_save(bad, local, VillageMap.load_default())
	check(not r.ok and r.reason.contains("older") and _raw(local) == before, "a save from before the village was rebuilt is refused, not claimed to load")
	for step in ["migrate", "validate"]:
		SaveTransfer.fail_at = step
		r = SaveTransfer.import_save(DIR + "outside/copy.json", local, VillageMap.load_default())
		SaveTransfer.fail_at = ""
		check(not r.ok and _raw(local) == before, "a failed %s leaves the game's save untouched (%s)" % [step, r.reason])
	SaveStore.fail_at = "replace"
	r = SaveTransfer.import_save(DIR + "outside/copy.json", local, VillageMap.load_default())
	SaveStore.fail_at = ""
	check(not r.ok and _raw(local) == before, "an interrupted swap leaves the previous save whole: no half-converted save")
	var m := SaveTransfer.migrate(JSON.parse_string(_raw(DIR + "outside/copy.json")), VillageMap.load_default())
	var tampered: Dictionary = m.data.duplicate(true)
	(tampered.npcs as Array).pop_back()
	check(SaveTransfer.validate(JSON.parse_string(_raw(DIR + "outside/copy.json")), tampered, VillageMap.load_default()).contains("npcs"), "validation catches a migration that loses a person")


func test_unknown_sections() -> void:
	var src: Dictionary = JSON.parse_string(_raw(DIR + "outside/copy.json"))
	src["future_section"] = {"from": "a later build", "n": 3}
	var m := SaveTransfer.migrate(src, VillageMap.load_default())
	check(m.ok and m.data.get("future_section", {}) == {"from": "a later build", "n": 3}, "a section this build does not know is carried through an import unchanged")
