extends SceneTree
## MP-INTERACT-01 (owner, 2026-10-27; docs/expansion20/MP_INTERACT_AUDIT.md): one player choosing another and using the approved
## interactions through the game's own interface, in one process. The real game scene hosts a world with two guest characters
## (Bob and Cara) standing in it as a session's guests do (NetSession.by_peer); the host's side is driven by real input events
## (keys, a pad, a touch at phone size, a mouse click) through Main's input handlers to the target, the player window and its
## buttons; a guest's side is what its machine sends (NetActions.apply_verb: the host's entry for a guest's request, decoding,
## ownership and reach checks, then the verb as that guest). Covered: another player beside a villager, a workstation and a market
## stall; several players; a moving player; Next / Q / Tab / D-pad cycling; another level; a disconnected and a reconnected player;
## never oneself; touch at 20:9 phone size, mouse, keys and pad; host to guest, guest to host and guest to guest; gift, sale, bid,
## contract (delivery, conservation), message (never read by villagers), partner; accept, decline, counter; a double acceptance and
## the same goods offered twice; save and load with pending offers; the day's lapse; and single player untouched.
## The two-machine half (a guest's own screen, over loopback) is tests/net_interact_test.gd.
##   godot --headless --path game --script res://tests/mp_interact_ui_test.gd

var main
var failures := 0
var checks := 0
var bob: PlayerState
var cara: PlayerState


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://test_mp_interact_ui/save.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func frames(n := 3) -> void:
	for i in n:
		await process_frame


# ---------------------------------------------------------------- input --------------------------
func key(code: int) -> void:
	for down in [true, false]:
		var e := InputEventKey.new()
		e.physical_keycode = code
		e.keycode = code
		e.pressed = down
		Input.parse_input_event(e)
		await process_frame
	await process_frame


func pad(button: int) -> void:
	for down in [true, false]:
		var e := InputEventJoypadButton.new()
		e.button_index = button
		e.pressed = down
		e.device = 0
		Input.parse_input_event(e)
		await process_frame
	await process_frame


## The screen (viewport) position where a map position is drawn.
func screen_of(tile: Vector2) -> Vector2:
	return main.get_canvas_transform() * (tile * main.T)


func touch(at: Vector2) -> void:
	for down in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = 0
		e.position = at
		e.pressed = down
		root.push_input(e, true)
		await process_frame
	await process_frame


func click(at: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.position = at
	e.pressed = true
	root.push_input(e, true)
	await process_frame
	e = e.duplicate()
	e.pressed = false
	root.push_input(e, true)
	await frames(2)


## Press the window's button named `n` (a node name) or showing `text`, as a tap or click on it does. False when there is none.
func press(n: String) -> bool:
	for b in main.ui.panel_body.find_children("*", "Button", true, false):
		var bt := b as Button
		if (bt.name == n or bt.text == n) and not bt.disabled and bt.is_visible_in_tree():
			bt.pressed.emit()
			return true
	return false


func has_button(n: String) -> bool:
	for b in main.ui.panel_body.find_children("*", "Button", true, false):
		if ((b as Button).name == n or (b as Button).text == n) and (b as Button).is_visible_in_tree():
			return true
	return false


func words() -> String:
	var out := ""
	for l in main.ui.panel_body.find_children("*", "Label", true, false):
		out += (l as Label).text + " | "
	return out


# ---------------------------------------------------------------- staging ------------------------
func guest(nm: String, key_: String) -> PlayerState:
	var w: World = main.world
	var g := PlayerState.new()
	g.name = nm
	g.family = "Guest"
	g.sex = "female" if nm == "Cara" else "male"
	g.born = w.player.born
	Identity.register_player(w, g)
	w.give_start_kit(g)
	g.pos = w.player.pos + Vector2(6, 0)
	g.net_key = key_.repeat(32)
	w.add_guest(g)
	return g


## The session as a host with guests connected has it (NetSession.by_peer): the network itself is not used in this process.
func connect_guests(list: Array) -> void:
	var net: NetSession = main.net
	net.role = "host"
	net.by_peer = {}
	net.moves = {}
	for i in list.size():
		var g: PlayerState = list[i]
		g.away = false
		net.by_peer[9001 + i] = g.pid
		net.moves[9001 + i] = {"t": 0, "dir": Vector2.DOWN, "anim": "idle"}


func census() -> Dictionary:
	var g := SettlementHoldings.goods(main.world)
	return {"coins": main.world.total_coins(), "goods": g}


func same_census(a: Dictionary, b: Dictionary) -> bool:
	if int(a.coins) != int(b.coins):
		return false
	for k in a.goods.keys() + b.goods.keys():
		if int(a.goods.get(k, 0)) != int(b.goods.get(k, 0)):
			return false
	return true


func idle_npcs_near(at: Vector2, r: float) -> void:
	for n: NPC in main.world.npcs:
		if n.alive and n.pos.distance_to(at) < r:
			n.pos += Vector2(40, 40)                 # out of the way: the cases below put their own villager where they need one


## Stand the host at `at` facing `dir`, with Bob `off` from the probe in front of it.
func stand(at: Vector2, dir: Vector2) -> void:
	var p: PlayerState = main.world.player
	p.pos = at
	main.player_sprite.face(dir)
	main.move_to = Vector2.INF
	main.target_pref = ""
	main.prompt_done = ""


func kinds() -> Array:
	return main.target_options.map(func(t): return str(t.get("kind", "")))


func player_pids() -> Array:
	return main.target_options.filter(func(t): return str(t.get("kind", "")) == "player").map(func(t): return int(t.pid))


func open_spot() -> Vector2:
	var w: World = main.world
	var sp = main.map.data.spawns.player
	var base := Vector2(int(sp[0]) + 0.5, int(sp[1]) + 0.5)
	for r in range(0, 12):
		for off in [Vector2(r, 0), Vector2(-r, 0), Vector2(0, r), Vector2(0, -r), Vector2(r, r), Vector2(-r, -r)]:
			var at: Vector2 = base + off
			var ok := true
			for d in [Vector2.ZERO, Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1), Vector2(2, 0)]:
				if not w.step_ok(w.player, at + d):
					ok = false
			if ok and w.place_of(at) == "":
				return at
	return base


