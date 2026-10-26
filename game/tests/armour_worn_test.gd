extends SceneTree
## ARMOR-01 (owner playtest 2026-10-26: "I want to see my character wear the armor I purchase and put on"), in the real
## game scene, through the verbs the game uses (World.player_equip / player_unequip) and the view's own redraw:
##   - every armour and head item, put on, changes the player's drawn sheet; taken off, the sheet is the bare one again;
##   - in all eight directions the frame drawn differs while worn;
##   - armour and helmet together survive a save and a load, and are drawn after it;
##   - a character with no recipe (an heir from a villager's child, an old default sheet) shows its armour too;
##   - another player's worn gear (multiplayer): the public record carries it, the snapshot updates it, and the avatar
##     is redrawn when it changes.
##   godot --headless --path game --script res://tests/armour_worn_test.gd

var main
var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL " + what)


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://test_saves/armour_worn_test/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func frames(n := 3) -> void:
	for i in n:
		await process_frame


func px(t: Texture2D) -> PackedByteArray:
	var img := t.get_image()
	img.convert(Image.FORMAT_RGBA8)
	return img.get_data()


func frame_px(t: Texture2D, row: int, col: int) -> PackedByteArray:
	var img := t.get_image()
	img.convert(Image.FORMAT_RGBA8)
	return img.get_region(Rect2i(col * 32, row * 32, 32, 32)).get_data()


func _run() -> void:
	main.new_game()
	main.ui.hide_all()
	var w: World = main.world
	var p := w.player
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	p.appearance = CharacterLook.normalize(CharacterLook.random_recipe(rng, "female"))     # as character creation gives
	p.sprite = ""
	main.player_sprite.setup_texture(CharacterLook.player_sheet(p))
	await frames()
	check(not p.appearance.is_empty(), "a character made in character creation (a recipe)")
	for slot in ["armor", "head"]:
		w.player_unequip(slot)
	await frames()
	var bare := px(main.player_sprite.texture)
	var gear := []
	for id in GameData.items:
		if str(GameData.items[id].type) in ["armor", "head"] and float(GameData.items[id].get("armor", 0)) > 0.0:
			gear.append(str(id))
	gear.sort()
	check(gear.size() >= 4, "the armour items: %s" % [gear])
	for id in gear:
		p.inv.add(id, 1)
		check(w.player_equip(id), "%s: put on" % id)
		await frames()
		var t: Texture2D = main.player_sprite.texture
		check(px(t) != bare, "%s: the player is drawn wearing it" % id)
		var dirs_ok := true
		for row in 8:
			for col in [0, 2, 5, 13, 16]:          # idle, walk, sword, work, tool swing
				if frame_px(t, row, col) == _bare_frame(bare, row, col):
					dirs_ok = false
		check(dirs_ok, "%s: it shows in all eight directions, idle, walking, working and fighting" % id)
		var slot: String = "armor" if str(GameData.items[id].type) == "armor" else "head"
		check(w.player_unequip(slot), "%s: taken off" % id)
		await frames()
		check(px(main.player_sprite.texture) == bare, "%s: taken off, the character's own clothes again" % id)
		p.inv.remove(id, 1)                     # Build 22: the catalogue has more pieces than the armour tab has places
	# save and load keep the armour on, and it is drawn
	p.inv.add("iron_armor", 1)
	p.inv.add("iron_helmet", 1)
	w.player_equip("iron_armor")
	w.player_equip("iron_helmet")
	await frames()
	var worn_px := px(main.player_sprite.texture)
	check(main.save_game(false), "saved")
	main.continue_game()
	await frames(4)
	check(main.world.player.armor == "iron_armor" and main.world.player.head == "iron_helmet" and px(main.player_sprite.texture) == worn_px, "after a load the armour and helmet are worn and drawn the same")
	w = main.world
	p = w.player
	# no recipe (an heir from a villager's child): the worn layers over the baked sheet
	var baked_path := "res://assets/characters/villager_00.png"
	if ResourceLoader.exists(baked_path):
		var ps := PlayerState.new()
		ps.sprite = baked_path
		var plain := px(CharacterLook.player_sheet(ps))
		ps.armor = "leather_armor"
		ps.head = "iron_helmet"
		check(px(CharacterLook.player_sheet(ps)) != plain, "a character drawn from a baked sheet shows its armour and helmet too")
		ps.armor = ""
		ps.head = ""
		check(px(CharacterLook.player_sheet(ps)) == plain, "and without them, the baked sheet as it was")
	# another player's gear
	var gu := PlayerState.new()
	gu.name = "Gwen"
	gu.family = "Fairlight"
	gu.appearance = CharacterLook.normalize(p.appearance)
	Identity.register_player(w, gu)
	w.add_guest(gu)
	gu.armor = "iron_armor"
	gu.inv.add("bread", 3)
	var pub: Dictionary = NetSession.public_player(gu)
	check(str(pub.get("armor", "")) == "iron_armor" and (pub.get("inv", {}).get("items", {}) as Dictionary).is_empty(), "the public record of a player carries what they wear, not their pack")
	main.net.my_pid = -99
	main.net.s_players([{"pid": gu.pid, "name": gu.name, "sprite": "", "pos": p.pos + Vector2(2, 0), "dir": Vector2.DOWN, "anim": "idle", "alive": true, "worn": ["", ""]}])
	check(gu.armor == "" and gu.head == "", "a snapshot updates what another player wears")
	main.net.role = "guest"                    # draw the avatars as a guest's machine does (only for these calls)
	main._sync_avatars(0.1)
	var av: ActorSprite = main.avatar_sprites.get(gu.pid)
	var a0 := px(av.texture) if av != null else PackedByteArray()
	main.net.s_players([{"pid": gu.pid, "name": gu.name, "sprite": "", "pos": p.pos + Vector2(2, 0), "dir": Vector2.DOWN, "anim": "idle", "alive": true, "worn": ["leather_armor", "leather_cap"]}])
	main._sync_avatars(0.1)
	var a1 := px(av.texture) if av != null else PackedByteArray()
	main.net.s_players([{"pid": gu.pid, "name": gu.name, "sprite": "", "pos": p.pos + Vector2(2, 0), "dir": Vector2.DOWN, "anim": "idle", "alive": true, "worn": ["", ""]}])
	main._sync_avatars(0.1)
	var a2 := px(av.texture) if av != null else PackedByteArray()
	main.net.role = ""
	check(av != null and a1 != a0 and a2 == a0, "another player's avatar is redrawn when they put armour on and take it off")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _bare_frame(bare: PackedByteArray, row: int, col: int) -> PackedByteArray:
	var img := Image.create_from_data(928, 256, false, Image.FORMAT_RGBA8, bare)
	return img.get_region(Rect2i(col * 32, row * 32, 32, 32)).get_data()
