extends SceneTree
## MP Batch C (docs/multiplayer/BATCH_C.md), gate G2 over the network: two and three Godot processes on this machine over loopback,
## every one running the real game scene. This process is a guest; tests/net_host.gd the host; tests/net_guest.gd another guest. The
## guest calls the World verbs as its interface does (each sent by World.mirror and applied by the host as the guest, NetActions):
## eating, resting by agreement (MP-D2), picking a plant, buying from a villager, setting down a cart, talking and giving, striking a
## villager. After each, the host's record of the guest and the guest's own copy agree, the guest's copy of the shared world takes the
## host's sections (NetSync: every synchronized section identical on both machines), and coins stay conserved. A request naming the
## host's reference is refused. Then several persistent players across a host restart: two guests, the host saves and quits, comes
## back, each guest returns as the same character with its own records. Real devices and real networks are not tested here.
##   godot --headless --path game --script res://tests/net_c_test.gd

var main
var failures := 0
var checks := 0
var dir := "user://test_net_c/"
var port := 0
var dport := 0
var host_pid := -1
var seq := 0
const KEY := "0123456789abcdef0123456789abcdef"
const KEY2 := "fedcba9876543210fedcba9876543210"
## Sections compared on both machines (NetSync.KEYS but the villagers, whose places and plans run on the host between snapshots).
const SAME := ["buildings", "stalls", "plots", "fields", "households", "loot", "trees", "plants", "deposits", "boulders", "treasury",
	"granary", "vacancies", "carts", "relations", "credit", "justice", "contracts", "quest_offers", "feast", "farm", "farm_plots", "chests"]


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	port = 49000 + OS.get_process_id() % 40 * 2
	dport = port + 1
	DirAccess.make_dir_recursive_absolute(dir)
	for f in ["status.json", "cmd.json", "host_save.json", "host_save.json.bak", "g2.json", "dump.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + f))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = dir + "guest_never_saves.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


# ---------------------------------------------------------------- helpers ----------------------
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


func join(key: String = KEY) -> bool:
	main.net.join("127.0.0.1", port, key, "Ann", "oak")
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


## A verb as the guest's interface calls it, then the host's answer and the sections it changed.
func act(c: Callable) -> Variant:
	var n0: int = main.net.replies.size()
	var s0: int = main.net.syncs
	var r = c.call()
	await until(func(): return main.net.replies.size() > n0, 5.0)
	await until(func(): return main.net.syncs > s0, 3.0)
	await wait(0.3)
	return r


func last_reply() -> Dictionary:
	var ks: Array = main.net.replies.keys()
	ks.sort()
	return main.net.replies[ks[ks.size() - 1]] if not ks.is_empty() else {}


## Both machines hold the same shared world: the host's sections and the guest's copy's are identical.
func copies_agree(what: String) -> void:
	var s0: int = main.net.syncs
	await command({"cmd": "dump", "keys": SAME})
	await until(func(): return main.net.syncs > s0, 2.0)          # the sections of that moment (none come when the copy was current)
	await wait(0.2)
	var f := FileAccess.open(dir + "dump.json", FileAccess.READ)
	var host: Dictionary = JSON.parse_string(f.get_as_text()) if f != null else {}
	var mine: Dictionary = JSON.parse_string(JSON.stringify(main.world.to_dict()))
	var bad := []
	for k in SAME:
		if JSON.stringify(host.get("sections", {}).get(k)) != JSON.stringify(mine.get(k)):
			bad.append(k)
	check(bad.is_empty(), "%s: the guest's copy of the shared world is the host's%s" % [what, "" if bad.is_empty() else " (differs: %s)" % str(bad)])


func agree(what: String) -> void:
	await wait(1.2)                                   # the guest's own character comes every second (s_self)
	var r := rec()
	var host_inv: Dictionary = r.get("inv", {})
	var mine: Dictionary = main.world.player.inv.items
	var same := host_inv.size() == mine.size()
	for k in host_inv:
		same = same and int(host_inv[k]) == int(mine.get(k, -1))
	check(same and int(r.get("coins", -1)) == main.world.player.coins and int(r.get("crimes", -1)) == main.world.player.crimes.size(),
		"%s: the host's record of the guest and the guest's own agree (pack, purse %d, crimes %d)" % [what, main.world.player.coins, main.world.player.crimes.size()])
	check(int(status().get("coin_leak", 1)) == 0, "%s: coins conserved on the host" % what)


func near_me(n: NPC) -> void:
	await command({"cmd": "guest_to", "x": n.pos.x + 1.0, "y": n.pos.y})
	await until(func(): return main.world.player.pos.distance_to(n.pos + Vector2(1, 0)) < 0.5, 3.0)


# ---------------------------------------------------------------- the run ----------------------
func _run() -> void:
	check(await start_host("new"), "a host process starts a new world and hosts it (port %d)" % port)
	check(await join(), "the guest joins")
	if main.guest_world:
		await verbs()
		await several_players_restart()
	if host_pid > 0 and OS.is_process_running(host_pid):
		await stop_host()
	if host_pid > 0 and OS.is_process_running(host_pid):
		OS.kill(host_pid)
	print("net_c_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func verbs() -> void:
	var w: World = main.world
	await wait(1.0)
	await copies_agree("on joining")
	# C1: eat (the interface's own verb, sent to the host)
	await command({"cmd": "give", "id": "bread", "n": 2})
	await until(func(): return main.world.player.inv.has("bread", 2), 3.0)
	var hunger0 := float(rec().get("hunger", 0.0))
	await act(func(): return main.world.player_eat("bread"))
	check(bool(last_reply().get("ok", false)) and str(last_reply().get("path", "")) == "player_eat", "C1 eat: the host applied the guest's player_eat")
	await agree("C1 eat")
	# C1 / MP-D2: a guest resting while the host is awake rests in real time
	var m0 := float(status().get("minutes", 0.0))
	await act(func(): return main.world.player_rest())
	check(bool(rec().get("resting", false)) and float(status().get("minutes", 0.0)) - m0 < 120.0, "C1 rest (MP-D2): the guest rests in real time, the host awake: no jump of the clock")
	await act(func(): return main.world.player_wake())
	check(not bool(rec().get("resting", true)), "C1: and gets up by acting")
	# C2: pick a ripe plant
	var pl := {}
	for p in w.plants:
		if str(p.state) == "ripe" and not p.get("ow", false):
			pl = p
			break
	await command({"cmd": "guest_to", "x": float(pl.x) + 0.5, "y": float(pl.y) + 1.5})
	await until(func(): return main.world.player.pos.distance_to(Vector2(float(pl.x) + 0.5, float(pl.y) + 1.5)) < 0.5, 3.0)
	var inv0: String = JSON.stringify(main.world.player.inv.items)
	await act(func(): return main.world.player_pick_plant(main.world.plant_at(Vector2i(int(pl.x), int(pl.y)))))
	check(JSON.stringify(rec().get("inv", {})) != inv0 and str(status().get("plants", {}).get("%d,%d" % [int(pl.x), int(pl.y)], "")) != "ripe",
		"C2 pick: the plant is picked on the host, its goods in the guest's pack")
	await agree("C2 pick")
	await copies_agree("C2 pick")
	# C3: buy from a villager
	var vendor: NPC = null
	var item := ""
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.job != "guard":
			for id in n.inv.ids():
				if not w.brain.keeps(n, id) and GameData.value(id) > 0 and GameData.value(id) <= 10:
					vendor = n
					item = id
					break
		if vendor != null:
			break
	if vendor != null:
		await near_me(vendor)
		var c0: int = main.world.player.coins
		await act(func(): return main.world.player_buy_many(main.world.npc(vendor.id), item, 1))
		check(int(rec().get("coins", c0)) < c0 and int(rec().get("inv", {}).get(item, 0)) >= 1, "C3 buy: the guest bought %s from %s on the host, with its own coins" % [item, vendor.name])
		await agree("C3 buy")
	# C4: set a cart down
	await command({"cmd": "give", "id": "handcart", "n": 1})
	await until(func(): return main.world.player.inv.has("handcart"), 3.0)
	await act(func(): return main.world.player_set_down_cart(main.world.player.pos + Vector2(1, 0)))
	check(int(rec().get("carts", 0)) == 1, "C4 cart: the cart set down is the guest's on the host")
	await agree("C4 cart")
	await copies_agree("C4 cart")
	# C5: talk and give, by the guest's own id
	var friend: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.job != "guard")[0]
	await near_me(friend)
	await command({"cmd": "give", "id": "flower", "n": 1})
	await until(func(): return main.world.player.inv.has("flower"), 3.0)
	await act(func(): main.world.relations.talked(main.world.npc(friend.id)); return true)
	await act(func(): return main.world.relations.give(main.world.acting_id(), main.world.npc(friend.id), "flower"))
	var mine_id: int = main.world.acting_id()
	check(mine_id == -main.net.my_pid and float(main.world.relations.peek(mine_id, friend.id).regard) > 0.0 and float(main.world.relations.peek(-2, friend.id).regard) == 0.0,
		"C5: the villager's tie with the guest (id %d) grew on the host and came back to the guest's copy; the host's is untouched" % mine_id)
	await copies_agree("C5 talk and give")
	# C6: strike a villager
	var victim: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.job != "guard" and n != friend)[0]
	await near_me(victim)
	await act(func(): return main.world.player_hit_npc(main.world.npc(victim.id), 1.0))
	check(int(rec().get("crimes", 0)) >= 1 and int(rec().get("case", 0)) >= 1 and status().players.values().all(func(p): return not p.host or int(p.crimes) == 0),
		"C6: the guest's assault is on the guest's record and case on the host; the host is innocent")
	await agree("C6 strike")
	# a request naming the host's reference is refused
	var nr: int = main.net.replies.size()
	main.net.send_verb("player_set_down_cart", [main.world.player.pos])
	main.net.send_verb("start_site", [{"$r": "plots", "k": str(w.plots[0].id)}, "house", "player"])
	await until(func(): return main.net.replies.size() >= nr + 2, 5.0)
	check(not bool(last_reply().get("ok", true)) and str(last_reply().get("text", "")) == "That is not yours.", "a guest's request naming the host's reference is refused")
	await agree("after the refusals")