# ---------------------------------------------------------------- the run ------------------------
func _run() -> void:
	DirAccess.make_dir_recursive_absolute("user://test_mp_interact_ui")
	main.new_game()
	main.ui.hide_all()
	main.net.set_process(false)                       # no network in this process: the session's records only
	var w: World = main.world
	var host: PlayerState = w.player
	host.hunger = 100.0
	await frames()
	# --- single player: nothing of this shows ---
	var spot := open_spot()
	idle_npcs_near(spot, 6.0)
	stand(spot, Vector2.RIGHT)
	main._find_target()
	check(main.other_players().is_empty() and not kinds().has("player"), "single player: no other player, no player target")
	main.ui.show_pause()
	check(not has_button("Players") and not words().contains("Players"), "single player: the pause menu has no Players entry")
	main.ui.hide_all()
	# --- a session with two guests ---
	bob = guest("Bob", "ab")
	cara = guest("Cara", "cd")
	connect_guests([bob, cara])
	bob.pos = spot + Vector2(1.0, 0)
	cara.pos = spot + Vector2(0, 30)
	await frames()
	await _targeting(spot)
	await _inputs(spot)
	await _host_to_guest(spot)
	await _guest_to_host(spot)
	await _guest_to_guest(spot)
	await _security(spot)
	await _integrity(spot)
	await _saves(spot)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _targeting(spot: Vector2) -> void:
	var w: World = main.world
	var host: PlayerState = w.player
	# alone with Bob in front
	stand(spot, Vector2.RIGHT)
	main._find_target()
	check(player_pids() == [bob.pid] and str(main.target.get("kind", "")) == "player" and int(main.target.pid) == bob.pid,
		"Bob in front is a target of kind player, by his pid (%s)" % [kinds()])
	check(str(main.target.label).begins_with("Bob (player)") and main.ui.prompt_text.begins_with("Bob (player)"), "the prompt names him: \"%s\"" % main.ui.prompt_text)
	check(not player_pids().has(host.pid), "never oneself")
	await frames(2)
	check(main.player_mark != null and main.player_mark.marks.size() == 1 and main.player_mark.marks[0][1], "a bright ring at his feet (chosen)")
	# out of reach
	bob.pos = spot + Vector2(5, 0)
	main._find_target()
	check(not kinds().has("player"), "five tiles off he is not offered (reach)")
	bob.pos = spot + Vector2(1.0, 0)
	# beside a villager, nearer than him
	var v: NPC = w.npcs.filter(func(n): return n.alive and n.role == "adult" and n.job != "guard")[0]
	v.plan = [w.brain.work(600, "", {}, "idle")]
	v.pos = spot + Vector2(0.8, 0.3)
	stand(spot, Vector2.RIGHT)
	main._find_target()
	check(kinds().has("npc") and kinds().has("player"), "Bob beside a villager: both on offer (%s)" % [kinds()])
	var at := -1
	for i in 4:
		if str(main.target.get("kind", "")) == "player":
			at = i
			break
		main.cycle_target(1)
	check(at >= 0 and int(main.target.pid) == bob.pid, "Next reaches Bob beside the villager")
	main._find_target()
	check(str(main.target.get("kind", "")) == "player", "and the choice holds frame to frame")
	v.pos = spot + Vector2(40, 40)
	# beside a workstation: Use is the anvil, Talk is Bob
	var anvil: String = w.stations_of("anvil")[0]
	var st: Dictionary = w.stations[anvil]
	var use := Vector2(int(st.use[0]) + 0.5, int(st.use[1]) + 0.5)
	idle_npcs_near(use, 4.0)
	stand(use, Vector2(int(st.at[0]) + 0.5, int(st.at[1]) + 0.5) - use)
	bob.pos = use + main.facing_vec() * 0.9 + main.facing_vec().orthogonal() * 0.5
	main._find_target()
	check(kinds().has("station") and kinds().has("player"), "Bob beside the anvil: the anvil and Bob on offer (%s)" % [kinds()])
	check(str(main.target.get("kind", "")) == "station" and str(main.talk_alt.get("kind", "")) == "player", "Use stays on the anvil, Talk is Bob (INT-483's order)")
	check(main.ui.prompt_text.contains("Bob (player)"), "the prompt's talk line names Bob: \"%s\"" % main.ui.prompt_text.replace("\n", " | "))
	main.scheme = "kbm"
	main.ui.set_scheme("kbm")
	await key(KEY_T)
	check(main.ui.is_open("player") and main.ui.title_label.text == "BOB (PLAYER)", "T opens Bob's window beside the anvil (%s)" % main.ui.title_label.text)
	main.ui.hide_all()
	await frames()
	# beside a market stall
	var stall_at := Vector2.INF
	for post in main._shop_posts():
		if post.stall:
			stall_at = post.cells[0]
			break
	if stall_at != Vector2.INF:
		var found := false
		for off in [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1.2), Vector2(1.2, 0)]:
			var here: Vector2 = stall_at + off
			if not w.step_ok(host, here):
				continue
			idle_npcs_near(here, 3.0)
			stand(here, stall_at - here)
			bob.pos = here + (stall_at - here).normalized().orthogonal() * 0.9 + (stall_at - here).normalized() * 0.4
			main._find_target()
			if kinds().has("player") and kinds().any(func(k): return k in ["stall", "desk", "shop"]):
				found = true
				break
		check(found, "Bob beside a market stall: the stall and Bob on offer (%s)" % [kinds()])
		var reach := -1
		for i in main.target_options.size():
			if str(main.target.get("kind", "")) == "player":
				reach = i
				break
			main.cycle_target(1)
		check(reach >= 0, "Next reaches Bob beside the stall")
	else:
		check(false, "the village has a market stall to stand by")
	# several players together, each chosen on its own, deterministic order
	stand(spot, Vector2.RIGHT)
	bob.pos = spot + Vector2(1.0, 0.3)
	cara.pos = spot + Vector2(1.0, -0.3)
	main._find_target()
	var pids := player_pids()
	check(pids.size() == 2 and pids.has(bob.pid) and pids.has(cara.pid), "two players together: both on offer (%s)" % [pids])
	var first: Array = pids.duplicate()
	main._find_target()
	check(player_pids() == first, "in the same order frame to frame (nearest, then pid)")
	main.cycle_target(1)
	var chosen := int(main.target.get("pid", -1))
	check(chosen in [bob.pid, cara.pid] and chosen != first[0], "Next chooses the other one")
	main._find_target()
	check(int(main.target.get("pid", -1)) == chosen, "and keeps them")
	# a moving player stays chosen while in reach
	for k in 5:
		var who: PlayerState = w.player_by_pid(chosen)
		who.pos += Vector2(0.05, 0.02)
		await process_frame
		main._find_target()
	check(int(main.target.get("pid", -1)) == chosen, "the chosen player moving a little stays the one chosen")
	# another level
	cara.pos = spot + Vector2(0, 30)
	bob.pos = spot + Vector2(1.0, 0)
	bob.map_level = -1
	main._find_target()
	await frames(2)
	check(not kinds().has("player"), "Bob on the level below is not offered from the surface")
	check(main.avatar_sprites.has(bob.pid) and not main.avatar_sprites[bob.pid].visible, "nor drawn here")
	bob.map_level = 0
	await frames(2)
	check(main.avatar_sprites[bob.pid].visible, "back on the surface he is drawn again")
	# disconnected, then reconnected
	bob.away = true
	connect_guests([cara])
	bob.away = true
	main._find_target()
	check(not kinds().has("player") and not main.other_players().has(bob), "Bob disconnected (away): not a target")
	connect_guests([bob, cara])
	main._find_target()
	check(player_pids() == [bob.pid], "Bob reconnected: a target again")
	bob.alive = false
	main._find_target()
	check(not kinds().has("player"), "a dead player is not a target")
	bob.alive = true


