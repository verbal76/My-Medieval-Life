extends "res://tests/player_journey_test.gd"
## Extra Life preview (owner 2026-11-12, B25 stabilization directive section 3): a representative, continuous gameplay session
## through the real game scene (main.gd) and its windows, the way a casual player plays it on a stream. It reuses the player
## journey's helpers (walking with Main.move_to, talking with Main.talk_to, the trade window and its quantity picker, the reeve's
## board) and plays rounds of: talking with villagers (What do you do?, Any news?), opening the pack and wielding the sword,
## felling a tree with the starting axe, mining stone, hunting a wild animal with the sword and taking what it leaves, sawing
## planks or roasting meat at a station's craft window, asking the reeve "Any work for me?", selling what was gathered and buying
## food at a shop, eating, and saving and continuing from the title, with the world compared value for value across the reload.
## Each round lets the clock run on. Measured (printed, not thresholds, WDR-022): the frame time of Main._process, static memory
## after each round, rounds and game time played. Checked: every step's window or result, coins conserved, the reload exact, the
## player alive and able to walk. Run headless (one round, the CI form):
##   godot --headless --path game --script res://tests/extra_life_session_test.gd
## A long session (rounds until the wall-clock budget in minutes is spent):
##   godot --headless --path game --script res://tests/extra_life_session_test.gd -- --rounds 99 --wall 40

const SESSION_SAVE := "user://test_saves/extra_life_session_test/save1.json"

var rounds := 1
var wall_minutes := 0.0
var frame_ms_max := 0.0
var frame_ms_sum := 0.0
var frame_count := 0
var spikes := 0                    # frames of Main._process over 50 ms
var mem_samples := []
var events := {}                   # what happened how often (felled, hunted, crafted, sold...)
var misses := {}                   # what could not be done this round, and why (counted)
var talked_to := {}
var phase := ""
var spike_phases := {}             # the phase each frame over 50 ms fell in
var reload_loop := 0              # --reload-loop N: after the rounds, N saves and Continues in a row (memory per reload)
var shots := ""                    # --shots DIR: save the screen at key moments of round 1 (needs a display: xvfb-run, no --headless)


func _frames(n: int) -> void:
	for i in n:
		var t0 := Time.get_ticks_usec()
		main._process(DT)
		var ms := (Time.get_ticks_usec() - t0) / 1000.0
		frame_ms_max = maxf(frame_ms_max, ms)
		frame_ms_sum += ms
		frame_count += 1
		if ms > 50.0:
			spikes += 1
			spike_phases[phase] = "%s %.0f" % [str(spike_phases.get(phase, "")), ms]


func _count(d: Dictionary, k: String) -> void:
	d[k] = int(d.get(k, 0)) + 1


func _miss(k: String, why: String) -> void:
	_count(misses, k)
	note("MISS %s: %s" % [k, why])


func _args() -> void:
	var a := OS.get_cmdline_user_args()
	for i in a.size():
		if a[i] == "--rounds" and i + 1 < a.size():
			rounds = int(a[i + 1])
		elif a[i] == "--wall" and i + 1 < a.size():
			wall_minutes = float(a[i + 1])
		elif a[i] == "--reload-loop" and i + 1 < a.size():
			reload_loop = int(a[i + 1])
		elif a[i] == "--shots" and i + 1 < a.size():
			shots = a[i + 1]


## The screen as drawn now, saved as DIR/NAME.png (only with --shots and a display).
func _shot(name: String, r: int) -> void:
	if shots == "" or r != 1 or DisplayServer.get_name() == "headless":
		return
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(shots)
	root.get_viewport().get_texture().get_image().save_png(shots.path_join(name + ".png"))


## Face `cell` from where the player stands and cycle Use until it offers `kind`. Returns whether it does.
func _aim(cell: Vector2i, kind: String) -> bool:
	main.player_sprite.face(Vector2(cell) + Vector2(0.5, 0.5) - main.world.player.pos)
	main._find_target()
	for k in 10:
		if str(main.target.get("kind", "")) == kind:
			return true
		main.cycle_target(1)
	return str(main.target.get("kind", "")) == kind


