extends SceneTree
## Build 42 G4: MML-MP-05, MML-MP-06 and MML-MP-07 checked between two Godot processes on loopback (not real devices). This process
## is a guest (Ann) running the real game scene (main.gd), its network session tapped (tests/mp_g4_net_tap.gd) so that every
## welcome and section sync is checked as the text that came over the wire; tests/mp_g4_host.gd (tests/net_host.gd plus three
## commands) is the host in another process. In order:
##   join      the welcome to an unrelated guest carries none of the host's private records (ties, trade contacts, debts, crime
##             cases, contracts, law lessons, kept messages, purse, pack) (MP-07), and the guest is in play at once (MP-06);
##   marriage  the guest asks the host to marry, the host accepts (MP-D8): the public family links come over the wire; the host's
##             new private records (made after the marriage) never do, in any sync, nor anywhere in the guest's copy (MP-07,
##             household member);
##   sharing   the host's cart: its load withheld and pulling it refused before any agreement; the guest proposes tier 3 from its own
##             Players window (Asset sharing), the host accepts: the same tier both ways on the host, the load now in the guest's
##             copy, the guest pulls the cart; still nothing private on the wire (MP-05, MP-07);
##   away      the guest's app paused past the host's watchdog: the host drops it (away), does nothing in its name meanwhile, and
##             the host revokes the agreement while the guest is away; the guest comes back by itself to the same character, the
##             revocation stands (no tier in its copy, the load withheld, pulling refused), and it acts at once (MP-05 E8, MP-06 F2);
##   rejoin    tier 2 offered by the host and accepted from the guest's own Players window, paused and back again: the agreement
##             is still tier 2 (MP-05 E7); every welcome after a reconnect is private-record free (MP-07 G5).
## Menus as far as headless allows: the guest's Players window is built and its buttons pressed by their names and words; nothing
## is looked at on a screen.
##   godot --headless --path game --script res://tests/mp_g4_loopback_test.gd

