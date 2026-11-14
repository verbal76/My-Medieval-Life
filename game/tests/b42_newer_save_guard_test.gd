extends SceneTree
## B42 newer-version save protection (owner directive 2026-11-14, to Agent Q: "A newer-version save must never be overwritten,
## modified, truncated, deleted or silently replaced"; every write path stays blocked from it; CLAUDE.md section 7). A save file
## written by a later version of the game than this build reads is put in each place the game's saving touches (the slot, its
## backup, its dated backups, the previous game, the linked copy outside the game), its bytes are hashed, and the game then loads,
## autosaves (on the background thread), saves by hand, shuts down and starts again. After it all, each of those files must still
## exist on disk byte for byte (in its place, or moved aside under a kept name, which the player is told), and no other file may
## have been made from it and then lost.
##   godot --headless --path game -s res://tests/b42_newer_save_guard_test.gd [-- slot|demo|previous|dated|bak|race|copy]

const DIR := "user://test_saves/b42_newer_guard/"
const BASE := DIR + "save1.json"

var main
var checks := 0
var failures := 0


func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("ok   " if ok else "FAIL ") + what)


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var parts := ["slot", "demo", "previous", "dated", "bak", "race", "copy"]
	if not args.is_empty():
		parts = args
	for p in parts:
		print("-- %s" % p)
		await call("_part_" + p)
	Demo.force = -1
	SaveStore.today = ""
	_stop_main()
	_clear()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ------------------------------------------------------------------ helpers
func _start_main() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = BASE
	await process_frame


func _stop_main() -> void:
	if main != null:
		main.queue_free()                     # _exit_tree: a background save still being written lands first
		main = null


## The shutdown of a running game: the window's close (it saves), then the scene goes.
func _shutdown() -> void:
	main._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	_stop_main()
	await process_frame


func _clear() -> void:
	for d in [DIR, DIR + "demo/", DIR + "outside/"]:
		if DirAccess.dir_exists_absolute(d):
			for f in DirAccess.get_files_at(d):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(d.path_join(f)))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR + "demo/"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR + "outside/"))


## A save from a newer version, each one distinct (`tag`), with real content so a truncation would show.
func _newer(tag: String) -> String:
	var v := World.SAVE_VERSION + 1
	return JSON.stringify({"save_version": v, "format": "mml-save/%d" % v, "tag": tag, "meta": {"save_id": "newer-" + tag},
		"payload": "x".repeat(4096)}, "  ")


