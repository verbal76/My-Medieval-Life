extends SceneTree
## Writes a real Build 20 save (save version 21) through the game's own save path (Main.save_game) with the UNMODIFIED Build 20
## code (56c24cb): a new single-player game played for a while, the player with coins, goods, a tie with a villager (talk and a
## gift), a partner, a crime on the record and a contract; the fixture tests/fixtures/b20_save_v21_single.json.
##   godot --headless --path game --script res://tests/gen_b20_save_fixture.gd -- OUT.json

var main


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var args := OS.get_cmdline_user_args()
	main.save_path = args[0] if not args.is_empty() else "user://b20_fixture.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	main.new_game()
	main.ui.hide_all()
	var w: World = main.world
	for i in 400:
		w.update(0.5)
	var p := w.player
	p.coins += 50
	p.inv.add("apple", 3)
	var ad: Array = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.job != "guard" and n.partner < 0)
	var friend: NPC = ad[0]
	w.relations.talked(friend)
	w.relations.give(Life.PLAYER_ID, friend, "apple")
	var mate: NPC = null
	for n: NPC in ad:
		if n.sex != p.sex and Life.partner_refusal(w, n) == "":
			mate = n
			break
	if mate != null:
		Life.partner_player(w, mate)
	var v: NPC = ad[ad.size() - 1]
	p.crimes.append({"day": w.day(), "kind": "theft", "what": "bread", "victim": v.id, "witnesses": 1})     # a theft on the record (Build 20 has no crime_record yet)
	main.save_game(false)
	print("saved %s: partner %d, coins %d, pid %d" % [main.save_path, p.partner, p.coins, p.pid])
	quit(0)
