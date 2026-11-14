extends SceneTree
## MML-MP-02 (audit 011): a multiplayer guest runs its own market stall and shop as the host runs its own. Every management action of
## the stall window (StallWindow: put up, take back, price, display, larger stall, collect, put in and take out of the till, pay the
## rent owing, open and close the stall and settle, give up the pitch or close the shop, hire and let go of the attendant, the back
## room's store and bring out, the workroom's set aside, bring back, put up and production orders) is sent by the guest's world
## (World.mirror) and applied by the host as the guest (NetActions.apply_verb), so the host's world changes exactly as the host's own
## action would, and the guest's copy agrees after the host's sync (NetSync). Forged requests (another player's or a villager's
## stall, a record the guest made up, a villager's or another player's reference, too far, while away) change nothing. Coins and goods
## are conserved. The host's stall survives a reconnect (a fresh welcome) and the host's save and load.
##
## In one process: the host's World and the guest's World (loaded from the host's welcome, NetSession.welcome_view) joined by a
## queue in place of ENet. The verbs and their arguments go through the real codec (NetActions.enc on the guest's world, dec on the
## host's), the host's gateway (apply_verb: decoding, ownership, reach, away) and the real sync (NetSync.changed and adopt, filtered by
## NetSession._private_for). Not tested here: the network itself (net_c_test, net_mp4_test) and real devices.
##   godot --headless --path game -s tests/mp02_guest_stall_management_test.gd

var checks := 0
var failures := 0
var hw: World                   # the host's world
var gw: World                   # the guest's copy
var g: PlayerState              # the guest as the host has it
var gref := ""
var queue := []                 # verbs the guest's world sent, not yet applied
var replies := []
var synced := {}


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		failures += 1


func mk_player(w: World, nm: String, key: String) -> PlayerState:
	var p := PlayerState.new()
	p.name = nm
	p.family = "Stall"
	p.sex = "female"
	p.born = w.player.born
	Identity.register_player(w, p)
	w.give_start_kit(p)
	p.net_key = key.repeat(32)
	w.add_guest(p)
	p.pos = w.player.pos
	return p


## The guest joins (or rejoins): its copy is the host's welcome, its verbs go to the queue as World.mirror sends them.
func connect_guest() -> void:
	if gw != null:
		gw.dispose()
	var d := NetSession.welcome_view(hw, g.pid)
	synced = NetSync.digest(d)
	gw = World.new()
	gw.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
	gw.set_local_player(gw.player_by_pid(g.pid))
	gw.remote = func(path: String, args: Array) -> int:
		queue.append([path, args.map(func(v): return NetActions.enc(gw, v))])
		return queue.size()


