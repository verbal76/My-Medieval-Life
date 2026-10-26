extends SceneTree
## Wiki (PL2-009) and Settings / menu flow (PL1-01, PL1-02): every item, recipe and resource node has
## a page (with its icon where one exists), links resolve, search finds the usual words, other
## systems can add pages, and opening Settings / Controls / Wiki and leaving by X, Esc or the pad's B
## restores the world, the HUD and input, from the title screen and from the pause menu. Run:
##   godot --headless --path game --script res://tests/wiki_test.gd

var main
var failures := 0


func check(cond: bool, what: String) -> void:
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://test_saves/wiki_test/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _key(code: int) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = true
	return e


func _pad(button: int) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	e.pressed = true
	return e


func _tab(name: String) -> void:
	main.ui.panel_body.find_child("SettingsTabs", true, false).get_node("Tab_" + name).pressed.emit()


func _find(text: String) -> Button:
	for b: Button in main.ui.panel_body.find_children("*", "Button", true, false):
		if b.text.begins_with(text):
			return b
	return null


func _run() -> void:
	await _data_tests()
	await _flow_tests()
	print("wiki_test: %s" % ("FAILED %d" % failures if failures else "all passed"))
	quit(1 if failures else 0)


func _data_tests() -> void:
	GameData.ensure()
	var w := Wiki.build()
	var missing := []
	var no_icon := []
	for id in GameData.items:
		if not w.pages.has("item:" + id):
			missing.append(id)
		elif ResourceLoader.exists("res://assets/icons/%s.png" % id) and w.pages["item:" + id].icon == "":
			no_icon.append(id)
	check(missing.is_empty() and no_icon.is_empty(), "every item has a page, with its icon where one exists %s %s" % [missing, no_icon])
	missing.clear()
	for id in GameData.recipes:
		if not w.pages.has("recipe:" + id):
			missing.append(id)
	check(missing.is_empty(), "every recipe has a page %s" % [missing])
	for id in GameData.resources.nodes:
		if not w.pages.has("node:" + id):
			missing.append(id)
	check(missing.is_empty(), "every resource node has a page %s" % [missing])
	for id in GameData.skills:
		if not w.pages.has("skill:" + id):
			missing.append(id)
	for id in Population.JOBS:
		if not w.pages.has("job:" + id):
			missing.append(id)
	for id in GameData.b("animals"):
		if not str(id).begins_with("_") and not w.pages.has("animal:" + id):
			missing.append(id)
	check(missing.is_empty(), "every skill, job and animal has a page %s" % [missing])
	check(w.pages.has("station:forge") and w.pages.has("station:stove") and w.pages.has("station:sawhorse"), "stations have pages")
	check(w.broken_links().is_empty(), "every link resolves %s" % [w.broken_links()])
	for q in ["pickaxe", "plank", "iron ore", "heal", "planks", "stove", "theft", "calendar", "lockpicking"]:
		var r := w.search(q)
		check(not r.is_empty(), "search finds '%s' (%d)" % [q, r.size()])
	check(w.search("pickaxe")[0].begins_with("item:") and "item:pickaxe" in w.search("pickaxe"), "the pickaxe item is among the pickaxe results")
	check("item:iron_ore" in w.search("iron ore"), "'iron ore' finds the iron ore item")
	check("todo:player_shops" in w.search("player shops") and w.pages["todo:player_shops"].blocks[0].t == "note" and not w.pages.has("todo:lockpicking") and "sys:chests" in w.search("lockpick"), "unbuilt ideas are marked Not in the game yet; lockpicking is built")
	check(w.search("zzzz").is_empty(), "nonsense finds nothing")
	check("sys:farm_goods" in w.search("cheese") and w.pages["sys:farm_goods"].text.contains("tanner") and w.pages["job:cook"].text.contains("cheese"), "the wiki explains the village's eggs, milk and wool chain (Build 13)")
	check(w.pages.has("sys:home_work") and w.pages["sys:home_work"].text.contains("poultice"), "the wiki explains villagers' home production and healing (B14)")
	var meds := ["linen_bandage", "herbal_poultice", "healing_tonic", "strong_healing_tonic"]
	check(meds.all(func(m): return w.pages["item:" + m].category == "items_medicine") and w.in_category("items_materials").all(func(pid): return not meds.has(str(pid).trim_prefix("item:"))), "medicines have their own category, not Materials (Build 12 audit)")
	var pk: String = w.pages.get("sys:pack", {}).get("text", "")
	check(pk.contains("eight tabs") and pk.contains("first row is open: 9") and pk.contains("take no place") and pk.contains("raw materials inventory full")
		and "sys:pack" in w.search("inventory full") and w.pages.has("job:tailor") and not w.pages.has("todo:pack_rows"), "INV-18: the pack page explains categories, places, locked rows and gear; the tailor opens the rows (no longer a todo)")
	check(w.pages["sys:trading"].text.contains("every unit is priced in turn") and w.pages["sys:theft"].text.contains("what it was worth"), "the trading and theft pages describe the Build 13 rules")
	check(w.pages["item:iron_bar"].text.contains("pickaxe"), "an item page links to what it makes (iron bar -> pickaxe)")
	check(w.chain_lines("pickaxe").size() >= 3, "the pickaxe has a production chain down to ore")
	# GP-WIKI-RECIPE-TOOLS (owner 2026-10-26): every recipe with a tool shows it, with links and the items that count
	var no_tools := []
	for rid in GameData.recipes:
		var kinds := Wiki.recipe_tool_kinds(rid)
		if kinds.is_empty():
			continue
		var pg: Dictionary = w.pages["recipe:" + rid]
		var lk := w.links_of("recipe:" + rid)
		var out_id: String = GameData.recipes[rid].out.keys()[0]
		for k in kinds:
			var its := Wiki.tool_kind_items(k)
			if (its.is_empty() or not its.all(func(i): return lk.has("item:" + i) and pg.text.contains(GameData.item_name(i).to_lower()))
					or not str(w.chain_lines(out_id)[0]).contains(Wiki.tool_kind_name(k)) or not w.pages["item:" + out_id].text.contains(GameData.item_name(its[0]).to_lower())):
				no_tools.append("%s/%s" % [rid, k])
	check(no_tools.is_empty() and not Wiki.recipe_tool_kinds("dress_stone").is_empty(), "every recipe with a tool shows it on its page, its product's page and its chain line, linked to every item that counts %s" % [no_tools])
	check(w.pages["sys:appearance"].text.contains("leather armour as a leather jerkin") and not w.pages.has("todo:looks_more"), "ARMOR-01: every armour shows on your figure, leather included (no longer a Not yet page)")
	var lp: String = w.pages["sys:chests"].text
	check(lp.contains("game of timing") and lp.contains("own input") and lp.contains("never smaller") and lp.contains("nothing has happened"), "GP-LOCKPICK: the chests page explains the pin-tumbler game")
	var mu: String = w.pages["sys:mining_underground"].text
	check(mu.contains("daylight falling in") and mu.contains("a beam laid across the passage") and mu.contains("never covers a seam"), "GP-MINE-WOOD-FRAME: the underground page says how the way out and a support look")
	var th: String = w.pages["sys:theft"].text
	check(th.contains("red ring") and th.contains("pursued by the guards") and th.contains("never shows where a guard is") and "sys:theft" in w.search("hunted") and "sys:theft" in w.search("chased"),
		"GP-WANTED-INDICATOR: the theft and guards page explains the red ring and the note")
	var ch: String = w.pages["item:chisel"].text
	check(ch.contains("needed for") and ch.contains("making building block") and w.links_of("item:chisel").has("recipe:dress_stone"), "the chisel's page says what it is needed for")
	var ml: String = w.pages["item:mallet"].text
	check(ml.contains("timber support") and ml.contains("ladder") and ml.contains("building block") and ml.contains("cliff stairs"), "the mallet's page names the supports, ladders, stone dressing and cliff stairs it is needed for")
	var pk2: String = w.pages["item:pickaxe"].text
	check(pk2.contains("cutting new passages") and pk2.contains("gathering: iron seam"), "the pickaxe's page names mining work")
	var wa: Array = w.pages["item:prospecting_kit"].blocks[0].rows.filter(func(r): return r[0] == "Works as")
	check(wa.size() == 1 and str(wa[0][1]) == "a prospecting kit", "'Works as' is in words, not a code name %s" % [wa])
	check(w.pages.has("sys:calendar") and w.pages.has("sys:family") and w.pages.has("sys:inheritance") and w.pages.has("sys:animal_life"), "calendar, ageing, family, inheritance and animal life pages exist")
	var ms: String = w.pages.get("guide:market_stall", {}).get("text", "")
	check(ms.contains("3 plank") and ms.contains("open stall") and ms.contains("close stall") and ms.contains("everything has sold") and ms.contains("5%") and ms.contains("daily rent"),
		"the market stall guide: 3 planks, OPEN / CLOSE, settlement on closing or selling out, the manor's 5% on every stall, the pitches' rent")
	check("guide:market_stall" in w.search("market stall commission"), "search finds the market stall guide")
	# CON-01 contracts and DVW-B4 spoiling and wear
	var con: String = w.pages.get("sys:contracts", {}).get("text", "")
	check(con.contains("propose a contract") and con.contains("set aside") and con.contains("lapses") and con.contains("there is no fine")
			and con.contains("%d contracts at once" % int(Contracts.cfg().max_open_per_seller)) and con.contains("villagers use the same contracts"),
		"the contracts page: proposing, coins set aside, lapsing without a fine, the seller's limit, villagers' own orders")
	check("sys:contracts" in w.search("contract") and "sys:contracts" in w.search("counteroffer"), "search finds the contracts page")
	var dec: String = w.pages.get("sys:decay", {}).get("text", "")
	check(dec.contains("wheat") and dec.contains("handcart") and dec.contains("falling apart") and "sys:decay" in w.search("spoil"), "the spoiling and wear page, found by searching spoil")
	check(w.pages["item:wheat"].text.contains("spoil a day") and w.pages["item:leather_armor"].text.contains("days worn") and not w.pages["item:iron_ore"].text.contains("spoil"),
		"item pages say how food keeps and how long armour lasts; ore keeps")
	# Build 17 mining and geology, the manor's job board, and what is not built yet (WIKI-B17)
	var mine_ids := ["sys:mining", "sys:prospecting", "sys:open_pits", "sys:mining_underground", "sys:minecarts", "sys:mine_shafts", "sys:mine_stability", "sys:mine_backfill", "sys:manor_jobs"]
	check(mine_ids.all(func(pid): return w.pages.has(pid)), "the Build 17 mining, prospecting, pit, underground, stability, backfill and job board pages exist")
	for q in [["minecart", "sys:minecarts"], ["prospect", "sys:prospecting"], ["backfill", "sys:mine_backfill"], ["trial pit", "sys:prospecting"], ["open pit", "sys:open_pits"], ["adit", "sys:mining_underground"],
			["timber support", "sys:mining_underground"], ["shaft", "sys:mine_shafts"], ["ladder", "sys:mine_shafts"], ["collapse", "sys:mine_stability"], ["quarry", "sys:mining"], ["assay", "sys:prospecting"],
			["job board", "sys:manor_jobs"], ["any work for me", "sys:manor_jobs"], ["worked out", "sys:mining"]]:
		check(q[1] in w.search(q[0]), "search '%s' finds %s" % [q[0], q[1]])
	var mt: String = w.pages["sys:mining"].text
	check(mt.contains("(14 left)") and mt.contains("grey rock") and mt.contains("no mining wage") and mt.contains("never stops you"), "the mining page: the N left prompt, the grey rock after a seam, independent miners, the level that gates nothing")
	var pt: String = w.pages["sys:prospecting"].text
	check(pt.contains("never certain") and pt.contains("trial pit") and pt.contains("prospector's kit") and pt.contains("the smith"), "the prospecting page: samples, the smith's assay that is never certain, trial pits")
	check(w.pages["sys:open_pits"].text.contains("topsoil") and w.pages["sys:open_pits"].text.contains("ramp") and w.pages["sys:mine_backfill"].text.contains("only you can start"), "the open pit and backfill pages: layers, the ramp, backfill only by the player")
	var cm: String = w.pages["sys:contracts"].text
	check(cm.contains("nothing is signed from a distance") and cm.contains("hire") and not cm.contains("offer you such work"), "the contracts page: signing in person for goods and work; no live villager offers of work")
	var todo_ids := ["earth_reuse", "bigger_pits", "selling_finds", "contract_advances", "contract_results_pay", "contract_disputes", "farm_labour_contracts", "villagers_hire", "service_signing",
			"injuries", "illness", "treatment", "practitioners", "medical_costs", "lasting_harm"]
	check(todo_ids.all(func(t): return w.pages.has("todo:" + t) and w.pages["todo:" + t].category == "notyet" and w.pages["todo:" + t].blocks[0].t == "note" and str(w.pages["todo:" + t].blocks[0].text).begins_with("Not in the game yet.")),
		"every approved-but-unbuilt Build 17 idea and health placeholder is marked Not in the game yet")
	var mpt: String = w.pages["sys:multiplayer"].text if w.pages.has("sys:multiplayer") else ""
	check(mpt.contains("open to friends") and mpt.contains("join a game") and mpt.contains("leave the game") and mpt.contains("47810") and mpt.contains("firewall")
		and not w.pages.has("todo:multiplayer") and w.pages["todo:multiplayer_more"].text.contains("internet") and w.pages["todo:multiplayer_more"].text.contains("phone"),
		"Build 21: Playing with friends is a page of how to host and join on the same network; internet play and phone hosting stay Not in the game yet")
	check("todo:injuries" in w.search("injury") or "todo:injuries" in w.search("injuries"), "search finds the health placeholders")
	var plain := true
	var odd := []
	for pid in mine_ids + ["node:open_pit", "node:prospect_clue", "node:tunnel_rock", "node:iron_seam", "node:stone_seam", "item:topsoil", "item:spoil", "item:timber_support", "item:ore_sample", "item:ladder", "item:track_section"]:
		var tx: String = w.pages[pid].text
		for bad in [".gd", ".json", "World.deposit", "World.mine", "OpenPits", "MineWorks", "mine_unit", "quarry_host_stone", "expose_reach", "mined_", "dug_", "Q18-", "OD-2", "MIN-"]:
			if tx.contains(bad.to_lower()):
				plain = false
				odd.append("%s: %s" % [pid, bad])
	check(plain, "the mining pages are written for the player, without code names or register ids %s" % [odd])
	var no_shift := true
	for pid in w.pages:
		if str(w.pages[pid].text).contains("shift in the mine"):
			no_shift = false
	check(no_shift, "the retired mine-shift quest is mentioned nowhere in the wiki")
	check(not w.pages["sys:mine_stability"].text.contains("survive") and not w.pages["sys:mine_stability"].text.contains("killed"), "the stability page leaves a collapse's outcome for a person to its own page")
	# other systems add pages
	Wiki.add_provider(func(wk: Wiki): wk.add_page("sys:test_extra", "Extra system", "systems", [Wiki.p("A test page about glowworms.")]))
	var w2 := Wiki.build()
	check(w2.pages.has("sys:test_extra") and "sys:test_extra" in w2.search("glowworm"), "a provider can add a searchable page")
	Wiki.providers.clear()
	# the window navigates and steps back
	var sc := ScrollContainer.new()
	var body := VBoxContainer.new()
	sc.add_child(body)
	root.add_child(sc)
	var win := WikiWindow.new()
	win.open(null, body)
	check(not win.step_back(), "no step back from the wiki home")
	win.goto("item:pickaxe")
	check(win.host.find_child("PageTitle", true, false).text == "Pickaxe" and win.host.find_child("PageIcon", true, false) != null, "an item page shows its title and icon")
	win.goto("recipe:forge_pickaxe")
	check(win.step_back() and win.view.id == "item:pickaxe" and not win.step_back() == false, "Back returns to the previous page")
	win.search_for("plank")
	check(win.view.kind == "search" and win.host.find_child("WikiResultsTitle", true, false) != null, "searching shows results")
	sc.queue_free()


