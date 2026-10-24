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
##   - the fine goes through the treasury (coins conserved); coordination is bounded (a look round a minute per guard);
##   - A7: a head of household who knows the player for a killer meets them as a threat to the family (shield, fight or
##     flee, the family-danger decision), one who does not carries on; the existing refusals apply to a killer (contracts and
##     courtship by notoriety, CRT-12); credit, barter and sales follow the villager's own ledger as the owner's numbers
##     weigh it (one murder seen does not, alone, make a witness refuse credit; shop sales never refuse: trade_sell forgo 0);
##   - A8: two players in one world (World.players, World.as_actor): a guest's killing is the guest's: their record, their
##     case, the guard's chase and blows, their killings count, the talk ("Gwen Fairlight killed ..." to the host, "you"
##     to the guest); never the host's. A villager who shares the player's first name is not taken for the player.
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
	test_family_fears_killer()
	test_trade_refused()
	test_two_players()
	test_name_collision()
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
	var ad := _adults(w, 5)
	var near_g: NPC = gs[0]
	var far_g: NPC = gs[1]
	var sleep_g: NPC = gs[2] if gs.size() > 2 else null
	var lone_g: NPC = gs[3] if gs.size() > 3 else null
	var victim: NPC = ad[0]
	var wit: NPC = ad[1]
	var hearer: NPC = ad[2]
	var relay: NPC = ad[3]
	var keep := [near_g, far_g, victim, wit, hearer, relay] + ([sleep_g] if sleep_g else []) + ([lone_g] if lone_g else [])
	var at := _stage(w, keep)
	var ear := float(Justice.cfg().hue_and_cry_tiles)
	var voice := float(GameData.b("witness_radius"))
	# MP C (owner decision 2026-10-24: the cry spreads from hearer to hearer): the witness cries out, a villager within its earshot
	# takes the cry up, and the guard and the second villager out of sight of the killing hear it from that villager
	wit.pos = at + Vector2(-2, 0)
	relay.pos = _at(w, at, voice - 1.0)
	near_g.pos = _at(w, relay.pos, voice - 1.0)
	if near_g.pos.distance_to(at) <= voice + 0.5:
		near_g.pos = _at(w, relay.pos, voice - 1.0, 8)
	hearer.pos = _at(w, relay.pos, voice - 2.0, 4)
	far_g.pos = _at(w, at, ear + 15.0, 4)                  # beyond the cry's reach
	if lone_g:
		lone_g.pos = _at(w, at, ear - 4.0, 12)            # within the cry's reach, out of earshot of every voice
	if sleep_g:
		sleep_g.pos = _at(w, relay.pos, 3.0, 2)
		sleep_g.anim = "sleep"
	_kill(w, victim)
	check(not victim.alive, "a killing, seen by a witness")
	check(w.justice.knows(near_g, "player") and w.justice.tier_for(near_g, "player") == "murder", "a guard within earshot, out of sight, hears the hue and cry: knows of the murder")
	check(str(near_g.pursuit.get("state", "")) == "responding" and Vector2(near_g.plan[0].to).distance_to(at) < 2.0, "and comes to the place")
	check(not w.justice.knows(far_g, "player") and far_g.pursuit.is_empty(), "a guard beyond earshot knows nothing")
	if lone_g and lone_g.pos.distance_to(relay.pos) > voice and lone_g.pos.distance_to(wit.pos) > voice and lone_g.pos.distance_to(hearer.pos) > voice and lone_g.pos.distance_to(near_g.pos) > voice:
		check(not w.justice.knows(lone_g, "player"), "a guard within the cry's reach but out of earshot of every voice does not hear it (owner 2026-10-24: no instant radius)")
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
	var by: NPC = _adults(w, 1)[0]                        # MP C: a bystander takes up the guard's call (the cry spreads by voices)
	var voice := float(GameData.b("witness_radius"))
	g.pos = at + Vector2(0.6, 0)
	by.plan.clear()
	by.anim = "idle"
	by.depth = 0
	by.pos = _at(w, at, voice - 1.0)
	other.pos = _at(w, by.pos, voice - 1.0)
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


