extends SceneTree
## B25R1-007 (owner directive 2026-11-03 section 6, "Unlock all cosmetic character customization options") and B25R1-008
## (section 7A, 7B, 7D), scenario H: the character creator, driven through the real game scene and its window. Checks that
## every cosmetic option is reachable in the window for a man and a woman alike (no gender gate), for every body; that each
## option draws (every direction of every animation play uses, the layer on the body); that the look is the player's sprite
## in play, saved and loaded; that an older save (before the new layers) loads and draws as before; that no look grants or
## changes equipment, coins or anything else; and the window's behaviour: the HUD hidden behind it, the dimmer taking stray
## touches, the origin's words unchanged. Run headless:
##   godot --headless --path game --script res://tests/char_create_test.gd [-- CONTACT.png]
## With a path, it also saves a contact sheet of fantasy looks (rows: looks; columns: the frames of idle, walk, sword,
## work, swing, gather and carry facing south, east, north and west) to look at.

var main
var failures := 0
const TEST_SAVE := "user://test_saves/char_create_test/save1.json"
# the frames play draws a character with (ActorSprite.ANIMS); every one must draw in every direction
const PLAY_ANIMS := ["idle", "walk", "sword", "work", "swing", "gather", "carry", "hurt", "throw"]


func check(cond: bool, what: String) -> void:
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = TEST_SAVE
	DirAccess.make_dir_recursive_absolute(TEST_SAVE.get_base_dir())
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _find(name: String) -> Node:
	return main.ui.panel_body.find_child(name, true, false)


func _press(name: String) -> bool:
	var b := _find(name) as Button
	if b == null or b.disabled:
		return false
	b.pressed.emit()
	return true


## The recipe the open creator holds: what Begin would start with (read from the preview's sheet: the texture is cached per
## recipe, so the one whose texture it is).
func _spec_of(recipes: Array):
	var tex: Texture2D = (_find("Preview") as TextureRect).texture.atlas
	for r in recipes:
		if CharacterLook.texture(r) == tex:
			return r
	return null


