extends SceneTree
## B14: the villagers' home economy. Run: godot --headless --path game --script res://tests/home_test.gd
## Home production (food and medicine for the household's own use, from real plants and stock).

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   ", what)
	else:
		failures += 1
		print("FAIL ", what)


func new_world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


func _init() -> void:
	test_healing()
	test_foraging_and_brewing()
	test_village_days()
	test_player_storefront()
	test_villager_storefront()
	test_cart_parts()
	test_household_cart()
	test_cart_days()
	test_local_pricing()
	test_apple_trees()
	test_carts_in_play()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## An adult with a household and a home, at the evening hour, fed, free of plans.
func _villager(w: World) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 0 and n.home != "" and n.job != "sage":
			n.plan.clear()
			n.hunger = 100.0
			return n
	return null


func _evening(w: World) -> void:
	w.minutes = float(w.day()) * 1440.0 + 19.0 * 60.0


func test_healing() -> void:
	var w := new_world()
	_evening(w)
	var n := _villager(w)
	var pantry: Inventory = w.households[n.household].pantry
	for m in NPCBrain.MEDICINES:
		n.inv.items.erase(m)
		pantry.items.erase(m)
	n.hp = n.max_hp
	check(not w.brain._plan_heal(n), "a villager at full health does not treat themselves")
	n.hp = n.max_hp * 0.3
	pantry.add("herbal_poultice", 1)
	check(w.brain._plan_heal(n) and n.plan[-1].get("act", "") == "use_medicine", "hurt, they go home to dress the wound: " + n.doing)
	var hp0 := n.hp
	check(w.brain.act(n, "use_medicine", {"pantry": true}) and is_equal_approx(n.hp, minf(n.max_hp, hp0 + float(GameData.item("herbal_poultice").heal))) and not pantry.has("herbal_poultice"),
		"the household's poultice heals them and is used up")
	check(not w.brain.act(n, "use_medicine", {"pantry": true}), "with none left, nothing heals: no medicine from nowhere")
	# none at home: buy from the Apothecary with their own coins
	n.hp = n.max_hp * 0.3
	n.plan.clear()
	var sage := w.npc(w.sage_id)
	sage.plan.clear()
	sage.anim = "idle"
	n.coins = 50
	check(w.brain._plan_heal(n) and n.plan.any(func(s): return s.get("act", "") == "buy_from"), "with none at home they go to buy medicine: " + n.doing)
	var buy: Dictionary = n.plan.filter(func(s): return s.get("act", "") == "buy_from")[0]
	var total := w.total_coins()
	var c0 := n.coins
	var s0 := sage.coins
	check(w.brain.act(n, "buy_from", buy.args) and n.coins < c0 and sage.coins - s0 == c0 - n.coins and w.total_coins() == total, "bought with the villager's own coins (%d)" % (c0 - n.coins))
	var hp1 := n.hp
	check(w.brain.act(n, "use_medicine", {}) and n.hp > hp1, "and used")
	n.hp = n.max_hp * 0.3
	n.coins = 0
	n.plan.clear()
	check(not w.brain._plan_heal(n), "without coins or medicine they cannot treat themselves")


