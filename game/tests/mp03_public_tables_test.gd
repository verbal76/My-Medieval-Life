extends SceneTree
## B25-MP03-TABLES-D1 (owner, 2026-11-10): "Multiplayer guests may interact with genuinely public tables when the tables are
## accessible and within the permitted interaction range." On top of B25-AUD-MP-03 (mp03_forged_store_test): a guest may name a
## genuinely public table (NetActions.public_table: a table no building, stall, parcel, claim or live keeper holds) within
## VERB_REACH as a store; every other table (the tavern's, whose dish is its keeper's stock; one in a house; one a villager keeps;
## one on a parcel), a table out of reach, a non-table container and the MP-03 private stores stay refused, and a refusal changes
## nothing. A tavern table is still reached the way the host reaches it (player_take: theft from its keeper). The guest's away and
## back transition (NetSession.guest_state) changes none of this.
## Run: godot --headless --path game --script res://tests/mp03_public_tables_test.gd
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


func snapshot(w: World, stores: Array) -> String:
	var parts := []
	for s: Inventory in stores:
		parts.append(JSON.stringify(s.to_dict()))
	for q: PlayerState in w.player_list():
		parts.append(str(q.coins))
	return "|".join(parts)


## A cell near `at` that no building, parcel or claim covers (where a public table could stand).
func open_cell(w: World, at: Vector2) -> Vector2i:
	var c0 := Vector2i(floori(at.x), floori(at.y))
	for r in range(2, 12):
		for dx in range(-r, r + 1):
			for dy in [-r, r]:
				var c := c0 + Vector2i(dx, dy)
				if is_open(w, c):
					return c
	return Vector2i(-1, -1)


func is_open(w: World, c: Vector2i) -> bool:
	for id in w.buildings:
		var b: Dictionary = w.buildings[id]
		if b.has("x") and b.has("w") and Rect2i(int(b.x), int(b.y), int(b.w), int(b.h)).grow(1).has_point(c):
			return false
	for pl in w.plots:
		if Rect2i(int(pl.x), int(pl.y), int(pl.w), int(pl.h)).has_point(c):
			return false
	if w.homesteads != null:
		for cl in w.homesteads.claims:
			if Homesteads.rect_of(cl).has_point(c):
				return false
	return c.x >= 0 and c.y >= 0


func table(id: String, c: Vector2i, at: String, keeper: int) -> Dictionary:
	return {"id": id, "kind": "table", "x": c.x, "y": c.y, "at": at, "dish": "pottage", "inv": Inventory.new(), "keeper": keeper}


