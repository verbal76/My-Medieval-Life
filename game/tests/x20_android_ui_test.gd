extends SceneTree
## Expansion 20, batch X20-B2 (owner, 2026-10-24, docs/directives/2026-10-24_expansion20_open_items_reconciliation.md
## sections 3 and 4), in the real game scene on a pretend phone:
##   - GP-ANDROID-RECENTER: after looking away, Recenter draws the player at the centre of the area the status box and the
##     touch columns leave clear, never under them, at 20:9, 16:9 and 16:10 and at several zooms;
##   - GP-ANDROID-HUD-SCALE: the status box about 15% smaller than Build 22's 204 x 152, every value still shown;
##   - GP-ANDROID-ACTION-BUTTONS: the nine buttons in their two columns and order, each a disc behind its own glyph with its
##     caption, a comfortable target, closer to the right edge than before;
##   - GP-ANDROID-USE-TALK-TARGETING: Use takes the station before a villager beside it, Talk the villager; Next / Q cycle;
##   - GP-INTERACTABLE-OUTLINES: the things on offer glow, the chosen one brightest, by their silhouettes; never a person,
##     a theft or a refused station, never with a window open, at most six;
##   - GP-INTERACTION-PROMPT-LIFECYCLE: the prompt shows for the chosen target, goes while its window is open and the work
##     runs, stays down after, and comes back when the thing is chosen again; the work's bar still says "Crafting".
##   - GP-MESSAGE-FOOTPRINT (owner, 2026-10-26): the message a small box at the top edge, the prompt a slim line at the
##     bottom edge with a small "2/3" Next, both out of the middle of the play area at 20:9, 16:9 and 16:10; the message
##     tapped away or gone after its time, and kept on the journal's Messages page.
##   godot --headless --path game --script res://tests/x20_android_ui_test.gd

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
	main.save_path = "user://test_saves/x20_android_ui_test/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func frames(n := 3) -> void:
	for i in n:
		await process_frame


func _run() -> void:
	main.new_game()
	main.ui.hide_all()
	main.ui.toast.visible = false
	main.settings.phone = true
	main.scheme = "touch"
	main.ui.set_scheme("touch")
	main.ui.fit_safe_area()
	await frames()
	await _recenter()
	_hud_scale()
	await _buttons()
	await _targeting()
	await _outlines()
	await _prompt_lifecycle()
	_refused_station()
	await _message_footprint()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ---------------------------------------------------------------- GP-ANDROID-RECENTER ----------
func _recenter() -> void:
	var ui = main.ui
	check(GameUI.clear_centre(Rect2(0, 0, 100, 50), []) == Vector2(50, 25), "with no HUD the play centre is the screen's centre")
	var c := GameUI.clear_centre(Rect2(0, 0, 100, 50), [Rect2(80, 0, 20, 50)])
	check(c.is_equal_approx(Vector2(40, 25)), "a full-height column at the right moves the centre to the middle of what is left (%s)" % c)
	var p: PlayerState = main.world.player
	main.paused = true
	for sz in [Vector2i(1001, 450), Vector2i(800, 450), Vector2i(720, 450)]:
		get_root().content_scale_size = sz
		ui.fit_safe_area()
		await frames()
		for z in [2.0, 4.0, 8.0]:
			main.camera.zoom = Vector2(z, z) * main.view_scale
			main.camera.position_smoothing_enabled = false
			main.pan_camera(Vector2(300, -120))
			main._sync_sprites()
			main.recenter()
			main.camera.position_smoothing_enabled = false
			main._sync_sprites()
			await frames(2)
			var at: Vector2 = main.player_sprite.get_global_transform_with_canvas().origin
			var want: Vector2 = ui.play_centre()
			var sb: Rect2 = ui.status_box.get_global_rect()
			var tb: Rect2 = ui.touch_bar.get_global_rect()
			check(at.distance_to(want) < 1.5 and not sb.has_point(at) and not tb.has_point(at) and not main.cam_free,
				"%s zoom %d: Recenter draws the player at the play centre %s (at %s), clear of the status box %s and the buttons %s" % [sz, int(z), want, at, sb, tb])
			check(at.x < sz.x / 2.0, "%s zoom %d: on a phone the player stands left of the screen's middle, away from the buttons" % [sz, int(z)])
	# the dead zone still lets the player walk off the point before the camera follows (following unchanged)
	main.camera.zoom = Vector2(4, 4) * main.view_scale
	main.recenter()
	main._sync_sprites()
	var cam0: Vector2 = main.camera.position
	p.pos += Vector2(0.2, 0)
	main._sync_sprites()
	check(main.camera.position == cam0, "a small step inside the dead zone leaves the camera where it was (following unchanged)")
	p.pos -= Vector2(0.2, 0)
	get_root().content_scale_size = Vector2i(1001, 450)
	ui.fit_safe_area()
	await frames()
	main.paused = false


