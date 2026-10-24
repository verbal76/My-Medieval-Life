extends SceneTree
## MP Batch C (docs/multiplayer/BATCH_C.md), gate G2 in one process: every player is a full individual of the one simulation.
##  - identities: each player's person id (World.person_id: -2 the host's line, -line a guest's), references, Contracts.ref_of;
##  - parity: each verb of the checklist done by the host in one world and by a guest in an identical world gives the actor the
##    same outcome (purse, pack, skills, crimes, case, ties, judgment ledgers, holdings...) and leaves the other player untouched,
##    the coin and goods census conserved: the same rules for host and guest, no guest-only path;
##  - the G2 matrix of the owner's directive (2026-10-24): two players and one villager, different opinions of each, a crime by one
##    with the other innocent, separate quests, independent marriages and succession (two families, no collision), a shared
##    transaction without duplication, two grabs for one limited thing, rest by agreement (MP-D2), stations held apart;
##  - every network verb (NetActions.VERBS) resolves and is sent by its verb (World.mirror), and the host refuses another player's
##    reference, an unknown verb and what is out of reach;
##  - save 22: round trip, the Build 20 save (56c24cb, tests/fixtures/b20_save_v21_single.json) and a save 21 with a guest (805a1c9)
##    migrated with nothing lost, idempotently.
##   godot --headless --path game --script res://tests/multiplayer_c_test.gd

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
	test_identities()
	test_verbs_catalog()
	test_refusals()
	test_parity()
	test_one_villager_two_players()
	test_crime_one_innocent_other()
	test_quests_apart()
	test_asks_apart()
	test_families_and_succession()
	test_shared_transaction()
	test_limited_resource()
	test_rest_by_agreement()
	test_stations_apart()
	test_consent_between_players()
	test_animals_and_bandits()
	test_save22()
	test_build20_migration()
	test_save21_guest_migration()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ------------------------------------------------------------------ helpers ----------------------
func _world(seed_ := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed_)
	return w


func _guest(w: World, nm := "Gwen", key := "ab") -> PlayerState:
	var g := PlayerState.new()
	g.name = nm
	g.family = "Fairlight"
	g.sex = "female"
	g.born = w.player.born
	Identity.register_player(w, g)
	w.give_start_kit(g)
	g.pos = w.player.pos + Vector2(3, 0)
	g.net_key = key.repeat(32)
	w.add_guest(g)
	w.as_actor(g, w.quests.start_story)          # a newcomer seeks the sage, as every new character does (NetSession.guest_state)
	return g


func _adults(w: World) -> Array:
	return w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.job != "guard")


func _open(w: World, c: Vector2i) -> bool:
	return not w.map.is_solid(c) and w.place_of(Vector2(c) + Vector2(0.5, 0.5)) == ""


## An open outdoor cell next to `c` (or `c`).
func _beside(w: World, c: Vector2i) -> Vector2:
	for off in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1)]:
		if _open(w, c + off):
			return Vector2(c + off) + Vector2(0.5, 0.5)
	return Vector2(c) + Vector2(0.5, 0.5)


## Every good in the world, over every holder, as item -> count.
func _goods(w: World) -> Dictionary:
	var out := {}
	_flat(SettlementHoldings.goods(w), out)
	return out


func _flat(v, out: Dictionary) -> void:
	if v is Dictionary:
		for k in v:
			if v[k] is Dictionary:
				_flat(v[k], out)
			elif (v[k] is int or v[k] is float) and GameData.items.has(str(k)):
				out[str(k)] = int(out.get(str(k), 0)) + int(v[k])


func _census(w: World) -> Dictionary:
	return {"coins": w.total_coins(), "goods": _goods(w)}


## What a player is, for comparing the host's turn with a guest's: their own records, ids mapped to "me".
func _summary(w: World, p: PlayerState) -> Dictionary:
	var me := w.person_id(p)
	var ref := w.player_ref(p)
	var ties := {}
	for n: NPC in w.npcs:
		var t: Dictionary = w.relations.peek(me, n.id)
		if float(t.regard) != 0.0 or float(t.attraction) != 0.0 or bool(t.friends):
			ties[n.id] = [snappedf(float(t.regard), 0.01), snappedf(float(t.attraction), 0.01), bool(t.friends), str(t.stage)]
	var good := 0
	var bad := 0
	if w.judgment != null:
		for n: NPC in w.npcs:
			good += w.judgment.good(n.id, me)
			bad += w.judgment.bad(n.id, me)
	var held := 0
	for pl in w.plots:
		if str(pl.get("owner", "")) == ref or str(pl.get("tenant", "")) == ref:
			held += 1
	var crimes := []
	for c in p.crimes:
		crimes.append(str(c.kind))
	return {"coins": p.coins, "inv": p.inv.items.duplicate(), "hp": snappedf(p.hp, 0.01), "skills": p.skills.duplicate(), "crimes": crimes,
		"case": (w.justice.case_of(ref).get("crimes", []) as Array).size(), "tier": w.justice.known_tier(ref) if not w.justice.case_of(ref).is_empty() else "",
		"killings": w.relations.killings_of(ref), "notoriety": w.relations.notoriety(p), "ties": ties, "good": good, "bad": bad,
		"quests": p.quests.size(), "home": p.home, "partner": p.partner, "held": held, "carts": w.carts.of(ref).size(),
		"contracts": w.contracts.list.filter(func(c): return str(c.buyer) == ref or str(c.seller) == ref).size(),
		"debts": w.credit.debts.filter(func(d): return str(d.creditor) == ref or str(d.debtor) == ref).size(),
		"chest": p.chest.items.duplicate(), "level": p.map_level, "tool": p.tool}


