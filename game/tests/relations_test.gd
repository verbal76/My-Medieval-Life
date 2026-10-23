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
	test_chemistry()
	test_closeness()
	test_no_rushing()
	test_seek_company()
	test_refusals()
	test_same_sex()
	test_save()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## An unpartnered adult villager of courting age of a given job ("" any).
func single(w: World, job := "", not_id := -99) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.partner < 0 and n.id != not_id and (job == "" or n.job == job) \
				and Life.npc_age(w, n) >= 18.0 and Life.npc_age(w, n) <= 50.0 and w.relations.can_court(ME, n.id) and w.relations.willing(n):
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
	w.player.inv.add("bread", 3)
	r.helped(ME, n)
	r.give(ME, n, "bread")
	check(not r.can_befriend(n), "a day's help and a gift are not yet a friendship (regard %.0f, the day's limit)" % float(r.peek(ME, n.id).regard))
	next_day(w)
	r.helped(ME, n)
	r.give(ME, n, "bread")
	check(r.can_befriend(n), "after help and gifts on two days the Befriend choice is there (regard %.0f)" % float(r.peek(ME, n.id).regard))
	r.befriend(ME, n.id)
	check(r.player_friend(n) and not r.can_befriend(n), "befriended: no proposal, and only once")
	check(Dialogue.bond_words(w, n) == "your friend", "the talk window says so")


# ---------------------------------------------------------------- courting -------------------
func test_courting() -> void:
	var w := new_world()
	var r := w.relations
	var n := single(w)
	check(r.ask_court(ME, n) != "" and r.stage(ME, n.id) == "", "asking to court a stranger is declined")
	var c := Relations.cfg()
	var t := r.tie(ME, n.id)
	t.regard = float(c.marry_regard) + 10.0
	t.attraction = float(c.court_at) + 10.0
	t.days_known = int(c.court_min_days) - 1
	check(r.ask_court(ME, n) != "", "drawn to you but known only %d days: not yet" % (int(c.court_min_days) - 1))
	t.attraction = float(c.court_at) + 10.0
	t.days_known = int(c.court_min_days)
	check(r.ask_court(ME, n) == "" and r.stage(ME, n.id) == "courting", "drawn enough and known on %d separate days, they agree to court" % int(c.court_min_days))
	t.attraction = float(c.propose_at) + 5.0
	var before := float(t.attraction)
	check(r.propose(ME, n) != "" and r.stage(ME, n.id) == "courting" and float(t.attraction) < before, "a proposal on the first day is too soon: declined, and things cool")
	t.attraction = float(c.propose_at) + 5.0
	for i in int(c.propose_min_days):
		next_day(w)
	t.days_known = int(c.marry_min_days) - 1
	check(r.propose(ME, n) != "", "courted long enough but known on too few days: still too soon")
	t.attraction = float(c.propose_at) + 5.0
	t.days_known = int(c.marry_min_days)
	check(r.propose(ME, n) == "" and w.player.partner == n.id and n.partner == ME and r.stage(ME, n.id) == "partners", "after courting long enough and knowing each other many days, yes: partners")
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
	# a guard who is a friend: judgment off (Build 18) lets the player off with a warning; with the judgment store attached the
	# fine is lowered but never waived (X19-GUARD)
	var guard: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.job == "guard" and n.alive)[0]
	w.player.coins = 50
	var gfull := World.theft_fine_for({})
	r.befriend(ME, guard.id)
	var text := w.guard_confront(guard, {}, null, null)
	check(w.judgment == null and w.player.coins == 50 and text.contains("let off with a warning"), "judgment off: a guard who is your friend waives the fine with a warning (Build 18)")
	JudgmentLive.attach(w)
	w.player.coins = 50
	text = w.guard_confront(guard, {}, null, null)
	var gpaid := 50 - w.player.coins
	check(gpaid >= 1 and gpaid < gfull and text.contains("lowered"), "judgment on: a guard who is your friend lowers the fine but still fines (%d of %d)" % [gpaid, gfull])
	w.judgment = null
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
	# the player's talk (CRT-09/10): 0.25 the first time a day, 0.11 the next, less each time after
	var sh: Dictionary = Relations.cfg().shared
	var n := single(w, "", x.id)
	r.talked(n)
	var g1 := float(r.peek(ME, n.id).regard)
	check(absf(g1 - float(sh.talk_first)) < 0.001, "the first talk of the day adds %.2f" % float(sh.talk_first))
	r.talked(n)
	var g2 := float(r.peek(ME, n.id).regard)
	check(absf(g2 - g1 - float(sh.talk_more)) < 0.001, "a second talk adds only %.2f" % float(sh.talk_more))
	for i in 20:
		r.talked(n)
	check(float(r.peek(ME, n.id).regard) - g2 < float(sh.talk_more) * 1.01, "twenty more presses of the talk button add less than one more talk")