# ---------------------------------------------------------------- GP-ANDROID-HUD-SCALE ---------
func _hud_scale() -> void:
	var ui = main.ui
	var s: Vector2 = ui.status_box.size
	check(s.x <= 204.0 * 0.88 and s.x >= 204.0 * 0.78 and s.y <= 152.0 * 0.88 and s.y >= 152.0 * 0.75,
		"the status box is about 15%% smaller than Build 22's 204 x 152: %s (%.0f%% x %.0f%%)" % [s, s.x / 2.04, s.y / 1.52])
	var shown := true
	for k in ["hp", "hunger", "stamina"]:
		shown = shown and ui.bar_labels[k].text.contains("/") and ui.bar_labels[k].get_theme_font_size("font_size") >= 13 \
			and ui.bars[k].size.x >= 120.0
	check(shown and ui.coins_label.text.strip_edges() != "" and ui.clock_label.text.contains(":") and ui.date_label.text.contains("Year"),
		"every value is still there: the three bars' numbers at 13 points, coins, the time and the date")
	check(ui.coins_label.get_theme_font_size("font_size") >= 15 and ui.date_label.get_theme_font_size("font_size") >= 13, "coins and the clock at 15 points, the date at 13")


# ---------------------------------------------------------------- GP-ANDROID-ACTION-BUTTONS ----
func _buttons() -> void:
	var ui = main.ui
	await frames()
	var names: Array = ui.touch_columns.map(func(c): return c.get_children().map(func(b): return str(b.text).trim_suffix(" ON").trim_suffix(" OFF")))
	check(names == [["Run", "Gather", "Fire", "Skills", "Menu"], ["Use", "Attack", "Pack", "Map"]], "the same nine actions in the same two columns and order: %s" % [names])
	var icons := {"Run": "stamina", "Gather": "gather", "Fire": "fire", "Skills": "skills", "Menu": "menu", "Use": "use", "Attack": "attack", "Pack": "pack", "Map": "map"}
	var bad := []
	for b: Button in ui.touch_buttons():
		var nm := str(b.text).trim_suffix(" ON").trim_suffix(" OFF")
		var disc: Control = b.get_node_or_null("Disc")
		var r := b.get_global_rect()
		var glyph := r.size.y - (GameUI.TOUCH_TOP + (GameUI.TOUCH_DISC - GameUI.TOUCH_ICON) / 2.0) - GameUI.TOUCH_CAPTION_H
		if b.icon == null or not b.icon.resource_path.ends_with("/%s.png" % icons[nm]) or disc == null or not disc.show_behind_parent \
				or r.size.x < GameUI.TOUCH_BUTTON_W or r.size.y < GameUI.TOUCH_BUTTON_MIN_H or absf(glyph - GameUI.TOUCH_ICON) > 0.5 \
				or b.get_theme_stylebox("normal") is StyleBoxFlat:
			bad.append([nm, r, glyph])
	check(bad.is_empty(), "each button: its own glyph art in a %d-unit box on a disc behind it, no rectangle, at least %d x %d to touch %s" % [int(GameUI.TOUCH_ICON), int(GameUI.TOUCH_BUTTON_W), int(GameUI.TOUCH_BUTTON_MIN_H), bad])
	check(GameUI.TOUCH_ICON == 40.0 and GameUI.TOUCH_DISC > GameUI.TOUCH_ICON and GameUI.TOUCH_DISC < 72.0, "the glyph keeps Build 21's 40-unit box; the disc only a rim round it (%d)" % int(GameUI.TOUCH_DISC))
	var view: Vector2 = main.get_viewport().get_visible_rect().size
	var tb: Rect2 = ui.touch_bar.get_global_rect()
	check(absf(view.x - tb.end.x - GameUI.TOUCH_EDGE) < 1.0 and GameUI.TOUCH_EDGE < GameUI.HUD_MARGIN.phone, "the columns stand %d units from the right edge (were %d)" % [int(GameUI.TOUCH_EDGE), int(GameUI.HUD_MARGIN.phone)])
	check(tb.size.x < 215.0 - 40.0, "the two columns take %d units of width (were 203 plus the margin)" % int(tb.size.x))
	var overlap := 0
	var all: Array = ui.touch_buttons()
	for i in all.size():
		for j in range(i + 1, all.size()):
			if (all[i].get_global_rect() as Rect2).grow(-0.5).intersects(all[j].get_global_rect()):
				overlap += 1
	check(overlap == 0, "no two buttons overlap")
	main.gather_button()
	var gd: GameUI.TouchDisc = ui.gather_btn.get_node("Disc")
	check(gd.on and ui.gather_btn.text == "Gather ON", "Gather on: its disc lit gold, its caption Gather ON")
	main.gather_button()
	check(not gd.on and ui.gather_btn.text == "Gather OFF", "Gather off again")
	ui.message("")
	ui.toast.visible = false


