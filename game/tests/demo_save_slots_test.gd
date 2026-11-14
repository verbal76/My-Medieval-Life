extends SceneTree
## B42-DEMO-SAVE-OVERWRITE (owner 2026-11-14, B4: "Demo overwrites full-game saves: a player-data protection defect"): the demo and
## the full game share one user folder on Windows and Linux (one config/name), and before Build 42 one save slot, so the demo's New
## game put the full game's world aside without a word (a second New game removed it). Now the demo keeps its worlds in its own slot
## (Demo.slot: demo/save1.json beside the full game's save1.json) and the full game takes up a demo world only when the player
## chooses it. Checks: coexistence (each edition's New game, Continue, autosave, backups and Import leave the other's files byte for
## byte), the demo -> full handoff with its confirmation naming the replaced world (kept in save_backups), the migration of a shared
## save from before Build 42 (copied, never moved), a legacy full-game world put aside by the old demo never removed by the full game,
## and the linked outside copy kept per edition. Only test folders under user:// (XDG_DATA_HOME), never a player's saves.
## One part per process keeps memory low (each new world is a whole village); with no part all run in turn. Run headless:
##   godot --headless --path game --script res://tests/demo_save_slots_test.gd [-- coexist|handoff|legacy|copy]

const DIR := "user://test_saves/demo_save_slots/"
const FULL := DIR + "save1.json"
const DEMO := DIR + "demo/save1.json"

var main
var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	SteamPromo.opener = func(u: String) -> int: return OK
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _wipe(dir: String) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for d in DirAccess.get_directories_at(dir):
		_wipe(dir.path_join(d))
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir.path_join(f)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir))


## {file name: sha256} of the files directly in `dir` (one edition's slot and its previous, kept and backup files).
func _snap(dir: String) -> Dictionary:
	var out := {}
	if DirAccess.dir_exists_absolute(dir):
		for f in DirAccess.get_files_at(dir):
			out[f] = FileAccess.get_sha256(dir.path_join(f))
	return out


func _id(path: String) -> String:
	var r := SaveStore.inspect(path, World.SAVE_VERSION)
	return str((r.data as Dictionary).get("meta", {}).get("save_id", "")) if r.state == "ok" else ""


func _fresh() -> void:
	main.running = false
	main.save_path = FULL
	main._adopted_for = ""
	_wipe(DIR)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))


## A world as the player makes one: creation, the origin's Begin (which saves).
func _new_world(name: String) -> String:
	main.new_game({"name": name, "family": "Test", "sex": "female", "appearance": {}})
	main.resume_after_origin()
	return str(main.save_meta.get("save_id", ""))


func _buttons() -> Array:
	return main.ui.panel_body.find_children("*", "Button", true, false).map(func(b): return str(b.text))


func _press(caption: String) -> bool:
	for b in main.ui.panel_body.find_children("*", "Button", true, false):
		if str((b as Button).text) == caption and not (b as Button).disabled:
			(b as Button).pressed.emit()
			return true
	return false


func _drop_backups(ids: Array) -> void:
	if not DirAccess.dir_exists_absolute(SaveTransfer.BACKUP_DIR):
		return
	for f in DirAccess.get_files_at(SaveTransfer.BACKUP_DIR):
		for id in ids:
			if str(id) != "" and f.contains(str(id)):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveTransfer.BACKUP_DIR + f))     # this test's backups only
				break


func _run() -> void:
	main.set_process(false)
	var args := OS.get_cmdline_user_args()
	var part := str(args[0]) if args.size() > 0 else "all"
	if part in ["all", "coexist"]:
		await _coexistence()
	if part in ["all", "handoff"]:
		await _handoff()
	if part in ["all", "legacy"]:
		await _legacy()
	if part in ["all", "copy"]:
		_linked_copy()
	print("%d checks, %d failures" % [checks, failures])
	Demo.force = -1
	SteamPromo.opener = Callable()
	_wipe(DIR)
	main.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)