func _inputs(spot: Vector2) -> void:
	var ui = main.ui
	# keys: Q to him, E opens; Esc closes
	idle_npcs_near(spot, 6.0)
	stand(spot, Vector2.RIGHT)
	bob.pos = spot + Vector2(1.0, 0)
	cara.pos = spot + Vector2(0, 30)
	main.scheme = "kbm"
	ui.set_scheme("kbm")
	await frames()
	await key(KEY_E)
	check(ui.is_open("player") and ui.title_label.text == "BOB (PLAYER)", "keys: E with Bob chosen opens his window")
	check(has_button("PlayerTalk") and has_button("PlayerGive") and has_button("PlayerSell") and has_button("PlayerContract"), "it offers Talk, Give, Sell, Contract")
	check(not main.paused or main.net.has_guests(), "the shared world is not stopped for it")
	await key(KEY_ESCAPE)
	check(not ui.modal(), "Esc closes it")
	# pad: D-pad to cycle, A to open, B to close
	main.scheme = "gamepad"
	ui.set_scheme("gamepad")
	var v: NPC = main.world.npcs.filter(func(n): return n.alive and n.role == "adult" and n.job != "guard")[0]
	v.plan = [main.world.brain.work(600, "", {}, "idle")]
	stand(spot, Vector2.RIGHT)
	v.pos = spot + main.facing_vec() * World.TARGET_PROBE          # the villager nearest, Bob just beside: the villager comes first
	bob.pos = v.pos + Vector2(0, 0.6)
	await frames()
	check(str(main.target.get("kind", "")) == "npc", "pad: the villager in front is chosen first (%s)" % [kinds()])
	var tries := 0
	while str(main.target.get("kind", "")) != "player" and tries < 4:
		await pad(JOY_BUTTON_DPAD_RIGHT)
		tries += 1
	check(str(main.target.get("kind", "")) == "player" and tries >= 1, "pad: the D-pad reaches Bob beside a villager (%d presses)" % tries)
	await pad(JOY_BUTTON_A)
	check(ui.is_open("player"), "pad: A opens his window")
	await pad(JOY_BUTTON_B)
	check(not ui.modal(), "pad: B closes it, back to play")
	await frames()
	v.pos = spot + Vector2(40, 40)
	# touch at a 20:9 phone size: a tap on Bob
	var was: Vector2i = root.content_scale_size
	root.content_scale_size = Vector2i(1001, 450)
	main.scheme = "touch"
	ui.set_scheme("touch")
	stand(spot, Vector2.LEFT)
	await frames(4)
	var at := screen_of(main.avatar_sprites[bob.pid].position / main.T + Vector2(0, -0.4))
	check(not ui.blocks(at), "Bob is drawn clear of the touch buttons at 1001x450 (%s)" % at)
	await touch(at)
	await frames(2)
	check(ui.is_open("player") and ui.title_label.text == "BOB (PLAYER)", "touch: a tap on Bob opens his window (facing away from him)")
	var win: Rect2 = ui.panel.get_global_rect()
	var view: Vector2 = root.get_visible_rect().size
	check(win.size.x <= view.x and win.size.y <= view.y and win.size.x < view.x * 0.75, "the window is compact on the phone (%s of %s)" % [win.size, view])
	for b in ui.panel_body.find_children("*", "Button", true, false):
		if (b as Button).is_visible_in_tree() and (b as Button).get_global_rect().size.y < 40.0:
			check(false, "every button is a thumb's height (%s: %s)" % [(b as Button).text, (b as Button).get_global_rect().size])
			break
	ui.hide_all()
	await frames()
	# a tap on Bob from two tiles off walks up to him, then opens
	bob.pos = spot + Vector2(2.6, 0)
	await frames(3)
	at = screen_of(main.avatar_sprites[bob.pid].position / main.T + Vector2(0, -0.4))
	await touch(at)
	var opened := false
	for i in 120:
		await process_frame
		if ui.is_open("player"):
			opened = true
			break
	check(opened, "touch: a tap on Bob farther off walks up to him and opens his window")
	ui.hide_all()
	root.content_scale_size = was
	await frames(2)
	# mouse: a left click on Bob; a click on open ground walks
	main.scheme = "kbm"
	ui.set_scheme("kbm")
	stand(spot, Vector2.UP)
	bob.pos = spot + Vector2(1.0, 0)
	await frames(3)
	await click(screen_of(main.avatar_sprites[bob.pid].position / main.T + Vector2(0, -0.4)))
	check(ui.is_open("player"), "mouse: a left click on Bob opens his window (Windows and Linux)")
	ui.hide_all()
	await frames()
	stand(spot, Vector2.UP)
	await click(screen_of(spot + Vector2(-3, 2)))
	check(not ui.modal() and main.move_to.distance_to(spot + Vector2(-3, 2)) < 0.6, "a click on open ground still walks there (%s)" % main.move_to)
	main.move_to = Vector2.INF
	await frames()


