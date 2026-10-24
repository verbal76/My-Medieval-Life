extends SceneTree
## GP-POLISH P2: screenshots of the owner's reports of 2026-10-24 in the real game scene, to be looked at. Needs a display:
##   xvfb-run -a godot --rendering-driver opengl3 --resolution WxH --path game --script res://tests/polish_shot.gd -- OUT.png MODE
## MODE: wheat (a ripe manor field half cut by the player, a cut cell of the player's farm beside it); at:X:Y[:ZOOM] (the
## player and the camera at cell X, Y); at:X:Y:ZOOM:CX:CY (the camera on cell CX, CY)

var main
var out := "/tmp/polish.png"
var mode := "wheat"
var frames := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.size() > 1:
		mode = args[1]
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	main.save_path = "user://test_saves/polish_shot/save1.json"
	main.new_game()
	main.ui.hide_all()
	process_frame.connect(_wait)


func _place() -> void:
	var w: World = main.world
	if mode.begins_with("at:"):
		var a := mode.split(":")
		w.player.pos = Vector2(int(a[1]) + 0.5, int(a[2]) + 0.5)
		main.camera.zoom = Vector2(float(a[3]) if a.size() > 3 else 3.0, float(a[3]) if a.size() > 3 else 3.0) * main.view_scale
		main.camera.position_smoothing_enabled = false
		var look := w.player.pos if a.size() < 6 else Vector2(int(a[4]) + 0.5, int(a[5]) + 0.5)
		main.follow_at = main._in_view(look * main.T)
		return
	if mode.begins_with("pack:"):            # pack:ITEM: the pack open on that item (add --phone for the phone layout)
		var id := mode.substr(5)
		w.player.inv.add(id, 2)
		main.ui.show_inventory(GameData.category(id))
		await process_frame
		main.ui.inventory_window().choose(id)
		return
	if mode == "stall_put" or mode == "talk":     # the stall window with its put-up dialog; a farmer's talk window
		if mode == "talk":
			for n: NPC in w.npcs:
				if n.job == "farmer":
					main.ui.show_talk(n)
					break
			return
		w.player.coins = 100
		w.business.rent()
		var st: Dictionary = w.business.mine()
		w.player.inv.add("pottage", 58)
		w.business.list_item(st, "pottage", 3)
		StallWindow.show(main.ui, str(st.id), {"id": "pottage", "mode": "put"})
		return
	match mode:
		"wheat":
			var f: Dictionary = w.fields[0]
			w.set_field(f, "ripe")
			f.crop = int(GameData.b("field_yield"))
			f.crop_full = int(f.crop)
			w.player.pos = Vector2(int(f.x) + int(f.w) + 0.5, int(f.y) + int(f.h) - 0.5)
			var took := 0
			while took * 2 < int(f.crop_full):
				took += w.player_harvest(f)
			main.camera.zoom = Vector2(3, 3) * main.view_scale
			main.camera.position_smoothing_enabled = false
			main.follow_at = main._in_view(Vector2(int(f.x) + int(f.w) * 0.5, int(f.y) + int(f.h) * 0.5) * main.T)


func _wait() -> void:
	frames += 1
	if frames == 5:
		_place()
	if frames == 8 and not (mode.begins_with("pack:") or mode in ["stall_put", "talk"]):
		main.ui.hide_all()
	if frames < 40:
		return
	process_frame.disconnect(_wait)
	if mode.begins_with("at:"):
		main.ui.hide_all()
		for n in main.ui.find_children("*", "PanelContainer", true, false):
			if n.visible and n.get_global_rect().get_center().y > 300:
				n.visible = false             # the opening toast and the prompt: out of the way of the art
	var img := root.get_texture().get_image()
	img.save_png(out)
	print("saved ", out, " ", img.get_size())
	quit(0)