# ------------------------------------------------------------------ coexistence --------------------
func _coexistence() -> void:
	_fresh()
	Demo.force = 0
	check(main.save_path == FULL, "the full game's slot is save1.json")
	var full_id := _new_world("Fay")
	main.save_game(false)                                   # a backup (.bak) too
	var full_before := _snap(DIR)
	check(FileAccess.file_exists(FULL) and FileAccess.file_exists(FULL + ".bak"), "the full game's world and its backup are saved")
	# the demo: its own slot; the full game's world is not its to continue
	Demo.force = 1
	main.running = false
	check(main.save_path == DEMO, "the demo's slot is demo/save1.json (%s)" % main.save_path)
	check(not main.can_continue(), "the demo's title has nothing to continue: the full game's world is not the demo's")
	main.ui.show_title(main.can_continue())
	check(main.ui.panel_body.find_children("*", "Button", true, false).any(func(b): return b.text == "Continue" and b.disabled),
			"the demo's Continue is off (%s)" % ", ".join(_buttons()))
	check(not _buttons().has("Continue your demo world"), "the demo's title never offers to take a world")
	var d1 := _new_world("Ada")
	var d2 := _new_world("Bea")                              # a second new game: the first is the previous game
	for i in 3:
		main.save_game(false)                               # autosaves
	main._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)   # the save on closing the window
	check(_snap(DIR) == full_before, "the demo's two New games, autosaves and closing save leave every full-game file byte for byte")
	check(_id(DEMO) == d2 and _id(DIR + "demo/save1.previous.json") == d1 and FileAccess.file_exists(DEMO + ".bak"),
			"the demo's worlds, its previous game and its backup are in its own folder")
	var exp := DIR + "carried.json"
	check(bool(main.export_save_to(exp).ok), "the demo exports its world")
	DirAccess.rename_absolute(ProjectSettings.globalize_path(exp), ProjectSettings.globalize_path(DIR + "demo/carried.json"))
	full_before = _snap(DIR)
	var im: Dictionary = main.import_save_from(DIR + "demo/carried.json")
	await process_frame
	check(bool(im.ok) and _snap(DIR) == full_before, "an Import in the demo goes to the demo's slot; the full game's files are unchanged")
	var demo_before := _snap(DIR + "demo")
	# the full game again: Continue is its own world; its saves and New game leave the demo's files alone
	Demo.force = 0
	main.running = false
	main.continue_game()
	await process_frame
	check(main.running and str(main.save_meta.get("save_id", "")) == full_id, "the full game's Continue goes on with its own world (Fay)")
	main.save_game(false)
	var f2 := _new_world("Gil")
	check(_snap(DIR + "demo") == demo_before, "the full game's Continue, saves and New game leave every demo file byte for byte")
	check(_id(FULL) == f2 and _id(DIR + "save1.previous.json") == full_id, "the full game keeps its own previous game (Fay) as before")
	Demo.force = 1
	main.running = false
	main.continue_game()
	await process_frame
	check(main.running and str(main.save_meta.get("save_id", "")) == d2, "the demo's Continue goes on with its own world (Bea)")
	_drop_backups([d1, d2, full_id, f2])


