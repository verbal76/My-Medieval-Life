extends SceneTree
## B14-11: the plough horse (owner answers 2026-10-23, docs/directives/2026-10-23_owner_answers_horse.md). It is bought from
## the visiting caravan for 120 coins into the player's own horse pen; with it and the hand plough tilling takes 1 s and 10
## stamina; it eats 2 wheat a meal like a cow and dies if unfed; it survives a save; the coins go to the caravan's purse
## and no coin is made or lost. Run: godot --headless --path game --script res://tests/horse_test.gd

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
	test_buying()
	test_ploughing()
	test_feeding()
	test_save()
	test_wiki()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## Open ground of the player's with a horse pen on it (planks in the pack); returns the pen.
var parcel := {}


func horse_pen(w: World) -> Dictionary:
	var p := w.player
	p.coins = 1000
	for t in w.trees:
		t.state = "cleared"
		w.map.set_solid(Vector2i(int(t.x), int(t.y)), false)
	var pl: Dictionary = w.property.claim(w.construction.find_ground("house", Vector2i(30, 30), World.PLAYER), World.PLAYER, false)
	parcel = pl
	p.inv.add("plank", 40)
	var rect: Rect2i = w.farm.pen_rect_ahead("horse", Vector2(float(pl.x) + 4.5, float(pl.y) + 8.5), Vector2.UP)
	var pen: Dictionary = w.farm.build_pen("horse", rect, p)
	check(not pen.is_empty(), "a horse pen is fenced on the player's ground (%s)" % w.farm.pen_why)
	return pen


## The day the caravan comes, at its hour.
func caravan_day(w: World, hour := 13.0) -> void:
	var every := int(GameData.b("caravan_every_days"))
	w.minutes = (every * 3 + 1) * 1440.0 + hour * 60.0


func test_data() -> void:
	var f: Dictionary = GameData.b("farming")
	var cow: Dictionary = GameData.b("animals").cow
	var h: Dictionary = GameData.b("animals").horse
	check(int(f.caravan_horse.price) == 120, "the caravan's price is 120 coins")
	check(float(f.till.horse.seconds) == 1.0 and float(f.till.horse.stamina) == 10.0, "tilling with the horse is 1 s and 10 stamina")
	check(f.pens.has("horse") and not f.animal_price.has("horse"), "a horse pen exists; no keeper sells horses")
	check(int(h.feed) == 2 and int(h.feed) == int(cow.feed), "it eats 2 wheat a meal, like a cow")
	check(h.kind == "livestock" and h.layout == "farm" and ResourceLoader.exists("res://assets/animals/%s.png" % h.skins[0]), "livestock drawn from the Animal Farm sheet")
	for k in ["hp", "speed", "grow_years", "elder_years", "death_years", "meat", "hide"]:
		check(h[k] == cow[k], "%s is the cow's (agent proposal)" % k)


func test_buying() -> void:
	var w := new_world()
	var p := w.player
	var pen := horse_pen(w)
	w.player.pos = w.farm.caravan_stop()
	w.minutes = 2 * 1440.0 + 13.0 * 60.0          # day 2: not a visit day (visits on 1, 3, 5, ...)
	check(not w.farm.caravan_here() and w.farm.buy_horse(p) == "The caravan is not here.", "no caravan, no horse")
	caravan_day(w, 11.0)
	check(not w.farm.caravan_here(), "before noon on its day the caravan has not come")
	caravan_day(w, 13.0)
	check(w.farm.caravan_here(), "the caravan is at its stop in the afternoon of its day")
	caravan_day(w, 19.0)
	check(not w.farm.caravan_here(), "and gone in the evening")
	caravan_day(w)
	# too few coins
	p.coins = 119
	var coins0 := p.coins
	check(w.farm.buy_horse(p).contains("120 coins") and p.coins == coins0 and w.farm.plough_horse() == null, "119 coins: refused, nothing changes")
	# conservation
	p.coins = 500
	var net0 := w.total_coins() - w.coin_sources
	var purse0 := w.caravan_purse
	var got := w.farm.buy_horse(p)
	check(got == "", "with 500 coins the horse is bought (%s)" % got)
	check(p.coins == 380 and w.caravan_purse == purse0 + 120, "120 coins left the player and went into the caravan's purse exactly")
	check(w.total_coins() - w.coin_sources == net0, "no coin was made or lost (coins less outside sources unchanged)")
	var horse := w.farm.plough_horse()
	check(horse != null and horse.area == pen.id and horse.sex == "m" and horse.adult(w.minutes) and horse.hunger == 100.0, "an adult horse stands in the player's horse pen, fed")
	check(w.farm.buy_horse(p) == "You already have a plough horse." and p.coins == 380, "a second horse is refused")
	# no pen
	var w2 := new_world()
	w2.player.coins = 500
	caravan_day(w2)
	check(w2.farm.buy_horse(w2.player).contains("horse pen") and w2.player.coins == 500, "without a horse pen with room, refused")


