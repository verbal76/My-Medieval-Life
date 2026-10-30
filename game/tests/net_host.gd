extends SceneTree
## Multiplayer A2 test host (carried forward from the MP-01 prototype): the real game (main.gd) hosting its world in its own
## Godot process, driven by game/tests/net_g1_test.gd (and net_batch_b_test.gd) through a command file and reporting through a
## status file (both in the given directory). Args after "--": port discovery_port mode(new|continue) dir [max_players, default 2].

var main
var dir := "user://test_net/"
var mode := "new"
var port := 47900
var dport := 47901
var last_seq := -1
var t_status := 0.0
var started := false
var walk := 0.0
var coins0 := 0
var stats0 := {}
var max_players := 2
var census := {}          # MP Batch B: {coins, goods} taken on demand, at load and after the last save
var storm := 0.0          # MP Batch B: seconds left of saving every frame (a guest joining mid-save)
var saves := 0
var orphan_id := -1       # MP-PLAYER-FAMILY: the child family_orphan made
var releases: Array = []  # MP-INTERACT-01: input events to release on the next frame (a key or button pressed by a command)
var spot := Vector2.INF   # MP-INTERACT-01: where "stage" stood the players
var why_last := ""        # the host's last "offer": "" or why not
var felled := ""          # the tree "fell" felled
var holding := false      # X20 phase 4.5 (net_mp4_test): guests' requests are held back as they arrive, then applied in one frame
var held: Array = []
var releasing := false
var batch := {}           # the last release: {held, applied (in that one frame), frame}
var _batch_from := -1
var suspended := {}       # Batch D: the last "suspend": {minutes_before, secs}


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	port = int(a[0])
	dport = int(a[1])
	mode = str(a[2])
	dir = str(a[3])
	if a.size() > 4:
		max_players = int(a[4])
	DirAccess.make_dir_recursive_absolute(dir)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = dir + "host_save.json"
	process_frame.connect(_start, CONNECT_ONE_SHOT)
	process_frame.connect(_hold_step)


## X20 phase 4.5: "process_frame" comes after the network poll (requests that arrived this frame are in NetSession.queue) and before
## Main._process, which applies the queue (NetSession.apply_requests). Held, the arrivals wait here; released, every held request goes
## back into the queue at once, so the host applies them all in this one frame, in their arrival order (the same tick).
func _hold_step() -> void:
	if not started:
		return
	if _batch_from >= 0:
		batch["applied"] = main.net.applied - _batch_from
		_batch_from = -1
	if holding:
		held.append_array(main.net.queue)
		main.net.queue = []
	elif releasing:
		releasing = false
		var keep := held.filter(func(q): return main.net.by_peer.has(int(q.peer)))     # as NetSession drops a gone guest's requests
		main.net.queue = keep + main.net.queue
		batch = {"held": keep.size(), "frame": Engine.get_process_frames()}
		_batch_from = main.net.applied
		held = []


func _start() -> void:
	if mode == "continue":
		main.continue_game()
	else:
		main.new_game()
	main.ui.hide_all()
	census = {"at": "load", "coins": main.world.total_coins(), "goods": _goods(), "away": _aways(), "minutes": main.world.minutes,
		"msec": Time.get_unix_time_from_system()}
	if mode == "ui":                                  # Build 21: opened by the player's own menus (the pause menu, Open to friends)
		started = await _open_by_menu()
		coins0 = main.world.total_coins()
		stats0 = main.world.stats.duplicate()
		_status()
		return
	var why: String = main.host_game({"port": port, "discovery_port": dport, "max_players": max_players, "password": "oak",
		"host_name": "Hosta", "world_name": "Test Vale"})
	started = why == ""
	if not started:
		printerr("host failed: ", why)
	coins0 = main.world.total_coins()
	stats0 = main.world.stats.duplicate()
	_status()


