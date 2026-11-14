extends SceneTree
## B42 (B25-MOVE-STUTTER-INV): the hourly autosave made its text (JSON.stringify of a ~450 KB save) and wrote, read back and
## backed up the file on the main thread: 45-94 ms in one frame every game hour here (to_dict 9-15, stringify 19-43, write
## 7-25), up to 306 ms on the southern walk. Main.save_game(show, background = true) now takes the save on the frame (to_dict and
## a deep copy) and makes the text and the file on a background thread. This test:
##  1. the background save's file is the one a save on that frame writes (byte for byte but the wall-clock saved_at second);
##  2. it takes less of the main thread than the whole save;
##  3. a save asked while one is being written waits for it: the later save is the file and the earlier one its backup;
##  4. a background save that fails is reported as a failed save (save_failing) and leaves the last save;
##  5. in play, the hour's autosave is a background one and the file it leaves loads.
##   godot --headless --path game -s res://tests/autosave_async_test.gd

var main
var checks := 0
var failures := 0
var frames := 0
var phase := 0
var saw_thread := false


func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("ok   " if ok else "FAIL ") + what)


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://test_autosave_async/save.json"
	process_frame.connect(_begin, CONNECT_ONE_SHOT)


static func _norm(t: String) -> String:
	var re := RegEx.new()
	re.compile("\"saved_at\":\\s*\\d+")
	return re.sub(t, "\"saved_at\":0", true)


func _text(p: String) -> String:
	return FileAccess.get_file_as_string(p) if FileAccess.file_exists(p) else ""


func _begin() -> void:
	main.new_game()
	for f in ["", ".bak"]:
		if FileAccess.file_exists(main.save_path + f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path + f))
	main.paused = true                              # the world stays as it is between the saves compared
	var t0 := Time.get_ticks_usec()
	check(main.save_game(false), "a save on the frame (the reference)")
	var t1 := Time.get_ticks_usec()
	var ref := _text(main.save_path)
	check(main.save_game(false, true), "a background save is begun")
	var t2 := Time.get_ticks_usec()
	check(main.get("_save_thread") != null, "its text and file are being made on a thread")
	main.finish_background_save()
	var bg := _text(main.save_path)
	check(ref.length() > 100000 and _norm(bg) == _norm(ref), "the background save's file is the frame's save, byte for byte but saved_at (%d bytes)" % bg.length())
	check(_norm(_text(main.save_path + ".bak")) == _norm(ref), "and the save before it is kept as the backup, as before")
	var sync_ms := (t1 - t0) / 1000.0
	var bg_ms := (t2 - t1) / 1000.0
	print("     main thread: the whole save %.1f ms, a background save %.1f ms" % [sync_ms, bg_ms])
	check(bg_ms < sync_ms * 0.75, "a background save holds the main thread less than the whole save (%.1f against %.1f ms)" % [bg_ms, sync_ms])
	# 3: the order of saves
	main.save_game(false, true)
	var first: Dictionary = main.world.to_dict()
	main.world.minutes += 7.0                        # a later state
	main.save_game(false)                            # waits for the background one, then writes
	var last := _text(main.save_path)
	var lastd: Dictionary = JSON.parse_string(last)
	var bakd: Dictionary = JSON.parse_string(_text(main.save_path + ".bak"))
	check(is_equal_approx(float(lastd.minutes), float(first.minutes) + 7.0) and is_equal_approx(float(bakd.minutes), float(first.minutes)),
			"a save asked during a background save comes after it: the file is the later save, its backup the background one")
	# 4: a failure
	SaveStore.fail_at = "write"
	main.save_game(false, true)
	main.finish_background_save()
	SaveStore.fail_at = ""
	check(bool(main.save_failing) and _text(main.save_path) == last, "a background save that fails is a failed save (save_failing), and the last save is unchanged")
	main.save_game(false)
	check(not bool(main.save_failing), "the next save clears it")
	# 5: in play, the hour
	main.paused = false
	main.world.minutes = floorf(main.world.minutes / 60.0) * 60.0 + 59.9
	process_frame.connect(_frame)


func _frame() -> void:
	frames += 1
	if main.get("_save_thread") != null:
		saw_thread = true
	if frames < 120:
		return
	process_frame.disconnect(_frame)
	main.finish_background_save()
	check(saw_thread, "the hour's autosave in play is made in the background")
	var r := SaveStore.inspect(main.save_path, World.SAVE_VERSION)
	check(r.state == "ok", "the file it leaves is a good save (%s)" % r.state)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
