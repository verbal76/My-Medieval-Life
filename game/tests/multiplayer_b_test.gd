extends SceneTree
## MP Batch B (docs/multiplayer/BATCH_B.md): persistence of guest characters in one process. A loaded world has every guest
## out of play until it rejoins (MP-D1); a player away is not a target (a victim or guard does not strike at it) while its case
## and records stay; a guest's death and its own choice of the heir (MP-D4) through the established succession, for that
## guest's line only (the host's family links, ties, contracts and debts untouched), the identity and the line's reference
## carried to the heir, coins conserved; save 21 round trips of all of it; an older save with no "players" key as single
## player; single player's heir unchanged. The two-process flow is net_batch_b_test.gd.
##   godot --headless --path game --script res://tests/multiplayer_b_test.gd

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
	test_suspend_on_load()
	test_away_not_targetable()
	test_guest_heir()
	test_host_heir_unchanged()
	test_old_save()
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
	g.net_key = "ab".repeat(32)
	w.add_guest(g)
	return g


func _reload(w: World) -> World:
	var d = JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	return w2


func _open(w: World, c: Vector2i) -> bool:
	return not w.map.is_solid(c) and w.place_of(Vector2(c) + Vector2(0.5, 0.5)) == ""


## An open stretch away from the camp; everyone but `keep` moved off to the map's corner (as manhunt_test).
func _stage(w: World, keep: Array) -> Vector2:
	for y in range(60, 120):
		for x in range(60, 160):
			var c := Vector2i(x, y)
			var ok := true
			for dx in range(-3, 4):
				ok = ok and _open(w, c + Vector2i(dx, 0))
			if not ok or Vector2(c).distance_to(Vector2(w.bandit_camp)) < 40.0:
				continue
			var at := Vector2(c) + Vector2(0.5, 0.5)
			for n: NPC in w.npcs:
				if not keep.has(n) and n.alive:
					n.pos = Vector2(5.5, 5.5)
					n.plan.clear()
			for n: NPC in keep:
				n.anim = "idle"
				n.plan.clear()
				n.depth = 0
			w.player.pos = at
			return at
	return Vector2.ZERO


func _adults(w: World, k: int) -> Array:
	return w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.job != "guard").slice(0, k)


# ------------------------------------------------------------------ MP-D1 on load ----------
func test_suspend_on_load() -> void:
	var w := _world()
	var single := JSON.stringify(w.to_dict(), "", true)
	w.suspend_guests()
	check(JSON.stringify(w.to_dict(), "", true) == single, "single player: suspending guests changes nothing (no guests)")
	var g := _guest(w)
	g.away = false                                  # saved while connected (an hourly save, or a host killed mid-session)
	var w2 := _reload(w)
	var g2 := w2.player_by_pid(g.pid)
	check(g2 != null and not g2.away, "a save written while the guest was connected has it in play")
	w2.suspend_guests()
	check(g2.away and not w2.host_player().away and w2.active_players() == [w2.host_player()], "loaded by the host: the guest is out of play until it rejoins, the host is not")
	check(g2.inv.items == g.inv.items and g2.coins == g.coins and g2.net_key == g.net_key, "and keeps its pack, purse and identity")
	w.dispose()
	w2.dispose()


# ------------------------------------------------------------------ MP-D1: not targetable ----------
func test_away_not_targetable() -> void:
	var w := _world()
	var host := w.player
	var gu := _guest(w)
	var g: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.job == "guard")[0]
	var ad := _adults(w, 2)
	var v: NPC = ad[0]
	var wit: NPC = ad[1]
	var at := _stage(w, [g, v, wit])
	gu.pos = at
	gu.max_hp = 9999.0
	gu.hp = 9999.0
	host.pos = at + Vector2(0, 14)
	g.pos = at + Vector2(5, 0)
	g.max_hp = 9999.0
	g.hp = 9999.0
	wit.pos = at + Vector2(-2, 0)
	v.pos = at + Vector2(0.6, 0)
	v.hp = 1.0
	w.player_hit_npc(v, 500.0, gu)
	var ref := w.player_ref(gu)
	check(str(g.pursuit.get("ref", "")) == ref and not w.justice.case_of(ref).is_empty(), "a guest's killing: a guard is on the guest's case")
	gu.away = true                                  # the guest disconnects in the middle of the chase
	var hp0 := gu.hp
	g.attack_cd = 0.0
	for i in 60:
		w.brain.fight(g, 0.05)
		g.attack_cd = 0.0
	check(gu.hp == hp0, "a player away is not struck (hp %.0f)" % gu.hp)
	check(str(g.pursuit.get("state", "")) != "pursuing", "the guard does not see it: the chase becomes a search or ends (%s)" % str(g.pursuit.get("state", "released")))
	check(not w.justice.case_of(ref).is_empty() and gu.crimes.any(func(c): return c.kind == "killing"), "the case and the crime stay on the guest's record (MP-D1)")
	check(w.relations.killings_of(ref) == 1 and w.relations.killings == 0, "the killing stays the guest's")
	var rec := _reload(w)
	var gr: PlayerState = rec.player_of_ref(ref)
	check(gr != null and gr.pid == gu.pid and not rec.justice.case_of(ref).is_empty() and rec.relations.killings_of(ref) == 1 and gr.crimes.size() == gu.crimes.size(),
		"saved and loaded: the guest's case, its killings and its crimes are still its own")
	var tagged := false
	if rec.judgment != null:
		for ev in rec.judgment.facts:
			var f: Dictionary = rec.judgment.fact(int(ev))
			if (f.tags as Array).has("by:" + ref):
				tagged = true
	check(rec.judgment == null or tagged, "the judgment fact naming the guest survives the save")
	w.dispose()
	rec.dispose()


