extends SceneTree
## GP-CRIME-PURSUIT step A3 (owner directive 2026-10-24, open item 03 C, E and F; owner answers 1 and 2): coordination,
## the hue and cry, escalation and proportionate force.
##   - a murder seen raises the hue and cry: guards within earshot (out of sight) learn of it and come; beyond it, none;
##     villagers within earshot learn who is cried after; a sleeper hears nothing; a killing nobody sees raises nothing;
##   - a second killing rings the bell (multiple murder): guards far across the village come; only guards that exist;
##   - guards share the case and the last-known place when they meet, and a free one joins;
##   - a villager who knows the offender and sees them tells a guard where (a sighting);
##   - a blow at a guard calls for help; theft or assault: guards beat the offender down and take them in (fined, goods
##     back), never killing; a beaten player may yield; murder after resistance and multiple murder: lethal;
##   - a guard who knows of a murder does not settle a theft with a fine; who kills again after being taken in for a
##     murder is a multiple murderer (the bell rings);
##   - the fine goes through the treasury (coins conserved); coordination is bounded (a look round a minute per guard).
## Run headless:
##   godot --headless --path game --script res://tests/manhunt_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	test_hue_and_cry()
	test_bell()
	test_share_and_sighting()
	test_guard_struck()
	test_take_in_and_yield()
	test_lethal()
	test_repeat_murderer()
	test_no_fine_for_a_murderer()
	test_bounded()
	print("manhunt_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


func _open(w: World, c: Vector2i) -> bool:
	return not w.map.is_solid(c) and w.place_of(Vector2(c) + Vector2(0.5, 0.5)) == ""


## An open stretch away from the camp; everyone but `keep` moved 120 tiles off; nobody in `keep` asleep.
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
					n.pos = Vector2(5.5, 5.5)          # far out of earshot (the map's corner)
					n.plan.clear()
			for n: NPC in keep:
				n.anim = "idle"
				n.plan.clear()
				n.depth = 0
			w.player.pos = at
			return at
	return Vector2.ZERO


func _guards(w: World) -> Array:
	return w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.job == "guard")


func _adults(w: World, k: int) -> Array:
	return w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.job != "guard").slice(0, k)


func _sturdy(n: NPC) -> void:
	n.max_hp = 9999.0
	n.hp = 9999.0


func _kill(w: World, v: NPC) -> void:
	v.pos = w.player.pos + Vector2(0.6, 0)
	v.hp = 1.0
	v.max_hp = 30.0
	w.player_hit_npc(v, 500.0)


## An open cell `d` tiles from `at`, outdoors.
func _at(w: World, at: Vector2, d: float, k0 := 0) -> Vector2:
	for k in range(k0, k0 + 16):
		var c := Vector2i((at + Vector2.RIGHT.rotated(TAU * k / 16.0) * d).floor())
		if _open(w, c):
			return Vector2(c) + Vector2(0.5, 0.5)
	return at + Vector2(d, 0)


func test_hue_and_cry() -> void:
	var w := _world()
	var gs := _guards(w)
	var ad := _adults(w, 4)
	var near_g: NPC = gs[0]
	var far_g: NPC = gs[1]
	var sleep_g: NPC = gs[2] if gs.size() > 2 else null
	var victim: NPC = ad[0]
	var wit: NPC = ad[1]
	var hearer: NPC = ad[2]
	var keep := [near_g, far_g, victim, wit, hearer] + ([sleep_g] if sleep_g else [])
	var at := _stage(w, keep)
	var ear := float(Justice.cfg().hue_and_cry_tiles)
	near_g.pos = _at(w, at, 20.0)                          # out of sight, within earshot
	far_g.pos = _at(w, at, ear + 15.0, 4)                  # beyond earshot
	wit.pos = at + Vector2(-2, 0)
	hearer.pos = _at(w, at, 22.0, 8)
	if sleep_g:
		sleep_g.pos = _at(w, at, 15.0, 12)
		sleep_g.anim = "sleep"
	_kill(w, victim)
	check(not victim.alive, "a killing, seen by a witness")
	check(w.justice.knows(near_g, "player") and w.justice.tier_for(near_g, "player") == "murder", "a guard within earshot, out of sight, hears the hue and cry: knows of the murder")
	check(str(near_g.pursuit.get("state", "")) == "responding" and Vector2(near_g.plan[0].to).distance_to(at) < 2.0, "and comes to the place")
	check(not w.justice.knows(far_g, "player") and far_g.pursuit.is_empty(), "a guard beyond earshot knows nothing")
	if sleep_g:
		check(not w.justice.knows(sleep_g, "player"), "a sleeping guard does not hear it")
	check(w.justice.case_of("player").aware.has(str(hearer.id)) and hearer.memory.any(func(m): return str(m).begins_with("heard the hue and cry: ")), "a villager within earshot learns who is cried after")
	check(int(w.stats.get("justice_hue_and_cry", 0)) == 1, "one hue and cry")
	# a killing nobody sees raises nothing
	var w2 := _world()
	var v2: NPC = _adults(w2, 1)[0]
	var g2: NPC = _guards(w2)[0]
	var at2 := _stage(w2, [v2, g2])
	g2.pos = _at(w2, at2, 20.0)
	_kill(w2, v2)
	check(int(w2.stats.get("justice_hue_and_cry", 0)) == 0 and not w2.justice.knows(g2, "player"), "a killing nobody sees raises no cry; no guard knows of it")
	w.dispose()
	w2.dispose()


