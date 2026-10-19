extends SceneTree
## CRT-01..07 (owner, 2026-10-19): gifts, regard and attraction, befriending, courting and proposals for the
## player and between villagers, friends' benefits, same-sex couples, saving. Pure World. Run headless:
##   godot --headless --path game --script res://tests/relations_test.gd

var failures := 0
var checks := 0
const ME := Life.PLAYER_ID


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func new_world(seed := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


func _init() -> void:
	test_gifts()
	test_befriending()
	test_courting()
	test_friends_benefits()
	test_villagers_court()
	test_shared_hours()
	test_same_sex()
	test_save()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## An unpartnered adult villager of courting age of a given job ("" any).
func single(w: World, job := "", not_id := -99) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.partner < 0 and n.id != not_id and (job == "" or n.job == job) \
				and Life.npc_age(w, n) >= 18.0 and Life.npc_age(w, n) <= 50.0 and w.relations.can_court(ME, n.id):
			return n
	return null


func next_day(w: World) -> void:
	w.minutes += 1440.0


# ---------------------------------------------------------------- gifts ----------------------
func test_gifts() -> void:
	var w := new_world()
	var r := w.relations
	check(Relations.gift_kind("flower") == "flower" and Relations.gift_kind("ale") == "drink" and Relations.gift_kind("bread") == "food"
			and Relations.gift_kind("plain_clothes") == "clothes" and Relations.gift_kind("gold_ring") == "jewellery" and Relations.gift_kind("coal") == "useful",
			"gifts by kind: flowers, drink, food, clothes, jewellery, useful things")
	check(Relations.gift_kind("rotten_apple") == "", "a rotten apple is no gift")
	var smith := single(w, "smith")
	if smith == null:
		smith = single(w)
		smith.job = "smith"
	check(r.favourites(smith).has("coal") and r.favourite_reason(smith, "coal") == "useful to a smith", "a smith is glad of coal, and the list says why")
	smith.hunger = 10.0
	check(r.favourites(smith).has("bread") and r.favourite_reason(smith, "bread") == "they are hungry", "a hungry villager is glad of food")
	smith.hunger = 100.0
	var traditional := r.gift_effect(ME, smith, "flower")
	var fav := r.gift_effect(ME, smith, "coal")
	var useless := r.gift_effect(ME, smith, "stone")
	check(float(traditional.attraction) > 0.0 and float(traditional.regard) > 0.0, "a traditional gift (a flower) builds attraction and regard")
	check(float(fav.attraction) >= float(traditional.attraction) and float(fav.regard) > float(traditional.regard), "a gift that suits them counts more (coal to a smith)")
	check(float(useless.attraction) == 0.0 and float(useless.regard) > 0.0, "a merely useful thing earns a little regard and no attraction")
	# the gift moves real goods
	w.player.inv.add("flower", 3)
	var had := smith.inv.count("flower")
	var said := r.give(ME, smith, "flower")
	check(said != "" and smith.inv.count("flower") == had + 1 and w.player.inv.count("flower") == 2, "a gift moves one flower from the pack to theirs")
	var t := r.peek(ME, smith.id)
	check(float(t.attraction) > 0.0 and float(t.regard) > 0.0, "and raises the tie")
	var a1 := float(t.attraction)
	r.give(ME, smith, "flower")
	check(float(r.peek(ME, smith.id).attraction) == a1, "a second gift the same day counts nothing")
	next_day(w)
	r.give(ME, smith, "flower")
	var a2 := float(r.peek(ME, smith.id).attraction)
	check(a2 > a1 and a2 - a1 < a1, "the same gift again the next day counts for less (%.1f, then +%.1f)" % [a1, a2 - a1])
	var kid: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.role == "child")[0]
	check(float(r.gift_effect(ME, kid, "flower").attraction) == 0.0, "a child is never courted: no attraction")


# ---------------------------------------------------------------- befriending ----------------
func test_befriending() -> void:
	var w := new_world()
	var r := w.relations
	var n := single(w)
	check(not r.can_befriend(n), "a stranger cannot be befriended at once")
	r.helped(ME, n)
	r.helped(ME, n)
	w.player.inv.add("bread", 2)
	r.give(ME, n, "bread")
	check(r.can_befriend(n), "after help and a gift the Befriend choice is there (regard %.0f)" % float(r.peek(ME, n.id).regard))
	r.befriend(ME, n.id)
	check(r.player_friend(n) and not r.can_befriend(n), "befriended: no proposal, and only once")
	check(Dialogue.bond_words(w, n) == "your friend", "the talk window says so")