# ---------------------------------------------------------------- GP-ANDROID-USE-TALK-TARGETING
var anvil := ""


func _at_anvil(with_villager: bool) -> NPC:
	var w: World = main.world
	anvil = w.stations_of("anvil")[0]
	var st: Dictionary = w.stations[anvil]
	var p := w.player
	p.pos = Vector2(int(st.use[0]) + 0.5, int(st.use[1]) + 0.5)
	main.player_sprite.face(Vector2(int(st.at[0]) + 0.5, int(st.at[1]) + 0.5) - p.pos)
	var by: NPC = w.npcs.filter(func(n): return n.alive and n.role == "adult" and n.job != "smith" and n.job != "guard")[0]
	by.plan = [w.brain.work(600, "", {}, "idle")]
	by.anim = "idle"
	by.pos = p.pos + (main.facing_vec() * 0.8 if with_villager else Vector2(30, 0))
	main.target_pref = ""
	main.prompt_done = ""
	main._find_target()
	return by


func _targeting() -> void:
	var ui = main.ui
	main.paused = true
	var by := _at_anvil(true)
	var kinds: Array = main.target_options.map(func(t): return str(t.kind))
	check(kinds.has("station") and kinds.has("npc"), "the anvil and the villager by it are both on offer: %s" % [kinds])
	check(str(main.target.get("kind", "")) == "station" and main.talk_alt.get("npc") == by, "Use takes the anvil, not the villager in front of it; Talk is the villager")
	check(ui.prompt_text.begins_with("Use the anvil") and ui.prompt_text.contains("Tap them: Talk to"), "the prompt names the anvil and how to talk to the villager: \"%s\"" % ui.prompt_text.replace("\n", " | "))
	check(ui.prompt_next.visible, "on a touch screen the prompt has a Next button")
	check(ui.blocks(ui.prompt_next.get_global_rect().get_center()), "a tap on Next is the interface's, not a walk")
	ui.prompt_next.pressed.emit()
	check(str(main.target.get("kind", "")) == "npc", "Next chooses the villager")
	main._find_target()
	check(str(main.target.get("kind", "")) == "npc", "and the choice holds")
	ui.prompt_next.pressed.emit()
	check(str(main.target.get("kind", "")) == "station", "Next again: back to the anvil")
	main.interact()
	check(ui.is_open("craft"), "Use opens the anvil's window, with the villager beside it")
	ui.hide_all()
	# Talk prefers people: T with the anvil chosen talks to the villager
	main.scheme = "kbm"
	ui.set_scheme("kbm")
	main.cycle_target(1)                  # chosen again (Q there and back): its prompt is back after the window (lifecycle)
	main.cycle_target(-1)
	main._find_target()
	check(not ui.prompt_next.visible and ui.prompt_text.contains("T: Talk to"), "with keys no Next button; the prompt says T to talk")
	main.prompt_done = ""
	Input.action_press("talk")
	main._player_step(0.016)
	Input.action_release("talk")
	check(ui.is_open("talk") or ui.is_open("trade"), "T talks to the villager while Use stays on the anvil")
	ui.hide_all()
	await frames()                        # the key's "just pressed" lasts until the next frame (it may talk again there)
	ui.hide_all()
	# with only people in reach, Use still talks to the nearest (unchanged)
	var base: Vector2 = main.world.player.pos
	for off in [Vector2(0, 6), Vector2(6, 6), Vector2(-6, 6), Vector2(0, 9), Vector2(8, 0), Vector2(-8, 0), Vector2(0, 12), Vector2(10, 10)]:
		main.world.player.pos = base + off
		by.pos = main.world.player.pos + main.facing_vec() * 0.8
		main.target_pref = ""
		main._find_target()
		if main.target_options.all(func(t): return str(t.kind) in ["npc", "shop"]):
			break
	check(main.target_options.size() >= 1 and main.target_options.all(func(t): return str(t.kind) in ["npc", "shop"]), "a spot with only the villager in reach: %s" % [main.target_options.map(func(t): return str(t.kind))])
	check(str(main.target.kind) in ["npc", "shop"] and main.talk_alt.is_empty(), "with only a villager in reach Use talks to them, as before")
	# reach unchanged: far from the anvil it is not offered
	check(not main.target_options.any(func(t): return str(t.get("kind", "")) == "station" and str(t.get("id", "")) == anvil), "out of the anvil's reach it is not offered (reach unchanged)")
	# use_order: things before characters, each in its order; all-character or all-thing lists unchanged
	var a := {"kind": "npc", "label": "a"}
	var b := {"kind": "station", "label": "b"}
	var c := {"kind": "animal", "label": "c"}
	var d := {"kind": "chest", "label": "d"}
	check(main.use_order([a, b, c, d]) == [b, d, a, c] and main.use_order([a, c]) == [a, c] and main.use_order([b, d]) == [b, d], "use_order: things first, then people and animals, each in its order")
	main.scheme = "touch"
	ui.set_scheme("touch")