## Chemistry: fixed per pair and world, most pairs little, a few a great deal; it scales attraction from time
## together; courting pairs gain faster; someone refused for good is not courted again.
func test_chemistry() -> void:
	var w := new_world()
	var r := w.relations
	var c := Relations.cfg()
	var vals: Array = []
	for i in 200:
		vals.append(r.chemistry(i, i + 37))
	vals.sort()
	check(float(vals[0]) >= float(c.chemistry_min) and float(vals[-1]) <= float(c.chemistry_min) + float(c.chemistry_span) + 0.001, "chemistry stays within its range")
	check(float(vals[100]) < 1.0 and float(vals[180]) > 1.2, "most pairs click a little, a few a great deal (median %.2f, top tenth %.2f)" % [float(vals[100]), float(vals[180])])
	check(r.chemistry(5, 9) == r.chemistry(9, 5) and r.chemistry(5, 9) == new_world().relations.chemistry(5, 9), "the same for a pair either way and for the same seed")
	var x := single(w)
	var y: NPC = null
	for o: NPC in w.npcs:
		if o != x and o.alive and o.role == "adult" and r.can_court(x.id, o.id):
			y = o
			break
	w.minutes = float(w.day()) * 1440.0 + 19.0 * 60.0
	r.share(x.id, y.id, "social")
	var plain := float(r.peek(x.id, y.id).attraction)
	check(absf(plain - float(c.shared.social_attraction) * r.chemistry(x.id, y.id)) < 0.001, "an evening together builds attraction times their chemistry")
	r.tie(x.id, y.id).stage = "courting"
	w.minutes += 60.0
	r.share(x.id, y.id, "social")
	check(absf(float(r.peek(x.id, y.id).attraction) - plain * (1.0 + float(c.shared.courting_factor))) < 0.01, "and twice as much while courting")
	r.tie(x.id, y.id).refused = true
	r.tie(x.id, y.id).stage = ""
	r.tie(x.id, y.id).attraction = 90.0
	r.tie(x.id, y.id).days_known = 10
	GameData.b("relations").npc_court_chance = 1.0
	r.interests.erase(x.id)
	r.dawn()
	GameData.b("relations").npc_court_chance = 0.15
	check(int(r.interests.get(x.id, -1)) != y.id, "someone who refused them for good is not courted again")


## The player's closeness (CRT-10): minutes near a villager, the nearest counting most, within a day's limit;
## a day counts as known after close.known_minutes near.
func test_closeness() -> void:
	var w := new_world()
	var r := w.relations
	var cl: Dictionary = Relations.cfg().close
	var a := single(w)
	var b := single(w, "", a.id)
	w.minutes = float(w.day()) * 1440.0 + 10.0 * 60.0
	a.pos = w.player.pos + Vector2(0.8, 0)
	b.pos = w.player.pos + Vector2(2.0, 0)
	check(not w.asleep(a) and not w.asleep(b), "two villagers awake beside the player")
	for i in 5:                                   # ten minutes
		r.player_tick(2.0)
	var ra := float(r.peek(ME, a.id).regard)
	var rb := float(r.peek(ME, b.id).regard)
	check(ra > 0.0 and rb > 0.0 and absf(ra - rb * float(cl.focus_factor)) < 0.001, "time near counts, the nearest (whose name is up) %.0fx (%.3f, %.3f)" % [float(cl.focus_factor), ra, rb])
	check(int(r.peek(ME, a.id).days_known) == 0, "a few minutes are not yet a day's acquaintance")
	for i in 10:
		r.player_tick(2.0)
	check(int(r.peek(ME, a.id).days_known) == 1, "after %d minutes near, the day counts as known" % int(cl.known_minutes))
	for i in 600:                                 # twenty more hours side by side
		r.player_tick(2.0)
	check(float(r.peek(ME, a.id).regard) <= float(cl.daily_regard) + 0.01, "a whole day side by side gives at most close.daily_regard (%.1f)" % float(r.peek(ME, a.id).regard))
	var far: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.pos.distance_to(w.player.pos) > 10.0:
			far = o
			break
	check(float(r.peek(ME, far.id).regard) == 0.0, "nobody far away gains anything")