func _run() -> void:
	var ui = main.ui
	var st := CharacterLook.style()
	var base: Dictionary = CharacterLook.normalize({"picks": {"race": "human", "hair": "m2", "clothes": "basic", "shoes": "leather-boots"},
		"swatches": {"skin": 1, "hair": 1, "facial_hair": 1, "eyes": 3, "clothes": 0, "leather_shoes": 0}})

	# 1. every cosmetic option is offered, and nothing that is equipment
	var picks: Dictionary = st.creation.picks
	check(picks.race == ["human", "cyclops", "skeleton"] and (picks["ears-&-horns"] as Array).size() == 12 and picks.jaw.size() == 2,
		"creation offers every body (human, cyclops, skeleton), all 11 ears and horns and the jaw")
	check(not picks.has("headwear") and not picks.has("gloves") and picks.clothes == ["basic", "tunic"]
		and not (picks.shoes as Array).has("metal-boots"), "no headwear, gloves, armour or metal boots: those are equipment")
	var rows_ok := true
	for sel in ["skin", "hair", "eyes", "clothes", "tunic", "leather_shoes", "skeleton"]:
		var ramp := str(st.selections[sel])
		rows_ok = rows_ok and CharacterLook.rows(sel).size() == (st.ramps[ramp] as Array).size()
	check(rows_ok and CharacterLook.rows("skin").size() >= 20 and CharacterLook.rows("hair").size() >= 20 and CharacterLook.rows("eyes").size() >= 20,
		"every row of every colour ramp is offered: %d skins, %d hair and %d eye colours" % [CharacterLook.rows("skin").size(),
		CharacterLook.rows("hair").size(), CharacterLook.rows("eyes").size()])
	var named := true
	for sel in ["skin", "hair", "eyes", "clothes", "skeleton"]:
		for r in CharacterLook.rows(sel):
			named = named and not CharacterLook.swatch_name(sel, int(r)).begins_with("colour")
	check(named, "every colour has a name (its tooltip and the chosen colour's line)")
	var fantasy_skin := ["sky blue", "deep blue", "stone grey", "teal"].all(func(n): return st.added_rows.skin.values().has(n))
	check(fantasy_skin and CharacterLook.swatch_name("skin", 8) == "green", "fantasy skins: green, blue, grey and teal among them")

	# 2. every option draws: each layer option on each body, every direction of every animation play uses, on the body
	var bad := []
	var drawn := 0
	for race in picks.race:
		for layer in ["ears-&-horns", "jaw", "hair", "facial-hair", "eyelashes", "clothes", "shoes"]:
			for opt in CharacterLook.options(layer):
				if opt == "":
					continue
				var r: Dictionary = base.duplicate(true)
				r.picks.race = race
				r.picks[layer] = opt
				var why := _draws(r, layer, str(opt))
				drawn += 1
				if why != "":
					bad.append("%s %s %s: %s" % [race, layer, opt, why])
	check(bad.is_empty(), "%d layer options on all three bodies draw in all 8 directions of %s, on the body %s" % [drawn, PLAY_ANIMS, bad.slice(0, 4)])
	# every colour row recolours what it should
	var same := []
	for sel in ["skin", "hair", "eyes", "clothes", "tunic", "leather_shoes", "skeleton"]:
		var r0: Dictionary = base.duplicate(true)
		if sel == "tunic":
			r0.picks.clothes = "tunic"
		if sel == "skeleton":
			r0.picks.race = "skeleton"
		var seen := {}
		for row in CharacterLook.rows(sel):
			var r: Dictionary = r0.duplicate(true)
			CharacterLook.set_swatch(r, sel, int(row))
			var key := CharacterLook.render(r).get_data().hex_encode().sha256_text()
			if seen.has(key):
				same.append("%s %d = %d" % [sel, row, seen[key]])
			seen[key] = int(row)
	check(same.is_empty(), "every colour of every ramp draws a different character %s" % [same])

	# 3. the window: every option reachable for a woman and for a man (no gender gate), the preview redrawn from the choice
	for sx in ["female", "male"]:
		ui.creation_tab = "body"
		ui.show_creation({"name": "Ada", "family": "Thorne", "sex": sx, "appearance": base})
		var reached := {}
		var missing := []
		for f in [["Body", "race"], ["Ears & horns", "ears-&-horns"], ["Jaw", "jaw"], ["Hair", "hair"], ["Beard", "facial-hair"],
				["Eyelashes", "eyelashes"], ["Clothes", "clothes"], ["Boots", "shoes"]]:
			var label: String = f[0]
			var layer: String = f[1]
			var opts := CharacterLook.options(layer)
			var seen := {}
			for i in opts.size():
				var v: Label = _find(label + " value")
				if v == null:
					break
				seen[v.text] = true
				_press(label + " >")
			reached[layer] = seen.size()
			if seen.size() != opts.size():
				missing.append("%s %d of %d" % [layer, seen.size(), opts.size()])
			ui.show_creation({"name": "Ada", "family": "Thorne", "sex": sx, "appearance": base})
		check(missing.is_empty(), "a %s can reach every option of every layer with < and > %s" % [sx, missing])
		var sw_missing := []
		for f in [["Skin", "skin"], ["Hair colour", "hair"], ["Eyes", "eyes"], ["Clothes colour", "clothes"], ["Boots colour", "leather_shoes"]]:
			for row in CharacterLook.rows(f[1]):
				if _find("%s %d" % [f[0], row]) == null:
					sw_missing.append("%s %d" % [f[0], row])
		check(sw_missing.is_empty(), "a %s sees a swatch for every skin, hair, eye, cloth and leather colour %s" % [sx, sw_missing.slice(0, 5)])
	# pressing a swatch and a pick redraws the preview with exactly that change
	ui.show_creation({"name": "Ada", "family": "Thorne", "sex": "female", "appearance": base})
	_press("Skin 12")
	var want: Dictionary = base.duplicate(true)
	CharacterLook.set_swatch(want, "skin", 12)
	check(_spec_of([want]) != null, "a deep blue skin swatch redraws the preview in that skin")
	_press("Ears & horns >")
	want.picks["ears-&-horns"] = "elven-ears"
	check(_spec_of([want]) != null, "and Ears & horns > gives her elven ears")
	_press("Beard >")
	want.picks["facial-hair"] = "beard1"
	check(_spec_of([want]) != null, "a woman may have a beard")
	# a skeleton: its bone colours in place of skin, no eye colour or eyelashes
	var bones: Dictionary = base.duplicate(true)
	bones.picks.race = "skeleton"
	ui.show_creation({"name": "Ada", "family": "Thorne", "sex": "female", "appearance": bones})
	check(_find("Bone 2") != null and _find("Skin 0") == null and _find("Eyes 0") == null and _find("Eyelashes >") == null,
		"a skeleton chooses its bone and eye glow, and no skin, eye colour or eyelashes")
	var cyc: Dictionary = base.duplicate(true)
	cyc.picks.race = "cyclops"
	ui.show_creation({"name": "Ada", "family": "Thorne", "sex": "male", "appearance": cyc})
	check(_find("Skin 0") != null and _find("Eyes 0") == null, "a cyclops chooses its skin, and its one eye is its own")
	# the preview: animated, turned and posed
	var pv: LookPreview = _find("Preview")
	var r1: Rect2 = (pv.texture as AtlasTexture).region
	pv._process(0.15)
	check((pv.texture as AtlasTexture).region != r1, "the preview is animated (walking by default)")
	_press("Turn right")
	check(not pv.turning and pv.dir == 1 and ui.preview_dir == 1, "Turn right stops its turning and faces it the next way")
	_press("Pose")
	check(pv.anim == "idle" and (_find("Pose") as Button).text == "Standing", "Pose changes it to standing")
	ui.preview_pose = "walk"
	ui.preview_dir = 0
	ui.preview_turning = true
	# Randomize: anything at all; Plain villager: an ordinary human
	var rng := RandomNumberGenerator.new()
	var fantasy := 0
	var plain_ok := true
	for i in 200:
		rng.seed = 7000 + i
		var rr := CharacterLook.random_recipe(rng, "female", true)
		if rr.picks.race != "human" or rr.picks["ears-&-horns"] != "" or int(rr.swatches.skin) > 6:
			fantasy += 1
		var pr := CharacterLook.random_recipe(rng, "female")
		plain_ok = plain_ok and pr.picks.race == "human" and pr.picks["ears-&-horns"] == "" and int(pr.swatches.skin) <= 6
	check(fantasy > 100 and plain_ok and _find("Randomize") != null and _find("Plain villager") != null,
		"Randomize rolls any look (%d of 200 beyond an ordinary human); Plain villager an ordinary one" % fantasy)
	_press("Randomize")
	check(ui.is_open("creation") and _find("Preview") != null, "Randomize redraws the creator")
	# 4. modal behaviour (7D): no HUD behind the creator, the dimmer over the HUD takes stray touches
	check(ui.is_open("creation") and not ui.hud.visible and ui.dimmer.visible and ui.dimmer.mouse_filter == Control.MOUSE_FILTER_STOP,
		"while creating: the HUD is hidden and the dimmer covers the screen and takes touches")
	check(ui.dimmer.get_index() > ui.hud_root.get_index() and ui.dimmer.get_index() < ui.root.get_index(),
		"the dimmer lies over the HUD and under the window")

	# 5. Begin: the look is the player's sprite in play; nothing else differs from a plain character
	var wild: Dictionary = base.duplicate(true)
	wild.picks.race = "human"
	wild.picks["ears-&-horns"] = "goat-horns-2"
	wild.picks.jaw = "jaw"
	wild.picks["facial-hair"] = "beard2"
	CharacterLook.set_swatch(wild, "skin", 13)
	CharacterLook.set_swatch(wild, "hair", 16)
	CharacterLook.set_swatch(wild, "eyes", 14)
	CharacterLook.set_swatch(wild, "clothes", 8)
	ui.show_creation({"name": "Ada", "family": "Thorne", "sex": "female", "appearance": wild})
	_press("Begin")
	var w: World = main.world
	var p: PlayerState = w.player
	check(w != null and p.appearance == wild and p.sex == "female", "Begin starts Ada with her horned, grey-skinned look")
	check(main.player_sprite.texture == CharacterLook.texture(wild, [p.armor, p.head]), "the look is the player's sprite in play")
	check(ui.is_open("origin") and not ui.hud.visible and ui.dimmer.visible, "the origin story: no HUD behind it, dimmed world")
	var story := _texts(ui.panel_body)
	check(story.contains("You worked another family's farm three valleys over until the harvest failed and the farmer could no longer feed you. There were hard words, and you left before dawn.")
		and story.contains("You carry what you could: a rusty sword that was your father's, a pickaxe nobody wanted, an axe as rusty, a loaf of bread, an apple going soft, two linen bandages and %d coins." % int(GameData.b("start_coins_player")))
		and story.contains("This is the first village you have seen with smoke in its chimneys. A hundred people live here, and every one of them has their own work and their own worries. None of them owes you anything.")
		and story.contains("Find a way to live.") and _find("Figure") != null, "the origin's words are unchanged, beside the character's figure")
	var kit := _kit(p)
	_press("Begin")
	check(not ui.modal() and ui.hud.visible and not ui.dimmer.visible and not main.paused, "Begin: into the village, the HUD back, nothing dimmed")
	# the same start with the plainest look: the same kit, gear, coins and skills
	main.new_game({"name": "Bob", "family": "Plain", "sex": "female", "appearance": base})
	var plain_kit := _kit(main.world.player)
	check(kit == plain_kit, "the look grants nothing: the same kit, gear, coins, skills and health as a plain look")
	ui.hide_all()
	main.resume_after_origin()
	main.new_game({"name": "Ada", "family": "Thorne", "sex": "female", "appearance": wild})
	ui.hide_all()
	main.resume_after_origin()
	w = main.world
	p = w.player

	# 6. saved and loaded; an older save (before the new layers) loads and draws as it did
	var map: VillageMap = w.map
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(map, d)
	check(w2.player.appearance == wild and CharacterLook.player_sheet(w2.player) == CharacterLook.texture(wild, [p.armor, p.head]),
		"the look comes back from the save and draws the same")
	w2.dispose()
	check(main.save_game(false), "the game saves")
	main.continue_game()
	check(main.world.player.appearance == wild and main.player_sprite.texture == CharacterLook.texture(wild, [main.world.player.armor, main.world.player.head]),
		"saved and loaded through the game: the player is drawn with the chosen look")
	map = main.world.map
	var old: Dictionary = JSON.parse_string(JSON.stringify(main.world.to_dict()))
	var old_look: Dictionary = {"picks": {"race": "human", "hair": "f2", "facial-hair": "", "eyelashes": "f1", "clothes": "tunic", "shoes": "leather-boots"},
		"swatches": {"skin": 3, "hair": 1, "facial_hair": 1, "eyes": 8, "tunic": 2, "leather_shoes": 0}}
	old.player.appearance = old_look.duplicate(true)       # as Build 25 saved it: no ears, horns or jaw keys
	old.player.heir_appearance = old_look.duplicate(true)
	check(SaveStore.inspect_text(JSON.stringify(old), World.SAVE_VERSION).state == "ok", "a save from before B25R1 is read")
	var w3 := World.new()
	w3.load_dict(map, old)
	var before := CharacterLook.render(CharacterLook.apply_worn(old_look, [w3.player.armor, w3.player.head]))
	var after := (CharacterLook.player_sheet(w3.player) as Texture2D).get_image()
	check(w3.player.appearance.picks["ears-&-horns"] == "" and w3.player.appearance.picks.jaw == "" and after.get_data() == before.get_data(),
		"its look gains no ears, horns or jaw and draws pixel for pixel as before")
	w3.dispose()

	# 7. optional: a contact sheet of looks to look at
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_contact(args[0], base)
	print("char_create_test: %d failures" % failures)
	quit(1 if failures > 0 else 0)