func test_foraging_and_brewing() -> void:
	var w := new_world()
	_evening(w)
	var n := _villager(w)
	n.hp = n.max_hp
	var pantry: Inventory = w.households[n.household].pantry
	for id in ["flower", "herbal_poultice", "red_berries", "blueberries"]:
		pantry.items.erase(id)
		n.inv.items.erase(id)
	check(w.brain._plan_home_work(n) and n.plan.any(func(s): return s.get("act", "") == "forage"), "the household needs medicine: they go to gather wild flowers: " + n.doing)
	var fstep: Dictionary = n.plan.filter(func(s): return s.get("act", "") == "forage")[0]
	var pl := {}
	for p in w.plants:
		if str(p.id) == str(fstep.args.plant):
			pl = p
	check(not pl.is_empty() and pl.kind == "flower" and pl.state == "ripe", "a real ripe flower near home (%s)" % pl.get("id", "?"))
	var dist := Vector2(w.building_door(n.home)).distance_to(Vector2(int(pl.x), int(pl.y)))
	check(dist <= float(NPCBrain.hp_cfg().forage_range), "within reach of home (%.0f tiles)" % dist)
	check(w.brain.act(n, "forage", fstep.args) and n.inv.has("flower") and pl.state == "picked", "picked: the flower is in hand and the plant is bare")
	check(not w.brain.act(n, "forage", fstep.args), "a picked plant gives nothing more")
	w.brain.act(n, "store_home", {})
	check(pantry.has("flower") and not n.inv.has("flower"), "the flower goes into the household's store")
	pantry.add("flower", 1)
	n.plan.clear()
	check(w.brain._plan_home_work(n) and n.plan[-1].get("act", "") == "home_brew", "with flowers enough they brew at home: " + n.doing)
	var f0 := pantry.count("flower")
	n.skills = {}                            # a novice: the recipe's own conversion (PAR-01 skill effects aside)
	check(w.brain.act(n, "home_brew", {}) and pantry.count("herbal_poultice") == 1 and pantry.count("flower") == f0 - int(GameData.recipes.brew_poultice["in"].flower), "two flowers became a poultice at the hearth")
	pantry.items.erase("flower")
	check(not w.brain.act(n, "home_brew", {}), "no flowers, no poultice")
	pantry.add("herbal_poultice", int(NPCBrain.hp_cfg().poultice_keep))
	pantry.add("red_berries", int(NPCBrain.hp_cfg().berries_keep))
	n.plan.clear()
	n.coins = 0                                     # too poor to build a storefront
	check(not w.brain._plan_home_work(n), "a household with its poultices and berries in store does no more")


## Eight days of village life: villagers forage, brew and use their own medicine; coins conserved.
func test_village_days() -> void:
	var w := new_world()
	var start := w.total_coins()
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.id % 7 == 0:
			n.hp = n.max_hp * 0.4                   # a few villagers hurt, to see them treat themselves
	var steps := int(8.0 * 1440.0 / float(GameData.b("game_minutes_per_second")) / 0.5)
	for i in steps:
		w.update(0.5)
	var st: Dictionary = w.stats
	var used := 0
	for m in NPCBrain.MEDICINES:
		used += int(st.get("npc_used_" + m, 0))
	print("  home stats: ", {"foraged_flower": st.get("villager_foraged_flower", 0), "foraged_berries": int(st.get("villager_foraged_red_berries", 0)) + int(st.get("villager_foraged_blueberries", 0)),
		"home_brewed": st.get("home_brewed", 0), "medicine_used": used})
	check(int(st.get("villager_foraged_flower", 0)) > 0 and int(st.get("home_brewed", 0)) > 0, "over 8 days villagers gather flowers and brew poultices at home")
	check(used > 0, "and hurt villagers use medicine")
	check(w.total_coins() == start + w.coin_sources, "coins conserved (%d + sources %d = %d)" % [start, w.coin_sources, w.total_coins()])


## B14: the player builds a storefront by the door of a house they hold, from real materials; it opens as a
## shop (listings, villager demand, books), survives save and load, and closing it keeps the counter.
func test_player_storefront() -> void:
	var w := new_world()
	var p := w.player
	var biz: Business = w.business
	var b: Dictionary = {}
	var ids: Array = w.buildings.keys()
	ids.sort()
	for id in ids:
		var x: Dictionary = w.buildings[id]
		if str(x.get("type", "")) == "house" and w.owner_of(x) != World.PLAYER and biz.front_place(x).size() > 0:
			b = x
			break
	check(not b.is_empty(), "a village house with room for a counter by its door (%s)" % b.get("id", "?"))
	check(biz.storefront_refusal(b) != "", "a house the player does not hold cannot have one")
	w.set_owner(b, World.PLAYER)
	p.inv.items.clear()
	p.coins = 100
	check(biz.storefront_refusal(b).contains("takes"), "without the materials: " + biz.storefront_refusal(b))
	for id in Business.storefront_cost():
		p.inv.add(id, int(Business.storefront_cost()[id]))
	var f := biz.front_place(b)
	var c0 := Vector2i(int(f.x), int(f.y))
	check(not w.map.is_solid(c0) and not w.map.is_solid(c0 + Vector2i(1, 0)), "the counter's two cells are open ground before")
	var t0 := w.treasury
	check(biz.build_storefront(b) == "" and b.has("front") and b.has("shop") and bool(b.shop.get("front", false)), "built and opened as a shop")
	check(p.inv.total() == 0, "the materials were used up")
	check(w.map.is_solid(c0) and w.map.is_solid(c0 + Vector2i(1, 0)) and not w.map.is_solid(Vector2i(int(f.use[0]), int(f.use[1]))), "the counter is solid; the serving cell stays open")
	var door := w.building_door(str(b.id))
	check(not w.map.is_solid(door), "the door is not blocked")
	check(w.treasury == t0 and p.coins == 100 and biz.rent_of(b.shop) == 0, "no rent or licence: the household's own ground")
	check(biz.premises().has(b.shop) and biz.is_mine(b.shop), "it is one of the player's premises")
	p.inv.add("herbal_poultice", 4)
	check(biz.list_item(b.shop, "herbal_poultice", 4) == "" and int(b.shop.stock.herbal_poultice) == 4, "goods are listed at the storefront")
	check(biz.build_storefront(b) != "", "a second storefront cannot be built")
	# save and load
	var d := w.to_dict()
	var w2 := World.new()
	var m2 := VillageMap.load_default()
	w2.load_dict(m2, JSON.parse_string(JSON.stringify(d)))
	var b2: Dictionary = w2.buildings[str(b.id)]
	check(b2.has("front") and b2.has("shop") and int(b2.shop.stock.herbal_poultice) == 4 and m2.is_solid(c0), "after loading: the counter, the shop and its stock")
	# closing keeps the counter; it opens again for the licence only
	biz.close(b.shop, "Closed.")
	check(not b.has("shop") and b.has("front") and w.map.is_solid(c0) and p.inv.count("herbal_poultice") == 4, "closing returns the goods and keeps the counter")
	check(biz.open_front(b) == "" and b.has("shop"), "it opens again, no materials needed")