# ------------------------------------------------------------------ demo -> full game --------------
func _handoff() -> void:
	_fresh()
	Demo.force = 1
	var d1 := _new_world("Ada")
	main.world.player.coins += 7
	var coins: int = main.world.total_coins()
	main.save_game(false)
	var demo_before := _snap(DIR + "demo")
	# the full game with no world of its own: the title offers the demo's world and it goes on at once
	Demo.force = 0
	main.running = false
	main.ui.show_title(main.can_continue())
	check(_buttons().has("Continue your demo world"), "the full game's title offers the demo's world (%s)" % ", ".join(_buttons()))
	check(_press("Continue your demo world"), "Continue your demo world pressed")
	await process_frame
	check(main.running and str(main.save_meta.get("save_id", "")) == d1 and main.world.total_coins() == coins and not main.ui.is_open("demo_expired"),
			"the full game goes on with the demo's world, nothing lost (%d coins), no demo limit" % coins)
	main.save_game(false)
	check(_snap(DIR + "demo") == demo_before, "the demo keeps its own copy of the world, unchanged")
	main.running = false
	main.ui.show_title(main.can_continue())
	check(not _buttons().has("Continue your demo world"), "once the full game has gone on with it, the offer is gone (%s)" % ", ".join(_buttons()))
	# the full game has a world of its own: the offer asks first, naming the world it replaces, and keeps it
	var f1 := _new_world("Fay")
	main.save_game(false)
	var fay_text := FileAccess.get_file_as_string(FULL)
	Demo.force = 1
	main.running = false
	var d2 := _new_world("Bea")
	Demo.force = 0
	main.running = false
	main.ui.show_title(main.can_continue())
	check(_press("Continue your demo world"), "the offer again for the demo's new world (Bea)")
	await process_frame
	check(main.ui.is_open("demo_world") and not main.running, "with a full-game world in the slot, a confirmation opens first; nothing is changed yet")
	var said := " ".join(main.ui.panel_body.find_children("*", "Label", true, false).map(func(l): return str(l.text)))
	check(said.contains("Bea Test") and said.contains("Fay Test") and said.contains("save_backups"),
			"it names the demo world, the full-game world it takes the place of, and where that one is kept (%s)" % said)
	check(_press("Back") and main.ui.is_open("title") and FileAccess.get_file_as_string(FULL) == fay_text, "Back: nothing changed (Fay's save byte for byte)")
	check(_press("Continue your demo world") and _press("Continue the demo world"), "Continue the demo world confirmed")
	await process_frame
	check(main.running and str(main.save_meta.get("save_id", "")) == d2, "the full game goes on with the demo's world (Bea)")
	var kept := ""
	for f in DirAccess.get_files_at(SaveTransfer.BACKUP_DIR):
		if f.begins_with("replaced-%s-" % f1) and FileAccess.get_file_as_string(SaveTransfer.BACKUP_DIR + f) == fay_text:
			kept = f
	check(kept != "", "the full game's world it replaced (Fay) is kept byte for byte in save_backups (%s)" % kept)
	var back: Dictionary = main.import_save_from(SaveTransfer.BACKUP_DIR + kept)
	await process_frame
	check(bool(back.ok) and str(main.save_meta.get("save_id", "")) == f1, "and Import brings Fay's world back")
	_drop_backups([d1, d2, f1])