func _host_to_guest(spot: Vector2) -> void:
	var w: World = main.world
	var ui = main.ui
	var host: PlayerState = w.player
	idle_npcs_near(spot, 6.0)
	stand(spot, Vector2.RIGHT)
	bob.pos = spot + Vector2(1.0, 0)
	host.inv.add("apple", 4)
	w.stat("imported_apple", 4.0)
	host.coins += 0
	var c0 := census()
	main.ui.show_player(bob.pid)
	await frames()
	# Give: the item, then how many (picker), Offer
	check(press("PlayerGive"), "Give")
	await frames()
	check(press("Apple x4") or press("apple x4") , "the pack's apples are listed: %s" % words())
	await frames()
	var qp: QuantityPicker = ui.panel_body.find_child("QuantityPicker", true, false)
	check(qp != null, "how many: the quantity picker")
	if qp != null:
		qp.set_qty(2)
		qp.confirm()
	await frames()
	var o: Array = w.offers_to(bob)
	check(o.size() == 1 and str(o[0].kind) == "gift" and int(o[0].qty) == 2 and host.inv.count("apple") == 4 and not bob.inv.has("apple"),
		"host to guest: an offer of 2 apples waits; nothing moved yet")
	# Bob (the guest) declines through his machine's request
	var r := NetActions.apply_verb(w, bob, "player_answer", [int(o[0].id), false])
	await frames(2)
	check(r.ok and w.offers_to(bob).is_empty() and host.inv.count("apple") == 4 and not bob.inv.has("apple"), "declined: nothing moves")
	check(ui.toast.text.contains("Bob declines"), "the host is told: \"%s\"" % ui.toast.text)
	# again, accepted
	main.ui.show_player(bob.pid)
	await frames()
	press("PlayerGive")
	await frames()
	press("Apple x4")
	await frames()
	qp = ui.panel_body.find_child("QuantityPicker", true, false)
	if qp != null:
		qp.set_qty(2)
		qp.confirm()
	o = w.offers_to(bob)
	r = NetActions.apply_verb(w, bob, "player_answer", [int(o[0].id), true])
	await frames(2)
	check(r.ok and host.inv.count("apple") == 2 and bob.inv.count("apple") == 2, "accepted: two apples move once")
	check(ui.toast.text.contains("Bob accepts"), "the host is told: \"%s\"" % ui.toast.text)
	check(same_census(c0, census()), "coins and goods conserved")
	# Sell: 2 apples for 7 coins, set with the steppers
	var hc := host.coins
	var bc := bob.coins
	main.ui.show_player(bob.pid)
	await frames()
	check(press("PlayerSell"), "Sell")
	await frames()
	press("Apple x2")
	await frames()
	check(ui.panel_body.find_child("TermsSummary", true, false) != null, "the terms page: %s" % words())
	press("Step_qty_p1")
	await frames()
	var price_now := int((ui.panel_body.find_child("Term_price", true, false) as Label).text.get_slice(": ", 1))
	for i in 7 - price_now if price_now < 7 else 0:
		press("Step_price_p1")
		await process_frame
	for i in price_now - 7 if price_now > 7 else 0:
		press("Step_price_m1")
		await process_frame
	var sum := (ui.panel_body.find_child("TermsSummary", true, false) as Label).text
	check(sum == "You sell 2 apple to Bob for 7 coins.", "the terms say it: \"%s\"" % sum)
	check(press("TermsSend"), "Send")
	o = w.offers_to(bob)
	check(o.size() == 1 and str(o[0].kind) == "sell" and int(o[0].price) == 7 and int(o[0].qty) == 2, "a sale offer waits")
	r = NetActions.apply_verb(w, bob, "player_answer", [int(o[0].id), true])
	check(r.ok and host.coins == hc + 7 and bob.coins == bc - 7 and bob.inv.count("apple") == 4 and not host.inv.has("apple"),
		"accepted: 7 coins one way, 2 apples the other, once (World.trade)")
	check(same_census(c0, census()), "coins and goods conserved after the sale")
	# Contract: host asks Bob to supply 3 apples at 2 each within 2 days
	main.ui.show_player(bob.pid)
	await frames()
	check(press("PlayerContract"), "Contract")
	await frames()
	check(press("Apple"), "any goods to ask for")
	await frames()
	for i in 2:
		press("Step_qty_m1")
		await process_frame
	var pe := int((ui.panel_body.find_child("Term_price", true, false) as Label).text.get_slice(": ", 1))
	for i in absi(pe - 2):
		press("Step_price_m1" if pe > 2 else "Step_price_p1")
		await process_frame
	press("Step_days_m1")
	await frames()
	sum = (ui.panel_body.find_child("TermsSummary", true, false) as Label).text
	check(sum.begins_with("Bob supplies you 3 apple at 2 each (6 coins"), "the contract's terms: \"%s\"" % sum)
	press("TermsSend")
	o = w.offers_to(bob)
	check(o.size() == 1 and str(o[0].kind) == "contract" and int(o[0].days) == 2, "a contract offer waits")
	var hc2 := host.coins
	r = NetActions.apply_verb(w, bob, "player_answer", [int(o[0].id), true])
	var open: Array = w.contracts_with_player(bob)
	check(r.ok and open.size() == 1 and int(open[0].reserved) == 6 and host.coins == hc2 - 6 and str(open[0].seller) == w.player_ref(bob),
		"accepted: the contract opens, the host's 6 coins set aside (CON-01)")
	var cid := int(open[0].id)
	r = NetActions.apply_verb(w, bob, "player_contract_deliver", [cid, 3])
	check(r.ok and int(r.result) == 3 and host.inv.count("apple") == 3 and bob.coins == bc - 7 + 6 and str(w.contracts.get_contract(cid).state) == "fulfilled",
		"Bob delivers 3 beside the host: goods and payment in one step, the contract fulfilled")
	check(same_census(c0, census()), "coins and goods conserved through the contract")
	# Talk: a ready phrase and a typed message
	main.ui.show_player(bob.pid)
	await frames()
	press("PlayerTalk")
	await frames()
	check(press("Hello!"), "a ready phrase (a pad needs no keyboard)")
	var m: Array = w.messages_to(bob)
	check(m.size() == 1 and str(m[0].text) == "Hello!" and str(m[0].kind) == "say", "Bob has the message")
	press("PlayerTalk")
	await frames()
	var edit: LineEdit = ui.panel_body.find_child("PlayerSay", true, false)
	edit.text = "Meet me at the well\nat noon"
	press("PlayerSend")
	m = w.messages_to(bob)
	check(m.size() == 2 and str(m[1].text) == "Meet me at the well at noon", "a typed message, kept on one line: \"%s\"" % (str(m[1].text) if m.size() > 1 else ""))
	var heard := false
	for n: NPC in w.npcs:
		for mem in n.memory:
			if str(mem).contains("Meet me at the well"):
				heard = true
	check(not heard and not "\n".join(w.log_lines).contains("Meet me at the well"), "no villager hears or remembers it; it is not in the village record")
	ui.hide_all()


