extends SceneTree
## B25-AUD-MP-03 (host authorization): a modified guest client names, in a whitelisted verb's arguments, a store that is not its
## own ({"$inv": "npc" | "pantry" | "granary" | "container" | "cart"}). The host's decoder (NetActions.dec / _dec_inv) must refuse
## it, so no verb spends or moves goods from a villager's pack, a household's pantry, the granary, a villager's container or a cart
## the guest may not use. Controls: the stores a genuine guest client sends (its own pack; its own chest; a cart it may use) work.
## Run: godot --headless --path game --script res://tests/mp03_forged_store_test.gd
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


## Every store a forged request could reach, as a fingerprint (counts of every item in each), plus the players' coins.
func snapshot(w: World, stores: Array) -> String:
	var parts := []
	for s: Inventory in stores:
		parts.append(JSON.stringify(s.to_dict() if s.has_method("to_dict") else s.ids().map(func(id): return [id, s.count(id)])))
	parts.append(str(w.player.coins))
	for q: PlayerState in w.player_list():
		parts.append(str(q.coins))
	return "|".join(parts)


func fill(inv: Inventory, need: Dictionary) -> void:
	for id in need:
		inv.add(str(id), int(need[id]) + 2)
	inv.add("wheat", 10)


func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 3303)
	var guest := mk_player(w, "Gwen", "f")
	var hal := mk_player(w, "Hal", "e")
	var gref: String = w.player_ref(guest)
	var href: String = w.player_ref(hal)

	# The guest's own building site: a genuine guest delivers its pack to it (World.deliver, "deliver" verb).
	var plot: Dictionary = w.plots[1]
	w.start_site(plot, "house", gref)
	var need: Dictionary = plot.site.need.duplicate()
	check(not need.is_empty(), "setup: the guest's site needs materials")
	var site_raw = NetActions.enc(w, plot)
	var here = NetActions._pos_of(plot)
	guest.pos = here
	hal.pos = here
	w.player.pos = here

	# Stores that are not the guest's, each holding what the site needs and some wheat.
	var npc: NPC = null
	for n: NPC in w.npcs:
		if n.alive:
			npc = n
			break
	var pantry: Inventory = w.households[0].pantry
	var granary: Inventory = w.granary
	var host_cart: Dictionary = w.carts.place(World.PLAYER, here)
	var hal_cart: Dictionary = w.carts.place(href, here)
	var hh_cart: Dictionary = w.carts.place("hh:0", here)
	var cont: Dictionary = {}
	for c in w.containers:
		if c.get("inv") is Inventory:
			cont = c
			break
	var foreign := {"npc": {"$inv": "npc", "id": npc.id}, "pantry": {"$inv": "pantry", "id": 0}, "granary": {"$inv": "granary"},
		"host cart": {"$inv": "cart", "id": int(host_cart.id)}, "Hal's cart": {"$inv": "cart", "id": int(hal_cart.id)},
		"household cart": {"$inv": "cart", "id": int(hh_cart.id)}}
	var stores := [npc.inv, pantry, granary, host_cart.store, hal_cart.store, hh_cart.store]
	if not cont.is_empty():
		foreign["container"] = {"$inv": "container", "id": str(cont.id)}
		stores.append(cont.inv)
	check(not cont.is_empty(), "setup: the village has a villager's container")
	for s: Inventory in stores:
		fill(s, need)
	var pen: Dictionary = {}
	for id in w.fauna.pens:
		pen = w.fauna.pens[id]
		break
	var pen_raw = NetActions.enc(w, pen) if not pen.is_empty() else null

	# 1. Forged stores through whitelisted verbs: refused, and nothing anywhere changes.
	for name in foreign:
		var raw: Dictionary = foreign[name]
		var before := snapshot(w, stores + [guest.inv])
		var need_before := JSON.stringify(plot.site.need)
		var r := req(w, guest, "deliver", [site_raw, raw, gref])
		check(not bool(r.ok) and snapshot(w, stores + [guest.inv]) == before and JSON.stringify(plot.site.need) == need_before,
			"deliver from %s: refused, no goods move" % name)
		if pen_raw != null:
			var trough := int(pen.get("trough", 0))
			before = snapshot(w, stores)
			guest.pos = NetActions._pos_of(pen) if NetActions._pos_of(pen) != null else here
			r = req(w, guest, "fauna.feed", [pen_raw, raw, 5])
			check(not bool(r.ok) and snapshot(w, stores) == before and int(pen.get("trough", 0)) == trough,
				"fauna.feed from %s: refused, no wheat moves" % name)
			guest.pos = here
		before = snapshot(w, stores)
		req(w, guest, "farm_plots.build_fence", [{"$r": "fields", "k": "none"}, gref, [{"$inv": "pack"}, raw]])
		req(w, guest, "construction.build_stall", [gref, Vector2i(here), raw])
		req(w, guest, "plant_bush", [Vector2i(here), "wheat", raw])
		check(snapshot(w, stores) == before, "build_fence / build_stall / plant_bush naming %s: no goods move" % name)
	check(pen_raw != null, "setup: the village has a pen to feed")

	# 2. Controls: what a genuine guest client sends still works. One unit at a time, so the site stays open.
	if plot.site.need.is_empty() or bool(plot.site.get("done", false)):
		check(false, "the guest's site was filled by forged deliveries (controls cannot run)")
		w.dispose()
		print("%d checks, %d failures" % [checks, failures])
		quit(1)
		return
	var some := ""
	for id in plot.site.need:
		if some == "" or int(plot.site.need[id]) > int(plot.site.need[some]):
			some = str(id)
	check(int(plot.site.need.get(some, 0)) >= 6, "setup: the site still needs %s for the controls" % some)
	for id in need:
		guest.inv.remove(str(id), guest.inv.count(str(id)))
	guest.inv.add(some, 1)
	var left := int(plot.site.need[some])
	var r1 := req(w, guest, "deliver", [site_raw, {"$inv": "pack"}, gref])
	check(bool(r1.ok) and guest.inv.count(some) == 0 and int(plot.site.need[some]) == left - 1, "control: the guest delivers from its own pack")
	if pen_raw != null:
		guest.pos = NetActions._pos_of(pen) if NetActions._pos_of(pen) != null else here
		guest.inv.add("wheat", 3)
		var gw := guest.inv.count("wheat")
		var trough := int(pen.get("trough", 0))
		var r2 := req(w, guest, "fauna.feed", [pen_raw, {"$inv": "pack"}, 3])
		check(bool(r2.ok) and guest.inv.count("wheat") == gw - 3 and int(pen.trough) == trough + 3, "control: the guest feeds a pen from its own pack")
		guest.pos = here
	var site2_raw = site_raw
	var here2 = here
	var plot2 := plot
	guest.chest.remove(some, guest.chest.count(some))
	guest.chest.add(some, 1)
	var r3 := req(w, guest, "deliver", [site2_raw, {"$inv": "chest"}, gref])
	check(bool(r3.ok) and guest.chest.count(some) == 0, "control: the guest delivers from its own chest")
	var own_cart: Dictionary = w.carts.place(gref, here2)
	own_cart.store.add(some, 1)
	var r4 := req(w, guest, "deliver", [site2_raw, {"$inv": "cart", "id": int(own_cart.id)}, gref])
	check(bool(r4.ok) and own_cart.store.count(some) == 0, "control: the guest delivers from its own cart")
	# Tier 3 (MP-05): the host's cart is the guest's to use.
	check(w.player_offer("asset_share", guest.pid, "", 3) == "", "host proposes tier 3")
	req(w, guest, "player_answer", [int(w.offers.back().id), true])
	check(w.asset_share_tier(World.PLAYER, gref) == 3, "tier 3 agreed")
	host_cart.pos = here2
	for id in need:
		host_cart.store.remove(str(id), host_cart.store.count(str(id)))
	host_cart.store.add(some, 1)
	var r5 := req(w, guest, "deliver", [site2_raw, {"$inv": "cart", "id": int(host_cart.id)}, gref])
	check(bool(r5.ok) and host_cart.store.count(some) == 0, "control: at tier 3 the guest delivers from the host's cart")
	# Hal's cart stays Hal's (no agreement with the guest), and a far cart is out of reach.
	hal_cart.pos = here2
	var hl: int = hal_cart.store.count(some)
	var r6 := req(w, guest, "deliver", [site2_raw, {"$inv": "cart", "id": int(hal_cart.id)}, gref])
	check(not bool(r6.ok) and hal_cart.store.count(some) == hl, "tier 3 with the host does not open Hal's cart")
	own_cart.pos = (here2 as Vector2) + Vector2(NetActions.VERB_REACH + 10.0, 0)
	own_cart.store.add(some, 1)
	var oc: int = own_cart.store.count(some)
	var r7 := req(w, guest, "deliver", [site2_raw, {"$inv": "cart", "id": int(own_cart.id)}, gref])
	check(not bool(r7.ok) and own_cart.store.count(some) == oc, "the guest's own cart out of reach is refused")
	# The host's own actions are untouched: it delivers from the granary directly (property.gd's own use).
	var gr := granary.count(some)
	w.deliver(plot2, granary, World.PLAYER)
	check(granary.count(some) < gr and bool(plot2.site.get("done", false)), "host: its own (direct) delivery from the granary still works")
	w.dispose()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