## A head of household with a dependant outdoors (JudgmentFamily.head), for the danger tests.
func _head_and_child(w: World) -> Array:
	for c: NPC in w.npcs:
		if not c.alive or c.role != "child" or c.household < 0:
			continue
		var hd: NPC = JudgmentFamily.head(w, c.household)
		if hd != null and hd != c and hd.job != "guard" and JudgmentFamily.tier(w, hd, c) <= JudgmentFamily.TIER_PARENT:
			return [hd, c]
	return []


func test_family_fears_killer() -> void:
	var w := _world()
	var hc := _head_and_child(w)
	check(not hc.is_empty(), "a head of household with a child")
	var hd: NPC = hc[0]
	var kid: NPC = hc[1]
	var v: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.household != hd.household and n.job != "guard")[0]
	var at := _stage(w, [hd, kid, v])
	for b: NPC in w.npcs:
		if b.alive and b.role == "bandit":
			b.pos = Vector2(w.bandit_camp) + Vector2(0.5, 0.5)     # the bandits at their camp, not by the family
	# the killing: the head sees it from 6 tiles
	hd.pos = _at(w, at, 6.0)
	_kill(w, v)
	check(JudgmentFamily.knows_killer(w, hd, "player"), "the head saw the killing: knows the player for a killer")
	# later: the killer near the child, the head within reach
	w.minutes += 120.0
	kid.pos = _at(w, at, 2.0, 4)
	kid.plan.clear()
	hd.plan.clear()
	hd.report = {}
	var acted := JudgmentFamily.danger(w, hd)
	print("     the head, the killer by the child: %s, doing '%s'" % [str(acted), hd.doing])
	check(acted and hd.doing in ["shielding the family", "defending the family", "running from danger"], "meets the killer as a threat to the family (%s)" % hd.doing)
	# a head who knows nothing of it carries on
	var w2 := _world()
	var hc2 := _head_and_child(w2)
	var hd2: NPC = hc2[0]
	var kid2: NPC = hc2[1]
	var v2: NPC = w2.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.household != hd2.household and n.job != "guard")[0]
	var at2 := _stage(w2, [hd2, kid2, v2])
	for b: NPC in w2.npcs:
		if b.alive and b.role == "bandit":
			b.pos = Vector2(w2.bandit_camp) + Vector2(0.5, 0.5)
	hd2.pos = Vector2(5.5, 5.5)
	var wit: NPC = w2.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n != v2 and n.household != hd2.household and n.job != "guard")[0]
	wit.pos = at2 + Vector2(-2, 0)
	wit.anim = "idle"
	_kill(w2, v2)
	w2.minutes += 120.0
	hd2.pos = _at(w2, at2, 6.0)
	kid2.pos = _at(w2, at2, 2.0, 4)
	hd2.plan.clear()
	check(not JudgmentFamily.knows_killer(w2, hd2, "player") and not JudgmentFamily.danger(w2, hd2), "a head who does not know of the killing sees no threat in the player")
	hd2.memory.append("heard the hue and cry: %s %s killed %s %s" % [w2.player.name, w2.player.family, v2.name, v2.family])
	check(JudgmentFamily.knows_killer(w2, hd2, "player") and JudgmentFamily.danger(w2, hd2), "the same head, once they have heard who did it, does")
	w.dispose()
	w2.dispose()


func test_trade_refused() -> void:
	var w := _world()
	var ad := _adults(w, 3)
	var v: NPC = ad[0]
	var wit: NPC = ad[1]
	var seller: NPC = ad[2]
	var at := _stage(w, [v, wit])
	wit.pos = at + Vector2(-2, 0)
	var c0: Dictionary = w.contracts.evaluate(seller, "player", "log", 2, 5, 3)
	_kill(w, v)
	check(w.judgment.bad(wit.id, Life.PLAYER_ID) > 0, "the witness's own ledger holds the killing against the player (the morality stays authoritative)")
	var c1: Dictionary = w.contracts.evaluate(seller, "player", "log", 2, 5, 3)
	print("     a contract asked before and after the killing: %s | %s" % [str(c0.get("say", "")), str(c1.get("say", ""))])
	check(str(c1.get("say", "")).contains("not deal with you"), "after a killing villagers refuse the killer contracts (Relations notoriety, CRT-12)")
	check(w.relations.ask_court(Life.PLAYER_ID, seller).contains("After what you've done"), "and courtship")
	w.dispose()