func _guest_to_host(spot: Vector2) -> void:
	var w: World = main.world
	var ui = main.ui
	var host: PlayerState = w.player
	idle_npcs_near(spot, 6.0)
	stand(spot, Vector2.RIGHT)
	bob.pos = spot + Vector2(1.0, 0)
	var c0 := census()
	# Bob's machine sends an offer: 1 apple for the host
	var r := NetActions.apply_verb(w, bob, "player_offer", ["gift", host.pid, "apple", 1, null, 0, 0, ""])
	await frames(2)
	check(r.ok and str(r.text) == "" and w.offers_to(host).size() == 1, "guest to host: Bob offers an apple (his request, applied by the host as Bob)")
	check(ui.toast.text.begins_with("Bob offers you 1 apple"), "the host is told at once, in the compact message: \"%s\"" % ui.toast.text)
	check(w.player_messages().any(func(e): return str(e[2]).begins_with("Bob offers you 1 apple")), "and it is kept in the Messages journal")
	# the host answers in Bob's window, reached by E
	main.scheme = "kbm"
	ui.set_scheme("kbm")
	await frames()
	await key(KEY_E)
	check(ui.is_open("player") and words().contains("Bob offers you 1 apple"), "E on Bob: his window shows the offer: %s" % words())
	var a0 := host.inv.count("apple")
	var oid := int(w.offers_to(host)[0].id)
	check(press("OfferAccept%d" % oid), "Accept")
	check(host.inv.count("apple") == a0 + 1 and w.offers_to(host).is_empty(), "the apple moves once")
	check(w.messages_to(bob).any(func(x): return str(x.text).begins_with(host.name + " accepts")), "Bob is told the answer (a note)")
	# a partner request from Bob, answered from the pause menu's Players while away from him
	host.born = Life.born_for_age(25.0, w.minutes)
	bob.born = host.born
	r = NetActions.apply_verb(w, bob, "player_offer", ["partner", host.pid])
	check(r.ok and w.offers_to(host).size() == 1, "Bob asks the host to be partners")
	ui.hide_all()
	bob.pos = spot + Vector2(10, 0)
	ui.show_pause()
	check(has_button("Players (1 waiting)"), "the pause menu shows Players, with one waiting")
	press("Players (1 waiting)")
	await frames()
	check(ui.is_open("players") and words().contains("Bob offers you to be partners"), "the players list shows the request: %s" % words())
	oid = int(w.offers_to(host)[0].id)
	press("OfferAccept%d" % oid)
	await frames()
	check(host.partner == -1 and w.offers_to(host).size() == 1 and ui.toast.text == "Stand beside Bob to accept.", "away from Bob the acceptance waits (\"%s\")" % ui.toast.text)
	bob.pos = spot + Vector2(1.0, 0)
	press("OfferAccept%d" % oid)
	check(host.partner == w.person_id(bob) and bob.partner == Life.PLAYER_ID, "beside him, accepted: partners, both agreeing (MP-D8)")
	check(same_census(c0, census()), "coins and goods conserved")
	ui.hide_all()
	# a counter: Bob offers to sell 1 apple for 9; the host counters with a bid of 4
	bob.inv.add("apple", 1)
	w.stat("imported_apple", 1.0)
	c0 = census()
	NetActions.apply_verb(w, bob, "player_offer", ["sell", host.pid, "apple", 1, null, 9, 0, ""])
	main.ui.show_player(bob.pid)
	await frames()
	oid = int(w.offers_to(host)[0].id)
	check(press("OfferCounter%d" % oid), "Counter")
	await frames()
	for i in 5:
		press("Step_price_m1")
		await process_frame
	check((ui.panel_body.find_child("TermsSummary", true, false) as Label).text == "You buy 1 apple from Bob for 4 coins.", "a counter is a bid on his apple")
	press("TermsSend")
	var bid: Array = w.offers_to(bob)
	check(w.offers_to(host).is_empty() and bid.size() == 1 and str(bid[0].kind) == "buy" and int(bid[0].price) == 4, "his offer declined, the bid sent")
	var hc := host.coins
	r = NetActions.apply_verb(w, bob, "player_answer", [int(bid[0].id), true])
	check(r.ok and host.coins == hc - 4 and host.inv.count("apple") == a0 + 2, "Bob accepts the bid: 4 coins and the apple, once")
	check(same_census(c0, census()), "conserved")
	ui.hide_all()