func _flow_tests() -> void:
	var ui = main.ui
	main.new_game()
	await process_frame
	var w: World = main.world
	check(main.running and not main.paused, "a game is running")
	# from the pause menu: Settings > Controls > X, repeatedly, by every input
	for round in 3:
		ui.show_pause()
		check(main.paused, "round %d: the pause menu pauses" % round)
		_find("Controls").pressed.emit()
		check(ui.is_open("settings") and ui.settings_tab == "controls" and main.paused, "round %d: Controls opens in Settings" % round)
		check(ui.panel.get_tree().get_nodes_in_group("none").is_empty(), "no stacked windows")
		ui.close_btn.pressed.emit()
		check(ui.is_open("pause") and main.paused, "round %d: X returns to the pause menu" % round)
		_find("Settings").pressed.emit()
		main._unhandled_input(_key(KEY_ESCAPE))
		check(ui.is_open("pause"), "round %d: Esc in Settings returns to the pause menu" % round)
		_find("Controls").pressed.emit()
		main._unhandled_input(_pad(JOY_BUTTON_B))
		check(ui.is_open("pause"), "round %d: the pad's B in Controls returns to the pause menu" % round)
		_find("Encyclopedia").pressed.emit()
		check(ui.is_open("wiki") and ui.title_label.text == "VILLAGE ENCYCLOPEDIA" and main.paused, "round %d: the Village Encyclopedia opens from the pause menu in its own window" % round)
		main._unhandled_input(_key(KEY_ESCAPE))
		check(ui.is_open("pause"), "round %d: Esc leaves the wiki" % round)
		_find("Resume").pressed.emit()
		check(not ui.panel.visible and ui.hud.visible and not main.paused, "round %d: Resume restores the world, the HUD and input" % round)
	# from play: Esc opens the pause menu, Esc closes it
	main._unhandled_input(_key(KEY_ESCAPE))
	check(ui.is_open("pause") and main.paused, "Esc opens the pause menu")
	main._unhandled_input(_key(KEY_ESCAPE))
	check(not ui.panel.visible and not main.paused, "Esc closes the pause menu and play resumes")
	# tabs and persistence
	ui.show_pause()
	_find("Settings").pressed.emit()
	for t in ["audio", "display", "interface", "controls", "saves"]:
		_tab(t)
		await process_frame
		check(ui.settings_tab == t and ui.is_open("settings"), "the %s tab opens" % t)
	_tab("interface")
	await process_frame
	var before: String = main.settings.ui_size
	_find(before.capitalize()).pressed.emit()
	check(main.settings.ui_size != before, "an interface setting changes")
	var again := GameSettings.new()
	again.load_file()
	check(again.ui_size == main.settings.ui_size, "settings persist")
	main.settings.ui_size = "normal"
	main.apply_settings()
	# the wiki from Settings: its own window; pages, then Back steps through them, then returns to Settings
	_tab("wiki")
	await process_frame
	check(ui.is_open("wiki") and ui.settings_tab == "interface", "the Encyclopedia tab opens the encyclopedia window")
	check(ui.panel_body.find_child("WikiNav", true, false) != null and ui.panel_body.find_child("WikiArticle", true, false) != null, "the encyclopedia has a navigation panel and an article panel")
	var win_back: Callable = ui.inner_back
	check(win_back.is_valid(), "the wiki tab has its own Back step")
	ui.panel_body.find_child("WikiSearch", true, false).text_changed.emit("pickaxe")
	await process_frame
	check(ui.panel_body.find_child("Link_item_pickaxe", true, false) != null, "typing 'pickaxe' lists the pickaxe")
	ui.panel_body.find_child("Link_item_pickaxe", true, false).pressed.emit()
	await process_frame
	check(ui.panel_body.find_child("PageTitle", true, false).text == "Pickaxe", "a result opens its page")
	main._unhandled_input(_pad(JOY_BUTTON_B))
	await process_frame
	check(ui.is_open("wiki") and ui.panel_body.find_child("WikiResultsTitle", true, false) != null, "B steps back to the results, still in the encyclopedia")
	check(ui.panel_body.find_child("WikiSearch", true, false).text == "pickaxe", "the search box shows the search stepped back to")
	ui.close_btn.pressed.emit()
	await process_frame
	check(ui.is_open("wiki") and ui.panel_body.find_child("Cat_items_tools", true, false) != null, "X steps back to the wiki home")
	ui.close_btn.pressed.emit()
	check(ui.is_open("settings"), "X then leaves the encyclopedia for Settings")
	_tab("wiki")
	await process_frame
	ui.panel_body.find_child("Cat_items_tools", true, false).pressed.emit()
	ui.panel_body.find_child("Link_item_pickaxe", true, false).pressed.emit()
	await process_frame
	ui.panel_body.find_child("WikiClose", true, false).pressed.emit()
	check(ui.is_open("settings"), "Close leaves the encyclopedia at once, from any page")
	ui.close_btn.pressed.emit()
	check(ui.is_open("pause"), "X then leaves Settings for the pause menu")
	_find("Encyclopedia").pressed.emit()
	ui.panel_body.find_child("WikiResume", true, false).pressed.emit()
	check(not ui.panel.visible and not main.paused, "Resume play goes straight back to the game")
	ui.show_pause()
	_find("Resume").pressed.emit()
	check(not ui.panel.visible and not main.paused, "play resumes after Settings and Wiki")
	# Start (Menu) closes a window of play too
	ui.show_pause()
	_find("Encyclopedia").pressed.emit()
	main._unhandled_input(_pad(JOY_BUTTON_START))
	check(ui.is_open("pause"), "the pad's Menu button steps back as well")
	ui.hide_all()
	# from the title screen: Controls / Settings / Wiki then X, Esc and B come back to the title, never to a grey world
	main.running = false
	main.paused = true
	ui.show_title(false)
	check(ui.is_open("title") and main.paused, "the title screen pauses")
	for entry in ["Controls", "Settings", "Encyclopedia"]:
		_find(entry).pressed.emit()
		check(ui.is_open("wiki" if entry == "Encyclopedia" else "settings"), "%s opens from the title" % entry)
		if entry == "Encyclopedia":
			check(ui.panel_body.find_child("WikiResume", true, false) == null, "no Resume play on the title screen's encyclopedia")
		ui.close_btn.pressed.emit()
		check(ui.is_open("title") and main.paused, "X from %s returns to the title screen" % entry)
		_find(entry).pressed.emit()
		main._unhandled_input(_key(KEY_ESCAPE))
		check(ui.is_open("title"), "Esc from %s returns to the title screen" % entry)
		_find(entry).pressed.emit()
		main._unhandled_input(_pad(JOY_BUTTON_B))
		check(ui.is_open("title"), "B from %s returns to the title screen" % entry)
	main._unhandled_input(_key(KEY_ESCAPE))
	check(ui.is_open("title"), "Esc on the title screen does nothing (it used to leave a grey world)")
	check(w != null, "world still present")