func _guest(w: World) -> PlayerState:
	var g := PlayerState.new()
	g.name = "Gwen"
	g.family = "Fairlight"
	g.born = Life.born_for_age(25.0, w.minutes)     # a grown woman, as a new player is
	g.sex = "female"
	Identity.register_player(w, g)
	w.give_start_kit(g)
	w.add_guest(g)
	return g


func test_two_players() -> void:
	var w := _world()
	var host := w.player
	var gu := _guest(w)
	var g: NPC = _guards(w)[0]
	var ad := _adults(w, 2)
	var v: NPC = ad[0]
	var wit: NPC = ad[1]
	var at := _stage(w, [g, v, wit])
	gu.pos = at
	gu.max_hp = 9999.0
	gu.hp = 9999.0
	host.pos = _at(w, at, 14.0)
	host.max_hp = 9999.0
	host.hp = 9999.0
	g.pos = at + Vector2(5, 0)
	_sturdy(g)
	wit.pos = at + Vector2(-2, 0)
	v.pos = at + Vector2(0.6, 0)
	v.hp = 1.0
	w.player_hit_npc(v, 500.0, gu)
	var ref := w.player_ref(gu)
	check(not v.alive and gu.crimes.any(func(c): return c.kind == "killing") and host.crimes.is_empty(), "the guest's killing is on the guest's record, not the host's")
	check(not w.justice.case_of(ref).is_empty() and w.justice.case_of("player").is_empty(), "the case is the guest's (%s); the host has none" % ref)
	check(str(g.pursuit.get("ref", "")) == ref, "the guard is on the guest's case")
	check(w.relations.killings_of(ref) == 1 and w.relations.killings == 0, "the killing counts against the guest, not the host's family line")
	var single: NPC = w.npcs.filter(func(o: NPC) -> bool: return o.alive and o != v and w.relations.can_court(w.person_id(gu), o.id))[0]
	var reply: String = w.as_actor(gu, func(): return w.relations.ask_court(w.person_id(gu), single))     # MP C: the guest courts as itself
	check(reply.contains("After what"), "a villager will not walk out with the guest (%s)" % reply)
	check(not w.relations.ask_court(Life.PLAYER_ID, single).contains("After what"), "but holds nothing against the host")
	# the chase and the blows go to the guest
	var hp_h := host.hp
	var hp_g := gu.hp
	g.pos = gu.pos + Vector2(3, 0)
	g.attack_cd = 0.0
	for i in 60:
		w.brain.fight(g, 0.05)
		g.attack_cd = 0.0
	check(g.pos.distance_to(gu.pos) < 1.5 and gu.hp < hp_g and host.hp == hp_h, "the guard runs down and strikes the guest, never the host")
	# the talk: the witness accuses the guest to her face, names her to the host
	var to_guest: String = w.as_actor(gu, func(): return Dialogue.news(w, wit))
	var to_host := Dialogue.news(w, wit)
	print("     witness's news to the guest: %s | to the host: %s" % [to_guest, to_host])
	check(to_guest.contains("you killed"), "to the guest: \"you killed\"")
	check(to_host.contains("Gwen Fairlight killed") and not to_host.contains("you killed"), "to the host: \"Gwen Fairlight killed\", never \"you\"")
	var tagged := false
	for ev in w.judgment.facts:
		var f: Dictionary = w.judgment.fact(int(ev))
		if str(f.type) == "killing" and (f.tags as Array).has("by:" + ref):
			tagged = true
	check(tagged, "the judgment fact names the guest by reference (Batch C keys players as -2)")
	w.dispose()


func test_name_collision() -> void:
	var w := _world()
	var bandit: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "bandit")[0]
	var v: NPC = _adults(w, 1)[0]
	bandit.name = w.player.name                     # a bandit with the player's first name
	w.kill(v, "slain by %s" % bandit.name)
	check(w.relations.killings == 0 and w.justice.cases.is_empty() and w.player.crimes.is_empty(), "a bandit sharing the player's first name: the killing is not the player's")
	w.dispose()
