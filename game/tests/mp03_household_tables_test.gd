extends SceneTree
## B25-MP03-OWNERSHIP-D1 (owner, 2026-11-10; docs/directives/2026-11-10_household_food_property_permissions.md), on top of
## B25-AUD-MP-03 and B25-MP03-TABLES-D1 (mp03_forged_store_test, mp03_public_tables_test):
##   B  the tavern's tables stay private: what is on them is the business's stock (taking it is theft, player_take);
##   C  a guest uses the tables and containers it owns or is authorized to use, by the same property rule as the host
##      (Chests.info for a container, Furniture.home_refusal for a home's food table), and nobody else does;
##   D  after the tavern keepers die the tables stay private: nothing on them becomes free.
## Every answer is the host's (NetActions._dec_inv in the host's World, the guest's position as the host has it); a refusal moves
## nothing; the answers are the same after a save and load and on two identical worlds.
## Run: godot --headless --path game --script res://tests/mp03_household_tables_test.gd
var checks := 0
var failures := 0
func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		failures += 1


func mk_player(w: World, nm: String, key: String) -> PlayerState:
	var p := PlayerState.new()
	p.name = nm
	p.family = "Forge"
	p.sex = "female"
	p.born = w.player.born
	Identity.register_player(w, p)
	w.give_start_kit(p)
	p.net_key = key.repeat(32)
	w.add_guest(p)
	p.pos = w.player.pos
	return p


func req(w: World, g: PlayerState, path: String, raw: Array) -> Dictionary:
	return NetActions.apply_verb(w, g, path, raw)


## The decoder's answer for player `p` naming store `d`: "ok" or the refusal.
func ans(w: World, p: PlayerState, d: Dictionary) -> String:
	var bad := {"why": ""}
	var inv = NetActions._dec_inv(w, p, d, bad)
	return "ok" if inv != null and str(bad.why) == "" else str(bad.why)


## A household's house with a food table spot and a crate or barrel of its own, the one whose crate is nearest a parcel; "" if none.
func house_with_table_and_crate(w: World, skip := "") -> String:
	var ids: Array = w.buildings.keys()
	ids.sort()
	var best := ""
	var bd := INF
	for id in ids:
		if str(id) == skip or str(w.buildings[id].get("type", "")) != "house":
			continue
		var has_table := false
		for s in w.interiors.get(id, {}).get("spots", []):
			if s.kind == "table":
				has_table = true
		var has_crate := false
		for c in w.containers:
			if str(c.at) == str(id) and c.kind != "table":
				has_crate = true
		if has_table and has_crate:
			var c := crate_in(w, str(id))
			for pl in w.plots:
				var d := Vector2(int(c.x), int(c.y)).distance_to(Vector2(int(pl.x), int(pl.y)))
				if d < bd:
					bd = d
					best = str(id)
	return best


func crate_in(w: World, bid: String) -> Dictionary:
	for c in w.containers:
		if str(c.at) == bid and c.kind != "table":
			return c
	return {}


func table_station(w: World, bid: String) -> String:
	for s in w.interiors.get(bid, {}).get("spots", []):
		if s.kind == "table":
			return Furniture.station_id(bid, s)
	return ""


## The world every part of the test (and its save/load and determinism copies) starts from: Gwen holds a house (its crate's goods
## are her stash), Mara lives there with her (as Life moves a partner in), Hal is another player, and a villager household keeps
## another house.
func build(seed: int) -> Dictionary:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	var gwen := mk_player(w, "Gwen", "f")
	var hal := mk_player(w, "Hal", "e")
	var mara := mk_player(w, "Mara", "d")
	var bid := house_with_table_and_crate(w)
	var vid := house_with_table_and_crate(w, bid)
	var out := {"w": w, "gwen": gwen, "hal": hal, "mara": mara, "bid": bid, "vid": vid}
	if bid == "" or vid == "":
		return out
	var b: Dictionary = w.buildings[bid]
	b.erase("tenant")
	w.set_owner(b, w.player_ref(gwen))
	gwen.home = bid
	mara.home = bid
	var crate := crate_in(w, bid)
	var here := Vector2(int(crate.x), int(crate.y)) + Vector2(0.5, 0.5)
	for q: PlayerState in [gwen, hal, mara, w.player]:
		q.pos = here
	out.crate = crate
	out.vcrate = crate_in(w, vid)
	out.here = here
	w.chests.info(w.chests.unit_of_container(crate)).store.add("plank", 5)       # the host acting: Gwen's stash (by unit id)
	return out


