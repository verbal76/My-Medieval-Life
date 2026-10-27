extends SceneTree
## X20 final validation, phase 4.5 (owner directive 2026-10-27, "Multiplayer simulation"): the approved host-owned world (master
## multiplayer directive 2026-10-24: one host, about three or four players, time stops when the host leaves) with one host and two
## guests, then one host and three guests (four players), each a Godot process on this machine over loopback running the real game
## scene. This process is the guest Ann (touch, keys, a pad); tests/net_host.gd the host Hosta (keys, the mouse); tests/
## net_interact_guest.gd the guests Cara (touch, tag g2) and Dan (the mouse and keys, tag g3); tests/net_guest.gd a fifth who is
## refused (the world is full).
## Covered: every player choosing every other through the real input paths (tap, left click, Q and E, the pad's D-pad and A);
## requests from several players applied by the host in one frame (tests/net_host.gd "hold" and "release": the same tick): two
## players accepting one gift whose goods exist once, one buyer accepting two sales he can pay only one of, two gifts crossing, two
## players picking one plant; messages from two senders and a burst from one, delivered once each and in order; every participant's
## copy of the shared world compared with the host's at one frozen moment (tests/net_snapshot.gd: the synchronized sections, the
## offers, the clock, the villagers, every player's place, its own pack and purse); a guest leaving and coming back with offers
## pending both ways; a save with every guest playing, the host quitting (no minute passes while it is away, no guest can act) and
## coming back from it, everyone returning as the same character; the host killed after a save; coins and goods conserved over all
## four players throughout. Real devices, real networks and the Windows and Android builds are not tested here
## (docs/expansion20/MP_TEST_MATRIX.md).
##   godot --headless --path game --script res://tests/net_mp4_test.gd

const Snap := preload("res://tests/net_snapshot.gd")
const SAME := ["buildings", "stalls", "plots", "fields", "households", "loot", "trees", "plants", "deposits", "boulders", "treasury",
	"granary", "vacancies", "carts", "relations", "credit", "justice", "contracts", "quest_offers", "feast", "farm", "farm_plots", "chests"]
const ID_A := "a0123456789abcdef0123456789abcde"
const ID_C := "c0123456789abcdef0123456789abcde"
const ID_D := "d0123456789abcdef0123456789abcde"
const ID_E := "e0123456789abcdef0123456789abcde"
const ORE := "iron_ore"           # goods that neither spoil nor are eaten, for exact counts

var main
var failures := 0
var checks := 0
var dir := "user://test_net_mp4/"
var port := 0
var dport := 0
var host_proc := -1
var procs := {}                   # tag -> process id
var seq := 0
var gseq := {"g2": 0, "g3": 0}
var host_pid := 0
var ann := 0
var cara := 0
var dan := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	port = 48600 + OS.get_process_id() % 45 * 2
	dport = port + 1
	DirAccess.make_dir_recursive_absolute(dir)
	for f in DirAccess.get_files_at(dir):
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


func gs(tag: String) -> Dictionary:
	return _read(tag + "_status.json")


