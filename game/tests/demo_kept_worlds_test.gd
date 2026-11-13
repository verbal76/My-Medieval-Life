extends SceneTree
## B25-DEMO-KEPT-WORLDS (owner 2026-11-12, option A: "Add a Kept Worlds list on the title screen supporting multiple retained worlds,
## with character, settlement, and last-played information where available. Expired worlds must not be playable beyond demo
## restrictions, but their save data must be preserved for eventual full-game import. Do not delete or overwrite existing saves.
## Verify save compatibility and migration behavior before claiming import works."), driven through the real game scene:
##  - four demo worlds started one after another from the title (one used up); every earlier world's last save is kept, byte for
##    byte, under its own name (a name already taken by another file: both kept); nothing deleted or written over;
##  - the title's Kept worlds window lists each with its character, settlement, day and when it was last played;
##  - a used-up world opens the demo's end screen and its Export, and is never played on (refused, its file unmoved);
##  - a world with time left is continued from the list (the world in the slot kept aside first), its demo time as it was;
##  - full-game import of the exported used-up world (SaveTransfer: validated, migrated) plays on with the character, coins,
##    inventory and day it had; a version 22 save marked as a used-up demo world goes through the migration (22 to 23) the same way;
##  - the full game's title is unchanged (no Kept worlds) and its one-previous-game rule is as before.
## Run headless:  godot --headless --path game --script res://tests/demo_kept_worlds_test.gd

const DIR := "user://test_saves/demo_kept_worlds_test/"
const SAVE := DIR + "save1.json"
const FULL_DIR := DIR + "full_app/"

var main
var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	_wipe(DIR)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FULL_DIR))
	Demo.force = 1
	SteamPromo.opener = func(u: String) -> int: return OK
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = SAVE
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _wipe(dir: String) -> void:
	var abs := ProjectSettings.globalize_path(dir)
	if not DirAccess.dir_exists_absolute(abs):
		return
	for d in DirAccess.get_directories_at(abs):
		_wipe(dir.path_join(d) + "/")
	for f in DirAccess.get_files_at(abs):
		DirAccess.remove_absolute(abs.path_join(f))


func _frames(n: int, dt := 0.1) -> void:
	for i in n:
		main._process(dt)


func _buttons() -> Array:
	return main.ui.panel_body.find_children("*", "Button", true, false).map(func(b): return str(b.text))


func _labels() -> Array:
	return main.ui.panel_body.find_children("*", "Label", true, false).map(func(l): return str(l.text))


func _press(caption: String, prefix := false) -> bool:
	for b in main.ui.panel_body.find_children("*", "Button", true, false):
		var t := str((b as Button).text)
		if (t == caption or (prefix and t.begins_with(caption))) and not (b as Button).disabled:
			(b as Button).pressed.emit()
			return true
	return false


func _new_world(name: String) -> bool:
	if not main.ui.is_open("creation"):
		return false
	var edits: Array = main.ui.panel_body.find_children("*", "LineEdit", true, false)
	if edits.size() < 2:
		return false
	(edits[0] as LineEdit).text = name
	(edits[1] as LineEdit).text = "Demo"
	if not _press("Begin") or not main.ui.is_open("origin"):
		return false
	return _press("Begin")


## Every save file in the folder: file name -> text (the backups and temporary files of the slot left out).
func _files() -> Dictionary:
	var out := {}
	for f in DirAccess.get_files_at(ProjectSettings.globalize_path(DIR)):
		if f.ends_with(".json") and not f.contains(".backup-"):
			out[f] = FileAccess.get_file_as_string(DIR + f)
	return out


func _id_of(text: String) -> String:
	var json := JSON.new()                 # a file that is not a save (the test's own) reads as no id, without an engine error
	if json.parse(text) != OK or not json.data is Dictionary:
		return ""
	return str((json.data as Dictionary).get("meta", {}).get("save_id", ""))


## From the title: a new world begun, played a little and saved; its last save's text is what must survive.
func _start_world(name: String) -> String:
	main.running = false
	main.ui.show_title(main.can_continue())
	check(_press("New game") and _new_world(name), "%s: a new world begun from the title (%s)" % [name, "demo" if Demo.is_demo() else "full game"])
	await process_frame
	_frames(50)
	check(main.save_game(false), "%s's world saved" % name)
	return str(main.save_meta.get("save_id", ""))


