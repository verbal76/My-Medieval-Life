extends SceneTree
## LE-01 till ownership (owner directive 2026-10-27, docs/directives/2026-10-27_complete_expansion20_first.md s.2B): every
## business till that holds coins resolves, in the economy model (EconActor), to the owner the live money rules pay
## (ECON-P3 storefront tills, B18-DP-01 trade-counter tills: BusinessMoney.front_owner / counter_owner, the one rule), and
## its coins are neither lost, duplicated nor handed to the wrong holder: at world start, a new storefront and counter,
## ownership and tenancy transfer, the holder household ending, save/load (old saves too), closure, and sales.
## No business identity is made (D03 FUTURE, OD-LE-04/07): a business is still its till plus its holder.
## Run headless:  godot --headless --path game --script res://tests/till_ownership_test.gd

const ON := {"enabled": true}
var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _init() -> void:
	GameData.ensure()
	test_world_start()
	test_new_storefront_and_sales()
	test_counter()
	test_transfer()
	test_household_ended()
	test_save_load()
	test_closure()
	test_switch_off()
	test_till_d1_migration()
	EconomyFoundation.set_override({})
	print("till_ownership_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func new_world(on := true) -> World:
	EconomyFoundation.set_override(ON if on else {})
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.minutes = 1440.0 + 10.0 * 60.0
	return w


## Every till ref has a controller the model resolves, and the till refs' coins add up to Business.tills (no till the
## census counts is missing from the model, none counted twice).
func audit(w: World, what: String) -> void:
	var e: EconActor = w.economy.actors
	var sum := 0
	var bad: Array = []
	for t in e.till_refs():
		sum += e.coins(t)
		var c := e.controller(t)
		if c == "" or not e.exists(c):
			bad.append(t)
	check(bad.is_empty() and sum == w.business.tills(), "%s: every till has a controller that exists (%s) and the tills add up (%d = %d)" % [what, str(bad), sum, w.business.tills()])


## A household adult whose household holds their house and has room for a storefront.
func householder(w: World, skip := -1) -> NPC:
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 0 and o.household != skip and o.home != "" and w.buildings.has(o.home) \
				and w.holds(World.hh_ref(o.household), w.buildings[o.home]) and w.business.front_place(w.buildings[o.home]).size() > 0:
			return o
	return null


func give(inv: Inventory, c: Dictionary) -> void:
	for id in c:
		inv.add(id, int(c[id]))


## Build the storefront the villagers' way (Business.build_npc_front, materials in hand) and put `n` at its counter.
func open_front(w: World, n: NPC) -> Dictionary:
	var house: Dictionary = w.buildings[n.home]
	give(n.inv, w.business.storefront_cost())
	var built := w.business.build_npc_front(house, n)
	assert(built)
	w.front_keepers[n.home] = n.id
	n.plan.clear()
	n.target = -1
	n.pos = Vector2(int(house.front.use[0]) + 0.5, int(house.front.use[1]) + 0.5)
	return house


# ------------------------------------------------------------------------------------------------ world start
func test_world_start() -> void:
	var w := new_world()
	var e: EconActor = w.economy.actors
	audit(w, "world start")
	var kinds := {}
	for t in e.till_refs():
		kinds[e.kind(t)] = true
		check(e.location(t) != "" and e.profile(t).controller == e.controller(t), "%s: a location and a profile" % t)
	check(kinds.has("stall"), "the stalls' tills are listed")
	check(e.kind("front:b1") == "front" and e.kind("counter:b1") == "counter" and not e.exists("front:nowhere") and e.controller("counter:nowhere") == "", "front:/counter: refs: kinds; an unknown building does not exist")
	check(e.kind("business:b1") == "" and EconActor.BUSINESS_IDENTITY.contains("OD-LE-04"), "still no business identity (D03 FUTURE, OD-LE-04/07)")


# ------------------------------------------------------------------------------------------------ storefront, sales
func test_new_storefront_and_sales() -> void:
	var w := new_world()
	var e: EconActor = w.economy.actors
	var n := householder(w)
	var hr := World.hh_ref(n.household)
	var house := open_front(w, n)
	var ref := "front:" + str(house.id)
	check(e.exists(ref) and e.coins(ref) == 0 and e.controller(ref) == hr and e.till_refs().has(ref), "a new storefront is a till of its household (%s)" % e.controller(ref))
	check(e.location(ref) == str(house.id) and e.judged_person(ref) == JudgmentLive.person_of_ref(w, hr), "located at the house; judged as its household")
	n.inv.add("herbal_poultice", 4)
	w.player.coins += 100
	var all := w.total_coins()
	check(w.business.money.till_ref_for(n) == ref, "a sale by the keeper at the counter goes to that till")
	check(w.trade(w.player, n, "herbal_poultice", 2, 6) and e.coins(ref) == 12 and w.total_coins() == all, "the sale's 12 coins are in the storefront's till, conserved")
	var ev: Dictionary = w.economy.events.ring[w.economy.events.ring.size() - 1]
	check(ev.type == "trade" and ev.note == "till:" + ref and w.economy.needs.dirty.has(hr), "the model's trade event names the till; its controller's needs are marked")
	audit(w, "after a storefront sale")
	# the daily settlement pays the controller the model names
	house.front.till = 60
	all = w.total_coins()
	var head: NPC = w.party(e.controller(ref))
	var before := head.coins
	w.business.money.daily()
	check(head.coins > before and w.total_coins() == all, "daily(): the till's owner pay goes to the household the model names as controller")


# ------------------------------------------------------------------------------------------------ trade counters
func test_counter() -> void:
	var w := new_world()
	var e: EconActor = w.economy.actors
	var k := w.tavern_keeper()
	var tav: Dictionary = w.buildings[str(w.stations[k.workplace].building)]
	var ref := "counter:" + str(tav.id)
	check(not e.exists(ref), "no counter till before the first sale (an old save the same)")
	k.plan.clear()
	k.target = -1
	k.pos = w.shop_post(k)
	k.inv.add("ale", 4)
	w.player.coins += 100
	var all := w.total_coins()
	check(w.business.money.till_ref_for(k) == ref and w.trade(w.player, k, "ale", 2, 5), "the tavernkeeper sells two ales at the counter")
	check(e.exists(ref) and e.coins(ref) == 10 and w.total_coins() == all and e.till_refs().has(ref), "a new counter till holds the 10 coins")
	var holder := w.holder_of(tav)
	var want := holder if holder != World.MANOR and not World.is_player_ref(holder) and w.party(holder) != null else World.npc_ref(k.id)
	check(e.controller(ref) == want, "counter till controlled by the household holding the building, else its keeper (%s)" % e.controller(ref))
	audit(w, "after a counter sale")
	# held by the manor, keeper alive: the keeper; keeper gone: the manor (escheat), and daily pays exactly that
	var ow: String = tav.get("owner", World.MANOR)
	var tn: String = tav.get("tenant", "")
	w.set_tenant(tav, "")
	w.set_owner(tav, World.MANOR)
	check(e.controller(ref) == World.npc_ref(k.id), "a manor building's counter: its keeper")
	tav.counter.keeper = 99999
	check(e.controller(ref) == World.MANOR, "no keeper left: the manor")
	tav.counter.till = 25
	var t0 := w.treasury
	all = w.total_coins()
	w.business.money.daily()
	check(w.treasury == t0 + 25 and e.coins(ref) == 0 and w.total_coins() == all, "daily(): the manor is paid, as the model said")
	tav.counter.keeper = k.id
	w.set_owner(tav, ow)
	w.set_tenant(tav, tn)


# ------------------------------------------------------------------------------------------------ transfer
func test_transfer() -> void:
	var w := new_world()
	var e: EconActor = w.economy.actors
	var n := householder(w)
	var house := open_front(w, n)
	var ref := "front:" + str(house.id)
	var other := householder(w, n.household)
	var oref := World.hh_ref(other.household)
	house.front.till = 30
	var all := w.total_coins()
	var head: NPC = w.party(World.hh_ref(n.household))
	var c0 := head.coins
	w.set_tenant(house, oref)
	check(e.controller(ref) == oref and e.coins(ref) == 0 and head.coins == c0 + 30 and w.total_coins() == all,
			"TILL-D1: let to another household: the owner household keeps its 30 coins, the tenant starts with an empty till")
	house.front.till = 12
	all = w.total_coins()
	var thead: NPC = w.party(oref)
	var t0 := thead.coins
	w.set_tenant(house, "")
	check(e.coins(ref) == 0 and thead.coins == t0 + 12 and w.total_coins() == all, "TILL-D1: the lease given up or taken back: the tenant household keeps its till")
	house.front.till = 9
	all = w.total_coins()
	var c1 := head.coins
	w.set_owner(house, oref)
	check(e.controller(ref) == oref and e.coins(ref) == 0 and head.coins == c1 + 9 and w.total_coins() == all,
			"TILL-D1: sold to another household: the seller keeps its till, the new owner starts empty")
	w.set_owner(house, "player")
	check(e.controller(ref) == "player" and e.judged_person(ref) == JudgmentLive.person_of_ref(w, "player"), "the player's: the player (their shop keeps its own till)")
	w.set_owner(house, World.MANOR)
	check(e.controller(ref) == World.MANOR, "the manor's: the manor")
	audit(w, "after transfers")


# ------------------------------------------------------------------------------------------------ household ends
func test_household_ended() -> void:
	var w := new_world()
	var e: EconActor = w.economy.actors
	var n := householder(w)
	var h := n.household
	var hr := World.hh_ref(h)
	var house := open_front(w, n)
	var ref := "front:" + str(house.id)
	house.front.till = 37
	var all := w.total_coins()
	var t0 := w.treasury
	for m in w.households[h].members:
		var o := w.npc(int(m))
		if o != null:
			o.alive = false
	check(e.controller(ref) == World.MANOR, "nobody of the household alive: the till is the manor's (escheat) before the house passes")
	w.property.household_ended(h)
	check(e.coins(ref) == 0 and w.treasury == t0 + 37 and w.total_coins() == all, "household_ended: its storefront till goes to the treasury (ECON-P3: an ended household leaves its till to the manor), conserved")
	check(w.holder_of(house) == World.MANOR and e.controller(ref) == World.MANOR, "the house and its (empty) till are the manor's")
	# regression: the next household to hold the house is not paid the dead household's takings
	var other := householder(w, h)
	var oref := World.hh_ref(other.household)
	w.set_owner(house, oref)
	var head: NPC = w.party(oref)
	head.coins = w.reserve_of(head)
	var before := head.coins
	w.business.money.daily()
	check(head.coins <= before, "the next holder draws nothing of the old household's till")
	audit(w, "after the household ended")
	check(hr != oref, "two households")


# ------------------------------------------------------------------------------------------------ save / load
func test_save_load() -> void:
	var w := new_world()
	var e: EconActor = w.economy.actors
	var n := householder(w)
	var house := open_front(w, n)
	var ref := "front:" + str(house.id)
	house.front.till = 21
	var k := w.tavern_keeper()
	var tav: Dictionary = w.buildings[str(w.stations[k.workplace].building)]
	tav["counter"] = {"till": 14, "keeper": k.id, "earned": 14, "paid": 0}
	var cref := "counter:" + str(tav.id)
	var all := w.total_coins()
	var ctl := [e.controller(ref), e.controller(cref)]
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var e2: EconActor = w2.economy.actors
	check(e2.coins(ref) == 21 and e2.coins(cref) == 14 and [e2.controller(ref), e2.controller(cref)] == ctl and w2.total_coins() == all, "round trip: tills, controllers and the village's coins unchanged")
	audit(w2, "after a round trip")
	# an older save: no front till keys, no counter record
	var old: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	(old.buildings[str(house.id)].front as Dictionary).erase("till")
	(old.buildings[str(tav.id)] as Dictionary).erase("counter")
	old.erase("economy")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), old)
	var e3: EconActor = w3.economy.actors
	check(e3.exists(ref) and e3.coins(ref) == 0 and e3.controller(ref) == World.hh_ref(n.household) and not e3.exists(cref), "an older save: the storefront's till reads empty and has its holder; no counter till")
	audit(w3, "an older save")


