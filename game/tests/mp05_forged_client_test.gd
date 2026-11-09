extends SceneTree
## MP-05 security: a modified (malicious) guest client sends forged verb requests to the host (NetActions.apply_verb, the host's
## own request path: decode, ownership and reach checks, then the verb as the guest). It must not use another player's assets
## beyond the tier the host's agreement allows, act for another player, forge an agreement or reach another pair's records.
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


## A guest's request as the host receives it.
func req(w: World, g: PlayerState, path: String, raw: Array) -> Dictionary:
	return NetActions.apply_verb(w, g, path, raw)


## Whether a take request moved item `id` into the guest's pack for free (not as recorded theft).
func free_take(w: World, g: PlayerState, unit_raw: Variant, id: String) -> bool:
	var before := g.inv.count(id)
	var r := req(w, g, "chests.take", [unit_raw, id, 1])
	var res = r.get("result", {})
	var theft: bool = res is Dictionary and bool(res.get("theft", false))
	return g.inv.count(id) > before and not theft


func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 8806)
	var guest := mk_player(w, "Gwen", "f")
	var hal := mk_player(w, "Hal", "e")
	var gref: String = w.player_ref(guest)
	var href: String = w.player_ref(hal)
	# The host's house and chest, holding a raw material, a finished good and a tool.
	var plot: Dictionary = w.plots[0]
	w.start_site(plot, "house", World.PLAYER)
	for id in plot.site.need.duplicate():
		w.player.inv.add(id, int(plot.site.need[id]))
	w.deliver(plot, w.player.inv, World.PLAYER)
	var house: Dictionary = w.buildings[str(plot.building)]
	w.property.set_home(str(house.id))
	var u: Dictionary = w.chests.units_in(str(house.id))[0]
	var u_raw: Dictionary = NetActions.enc(w, u)
	check(str(u_raw.get("$r", "")) == "unit", "setup: a chest unit is sent by name")
	w.player.chest.add("log", 5)
	w.player.chest.add("bread", 5)
	w.player.chest.add("axe", 2)
	var host_cart: Dictionary = w.carts.place(World.PLAYER, w.player.pos)
	host_cart.store.add("axe", 1)
	host_cart.store.add("log", 3)
	var hal_cart: Dictionary = w.carts.place(href, w.player.pos)
	hal_cart.store.add("log", 3)
	hal_cart.store.add("axe", 1)

	# 1. Tier 1: materials only. Tools and finished goods are refused, whatever the request.
	check(w.player_offer("asset_share", guest.pid, "", 1) == "", "host proposes tier 1")
	req(w, guest, "player_answer", [int(w.offers.back().id), true])
	check(w.asset_share_tier(World.PLAYER, gref) == 1, "tier 1 agreed")
	guest.pos = u.at
	check(not free_take(w, guest, u_raw, "axe"), "tier 1: a forged take of a tool from the host's chest is refused")
	check(not free_take(w, guest, u_raw, "bread"), "tier 1: a forged take of a finished good is refused")
	check(w.player.chest.count("axe") == 2 and w.player.chest.count("bread") == 5, "tier 1: the host's tools and goods stay put")
	check(free_take(w, guest, u_raw, "log"), "tier 1: the agreed material can be taken (control)")
	guest.inv.add("axe", 1)
	var ga := guest.inv.count("axe")
	req(w, guest, "chests.store", [u_raw, "axe", 1])
	check(guest.inv.count("axe") == ga and w.player.chest.count("axe") == 2, "tier 1: a tool cannot be stored into the shared chest")
	# Forged chest units built by the client itself instead of naming a real one: a 'homestead' or 'cart' of its own whose store
	# is really the host's cart load, or a household's pantry. Every one must be refused.
	guest.pos = w.player.pos
	var fake_home := {"id": "homestead:x", "kind": "chest", "bid": "", "at": guest.pos,
		"homestead": {"owner": gref, "store": {"$inv": "cart", "id": int(host_cart.id)}}}
	check(not free_take(w, guest, fake_home, "axe") and host_cart.store.count("axe") == 1,
		"forged unit: a self-made 'own homestead' wrapping the host's cart load gives nothing")
	var fake_cart := {"id": "cart:x", "kind": "cart", "bid": "", "at": guest.pos,
		"cart": {"owner": gref, "puller": "", "pos": guest.pos, "store": {"$inv": "cart", "id": int(host_cart.id)}}}
	check(not free_take(w, guest, fake_cart, "axe") and host_cart.store.count("axe") == 1,
		"forged unit: a self-made 'own cart' wrapping the host's cart load gives nothing")
	var pantry: Inventory = w.households[0].pantry
	var pid0 := "" if pantry.ids().is_empty() else str(pantry.ids()[0])
	var pc := pantry.count(pid0)
	var fake_pantry := {"id": "homestead:y", "kind": "chest", "bid": "", "at": guest.pos,
		"homestead": {"owner": gref, "store": {"$inv": "pantry", "id": 0}}}
	if pid0 != "":
		free_take(w, guest, fake_pantry, pid0)
	check(pid0 == "" or pantry.count(pid0) == pc, "forged unit: a self-made 'own chest' wrapping a household's pantry gives nothing")
	var fake_host_unit := u.duplicate()
	fake_host_unit.erase("at")
	check(not free_take(w, guest, fake_host_unit, "axe"), "forged unit: the host's chest sent as a plain record, not by name, gives no tool")
	guest.inv.add("bread", 1)
	var gb := guest.inv.count("bread")
	req(w, guest, "chests.store", [fake_cart, "bread", 1])
	check(guest.inv.count("bread") == gb and host_cart.store.count("bread") == 0, "forged unit: nothing can be stored through a self-made unit")

	# 2. Tier 2 still excludes tools; the host's cart stays the host's.
	check(w.player_offer("asset_share", guest.pid, "", 2) == "", "host proposes tier 2")
	req(w, guest, "player_answer", [int(w.offers.back().id), true])
	check(w.asset_share_tier(World.PLAYER, gref) == 2, "tier 2 agreed")
	guest.pos = u.at
	check(not free_take(w, guest, u_raw, "axe"), "tier 2: a forged take of a tool is refused")
	check(free_take(w, guest, u_raw, "bread"), "tier 2: a finished good can be taken (control)")
	guest.pos = w.player.pos
	var cart_raw = NetActions.enc(w, w.chests.unit("cart:%d" % int(host_cart.id)))
	check(not free_take(w, guest, cart_raw, "axe") and not free_take(w, guest, cart_raw, "log"), "tier 2: the host's cart load is not shared (tier 3 only)")
	req(w, guest, "carts.hitch", [NetActions.enc(w, host_cart), gref])
	check(str(host_cart.puller) == "", "tier 2: a forged hitch of the host's cart is refused")
	check(w.carts.hitch(host_cart, World.PLAYER) == "", "the host takes hold of its own cart")
	req(w, guest, "carts.park", [NetActions.enc(w, host_cart)])
	check(str(host_cart.puller) == World.PLAYER, "tier 2: a forged park cannot make the host let go of its cart")
	w.carts.park(host_cart)
	# A guest names a villager (or anyone not itself) as the one who takes hold.
	var hh_cart: Dictionary = w.carts.place("hh:0", w.player.pos)
	var member: Array = w.brain._members(0)
	if not member.is_empty():
		req(w, guest, "carts.hitch", [NetActions.enc(w, hh_cart), World.npc_ref((member[0] as NPC).id)])
	check(str(hh_cart.puller) == "", "forged hitch: a guest cannot make a villager take hold of a cart")
	req(w, guest, "carts.hitch", [NetActions.enc(w, host_cart), World.PLAYER])
	check(str(host_cart.puller) == "", "forged hitch: a guest cannot name the host as the puller")

	# 3. A third player's assets: no agreement with the guest, so only the foreign (theft) path, never a free take or a store.
	hal.pos = w.player.pos
	check(w.player_offer("asset_share", hal.pid, "", 3) == "", "host proposes tier 3 to Hal")
	var hal_oid := int(w.offers.back().id)
	# 4a. The guest answers an offer addressed to Hal.
	req(w, guest, "player_answer", [hal_oid, true])
	check(w.asset_share_tier(World.PLAYER, href) == 0 and w.asset_share_tier(href, gref) == 0, "forged answer: accepting another player's offer agrees nothing")
	check(w.offers.any(func(o): return int(o.id) == hal_oid), "forged answer: the other player's offer is untouched")
	check(str(w.as_actor(hal, w.player_answer.bind(hal_oid, true))) == "" and w.asset_share_tier(World.PLAYER, href) == 3, "Hal accepts host tier 3 (control)")
	var hal_unit = NetActions.enc(w, w.chests.unit("cart:%d" % int(hal_cart.id)))
	var hb: int = hal_cart.store.count("axe")
	var r3 := req(w, guest, "chests.take", [hal_unit, "axe", 1])
	var res3 = r3.get("result", {})
	check(hal_cart.store.count("axe") == hb or (res3 is Dictionary and bool(res3.get("theft", false))), "third player: a take from Hal's cart is never free (theft at most)")
	guest.inv.add("log", 1)
	var gl := guest.inv.count("log")
	req(w, guest, "chests.store", [hal_unit, "log", 1])
	check(guest.inv.count("log") == gl, "third player: the guest cannot store into Hal's cart")
	req(w, guest, "carts.hitch", [NetActions.enc(w, hal_cart), gref])
	check(str(hal_cart.puller) == "", "third player: the guest cannot hitch Hal's cart")

	# 4b. Forged agreement proposals: out-of-range tiers, a tier of another type, and an offer on behalf of another player.
	guest.pos = w.player.pos
	var before_offers := w.offers.size()
	for bad_tier in [0, 4, -1, 99]:
		req(w, guest, "player_offer", ["asset_share", w.player.pid, "", bad_tier, null, 0, 0, ""])
	req(w, guest, "player_offer", ["asset_share", w.player.pid, "", "3", null, 0, 0, ""])
	req(w, guest, "player_offer", ["asset_share", w.player.pid, "", [3], null, 0, 0, ""])
	check(w.offers.size() == before_offers, "forged offer: tiers 0, 4, -1, 99, \"3\" and [3] create no offer")
	req(w, guest, "player_offer", ["asset_share", w.player.pid, "", 2.7, null, 0, 0, ""])
	var made: Array = w.offers.filter(func(o): return str(o.kind) == "asset_share" and str(o.to) == World.PLAYER)
	check(made.size() <= 1 and made.all(func(o): return o.qty is int and int(o.qty) >= 1 and int(o.qty) <= 3 and str(o["from"]) == gref),
		"forged offer: a fractional tier is held as a whole tier 1-3, from the guest itself")
	for o in made:
		w.offers.erase(o)
	var r_on_behalf := req(w, guest, "player_offer", ["asset_share", w.player.pid, "", 3, {"$pid": hal.pid}, 0, 0, ""])
	check(not bool(r_on_behalf.ok) and not w.offers.any(func(o): return str(o.kind) == "asset_share" and str(o["from"]) == href and str(o.to) == World.PLAYER),
		"forged offer: an offer as Hal (another player's character) is refused")
	req(w, guest, "player_offer", ["asset_share", hal.pid, "", 3, null, 0, 0, ""])
	check(w.offers.all(func(o): return str(o.kind) != "asset_share" or str(o.to) != href or str(o["from"]) != World.PLAYER or int(o.id) == hal_oid),
		"forged offer: the guest's own offer to Hal is recorded as the guest's, never the host's")
	# 4c. The host's tier-1 offer accepted with extra forged arguments still agrees exactly tier 1.
	check(w.player_offer("asset_share", guest.pid, "", 1) == "", "host proposes tier 1 again")
	var t1 := int(w.offers.back().id)
	req(w, guest, "player_answer", [t1, true, null, 3])
	req(w, guest, "player_answer", [t1, true, {"$pid": w.player.pid}])
	check(w.asset_share_tier(World.PLAYER, gref) <= 2, "forged answer: extra arguments cannot raise the tier")
	req(w, guest, "player_answer", [t1, true])
	check(w.asset_share_tier(World.PLAYER, gref) == 1, "answer: the accepted tier is the offer's, exactly")

	# 5. Revoking: the guest's own pair only.
	req(w, guest, "asset_share_revoke", [hal.pid])
	check(w.asset_share_tier(World.PLAYER, href) == 3, "forged revoke: the guest cannot end the host-Hal agreement")
	req(w, guest, "asset_share_revoke", [w.player.pid, {"$pid": hal.pid}])
	check(w.asset_share_tier(World.PLAYER, href) == 3, "forged revoke: acting as Hal is refused")
	req(w, guest, "asset_share_revoke", [guest.pid])
	check(w.asset_share_tier(World.PLAYER, gref) == 1 and w.asset_share_tier(World.PLAYER, href) == 3, "forged revoke: naming itself changes nothing")

	# 6. Privacy: a guest's copy holds only its own pairs.
	var d: Dictionary = w.to_dict()
	NetSession._private_for(d, gref)
	var pairs: Dictionary = d.get("asset_shares", {})
	check(not pairs.is_empty() and pairs.keys().all(func(k): return str(k).split("|").has(gref)), "privacy: the guest's sync copy has its own agreement only")
	check(not pairs.has(World._asset_share_key(World.PLAYER, href)), "privacy: the host-Hal agreement is not sent to the guest")

	# 7. Ownership at tier 3: use, never sale, lease, transfer or removal.
	check(w.player_offer("asset_share", guest.pid, "", 3) == "", "host proposes tier 3")
	req(w, guest, "player_answer", [int(w.offers.back().id), true])
	check(w.asset_share_tier(World.PLAYER, gref) == 3, "tier 3 agreed")
	guest.pos = w.player.pos
	var owner_before := w.owner_of(plot)
	var coins_before := guest.coins
	var plot_raw = NetActions.enc(w, plot)
	var house_raw = NetActions.enc(w, house)
	req(w, guest, "property.sell", [plot_raw, gref])
	req(w, guest, "property.sell", [house_raw, gref])
	req(w, guest, "property.sell", [plot_raw, World.PLAYER])
	check(w.owner_of(plot) == owner_before and guest.coins == coins_before, "tier 3: the guest cannot sell the host's property")
	req(w, guest, "property.end_lease", [plot_raw, gref])
	req(w, guest, "property.lease", [plot_raw, gref])
	check(w.owner_of(plot) == owner_before and w.tenant_of(plot) != gref, "tier 3: the guest cannot lease or end a lease of the host's property")
	req(w, guest, "ventures.offer", [house_raw, 1])
	check(not house.has("sale"), "tier 3: the guest cannot offer the host's building for sale")
	req(w, guest, "property.set_home", [str(house.id)])
	check(guest.home != str(house.id) and w.holder_of(house) == World.PLAYER, "tier 3: the guest cannot make the host's house its home")
	var fit_before := JSON.stringify(house.get("fittings", {}))
	req(w, guest, "fitting.remove", [house_raw, "chest"])
	check(JSON.stringify(house.get("fittings", {})) == fit_before, "tier 3: the guest cannot take up the host's fittings")
	req(w, guest, "cancel_site", [plot_raw, {"$inv": "pack"}])
	check(not w.buildings.is_empty() and w.buildings.has(str(house.id)), "tier 3: the guest cannot demolish or cancel the host's building")
	check(req(w, guest, "carts.hitch", [NetActions.enc(w, host_cart), gref]).ok and str(host_cart.puller) == gref, "tier 3: the guest may pull the host's cart (control)")
	check(str(host_cart.owner) == World.PLAYER, "tier 3: pulling never transfers the cart")
	w.carts.park(host_cart, guest)
	check(str(host_cart.owner) == World.PLAYER and str(host_cart.puller) == "", "tier 3: the cart is let go and stays the host's")
	w.dispose()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
