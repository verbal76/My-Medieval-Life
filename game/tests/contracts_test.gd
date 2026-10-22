extends SceneTree
## CON-01 (owner directive 2026-10-21 section 5; OD-29 defaults): negotiated goods-procurement contracts. An offer is
## judged by the seller from real signals (tools, skill, sources, time, price against the going price and its needs,
## obligations) and accepted, refused with the reason, or countered; the buyer's coins are set aside at acceptance and
## counted; partial deliveries are paid unit by unit; a contract lapses at its deadline with the coins returned and
## regard lost; either side may cancel (delivered units stay paid); a party's death ends it; NPC to NPC and NPC to
## player use the same module; contracts are saved and loaded with nothing duplicated. Every coin and good only moves.
##   godot --headless --path game --script res://tests/contracts_test.gd

const Census := preload("res://tests/census.gd")

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
	test_accept_and_reserve()
	test_reject_by_real_signals()
	test_counteroffers()
	test_partial_delivery()
	test_lapse()
	test_cancellation()
	test_villager_works_toward_it()
	test_npc_to_npc()
	test_npc_offer_to_player()
	test_death_of_a_party()
	test_save_and_load()
	test_parity()
	test_evaluation_terms()
	test_time_counter()
	test_buyer_answers()
	test_npc_meets_counter()
	test_player_counters_npc_offer()
	test_offer_saved_and_older_saves()
	test_determinism()
	test_signing()
	# the talk window, in the game itself (its buttons are what touch, pad and keyboard press)
	DirAccess.make_dir_recursive_absolute("user://test_saves/contracts_test")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	if main.get_script() == null or not main.has_method("interact"):
		check(false, "the game's main script loads")
		quit(1)
		return
	main.save_path = "user://test_saves/contracts_test/save1.json"     # never the player's own save
	process_frame.connect(test_window, CONNECT_ONE_SHOT)


var main


func _buttons(node: Node, out: Array) -> Array:
	for c in node.get_children():
		if c is Button:
			out.append(c)
		_buttons(c, out)
	return out


func _press(text: String) -> bool:
	for b: Button in _buttons(main.ui.panel_body, []):
		if b.text.begins_with(text) and not b.disabled:
			b.pressed.emit()
			return true
	return false


## Press the button `text` (exactly) on the row whose label begins with `row` ("Quantity", "Price each", "Days").
func _press_on(row: String, text: String) -> bool:
	for h in main.ui.panel_body.find_children("*", "HBoxContainer", true, false):
		if not h.get_children().any(func(x): return x is Label and (x as Label).text.begins_with(row)):
			continue
		for b in h.get_children():
			if b is Button and b.text == text and not b.disabled:
				b.pressed.emit()
				return true
	return false


func _shows(text: String) -> bool:
	for l in main.ui.panel_body.find_children("*", "Label", true, false):
		if (l as Label).text.contains(text):
			return true
	return false