## Two identical worlds, each with the host and one guest: in `a` the host acts, in `b` the guest; `prep` stands the actor where the
## scenario needs (the other player 60 tiles off in both), `act` does it as the actor. Same outcome for the actor, the other player
## untouched, the census conserved, and `effect(before, after)` (the scenario did something).
func parity(name: String, prep: Callable, act: Callable, effect: Callable, seed_ := 1) -> void:
	var sums := []
	var results := []
	for k in 2:
		var w := _world(seed_)
		var g := _guest(w)
		var actor: PlayerState = w.host_player() if k == 0 else g
		var other: PlayerState = g if k == 0 else w.host_player()
		var ctx: Dictionary = prep.call(w, actor)
		if ctx.has("skip"):
			check(false, "%s: the scenario could not be set up (%s)" % [name, str(ctx.skip)])
			w.dispose()
			return
		other.pos = actor.pos + Vector2(60, 0)
		var other0 := JSON.stringify(other.to_dict(), "", true)
		var c0 := _census(w)
		var s0 := _summary(w, actor)
		var r = w.as_actor(actor, func(): return act.call(w, actor, ctx))
		var s1 := _summary(w, actor)
		var c1 := _census(w)
		var other1 := JSON.stringify(other.to_dict(), "", true)
		check(other1 == other0, "%s (%s acting): the other player is untouched%s" % [name, "host" if k == 0 else "guest",
			"" if other1 == other0 else " " + _diff(JSON.parse_string(other0), JSON.parse_string(other1))])
		var coins_in := int(w.stats.get("newcomer_coins_in", 0))
		check(c1.coins == c0.coins, "%s (%s acting): coins conserved (%d / %d)" % [name, "host" if k == 0 else "guest", c0.coins, c1.coins])
		var made := _made(c0.goods, c1.goods)
		check(effect.call(s0, s1, made), "%s (%s acting): it happened (%s)" % [name, "host" if k == 0 else "guest", _diff(s0, s1)])
		sums.append(s1)
		var rs := JSON.stringify(NetActions.enc(w, r), "", true)
		if k == 1:                                   # the guest's own reference and id read as the host's would
			rs = rs.replace("player:%d" % g.pid, "player").replace(str(-g.pid), "-2")
		results.append(rs)
		w.dispose()
	check(JSON.stringify(sums[0], "", true) == JSON.stringify(sums[1], "", true), "%s: the guest gets exactly what the host gets (same rules)%s" % [name,
		"" if JSON.stringify(sums[0], "", true) == JSON.stringify(sums[1], "", true) else " " + _diff(sums[0], sums[1])])
	check(results[0] == results[1], "%s: and the verb answers the same%s" % [name, "" if results[0] == results[1] else " (%s / %s)" % [results[0].left(200), results[1].left(200)]])


func _made(a: Dictionary, b: Dictionary) -> Dictionary:
	var out := {}
	for k in a.keys() + b.keys():
		var d := int(b.get(k, 0)) - int(a.get(k, 0))
		if d != 0:
			out[k] = d
	return out


func _diff(a: Dictionary, b: Dictionary) -> String:
	var out := []
	for k in a:
		if JSON.stringify(a[k]) != JSON.stringify(b.get(k)):
			if a[k] is Array and b.get(k) is Array and (a[k] as Array).size() == (b[k] as Array).size():
				for i in (a[k] as Array).size():
					if a[k][i] is Dictionary and b[k][i] is Dictionary and JSON.stringify(a[k][i]) != JSON.stringify(b[k][i]):
						out.append("%s[%d]: %s" % [k, i, _diff(a[k][i], b[k][i])])
						break
				continue
			out.append("%s: %s -> %s" % [k, JSON.stringify(a[k]).left(120), JSON.stringify(b.get(k)).left(120)])
	return "; ".join(out)


# ------------------------------------------------------------------ identities -------------------
func test_identities() -> void:
	var w := _world()
	var host := w.player
	var g := _guest(w)
	check(w.person_id(host) == Life.PLAYER_ID and w.person_id(g) == -g.pid and Life.is_player_id(-g.pid) and Life.is_player_id(-2),
		"person ids: the host's line -2, the guest's the negative of its pid (%d)" % w.person_id(g))
	check(not Life.is_player_id(-1) and not Life.is_player_id(Life.FORMER_PLAYER) and not Life.is_player_id(5) and not Life.is_player_id(g.pid),
		"no villager id, -1, -3 or a positive id is a player's")
	check(w.player_of_id(-2) == host and w.player_of_id(-g.pid) == g and w.player_of_id(-999999999) == null, "player_of_id finds each player")
	check(World.ref_of_id(-g.pid) == "player:%d" % g.pid and World.id_of_ref("player:%d" % g.pid) == -g.pid and World.id_of_ref("player") == -2 and World.id_of_ref("npc:3") == -1,
		"a person id and a reference name the same player")
	check(Contracts.ref_of(g) == "player:%d" % g.pid and Contracts.ref_of(host) == "player", "Contracts.ref_of (and Credit) names a guest as itself, the host as \"player\"")
	check(w.as_actor(g, func(): return w.acting_id()) == -g.pid and w.acting_id() == -2, "the acting player's id follows as_actor")
	check(w.player_for("player:%d" % g.pid) == g and w.player_for("player") == host, "a party reference finds its own player whoever acts")
	w.dispose()


func test_verbs_catalog() -> void:
	var w := _world()
	var bad := []
	var unsent := []
	for path in NetActions.VERBS:
		if not NetActions.target(w, path).is_valid():
			bad.append(path)
	var src := ""
	for f in ["res://scripts/core/world.gd"]:
		src += FileAccess.get_file_as_string(f)
	var dir := DirAccess.open("res://scripts/core")
	for f in dir.get_files():
		if f.ends_with(".gd"):
			src += FileAccess.get_file_as_string("res://scripts/core/" + f)
	for f in DirAccess.open("res://scripts/core/settlement").get_files():
		if f.ends_with(".gd"):
			src += FileAccess.get_file_as_string("res://scripts/core/settlement/" + f)
	for path in NetActions.VERBS:
		if path == "player_rest":
			if not src.contains('remote.call("player_rest"'):
				unsent.append(path)
		elif not src.contains('mirror("%s"' % path):
			unsent.append(path)
	check(bad.is_empty(), "every network verb names a verb of the world (%d verbs)%s" % [NetActions.VERBS.size(), "" if bad.is_empty() else ": " + str(bad)])
	check(unsent.is_empty(), "and every one is sent by its own verb on a guest's machine (World.mirror)%s" % ("" if unsent.is_empty() else ": " + str(unsent)))
	var by := {}
	for path in NetActions.VERBS:
		by[NetActions.VERBS[path]] = int(by.get(NetActions.VERBS[path], 0)) + 1
	check(["C1", "C2", "C3", "C4", "C5", "C6", "C7"].all(func(c): return by.has(c)), "verbs in every sub-batch C1-C7: %s" % str(by))
	w.dispose()


