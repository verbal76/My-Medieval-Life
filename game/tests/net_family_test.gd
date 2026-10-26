extends SceneTree
## MP-PLAYER-FAMILY over the network (owner decisions 2026-10-24; Build 22): two Godot processes on this machine over loopback, each
## running the real game scene. This process is a guest (a woman); tests/net_host.gd the host (a man with a house). The guest asks the
## host to marry (MP-D8, World.player_offer, sent by World.mirror), the host accepts: the couple's household is founded on the host and
## the guest's copy takes it. A child is born to them (Life.birth): both recorded as parents on the host, in the guest's copy (the
## villagers' section) and in the guest's own record (s_self). The guest takes in an orphaned child (Guardianship.player_adopt, sent to
## the host): both spouses its adoptive parents, the child in the couple's household, the population unchanged. The host saves and
## quits with the guest away and comes back: every link is kept, and the guest rejoins to the same family.
##   godot --headless --path game --script res://tests/net_family_test.gd

var main
var failures := 0
var checks := 0
var dir := "user://test_net_family/"
var port := 0
var dport := 0
var host_pid := -1
var seq := 0
const KEY := "0123456789abcdef0123456789abcdef"
const SAME := ["households", "relations"]


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	port = 48100 + OS.get_process_id() % 40 * 2
	dport = port + 1
	DirAccess.make_dir_recursive_absolute(dir)
	for f in ["status.json", "cmd.json", "host_save.json", "host_save.json.bak", "dump.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + f))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = dir + "guest_never_saves.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


# ---------------------------------------------------------------- helpers (as net_c_test.gd) ----
func spawn(script: String, args: Array) -> int:
	var a := ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", script, "--"] + args
	return OS.create_process(OS.get_executable_path(), a)


func status() -> Dictionary:
	var f := FileAccess.open(dir + "status.json", FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if typeof(d) == TYPE_DICTIONARY else {}


func command(d: Dictionary) -> void:
	seq += 1
	d["seq"] = seq
	var f := FileAccess.open(dir + "cmd.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	await until(func(): return int(status().get("seq", -1)) >= seq, 5.0)


func until(cond: Callable, secs: float) -> bool:
	var end := Time.get_ticks_msec() + int(secs * 1000.0)
	while Time.get_ticks_msec() < end:
		if cond.call():
			return true
		await process_frame
	return cond.call()


func wait(secs: float) -> void:
	await until(func(): return false, secs)


func join() -> bool:
	main.net.join("127.0.0.1", port, KEY, "Ann", "oak")
	return await until(func(): return main.guest_world, 30.0)


func rec(pid := 0) -> Dictionary:
	return status().get("players", {}).get(str(pid if pid > 0 else main.net.my_pid), {})


func start_host(mode: String) -> bool:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + "status.json"))
	host_pid = spawn("res://tests/net_host.gd", [str(port), str(dport), mode, dir, "3"])
	seq = 0
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + "cmd.json"))
	return await until(func(): return status().get("hosting", false), 90.0)


func stop_host() -> void:
	command({"cmd": "quit"})
	await until(func(): return not main.guest_world, 20.0)
	await until(func(): return not OS.is_process_running(host_pid), 10.0)


func act(c: Callable) -> Variant:
	var n0: int = main.net.replies.size()
	var s0: int = main.net.syncs
	var r = c.call()
	await until(func(): return main.net.replies.size() > n0, 5.0)
	await until(func(): return main.net.syncs > s0, 3.0)
	await wait(0.3)
	return r


func copies_agree(what: String) -> void:
	var s0: int = main.net.syncs
	await command({"cmd": "dump", "keys": SAME + ["npcs"]})
	await until(func(): return main.net.syncs > s0, 2.0)
	await wait(0.3)
	var f := FileAccess.open(dir + "dump.json", FileAccess.READ)
	var host: Dictionary = JSON.parse_string(f.get_as_text()) if f != null else {}
	var mine: Dictionary = JSON.parse_string(JSON.stringify(main.world.to_dict()))
	var bad := []
	for k in SAME:
		if JSON.stringify(host.get("sections", {}).get(k)) != JSON.stringify(mine.get(k)):
			bad.append(k)
	# the villagers' family links (their places and plans run on the host between snapshots)
	var links := {}
	for nd in host.get("sections", {}).get("npcs", []):
		links[int(nd.id)] = [nd.mother, nd.father, nd.get("adoptive", []), nd.household, nd.children]
	for n: NPC in main.world.npcs:
		var h = links.get(n.id)
		if h == null or JSON.stringify([float(n.mother), float(n.father), n.adoptive.map(func(x): return float(x)), float(n.household), n.children.map(func(x): return float(x))]) != JSON.stringify(h):
			bad.append("npc %d" % n.id)
			break
	check(bad.is_empty() and links.size() == main.world.npcs.size(), "%s: the guest's copy holds the host's households, ties and family links%s" % [what, "" if bad.is_empty() else " (differs: %s)" % str(bad)])


func couple() -> Dictionary:
	var hs: Array = status().get("family", {}).get("households", [])
	return hs[0] if hs.size() == 1 else {}


