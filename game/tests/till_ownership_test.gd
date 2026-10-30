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
	test_manor_and_player_keep_till()
	test_every_holder_change()
	test_counter_holder_change()
	test_stall_commission_recorded()
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
	w.set_owner(house, World.hh_ref(n.household))               # the household owns the house outright before it sells it
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


# ------------------------------------------------------------------------------------------------ LE-04 review fixes
## Build 24 review item 7 (TILL-D1: "The household keeps its money ... The next occupant receives an empty till"): a manor-held or
## player-held storefront's till goes to the manor's treasury or that player's own funds when the house changes hands; the next
## holder starts with an empty till. Conserved.
func test_manor_and_player_keep_till() -> void:
	for on in [true, false]:
		var w := new_world(on)
		var n := householder(w)
		var house := open_front(w, n)
		var other := householder(w, n.household)
		var oref := World.hh_ref(other.household)
		w.set_owner(house, World.MANOR)
		w.set_tenant(house, "")
		house.front.till = 17
		var t0 := w.treasury
		var all := w.total_coins()
		w.set_owner(house, oref)
		check(int(house.front.till) == 0 and w.treasury == t0 + 17 and w.total_coins() == all,
				"TILL-D1 (economy %s): a manor-held storefront sold to a household: the manor keeps its 17 coins, the buyer starts empty" % str(on))
		w.set_owner(house, "player")
		house.front.till = 23
		var p0 := w.player.coins
		all = w.total_coins()
		w.set_owner(house, oref)
		check(int(house.front.till) == 0 and w.player.coins == p0 + 23 and w.total_coins() == all,
				"TILL-D1 (economy %s): a player-held storefront handed on: the player keeps its 23 coins, the next holder starts empty" % str(on))
		w.set_owner(house, World.MANOR)
		house.front.till = 8
		t0 = w.treasury
		w.set_tenant(house, oref)
		check(int(house.front.till) == 0 and w.treasury == t0 + 8, "TILL-D1 (economy %s): a manor house let to a tenant: the manor keeps its till" % str(on))


class TillRecorder:
	var w: World
	var calls: Array = []
	func till_flow(till: String, who, amount: int, till_after: int, why: String) -> void:
		calls.append({"till": till, "why": why, "amount": amount, "treasury": w.treasury, "holder": (who.coins if who != null else -1)})
	func stat_moved(_key: String, _n: float, _before: float) -> void:
		pass


## Build 24 review item 6 (REC-DIAG): a stall's settlement records the commission at its own moment (the treasury holding the
## commission only), then the rest (the seller's coins, or the treasury again when it escheats), so the recorder's before/after
## coins of the manor are right.
func test_stall_commission_recorded() -> void:
	var w := new_world(false)
	var s: Dictionary = {}
	for id in w.stalls:
		s = w.stalls[id]
		break
	check(not s.is_empty(), "a market stall exists")
	var rec := TillRecorder.new()
	rec.w = w
	w.recorder = rec
	s.session = {"gross": 100, "sold": {}, "day": w.day(), "hour": 9, "seller": "npc:999999"}     # nobody of theirs left: escheat
	s.till = 100
	s.frac = 0
	var t0 := w.treasury
	var r: Dictionary = w.business.stalls.settle(s)
	w.recorder = null
	var c := int(r.commission)
	var net := int(r.net)
	check(c > 0 and net > 0 and w.treasury == t0 + c + net, "the commission and the escheated rest went to the treasury (%d + %d)" % [c, net])
	var com: Array = rec.calls.filter(func(x): return x.why == "commission")
	var esc: Array = rec.calls.filter(func(x): return x.why == "escheat")
	check(com.size() == 1 and int(com[0].treasury) == t0 + c, "the commission is recorded with the treasury after the commission only (%d, want %d)" % [int(com[0].treasury) if com.size() == 1 else -1, t0 + c])
	check(esc.size() == 1 and int(esc[0].treasury) == t0 + c + net, "the escheat is recorded after the rest arrived")