## The property answers this test reads, in a fixed order, as one list (for the save/load and determinism comparisons).
func answers(s: Dictionary) -> Array:
	var w: World = s.w
	var out := []
	var tav := []
	for c in w.containers:
		if c.kind == "table" and w._is_tavern(str(c.at)):
			tav.append(str(c.id))
	for who in ["gwen", "hal", "mara"]:
		var p: PlayerState = s[who]
		out.append([who, "crate", ans(w, p, {"$inv": "container", "id": str(s.crate.id)})])
		out.append([who, "vcrate", ans(w, p, {"$inv": "container", "id": str(s.vcrate.id)})])
		out.append([who, "home table", w.as_actor(p, func(): return Furniture.home_refusal(w, table_station(w, s.bid)))])
		out.append([who, "villager table", w.as_actor(p, func(): return Furniture.home_refusal(w, table_station(w, s.vid)))])
		for t in tav:
			out.append([who, t, ans(w, p, {"$inv": "container", "id": t})])
	return out


func stores_of(s: Dictionary) -> Array:
	var w: World = s.w
	var out := [w.chests.info(w.chests.unit_of_container(s.crate)).store, w.container_store(s.vcrate), w.granary]
	for c in w.containers:
		if c.kind == "table":
			out.append(c.inv)
	for q: PlayerState in w.player_list():
		out.append(q.inv)
		out.append(q.chest)
	for h in w.households:
		out.append(h.pantry)
	return out


func snapshot(s: Dictionary) -> String:
	var parts := []
	for inv in stores_of(s):
		parts.append(JSON.stringify(inv.to_dict()) if inv is Inventory else "-")
	for q: PlayerState in s.w.player_list():
		parts.append(str(q.coins))
	for n: NPC in s.w.npcs:
		parts.append(str(n.coins))
	return "|".join(parts)