## No rushing (owner: "I don't want this to be just keep spamming buttons and instantly get married in 10
## minutes"): a single day of everything at once cannot reach courting, and an ideal suitor who spends hours
## near someone, talks, brings their favourite gift and helps every day marries only after marry_min_days.
func test_no_rushing() -> void:
	var w := new_world()
	var r := w.relations
	var c := Relations.cfg()
	var n := single(w, "smith")
	if n == null:
		n = single(w)
		n.job = "smith"
	w.player.inv.add("coal", 40)
	w.player.inv.add("flower", 40)
	var married := -1
	var court_day := -1
	for day in 30:
		w.minutes = float(day) * 1440.0 + 9.0 * 60.0
		n.pos = w.player.pos + Vector2(0.8, 0)
		for i in 180:                             # six hours beside them
			r.player_tick(2.0)
		for i in 50:
			r.talked(n)
		r.give(ME, n, "coal")
		r.give(ME, n, "flower")
		r.helped(ME, n)
		if day == 0:
			check(r.ask_court(ME, n) != "", "a whole first day of everything at once: they will not court yet")
			check(r.propose(ME, n) != "", "and certainly not marry")
		# they ask when the mood says so (the gift window: "sweet on you", "plainly in love"); a refusal
		# for knowing each other too few days cools things, as it would for a player
		var att := float(r.peek(ME, n.id).attraction)
		if r.stage(ME, n.id) == "" and att >= float(c.court_at) and r.ask_court(ME, n) == "":
			court_day = day
		elif r.stage(ME, n.id) == "courting" and att >= float(c.propose_at) and r.propose(ME, n) == "":
			married = day
			break
		w.relations.dawn()
	check(court_day >= int(c.court_min_days) - 1, "courting begins no sooner than day %d (day %d)" % [int(c.court_min_days), court_day + 1])
	check(married >= int(c.marry_min_days) - 1 and married < 30, "the ideal suitor marries on day %d, not before day %d of knowing them" % [married + 1, int(c.marry_min_days)])


## CRT-11: a single villager with coins (or a gift) to spare seeks out the one they court in the evening,
## buying a gift first when they can; one without the means does not.
func test_seek_company() -> void:
	var w := new_world()
	var r := w.relations
	var a := single(w)
	var b: NPC = null
	for o: NPC in w.npcs:
		if o != a and o.alive and o.role == "adult" and o.partner < 0 and r.can_court(a.id, o.id):
			b = o
			break
	r.interests[a.id] = b.id
	w.minutes = float(w.day()) * 1440.0 + 19.0 * 60.0
	GameData.b("relations").seek.chance = 1.0
	a.coins = 0
	for id in a.inv.ids():
		a.inv.items.erase(id)
	GameData.b("relations").seek.poor_chance = 0.0
	check(not w.brain._plan_seek_company(a), "with nothing to spare they go out less (here: not tonight)")
	GameData.b("relations").seek.poor_chance = 1.0
	check(w.brain._plan_seek_company(a) and not a.plan.any(func(st) -> bool: return str(st.k) == "do" and str(st.act) == "buy_from"), "on the evenings they do go, they buy no gift")
	GameData.b("relations").seek.poor_chance = 0.25
	a.coins = 100
	var ok: bool = w.brain._plan_seek_company(a)
	check(ok and a.doing == "spending time with %s" % b.name, "with coins to spare they go to spend the evening with %s" % b.name)
	var bought := a.plan.any(func(st) -> bool: return str(st.k) == "do" and str(st.act) == "buy_from")
	var sellers := w.npcs.any(func(v: NPC) -> bool: return v.alive and not w.asleep(v) and ((v.job == "tavernkeeper" and v.inv.has("ale")) or (w.brain.buy_role(v) == "merchant_food" and v.inv.has("bread"))))
	check(bought == sellers, "buying a gift on the way when someone sells ale or bread (%s)" % ("buys one" if bought else "nobody sells"))
	var walk: Dictionary = a.plan[a.plan.size() - 2]
	var stay: Dictionary = a.plan[a.plan.size() - 1]
	check(str(walk.k) == "go" and Vector2(walk.to).distance_to(Vector2(b.cell())) <= 2.0 and str(stay.k) == "work" and float(stay.min) >= 40.0, "then walking to %s to stay a while" % b.name)
	# a gift already in hand is enough, coins or not
	a.coins = 0
	a.inv.add("flower", 1)
	check(w.brain._plan_seek_company(a), "a flower in hand is reason enough to go")
	GameData.b("relations").seek.chance = 0.6