# ---------------------------------------------------------------- GP-INTERACTABLE-OUTLINES -----
func _outlines() -> void:
	var ui = main.ui
	_at_anvil(true)
	main._sync_outlines()
	var to: TargetOutline = main.target_outline
	var drawn: Array = to.shown
	var st: Dictionary = main.world.stations[anvil]
	var anvil_cell := Vector2i(int(st.at[0]), int(st.at[1]))
	check(drawn.size() == 1 and drawn[0][0] == [anvil_cell] and drawn[0][1], "the anvil glows, brightly (chosen); the villager does not: %s" % [drawn])
	check(to.sprites[0].visible and to.sprites[0].modulate.a >= 0.7 and to.sprites[0].modulate.a > TargetOutline.NEAR.a + 0.15, "the chosen glow is bright (alpha %.2f, breathing between 0.7 and 1)" % to.sprites[0].modulate.a)
	main.cycle_target(1)
	main._sync_outlines()
	check(to.shown.size() == 1 and not to.shown[0][1] and absf(to.sprites[0].modulate.a - TargetOutline.NEAR.a) < 0.01, "the villager chosen: the anvil's glow goes faint, not away")
	main.cycle_target(1)
	# the silhouette, not the tile: an oven's outline follows its round body and chimney
	var oven: String = main.world.stations_of("oven")[0]
	var ov: Dictionary = main.world.stations[oven]
	var o := to.outline_of([Vector2i(int(ov.at[0]), int(ov.at[1]))])
	var img: Image = o.tex.get_image()
	var ring := 0
	var corner_gap := 0
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.9:
				ring += 1
	# a tile's square outline would put solid glow on every pixel round the cell's 16 x 16 square; the oven's round body
	# leaves the square's corners clear
	var cell_origin := Vector2i((Vector2(Vector2i(int(ov.at[0]), int(ov.at[1])) * 16) - o.origin).round())
	for corner in [Vector2i(-1, -1), Vector2i(16, -1), Vector2i(-1, 16), Vector2i(16, 16)]:
		var q: Vector2i = cell_origin + corner
		if q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height() and img.get_pixel(q.x, q.y).a < 0.5:
			corner_gap += 1
	check(ring > 40 and corner_gap >= 2, "the oven's glow follows its drawn shape (%d glow pixels; %d of the tile square's corners clear)" % [ring, corner_gap])
	var again := to.outline_of([Vector2i(int(ov.at[0]), int(ov.at[1]))])
	check(again.tex == o.tex, "a shape is built once and cached")
	# not drawn: with a window open; a theft; a station refused; at most MAX_SHOWN
	main.interact()
	main._sync_outlines()
	check(ui.modal() and to.shown.is_empty(), "with a window open nothing glows")
	ui.hide_all()
	check(main.outline_cells({"kind": "container", "c": {"x": 1, "y": 1}, "theft": true}).is_empty(), "a theft never glows")
	check(main.outline_cells({"kind": "npc"}).is_empty() and main.outline_cells({"kind": "info", "label": "x"}).is_empty(), "people and mere information never glow")
	var many: Array = []
	for i in 9:
		many.append([[Vector2i(int(st.at[0]), int(st.at[1]))], i == 0])
	to.show_items(many)
	check(to.shown.size() == TargetOutline.MAX_SHOWN and to.get_child_count() <= TargetOutline.MAX_SHOWN, "at most %d outlines at once (%d sprites)" % [TargetOutline.MAX_SHOWN, to.get_child_count()])
	main._sync_outlines()