func test_refusals() -> void:
	var w := _world()
	var host := w.player
	var g := _guest(w)
	var c0 := host.coins
	var r := NetActions.apply_verb(w, g, "conjure_gold", [])
	check(not r.ok, "an unknown verb is refused (%s)" % r.text)
	r = NetActions.apply_verb(w, g, "start_site", [NetActions.enc(w, w.plots[0]), "house", "player"])
	check(not r.ok and r.text == "That is not yours.", "a guest naming the host's reference is refused: nothing is done for or to another player")
	r = NetActions.apply_verb(w, g, "player_set_down_cart", [g.pos + Vector2(100, 0)])
	check(not r.ok and r.text == "That is too far away.", "what is out of the guest's reach is refused")
	r = NetActions.apply_verb(w, g, "player_buy_many", [{"$npc": 999999}, "bread", 1])
	check(not r.ok, "a villager who is not there is refused")
	r = NetActions.apply_verb(w, g, "player_eat", [{"$pid": host.pid}])
	check(not r.ok and host.coins == c0, "another player's character as an argument is refused")
	r = NetActions.apply_verb(w, g, "relations.give", [-2, {"$npc": _adults(w)[0].id}, "bread"])
	check(not r.ok, "giving as the host's person id is refused")
	var food := ""
	for id in g.inv.items:
		if GameData.item(id).has("food"):
			food = id
	r = NetActions.apply_verb(w, g, "player_eat", [food])
	check(r.ok and r.result == true and not r.player.is_empty(), "the guest's own verb is applied as the guest, and the answer carries its character")
	w.dispose()


# ------------------------------------------------------------------ parity, verb by verb -----------
func test_parity() -> void:
	# C1: eating, medicine, equipment, dropping
	parity("C1 eat", func(w: World, p: PlayerState): p.hunger = 40.0; p.inv.add("bread", 1); return {},
		func(w: World, p: PlayerState, _c): return w.player_eat("bread"),
		func(a, b, _m): return int(b.inv.get("bread", 0)) < int(a.inv.get("bread", 0)))
	parity("C1 equip and unequip", func(w: World, p: PlayerState): p.inv.add("iron_sword", 1); return {},
		func(w: World, p: PlayerState, _c): w.player_equip("iron_sword"); return w.player_unequip("weapon"),
		func(a, b, _m): return true)
	parity("C1 drop and pick up again", func(w: World, p: PlayerState): p.inv.add("apple", 2); return {},
		func(w: World, p: PlayerState, _c):
			w.player_drop("apple", 2)
			return w.player_loot(w.loot.size() - 1),
		func(a, b, _m): return int(b.inv.get("apple", 0)) == int(a.inv.get("apple", 0)))
	# C2: gathering, mining, felling, crafting, the family chest
	parity("C2 pick a wild plant", func(w: World, p: PlayerState):
			for pl in w.plants:
				if str(pl.state) == "ripe" and not pl.get("ow", false):
					p.pos = _beside(w, Vector2i(int(pl.x), int(pl.y)))
					return {"pl": Vector2i(int(pl.x), int(pl.y))}
			return {"skip": "no ripe plant"},
		func(w: World, p: PlayerState, c): return w.player_pick_plant(w.plant_at(c.pl)),
		func(a, b, _m): return JSON.stringify(a.inv) != JSON.stringify(b.inv))
	parity("C2 mine a seam", func(w: World, p: PlayerState):
			for d in w.deposits:
				if int(d.amount) > 5 and World.level_of(d) == 0 and str(d.ore) == "stone":
					p.pos = _beside(w, Vector2i(int(d.x), int(d.y)))
					p.inv.add("pickaxe", 1)
					p.tool = "pickaxe"
					return {"d": Vector2i(int(d.x), int(d.y))}
			return {"skip": "no stone seam"},
		func(w: World, p: PlayerState, c): return w.player_mine(w.deposit_at(c.d), "pickaxe"),
		func(a, b, _m): return int(b.inv.get("stone", 0)) > int(a.inv.get("stone", 0)))
	parity("C2 fell a tree", func(w: World, p: PlayerState):
			for t in w.trees:
				if str(t.state) == "grown":
					p.pos = _beside(w, Vector2i(int(t.x), int(t.y)))
					p.inv.add("axe", 1)
					p.tool = "axe"
					return {"t": Vector2i(int(t.x), int(t.y))}
			return {"skip": "no grown tree"},
		func(w: World, p: PlayerState, c):
			var r := {}
			for i in 30:
				r = w.player_chop(w.tree_at(c.t), 1, "axe")
				if str(r.get("result", "")) != "blow":
					break
			return r,
		func(a, b, _m): return int(b.inv.get("log", 0)) > int(a.inv.get("log", 0)))
	parity("C2 craft", func(w: World, p: PlayerState):
			var ids: Array = GameData.recipes.keys()
			ids.sort()
			for id in ids:
				var rc: Dictionary = GameData.recipes[id]
				if int(rc.get("level", 1)) <= 1 and w.craft_tool(p, id) != "-" and not rc.has("conserve"):
					for m in rc["in"]:
						p.inv.add(m, int(rc["in"][m]) * 2)
					return {"r": id}
			return {"skip": "no first-level recipe"},
		func(w: World, p: PlayerState, c): return w.player_craft(c.r),
		func(a, b, _m): return JSON.stringify(a.inv) != JSON.stringify(b.inv))
	# C3: buying and selling, a contract
	parity("C3 buy", func(w: World, p: PlayerState):
			for n: NPC in _adults(w):
				for id in n.inv.ids():
					if not w.brain.keeps(n, id) and GameData.value(id) > 0 and w.player_quote(n, id, 1, true).size() == 1:
						p.coins = 500
						p.pos = n.pos + Vector2(1, 0)
						return {"n": n.id, "id": id}
			return {"skip": "no vendor"},
		func(w: World, p: PlayerState, c): return w.player_buy_many(w.npc(c.n), c.id, 1),
		func(a, b, _m): return b.coins < a.coins and int(b.inv.get(_m.keys()[0] if not _m.is_empty() else "", 0)) >= 0)
	parity("C3 sell", func(w: World, p: PlayerState):
			p.inv.add("log", 3)
			for n: NPC in w.npcs:
				if n.alive and w.sale_refusal(n, p, "log", 1) == "":
					p.pos = n.pos + Vector2(1, 0)
					return {"n": n.id}
			return {"skip": "no buyer of logs"},
		func(w: World, p: PlayerState, c): return w.player_sell_many(w.npc(c.n), "log", 1),
		func(a, b, _m): return b.coins > a.coins)
	parity("C3 propose a contract", func(w: World, p: PlayerState):
			for n: NPC in _adults(w):
				if n.job == "miner":
					p.coins = 600
					p.pos = n.pos + Vector2(1, 0)
					return {"n": n.id}
			return {"skip": "no miner"},
		func(w: World, p: PlayerState, c): return w.contracts.propose(w.acting_ref(), w.npc(c.n), "iron_ore", 3, 30, 3),
		func(a, b, _m): return b.contracts > a.contracts or b.coins != a.coins)
	# C4: property, a cart, a stall
	parity("C4 set a cart down", func(w: World, p: PlayerState): p.inv.add("handcart", 1); return {},
		func(w: World, p: PlayerState, _c): return w.player_set_down_cart(p.pos + Vector2(1, 0)),
		func(a, b, _m): return b.carts == a.carts + 1)
	parity("C4 buy a plot", func(w: World, p: PlayerState):
			var best := {}
			for pl in w.plots:
				if w.property.for_sale(pl) and (best.is_empty() or int(pl.price) < int(best.price)):
					best = pl
			if best.is_empty():
				return {"skip": "no plot for sale"}
			p.coins = int(best.price) + 50
			p.pos = Vector2(float(best.door[0]) + 0.5, float(best.door[1]) + 1.5)
			return {"id": str(best.id)},
		func(w: World, p: PlayerState, c):
			for pl in w.plots:
				if str(pl.id) == c.id:
					return w.buy_plot(pl)
			return false,
		func(a, b, _m): return b.held == a.held + 1 and b.coins < a.coins)
	parity("C4 rent a market pitch", func(w: World, p: PlayerState): p.coins = 400; return {},
		func(w: World, p: PlayerState, _c): return w.business.rent(),
		func(a, b, _m): return b.coins < a.coins)
	# C5: talk, a gift, a friend
	parity("C5 talk and give", func(w: World, p: PlayerState):
			var n: NPC = _adults(w)[0]
			p.pos = n.pos + Vector2(1, 0)
			p.inv.add("flower", 1)
			return {"n": n.id},
		func(w: World, p: PlayerState, c):
			w.relations.talked(w.npc(c.n))
			return w.relations.give(w.acting_id(), w.npc(c.n), "flower"),
		func(a, b, _m): return b.ties.size() > a.ties.size())
	# C6: an assault, a pickpocket
	parity("C6 strike a villager", func(w: World, p: PlayerState):
			var n: NPC = _adults(w)[1]
			p.pos = n.pos + Vector2(0.6, 0)
			p.hp = 9999.0
			p.max_hp = 9999.0
			return {"n": n.id},
		func(w: World, p: PlayerState, c): return w.player_hit_npc(w.npc(c.n), 1.0),
		func(a, b, _m): return b.crimes.size() > a.crimes.size() and b.case > a.case)
	parity("C6 pick a pocket", func(w: World, p: PlayerState):
			var n: NPC = _adults(w)[2]
			n.coins = maxi(n.coins, 30)
			p.pos = n.pos + Vector2(0.6, 0)
			return {"n": n.id},
		func(w: World, p: PlayerState, c): return w.pickpocket(w.npc(c.n)),
		func(a, b, _m): return b.coins != a.coins or b.crimes.size() > a.crimes.size())
	# C7: through the adit, below
	parity("C7 go below", func(w: World, p: PlayerState):
			for por in w.underground.portals:
				if int(por.ends[1].level) == -1 and int(por.ends[0].level) == 0:
					p.pos = Vector2(por.ends[0].stand) + Vector2(0.5, 0.5)
					return {"dir": Vector2(por.ends[1].stand - por.ends[0].stand)}
			return {"skip": "no adit"},
		func(w: World, p: PlayerState, c): return w.player_through(c.dir),
		func(a, b, _m): return b.level == -1 and a.level == 0)