func command(d: Dictionary) -> void:
	seq += 1
	d["seq"] = seq
	var f := FileAccess.open(dir + "cmd.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	await until(func(): return int(status().get("seq", -1)) >= seq, 8.0)


func gcmd(tag: String, d: Dictionary) -> void:
	gseq[tag] += 1
	d["seq"] = gseq[tag]
	var f := FileAccess.open(dir + tag + "_cmd.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	await until(func(): return int(gs(tag).get("seq", -1)) >= int(gseq[tag]), 8.0)


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


func ore(pid: int) -> int:
	return int(rec(pid).get("inv", {}).get(ORE, 0))


func coins(pid: int) -> int:
	return int(rec(pid).get("coins", -1))


func all_ore() -> int:
	return ore(host_pid) + ore(ann) + ore(cara) + ore(dan)


func leak() -> int:
	return int(status().get("coin_leak", 999))


## A player's reference in the host's world: the host's own character is "player", a guest "player:<pid>".
func ref(pid: int) -> String:
	return "player" if pid == host_pid else "player:%d" % pid


func tag_of(pid: int) -> String:
	return "g2" if pid == cara else "g3"


func host_offers(kind: String, from_pid: int, to_pid: int) -> Array:
	var out := []
	for o in status().get("offers", []):
		if str(o.kind) == kind and str(o["from"]) == ref(from_pid) and str(o.to) == ref(to_pid):
			out.append(o)
	return out


func key(code: int) -> void:
	main.scheme = "kbm"
	main.ui.set_scheme("kbm")
	for down in [true, false]:
		var e := InputEventKey.new()
		e.physical_keycode = code
		e.keycode = code
		e.pressed = down
		Input.parse_input_event(e)
		await process_frame
	await process_frame


func pad(button: int) -> void:
	main.scheme = "gamepad"
	main.ui.set_scheme("gamepad")
	for down in [true, false]:
		var e := InputEventJoypadButton.new()
		e.button_index = button
		e.pressed = down
		Input.parse_input_event(e)
		await process_frame
	await process_frame


func tap_pid(pid: int) -> void:
	main.scheme = "touch"
	main.ui.set_scheme("touch")
	var sp: ActorSprite = main.avatar_sprites.get(pid)
	if sp == null:
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


func join_ann() -> bool:
	main.net.join("127.0.0.1", port, ID_A, "Ann", "oak")
	return await until(func(): return main.guest_world, 40.0)


func start_host(mode: String) -> bool:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + "status.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + "cmd.json"))
	seq = 0
	host_proc = spawn("res://tests/net_host.gd", [str(port), str(dport), mode, dir, "4"])
	return await until(func(): return status().get("hosting", false), 120.0)


func start_guest(tag: String, k: String, nm: String) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + tag + "_status.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + tag + "_cmd.json"))
	gseq[tag] = 0
	procs[tag] = spawn("res://tests/net_interact_guest.gd", [str(port), k, nm, "oak", dir, tag])


## The guests' processes asked to join again (after the host came back or they left).
func rejoin(tag: String) -> bool:
	await gcmd(tag, {"cmd": "join"})
	return await until(func(): return gs(tag).get("welcomed", false), 40.0)


## Everyone stood together by the host (net_host "stage"), repeated until the host's records and Ann's copy agree.
func stage() -> void:
	for attempt in 4:
		await command({"cmd": "stage"})
		main.move_to = Vector2.INF
		for t in procs:
			if t != "eve":
				await gcmd(t, {"cmd": "still"})
		await wait(0.8)
		var sp: Array = status().get("spot", [])
		if sp.size() != 2:
			continue
		var want := Vector2(float(sp[0]), float(sp[1])) + Vector2(1, 0)
		var host_has: Array = rec(ann).get("pos", [0, 0])
		if main.world.player.pos.distance_to(want) < 0.1 and Vector2(float(host_has[0]), float(host_has[1])).distance_to(want) < 0.1:
			break
	main.player_sprite.face(Vector2.LEFT)
	main.target_pref = ""
	await wait(0.6)


## Every participant's copy of the shared world against the host's at one frozen moment (tests/net_snapshot.gd).
func consistent(label: String, guests: Array) -> void:
	# every copy live first: the clock and the players in play have reached it (a guest that has just rejoined, a slow frame)
	var n_in: int = status().get("connected", []).size()
	await until(func(): return main.world.minutes >= float(status().get("minutes", 0)) - 2.0 and main.other_players().size() == n_in, 8.0)
	for t in guests:
		await until(func(): return float(gs(t).get("minutes", 0)) >= float(status().get("minutes", 0)) - 2.0 and (gs(t).get("others", []) as Array).size() == n_in, 8.0)
	await command({"cmd": "freeze"})
	await wait(0.4)                                     # what was already on its way arrives
	var s0: int = main.net.syncs
	await command({"cmd": "dump", "keys": SAME, "full": true})
	await until(func(): return main.net.syncs > s0, 2.0)
	await wait(0.8)
	var dump := _read("dump.json")
	var bad: Array = Snap.compare(main.world, main.net.my_pid, dump, SAME)
	check(bad.is_empty(), "%s: Ann's copy is the host's world (sections, offers, clock, %d villagers, %d players, her pack) %s" % [label,
		(dump.get("npcs", {}) as Dictionary).size(), (dump.get("players", {}) as Dictionary).size(), bad])
	for t in guests:
		await gcmd(t, {"cmd": "compare", "keys": SAME})
		var c: Dictionary = gs(t).get("cmp", {})
		check(int(c.get("seq", -1)) == int(gseq[t]) and (c.get("bad", ["no answer"]) as Array).is_empty(),
			"%s: %s's copy is the host's world %s" % [label, {"g2": "Cara", "g3": "Dan"}[t], c.get("bad", ["no answer"])])
	await command({"cmd": "thaw"})


## Each guest's own pack and purse on its machine as the host has them; coins conserved on the host.
func packs_agree(label: String) -> void:
	await wait(1.3)                                     # each guest's own record comes every second (s_self)
	var ok: bool = main.world.player.inv.count(ORE) == ore(ann) and main.world.player.coins == coins(ann)
	for t in ["g2", "g3"]:
		var g := gs(t)
		var pid := int(g.get("pid", 0))
		ok = ok and int(g.get("inv", {}).get(ORE, 0)) == ore(pid) and int(g.get("coins", -2)) == coins(pid)
	check(ok, "%s: every guest's own pack and purse is the host's record of it" % label)
	check(leak() == 0, "%s: coins conserved on the host (leak %d)" % [label, leak()])


## Requests from several players applied in one frame of the host: held as they arrive, released together.
func hold() -> void:
	await command({"cmd": "hold"})


## `n` requests (at least, with `more`: an action whose interface sends more than its one verb) are held, then applied in one frame.
func release(n: int, what: String, more := false) -> void:
	var got: bool = await until(func(): return int(status().get("held", 0)) >= n, 10.0)
	await wait(0.3)
	var h := int(status().get("held", 0))
	check(got and (h == n or (more and h >= n)), "%s: the host has the %d requests at once (%d held)" % [what, n, h])
	var f0 := int(status().get("batch", {}).get("frame", -1))
	await command({"cmd": "release"})
	check(await until(func(): return int(status().get("batch", {}).get("frame", -1)) != f0 and int(status().get("batch", {}).get("applied", -1)) >= 0, 5.0)
		and int(status().batch.applied) == h and int(status().batch.held) == h, "%s: and applies all %d in one frame (%s)" % [what, h, status().get("batch", {})])


# ---------------------------------------------------------------- the run ------------------------
func _run() -> void:
	var t0 := Time.get_ticks_msec()
	check(await start_host("new"), "the host opens its world for four")
	check(await join_ann(), "Ann joins (this process)")
	start_guest("g2", ID_C, "Cara")
	check(await until(func(): return gs("g2").get("welcomed", false) and status().get("connected", []).size() == 2, 60.0), "Cara joins (1 host + 2 guests)")
	host_pid = int(status().host_pid)
	ann = main.net.my_pid
	cara = int(gs("g2").pid)
	await stage()
	await _one_and_two()
	start_guest("g3", ID_D, "Dan")
	check(await until(func(): return gs("g3").get("welcomed", false) and status().get("connected", []).size() == 3, 60.0), "Dan joins (1 host + 3 guests: four players)")
	dan = int(gs("g3").pid)
	check(host_pid != ann and ann != cara and cara != dan and dan != host_pid and ann != dan and host_pid != cara, "four players, four permanent pids (%d %d %d %d)" % [host_pid, ann, cara, dan])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + "eve.json"))
	var eve := spawn("res://tests/net_guest.gd", [str(port), ID_E, "Eve", "oak", "eve.json", dir])
	check(await until(func(): return not _read("eve.json").is_empty(), 60.0) and str(_read("eve.json").get("refusal", "")) == "full"
		and status().get("connected", []).size() == 3, "a fifth player is refused: the world is full (%s)" % [_read("eve.json")])
	if OS.is_process_running(eve):
		OS.kill(eve)
	await command({"cmd": "give", "id": ORE, "n": 6})
	await command({"cmd": "take_host", "id": ORE})
	await stage()
	await _everyone_chooses_everyone()
	await stage()
	await command({"cmd": "fell"})
	check(await until(func(): return str(status().get("felled", "")) != "", 3.0), "a tree is felled on the host (%s): its record loses its growth date" % status().get("felled", ""))
	await wait(NetSync.SYNC_SECONDS + 1.0)
	await consistent("1+3, staged, after a tree was felled", ["g2", "g3"])
	await _same_tick()
	await _messages()
	await stage()
	await consistent("1+3, after the concurrent actions and messages", ["g2", "g3"])
	await _guest_away_and_back()
	await _save_live_and_restart()
	await _host_killed()
	check(leak() == 0, "coins conserved over the whole run")
	for t in ["g2", "g3"]:
		await gcmd(t, {"cmd": "quit"})
	await command({"cmd": "quit"})
	await until(func(): return not OS.is_process_running(host_proc), 20.0)
	for t in procs:
		if OS.is_process_running(procs[t]):
			OS.kill(procs[t])
	check(not FileAccess.file_exists(dir + "guest_never_saves.json") and not FileAccess.file_exists(dir + "g2_unused.json") and not FileAccess.file_exists(dir + "g3_unused.json"),
		"no guest ever saved the host's world")
	print("%d checks, %d failures (%.0f s)" % [checks, failures, (Time.get_ticks_msec() - t0) / 1000.0])
	quit(1 if failures > 0 else 0)