## B14: an industrious villager buys the materials with their own coins and builds a storefront at their
## house; a keeper takes the household's surplus to it; a hurt neighbour buys medicine there.
func test_villager_storefront() -> void:
	var w := new_world()
	_evening(w)
	var n: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 0 and o.home != "" and o.job != "sage" and w.buildings.has(o.home) \
				and w.holds(World.hh_ref(o.household), w.buildings[o.home]) and w.business.front_place(w.buildings[o.home]).size() > 0:
			n = o
			break
	check(n != null, "a villager whose household holds a house with room for a counter")
	var house: Dictionary = w.buildings[n.home]
	var pantry: Inventory = w.households[n.household].pantry
	n.plan.clear()
	n.hunger = 100.0
	n.hp = n.max_hp
	n.inv.items.clear()
	pantry.items.erase("herbal_poultice")
	pantry.add("herbal_poultice", int(NPCBrain.hp_cfg().poultice_keep))
	n.coins = int(NPCBrain.hp_cfg().storefront_coins) - 1
	check(not w.brain._plan_storefront(n, house), "below storefront_coins of their own they do not build")
	n.coins = 200
	check(w.brain._plan_storefront(n, house) and n.plan[-1].get("act", "") == "build_front", "with coins and medicine in store they set out to build: " + n.doing)
	var total := w.total_coins()
	var c0 := n.coins
	for st: Dictionary in n.plan:
		if st.get("act", "") == "buy_from":
			check(w.brain.act(n, "buy_from", st.args), "bought %d %s from %s" % [int(st.args.qty), st.args.item, w.npc(int(st.args.vendor)).name])
	check(n.inv.has_all(Business.storefront_cost()) and n.coins < c0 and w.total_coins() == total, "the materials were bought with their own coins (%d), none from nowhere" % (c0 - n.coins))
	check(w.brain.act(n, "build_front", {}) and house.has("front") and n.inv.total() == 0, "built: the materials are used up")
	var f: Dictionary = house.front
	check(w.map.is_solid(Vector2i(int(f.x), int(f.y))), "the counter stands by the door")
	check(not w.brain.act(n, "build_front", {}), "a second storefront is not built")
	# keeping it: the household's surplus goes to the counter
	pantry.add("herbal_poultice", 3)
	pantry.add("red_berries", int(NPCBrain.hp_cfg().berries_keep) + 2)
	n.plan.clear()
	check(w.brain._plan_storefront(n, house) and n.doing.contains("storefront"), "an adult goes to keep it: " + n.doing)
	check(n.inv.count("herbal_poultice") == 3 and n.inv.count("red_berries") == 2 and pantry.count("herbal_poultice") == int(NPCBrain.hp_cfg().poultice_keep) \
			and pantry.count("red_berries") == int(NPCBrain.hp_cfg().berries_keep), "only the surplus goes; the household keeps its own")
	n.pos = Vector2(int(f.use[0]) + 0.5, int(f.use[1]) + 0.5)
	n.plan.clear()
	n.target = -1
	check(w.at_post(n) and w.shop_name(n).contains("storefront"), "at the counter they serve as a shop: " + w.shop_name(n))
	check(w.brain.for_sale(n).has("herbal_poultice"), "poultices are for sale")
	var other: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 0 and o.household != n.household and o.job != "sage":
			other = o
			break
	check(not w.brain._plan_storefront(other, house), "another household's adult does not keep it")
	other.plan.clear()
	other.hp = other.max_hp * 0.3
	other.coins = 50
	other.pos = n.pos + Vector2(1, 2)
	for m in NPCBrain.MEDICINES:
		other.inv.items.erase(m)
		if other.household >= 0:
			w.households[other.household].pantry.items.erase(m)
	check(w.brain._plan_heal(other) and other.plan.any(func(s): return s.get("act", "") == "buy_from" and int(s.args.vendor) == n.id), "a hurt neighbour buys medicine at the storefront")
	var buy: Dictionary = other.plan.filter(func(s): return s.get("act", "") == "buy_from")[0]
	total = w.total_coins()
	var k0 := n.coins
	check(w.brain.act(other, "buy_from", buy.args) and n.coins > k0 and w.total_coins() == total, "the keeper is paid (%d coins), coins conserved" % (n.coins - k0))


