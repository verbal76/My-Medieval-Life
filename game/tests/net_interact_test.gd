extends SceneTree
## MP-INTERACT-01 (owner, 2026-10-27) over the network: three Godot processes on this machine over loopback, each running the real game
## scene, each player driving its own interface by input. This process is the guest Ann (a phone: touch at 1001 x 450, then keys and a
## pad); tests/net_host.gd the host (keys and the mouse, as on Windows and Linux); tests/net_interact_guest.gd the guest Cara (touch).
## Each chooses another player's character in the world (a tap, a click, E, Q, the pad's A), opens their window, makes an offer from
## it; the request reaches the intended player's screen (the compact message, the window, the journal), who accepts or declines in
## their own window; the host applies it; both see the result; coins and goods are conserved on the host. Host to guest, guest to
## host, guest to guest; a counterpart who disconnects mid-offer; a reconnection; a host save and restart with an offer pending.
## Real devices, real networks and the Windows and Android builds are not tested here (docs/expansion20/MP_INTERACT_AUDIT.md).
##   godot --headless --path game --script res://tests/net_interact_test.gd

var main
var failures := 0
var checks := 0
var dir := "user://test_net_interact/"
var port := 0
var dport := 0
var host_proc := -1
var g2_proc := -1
var seq := 0
var g2_seq := 0
var host_pid := 0
var ann := 0
var cara := 0
const KEY := "0123456789abcdef0123456789abcdef"
const KEY2 := "fedcba9876543210fedcba9876543210"


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	port = 48400 + OS.get_process_id() % 40 * 2
	dport = port + 1
	DirAccess.make_dir_recursive_absolute(dir)
	for f in ["status.json", "cmd.json", "host_save.json", "host_save.json.bak", "g2_status.json", "g2_cmd.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + f))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = dir + "guest_never_saves.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


# ---------------------------------------------------------------- helpers -----------------------
func spawn(script: String, args: Array) -> int:
	var a := ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", script, "--"] + args
	return OS.create_process(OS.get_executable_path(), a)


func _read(f_: String) -> Dictionary:
	var f := FileAccess.open(dir + f_, FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if typeof(d) == TYPE_DICTIONARY else {}


func status() -> Dictionary:
	return _read("status.json")


func g2() -> Dictionary:
	return _read("g2_status.json")


func command(d: Dictionary) -> void:
	seq += 1
	d["seq"] = seq
	var f := FileAccess.open(dir + "cmd.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	await until(func(): return int(status().get("seq", -1)) >= seq, 5.0)


func g2_command(d: Dictionary) -> void:
	g2_seq += 1
	d["seq"] = g2_seq
	var f := FileAccess.open(dir + "g2_cmd.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	await until(func(): return int(g2().get("seq", -1)) >= g2_seq, 5.0)


func until(cond: Callable, secs: float) -> bool:
	var end := Time.get_ticks_msec() + int(secs * 1000.0)
	while Time.get_ticks_msec() < end:
		if cond.call():
			return true
		await process_frame
	return cond.call()


func wait(secs: float) -> void:
	await until(func(): return false, secs)


func hui() -> Dictionary:
	return status().get("ui", {})


func rec(pid: int) -> Dictionary:
	return status().get("players", {}).get(str(pid), {})


func count(inv: Dictionary, id: String) -> int:
	return int(inv.get(id, 0))


func host_offer(kind: String, from_pid: int) -> Dictionary:
	var ref := "player:%d" % from_pid
	for o in status().get("offers", []):
		if str(o.kind) == kind and str(o["from"]) == ref and str(o.to) == "player":
			return o
	return {}


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
		Input.parse_input_event(e)
		await process_frame
	await process_frame


func tap_pid(pid: int) -> void:
	var sp: ActorSprite = main.avatar_sprites.get(pid)
	if sp == null:
		check(false, "the player %d is drawn on this screen" % pid)
		return
	var at: Vector2 = main.get_canvas_transform() * (sp.position + Vector2(0, -0.4 * main.T))
	for down in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = 0
		e.position = at
		e.pressed = down
		root.push_input(e, true)
		await process_frame
	await process_frame


func press(n: String) -> bool:
	for b in main.ui.panel_body.find_children("*", "Button", true, false):
		var bt := b as Button
		if (bt.name == n or bt.text == n) and not bt.disabled and bt.is_visible_in_tree():
			bt.pressed.emit()
			return true
	return false


func picker(n: int) -> void:
	await process_frame
	var qp: QuantityPicker = main.ui.panel_body.find_child("QuantityPicker", true, false)
	if qp != null:
		qp.set_qty(n)
		qp.confirm()


func words() -> String:
	var out := ""
	for l in main.ui.panel_body.find_children("*", "Label", true, false):
		out += (l as Label).text + " | "
	return out


var sent := {}                # request id -> verb path, for a failing check's message


func join() -> bool:
	main.net.join("127.0.0.1", port, KEY, "Ann", "oak")
	var ok: bool = await until(func(): return main.guest_world, 30.0)
	if ok:
		main.world.remote = func(path: String, args: Array) -> int:
			var rid: int = main.net.send_verb(path, args)
			sent[rid] = path
			return rid
	return ok


func start_host(mode: String) -> bool:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + "status.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + "cmd.json"))
	seq = 0
	host_proc = spawn("res://tests/net_host.gd", [str(port), str(dport), mode, dir, "3"])
	return await until(func(): return status().get("hosting", false), 90.0)


## Everyone stood together by the host (net_host "stage"): the host at the spot facing right, Ann one tile right of it, Cara below
## her. A move Ann sent before the host moved her can arrive after it and put her back, so the stage is repeated until the host's
## record and Ann's own copy agree on where she stands.
func stage() -> void:
	for attempt in 4:
		await command({"cmd": "stage"})
		main.move_to = Vector2.INF
		await wait(0.8)
		var sp: Array = status().get("spot", [])
		if sp.size() != 2:
			continue
		var want := Vector2(float(sp[0]), float(sp[1])) + Vector2(1, 0)
		var host_has: Array = rec(ann).get("pos", [0, 0])
		if main.world.player.pos.distance_to(want) < 0.1 and Vector2(float(host_has[0]), float(host_has[1])).distance_to(want) < 0.1:
			break
	main.player_sprite.face(Vector2.LEFT)              # Ann faces the host
	main.target_pref = ""
	await wait(0.6)                                    # every screen draws the others where they stand (s_players)


## The host's answers to this guest's requests that said something (refusals, differences), for a failing check's message.
func replies_said() -> Array:
	var out := []
	for k in main.net.replies:
		var r: Dictionary = main.net.replies[k]
		if str(r.get("text", "")) != "":
			out.append("%s: %s" % [sent.get(k, r.get("path", "")), r.text])
	return out


func leak() -> int:
	return int(status().get("coin_leak", 999))


# ---------------------------------------------------------------- the run ------------------------
func _run() -> void:
	check(await start_host("new"), "the host opens its world")
	check(await join(), "Ann joins (this process)")
	g2_proc = spawn("res://tests/net_interact_guest.gd", [str(port), KEY2, "Cara", "oak", dir])
	check(await until(func(): return g2().get("welcomed", false) and status().get("connected", []).size() == 2, 60.0), "Cara joins (a third process)")
	host_pid = int(status().host_pid)
	ann = main.net.my_pid
	cara = int(g2().pid)
	await command({"cmd": "give", "id": "apple", "n": 6})
	await stage()
	await _targets()
	await _ann_gives_by_touch()
	await _host_sells_by_mouse()
	await _ann_declines_by_pad()
	await _guests_together()
	await _contract()
	await _disconnect_and_back()
	await _restart_with_offer()
	await g2_command({"cmd": "quit"})
	await command({"cmd": "quit"})
	await until(func(): return not OS.is_process_running(host_proc), 20.0)
	if OS.is_process_running(g2_proc):
		OS.kill(g2_proc)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _targets() -> void:
	check(await until(func(): return hui().get("target", "") == "player" and int(hui().get("target_pid", 0)) == ann, 5.0),
		"the host's screen: Ann beside it is its target (%s %s facing %s; host %s, Ann %s, Cara %s)" % [hui().get("options", []), hui().get("pids", []), hui().get("facing", []),
		status().get("host_pos"), rec(ann).get("pos"), rec(cara).get("pos")])
	main._find_target()
	check(str(main.target.get("kind", "")) == "player" and int(main.target.pid) == host_pid, "Ann's screen: the host beside her is her target")
	check(main.other_players().map(func(q): return q.pid).has(cara), "Ann's copy knows Cara, who joined after her (announced by the host)")
	check(await until(func(): return (g2().get("others", []) as Array).map(func(x): return int(x)).has(ann) and (g2().get("others", []) as Array).map(func(x): return int(x)).has(host_pid), 5.0),
		"Cara's screen has Ann and the host as players (%s)" % [g2().get("others", [])])


func _ann_gives_by_touch() -> void:
	var ui: GameUI = main.ui
	var was: Vector2i = root.content_scale_size
	root.content_scale_size = Vector2i(1001, 450)
	main.scheme = "touch"
	ui.set_scheme("touch")
	await wait(0.3)
	var hname := str(rec(host_pid).get("name", ""))
	await tap_pid(host_pid)
	check(await until(func(): return ui.is_open("player"), 3.0) and ui.title_label.text == ("%s (player)" % hname).to_upper(),
		"Ann (touch, guest to host): a tap on the host opens its window (%s)" % ui.title_label.text)
	press("PlayerGive")
	await process_frame
	check(press("Apple x6"), "her apples are listed: %s" % words())
	await picker(2)
	check(await until(func(): return not host_offer("gift", ann).is_empty(), 5.0), "the request reaches the host: a gift of 2 apples from Ann")
	var o := host_offer("gift", ann)
	check(await until(func(): return str(hui().get("toast", "")).begins_with("Ann offers you 2 apples"), 3.0), "the host's screen tells it: \"%s\"" % hui().get("toast", ""))
	check(status().get("ui", {}).get("messages", []).any(func(m): return str(m).begins_with("Ann offers you 2 apples")), "and keeps it in the host's Messages journal")
	var h0 := count(rec(host_pid).get("inv", {}), "apple")
	await command({"cmd": "key", "code": KEY_E})
	check(await until(func(): return hui().get("kind", "") == "player" and str(hui().get("title", "")) == "ANN (PLAYER)", 3.0), "the host presses E on Ann: her window")
	check((hui().get("words", []) as Array).has("Ann offers you 2 apples."), "it shows her offer: %s" % [hui().get("words", [])])
	await command({"cmd": "press", "name": "OfferAccept%d" % int(o.id)})
	check(await until(func(): return count(rec(ann).get("inv", {}), "apple") == 4 and count(rec(host_pid).get("inv", {}), "apple") == h0 + 2, 5.0),
		"the host accepts: 2 apples move once on the host")
	check(await until(func(): return main.world.player.inv.count("apple") == 4, 3.0), "Ann's own copy has 4 left (the host's record)")
	check(await until(func(): return ui.toast.text.contains("accepts your offer: 2 apples"), 5.0), "Ann's screen is told: \"%s\" %s" % [ui.toast.text, replies_said()])
	check(leak() == 0, "coins conserved on the host")
	ui.hide_all()
	await command({"cmd": "close"})
	root.content_scale_size = was
	await wait(0.2)


func _host_sells_by_mouse() -> void:
	var ui: GameUI = main.ui
	await command({"cmd": "click_pid", "pid": ann})
	check(await until(func(): return hui().get("kind", "") == "player" and str(hui().get("title", "")) == "ANN (PLAYER)", 3.0), "the host (mouse, host to guest): a click on Ann opens her window")
	await command({"cmd": "press", "name": "PlayerSell"})
	await command({"cmd": "press", "name": "Apple x2"})
	await command({"cmd": "press", "name": "TermsSend"})
	check(await until(func(): return main.world.offers_to(main.world.player).any(func(x): return str(x.kind) == "sell"), 5.0), "the sale reaches Ann's copy")
	var o: Dictionary = main.world.offers_to(main.world.player).filter(func(x): return str(x.kind) == "sell")[0]
	var price := int(o.price)
	check(await until(func(): return ui.toast.text.contains("offers you 1 apple for %d coins" % price), 3.0), "Ann's screen tells her: \"%s\"" % ui.toast.text)
	main.scheme = "kbm"
	ui.set_scheme("kbm")
	main.player_sprite.face(Vector2.LEFT)
	await wait(0.2)
	await key(KEY_E)
	check(ui.is_open("player") and words().contains("offers you 1 apple for %d coins" % price), "Ann presses E on the host: its window shows the sale")
	var c0: int = main.world.player.coins
	var hc0 := int(rec(host_pid).get("coins", 0))
	check(press("OfferAccept%d" % int(o.id)), "Accept")
	check(await until(func(): return main.world.player.coins == c0 - price and main.world.player.inv.count("apple") == 5, 5.0),
		"Ann pays %d and has the apple (the host's record)" % price)
	check(await until(func(): return int(rec(host_pid).get("coins", 0)) == hc0 + price, 3.0), "the host is paid once")
	check(await until(func(): return (hui().get("messages", []) as Array).any(func(m): return str(m).begins_with("Ann accepts your offer")), 5.0), "the host is told Ann accepted")
	check(leak() == 0, "coins conserved")
	ui.hide_all()
	await command({"cmd": "close"})


func _ann_declines_by_pad() -> void:
	var ui: GameUI = main.ui
	await command({"cmd": "key", "code": KEY_E})
	await until(func(): return hui().get("kind", "") == "player", 3.0)
	await command({"cmd": "press", "name": "PlayerGive"})
	await command({"cmd": "press", "name": "Apple x1"})
	check(await until(func(): return main.world.offers_to(main.world.player).any(func(x): return str(x.kind) == "gift"), 5.0), "the host offers Ann its last apple")
	var o: Dictionary = main.world.offers_to(main.world.player).filter(func(x): return str(x.kind) == "gift")[0]
	main.scheme = "gamepad"
	ui.set_scheme("gamepad")
	await wait(0.2)
	await pad(JOY_BUTTON_A)
	check(ui.is_open("player"), "Ann (pad): A on the host opens its window")
	var a0: int = main.world.player.inv.count("apple")
	check(press("OfferDecline%d" % int(o.id)), "Decline")
	check(await until(func(): return (hui().get("messages", []) as Array).any(func(m): return str(m).begins_with("Ann declines your offer")), 5.0), "the host is told Ann declined")
	await wait(0.5)
	check(main.world.player.inv.count("apple") == a0 and count(rec(host_pid).get("inv", {}), "apple") >= 1, "nothing moved")
	await pad(JOY_BUTTON_B)
	check(not ui.modal(), "B: back to play")
	await command({"cmd": "close"})


func _guests_together() -> void:
	var ui: GameUI = main.ui
	await g2_command({"cmd": "tap_pid", "pid": ann})
	check(await until(func(): return str(g2().get("ui", {}).get("title", "")) == "ANN (PLAYER)", 3.0), "Cara (touch, guest to guest): a tap on Ann opens her window")
	await g2_command({"cmd": "press", "name": "PlayerTalk"})
	await g2_command({"cmd": "press", "name": "Hello!"})
	check(await until(func(): return main.world.messages_to(main.world.player).any(func(m): return str(m.text) == "Hello!"), 6.0), "Cara's message reaches Ann's copy")
	check(await until(func(): return ui.toast.text == "Cara says: \"Hello!\"", 3.0), "Ann's screen shows it as Cara's words: \"%s\"" % ui.toast.text)
	await g2_command({"cmd": "close"})
	# Ann to Cara, by keys: Q to Cara, E, Give
	main.scheme = "kbm"
	ui.set_scheme("kbm")
	main.player_sprite.face(Vector2.DOWN)
	await wait(0.2)
	var tries := 0
	while not (str(main.target.get("kind", "")) == "player" and int(main.target.pid) == cara) and tries < 5:
		await key(KEY_Q)
		tries += 1
	check(str(main.target.get("kind", "")) == "player" and int(main.target.pid) == cara, "Ann (keys): Q reaches Cara (%d presses)" % tries)
	await key(KEY_E)
	check(ui.is_open("player") and ui.title_label.text == "CARA (PLAYER)", "E opens Cara's window")
	press("PlayerGive")
	await process_frame
	press("Apple x%d" % main.world.player.inv.count("apple"))
	await picker(1)
	check(await until(func(): return (g2().get("offers", []) as Array).any(func(x): return str(x.kind) == "gift" and str(x.to) == "player:%d" % cara), 6.0), "the gift reaches Cara's copy")
	var o: Dictionary = (g2().get("offers", []) as Array).filter(func(x): return str(x.kind) == "gift" and str(x.to) == "player:%d" % cara)[0]
	var c0 := count(rec(cara).get("inv", {}), "apple")
	await g2_command({"cmd": "tap_pid", "pid": ann})
	await until(func(): return str(g2().get("ui", {}).get("title", "")) == "ANN (PLAYER)", 3.0)
	await g2_command({"cmd": "press", "name": "OfferAccept%d" % int(o.id)})
	check(await until(func(): return count(rec(cara).get("inv", {}), "apple") == c0 + 1 and count(rec(ann).get("inv", {}), "apple") == 4, 5.0), "Cara accepts: the apple moves once")
	check(await until(func(): return main.world.player.inv.count("apple") == 4, 3.0), "Ann's copy follows")
	check(leak() == 0, "coins conserved")
	ui.hide_all()
	await g2_command({"cmd": "close"})


func _contract() -> void:
	var ui: GameUI = main.ui
	await stage()                                      # Cara walked up to Ann when she tapped her: everyone back in place
	main.player_sprite.face(Vector2.LEFT)
	await command({"cmd": "face", "x": main.world.player.pos.x, "y": main.world.player.pos.y})
	await command({"cmd": "key", "code": KEY_E})
	check(await until(func(): return str(hui().get("title", "")) == "ANN (PLAYER)", 3.0), "the host opens Ann's window")
	await command({"cmd": "press", "name": "PlayerContract"})
	await command({"cmd": "press", "name": "Apple"})
	for i in 3:
		await command({"cmd": "press", "name": "Step_qty_m1"})
	check((hui().get("words", []) as Array).any(func(x): return str(x).begins_with("Ann supplies you 2 apples")), "the host's terms: %s" % [hui().get("words", [])])
	await command({"cmd": "press", "name": "TermsSend"})
	check(await until(func(): return main.world.offers_to(main.world.player).any(func(x): return str(x.kind) == "contract"), 5.0), "the contract offer reaches Ann")
	var o: Dictionary = main.world.offers_to(main.world.player).filter(func(x): return str(x.kind) == "contract")[0]
	var hc0 := int(rec(host_pid).get("coins", 0))
	await key(KEY_E)
	check(ui.is_open("player") and words().contains("a contract: you supply 2 apples"), "Ann's window shows it (%s; %s; target %s)" % [ui.panel_kind, words(), main.target])
	press("OfferAccept%d" % int(o.id))
	var host_q: PlayerState = main.world.player_by_pid(host_pid)
	check(await until(func(): return main.world.contracts_with_player(host_q).size() == 1, 6.0), "the contract opens, on both machines")
	check(await until(func(): return int(rec(host_pid).get("coins", 0)) == hc0 - 2 * int(o.price), 3.0), "the host's coins for it are set aside")
	var c: Dictionary = main.world.contracts_with_player(host_q)[0]
	main.ui.show_player(host_pid)
	await process_frame
	var a0: int = main.world.player.coins
	check(press("ContractDeliver%d" % int(c.id)), "Ann delivers from the host's window (%s)" % words())
	check(await until(func(): return main.world.player.coins == a0 + 2 * int(o.price) and main.world.player.inv.count("apple") == 2, 5.0), "Ann is paid as the goods go")
	check(leak() == 0, "coins conserved through the contract")
	ui.hide_all()
	await command({"cmd": "close"})


func _disconnect_and_back() -> void:
	var ui: GameUI = main.ui
	await stage()
	main.ui.show_player(host_pid)
	await process_frame
	press("PlayerGive")
	await process_frame
	press("Apple x%d" % main.world.player.inv.count("apple"))
	await picker(1)
	check(await until(func(): return not host_offer("gift", ann).is_empty(), 5.0), "Ann offers the host an apple")
	var o := host_offer("gift", ann)
	var a0 := count(rec(ann).get("inv", {}), "apple")
	var h0 := count(rec(host_pid).get("inv", {}), "apple")
	ui.hide_all()
	main.leave_guest_world("")
	check(await until(func(): return status().get("connected", []).size() == 1 and rec(ann).get("away", false), 5.0), "Ann disconnects: away on the host")
	check(await until(func(): return not (hui().get("options", []) as Array).has("player") or int(hui().get("target_pid", 0)) != ann, 3.0), "the host can no longer choose her")
	await command({"cmd": "key", "code": KEY_ESCAPE})
	await command({"cmd": "press", "name": "Players (1 waiting)"})
	check(hui().get("kind", "") == "players", "the host's pause menu: Players, one waiting")
	await command({"cmd": "press", "name": "OfferAccept%d" % int(o.id)})
	await wait(0.3)
	check(str(hui().get("toast", "")) == "They are gone." and count(rec(ann).get("inv", {}), "apple") == a0 and count(rec(host_pid).get("inv", {}), "apple") == h0,
		"accepting what a disconnected player offered moves nothing (\"%s\")" % hui().get("toast", ""))
	await command({"cmd": "close"})
	check(await join(), "Ann reconnects")
	await stage()
	check(await until(func(): return hui().get("target", "") == "player" and int(hui().get("target_pid", 0)) == ann, 5.0), "the host can choose her again")
	main._find_target()
	check(str(main.target.get("kind", "")) == "player" and int(main.target.pid) == host_pid, "and she the host")


func _restart_with_offer() -> void:
	var ui: GameUI = main.ui
	await command({"cmd": "key", "code": KEY_E})
	await until(func(): return str(hui().get("title", "")) == "ANN (PLAYER)", 3.0)
	await command({"cmd": "press", "name": "PlayerGive"})
	var hn := count(rec(host_pid).get("inv", {}), "apple")
	await command({"cmd": "press", "name": "Apple x%d" % hn})
	await command({"cmd": "picker", "n": 1})
	check(await until(func(): return main.world.offers_to(main.world.player).any(func(x): return str(x.kind) == "gift"), 5.0), "the host offers Ann an apple; she has not answered")
	await command({"cmd": "quit"})
	check(await until(func(): return not main.guest_world, 20.0), "the host saves and quits: Ann is out")
	await until(func(): return not OS.is_process_running(host_proc), 15.0)
	check(await start_host("continue"), "the host comes back from its save")
	check(await join(), "Ann rejoins")
	await stage()
	var o: Array = main.world.offers_to(main.world.player).filter(func(x): return str(x.kind) == "gift")
	check(o.size() == 1, "the pending offer was saved with the world and is still hers to answer")
	if o.is_empty():
		return
	var a0: int = main.world.player.inv.count("apple")
	await key(KEY_E)
	check(ui.is_open("player"), "E on the host: its window")
	press("OfferAccept%d" % int(o[0].id))
	check(await until(func(): return main.world.player.inv.count("apple") == a0 + 1, 5.0), "accepted after the restart: the apple moves once")
	check(leak() == 0, "coins conserved after the restart")
	ui.hide_all()