# ---------------------------------------------------------------- courting -------------------
func test_courting() -> void:
	var w := new_world()
	var r := w.relations
	var n := single(w)
	check(r.ask_court(ME, n) != "" and r.stage(ME, n.id) == "", "asking to court a stranger is declined")
	var t := r.tie(ME, n.id)
	t.attraction = float(Relations.cfg().court_at)
	check(r.ask_court(ME, n) == "" and r.stage(ME, n.id) == "courting", "drawn enough, they agree to court")
	t.attraction = float(Relations.cfg().propose_at) + 5.0
	var before := float(t.attraction)
	check(r.propose(ME, n) != "" and r.stage(ME, n.id) == "courting" and float(t.attraction) < before, "a proposal on the first day is too soon: declined, and things cool")
	t.attraction = float(Relations.cfg().propose_at) + 5.0
	for i in int(Relations.cfg().propose_min_days):
		next_day(w)
	check(r.propose(ME, n) == "" and w.player.partner == n.id and n.partner == ME and r.stage(ME, n.id) == "partners", "after courting long enough, yes: partners")
	var other := single(w, "", n.id)
	check(other == null or not r.can_court(ME, other.id), "a partnered player courts nobody else")
	# feelings fade without contact
	var w2 := new_world()
	var m := single(w2)
	var t2 := w2.relations.tie(ME, m.id)
	t2.attraction = 40.0
	t2.last = w2.day()
	for i in 10:
		next_day(w2)
		w2.relations.dawn()
	check(float(t2.attraction) < 40.0, "feelings fade slowly when you stay away (%.1f)" % float(t2.attraction))


# ---------------------------------------------------------------- friends' benefits ----------
func test_friends_benefits() -> void:
	var w := new_world()
	var r := w.relations
	var seller: NPC = null
	var id := ""
	var best := 0
	for n: NPC in w.npcs:                        # the dearest thing anyone sells, so the discount shows
		if not n.alive or n.role != "adult":
			continue
		for x in w.brain.for_sale(n):
			var price: int = w.player_quote(n, str(x), 1, true)[0]
			if price > best:
				best = price
				seller = n
				id = str(x)
	check(seller != null, "someone sells something")
	if seller == null:
		return
	var before: int = w.player_quote(seller, id, 1, true)[0]
	r.befriend(ME, seller.id)
	var after: int = w.player_quote(seller, id, 1, true)[0]
	check(before >= 10 and after < before, "a friend sells cheaper (%d -> %d coins)" % [before, after])
	# a guard who is a friend lets the player off with a warning
	var guard: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.job == "guard" and n.alive)[0]
	w.player.coins = 50
	r.befriend(ME, guard.id)
	var text := w.guard_confront(guard, {}, null, null)
	check(w.player.coins == 50 and text.contains("warning"), "a guard who is your friend lets you off with a warning")
	var w2 := new_world()
	var g2: NPC = w2.npcs.filter(func(n: NPC) -> bool: return n.job == "guard" and n.alive)[0]
	var pal: NPC = single(w2)
	pal.pos = w2.player.pos
	w2.player.coins = 200
	var full := World.theft_fine_for({"bread": 1})
	w2.relations.befriend(ME, pal.id)
	var said := w2.guard_confront(g2, {"bread": 1}, null, null)
	check(200 - w2.player.coins == full / 2 and said.contains(pal.name), "a friend nearby speaks up and halves the fine (%d of %d)" % [200 - w2.player.coins, full])
	# a friend carries for the player's building site without a wage
	var w3 := new_world()
	var friend := single(w3)
	w3.player.coins = 500
	var plot: Dictionary = w3.property.market().filter(func(x): return w3.property.is_parcel(x))[0]
	w3.property.buy(plot, World.PLAYER)
	w3.start_site(plot, "house", World.PLAYER)
	w3.relations.befriend(ME, friend.id)
	friend.job = ""
	var coins := w3.player.coins
	var why := w3.construction.hire(World.PLAYER, friend, plot, 0)
	check(why == "" and w3.player.coins == coins, "a friend carries for your site without a wage (%s)" % (why if why != "" else "hired"))


# ---------------------------------------------------------------- villagers court ------------
func test_villagers_court() -> void:
	var a := new_world(3)
	var b := new_world(3)
	# strangers do not court: with no shared hours nobody takes an interest (CRT-08)
	var c := new_world(3)
	GameData.b("relations").npc_court_chance = 1.0
	for i in 10:
		c.minutes += 1440.0
		c.relations.dawn()
	check(c.relations.interests.is_empty() and int(c.stats.get("courtships", 0)) == 0, "villagers never court someone they have not come to know")
	# shared hours (where they stand: at home, beside neighbours and workmates) build ties, then courting
	for d in 25:
		for w in [a, b]:
			var base := float(w.day() + 1) * 1440.0
			for h in range(7, 22):
				w.minutes = base + h * 60.0
				w.relations.hour(h)
			w.minutes = base + 23.0 * 60.0
			w.relations.dawn()
	GameData.b("relations").npc_court_chance = 0.15
	check(JSON.stringify(a.relations.to_dict()) == JSON.stringify(b.relations.to_dict()), "villagers' ties and courting are the same for the same seed")
	var friends := 0
	for k in a.relations.ties:
		if bool(a.relations.ties[k].friends):
			friends += 1
	check(friends > 0, "time spent together makes villagers friends on their own (%d friendships)" % friends)
	check(int(a.stats.get("courtships", 0)) > 0 and int(a.stats.get("proposals_accepted", 0)) > 0, "people who share their days court and marry (%d courtships, %d accepted)" % [int(a.stats.get("courtships", 0)), int(a.stats.get("proposals_accepted", 0))])
	var known := true
	for id in a.relations.interests:
		known = known and float(a.relations.peek(int(id), int(a.relations.interests[id])).attraction) >= float(Relations.cfg().interest_at)
	check(known, "every interest is in someone they came to know")


