extends SceneTree
## B42 (B25-MOVE-STUTTER-INV): the parts of an autosave timed apart on a new game (seed 1): world.to_dict, JSON.stringify,
## SaveStore.write_text (which also reads the file back and parses the old save). Diagnostics only.
##   godot --headless --path game -s res://tests/autosave_cost_probe.gd
var main
var n := 0


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://autosave_cost_probe/save.json"
	process_frame.connect(func(): main.new_game(), CONNECT_ONE_SHOT)
	process_frame.connect(_frame)


func _frame() -> void:
	n += 1
	if n < 60:
		return
	for rep in 5:
		var t0 := Time.get_ticks_usec()
		var d: Dictionary = main.world.to_dict()
		d["meta"] = main._save_meta()
		var t1 := Time.get_ticks_usec()
		var s := JSON.stringify(d, "", true, true)
		var t2 := Time.get_ticks_usec()
		var r := SaveStore.write_text(main.save_path, s, true)
		var t3 := Time.get_ticks_usec()
		var t_save0 := Time.get_ticks_usec()
		main.save_game(false)
		var t_save1 := Time.get_ticks_usec()
		print("rep %d: %d KB; to_dict %.1f ms, stringify %.1f, write_text %.1f (ok %s); whole save_game %.1f; load %s" % [rep,
				s.length() / 1024, (t1 - t0) / 1000.0, (t2 - t1) / 1000.0, (t3 - t2) / 1000.0, str(r.ok), (t_save1 - t_save0) / 1000.0,
				FileAccess.get_file_as_string("/proc/loadavg").strip_edges()])
	quit(0)