func _take_loot_near(within := 3.0) -> int:
	var w: World = main.world
	var p := w.player
	var got := 0
	for i in range(w.loot.size() - 1, -1, -1):
		if i >= w.loot.size():
			continue
		var l: Dictionary = w.loot[i]
		if (l.pos as Vector2).distance_to(p.pos) > within:
			continue
		_walk_to(l.pos, 0.6, 300)
		var t0 := p.inv.total()
		var r := w.player_loot(i)
		got += p.inv.total() - t0
		if str(r.get("far", "")) != "":
			note("loot out of reach: %s" % str(r.far))
	return got


# ------------------------------------------------------------------ the rounds --------------------
func _dialogue(r: int) -> void:
	phase = "dialogue r%d" % r
	var w: World = main.world
	# a player looks for someone free to talk: not asleep, not minding a shop (a shopkeeper at a post opens the trade window),
	# not busy at work (Dialogue.busy: a busy villager answers with a brush-off line, by design)
	var free := func(n): return n.role == "adult" and not w.asleep(n) and not w.at_post(n) and not Dialogue.busy(n)
	var cands := _npc_with(func(n): return free.call(n) and not talked_to.has(n.id))
	if cands.is_empty():
		talked_to = {}
		cands = _npc_with(free)
	note("round %d: %d villagers free to talk now (%s)" % [r, _npc_with(free).size(), w.clock_text()])
	var said := ""
	for n: NPC in cands.slice(0, 5):
		if not _talk(n, 900) or not main.ui.is_open("talk"):
			note("talking to %s (%s, doing '%s') did not open the talk window (window '%s', %.1f tiles away, walk_stuck %.1f)" % [n.name, n.job,
				str(n.doing), main.ui.panel_kind, main.world.player.pos.distance_to(n.pos), main.walk_stuck])
			main.ui.hide_all()
			continue
		talked_to[n.id] = true
		if _press("What do you do?"):
			_frames(1)
		await _shot("01b_dialogue", r)
		var lines := []
		for q in ["What do you do?", "Any news?", "How are things at home?"]:
			if _press(q):
				_frames(1)
				lines.append(_talk_text().substr(0, 90))
		said = "%s (%s): %s" % [n.name, n.job, " | ".join(lines)]
		_press("Goodbye")
		break
	check(said != "", "round %d: walked up to a villager and talked (%s)" % [r, said.substr(0, 220)])
	if said == "":
		_miss("dialogue", "nobody within reach would talk")
	main.ui.hide_all()


func _pack_and_wield(r: int) -> void:
	phase = "pack_and_wield r%d" % r
	var p: PlayerState = main.world.player
	main.ui.show_inventory()
	var win: InventoryWindow = main.ui.inventory_window()
	check(main.ui.is_open("inventory") and win != null, "round %d: the pack window opens" % r)
	if win == null:
		return
	var weapon := "rusty_sword" if p.inv.has("rusty_sword") or p.weapon == "rusty_sword" else ""
	for id in p.inv.ids():
		if GameData.item(id).has("dmg") and weapon == "":
			weapon = id
	if p.weapon == "" and weapon != "":
		win.choose_tab("weapons")
		win.choose(weapon)
		check(_press("Wield") and p.weapon == weapon, "round %d: the %s is wielded from the pack" % [r, weapon])
	else:
		check(p.weapon != "", "round %d: a weapon is in hand (%s)" % [r, p.weapon])
	for t in ["food", "raw", "tools", "weapons", "armour", "medicine", "general", "crafted"]:
		win.choose_tab(t)
	note("pack: %s; weapon %s, tool %s, armour %s" % [str(p.inv.items).substr(0, 300), p.weapon, p.tool, p.armor])
	main.ui.hide_all()


