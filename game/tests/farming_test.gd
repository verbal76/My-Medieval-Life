extends SceneTree
## PL2-015: farming, livestock and manual plowing by the player. Land the player holds is cleared (tree, stump,
## sapling, wild plant, boulder), tilled by hand and with the hand plough (time and stamina differ), sown,
## grown through the days and the seasons, harvested with seed saving; a pen is fenced, animals bought from the
## keeper, fed, bred, their eggs, milk and wool collected and sold; everything survives a save. Pure World.
## Run: godot --headless --path game --script res://tests/farming_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func new_world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


func _init() -> void:
	test_data()
	test_land_and_clearing()
	test_tilling()
	test_crops()
	test_pens_and_animals()
	test_market()
	test_save()
	test_village_chain()
	test_propagation()
	test_perennials()
	test_household_seed()
	test_seed_seller()
	test_crop_view()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## Open ground of the player's: a parcel claimed on clear land, the trees around it felled (felling is its own
## mechanic, tree_test.gd). Returns the parcel.
func farm_land(w: World) -> Dictionary:
	w.player.coins = 3000
	for t in w.trees:
		t.state = "cleared"
		w.map.set_solid(Vector2i(int(t.x), int(t.y)), false)
	var rect := w.construction.find_ground("house", Vector2i(30, 30), World.PLAYER)
	var pl: Dictionary = w.property.claim(rect, World.PLAYER, false)
	check(not pl.is_empty() and w.holds(World.PLAYER, pl), "the player holds a parcel of open ground (%s)" % w.property.why)
	return pl


func cell_in(pl: Dictionary, i: int, j: int) -> Vector2i:
	return Vector2i(int(pl.x) + i, int(pl.y) + j)


func test_data() -> void:
	GameData.ensure()
	var f: Dictionary = Farming.cfg()
	for crop in f.crops:
		var c: Dictionary = f.crops[crop]
		check(GameData.items.has(str(c.seed)) and GameData.items.has(str(c.item)) and int(c.seeds_back) >= 1, "%s: its seed and its produce are items, and a harvest returns seed" % crop)
		check(FileAccess.file_exists("res://assets/icons/%s.png" % c.seed) and FileAccess.file_exists("res://assets/icons/%s.png" % c.item), "%s: both have an icon" % crop)
	for item in ["plough", "egg", "milk", "wool", "wool_cloth", "cheese"]:
		check(GameData.items.has(item) and FileAccess.file_exists("res://assets/icons/%s.png" % item), "%s is an item with an icon" % item)
	check(GameData.recipes.has("craft_plough") and GameData.recipes.craft_plough.station == "workbench" and GameData.recipes.craft_plough["in"].has("plank") and GameData.recipes.craft_plough["in"].has("iron_bar"), "the plough is made at the workbench from planks and iron")
	check(float(f.till.plough.seconds) < float(f.till.hand.seconds) and float(f.till.plough.stamina) < float(f.till.hand.stamina), "tilling by hand is slower and costs more stamina than with the plough")
	check(f.season_rate.Winter == 0.0 and f.season_rate.Autumn < f.season_rate.Spring and not (f.sow_seasons as Array).has("Winter"), "no growth or sowing in winter, slower growth in autumn")


func test_land_and_clearing() -> void:
	var w := new_world()
	var p := w.player
	var pl := farm_land(w)
	var inside := cell_in(pl, 1, 1)
	check(w.farm.land_refusal(Vector2i(2, 2)) != "" and w.farm.land_refusal(inside) == "", "ground outside the parcel is refused, inside it is open")
	var other: Dictionary = w.plots[0]
	check(w.farm.till_refusal(Vector2i(int(other.x) + 1, int(other.y) + 1), p).begins_with("That is not your land"), "the manor's unsold plot cannot be tilled")
	w.property.lease(other, World.PLAYER)
	check(w.farm.parcel_at(Vector2i(int(other.x) + 1, int(other.y) + 1)) == other, "leased ground counts as the player's")
	w.property.end_lease(other, World.PLAYER)
	# a stump, a sapling, a bush, a boulder, a grown tree
	var tcell := cell_in(pl, 2, 2)
	var tree := {"x": tcell.x, "y": tcell.y, "species": "oak_summer", "state": "stump", "regrow": 9999.0, "born": 0.0, "trunk": 0, "top": 0, "bottom": 0}
	w.trees.append(tree)
	check(w.farm.till_refusal(tcell, p).begins_with("Clear"), "a stump stands in the way of the plough")
	p.inv.items.erase("axe")
	check(w.farm.clear_tree_refusal(tree, p) != "" and w.farm.targets_at(tcell, p)[0].act == "clear_tree", "digging out a stump needs an axe; the action is offered")
	p.inv.add("axe")
	var s0 := p.stamina
	check(w.farm.clear_tree(tree, p) == "" and tree.state == "cleared" and p.stamina < s0 and not w.map.is_solid(tcell), "the stump is dug out with the axe (stamina spent), the ground is cleared for good")
	check(w.farm.obstacle(tcell).is_empty(), "nothing stands there now")
	var scell := cell_in(pl, 3, 2)
	var sap := {"x": scell.x, "y": scell.y, "species": "oak_summer", "state": "sapling", "regrow": 0.0, "born": w.minutes, "trunk": 0, "top": 0, "bottom": 0}
	w.trees.append(sap)
	check(w.farm.clear_tree_refusal(sap, p) == "" and w.farm.clear_tree(sap, p) == "" and sap.state == "cleared", "a sapling is pulled up by hand")
	var young_hand := PlayerState.new()
	young_hand.inv.items.erase("axe")
	var big := {"x": cell_in(pl, 4, 2).x, "y": cell_in(pl, 4, 2).y, "species": "oak_summer", "state": "grown", "regrow": 0.0, "born": -1.0e7, "trunk": 0, "top": 0, "bottom": 0}
	w.trees.append(big)
	check(w.farm.clear_tree_refusal(big, p).begins_with("Fell the tree first"), "a mature tree is felled first, as anywhere (the axe), then its stump dug out")
	var bcell := cell_in(pl, 5, 3)
	var plant := {"id": "t_plant", "x": bcell.x, "y": bcell.y, "kind": "flower", "tile": 1, "state": "ripe", "regrow": 0.0}
	w.plants.append(plant)
	check(w.farm.obstacle(bcell).kind == "plant" and w.farm.clear_plant(plant) == "" and w.farm.obstacle(bcell).is_empty(), "a wild plant is grubbed up")
	var rcell := cell_in(pl, 6, 4)
	var rock := {"x": rcell.x, "y": rcell.y, "ore": "stone", "amount": 2, "boulder": true}
	w.boulders.append(rock)
	w.map.set_solid(rcell, true)
	check(w.farm.obstacle(rcell).kind == "boulder" and w.farm.till_refusal(rcell, p).begins_with("Clear"), "a boulder blocks the plough")
	while int(rock.amount) > 0:
		w.mine_unit(rock)
	check(w.farm.obstacle(rcell).is_empty() and w.farm.till_refusal(rcell, p) == "", "mined away, the cell can be tilled")
	# the same through the target the player uses
	w.trees.append({"x": cell_in(pl, 7, 5).x, "y": cell_in(pl, 7, 5).y, "species": "oak_summer", "state": "stump", "regrow": 9999.0, "born": 0.0, "trunk": 0, "top": 0, "bottom": 0})
	var tg: Dictionary = w.farm.targets_at(cell_in(pl, 7, 5), p)[0]
	var pn: Dictionary = w.farm.plan(tg, p)
	check(pn.ok and float(pn.secs) == float(Farming.cfg().clear.stump_seconds) and pn.run.call().text == "" and w.farm.obstacle(cell_in(pl, 7, 5)).is_empty(), "the clear action runs through plan() like in play")


