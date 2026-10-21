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
	check(_press("★ Iron ore"), "the goods the miner can come by are listed first, iron ore among them")
	var c0 := coins(w)
	for row in ["Quantity", "Price each", "Days"]:     # each down to 1 (each press redraws the window; 1 is the least)
		for i in 12:
			_press_on(row, "-1")
	check(_shows("Quantity: 1") and _shows("Price each: 1") and _shows("Days: 1"), "quantity, price and days are set with - and +")
	check(_press_on("Quantity", "+10") and _shows("Quantity: 11"), "+10 raises the quantity")
	check(_press_on("Days", "+1") and _shows("Days: 2"), "+1 gives the seller another day")
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
	return m


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