# ------------------------------------------------------------------ the G2 matrix --------------------
## Two players and one villager: each talks with them; the villager's ties to each are their own; a gift from one raises only theirs.
func test_one_villager_two_players() -> void:
	var w := _world()
	var host := w.player
	var g := _guest(w)
	var n: NPC = _adults(w)[0]
	host.pos = n.pos + Vector2(1, 0)
	g.pos = n.pos + Vector2(-1, 0)
	w.relations.talked(n)
	w.as_actor(g, func(): w.relations.talked(n))
	g.inv.add("flower", 1)
	w.as_actor(g, func(): w.relations.give(w.acting_id(), n, "flower"))
	var th := w.relations.peek(-2, n.id)
	var tg := w.relations.peek(w.person_id(g), n.id)
	check(float(th.regard) > 0.0 and float(tg.regard) > float(th.regard), "one villager, two players: the guest's gift raised the guest's tie only (host %.1f, guest %.1f)" % [float(th.regard), float(tg.regard)])
	# the closeness each earns standing near is their own (Relations.player_tick per player, its own clock)
	var far: NPC = _adults(w)[3]
	host.pos = far.pos + Vector2(1, 0)
	g.pos = Vector2(5.5, 5.5)
	var before := float(w.relations.peek(-2, far.id).regard)
	var gbefore := float(w.relations.peek(w.person_id(g), far.id).regard)
	for i in 400:
		w.relations.player_tick(1.0)
		w.as_actor(g, func(): w.relations.player_tick(1.0))
	check(float(w.relations.peek(-2, far.id).regard) > before and float(w.relations.peek(w.person_id(g), far.id).regard) == gbefore,
		"the time the host spends near a villager builds the host's tie, not the guest's (who is elsewhere)")
	# MP-D7: a newcomer comes with no standing at all
	var g2 := _guest(w, "Nell", "cd")
	var any := false
	for o: NPC in w.npcs:
		var t: Dictionary = w.relations.peek(w.person_id(g2), o.id)
		any = any or float(t.regard) != 0.0 or float(t.attraction) != 0.0
	check(not any and w.relations.notoriety(g2) == 0, "a newcomer (MP-D7) has no tie and no notoriety: the village's opinion from nothing")
	w.dispose()