## The player proposes through the talk window: "Propose a contract", the goods, the terms with - and +, Propose; a
## too-low price is countered and the counter agreed to; the open contract is listed and its goods collected.
func test_window() -> void:
	main.new_game()
	var w: World = main.world
	var ui = main.ui
	var m := miner(w)
	m.inv.remove("iron_ore", m.inv.count("iron_ore"))
	w.player.coins = 300
	ui.show_talk(m)
	check(_press("Propose a contract") and ui.is_open("contract"), "the talk offers \"Propose a contract\", which opens the contract window")
	check(_shows("Step 1 of 5") and _press("★ Iron ore"), "step one lists the goods the miner can come by first, iron ore among them")
	check(_shows("Step 2 of 5") and _shows("Quantity:"), "choosing the goods moves on to the quantity step")
	var c0 := coins(w)
	for i in 12:     # each press redraws the window; 1 is the least
		_press_on("Quantity", "-1")
	check(_shows("Quantity: 1"), "the quantity is set with - and +")
	check(_press_on("Quantity", "+10") and _shows("Quantity: 11"), "+10 raises the quantity")
	check(_press("Next") and _shows("Step 3 of 5") and _shows("Price each:"), "Next moves to the price step")
	for i in 60:
		_press_on("Price each", "-1")
	check(_shows("Price each: 1"), "the price is set with - and +")
	check(_press("Next") and _shows("Step 4 of 5") and _shows("Days:"), "Next moves to the days step")
	for i in 5:
		_press_on("Days", "-1")
	check(_press_on("Days", "+1") and _shows("Days: 2"), "+1 gives the seller another day")
	check(_press("Next") and _shows("Step 5 of 5") and _shows("%s delivers 11 iron ore by the end of day %d for 11 coins (1 each)." % [m.name, w.day() + 2]),
			"the summary says the agreement in one sentence")
	check(_press("Back") and _shows("Step 4 of 5") and _shows("Days: 2") and _press("Back") and _shows("Step 3 of 5") and _shows("Price each: 1"),
			"Back returns to each step before, with its terms kept")
	check(_press("Next") and _press("Next") and _shows("Step 5 of 5"), "and forward again to the summary")
	check(ui.inner_back.is_valid() and ui.inner_back.call() and _shows("Step 4 of 5") and _press("Next") and _shows("Step 5 of 5"), "Esc, X and the pad's B step back one step before closing the window")
	check(w.contracts.list.is_empty(), "nothing exists until Propose")
	check(_press("Propose") and _shows("least I'd take"), "a price of 1 is countered with the miner's least price")
	check(w.contracts.list.is_empty() and coins(w) == c0, "nothing is set aside for a counteroffer")
	check(_press("Agree:") and w.contracts.open_of(World.PLAYER, "buyer").size() == 1, "agreeing to the counter opens the contract")
	var c: Dictionary = w.contracts.open_of(World.PLAYER, "buyer")[0] if not w.contracts.open_of(World.PLAYER, "buyer").is_empty() else {}
	check(not c.is_empty() and _shows("You buy %d iron ore" % int(c.qty)) and coins(w) == c0, "the window lists it; coins only moved")
	m.inv.add("iron_ore", 2)
	ui.show_contract(m)
	var p0 := w.player.inv.count("iron_ore")
	check(_press("Collect 2") and w.player.inv.count("iron_ore") == p0 + 2 and int(c.delivered) == 2, "the player collects what the miner holds, paid on delivery")
	check(_press("Cancel") and str(c.state) == "cancelled" and coins(w) == c0, "and may cancel: the rest comes back")
	ui.show_talk(m)
	check(_press("Propose a contract"), "with nothing open the choice reads \"Propose a contract\" again")
	# a villager's standing order to the player, countered in the window (NPC to player, counters both ways)
	var smith: NPC = w.brain._first_with_job("smith")
	smith.coins = 5000
	w.player.pos = smith.pos
	var off: Dictionary = w.contracts.offer_to_player(smith, "coal", 10, 8, 3)
	ui.show_contract(smith)
	check(_shows("asks you for 10 coal") and _press("Counter"), "the offer is listed with Agree, Counter and Decline")
	check(_shows("Step 1 of 4") and _shows("Quantity: 10") and _press("Next"), "a counter starts at the quantity: the goods are the villager's")
	for i in 20:
		_press_on("Price each", "+1")
	check(_shows("Price each: 28") and _press("Next") and _press("Next") and _shows("You deliver 10 coal to") and _press("Put these terms"), "the player raises the price and puts the terms back")
	check(str(off.state) == "offered" and int(off.price_each) == floori(8 * float(Contracts.cfg().npc_counter_tolerance)) and _shows("most I'd pay"),
			"the smith counters with the most it pays; the offer now stands on those terms")
	check(_press("Agree") and str(off.state) == "accepted" and int(off.reserved) == 10 * int(off.price_each), "agreeing to it face to face opens the contract")
	# CON-02: hiring a villager for work in the same window (a service the game performs: digging the player's pit)
	var site := Vector2i(-1, -1)
	for y in w.map.h:
		for x in w.map.w:
			if site.x < 0 and w.pits.site_open(Vector2i(x, y)) and w.pits.site_refusal(Vector2i(x, y)) == "":
				site = Vector2i(x, y)
	var pit := w.pits.open_pit(World.PLAYER, site) if site.x >= 0 else {}
	var m2 := miner(w)
	if not m2.inv.has("shovel"):
		m2.inv.add("shovel")                      # MIN-E-Q4: a pit's earth is dug with a shovel
	w.player.pos = m2.pos
	w.player.coins = 500
	ui.show_contract(m2)
	check(not pit.is_empty() and _press("Dig your open pit") and _shows("Quantity:"), "the window offers to hire the miner to dig the player's open pit")
	var before := w.contracts.open_of(World.PLAYER, "buyer").size()
	_press("Next")
	_press_on("Price each", "+1")
	_press_on("Price each", "+1")
	_press("Next")
	_press("Next")
	check(_shows("does this work for you"), "the work's summary names who does it and for how much")
	_press("Propose")
	var made: Array = w.contracts.open_of(World.PLAYER, "buyer").filter(func(x): return Contracts.is_service(x))
	check(made.size() == 1 or _shows("least I'd take"), "proposing it makes a service contract, or the miner answers with its terms")
	if made.is_empty() and _press("Agree:"):
		made = w.contracts.open_of(World.PLAYER, "buyer").filter(func(x): return Contracts.is_service(x))
	check(made.size() == 1 and w.contracts.open_of(World.PLAYER, "buyer").size() == before + 1 and _shows("works for you"), "the service is listed in the window")
	ui.hide_all()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func new_world(seed := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


func miner(w: World) -> NPC:
	var m: NPC = w.brain._first_with_job("miner")
	if not m.inv.has("pickaxe"):
		m.inv.add("pickaxe")
	w.player.pos = m.pos          # face to face (Q18-13: formal contracts are signed in person); far() parts them
	return m


## Send the player far from everyone (no one is face to face with them).
func far(w: World) -> void:
	w.player.pos = Vector2(2, 2)
	while not w.present(w.player.pos, float(Contracts.cfg().sign_reach)).is_empty():
		w.player.pos += Vector2(3, 0)


func coins(w: World) -> int:
	return w.total_coins() - w.coin_sources


func goods(w: World) -> Dictionary:
	return Census.goods(w)


func test_accept_and_reserve() -> void:
	var w := new_world()
	var m := miner(w)
	w.player.coins = 500
	var c0 := coins(w)
	var r := w.contracts.propose(World.PLAYER, m, "iron_ore", 3, 30, 3)
	check(str(r.answer) == "accept" and r.has("contract"), "a miner with a pickaxe accepts 3 iron ore at 30 each in 3 days (%s)" % str(r.get("say", "")))
	if not r.has("contract"):
		return
	var c: Dictionary = r.contract
	check(w.player.coins == 410 and int(c.reserved) == 90, "the 90 coins are set aside from the player's purse at acceptance")
	check(w.contracts.reserved_total() == 90 and coins(w) == c0, "and still counted in the village's coins")
	check(str(c.route) == "mine" and int(c.deadline_day) == w.day() + 2, "by mining, due by the end of the third day")
	check(w.brain.reserve(m, "iron_ore") == 3, "the miner keeps back the ore it owes from sale")


func test_reject_by_real_signals() -> void:
	var w := new_world()
	w.player.coins = 500
	var wc: NPC = w.brain._first_with_job("woodcutter")
	wc.inv.remove("pickaxe", wc.inv.count("pickaxe"))
	wc.inv.remove("iron_ore", wc.inv.count("iron_ore"))
	for o: NPC in w.npcs:
		o.inv.remove("iron_ore", o.inv.count("iron_ore"))     # nobody sells it: it cannot be bought either
	var r := w.contracts.propose(World.PLAYER, wc, "iron_ore", 3, 30, 3)
	check(str(r.answer) == "reject" and str(r.say).contains("pickaxe"), "a woodcutter with no pickaxe refuses ore: \"%s\"" % str(r.say))
	var f: NPC = w.brain._first_with_job("farmer")
	r = w.contracts.propose(World.PLAYER, f, "iron_armor", 1, 200, 5)
	check(str(r.answer) == "reject" and str(r.say).contains("skill"), "a farmer refuses iron armour it has not the skill to make: \"%s\"" % str(r.say))
	for o: NPC in w.npcs:
		if o.role == "child":
			r = w.contracts.propose(World.PLAYER, o, "log", 1, 10, 3)
			check(str(r.answer) == "reject", "a child takes on no contract")
			break
	w.player.coins = 5
	var m := miner(w)
	r = w.contracts.propose(World.PLAYER, m, "iron_ore", 3, 30, 3)
	check(str(r.answer) == "refused" and w.contracts.list.is_empty() and w.player.coins == 5, "a buyer who cannot set the coins aside cannot make the offer")
	w.player.coins = 500
	var a := w.contracts.propose(World.PLAYER, m, "iron_ore", 1, 30, 3)
	var b := w.contracts.propose(World.PLAYER, m, "coal", 1, 30, 3)
	var c := w.contracts.propose(World.PLAYER, m, "stone", 1, 30, 3)
	check(a.has("contract") and b.has("contract") and str(c.answer) == "reject" and str(c.say).contains("promised"),
			"a seller already bound to max_open_per_seller contracts refuses another: \"%s\"" % str(c.get("say", "")))


func test_counteroffers() -> void:
	var w := new_world()
	w.player.coins = 2000
	var m := miner(w)
	var r := w.contracts.propose(World.PLAYER, m, "iron_ore", 3, 1, 3)
	check(str(r.answer) == "counter" and int(r.price_each) > 1 and int(r.price_each) == int(r.min_price) and int(r.qty) == 3,
			"too low a price is countered with the seller's least price (%d): \"%s\"" % [int(r.price_each), str(r.say)])
	check(w.contracts.list.is_empty() and w.player.coins == 2000, "a counteroffer opens nothing and sets nothing aside")
	var again := w.contracts.propose(World.PLAYER, m, "iron_ore", int(r.qty), int(r.price_each), int(r.days), r.history)
	check(again.has("contract") and (again.contract.history as Array).size() == 4, "the buyer meets the counter and the contract opens, with the talk on record")
	var w2 := new_world()
	w2.player.coins = 5000
	var m2 := miner(w2)
	var big := w2.contracts.propose(World.PLAYER, m2, "iron_ore", 200, 10, 1)
	var cap := int(w2.contracts.means(m2, "iron_ore", int(big.days)).cap) + int(w2.contracts.means(m2, "iron_ore", int(big.days)).stock)
	check(str(big.answer) == "counter" and (int(big.days) > 1 or int(big.qty) < 200) and int(big.qty) <= cap,
			"a quantity it cannot manage by the deadline is countered with a later deadline or what it can do (%d in %d days)" % [int(big.qty), int(big.days)])
	var wa := new_world()
	var wb := new_world()
	wa.player.coins = 2000
	wb.player.coins = 2000
	var r3 := wa.contracts.propose(World.PLAYER, miner(wa), "iron_ore", 30, 2, 2)
	var r4 := wb.contracts.propose(World.PLAYER, miner(wb), "iron_ore", 30, 2, 2)
	check(str(r3.answer) == str(r4.answer) and int(r3.qty) == int(r4.qty) and int(r3.price_each) == int(r4.price_each) and int(r3.days) == int(r4.days), "the answer is the same for the same world and offer (deterministic)")


func test_partial_delivery() -> void:
	var w := new_world()
	w.player.coins = 500
	var m := miner(w)
	m.inv.remove("iron_ore", m.inv.count("iron_ore"))
	var c: Dictionary = w.contracts.propose(World.PLAYER, m, "iron_ore", 5, 20, 3).get("contract", {})
	check(not c.is_empty(), "contract for 5 iron ore opened")
	if c.is_empty():
		return
	var c0 := coins(w)
	var g0 := goods(w)
	var p0 := w.player.inv.count("iron_ore")
	var mc := m.coins
	check(w.contracts.deliver(c, 2) == 0, "nothing is delivered that the seller does not hold")
	m.inv.add("iron_ore", 2)
	var g1 := goods(w)
	check(w.contracts.deliver(c, 2) == 2, "two delivered of five")
	check(int(c.delivered) == 2 and int(c.paid) == 40 and int(c.reserved) == 60 and m.coins == mc + 40 and w.player.inv.count("iron_ore") == p0 + 2,
			"each unit is paid as it is handed over, from the coins set aside")
	check(coins(w) == c0 and goods(w) == g1, "coins and goods only moved")
	m.inv.add("iron_ore", 10)
	check(w.contracts.deliver(c, 10) == 3 and int(c.delivered) == 5 and str(c.state) == "fulfilled", "no more than the quantity is delivered; the contract is fulfilled")
	check(int(c.paid) == 100 and int(c.reserved) == 0 and m.inv.count("iron_ore") == 7, "paid exactly the total, nothing more set aside")
	check(w.contracts.deliver(c, 1) == 0 and int(c.paid) == 100, "a fulfilled contract takes no further delivery or payment")
	check(coins(w) == c0, "no coin made or lost (%d)" % (coins(w) - c0))
	check(g0.get("iron_ore", 0) + 12 == goods(w).get("iron_ore", 0), "no ore made or lost beyond what the test gave")


func test_lapse() -> void:
	var w := new_world()
	w.player.coins = 500
	var m := miner(w)
	var c: Dictionary = w.contracts.propose(World.PLAYER, m, "iron_ore", 4, 20, 1).get("contract", {})
	check(not c.is_empty(), "contract for 4 iron ore in 1 day opened")
	if c.is_empty():
		return
	var t: Dictionary = w.relations.tie(Life.PLAYER_ID, m.id)
	t.regard = 40.0
	var c0 := coins(w)
	w.contracts.dawn()
	check(str(c.state) == "accepted", "on its deadline day it still stands")
	w.minutes += World.DAY
	w.contracts.dawn()
	check(str(c.state) == "lapsed" and int(c.reserved) == 0 and w.player.coins == 500, "past the deadline it lapses; the coins set aside go back to the buyer")
	check(float(w.relations.peek(Life.PLAYER_ID, m.id).regard) == 40.0 - float(Contracts.cfg().default_regard), "the seller who failed loses regard with the buyer")
	check(coins(w) == c0, "no money penalty: coins only moved")
	check(w.brain.reserve(m, "iron_ore") == 0, "the miner no longer keeps ore back for it")


func test_cancellation() -> void:
	var w := new_world()
	w.player.coins = 500
	var m := miner(w)
	var c: Dictionary = w.contracts.propose(World.PLAYER, m, "iron_ore", 4, 20, 3).get("contract", {})
	m.inv.add("iron_ore", 1)
	w.contracts.deliver(c, 1)
	var mc := m.coins
	var c0 := coins(w)
	check(w.contracts.cancel(c, "npc:999") != "", "only the parties can end a contract")
	check(w.contracts.cancel(c, World.PLAYER) == "" and str(c.state) == "cancelled", "the buyer cancels")
	check(w.player.coins == 500 - 20 and m.coins == mc and int(c.reserved) == 0, "the delivered unit stays paid; the rest comes back to the buyer")
	check(coins(w) == c0 and w.contracts.cancel(c, World.PLAYER) != "", "coins only moved; an ended contract cannot be ended again")
	var c2: Dictionary = w.contracts.propose(World.PLAYER, m, "coal", 2, 20, 3).get("contract", {})
	check(not c2.is_empty() and w.contracts.cancel(c2, World.npc_ref(m.id)) == "" and w.player.coins == 480, "the seller may withdraw too; the buyer's coins come back")


func test_villager_works_toward_it() -> void:
	var w := new_world()
	w.player.coins = 500
	var m := miner(w)
	m.inv.remove("iron_ore", m.inv.count("iron_ore"))
	var c: Dictionary = w.contracts.propose(World.PLAYER, m, "iron_ore", 3, 20, 3).get("contract", {})
	w.minutes = 9.0 * 60.0
	check(w.contracts.plan(m) and str(m.plan[-1].get("act", "")) == "mine", "the miner goes to mine the ore it owes")
	# a home for the player: the goods are brought to its chest
	var home := ""
	for id in w.buildings:
		if str(w.buildings[id].get("type", "")) == "house":
			home = id
			break
	w.player.home = home
	m.inv.add("iron_ore", 3)
	check(w.contracts.plan(m) and str(m.plan[-1].get("act", "")) == "contract_deliver", "with the ore in hand it takes it to the buyer")
	var chest0 := w.player.chest.count("iron_ore")
	check(w.brain.act(m, "contract_deliver", m.plan[-1].args) and w.player.chest.count("iron_ore") == chest0 + 3 and str(c.state) == "fulfilled",
			"and puts it in the player's chest at their home, paid on delivery")
	var f: NPC = w.brain._first_with_job("smith")
	var c2: Dictionary = w.contracts.propose(World.npc_ref(f.id), m, "coal", 2, 20, 3).get("contract", {})
	if not c2.is_empty():
		m.inv.add("coal", 2)
		check(w.contracts.plan(m) and m.plan[0].get("to") == w.brain._workplace_cell(f), "a villager buyer's goods are carried to its workplace")


func _clear_item(w: World, id: String) -> void:
	for o: NPC in w.npcs:
		o.inv.remove(id, o.inv.count(id))
	for hh in w.households:
		hh.pantry.remove(id, hh.pantry.count(id))


func test_npc_to_npc() -> void:
	var w := new_world()
	var smith: NPC = w.brain._first_with_job("smith")
	_clear_item(w, "coal")
	smith.coins = 600
	miner(w)
	var c0 := coins(w)
	check(w.contracts.order_input(smith), "the smith places an order")
	_sign_pending(w, smith)
	var mine: Array = w.contracts.open_of(World.npc_ref(smith.id), "buyer")
	check(not mine.is_empty() and str(mine[0].item) == "coal", "a smith with no coal and nobody selling any orders it from another villager")
	if mine.is_empty():
		return
	var c: Dictionary = mine[0]
	var s: NPC = w.npc(World.ref_id(c.seller))
	check(s != null and s.inv.has("pickaxe") and int(c.reserved) == int(c.qty) * int(c.price_each), "from someone who can mine it, the smith's coins set aside (%s)" % str(c.seller))
	check(coins(w) == c0, "coins only moved")
	s.inv.add("coal", int(c.qty))
	var sc := smith.inv.count("coal")
	check(w.contracts.npc_deliver(s, int(c.id)) and smith.inv.count("coal") == sc + int(c.qty) and str(c.state) == "fulfilled", "the coal is delivered and paid")
	check(coins(w) == c0, "and coins are conserved")
	check(not w.contracts.order_input(smith) or str(w.contracts.list[-1].item) != "coal", "a smith holding coal orders no more of it")


## A formal order made at a distance waits to be signed: the buyer walks to the seller (here: put beside it) and signs.
func _sign_pending(w: World, b: NPC) -> void:
	for c in w.contracts.list.duplicate():
		if str(c.state) == "signing" and c.buyer == World.npc_ref(b.id):
			b.pos = w.npc(World.ref_id(c.seller)).pos
			w.contracts.npc_sign(b, int(c.id))


func test_npc_offer_to_player() -> void:
	var w := new_world()
	var smith: NPC = w.brain._first_with_job("smith")
	_clear_item(w, "coal")
	for o: NPC in w.npcs:
		o.inv.remove("pickaxe", o.inv.count("pickaxe"))      # nobody can mine it
	smith.coins = 600
	w.contracts.order_input(smith)
	var offers: Array = w.contracts.with_player(smith)
	check(offers.size() == 1 and str(offers[0].state) == "offered" and offers[0].seller == World.PLAYER, "with nobody able, the smith's order is offered to the player")
	if offers.is_empty():
		return
	var c: Dictionary = offers[0]
	var c0 := coins(w)
	var sm := smith.coins
	w.player.pos = smith.pos
	check(w.contracts.accept_offer(c) == "" and str(c.state) == "accepted" and smith.coins == sm - int(c.reserved), "the player accepts; the smith's coins are set aside")
	w.player.inv.add("coal", 1)
	var pc := w.player.coins
	check(w.contracts.deliver(c, 1) == 1 and w.player.coins == pc + int(c.price_each) and int(c.delivered) == 1, "the player delivers one and is paid for it")
	check(coins(w) == c0, "coins only moved")
	w.minutes += World.DAY * 10
	w.contracts.dawn()
	check(str(c.state) == "lapsed" and smith.coins == sm - int(c.price_each), "left undone it lapses; the smith has back what was not delivered")


func test_death_of_a_party() -> void:
	var w := new_world()
	w.player.coins = 500
	var m := miner(w)
	var c: Dictionary = w.contracts.propose(World.PLAYER, m, "iron_ore", 3, 20, 3).get("contract", {})
	var c0 := coins(w)
	w.kill(m, "illness")
	check(str(c.state) == "cancelled" and w.player.coins == 500 and coins(w) == c0, "the seller dies: the contract ends and the buyer's coins come back")
	var smith: NPC = w.brain._first_with_job("smith")
	smith.coins = 300
	var m2: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o != smith and o.inv.has("pickaxe"):
			m2 = o
			break
	if m2 == null:
		return
	var c2: Dictionary = w.contracts.propose(World.npc_ref(smith.id), m2, "stone", 2, 20, 3).get("contract", {})
	check(not c2.is_empty(), "a smith orders stone")
	var c1 := coins(w)
	w.kill(smith, "illness")
	check(str(c2.state) == "cancelled" and int(c2.reserved) == 0 and coins(w) == c1, "the buyer dies: its coins come back before what it leaves passes on")
	w.player.coins = 500
	var c3: Dictionary = w.contracts.propose(World.PLAYER, m2, "stone", 2, 20, 3).get("contract", {})
	var c4 := coins(w)
	w.continue_as_heir()
	check(not c3.is_empty() and str(c3.state) == "cancelled" and int(w.loot[-1].coins) == 500 and coins(w) == c4,
			"the player dies: their contracts end, the coins set aside lie with the rest of what they left")


func test_save_and_load() -> void:
	var w := new_world()
	w.player.coins = 500
	var m := miner(w)
	var c: Dictionary = w.contracts.propose(World.PLAYER, m, "iron_ore", 4, 20, 3).get("contract", {})
	m.inv.add("iron_ore", 1)
	w.contracts.deliver(c, 1)
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	var c2: Dictionary = w2.contracts.get_contract(int(c.id))
	check(not c2.is_empty() and str(c2.state) == "accepted" and int(c2.delivered) == 1 and int(c2.reserved) == 60 and int(c2.paid) == 20,
			"saved and loaded: the contract, its deliveries and the coins set aside")
	check(w2.total_coins() == w.total_coins() and goods(w2) == goods(w), "every coin and good is there after loading")
	var m2: NPC = w2.npc(m.id)
	m2.inv.add("iron_ore", 5)
	check(w2.contracts.deliver(c2, 5) == 3 and int(c2.paid) == 80, "after loading only what is still owed is delivered and paid (no duplicate)")
	check(w2.contracts.next_id == w.contracts.next_id, "ids are never reused")
	var old := w.to_dict()
	old.erase("contracts")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(old)))
	check(w3.contracts.list.is_empty() and w3.contracts.reserved_total() == 0, "an older save loads with no contracts")


