extends SceneTree
## SJD-G (save migration): writes a real Build 24 save (save version 23, judgment section version 3) through the game's own
## save path (Main.save_game) with UNMODIFIED Build 24 judgment and world code (written at de8d225, whose judgment/ and
## world.gd are byte for byte Build 24's 4611d86): a new single-player game left to run four game days with judgment on as
## shipped, so the section holds facts, memories (permanent ones too: assaults), contributions, ledgers with fading and
## permanent parts, trust, gossip still scheduled and history; the fixture tests/fixtures/b24_save_v23_judgment.json.
##   godot --headless --path game --script res://tests/gen_b24_judgment_fixture.gd -- OUT.json   (run in a checkout of de8d225)

var main


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var args := OS.get_cmdline_user_args()
	main.save_path = args[0] if not args.is_empty() else "user://b24_judgment_fixture.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	main.new_game()
	main.ui.hide_all()
	var w: World = main.world
	while w.day() < 4:
		w.update(0.5)
		w.player.hunger = 100.0                # the idle player is fed (as in economy_sim), so it is alive to save
	w.update(0.5)
	var ok: bool = main.save_game(false)
	print("saved %s (%s): day %d, player alive %s, judgment %s" % [main.save_path, str(ok), w.day(), str(w.player.alive), JSON.stringify(w.judgment.counts())])
	quit(0)