func test_tilling() -> void:
	var w := new_world()
	var p := w.player
	var pl := farm_land(w)
	var c1 := cell_in(pl, 1, 1)
	var hand: Dictionary = w.farm.till_cost(p)
	check(float(hand.seconds) == float(Farming.cfg().till.hand.seconds), "no plough: the by-hand cost")
	p.stamina = 10.0
	check(w.farm.till_refusal(c1, p).contains("too tired"), "too tired to dig by hand with 10 stamina")
	p.stamina = p.stamina_cap()
	var before := p.stamina
	check(w.farm.till(c1, p) == "" and w.farm.cells.has(c1), "a cell is tilled by hand")
	var hand_spent := before - p.stamina
	check(is_equal_approx(hand_spent, float(hand.stamina)), "by hand it cost %.0f stamina" % hand_spent)
	p.inv.add("plough")
	var pc: Dictionary = w.farm.till_cost(p)
	p.stamina = p.stamina_cap()
	var c2 := cell_in(pl, 2, 1)
	check(w.farm.till(c2, p) == "", "a cell is tilled with the plough")
	var plough_spent := p.stamina_cap() - p.stamina
	check(is_equal_approx(plough_spent, float(pc.stamina)) and plough_spent < hand_spent and float(pc.seconds) < float(hand.seconds), "with the plough: %.1f s and %.0f stamina against %.1f s and %.0f by hand" % [float(pc.seconds), plough_spent, float(hand.seconds), hand_spent])
	check(p.inv.has("plough") and GameData.item("plough").durability > 0, "the plough wears (a durable tool)")
	# any shape: an L and a loose cell
	for ij in [[3, 1], [3, 2], [3, 3], [6, 6]]:
		p.stamina = p.stamina_cap()
		check(w.farm.till(cell_in(pl, ij[0], ij[1]), p) == "", "cell %s joins the field" % str(ij))
	check(w.farm.cells.size() == 6, "the field is six cells in an odd shape")
	check(w.farm.till(c1, p) == "Already tilled.", "a tilled cell is not tilled again")
	check(w.farm.tile_for(cell_in(pl, 6, 6)) != w.farm.tile_for(cell_in(pl, 3, 2)), "the lone cell and a middle cell are drawn with different edge tiles")
	# the village keeps off it
	var r := Rect2i(c1 - Vector2i(1, 1), Vector2i(4, 4))
	check(w.property.can_claim(r) != "", "nobody claims ground that holds the player's field")
	var f0 := w.fields.size()
	for i in 200:
		w.update(0.5)
	check(w.fields.size() == f0 and w.farm.cells.size() == 6, "the village's farmers leave the player's cells alone over a long run")


func grow_hours(w: World, n: int) -> void:
	for i in n:
		w.minutes += 60.0
		w.farm.hour()