# ------------------------------------------------------------------------------------------------ closure
func test_closure() -> void:
	var w := new_world()
	var e: EconActor = w.economy.actors
	# the player's shop (Business.close): its till goes back to the player and the shop: ref goes with it
	var hid := ""                                     # a house with room for a counter, made the player's for the test
	var ids: Array = w.buildings.keys()
	ids.sort()
	for id in ids:
		if str(w.buildings[id].get("type", "")) == "house" and not w.buildings[id].has("front") and w.business.front_place(w.buildings[id]).size() > 0:
			hid = str(id)
			break
	var b: Dictionary = w.buildings[hid]
	w.set_owner(b, w.acting_ref())
	w.set_tenant(b, "")
	give(w.player.inv, w.business.storefront_cost())
	var why := w.business.build_storefront(b)
	check(why == "" and b.has("shop") and e.exists("shop:" + hid) and e.controller("shop:" + hid) == "player", "the player's storefront opens a shop with its own till (%s)" % why)
	b.shop.till = 9
	var all := w.total_coins()
	var pc := w.player.coins
	w.business.close(b.shop, "closed")
	check(not e.exists("shop:" + hid) and w.player.coins >= pc + 9 and w.total_coins() == all, "closing: the shop's till goes to the player; nothing is lost")
	check(e.exists("front:" + hid) and e.coins("front:" + hid) == 0, "the storefront stays standing with an empty till")
	audit(w, "after closure")