# ---------------------------------------------------------------- GP-INTERACTION-PROMPT-LIFECYCLE
func _prompt_lifecycle() -> void:
	var ui = main.ui
	var w: World = main.world
	var saw: String = w.stations_of("sawhorse")[0]
	var st: Dictionary = w.stations[saw]
	var p := w.player
	p.pos = Vector2(int(st.use[0]) + 0.5, int(st.use[1]) + 0.5)
	main.player_sprite.face(Vector2(int(st.at[0]) + 0.5, int(st.at[1]) + 0.5) - p.pos)
	var by: NPC = w.npcs.filter(func(n): return n.alive and n.role == "adult" and n.job != "guard")[0]
	by.plan = [w.brain.work(600, "", {}, "idle")]
	by.anim = "idle"
	by.pos = p.pos + main.facing_vec() * 0.8
	main.target_pref = ""
	main.prompt_done = ""
	main.walking = false
	main._find_target()
	check(str(main.target.get("kind", "")) == "station" and ui.prompt_box.visible and ui.prompt_text.begins_with("Use the sawhorse"), "a valid target chosen: its prompt shows (\"%s\")" % ui.prompt_text.replace("\n", " | "))
	main.interact()
	check(ui.is_open("craft") and not ui.prompt_box.visible, "its window open: the prompt is down")
	main._player_step(0.016)
	check(not ui.prompt_box.visible, "and stays down while the window is open")
	p.inv.add("log", 4)
	var recipe := ""
	for id in GameData.recipes:
		if str(GameData.recipes[id].get("station", "")) == "sawhorse":
			recipe = id
			break
	main.craft(recipe)
	check(not main.action.is_empty() and str(main.action.label) == "Crafting", "crafting: the work runs")
	main._player_step(0.016)
	ui.update_hud()
	check(not ui.prompt_box.visible and ui.action_bar.visible and ui.action_label.text == "Crafting", "while it runs no prompt; the bar over the head says Crafting")
	var guard := 0
	while not main.action.is_empty() and guard < 2000:
		main._player_step(0.25)
		guard += 1
	main._player_step(0.016)
	check(main.action.is_empty() and str(main.target.get("kind", "")) == "station" and not ui.prompt_box.visible, "the work done, still beside the sawhorse: its prompt does not come back by itself (no stale prompt)")
	# chosen again: Next there and back (or Use again) brings it back
	by.pos = p.pos + main.facing_vec() * 0.8
	main._find_target()
	main.cycle_target(1)
	main.cycle_target(-1)
	main._find_target()
	check(ui.prompt_box.visible and ui.prompt_text.begins_with("Use the sawhorse"), "chosen again with Next: the prompt is back")
	# walking away clears the target and its mark; coming back shows the prompt again
	main.interact()
	ui.hide_all()
	main._player_step(0.016)
	check(not ui.prompt_box.visible and main.prompt_done != "", "used again: down again")
	p.pos += Vector2(0, 5)
	main._find_target()
	check(main.prompt_done == "" and (main.target.is_empty() or not ui.prompt_text.begins_with("Use the sawhorse")), "out of reach: the target goes, and with it the old prompt")
	p.pos -= Vector2(0, 5)
	main.player_sprite.face(Vector2(int(st.at[0]) + 0.5, int(st.at[1]) + 0.5) - p.pos)
	main._find_target()
	check(ui.prompt_box.visible and ui.prompt_text.begins_with("Use the sawhorse"), "back beside it: the prompt returns")
	# proximity is not an active interaction: standing there frame after frame keeps the prompt up
	for i in 5:
		main._player_step(0.05)
	check(ui.prompt_box.visible, "standing beside it does not hide the prompt")