func test_crops() -> void:
	var w := new_world()
	var p := w.player
	var pl := farm_land(w)
	p.inv.add("plough")
	var c := cell_in(pl, 1, 1)
	w.farm.till(c, p)
	check(w.season() == "Spring", "the world starts in spring")
	p.inv.items.erase("wheat_seed")
	check(w.farm.sow(c, "wheat", p).contains("no wheat seed"), "no seed, no sowing")
	# seeds from a farmer
	var farmer: NPC = null
	for n: NPC in w.npcs:
		if n.job == "farmer" and n.alive:
			farmer = n
			break
	check(farmer != null and w.farm.seed_offers(farmer).has("wheat"), "a farmer sells seed")
	var coins0 := p.coins
	var fc0 := farmer.coins
	var fs0 := farmer.inv.count("wheat_seed")
	check(fs0 == int(Farming.seed_cfg().seed_stock.farmer.wheat_seed), "a farmer starts with seed stock of their own (%d)" % fs0)
	check(not w.brain.for_sale(farmer).has("wheat_seed"), "seed is not sold as ordinary goods, only through the seed offer")
	check(w.farm.buy_seed(farmer, "wheat", 5, p) == "" and p.inv.count("wheat_seed") == 5 and p.coins == coins0 - 5 * w.farm.seed_price("wheat") and farmer.coins == fc0 + 5 * w.farm.seed_price("wheat"), "five seeds bought from the farmer with real coins")
	# Build 13 economy rule 3: seed comes out of the seller's stock, never from nowhere
	check(farmer.inv.count("wheat_seed") == fs0 - 5, "the farmer's seed stock fell by the five sold")
	var p_seed := p.inv.count("wheat_seed")
	var pc := p.coins
	check(w.farm.buy_seed(farmer, "wheat", fs0, p) != "" and p.inv.count("wheat_seed") == p_seed and p.coins == pc, "buying more than the farmer holds is refused whole")
	farmer.inv.remove("wheat_seed", farmer.inv.count("wheat_seed"))
	check(not w.farm.seed_offers(farmer).has("wheat") and w.farm.buy_seed(farmer, "wheat", 1, p) != "" and p.coins == pc, "a farmer with no seed left offers none")
	# farmers save seed from their harvest: taken from the crop, up to the cap
	var cut: int = w.farm.save_seed(farmer, 10)
	check(cut == 10 - int(Farming.seed_cfg().seed_keep) and farmer.inv.count("wheat_seed") == int(Farming.seed_cfg().seed_keep), "a farmer cutting 10 wheat keeps %d back as seed" % int(Farming.seed_cfg().seed_keep))
	farmer.inv.add("wheat_seed", int(Farming.seed_cfg().seed_cap))
	var held := farmer.inv.count("wheat_seed")
	check(w.farm.save_seed(farmer, 10) == 10 and farmer.inv.count("wheat_seed") == held, "with a full seed store the whole crop stays grain")
	farmer.inv.remove("wheat_seed", held - fs0)
	var merchant: NPC = null
	for n: NPC in w.npcs:
		if n.job == "merchant" and w.stalls.get(n.workplace, {}).get("kind", "") == "food":
			merchant = n
			break
	check(merchant != null and w.farm.seed_offers(merchant).has("carrot"), "the food stall's merchant sells seed too")
	# the caravan resupplies the food merchant's seed from the merchant's own coins (coins leave the village)
	var cs0 := merchant.inv.count("carrot_seed")
	merchant.inv.remove("carrot_seed", cs0)
	merchant.coins = 200
	for o: NPC in w.npcs:                         # only this merchant can pay, so the sums are theirs
		if o != merchant and o.job == "merchant" and w.farm.sells_seed(o):
			o.coins = w.reserve_of(o)             # nothing to spare above their reserve (OD-19)
	var src0 := w.coin_sources
	var tot0 := w.total_coins()
	var spent: int = w.brain._caravan_seeds()
	check(spent > 0 and merchant.inv.count("carrot_seed") > 0 and merchant.coins == 200 - spent and w.coin_sources == src0 - spent and w.total_coins() == tot0 - spent, "the caravan sells the merchant seed for %d coins of their own" % spent)
	merchant.coins = w.reserve_of(merchant)
	var mseed := merchant.inv.total()
	check(w.brain._caravan_seeds() == 0 and merchant.inv.total() == mseed, "a merchant without spare coins gets no seed: never from nowhere")
	merchant.coins = 200
	check(w.farm.sow(c, "wheat", p) == "" and w.farm.cells[c].state == "growing" and p.inv.count("wheat_seed") == 4, "the cell is sown: one seed used")
	var days := Farming.crop_days("wheat")
	grow_hours(w, int(days * 24.0) - 2)
	check(w.farm.cells[c].state == "growing" and float(w.farm.cells[c].progress) < 1.0, "still growing two hours short of %.0f days in spring" % days)
	grow_hours(w, 3)
	check(w.farm.cells[c].state == "ripe", "ripe after %.0f days of spring growth" % days)
	var wheat0 := p.inv.count("wheat")
	var seed0 := p.inv.count("wheat_seed")
	var got: Dictionary = w.farm.harvest(c, p)
	var cr: Dictionary = Farming.crops().wheat
	check(int(got.get("wheat", 0)) == int(cr.yield) and p.inv.count("wheat") == wheat0 + int(cr.yield), "harvest gives the wheat (%d)" % int(cr.yield))
	check(p.inv.count("wheat_seed") == seed0 + int(cr.seeds_back) and w.farm.cells[c].state == "tilled", "seed saving: part of the harvest returns as seed, the cell is empty tilled soil again")
	check(w.farm.sow(c, "wheat", p) == "", "the saved seed sows it again, no purchase needed")
	# seasons: autumn grows slower, winter not at all and cannot be sown
	var c2 := cell_in(pl, 2, 1)
	p.stamina = 100.0
	w.farm.till(c2, p)
	var spring_p: float = float(w.farm.cells[c].progress)
	w.minutes = 4.0 * 1440.0 + 7.0 * 60.0
	check(w.season() == "Autumn", "day 5 is autumn")
	var a0 := float(w.farm.cells[c].progress)
	grow_hours(w, 24)
	var autumn_gain: float = float(w.farm.cells[c].progress) - a0
	w.minutes = 6.0 * 1440.0 + 7.0 * 60.0
	check(w.season() == "Winter" and not w.farm.can_sow_now(), "day 7 is winter: nothing can be sown")
	p.inv.add("carrot_seed")
	check(w.farm.sow(c2, "carrot", p).contains("winter"), "sowing in winter is refused")
	var w0 := float(w.farm.cells[c].progress)
	grow_hours(w, 20)
	check(float(w.farm.cells[c].progress) == w0, "nothing grows in winter")
	w.minutes = 0.0 * 1440.0 + 7.0 * 60.0
	var s0 := float(w.farm.cells[c].progress)
	grow_hours(w, 24)
	var spring_gain: float = float(w.farm.cells[c].progress) - s0
	check(autumn_gain > 0.0 and autumn_gain < spring_gain and is_equal_approx(autumn_gain / spring_gain, float(Farming.cfg().season_rate.Autumn)), "autumn growth is %.2f of spring's (%.3f against %.3f a day)" % [autumn_gain / spring_gain, autumn_gain, spring_gain])
	check(spring_p == 0.0, "(a freshly sown cell starts at nothing)")
	# a crop sown in the last autumn day ripens only after winter has passed
	w.minutes = 5.0 * 1440.0 + 20.0 * 60.0
	var c3 := cell_in(pl, 3, 1)
	p.stamina = 100.0
	w.farm.till(c3, p)
	p.inv.add("herb_seed")
	check(w.farm.sow(c3, "herb", p) == "", "a herb is sown in autumn")
	var weeks := 0
	while w.farm.cells[c3].state != "ripe" and weeks < 400:
		w.minutes += 60.0
		w.farm.hour()
		weeks += 1
	check(w.farm.cells[c3].state == "ripe" and weeks > int(Farming.crop_days("herb") * 24.0), "it ripens later than a spring sowing (%d hours: winter paused it)" % weeks)
	var flower0 := p.inv.count("flower")
	check(w.farm.harvest(c3, p).has("flower") and p.inv.count("flower") > flower0, "the herb harvest is the flower the sage uses")
	# the one seed in the pack of each crop is offered by the targets; a ripe cell offers a harvest
	var tl: Array = w.farm.targets_at(c2, p)
	check(tl.size() >= 1 and tl[0].act == "sow", "a tilled cell with seed in the pack offers to sow it")
	# a full pack stops a harvest, not the crop
	w.farm.cells[c2] = {"crop": "wheat", "state": "ripe", "progress": 1.0}
	for i in 200:
		if not p.inv.add("log"):
			break
	check(not w.farm.plan(w.farm.targets_at(c2, p)[0], p).ok or p.inv.can_add("wheat"), "a harvest needs room in the pack")