const KEY := "fedcba9876543210fedcba9876543210"
var main
var tap
var failures := 0
var checks := 0
var dir := "user://test_mp_g4/"
var port := 0
var dport := 0
var host_pid := -1
var seq := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	port = 48300 + OS.get_process_id() % 40 * 2
	dport = port + 1
	DirAccess.make_dir_recursive_absolute(dir)
	for f in ["status.json", "cmd.json", "host_save.json", "host_save.json.bak", "dump.json", "g4.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + f))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = dir + "guest_never_saves.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


## The guest's NetSession replaced by the tapped one (same node name, so the host's calls reach it), wired as main.gd wires its own.
func _tap() -> void:
	var old: NetSession = main.net
	tap = load("res://tests/mp_g4_net_tap.gd").new()
	tap.main = main
	main.remove_child(old)
	old.free()
	main.add_child(tap)
	main.net = tap
	tap.changed.connect(func(t): main.ui.message(t, 8.0, "game"))
	tap.answered.connect(func(t): main.ui.message(t, 8.0))
	tap.verb_answered.connect(main._on_verb_answered)


# ---------------------------------------------------------------- helpers (as net_family_test.gd) ----
func spawn(script: String, args: Array) -> int:
	var a := ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", script, "--"] + args
	return OS.create_process(OS.get_executable_path(), a)


func read_json(name: String) -> Dictionary:
	var f := FileAccess.open(dir + name, FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if typeof(d) == TYPE_DICTIONARY else {}


func status() -> Dictionary:
	return read_json("status.json")


func g4() -> Dictionary:
	return read_json("g4.json")


func command(d: Dictionary) -> void:
	seq += 1
	d["seq"] = seq
	var f := FileAccess.open(dir + "cmd.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	await until(func(): return int(status().get("seq", -1)) >= seq and int(g4().get("seq", -1)) >= seq, 5.0)


func until(cond: Callable, secs: float) -> bool:
	var end := Time.get_ticks_msec() + int(secs * 1000.0)
	while Time.get_ticks_msec() < end:
		if cond.call():
			return true
		await process_frame
	return cond.call()


func wait(secs: float) -> void:
	await until(func(): return false, secs)


func rec(pid := 0) -> Dictionary:
	return status().get("players", {}).get(str(pid if pid > 0 else tap.my_pid), {})


func in_game() -> bool:
	return main.guest_world and tap.connected() and not tap.reconnecting


func act(c: Callable) -> Variant:
	var n0: int = tap.replies.size()
	var r = c.call()
	await until(func(): return tap.replies.size() > n0, 5.0)
	await wait(0.5)
	return r


func last_reply() -> Dictionary:
	var ks: Array = tap.replies.keys()
	ks.sort()
	return tap.replies[ks[ks.size() - 1]] if not ks.is_empty() else {}


## A verb's answer from the host (NetActions.apply_verb): "ok" says the request was applied; a refusal is the verb's own text.
func refused(r: Dictionary) -> bool:
	return not bool(r.get("ok", false)) or str(r.get("text", "")) != ""


func host_pid_() -> int:
	return int(status().get("host_pid", -1))


## What of the host's private records a text that came over the wire (or the guest's copy) holds: one line each, none is private.
func leaks(text: String) -> Array:
	var out := []
	if text.find("HOSTSECRET") >= 0:
		out.append("the host's kept message")
	var d = JSON.parse_string(text)
	if typeof(d) != TYPE_DICTIONARY:
		return out + ["unreadable"]
	var hid := int(g4().get("host_id", -999))
	var me_id := int(rec().get("id", 0))
	var me_ref := str(rec().get("ref", ""))
	var hostish := func(k: String) -> bool:
		var ids := Array(k.split(":")).map(func(s): return int(s))
		return ids.has(hid) and not ids.has(me_id)
	if d.get("relations") is Dictionary:
		for sec in ["ties", "trades"]:
			for k in (d.relations.get(sec, {}) as Dictionary):
				if hostish.call(str(k)):
					out.append("relations.%s %s" % [sec, k])
	var party := func(a: String, b: String) -> bool:
		return (a == World.PLAYER or b == World.PLAYER) and not me_ref in [a, b]
	if d.get("credit") is Dictionary:
		for x in d.credit.get("debts", []):
			if party.call(str(x.get("creditor", "")), str(x.get("debtor", ""))):
				out.append("debt %s" % str(x.get("id", "")))
	if d.get("justice") is Dictionary and (d.justice.get("cases", {}) as Dictionary).has(World.PLAYER):
		out.append("the host's crime case")
	if d.get("contracts") is Dictionary:
		for x in d.contracts.get("list", []):
			if party.call(str(x.get("buyer", "")), str(x.get("seller", ""))):
				out.append("contract %s" % str(x.get("id", "")))
	if d.get("law_lessons") is Dictionary and (d.law_lessons as Dictionary).has(World.PLAYER):
		out.append("law lessons")
	if d.get(MessageJournal.KEY) is Dictionary and (d[MessageJournal.KEY] as Dictionary).has(World.PLAYER):
		out.append("kept messages")
	var host_recs := []
	if d.get("player") is Dictionary:
		host_recs.append(d.player)
	if d.get("players") is Dictionary:
		var hp = (d.players.get("by_pid", {}) as Dictionary).get(str(host_pid_()))
		if hp is Dictionary:
			host_recs.append(hp)
	for r in host_recs:
		if int(r.get("coins", 0)) != 0 or JSON.stringify(r).find("bread") >= 0 or not (r.get("crimes", []) as Array).is_empty():
			out.append("the host's purse, pack, chest or crimes")
	return out


func wire_leaks(from_welcome: int, from_sync: int) -> Array:
	var out := []
	for i in range(from_welcome, tap.wire_welcomes.size()):
		for l in leaks(tap.wire_welcomes[i]):
			out.append("welcome %d: %s" % [i, l])
	for i in range(from_sync, tap.wire_syncs.size()):
		for l in leaks(tap.wire_syncs[i]):
			out.append("sync %d: %s" % [i, l])
	return out


func copy_leaks() -> Array:
	return leaks(JSON.stringify(main.world.to_dict()))


func cart_in_copy() -> Dictionary:
	var id := int(g4().get("cart", {}).get("id", -1))
	for c in main.world.carts.carts:
		if int(c.id) == id:
			return c
	return {}


## The app paused (Android's background) until the host has dropped this guest, then resumed: it reconnects by itself.
func away_and_back() -> Array:
	var me: int = tap.my_pid
	var r0: int = tap.reconnects
	main._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	main.process_mode = Node.PROCESS_MODE_DISABLED
	var dropped := await until(func(): return bool(rec(me).get("away", false)), NetSession.TIMEOUT_MAX_MS / 1000.0 + 15.0)
	return [dropped, me, r0]


func resume(me: int, r0: int) -> bool:
	main.process_mode = Node.PROCESS_MODE_INHERIT
	main._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	var back := await until(func(): return in_game() and tap.reconnects == r0 + 1 and tap.my_pid == me, 40.0)
	await wait(1.5)
	return back


func share_from_window(tier: int) -> bool:
	PlayerWindow.show(main.ui, host_pid_(), "sharing")
	for b in main.ui.panel_body.find_children("*", "Button", true, false):
		if (b as Button).text.begins_with("Tier %d" % tier) and not (b as Button).disabled:
			(b as Button).pressed.emit()
			return true
	return false


func accept_in_window(kind: String) -> bool:
	var o := {}
	for x in main.world.offers:
		if str(x.kind) == kind and str(x["from"]) == World.PLAYER and str(x.to) == main.world.acting_ref():
			o = x
	if o.is_empty():
		return false
	PlayerWindow.show(main.ui, host_pid_())
	var b: Button = main.ui.panel_body.find_child("OfferAccept%d" % int(o.id), true, false)
	if b == null or b.disabled:
		return false
	b.pressed.emit()
	return true


# ---------------------------------------------------------------- the run ----------------------
func _run() -> void:
	_tap()                                                 # main's _ready has made its NetSession by the first frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + "status.json"))
	host_pid = spawn("res://tests/mp_g4_host.gd", [str(port), str(dport), "new", dir, "3"])
	var hosting := await until(func(): return status().get("hosting", false), 90.0)
	check(hosting, "a host process starts a new world and hosts it (port %d)" % port)
	if hosting:
		await scenario()
	if host_pid > 0 and OS.is_process_running(host_pid):
		await command({"cmd": "quit"})
		await until(func(): return not OS.is_process_running(host_pid), 15.0)
	if host_pid > 0 and OS.is_process_running(host_pid):
		OS.kill(host_pid)
	print("mp_g4_loopback_test: %d checks, %d failures; %d welcomes and %d syncs read off the wire" % [checks, failures,
		tap.wire_welcomes.size(), tap.wire_syncs.size()])
	quit(1 if failures > 0 else 0)


func scenario() -> void:
	# -- join, as an unrelated guest
	await command({"cmd": "g4_private", "tag": "a"})
	var hrec: Dictionary = rec(host_pid_())
	check(int(hrec.get("case", 0)) > 0 and int(g4().get("host_coins", 0)) > 0, "setup: the host has private records (a crime case, a purse of %d)" % int(g4().get("host_coins", 0)))
	tap.join("127.0.0.1", port, KEY, "Ann", "oak")
	check(await until(func(): return main.guest_world, 40.0), "the guest joins")
	if not main.guest_world:
		return
	await wait(1.5)
	var me: int = tap.my_pid
	var hid := host_pid_()
	check(tap.wire_welcomes.size() == 1 and leaks(tap.wire_welcomes[0]).is_empty(), "MP-07 unrelated guest: the welcome off the wire carries none of the host's private records (%s)" % str(wire_leaks(0, 0)))
	var w0: Dictionary = JSON.parse_string(tap.wire_welcomes[0]) if tap.wire_welcomes.size() > 0 else {}
	var vill := (w0.get("npcs", []) as Array).size()
	var mine0: Dictionary = w0.get("players", {}).get("by_pid", {}).get(str(me), {})
	check(vill > 0 and (w0.get("households", []) as Array).size() > 0 and w0.has("relations") and int(mine0.get("coins", -1)) >= 0 and mine0.has("inv"),
		"and the public world (%d villagers, their households and ties) and the guest's own record whole" % vill)
	check(not bool(rec(me).get("away", true)), "MP-06: the guest is in play from its first frame")
	# -- marriage (household member)
	await command({"cmd": "family_setup", "sex": "female"})
	await until(func(): return main.world.player.sex == "female", 3.0)
	await act(func(): return main.world.player_offer("partner", hid))
	await command({"cmd": "family_accept"})
	var hostid := int(g4().get("host_id", 0))
	var wed := await until(func(): return int(rec(me).get("partner", 0)) == hostid and main.world.player.partner == hostid, 6.0)
	check(wed, "the guest and the host marry by offer and answer (MP-D8)")
	var s_mark: int = tap.wire_syncs.size()
	await command({"cmd": "g4_private", "tag": "b"})            # the host's new private records, now that the guest is family
	await command({"cmd": "give_host", "id": "bread", "n": 3})
	await wait(3.0)
	var hp_copy: PlayerState = main.world.player_by_pid(hid)
	check(hp_copy != null and hp_copy.partner == int(rec(me).get("id", 0)), "MP-07 household member: the marriage reaches the guest (public family link)")
	check(tap.wire_syncs.size() > s_mark and wire_leaks(0, 0).is_empty(), "MP-07 household member: %d syncs since, none carries the host's private records (%s)" % [tap.wire_syncs.size() - s_mark, str(wire_leaks(0, 0))])
	check(copy_leaks().is_empty(), "nor does anything in the guest's copy of the world (%s)" % str(copy_leaks()))
	# -- MP-05: the host's cart, before and after an agreement
	await command({"cmd": "g4_cart"})
	await until(func(): return not cart_in_copy().is_empty(), 4.0)
	var cart_id := int(g4().get("cart", {}).get("id", -1))
	check(cart_id >= 0 and not cart_in_copy().is_empty() and (cart_in_copy().store as Inventory).count("log") == 0 and int(g4().cart.logs) == 3,
		"MP-05 before any agreement: the host's cart stands in the guest's copy with its load withheld (host: %d logs)" % int(g4().get("cart", {}).get("logs", -1)))
	await act(func(): return main.world.carts.hitch(cart_in_copy(), main.world.acting_ref()))
	check(refused(last_reply()) and str(g4().cart.puller) == "", "and pulling it is refused by the host (%s)" % str(last_reply().get("text", "")))
	check(share_from_window(3), "the guest's Players window offers Asset sharing, tier 3 (pressed)")
	await until(func(): return (g4().get("offers", []) as Array).any(func(o): return str(o.kind) == "asset_share"), 4.0)
	var off: Array = (g4().get("offers", []) as Array).filter(func(o): return str(o.kind) == "asset_share")
	check(off.size() == 1 and int(off[0].qty) == 3 and (g4().shares as Dictionary).is_empty(), "the offer reaches the host; nothing is shared before it is accepted")
	if off.size() == 1:
		await command({"cmd": "answer", "id": int(off[0].id), "accept": true})
	await until(func(): return main.world.asset_shares.values().has(3.0) or main.world.asset_shares.values().has(3), 4.0)
	var hs: Dictionary = g4().shares
	check(hs.size() == 1 and int(hs.values()[0]) == 3 and (main.world.asset_shares.values().has(3) or main.world.asset_shares.values().has(3.0)), "accepted: tier 3 on the host, one agreement for the pair, and in the guest's copy (%s)" % JSON.stringify(hs))
	await until(func(): return (cart_in_copy().get("store", Inventory.new()) as Inventory).count("log") == 3, 4.0)
	check((cart_in_copy().store as Inventory).count("log") == 3, "at tier 3 the cart's load comes to the guest's copy")
	await act(func(): return main.world.carts.hitch(cart_in_copy(), main.world.acting_ref()))
	check(bool(last_reply().get("ok", false)) and not refused(last_reply()) and str(g4().cart.puller) == str(rec(me).get("ref", "?")) and str(g4().cart.owner) == World.PLAYER,
		"the guest pulls the host's cart; it stays the host's (%s)" % JSON.stringify(g4().cart))
	check(wire_leaks(0, 0).is_empty() and copy_leaks().is_empty(), "MP-05/MP-07: sharing assets brings no private record over the wire (%s)" % str(wire_leaks(0, 0)))
	# -- away, a revocation meanwhile, back
	var r_before: Dictionary = rec(me)
	var ab: Array = await away_and_back()
	check(bool(ab[0]), "MP-06: the guest's app paused past the watchdog, the host drops it: out of play (away)")
	await wait(1.0)
	await command({"cmd": "g4_revoke", "pid": me})
	check((g4().shares as Dictionary).is_empty() and str(g4().get("why", "?")) == "", "MP-05 E8: the host revokes the agreement while the guest is away (%s)" % str(g4().get("why", "")))
	await wait(1.0)
	var r_away: Dictionary = rec(me)
	check(int(r_away.get("coins", -1)) == int(r_before.get("coins", -2)) and JSON.stringify(r_away.get("inv")) == JSON.stringify(r_before.get("inv")) and bool(r_away.get("away", false)),
		"MP-06 F3: nothing is done in the away guest's name (purse and pack unchanged)")
	var nw: int = tap.wire_welcomes.size()
	var back: bool = await resume(ab[1], ab[2])
	check(back, "the guest comes back by itself to the same character (pid %d, reconnects %d)" % [tap.my_pid, tap.reconnects])
	check(tap.wire_welcomes.size() == nw + 1 and wire_leaks(nw, 0).is_empty(), "MP-07 G5: the welcome after the reconnect carries none of the host's private records (%s)" % str(wire_leaks(nw, 0)))
	check(main.world.asset_shares.is_empty() and (g4().shares as Dictionary).is_empty(), "MP-05 E8: the revocation stands after the rejoin (guest's copy and host)")
	await until(func(): return str(g4().get("cart", {}).get("puller", "x")) == "", 3.0)
	check(str(g4().cart.puller) == "" and str(g4().cart.owner) == World.PLAYER and (cart_in_copy().store as Inventory).count("log") == 0,
		"the cart is let go, stays the host's, and its load is withheld again in the guest's copy")
	await act(func(): return main.world.carts.hitch(cart_in_copy(), main.world.acting_ref()))
	check(refused(last_reply()) and str(g4().cart.puller) == "", "pulling it is refused again (%s)" % str(last_reply().get("text", "")))
	await act(func(): return main.world.player_offer("say", hid, "", 1, null, 0, 0, "Back again."))
	check(bool(last_reply().get("ok", false)) and not bool(rec(me).get("away", true)), "MP-06 F2: straight after the reconnect the guest acts (a message to the host) and is in play")
	check(main.world.player.partner == hostid, "MP-07: after the rejoin the guest is still the host's spouse (public link)")
	# -- tier 2 from the host, accepted in the guest's window, kept over another reconnect (E7)
	await command({"cmd": "offer", "kind": "asset_share", "to": me, "qty": 2})
	await until(func(): return main.world.offers.any(func(o): return str(o.kind) == "asset_share"), 4.0)
	check(accept_in_window("asset_share"), "the host offers tier 2; the guest accepts it in its Players window (%s)" % str(g4().get("why", "")))
	await until(func(): return (g4().shares as Dictionary).size() == 1, 4.0)
	check((g4().shares as Dictionary).size() == 1 and int((g4().shares as Dictionary).values()[0]) == 2, "tier 2 on the host (%s)" % JSON.stringify(g4().shares))
	var ab2: Array = await away_and_back()
	check(bool(ab2[0]), "paused again: the host drops the guest")
	var nw2: int = tap.wire_welcomes.size()
	var back2: bool = await resume(ab2[1], ab2[2])
	check(back2 and (g4().shares as Dictionary).size() == 1 and int((g4().shares as Dictionary).values()[0]) == 2 and (main.world.asset_shares.values().has(2) or main.world.asset_shares.values().has(2.0)),
		"MP-05 E7: back again, the agreement is still tier 2, on the host and in the guest's copy")
	check(wire_leaks(nw2, 0).is_empty() and copy_leaks().is_empty(), "MP-07: and still nothing private over the wire or in the copy (%s)" % str(wire_leaks(0, 0)))
	check(int(status().get("coin_leak", 1)) == 0, "coins conserved on the host across the session (leak %d)" % int(status().get("coin_leak", 1)))