func _guest_to_guest(spot: Vector2) -> void:
	var w: World = main.world
	bob.pos = spot + Vector2(3, 3)
	cara.pos = bob.pos + Vector2(1, 0)
	bob.inv.add("bread", 2)
	w.stat("imported_bread", 2.0)
	var c0 := census()
	var r := NetActions.apply_verb(w, bob, "player_offer", ["sell", cara.pid, "bread", 2, null, 5, 0, ""])
	check(r.ok and w.offers_to(cara).size() == 1, "guest to guest: Bob offers Cara 2 bread for 5 coins")
	var oid := int(w.offers_to(cara)[0].id)
	r = NetActions.apply_verb(w, bob, "player_answer", [oid, true])
	check(str(r.text) == "There is no such offer." and w.offers_to(cara).size() == 1, "Bob cannot accept it for Cara")
	var cc := cara.coins
	r = NetActions.apply_verb(w, cara, "player_answer", [oid, true])
	check(r.ok and cara.coins == cc - 5 and cara.inv.count("bread") >= 2, "Cara accepts: 5 coins to Bob, the bread to her")
	r = NetActions.apply_verb(w, cara, "player_answer", [oid, true])
	check(str(r.text) == "There is no such offer.", "accepting twice does nothing the second time")
	check(same_census(c0, census()), "conserved")
	r = NetActions.apply_verb(w, cara, "player_offer", ["say", bob.pid, "", 0, null, 0, 0, "Thanks, Bob"])
	check(r.ok and w.messages_to(bob).any(func(x): return str(x.text) == "Thanks, Bob"), "Cara says something to Bob")


