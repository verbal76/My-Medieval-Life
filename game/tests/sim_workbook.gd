extends SceneTree
## SIM-GATE-01: the CI gate's workbook, made by the project's one XLSX writer (scripts/recorder_export/). tools/sim_suite.py
## runs the scenarios and the gate's checks, writes gate.json, then runs this headless; it analyses each recorded run's
## flight recorder archive (recorder_analysis.gd), writes that analysis as JSON beside the archive (the structured export)
## and builds the workbook (workbook_builder.gd). It changes nothing in the game.
##   godot --headless --path game --script res://tests/sim_workbook.gd -- --gate gate.json --out workbook.xlsx
##   godot --headless --path game --script res://tests/sim_workbook.gd -- --gate gate.json --analyse-only
## (--analyse-only writes the analyses and no workbook: the suite reads them for its measured, proposed thresholds and then
## asks for the workbook.) Exit 0 when the workbook (or the analyses) were written, 1 otherwise; prints "WORKBOOK {json}".

const Analysis := preload("res://scripts/recorder_export/recorder_analysis.gd")
const Builder := preload("res://scripts/recorder_export/workbook_builder.gd")


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var arg := func(name: String, fallback: String) -> String:
		return args[args.find(name) + 1] if name in args and args.find(name) + 1 < args.size() else fallback
	var gate = RecorderArchive.read_json(str(arg.call("--gate", "")))
	var out := str(arg.call("--out", ""))
	var analyse_only := "--analyse-only" in args
	if not (gate is Dictionary) or (out == "" and not analyse_only):
		printerr("sim_workbook: --gate gate.json --out workbook.xlsx")
		quit(1)
		return
	var defs: Dictionary = Analysis.load_defs()
	var runs := []
	var t0 := Time.get_ticks_msec()
	for r in gate.get("runs", []):
		var run: Dictionary = r.duplicate(true)
		run.analysis = null
		var sdir := str(r.get("session_dir", ""))
		if sdir != "" and DirAccess.dir_exists_absolute(sdir):
			var a: Dictionary = Analysis.analyse(sdir, defs)
			run.analysis = a
			var f := FileAccess.open(str(r.get("analysis_out", sdir + "/analysis.json")), FileAccess.WRITE)
			if f != null:
				var exported := a.duplicate()
				exported.erase("records")                  # the event records are in the archive and the workbook's Events sheet
				f.store_string(JSON.stringify(exported, " ", true))
				f.close()
		runs.append(run)
	if analyse_only:
		print("WORKBOOK " + JSON.stringify({"ok": true, "analysed": runs.filter(func(x): return x.analysis != null).size(), "ms": Time.get_ticks_msec() - t0}))
		quit(0)
		return
	var res: Dictionary = Builder.new().build(out, runs, gate, defs)
	res.ms = Time.get_ticks_msec() - t0
	print("WORKBOOK " + JSON.stringify(res))
	quit(0 if res.ok else 1)
