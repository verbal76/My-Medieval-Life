extends SceneTree
## CC-01 (Build 18): the player's look drawn at run time from a recipe (CharacterLook). Checks that a recipe draws
## exactly the sheet the importer baked from it (tools/puny_chargen.py, pixel for pixel), the cost of drawing one,
## creation's limits, the recipe in the save, the migration of a version 17 save (a look id and its sheet) to
## the equivalent recipe, the heir's look, and the empty equipment hook. Run headless:
##   godot --headless --path game --script res://tests/character_look_test.gd

var failures := 0


func check(cond: bool, what: String) -> void:
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	var looks: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/appearances.json")).looks
	var st := CharacterLook.style()
	check(st.format == "mml-character-style/1" and st.worn_layers.is_empty(), "the style is read; nothing worn changes the look yet")

	# 1. the same sheet as the importer's generator: every Build 7-17 look, drawn from its recipe
	var same := 0
	for l in looks:
		var mine := CharacterLook.render(CharacterLook.normalize(l.recipe))
		var baked: Image = (load(l.sprite) as Texture2D).get_image()
		baked.convert(Image.FORMAT_RGBA8)
		if mine.get_size() == baked.get_size() and _seen(mine) == _seen(baked):
			same += 1
		else:
			print("     differs: ", l.id)
	check(same == looks.size(), "all %d baked looks are drawn pixel for pixel from their recipes (%d match)" % [looks.size(), same])

	# 2. the cost: drawing time cold (layers read) and warm, and the texture's memory
	CharacterLook.clear_cache()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var r1 := CharacterLook.random_recipe(rng, "male")
	r1.picks.hair = "m5"
	r1.picks["facial-hair"] = "beard1"
	r1.picks.shoes = "leather-boots"
	r1.picks.eyelashes = "m1"
	var t0 := Time.get_ticks_usec()
	var img := CharacterLook.render(r1)
	var cold := Time.get_ticks_usec() - t0
	t0 = Time.get_ticks_usec()
	CharacterLook.render(r1)
	var warm := Time.get_ticks_usec() - t0
	var bytes := img.get_data().size()
	print("     cost: cold %.1f ms (reading 8 layer sheets), warm %.1f ms; one sheet %dx%d RGBA8 = %d bytes (%.0f KB) of texture"
		% [cold / 1000.0, warm / 1000.0, img.get_width(), img.get_height(), bytes, bytes / 1024.0])
	var sparse_bytes := 0
	for k in CharacterLook._sparse:
		sparse_bytes += (CharacterLook._sparse[k][0] as PackedInt32Array).size() * 8
	print("     layer pixels kept for redrawing: %d bytes (%.0f KB) for %d sheets" % [sparse_bytes, sparse_bytes / 1024.0, CharacterLook._sparse.size()])
	check(img.get_width() == 928 and img.get_height() == 256 and bytes == 928 * 256 * 4, "one 928 x 256 sheet, as ActorSprite draws")
	var tex := CharacterLook.texture(r1)
	check(CharacterLook.texture(r1.duplicate(true)) == tex, "a recipe's sheet is composed once and reused")

	# 3. creation's limits: an ordinary villager, the same rolls for the same seed
	var allowed: Dictionary = st.creation.picks
	var ok := true
	var seen_none_hair := false
	for i in 300:
		rng.seed = i
		var r := CharacterLook.random_recipe(rng, "female" if i % 2 else "male")
		for layer in r.picks:
			var opts := CharacterLook.options(layer)
			if not opts.has(r.picks[layer]):
				ok = false
		for sel in st.creation.swatches:
			if not CharacterLook.rows(sel).has(int(r.swatches[sel])):
				ok = false
		if i % 2 and r.picks["facial-hair"] != "":
			ok = false
		if r.swatches.facial_hair != r.swatches.hair:
			ok = false
		seen_none_hair = seen_none_hair or r.picks.hair == ""
	check(ok and seen_none_hair, "300 random looks stay within creation's choices (no beard on a woman; a beard the hair's colour)")
	check(not allowed.has("headwear") and not allowed.has("gloves") and not allowed.has("ears-&-horns") and allowed.race == ["human"]
		and allowed.clothes == ["basic", "tunic"] and not (CharacterLook.options("shoes") as Array).has("metal-boots"),
		"no headwear, gloves, horns, armour or metal boots; human only")
	check(CharacterLook.rows("skin") == [0, 1, 2, 3, 4, 5, 6] and CharacterLook.rows("hair") == [0, 1, 2, 3, 4] and CharacterLook.options("hair").size() == 14,
		"natural skin (7) and hair colours (5); 13 hair styles and none")
	rng.seed = 42
	var a := CharacterLook.random_recipe(rng)
	rng.seed = 42
	check(CharacterLook.random_recipe(rng) == a, "the same seed rolls the same look")

	# 4. the recipe is saved and loaded
	var map := VillageMap.load_default()
	var w := World.new()
	w.setup(map, 1)
	var p := w.player
	p.appearance = CharacterLook.normalize(r1)
	p.heir_appearance = CharacterLook.normalize(a)
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	check(int(d.save_version) == World.SAVE_VERSION and World.SAVE_VERSION >= 18 and d.player.has("appearance"), "the save is the current version (18 or later) and holds the appearance")
	var w2 := World.new()
	w2.load_dict(map, d)
	check(w2.player.appearance == p.appearance and w2.player.heir_appearance == p.heir_appearance, "the look and the heir's look come back from the save")
	check(CharacterLook.player_sheet(w2.player) == CharacterLook.texture(p.appearance, [p.armor, p.head]), "the loaded player is drawn from the recipe")
	w2.dispose()

	# 5. a version 17 save (fixture: as Build 17 wrote it, the look's id and baked sheets) migrates
	var look: Dictionary = looks.filter(func(l): return l.id == "player_f2_tunic")[0]
	var other: Dictionary = looks[0]
	var old := _v17_save(w, look.id, look.sprite, other.sprite)
	check(SaveStore.inspect_text(JSON.stringify(old), World.SAVE_VERSION).state == "ok", "a version 17 save is still read")
	var w3 := World.new()
	w3.load_dict(map, old)
	check(w3.player.appearance == CharacterLook.normalize(look.recipe), "its look (%s) becomes the recipe it was baked from" % look.id)
	check(w3.player.heir_appearance == CharacterLook.normalize(other.recipe), "its heir's sheet becomes that look's recipe")
	var drawn := (CharacterLook.player_sheet(w3.player) as Texture2D).get_image()
	var was: Image = (load(look.sprite) as Texture2D).get_image()
	was.convert(Image.FORMAT_RGBA8)
	check(_seen(drawn) == _seen(was), "the migrated player looks exactly as before")
	var back: Dictionary = JSON.parse_string(JSON.stringify(w3.to_dict()))
	check(int(back.save_version) == World.SAVE_VERSION and CharacterLook.normalize(back.player.appearance) == w3.player.appearance, "saved again as the current version with the recipe")
	w3.dispose()
	var m := SaveTransfer.migrate(old, map)
	check(m.ok and m.data.player.appearance == CharacterLook.normalize(look.recipe), "an imported version 17 save migrates the same way (%s)" % m.get("reason", ""))
	# a player who was a villager's child (drawn from a villager's sheet) keeps that sheet
	var kid := _v17_save(w, "", "res://assets/characters/villager_03.png", look.sprite)
	var w4 := World.new()
	w4.load_dict(map, kid)
	check(w4.player.appearance.is_empty() and w4.player.sprite.ends_with("villager_03.png")
		and CharacterLook.player_sheet(w4.player) == load("res://assets/characters/villager_03.png"), "a child heir's villager sheet stays as it was")
	check(w4.player.heir_appearance == CharacterLook.normalize(look.recipe), "and the relative's look still migrates")
	w4.dispose()

	# 6. the heir: a relative takes the heir look, and the next one the player's
	p.alive = false
	w.continue_as_heir()
	check(w.player.appearance == CharacterLook.normalize(a) and w.player.heir_appearance == CharacterLook.normalize(r1), "a relative heir takes the heir's look; the next heir the first look")
	w.dispose()

	# 7. the equipment hook: a worn item's layer drawn over, or hiding, others (no item has one yet)
	st.worn_layers["test_hood"] = {"hides": ["hair"], "layer": "shoes", "option": "leather-boots", "swatches": {"leather_shoes": 1}}
	var worn := CharacterLook.apply_worn(r1, ["test_hood", "plain_clothes"])
	check(worn.picks.hair == "" and worn.picks.shoes == "leather-boots" and worn.swatches.leather_shoes == 1 and r1.picks.hair == "m5", "a worn item's entry hides and adds layers without touching the recipe")
	st.worn_layers.erase("test_hood")
	check(CharacterLook.apply_worn(r1, ["plain_clothes", "iron_helmet"]) == {"picks": r1.picks, "swatches": r1.swatches}, "with no entries, worn items change nothing")

	print("character_look_test: %d failure(s)" % failures)
	quit(1 if failures else 0)


## An RGBA8 image's pixels as seen: fully transparent pixels all alike (Godot's import gives the transparent
## pixels of a baked sheet the colour of their neighbours, fix_alpha_border; they are never drawn).
func _seen(img: Image) -> PackedInt32Array:
	var a := img.get_data().to_int32_array()
	for i in a.size():
		if a[i] & 0xFF000000 == 0:
			a[i] = 0
	return a


## A save as save_version 17 wrote it (fixture builder): the current save less CC-01's keys, the player holding
## a look id and baked sheets.
func _v17_save(w: World, look: String, sprite: String, heir_sprite: String) -> Dictionary:
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	d.save_version = 17
	d.format = "mml-save/17"
	d.player.erase("appearance")
	d.player.erase("heir_appearance")
	d.player.look = look
	d.player.sprite = sprite
	d.player.heir_sprite = heir_sprite
	return d