func test_bell() -> void:
	var w := _world()
	var gs := _guards(w)
	var ad := _adults(w, 3)
	var g0: NPC = gs[0]
	var far_g: NPC = gs[1]
	var keep := [g0, far_g] + ad
	var at := _stage(w, keep)
	g0.pos = at + Vector2(4, 0)
	_sturdy(g0)
	w.player.hp = 9999.0
	w.player.max_hp = 9999.0
	far_g.pos = _at(w, at, 60.0)
	var npc_count := w.npcs.size()
	_kill(w, ad[0])
	check(not w.justice.knows(far_g, "player"), "one murder: the far guard (60 tiles) has not heard")
	ad[1].pos = w.player.pos + Vector2(0.6, 0)
	_kill(w, ad[1])
	check(w.justice.known_tier("player") == "multiple_murder", "a second killing seen: multiple murder")
	check(int(w.stats.get("justice_bell", 0)) == 1 and w.justice.knows(far_g, "player"), "the bell rings: the guard 60 tiles off learns of it")
	check(not far_g.pursuit.is_empty(), "and comes")
	var hunting := _guards(w).filter(func(g: NPC) -> bool: return not g.pursuit.is_empty()).size()
	check(w.npcs.size() == npc_count and hunting <= _guards(w).size(), "only the village's own guards come (%d of %d), none made" % [hunting, _guards(w).size()])
	w.dispose()


func test_share_and_sighting() -> void:
	var w := _world()
	var gs := _guards(w)
	var ad := _adults(w, 2)
	var a: NPC = gs[0]
	var b: NPC = gs[1]
	var victim: NPC = ad[0]
	var wit: NPC = ad[1]
	var at := _stage(w, [a, b, victim, wit])
	_sturdy(victim)
	a.pos = at + Vector2(4, 0)
	b.pos = _at(w, at, 40.0)
	wit.pos = at + Vector2(-2, 0)
	w.player.hp = 9999.0
	w.player_hit_npc(victim, 1.0)                    # an assault: no cry (nobody pursued yet)
	check(w.justice.knows(a, "player") and not w.justice.knows(b, "player"), "an assault: the guard who saw it knows, the other does not")
	# the player gets away: a searches; b comes into a's sight
	w.player.pos = _at(w, at, 30.0, 3)
	w.brain.fight(a, 0.05)
	check(str(a.pursuit.get("state", "")) == "searching", "the guard who lost the player searches")
	b.pos = a.pos + Vector2(2, 0) if _open(w, Vector2i((a.pos + Vector2(2, 0)).floor())) else a.pos + Vector2(0, 2)
	b.anim = "idle"
	b.target = -1
	b.plan.clear()
	w.minutes += float(Justice.cfg().share_minutes) + 0.1
	w.brain.pursue(a)
	check(w.justice.knows(b, "player") and w.justice.tier_for(b, "player") == "assault", "guards who meet share the case")
	check(str(b.pursuit.get("state", "")) == "responding" and Vector2(float(b.pursuit.at[0]), float(b.pursuit.at[1])).distance_to(Vector2(float(a.pursuit.at[0]), float(a.pursuit.at[1]))) < 0.01,
			"and the free one joins, from the last-known place")
	# a witness who knows the player sees them again: they tell a guard where
	wit.report = {}
	wit.plan.clear()
	wit.pos = w.player.pos + Vector2(3, 0) if _open(w, Vector2i((w.player.pos + Vector2(3, 0)).floor())) else w.player.pos + Vector2(0, 3)
	wit.anim = "idle"
	check(w.justice.sighting(wit) and str(wit.report.get("how", "")) == "sighting" and Vector2(float(wit.report.at[0]), float(wit.report.at[1])).distance_to(w.player.pos) < 0.01,
			"a villager who knows the offender and sees them will tell a guard where they are")
	check(not w.justice.sighting(wit), "but not again at once")
	var stranger: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.job != "guard" and n != wit and n != victim)[0]
	stranger.pos = wit.pos
	stranger.anim = "idle"
	check(not w.justice.sighting(stranger), "one who does not know what the player did reports nothing")
	w.dispose()