func test_pens_and_animals() -> void:
	var w := new_world()
	var p := w.player
	var pl := farm_land(w)
	var spot := Vector2(float(pl.x) + 4.5, float(pl.y) + 8.5)
	p.pos = spot
	var rect: Rect2i = w.farm.pen_rect_ahead("chicken", p.pos, Vector2.UP)
	check(w.farm.pen_refusal("chicken", rect, p).contains("planks"), "a pen needs planks (%s)" % w.farm.pen_refusal("chicken", rect, p))
	p.inv.add("plank", 20)
	var far := Rect2i(Vector2i(1, 1), rect.size)
	check(w.farm.pen_refusal("chicken", far, p) != "", "a pen cannot go on ground that is not the player's")
	var planks0 := p.inv.count("plank")
	var pen: Dictionary = w.farm.build_pen("chicken", rect, p)
	check(not pen.is_empty() and w.fauna.pens.has(pen.id) and p.inv.count("plank") == planks0 - w.farm.pen_planks(rect), "the chicken pen is fenced for %d planks (%s)" % [w.farm.pen_planks(rect), w.farm.pen_why])
	var gate := Vector2i(int(pen.gate[0]), int(pen.gate[1]))
	check(w.map.is_solid(Vector2i(rect.position.x, rect.position.y + 1)) and not w.map.is_solid(gate) and not w.map.is_solid(rect.position + Vector2i(2, 2)), "the fence is solid, the gate and the inside are open")
	check(w.owner_of(pen) == World.PLAYER and w.farm.player_pens().size() == 1 and w.fauna.cells(pen.id).size() == (rect.size.x - 2) * (rect.size.y - 2), "it is the player's; animals may stand on its %d inner cells" % w.fauna.cells(pen.id).size())
	# buying from the keeper's pen: real stock, real coins
	var src: Dictionary = w.fauna.pen_of("chicken")
	var keeper: NPC = w.pen_keeper(src)
	var n0 := w.fauna.count(src.id, "chicken")
	for i in 4:
		var extra: Animal = w.fauna.spawn(src.id, "chicken", "f" if i % 2 == 0 else "m", null)
		extra.born = w.minutes - 5.0 * 1440.0
	var spare_f := w.farm.spare_animal(src, "f")
	var spare_m := w.farm.spare_animal(src, "m")
	check(spare_f != null and spare_m != null, "the keeper has a hen and a cock to spare")
	var coins0 := p.coins
	var kc0 := keeper.coins if keeper else w.treasury
	var price := w.farm.animal_price(spare_f)
	var before := w.fauna.count(src.id, "chicken")
	check(w.farm.buy_animal(src, "f", p) == "" and p.coins == coins0 - price, "a hen is bought for %d coins" % price)
	check(w.fauna.count(src.id, "chicken") == before - 1 and w.fauna.count(pen.id, "chicken") == 1, "she came out of the keeper's pen into the player's")
	check((keeper.coins if keeper else w.treasury) == kc0 + price, "the keeper got the coins (no coin was made)")
	check(w.farm.buy_animal(src, "m", p) == "", "a cock is bought")
	check(w.farm.buy_animal(w.fauna.pens[pen.id], "m", p) == "That is your own pen." and w.farm.buy_refusal(w.fauna.pen_of("cow"), "f", p).contains("cow pen"), "no pen of that kind, no purchase; your own pen sells nothing")
	# feeding
	var hen: Animal = null
	var cock: Animal = null
	for a: Animal in w.fauna.animals:
		if a.area == pen.id:
			if a.sex == "f":
				hen = a
			else:
				cock = a
	hen.born = w.minutes - 5.0 * 1440.0
	cock.born = w.minutes - 5.0 * 1440.0
	hen.hunger = 10.0
	p.inv.add("wheat", 6)
	check(w.fauna.feed(pen, p.inv, 4) == 4 and int(pen.trough) == 4, "wheat goes into the trough at the gate")
	w.fauna.tick(10.0)
	check(hen.hunger > 90.0 and int(pen.trough) < 4, "a hungry hen eats from the trough (%.0f)" % hen.hunger)
	w.fauna.feed(pen, p.inv, 2)
	# products
	hen.hunger = 100.0
	cock.hunger = 100.0
	w.farm.daily_products()
	check(w.farm.products_in(pen).is_empty(), "the first morning only starts the hen's clock")
	w.minutes += 1440.0
	hen.hunger = 100.0
	w.farm.daily_products()
	check(int(pen.products.get("egg", 0)) == 1, "a well-fed adult hen lays an egg a day")
	hen.hunger = 10.0
	w.minutes += 1440.0
	w.farm.daily_products()
	check(int(pen.products.get("egg", 0)) == 1, "a hungry hen lays nothing")
	var got: Dictionary = w.farm.collect(pen, p)
	check(int(got.get("egg", 0)) == 1 and p.inv.count("egg") == 1 and w.farm.products_in(pen).is_empty(), "the egg is collected at the gate")
	# breeding
	hen.hunger = 100.0
	cock.hunger = 100.0
	hen.next_birth = 0.0
	var young := 0
	for day in 30:
		hen.hunger = 100.0
		cock.hunger = 100.0
		w.minutes += 1440.0
		w.fauna.new_day()
		young = w.fauna.count(pen.id, "chicken") - 2
		if young > 0:
			break
	check(young > 0, "the pair breed in the player's pen: %d chicks" % young)
	for a: Animal in w.fauna.animals:
		if a.area == pen.id and a.id != hen.id and a.id != cock.id:
			check(a.stage(w.minutes) == "newborn" and not a.adult(w.minutes), "a chick is a newborn with the life stages")
			break
	# a cow pen and a sheep pen: milk and wool
	var cow_pen: Dictionary = w.farm.build_pen("cow", Rect2i(Vector2i(int(pl.x) + 1, int(pl.y) + 1), Vector2i(7, 6)), p)
	check(cow_pen.is_empty() and w.farm.pen_why != "", "a pen that does not fit the ground is refused (%s)" % w.farm.pen_why)
	for kind in ["cow", "sheep"]:
		var item := str(Farming.cfg().products[kind].item)
		var pr: Dictionary = {"id": "pen_player_t_" + kind, "kind": kind, "x": 1, "y": 1, "w": 7, "h": 6, "gate": [4, 1], "feed_at": [4, 0], "trough": 0, "owner": World.PLAYER, "tenant": "", "player": true, "products": {}}
		w.fauna.pens[pr.id] = pr
		var f: Animal = w.fauna.spawn(pr.id, kind, "f", null)
		f.born = w.minutes - 10.0 * 1440.0
		f.hunger = 100.0
		f.next_product = 0.0
		for d in 6:
			f.hunger = 100.0
			w.minutes += 1440.0
			w.farm.daily_products()
		check(int(pr.products.get(item, 0)) >= 1, "a %s gives %s: %d waiting after six days" % [kind, item, int(pr.products.get(item, 0))])
		check(int(pr.products.get(item, 0)) <= int(Farming.cfg().product_cap), "the pen holds at most %d" % int(Farming.cfg().product_cap))
		var take: Dictionary = w.farm.collect(pr, p)
		check(int(take.get(item, 0)) >= 1 and p.inv.count(item) >= 1, "the %s is collected" % item)
	# the village's own pens give the player nothing: their eggs, milk and wool are the keeper's (Build 13)
	src.products = {"egg": 2}
	var e_before := p.inv.count("egg")
	check(w.farm.collect(src, p).is_empty() and p.inv.count("egg") == e_before and int(src.products.egg) == 2, "the player cannot collect from the keeper's pen")


func test_market() -> void:
	var w := new_world()
	var p := w.player
	var cook: NPC = null
	var food: NPC = null
	var goods: NPC = null
	for n: NPC in w.npcs:
		if not n.alive:
			continue
		if n.job == "cook" and cook == null:
			cook = n
		elif n.job == "merchant":
			var kind: String = str(w.stalls.get(n.workplace, {}).get("kind", ""))
			if kind == "food" and food == null:
				food = n
			elif kind == "goods" and goods == null:
				goods = n
	check(cook != null and food != null and goods != null, "a cook, a food merchant and a goods merchant are in the village")
	p.inv.add("egg", 3)
	p.inv.add("milk", 2)
	p.inv.add("wool", 3)
	p.inv.add("carrot", 2)
	cook.coins = 500
	food.coins = 500
	goods.coins = 500
	check(w.brain.wants(cook, "egg") > 0 and w.brain.wants(food, "milk") > 0 and w.brain.wants(goods, "wool") > 0 and w.brain.wants(cook, "carrot") > 0, "the cook and the merchants buy eggs, milk, carrots and wool")
	var quote: Array = w.player_quote(cook, "egg", 3, false)
	var bill: int = quote.reduce(func(a, x): return a + int(x), 0)
	var c0 := p.coins
	var res: Dictionary = w.player_sell_many(cook, "egg", 3)
	check(res.result == "sold" and p.coins == c0 + bill and int(res.paid) == bill and p.inv.count("egg") == 0, "three eggs sold to the cook for %d coins (%s)" % [bill, quote])
	check(w.player_sell_many(goods, "wool", 3).result == "sold", "wool sold to the goods merchant")
	# through the player's own stall (PL1-10): a villager who needs it buys
	var b: Business = w.business
	check(b.listable("egg") >= 0 and GameData.items.has("egg"), "eggs can be listed at the stall")
	# the recipes: cheese, egg bread, cloth, bandages
	for r in ["press_cheese", "bake_egg_bread", "weave_cloth", "sew_bandages", "craft_plough"]:
		var rec: Dictionary = GameData.recipes[r]
		check(w.stations_of(str(rec.station)).size() > 0 or Furniture.STATION_OF.values().has(str(rec.station)), "%s has a %s to be made at" % [r, rec.station])
	var cheese: Dictionary = GameData.recipes.press_cheese
	check(cheese.out.cheese == 1 and cheese["in"].milk == 3, "milk presses into cheese")
	check(GameData.recipes.sew_bandages.out.linen_bandage == 3 and GameData.recipes.weave_cloth["in"].wool == 2, "wool is woven into cloth and sewn into bandages")