## A crime by the guest: on its own record, case, judgment ledgers and notoriety; the host stays innocent in every one of them.
func test_crime_one_innocent_other() -> void:
	var w := _world()
	var host := w.player
	var g := _guest(w)
	var ad := _adults(w)
	var v: NPC = ad[1]
	var wit: NPC = ad[2]
	g.pos = v.pos + Vector2(0.6, 0)
	wit.pos = v.pos + Vector2(-1.5, 0)
	wit.plan.clear()
	wit.anim = "idle"
	host.pos = v.pos + Vector2(40, 0)
	g.hp = 9999.0
	g.max_hp = 9999.0
	var host_tie := float(w.relations.peek(-2, v.id).regard)
	w.player_hit_npc(v, 1.0, g)
	var ref := w.player_ref(g)
	check(not g.crimes.is_empty() and host.crimes.is_empty(), "the guest's assault is on the guest's record; the host's is clean")
	check(not w.justice.case_of(ref).is_empty() and w.justice.case_of("player").is_empty(), "the case is the guest's only")
	check(v.target == w.person_id(g) and w.brain.foe_player(v) == g, "the victim takes on the guest, by its own id")
	var bad_h := 0
	var bad_g := 0
	if w.judgment != null:
		for n: NPC in w.npcs:
			bad_h += w.judgment.bad(n.id, -2)
			bad_g += w.judgment.bad(n.id, w.person_id(g))
		check(bad_g > 0 and bad_h == 0, "the village's Bad ledger: the guest's (%d), none of it the host's" % bad_g)
	else:
		check(true, "judgment off: no ledgers to compare")
	check(float(w.relations.peek(w.person_id(g), v.id).regard) <= 0.0 and v.memory.any(func(m): return str(m).contains(g.name)) and float(w.relations.peek(-2, v.id).regard) == host_tie, "the victim remembers the guest and thinks no better of them; the host's tie is untouched (guest %.1f; the host's tie as it was, %.1f / %.1f)" % [float(w.relations.peek(w.person_id(g), v.id).regard), host_tie, float(w.relations.peek(-2, v.id).regard)])
	# a report on the guest reaches a guard and puts the guard on the guest, not the host
	var gd: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.job == "guard")[0]
	var rep: NPC = ad[3]
	w.report_crime(rep, w.person_id(g), "saw", "attack", ref, [0])
	check(int(rep.report.offender) == w.person_id(g) and str(rep.report.ref) == ref, "a villager's report names the guest by id and reference")
	gd.target = -1
	gd.pursuit = {}
	w.deliver_report(rep, gd)
	check(not w.justice.knows(gd, "player") and w.justice.knows(gd, ref), "the guard told knows of the guest's crime, nothing of the host")
	w.dispose()


## Separate quests and rewards: one quest giver's offer, taken by the guest, is the guest's; the host's list stays its own.
func test_quests_apart() -> void:
	var w := _world()
	var host := w.player
	var g := _guest(w)
	w.quests.refresh()
	var giver: NPC = null
	for n: NPC in w.npcs:
		if n.alive and not w.quests.offer_of(n).is_empty() and w.quests.can_fund(n, w.quests.offer_of(n)):
			giver = n
			break
	if giver == null:
		check(true, "no quest on offer in this world (nothing to separate)")
		w.dispose()
		return
	g.pos = giver.pos + Vector2(1, 0)
	var hq := host.quests.size()
	var gq := g.quests.size()
	var q := w.quests.accept(giver, "", g)
	check(not q.is_empty() and g.quests.size() == gq + 1 and host.quests.size() == hq, "the guest's quest is on the guest's list only")
	check(w.quests.offer_of(giver).is_empty(), "and the offer is taken: the host cannot take the same quest twice (no duplicate reward)")
	var c0 := w.total_coins()
	w.kill(giver, "old age")
	w.as_actor(g, w.quests.drop_failed)
	w.quests.drop_failed()
	check(g.quests.size() == gq and host.quests.size() == hq and w.total_coins() == c0,
		"its giver dies: the guest's quest is dropped from the guest's list (what was set aside goes back), the host's list untouched")
	w.dispose()


## A villager's ask (credit or barter) is put to one player and answered by that player only.
func test_asks_apart() -> void:
	var w := _world()
	var host := w.player
	var g := _guest(w)
	var b: NPC = _adults(w)[0]
	g.inv.add("bread", 4)
	g.pos = b.pos + Vector2(1, 0)
	b.coins = 0
	w.relations.tie(w.person_id(g), b.id).regard = 100.0       # the villager knows the guest well (trust is the guest's own tie)
	var asked: bool = w.as_actor(g, func(): return w.credit._ask_player(b, "bread", 1, 2))
	var rq: Array = w.as_actor(g, func(): return w.credit.request_for(b.id))
	check(asked and rq.size() == 1 and str(rq[0].to) == w.player_ref(g) and w.credit.request_for(b.id).is_empty(), "the ask is put to the guest; the host sees none")
	check(str(w.credit.answer_request(int(rq[0].id), true).result) == "failed", "the host cannot answer the guest's ask")
	var r: Dictionary = w.credit.answer_request(int(rq[0].id), false, g)
	check(str(r.result) == "refused" and not w.credit.refused.has(b.id) and (w.credit.refused_by.get(w.player_ref(g), {}) as Dictionary).has(b.id),
		"the guest turns it down: the refusal is the guest's own (the villager may still ask the host)")
	var d := w.to_dict()
	var w2 := _reload(d)
	check((w2.credit.refused_by.get(w.player_ref(g), {}) as Dictionary).has(b.id), "and is saved")
	w.dispose()
	w2.dispose()


## Two player families in one world: the host and the guest each court and partner a villager of their own; the guest's child is
## the guest's line's (its own id as a parent); the guest's death and its heir (the child) keep the guest's line, the host's untouched.
func test_families_and_succession() -> void:
	var w := _world()
	var host := w.player
	var g := _guest(w)
	host.sex = "male"
	g.sex = "female"
	var men := _adults(w).filter(func(n: NPC) -> bool: return n.sex == "male" and n.partner < 0)
	var women := _adults(w).filter(func(n: NPC) -> bool: return n.sex == "female" and n.partner < 0)
	if men.is_empty() or women.is_empty():
		check(false, "two unpartnered villagers to marry")
		w.dispose()
		return
	var hm: NPC = women[0]
	var gm: NPC = men[0]
	check(Life.partner_player(w, hm) == "", "the host partners a villager")
	var why: String = w.as_actor(g, func(): return Life.partner_player(w, gm))
	check(why == "" and g.partner == gm.id and gm.partner == w.person_id(g) and hm.partner == -2,
		"the guest partners another: two families, each link the player's own id (guest %d, host %d)" % [gm.partner, hm.partner])
	check(Life.has_partner(w, gm) and Life.has_partner(w, hm), "each villager's partner is recognized as alive and theirs")
	check(w.as_actor(g, func(): return Life.partner_refusal(w, hm)) != "", "a villager partnered with the host is not free for the guest")
	# the guest's child, by the established birth (Life.birth): the guest is the mother, by its own id
	var kid: NPC = Life.birth(w, g, gm, gm.household)
	check(kid.mother == w.person_id(g) and kid.father == gm.id and g.children.has(kid.id), "the guest's child records the guest as its mother (its own id)")
	kid.born = w.minutes - Life.year_days() * World.DAY * 20.0
	Life.sync_roles(w)
	var c0 := w.total_coins()
	var line := w.player_ref(g)
	var ties0 := w.relations.peek(w.person_id(g), gm.id).duplicate()
	w.relations.talked(gm)
	w.as_actor(g, func(): w.relations.talked(gm))
	var tg := float(w.relations.peek(w.person_id(g), gm.id).regard)
	g.alive = false
	g.hp = 0.0
	g.death_cause = "a test"
	var gid := w.person_id(g)
	w.continue_as_heir(g)
	var h: PlayerState = null
	for q: PlayerState in w.player_list():
		if not w.is_host(q) and q.alive:
			h = q
	check(h != null and h.pid == kid.id and h.line == g.pid and w.player_ref(h) == line and w.person_id(h) == gid,
		"the guest's heir is its own child, of the same line (its reference %s and person id %d kept)" % [line, gid])
	check(float(w.relations.peek(gid, gm.id).regard) == tg, "the village's view of the guest's family goes on with the heir (the line's ties)")
	check(gm.partner == g.pid and not Life.is_player_id(gm.partner), "the dead guest's partner's link now names the dead guest as a person (its own id), not the heir")
	check(hm.partner == -2 and host.partner == hm.id and host.alive, "the host's family is untouched")
	check(w.total_coins() == c0 + h.coins - int(GameData.b("start_coins_player")) * 0 and w.coin_sources >= 0, "coins: only the heir's starting purse is new (coin_sources)")
	var ids := {}
	var dup := false
	for q: PlayerState in w.player_list():
		dup = dup or ids.has(w.person_id(q))
		ids[w.person_id(q)] = true
	check(not dup, "no two player characters share a person id (no ownership or inheritance collision)")
	w.dispose()