func test_guard_struck() -> void:
	var w := _world()
	var gs := _guards(w)
	var g: NPC = gs[0]
	var other: NPC = gs[1]
	var at := _stage(w, [g, other])
	_sturdy(g)
	g.pos = at + Vector2(0.6, 0)
	other.pos = _at(w, at, 20.0)
	w.player.hp = 9999.0
	w.player_hit_npc(g, 1.0)
	check(w.player.crimes[-1].kind == "guard_assault" and g.target == Life.PLAYER_ID, "a guard struck takes the player on")
	check(int(w.stats.get("justice_hue_and_cry", 0)) == 1 and w.justice.knows(other, "player") and not other.pursuit.is_empty(), "and calls for help: a guard within earshot comes")
	w.dispose()


func test_take_in_and_yield() -> void:
	var w := _world()
	var g: NPC = _guards(w)[0]
	var ad := _adults(w, 2)
	var v: NPC = ad[0]
	var at := _stage(w, [g, v])
	_sturdy(v)
	g.pos = at + Vector2(3, 0)
	v.pos = at + Vector2(0.6, 0)
	# stolen goods in the pack: a theft seen by no guard first
	g.pos = at + Vector2(40, 0)
	w.player.inv.add("bread", 2)
	w.player.mark_stolen("bread", v.id, 2)
	w.player.coins = 500
	w.player.hp = 9999.0
	g.pos = at + Vector2(3, 0)
	w.player_hit_npc(v, 1.0)
	check(w.justice.tier_for(g, "player") == "assault" and not w.justice.lethal(g, "player"), "an assault: the guard may not kill")
	w.player.hp = 3.0
	w.player.max_hp = 40.0
	var coins0 := w.total_coins()
	var treas0 := w.treasury
	var bread0 := v.inv.count("bread")
	g.pos = w.player.pos + Vector2(0.8, 0)
	g.attack_cd = 0.0
	for i in 40:
		w.brain.fight(g, 0.05)
		if g.target == -1:
			break
	check(w.player.alive and w.player.hp >= float(Justice.cfg().subdue_hp), "beaten down, not killed (health %.1f)" % w.player.hp)
	check(w.justice.status("player") == "clear" and g.pursuit.is_empty() and g.target == -1, "taken in: the case settled, the guard off it")
	var fine := int(Justice.response("assault").yield_fine) + World.theft_fine_for({"bread": 2})
	check(w.treasury - treas0 == fine and w.total_coins() == coins0, "fined %d to the manor's treasury; no coin made or lost" % fine)
	check(v.inv.count("bread") == bread0 + 2 and w.player.stolen_count("bread") == 0, "the stolen goods go back to their owner")
	check(w.justice.case_of("player").crimes.all(func(c): return str(c.settled) != ""), "every crime settled (taken)")
	# yield: a beaten player with a guard of the case in sight
	var w2 := _world()
	var g2: NPC = _guards(w2)[0]
	var v2: NPC = _adults(w2, 1)[0]
	var at2 := _stage(w2, [g2, v2])
	_sturdy(v2)
	g2.pos = at2 + Vector2(3, 0)
	v2.pos = at2 + Vector2(0.6, 0)
	w2.player.hp = 9999.0
	w2.player.max_hp = 40.0
	w2.player.coins = 7
	w2.player_hit_npc(v2, 1.0)
	w2.player.hp = 40.0
	check(not w2.player_yield().ok, "a player not beaten cannot yield")
	w2.player.hp = 10.0
	var t0 := w2.treasury
	var r := w2.player_yield()
	check(r.ok and w2.justice.status("player") == "clear" and g2.target == -1 and w2.player.coins == 0 and w2.treasury - t0 == 7, "a beaten player yields: fined all they have (%s)" % r.text)
	check(w2.relations.notoriety() >= 0 and w2.player.crimes[-1].kind == "assault", "the record keeps the assault (the morality ledgers are untouched)")
	w.dispose()
	w2.dispose()


