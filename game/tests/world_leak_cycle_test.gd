extends SceneTree
## B42 KI-08 (Build 40 D1): a world thrown away is freed. Drives the real game scene the way a player does: a new game, then
## N times "Save and quit to title" (the pause menu's own steps) and Continue (main.continue_game), and counts the
## engine's live objects (Performance OBJECT_COUNT) on the title after each cycle. Before the fix every world survived as a
## reference cycle (World <-> its subsystems' back-references), about 450-500 objects a cycle. It also checks a dropped
## World is really freed (a weakref to it goes empty). Run headless:
##   godot --headless --path game --script res://tests/world_leak_cycle_test.gd [-- --cycles N]

const TEST_SAVE := "user://test_saves/world_leak_cycle_test/save1.json"
## Objects a cycle may still add on the title once the first cycles have warmed every cache (fonts, shaders, the wiki's
## pages, the save store's buffers...): far below one world (~450+ objects a world on Build 41).
const PER_CYCLE_TOLERANCE := 20

var main
var failures := 0


func check(cond: bool, what: String) -> void:
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	if main.get_script() == null or not main.has_method("continue_game"):
		print("FAIL the game's main script did not load (a script error above): stopping")
		quit(1)
		return
	main.save_path = TEST_SAVE
	_clear_saves()
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _clear_saves() -> void:
	var dir := ProjectSettings.globalize_path(TEST_SAVE.get_base_dir())
	DirAccess.make_dir_recursive_absolute(dir)
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(f))


## The pause menu's "Save and quit to title" (GameUI.show_pause), step for step.
func save_and_quit_to_title() -> void:
	main.stop_hosting()
	main.save_game(false)
	main.end_recording()
	main.running = false
	main.ui.show_title(true)


func settle() -> void:
	for i in 4:
		await process_frame          # queue_free'd nodes go, deferred calls run


func _objects() -> int:
	return int(Performance.get_monitor(Performance.OBJECT_COUNT))


func _run() -> void:
	var cycles := 4
	var args := OS.get_cmdline_user_args()
	var at := args.find("--cycles")
	if at >= 0 and at + 1 < args.size():
		cycles = int(args[at + 1])
	main.new_game()
	await settle()
	check(main.world != null and main.world.load_error == "", "a new world started")
	save_and_quit_to_title()
	await settle()
	var counts: Array = [_objects()]
	var mem: Array = [Performance.get_monitor(Performance.MEMORY_STATIC)]
	var prev: WeakRef = weakref(main.world)
	for c in cycles:
		main.continue_game()
		await settle()
		check(main.world != null and main.running, "cycle %d: Continue loaded the world" % (c + 1))
		var w_now = main.world
		check(prev.get_ref() == null, "cycle %d: the previous world was freed when the save was loaded" % (c + 1))
		prev = weakref(w_now)
		w_now = null
		save_and_quit_to_title()
		await settle()
		counts.append(_objects())
		mem.append(Performance.get_monitor(Performance.MEMORY_STATIC))
		print("cycle %d on the title: %d objects, static memory %.1f MB" % [c + 1, counts[-1], mem[-1] / 1048576.0])
	# the first cycles warm caches; the growth from the second to the last is the per-world leak
	var grow := (int(counts[-1]) - int(counts[1])) / float(maxi(1, cycles - 1))
	print("objects on the title per cycle: %s (growth %.1f a cycle after the first)" % [str(counts), grow])
	check(grow <= PER_CYCLE_TOLERANCE, "the title's object count is flat across cycles (%.1f a cycle, at most %d)" % [grow, PER_CYCLE_TOLERANCE])
	# the last world, kept by main for the next Continue, is freed once main throws it away (AerialMap's static instance
	# held it until the next map opened)
	main._clear_world()
	main.world = null
	await settle()
	check(prev.get_ref() == null, "the last world was freed when main threw it away")
	print("%s: %d failure(s)" % ["PASS" if failures == 0 else "FAIL", failures])
	_clear_saves()
	quit(1 if failures > 0 else 0)