# ---------------------------------------------------------------- the run ----------------------
func _run() -> void:
	check(await start_host("new"), "a host process starts a new world and hosts it (port %d)" % port)
	check(await join(), "the guest joins")
	if main.guest_world:
		await family()
	if host_pid > 0 and OS.is_process_running(host_pid):
		await stop_host()
	if host_pid > 0 and OS.is_process_running(host_pid):
		OS.kill(host_pid)
	print("net_family_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func family() -> void:
	await wait(1.0)
	await command({"cmd": "family_setup", "sex": "female"})
	await until(func(): return main.world.player.sex == "female", 3.0)
	var me := int(main.net.my_pid)
	var host := int(status().host_pid)
	var my_id := -me
	await act(func(): return main.world.player_offer("partner", host))
	check(str(last_reply().get("path", "")) == "player_offer" and bool(last_reply().get("ok", false)), "the guest asks the host to marry (MP-D8, sent to the host)")
	await command({"cmd": "family_accept"})
	await until(func(): return not couple().is_empty(), 3.0)
	var c0 := couple()
	check(not c0.is_empty() and JSON.stringify(c0.couple) == JSON.stringify([-2.0, float(my_id)]) and str(c0.home) != "" and (c0.members as Array).is_empty(),
		"accepted: the couple's household is founded on the host, the host's line first, in the host's house, no member yet (%s)" % JSON.stringify(c0))
	check(int(rec().partner) == -2 and int(rec(host).partner) == my_id, "both are partners by each other's own id")
	await copies_agree("married")
	# a birth: both parents recorded, everywhere
	var n0 := int(status().family.npcs)
	await command({"cmd": "family_birth"})
	await until(func(): return not (status().family.kids as Dictionary).is_empty(), 3.0)
	var kids: Dictionary = status().family.kids
	var kid_id := int(kids.keys()[0]) if kids.size() == 1 else -1
	var k: Dictionary = kids.get(str(kid_id), {})
	check(kids.size() == 1 and int(k.mother) == my_id and int(k.father) == -2 and int(k.household) == int(c0.id) and int(status().family.npcs) == n0 + 1,
		"a child is born to the couple: the guest its mother, the host its father, in their household, one new person (%s)" % JSON.stringify(k))
	check((rec().children as Array).has(float(kid_id)) and (rec(host).children as Array).has(float(kid_id)), "the child is each spouse's on the host")
	await copies_agree("after the birth")
	await wait(1.2)                                    # the guest's own record comes every second (s_self)
	var kc: NPC = main.world.npc(kid_id)
	check(kc != null and kc.mother == my_id and kc.father == -2 and main.world.player.children.has(kid_id), "the guest's copy: the child names both parents, and the guest's own record names the child")
	# an adoption by the guest's own action
	await command({"cmd": "family_orphan"})
	await until(func(): return int(status().get("orphan", -1)) >= 0, 3.0)
	var oid := int(status().orphan)
	check(oid >= 0, "an orphaned child cared for by strangers (%d)" % oid)
	if oid < 0:
		return
	await copies_agree("the orphan placed")                  # the guest's copy knows the parents are gone, as its interface would
	var on: NPC = main.world.npc(oid)
	await command({"cmd": "guest_to", "x": on.pos.x + 1.0, "y": on.pos.y})      # the guest talks with the child, beside them
	await until(func(): return main.world.player.pos.distance_to(on.pos + Vector2(1, 0)) < 0.5, 3.0)
	var living0 := int(status().family.living)
	var npcs0 := int(status().family.npcs)
	var why = await act(func(): return Guardianship.player_adopt(main.world, main.world.npc(oid)))
	var kids2: Dictionary = status().family.kids
	var a: Dictionary = kids2.get(str(oid), {})
	check(bool(last_reply().get("ok", false)) and JSON.stringify(a.get("adoptive", [])) == JSON.stringify([-2.0, float(my_id)]) and int(a.get("household", -1)) == int(c0.id),
		"the guest takes the child in: both spouses its adoptive parents, in the couple's household (%s, host: %s, %s)" % [str(why), JSON.stringify(last_reply()), JSON.stringify(a)])
	check(int(status().family.npcs) == npcs0 and int(status().family.living) == living0, "no new person: the population is unchanged (%d)" % living0)
	check((rec().children as Array).has(float(oid)) and (rec(host).children as Array).has(float(oid)), "the adopted child is each spouse's")
	await copies_agree("after the adoption")
	var fam_before: Dictionary = status().family
	# the host saves and quits with the guest away; comes back; the guest rejoins
	await stop_host()
	check(await start_host("continue"), "the host continues its world from the save")
	var away: Dictionary = rec(me)
	check(bool(away.get("away", false)) and int(away.get("partner", 0)) == -2 and (away.get("children", []) as Array).size() == 2,
		"the guest is out of play and keeps its partner and both children (%s)" % JSON.stringify(away).left(300))
	var fam_after: Dictionary = status().get("family", {})
	check(JSON.stringify(fam_after.get("households")) == JSON.stringify(fam_before.get("households")) and JSON.stringify(fam_after.get("kids")) == JSON.stringify(fam_before.get("kids")),
		"every family link is as before the restart (households, parents, adoptive parents)")
	check(await join(), "the guest rejoins")
	await wait(1.5)
	check(main.world.player.partner == -2 and main.world.player.children.size() == 2 and main.world.npc(oid) != null and main.world.npc(oid).adoptive.has(my_id),
		"as the same spouse and parent")
	await copies_agree("after rejoining")


func last_reply() -> Dictionary:
	var ks: Array = main.net.replies.keys()
	ks.sort()
	return main.net.replies[ks[ks.size() - 1]] if not ks.is_empty() else {}