func test_parity() -> void:
	var w := new_world()
	w.player.coins = 500
	var m := miner(w)
	var smith: NPC = w.brain._first_with_job("smith")
	var a := w.contracts.evaluate(m, World.PLAYER, "iron_ore", 3, 2, 3)
	var b := w.contracts.evaluate(m, World.npc_ref(smith.id), "iron_ore", 3, 2, 3)
	check(str(a.answer) == str(b.answer) and int(a.price_each) == int(b.price_each) and int(a.qty) == int(b.qty),
			"the same offer gets the same answer from the player or a villager (%s at %d)" % [str(a.answer), int(a.price_each)])
	w.relations.tie(Life.PLAYER_ID, m.id).friends = true
	var f := w.contracts.evaluate(m, World.PLAYER, "iron_ore", 3, 2, 3)
	check(int(f.min_price) <= int(a.min_price), "a friend is asked no more (%d, a stranger %d)" % [int(f.min_price), int(a.min_price)])


## Each of the directive's questions is weighed and on record (evaluate's terms): obligations, household needs,
## competing opportunities (its usual earnings), the relationship and risk.
func test_evaluation_terms() -> void:
	var w := new_world()
	w.player.coins = 5000
	var m := miner(w)
	var smith: NPC = w.brain._first_with_job("smith")
	m.income_days = []
	var a := w.contracts.evaluate(m, World.PLAYER, "iron_ore", 3, 2, 3)
	var t: Dictionary = a.terms
	check(t.has("obligations") and t.has("household") and t.has("alternatives") and t.has("relationship") and t.has("risk") and t.has("going"),
			"the answer records every term it weighed (%s)" % str(t.keys()))
	m.income_days = [400, 400, 400, 400, 400]
	var b := w.contracts.evaluate(m, World.PLAYER, "iron_ore", 3, 2, 3)
	check(float(b.terms.alternatives) > float(t.alternatives) and int(b.min_price) > int(a.min_price),
			"a villager who earns well in its own trade asks more for the same work (%d, idle %d)" % [int(b.min_price), int(a.min_price)])
	var purse := m.coins
	m.coins = 0
	var needy := w.contracts.evaluate(m, World.PLAYER, "iron_ore", 3, 2, 3)
	m.coins = 100000
	var rich := w.contracts.evaluate(m, World.PLAYER, "iron_ore", 3, 2, 3)
	m.coins = purse
	check(int(needy.min_price) <= int(rich.min_price) and float(rich.terms.household) == float(Contracts.cfg().comfortable_factor),
			"a household short of its needs takes less than one with its reserve covered (%d, %d)" % [int(needy.min_price), int(rich.min_price)])
	var stranger := w.contracts.evaluate(m, World.npc_ref(smith.id), "iron_ore", 3, 2, 3)
	var old_partner := m.partner
	m.partner = smith.id
	var kin := w.contracts.evaluate(m, World.npc_ref(smith.id), "iron_ore", 3, 2, 3)
	m.partner = old_partner
	check(bool(kin.terms.close) and not bool(stranger.terms.close) and int(kin.min_price) < int(stranger.min_price),
			"a partner is given a friend's price (%d, a stranger %d)" % [int(kin.min_price), int(stranger.min_price)])
	var c: Dictionary = w.contracts.propose(World.PLAYER, m, "iron_ore", 1, int(b.min_price), 3).get("contract", {})
	check(not c.is_empty() and w.contracts.cancel(c, World.PLAYER) == "", "the player orders and then cancels")
	var after := w.contracts.evaluate(m, World.PLAYER, "iron_ore", 3, 2, 3)
	check(int(after.terms.cancelled_on_me) == 1 and float(after.terms.risk) > 0.0 and int(after.min_price) > int(b.min_price),
			"a buyer who ended a contract early is asked more: risk (%d, before %d)" % [int(after.min_price), int(b.min_price)])
	var quit: Dictionary = w.contracts.propose(World.PLAYER, m, "coal", 1, 500, 3).get("contract", {})
	if not quit.is_empty():
		w.contracts.cancel(quit, World.npc_ref(m.id))
	check(int(w.contracts.evaluate(m, World.PLAYER, "iron_ore", 3, 2, 3).terms.cancelled_on_me) == 1, "a seller's own withdrawal is not held against the buyer")
	w.manor_orders.append({"smith": smith.id, "tool": "axe", "for": m.id, "paid": 0, "day": w.day()})
	var ob: Dictionary = w.contracts.obligations(smith)
	check(int(ob.tool_orders) == 1 and int(ob.contracts) == 0 and not bool(ob.manor_job), "a smith's manor tool orders count among its obligations")
	var e := w.contracts.evaluate(smith, World.PLAYER, "iron_ore", 1, 50, 3)
	check((e.terms.get("obligations", {}) as Dictionary).has("tool_orders"), "and are weighed in its answer")


