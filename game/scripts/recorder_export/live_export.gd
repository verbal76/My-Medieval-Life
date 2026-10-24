extends RefCounted
## SIM-GATE-01 amendment (owner, 2026-10-24): the desktop game's export of a live gameplay recording. Windows and Linux only:
## this folder is excluded from the Android export (export_presets.cfg) and main.gd offers it only where the file exists
## and the platform is a PC (Main.recording_supported). Recording itself is the flight recorder, switched on by the player
## in Settings, Saves ("Record gameplay", GameSettings.record_gameplay; off by default): bounded buffer, incremental chunk
## files under user://recorder, storage cap (recorder.json), no effect on the game.
##
## export_world(world, dest_dir) writes, into dest_dir (default: the Documents folder, "My Medieval Life/recordings"):
##   <session>_day<N>.xlsx           the analysis workbook (charts and event records), the same builder the CI gate uses
##   <session>_day<N>_analysis.json  the analysis as structured data
##   <session>_day<N>_archive.zip    the recorder's own archive of the session (gzip JSON-lines chunks and session.json)
## With no recording running it exports the newest session on disk. Returns {ok, reason, files, dir}.

const Analysis := preload("res://scripts/recorder_export/recorder_analysis.gd")
const Builder := preload("res://scripts/recorder_export/workbook_builder.gd")


static func default_dir() -> String:
	var docs := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if docs == "":
		return ProjectSettings.globalize_path("user://recordings")
	return docs.path_join("My Medieval Life").path_join("recordings")


static func newest_session(root: String) -> String:
	var abs_root := FlightRecorder._abs(root)
	var dirs := Array(DirAccess.get_directories_at(abs_root))
	dirs.sort()
	return abs_root.path_join(dirs[-1]) if not dirs.is_empty() else ""


static func export_world(world, dest_dir := "") -> Dictionary:
	var sdir := ""
	var day := -1
	if world != null and world.recorder != null:
		world.recorder.flush()                      # what is buffered goes to its chunk files first (as each hour does)
		sdir = FlightRecorder._abs(world.recorder.dir)
		day = world.day()
	else:
		sdir = newest_session(str(FlightRecorder.default_cfg().get("root", "user://recorder")))
	if sdir == "" or not DirAccess.dir_exists_absolute(sdir):
		return {"ok": false, "reason": "nothing has been recorded yet: switch on Record gameplay in Settings, Saves, and play a while"}
	var dir := dest_dir if dest_dir != "" else default_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var defs: Dictionary = Analysis.load_defs()
	var a: Dictionary = Analysis.analyse(sdir, defs)
	if day < 0 and not a.hourly.is_empty():
		day = int(a.hourly[-1].day)
	var base := dir.path_join("%s_day%d" % [sdir.get_file(), maxi(0, day)])
	var run := {"run": sdir.get_file(), "scenario": "live gameplay", "seed": a.session.get("seed"), "days": maxi(0, day), "recorded": true,
		"result": str(a.performance.completeness), "analysis": a}
	var res: Dictionary = Builder.new().build(base + ".xlsx", [run], {}, defs)
	if not res.ok:
		return {"ok": false, "reason": "the workbook could not be written: %s" % res.error}
	var f := FileAccess.open(base + "_analysis.json", FileAccess.WRITE)
	if f != null:
		var exported := a.duplicate()
		exported.erase("records")
		f.store_string(JSON.stringify(exported, " ", true))
		f.close()
	var zipped := _zip_archive(sdir, base + "_archive.zip")
	return {"ok": true, "reason": "", "dir": dir, "files": [base + ".xlsx", base + "_analysis.json"] + ([base + "_archive.zip"] if zipped else [])}


## The session's files into one zip (each chunk file as it is: already gzip).
static func _zip_archive(sdir: String, path: String) -> bool:
	var z := ZIPPacker.new()
	if z.open(path) != OK:
		return false
	var files := RecorderArchive.chunk_files(sdir)
	files.append("session.json")
	for rel in files:
		var data := FileAccess.get_file_as_bytes(sdir.path_join(rel))
		z.start_file(sdir.get_file().path_join(rel))
		z.write_file(data)
		z.close_file()
	return z.close() == OK
