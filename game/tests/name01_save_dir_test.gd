extends SceneTree
## NAME-01 Workstream B (owner directive 2026-11-13, docs/directives/2026-11-13_name01_forge_my_life_master_directive.md):
## the game is Forge My Life, and so is its save folder (the user:// folder, named by config/name). A save written
## in one Godot process loads in the next; an export uses the new file name; the exported file imports and loads.
## Two phases, each its own process, so the load really comes after a fresh start:
##   godot --headless --path game --script res://tests/name01_save_dir_test.gd -- save
##   godot --headless --path game --script res://tests/name01_save_dir_test.gd -- load
## With no phase both run in this one process (the CI form); the two-process run is the restart check.

var failures := 0
var checks := 0
const DIR := "user://test_saves/name01/"
const SAVE := DIR + "save1.json"                  # written as the game writes user://save1.json (SaveStore.write_text, dated)
const EXPECT := DIR + "expected.json"             # what phase "save" wrote, for phase "load" to compare with


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _init() -> void:
	GameData.ensure()
	var args := OS.get_cmdline_user_args()
	var phase := str(args[0]) if args.size() > 0 else "both"
	var udir := OS.get_user_data_dir()
	print("user data dir: ", udir)
	check(str(ProjectSettings.get_setting("application/config/name", "")) == "Forge My Life", "the project is named Forge My Life")
	check(udir.get_file() == "Forge My Life", "the save folder is named Forge My Life (%s)" % udir)
	check(ProjectSettings.globalize_path(SAVE).begins_with(udir + "/"), "a save path resolves inside that folder")
	if phase in ["save", "both"]:
		phase_save()
	if phase in ["load", "both"]:
		phase_load()
		_wipe(DIR)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func phase_save() -> void:
	_wipe(DIR)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	var w := World.new()
	w.setup(VillageMap.load_default(), 11)
	for i in 1200:                                  # five game hours in half-second steps
		w.update(0.5)
	w.player.coins += 41
	var d := w.to_dict()
	d["meta"] = {"save_id": "name01-world", "created": 1000, "saved_at": 2000, "builds": ["name01-test"], "character": w.player.name}
	w.dispose()
	var text := JSON.stringify(d, "", true, true)
	var r := SaveStore.write_text(SAVE, text, true)
	check(r.ok, "a new save is written")
	var abs := ProjectSettings.globalize_path(SAVE)
	print("save written to: ", abs)
	check(FileAccess.file_exists(abs) and abs.begins_with(OS.get_user_data_dir()), "the new save is on disk in the Forge My Life folder")
	var f := FileAccess.open(EXPECT, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func phase_load() -> void:
	check(FileAccess.file_exists(SAVE), "the save is there after a restart")
	var r := SaveStore.inspect(SAVE, World.SAVE_VERSION)
	check(r.state == "ok", "the save reads as a good save (%s)" % r.get("reason", ""))
	if r.state != "ok":
		return
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(EXPECT))
	var map := VillageMap.load_default()
	var w := World.new()
	w.load_dict(map, r.data)
	check(w.load_error == "", "the save loads into a world")
	check(int(w.player.coins) == int(expected.player.coins) and w.player.name == str(expected.player.name), "the loaded world is the one saved (player %s, %d coins)" % [w.player.name, w.player.coins])
	check(w.npcs.size() == int((expected.get("npcs", []) as Array).size()), "every villager came back")
	w.dispose()
	# Export: the file name names Forge My Life; the copy is the save, byte for byte.
	var name := SaveTransfer.suggested_name(r.data)
	print("suggested export name: ", name)
	check(name.begins_with("ForgeMyLife-") and name.ends_with(".json") and name.contains("-day"), "the export file name follows ForgeMyLife-<name>-day<N>-<date>.json")
	check(SaveTransfer.FILE_FILTER.contains("Forge My Life save") and not SaveTransfer.FILE_FILTER.contains("Medieval"), "the file dialog calls it a Forge My Life save")
	var out := DIR + "outside/" + name
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
	var e := SaveTransfer.export_save(SAVE, out)
	check(e.ok and FileAccess.get_file_as_string(out) == FileAccess.get_file_as_string(SAVE), "the export is written and reads back the same")
	# Import into a fresh install's save, then load it.
	var local := DIR + "newinstall/save1.json"
	var i := SaveTransfer.import_save(out, local, VillageMap.load_default())     # a fresh map, as main.gd passes
	check(i.ok, "the exported file imports (%s)" % i.get("reason", ""))
	var back := SaveStore.inspect(local, World.SAVE_VERSION)
	check(back.state == "ok", "the imported save reads as a good save")
	if back.state == "ok":
		var w2 := World.new()
		w2.load_dict(VillageMap.load_default(), back.data)   # a fresh start's map
		check(w2.load_error == "" and int(w2.player.coins) == int(expected.player.coins), "the imported save loads the same world")
		w2.dispose()
	var bdir := ProjectSettings.globalize_path(SaveTransfer.BACKUP_DIR)     # only this test's own import backup is removed
	if DirAccess.dir_exists_absolute(bdir):
		for f in DirAccess.get_files_at(bdir):
			if f.begins_with("import-name01-world-"):
				DirAccess.remove_absolute(bdir.path_join(f))


func _wipe(dir: String) -> void:
	var abs := ProjectSettings.globalize_path(dir)
	if not DirAccess.dir_exists_absolute(abs):
		return
	for f in DirAccess.get_files_at(abs):
		DirAccess.remove_absolute(abs.path_join(f))
	for sub in DirAccess.get_directories_at(abs):
		_wipe(dir.path_join(sub))
		DirAccess.remove_absolute(abs.path_join(sub))