## Time: a villager whose working day is nearly over cannot promise ore by tonight, and asks for more days.
func test_time_counter() -> void:
	var w := new_world()
	w.player.coins = 500
	var m := miner(w)
	m.inv.remove("iron_ore", m.inv.count("iron_ore"))
	var day0 := float(w.day()) * World.DAY
	w.minutes = day0 + (NPCBrain.WORK_END - 0.05) * 60.0
	var r := w.contracts.evaluate(m, World.PLAYER, "iron_ore", 3, 50, 1)
	check(str(r.answer) == "counter" and int(r.days) > 1 and int(r.qty) == 3, "at the end of the working day 3 ore by tonight is countered with more days: \"%s\"" % str(r.say))
	w.minutes = day0 + 8.0 * 60.0
	var r2 := w.contracts.evaluate(m, World.PLAYER, "iron_ore", 3, 50, 1)
	check(str(r2.answer) == "accept", "in the morning the same offer is accepted (\"%s\")" % str(r2.say))


## The buyer's side: the one rule a villager buyer answers a seller's terms by.
func test_buyer_answers() -> void:
	var w := new_world()
	var smith: NPC = w.brain._first_with_job("smith")
	smith.coins = 5000
	var k := w.contracts
	var tol := float(Contracts.cfg().npc_counter_tolerance)
	var a := k.buyer_answer(smith, "coal", 10, 8, 4, 10, 8, 3)
	check(str(a.answer) == "accept", "its own terms are agreed")
	a = k.buyer_answer(smith, "coal", 10, 8, 4, 10, floori(8 * tol), 3)
	check(str(a.answer) == "accept", "a price within npc_counter_tolerance is agreed")
	a = k.buyer_answer(smith, "coal", 10, 8, 4, 10, 30, 3)
	check(str(a.answer) == "counter" and int(a.price_each) == floori(8 * tol) and str(a.say).contains("most"), "a dearer price is countered with the most it pays: \"%s\"" % str(a.say))
	a = k.buyer_answer(smith, "coal", 10, 8, 4, 2, 8, 3)
	check(str(a.answer) == "reject" and str(a.say).contains("no use"), "fewer than it can use is refused: \"%s\"" % str(a.say))
	a = k.buyer_answer(smith, "coal", 10, 8, 4, 25, 8, 3)
	check(str(a.answer) == "counter" and int(a.qty) == 10, "more than it asked for is countered with what it wants")
	a = k.buyer_answer(smith, "coal", 10, 8, 4, 10, 8, 99)
	check(str(a.answer) == "counter" and int(a.days) == int(Contracts.cfg().max_days), "too long a wait is countered with max_days")
	smith.coins = w.reserve_of(smith) + 20
	a = k.buyer_answer(smith, "coal", 10, 8, 1, 10, 8, 3)
	check(str(a.answer) == "counter" and int(a.qty) * 8 <= 20 and str(a.say).contains("pay for"), "it sets aside only coins above its household's reserve: \"%s\"" % str(a.say))
	smith.coins = w.reserve_of(smith)
	a = k.buyer_answer(smith, "coal", 10, 8, 1, 10, 8, 3)
	check(str(a.answer) == "reject", "with nothing to spare it refuses")