## Several persistent players across a host restart: a second guest joins and leaves; the host saves and quits and comes back;
## both guests are in its world, out of play, with their records; each rejoins as the same character.
func several_players_restart() -> void:
	var r2 := await spawn_guest(KEY2, "Bert", "g2.json")
	check(bool(r2.get("welcomed", false)), "a second guest joins and leaves")
	await wait(1.0)
	var players0: Dictionary = status().get("players", {})
	var guests0 := players0.values().filter(func(p): return not p.host)
	check(guests0.size() == 2, "the host's world holds two guests (%d)" % guests0.size())
	var me0 := rec()
	var pid := int(main.net.my_pid)
	await stop_host()
	check(not main.guest_world, "the host saves and quits")
	check(await start_host("continue"), "the host continues its world from the save")
	var players1: Dictionary = status().get("players", {})
	check(players1.values().filter(func(p): return not p.host and bool(p.away)).size() == 2, "both guests are in it, out of play (MP-D1)")
	check(await join(), "the guest rejoins")
	var me1 := rec()
	check(int(main.net.my_pid) == pid and int(me1.coins) == int(me0.coins) and int(me1.crimes) == int(me0.crimes) and int(me1.carts) == int(me0.carts)
		and int(me1.id) == int(me0.id), "as the same character, with its own purse, record, cart and id")
	var b0: Dictionary = {}
	for k in players0:
		if not players0[k].host and int(k) != pid:
			b0 = players0[k]
	var r3 := await spawn_guest(KEY2, "Bert", "g2.json")
	await wait(1.0)
	var b1: Dictionary = {}
	for k in status().get("players", {}):
		var p: Dictionary = status().players[k]
		if not p.host and int(k) != pid:
			b1 = p
	check(bool(r3.get("welcomed", false)) and str(b1.get("key", "")) == str(b0.get("key", "x")) and status().players.size() == players0.size(),
		"the second guest comes back as its own character too (no new one made)")


func spawn_guest(key: String, who: String, out: String) -> Dictionary:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + out))
	spawn("res://tests/net_guest.gd", [str(port), key, who, "oak", out, dir])
	var ok := await until(func(): return FileAccess.file_exists(dir + out), 90.0)
	var r = JSON.parse_string(FileAccess.get_file_as_string(dir + out)) if ok else null
	return r if r is Dictionary else {}