func _put(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


## Every file under the test folders whose bytes are exactly `text` (sha-256 compared, then the bytes).
func _holders(text: String) -> Array:
	var want := text.sha256_text()
	var out := []
	for d in [DIR, DIR + "demo/", DIR + "outside/", SaveTransfer.BACKUP_DIR]:
		if not DirAccess.dir_exists_absolute(d):
			continue
		for f in DirAccess.get_files_at(d):
			var p: String = d.path_join(f)
			if FileAccess.get_sha256(p) == want and FileAccess.get_file_as_string(p) == text:
				out.append(p)
	return out


## The protection: `text` (hashed before) is still on disk, byte for byte.
func _kept(text: String, what: String) -> Array:
	var h := _holders(text)
	check(not h.is_empty(), "%s: still on disk byte for byte (sha256 %s..., %s)" % [what, text.sha256_text().substr(0, 12), h])
	return h


func _cycle(label: String) -> void:
	main.autosave_hour = -5
	main._process(0.01)                      # the hourly autosave, on the background thread
	check(main.get("_save_thread") != null or main.save_blocked != "", "%s: an autosave was begun" % label)
	main.finish_background_save()
	main.save_game(false)                    # a manual save, twice (the second turns the first's backup over)
	main.world.minutes += 61.0
	main.save_game(false)


# ------------------------------------------------------------------ the slot (full game and demo): load, autosave, save, shutdown, restart
func _slot_part(demo: bool) -> void:
	Demo.force = 1 if demo else 0
	_clear()
	await _start_main()
	var slot: String = main.save_path
	var text := _newer("slot")
	_put(slot, text)
	var sha := FileAccess.get_sha256(slot)
	main.continue_game()
	var h := _kept(text, "after the load")
	check(h.size() == 1 and h[0] != slot and str(h[0]).get_file().contains(".newer-") and main.ui.toast.text.contains(str(h[0]).get_file()),
			"the newer save is moved aside unchanged and the player is told where (%s)" % main.ui.toast.text)
	var kept: String = h[0] if not h.is_empty() else ""
	check(main.running and main.world != null, "a new game was started beside it")
	_cycle("after the load")
	await _shutdown()
	await _start_main()
	main.continue_game()                     # the restart: the new game in the slot is continued
	_cycle("after the restart")
	await _shutdown()
	check(FileAccess.file_exists(kept) and FileAccess.get_sha256(kept) == sha, "%s: the kept file after load, autosave, saves, shutdown and restart: the same sha256" % ("demo" if demo else "full game"))
	check(_holders(text).size() == 1, "and it is the only copy, never renamed again")


func _part_slot() -> void:
	await _slot_part(false)


func _part_demo() -> void:
	await _slot_part(true)


# ------------------------------------------------------------------ the previous game (save1.previous.json), on New game
func _part_previous() -> void:
	Demo.force = 0
	_clear()
	await _start_main()
	main.new_game()
	main.save_game(false)                    # a world of this version in the slot
	var prev: String = BASE.get_basename() + main.PREVIOUS_SUFFIX
	var text := _newer("previous")
	_put(prev, text)
	for n in ["Ada", "Bea"]:                  # New game twice: each keeps the game before it as the previous game
		main.new_game({"name": n, "family": "Test", "sex": "female", "appearance": {}})
		main.resume_after_origin()
		_cycle("New game " + n)
	await _shutdown()
	_kept(text, "a newer previous game after two New games")


# ------------------------------------------------------------------ dated backups (DVW-A2): a newer build's are never pruned
func _part_dated() -> void:
	Demo.force = 0
	_clear()
	var texts := []
	for day in ["2026-11-01", "2026-11-02", "2026-11-03"]:
		var t := _newer("dated-" + day)
		_put("%s%s%s.json" % [BASE.get_basename(), SaveStore.DATED, day], t)
		texts.append(t)
	var slot_text := _newer("slot-with-dated")
	_put(BASE, slot_text)
	await _start_main()
	SaveStore.today = "2026-11-14"
	main.continue_game()
	_cycle("day 1")
	SaveStore.today = "2026-11-15"
	_cycle("day 2")
	await _shutdown()
	SaveStore.today = ""
	_kept(slot_text, "the newer save")
	for i in texts.size():
		_kept(texts[i], "the newer dated backup %d" % (i + 1))


# ------------------------------------------------------------------ a newer backup beside a readable save
func _part_bak() -> void:
	Demo.force = 0
	_clear()
	await _start_main()
	main.new_game()
	main.save_game(false)
	_stop_main()
	await process_frame
	var text := _newer("bak")
	_put(BASE + SaveStore.BAK, text)
	await _start_main()
	main.continue_game()
	check(main.running and main.world != null, "the readable save is continued")
	_cycle("with a newer backup")
	await _shutdown()
	_kept(text, "a newer backup after the saves")


# ------------------------------------------------------------------ the background autosave and a newer file put in the slot
func _part_race() -> void:
	Demo.force = 0
	_clear()
	await _start_main()
	main.new_game()
	main.save_game(false)
	var text := _newer("race")
	main.save_game(false, true)              # a background save in flight...
	_put(BASE, text)                         # ...while a newer save appears in the slot (another build, a copy restored)
	main.finish_background_save()
	main.save_game(false)
	var told: String = main.ui.toast.text
	main.save_game(false)
	await _shutdown()
	var h := _kept(text, "a newer save put in the slot during a background autosave")
	check(not h.is_empty() and told.contains("newer version") and told.contains(str(h[0]).get_file()), "the player is told where it was kept: %s" % told)
	check(h.any(func(x): return str(x).get_file().contains(".newer-")), "and it is kept as a newer version's save, not only by chance in a dated copy (%s)" % [h])


# ------------------------------------------------------------------ the linked copy outside the game (SAVE-05)
func _part_copy() -> void:
	Demo.force = 0
	_clear()
	await _start_main()
	main.new_game()
	var copy := DIR + "outside/copy.json"
	var text := _newer("copy")
	_put(copy, text)
	main.settings.save_copy = copy
	main.save_game(false)
	_cycle("with a newer linked copy")
	main.settings.save_copy = ""
	await _shutdown()
	_kept(text, "a linked copy written by a newer version")