## NPC to NPC: a business's order countered by the seller is met when the counter is within what it pays.
func test_npc_meets_counter() -> void:
	var w := new_world()
	var smith: NPC = w.brain._first_with_job("smith")
	smith.coins = 5000
	var m := miner(w)
	m.inv.remove("coal", m.inv.count("coal"))
	m.income_days = [60, 60, 60, 60, 60]
	smith.pos = m.pos                # face to face, so a formal contract is signed at once
	var least := int(w.contracts.evaluate(m, World.npc_ref(smith.id), "coal", 4, 1, 3).min_price)
	var tol := float(Contracts.cfg().npc_counter_tolerance)
	var price := maxi(1, floori(float(least) / tol))
	while floori(float(price) * tol) < least:
		price += 1
	var c0 := coins(w)
	var r := w.contracts.propose(World.npc_ref(smith.id), m, "coal", 4, price, 3)
	check(price < least and str(r.answer) == "counter", "the miner counters a price under its least (%d < %d): \"%s\"" % [price, least, str(r.get("say", ""))])
	if str(r.answer) == "counter":
		check(w.contracts.meet_counter(smith, m, "coal", 4, price, 1, r), "the smith meets the counter, within its tolerance")
		var mine: Array = w.contracts.open_of(World.npc_ref(smith.id), "buyer")
		var c: Dictionary = mine[-1] if not mine.is_empty() else {}
		check(not c.is_empty() and int(c.price_each) == least and int(c.reserved) == int(c.qty) * least and (c.history as Array).size() == 4 and coins(w) == c0,
				"the contract opens at the counter's price, the coins set aside, the talk on record")
	var w2 := new_world()
	var smith2: NPC = w2.brain._first_with_job("smith")
	smith2.coins = 5000
	var m2 := miner(w2)
	m2.income_days = [60, 60, 60, 60, 60]
	var r2 := w2.contracts.propose(World.npc_ref(smith2.id), m2, "coal", 4, 1, 3)
	check(least <= 1 or (str(r2.answer) == "counter" and not w2.contracts.meet_counter(smith2, m2, "coal", 4, 1, 1, r2) and w2.contracts.list.is_empty()),
			"a counter far above what it pays is not met; nothing opens")