# ---------------------------------------------------------------- one host, two guests ----------
func _one_and_two() -> void:
	var others: Array = main.other_players().map(func(q): return q.pid)
	check(others.has(host_pid) and others.has(cara), "1+2, Ann's copy has the host and Cara in play (%s)" % [others])
	check(await until(func(): return (gs("g2").get("others", []) as Array).map(func(x): return int(x)).has(ann) and (gs("g2").get("others", []) as Array).map(func(x): return int(x)).has(host_pid), 5.0),
		"1+2, Cara's copy has Ann and the host in play (%s)" % [gs("g2").get("others", [])])
	main._find_target()
	check(str(main.target.get("kind", "")) == "player" and int(main.target.pid) == host_pid, "1+2, Ann faces the host: her target")
	await tap_pid(cara)
	check(await until(func(): return main.ui.is_open("player") and main.ui.title_label.text == "CARA (PLAYER)", 3.0), "1+2, Ann (touch) taps Cara: her window (%s)" % main.ui.title_label.text)
	main.ui.hide_all()
	await stage()
	check(await until(func(): return int(hui().get("target_pid", 0)) == ann, 5.0), "1+2, the host faces Ann: its target (%s)" % [hui().get("pids", [])])
	var hn := str(rec(host_pid).get("name", "?")).to_upper()
	await gcmd("g2", {"cmd": "tap_pid", "pid": host_pid})
	check(await until(func(): return str(gs("g2").get("ui", {}).get("title", "")) == "%s (PLAYER)" % hn, 3.0), "1+2, Cara (touch) taps the host: its window (%s)" % gs("g2").get("ui", {}).get("title", ""))
	await gcmd("g2", {"cmd": "press", "name": "PlayerTalk"})
	await gcmd("g2", {"cmd": "press", "name": "Hello!"})
	check(await until(func(): return (hui().get("messages", []) as Array).any(func(m): return str(m).contains("Hello!")), 6.0), "1+2, Cara's message reaches the host's journal")
	await gcmd("g2", {"cmd": "close"})
	await stage()
	await consistent("1+2", ["g2"])


func _cara_sees(pids: Array) -> bool:
	var have: Array = (gs("g2").get("ui", {}).get("pids", []) as Array).map(func(x): return int(x))
	return pids.all(func(p): return have.has(p))