func _init() -> void:
	GameData.ensure()
	var s := build(3303)
	var w: World = s.w
	check(s.bid != "" and s.vid != "", "setup: two houses with a food table and a crate (%s, %s)" % [s.bid, s.vid])
	if s.bid == "" or s.vid == "":
		quit(1)
		return
	var gwen: PlayerState = s.gwen
	var hal: PlayerState = s.hal
	var mara: PlayerState = s.mara
	var gref := w.player_ref(gwen)
	var cid := str(s.crate.id)
	var own := {"$inv": "container", "id": cid}
	var gstash: Inventory = w.as_actor(gwen, func(): return w.chests.info(w.chests.unit_of_container(s.crate)).store)

	# C: the property rule itself, as the host's single-player paths read it (Chests.info, Furniture.home_refusal).
	var acc := func(p: PlayerState, c: Dictionary) -> String:
		return str(w.as_actor(p, func(): return w.chests.info(w.chests.unit_of_container(c)).access))
	check(acc.call(gwen, s.crate) == "own", "rule: Gwen's house crate is her own")
	check(acc.call(hal, s.crate) == "foreign" and acc.call(w.player, s.crate) == "foreign", "rule: to Hal and to the host it is another player's")
	check(acc.call(mara, s.crate) == "foreign", "rule: to Mara, living there without a sharing agreement, it is not hers")
	check(acc.call(gwen, s.vcrate) == "foreign", "rule: a villager household's crate is not Gwen's")

	# C: Gwen names her own crate within reach (the store the property rule gives her: her stash); one plank to her own site.
	var plot: Dictionary = {}
	var best := INF
	for pl in w.plots:
		var d := (Vector2(int(pl.x), int(pl.y))).distance_to(s.here)
		if pl.get("site", {}).is_empty() and d < best:
			best = d
			plot = pl
	check(not plot.is_empty(), "setup: a parcel near the house for Gwen's site")
	w.start_site(plot, "house", gref)
	var mid: Vector2 = (s.here + (NetActions._pos_of(plot) as Vector2)) * 0.5        # within reach of both the crate and the site
	check(mid.distance_to(s.here) < NetActions.VERB_REACH - 1.0, "setup: a place in reach of the crate and the site")
	for q: PlayerState in [gwen, hal, mara]:
		q.pos = mid
	var need: int = int(plot.site.need.get("plank", 0))
	check(need >= 2, "setup: the site needs planks")
	gstash.remove("plank", gstash.count("plank"))
	gstash.add("plank", 1)
	var before := gstash.count("plank")
	var r := req(w, gwen, "deliver", [NetActions.enc(w, plot), own, gref])
	check(bool(r.ok) and gstash.count("plank") == before - 1 and int(plot.site.need.get("plank", 0)) == need - 1,
		"Gwen delivers from her own house crate (her stash): %s" % str(r.text))
	check(ans(w, gwen, own) == "ok", "the decoder gives Gwen her own crate")

	# Unauthorized: Hal, Mara (no agreement), a villager's crate; reach; impersonation. Nothing moves on any refusal.
	gstash.add("plank", 3)
	for who in [hal, mara]:
		var snap := snapshot(s)
		var rr := req(w, who, "deliver", [NetActions.enc(w, plot), own, w.player_ref(who)])
		check(not bool(rr.ok) and snapshot(s) == snap, "%s naming Gwen's crate: refused (%s), nothing moves" % [who.name, str(rr.text)])
	var snap2 := snapshot(s)
	var rv := req(w, gwen, "deliver", [NetActions.enc(w, plot), {"$inv": "container", "id": str(s.vcrate.id)}, gref])
	check(not bool(rv.ok) and snapshot(s) == snap2, "Gwen naming a villager household's crate: refused, nothing moves")
	var ri := req(w, hal, "deliver", [NetActions.enc(w, plot), own, gref])
	check(not bool(ri.ok) and str(ri.text) == "That is not yours." and snapshot(s) == snap2, "Hal claiming to be Gwen: refused")
	gwen.pos = s.here + Vector2(NetActions.VERB_REACH + 4.0, 0)
	check(gwen.pos.distance_to(s.here) > NetActions.VERB_REACH, "setup: Gwen out of reach of her crate")
	check(ans(w, gwen, own) == "That is too far away.", "Gwen's own crate out of reach (her position as the host has it): refused")
	var rf := req(w, gwen, "deliver", [NetActions.enc(w, plot), own, gref, s.here])
	check(not bool(rf.ok) and snapshot(s) == snap2, "a position written into the request does not move her: refused")
	gwen.pos = mid

	# Household permission: Mara with Gwen's sharing agreement (MP-INTERACT-01 tier 1) uses it as shared, like chests.take.
	check(w.player_offer("asset_share", mara.pid, "", 1, gwen) == "", "Gwen offers Mara tier 1")
	req(w, mara, "player_answer", [int(w.offers.back().id), true])
	check(acc.call(mara, s.crate) == "shared" and ans(w, mara, own) == "ok", "with the agreement Mara may use Gwen's crate")
	check(ans(w, hal, own) == "That is not yours.", "Hal still may not")

	# C: the home's food table (Furniture.home_refusal): Gwen's own, Mara's home, not Hal's; the villager's house refuses all three.
	var sid := table_station(w, s.bid)
	var vsid := table_station(w, s.vid)
	var hr := func(p: PlayerState, id: String) -> String:
		return str(w.as_actor(p, func(): return Furniture.home_refusal(w, id)))
	check(hr.call(gwen, sid) == "" and hr.call(mara, sid) == "", "Gwen and Mara may use the food table of their home")
	check(hr.call(hal, sid) != "" and hr.call(w.player, sid) != "", "Hal and the host may not (the host has no ownership by hosting)")
	check(hr.call(gwen, vsid) != "" and hr.call(w.player, vsid) != "", "a villager's food table: refused to guest and host alike")
	var recipe: String = GameData.recipes_at("prep")[0] if not GameData.recipes_at("prep").is_empty() else ""
	check(recipe != "", "setup: a prep recipe")
	var cg := req(w, gwen, "player_craft_begin", [recipe, sid])
	var ch := req(w, hal, "player_craft_begin", [recipe, sid])
	check(not str(cg.get("result", {}).get("why", "")).begins_with("This is not your house"), "Gwen at her own food table: no refusal for leave")
	check(str(ch.get("result", {}).get("why", "")).begins_with("This is not your house"), "Hal at Gwen's food table: refused for leave")

	# Parity: the same case decided the same way for host and guest under the property rule.
	check(acc.call(w.player, s.crate) == acc.call(hal, s.crate) and hr.call(w.player, sid) == hr.call(hal, sid),
		"parity: the host and Hal, neither holding the house, get the same property answers")

	# B: the tavern's tables are the business's: refused to every guest, the dish still taken only as theft.
	for c in w.containers:
		if c.kind == "table":
			check(ans(w, gwen, {"$inv": "container", "id": str(c.id)}) == "That is not yours.", "tavern table %s: private to Gwen" % str(c.id))

	# D: both keepers die. Succession opens the post; the tables stay private and their dishes stay where they are.
	var tab: Dictionary = {}
	for c in w.containers:
		if c.kind == "table":
			tab = c
			break
	var k0 := w.tavern_keeper()
	tab.inv.add("pottage", 1)
	tab.keeper = k0.id
	for n: NPC in w.npcs.duplicate():
		if n.alive and n.job == "tavernkeeper":
			w.kill(n, "illness")
	check(w.tavern_keeper() == null, "setup: no tavern keeper lives")
	var vac := false
	for v in w.vacancies:
		if str(v.job) == "tavernkeeper":
			vac = true
	check(vac, "succession: the tavern keeper's post is open (World.vacancies)")
	gwen.pos = Vector2(int(tab.x), int(tab.y)) + Vector2(0.5, 0.5)
	var snap3 := snapshot(s)
	for c in w.containers:
		if c.kind == "table":
			check(not NetActions.public_table(w, c) and ans(w, gwen, {"$inv": "container", "id": str(c.id)}) == "That is not yours.",
				"after the keepers' deaths tavern table %s is still private" % str(c.id))
	req(w, gwen, "deliver", [NetActions.enc(w, plot), {"$inv": "container", "id": str(tab.id)}, gref])
	check(snapshot(s) == snap3 and tab.inv.count("pottage") >= 1, "nothing on the tables became free: nothing moved")
	gwen.pos = mid

	# Single player unchanged: the host names its own pack and chest, and the host's decoder path is as it was.
	var bad := {"why": ""}
	check(NetActions._dec_inv(w, w.player, {"$inv": "pack"}, bad) == w.player.inv and NetActions._dec_inv(w, w.player, {"$inv": "chest"}, bad) == w.player.chest,
		"host: its own pack and chest")

	# Save and load: the same answers.
	var a1 := answers(s)
	var dd: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), dd)
	var s2 := s.duplicate()
	s2.w = w2
	s2.gwen = w2.player_by_pid(gwen.pid)
	s2.hal = w2.player_by_pid(hal.pid)
	s2.mara = w2.player_by_pid(mara.pid)
	s2.crate = w2.container(cid)
	s2.vcrate = w2.container(str(s.vcrate.id))
	check(s2.gwen != null and s2.hal != null and s2.mara != null, "loaded: the three guests")
	if s2.gwen != null and s2.hal != null and s2.mara != null:
		var a2 := answers(s2)
		check(JSON.stringify(a2) == JSON.stringify(a1), "loaded: the same property answers (%d)" % a1.size())
		check(ans(w2, s2.gwen, own) == "ok" and ans(w2, s2.mara, own) == "ok" and ans(w2, s2.hal, own) == "That is not yours.",
			"loaded: Gwen's crate is hers, Mara's by agreement, not Hal's")

	# Determinism: two identical worlds answer the same.
	var sa := build(3303)
	var sb := build(3303)
	check(JSON.stringify(answers(sa)) == JSON.stringify(answers(sb)), "two identical worlds give the same answers")
	check(answers(sa).filter(func(x): return x[0] == "gwen" and x[1] == "crate")[0][2] == "ok", "and Gwen's own crate is hers in each")
	for x in [sa, sb]:
		x.w.dispose()
	w2.dispose()
	w.dispose()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