func test_lethal() -> void:
	var w := _world()
	var g: NPC = _guards(w)[0]
	var ad := _adults(w, 3)
	var at := _stage(w, [g] + ad)
	_sturdy(g)
	g.pos = at + Vector2(4, 0)
	w.player.hp = 9999.0
	_kill(w, ad[0])
	check(w.justice.tier_for(g, "player") == "murder" and not w.justice.lethal(g, "player"), "one murder, no resistance: the guard beats the murderer down")
	w.player.pos = g.pos + Vector2(0.6, 0)
	w.player_hit_npc(g, 1.0)
	check(w.justice.lethal(g, "player"), "a murderer who strikes a guard has resisted: lethal force allowed")
	var w2 := _world()
	var g2: NPC = _guards(w2)[0]
	var ad2 := _adults(w2, 3)
	var at2 := _stage(w2, [g2] + ad2)
	_sturdy(g2)
	g2.pos = at2 + Vector2(4, 0)
	w2.player.hp = 9999.0
	_kill(w2, ad2[0])
	ad2[1].pos = w2.player.pos + Vector2(0.6, 0)
	_kill(w2, ad2[1])
	check(w2.justice.lethal(g2, "player"), "a multiple murderer may be killed")
	w2.player.hp = 5.0
	w2.player.max_hp = 40.0
	w2.player.armor = ""
	g2.pos = w2.player.pos + Vector2(0.8, 0)
	g2.attack_cd = 0.0
	if not Life.is_player_id(g2.target):
		w2.justice.engage(g2, "player", "pursuing")
	for i in 400:
		w2.brain.fight(g2, 0.05)
		if not w2.player.alive:
			break
		g2.attack_cd = 0.0
	check(not w2.player.alive and w2.justice.cases.is_empty(), "who keeps fighting can die by the guards' hand; the case then ends")
	w.dispose()
	w2.dispose()


func test_no_fine_for_a_murderer() -> void:
	var w := _world()
	var g: NPC = _guards(w)[0]
	var ad := _adults(w, 2)
	var at := _stage(w, [g] + ad)
	_sturdy(g)
	g.pos = at + Vector2(4, 0)
	w.player.hp = 9999.0
	_kill(w, ad[0])
	w.justice.release(g, "test")
	g.target = -1
	w.player.inv.add("bread", 1)
	var t0 := w.treasury
	w.witness("theft", "a loaf", ad[1], {"bread": 1}, null)
	check(w.treasury == t0 and g.target == Life.PLAYER_ID, "a guard who knows of a murder does not take a fine for a theft: they take the murderer on")
	w.dispose()


func test_bounded() -> void:
	var w := _world()
	var gs := _guards(w)
	var v: NPC = _adults(w, 1)[0]
	var at := _stage(w, gs + [v])
	_sturdy(v)
	for i in gs.size():
		gs[i].pos = at + Vector2(2 + i, 1)
	w.player.hp = 9999.0
	w.player_hit_npc(v, 1.0)
	w.player.pos = _at(w, at, 40.0)
	var t := Time.get_ticks_usec()
	var ticks := 0
	for k in 1200:                                  # 60 real seconds = 120 game minutes, every guard each tick
		w.minutes += 0.1
		for g: NPC in gs:
			w._update_npc(g, 0.05)
			ticks += 1
	var us := float(Time.get_ticks_usec() - t) / float(ticks)
	var looks := int(w.stats.get("justice_share_looks", 0))
	var bound := gs.size() * (120.0 / float(Justice.cfg().share_minutes) + 1.0)
	print("     %d guards, %d ticks: %.1f us a guard tick (walking included); %d looks round (bound %d)" % [gs.size(), ticks, us, looks, int(bound)])
	check(looks <= bound, "coordination is bounded: at most one look round a minute for each guard on a case")
	check(us < 2000.0, "a guard's tick on a case stays cheap (%.1f us, walking and path-finding included)" % us)
	w.dispose()


func test_repeat_murderer() -> void:
	var w := _world()
	var g: NPC = _guards(w)[0]
	var ad := _adults(w, 3)
	var at := _stage(w, [g] + ad)
	_sturdy(g)
	g.pos = at + Vector2(4, 0)
	w.player.hp = 9999.0
	_kill(w, ad[0])
	w.justice.take_in(g, "player", "taken")
	check(w.justice.status("player") == "clear" and w.justice.tier_for(g, "player") == "minor", "taken in for the murder: nothing outstanding")
	ad[1].pos = w.player.pos + Vector2(0.6, 0)
	_kill(w, ad[1])
	check(w.justice.tier_for(g, "player") == "multiple_murder" and int(w.stats.get("justice_bell", 0)) == 1, "killing again after answering for a murder: a multiple murderer, the bell rings")
	w.dispose()