func test_save() -> void:
	var w := new_world()
	var p := w.player
	var pl := farm_land(w)
	p.inv.add("plough")
	p.inv.add("wheat_seed", 3)
	p.inv.add("plank", 20)
	for ij in [[1, 1], [2, 1], [2, 2]]:
		p.stamina = 100.0
		w.farm.till(cell_in(pl, ij[0], ij[1]), p)
	w.farm.sow(cell_in(pl, 1, 1), "wheat", p)
	w.farm.sow(cell_in(pl, 2, 1), "wheat", p)
	grow_hours(w, 30)
	var rect := Rect2i(Vector2i(int(pl.x) + 1, int(pl.y) + int(pl.h) - 6), Vector2i(5, 4))
	rect = w.farm.pen_rect_ahead("chicken", Vector2(float(pl.x) + 4.5, float(pl.y) + 8.5), Vector2.UP)
	var pen: Dictionary = w.farm.build_pen("chicken", rect, p)
	check(not pen.is_empty(), "a pen to save (%s)" % w.farm.pen_why)
	var hen := w.fauna.spawn(pen.id, "chicken", "f", null)
	hen.born = w.minutes - 5.0 * 1440.0
	hen.next_product = w.minutes + 500.0
	pen.products = {"egg": 3}
	pen.trough = 7
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	var m := VillageMap.load_default()
	w2.load_dict(m, d)
	check(w2.farm.cells.size() == 3 and w2.farm.cells[cell_in(pl, 1, 1)].crop == "wheat" and w2.farm.cells[cell_in(pl, 1, 1)].state == "growing", "the field loads with its cells, crops and states")
	check(is_equal_approx(float(w2.farm.cells[cell_in(pl, 1, 1)].progress), float(w.farm.cells[cell_in(pl, 1, 1)].progress)) and w2.farm.cells[cell_in(pl, 2, 2)].state == "tilled", "growth progress and empty soil are kept")
	var pen2: Dictionary = w2.fauna.pens.get(pen.id, {})
	check(not pen2.is_empty() and pen2.get("player", false) and int(pen2.trough) == 7 and int(pen2.products.egg) == 3 and w2.owner_of(pen2) == World.PLAYER, "the pen loads: the player's, its trough and its eggs")
	check(w2.map.is_solid(Vector2i(rect.position.x, rect.position.y + 1)) and not w2.map.is_solid(Vector2i(int(pen2.gate[0]), int(pen2.gate[1]))), "its fence is solid again, the gate open")
	var h2: Animal = null
	for a: Animal in w2.fauna.animals:
		if a.area == pen.id:
			h2 = a
	check(h2 != null and is_equal_approx(h2.next_product, hen.next_product) and h2.species == "chicken", "the hen loads with her egg clock")
	check(w2.farm.next_pen == w.farm.next_pen and w2.farm.player_pens().size() == 1, "the pen counter is kept")
	# keeps growing after loading
	grow_hours(w2, 24)
	check(w2.farm.cells[cell_in(pl, 1, 1)].state == "ripe", "the loaded crop ripens on the clock")
	# an older save with no farm at all loads empty
	var old: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	old.erase("farm")
	old.fauna.erase("player_pens")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), old)
	check(w3.farm.cells.is_empty() and w3.farm.player_pens().is_empty(), "an older save without a farm loads with none")
	# building on ground ploughs the field under
	var w4 := new_world()
	var pl4 := farm_land(w4)
	w4.player.inv.add("plough")
	w4.player.stamina = 100.0
	w4.farm.till(cell_in(pl4, 1, 1), w4.player)
	check(w4.farm.cells.size() == 1, "(a field cell)")
	w4.start_site(pl4, "house", World.PLAYER)
	check(w4.farm.cells.is_empty(), "marking out a house on the ground ploughs the field under")