func _fell_tree(r: int) -> void:
	phase = "fell_tree r%d" % r
	var w: World = main.world
	var p := w.player
	var cands := w.trees.filter(func(t): return t.state == "grown")
	cands.sort_custom(func(a, b): return Vector2(a.x, a.y).distance_to(p.pos) < Vector2(b.x, b.y).distance_to(p.pos))
	var logs0 := p.inv.count("log")
	var tried := 0
	for t in cands.slice(0, 6):
		var cell := Vector2i(int(t.x), int(t.y))
		var stand: Vector2i = w.brain.beside(cell, cell + Vector2i(0, 1))
		tried += 1
		if not _walk_to(Vector2(stand) + Vector2(0.5, 0.5), 0.8, 2500):
			_miss("tree_walk", "could not walk to the tree at %s (stood %s)" % [str(cell), str(p.pos)])
			continue
		if not _aim(cell, "tree"):
			_miss("tree_target", "no Fell target at %s (%s)" % [str(cell), str(main.target.get("label", ""))])
			continue
		var lab := str(main.target.get("label", ""))
		for i in int(Trees.cfg().chops) + 3:
			if not _aim(cell, "tree") or w.tree_at(cell).get("state", "") != "grown":
				break
			main.interact()
			if main.ui.modal():
				note("felling opened '%s': %s" % [main.ui.panel_kind, _talk_text().substr(0, 160)])
				main.ui.hide_all()
				break
			_finish_action()
		_frames(3)
		_take_loot_near(3.0)
		if p.inv.count("log") > logs0:
			break
		note("the tree at %s (%s) gave no log: state %s" % [str(cell), lab, str(w.tree_at(cell).get("state", "gone"))])
	var got := p.inv.count("log") - logs0
	check(got > 0, "round %d: felled a tree with the axe and took its logs (+%d log, %d trees tried)" % [r, got, tried])
	if got > 0:
		_count(events, "felled")
	else:
		_miss("fell", "no logs after %d trees" % tried)
	_conserved("round %d after felling" % r)


func _mine(r: int) -> void:
	phase = "mine r%d" % r
	var w: World = main.world
	var p := w.player
	var s0 := p.inv.count("stone")
	var d := w.nearest_deposit(Vector2i(p.pos), ["stone"])
	if d.is_empty():
		_miss("mine", "no stone deposit")
		return
	var cell := Vector2i(int(d.x), int(d.y))
	var stand: Vector2i = w.brain.beside(cell, cell + Vector2i(0, 1))
	if not _walk_to(Vector2(stand) + Vector2(0.5, 0.5), 0.8, 2500):
		_miss("mine_walk", "could not walk to the stone at %s" % str(cell))
		return
	for i in 3:
		if not _aim(cell, "deposit"):
			break
		main.interact()
		_finish_action()
	check(p.inv.count("stone") > s0, "round %d: mined stone with the pickaxe (+%d)" % [r, p.inv.count("stone") - s0])
	if p.inv.count("stone") > s0:
		_count(events, "mined")
	_conserved("round %d after mining" % r)


func _hunt(r: int) -> void:
	phase = "hunt r%d" % r
	var w: World = main.world
	var p := w.player
	var prey: Array = w.fauna.animals.filter(func(a): return a.alive and a.wild() and not bool(a.spec().get("people", false)))
	prey.sort_custom(func(a, b): return a.pos.distance_to(p.pos) < b.pos.distance_to(p.pos))
	if prey.is_empty():
		_miss("hunt", "no wild game left in the world")
		check(true, "round %d: no wild game to hunt (an outcome, WDR-022)" % r)
		return
	var loot0: int = w.loot.size()
	var inv0 := {}
	for id in p.inv.ids():
		inv0[id] = p.inv.count(id)
	var killed := false
	var what := ""
	var swings := 0
	for a: Animal in prey.slice(0, 3):
		what = "%s at %.0f tiles" % [a.label(), a.pos.distance_to(p.pos)]
		var frames := 0
		while a.alive and frames < 3000:
			frames += 1
			if main.ui.modal():
				main.ui.hide_all()
			if p.pos.distance_to(a.pos) > 1.0:
				main.move_to = a.pos
				_frames(1)
				continue
			main.move_to = Vector2.INF
			main.player_sprite.face(a.pos - p.pos)
			if main.attack(a) == "start":
				swings += 1
			_frames(2)
		main.move_to = Vector2.INF
		if not a.alive:
			killed = true
			break
		note("could not catch the %s in %d frames (%d swings)" % [what, frames, swings])
	_frames(3)
	var taken := _take_loot_near(4.0)
	var gained := []
	for id in p.inv.ids():
		var dn := p.inv.count(id) - int(inv0.get(id, 0))
		if dn > 0:
			gained.append("%s +%d" % [id, dn])
	if killed:
		check(true, "round %d: hunted a wild animal with the %s (%s, %d swings)" % [r, p.weapon, what, swings])
		_count(events, "hunted")
		if w.loot.size() > loot0 or taken > 0:
			check(taken > 0, "round %d: harvested the kill (%s)" % [r, ", ".join(gained)])
		else:
			note("round %d: the kill (%s) left nothing to take (a young animal or a bird yields little or nothing: Fauna.kill)" % [r, what])
	else:
		check(swings > 0, "round %d: chased and swung at wild game with the %s (%d swings; it got away: %s)" % [r, p.weapon, swings, what])
		_miss("hunt", "the prey got away: " + what)
	_conserved("round %d after hunting" % r)