## NPC to player, with counters both ways: the player puts other terms to a villager's standing offer.
func test_player_counters_npc_offer() -> void:
	var w := new_world()
	var smith: NPC = w.brain._first_with_job("smith")
	smith.coins = 5000
	var k := w.contracts
	w.player.pos = smith.pos
	var c := k.offer_to_player(smith, "coal", 10, 8, 3)
	check(str(c.state) == "offered" and int(c.reserved) == 0 and k.reserved_total() == 0, "a villager's offer to the player sets nothing aside yet")
	var c0 := coins(w)
	var unit := maxi(1, w.brain.batch_unit(smith, "coal"))
	if unit > 1:
		var low := k.counter_offer(c, unit - 1, 8, 3)
		check(str(low.answer) == "reject" and str(c.state) == "offered" and int(c.qty) == 10 and int(c.price_each) == 8, "too few is refused and the offer stands as it was")
	var dear := k.counter_offer(c, 10, 40, 3)
	var top := floori(8 * float(Contracts.cfg().npc_counter_tolerance))
	check(str(dear.answer) == "counter" and int(c.price_each) == top and str(c.state) == "offered" and k.reserved_total() == 0,
			"a price far above its own is countered: the offer now stands at %d each, still nothing set aside" % int(c.price_each))
	var ok := k.counter_offer(c, 10, top, 4)
	check(str(ok.answer) == "accept" and ok.has("contract") and str(c.state) == "accepted" and int(c.reserved) == 10 * top and int(c.days) == 4,
			"the player's terms within what it pays are agreed: the contract opens, its coins set aside")
	check(coins(w) == c0 and str(k.counter_offer(c, 10, top, 4).answer) == "refused", "coins only moved; an accepted offer takes no more counters")
	w.player.inv.add("coal", 3)
	var pc := w.player.coins
	check(k.deliver(c, 3) == 3 and w.player.coins == pc + 3 * top and k.deliver(c, 3) == 0, "the player delivers and is paid once (no second payment for the same goods)")
	var sm := smith.coins
	check(k.cancel(c, World.PLAYER) == "" and smith.coins == sm + 7 * top and int(c.reserved) == 0, "the player withdraws: the smith's set-aside coins for the rest come back")
	check(coins(w) == c0, "every coin only moved (%d)" % (coins(w) - c0))
	var d := k.offer_to_player(smith, "coal", 10, 8, 3)
	k.counter_offer(d, 10, 40, 3)
	w.minutes += World.DAY * 3
	k.dawn()
	check(str(d.state) == "cancelled" and int(d.reserved) == 0, "a countered offer not taken up is withdrawn after offer_days, nothing held")