# ---------------------------------------------------------------- choosing --------------------------
## Twelve choices: each of the four players chooses each of the other three, by its own input paths, and the window names them. A
## tap or a click chooses the character under it; keys and a pad choose among the people in front of the player (World.TARGET_PROBE):
## the player turns to someone, Q (the D-pad) goes round those there, E (A) opens the one chosen.
func _everyone_chooses_everyone() -> void:
	var names := {}
	for pid in [host_pid, ann, cara, dan]:
		names[pid] = str(rec(pid).get("name", "?")).to_upper()
	# the host, the mouse: a left click on each
	for pid in [ann, cara, dan]:
		await command({"cmd": "click_pid", "pid": pid})
		check(await until(func(): return str(hui().get("title", "")) == "%s (PLAYER)" % names[pid], 3.0), "the host (mouse) clicks %s: their window (%s)" % [names[pid], hui().get("title", "")])
		await command({"cmd": "close"})
		await stage()
	# the host, keys: turned to each, Q to them, E
	for pid in [ann, cara, dan]:
		var at: Array = rec(pid).get("pos", [0, 0])
		await command({"cmd": "face", "x": float(at[0]), "y": float(at[1])})
		await until(func(): return (hui().get("pids", []) as Array).map(func(x): return int(x)).has(pid), 3.0)
		var n := 0
		while int(hui().get("target_pid", 0)) != pid and n < 6:
			var was := int(hui().get("target_pid", 0))
			await command({"cmd": "key", "code": KEY_Q})
			await until(func(): return int(hui().get("target_pid", 0)) != was, 2.0)     # one press, one step (a slow frame is waited for)
			n += 1
		await command({"cmd": "key", "code": KEY_E})
		check(await until(func(): return str(hui().get("title", "")) == "%s (PLAYER)" % names[pid], 3.0),
			"the host (keys) turns to %s, Q (%d) and E: their window (%s; in front %s)" % [names[pid], n, hui().get("title", ""), hui().get("pids", [])])
		await command({"cmd": "close"})
	await stage()
	# Ann, touch: a tap on each
	for pid in [host_pid, cara, dan]:
		await tap_pid(pid)
		check(await until(func(): return main.ui.is_open("player") and main.ui.title_label.text == "%s (PLAYER)" % names[pid], 3.0), "Ann (touch) taps %s: their window (%s)" % [names[pid], main.ui.title_label.text])
		main.ui.hide_all()
		await stage()
	# Ann, a pad: turned to each, the D-pad to them, A, then B back to play
	for pid in [host_pid, cara, dan]:
		main.player_sprite.face(main.world.player_by_pid(pid).pos - main.world.player.pos)
		main._find_target()
		var n := 0
		while int(main.target.get("pid", 0)) != pid and n < 4:
			await pad(JOY_BUTTON_DPAD_RIGHT)
			n += 1
		await pad(JOY_BUTTON_A)
		check(main.ui.is_open("player") and main.ui.title_label.text == "%s (PLAYER)" % names[pid], "Ann (pad) turns to %s, the D-pad (%d) and A: their window (%s)" % [names[pid], n, main.ui.title_label.text])
		await pad(JOY_BUTTON_B)
		check(not main.ui.modal(), "B: back to play")
	# Cara, touch
	for pid in [host_pid, ann, dan]:
		await gcmd("g2", {"cmd": "tap_pid", "pid": pid})
		check(await until(func(): return str(gs("g2").get("ui", {}).get("title", "")) == "%s (PLAYER)" % names[pid], 3.0), "Cara (touch) taps %s: their window" % names[pid])
		await gcmd("g2", {"cmd": "close"})
		await stage()
	# Dan, the mouse, then keys
	for pid in [host_pid, ann, cara]:
		await gcmd("g3", {"cmd": "click_pid", "pid": pid})
		check(await until(func(): return str(gs("g3").get("ui", {}).get("title", "")) == "%s (PLAYER)" % names[pid], 3.0), "Dan (mouse) clicks %s: their window (%s)" % [names[pid], gs("g3").get("ui", {}).get("title", "")])
		await gcmd("g3", {"cmd": "close"})
		await stage()
	for pid in [host_pid, ann, cara]:
		var at2: Array = rec(pid).get("pos", [0, 0])
		await gcmd("g3", {"cmd": "face", "x": float(at2[0]), "y": float(at2[1])})
		await wait(0.2)
		await until(func(): return (gs("g3").get("ui", {}).get("pids", []) as Array).map(func(x): return int(x)).has(pid), 3.0)
		var n := 0
		while int(gs("g3").get("ui", {}).get("target_pid", 0)) != pid and n < 6:
			var was := int(gs("g3").get("ui", {}).get("target_pid", 0))
			await gcmd("g3", {"cmd": "key", "code": KEY_Q})
			await until(func(): return int(gs("g3").get("ui", {}).get("target_pid", 0)) != was, 2.0)
			n += 1
		await gcmd("g3", {"cmd": "key", "code": KEY_E})
		check(await until(func(): return str(gs("g3").get("ui", {}).get("title", "")) == "%s (PLAYER)" % names[pid], 3.0),
			"Dan (keys) turns to %s, Q (%d) and E: their window (%s; in front %s)" % [names[pid], n, gs("g3").get("ui", {}).get("title", ""), gs("g3").get("ui", {}).get("pids", [])])
		await gcmd("g3", {"cmd": "close"})