## Build 21: the pause menu, its Open to friends button, the password "oak", Open: as a player does it (the default ports).
func _open_by_menu() -> bool:
	var ui: GameUI = main.ui
	ui.show_pause()
	await process_frame
	if not _press(ui.panel_body, "Open to friends"):
		printerr("host: no Open to friends in the pause menu")
		return false
	await process_frame
	var pw: LineEdit = ui.panel_body.find_child("HostPassword", true, false)
	if pw == null:
		printerr("host: no password field")
		return false
	pw.text = "oak"
	_press(ui.panel_body, "Open to friends")
	await process_frame
	port = main.net.port
	return main.net.is_host()


func _press(node: Node, text: String) -> bool:
	for b in node.find_children("*", "BaseButton", true, false):
		if b is Button and (b as Button).text == text and not (b as Button).disabled and (b as Button).is_visible_in_tree():
			(b as Button).pressed.emit()
			return true
	return false


func _process(delta: float) -> bool:
	if not started:
		return false
	main.world.host_player().hunger = 100.0          # the idle host does not starve while the test runs
	for e in releases:
		Input.parse_input_event(e)
	releases.clear()
	if walk > 0.0:
		var step := minf(walk, 3.0 * delta)
		main.world.host_player().pos.x += step
		walk -= step
	if storm > 0.0:
		storm -= delta
		if main.save_game(false):
			saves += 1
	t_status += delta
	if t_status >= 0.1:
		t_status = 0.0
		_commands()
		_status()
	return false