# ------------------------------------------------------------------ MP-D4: a guest's heir ----------
func test_guest_heir() -> void:
	var w := _world()
	var host := w.host_player()
	var gu := _guest(w)
	var ref := w.player_ref(gu)
	var old_pid := gu.pid
	var ad := _adults(w, 3)
	var partner: NPC = ad[0]
	partner.partner = Life.PLAYER_ID                # the host's family link (-2)
	host.partner = partner.id
	var c_host: Dictionary = w.contracts._new_record(World.npc_ref(ad[1].id), World.PLAYER, "bread", 2, 3, 5, [])
	c_host.state = "accepted"
	c_host.id = 90001
	var c_guest: Dictionary = w.contracts._new_record(World.npc_ref(ad[2].id), ref, "bread", 2, 3, 5, [])
	c_guest.state = "accepted"
	c_guest.id = 90002
	w.contracts.list.append(c_host)
	w.contracts.list.append(c_guest)
	w.relations.guest_killings[ref] = 2
	gu.skills["mining"] = 500
	gu.coins = 77
	var coins0 := w.total_coins()
	var src0 := w.coin_sources
	w.damage_player(99999.0, "a test", gu)
	check(not gu.alive and host.alive and w.player == host, "the guest dies; the host plays on")
	for i in 20:
		w.update(0.1)                               # MP-D4: the world goes on while the guest chooses
	check(w.player_by_pid(old_pid) == gu and not gu.alive, "nothing chooses for the guest: still dead, still its record, until its player chooses")
	var ties_before: Dictionary = w.relations.ties.duplicate(true)      # (the ticks above move ties near villagers, as always)
	w.continue_as_heir(gu)
	var heir: PlayerState = w.player_of_ref(ref)
	check(heir != null and heir != gu and heir.alive and heir.pid != old_pid and w.player_by_pid(old_pid) == null and w.player_by_pid(heir.pid) == heir,
		"the guest's choice: its heir is a player of the world by its own pid (%d after %d)" % [heir.pid if heir else 0, old_pid])
	check(heir.net_key == gu.net_key and heir.line == old_pid and w.player_ref(heir) == ref and not w.is_host(heir),
		"the heir carries the identity, and the line keeps its reference (%s)" % w.player_ref(heir))
	check(w.host_player() == host and host.alive and w.player == host, "the host's character is untouched")
	check(partner.partner == Life.PLAYER_ID and host.partner == partner.id, "the host's family links stay the host's (-2 not retired)")
	check(JSON.stringify(w.relations.ties, "", true) == JSON.stringify(ties_before, "", true), "the host's ties are untouched")
	check((w.tie_history.get(str(old_pid), {}).get("ties", {"x": 1}) as Dictionary).is_empty(), "the dead guest's tie history does not copy the host's ties")
	check(str(c_host.state) == "accepted" and str(c_guest.state) == "cancelled", "the guest's open contract ends with it; the host's stands")
	check(w.relations.killings_of(ref) == 2 and w.justice.case_of(ref).is_empty(), "the line keeps its killings (as the host's heir does); the case ended with the dead")
	check(heir.skills.is_empty() and heir.coins == int(GameData.b("start_coins_player")), "the heir starts every skill from nothing, with the starting kit")
	check(w.total_coins() - coins0 == heir.coins and w.coin_sources - src0 == heir.coins, "coins conserved: only the heir's starting purse came in, counted (%d)" % heir.coins)
	check(w.players.size() == 2 and w.active_players().has(heir), "two players, the heir in play")
	var w2 := _reload(w)
	var h2: PlayerState = w2.player_of_ref(ref)
	check(h2 != null and h2.pid == heir.pid and h2.line == old_pid and h2.net_key == heir.net_key and w2.player_ref(h2) == ref, "save 21: the heir, its line and its identity load back")
	check(not w2.host_player().to_dict().has("line"), "the host's record has no line key")
	w.dispose()
	w2.dispose()


## Single player: the heir's path is as before (the reference "player", no identity, no line).
func test_host_heir_unchanged() -> void:
	var w := _world()
	var p := w.player
	var ad := _adults(w, 1)
	ad[0].partner = Life.PLAYER_ID
	p.partner = ad[0].id
	w.damage_player(99999.0, "a test")
	w.continue_as_heir()
	check(w.player != p and w.player.alive and w.player_ref(w.player) == "player" and w.player.line == 0 and w.player.net_key == "", "single player: the heir is the host, reference \"player\"")
	check(ad[0].partner == Life.FORMER_PLAYER, "and the dead player's links are retired as before (-3)")
	check(not w.player.to_dict().has("line") and not w.player.to_dict().has("net_key"), "with no new save keys")
	w.dispose()


## An older save (version 20) has no "players" key: one player, the host, nothing suspended or added.
func test_old_save() -> void:
	var f := FileAccess.open("res://tests/fixtures/b19_save_v20_seed3.json", FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	check(d is Dictionary and not (d as Dictionary).has("players"), "the Build 19 fixture has no players section")
	var w := World.new()
	w.load_dict(VillageMap.load_default(), d)
	w.suspend_guests()
	check(w.load_error == "" and w.players.size() == 1 and not w.host_player().away, "it loads as single player (the host alone, in play)")
	w.dispose()