# ---------------------------------------------------------------- the same tick --------------------
func _same_tick() -> void:
	await stage()
	# 1. one ore, offered by the host to Ann and to Cara; both accept in the same frame: it moves once
	await command({"cmd": "give_host", "id": ORE, "n": 1})
	await command({"cmd": "offer", "kind": "gift", "to": ann, "item": ORE, "qty": 1})
	await command({"cmd": "offer", "kind": "gift", "to": cara, "item": ORE, "qty": 1})
	check(await until(func(): return main.world.offers_to(main.world.player).size() == 1 and (gs("g2").get("offers", []) as Array).any(func(o): return str(o.to) == "player:%d" % cara), 5.0),
		"the host's one ore is offered to Ann and to Cara; both are told (%s)" % status().get("why_last", ""))
	var o_ann := host_offers("gift", host_pid, ann)
	var o_cara := host_offers("gift", host_pid, cara)
	var total := all_ore()
	var a0 := ore(ann)
	var c0 := ore(cara)
	await hold()
	main.ui.show_player(host_pid)
	await process_frame
	check(not o_ann.is_empty() and press("OfferAccept%d" % int(o_ann[0].id)), "Ann accepts in the host's window")
	await gcmd("g2", {"cmd": "show_player", "pid": host_pid})
	await gcmd("g2", {"cmd": "press", "name": "OfferAccept%d" % (int(o_cara[0].id) if not o_cara.is_empty() else -1)})
	await release(2, "two acceptances of one gift")
	await wait(0.6)
	var got_a := ore(ann) - a0
	var got_c := ore(cara) - c0
	check(got_a + got_c == 1 and ore(host_pid) == 0 and all_ore() == total, "the ore moves once: Ann +%d, Cara +%d, the host %d, %d in all (was %d)" % [got_a, got_c, ore(host_pid), all_ore(), total])
	check(host_offers("gift", host_pid, ann).is_empty() and host_offers("gift", host_pid, cara).is_empty(), "both offers are settled on the host (one given, one no longer possible)")
	var loser_said: Array = (main.net.replies.values().map(func(r): return str(r.get("text", ""))) if got_a == 0 else gs("g2").get("replies", []))
	check(loser_said.any(func(x): return str(x).contains("no longer has it")), "the one too late is told the host no longer has it")
	main.ui.hide_all()
	await gcmd("g2", {"cmd": "close"})
	await packs_agree("one gift, two acceptances")

	# 2. Dan can pay for one of two sales, and accepts both in the same frame: one sale, paid once
	var price: int = coins(dan) / 2 + 1
	var d0 := coins(dan)
	var dore := ore(dan)
	main.world.player_offer("sell", dan, ORE, 1, null, price)
	await gcmd("g2", {"cmd": "offer", "kind": "sell", "to": dan, "item": ORE, "qty": 1, "price": price})
	check(await until(func(): return (gs("g3").get("offers", []) as Array).filter(func(o): return str(o.kind) == "sell").size() == 2, 6.0),
		"Ann and Cara each offer Dan an ore for %d coins (he has %d); both reach his copy" % [price, d0])
	var s_ann := host_offers("sell", ann, dan)
	var s_cara := host_offers("sell", cara, dan)
	var ac := coins(ann)
	var cc := coins(cara)
	total = all_ore()
	await hold()
	await gcmd("g3", {"cmd": "show_player", "pid": ann})
	await gcmd("g3", {"cmd": "press", "name": "OfferAccept%d" % (int(s_ann[0].id) if not s_ann.is_empty() else -1)})
	await gcmd("g3", {"cmd": "show_player", "pid": cara})
	await gcmd("g3", {"cmd": "press", "name": "OfferAccept%d" % (int(s_cara[0].id) if not s_cara.is_empty() else -1)})
	await release(2, "two sales accepted at once")
	await wait(0.6)
	var paid := (coins(ann) - ac) + (coins(cara) - cc)
	check(coins(dan) == d0 - price and paid == price and ore(dan) == dore + 1 and all_ore() == total,
		"one sale goes through: Dan pays %d once (%d -> %d), the sellers get %d, he has one ore more" % [price, d0, coins(dan), paid])
	var waiting := host_offers("sell", ann, dan) + host_offers("sell", cara, dan)
	check(waiting.size() == 1, "the sale he could not pay waits on the host, answered with why (%s)" % [gs("g3").get("replies", []).slice(-2)])
	await gcmd("g3", {"cmd": "close"})
	await wait(NetSync.SYNC_SECONDS + 1.5)
	var dan_has: Array = (gs("g3").get("offers", []) as Array).filter(func(o): return str(o.kind) == "sell" and str(o.to) == "player:%d" % dan)
	check(dan_has.size() == 1 and not waiting.is_empty() and int(dan_has[0].id) == int(waiting[0].id),
		"Dan's copy still shows the waiting sale, to answer when he can pay (host %s, his copy %s)" % [waiting.map(func(o): return int(o.id)), dan_has.map(func(o): return int(o.id))])
	await packs_agree("two sales, one purse")
	# he tries the waiting one again, still short: the host refuses and nothing else changes; the offer must stay on his screen
	if not waiting.is_empty():
		var from_pid := ann if str(waiting[0]["from"]) == "player:%d" % ann else cara
		await gcmd("g3", {"cmd": "show_player", "pid": from_pid})
		await gcmd("g3", {"cmd": "press", "name": "OfferAccept%d" % int(waiting[0].id)})
		check(await until(func(): return (gs("g3").get("replies", []) as Array).count("You haven't %d coins." % price) >= 2, 5.0), "Dan accepts it again, still short: refused again")
		await gcmd("g3", {"cmd": "close"})
		await wait(NetSync.SYNC_SECONDS + 1.5)
		check((host_offers("sell", ann, dan) + host_offers("sell", cara, dan)).size() == 1
			and (gs("g3").get("offers", []) as Array).any(func(o): return int(o.id) == int(waiting[0].id)),
			"the refused acceptance leaves the offer waiting on the host and on Dan's screen (his copy: %s)" % [(gs("g3").get("offers", []) as Array).filter(func(o): return str(o.kind) == "sell").map(func(o): return int(o.id))])
	# the unpaid sale withdrawn by its answer: declined
	if not waiting.is_empty():
		await gcmd("g3", {"cmd": "show_player", "pid": ann if str(waiting[0]["from"]) == "player:%d" % ann else cara})
		await gcmd("g3", {"cmd": "press", "name": "OfferDecline%d" % int(waiting[0].id)})
		check(await until(func(): return (host_offers("sell", ann, dan) + host_offers("sell", cara, dan)).is_empty(), 5.0), "Dan declines the other: nothing waits")
		await gcmd("g3", {"cmd": "close"})

	# 3. two gifts crossing: offered in one frame, accepted in one frame
	total = all_ore()
	a0 = ore(ann)
	c0 = ore(cara)
	await hold()
	main.world.player_offer("gift", cara, ORE, 1)
	await gcmd("g2", {"cmd": "offer", "kind": "gift", "to": ann, "item": ORE, "qty": 1})
	await release(2, "two gifts offered at once")
	check(await until(func(): return not host_offers("gift", ann, cara).is_empty() and not host_offers("gift", cara, ann).is_empty(), 5.0), "both gifts wait on the host")
	await until(func(): return main.world.offers_to(main.world.player).size() == 1, 5.0)
	var g_to_ann := host_offers("gift", cara, ann)
	var g_to_cara := host_offers("gift", ann, cara)
	await hold()
	main.ui.show_player(cara)
	await process_frame
	check(not g_to_ann.is_empty() and press("OfferAccept%d" % int(g_to_ann[0].id)), "Ann accepts Cara's")
	await gcmd("g2", {"cmd": "show_player", "pid": ann})
	await gcmd("g2", {"cmd": "press", "name": "OfferAccept%d" % (int(g_to_cara[0].id) if not g_to_cara.is_empty() else -1)})
	await release(2, "two crossing gifts accepted at once")
	await wait(0.6)
	check(ore(ann) == a0 and ore(cara) == c0 and all_ore() == total and host_offers("gift", ann, cara).is_empty() and host_offers("gift", cara, ann).is_empty(),
		"each gives one and gets one: Ann %d, Cara %d, %d in all" % [ore(ann), ore(cara), all_ore()])
	main.ui.hide_all()
	await gcmd("g2", {"cmd": "close"})
	await packs_agree("two crossing gifts")

	# 4. Ann and Dan pick one plant in the same frame: one gets it
	await _one_plant()