func _commands() -> void:
	var f := FileAccess.open(dir + "cmd.json", FileAccess.READ)
	if f == null:
		return
	var c = JSON.parse_string(f.get_as_text())
	if typeof(c) != TYPE_DICTIONARY or int(c.seq) <= last_seq:
		return
	last_seq = int(c.seq)
	var w: World = main.world
	match str(c.cmd):
		"walk_host":
			walk = float(c.tiles)
			main.player_sprite.face(Vector2.RIGHT)
		"guest_to":
			for id in main.net.by_peer:
				var p: PlayerState = w.player_by_pid(int(main.net.by_peer[id]))
				p.pos = Vector2(float(c.x), float(c.y))
				main.net.rpc_id(id, "s_correct", p.pos)
		"host_pick":
			var pl := w.plant_at(Vector2i(int(c.x), int(c.y)))
			var got := w.pick_plant(pl)                  # the host's own character, as in single player
			for id in got:
				w.host_player().inv.add(id, int(got[id]))
		"ripen":
			var pl2 := w.plant_at(Vector2i(int(c.x), int(c.y)))
			pl2.state = "ripe"
		"quit":
			main.save_game(false)
			main.net.stop()
			main.save_game(false)
			census = {"at": "saved", "coins": w.total_coins(), "goods": _goods(), "away": _aways(), "minutes": w.minutes,
				"msec": Time.get_unix_time_from_system()}
			_status()
			quit(0)
		"crash":                                     # MP Batch B: the host is killed after an hourly save made while the guest played
			main.save_game(false)
			census = {"at": "saved", "coins": w.total_coins(), "goods": _goods(), "away": _aways(), "minutes": w.minutes,
				"msec": Time.get_unix_time_from_system()}
			_status()
			main.net.peer.close()
			quit(0)
		"endow":                                     # MP Batch B: per-player records for the guest, made by the host's rules, as the guest
			for id in main.net.by_peer:
				var g: PlayerState = w.player_by_pid(int(main.net.by_peer[id]))
				var v: NPC = null
				for n: NPC in w.npcs:
					if n.alive and n.role == "adult" and n.job != "guard":
						v = n
						break
				w.host_player().coins -= 5               # coins move, never made
				g.coins += 5
				g.skills["mining"] = 900
				w.as_actor(g, func(): w.crime_record({"day": w.day(), "kind": "theft", "what": "bread", "victim": v.id, "witnesses": 1}, v))
				w.relations.guest_killings[w.player_ref(g)] = int(w.relations.guest_killings.get(w.player_ref(g), 0)) + 1
				if w.judgment != null:
					w.as_actor(g, func(): JudgmentLive.on_gift(w, w.person_id(g), v, "bread"))      # MP C: the guest gives as itself
				main.net.rpc_id(id, "s_self", g.to_dict())
		"census":
			census = {"at": "now", "coins": w.total_coins(), "goods": _goods(), "away": _aways()}
		"suspend":                                   # Batch D (net_fault_test): Android's background, as the app meets it: the pause
			var m0: float = w.minutes                    # notification, the process frozen (no frames, no network) for `secs`, then
			main._notification(Node.NOTIFICATION_APPLICATION_PAUSED)     # the resume notification before the next frame
			OS.delay_msec(int(float(c.secs) * 1000.0))
			main._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
			suspended = {"minutes_before": m0, "secs": float(c.secs)}
		"give":                                      # MP C: goods for the guests' tests, entered in the books as imported
			for id in main.net.by_peer:
				var gp: PlayerState = w.player_by_pid(int(main.net.by_peer[id]))
				gp.inv.add(str(c.id), int(c.n))
				w.stat("imported_" + str(c.id), float(c.n))
				main.net.rpc_id(id, "s_self", gp.to_dict())
		"dump":                                      # MP C: the shared world's sections as the host has them (NetSync), for comparing copies
			main.net.send_syncs(true)                # the guests' copies take this same moment's sections
			var dd: Dictionary = w.to_dict()
			var out := {"digest": NetSync.digest(dd), "sections": {}}
			for k in c.get("keys", []):
				out.sections[k] = dd.get(k)
			if c.get("full", false):                 # X20 phase 4.5 (net_snapshot.gd): offers, villagers, players, the clock
				out["offers"] = w.offers.duplicate(true)
				var of := {}                         # X20: what each player's copy is sent of them (NetSession.offers_for)
				for p: PlayerState in w.player_list():
					of[str(p.pid)] = NetSession.offers_for(w, w.player_ref(p))
				out["offers_for"] = of
				out["minutes"] = w.minutes
				var nn := {}
				for n: NPC in w.npcs:
					nn[str(n.id)] = n.alive
				out["npcs"] = nn
				var pp := {}
				for p: PlayerState in w.player_list():
					pp[str(p.pid)] = {"pos": [p.pos.x, p.pos.y], "inv": p.inv.items.duplicate(), "coins": p.coins, "away": p.away}
				out["players"] = pp
			var df := FileAccess.open(dir + "dump.json", FileAccess.WRITE)
			df.store_string(JSON.stringify(out))
			df.close()
		"save_storm":
			storm = float(c.secs)
		"hold":                                      # X20 phase 4.5: the guests' requests wait (_hold_step)
			holding = true
		"release":                                   # and are applied together, in one frame
			holding = false
			releasing = true
		"freeze":                                    # the host's frame stops (Main and its children: no simulation, no snapshots) so
			main.process_mode = Node.PROCESS_MODE_DISABLED     # every copy can be compared with one moment of the host's world
		"thaw":
			main.process_mode = Node.PROCESS_MODE_INHERIT
		"put":                                       # one player (by pid) stands at x, y
			var pp: PlayerState = w.player_by_pid(int(c.pid))
			if pp != null:
				pp.pos = Vector2(float(c.x), float(c.y))
				for id in main.net.by_peer:
					if int(main.net.by_peer[id]) == pp.pid:
						main.net.rpc_id(id, "s_correct", pp.pos)
		"give_host":                                 # goods for the host's own pack, entered in the books as imported
			w.host_player().inv.add(str(c.id), int(c.n))
			w.stat("imported_" + str(c.id), float(c.n))
		"take_host":                                 # the host's pack emptied of one good (counted out as exported), for a test's exact count
			var hn := w.host_player().inv.count(str(c.id))
			w.host_player().inv.remove(str(c.id), hn)
			w.stat("imported_" + str(c.id), -float(hn))
		"offer":                                     # the host offers, as its interface's buttons do (World.player_offer)
			why_last = w.player_offer(str(c.kind), int(c.to), str(c.get("item", "")), int(c.get("qty", 1)), null, int(c.get("price", 0)), int(c.get("days", 0)), str(c.get("text", "")))
		"fell":                                      # the grown village tree nearest the players felled, as a woodcutter fells one
			var best := {}
			for t in w.trees:
				if str(t.state) == "grown" and not t.get("ow", false) and t.has("born") and (best.is_empty() or Vector2(int(t.x), int(t.y)).distance_to(spot) < Vector2(int(best.x), int(best.y)).distance_to(spot)):
					best = t
			if not best.is_empty() and w.fell(best, 0) > 0:
				felled = "%d,%d%s" % [int(best.x), int(best.y), "" if best.has("born") else " (no born)"]
		"quit_to_title":                             # X20: the pause menu's "Save and quit to title", pressed as the player does
			main.ui.show_pause()
			_press(main.ui.panel_body, "Save and quit to title")
		"save":                                      # a save while the guests play (the hourly save, by hand)
			main.save_game(false)
			saves += 1
			census = {"at": "saved_live", "coins": w.total_coins(), "goods": _goods(), "away": _aways(), "minutes": w.minutes,
				"msec": Time.get_unix_time_from_system()}
		"animal_to":                                 # Build 21: a host animal put somewhere on its own ground, standing there a while
			var a: Animal = w.fauna.by_id(int(c.id))
			if a != null:
				a.pos = Vector2(float(c.x), float(c.y))
				a.goal = Vector2.INF
				a.wait = 30.0
				a.moving = false
		"animal_hurt":
			var a2: Animal = w.fauna.by_id(int(c.id))
			if a2 != null:
				a2.hp = float(c.hp)
		"animal_kill":
			var a3: Animal = w.fauna.by_id(int(c.id))
			if a3 != null:
				w.fauna.kill(a3)
		"animal_spawn":
			var a4: Animal = w.fauna.spawn(str(c.area), str(c.species), "f", null)
			a4.wait = 30.0
		"pen_trough":
			w.fauna.pens[str(c.id)].trough = int(c.n)
		"stage":                                     # MP-INTERACT-01: the host and every guest together on open ground, villagers kept off
			spot = _open_spot()
			var hp2 := w.host_player()
			hp2.pos = spot
			hp2.born = Life.born_for_age(25.0, w.minutes)
			main.player_sprite.face(Vector2.RIGHT)
			main.move_to = Vector2.INF
			var k := 0
			var ids: Array = main.net.by_peer.keys()
			ids.sort_custom(func(x, y): return int(main.net.by_peer[x]) < int(main.net.by_peer[y]))     # by pid: the first to join first
			for id in ids:
				var gp: PlayerState = w.player_by_pid(int(main.net.by_peer[id]))
				gp.pos = spot + ([Vector2(1.0, 0), Vector2(1.0, 1.4), Vector2(0, 1.4)][k % 3])     # all within reach of each other
				gp.born = hp2.born
				k += 1
				main.net.rpc_id(id, "s_correct", gp.pos)
			_clear_villagers()
		"clear_villagers":
			_clear_villagers()
		"face":                                      # the host faces a point (tiles)
			main.player_sprite.face(Vector2(float(c.x), float(c.y)) - w.host_player().pos)
		"key":                                       # a key pressed (released next frame), as the keyboard does
			var e := InputEventKey.new()
			e.physical_keycode = int(c.code)
			e.keycode = int(c.code)
			e.pressed = true
			Input.parse_input_event(e)
			var up := e.duplicate()
			up.pressed = false
			releases.append(up)
		"pad":                                       # a pad button pressed (released next frame)
			var j := InputEventJoypadButton.new()
			j.button_index = int(c.button)
			j.pressed = true
			Input.parse_input_event(j)
			var ju := j.duplicate()
			ju.pressed = false
			releases.append(ju)
		"click_pid":                                 # a left click on that player's drawn character (Windows, Linux)
			var sp: ActorSprite = main.avatar_sprites.get(int(c.pid))
			if sp != null:
				var at: Vector2 = main.get_canvas_transform() * (sp.position + Vector2(0, -0.4 * main.T))
				var mb := InputEventMouseButton.new()
				mb.button_index = MOUSE_BUTTON_LEFT
				mb.position = at
				mb.pressed = true
				root.push_input(mb, true)
				var mu := mb.duplicate()
				mu.pressed = false
				root.push_input(mu, true)
		"press":                                     # a button of the open window, by its node name or its words
			_press_named(main.ui.panel_body, str(c.name))
		"picker":                                    # the open quantity picker set and confirmed
			var qp: QuantityPicker = main.ui.panel_body.find_child("QuantityPicker", true, false)
			if qp != null:
				qp.set_qty(int(c.n))
				qp.confirm()
		"close":
			main.ui.hide_all()
		"ui_stop":                                   # Build 21: Stop hosting, pressed in the host's Open to friends window
			_press(main.ui.panel_body, "Stop hosting")
		"kill_guest":
			for id in main.net.by_peer:
				w.damage_player(99999.0, "a test", w.player_by_pid(int(main.net.by_peer[id])))
		"family_setup":                              # MP-PLAYER-FAMILY: the host a man of 25 with a house of his own, the guest beside him
			var hp := w.host_player()
			hp.sex = "male"
			hp.born = Life.born_for_age(25.0, w.minutes)
			var bids: Array = w.buildings.keys()
			bids.sort()
			for pass_ in 2:                          # a house nobody lives in first, else any house with beds
				for bid in bids:
					var b: Dictionary = w.buildings[bid]
					if hp.home == "" and str(b.type) == "house" and w.construction.beds_in(str(bid)) >= 2 and (pass_ == 1 or w.household_in(str(bid)) < 0):
						w.set_owner(b, World.PLAYER)
						w.set_tenant(b, "")
						hp.home = str(bid)
			for id in main.net.by_peer:
				var gp: PlayerState = w.player_by_pid(int(main.net.by_peer[id]))
				gp.sex = str(c.get("sex", "female"))
				gp.born = hp.born
				gp.pos = hp.pos + Vector2(1, 0)
				main.net.rpc_id(id, "s_correct", gp.pos)
				main.net.rpc_id(id, "s_self", gp.to_dict())
		"family_accept":                             # the host accepts the guest's offer (MP-D8)
			for o in w.offers_to(w.host_player()):
				w.player_answer(int(o.id), true)
			Life.sync_couple_homes(w)
		"family_birth":                              # a birth to the couple by Life.birth (the chance of Life.births is a test's patience)
			var gq: PlayerState = w.player_of_id(w.host_player().partner)
			var hh := Life.couple_household(w, w.host_player(), gq)
			var mom: PlayerState = gq if gq.sex == "female" else w.host_player()
			var dad: PlayerState = w.host_player() if mom == gq else gq
			if hh >= 0:
				Life.birth(w, mom, dad, hh)
		"family_orphan":                             # a child whose parents die, taken in by strangers: one the couple may adopt
			for hh2 in w.households:
				var ms: Array = w.brain._members(int(hh2.id))
				if int(hh2.id) < 3 or Life.is_couple(hh2) or not ms.any(func(o: NPC) -> bool: return o.role == "child"):
					continue
				var kid: NPC = ms.filter(func(o: NPC) -> bool: return o.role == "child")[0]
				if not Life.parent_ids(kid).all(func(pid): return int(pid) < 0 or w.npc(int(pid)) == null or ms.has(w.npc(int(pid))) or not w.npc(int(pid)).alive):
					continue                             # a parent living elsewhere would keep the child
				for o: NPC in ms:
					if o.alive and o.role != "child":
						w.kill(o, "fever")
				var tier := Guardianship.place(w, kid)
				if tier in ["villager", "clan"]:            # no kin of theirs cares for the child: the couple may take them in
					orphan_id = kid.id
					break