# ------------------------------------------------------------------------------------------------ switch off
func test_switch_off() -> void:
	var w := new_world(false)
	check(w.economy == null, "off: no model")
	var n := householder(w)
	var house := open_front(w, n)
	house.front.till = 11
	var all := w.total_coins()
	var t0 := w.treasury
	for m in w.households[n.household].members:
		var o := w.npc(int(m))
		if o != null:
			o.alive = false
	w.property.household_ended(n.household)
	check(w.treasury == t0 + 11 and BusinessMoney.till_of(house) == 0 and w.total_coins() == all, "off: the live rule is the same (the economy model is not needed for the escheat)")


# ------------------------------------------------------------------------------------------------ TILL-D1: moving away
## Owner 2026-10-28: a household that moves keeps its money: its storefront till goes to its own funds and leaves the village with it.
func test_till_d1_migration() -> void:
	var w := new_world()
	var n := householder(w)
	var h := n.household
	var house := open_front(w, n)
	house.front.till = 41
	var s: OffMapSettlement = w.regions.by_id["wulstead"]
	var ms: Array = w.brain._members(h)
	var carried := 41
	for o: NPC in ms:
		carried += o.coins
	var src0 := w.coin_sources
	var t0 := w.treasury
	var ok := Migration._household_out(w, s, ms, true, "hunger", Migration.hiring(s) if Migration.hiring(s) != "" else "farm")
	check(ok, "TILL-D1: the household leaves for Wulstead")
	check(int(house.front.get("till", 0)) == 0 and w.treasury == t0, "TILL-D1: its till went with it, not to the manor")
	check(src0 - w.coin_sources == carried, "TILL-D1: the coins that crossed are its purses and its till (%d)" % carried)