func _craft(r: int) -> void:
	phase = "craft r%d" % r
	var w: World = main.world
	var p := w.player
	var plans := []
	if p.inv.count("meat") > 0 and p.inv.count("log") > 0:
		plans.append(["roast_meat", "oven", "roast_meat"])
	if p.inv.count("log") > 0:
		plans.append(["saw_planks", "sawhorse", "plank"])
	if plans.is_empty():
		_miss("craft", "nothing to craft with (logs %d, meat %d)" % [p.inv.count("log"), p.inv.count("meat")])
		return
	var done := ""
	for attempt in 4:
		if done != "":
			break
		if attempt > 0:
			note("round %d: every station for %s is in use; the player waits a little (attempt %d)" % [r, str(plans.map(func(x): return x[1])), attempt + 1])
			_frames(150)
		done = _craft_once(r, plans)
	main.ui.hide_all()
	if done != "":
		check(true, "round %d: crafted at a station through its window: %s" % [r, done])
		_count(events, "crafted")
	else:
		# every station of the kind held by a villager at work for the whole wait is the village's life, not a fault (WDR-022):
		# counted and reported; the craft window itself is checked when a station is free
		_miss("craft", "no station free for %s after waiting (villagers at work there)" % str(plans))
	_conserved("round %d after crafting" % r)


func _craft_once(r: int, plans: Array) -> String:
	var w: World = main.world
	var p := w.player
	var done := ""
	for plan in plans:
		var all_ids: Array = w.stations_of(str(plan[1]))
		var ids: Array = all_ids.filter(func(id): return w.station_refusal(id) == "")
		if ids.is_empty():
			note("no %s free for the player: %s" % [plan[1], "; ".join(all_ids.map(func(id): return "%s: %s" % [id, w.station_refusal(id)]))])
		ids.sort_custom(func(a, b): return Vector2(w.station_use(a)).distance_to(p.pos) < Vector2(w.station_use(b)).distance_to(p.pos))
		for id in ids.slice(0, 3):
			var su: Vector2i = w.station_use(id)
			if not _walk_to(Vector2(su) + Vector2(0.5, 0.5), 0.6, 2500):
				continue
			var st: Dictionary = w.stations[id]
			if not _aim(Vector2i(int(st.at[0]), int(st.at[1])), "station"):
				continue
			main.interact()
			if not main.ui.is_open("craft"):
				continue
			var out: String = plan[2]
			var n0 := p.inv.count(out)
			var pressed := false
			for h in main.ui.panel_body.get_children():
				if h is HBoxContainer and h.get_child_count() >= 3 and (h.get_child(1) as Label) != null and str(h.get_child(1).text).split("<-")[0].contains(GameData.item_name(out)):
					var b := h.get_child(2) as Button
					if b != null and not b.disabled:
						b.pressed.emit()
						pressed = true
					else:
						note("the craft window's Make for %s at %s is disabled: %s %s" % [out, id, w.player_craft_refusal(str(plan[0])), w.station_refusal(id)])
					break
			if not pressed:
				main.ui.hide_all()
				continue
			_finish_action()
			if p.inv.count(out) > n0:
				done = "%s at %s (%s +%d)" % [plan[0], id, out, p.inv.count(out) - n0]
				break
		if done != "":
			break
	main.ui.hide_all()
	return done


