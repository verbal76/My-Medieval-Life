extends SceneTree
## MP Batch A1 (docs/multiplayer/BATCH_A.md): one simulation, several player characters, no change to single player.
## World.players / player_by_pid, the acting-player context (as_actor) and the actor parameter of the player verbs, the player
## references ("player" the host, "player:<pid>" a guest, the legacy -2), the purses and goods of every player in the census,
## the per-player level, and save 21 (the "players" section; a save 20 loads with its "player" as the only player).
##   godot --headless --path game --script res://tests/multiplayer_a1_test.gd

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL: " + what)


func _init() -> void:
	GameData.ensure()
	test_single_player()
	test_guest_and_verbs()
	test_refs()
	test_census_and_detail()
	test_ticks()
	test_save_21()
	test_save_20_fixture()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _world(seed_ := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed_)
	return w


func _guest(w: World, nm := "Gwen") -> PlayerState:
	var g := PlayerState.new()
	g.name = nm
	g.family = "Fairlight"
	Identity.register_player(w, g)
	w.give_start_kit(g)
	g.pos = w.player.pos + Vector2(3, 0)
	return g


## The named sections of two saves are identical.
func _same_sections(a: Dictionary, b: Dictionary, keys: Array) -> bool:
	for k in keys:
		if JSON.stringify(a.get(k), "", true) != JSON.stringify(b.get(k), "", true):
			print("   differs: ", k)
			return false
	return true


func _norm(d) -> Dictionary:
	return JSON.parse_string(JSON.stringify(d, "", true, true))


# ------------------------------------------------------------------ single player ----------
func test_single_player() -> void:
	var w := _world()
	check(w.players.size() == 1 and w.player_list() == [w.player], "single player: players holds the host alone")
	check(w.player.pid >= World.BAND_START and w.players.has(w.player.pid) and w.player_by_pid(w.player.pid) == w.player, "the host has its permanent pid and player_by_pid finds it")
	check(w.player_by_pid(12345) == null and w.player_by_pid(0) == null, "an unknown pid names nobody")
	check(w.is_host(w.player) and w.host_player() == w.player and w.acting_player() == w.player, "the host is the acting player by default")
	check(w.player_positions() == [w.player.pos], "the detail centres of one player are its position")
	check(w.add_guest(w.player) == false and w.add_guest(null) == false and w.add_guest(PlayerState.new()) == false, "the host, nobody and a character with no pid are not added as guests")
	var old := w.player
	var swap := PlayerState.new()
	w.player = swap                         # the setter is the host's (load, heir)
	check(w.host_player() == swap and w.player == swap and old != swap, "assigning World.player replaces the host's character")
	w.dispose()