## A shared transaction without duplication: the guest buys a villager's last loaf; the coins go guest -> villager once, the loaf
## villager -> guest once; the host's purse and pack unchanged; the census the same.
func test_shared_transaction() -> void:
	var w := _world()
	var host := w.player
	var g := _guest(w)
	var n: NPC = null
	var item := ""
	for o: NPC in _adults(w):
		for id in o.inv.ids():
			if not w.brain.keeps(o, id) and GameData.value(id) > 0:
				n = o
				item = id
				break
		if n != null:
			break
	if n == null:
		check(false, "a villager with something to sell")
		w.dispose()
		return
	g.coins = 300
	g.pos = n.pos + Vector2(1, 0)
	var c0 := _census(w)
	var hc := host.coins
	var have := n.inv.count(item)
	var r := w.player_buy_many(n, item, 1, g)
	var c1 := _census(w)
	check(str(r.result) == "bought" and n.inv.count(item) == have - 1 and g.inv.count(item) >= 1, "the guest bought one %s from %s" % [item, n.name])
	check(c0.coins == c1.coins and JSON.stringify(c0.goods) == JSON.stringify(c1.goods) and host.coins == hc, "no coin or good made or lost; the host's purse untouched")
	check(w.relations.traded_with(w.person_id(g), n.id) and not w.relations.traded_with(-2, n.id), "the trade is the guest's own contact (X18-Q12-POST)")
	w.dispose()


## Two players reach for one ripe plant: applied in order, the first gets it, the second finds it taken; the plant's goods exist once.
func test_limited_resource() -> void:
	var w := _world()
	var host := w.player
	var g := _guest(w)
	var pl := {}
	for p in w.plants:
		if str(p.state) == "ripe" and not p.get("ow", false):
			pl = p
			break
	var c := Vector2i(int(pl.x), int(pl.y))
	host.pos = _beside(w, c)
	g.pos = _beside(w, c)
	var g0 := _goods(w)
	var a := w.player_pick_plant(pl, g)
	var b := w.player_pick_plant(pl, host)
	var made := _made(g0, _goods(w))
	check(not a.is_empty() and b.is_empty(), "the guest's reach came first and took the plant; the host's found it picked")
	var once := true
	for k in a:
		once = once and int(made.get(k, 0)) == int(a[k])
	check(once, "its goods exist once (%s)" % str(made))
	# the same through the network entry: two requests in one frame are applied in arrival order
	var pl2 := {}
	for p in w.plants:
		if str(p.state) == "ripe" and not p.get("ow", false) and p != pl:
			pl2 = p
			break
	var c2 := Vector2i(int(pl2.x), int(pl2.y))
	g.pos = _beside(w, c2)
	var g2 := _guest(w, "Nell", "cd")
	g2.pos = _beside(w, c2)
	var r1 := NetActions.apply_verb(w, g2, "player_pick_plant", [NetActions.enc(w, pl2)])
	var r2 := NetActions.apply_verb(w, g, "player_pick_plant", [NetActions.enc(w, pl2)])
	check(r1.ok and not (r1.result as Dictionary).is_empty() and (r2.result as Dictionary).is_empty(), "two guests' requests for one plant: the first applied gets it, the second nothing")
	w.dispose()


## MP-D2: the clock runs quickly only when every living player in play rests; one resting alone rests in real time.
func test_rest_by_agreement() -> void:
	var w := _world()
	w.minutes = floorf(w.minutes / World.DAY) * World.DAY + 21.0 * 60.0       # the evening
	var host := w.player
	var g := _guest(w)
	host.hp = 5.0
	g.hp = 5.0
	var m0 := w.minutes
	var r: Dictionary = w.player_rest(g)
	check(bool(r.waiting) and w.minutes == m0 and g.rest_until > m0, "the guest rests while the host is awake: nothing jumps (real time)")
	for i in 20:
		w.update(0.5)
	check(w.minutes < m0 + 60.0 and g.rest_until > w.minutes, "the world goes on at its own pace (%.0f minutes)" % (w.minutes - m0))
	var r2: Dictionary = w.player_rest()
	check(w.minutes > m0 + 300.0 and float(r2.minutes) > 300.0, "the host rests too: everyone rests, the night passes quickly (%.0f minutes)" % (w.minutes - m0))
	check(host.hp == host.hp_cap() and g.hp == g.hp_cap() and host.rest_until < 0.0 and g.rest_until < 0.0, "both woke rested at the morning")
	# moving or a blow wakes one resting in real time
	w.player_rest(g)
	check(g.rest_until >= 0.0 and w.player_wake(g) and g.rest_until < 0.0, "a player resting in real time gets up by acting")
	w.player_rest(g)
	w.damage_player(1.0, "a test", g)
	check(g.rest_until < 0.0, "a blow wakes them")
	# one player in play: Build 19's rest
	var w1 := _world()
	w1.minutes = floorf(w1.minutes / World.DAY) * World.DAY + 21.0 * 60.0
	var n0 := w1.minutes
	var r3: Dictionary = w1.player_rest()
	check(not r3.has("waiting") and w1.minutes > n0 + 300.0, "single player: the rest of Build 19, unchanged")
	w1.dispose()
	w.dispose()