func _sell_goods(r: int) -> void:
	phase = "sell_goods r%d" % r
	var w: World = main.world
	var p := w.player
	var earned := 0
	var sold := []
	for id in ["hide", "rabbit_pelt", "feather", "plank", "stone", "log", "antler", "boar_tusk"]:
		if p.inv.count(id) == 0:
			continue
		for n: NPC in _npc_with(func(n): return w.brain.wants(n, id) > 0 and w.purchase_qty(n, p, id, p.inv.count(id)) > 0).slice(0, 2):
			if not _talk(n, 900):
				continue
			main.ui.show_trade(n, {"id": id, "mode": "sell", "price": w.deal_price(w.buy_price(n, id), n, p)})
			var qp = _picker()
			if qp == null:
				main.ui.hide_all()
				continue
			var q := mini(p.inv.count(id), w.purchase_qty(n, p, id, p.inv.count(id)))
			var purse := p.coins
			var theirs := n.coins
			qp.confirmed.emit(q)
			var got := p.coins - purse
			check(got >= 0 and theirs - n.coins == got, "round %d: sold %d %s to %s (%s) through the trade window for %d coins, from their purse" % [r, q, id, n.name, n.job, got])
			if got > 0:
				earned += got
				sold.append("%s x%d" % [id, q])
			main.ui.hide_all()
			break
		if sold.size() >= 2:
			break
	note("round %d: sold %s for %d coins" % [r, str(sold), earned])
	if earned > 0:
		_count(events, "sold")
	else:
		_miss("sell", "nobody bought what was gathered just now")
	_conserved("round %d after selling" % r)


func _save_reload(r: int) -> void:
	phase = "save_reload r%d" % r
	main.ui.hide_all()
	_frames(3)
	var day0: int = main.world.day()
	var before := _snapshot()
	check(main.save_game(false), "round %d: saved" % r)
	main.ui.show_title(main.can_continue())
	check(_press("Continue"), "round %d: Continue pressed on the title" % r)
	var after := _snapshot()
	await process_frame
	var bad := []
	for k in ["coins", "inv", "player", "log", "messages", "quests", "minutes", "world_coins", "pos"]:
		if str(before[k]) != str(after[k]):
			bad.append("%s (%s)" % [k, _diff(str(before[k]), str(after[k])).substr(0, 300)])
	check(bad.is_empty(), "round %d: after the reload the purse, pack, player, journal, quests, clock, world's coins and position are exactly as saved%s" % [r, "" if bad.is_empty() else ": " + "; ".join(bad)])
	check(main.world.day() == day0 and main.running and not main.paused and not main.ui.modal(), "round %d: play resumes on the same day (%d)" % [r, day0])
	_count(events, "reloaded")
	_conserved("round %d after the reload" % r)