## B14 carts: the carpenter saws wheels and the smith forges the axle and ironwork from their own stock.
func test_cart_parts() -> void:
	var w := new_world()
	var c: NPC = w.brain._first_with_job("carpenter")
	c.plan.clear()
	c.inv.items.erase("cart_wheel")
	c.inv.items.erase("handcart")
	c.inv.items["plank"] = 10
	check(w.brain._carpenter_carts(c) and c.plan[-1].args.get("recipe", "") == "make_cart_wheel", "the carpenter with planks to spare makes a cart wheel: " + c.doing)
	check(w.brain.act(c, "craft", c.plan[-1].args) and c.inv.count("cart_wheel") == 1 and c.inv.count("plank") == 7, "three planks became a wheel")
	c.inv.items["plank"] = 4
	c.plan.clear()
	check(not w.brain._carpenter_carts(c), "short of planks (%d) the carpenter saws planks first" % c.inv.count("plank"))
	var s: NPC = w.brain._first_with_job("smith")
	for id in s.inv.ids():
		if id != "hammer":
			s.inv.items.erase(id)
	s.inv.items["iron_bar"] = 1
	s.inv.items["plank"] = 1
	s.plan.clear()
	check(w.brain._smith(s) and s.plan[-1].args.get("recipe", "") == "forge_cart_axle", "the smith with a bar and a plank forges an axle: " + s.doing)
	check(w.brain.act(s, "craft", s.plan[-1].args) and s.inv.count("cart_axle") == 1 and not s.inv.has("iron_bar"), "an iron bar and a plank became an axle")
	s.inv.items["iron_bar"] = 1
	s.inv.items["coal"] = 1
	s.plan.clear()
	check(w.brain._smith(s) and s.plan[-1].args.get("recipe", "") == "forge_cart_ironwork", "then the ironwork from a bar and coal: " + s.doing)
	check(w.brain.act(s, "craft", s.plan[-1].args) and s.inv.count("cart_ironwork") == 1, "made")
	# the carpenter, with wheels and planks, buys the smith's axle and ironwork and builds a handcart to sell
	c.inv.items["cart_wheel"] = 2
	c.inv.items["plank"] = 10
	c.coins = 200
	c.plan.clear()
	var total := w.total_coins()
	check(w.brain._carpenter_carts(c) and c.plan.any(func(st): return st.get("act", "") == "buy_from" and st.args.item == "cart_axle"), "the carpenter goes to the smith for the axle and ironwork: " + c.doing)
	for st: Dictionary in c.plan:
		if st.get("act", "") == "buy_from":
			w.brain.act(c, "buy_from", st.args)
	check(c.inv.has_all(GameData.recipes.build_handcart["in"]) and w.total_coins() == total and not s.inv.has("cart_axle"), "bought with the carpenter's coins; coins conserved")
	c.plan.clear()
	check(w.brain._carpenter_carts(c) and c.plan[-1].args.get("recipe", "") == "build_handcart", "and assembles a handcart at the workbench: " + c.doing)
	check(w.brain.act(c, "craft", c.plan[-1].args) and c.inv.count("handcart") == 1 and not c.inv.has("cart_axle"), "the parts became a handcart")
	check(w.brain.for_sale(c).has("handcart"), "it is for sale at the carpenter's")