## Build 13: the village's livestock chain. Pens make eggs, milk and wool; keepers collect and sell them;
## the cook presses cheese and bakes egg bread at the kitchen's preparation table; the tanner weaves wool
## into cloth and sews bandages for the Apothecary; villagers buy and eat cheese and bread. Every step moves
## real goods and coins.
func test_village_chain() -> void:
	var w := new_world()
	var preps: Array = w.stations_of("prep")
	check(preps.size() == 1 and str(w.stations[preps[0]].get("building", "")) == "b2", "the tavern kitchen has a preparation table (%s)" % [preps])
	var prep: String = preps[0]
	# 1. a village pen makes eggs; its keeper collects them
	var pen: Dictionary = {}
	for id in w.fauna.pens:
		if w.fauna.pens[id].kind == "chicken" and not w.fauna.pens[id].get("player", false):
			pen = w.fauna.pens[id]
	check(not pen.is_empty(), "the village has a chicken pen")
	for a: Animal in w.fauna.animals:
		if a.area == pen.id:
			a.hunger = 100.0
	w.farm.daily_products()
	w.minutes += 1441.0
	for a: Animal in w.fauna.animals:
		if a.area == pen.id:
			a.hunger = 100.0
	w.farm.daily_products()
	var laid := int(pen.get("products", {}).get("egg", 0))
	check(laid > 0, "the village hens lay (%d eggs wait in the pen)" % laid)
	var keeper: NPC = null
	for n: NPC in w.npcs:
		if n.alive and w.tenant_of(pen) == World.npc_ref(n.id):
			keeper = n
	check(keeper != null, "the pen has a keeper")
	keeper.plan.clear()
	keeper.hunger = 100.0
	w.minutes = float(w.day()) * 1440.0 + 9.0 * 60.0
	w.brain.decide(keeper)
	check(keeper.plan.any(func(st): return str(st.get("act", st.get("a", ""))) == "collect_pen") or keeper.doing.contains("collecting"), "the keeper goes to collect: " + keeper.doing)
	var e0 := keeper.inv.count("egg")
	check(w.brain.act(keeper, "collect_pen", {"pen": pen.id}) and keeper.inv.count("egg") == e0 + laid and int(pen.products.egg) == 0, "collected: the eggs move from the pen into the keeper's pack")
	# 2. the cook buys them with the cook's own coins and bakes egg bread at the table
	var cook: NPC = w.npcs.filter(func(n): return n.alive and n.job == "cook")[0]
	check(w.brain.wants(cook, "egg") > 0 and w.brain.wants(cook, "milk") > 0, "the cook buys eggs and milk")
	var coins := w.total_coins()
	var price := w.buy_price(cook, "egg")
	var cc := cook.coins
	check(w.trade(cook, keeper, "egg", 1, price) and cook.coins == cc - price and w.total_coins() == coins, "an egg sold to the cook for %d of the cook's coins" % price)
	cook.inv.items.erase("bread")
	cook.inv.add("wheat", 2)
	var w0 := cook.inv.count("wheat")
	var eg0 := cook.inv.count("egg")
	check(w.brain.act(cook, "craft", {"recipe": "bake_egg_bread", "station": prep}) and cook.inv.count("bread") == 2 and cook.inv.count("egg") == eg0 - 1 and cook.inv.count("wheat") == w0 - 2, "egg bread: 1 egg and 2 wheat become 2 loaves")
	cook.inv.items.erase("milk")
	cook.inv.items.erase("cheese")
	cook.inv.add("milk", 3)
	check(w.brain.act(cook, "craft", {"recipe": "press_cheese", "station": prep}) and cook.inv.count("cheese") == 1 and not cook.inv.has("milk"), "cheese: 3 milk pressed into 1 cheese")
	cook.inv.items.erase("milk")
	check(w.brain.act(cook, "craft", {"recipe": "press_cheese", "station": prep}) == false and cook.inv.count("cheese") == 1, "no milk, no cheese: nothing from nothing")
	# the cook plans it when the milk is in hand
	cook.inv.add("milk", 3)
	for f in NPCBrain.COOKED:
		cook.inv.items.erase(f)
	cook.inv.items.erase("meat")
	cook.inv.items.erase("wheat")
	cook.plan.clear()
	w.brain.decide(cook)
	check(cook.plan.any(func(st): return str(st.get("args", {}).get("recipe", "")) == "press_cheese" or str(st.get("a", {}).get("recipe", "")) == "press_cheese") or cook.doing.contains("prep"), "the cook decides to press cheese at the table: " + cook.doing)
	# 3. villagers eat cheese and bread
	check(NPCBrain.COOKED.has("cheese") and NPCBrain.COOKED.has("bread") and NPCBrain.FOOD.has("cheese"), "cheese and bread are meals villagers buy and eat")
	var eater: NPC = w.npcs.filter(func(n): return n.alive and n.role == "adult" and n.job == "farmer")[0]
	for f in NPCBrain.COOKED:
		eater.inv.items.erase(f)
	eater.inv.add("cheese", 1)
	eater.hunger = 20.0
	check(w.brain.act(eater, "eat", {"cooked_only": true}) and is_equal_approx(eater.hunger, 20.0 + float(GameData.item("cheese").food)) and not eater.inv.has("cheese"), "a villager eats the cheese")
	# 4. wool: the tanner buys it, weaves cloth and sews bandages the sage buys
	var tanner: NPC = w.npcs.filter(func(n): return n.alive and n.job == "tanner")[0]
	var sage := w.npc(w.sage_id)
	check(w.brain.wants(tanner, "wool") > 0 and w.brain.wants(sage, "linen_bandage") > 0, "the tanner buys wool, the sage buys bandages")
	tanner.inv.items.clear()
	tanner.skills = {}                       # a novice: the recipe's own conversion (PAR-01 skill effects aside)
	tanner.inv.add("wool", 2)
	var bench: String = w.stations_of("workbench")[0]
	check(w.brain.act(tanner, "craft", {"recipe": "weave_cloth", "station": bench}) and tanner.inv.count("wool_cloth") == 1 and not tanner.inv.has("wool"), "2 wool woven into cloth")
	check(w.brain.act(tanner, "craft", {"recipe": "sew_bandages", "station": bench}) and tanner.inv.count("linen_bandage") == 3 and not tanner.inv.has("wool_cloth"), "cloth sewn into 3 bandages")
	tanner.plan.clear()
	tanner.hunger = 100.0
	w.brain.decide(tanner)
	check(tanner.doing.contains("sell") or tanner.plan.any(func(st): return str(st).contains("sell")), "the tanner takes the bandages to sell: " + tanner.doing)
	# 5. a week of village life: the chain runs on its own, with real goods and coins
	var w2 := new_world()
	var start := w2.total_coins()
	var steps := int(8.0 * 1440.0 / float(GameData.b("game_minutes_per_second")) / 0.5)
	for i in steps:
		w2.update(0.5)
	var st: Dictionary = w2.stats
	print("  chain stats: ", {"collected_egg": st.get("keeper_collected_egg", 0), "collected_milk": st.get("keeper_collected_milk", 0), "collected_wool": st.get("keeper_collected_wool", 0),
		"used_egg": st.get("used_egg", 0), "used_milk": st.get("used_milk", 0), "used_wool": st.get("used_wool", 0), "eaten_cheese": st.get("eaten_cheese", 0), "eaten_bread": st.get("eaten_bread", 0)})
	check(int(st.get("keeper_collected_egg", 0)) > 0 and int(st.get("keeper_collected_milk", 0)) > 0, "over 8 days the keepers collect eggs and milk")
	check(int(st.get("used_egg", 0)) + int(st.get("used_milk", 0)) > 0, "and the cook uses them at the table")
	check(int(st.get("eaten_cheese", 0)) + int(st.get("eaten_bread", 0)) > 0, "and villagers eat cheese or egg bread")
	check(w2.total_coins() == start + w2.coin_sources, "coins conserved through the chain (%d + sources %d = %d)" % [start, w2.coin_sources, w2.total_coins()])


# ---------------------------------------------------------------- SEED-02..04, MERCH-01 ----------
## A wild plant of `kind` in the village (not grown from a cutting).
func wild_plant(w: World, kind: String) -> Dictionary:
	for pl in w.plants:
		if str(pl.kind) == kind and not pl.get("planted", false):
			return pl
	return {}


## The first day (from `from`) whose day of the year falls in `season`.
func day_in(season: String, from := 0) -> int:
	var d := from
	while Life.season(float(d) * 1440.0 + 600.0) != season:
		d += 1
	return d


func set_day(w: World, d: int) -> void:
	w.minutes = float(d) * 1440.0 + 10.0 * 60.0


## A village cell a cutting can be planted on, near (30, 30).
func open_cell(w: World, item: String) -> Vector2i:
	for r in range(0, 40):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var c := Vector2i(30 + dx, 30 + dy)
				if w.plant_bush_refusal(c, item) == "":
					return c
	return Vector2i(-1, -1)