func _one_plant() -> void:
	var w: World = main.world
	var pl := {}
	for p in w.plants:
		if str(p.state) == "ripe" and str(status().plants.get("%d,%d" % [int(p.x), int(p.y)], "")) == "ripe" and Vector2(int(p.x), int(p.y)).distance_to(w.player.pos) < 40.0:
			pl = p
			break
	check(not pl.is_empty(), "a ripe plant for two")
	if pl.is_empty():
		return
	var cell := Vector2i(int(pl.x), int(pl.y))
	var spots := []
	for off in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
		if spots.size() < 2 and not w.map.is_solid_world(cell + off):
			spots.append(Vector2(cell + off) + Vector2(0.5, 0.5))
	check(spots.size() == 2, "two places beside it")
	if spots.size() < 2:
		return
	await command({"cmd": "put", "pid": ann, "x": spots[0].x, "y": spots[0].y})
	await command({"cmd": "put", "pid": dan, "x": spots[1].x, "y": spots[1].y})
	await gcmd("g3", {"cmd": "still"})
	main.move_to = Vector2.INF
	await until(func(): return w.player.pos.distance_to(spots[0]) < 0.1 and Vector2(rec(dan).pos[0], rec(dan).pos[1]).distance_to(spots[1]) < 0.1, 4.0)
	var inv_a: Dictionary = rec(ann).get("inv", {}).duplicate()
	var inv_d: Dictionary = rec(dan).get("inv", {}).duplicate()
	var ga0: int = main.gain_log.size()
	var gd0: int = (gs("g3").get("gains", []) as Array).size()
	var ann_told := []
	await hold()
	main.select_resource(ResourceNodes.node_at(w, cell, true), false)
	await gcmd("g3", {"cmd": "pick", "x": cell.x, "y": cell.y})
	await release(2, "two players picking one plant", true)
	var end := Time.get_ticks_msec() + 2500
	while Time.get_ticks_msec() < end:                  # what Ann's screen says, as it comes
		if main.ui.toast.visible and (ann_told.is_empty() or ann_told[-1] != main.ui.toast.text):
			ann_told.append(main.ui.toast.text)
		await process_frame
	var gain_a := _gain(inv_a, rec(ann).get("inv", {}))
	var gain_d := _gain(inv_d, rec(dan).get("inv", {}))
	var yld := ResourceNodes.products(ResourceNodes.def_for("plant", str(pl.kind)))
	var n_yld := 0
	for k in yld:
		n_yld += int(yld[k])
	check((gain_a == 0) != (gain_d == 0) and gain_a + gain_d > 0 and gain_a + gain_d <= maxi(n_yld, 1) * 3,
		"one of them picks it: Ann +%d, Dan +%d (a picking gives %s)" % [gain_a, gain_d, yld])
	check(str(status().plants.get("%d,%d" % [cell.x, cell.y], "")) == "picked", "the host's plant is picked once")
	var loser_results: Array = (gs("g3").get("results", []) as Array) if gain_a > 0 else main.net.replies.values().filter(func(r): return str(r.get("path", "")) == "player_pick_plant").map(func(r): return JSON.stringify(r.get("result")))
	check(loser_results.has("{}"), "the host gives the second picker nothing (its answer: %s)" % [loser_results.slice(-3)])
	var gains_a: Array = main.gain_log.slice(ga0).map(func(g): return str(g[1]))
	var gains_d: Array = (gs("g3").get("gains", []) as Array).slice(gd0)
	var told_d: Array = gs("g3").get("toasts", [])
	var winner_gains: Array = gains_a if gain_a > 0 else gains_d
	var loser_gains: Array = gains_d if gain_a > 0 else gains_a
	var loser_told: Array = told_d if gain_a > 0 else ann_told
	check(winner_gains.size() >= 1 and str(winner_gains[0]).begins_with("+"), "the one who picked it is shown what came (%s)" % [winner_gains])
	check(loser_gains.is_empty() and loser_told.has("Nothing left to pick."),
		"the other is shown the truth, \"Nothing left to pick.\", and no gain (shown %s; gains %s)" % [loser_told.slice(-4), loser_gains])
	await packs_agree("one plant, two pickers")


func _gain(before: Dictionary, after: Dictionary) -> int:
	var n := 0
	for k in after:
		n += maxi(0, int(after[k]) - int(before.get(k, 0)))
	return n


# ---------------------------------------------------------------- messages -------------------------
func _messages() -> void:
	await stage()
	# two senders to Dan, turn about: each arrives once, each sender's in the order sent, Dan's copy in the host's order
	for i in 3:
		main.world.player_offer("say", dan, "", 0, null, 0, 0, "Ann %d" % (i + 1))
		await wait(0.15)
		await gcmd("g2", {"cmd": "say", "to": dan, "text": "Cara %d" % (i + 1)})
		await wait(0.15)
	var host_seq := func() -> Array:
		var l := (status().get("offers", []) as Array).filter(func(o): return str(o.kind) == "say" and str(o.to) == "player:%d" % dan)
		l.sort_custom(func(x, y): return int(x.id) < int(y.id))
		return l.map(func(o): return str(o.text))
	check(await until(func(): return host_seq.call().size() == 6, 6.0), "all six messages reach the host, once each (%s)" % [host_seq.call()])
	var hs: Array = host_seq.call()
	check(hs.filter(func(x): return str(x).begins_with("Ann")) == ["Ann 1", "Ann 2", "Ann 3"] and hs.filter(func(x): return str(x).begins_with("Cara")) == ["Cara 1", "Cara 2", "Cara 3"],
		"each sender's messages in the order sent (%s)" % [hs])
	check(await until(func(): return (gs("g3").get("offers", []) as Array).filter(func(o): return str(o.kind) == "say" and str(o.to) == "player:%d" % dan).map(func(o): return str(o.text)) == hs, 6.0),
		"Dan's copy holds the same six in the host's order (%s)" % [(gs("g3").get("offers", []) as Array).map(func(o): return [o.kind, o.get("text", "")])])
	check(await until(func(): return (gs("g3").get("messages", []) as Array).any(func(m): return str(m).contains("Cara 3")), 6.0), "and his screen kept the last in his journal")
	# a burst: five from Ann in one frame to Cara
	for i in 5:
		main.world.player_offer("say", cara, "", 0, null, 0, 0, "burst %d" % (i + 1))
	var want := ["burst 1", "burst 2", "burst 3", "burst 4", "burst 5"]
	check(await until(func(): return (gs("g2").get("offers", []) as Array).filter(func(o): return str(o.kind) == "say" and str(o.text).begins_with("burst")).map(func(o): return str(o.text)) == want, 8.0),
		"five messages sent in one frame reach Cara once each, in order")
	await _private("after the messages")
	# a private offer from the host to Cara: Dan and Ann never hold it
	await command({"cmd": "give_host", "id": ORE, "n": 1})
	await command({"cmd": "offer", "kind": "gift", "to": cara, "item": ORE, "qty": 1})
	check(await until(func(): return (gs("g2").get("offers", []) as Array).any(func(o): return str(o.kind) == "gift" and str(o["from"]) == "player"), 5.0), "the host offers Cara an ore: she has it")
	await wait(NetSync.SYNC_SECONDS + 1.0)
	await _private("after the host's offer to Cara")
	var oc := host_offers("gift", host_pid, cara)
	if not oc.is_empty():
		await gcmd("g2", {"cmd": "show_player", "pid": host_pid})
		await gcmd("g2", {"cmd": "press", "name": "OfferDecline%d" % int(oc[0].id)})
		await gcmd("g2", {"cmd": "close"})
	await command({"cmd": "take_host", "id": ORE})