## A storefront household's adult assembles a handcart from bought parts, or buys a finished one when cheaper.
func test_household_cart() -> void:
	var w := new_world()
	_evening(w)
	var n: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 0 and o.home != "" and not o.job in ["sage", "carpenter", "smith"] and w.buildings.has(o.home) \
				and w.holds(World.hh_ref(o.household), w.buildings[o.home]) and w.business.front_place(w.buildings[o.home]).size() > 0:
			n = o
			break
	var house: Dictionary = w.buildings[n.home]
	n.plan.clear()
	n.inv.items.clear()
	n.coins = 400
	check(not w.brain._plan_cart(n, house), "a household without a storefront does not want a cart")
	house["front"] = w.business.front_place(house)
	var c: NPC = w.brain._first_with_job("carpenter")
	var s: NPC = w.brain._first_with_job("smith")
	c.inv.items["cart_wheel"] = 2
	c.inv.items["plank"] = 20
	c.inv.items.erase("handcart")
	s.inv.items["cart_axle"] = 1
	s.inv.items["cart_ironwork"] = 1
	check(w.brain._plan_cart(n, house) and n.plan.any(func(st): return st.get("act", "") == "craft"), "with no cart for sale they buy the parts to assemble one: " + n.doing)
	var total := w.total_coins()
	for st: Dictionary in n.plan:
		if st.get("act", "") in ["buy_from", "craft", "store_home"]:
			w.brain.act(n, st.act, st.args)
	var parked: Array = w.carts.of(World.hh_ref(n.household))
	check(parked.size() == 1 and w.brain.household_cart(n.household) and w.total_coins() == total, "assembled from bought parts; the cart is set down at the house")
	check(Vector2i(parked[0].pos) == w.brain.cart_spot(n.home) and not w.households[n.household].pantry.has("handcart"), "parked by the door")
	n.plan.clear()
	check(not w.brain._plan_cart(n, house), "a household with a cart wants no other")
	# a finished cart for sale and no parts: they buy it
	w.carts.carts.clear()
	c.inv.items.erase("cart_wheel")
	c.inv.items["handcart"] = 1
	n.coins = 400
	n.plan.clear()
	check(w.brain._plan_cart(n, house) and n.plan.any(func(st): return st.get("act", "") == "buy_from" and st.args.item == "handcart"), "with the parts not to be had they buy the carpenter's handcart: " + n.doing)
	var c0 := n.coins
	for st: Dictionary in n.plan:
		if st.get("act", "") in ["buy_from", "store_home"]:
			w.brain.act(n, st.act, st.args)
	check(w.carts.of(World.hh_ref(n.household)).size() == 1 and c0 - n.coins >= int(GameData.item("handcart").value) / 2, "bought for %d coins" % (c0 - n.coins))
	n.coins = int(GameData.b("carts").cart_coins) - 1
	w.carts.carts.clear()
	n.plan.clear()
	check(not w.brain._plan_cart(n, house), "below cart_coins they wait")


## Twelve days: the cart trades make parts from the village's own materials; coins conserved.
func test_cart_days() -> void:
	var w := new_world()
	var start := w.total_coins()
	var steps := int(12.0 * 1440.0 / float(GameData.b("game_minutes_per_second")) / 0.5)
	for i in steps:
		w.update(0.5)
	var st: Dictionary = w.stats
	print("  cart stats: ", {"wheels": st.get("made_cart_wheel", 0), "axles": st.get("made_cart_axle", 0), "ironwork": st.get("made_cart_ironwork", 0),
		"handcarts": st.get("made_handcart", 0), "storefronts": st.get("storefront_built_villager", 0)})
	check(int(st.get("made_cart_wheel", 0)) > 0 and int(st.get("made_cart_axle", 0)) > 0 and int(st.get("made_cart_ironwork", 0)) > 0, "over 12 days the carpenter and smith make cart parts")
	check(w.total_coins() == start + w.coin_sources, "coins conserved (%d + sources %d = %d)" % [start, w.coin_sources, w.total_coins()])