## Two players hold two places of a station apart; one finishing frees only its own.
func test_stations_apart() -> void:
	var w := _world()
	var g := _guest(w)
	var id := ""
	for k in w.stations:
		if int(w.stations[k].get("capacity", 1)) == 1:
			id = k
			break
	w.reserve_for_player(id, 30.0)
	check(w.player_at_station(id) and not w.player_at_station(id, g), "the host holds the station; the guest does not")
	check(w.as_actor(g, func(): return w.station_refusal(id)) != "" or w.stations[id].get("building", "") != "", "the guest is told someone else is using a one-place station")
	w.release_player_station(id, g)
	check(w.player_at_station(id), "the guest finishing frees nothing of the host's")
	check(w.players_at(w.stations[id]) == 1, "villagers count one player there")
	w.dispose()


## MP-D8: between two players nothing is done until both agree: a partnership and a gift, offered, then accepted or declined.
func test_consent_between_players() -> void:
	var w := _world()
	var host := w.player
	var g := _guest(w)
	host.born = w.minutes - Life.year_days() * World.DAY * 25.0
	g.born = host.born
	g.pos = host.pos + Vector2(1, 0)
	var c0 := _census(w)
	check(w.player_offer("partner", g.pid) == "" and host.partner == -1 and g.partner == -1, "the host asks the guest to be partners: nothing is done yet")
	check(w.offers_to(g).size() == 1 and w.offers_to(host).is_empty(), "the offer waits for the guest's answer")
	check(w.player_answer(int(w.offers_to(g)[0].id), true, host) == "There is no such offer.", "the one who asked cannot answer for the other")
	check(w.player_answer(int(w.offers_to(g)[0].id), true, g) == "", "the guest accepts")
	check(host.partner == w.person_id(g) and g.partner == -2, "both are partners, each by the other's own id")
	check(w.player_offer("partner", g.pid) != "", "a partnered player cannot be asked again")
	# a gift, with its stolen mark, declined then accepted
	g.inv.add("apple", 2)
	var v: NPC = _adults(w)[0]
	g.mark_stolen("apple", v.id, 1)
	check(w.player_offer("gift", host.pid, "apple", 2, g) == "" and g.inv.count("apple") == 2 and not host.inv.has("apple"), "the guest offers two apples: they stay in its pack until taken")
	w.player_answer(int(w.offers_to(host)[0].id), false)
	check(w.offers_to(host).is_empty() and g.inv.count("apple") == 2, "declined: nothing moves")
	w.player_offer("gift", host.pid, "apple", 2, g)
	check(w.player_answer(int(w.offers_to(host)[0].id), true) == "" and host.inv.count("apple") == 2 and not g.inv.has("apple"), "accepted: the apples move once")
	check(host.stolen.get("apple", {}).get(str(v.id), 0) == 1 and not g.stolen.has("apple"), "and the stolen mark goes with them")
	var c1 := _census(w)
	check(c0.coins == c1.coins and int(c1.goods.get("apple", 0)) - int(c0.goods.get("apple", 0)) == 2, "nothing made but the test's two apples")
	g.pos = host.pos + Vector2(20, 0)
	check(w.player_offer("gift", g.pid, "apple", 1) != "", "a player not beside you cannot be offered anything")
	g.pos = host.pos + Vector2(1, 0)
	w.player_offer("gift", g.pid, "apple", 1)
	w.minutes += World.DAY
	w._new_day()
	check(w.offers.is_empty(), "an offer lapses with its day")
	var d := w.to_dict()
	w.player_offer("gift", g.pid, "apple", 1)
	var w2 := _reload(w.to_dict())
	check(w2.offers.size() == 1 and int(w2.offers[0].qty) == 1 and w2.player_by_pid(g.pid).partner == -2, "an open offer and the partnership are saved (save 22)")
	# the guest dies: the host's partner link names the dead guest, not its heir
	g.alive = false
	w.continue_as_heir(g)
	check(host.partner == g.pid, "after the guest's death the host's partner link names the dead guest as a person (%d)" % host.partner)
	w.dispose()
	w2.dispose()


## Animals and bandits choose among the players by the same rules: a beast struck by the guest fights the guest; a bandit stalks the
## player near it.
func test_animals_and_bandits() -> void:
	var w := _world()
	var host := w.player
	var g := _guest(w)
	var beast: Animal = null
	for a: Animal in w.fauna.animals:
		if a.alive and bool(a.spec().get("people", false)):
			beast = a
			break
	if beast != null:
		g.pos = beast.pos + Vector2(0.8, 0)
		w.player_hit_animal(beast, 0.5, g)
		check(beast.anger == w.player_ref(g), "a beast struck by the guest is angry with the guest (%s)" % beast.anger)
		var hg := g.hp
		var hh := host.hp
		beast.bite_cd = 0.0
		w.fauna._bite(beast, g.pos)
		check(g.hp < hg and host.hp == hh, "its bite hurts the guest, not the host")
	else:
		check(true, "no wolf or bear in this world")
	var b: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "bandit":
			b = n
			break
	if b != null:
		host.pos = b.pos + Vector2(40, 0)
		g.pos = b.pos + Vector2(3, 0)
		var prey = w.brain._prey_for(b)
		check(prey == g, "a bandit stalks the player within reach: the guest, the host being far")
	w.dispose()


# ------------------------------------------------------------------ saves -------------------------
func _reload(d: Dictionary) -> World:
	var w := World.new()
	w.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d, "", true, true)))
	return w


func test_save22() -> void:
	var w := _world()
	var g := _guest(w)
	var n: NPC = _adults(w)[0]
	g.pos = n.pos + Vector2(1, 0)
	w.as_actor(g, func(): w.relations.talked(n))
	n.partner = w.person_id(g)
	g.partner = n.id
	var d := w.to_dict()
	check(int(d.save_version) == 22 and str(d.format) == "mml-save/22", "the save is version 22")
	var w2 := _reload(d)
	var g2 := w2.player_by_pid(g.pid)
	check(g2 != null and w2.person_id(g2) == w.person_id(g) and Contracts.ref_of(g2) == w.player_ref(g), "the guest comes back with its id and reference")
	check(float(w2.relations.peek(w2.person_id(g2), n.id).regard) == float(w.relations.peek(w.person_id(g), n.id).regard) and w2.npc(n.id).partner == w.person_id(g),
		"its ties and its partner's link under its own id")
	check(JSON.stringify(w2.to_dict(), "", true) == JSON.stringify(_reload(w2.to_dict()).to_dict(), "", true), "a second round trip changes nothing")
	w.dispose()
	w2.dispose()