func test_ploughing() -> void:
	var w := new_world()
	var p := w.player
	horse_pen(w)
	caravan_day(w)
	p.inv.add("plough")
	check(float(w.farm.till_cost(p).seconds) == 2.5 and float(w.farm.till_cost(p).stamina) == 25.0, "hand plough alone: 2.5 s, 25 stamina")
	check(w.farm.buy_horse(p) == "", "buy the horse")
	check(float(w.farm.till_cost(p).seconds) == 1.0 and float(w.farm.till_cost(p).stamina) == 10.0, "plough and horse: 1 s, 10 stamina")
	p.inv.remove("plough", 1)
	check(float(w.farm.till_cost(p).seconds) == 7.0 and float(w.farm.till_cost(p).stamina) == 80.0, "a horse without the plough: still by hand, 7 s and 80")
	p.inv.add("plough")
	# a real tilled cell
	p.stamina = 100.0
	var c := Vector2i(-1, -1)
	for j in int(parcel.h):                          # a cell of the parcel the pen does not cover
		for i in int(parcel.w):
			if c.x < 0 and w.farm.till_refusal(Vector2i(int(parcel.x) + i, int(parcel.y) + j), p) == "":
				c = Vector2i(int(parcel.x) + i, int(parcel.y) + j)
	check(c.x >= 0, "a free cell to till")
	var plan: Dictionary = w.farm.plan(w.farm.targets_at(c, p)[0], p)
	check(plan.ok and is_equal_approx(float(plan.secs), 1.0), "the timed action takes 1 s (%s)" % str(plan.get("secs")))
	plan.run.call()
	check(is_equal_approx(p.stamina, 90.0) and w.farm.cells.has(c), "10 stamina taken and the cell is tilled")
	# the horse dies: back to the hand plough
	w.fauna.remove(w.farm.plough_horse())
	check(w.farm.plough_horse() == null and float(w.farm.till_cost(p).seconds) == 2.5, "no horse, no speed-up")


func test_feeding() -> void:
	var w := new_world()
	var p := w.player
	var pen := horse_pen(w)
	caravan_day(w)
	w.farm.buy_horse(p)
	var horse := w.farm.plough_horse()
	# hungry and fed: a meal is 2 wheat
	horse.hunger = 10.0
	p.inv.add("wheat", 10)
	check(w.fauna.feed(pen, p.inv, 4) == 4 and int(pen.trough) == 4, "wheat goes in the trough at the gate")
	check(w.fauna.daily_need(pen) == 4 and w.fauna.hungry(pen) == 1, "it eats about 4 wheat a day and is hungry now")
	w.fauna.tick(10.0)
	check(horse.hunger == 100.0 and int(pen.trough) == 2, "a meal took 2 wheat and filled it")
	# unfed: loses health and dies
	pen.trough = 0
	horse.hunger = 0.0
	var hp0 := horse.hp
	w.fauna.tick(60.0)
	check(horse.hp < hp0, "an unfed horse loses health")
	for i in 60:
		w.fauna.tick(60.0)
	check(w.farm.plough_horse() == null and int(w.stats.get("starved_horse", 0)) == 1, "and dies if nobody feeds it")
	# it does not breed
	var w2 := new_world()
	var pen2 := horse_pen(w2)
	caravan_day(w2)
	w2.farm.buy_horse(w2.player)
	pen2.trough = 50
	for i in 40:
		w2.minutes += 1440.0
		w2.fauna.tick(60.0)
		w2.fauna.new_day()
	check(w2.fauna.count(pen2.id, "horse") <= 1, "it never breeds (one only)")


func test_save() -> void:
	var w := new_world()
	var p := w.player
	var pen := horse_pen(w)
	caravan_day(w)
	w.farm.buy_horse(p)
	pen.trough = 5
	w.farm.plough_horse().hunger = 61.0
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var h2 := w2.farm.plough_horse()
	check(h2 != null and h2.species == "horse" and is_equal_approx(h2.hunger, 61.0) and h2.area == pen.id, "the horse loads in its pen with its hunger")
	check(int(w2.fauna.pens[pen.id].trough) == 5 and w2.caravan_purse == w.caravan_purse and w2.coin_sources == w.coin_sources, "its trough and the caravan's purse load")
	w2.player.inv.add("plough")
	check(float(w2.farm.till_cost(w2.player).seconds) == 1.0, "the loaded horse still speeds the plough")
	check(int(d.save_version) == World.SAVE_VERSION, "the save version is unchanged (%d): the horse is an ordinary pen animal" % World.SAVE_VERSION)


func test_wiki() -> void:
	var w := Wiki.build()
	check(w.pages.has("animal:horse") and w.pages.has("guide:animals") and w.pages.has("sys:caravan"), "the wiki has the horse, the animals guide and the caravan")
	for id in ["guide:animals", "sys:farming", "sys:caravan", "animal:horse"]:
		check(str(w.pages[id].text).contains("plough horse"), "%s describes the plough horse" % id)
	check(str(w.pages["guide:animals"].text).contains("120") and str(w.pages["sys:caravan"].text).contains("120"), "and its price")
	check(not str(w.pages["sys:farming"].text).contains("no horses"), "no page still says there are no horses")
	check(not str(w.pages["todo:farm_more"].text).contains("no horses or oxen"), "'Not in the game yet' no longer lists the horse")