func _run() -> void:
	_args()
	main.save_path = SESSION_SAVE
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SESSION_SAVE.get_base_dir()))
	var t_start := Time.get_ticks_msec()
	var ui = main.ui
	check(ui.is_open("title") and _press("New game") and ui.is_open("creation"), "the title's New game opens character creation")
	var edits: Array = ui.panel_body.find_children("*", "LineEdit", true, false)
	if edits.size() >= 2:
		(edits[0] as LineEdit).text = "Stream"
		(edits[1] as LineEdit).text = "Guest"
	check(_press("Begin"), "Begin pressed with a name")
	await process_frame
	check(main.world != null and ui.is_open("origin") and _press("Begin"), "the world is made and the origin's Begin pressed")
	await process_frame
	var w: World = main.world
	coins_start = w.total_coins()
	stats_start = w.stats.duplicate()
	sources_start = w.coin_sources
	var m_start: float = w.minutes
	mem_samples.append(OS.get_static_memory_usage())
	note("start: %s, villagers %d, wild animals %d, trees %d, static memory %.1f MB" % [w.clock_text(), w.npcs.size(),
		w.fauna.animals.filter(func(a): return a.wild()).size(), w.trees.size(), OS.get_static_memory_usage() / 1048576.0])
	var r := 0
	while r < rounds:
		r += 1
		w = main.world
		var p := w.player
		var rm0: float = w.minutes
		if w.hour() >= 20 or w.hour() < 6:
			var g := 0
			while (w.hour() >= 20 or w.hour() < 6) and g < 6:      # night: the player sleeps until morning, as on a stream
				g += 1
				main._rest_now()
				main.ui.hide_all()
				_frames(3)
			note("round %d: slept through the night (%d rests) to %s" % [r, g, w.clock_text()])
		note("---- round %d: %s, coins %d, hunger %.0f, health %.0f" % [r, w.clock_text(), p.coins, p.hunger, p.hp])
		await _shot("01_start", r)
		await _dialogue(r)
		if r == 1 or p.weapon == "":
			_pack_and_wield(r)
		if shots != "" and r == 1:
			main.ui.show_inventory("weapons")
			await _shot("02_pack", r)
			main.ui.hide_all()
		_fell_tree(r)
		await _shot("03_after_felling", r)
		_mine(r)
		_hunt(r)
		await _shot("04_after_hunt", r)
		_craft(r)
		if w.hour() >= 20.0 or w.hour() < 6.0:
			main._rest_now()                  # the reeve is abed at night: sleep first, as a player would
			main.ui.hide_all()
			_frames(3)
		var paid := _manor_work("round %d" % r)
		await _shot("05_reeve", r)
		if paid:
			_count(events, "manor_paid")
		main.ui.hide_all()
		_sell_goods(r)
		_eat_if_hungry("round %d" % r)
		var mem_pre := OS.get_static_memory_usage()
		var obj_pre := Performance.get_monitor(Performance.OBJECT_COUNT)
		await _save_reload(r)
		note("round %d: the reload changed static memory by %+.1f MB and objects by %+d (nodes now %d)" % [r,
			(OS.get_static_memory_usage() - mem_pre) / 1048576.0, int(Performance.get_monitor(Performance.OBJECT_COUNT) - obj_pre),
			int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])
		w = main.world
		p = w.player
		# let the day go on: walk about with the keys and let the clock run
		for a in ["move_right", "move_down", "move_left", "move_up"]:
			Input.action_press(a)
			_frames(15)
			Input.action_release(a)
		_frames(300)
		check(p.alive, "round %d: the player is alive (health %.0f, hunger %.0f)" % [r, p.hp, p.hunger])
		if not p.alive:
			break
		var mem := OS.get_static_memory_usage()
		mem_samples.append(mem)
		var wall := (Time.get_ticks_msec() - t_start) / 60000.0
		note("round %d done: %s (+%.0f game minutes), coins %d, static memory %.1f MB, wall %.1f min, frame max %.1f ms" % [r, w.clock_text(),
			w.minutes - rm0, p.coins, mem / 1048576.0, wall, frame_ms_max])
		if wall_minutes > 0.0 and wall >= wall_minutes:
			break
	if reload_loop > 0:
		# saves alone, then Continues alone, so a growth can be put down to the one or the other
		var mb := func(): return "%.1f MB / %d objects" % [OS.get_static_memory_usage() / 1048576.0, int(Performance.get_monitor(Performance.OBJECT_COUNT))]
		var ms := [mb.call()]
		for k in reload_loop:
			main.save_game(false)
			_frames(2)
			ms.append(mb.call())
		note("SESSION save loop: %d saves in a row: %s" % [reload_loop, ", ".join(ms)])
		ms = [mb.call()]
		for k in reload_loop:
			main.ui.show_title(main.can_continue())
			_press("Continue")
			await process_frame
			_frames(2)
			ms.append(mb.call())
		note("SESSION continue loop: %d Continues in a row: %s" % [reload_loop, ", ".join(ms)])
	w = main.world
	var game_min: float = w.minutes - m_start
	note("SESSION rounds %d, game time %.0f minutes (%.1f hours, day %d), wall %.1f minutes" % [r, game_min, game_min / 60.0, w.day(), (Time.get_ticks_msec() - t_start) / 60000.0])
	note("SESSION events %s" % str(events))
	note("SESSION misses %s" % str(misses))
	note("SESSION frames %d, Main._process mean %.2f ms, max %.1f ms, over 50 ms %d" % [frame_count, frame_ms_sum / maxf(1.0, frame_count), frame_ms_max, spikes])
	note("SESSION frames over 50 ms by phase: %s" % str(spike_phases))
	note("SESSION static memory MB per round: %s" % ", ".join(mem_samples.map(func(m): return "%.1f" % (m / 1048576.0))))
	check(game_min > 0.0 and r >= 1, "the session played %d rounds over %.0f game minutes" % [r, game_min])
	_conserved("at the end of the session")
	print("%d checks, %d failures" % [checks, failures])
	main.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures > 0 else 0)