## B14: a seller's asking price follows what else is for sale within local_supply.radius: a lone seller asks
## the scarcity price, many sellers nearby bring it down; buying the parts beats a lone finished cart, and
## goods the player puts up for sale nearby lower the villagers' price.
func test_local_pricing() -> void:
	var w := new_world()
	var c: NPC = w.brain._first_with_job("carpenter")
	var cfg: Dictionary = GameData.b("local_supply")
	for o: NPC in w.npcs:
		if o != c:
			o.inv.items.erase("handcart")
			o.inv.items.erase("cart_wheel")
	c.inv.items["handcart"] = 1
	var lone := w.sell_price(c, "handcart")
	check(w.local_supply("handcart", c.pos, c) == 0 and lone == World.sell_price_at("handcart", 1), "a lone handcart seller asks the scarcity price (%d for a cart worth %d)" % [lone, int(GameData.item("handcart").value)])
	var rec: Dictionary = GameData.recipes.build_handcart
	var parts := 0
	for id in rec["in"]:
		parts += int(rec["in"][id]) * World.sell_price_at(id, 2)
	check(parts < lone, "the parts cost less (%d) than the lone finished cart (%d): making your own pays" % [parts, lone])
	# another trader near the carpenter with carts for sale
	var o: NPC = w.brain._first_with_job("smith")
	o.pos = c.pos + Vector2(3, 0)
	o.inv.items["handcart"] = 5
	var near := w.sell_price(c, "handcart")
	check(w.local_supply("handcart", c.pos, c) == 5 and near < lone, "with 5 more for sale nearby the carpenter asks less (%d)" % near)
	o.pos = c.pos + Vector2(float(cfg.radius) + 5.0, 0)
	check(w.sell_price(c, "handcart") == lone, "beyond the radius they do not count")
	# the player's stock for sale at a counter nearby lowers it as well
	o.inv.items.erase("handcart")
	var ids: Array = w.buildings.keys()
	ids.sort()
	var b: Dictionary = w.buildings[ids[0]]
	b["shop"] = {"shop": true, "id": str(b.id), "building": str(b.id), "x": int(c.pos.x) + 2, "y": int(c.pos.y), "use": [int(c.pos.x) + 2, int(c.pos.y) + 1], "stock": {"handcart": 10}, "prices": {}}
	var pl := w.sell_price(c, "handcart")
	check(pl < near and pl >= World.sell_price_at("handcart", 1, int(cfg.cap)), "10 carts on the player's counter nearby bring it to %d" % pl)
	b.erase("shop")
	# the player's quote follows the same local price
	w.player.coins = 1000
	check(w.player_quote(c, "handcart", 1, true)[0] == maxi(1, roundi(lone * w.player_price_factor(true))), "the player is quoted the same local price")