func _security(spot: Vector2) -> void:
	var w: World = main.world
	var host: PlayerState = w.player
	bob.pos = spot + Vector2(1.0, 0)
	cara.pos = spot + Vector2(0, 30)
	var c0 := census()
	var r := NetActions.apply_verb(w, cara, "player_offer", ["gift", host.pid, "bread", 1, null, 0, 0, ""])
	check(str(r.text) == "Stand beside them to ask." and w.offers_to(host).is_empty(), "from afar nothing can be offered (reach on the host)")
	r = NetActions.apply_verb(w, bob, "player_offer", ["gift", host.pid, "iron_bar", 50, null, 0, 0, ""])
	check(str(r.text) == "You do not have that.", "goods one does not have cannot be offered")
	r = NetActions.apply_verb(w, bob, "player_offer", ["sell", host.pid, "bread", 1, null, 999999999, 0, ""])
	check(str(r.text).begins_with("Name a price"), "an absurd price is refused")
	r = NetActions.apply_verb(w, bob, "player_offer", ["note", host.pid, "", 0, null, 0, 0, "You owe me"])
	check(str(r.text) == "That cannot be offered." and w.messages_to(host).filter(func(x): return str(x.text) == "You owe me").is_empty(), "a player cannot forge a note")
	r = NetActions.apply_verb(w, bob, "player_offer", ["say", host.pid, "", 0, null, 0, 0, "x".repeat(500) + "\u0007"])
	var said: Array = w.messages_to(host).filter(func(x): return str(x.text).begins_with("xxx"))
	check(r.ok and said.size() == 1 and str(said[0].text).length() == World.SAY_MAX, "a message is cut to %d characters, control characters dropped" % World.SAY_MAX)
	r = NetActions.apply_verb(w, bob, "player_offer", ["gift", host.pid, "bread", 1, {"$pid": host.pid}, 0, 0, ""])
	check(not r.ok and str(r.text) == "That is not yours.", "naming the host's character as the actor is refused (no acting as another)")
	r = NetActions.apply_verb(w, bob, "contracts.cancel", [{"$r": "contract", "k": 1}, "player"])
	check(not r.ok and str(r.text) == "That is not yours.", "ending a contract as the host is refused")
	r = NetActions.apply_verb(w, bob, "player_contract_deliver", [987654, 1])
	check(r.ok and int(r.result) == 0, "delivering on a contract that is not one's own does nothing")
	check(same_census(c0, census()), "nothing moved")