## CRT-12: proposals can be refused: not the marrying kind, a rival they prefer, a killer or a known thief,
## and harm done to someone's family or friends turns them against the player.
func test_refusals() -> void:
	var c := Relations.cfg()
	var ready := func(w: World, n: NPC) -> Dictionary:      # a courtship that would otherwise succeed
		var t: Dictionary = w.relations.tie(ME, n.id)
		t.regard = 60.0
		t.attraction = 90.0
		t.days_known = int(c.marry_min_days)
		t.stage = "courting"
		t.since = w.day() - int(c.propose_min_days)
		return t
	# not the marrying kind
	var w := new_world()
	var unwilling: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.partner < 0 and w.relations.can_court(ME, o.id) and not w.relations.willing(o):
			unwilling = o
			break
	check(unwilling != null, "some villagers do not mean to marry (%d%%)" % int(c.unwilling_percent))
	if unwilling != null:
		ready.call(w, unwilling)
		check(w.relations.propose(ME, unwilling).contains("don't mean to marry") and w.player.partner == -1, "they refuse however well the courting went")
	# a rival suitor they prefer
	var n := single(w)
	var t: Dictionary = ready.call(w, n)
	var rival: NPC = null
	for o: NPC in w.npcs:
		if o != n and o.alive and o.role == "adult" and w.relations.can_court(o.id, n.id):
			rival = o
			break
	var rt := w.relations.tie(rival.id, n.id)
	rt.stage = "courting"
	rt.attraction = 95.0
	check(w.relations.propose(ME, n).contains("someone else") and w.player.partner == -1, "a rival suitor they care for more: refused")
	# too little regard (harm lowered it)
	var w2 := new_world()
	var m := single(w2)
	var t2: Dictionary = ready.call(w2, m)
	t2.regard = float(c.marry_regard) - 1.0
	check(w2.relations.propose(ME, m).contains("think well enough"), "not thinking well enough of the suitor: refused")
	# a killer
	var w3 := new_world()
	var k := single(w3)
	ready.call(w3, k)
	var victim: NPC = w3.npcs.filter(func(o: NPC) -> bool: return o.alive and o.role == "adult" and o != k and o.job != "guard")[0]
	w3.kill(victim, "slain by %s %s" % [w3.player.name, w3.player.family])
	check(w3.relations.killings == 1 and w3.relations.propose(ME, k).contains("killed"), "a suitor who has killed a villager: refused")
	check(w3.relations.ask_court(ME, single(w3, "", k.id)) != "", "and nobody will even court them")
	# a known thief
	var w4 := new_world()
	var q := single(w4)
	ready.call(w4, q)
	for i in int(c.notoriety_refuse):
		w4.player.crimes.append({"day": w4.day(), "kind": "theft", "what": "bread", "victim": -1, "witnesses": 2, "items": {}, "qty": 1, "value": 2})
	check(w4.relations.propose(ME, q).contains("thief"), "a suitor seen stealing again and again: refused")
	# stealing from someone's family or friend lowers their regard too
	var w5 := new_world()
	var mum: NPC = null
	var kid: NPC = null
	for o: NPC in w5.npcs:
		if o.alive and o.mother >= 0 and w5.npc(o.mother) != null and w5.npc(o.mother).alive:
			kid = o
			mum = w5.npc(o.mother)
			break
	var pal := single(w5, "", mum.id)
	w5.relations.befriend(pal.id, kid.id)
	w5.relations.tie(ME, mum.id).regard = 40.0
	w5.relations.tie(ME, pal.id).regard = 40.0
	w5.relations.harmed(kid, float(c.victim_harm))
	check(float(w5.relations.peek(ME, mum.id).regard) < 40.0, "robbing someone lowers their mother's regard for you (%.1f)" % float(w5.relations.peek(ME, mum.id).regard))
	check(float(w5.relations.peek(ME, pal.id).regard) < 40.0 and float(w5.relations.peek(ME, pal.id).regard) > float(w5.relations.peek(ME, mum.id).regard),
			"and, less, their friend's")
	# villagers refuse villagers too
	var w6 := new_world()
	var u: NPC = null
	var v: NPC = null
	for o: NPC in w6.npcs:
		if o.alive and o.role == "adult" and o.partner < 0 and not w6.relations.willing(o):
			u = o
			break
	for o: NPC in w6.npcs:
		if u != null and o != u and o.alive and o.role == "adult" and o.partner < 0 and w6.relations.can_court(o.id, u.id) and w6.relations.willing(o):
			v = o
			break
	if u != null and v != null:
		var tv := w6.relations.tie(v.id, u.id)
		tv.regard = 60.0
		tv.attraction = 90.0
		tv.days_known = int(c.marry_min_days)
		tv.stage = "courting"
		tv.since = w6.day() - int(c.propose_min_days)
		check(w6.relations.propose(v.id, u) != "" and u.partner == -1, "a villager can refuse a villager's proposal too")


# ---------------------------------------------------------------- same sex -------------------
func test_same_sex() -> void:
	var w := new_world()
	var r := w.relations
	var n: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.partner < 0 and o.sex == w.player.sex and r.can_court(ME, o.id) and r.willing(o):
			n = o
			break
	check(n != null and r.can_court(ME, n.id), "the player may court someone of the same sex (CRT-07)")
	if n == null:
		return
	var t := r.tie(ME, n.id)
	t.attraction = 90.0
	t.regard = 60.0
	t.days_known = int(Relations.cfg().marry_min_days)
	r.ask_court(ME, n)
	for i in int(Relations.cfg().propose_min_days):
		next_day(w)
	t.attraction = 90.0
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