## Each copy holds only the offers and messages its player sent or received: none between two other players, none of their words.
func _private(label: String) -> void:
	var me := "player:%d" % ann
	var foreign_a: Array = main.world.offers.filter(func(o): return str(o["from"]) != me and str(o.to) != me)
	check(foreign_a.is_empty() and not main.world.offers.any(func(o): return str(o.get("text", "")) in ["Cara 1", "Cara 2", "Cara 3"]),
		"%s: Ann's copy holds no offer or message between others (%d)" % [label, foreign_a.size()])
	for t in ["g2", "g3"]:
		var g := gs(t)
		var texts: Array = (g.get("offers", []) as Array).map(func(o): return str(o.get("text", "")))
		# Dan must not hold Ann's burst to Cara; Cara must not hold Ann's messages to Dan (her own to Dan are hers)
		var theirs: Array = ["burst 1", "burst 2", "burst 3", "burst 4", "burst 5"] if t == "g3" else ["Ann 1", "Ann 2", "Ann 3"]
		var others_words := texts.filter(func(x): return theirs.has(str(x)))
		check(int(g.get("foreign_offers", -1)) == 0 and others_words.is_empty(),
			"%s: %s's copy holds no offer or message between others (%d; %s)" % [label, {"g2": "Cara", "g3": "Dan"}[t], int(g.get("foreign_offers", -1)), others_words])


# ---------------------------------------------------------------- a guest away and back -------------
func _guest_away_and_back() -> void:
	await stage()
	# Cara offers Dan an ore; Dan leaves before answering; he comes back and it is still his to answer
	await gcmd("g2", {"cmd": "offer", "kind": "gift", "to": dan, "item": ORE, "qty": 1})
	check(await until(func(): return not host_offers("gift", cara, dan).is_empty(), 5.0), "Cara offers Dan an ore")
	var o := host_offers("gift", cara, dan)
	await gcmd("g3", {"cmd": "leave"})
	check(await until(func(): return status().get("connected", []).size() == 2 and rec(dan).get("away", false), 6.0), "Dan leaves: away on the host")
	check(await until(func(): return not main.other_players().map(func(q): return q.pid).has(dan), 3.0), "Ann's copy no longer has Dan in play")
	main._find_target()
	check(not main.target_options.map(func(x): return int(x.get("pid", 0))).has(dan), "nobody can choose him")
	check(not gs("g3").get("welcomed", true) and not gs("g3").get("world", true), "Dan's own machine is out of the world: it can do nothing in it")
	var d_ore := ore(dan)
	var c_ore := ore(cara)
	check(await rejoin("g3"), "Dan comes back")
	check(int(gs("g3").pid) == dan, "as the same character (pid %d)" % int(gs("g3").pid))
	check(int(gs("g3").get("foreign_offers", -1)) == 0 and (gs("g3").get("journal_refs", []) as Array).all(func(r): return str(r) == "player:%d" % dan),
		"the world he is sent holds only his own offers and his own journal (%d others' offers; journals %s)" % [int(gs("g3").get("foreign_offers", -1)), gs("g3").get("journal_refs", [])])
	check(await until(func(): return (gs("g3").get("offers", []) as Array).any(func(x): return not o.is_empty() and int(x.id) == int(o[0].id)), 5.0), "Cara's offer is still his to answer")
	await stage()
	await gcmd("g3", {"cmd": "show_player", "pid": cara})
	await gcmd("g3", {"cmd": "press", "name": "OfferAccept%d" % (int(o[0].id) if not o.is_empty() else -1)})
	check(await until(func(): return ore(dan) == d_ore + 1 and ore(cara) == c_ore - 1, 5.0), "he accepts: the ore moves once")
	await gcmd("g3", {"cmd": "close"})
	# Cara offers Ann an ore and leaves: Ann's acceptance moves nothing; back, Cara has her ore and no offer
	await gcmd("g2", {"cmd": "offer", "kind": "gift", "to": ann, "item": ORE, "qty": 1})
	check(await until(func(): return main.world.offers_to(main.world.player).any(func(x): return str(x.kind) == "gift" and str(x["from"]) == "player:%d" % cara), 5.0), "Cara offers Ann an ore")
	var o2: Array = main.world.offers_to(main.world.player).filter(func(x): return str(x.kind) == "gift")
	var total := all_ore()
	await gcmd("g2", {"cmd": "leave"})
	check(await until(func(): return rec(cara).get("away", false), 6.0), "Cara leaves")
	var a0 := ore(ann)
	c_ore = ore(cara)
	main.ui.show_player(cara)
	await process_frame
	var rid0: int = main.net._next_request
	main.world.player_answer(int(o2[0].id), true)
	await until(func(): return main.net.replies.has(rid0), 5.0)
	await wait(0.5)
	check(ore(ann) == a0 and ore(cara) == c_ore and all_ore() == total and str(main.net.replies.get(rid0, {}).get("result", "")) == "They are gone.",
		"Ann accepts what Cara offered before she left: nothing moves (%s; Ann %d/%d, Cara %d/%d)" % [main.net.replies.get(rid0, {}), ore(ann), a0, ore(cara), c_ore])
	main.ui.hide_all()
	check(await rejoin("g2"), "Cara comes back")
	check(int(gs("g2").pid) == cara and int(gs("g2").get("inv", {}).get(ORE, 0)) == c_ore and not (gs("g2").get("offers", []) as Array).any(func(x): return str(x.kind) == "gift" and str(x.to) == "player:%d" % ann),
		"as the same character, her ore still hers, the offer gone (%s)" % [gs("g2")])
	await stage()
	await consistent("after two guests left and came back", ["g2", "g3"])
	await packs_agree("after leaving and coming back")