# ------------------------------------------------------------------ a guest and the actor verbs ----------
func test_guest_and_verbs() -> void:
	var w := _world()
	var host := w.player
	var g := _guest(w)
	check(w.add_guest(g) and w.players.size() == 2 and w.player_by_pid(g.pid) == g, "a guest with a permanent pid is added")
	check(w.add_guest(g) == false, "the same guest is not added twice")
	check(w.players.keys() == [host.pid, g.pid] and w.player_list() == [host, g], "players are listed host first, then the guests by pid")
	var seen = w.as_actor(g, func(): return w.player)
	check(seen == g and w.player == host, "as_actor makes the guest the acting player and restores the host")
	var nest = w.as_actor(g, func(): return [w.player, w.as_actor(host, func(): return w.player), w.player])
	check(nest[0] == g and nest[1] == host and nest[2] == g and w.player == host, "as_actor nests and restores each level")
	var null_keeps = w.as_actor(g, func(): return w.as_actor(null, func(): return w.player))
	check(null_keeps == g, "a null actor keeps the current one")
	# verbs act on the explicit player
	var hb: int = host.inv.count("bread")
	var gb: int = g.inv.count("bread")
	w.player_gain("bread", 3, "made_", g)
	check(g.inv.count("bread") == gb + 3 and host.inv.count("bread") == hb, "player_gain with a guest as actor puts the goods in the guest's pack, not the host's")
	g.hunger = 40.0
	var hh := host.hunger
	var ate := w.player_eat("bread", g)
	check(ate and g.hunger > 40.0 and host.hunger == hh and g.inv.count("bread") == gb + 2, "player_eat feeds the acting guest only")
	var hp0 := host.hp
	w.damage_player(5.0, "test", g)
	check(g.hp < g.max_hp and host.hp == hp0, "damage_player hurts the acting guest only")
	var hx: int = int(host.skills.get("woodcutting", 0))
	w.player_xp("woodcutting", 3, g)
	check(int(g.skills.get("woodcutting", 0)) >= 3 and int(host.skills.get("woodcutting", 0)) == hx, "player_xp raises the acting guest's skill only")
	# the same call by the host is as before
	w.player_gain("bread", 1)
	check(host.inv.count("bread") == hb + 1, "a verb with no actor acts for the host as in Build 19")
	w.player_gain("bread", 1, "made_", host)
	check(host.inv.count("bread") == hb + 2, "a verb with the host as actor acts for the host")
	# level is per player
	g.map_level = -1
	check(w.player_level == 0 and w.as_actor(g, func(): return w.player_level) == -1, "player_level is the acting player's own")
	w.as_actor(g, func(): w.player_level = 0)
	check(g.map_level == 0 and host.map_level == 0, "setting player_level sets the acting player's")
	g.map_level = 0
	check(w.solid_for_player(Vector2i(1, 1), g) == w.map.is_solid_world(Vector2i(1, 1)), "solid_for_player takes an actor (the surface for a guest on it)")
	w.dispose()


# ------------------------------------------------------------------ references ----------
func test_refs() -> void:
	var w := _world()
	var g := _guest(w)
	w.add_guest(g)
	check(w.player_ref(w.player) == "player" and w.acting_ref() == "player", "the host's reference stays \"player\", as in every save")
	check(w.player_ref(g) == "player:%d" % g.pid and w.as_actor(g, func(): return w.acting_ref()) == "player:%d" % g.pid, "a guest's reference is player:<pid>")
	check(World.is_player_ref("player") and World.is_player_ref("player:%d" % g.pid) and World.is_player_ref(Life.PLAYER_ID), "player, player:<pid> and -2 are player references")
	check(not World.is_player_ref("npc:3") and not World.is_player_ref("hh:1") and not World.is_player_ref("manor") and not World.is_player_ref(5) and not World.is_player_ref(""), "villagers, households, the manor and the empty reference are not")
	check(w.player_of_ref("player") == w.player and w.player_of_ref(-2) == w.player and w.player_of_ref(w.player_ref(g)) == g, "player_of_ref: player and -2 are the host, player:<pid> that player")
	check(w.player_of_ref("player:99999999") == null and w.player_of_ref("npc:1") == null, "an unknown player and a villager resolve to nobody")
	check(w.ref_name("player") == "%s %s" % [w.player.name, w.player.family] and w.ref_name(w.player_ref(g)) == "Gwen Fairlight", "ref_name names each player")
	check(w.party("player") == null and w.party(w.player_ref(g)) == null and World.ref_id(w.player_ref(g)) == -1, "a player is no villager: party() is null and ref_id -1")
	check(World.pid_of_ref(w.player_ref(g)) == g.pid and World.pid_of_ref("player") == 0, "pid_of_ref reads the pid")
	check(w.is_acting_ref("player") and not w.is_acting_ref(w.player_ref(g)) and w.as_actor(g, func(): return w.is_acting_ref(w.player_ref(g))) and w.as_actor(g, func(): return not w.is_acting_ref("player")), "is_acting_ref: mine is the acting player's")
	check(Life.is_player_id(-2) and not Life.is_player_id(-1) and not Life.is_player_id(7), "Life.is_player_id is the one test of the legacy -2")
	# property under a guest's reference: the land registry works by reference
	var p: Dictionary = w.plots[0]
	var gref := w.player_ref(g)
	w.set_owner(p, gref)
	check(w.holds(gref, p) and not w.holds("player", p) and World.is_player_ref(w.owner_of(p)), "a parcel can be held by a guest's reference")
	w.dispose()