## MP-INTERACT-01: open ground near the host's spawn with room for three players round it, not in a building.
func _open_spot() -> Vector2:
	var w: World = main.world
	var sp = main.map.data.spawns.player
	var base := Vector2(int(sp[0]) + 0.5, int(sp[1]) + 0.5)
	for r in range(0, 14):
		for off in [Vector2(r, 0), Vector2(-r, 0), Vector2(0, r), Vector2(0, -r), Vector2(r, r), Vector2(-r, -r)]:
			var at: Vector2 = base + off
			var ok := w.place_of(at) == ""
			for d in [Vector2.ZERO, Vector2(1, 0), Vector2(-1, 0), Vector2(1, 1.4), Vector2(-1, 1.4), Vector2(0, 1.4)]:
				if not w.step_ok(w.host_player(), at + d):
					ok = false
			if ok:
				return at
	return base


func _clear_villagers() -> void:
	if spot == Vector2.INF:
		return
	for n: NPC in main.world.npcs:
		if n.alive and n.pos.distance_to(spot) < 6.0:
			n.pos = spot + Vector2(30, 30)
			n.plan = [main.world.brain.work(600, "", {}, "idle")]


func _press_named(node: Node, n: String) -> bool:
	for b in node.find_children("*", "BaseButton", true, false):
		if b is Button and ((b as Button).name == n or (b as Button).text == n) and not (b as Button).disabled and (b as Button).is_visible_in_tree():
			(b as Button).pressed.emit()
			return true
	return false