# ---------------------------------------------------------------- the host away ---------------------
func _save_live_and_restart() -> void:
	await stage()
	await command({"cmd": "offer", "kind": "gift", "to": dan, "item": "bread", "qty": 1})
	if str(status().get("why_last", "")) != "":
		await command({"cmd": "give_host", "id": "bread", "n": 1})
		await command({"cmd": "offer", "kind": "gift", "to": dan, "item": "bread", "qty": 1})
	check(await until(func(): return not host_offers("gift", host_pid, dan).is_empty(), 4.0), "the host offers Dan a loaf; he does not answer yet (%s)" % status().get("why_last", ""))
	await command({"cmd": "save"})
	var sf := FileAccess.open(dir + "host_save.json", FileAccess.READ)
	var sv = JSON.parse_string(sf.get_as_text()) if sf != null else {}
	var in_save: Dictionary = sv.get("players", {}).get("by_pid", {}) if sv is Dictionary else {}
	check(in_save.size() == 4 and (sv.get("player_offers", {}).get("list", []) as Array).size() >= 1, "a save with three guests playing holds all four players and the pending offer (%d players)" % in_save.size())
	var before := {}
	for pid in [ann, cara, dan]:
		before[pid] = {"inv": rec(pid).get("inv", {}), "coins": coins(pid), "pos": rec(pid).get("pos", [])}
	await command({"cmd": "quit"})
	check(await until(func(): return not main.guest_world, 20.0), "the host saves and quits: Ann is out")
	check(await until(func(): return not gs("g2").get("welcomed", true) and not gs("g3").get("welcomed", true), 10.0)
		and not gs("g2").get("world", true) and not gs("g3").get("world", true) and main.world == null, "Cara and Dan are out too; no machine holds the world, nobody can act in it")
	await until(func(): return not OS.is_process_running(host_proc), 15.0)
	var saved: Dictionary = status().get("census", {})
	await wait(4.0)                                     # the host away a while
	check(await start_host("continue"), "the host comes back from its save")
	var loaded: Dictionary = status().get("census", {})
	check(str(saved.get("at", "")) == "saved" and str(loaded.get("at", "")) == "load" and absf(float(loaded.get("minutes", -1)) - float(saved.get("minutes", -2))) < 0.01
		and float(loaded.get("msec", 0)) - float(saved.get("msec", 0)) >= 4.0,
		"no minute passed while the host was away: %.2f at the save, %.2f at the load, %.1f s apart" % [float(saved.get("minutes", -1)), float(loaded.get("minutes", -1)), float(loaded.get("msec", 0)) - float(saved.get("msec", 0))])
	check(int(saved.get("coins", -1)) == int(loaded.get("coins", -2)) and JSON.stringify(saved.get("goods")) == JSON.stringify(loaded.get("goods")), "coins and goods are the same across the restart")
	check((loaded.get("away", {}) as Dictionary).values().filter(func(x): return x).size() == 3, "every guest out of play until they rejoin")
	check(await join_ann(), "Ann rejoins")
	check(await rejoin("g2") and await rejoin("g3"), "Cara and Dan rejoin")
	await wait(1.3)
	var same := true
	for pid in [ann, cara, dan]:
		same = same and JSON.stringify(rec(pid).get("inv", {})) == JSON.stringify(before[pid].inv) and coins(pid) == int(before[pid].coins) \
			and Vector2(float(rec(pid).pos[0]), float(rec(pid).pos[1])).distance_to(Vector2(float(before[pid].pos[0]), float(before[pid].pos[1]))) < 0.6
	check(same and main.net.my_pid == ann and int(gs("g2").pid) == cara and int(gs("g3").pid) == dan, "each comes back as the same character, with the same pack and purse, where they stood")
	var m0 := float(status().get("minutes", 0))
	await wait(2.0)
	check(float(status().get("minutes", 0)) > m0, "the world's time goes on again with the host")
	await stage()
	var o := host_offers("gift", host_pid, dan)
	check(o.size() == 1 and (gs("g3").get("offers", []) as Array).any(func(x): return int(x.id) == int(o[0].id)), "the pending offer was saved with the world and is still Dan's to answer")
	if not o.is_empty():
		var b0 := int(rec(dan).get("inv", {}).get("bread", 0))
		await gcmd("g3", {"cmd": "show_player", "pid": host_pid})
		await gcmd("g3", {"cmd": "press", "name": "OfferAccept%d" % int(o[0].id)})
		check(await until(func(): return int(rec(dan).get("inv", {}).get("bread", 0)) == b0 + 1, 5.0), "he accepts after the restart: the loaf moves once")
		await gcmd("g3", {"cmd": "close"})
	await consistent("after the host's restart", ["g2", "g3"])
	await packs_agree("after the host's restart")


func _host_killed() -> void:
	await command({"cmd": "crash"})
	check(await until(func(): return not main.guest_world and not gs("g2").get("welcomed", true) and not gs("g3").get("welcomed", true), 30.0),
		"the host is killed: every guest is out (\"%s\")" % main.ui.toast.text)
	await until(func(): return not OS.is_process_running(host_proc), 15.0)
	var saved: Dictionary = status().get("census", {})
	await wait(2.0)
	check(await start_host("continue"), "the host comes back from the save made before it was killed")
	var loaded: Dictionary = status().get("census", {})
	check(absf(float(loaded.get("minutes", -1)) - float(saved.get("minutes", -2))) < 0.01 and int(saved.get("coins", -1)) == int(loaded.get("coins", -2)),
		"no minute passed while it was gone (%.2f / %.2f), the coins the same" % [float(saved.get("minutes", -1)), float(loaded.get("minutes", -1))])
	check(await join_ann() and await rejoin("g2") and await rejoin("g3") and status().get("connected", []).size() == 3, "all three guests return")
	await stage()
	await consistent("after the host was killed", ["g2", "g3"])
	await packs_agree("after the host was killed")