## Open contracts and standing offers survive a save and load; saves from before (Build 16, and early Build 17
## records without the newer keys) load.
func test_offer_saved_and_older_saves() -> void:
	var w := new_world()
	var smith: NPC = w.brain._first_with_job("smith")
	smith.coins = 5000
	w.player.coins = 500
	var offer := w.contracts.offer_to_player(smith, "coal", 10, 8, 3)
	var m := miner(w)
	var open: Dictionary = w.contracts.propose(World.PLAYER, m, "iron_ore", 4, 20, 3).get("contract", {})
	check(not open.is_empty(), "a contract is open before saving")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	var o2: Dictionary = w2.contracts.get_contract(int(offer.id))
	check(str(o2.get("state", "")) == "offered" and not w2.contracts.get_contract(int(open.get("id", -1))).is_empty() and w2.total_coins() == w.total_coins(),
			"an open contract and a standing offer are saved and loaded, every coin there")
	w2.player.pos = w2.npc(smith.id).pos
	var ok := w2.contracts.counter_offer(o2, 10, 8, 3)
	check(str(ok.answer) == "accept" and int(o2.reserved) == 80, "the loaded offer can still be agreed to")
	var old: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	for key in ["contracts", "prospecting", "discovery", "underground"]:
		old.erase(key)
	old.save_version = 16
	old.format = "mml-save/16"
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), old)
	check(w3.contracts.list.is_empty() and w3.contracts.next_id == 1 and w3.contracts.reserved_total() == 0, "a Build 16 save loads with no contracts and nothing set aside")
	var early: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	for c in early.contracts.list:
		for key in ["terms", "route", "recipe", "history"]:
			c.erase(key)
	var w4 := World.new()
	w4.load_dict(VillageMap.load_default(), early)
	var c4: Dictionary = w4.contracts.get_contract(int(open.get("id", -1)))
	var m4: NPC = w4.npc(m.id)
	m4.inv.add("iron_ore", 4)
	check(not c4.is_empty() and str((c4.terms as Dictionary).get("pay", "")) == "on_delivery" and w4.contracts.deliver(c4, 4) == 4 and str(c4.state) == "fulfilled",
			"an early Build 17 record without the newer keys loads with its defaults and is delivered")


## Determinism: the same world and the same day give the same orders, answers and records.
func test_determinism() -> void:
	var out := []
	for i in 2:
		var w := new_world(3)
		_clear_item(w, "coal")
		for o: NPC in w.npcs:
			if o.job == "smith":
				o.coins = 800
		w.contracts.dawn()
		var e := w.contracts.evaluate(miner(w), World.PLAYER, "iron_ore", 30, 2, 2)
		out.append(JSON.stringify([w.contracts.to_dict(), e]))
	check(out[0] == out[1] and out[0].contains("\"id\":1"), "two runs of the same seed make the same contracts and answers")