func test_propagation() -> void:
	var w := new_world()
	var p := w.player
	var prop: Dictionary = GameData.b("propagation")
	for kind in prop.kinds:
		var k: Dictionary = prop.kinds[kind]
		check(GameData.items.has(str(k.item)) and World.propagates(str(k.item)) == kind and FileAccess.file_exists("res://assets/icons/%s.png" % k.item), "%s: %s is an item with an icon that plants it" % [kind, k.item])
		check(float(k.chance) > 0.0 and float(k.chance) < 1.0 and float(k.grow_seasons) > 0.0, "%s: recovery is a chance, growth takes calendar time" % kind)
	# the recovery roll: deterministic, from the cell and the day, near its chance over many days
	var bush := wild_plant(w, "redberry")
	var hits := 0
	for d in 400:
		set_day(w, d)
		var a := w.propagation_drop(bush)
		if d < 3:
			check(a == w.propagation_drop(bush), "the roll is the same twice on day %d" % d)
		hits += 1 if not a.is_empty() else 0
	var share := float(hits) / 400.0
	var want := float(prop.kinds.redberry.chance)
	check(absf(share - want) < 0.07, "a red berry bush gives a cutting on %.2f of days (chance %.2f)" % [share, want])
	check(w.propagation_drop({"kind": "nothing", "x": 1, "y": 1}).is_empty(), "a kind without propagation gives nothing")
	# planting consumes the cutting, counted; the young plant bears only after growing, in its season
	var cut := "red_berry_cutting"
	set_day(w, day_in("Summer"))
	var cell := open_cell(w, cut)
	check(cell != Vector2i(-1, -1), "an open village cell to plant on: %s" % cell)
	check(w.plant_bush(cell, cut, p.inv).is_empty(), "nothing is planted without a cutting in the pack")
	check(w.plant_bush_refusal(cell, "wheat") != "", "wheat is no planting material")
	var road: Array = w.map.data.road[0]
	check(w.plant_bush_refusal(Vector2i(int(road[0]), int(road[1])), cut) != "", "not on the road")
	p.inv.add(cut, 2)
	var used0 := int(w.stats.get("used_" + cut, 0))
	var pl := w.plant_bush(cell, cut, p.inv)
	check(not pl.is_empty() and pl.state == "young" and pl.kind == "redberry" and p.inv.count(cut) == 1 and int(w.stats.get("used_" + cut, 0)) == used0 + 1, "planting takes one cutting from the pack (counted used_) and a young red berry bush stands there")
	check(int(pl.get("tile", -1)) == 2660 and w.plant_at(cell) == pl, "it is a red berry bush of the map's tile, found where it was planted")
	check(w.plant_bush_refusal(cell, cut) != "", "the cell is taken now")
	check(w.pick_plant(pl).is_empty(), "a young bush has nothing to pick")
	var grow := roundi(Life.seasons_to_days(float(prop.kinds.redberry.grow_seasons)))
	check(int(pl.regrow) == w.day() + grow, "it bears %d days later (grow_seasons in calendar days)" % grow)
	set_day(w, int(pl.regrow) - 1)
	w.season_plants()
	check(pl.state == "young", "a day before, it is still growing")
	set_day(w, int(pl.regrow))
	w.season_plants()
	var ok_season := w.plant_in_season("redberry")
	check(pl.state == ("ripe" if ok_season else "picked"), "grown on day %d (%s): %s" % [w.day(), w.season(), pl.state])
	set_day(w, day_in("Summer", int(pl.regrow)))
	w.season_plants()
	check(pl.state == "ripe" and not w.pick_plant(pl).is_empty(), "in summer the planted bush bears berries")
	# a flower seed grows a flower of one of the map's flower tiles
	p.inv.add("flower_seed", 1)
	var fcell := open_cell(w, "flower_seed")
	var fl := w.plant_bush(fcell, "flower_seed", p.inv)
	check(not fl.is_empty() and fl.kind == "flower" and [2656, 2657, 2658, 2659].has(int(fl.tile)) and not p.inv.has("flower_seed"), "a wild flower seed is used up and a young flower grows")
	# the player's picking path: what is picked and the cutting both reach the pack, both counted made_
	var wild := wild_plant(w, "blueberry")
	var d := day_in("Summer", w.day())
	set_day(w, d)
	while w.propagation_drop(wild).is_empty() or not w.plant_in_season("blueberry"):
		d += 1
		set_day(w, d)
	wild.state = "ripe"
	var m0 := int(w.stats.get("made_blue_berry_cutting", 0))
	var got := w.pick_plant(wild)
	var drop := w.propagation_drop(wild)
	for id in drop:
		w.player_gain(id, int(drop[id]))
	check(not got.is_empty() and p.inv.count("blue_berry_cutting") == 1 and int(w.stats.get("made_blue_berry_cutting", 0)) == m0 + 1, "the player picks blueberries and keeps the cutting (made_ counted)")
	# a crop's seed is counted used_ when sown
	var sd0 := int(w.stats.get("used_wheat_seed", 0))
	var land := farm_land(w)
	var fc := cell_in(land, 1, 1)
	p.stamina = 100.0
	p.inv.add("wheat_seed", 1)
	set_day(w, day_in("Spring", w.day()))
	w.farm.till(fc, p)
	check(w.farm.sow(fc, "wheat", p) == "" and int(w.stats.get("used_wheat_seed", 0)) == sd0 + 1, "sowing a crop counts its seed used_")
	# the save keeps the planted plants
	var dd: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), dd)
	var back := w2.plant_at(cell)
	check(not back.is_empty() and back.get("planted", false) and str(back.kind) == "redberry" and str(back.state) == str(pl.state) and w2.plant_at(fcell).get("kind", "") == "flower", "the planted bush and flower load with the save")


func test_perennials() -> void:
	var w := new_world()
	check(w.day() == 0 and w.season() == "Spring", "the game starts in spring")
	var bush := wild_plant(w, "redberry")
	var flower := wild_plant(w, "flower")
	check(bush.state == "picked" and flower.state == "ripe", "out of season from the start: the red berry bush is bare, the flower is out")
	check(w.pick_plant(bush).is_empty(), "nothing to pick from a bare bush")
	var why := ResourceNodes.can_harvest(w, ResourceNodes.def_for("plant", "redberry"), bush)
	check(why.contains("summer and autumn"), "the bush says when it bears: \"%s\"" % why)
	set_day(w, day_in("Summer"))
	w.season_plants()
	check(bush.state == "ripe", "in summer the bush bears")
	var got := w.pick_plant(bush)
	check(not got.is_empty() and bush.state == "picked" and w.plants.has(bush), "picked, it stays where it grows (perennial)")
	var regrow := int(bush.regrow)
	set_day(w, regrow)
	w.season_plants()
	check(bush.state == ("ripe" if w.plant_in_season("redberry") else "picked"), "it bears again on day %d only if in season (%s)" % [regrow, w.season()])
	set_day(w, day_in("Winter", w.day()))
	bush.state = "ripe"
	w.season_plants()
	check(bush.state == "picked", "winter strips the bush; the berries were never items, so nothing leaves the ledger")
	set_day(w, day_in("Summer", w.day()))
	w.season_plants()
	check(bush.state == "ripe", "next summer it bears again")
	set_day(w, day_in("Winter", w.day()))
	flower.state = "ripe"
	w.season_plants()
	check(flower.state == "ripe", "wild flowers are not seasonal (no plant_seasons entry)")
	# fruit trees: picked, the tree stays and bears again in its seasons
	var apple := {}
	for t in w.trees:
		if str(t.get("species", "")) == "apple_orchard" and t.state == "grown":
			apple = t
			break
	check(not apple.is_empty(), "the village has a grown apple tree")
	set_day(w, day_in("Summer", w.day()))
	apple.fruit_day = 0
	check(not w.pick_fruit(apple).is_empty() and apple.state == "grown", "picked, the apple tree stands")
	check(not Trees.fruit_ripe(apple, w.day(), w.season()), "it is bare after picking")
	check(not Trees.fruit_ripe(apple, int(apple.fruit_day) + 100, "Winter") and Trees.fruit_ripe(apple, int(apple.fruit_day), "Summer"), "it bears again after its regrowth, in summer, never in winter")