## Last (it runs the village on for a while): a station a villager is working at does not glow.
func _refused_station() -> void:
	var refused := 0
	var wrong := 0
	var steps := 0                          # let the village go to work until a villager works at one of the stations
	while steps < 1200 and not main.world.stations.keys().any(func(sid): return str(main.world.stations[sid].type) in World.PLAYER_STATIONS and main.world.station_refusal(sid) != ""):
		main.world.player.hunger = 100.0
		main.world.update(0.5)
		steps += 1
	for sid in main.world.stations:
		if str(main.world.stations[sid].type) in World.PLAYER_STATIONS and main.world.station_refusal(sid) != "":
			refused += 1
			if not main.outline_cells(main._station_target(sid)).is_empty():
				wrong += 1
	check(refused > 0 and wrong == 0, "a station someone else is using (or not the player's to use) does not glow (%d such, after %d steps)" % [refused, steps])


# ---------------------------------------------------------------- GP-MESSAGE-FOOTPRINT ----------
func _message_footprint() -> void:
	var ui = main.ui
	ui.hide_all()
	main.paused = true                    # the prompts here are set by hand; the world does not choose its own meanwhile
	main.scheme = "touch"
	ui.set_scheme("touch")
	var opening := "%s %s, %s. %s" % [main.world.player.name, main.world.player.family, main.world.clock_text(), GameUI.OPENING_HINT]
	var three := [{"kind": "station", "label": "Use the oven"}, {"kind": "npc", "label": "Talk to Mabel Reed"}, {"kind": "npc", "label": "Talk to Hugh Reed"}]
	for sz in [Vector2i(1001, 450), Vector2i(800, 450), Vector2i(720, 450)]:
		get_root().content_scale_size = sz
		ui.fit_safe_area()
		await frames()
		ui.message(opening, 8.0, "game")
		main.target_options = three
		main.target = three[1]
		ui.prompt("Talk to Mabel Reed\nNext: Talk to Hugh Reed (3 of 3)", true)
		await frames(3)
		var view := Rect2(Vector2.ZERO, Vector2(sz))
		var t: Rect2 = ui.toast.get_global_rect()
		var pb: Rect2 = ui.prompt_box.get_global_rect()
		var sb: Rect2 = ui.status_box.get_global_rect()
		var tb: Rect2 = ui.touch_bar.get_global_rect()
		var mid := Rect2(view.size * Vector2(0.25, 0.3), view.size * Vector2(0.5, 0.4))     # the middle of the play area
		check(t.position.y < 30.0 and not t.intersects(sb) and not t.intersects(tb) and not t.intersects(mid) and t.end.y <= view.size.y * 0.25,
			"%s: the opening message is a small box at the top edge, in its top quarter (%s), clear of the status box, the buttons and the middle (was 460 x 94 mid-screen)" % [sz, t])
		check(ui.toast.get_theme_font_size("font_size") == GameUI.TOAST_FONT and GameUI.TOAST_FONT < 17, "%s: the message's words are smaller (%d points, were 17)" % [sz, GameUI.TOAST_FONT])
		check(view.size.y - pb.end.y < 30.0 and pb.size.y <= 48.0 and not pb.intersects(tb) and not pb.intersects(sb) and not pb.intersects(t) and not pb.intersects(mid),
			"%s: the prompt is one slim line at the bottom edge (%s), clear of the buttons, the status box, the message and the middle (was 2 lines, 61 high)" % [sz, pb])
		check(ui.prompt_label.text == "Talk to Mabel Reed" and ui.prompt_next.visible and ui.prompt_next.text.begins_with("2/3"),
			"%s: the prompt keeps its target, and Next says which of the three is chosen (\"%s\", \"%s\")" % [sz, ui.prompt_label.text, ui.prompt_next.text])
		check(ui.prompt_next.get_global_rect().size.y >= 40.0, "%s: Next is still a thumb's height (%s)" % [sz, ui.prompt_next.get_global_rect().size])
		var lb: Rect2 = ui.log_box.get_global_rect()
		check(lb.position.y >= t.end.y or lb.position.x >= t.end.x or lb.end.x <= t.position.x, "%s: the corner log steps below the message, not under it" % sz)
	# the talk line stays, on the same line
	main.target = three[0]
	ui.prompt("Use the oven\nTap them: Talk to Mabel Reed", true)
	check(ui.prompt_label.text.contains("Use the oven") and ui.prompt_label.text.contains("Talk to Mabel Reed") and not ui.prompt_label.text.contains("\n")
		and ui.prompt_next.text.begins_with("1/3") and ui.prompt_text.contains("\n"), "the talk line is kept on the prompt's one line: \"%s\" [%s]" % [ui.prompt_label.text, ui.prompt_next.text])
	main.target_options = []
	main.target = {}
	ui.prompt("")
	# a tap on the message puts it away, and is not a walk; its time up, it goes too
	var at: Vector2 = ui.toast.get_global_rect().get_center()
	check(ui.blocks(at), "a tap on the message is the interface's, not a walk")
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	tap.position = at
	ui.toast.gui_input.emit(tap)
	check(not ui.toast.visible, "a tap on the message puts it away")
	ui.message("A short one.", 4.0, "game")
	ui.toast_t = 0.0001
	await frames(2)
	check(not ui.toast.visible and ui.toast.modulate.a == 1.0, "its time up, the message goes")
	check(ui.log_push == 0.0, "the corner log is back at the top when no message shows")
	# every message is kept on the journal's Messages page
	var kept: Array = ui.game_messages()
	check(kept.any(func(l: String): return l.ends_with(opening)) and kept.any(func(l: String): return l.ends_with("A short one.")),
		"the messages are kept in the world's journal, stamped with the day and time (%d kept)" % kept.size())
	ui.show_journal(-1, false, true)
	var words := ""
	for l in ui.panel_body.find_children("*", "Label", true, false):
		words += (l as Label).text + "\n"
	check(ui.is_open("journal") and ui.title_label.text.to_lower() == "journal: messages" and words.contains("A short one.") and words.contains("Any work for me?"),
		"the journal's Messages page shows them (%s: %s)" % [ui.title_label.text, words.replace("\n", " | ")])
	var btns: Array = ui.panel_body.find_children("*", "Button", true, false).map(func(b): return (b as Button).text)
	check(btns.has("Village record") and btns.has("Quests") and btns.has("Resources"), "and leads to the other pages: %s" % [btns])
	ui.show_journal(-1)
	btns = ui.panel_body.find_children("*", "Button", true, false).map(func(b): return (b as Button).text)
	check(btns.has("Messages"), "the village record leads to the Messages page")
	ui.hide_all()
	get_root().content_scale_size = Vector2i(1001, 450)
	ui.fit_safe_area()
