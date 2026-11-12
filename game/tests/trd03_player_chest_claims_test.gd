extends SceneTree
## TRD-03 (Build 25 audit, WP-1): EconActor.count reads a player's pack AND family chest, while a transaction
## (EconTransactions._held/_goods_out) moves goods from the pack only. A claim (EconReservations.reserve, through
## EconActor.holding) backed by chest goods could therefore promise what no transfer can deliver.
## Reachability, from the code: a goods claim is made only by an ask offer (EconOffers.post, called by EconMarket for villagers
## only) or a contract earmark (EconContractLinks.earmark, for the contract's seller, who is always the villager answering:
## Contracts.evaluate takes an NPC) or, where a player sells (Contracts.offer_to_player, open_between), a record with no craft route, which earmarks nothing (EconClaims.on_contract_open). A player's coins are claimed only as coins (EconActor.coins, the purse: no chest). So no game
## path makes a goods claim for a player and the mismatch is unreachable; no change. The test is the evidence and the guard: a
## player with goods in the chest only, through a real day of the market, gets no goods claim and no ask offer; it also measures
## (printed, not checked) what the API would do if a later feature let a player post one.
##   godot --headless --path game --script res://tests/trd03_player_chest_claims_test.gd

const STEP := 0.5

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL: ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	GameData.ensure()
	test_no_player_goods_claims()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func player_claims(w: World, pref: String) -> Array:
	var out := []
	for id in w.economy.reservations.records:
		var r: Dictionary = w.economy.reservations.records[id]
		if str(r.owner) == pref and str(r.item) != EconReservations.COINS:
			out.append(r)
	return out


func player_asks(w: World, pref: String) -> Array:
	var out := []
	for id in w.economy.offers.records:
		var o: Dictionary = w.economy.offers.records[id]
		if str(o.actor) == pref:
			out.append(o)
	return out


func test_no_player_goods_claims() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	check(w.economy != null and w.economy.market.drive, "fixture: the Living Economy drives its market")
	if w.economy == null:
		return
	var pref := World.PLAYER
	var item := "bread"
	w.player.chest.add(item, 20)
	w.player.chest.add("plank", 20)
	check(w.economy.actors.count(pref, item) == w.player.inv.count(item) + 20, "fixture: the economy counts the player's chest goods (%d)" % w.economy.actors.count(pref, item))
	var per_day := int(1440.0 / float(GameData.b("game_minutes_per_second")) / STEP)
	for s in per_day:
		w.update(STEP)
	check(player_claims(w, pref).is_empty(), "a day of the market makes no goods claim for the player (%d)" % player_claims(w, pref).size())
	check(player_asks(w, pref).is_empty(), "and posts no offer for the player (%d)" % player_asks(w, pref).size())
	# a villager's offer to the player (Contracts.offer_to_player) makes the player a contract's seller; its record has no
	# craft route, so opening it earmarks nothing (EconClaims.on_contract_open acts on route "craft" only)
	var mine: Array = w.contracts.list.filter(func(c): return str(c.seller) == pref)
	check(mine.all(func(c): return str(c.get("route", "")) != "craft"), "no contract the player sells on has a craft route (%d such contracts)" % mine.size())
	var c0: Dictionary = {}
	for c in mine:
		if str(c.state) == "offered" and not w.contracts.is_service(c):
			c0 = c
			break
	if not c0.is_empty():
		w.player.chest.add(str(c0.item), int(c0.qty))
		var why: String = w.contracts.accept_offer(c0)
		print("accepting the villager's offer of contract %d (%s): %s" % [int(c0.id), str(c0.item), "opened" if why == "" else why])
		check(player_claims(w, pref).is_empty(), "the player's accepted or offered contracts make no goods claim on the chest (%d)" % player_claims(w, pref).size())
	else:
		print("no goods offer to the player on day %d to accept" % w.day())
	# measurement only: what the API itself would do with a player's chest-only goods (no game path calls it)
	var held_pack := w.player.inv.count(item)
	var r: Dictionary = w.economy.offers.post(EconOffers.ASK, pref, item, held_pack + 5, 1, w.day() + 2)
	var npc: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.coins >= 50:
			npc = o
			break
	var t: Dictionary = {}
	if npc != null:
		t = w.transactions.exchange(w.transactions.next_txid("test"), World.npc_ref(npc.id), pref, item, held_pack + 5, held_pack + 5)
	print("TRD-03 API measurement (no game path): an ask for %d %s backed by the chest: post ok=%s; a transfer of them from the player: ok=%s (%s)"
		% [held_pack + 5, item, str(r.get("ok", false)), str(t.get("ok", false)), str(t.get("code", t.get("reason", "")))])