## Q18-13 (owner 2026-10-21): an ordinary small agreement needs no signing; a formal contract (formal_total coins or
## more) is concluded only face to face, never remotely and at once. Incomplete, rejected, interrupted and completed.
func test_signing() -> void:
	var w := new_world()
	w.player.coins = 1000
	var m := miner(w)
	m.inv.remove("iron_ore", m.inv.count("iron_ore"))
	var formal := int(Contracts.cfg().formal_total)
	far(w)
	var c0 := coins(w)
	var small := w.contracts.propose(World.PLAYER, m, "iron_ore", 1, formal - 1, 3)
	check(small.has("contract") and int(small.contract.reserved) == formal - 1, "a small agreement (%d coins) is concluded at a distance, unsigned" % (formal - 1))
	w.contracts.cancel(small.contract, World.PLAYER)
	var big := w.contracts.propose(World.PLAYER, m, "iron_ore", 2, formal, 3)
	check(str(big.answer) == "meet" and not big.has("contract") and w.player.coins == 1000 and coins(w) == c0 and w.contracts.reserved_total() == 0,
			"a formal contract asked for at a distance is not concluded: \"%s\"; nothing set aside" % str(big.get("say", "")))
	w.player.pos = m.pos
	big = w.contracts.propose(World.PLAYER, m, "iron_ore", 2, formal, 3)
	check(big.has("contract") and int(big.contract.reserved) == 2 * formal and coins(w) == c0, "face to face the same contract is signed and the coins set aside")
	w.contracts.cancel(big.contract, World.PLAYER)
	# the player as seller of a villager's formal order: accepted only in person
	var smith: NPC = w.brain._first_with_job("smith")
	smith.coins = 5000
	var off := w.contracts.offer_to_player(smith, "coal", 10, formal, 3)
	far(w)
	check(w.contracts.accept_offer(off) != "" and str(off.state) == "offered" and int(off.reserved) == 0, "the player cannot accept a villager's formal order from afar")
	w.player.pos = smith.pos
	check(w.contracts.accept_offer(off) == "" and str(off.state) == "accepted", "in person they can")
	w.contracts.cancel(off, World.PLAYER)

	# NPC to NPC at a distance: agreed in principle, signed when the buyer reaches the seller
	var w2 := new_world()
	var b: NPC = w2.brain._first_with_job("smith")
	b.coins = 5000
	var s := miner(w2)
	s.inv.remove("coal", s.inv.count("coal"))
	b.pos = s.pos + Vector2(40, 0)
	if not w2.present(b.pos, 3.0).is_empty() and w2.present(b.pos, 3.0).has(s):
		b.pos = s.pos + Vector2(0, 40)
	var c1 := coins(w2)
	var g1 := goods(w2)
	var r := w2.contracts.propose(World.npc_ref(b.id), s, "coal", 10, formal, 5)
	check(r.has("signing") and not r.has("contract"), "a villager's formal order at a distance waits to be signed")
	if not r.has("signing"):
		return
	var p: Dictionary = r.signing
	check(str(p.state) == "signing" and int(p.reserved) == 0 and w2.contracts.reserved_total() == 0 and b.coins == 5000 and coins(w2) == c1,
			"nothing is set aside before signing")
	check(not w2.contracts.waiting_on(World.npc_ref(b.id), "iron_ore") and w2.contracts.waiting_on(World.npc_ref(b.id), "coal"), "the buyer counts it as an order it is waiting on")
	w2.minutes = float(w2.day()) * World.DAY + 9.0 * 60.0
	check(w2.contracts.plan(b) and str(b.plan[-1].get("act", "")) == "contract_sign", "the buyer walks to the seller to sign")
	check(not w2.brain.act(b, "contract_sign", b.plan[-1].args) and str(p.state) == "signing", "not yet face to face: nothing is signed (no remote signing)")
	b.pos = s.pos
	check(w2.brain.act(b, "contract_sign", b.plan[-1].args) and str(p.state) == "accepted" and int(p.reserved) == int(p.qty) * int(p.price_each),
			"face to face it is signed and the buyer's coins set aside (%s)" % str((p.history as Array).map(func(h): return h.what)))
	check(coins(w2) == c1 and goods(w2) == g1, "signing only set coins aside")
	s.inv.add("coal", int(p.qty))
	check(w2.contracts.npc_deliver(s, int(p.id)) and str(p.state) == "fulfilled" and coins(w2) == c1, "completed: delivered and paid")

	# interrupted: the seller dies before signing; and an agreement never signed lapses
	var w3 := new_world()
	var b3: NPC = w3.brain._first_with_job("smith")
	b3.coins = 5000
	var s3 := miner(w3)
	b3.pos = s3.pos + Vector2(40, 0)
	var c3 := coins(w3)
	var g3 := goods(w3)
	var p3: Dictionary = w3.contracts.propose(World.npc_ref(b3.id), s3, "coal", 10, formal, 5).get("signing", {})
	var p4: Dictionary = {}
	for o: NPC in w3.npcs:
		if o != s3 and o != b3 and o.alive and o.role == "adult" and o.inv.has("pickaxe"):
			o.pos = s3.pos + Vector2(0, 60)
			p4 = w3.contracts.propose(World.npc_ref(b3.id), o, "stone", 10, formal, 5).get("signing", {})
			break
	w3.kill(s3, "illness")
	check(not p3.is_empty() and str(p3.state) == "cancelled" and int(p3.reserved) == 0, "interrupted: the seller dies before signing; the agreement ends")
	if not p4.is_empty():
		w3.minutes += World.DAY * int(Contracts.cfg().offer_days)
		w3.contracts.dawn()
		check(str(p4.state) == "cancelled" and str(p4.get("why", "")) == "never signed", "an agreement never signed lapses after offer_days")
	check(w3.contracts.reserved_total() == 0 and coins(w3) == c3, "no reservation made, no coin moved")
	var g3b := goods(w3)
	for k in ["coal", "stone"]:
		check(int(g3b.get(k, 0)) == int(g3.get(k, 0)), "no %s moved" % k)

	# rejected at the meeting: the seller can no longer do it
	var w4 := new_world()
	var b4: NPC = w4.brain._first_with_job("smith")
	b4.coins = 5000
	var s4 := miner(w4)
	_clear_item(w4, "coal")
	b4.pos = s4.pos + Vector2(40, 0)
	var p5: Dictionary = w4.contracts.propose(World.npc_ref(b4.id), s4, "coal", 10, formal, 5).get("signing", {})
	s4.inv.remove("pickaxe", s4.inv.count("pickaxe"))
	b4.pos = s4.pos
	var c5 := coins(w4)
	check(not p5.is_empty() and w4.contracts.npc_sign(b4, int(p5.id)) and str(p5.state) == "cancelled" and int(p5.reserved) == 0 and coins(w4) == c5 and b4.coins == 5000,
			"rejected when they meet (no pickaxe now): the agreement ends, nothing set aside")
