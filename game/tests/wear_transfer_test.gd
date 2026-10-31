extends SceneTree
## X20-WEAR-TRANSFER (defect found by Worker A): a tool's wear travels with it when it changes hands, so a worn tool never becomes
## as good as new by being sold, given, stored, inherited, looted, stolen back or shipped. One worn axe (5 uses left of its full
## durability) is the only one its holder has, so it is the one that moves; after each path the receiver's axe has 5 uses left and
## the number of axes in the world is unchanged. Also: part of a stack moving (the unused ones go, the worn one stays, as before),
## two worn units joined (their remaining uses kept together, at least 1), and a shipment's wear kept through a save. No new
## mechanic: wear values, rates and breakage are as they were.
## Run headless:  godot --headless --path game --script res://tests/wear_transfer_test.gd

const T := "axe"
const LEFT := 5
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
	EconomyFoundation.set_override({})
	test_trade_and_transfer()
	test_authority()
	test_gifts()
	test_stall()
	test_contract()
	test_inheritance_and_loot()
	test_theft_and_containers()
	test_stacks()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ------------------------------------------------------------------------------------------------ helpers
func new_world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


func adults(w: World) -> Array:
	return w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.household >= 0)


func full() -> int:
	return int(GameData.item(T).durability)


## Make `inv` hold exactly one axe, worn to LEFT uses.
func worn(inv: Inventory) -> void:
	inv.remove(T, inv.count(T))
	inv.add(T, 1)
	inv.durability[T] = LEFT


func clear(inv: Inventory) -> void:
	inv.remove(T, inv.count(T))


func left(inv: Inventory) -> int:
	return int(inv.durability.get(T, full())) if inv.has(T) else -1


## Every axe in the world (every holder, the settlements, transit).
func axes(w: World) -> int:
	return int(SettlementHoldings.goods(w).get(T, 0)) + int(w.regions.goods().get(T, 0)) + int(w.transactions.in_transit().goods.get(T, 0))


func guest(w: World) -> PlayerState:
	var g := PlayerState.new()
	g.name = "Gwen"
	g.family = "Fairlight"
	g.sex = "female"
	g.born = w.player.born
	Identity.register_player(w, g)
	w.give_start_kit(g)
	g.pos = w.player.pos + Vector2(1, 0)
	g.net_key = "ab".repeat(32)
	w.add_guest(g)
	return g


# ------------------------------------------------------------------------------------------------ paths
func test_trade_and_transfer() -> void:
	var w := new_world()
	var a: NPC = adults(w)[0]
	var b: NPC = adults(w)[1]
	worn(a.inv)
	clear(w.player.inv)
	w.player.coins = 100
	var n0 := axes(w)
	check(w.trade(w.player, a, T, 1, 3), "World.trade: the player buys a villager's only axe")
	check(left(w.player.inv) == LEFT and axes(w) == n0, "World.trade: the worn axe arrives worn (%d of %d uses left)" % [left(w.player.inv), full()])
	worn(a.inv)
	clear(b.inv)
	n0 = axes(w)
	check(w.transfer(a.inv, b.inv, T, 1) and left(b.inv) == LEFT and not a.inv.durability.has(T) and axes(w) == n0, "World.transfer: the wear goes with it (%d left)" % left(b.inv))


func test_authority() -> void:
	var w := new_world()
	var tx := w.transactions
	var a: NPC = adults(w)[0]
	var b: NPC = adults(w)[1]
	w.treasury += 100
	worn(a.inv)
	clear(w.granary)
	var n0 := axes(w)
	check(tx.exchange("wear:1", World.MANOR, World.npc_ref(a.id), T, 1, 3).ok and left(w.granary) == LEFT and axes(w) == n0,
		"transactions.exchange: the manor buys a worn axe, worn (%d left)" % left(w.granary))
	worn(a.inv)
	clear(b.inv)
	b.coins = 50
	n0 = axes(w)
	check(tx.ship("wear:2", World.npc_ref(b.id), World.npc_ref(a.id), T, 1, 2, w.day() + 1).ok, "transactions.ship: a worn axe into transit custody")
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	check(tx.deliver("wear:2").ok and left(b.inv) == LEFT and axes(w) == n0, "transactions.deliver: it arrives worn (%d left)" % left(b.inv))
	var b2 := w2.npc(b.id)
	clear(b2.inv)
	check(w2.transactions.deliver("wear:2").ok and left(b2.inv) == LEFT, "... and so after a save and load in transit (%d left)" % left(b2.inv))
	worn(a.inv)
	check(tx.ship("wear:3", World.npc_ref(b.id), World.npc_ref(a.id), T, 1, 2, w.day() + 1).ok and tx.fail("wear:3", "test").ok and left(a.inv) == LEFT,
		"transactions.fail: it comes back to the seller still worn (%d left)" % left(a.inv))


func test_gifts() -> void:
	var w := new_world()
	var g := guest(w)
	worn(w.player.inv)
	clear(g.inv)
	var n0 := axes(w)
	check(w.player_offer("gift", g.pid, T, 1) == "", "a gift offered to another player")
	var o: Dictionary = w.offers_to(g)[0]
	check(w.player_answer(int(o.id), true, g) == "" and left(g.inv) == LEFT and axes(w) == n0, "a gift between players: worn (%d left)" % left(g.inv))
	worn(g.inv)
	clear(w.player.inv)
	w.player.coins = 100
	check(w.as_actor(g, func(): return w.player_offer("sell", w.host_player().pid, T, 1, null, 4)) == "", "a sale offered between players")
	var o2: Dictionary = w.offers_to(w.player)[0]
	check(w.player_answer(int(o2.id), true) == "" and left(w.player.inv) == LEFT, "a sale between players (multiplayer offers): worn (%d left)" % left(w.player.inv))
	var n: NPC = adults(w)[2]
	clear(n.inv)
	worn(w.player.inv)
	w.relations.give(Life.PLAYER_ID, n, T, 1)
	check(left(n.inv) == LEFT, "a gift to a villager: worn (%d left)" % left(n.inv))