func _kit(p: PlayerState) -> String:
	var d := p.to_dict()
	var keep := {}
	for k in ["inv", "coins", "hp", "max_hp", "hunger", "stamina", "skills", "weapon", "armor", "tool", "head", "amulet", "ring", "spells", "pack_level", "chest"]:
		keep[k] = d[k]
	return JSON.stringify(keep, "", true)


func _texts(node: Node) -> String:
	return "\n".join(node.find_children("*", "", true, false).filter(func(c): return c is Label or c is Button).map(func(c): return c.text))


## "" when the recipe draws every frame play uses in every direction, with the layer `layer` (its option `opt`) drawn on
## or beside the body (its pixels within 3 px of the body's) wherever the layer has pixels; else why not.
func _draws(r: Dictionary, layer: String, opt: String) -> String:
	var img := CharacterLook.render(r)
	var st := CharacterLook.style()
	var lay_img: Image = (load(str(st.layers[layer][opt].sheet)) as Texture2D).get_image()
	var body_img: Image = (load(str(st.layers.race[str(r.picks.race)].sheet)) as Texture2D).get_image()
	var layer_frames := 0
	for anim in PLAY_ANIMS:
		for col in ActorSprite.ANIMS[anim][0]:
			for d in 8:
				var cell := Rect2i(int(col) * 32, d * 32, 32, 32)
				if img.get_region(cell).get_used_rect().size == Vector2i.ZERO:
					return "nothing drawn in %s frame %d direction %d" % [anim, col, d]
				var lr := lay_img.get_region(cell).get_used_rect()
				if lr.size == Vector2i.ZERO:
					continue
				layer_frames += 1
				var br := body_img.get_region(cell).get_used_rect()
				if not br.grow(3).intersects(lr):
					return "%s frame %d direction %d off the body (%s vs %s)" % [anim, col, d, lr, br]
	return "" if layer_frames > 0 else "the layer draws in no frame play uses"