func test_shared_hours() -> void:
	var w := new_world()
	var r := w.relations
	var x := single(w)
	var y: NPC = null
	for o: NPC in w.npcs:
		if o != x and o.alive and o.role == "adult" and r.can_court(x.id, o.id):
			y = o
			break
	y.pos = x.pos + Vector2(1, 0)
	x.job = "woodcutter"
	y.job = "woodcutter"
	w.minutes = float(w.day()) * 1440.0 + 9.0 * 60.0
	r.hour(9)
	var t := r.peek(x.id, y.id)
	check(float(t.regard) >= float(Relations.cfg().shared.work_regard) and float(t.attraction) > 0.0, "working side by side builds regard and attraction (%.1f, %.1f)" % [float(t.regard), float(t.attraction)])
	for h in range(10, 18):
		w.minutes = float(w.day()) * 1440.0 + h * 60.0
		r.hour(h)
	check(float(r.peek(x.id, y.id).regard) <= float(Relations.cfg().shared.daily_cap) + 0.01, "a day's shared hours count at most daily_cap")
	var far: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.pos.distance_to(x.pos) > 10.0:
			far = o
			break
	check(float(r.peek(x.id, far.id).regard) == 0.0, "people far apart share nothing")
	# the player: talking counts once a day
	var n := single(w)
	r.talked(n)
	var g := float(r.peek(ME, n.id).regard)
	r.talked(n)
	check(g > 0.0 and float(r.peek(ME, n.id).regard) == g, "talking with a villager counts, once a day")


# ---------------------------------------------------------------- same sex -------------------
func test_same_sex() -> void:
	var w := new_world()
	var r := w.relations
	var n: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.partner < 0 and o.sex == w.player.sex and r.can_court(ME, o.id):
			n = o
			break
	check(n != null and r.can_court(ME, n.id), "the player may court someone of the same sex (CRT-07)")
	if n == null:
		return
	var t := r.tie(ME, n.id)
	t.attraction = 90.0
	r.ask_court(ME, n)
	for i in int(Relations.cfg().propose_min_days):
		next_day(w)
	check(r.propose(ME, n) == "" and w.player.partner == n.id, "and marry them")
	# two villagers of one sex as partners have no children
	var w2 := new_world()
	var women: Array = w2.npcs.filter(func(o: NPC) -> bool: return o.alive and o.role == "adult" and o.sex == "female" and o.partner < 0 and Life.npc_age(w2, o) < 40.0)
	if women.size() >= 2:
		Life._link_partners(women[0], women[1])
		for hh in w2.households:
			hh.pantry.add("wheat", 200)
		var n0 := w2.npcs.size()
		GameData.b("life").birth_interval_years = 0.01
		for i in 40:
			w2.minutes += 1440.0
			Life.births(w2)
		GameData.b("life").birth_interval_years = 2.0
		check(not w2.npcs.slice(n0).any(func(k: NPC) -> bool: return k.mother == women[0].id or k.mother == women[1].id or k.father == women[0].id or k.father == women[1].id), "two women as partners have no children")


# ---------------------------------------------------------------- saving ---------------------
func test_save() -> void:
	var w := new_world()
	var n := single(w)
	w.player.inv.add("flower", 1)
	w.relations.give(ME, n, "flower")
	w.relations.befriend(ME, n.id)
	var t := w.relations.tie(ME, n.id)
	t.stage = "courting"
	t.since = 3
	w.relations.interests[n.id] = 7
	var d := w.to_dict()
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
	check(JSON.stringify(w2.relations.to_dict()) == JSON.stringify(w.relations.to_dict()), "ties and interests save and load unchanged")
	check(w2.relations.player_friend(w2.npc(n.id)) and w2.relations.stage(ME, n.id) == "courting", "a friend and a courtship survive a reload")
	d.erase("relations")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
	check(w3.relations.ties.is_empty(), "an older save without ties loads with everyone a stranger")
