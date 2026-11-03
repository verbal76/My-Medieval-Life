extends SceneTree
## REGION-NAV-01 Q4 (owner 2026-11-03, option C): self-employed crafters in the settlement economy. A household working on its own
## account (OffMapSettlement.own) is not in any business's workers; it makes goods by its trade's rules from inputs it buys with
## its own working purse, sells them in the settlement's market, and lives on the profit; an independent miner digs a claim of its
## own, never the quarry's. Craft households set up on their own one at a time when short of work and with savings; a failed
## crafter goes back to its trade's business; an ended household's trade is wound up into its estate. Coins and goods are
## conserved (the settlements' audit) through all of it, it saves and loads, and a crafter can be met and traded with while
## offering goods. Pure World. Run headless:
##   godot --headless --path game --script res://tests/settlement_crafter_test.gd

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
	# the data's crafters at the start
	var all_ok := true
	for s: OffMapSettlement in w.regions.list:
		var want: Array = (data.independent as Dictionary).get(s.id, [])
		all_ok = all_ok and s.own.size() == want.size()
		for k in s.own:
			var hid := int(k)
			var in_biz := false
			for t in s.biz:
				if (s.biz[t].workers as Array).has(hid):
					in_biz = true
			all_ok = all_ok and bool(s.hh[hid].alive) and not in_biz and (s.own[k].workers as Array) == [hid]
	check(all_ok, "each settlement starts with the data's self-employed crafters: a household of their own, in no business's workers")
	check(w.regions.audit() == "", "the opening books balance with them (%s)" % w.regions.audit())
	var higham: OffMapSettlement = w.regions.by_id["higham"]
	var garton: OffMapSettlement = w.regions.by_id["garton"]
	var smith_k: String = higham.own.keys()[0]
	var miner_k: String = garton.own.keys()[0]
	var quarry_res0 := JSON.stringify(garton.biz.quarry.reserves) if garton.biz.has("quarry") else ""
	var claim0: int = int(garton.own[miner_k].reserves.get("iron_ore", 0))
	# a month of the settlements' own days, the audit kept every day
	var bad := ""
	for d in range(0, 30):
		w.minutes = float(d) * 1440.0 + 11.0 * 60.0
		w.regions.catch_up(d)
		if bad == "" and w.regions.audit() != "":
			bad = "day %d: %s" % [d, w.regions.audit()]
	check(bad == "", "thirty days with the crafters at work, every day's audit balances (%s)" % bad)
	var earned := 0
	for s: OffMapSettlement in w.regions.list:
		for k in s.own:
			earned += int(s.own[k].get("paid", 0))
	check(earned > 0, "the crafters lived on what they sold: %d coins paid to their households in the month" % earned)
	check(int(garton.own.get(miner_k, {"reserves": {}}).reserves.get("iron_ore", claim0)) < claim0, "Garton's independent miner dug iron ore from their own claim (%d of %d left)" % [int(garton.own.get(miner_k, {"reserves": {}}).reserves.get("iron_ore", claim0)), claim0])
	check(quarry_res0 == "" or JSON.stringify(garton.biz.quarry.reserves) != "" , "(the quarry business keeps its own reserves)")
	# a craft household short of work with savings sets up on its own; not every worker household does
	var wul: OffMapSettlement = w.regions.by_id["wulstead"]
	var own0 := wul.own.size()
	var cand := -1
	for i in wul.hh.size():
		var h: Dictionary = wul.hh[i]
		if bool(h.alive) and str(h.trade) in ["tanner", "cook", "sawyer"] and not wul.own.has(str(i)):
			cand = i
			break
	check(cand >= 0, "Wulstead has a craft household working for a business")
	var h: Dictionary = wul.hh[cand]
	h.low = 2
	wul.gov.coins = int(wul.gov.coins) - 40         # savings for the test, moved within the settlement (never made from nothing)
	h.coins = int(h.coins) + 40
	var coins_before := wul.coins()
	wul._own_week()
	check(wul.own.has(str(cand)) and wul.own.size() == own0 + 1, "two weeks short of work, with savings, it sets up on its own account")
	var still_in := false
	for t in wul.biz:
		if (wul.biz[t].workers as Array).has(cand):
			still_in = true
	check(not still_in and wul.coins() == coins_before, "it leaves its business, and its savings became its working purse: no coin made or lost")
	var others := 0
	for i in wul.hh.size():
		if bool(wul.hh[i].alive) and wul.own.has(str(i)):
			others += 1
	check(others == own0 + 1, "only that household (one a week): the other worker households stay employed")
	# a crafter that has failed goes back to its trade's business
	var o: Dictionary = wul.own[str(cand)]
	o.idle = 99
	var trade_bt := str(o.type)
	wul._own_week()
	check(not wul.own.has(str(cand)) and (not wul.biz.has(trade_bt) or (wul.biz[trade_bt].workers as Array).has(cand)), "a crafter whose trade failed for weeks goes back to its trade's business")
	# an ended household winds its trade up into its estate
	var s_k: String = higham.own.keys()[0]
	var hid := int(s_k)
	var till := int(higham.own[s_k].till)
	var hcoins := int(higham.hh[hid].coins)
	higham._wind_up_own(higham.hh[hid])
	check(not higham.own.has(s_k) and int(higham.hh[hid].coins) == hcoins + till and w.regions.audit() == "", "a household's own trade wound up goes to it whole: purse to its coins, stock to its pantry, the audit still balances")
	# saved and loaded
	var d := garton.to_dict()
	var back := OffMapSettlement.from_dict(JSON.parse_string(JSON.stringify(d)))
	check(JSON.stringify(back.to_dict()) == JSON.stringify(garton.to_dict()) and back.own.has(miner_k), "a settlement with its crafters saves and loads unchanged")
	var old: Dictionary = JSON.parse_string(JSON.stringify(d))
	old.erase("own")
	var oldback := OffMapSettlement.from_dict(old)
	check(oldback.own.is_empty(), "an older save (no crafters) loads with none, ready for some to set up as the weeks go")
	# met and traded with while offering goods
	var met := {}
	for st: OffMapSettlement in w.regions.list:
		for p in SettlementFolk.people(w, st.id):
			if str(p.role) == "crafter":
				met[p.ref] = p
	check(not met.is_empty(), "the crafters are among the people a visitor can meet (%d)" % met.size())
	var seller := {}
	for d2 in range(30, 60):
		w.minutes = float(d2) * 1440.0 + 11.0 * 60.0
		w.regions.catch_up(d2)
		for st: OffMapSettlement in w.regions.list:
			for p in SettlementFolk.people(w, st.id):
				if str(p.role) == "crafter" and SettlementFolk.present(w, p):
					seller = p
		if not seller.is_empty():
			break
	check(not seller.is_empty(), "a crafter keeps their place on a day they have their own work to sell (%s, %s)" % [seller.get("name", "-"), seller.get("trade", "-")])
	if not seller.is_empty():
		var line: Dictionary = SettlementFolk.offers(w, seller).sells[0]
		w.player.coins = 500
		var v0 := w.total_coins() - w.coin_sources
		check(SettlementFolk.buy_from(w, World.PLAYER, seller, str(line.item), 1) == "", "the player buys a %s from %s, the %s" % [line.item, seller.name, seller.trade])
		check(w.total_coins() - w.coin_sources == v0 and w.regions.audit() == "", "the village's coins and the settlements' audit balance")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
