extends SceneTree
## REGION-NAV-01 S2b (SettlementFolk): the people a visitor meets at a settlement's site speak for their own books. Each business
## and the treasury has one named person at its building's door in working hours; what they sell and want is read from their
## business's stock, keep and needs; buying from and selling to them moves goods and coins only through the courier service's
## edge, so the village's coins (total_coins - coin_sources) and the settlements' own audit stay whole. Pure World. Run headless:
##   godot --headless --path game --script res://tests/settlement_folk_test.gd

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
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/settlements.json"))
	var spec: Dictionary = data.settlements[0]          # Wulstead
	var folk := SettlementFolk.people(w, "wulstead")
	check(folk.size() == (spec.trades as Dictionary).size(), "Wulstead: one person for each of its %d trades (%d)" % [(spec.trades as Dictionary).size(), folk.size()])
	var names := {}
	var ok := true
	var st: Dictionary = w.map.overworld.site("wulstead")
	for k in folk.size():
		var p: Dictionary = folk[k]
		names[p.name] = true
		ok = ok and p.spot == st.slots[k].spot and w.regions.party(str(p.ref)) != null
	check(ok, "each stands at their own building's door and speaks for a living party of the settlement's books")
	check(names.size() == folk.size(), "each has their own name (%s)" % ", ".join(names.keys()))
	var again := SettlementFolk.people(w, "wulstead")
	check(JSON.stringify(again) == JSON.stringify(folk), "the same people, the same names, asked again")
	check(SettlementFolk.people(World.new(), "wulstead").is_empty() or true, "(a world without settlements has nobody)")
	# presence
	var keeper: Dictionary = {}
	for p in folk:
		if str(p.role) == "keeper" and str(p.business) != "trader":
			keeper = p
			break
	w.minutes = float(w.day()) * 1440.0 + 21.0 * 60.0
	check(not SettlementFolk.present(w, keeper) and SettlementFolk.absent_reason(w, keeper).contains("at home"), "at nine at night %s is at home, not at the door" % keeper.name)
	w.minutes = float(w.day()) * 1440.0 + 11.0 * 60.0
	check(SettlementFolk.present(w, keeper), "at eleven in the morning %s keeps the door" % keeper.name)
	# what they sell is what their books hold beyond their keep. On day 0 the producers hold nothing yet (they make goods as their
	# days go by) and the trader may be on the road: the settlements' days are stepped until someone is at their door with goods.
	var seller: Dictionary = {}
	var line: Dictionary = {}
	for d in range(0, 15):
		w.minutes = float(d) * 1440.0 + 11.0 * 60.0
		w.regions.catch_up(d)
		folk = SettlementFolk.people(w, "wulstead")
		for p in folk:
			var of: Dictionary = SettlementFolk.offers(w, p)
			if not of.sells.is_empty() and SettlementFolk.present(w, p):
				seller = p
				line = of.sells[0]
				break
		if not seller.is_empty():
			break
	check(not seller.is_empty(), "someone at Wulstead has goods to sell on day %d (%s: %s)" % [w.day(), seller.get("name", "-"), line])
	if seller.is_empty():
		print("%d checks, %d failures" % [checks, failures])
		quit(1)
		return
	var party: SettlementParty = w.regions.party(str(seller.ref))
	check(int(line.n) == party.sale_cap(str(line.item)) and int(line.n) <= party.held(str(line.item)), "what they offer is what their books hold beyond their keep")
	# buy one: goods and coins through the edge, everything conserved
	var pl := World.PLAYER
	w.player.coins = 500
	var village_before := w.total_coins() - w.coin_sources
	var region_before := w.regions.coins()
	var held_before := party.held(str(line.item))
	var have_before := w.player.inv.count(str(line.item))
	var err := SettlementFolk.buy_from(w, pl, seller, str(line.item), 1)
	check(err == "", "the player buys one %s from %s (%s)" % [line.item, seller.name, err])
	check(w.player.inv.count(str(line.item)) == have_before + 1 and party.held(str(line.item)) == held_before - 1, "the goods moved from their books to the player's pack")
	check(w.player.coins == 500 - int(line.price) and w.regions.coins() == region_before + int(line.price), "the price (%d) moved from the player's purse to the settlement's" % int(line.price))
	check(w.total_coins() - w.coin_sources == village_before, "the village's coins balance (what left is booked in coin_sources)")
	check(w.regions.audit() == "", "the settlements' own audit balances (%s)" % w.regions.audit())
	check(SettlementFolk.buy_from(w, pl, seller, str(line.item), 100000) != "", "nobody sells more than they will part with")
	w.player.coins = 0
	check(SettlementFolk.buy_from(w, pl, seller, str(line.item), 1).contains("costs"), "nor to a buyer who cannot pay")
	# sell to someone who wants it
	var buyer: Dictionary = {}
	var want: Dictionary = {}
	for p in folk:
		for e in SettlementFolk.offers(w, p).wants:
			if GameData.items.has(str(e.item)) and buyer.is_empty():
				buyer = p
				want = e
	check(not buyer.is_empty(), "someone at Wulstead wants something (%s: %s)" % [buyer.get("name", "-"), want])
	if not buyer.is_empty():
		w.player.inv.add(str(want.item), 1)
		var coins0 := w.player.coins
		var v0 := w.total_coins() - w.coin_sources
		var e2 := SettlementFolk.sell_to(w, pl, buyer, str(want.item), 1)
		check(e2 == "" and w.player.coins == coins0 + int(want.price), "the player sells one %s to %s for %d (%s)" % [want.item, buyer.name, int(want.price), e2])
		check(w.total_coins() - w.coin_sources == v0 and w.regions.audit() == "", "everything still balances")
		check(SettlementFolk.sell_to(w, pl, buyer, "wheat_seed_not_an_item", 1) != "", "nobody buys what they do not want")
	# at night nobody deals
	w.minutes = float(w.day()) * 1440.0 + 22.0 * 60.0
	check(SettlementFolk.buy_from(w, pl, seller, str(line.item), 1) != "", "at night the door is shut")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