# ------------------------------------------------------------------ saves from before Build 42 -----
## A save's text as Build 41 wrote it: no edition mark.
func _as_b41(path: String) -> String:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	(d.meta as Dictionary).erase("edition")
	return JSON.stringify(d, "", true, true)


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _legacy() -> void:
	_fresh()
	Demo.force = 0
	var fay := _new_world("Fay")
	var fay_text := _as_b41(FULL)
	Demo.force = 1
	main.running = false
	var ada := _new_world("Ada")
	main.save_meta.demo.active = 7200.0                          # used up
	main.save_game(false)
	var ada_text := _as_b41(DEMO)
	var bea := _new_world("Bea")
	var bea_text := _as_b41(DEMO)
	# Build 41's layout, all in the shared slot: the demo's world Bea in save1.json, the full game's Fay put aside as the previous
	# game by the demo's New game, a used-up demo world kept by its id
	main.running = false
	_wipe(DIR)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	_write(FULL, bea_text)
	_write(DIR + "save1.previous.json", fay_text)
	_write(DIR + "save1.expired-%s.json" % ada, ada_text)
	var shared := _snap(DIR)
	# the new demo, first start: its worlds from the shared slot are copied into its own; nothing shared is touched
	Demo.force = 1
	main._adopted_for = ""
	check(main.can_continue(), "the demo, first start after the update: its world from before is there to continue")
	check(FileAccess.get_file_as_string(DEMO) == bea_text and FileAccess.get_file_as_string(DIR + "demo/save1.expired-%s.json" % ada) == ada_text,
			"the demo's world (Bea) and its kept used-up world are copied byte for byte into the demo's folder")
	check(not FileAccess.file_exists(DIR + "demo/save1.previous.json"), "the full game's world (Fay, no demo record) is not taken into the demo")
	check(_snap(DIR) == shared, "every shared file is left byte for byte (copied, never moved or removed)")
	main.continue_game()
	await process_frame
	check(main.running and str(main.save_meta.get("save_id", "")) == bea and Demo.remaining(main.save_meta) > 0.0, "the demo's Continue goes on with Bea, its time as it was")
	main.save_game(false)
	check(_snap(DIR) == shared, "the demo's saves after the update go to its own folder; the shared files are unchanged")
	main.running = false
	main._adopted_for = ""
	var demo_now := _snap(DIR + "demo")
	check(main.can_continue() and _snap(DIR + "demo") == demo_now, "the copy is made once: a later start copies nothing over the demo's newer save")
	# the full game: its slot is as Build 41 left it, so its Continue still finds the demo's world (the progression before Build 42)
	Demo.force = 0
	main.continue_game()
	await process_frame
	check(main.running and str(main.save_meta.get("save_id", "")) == bea, "the full game's Continue still goes on with the world in its slot (Bea), as before")
	main.save_game(false)
	check(str((SaveStore.inspect(FULL, World.SAVE_VERSION).data as Dictionary).meta.get("edition", "")) == "full", "the full game marks its saves as its own (meta.edition)")
	# the full game's New game: Fay, the full game's world the old demo put aside, is not removed to make room
	var gil := _new_world("Gil")
	var kept := ""
	for f in DirAccess.get_files_at(SaveTransfer.BACKUP_DIR):
		if f.begins_with("previous-%s-" % fay) and FileAccess.get_file_as_string(SaveTransfer.BACKUP_DIR + f) == fay_text:
			kept = f
	check(kept != "", "the full game's own world put aside by the old demo (Fay) is kept byte for byte in save_backups (%s), not removed" % kept)
	check(_id(DIR + "save1.previous.json") == bea and _id(FULL) == gil, "the previous game is now Bea, the world is Gil")
	# the full game's one-previous-game rule is otherwise unchanged: two full-game worlds in a row
	var hal := _new_world("Hal")
	check(_id(DIR + "save1.previous.json") == gil and _id(FULL) == hal, "full game: a new world puts the last aside as the previous game (as before)")
	_drop_backups([fay, ada, bea, gil, hal])


# ------------------------------------------------------------------ the outside copy ---------------
func _linked_copy() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	var cfg := DIR + "settings.cfg"
	var st = main.settings
	var keep: Dictionary = st.save_copies.duplicate()
	Demo.force = 0
	st.save_copy = "user://full_copy.json"
	Demo.force = 1
	check(st.save_copy == "", "the demo has no outside copy of its own yet: the full game's is not the demo's to write")
	st.save_copy = "user://demo_copy.json"
	st.save_file(cfg)
	st.save_copies = {"full": "", "demo": ""}
	st.load_file(cfg)
	check(st.save_copy == "user://demo_copy.json", "the demo's copy is kept (settings, saves, copy_demo)")
	Demo.force = 0
	check(st.save_copy == "user://full_copy.json", "the full game's copy is its own")
	var old := ConfigFile.new()
	old.set_value("saves", "copy", "user://b41_copy.json")
	old.save(cfg)
	st.save_copies = {"full": "", "demo": ""}
	st.load_file(cfg)
	Demo.force = 1
	check(st.save_copy == "", "a copy chosen before Build 42 is the full game's; the demo does not write it")
	Demo.force = 0
	check(st.save_copy == "user://b41_copy.json", "and the full game keeps it")
	st.save_copies = keep