## Every other way a storefront's holder changes (owner 2026-10-30 follow-through on item 7): eviction for arrears, a dead
## individual holder, a household with nobody left handing on its house, and a guest player; each exactly conserved and the next
## holder starting empty.
func test_every_holder_change() -> void:
	var w := new_world()
	var n := householder(w)
	var house := open_front(w, n)
	var other := householder(w, n.household)
	var oref := World.hh_ref(other.household)
	# eviction for arrears: the manor's house let to a household that cannot pay
	w.set_owner(house, World.MANOR)
	w.set_tenant(house, oref, 50)
	house.front.till = 14
	house.due_day = w.day()
	house.missed = int(GameData.b("rent_evict_missed")) - 1
	for m in w.households[other.household].members:
		var o := w.npc(int(m))
		if o != null:
			o.coins = 0
	var head: NPC = w.party(oref)
	var all := w.total_coins()
	w.property.collect_rents()
	check(w.tenant_of(house) == "" and int(house.front.till) == 0 and head.coins == 14 and w.total_coins() == all,
			"evicted for arrears: the tenant household keeps its 14 coins, the house goes back empty")
	# a dead individual holder: to their household
	var keeper := n
	w.set_owner(house, World.npc_ref(keeper.id))
	house.front.till = 6
	keeper.alive = false
	var hh_head: NPC = w.party(World.hh_ref(keeper.household))
	all = w.total_coins()
	if hh_head != null:
		var c0 := hh_head.coins
		w.set_owner(house, oref)
		check(int(house.front.till) == 0 and hh_head.coins == c0 + 6 and w.total_coins() == all, "a holder who died: the till goes to their household, not the next holder")
	keeper.alive = true
	# a household with nobody left handing on its house (outside household_ended): to the manor
	var hr := World.hh_ref(n.household)
	w.set_owner(house, hr)
	house.front.till = 11
	for m in w.households[n.household].members:
		var o := w.npc(int(m))
		if o != null:
			o.alive = false
	var t0 := w.treasury
	all = w.total_coins()
	w.set_owner(house, oref)
	check(int(house.front.till) == 0 and w.treasury == t0 + 11 and w.total_coins() == all, "nobody of the household left: its till escheats to the manor, the next holder starts empty")


## The same rule for a trade counter's till (B18-DP-01): its money belongs to whom counter_owner named under the previous holder
## (the holding household, else the keeper, else the manor); a change of holder never hands it to the next one.
func test_counter_holder_change() -> void:
	var w := new_world()
	var k := w.tavern_keeper()
	var tav: Dictionary = w.buildings[str(w.stations[k.workplace].building)]
	tav.counter = {"till": 0, "earned": 0, "keeper": k.id}
	var n := householder(w, k.household)
	var hr := World.hh_ref(n.household)
	var other := householder(w, n.household)
	var oref := World.hh_ref(other.household)
	w.set_tenant(tav, "")
	w.set_owner(tav, World.MANOR)
	tav.counter.till = 19
	var k0 := k.coins
	var all := w.total_coins()
	w.set_owner(tav, hr)
	check(int(tav.counter.till) == 0 and k.coins == k0 + 19 and w.total_coins() == all, "a manor tavern sold: its keeper's takings stay the keeper's, the buyer's counter starts empty")
	tav.counter.till = 13
	var head: NPC = w.party(hr)
	var h0 := head.coins
	all = w.total_coins()
	w.set_owner(tav, oref)
	check(int(tav.counter.till) == 0 and head.coins == h0 + 13 and w.total_coins() == all, "sold on: the selling household keeps its counter's 13 coins")
	tav.counter.till = 5
	tav.counter.keeper = 99999
	var t0 := w.treasury
	all = w.total_coins()
	w.set_owner(tav, World.MANOR)
	head = w.party(oref)
	check(int(tav.counter.till) == 0 and w.total_coins() == all, "taken back by the manor: the holder household keeps its till (%d left)" % int(tav.counter.till))
	tav.counter.till = 7
	t0 = w.treasury
	w.set_owner(tav, hr)
	check(int(tav.counter.till) == 0 and w.treasury == t0 + 7, "no keeper left under the manor: the manor keeps it")