func _integrity(spot: Vector2) -> void:
	var w: World = main.world
	var host: PlayerState = w.player
	bob.pos = spot + Vector2(1.0, 0)
	cara.pos = spot + Vector2(1.0, 1.0)
	for o in w.offers.duplicate():
		w.offers.erase(o)
	bob.inv.add("plank", 3)
	w.stat("imported_plank", 3.0)
	var c0 := census()
	# the same three planks offered to two players: only the first acceptance takes them
	var r1 := NetActions.apply_verb(w, bob, "player_offer", ["sell", host.pid, "plank", 3, null, 6, 0, ""])
	var r2 := NetActions.apply_verb(w, bob, "player_offer", ["sell", cara.pid, "plank", 3, null, 5, 0, ""])
	check(r1.ok and r2.ok and w.offers_to(host).size() == 1 and w.offers_to(cara).size() == 1, "the same planks offered to the host and to Cara")
	var cc := cara.coins
	var hc := host.coins
	NetActions.apply_verb(w, cara, "player_answer", [int(w.offers_to(cara)[0].id), true])
	var why := w.player_answer(int(w.offers_to(host)[0].id), true)
	check(cara.inv.count("plank") == 3 and not host.inv.has("plank") and host.coins == hc and cara.coins == cc - 5 and why == "Bob no longer has it.",
		"the first acceptance takes them; the second finds them gone and pays nothing (\"%s\")" % why)
	check(same_census(c0, census()), "no double spend: conserved")
	# an offer of a day gone cannot be accepted
	NetActions.apply_verb(w, bob, "player_offer", ["say", host.pid, "", 0, null, 0, 0, "late"])
	bob.inv.add("apple", 1)
	w.stat("imported_apple", 1.0)
	NetActions.apply_verb(w, bob, "player_offer", ["gift", host.pid, "apple", 1, null, 0, 0, ""])
	var stale := int(w.offers_to(host)[0].id)
	w.minutes += World.DAY
	w._new_day()
	check(w.offers_to(host).is_empty() and w.messages_to(host).is_empty(), "a new day: yesterday's offers and messages lapse")
	check(w.player_answer(stale, true) == "There is no such offer." and bob.inv.count("apple") >= 1, "a lapsed offer cannot be accepted")


func _saves(spot: Vector2) -> void:
	var w: World = main.world
	var host: PlayerState = w.player
	bob.pos = spot + Vector2(1.0, 0)
	bob.inv.add("apple", 2)
	w.stat("imported_apple", 2.0)
	NetActions.apply_verb(w, bob, "player_offer", ["sell", host.pid, "apple", 2, null, 3, 0, ""])
	w.player_offer("contract", bob.pid, "iron_ore", 4, null, 2, 3)
	w.player_offer("say", bob.pid, "", 0, null, 0, 0, "See you tomorrow")
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var h2 := w2.host_player()
	var b2 := w2.player_by_pid(bob.pid)
	var sale: Array = w2.offers_to(h2)
	var order: Array = w2.offers_to(b2)
	var said: Array = w2.messages_to(b2)
	check(sale.size() == 1 and str(sale[0].kind) == "sell" and int(sale[0].price) == 3 and int(sale[0].qty) == 2, "saved and loaded: the sale offer waits, with its price")
	check(order.size() == 1 and str(order[0].kind) == "contract" and int(order[0].days) == 3 and int(order[0].price) == 2, "the contract offer, with its days and price")
	check(said.size() == 1 and str(said[0].text) == "See you tomorrow", "and the message")
	b2.away = false                                 # Bob back in play after the load (MP-D1: a load puts guests away until they rejoin)
	b2.pos = h2.pos + Vector2(1, 0)
	var c0 := {"coins": w2.total_coins(), "goods": SettlementHoldings.goods(w2)}
	check(w2.player_answer(int(sale[0].id), true) == "" and h2.inv.count("apple") >= 2, "the host accepts the loaded sale offer")
	check(int(w2.total_coins()) == int(c0.coins), "conserved after the load")
	w2.dispose()