func _status() -> void:
	var w: World = main.world
	var players := {}
	for p: PlayerState in w.player_list():
		var ref := w.player_ref(p)
		players[str(p.pid)] = {"name": p.name, "pos": [p.pos.x, p.pos.y], "inv": p.inv.items.duplicate(), "coins": p.coins, "hunger": p.hunger,
			"away": p.away, "host": w.is_host(p), "ref": ref, "key": p.net_key,
			"alive": p.alive, "line": p.line, "skills": p.skills.duplicate(), "crimes": p.crimes.size(), "case": (w.justice.case_of(ref).get("crimes", []) as Array).size(),
			"killings": w.relations.killings_of(ref), "jtag": _tagged(w, ref), "resting": p.rest_until >= 0.0, "quests": p.quests.size(),
			"carts": w.carts.of(ref).size(), "id": w.person_id(p), "partner": p.partner, "children": p.children.duplicate()}
	var connected := []
	for id in main.net.by_peer:
		connected.append(int(main.net.by_peer[id]))
	var plants := {}
	for pl in w.plants:
		plants["%d,%d" % [int(pl.x), int(pl.y)]] = str(pl.state)
	var c_in := int(w.stats.get("newcomer_coins_in", 0)) - int(stats0.get("newcomer_coins_in", 0)) + int(w.stats.get("caravan_coins_in", 0)) - int(stats0.get("caravan_coins_in", 0)) \
		- int(w.stats.get("caravan_coins_out", 0)) + int(stats0.get("caravan_coins_out", 0)) + int(w.stats.get("scenario_coins_in", 0)) - int(stats0.get("scenario_coins_in", 0))
	var animals := {}
	for a: Animal in w.fauna.animals:
		animals[str(a.id)] = {"pos": [a.pos.x, a.pos.y], "hp": a.hp, "species": a.species, "area": a.area, "wild": a.wild()}
	var troughs := {}
	for pid2 in w.fauna.pens:
		troughs[str(pid2)] = int(w.fauna.pens[pid2].trough)
	var who: Label = main.ui.panel_body.find_child("HostPlayers", true, false)
	var d := {"hosting": main.net.is_host(), "animals": animals, "ui_kind": main.ui.panel_kind, "ui_players": who.text if who != null and main.ui.panel_kind == "host" else "",
		"running": main.running, "troughs": troughs, "seq": last_seq, "players": players, "connected": connected, "rejected": main.net.rejected,
		"applied": main.net.applied, "host_pid": w.host_player().pid, "host_pos": [w.host_player().pos.x, w.host_player().pos.y],
		"minutes": w.minutes, "seed": w.seed, "plants": plants, "coin_leak": w.total_coins() - coins0 - c_in,
		"census": census, "saves": saves, "family": _family(w), "orphan": orphan_id, "storm": storm > 0.0, "newcomers": int(w.stats.get("player_newcomers", 0)), "coin_sources": w.coin_sources,
		"journal": _journal_counts(w), "journal_kept": main.net.journal_kept,
		"ui": _ui_state(), "offers": w.offers.duplicate(true), "spot": [spot.x, spot.y] if spot != Vector2.INF else [],
		"held": held.size(), "holding": holding, "batch": batch, "why_last": why_last, "felled": felled, "rec": {"dir": str(w.recorder.dir) if w.recorder != null else "", "state": w.recorder.completeness() if w.recorder != null else ""}, "frozen": main.process_mode == Node.PROCESS_MODE_DISABLED,
		"day": w.day(), "net_d": {"duplicates": main.net.duplicates, "gaps": main.net.gaps_skipped, "resumes": main.net.resumes,
			"log": main.net.applied_log.duplicate(), "tag": main.net.tag, "suspended": suspended, "upnp": main.net.upnp.state,
			"mp_peers": main.net.multiplayer.get_peers().size() if main.net.peer != null else 0}}
	var tmp := dir + "status.tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(dir + "status.json"))