func test_stall() -> void:
	var w := new_world()
	var bz: Business = w.business
	w.player.coins = 200
	check(bz.rent() == "", "the player rents a pitch")
	var s := bz.mine()
	worn(w.player.inv)
	check(bz.list_item(s, T, 1) == "" and int(s.stock.get(T, 0)) == 1, "the worn axe put up for sale")
	check(bz.unlist(s, T, 1) == "" and left(w.player.inv) == LEFT, "taken back from the stall: still worn (%d left)" % left(w.player.inv))
	bz.list_item(s, T, 1)
	var n: NPC = adults(w)[0]
	clear(n.inv)
	n.coins = 100
	var n0 := axes(w)
	check(bz.sell(s, n, T, 1, 5) and left(n.inv) == LEFT and axes(w) == n0, "sold from the stall to a villager: worn (%d left)" % left(n.inv))
	worn(w.player.inv)
	bz.list_item(s, T, 1)
	bz.close(s)
	check(left(w.player.inv) == LEFT, "the stall closed: the axe back in the pack, worn (%d left)" % left(w.player.inv))


func test_contract() -> void:
	var w := new_world()
	var g := guest(w)
	g.coins = 50
	worn(w.player.inv)
	clear(g.inv)
	var c = w.contracts.open_between(w.player_ref(g), World.PLAYER, T, 1, 3, 2)
	check(c is Dictionary, "a contract: the host supplies the guest an axe")
	if c is Dictionary:
		check(w.contracts.deliver(c, 1) == 1 and left(g.inv) == LEFT, "delivered on the contract: worn (%d left)" % left(g.inv))


func test_inheritance_and_loot() -> void:
	var w := new_world()
	var a: NPC = null
	var h: NPC = null
	for n: NPC in adults(w):
		h = w._heir(n)
		if h != null:
			a = n
			break
	check(a != null, "a villager with an heir")
	if a != null:
		worn(a.inv)
		clear(h.inv)
		var n0 := axes(w)
		w.kill(a, "fever")
		check(left(h.inv) == LEFT and axes(w) == n0, "inherited: worn (%d left)" % left(h.inv))
	var v: NPC = adults(w)[3]
	worn(v.inv)
	var n1 := axes(w)
	w.kill(v, "slain")
	var l: Dictionary = w.loot[w.loot.size() - 1]
	check(left(l.inv) == LEFT and axes(w) == n1, "a slain villager's goods lie as loot, worn (%d left)" % left(l.inv))
	clear(w.player.inv)
	w.player.pos = l.pos
	w._player_loot(w.loot.size() - 1)
	check(left(w.player.inv) == LEFT and axes(w) == n1, "looted: worn (%d left)" % left(w.player.inv))
	var k := w.loot.size()
	w.player_drop(T, 1)
	check(w.loot.size() == k + 1 and left(w.loot[k].inv) == LEFT, "dropped: worn on the ground (%d left)" % left(w.loot[k].inv))
	worn(w.player.inv)
	k = w.loot.size()
	w.continue_as_heir()
	check(w.loot.size() == k + 1 and left(w.loot[k].inv) == LEFT, "the player's death: what they carried lies worn for the heir (%d left)" % left(w.loot[k].inv))


func test_theft_and_containers() -> void:
	var w := new_world()
	var owner: NPC = adults(w)[0]
	var g: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.job == "guard":
			g = n
	clear(owner.inv)
	worn(w.player.inv)
	w.player.mark_stolen(T, owner.id, 1)
	w.guard_confront(g, {T: 1}, null, owner)
	check(left(owner.inv) == LEFT, "stolen goods given back by the guard: worn (%d left)" % left(owner.inv))
	var c: Dictionary = {}
	for x in w.containers:
		var st: Inventory = w.container_store(x)
		if st != null and str(x.kind) != "table":
			c = x
			break
	check(not c.is_empty(), "a container")
	if c.is_empty():
		return
	var store: Inventory = w.container_store(c)
	store.items.clear()
	store.durability.clear()
	worn(store)
	clear(w.player.inv)
	w.player.pos = Vector2(float(c.x) + 0.5, float(c.y) + 1.5) if c.has("x") else w.player.pos
	var r := w._player_take(c)
	check(r != "far" and left(w.player.inv) == LEFT, "taken from a container: worn (%s; %d left)" % [r, left(w.player.inv)])


func test_stacks() -> void:
	var w := new_world()
	var a: NPC = adults(w)[0]
	var b: NPC = adults(w)[1]
	a.inv.remove(T, a.inv.count(T))
	a.inv.add(T, 3)
	a.inv.durability[T] = LEFT
	clear(b.inv)
	w.transfer(a.inv, b.inv, T, 1)
	check(left(a.inv) == LEFT and not b.inv.durability.has(T), "one of three moves: an unused one goes, the worn one stays (as before)")
	worn(a.inv)
	a.inv.durability[T] = full() - 20
	b.inv.durability[T] = full() - 10
	w.transfer(a.inv, b.inv, T, 1)
	check(b.inv.count(T) == 2 and left(b.inv) == full() - 30, "a worn axe joins a stack with a worn one: their remaining uses kept together (%d left)" % left(b.inv))
	worn(a.inv)
	b.inv.durability[T] = 2
	w.transfer(a.inv, b.inv, T, 1)
	check(left(b.inv) == 1 and b.inv.count(T) == 3, "two nearly worn out joined: at least 1 left, nothing breaks in a transfer")