func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 3303)
	var guest := mk_player(w, "Gwen", "f")
	var gref: String = w.player_ref(guest)

	var plot: Dictionary = w.plots[1]
	w.start_site(plot, "house", gref)
	var site_raw = NetActions.enc(w, plot)
	var here: Vector2 = NetActions._pos_of(plot)
	guest.pos = here
	var some := ""
	for id in plot.site.need:
		if some == "" or int(plot.site.need[id]) > int(plot.site.need[some]):
			some = str(id)
	check(int(plot.site.need.get(some, 0)) >= 6, "setup: the guest's site needs %s" % some)
	guest.inv.remove(some, guest.inv.count(some))

	# The tables. Public: in the open, nobody's. Private: the tavern's (keeper's dish), one in a house, one a villager keeps
	# in the open, one on a parcel. A crate (not a table) and the MP-03 stores.
	var cell := open_cell(w, here)
	check(cell != Vector2i(-1, -1), "setup: an open cell near the site for a public table")
	var pub := table("t_green", cell, "", -1)
	var keeper := w.tavern_keeper()
	var tav: Dictionary = {}
	for c in w.containers:
		if c.kind == "table":
			tav = c
			break
	check(not tav.is_empty() and keeper != null, "setup: the tavern has tables and a keeper")
	tav.keeper = keeper.id
	var house_id := ""
	for id in w.buildings:
		if str(w.buildings[id].get("type", "")) == "house" and w.household_in(str(id)) >= 0:
			house_id = str(id)
			break
	check(house_id != "", "setup: a household's house")
	var in_house := table("t_house", cell, house_id, -1)
	var kept := table("t_kept", cell, "", keeper.id)
	var on_parcel := table("t_parcel", Vector2i(int(plot.x), int(plot.y)), "", -1)
	var fcell := open_cell(w, here + Vector2(NetActions.VERB_REACH + 12.0, 0))
	var far := table("t_far", fcell, "", -1)
	check(fcell != Vector2i(-1, -1) and (Vector2(fcell) + Vector2(0.5, 0.5)).distance_to(here) > NetActions.VERB_REACH, "setup: an open cell out of reach")
	for t in [pub, in_house, kept, on_parcel, far]:
		w.containers.append(t)
	var crate: Dictionary = {}
	for c in w.containers:
		if c.kind != "table":
			crate = c
			break

	var npc: NPC = keeper
	var refused := {"tavern table": {"$inv": "container", "id": str(tav.id)}, "house table": {"$inv": "container", "id": "t_house"},
		"kept table": {"$inv": "container", "id": "t_kept"}, "parcel table": {"$inv": "container", "id": "t_parcel"},
		"far public table": {"$inv": "container", "id": "t_far"}, "no such table": {"$inv": "container", "id": "t_none"},
		"npc": {"$inv": "npc", "id": npc.id}, "pantry": {"$inv": "pantry", "id": 0}, "granary": {"$inv": "granary"}}
	var stores := [tav.inv, in_house.inv, kept.inv, on_parcel.inv, far.inv, pub.inv, npc.inv, w.households[0].pantry, w.granary, guest.inv]
	if not crate.is_empty():
		refused["crate"] = {"$inv": "container", "id": str(crate.id)}
		var cst = w.container_store(crate)
		if cst is Inventory and not stores.has(cst):
			stores.append(cst)
	check(not crate.is_empty(), "setup: a crate (a container that is not a table)")
	for c in w.containers:                       # every table the map has stands in the tavern: none is public
		if c.kind == "table" and not str(c.id).begins_with("t_"):
			refused["map table " + str(c.id)] = {"$inv": "container", "id": str(c.id)}
			if not stores.has(c.inv):
				stores.append(c.inv)
	for s: Inventory in stores:
		if s != guest.inv:
			s.add(some, 3)

	# 1. Refused, both while the guest is away (rejoining) and once it is back, and nothing anywhere changes.
	for away in [true, false]:
		guest.away = away
		for name in refused:
			var before := snapshot(w, stores)
			var need_before := JSON.stringify(plot.site.need)
			var r := req(w, guest, "deliver", [site_raw, refused[name], gref])
			check(not bool(r.ok) and snapshot(w, stores) == before and JSON.stringify(plot.site.need) == need_before,
				"%sdeliver from %s: refused, nothing moves" % ["(away) " if away else "", name])
			if name == "far public table":
				check(str(r.text) == "That is too far away.", "the far public table is refused for reach: %s" % str(r.text))
		var b2 := snapshot(w, stores)
		req(w, guest, "plant_bush", [Vector2i(here), "wheat", refused["tavern table"]])
		req(w, guest, "construction.build_stall", [gref, Vector2i(here), refused["house table"]])
		check(snapshot(w, stores) == b2, "%splant_bush / build_stall naming private tables: nothing moves" % ["(away) " if away else ""])

	# 2. Indirect route: the tavern table's store as the host answers it (container_store), then named as a store: refused.
	guest.away = false
	var tcell0 := Vector2i(int(tav.x), int(tav.y))
	guest.pos = Vector2(w.brain.beside(tcell0, tcell0 + Vector2i(0, 1))) + Vector2(0.5, 0.5)
	var cs := req(w, guest, "container_store", [{"$r": "containers", "k": str(tav.id)}])
	guest.pos = here
	check(str(cs.get("result", {}).get("$inv", "")) == "container", "the host answers the tavern table's store by name: %s" % str(cs.get("result")))
	var b3 := snapshot(w, stores)
	var r_ind := req(w, guest, "deliver", [site_raw, cs.get("result", {}), gref])
	check(bool(cs.ok) and not bool(r_ind.ok) and snapshot(w, stores) == b3, "the tavern table's store, as answered, cannot be spent from")

	# 3. Authorized: the public table within reach, while away (rejoining) and once back (NetSession.guest_state sets away false).
	for away in [true, false]:
		guest.away = away
		pub.inv.remove(some, pub.inv.count(some))
		pub.inv.add(some, 1)                         # deliver takes all a store has of what the site needs: one at a time
		var left := int(plot.site.need[some])
		var pt: int = pub.inv.count(some)
		var g0 := guest.coins
		var r := req(w, guest, "deliver", [site_raw, {"$inv": "container", "id": "t_green"}, gref])
		check(bool(r.ok) and pub.inv.count(some) == pt - 1 and int(plot.site.need[some]) == left - 1 and guest.coins == g0,
			"%sdeliver from the public table within reach: one %s moves to the site (%s)" % ["(away) " if away else "", some, str(r.text)])

	# 4. The tavern table is reached as the host reaches it: player_take beside it, a theft from its keeper.
	guest.away = false
	tav.inv.add("pottage", 1)
	var tcell := Vector2i(int(tav.x), int(tav.y))
	guest.pos = Vector2(w.brain.beside(tcell, tcell + Vector2i(0, 1))) + Vector2(0.5, 0.5)
	var gp: int = guest.inv.count("pottage")
	var gc := guest.crimes.size()
	var hc := w.player.crimes.size()
	var tt: int = tav.inv.total()
	var rt := req(w, guest, "player_take", [{"$r": "containers", "k": str(tav.id)}])
	var got := str(rt.get("result", ""))
	check(bool(rt.ok) and got != "" and got != "far" and got != "full" and guest.inv.count(got) == (gp + 1 if got == "pottage" else 1) and tav.inv.total() == tt - 1,
		"player_take at the tavern table: the guest takes one (%s)" % got)
	check(guest.crimes.size() == gc + 1 and w.player.crimes.size() == hc, "the take is the guest's theft, not the host's")

	# 5. The host is unchanged: it names any store (its own actions and single player).
	var bad := {"why": ""}
	check(NetActions._dec_inv(w, w.player, {"$inv": "container", "id": str(tav.id)}, bad) == tav.inv and bad.why == "", "host: names the tavern table's store")
	w.dispose()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