func _contact(path: String, base: Dictionary) -> void:
	var looks := []
	for spec in [["human", "elven-ears", 8, 4], ["cyclops", "", 12, 7], ["skeleton", "skeleton-big-horns", 0, 2], ["human", "goat-horns-1", 13, 16],
			["human", "cat-ears-1", 17, 18], ["human", "antlers", 15, 12], ["cyclops", "unicorn-horn", 7, 19], ["human", "bunny-ears-2", 19, 9]]:
		var r: Dictionary = base.duplicate(true)
		r.picks.race = spec[0]
		r.picks["ears-&-horns"] = spec[1]
		CharacterLook.set_swatch(r, "skin", spec[2])
		CharacterLook.set_swatch(r, "hair", spec[3])
		if spec[0] == "skeleton":
			CharacterLook.set_swatch(r, "skeleton", spec[3])
		looks.append(r)
	var cols := []
	for anim in ["idle", "walk", "sword", "work", "swing", "gather", "carry"]:
		for c in ActorSprite.ANIMS[anim][0]:
			cols.append(int(c))
	var dirs := [0, 2, 4, 6]
	var k := 3
	var out := Image.create(cols.size() * 32 * k, looks.size() * dirs.size() * 32 * k, false, Image.FORMAT_RGBA8)
	out.fill(Color8(70, 96, 58))
	for i in looks.size():
		var sheet := CharacterLook.render(looks[i])
		for j in dirs.size():
			for c in cols.size():
				var f := sheet.get_region(Rect2i(int(cols[c]) * 32, int(dirs[j]) * 32, 32, 32))
				f.resize(32 * k, 32 * k, Image.INTERPOLATE_NEAREST)
				out.blend_rect(f, Rect2i(0, 0, 32 * k, 32 * k), Vector2i(c * 32 * k, (i * dirs.size() + j) * 32 * k))
	out.save_png(path)
	print("     contact sheet: ", path)