## Every tie of a saved section is in world `w` with the same regard, attraction and stage.
func _ties_kept(saved: Dictionary, w: World) -> bool:
	for k in saved:
		var parts := str(k).split(":")
		var t: Dictionary = w.relations.peek(int(parts[0]), int(parts[1]))
		if absf(float(t.regard) - float(saved[k].get("regard", 0.0))) > 0.0001 or absf(float(t.attraction) - float(saved[k].get("attraction", 0.0))) > 0.0001 \
				or str(t.stage) != str(saved[k].get("stage", "")):
			print("     tie %s: %s / %s" % [k, JSON.stringify(t), JSON.stringify(saved[k])])
			return false
	return true


func _fixture(name: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/" + name))


## The Build 20 save (save 21, written by 56c24cb's own save path): read with everything kept, the single player its host by its
## permanent pid (and -2 in person-id records, ID-D1), the migration idempotent, nothing dropped.
func test_build20_migration() -> void:
	var d := _fixture("b20_save_v21_single.json")
	check(int(d.save_version) == 21, "the Build 20 fixture is a save 21")
	var m1 := World.migrate_21_to_22(d)
	var m2 := World.migrate_21_to_22(m1)
	m1.erase("_migrated_21")
	m2.erase("_migrated_21")
	check(JSON.stringify(m1, "", true) == JSON.stringify(m2, "", true), "the migration is idempotent: a migrated save migrated again is the same")
	var w := _reload(d)
	check(w.load_error == "" and w.player.pid == int(d.player.pid) and w.players.size() == 1 and w.person_id(w.player) == -2,
		"it loads: the single player is the host, by its permanent pid %d (person id -2)" % w.player.pid)
	var out := w.to_dict()
	var lost := []
	for k in d:
		if not out.has(k) and k != "meta":            # "meta" is Main's (the save's name and play time), written by Main.save_game
			lost.append(k)
	check(lost.is_empty(), "no section of the save is dropped%s" % ("" if lost.is_empty() else ": " + str(lost)))
	var pin := PlayerState.from_dict(d.player)
	check(int(out.player.partner) == int(d.player.partner) and int(out.player.coins) == int(d.player.coins) and w.player.crimes.size() == (d.player.crimes as Array).size()
		and JSON.stringify(w.player.inv.items) == JSON.stringify(pin.inv.items), "the player's purse, pack, crimes and partner are as saved")
	check(_ties_kept(d.relations.ties, w), "every tie is as saved (the player's under -2)")
	var npc_same := true
	for i in (d.npcs as Array).size():
		npc_same = npc_same and int(out.npcs[i].id) == int(d.npcs[i].id) and int(out.npcs[i].coins) == int(d.npcs[i].coins) and int(out.npcs[i].partner) == int(d.npcs[i].partner)
	check(npc_same and (out.npcs as Array).size() == (d.npcs as Array).size(), "every villager as saved (ids, purses, partners)")
	var once := _reload(out).to_dict()
	check(JSON.stringify(once, "", true) == JSON.stringify(_reload(once).to_dict(), "", true), "loading the migrated save again gives the same save (deterministic, idempotent)")
	var mt := SaveTransfer.migrate(d, VillageMap.load_default())
	check(mt.ok and int(mt.data.save_version) == World.SAVE_VERSION and not mt.data.has("_migrated_21"), "an imported Build 20 save migrates to 22 through SaveTransfer (%s)" % mt.get("reason", ""))
	var census_a := w.total_coins()
	var census_b := _reload(out).total_coins()
	check(census_a == census_b, "the coin census is the same before and after (%d)" % census_a)
	w.dispose()


## A save 21 with a guest (Batch B code, 805a1c9): the guest's records stay its own; what save 21 kept under -2 stays the host's line's;
## the guest's facts are still told apart by their tag.
func test_save21_guest_migration() -> void:
	var d := _fixture("mp_save_v21_guest.json")
	var gk := ""
	for k in d.players.by_pid:
		if int(k) != int(d.players.host):
			gk = k
	var gd: Dictionary = d.players.by_pid[gk]
	var w := _reload(d)
	var g := w.player_by_pid(int(gk))
	check(g != null and g.away and w.person_id(g) == -int(gk) and w.player_ref(g) == "player:" + gk, "the guest is back (away, MP-D1), by its id -%s" % gk)
	check(g.coins == int(gd.coins) and JSON.stringify(g.inv.items) == JSON.stringify(PlayerState.from_dict(gd).inv.items) and g.crimes.size() == (gd.crimes as Array).size(),
		"its purse, pack and crimes as saved")
	check(not w.justice.case_of("player:" + gk).is_empty() and w.relations.killings_of("player:" + gk) == int(d.relations.guest_killings["player:" + gk]),
		"its case and its killings as saved")
	var tagged := 0
	if w.judgment != null:
		for ev in w.judgment.facts:
			var f: Dictionary = w.judgment.fact(int(ev))
			if (f.tags as Array).has("by:player:" + gk):
				tagged += 1
				check(EventTalk.person_of_id(w, int(f.actors[0][0]), EventTalk._tags(f.tags)) == g, "a fact the guest did (save 21: -2, tagged) still names the guest in talk")
	check(tagged > 0 or w.judgment == null, "the guest's tagged facts are kept (%d)" % tagged)
	check(_ties_kept(d.relations.ties, w), "the ties under -2 are kept as they were (the host's line's)")
	var mine := 0
	for o: NPC in w.npcs:
		if float(w.relations.peek(w.person_id(g), o.id).regard) != 0.0:
			mine += 1
	check(mine == 0, "the guest starts its own ties from this load (none were its own in save 21)")
	var a := w.to_dict()
	var lost := []
	for k in d:
		if not a.has(k):
			lost.append(k)
	check(lost.is_empty(), "no section dropped%s" % ("" if lost.is_empty() else ": " + str(lost)))
	var a2 := _reload(a).to_dict()
	check(JSON.stringify(a, "", true) == JSON.stringify(a2, "", true), "the migrated save round trips unchanged%s" % ("" if JSON.stringify(a, "", true) == JSON.stringify(a2, "", true) else " " + _diff(a, a2).left(600)))
	w.dispose()