# ------------------------------------------------------------------ census, detail ----------
func test_census_and_detail() -> void:
	var w := _world()
	var coins0 := w.total_coins()
	var goods0: Dictionary = SettlementHoldings.goods(w).duplicate()
	var g := _guest(w)
	var kit_coins := g.coins
	w.coin_sources += kit_coins                        # the start kit's coins are new to the village (as for an heir)
	w.add_guest(g)
	check(w.total_coins() == coins0 + kit_coins, "a guest's coins count in World.total_coins")
	var goods1: Dictionary = SettlementHoldings.goods(w)
	var added := 0
	for id in goods1:
		added += int(goods1[id]) - int(goods0.get(id, 0))
	check(added == g.inv.total() + g.chest.total() and added > 0, "a guest's pack and chest count in the goods census (%d)" % added)
	check(int(SettlementHoldings.coins(w).player) == w.player.coins + g.coins, "the coin census holds every player's purse under player")
	# the detail tier follows every player
	var n: NPC = w.npcs.filter(func(o: NPC) -> bool: return o.alive)[0]
	g.pos = n.pos + Vector2(1, 0)
	w.player.pos = n.pos + Vector2(500, 0)
	check(w.nearest_player_distance(n.pos) < 2.0 and w.player_positions().size() == 2, "the nearest player of two decides the detail tier")
	g.alive = false
	check(w.nearest_player_distance(n.pos) >= 499.0 and w.player_positions().size() == 1, "a dead guest is not a detail centre")
	w.dispose()


# ------------------------------------------------------------------ ticks ----------
func test_ticks() -> void:
	var w := _world()
	var g := _guest(w)
	w.add_guest(g)
	var h0 := w.player.hunger
	var g0 := g.hunger
	for i in 30:
		w.update(0.5)
	check(w.player.hunger < h0 and g.hunger < g0, "every player's needs run with the clock (host %.2f -> %.2f, guest %.2f -> %.2f)" % [h0, w.player.hunger, g0, g.hunger])
	check(w.player == w.host_player(), "the acting player is the host again after the update")
	w.dispose()