## The host applies what the guest sent, in order, and syncs the guest's copy (its own record from each answer, then the changed
## sections), as NetSession does.
func pump() -> void:
	for q in queue:
		var r := NetActions.apply(hw, g, "verb", {"path": str(q[0]), "a": q[1]})     # as NetSession.apply_requests
		replies.append(r)
		for k in NetActions.resync_sections(str(q[0])):
			synced[k] = -1                           # as NetSession.apply_requests: the sections the guest's guess may have changed go again
		var fresh := PlayerState.from_dict(r.player)
		for pr in fresh.get_property_list():
			var k := str(pr.name)
			if int(pr.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE and not k in ["pos", "party", "map_level"]:
				gw.player.set(k, fresh.get(k))
	queue.clear()
	var d: Dictionary = hw.to_dict()
	NetSession._private_for(d, gref, hw)
	NetSync.adopt(gw, NetSync.changed(d, synced))


## A guest's request as the host receives it (a forged client sends whatever it likes).
func forged(path: String, raw: Array) -> Dictionary:
	return NetActions.apply(hw, g, "verb", {"path": path, "a": raw})


func js(v) -> String:
	return JSON.stringify(v, "", true)


## Host and guest agree on the premises record and on the guest's purse and pack.
func agree(id: String, what: String) -> void:
	var hs: Dictionary = hw.business.record(id)
	var gs: Dictionary = gw.business.record(id)
	var hd: Dictionary = JSON.parse_string(JSON.stringify(hs))
	check(js(hd) == js(gs) and gw.player.coins == g.coins and js(gw.player.inv.to_dict()) == js(g.inv.to_dict()),
		"%s: the guest's copy agrees with the host (record, purse, pack)" % what)


## Every unit of `id` the guest and the premises hold, and what lies about as loot.
func goods(id: String) -> int:
	var n := g.inv.count(id)
	for sid in hw.stalls:
		var s: Dictionary = hw.stalls[sid]
		n += int(s.get("stock", {}).get(id, 0)) + int(s.get("store", {}).get(id, 0)) + int(s.get("work", {}).get(id, 0))
	for s in hw.business.every_shop():
		n += int(s.get("stock", {}).get(id, 0)) + int(s.get("store", {}).get(id, 0)) + int(s.get("work", {}).get(id, 0))
	for l in hw.loot:
		n += (l.inv as Inventory).count(id)
	return n


func last_ok() -> bool:
	return not replies.is_empty() and bool(replies.back().ok)


func _init() -> void:
	GameData.ensure()
	hw = World.new()
	hw.setup(VillageMap.load_default(), 8602)
	g = mk_player(hw, "Gwen", "c")
	gref = hw.player_ref(g)
	g.coins = 3000
	g.inv.add("plank", 12)
	g.inv.add("bread", 6)
	var pitch: Dictionary = hw.business.free_pitch()
	check(not pitch.is_empty(), "setup: a free market pitch")
	var pid := str(pitch.id)
	g.pos = hw.business.use_cell(pitch)
	connect_guest()
	check(gw.player.pid == g.pid and gw.mirrors(), "setup: the guest's copy is the guest's and sends its verbs to the host")
	var coins0 := hw.total_coins()
	var planks0 := goods("plank")

	# ---------------------------------------------------------------- a market pitch ----------------------------------
	var gs: Dictionary = gw.business.record(pid)
	gw.business.rent(gs)
	pump()
	var hs: Dictionary = hw.business.record(pid)
	check(last_ok() and hw.tenant_of(hs) == gref, "rent: the host lets the pitch to the guest")
	agree(pid, "rent")
	gs = gw.business.record(pid)
	check(gw.business.is_mine(gs), "rent: the guest's copy shows the pitch as its own")

	gw.business.list_item(gs, "plank", 6)
	pump()
	check(int(hs.stock.get("plank", 0)) == 6 and g.inv.count("plank") == 6, "put up: 6 planks go from the guest's pack to the stall on the host")
	agree(pid, "put up")
	gw.business.set_price(gw.business.record(pid), "plank", GameData.value("plank") + 2)
	pump()
	check(int(hs.prices.get("plank", 0)) == GameData.value("plank") + 2, "price: the host keeps the guest's price")
	gw.business.unlist(gw.business.record(pid), "plank", 2)
	pump()
	check(int(hs.stock.get("plank", 0)) == 4 and g.inv.count("plank") == 8, "take back: 2 planks back to the guest's pack on the host")
	agree(pid, "take back")
	var c0 := g.coins
	gw.business.deposit(gw.business.record(pid), 50)
	pump()
	check(int(hs.till) == 50 and g.coins == c0 - 50, "put in: 50 coins from the guest's purse into the till on the host")
	gw.business.withdraw(gw.business.record(pid), 10)
	pump()
	check(int(hs.till) == 40 and g.coins == c0 - 40, "take out: 10 coins from the till back to the guest on the host")
	agree(pid, "till")
	gw.business.withdraw(gw.business.record(pid), 5000)
	pump()
	check(int(hs.till) == 40 and g.coins == c0 - 40, "take out: more than the till holds is refused on the host")
	# a session's sales (as the host's villagers would buy) are settled by the guest's Close the stall
	hw.business.stalls.record_sale(hs, gref, "plank", 1, 20)
	hs.stock.plank = maxi(0, int(hs.stock.get("plank", 0)) - 1)
	hs.till = int(hs.till) + 20
	pump()
	planks0 -= 1                        # the plank the villager bought (as Business.sell's buyer would carry it off)
	coins0 += 20                        # the villager's coins the test put in the till in its place
	var tr0 := hw.treasury
	gw.business.stalls.close(gw.business.record(pid))
	pump()
	check(not hw.business.stalls.is_open(hs) and hw.business.stalls.unsettled(hs) == 0 and hw.treasury == tr0 + 1,
		"close the stall and settle: the host closes it and the manor's 5%% of 20 goes to the treasury (%d)" % (hw.treasury - tr0))
	agree(pid, "close and settle")
	gw.business.stalls.open(gw.business.record(pid), gw.acting_ref())
	pump()
	check(hw.business.stalls.is_open(hs), "open the stall: the host opens it again")
	agree(pid, "open")
	# the larger stall and its display
	gw.business.upgrade(gw.business.record(pid))
	pump()
	check(bool(hs.get("large", false)), "larger stall: the host enlarges it")
	gw.business.set_display(gw.business.record(pid), "plank")
	pump()
	check(str(hs.get("display", "")) == "plank", "display: the host shows the planks")
	# the attendant: hired and let go
	var cands: Array = gw.as_actor(gw.player, gw.business.candidates)
	check(not cands.is_empty(), "attendant: the guest's copy lists people to hire")
	if not cands.is_empty():
		var who: NPC = cands[0]
		var far := Vector2(who.pos)
		var hn := hw.npc(who.id)
		hn.pos = g.pos + Vector2(40, 0)                  # hiring is from the window, wherever the candidate is (as for the host)
		gw.npc(who.id).pos = hn.pos
		gw.business.hire(gw.business.record(pid), gw.npc(who.id))
		pump()
		check(int(hs.get("attendant", -1)) == who.id, "hire: the host hires the guest's choice for the guest's stall (%s)" % replies.back().text)
		agree(pid, "hire")
		gw.business.dismiss(gw.business.record(pid))
		pump()
		check(int(hs.get("attendant", -1)) == -1, "let go: the host lets the attendant go")
		agree(pid, "let go")
		hn.pos = far
	# the rent owing
	hs.missed = 1
	hs.paid_day = hw.day() - 1
	pump()
	tr0 = hw.treasury
	gw.business.pay_arrears(gw.business.record(pid))
	pump()
	check(int(hs.missed) == 0 and int(hs.paid_day) == hw.day() and hw.treasury == tr0 + hw.business.rent_of(hs), "pay the rent owing: the host takes it to the manor")
	agree(pid, "rent owing")
	check(hw.total_coins() == coins0, "pitch: coins conserved (%d, %d)" % [hw.total_coins(), coins0])
	check(goods("plank") == planks0, "pitch: planks conserved")

	# ---------------------------------------------------------------- forged requests on the guest's own pitch ---------
	var before := js(hs)
	var cb := g.coins
	var fake := hs.duplicate(true)
	fake.till = 5000
	for path in ["business.collect", "business.withdraw", "business.close"]:
		forged(path, [NetActions.enc(hw, fake)] + ([100] if path == "business.withdraw" else []))
	check(g.coins == cb and js(hs) == before and hw.total_coins() == coins0, "forged: a made-up copy of the pitch with a full till pays nothing")
	var r := forged("business.stalls.open", [NetActions.enc(hw, hs), "hh:0"])
	check(not bool(r.ok), "forged: opening the guest's stall in a household's name is refused")
	g.away = true
	gw.business.unlist(gw.business.record(pid), "plank", 1)
	pump()
	check(not last_ok() and int(hs.stock.get("plank", 0)) == 3, "away: a guest out of play does not run its stall (%s)" % replies.back().text)
	agree(pid, "away: the guest's own guess is put right by the host's sync")
	g.away = false
	var gpos := g.pos
	g.pos = gpos + Vector2(80, 0)
	gw.business.unlist(gw.business.record(pid), "plank", 1)
	pump()
	check(not last_ok() and int(hs.stock.get("plank", 0)) == 3, "too far: the stall out of the guest's reach is refused (%s)" % replies.back().text)
	agree(pid, "too far: the guest's own guess is put right by the host's sync")
	g.pos = gpos

	# ---------------------------------------------------------------- another's stall: refused ----------------------
	var hal := mk_player(hw, "Hal", "d")
	hal.coins = 500
	var hal_pitch: Dictionary = hw.business.free_pitch()
	check(not hal_pitch.is_empty() and str(hw.as_actor(hal, hw.business.rent.bind(hal_pitch))) == "", "setup: Hal (another guest) rents a pitch")
	hal.inv.add("plank", 2)
	hw.as_actor(hal, hw.business.list_item.bind(hal_pitch, "plank", 2))
	var vill: Dictionary = {}
	for sid in hw.business.stalls.sorted_ids():
		var vs: Dictionary = hw.stalls[sid]
		if hw.business.stalls.is_merchant_stall(vs) or (hw.tenant_of(vs).begins_with("hh:")):
			vill = vs
			break
	check(not vill.is_empty(), "setup: a villager's stall")
	for other in [hal_pitch, vill].filter(func(x): return not x.is_empty()):
		forged_all(other)
	check(str(hw.as_actor(hal, hw.business.close.bind(hal_pitch))) != "", "setup: Hal gives up his pitch")
	hw.player.coins = maxi(hw.player.coins, 500)
	var host_pitch: Dictionary = hw.business.free_pitch()
	check(not host_pitch.is_empty() and hw.business.rent(host_pitch) == "", "setup: the host rents a pitch of its own")
	hw.player.inv.add("bread", 3)
	check(hw.business.list_item(host_pitch, "bread", 3) == "" and hw.business.deposit(host_pitch, 30) == "", "setup: the host's stall holds bread and 30 coins")
	forged_all(host_pitch)
	g.pos = gpos

	# ---------------------------------------------------------------- a shop in the guest's own room ------------------
	var room := _guest_room()
	check(not room.is_empty() and hw.holds(gref, room), "setup: the guest holds a storeroom")
	var bid := str(room.id)
	for kind in ["counter", "stock_chest", "workbench"]:
		for k in Fitting.cost(kind):
			g.inv.add(k, int(Fitting.cost(kind)[k]))
		var cell := _free_cell(room, kind)
		var why: String = str(hw.as_actor(g, hw.fitting.place.bind(room, kind, cell)))
		check(why == "", "setup: the guest's %s in its room (%s)" % [kind, why])
	g.pos = Vector2(hw.building_door(bid)) + Vector2(0.5, 0.5)
	pump()
	connect_guest()                       # the guest rejoins: its copy is the host's welcome again
	coins0 = hw.total_coins()
	planks0 = goods("plank")
	gw.business.open_shop(gw.buildings[bid])
	pump()
	var sh: Dictionary = hw.business.record(bid)
	check(last_ok() and not sh.is_empty() and str(sh.get("by", "")) == gref, "open the shop: the host opens the guest's shop (%s)" % replies.back().text)
	check(gw.business.is_mine(gw.business.record(bid)), "open the shop: the guest's copy shows it as its own")
	agree(bid, "open the shop")
	var gsh := func() -> Dictionary: return gw.business.record(bid)
	gw.business.list_item(gsh.call(), "plank", 3)
	pump()
	check(int(sh.stock.get("plank", 0)) == 3, "shop put up: 3 planks on the shelf on the host")
	gw.business.set_price(gsh.call(), "plank", GameData.value("plank") + 1)
	pump()
	check(int(sh.prices.get("plank", 0)) == GameData.value("plank") + 1, "shop price: on the host's shop record (not a copy)")
	gw.business.store_item(gsh.call(), "plank", 2)
	pump()
	check(int(sh.get("store", {}).get("plank", 0)) == 2, "store: 2 planks to the back room on the host's shop record")
	gw.business.fetch(gsh.call(), "plank", 1)
	pump()
	check(int(sh.get("store", {}).get("plank", 0)) == 1, "bring out: 1 plank back from the back room on the host")
	agree(bid, "back room")
	sh.till = 25
	coins0 += 25
	pump()
	var gc0 := g.coins
	gw.business.collect(gsh.call())
	pump()
	check(int(sh.till) == 0 and g.coins == gc0 + 25, "collect: the host pays the shop's till to the guest")
	gw.business.deposit(gsh.call(), 15)
	gw.business.withdraw(gsh.call(), 5)
	pump()
	check(int(sh.till) == 10 and g.coins == gc0 + 15, "shop till: put in 15, take out 5 on the host")
	agree(bid, "shop till")
	# the workroom and production orders (B18-DP-01)
	gw.business.works.stock_work(gsh.call(), "plank", 2)
	pump()
	check(int(sh.get("work", {}).get("plank", 0)) == 2, "set aside: 2 planks to the workroom on the host")
	gw.business.works.fetch_work(gsh.call(), "plank", 1)
	pump()
	check(int(sh.get("work", {}).get("plank", 0)) == 1, "bring back: 1 plank from the workroom on the host")
	gw.business.works.shelve(gsh.call(), "plank", 1)
	pump()
	check(not sh.has("work") and int(sh.stock.get("plank", 0)) == 4, "put up from the workroom: on the host's shelf")
	var recs: Array = gw.business.works.recipes()
	check(not recs.is_empty(), "orders: the guest's workbench makes something (%d recipes)" % recs.size())
	if not recs.is_empty():
		gw.business.works.add_order(gsh.call(), str(recs[0]), 2)
		pump()
		check(hw.business.works.orders(sh).size() == 1 and str(sh.orders[0].recipe) == str(recs[0]), "order: the host keeps the guest's production order")
		agree(bid, "order")
		gw.business.works.cancel_order(gsh.call(), 0)
		pump()
		check(hw.business.works.orders(sh).is_empty(), "cancel order: the host drops it")
	# a made-up shop record with a till of its own: refused
	var fsh := sh.duplicate(true)
	fsh.till = 900
	var gc1 := g.coins
	for path in ["business.collect", "business.withdraw", "business.hire"]:
		forged(path, [NetActions.enc(hw, fsh)] + ([100] if path == "business.withdraw" else []) + ([hw.business.candidates()[0]] if path == "business.hire" else []))
	check(g.coins == gc1 and hw.total_coins() == coins0, "forged: a made-up copy of the guest's shop with a full till pays nothing")
	check(hw.total_coins() == coins0, "shop: coins conserved")
	check(goods("plank") == planks0, "shop: planks conserved")

	# ---------------------------------------------------------------- the host saves and loads; the guest comes back -------
	var saved: Dictionary = JSON.parse_string(JSON.stringify(hw.to_dict()))
	var hw2 := World.new()
	hw2.load_dict(VillageMap.load_default(), saved)
	check(hw2.load_error == "", "save and load: the host's world loads")
	var g2 := hw2.player_by_pid(g.pid)
	check(g2 != null and hw2.tenant_of(hw2.business.record(pid)) == gref and str(hw2.business.record(bid).get("by", "")) == gref,
		"save and load: the guest's pitch and shop are still the guest's")
	check(js(JSON.parse_string(JSON.stringify(hw2.business.record(pid)))) == js(JSON.parse_string(JSON.stringify(hs))), "save and load: the pitch record is kept whole")
	var old_hw := hw
	hw = hw2
	g = g2
	g.away = false                            # the guest has rejoined (NetSession puts it into play)
	g.pos = hw.business.use_cell(hw.business.record(pid))
	connect_guest()
	agree(pid, "after the host's load and the guest's rejoin")
	var hs2: Dictionary = hw.business.record(pid)
	var stock_b := int(hs2.stock.get("plank", 0))
	gw.business.list_item(gw.business.record(pid), "plank", 1)
	pump()
	check(int(hs2.stock.get("plank", 0)) == stock_b + 1, "after the load: the guest still runs its stall")
	# giving up the pitch: goods and till come back
	var c1 := g.coins
	var till1 := int(hs2.till)
	coins0 = hw.total_coins()
	planks0 = goods("plank")
	gw.business.close(gw.business.record(pid))
	pump()
	check(hw.tenant_of(hs2) == "" and g.coins == c1 + till1 and goods("plank") == planks0 and hw.total_coins() == coins0,
		"give up the pitch: the host returns its goods and till to the guest, conserved (%s)" % replies.back().text)
	agree(pid, "give up the pitch")
	g.pos = Vector2(hw.building_door(bid)) + Vector2(0.5, 0.5)
	gw.business.close(gw.business.record(bid))
	pump()
	check(not hw.buildings[bid].has("shop") and hw.total_coins() == coins0 and goods("plank") == planks0, "close the shop: closed on the host, conserved")
	check(not gw.buildings[bid].has("shop"), "close the shop: the guest's copy agrees")
	old_hw.dispose()
	hw.dispose()
	gw.dispose()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## Every management verb a forged guest could send about stall `other` (not its own): each refused, nothing changes.
func forged_all(other: Dictionary) -> void:
	g.pos = hw.business.use_cell(other)
	var snap := js(other)
	var coins_b := hw.total_coins()
	var gc := g.coins
	var gp := g.inv.count("plank") + g.inv.count("bread")
	var raw = NetActions.enc(hw, other)
	var it := str(other.get("stock", {}).keys()[0]) if not other.get("stock", {}).is_empty() else "plank"
	var refused := 0
	var tried := 0
	for req in [["business.unlist", [raw, it, 1]], ["business.collect", [raw]], ["business.deposit", [raw, 5]],
			["business.withdraw", [raw, 5]], ["business.close", [raw]], ["business.pay_arrears", [raw]],
			["business.fetch", [raw, it, 1]], ["business.dismiss", [raw]], ["business.list_item", [raw, "plank", 1]],
			["business.set_price", [raw, it, 1]], ["business.set_display", [raw, it]], ["business.upgrade", [raw]],
			["business.stalls.close", [raw]], ["business.stalls.open", [raw, gref]],
			["business.works.stock_work", [raw, "plank", 1]], ["business.works.fetch_work", [raw, "plank", 1]],
			["business.works.shelve", [raw, "plank", 1]], ["business.works.add_order", [raw, "plank", 1, 0]],
			["business.works.cancel_order", [raw, 0]], ["business.store_item", [raw, "plank", 1]],
			["business.hire", [raw, NetActions.enc(hw, hw.business.candidates()[0])]]]:
		tried += 1
		if not bool(forged(str(req[0]), req[1]).ok):
			refused += 1
	check(refused == tried and js(other) == snap and g.coins == gc and g.inv.count("plank") + g.inv.count("bread") == gp and hw.total_coins() == coins_b,
		"forged: every management verb on %s's stall is refused, nothing changes (%d of %d refused)" % [hw.ref_name(hw.holder_of(other), false), refused, tried])


## A storeroom the guest holds (its leased plot's house and a storeroom module), as business_test builds the host's.
func _guest_room() -> Dictionary:
	var pl: Dictionary = hw.plots[0]
	var box := Rect2i(int(pl.x) - 40, int(pl.y) - 40, int(pl.w) + 80, int(pl.h) + 80)
	for t in hw.trees:                                   # room for the storeroom module, as business_test clears it
		if box.has_point(Vector2i(int(t.x), int(t.y))):
			t.state = "cleared"
			hw.map.set_solid(Vector2i(int(t.x), int(t.y)), false)
	return hw.as_actor(g, func():
		hw.property.lease(pl, gref)
		hw.start_site(pl, "house", gref)
		for id in pl.site.need.duplicate():
			g.inv.add(id, int(pl.site.need[id]))
		hw.deliver(pl, g.inv, gref)
		var c: Construction = hw.construction
		var m: Dictionary = c.place("storage", c.find_module_slot("storage", pl, gref), gref, false, pl)
		for id in m.site.need.duplicate():
			g.inv.add(id, int(m.site.need[id]))
		hw.deliver(m, g.inv, gref)
		return hw.property.building_on(m))


func _free_cell(b: Dictionary, kind: String) -> Vector2i:
	var cells: Array = hw.fitting.floor_set(b).keys()
	cells.sort_custom(func(m: Vector2i, n: Vector2i): return m.y < n.y or (m.y == n.y and m.x < n.x))
	for c: Vector2i in cells:
		if str(hw.as_actor(g, hw.fitting.why_not.bind(b, kind, c))) == "":
			return c
	return Vector2i(-1, -1)