## B14 (asset pipeline: Craftpix fruit trees): apple trees in the cottagers' orchards bear apples in summer and
## autumn; the player and villagers pick them; they are felled and replanted like any tree; saved.
func test_apple_trees() -> void:
	var w := new_world()
	var apples: Array = w.trees.filter(func(t): return str(t.get("species", "")) == "apple_orchard")
	check(apples.size() >= 3, "the village has apple trees by its houses (%d)" % apples.size())
	check(apples.all(func(t): return not w._in_woods(Vector2i(int(t.x), int(t.y)))), "none in the woods")
	check(Trees.variant("apple_orchard").has("fruit") and ResourceLoader.exists("res://assets/trees/" + str(Trees.variant("apple_orchard").fruit.file)), "the fruit-tree art is loaded (Craftpix, via fruit_trees.json)")
	var t: Dictionary = apples[0]
	t.state = "grown"
	t.erase("fruit_day")
	w.minutes = 2.0 * 1440.0 + 600.0                 # day 2: summer
	check(w.season() == "Summer" and Trees.fruit_ripe(t, w.day(), w.season()), "a grown apple tree hangs with fruit in summer")
	var got := w.pick_fruit(t)
	check(int(got.get("apple", 0)) == int(GameData.b("fruit_trees").apple_orchard.yield), "picking gives %d apples" % int(got.get("apple", 0)))
	check(not Trees.fruit_ripe(t, w.day(), w.season()) and w.pick_fruit(t).is_empty(), "then it is bare: nothing from nowhere")
	w.minutes = float(int(t.fruit_day)) * 1440.0 + 600.0
	check(Trees.fruit_ripe(t, w.day(), w.season()) == (w.season() in ["Summer", "Autumn"]), "it bears again after regrow_seasons, in a fruiting season (%s)" % w.season())
	w.minutes = 6.0 * 1440.0 + 600.0                 # day 6: winter
	t.fruit_day = 0
	check(w.season() == "Winter" and not Trees.fruit_ripe(t, w.day(), w.season()), "no fruit in winter")
	# felled like any tree; its sapling plants an apple tree
	w.minutes = 2.0 * 1440.0 + 600.0
	check(Trees.sapling_item(str(t.species)) == "apple_sapling" and Trees.planted_species("apple_sapling", Vector2i(5, 5)) == "apple_orchard", "its sapling is an apple sapling and grows an apple tree")
	var logs := w.fell(t, 0)
	check(logs >= 4 and t.state == "stump", "felled for %d logs, leaving a stump" % logs)
	# a villager picks apples near home instead of a farther berry bush
	var w2 := new_world()
	w2.minutes = 2.0 * 1440.0 + 19.0 * 60.0
	var n: NPC = null
	var near_tree := {}
	for o: NPC in w2.npcs:
		if o.alive and o.role == "adult" and o.household >= 0 and o.home != "" and o.job != "sage":
			for at in w2.trees:
				if str(at.get("species", "")) == "apple_orchard" and Vector2(w2.building_door(o.home)).distance_to(Vector2(int(at.x), int(at.y))) <= 18.0:
					n = o
					near_tree = at
					break
		if n != null:
			break
	check(n != null, "a household lives by an apple tree")
	near_tree.state = "grown"
	near_tree.erase("fruit_day")
	for pl in w2.plants:
		pl.state = "picked"                          # no bushes in fruit: the apples are the household's food
	var pantry: Inventory = w2.households[n.household].pantry
	pantry.add("herbal_poultice", int(NPCBrain.hp_cfg().poultice_keep))
	for id in ["red_berries", "blueberries", "apple"]:
		pantry.items.erase(id)
	n.plan.clear()
	n.hp = n.max_hp
	n.coins = 0
	check(w2.brain._plan_home_work(n) and n.plan.any(func(st): return st.get("act", "") == "pick_fruit"), "the villager goes to pick apples: " + n.doing)
	var step: Dictionary = n.plan.filter(func(st): return st.get("act", "") == "pick_fruit")[0]
	check(w2.brain.act(n, "pick_fruit", step.args) and n.inv.has("apple"), "and picks them")
	w2.brain.act(n, "store_home", {})
	check(pantry.count("apple") == int(GameData.b("fruit_trees").apple_orchard.yield), "the apples go into the household's store")
	# saved
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w2.to_dict())))
	var again := w3.tree_at(Vector2i(int(near_tree.x), int(near_tree.y)))
	check(str(again.get("species", "")) == "apple_orchard" and int(again.get("fruit_day", 0)) == int(near_tree.fruit_day), "the apple tree and its fruit day are saved")


