extends SceneTree
## FLIGHT-REC-01 (owner directive 2026-11-02): the flight recorder campaign's analysis workbook, written by the project's one XLSX
## writer (scripts/recorder_export/workbook_builder.gd build_spec) from the sheets tools/flight_analyse.py prepared from the whole
## archive (workbook_data.json). Desktop and CI only; it changes nothing in the game. Prints "WORKBOOK {json}"; exit 0 when written.
##   godot --headless --path game --script res://tests/flight_workbook.gd -- --spec workbook_data.json --out flight.xlsx

const Builder := preload("res://scripts/recorder_export/workbook_builder.gd")


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var arg := func(name: String, fallback: String) -> String:
		return args[args.find(name) + 1] if name in args and args.find(name) + 1 < args.size() else fallback
	var spec = RecorderArchive.read_json(str(arg.call("--spec", "")))
	var out := str(arg.call("--out", ""))
	if not (spec is Dictionary) or out == "":
		printerr("flight_workbook: --spec workbook_data.json --out flight.xlsx")
		quit(1)
		return
	var t0 := Time.get_ticks_msec()
	var res: Dictionary = Builder.new().build_spec(out, spec)
	res.ms = Time.get_ticks_msec() - t0
	print("WORKBOOK " + JSON.stringify(res))
	quit(0 if res.ok else 1)
