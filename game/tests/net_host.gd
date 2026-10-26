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


func _start() -> void:
	if mode == "continue":
		main.continue_game()
	else:
		main.new_game()
	main.ui.hide_all()
	census = {"at": "load", "coins": main.world.total_coins(), "goods": _goods(), "away": _aways()}
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
			census = {"at": "saved", "coins": w.total_coins(), "goods": _goods(), "away": _aways()}
			_status()
			quit(0)
		"crash":                                     # MP Batch B: the host is killed after an hourly save made while the guest played
			main.save_game(false)
			census = {"at": "saved", "coins": w.total_coins(), "goods": _goods(), "away": _aways()}
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
			var df := FileAccess.open(dir + "dump.json", FileAccess.WRITE)
			df.store_string(JSON.stringify(out))
			df.close()
		"save_storm":
			storm = float(c.secs)
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
		"census": census, "saves": saves, "family": _family(w), "orphan": orphan_id, "storm": storm > 0.0, "newcomers": int(w.stats.get("player_newcomers", 0)), "coin_sources": w.coin_sources}
	var tmp := dir + "status.tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(dir + "status.json"))


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