## B14-06 carts in play: pulling, who may use a cart, theft from it, the cart stop delivery, a market run, saving.
func test_carts_in_play() -> void:
	var w := new_world()
	var p := w.player
	var c: Dictionary = w.carts.place(World.PLAYER, p.pos + Vector2(1, 0))
	check(w.carts.of(World.PLAYER).size() == 1 and (c.store as Inventory).max_stacks == int(Carts.cfg().stacks), "a handcart set down is a cart in the world with %d stacks" % int(Carts.cfg().stacks))
	check(w.carts.hitch(c, World.PLAYER) == "" and w.carts.pulled_by(World.PLAYER) == c, "the player takes hold of their own cart")
	check(Carts.pull_speed() < 1.0, "pulling slows walking (x%.2f)" % Carts.pull_speed())
	p.pos += Vector2(5, 0)
	w.carts.update(0.1)
	check(absf((c.pos as Vector2).distance_to(p.pos) - float(Carts.cfg().trail)) < 0.01, "the cart follows a step behind on its rope")
	var stranger: NPC = w.npcs.filter(func(n): return n.alive and n.role == "adult" and not w.business.is_attendant(n))[0]
	w.carts.park(c)
	check(c.puller == "" and w.carts.hitch(c, World.npc_ref(stranger.id)) != "", "a villager who is not the player's hired help may not take it")
	# a household's cart: its members may pull it; the player taking from it is theft
	var n := _villager(w)
	var hc: Dictionary = w.carts.place(World.hh_ref(n.household), Vector2(w.brain.cart_spot(n.home)) + Vector2(0.5, 0.5))
	check(w.carts.hitch(hc, World.npc_ref(n.id)) == "" and w.carts.hitch(hc, World.PLAYER) != "", "a household member pulls the family cart; the player may not")
	w.carts.park(hc)
	(hc.store as Inventory).add("apple", 3)
	var u: Dictionary = w.chests.unit("cart:%d" % int(hc.id))
	check(w.chests.store(u, "apple", 1) != "", "the player cannot fill another's cart")
	var r: Dictionary = w.chests.take(u, "apple", 1)
	check(r.ok and r.get("theft", false) and p.inv.count("apple") >= 1, "taking from it is theft: " + str(r.text))
	# the player's cart at a cart stop near their stall: the attendant unloads it into the stall's store
	var b: Business = w.business
	p.coins = 300
	check(b.rent() == "", "the player rents a market pitch")
	var stall := b.mine()
	check(not stall.is_empty(), "the player has a pitch to deliver to")
	var a: NPC = b.candidates()[0]
	check(b.hire(stall, a) == "", "an attendant is hired")
	var stop: Dictionary = Carts.cfg().stops[0]
	c.pos = Vector2(float(stop.x) + 0.5, float(stop.y) + 0.5)
	(c.store as Inventory).add("herbal_poultice", 4)
	var near: bool = Vector2(int(stall.x), int(stall.y)).distance_to(c.pos) <= float(Carts.cfg().deliver_range)
	var before := int((stall.get("store", {}) as Dictionary).get("herbal_poultice", 0))
	w.carts.hour()
	var after := int((stall.get("store", {}) as Dictionary).get("herbal_poultice", 0))
	if near:
		check(after == before + 4 and (c.store as Inventory).total() == 0, "parked at %s, the attendant unloads the cart into the stall's store" % stop.name)
	else:
		check(after == before and (c.store as Inventory).total() == 4, "a stop beyond deliver_range of the stall is not served")
	c.pos = p.pos + Vector2(30, 30)
	(c.store as Inventory).add("apple", 2)
	w.carts.hour()
	check((c.store as Inventory).count("apple") == 2, "away from a cart stop nothing is unloaded")
	# saved and loaded whole
	c.puller = World.PLAYER
	var d := w.carts.to_dict()
	var back := Carts.new(w)
	back.load_dict(JSON.parse_string(JSON.stringify(d)))
	var c2: Dictionary = back.by_id(int(c.id))
	check(back.carts.size() == w.carts.carts.size() and back.next_id == w.carts.next_id and str(c2.owner) == World.PLAYER and str(c2.puller) == World.PLAYER
			and (c2.store as Inventory).count("apple") == 2 and (c2.pos as Vector2).distance_to(c.pos) < 0.001, "carts save and load with owner, puller, position and load")
	# a household's market run: surplus goods ride to the merchants and the cart comes home
	var w2 := new_world()
	w2.minutes = 2.0 * 1440.0 + 9.0 * 60.0
	var m := _villager(w2)
	var house: Dictionary = w2.buildings[m.home]
	var cart: Dictionary = w2.carts.place(World.hh_ref(m.household), Vector2(w2.brain.cart_spot(m.home)) + Vector2(0.5, 0.5))
	var pantry: Inventory = w2.households[m.household].pantry
	pantry.add("apple", int(GameData.b("home_production").berries_keep) + int(Carts.cfg().trip_min) + 2)
	var total := w2.total_coins()
	check(w2.brain._plan_market_run(m, house), "with surplus apples and a parked cart the household plans a market run: " + m.doing)
	var sold0: int = pantry.count("apple")
	var pulled := false
	for i in int(6.0 * 60.0 / float(GameData.b("game_minutes_per_second")) / 0.5):
		w2.update(0.5)
		pulled = pulled or str(cart.puller) != ""
		if pulled and str(cart.puller) == "":
			break
	check(pulled, "a household member took the cart")
	check(str(cart.puller) == "" and (cart.store as Inventory).total() == 0, "the cart came home parked and empty")
	check(pantry.count("apple") < sold0 and w2.total_coins() == total + w2.coin_sources, "apples were sold (%d left at home), coins conserved" % pantry.count("apple"))