func test_household_seed() -> void:
	var w := new_world()
	var n: NPC = w.npcs.filter(func(o): return o.alive and o.role == "adult" and o.household >= 0 and o.home != "")[0]
	var pantry: Inventory = w.households[n.household].pantry
	var bush := wild_plant(w, "redberry")
	var d := day_in("Summer")
	set_day(w, d)
	while w.propagation_drop(bush).is_empty() or not w.plant_in_season("redberry"):
		d += 1
		set_day(w, d)
	bush.state = "ripe"
	var m0 := int(w.stats.get("made_red_berry_cutting", 0))
	var c0 := n.inv.count("red_berry_cutting")
	check(w.brain.act(n, "forage", {"plant": str(bush.id)}) and n.inv.count("red_berry_cutting") == c0 + 1 and int(w.stats.get("made_red_berry_cutting", 0)) == m0 + 1, "a villager foraging keeps the cutting, by the player's rule (made_ counted)")
	var p0 := pantry.count("red_berry_cutting")
	w.brain.act(n, "store_home", {})
	check(pantry.count("red_berry_cutting") == p0 + c0 + 1 and not n.inv.has("red_berry_cutting"), "the cutting is saved in the household's pantry")
	var keep := int(GameData.b("propagation").household_keep)
	pantry.add("red_berry_cutting", keep + 3 - pantry.count("red_berry_cutting"))
	check(int(w.brain.front_goods(n.household).get("red_berry_cutting", 0)) == 3, "the household keeps %d and offers the rest for market" % keep)
	check(NPCBrain.OUTLETS["red_berry_cutting"] == ["merchant_food"], "the seed seller (the food stall) buys households' cuttings")


func test_seed_seller() -> void:
	var w := new_world()
	var p := w.player
	var food: NPC = null
	var farmer: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.job == "merchant" and w.farm.sells_seed(n) and food == null:
			food = n
		elif n.alive and n.job == "farmer" and n.household >= 0 and farmer == null:
			farmer = n
	check(food != null and farmer != null, "a seed seller and a farmer")
	for id in Farming.propagule_items():
		check(not food.inv.has(id), "no %s at the start: no free stock" % id)
	check(w.farm.propagule_offers(food).is_empty(), "nothing offered without stock")
	# the caravan sells the merchant cuttings and flower seed for the merchant's coins
	var sellers: Array = w.npcs.filter(func(o): return o.alive and o.job == "merchant" and w.farm.sells_seed(o))
	var coins0 := 0
	for o: NPC in sellers:
		o.coins = 2000
		coins0 += o.coins
	var spent := 0
	for i in 4:
		spent += w.brain._caravan_seeds()
	var got := 0
	var coins1 := 0
	for o: NPC in sellers:
		coins1 += o.coins
	for id in Farming.propagule_items():
		var held := 0
		for o: NPC in sellers:
			held += o.inv.count(id)
		got += held
		check(int(w.stats.get("imported_" + id, 0)) == held, "%s: every one the seed sellers hold was imported (counted %d)" % [id, held])
	check(got > 0 and coins1 == coins0 - spent, "the caravan restocks %d cuttings and flower seed, paid from the sellers' coins (%d)" % [got, spent])
	# the player buys one: coins to the merchant, stock down by one
	var id: String = w.farm.propagule_offers(food)[0]
	var price := w.farm.seed_item_price(id, p)
	p.coins = 100
	var s0 := food.inv.count(id)
	var fc := food.coins
	check(w.farm.buy_seed_item(food, id, 1, p) == "" and p.inv.count(id) == 1 and food.inv.count(id) == s0 - 1 and p.coins == 100 - price and food.coins == fc + price, "the player buys a %s for %d coins from the stock" % [id, price])
	check(w.farm.buy_seed_item(food, id, 99, p) != "", "not more than the stock")
	# a farmer short of seed buys it from the seller with their own coins, by the same rule
	var pantry: Inventory = w.households[farmer.household].pantry
	farmer.inv.items.erase("wheat_seed")
	pantry.items.erase("wheat_seed")
	farmer.coins = 300
	if not food.inv.has("wheat_seed", 2):
		food.inv.add("wheat_seed", 2)
	var total := w.total_coins()
	check(w.brain._plan_buy_seed(farmer) and farmer.plan.size() == 2, "a farmer without seed plans to buy it: " + farmer.doing)
	var keep := int(Farming.seed_cfg().seed_keep)
	var ws0 := food.inv.count("wheat_seed")
	var sp := w.farm.seed_item_price("wheat_seed", farmer)
	var f0 := farmer.coins
	var m0 := food.coins
	check(w.brain.act(farmer, "buy_seed", {"vendor": food.id, "item": "wheat_seed", "qty": keep}), "the farmer buys at the stall")
	check(farmer.inv.count("wheat_seed") == keep and food.inv.count("wheat_seed") == ws0 - keep, "%d wheat seed moved from the merchant's stock to the farmer" % keep)
	check(farmer.coins == f0 - sp * keep and food.coins == m0 + sp * keep and w.total_coins() == total, "the farmer paid %d coins to the merchant; coins conserved" % (sp * keep))
	check(not w.brain._plan_buy_seed(farmer), "with seed_keep in hand the farmer buys no more")


## VIS-CROP-01: what the fields look like is read from their state and never changes it. Every cell of a field has the
## same ground (the tilled-soil set) whatever its state, so a part-sown field joins cleanly; CropView draws each sown
## cell's plant by its growth (four stages), the ripe plant when ripe, and stubble on a manor field cut since it was
## ripe and not sown again; bare tilled soil shows no plant.
func test_crop_view() -> void:
	var w := new_world()
	var pl := farm_land(w)
	var p := w.player
	p.inv.add("wheat_seed", 5)
	p.inv.add("carrot_seed", 5)
	var a := cell_in(pl, 2, 2)
	var b := cell_in(pl, 3, 2)
	var c := cell_in(pl, 4, 2)
	for x in [a, b, c]:
		p.stamina = p.stamina_cap()
		w.farm.till(x, p)
	var ground := []
	for x in [a, b, c]:
		ground.append(w.farm.tile_for(x))
	w.farm.sow(a, "wheat", p)
	w.farm.sow(b, "carrot", p)
	check(w.farm.tile_for(a) == ground[0] and w.farm.tile_for(b) == ground[1], "a sown cell keeps the same ground tile as when it was only tilled")
	var cv := CropView.new()
	cv.setup(w)
	var by_cell := func() -> Dictionary:
		var d := {}
		for e in cv.plants():
			d[Vector2i(int(e[0]), int(e[1]))] = [int(e[2]), int(e[3])]
		return d
	var now: Dictionary = by_cell.call()
	check(now.get(a) == [CropView.ROWS.wheat, 0] and now.get(b) == [CropView.ROWS.carrot, 0] and not now.has(c), "just sown: each crop's first plant; the tilled cell shows bare soil (%s)" % [now])
	w.farm.cells[a].progress = 0.6
	w.farm.cells[b].state = "ripe"
	now = by_cell.call()
	check(now.get(a) == [CropView.ROWS.wheat, 2] and now.get(b) == [CropView.ROWS.carrot, CropView.RIPE], "growth 0.6 shows the third stage, ripe the grown plant")
	var snap := JSON.stringify(w.farm.cells.values())
	cv.refresh()
	check(JSON.stringify(w.farm.cells.values()) == snap, "drawing changes nothing in the field's state")
	var f: Dictionary = w.fields[0]
	w.set_field(f, "growing")
	var stage0: int = cv.field_column(f)
	w.set_field(f, "ripe")
	var ripe: int = cv.field_column(f)
	w.set_field(f, "tilled")
	check(stage0 == 0 and ripe == CropView.RIPE and cv.field_column(f) == CropView.STUBBLE, "a manor field: first stage when sown, ripe wheat, then stubble once cut (%d, %d, %d)" % [stage0, ripe, cv.field_column(f)])
	var fresh := {"state": "tilled"}
	check(cv.field_column(fresh) == -1, "a field never yet ripe shows bare soil")
	cv.free()
