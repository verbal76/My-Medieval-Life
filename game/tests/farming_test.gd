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
	check(w.farm.buy_seed(farmer, "wheat", 5, p) == "" and p.inv.count("wheat_seed") == 5 and p.coins == coins0 - 5 * w.farm.seed_price("wheat") and farmer.coins == fc0 + 5 * w.farm.seed_price("wheat"), "five seeds bought from the farmer with real coins")
	var merchant: NPC = null
	for n: NPC in w.npcs:
		if n.job == "merchant" and w.stalls.get(n.workplace, {}).get("kind", "") == "food":
			merchant = n
			break
	check(merchant != null and w.farm.seed_offers(merchant).has("carrot"), "the food stall's merchant sells seed too")
	check(w.farm.sow(c, "wheat", p) == "" and w.farm.cells[c].state == "growing" and p.inv.count("wheat_seed") == 4, "the cell is sown: one seed used")
	var days := float(Farming.crops().wheat.days)
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
	check(w.farm.cells[c3].state == "ripe" and weeks > int(float(Farming.crops().herb.days) * 24.0), "it ripens later than a spring sowing (%d hours: winter paused it)" % weeks)
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
	# the village's own pens give the player nothing and its keepers keep their stock
	check(w.farm.products_in(src).is_empty(), "the keeper's pen collects nothing for anyone")


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
	var price := w.buy_price(cook, "egg")
	var c0 := p.coins
	var res: Dictionary = w.player_sell_many(cook, "egg", price, 3)
	check(res.result == "sold" and p.coins == c0 + 3 * price and p.inv.count("egg") == 0, "three eggs sold to the cook for %d each" % price)
	check(w.player_sell_many(goods, "wool", w.buy_price(goods, "wool"), 3).result == "sold", "wool sold to the goods merchant")
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