# ------------------------------------------------------------------ save 21 ----------
func test_save_21() -> void:
	var w := _world()
	var g := _guest(w)
	g.map_level = 0
	g.coins = 77
	g.inv.add("wheat", 4)
	g.skills["woodcutting"] = 25
	w.add_guest(g)
	var d := _norm(w.to_dict())
	check(int(d.save_version) == 21 and World.SAVE_VERSION == 21 and str(d.format) == "mml-save/21", "the save is version 21")
	check(d.has("player") and d.has("players") and int(d.players.host) == w.player.pid and (d.players.by_pid as Dictionary).size() == 2, "it writes the host's \"player\" as always and a \"players\" section with every player by pid")
	check(JSON.stringify(d.player, "", true) == JSON.stringify(d.players.by_pid[str(w.player.pid)], "", true), "the host's record in players is the same as \"player\"")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	check(w2.load_error == "" and w2.players.size() == 2, "a version 21 save loads with both players")
	var g2: PlayerState = w2.player_by_pid(g.pid)
	check(g2 != null and g2 != w2.player and g2.name == "Gwen" and g2.coins == 77 and g2.inv.count("wheat") == 4 and int(g2.skills.get("woodcutting", 0)) == 25, "the guest comes back with its purse, pack and skills")
	check(w2.player.pid == w.player.pid and JSON.stringify(_norm(w2.player.to_dict()), "", true) == JSON.stringify(d.player, "", true), "the host's character is unchanged")
	var rt := _norm(w2.to_dict())
	check(_same_sections(rt, d, ["player", "players", "underground", "people", "next_band_id", "save_version"]), "saving the loaded world writes the players' sections again (round trip)")
	# an older build reads "player" and ignores "players": the shape of a save 20
	var older := d.duplicate(true)
	older.erase("players")
	older.save_version = 20
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), older)
	check(w3.load_error == "" and w3.players.size() == 1, "without the new key the same save loads with the host alone")
	w3.dispose()
	# a record that cannot be a player is kept, never dropped
	var odd := d.duplicate(true)
	odd.players.by_pid["junk"] = {"name": "Nobody", "family": "X", "sprite": "", "heir_sprite": "", "weapon": "", "armor": "", "home": "", "generation": 1, "coins": 3, "deaths": 0, "pid": 0,
			"hp": 1.0, "max_hp": 1.0, "hunger": 1.0, "stamina": 1.0, "pos": [1.0, 1.0], "inv": {"items": {}}, "chest": {"items": {}}, "skills": {}, "spells": {}, "alive": true}
	var w4 := World.new()
	w4.load_dict(VillageMap.load_default(), odd)
	var back := _norm(w4.to_dict())
	check(w4.load_error == "" and w4.players.size() == 2 and (back.players.by_pid as Dictionary).has("xjunk"), "a record with no usable pid is kept in the save and written back")
	w4.dispose()
	# a guest below the surface stays there; one whose level is gone comes up
	var low := _world()
	var lg := _guest(low)
	low.add_guest(lg)
	lg.map_level = -7
	var ld := _norm(low.to_dict())
	var low2 := World.new()
	low2.load_dict(VillageMap.load_default(), ld)
	check(low2.player_by_pid(lg.pid).map_level == 0, "a guest saved on a level that is gone is brought to the surface")
	low2.dispose()
	low.dispose()
	w2.dispose()
	w.dispose()


func test_save_20_fixture() -> void:
	var text := FileAccess.get_file_as_string("res://tests/fixtures/b19_save_v20_seed3.json")
	var d: Dictionary = JSON.parse_string(text)
	check(int(d.save_version) == 20 and not d.has("players"), "the fixture is a real Build 19 save (version 20, no players section)")
	var w := World.new()
	w.load_dict(VillageMap.load_default(), JSON.parse_string(text))
	check(w.load_error == "" and w.players.size() == 1 and w.player_list()[0] == w.player, "a version 20 save loads with its \"player\" as the only player")
	var p := _norm(w.player.to_dict())
	var same := true
	for k in d.player:
		if JSON.stringify(p.get(k), "", true) != JSON.stringify(d.player[k], "", true):
			same = false
			print("   differs: ", k)
	check(same and w.player.coins == 137 and w.player.pid == int(d.player.pid), "the player's state is identical to the saved one")
	check(w.player_level == int(d.underground.player_level) and w.player.map_level == w.player_level, "the level comes from the saved underground section")
	var d21 := _norm(w.to_dict())
	check(int(d21.save_version) == 21 and (d21.players.by_pid as Dictionary).size() == 1 and JSON.stringify(d21.player, "", true) == JSON.stringify(d21.players.by_pid[str(w.player.pid)], "", true), "it saves as version 21 with the host as the one player")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d21)
	check(w2.load_error == "" and _same_sections(_norm(w2.to_dict()), d21, ["player", "players", "underground", "people", "next_band_id", "save_version"]), "and the version 21 save round-trips (the players' sections)")
	# the other sections are untouched by the new key
	var untouched := true
	for k in d:
		if k in ["save_version", "format", "player", "meta"]:
			continue
		if not d21.has(k):
			untouched = false
			print("   missing: ", k)
	check(untouched, "every section of the old save is still written")
	var m := SaveTransfer.migrate(JSON.parse_string(text), VillageMap.load_default())
	check(m.ok and int(m.data.save_version) == 21 and m.data.has("players"), "importing the old save migrates it to 21 (%s)" % m.get("reason", ""))
	w2.dispose()
	w.dispose()
