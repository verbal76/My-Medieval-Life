extends SceneTree
## SIM-GATE-01 amendment: the desktop game's live recording export (scripts/recorder_export/live_export.gd). A world records a
## day with the flight recorder; the export writes the workbook (every sheet of data/sim_workbook.json), the analysis JSON and
## the archive zip; the workbook opens as a zip with its sheets and charts; the world goes on with its recorder (an export
## changes nothing in it). Run headless:
##   godot --headless --path game --script res://tests/live_export_test.gd

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
	var tmp := OS.get_cache_dir() + "/mml_live_export_%d" % int(Time.get_unix_time_from_system())
	DirAccess.make_dir_recursive_absolute(tmp)
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var rec := WorldRecorder.attach(w, {"root": tmp + "/rec"})
	for i in 26 * 60:
		w.update(0.5)
		w.player.hunger = 100.0
	var ex = load("res://scripts/recorder_export/live_export.gd")
	var r: Dictionary = ex.export_world(w, tmp + "/out")
	check(r.ok and r.files.size() == 3, "the export wrote the workbook, the analysis and the archive (%s)" % str(r))
	for f in r.get("files", []):
		check(FileAccess.file_exists(f) and FileAccess.get_file_as_bytes(f).size() > 100, "written: " + str(f).get_file())
	var z := ZIPReader.new()
	check(z.open(r.files[0]) == OK, "the workbook opens as a zip")
	var names := Array(z.get_files())
	var wb := z.read_file("xl/workbook.xml").get_string_from_utf8()
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sim_workbook.json"))
	var missing := (defs.required_sheets as Array).filter(func(s): return not wb.contains('name="%s"' % str(s).xml_escape()))
	check(missing.is_empty(), "every required sheet is in the workbook (missing: %s)" % str(missing))
	check(names.filter(func(n): return n.begins_with("xl/charts/chart")).size() >= 8, "the workbook carries its charts (%d)" % names.filter(func(n): return n.begins_with("xl/charts/chart")).size())
	var ev := z.read_file("xl/worksheets/sheet%d.xml" % 13).get_string_from_utf8()
	check(ev.count("<row ") > 10, "the Events sheet holds event records (%d rows)" % ev.count("<row "))
	z.close()
	check(w.recorder == rec and rec.recording(), "the recorder goes on recording after an export")
	var a = JSON.parse_string(FileAccess.get_file_as_string(r.files[1]))
	check(a is Dictionary and (a.hourly as Array).size() >= 25 and int(a.hourly[-1].alive) == w.npcs.filter(func(n): return n.alive and n.role != "bandit").size(),
		"the analysis holds the hourly snapshots; the last one's villagers alive match the world now")
	w.dispose()
	_remove(tmp)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _remove(path: String) -> void:
	for d in DirAccess.get_directories_at(path):
		_remove(path + "/" + d)
	for f in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path + "/" + f)
	DirAccess.remove_absolute(path)