func _run() -> void:
	var ui = main.ui
	main.set_process(false)
	# --- world 1: Ada, played, given coins and goods, and used up
	var ida: String = await _start_world("Ada")
	var w: World = main.world
	w.player.coins += 37
	w.player.inv.add("bread", 3)
	w.player.inv.add("log", 2)
	var ada := {"coins": w.player.coins, "bread": w.player.inv.count("bread"), "log": w.player.inv.count("log"), "minutes": 0.0, "pos": Vector2.ZERO}
	main.save_meta.demo.active = 7200.0 - 1.0
	main.save_meta.demo.warned = [1800, 600, 300, 60]
	_frames(20)
	check(Demo.expired(main.save_meta) and ui.is_open("demo_expired"), "Ada's world: demo time used up, the end screen shown")
	ada.minutes = w.minutes
	ada.pos = w.player.pos
	ada["day"] = int(w.minutes / 1440.0) + 1
	var seen := {}                         # world id -> the text of its last save (what must be kept, byte for byte)
	seen[ida] = FileAccess.get_file_as_string(SAVE)
	# --- worlds 2 to 4, each from the title; a file already holding the name Bea's world will be kept under, to keep both
	var order := [ida]
	var names := ["Bea", "Cid", "Dan"]
	var decoy := ""
	for n in names:
		if n == "Dan":
			decoy = DIR + "save1.kept-%s.json" % order[1].validate_filename()
			var f := FileAccess.open(decoy, FileAccess.WRITE)
			f.store_string("a file the player put here")
			f.close()
		var id: String = await _start_world(n)
		order.append(id)
		var all := _files()
		var lost := []
		for k in seen:
			if not all.values().has(seen[k]):
				lost.append(k)
		check(lost.is_empty(), "after %s's new world every earlier world's last save is still on disk, unchanged (%d kept, %d lost)" % [n, seen.size(), lost.size()])
		seen[id] = FileAccess.get_file_as_string(SAVE)
	check(FileAccess.get_file_as_string(decoy) == "a file the player put here", "a file already under the name a world is kept by is not written over")
	check(FileAccess.file_exists(DIR + "save1.kept-%s-2.json" % order[1].validate_filename()), "Bea's world kept beside it under a numbered name (%s)" % ("save1.kept-%s-2.json" % order[1]))
	check(FileAccess.file_exists(DIR + "save1.expired-%s.json" % ida.validate_filename()), "the used-up world kept as save1.expired-<its id>.json")
	# --- the title's Kept worlds list
	main.running = false
	ui.show_title(main.can_continue())
	check(ui.panel_body.find_child("KeptWorlds", true, false) != null, "the demo's title offers Kept worlds")
	check(_press("Kept worlds") and ui.is_open("kept_worlds"), "Kept worlds opens its window")
	var labels := _labels()
	var listed: Array = main.kept_worlds()
	check(listed.size() == 5, "five files listed: four worlds and the player's own file (%s)" % ", ".join(listed.map(func(e): return str(e.file))))
	for i in names.size() + 1:
		var who: String = (["Ada"] + names)[i] + " Demo"
		check(labels.any(func(t): return t.contains(who) and t.contains("The manor village") and t.contains("day ") and t.contains("Last played")),
			"the list shows %s's world with its character, settlement, day and last played" % who)
	check(labels.any(func(t): return t.contains("Ada Demo") and t.contains("Demo time used up")), "Ada's world is marked used up")
	check(labels.any(func(t): return t.contains("Bea Demo") and t.contains("Demo time left")), "Bea's world shows its demo time left")
	check(labels.any(func(t): return t.contains("cannot be read") and t.contains("kept as it is")), "the file that is not a save is listed as kept as it is")
	check(labels.any(func(t): return t.begins_with("Your current world") and t.contains("Dan Demo")), "the current world is Dan's")
	check(labels.any(func(t): return t.contains("Ada Demo") and t.contains("day %d" % int(ada.day))), "Ada's day as saved (day %d)" % int(ada.day))
	# --- the used-up world: its end screen and Export; never played on
	var ada_path := DIR + "save1.expired-%s.json" % ida.validate_filename()
	check(_press("Demo time used up: Ada Demo") and ui.is_open("kept_expired"), "the used-up world opens the demo's end screen")
	check(_labels().has(Demo.EXPIRED_NOTE) and ui.panel_body.find_child("KeptExport", true, false) != null and ui.panel_body.find_child("SteamButton", true, false) != null,
		"it says the approved words and offers Export and the Steam page (%s)" % ", ".join(_buttons()))
	check(not main.running and str(main.save_meta.get("save_id", "")) != ida, "the used-up world is not loaded or played")
	var why: String = main.continue_kept_world(ada_path)
	check(why != "" and FileAccess.get_file_as_string(ada_path) == seen[ida] and not main.running, "continuing it in the demo is refused, the file unmoved and unchanged (%s)" % why)
	var exported := DIR + "ada_export.json"
	var ex: Dictionary = main.export_kept_world(ada_path, exported)
	check(ex.ok and FileAccess.get_file_as_string(exported) == seen[ida] and FileAccess.get_file_as_string(ada_path) == seen[ida], "Export copies the used-up world, byte for byte, and leaves it in place (%s)" % str(ex.get("info", ex.get("reason", ""))))
	# --- a kept world with time left, continued from the list
	ui.show_kept_worlds()
	var bea_left := 0.0
	for e in main.kept_worlds():
		if str(e.get("save_id", "")) == order[1]:
			bea_left = float(e.remaining)
	check(_press("Continue Bea Demo"), "Continue Bea Demo pressed")
	await process_frame
	check(main.running and not main.paused and str(main.save_meta.get("save_id", "")) == order[1] and is_equal_approx(Demo.remaining(main.save_meta), bea_left),
		"Bea's world continues in the demo, its demo time as it was (%s left)" % Demo.text(bea_left))
	var all2 := _files()
	var ids := {}
	for f in all2:
		ids[_id_of(all2[f])] = true
	check(order.all(func(i): return ids.has(i)), "every world is still on disk after the switch (Dan's kept aside)")
	check(FileAccess.file_exists(DIR + "save1.kept-%s.json" % order[3].validate_filename()), "Dan's world, in the slot before, is kept under its own name")
	main.save_game(false)
	# --- full game: the exported used-up world imported in its own storage (Android) and played
	Demo.force = 0
	main.running = false
	main.save_path = FULL_DIR + "save1.json"
	var im: Dictionary = main.import_save_from(exported)
	await process_frame
	w = main.world
	check(im.ok and int(im.get("from_version", 0)) == World.SAVE_VERSION, "the full game imports the exported demo world (SaveTransfer checked and validated it) (%s)" % str(im.get("reason", "")))
	check(str(main.save_meta.get("save_id", "")) == ida and str(w.player.name) == "Ada" and str(w.player.family) == "Demo", "the same world and character (Ada Demo, id %s)" % ida)
	check(w.player.coins == int(ada.coins) and w.player.inv.count("bread") == int(ada.bread) and w.player.inv.count("log") == int(ada.log),
		"coins and inventory kept (%d coins, %d bread, %d logs)" % [w.player.coins, w.player.inv.count("bread"), w.player.inv.count("log")])
	check(is_equal_approx(w.minutes, float(ada.minutes)) and w.player.pos == ada.pos and int(w.minutes / 1440.0) + 1 == int(ada.day), "the day and place kept (day %d, minute %.1f)" % [int(ada.day), w.minutes])
	_frames(100)
	ui.update_hud()
	check(main.running and not main.paused and not ui.is_open("demo_expired") and not ui.demo_label.visible, "the full game plays it with no demo limit or timer")
	check(w.minutes > float(ada.minutes) and main.save_game(false), "and it plays on and saves")
	# --- migration. A demo save is written by the same source at the same save version (World.SAVE_VERSION) and region generation
	# as the full game, so it needs no migration; the migration path is still checked: (1) the demo world written as the previous
	# save version (22) is brought up (SaveTransfer.MIGRATIONS 22 to 23) and plays; (2) an older demo-marked save whose region was
	# laid out before the rebuild (the v22 fixture, overworld generation 2) is refused by design (B25R1-Q5), nothing changed.
	var ada_d: Dictionary = JSON.parse_string(seen[ida])
	ada_d["save_version"] = 22
	var v22_path := DIR + "ada_as_v22.json"
	var f2 := FileAccess.open(v22_path, FileAccess.WRITE)
	f2.store_string(JSON.stringify(ada_d, "", true, true))
	f2.close()
	var before := FileAccess.get_file_as_string(main.save_path)
	main.running = false
	var im22: Dictionary = main.import_save_from(v22_path)
	await process_frame
	w = main.world
	check(im22.ok and int(im22.get("from_version", 0)) == 22 and int(JSON.parse_string(FileAccess.get_file_as_string(main.save_path)).save_version) == World.SAVE_VERSION,
		"the used-up demo world as a save 22 is migrated to %d on import (%s)" % [World.SAVE_VERSION, str(im22.get("reason", ""))])
	check(str(main.save_meta.get("save_id", "")) == ida and w.player.coins == int(ada.coins) and w.player.inv.count("bread") == int(ada.bread) and is_equal_approx(w.minutes, float(ada.minutes)) and main.running,
		"and plays with the same character, coins, goods and day (%s, %d coins)" % [str(w.player.name), w.player.coins])
	var replaced := str(im22.get("replaced", ""))
	check(replaced != "" and _id_of(FileAccess.get_file_as_string(replaced)) == ida and FileAccess.get_file_as_string(replaced) == before,
		"the full game's save it replaced is kept, unchanged, in its save backups (%s)" % replaced.get_file())
	var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/mp_save_v22_couple.json"))
	old["meta"] = {"save_id": "old22world", "saved_at": 1762000000, "demo": {"allowance": 7200.0, "active": 7200.0, "warned": [1800, 600, 300, 60], "expired": true}}
	var old_path := DIR + "save1.expired-old22world.json"
	var old_text := JSON.stringify(old, "", true, true)
	var f3 := FileAccess.open(old_path, FileAccess.WRITE)
	f3.store_string(old_text)
	f3.close()
	var e22: Dictionary = KeptWorlds.info(old_path, SAVE)
	check(bool(e22.ok) and bool(e22.expired) and str(e22.character).begins_with(str(old.player.name)), "an older used-up demo world is listed: %s" % KeptWorlds.describe(e22))
	main.save_game(false)
	main.running = false                   # on the title: nothing running saves over the slot during the import
	before = FileAccess.get_file_as_string(main.save_path)
	var imo: Dictionary = main.import_save_from(old_path)
	check(not imo.ok and str(imo.reason).contains("before the region was rebuilt") and FileAccess.get_file_as_string(main.save_path) == before and FileAccess.get_file_as_string(old_path) == old_text,
		"one from before the region was rebuilt is refused with the reason, nothing changed (%s)" % str(imo.get("reason", "")).left(90))
	# --- the full game: the title is unchanged, and its one-previous-game rule is as before
	main.running = false
	ui.show_title(main.can_continue())
	check(ui.panel_body.find_child("KeptWorlds", true, false) == null and not _buttons().any(func(t): return t.contains("Kept")), "the full game's title has no Kept worlds (%s)" % ", ".join(_buttons()))
	check(_buttons().slice(0, 5) == ["Continue", "New game", "Host a game", "Join a game", "Settings"], "the full game's title buttons as before")
	for n in ["Eve", "Fay"]:
		await _start_world(n)
	var full_kept := Array(DirAccess.get_files_at(ProjectSettings.globalize_path(FULL_DIR))).filter(func(f): return f.contains(".kept-") or f.contains(".expired-"))
	check(full_kept.is_empty() and FileAccess.file_exists(FULL_DIR + "save1.previous.json"), "the full game keeps one previous game, as before (no kept files)")
	check(main.continue_kept_world(main.save_path) != "", "the full game does not use kept worlds")
	print("%d checks, %d failures" % [checks, failures])
	Demo.force = -1
	SteamPromo.opener = Callable()
	main.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures > 0 else 0)