## MP-INTERACT-01: what the host's screen shows: the window, its title, words and buttons, the message, the chosen target.
func _ui_state() -> Dictionary:
	var ui: GameUI = main.ui
	var words := []
	var buttons := []
	if ui.modal():
		for l in ui.panel_body.find_children("*", "Label", true, false):
			words.append((l as Label).text)
		for b in ui.panel_body.find_children("*", "Button", true, false):
			if (b as Button).is_visible_in_tree():
				buttons.append(str((b as Button).name) + "=" + (b as Button).text + ("" if not (b as Button).disabled else " (off)"))
	return {"kind": ui.panel_kind if ui.modal() else "", "title": ui.title_label.text if ui.modal() else "", "words": words, "buttons": buttons,
		"toast": ui.toast.text if ui.toast.visible else "", "target": str(main.target.get("kind", "")), "target_pid": int(main.target.get("pid", 0)),
		"options": main.target_options.map(func(t): return str(t.get("kind", ""))), "messages": w_messages(),
		"facing": [main.facing_vec().x, main.facing_vec().y], "pids": main.target_options.map(func(t): return int(t.get("pid", 0)))}


func w_messages() -> Array:
	return main.world.player_messages().map(func(e): return str(e[2]))


## MP-PLAYER-FAMILY: the couples' households and every child of a player (its parents, adoptive parents, household), and the population.
func _family(w: World) -> Dictionary:
	var hs := []
	for hh in w.households:
		if hh.has("couple"):
			hs.append({"id": int(hh.id), "couple": hh.couple, "members": hh.members, "home": str(hh.home), "family": str(hh.family)})
	var kids := {}
	for n: NPC in w.npcs:
		if Life.is_player_id(n.mother) or Life.is_player_id(n.father) or not n.adoptive.is_empty():
			kids[str(n.id)] = {"mother": n.mother, "father": n.father, "adoptive": n.adoptive, "household": n.household, "alive": n.alive}
	return {"households": hs, "kids": kids, "npcs": w.npcs.size(), "living": w.npcs.filter(func(o: NPC) -> bool: return o.alive).size()}


## Every good in the world, over every holder (the census of the economy simulation's ledger; every player's pack and chest).
func _goods() -> Dictionary:
	var g := SettlementHoldings.goods(main.world)
	var out := {}
	var ks := g.keys()
	ks.sort()
	for k in ks:
		out[str(k)] = g[k]
	return out


func _aways() -> Dictionary:
	var out := {}
	for p: PlayerState in main.world.player_list():
		out[str(p.pid)] = p.away
	return out


## Whether a judgment fact names this player by its reference (the "by:" tag).
static func _tagged(w: World, ref: String) -> bool:
	if w.judgment == null:
		return false
	for ev in w.judgment.facts:
		if (w.judgment.fact(int(ev)).tags as Array).has("by:" + ref):
			return true
	return false


## GP-MESSAGE-JOURNAL: how many messages each player keeps in the host's world, and the newest's words, by player reference.
func _journal_counts(w: World) -> Dictionary:
	var out := {}
	for r in w.messages.by_ref:
		var list: Array = w.messages.by_ref[r]
		out[str(r)] = {"n": list.size(), "last": str(list[-1][2]) if not list.is_empty() else ""}
	return out
