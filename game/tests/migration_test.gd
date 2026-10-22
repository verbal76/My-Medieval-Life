extends SceneTree
## Expansion 18, MIGRATE-18 (owner Q18-7, "Both ways, for reasons"): people move between the village and the five neighbouring
## settlements for work, land, marriage or hunger, each only when its real signal is there, carrying their age, name, skills, purse and
## goods; nobody is made or lost (people, coins, goods) and it is deterministic and saved.
##   godot --headless --path game --script res://tests/migration_test.gd

const Census := preload("res://tests/census.gd")

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL: " + what)


func _init() -> void:
	GameData.ensure()
	test_no_reason_no_move()
	test_hunger()
	test_work()
	test_land()
	test_marriage()
	test_carried_across()
	test_conservation_and_save()
	test_old_save()
	test_determinism()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ------------------------------------------------------------------ fixtures ----------------
func _world(seed_ := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed_)
	w.regions.step_day(w.day())                       # every settlement on the village's day
	return w


## What must not change when people move: the whole world's coins (net of what came from outside), every good, and the people.
func _books(w: World) -> Dictionary:
	var goods: Dictionary = Census.goods(w).duplicate()
	var rg := w.regions.goods()
	for k in rg:
		goods[k] = int(goods.get(k, 0)) + int(rg[k])
	var alive := 0
	for n: NPC in w.npcs:
		if n.alive and n.role != "bandit":
			alive += 1
	return {"coins": w.total_coins() + w.regions.coins() - (w.coin_sources + w.regions.net_paid_by_village()),
		"goods": goods, "people": alive + w.regions.population()}


func _same(a: Dictionary, b: Dictionary) -> bool:
	return int(a.coins) == int(b.coins) and a.goods == b.goods and int(a.people) == int(b.people)


func _sound(w: World) -> bool:
	return w.regions.audit() == "" and w.regions.net_migrants_from_village() == w.regions.net_migrants_counted()


## A household of the village without an office-holder, a market trader or any tie to the player, and the lowest id (from `after`).
func _plain(w: World, after := 2) -> int:
	for h in range(maxi(3, after + 1), w.households.size()):
		var ms: Array = w.brain._members(h)
		if not w.households[h].get("ended", false) and not ms.is_empty() and not Migration._any_barred(w, ms):
			return h
	return -1


func _feed_settlement(s: OffMapSettlement) -> void:
	s.biz.farm.stock.wheat = int(s.biz.farm.stock.get("wheat", 0)) + 3000
	s.reopen_books()


## The household's food and coins go to the granary and the treasury (nothing is destroyed), so it has none.
func _starve(w: World, h: int) -> void:
	for id in w.households[h].pantry.ids():
		w.granary.add(id, w.households[h].pantry.count(id))
	w.households[h].pantry.items.clear()
	for o: NPC in w.brain._members(h):
		for id in o.inv.ids():
			w.granary.add(id, o.inv.count(id))
		o.inv = Inventory.new()
		w.treasury += o.coins
		o.coins = 0


func _closed_market() -> Dictionary:
	var m := {}
	for j in ["manor_hand", "farmer", "woodcutter", "hunter", "miner", "prospector", "tailor", "barber", "preacher", "church_assistant"]:
		m[j] = {"pay": 9.0, "open": 0, "tool": "", "at": Vector2i.ZERO}
	return m


## Another grown, unmarried, willing member for a settlement household (a settlement's candidates are few at the start).
func _add_member(s: OffMapSettlement, hi: int, sex: int, age := 24.0) -> void:
	s.hh[hi].mem.append([s.day - roundi(age * s._yd), sex, 0, 0])
	s._recount(s.hh[hi])
	s.reopen_books()


func _member_named(s: OffMapSettlement, name: String) -> Array:
	for h in s.hh:
		for m in h.mem:
			if m.size() > OffMapSettlement.M_WHO and str(m[OffMapSettlement.M_WHO].n) == name:
				return [h, m]
	return []


# ------------------------------------------------------------------ no reason, no move ----------------
func test_no_reason_no_move() -> void:
	var w := _world()
	var s: OffMapSettlement = w.regions.by_id["wulstead"]
	var before := _books(w)
	check(not Migration._hunger_out(w, s) and not Migration._hunger_in(w, s), "hunger: a fed village and fed settlements send nobody")
	check(not Migration._work_out(w, s) and not Migration._work_in(w, s), "work: nobody out of work, no household short of it, no move")
	check(not Migration._land_out(w, s) and not Migration._land_in(w, s), "land: no household waiting for a home, none landless, no move")
	var moved := 0
	for d in 3:
		moved += Migration.visit(w)
	check(moved == 0 and w.regions.moves.is_empty() and int(w.stats.get("migrants_out", 0)) == 0 and int(w.stats.get("migrants_in", 0)) == 0,
		"marriage waits for acquaintance, so three visits on the first days move nobody")
	check(_same(before, _books(w)) and _sound(w), "and nothing changed in the books")
	var a := 0
	for n: NPC in w.npcs:
		a += 1 if n.away != "" else 0
	check(a == 0, "nobody is away")


# ------------------------------------------------------------------ hunger ----------------
func test_hunger() -> void:
	var w := _world()
	var s: OffMapSettlement = w.regions.by_id["wulstead"]
	var h := _plain(w)
	check(h >= 3, "a household without an office-holder is there to test")
	_feed_settlement(s)
	_starve(w, h)
	w.food_days = 10.0
	check(not Migration._hunger_out(w, s), "out: a hungry household stays while the village is not in famine (its own relief serves it)")
	w.food_days = 0.5
	var members: Array = w.brain._members(h)
	var names := members.map(func(o): return o.name)
	var ages := members.map(func(o): return Life.npc_age(w, o))
	var pop0 := s.population()
	for o: NPC in members:
		o.coins = 7
		o.inv.add("axe")
	w.households[h].pantry.add("bread", 2)
	var before := _books(w)
	check(w.brain.household_food_days(h) < float(GameData.b("relief_trigger_days")), "the household is under the relief line")
	check(Migration._hunger_out(w, s), "out: a household under the relief line in famine goes to a settlement with food above its claim")
	var alive_after: int = w.brain._members(h).size()
	check(alive_after == 0, "all of its members left the village")
	var all_away := true
	for o: NPC in members:
		all_away = all_away and not o.alive and o.away == "wulstead"
	check(all_away, "they are marked as away at Wulstead, not dead")
	check(s.population() == pop0 + members.size(), "and the settlement's people grew by exactly that many (%d)" % members.size())
	var found := _member_named(s, names[0])
	check(not found.is_empty(), "each keeps their name in the settlement")
	if not found.is_empty():
		var age := s._age(found[1])
		check(absf(age - float(ages[0])) < 1.0 / float(Life.year_days()) + 0.001, "and their age (%.2f years)" % age)
	check(int(w.regions.move_counts.get("out:hunger", 0)) == members.size() and int(w.stats.get("migrant_out_hunger", 0)) == members.size(), "the move is recorded as hunger, out")
	check(_same(before, _books(w)) and _sound(w), "people, coins and goods are conserved across the boundary (axes, bread, purses)")
	check(int(s.flows.outside_coins_in) == 7 * members.size() and int(s.flows.outside_in.get("axe", 0)) == members.size(), "and the settlement's flow lines show the purses and packs that came")
	check(w.households[h].get("ended", false), "the emptied household is ended, its house back with the manor")
	# in: a hungry settlement household, a village with food to spare
	var w2 := _world()
	var s2: OffMapSettlement = w2.regions.by_id["netherton"]
	var hi := -1
	for i in s2.hh.size():
		if str(s2.hh[i].trade) != "official" and s2._workers(s2.biz[OffMapSettlement.TRADE_BIZ[s2.hh[i].trade]]) >= 2:
			hi = i
			break
	var sh: Dictionary = s2.hh[hi]
	sh.hungry = 3
	sh.coins = 0
	sh.pantry = {}
	sh.credit = 0.0
	s2.reopen_books()
	var size: int = sh.mem.size()
	w2.food_days = 0.5
	check(not Migration._hunger_in(w2, s2), "in: nobody comes while the village itself is in famine")
	w2.food_days = 30.0
	sh.hungry = 0
	check(not Migration._hunger_in(w2, s2), "in: a household that is not hungry stays")
	sh.hungry = 3
	sh.coins = 90
	check(not Migration._hunger_in(w2, s2), "in: a household that can buy a day's food stays")
	sh.coins = 0
	var alive0 := w2.alive_count()
	var before2 := _books(w2)
	check(Migration._hunger_in(w2, s2), "in: a hungry household that cannot buy food comes to a village with food to spare")
	check(w2.alive_count() == alive0 + size and not sh.alive, "the village gained its %d people and the household is gone from the settlement" % size)
	check(_same(before2, _books(w2)) and _sound(w2), "and again nothing was made or lost")
	check(int(w2.regions.move_counts.get("in:hunger", 0)) == size, "recorded as hunger, in")
	for n: NPC in w2.npcs:
		if n.alive and n.household >= 0 and n.id > 120 and w2.households[n.household].members.has(n.id):
			check(n.hunger > 0.0 and n.home != "", "an arrival is housed (%s)" % n.name)
			break


# ------------------------------------------------------------------ work ----------------
func test_work() -> void:
	var w := _world()
	var s: OffMapSettlement = w.regions.by_id["higham"]
	s.biz.farm.rate = 12.0
	var h := _plain(w)
	var who: NPC = null
	for o: NPC in w.brain._members(h):
		if o.role == "adult" and Life._may_move(w, o):
			who = o
			break
	who.job = ""
	who.skills = {"mining": 777}
	who.coins = 33
	who.inv.add("axe")
	var hh: Dictionary = w.households[h]
	hh.econ = {"streak": 0}
	check(not Migration._work_out(w, s, _closed_market()), "out: a household that lives on its income sends nobody for work")
	hh.econ = {"streak": 3}
	var open := _closed_market()
	open.farmer.open = 2
	check(not Migration._work_out(w, s, open), "out: nobody leaves while the village's labour market has a place open")
	s.biz.farm.rate = 3.0
	check(not Migration._work_out(w, s, _closed_market()), "out: nor for a settlement trade that pays no better than switch_to_at_least")
	s.biz.farm.rate = 12.0
	var before := _books(w)
	var pop0 := s.population()
	check(Migration._work_out(w, s, _closed_market()), "out: an adult without a trade, in a household that cannot live on its income, with no place open, goes to a trade that pays")
	check(not who.alive and who.away == "higham" and s.population() == pop0 + 1, "they are away, and the settlement has one more person")
	check(_same(before, _books(w)) and _sound(w), "the books balance: the purse of 33 coins and the axe crossed")
	var m := _member_named(s, who.name)
	check(not m.is_empty() and int(m[1][OffMapSettlement.M_WHO].sk.get("mining", 0)) == 777, "their skills went with them")
	# in: the same person comes back for work (a place in the labour market that pays more than their household made)
	var hs: Dictionary = m[0]
	hs.low = 2
	hs.rate = 1.0
	hs.mem.push_front(hs.mem.pop_back())                     # (they are the one the settlement sends: the first grown, unmarried member)
	hs.mem[0][OffMapSettlement.M_PAIR] = 0
	var mk := _closed_market()
	check(not Migration._work_in(w, s, mk), "in: with no place open in the village nobody comes")
	mk.manor_hand.open = 1
	hs.low = 0
	check(not Migration._work_in(w, s, mk), "in: a settlement household that earns enough stays")
	hs.low = 2
	var before2 := _books(w)
	var alive0 := w.alive_count()
	check(Migration._work_in(w, s, mk), "in: an adult of a household short of work takes an open place that pays more than it earned")
	check(w.alive_count() == alive0 + 1 and _same(before2, _books(w)) and _sound(w), "one more villager, and the books balance")
	var back: NPC = w.npcs.back()
	check(back.alive and back.name == who.name and back.skills.get("mining", 0) == 777 and back.job == "manor_hand", "they are a new villager with the same name and skills, in the work they came for")
	check(absf(Life.npc_age(w, back) - Life.npc_age(w, who)) < 2.0 / float(Life.year_days()), "and the same age")
	# in, for a post nobody could fill (the newcomer's place)
	var w2 := _world()
	var s2: OffMapSettlement = w2.regions.by_id["higham"]
	for o: NPC in w2.npcs:
		if o.alive and o.role == "adult" and NPCBrain.APPRENTICE_FROM.has(o.job):
			o.job = "farmer"
		if o.job == "smith":
			o.job = "farmer"
	w2.vacancies.append({"job": "smith", "workplace": "", "home": "", "household": -1, "day": w2.day() - 30, "who": "the late Test Smith", "heir": -1})
	var smith_hh := -1
	for i in s2.hh.size():
		if str(s2.hh[i].trade) == "smith":
			smith_hh = i
	var sm: Dictionary = s2.hh[smith_hh]
	sm.low = 1
	_add_member(s2, smith_hh, 0)
	var newcomer_coins0 := int(w2.stats.get("newcomer_coins_in", 0))
	check(Migration.open_vacancies(w2).size() == 1, "a post open past succession_days with no apprentice is a newcomer's place")
	var before3 := _books(w2)
	var ok := Migration._work_in(w2, s2, _closed_market())
	check(ok and w2.vacancies.is_empty(), "in: a real migrant takes the post before a newcomer is made for it")
	check(int(w2.stats.get("newcomer_coins_in", 0)) == newcomer_coins0 and _same(before3, _books(w2)) and _sound(w2), "no purse is made from nothing for them")
	var smiths := 0
	for n: NPC in w2.npcs:
		smiths += 1 if n.alive and n.job == "smith" else 0
	check(smiths == 1, "and the smithy has its smith again")


# ------------------------------------------------------------------ land ----------------
func test_land() -> void:
	var w := _world()
	var s: OffMapSettlement = w.regions.by_id["garton"]
	_feed_settlement(s)
	var h := _plain(w)
	var goal := {"need": "no home", "since": w.day() - 5, "by": -1, "plan": "home", "cost": 300, "short": 100, "why": "saving for a home of its own"}
	w.households[h].housing = {"no home": goal.duplicate()}
	var members: Array = w.brain._members(h)
	var before := _books(w)
	w.households[h].housing["no home"].short = 0
	check(not Migration._land_out(w, s), "out: a household whose housing goal is not waiting on coins stays")
	w.households[h].housing["no home"].short = 100
	w.households[h].housing["no home"].since = w.day() - 1
	check(not Migration._land_out(w, s), "out: nor one that has waited less than mobility_unsustainable_days")
	w.households[h].housing["no home"].since = w.day() - 5
	check(Migration._land_out(w, s), "out: a household that has waited on coins for a home for the village's wait goes to a settlement whose land yields food")
	check(w.brain._members(h).is_empty() and _same(before, _books(w)) and _sound(w), "all went, and the books balance")
	check(int(w.regions.move_counts.get("out:land", 0)) == members.size(), "recorded as land, out")
	# a crowded household: the grown member who would have founded a household, with a partner
	var w1 := _world()
	var c := -1
	for hh in range(3, w1.households.size()):
		var f: NPC = w1.construction.founder_of(hh)
		if f != null and not Migration._any_barred(w1, [f]):
			c = hh
			break
	if c >= 0:
		var f: NPC = w1.construction.founder_of(c)
		w1.households[c].housing = {"crowded": {"need": "crowded", "since": w1.day() - 5, "by": -1, "plan": "split", "cost": 300, "short": 100, "why": ""}}
		var s1: OffMapSettlement = w1.regions.by_id["garton"]
		_feed_settlement(s1)
		var rest: int = w1.brain._members(c).size()
		check(Migration._land_out(w1, s1) and not f.alive and w1.brain._members(c).size() >= 1 and w1.brain._members(c).size() < rest, "out: a crowded household sends the grown member who would have founded a household (not the household)")
	else:
		check(true, "(no household with a founder in this village to test the crowded case)")
	# in: a landless settlement household that can pay for a house on the manor's market
	var w2 := _world()
	var s2: OffMapSettlement = w2.regions.by_id["wulstead"]
	var hi := -1
	for i in s2.hh.size():
		var x: Dictionary = s2.hh[i]
		if str(x.trade) != "official" and int(x.adults) == 2 and x.mem.size() >= 2 and s2._workers(s2.biz[OffMapSettlement.TRADE_BIZ[x.trade]]) >= 2:
			hi = i
			break
	var sh: Dictionary = s2.hh[hi]
	var people: int = sh.mem.size()
	sh.coins = 600
	sh.landless = 1
	s2.reopen_books()
	if not Migration._can_house(w2, 600, true):
		var gone := _plain(w2)
		for o: NPC in w2.brain._members(gone):
			o.alive = false
		w2.property.household_ended(gone)                  # a house falls to the manor and is for sale
	check(Migration._can_house(w2, 600, true), "a house is for sale on the manor's market")
	sh.landless = 0
	check(not Migration._land_in(w2, s2), "in: a household with land of its own does not come")
	sh.landless = 1
	sh.coins = 2
	check(not Migration._land_in(w2, s2), "in: nor one that cannot pay for a house by the village's rule")
	sh.coins = 600
	var before2 := _books(w2)
	var homes0 := 0
	for hh2 in w2.households:
		homes0 += 1 if not hh2.get("ended", false) and str(hh2.home) != "" else 0
	check(Migration._land_in(w2, s2), "in: a landless settlement household with the price of a house comes and takes one")
	var nh: Dictionary = w2.households[w2.households.size() - 1]
	check(str(nh.home) != "" and w2.brain._members(int(nh.id)).size() == people and not sh.alive, "it has a home of its own in the village (%s) and left the settlement" % str(nh.home))
	check(_same(before2, _books(w2)) and _sound(w2), "the books balance (the price of the house went to the manor)")
	check(int(w2.regions.move_counts.get("in:land", 0)) == people, "recorded as land, in")


# ------------------------------------------------------------------ marriage ----------------
func test_marriage() -> void:
	var w := _world()
	var s: OffMapSettlement = w.regions.by_id["bourton"]
	_add_member(s, 3, 0)
	var men := Migration._marriageable_in(s, 0)
	check(not men.is_empty(), "the settlement has a grown, willing, unpartnered man")
	# out: a villager bride and a settlement groom
	var bride: NPC = null
	for n: NPC in w.npcs:
		if n.sex == "female" and Migration._marriageable(w, n) and Life._may_move(w, n):
			bride = n
			break
	check(bride != null, "the village has a grown, willing, unpartnered woman")
	bride.coins = 40
	bride.skills = {"cooking": 500}
	var before := _books(w)
	var partnerships := int(w.stats.get("partnerships", 0))
	var hh0 := s.households()
	var pop0 := s.population()
	check(not Migration._marry_out(w, s), "out: they begin to know each other at the caravan; no wedding that day")
	check(w.regions.suits.has("bourton|out"), "and the courtship is kept")
	w.minutes += 5.0 * World.DAY
	check(not Migration._marry_out(w, s), "out: nor five days on (marry_min_days is %d)" % int(GameData.b("relations").marry_min_days))
	w.minutes += 8.0 * World.DAY
	var ok := Migration._marry_out(w, s)
	check(ok and not bride.alive and bride.away == "bourton", "out: after marry_min_days of acquaintance she goes to him")
	check(s.households() == hh0 + 1 or s.households() == hh0, "a household is founded (the last of one may close)")
	check(s.population() == pop0 + 1 and int(w.stats.get("partnerships", 0)) == partnerships + 1, "the settlement has one more person, and it counts as a partnership")
	var m := _member_named(s, bride.name)
	check(not m.is_empty() and int(m[1][OffMapSettlement.M_PAIR]) == 1 and int(m[0].adults) == 2, "she is half of a couple in a household of two grown people")
	check(not m.is_empty() and int(m[1][OffMapSettlement.M_WHO].sk.get("cooking", 0)) == 500 and int(m[0].coins) >= 40, "with her skills and her purse")
	check(_same(before, _books(w)) and _sound(w), "people, coins and goods are conserved")
	check(not w.regions.suits.has("bourton|out"), "the courtship ended with the wedding")
	# in: a settlement bride and a villager groom with a bed
	var w2 := _world()
	var s2: OffMapSettlement = w2.regions.by_id["bourton"]
	_add_member(s2, 3, 1)
	var brides := Migration._marriageable_in(s2, 1)
	var bm: Array = s2.hh[brides[0][0]].mem[brides[0][1]]
	bm.append({"n": "Mabel", "f": "Stone", "sk": {"cooking": 300}})
	var groom: NPC = null
	for n: NPC in w2.npcs:
		if n.sex == "male" and Migration._marriageable(w2, n) and n.household >= 3 \
				and w2.construction.beds_in(str(w2.households[n.household].home)) >= w2.construction.beds_needed(n.household):
			groom = n
			break
	check(groom != null, "the village has a willing man whose house has a bed")
	var before2 := _books(w2)
	check(not Migration._marry_in(w2, s2), "in: acquaintance first")
	w2.minutes += 13.0 * World.DAY
	var alive0 := w2.alive_count()
	check(Migration._marry_in(w2, s2), "in: after marry_min_days a settlement woman comes to marry a villager")
	var wife: NPC = null
	for n: NPC in w2.npcs:
		if n.alive and n.partner == groom.id:
			wife = n
	check(wife != null and groom.partner == wife.id and Life.has_partner(w2, groom) and Life.has_partner(w2, wife), "they are partners, both ways (the village's own link)")
	check(wife != null and wife.household == groom.household and wife.home == groom.home, "she lives in his house")
	check(w2.alive_count() == alive0 + 1 and _same(before2, _books(w2)) and _sound(w2), "one more villager, and the books balance")
	# the rules of the village's partnering: age bounds, gap and the unwilling
	var c: Dictionary = Life.cfg()
	var bad := 0
	for b in Migration._marriageable_in(s2, 1):
		var a := s2._age(s2.hh[b[0]].mem[b[1]])
		bad += 1 if a < float(c.partner_min_age) or a > float(c.partner_max_age) else 0
	check(bad == 0, "the settlement's candidates are all of marrying age")
	var unw := 0
	for b in Migration._marriageable_in(s2, 0) + Migration._marriageable_in(s2, 1):
		unw += int(s2.hh[b[0]].mem[b[1]][OffMapSettlement.M_UNWILLING])
	check(unw == 0, "and none is one who will not marry")


# ------------------------------------------------------------------ a person keeps what they are ----------------
func test_carried_across() -> void:
	var w := _world()
	var s: OffMapSettlement = w.regions.by_id["higham"]
	# a settlement-born adult of a smith household gets the village's starting skills for the trade, reproducibly
	var smith_hh := -1
	for i in s.hh.size():
		if str(s.hh[i].trade) == "smith":
			smith_hh = i
	var m: Array = s.hh[smith_hh].mem[0]
	var p1 := Migration._with_who(s, s._pack_of(m, 0), "smith")
	var p2 := Migration._with_who(s, s._pack_of(m, 0), "smith")
	check(str(p1.n) == str(p2.n) and p1.f == p2.f and p1.sk == p2.sk, "a member born in the settlement gets the same name and skills every time")
	check((p1.sk as Dictionary).has("smithing") and int(p1.sk.smithing) > 0, "a smith's household member has smithing (the village's starting rule for the trade: %s)" % str(p1.sk))
	check(Life.sex_of_name(str(p1.n)) == ("female" if int(p1.sex) == 1 else "male"), "and a name of their sex (%s)" % str(p1.n))
	var child := [s.day - 2 * Life.year_days(), 1, 0, 0]
	var p3 := Migration._with_who(s, s._pack_of(child, 0), "smith")
	check((p3.sk as Dictionary).is_empty(), "a child has no trade skills")


# ------------------------------------------------------------------ conservation and save ----------------
## Two moves (a hungry household out, a worker out); returns the books as they stood when the moves began.
func _make_moves(w: World) -> Dictionary:
	_feed_settlement(w.regions.by_id["wulstead"])
	var h := _plain(w)
	_starve(w, h)
	w.food_days = 0.5
	var began := _books(w)
	Migration._hunger_out(w, w.regions.by_id["wulstead"])
	var s: OffMapSettlement = w.regions.by_id["higham"]
	s.biz.farm.rate = 12.0
	var h2 := _plain(w, h)
	var who: NPC = null
	for o: NPC in w.brain._members(h2):
		if o.role == "adult" and Life._may_move(w, o):
			who = o
	who.job = ""
	w.treasury += who.coins - 21                         # (their purse is 21 coins; the difference to or from the treasury)
	who.coins = 21
	w.households[h2].econ = {"streak": 3}
	Migration._work_out(w, s, _closed_market())
	w.food_days = 30.0
	return began


func test_conservation_and_save() -> void:
	var w := _world()
	var before := _make_moves(w)
	check(w.regions.moves.size() == 2 and _same(before, _books(w)) and _sound(w), "two moves (a household and a worker) leave every book as it was")
	w.regions.suits["bourton|in"] = {"pair": "1:2:3", "since": 4}
	var text := JSON.stringify(w.to_dict(), "", true, true)
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(text))
	check(JSON.stringify(w2.regions.to_dict(), "", true, true) == JSON.stringify(w.regions.to_dict(), "", true, true), "saved and loaded, the settlements, the log, the counts and the courtships are exactly as they were")
	var away := 0
	var away2 := 0
	for n: NPC in w.npcs:
		away += 1 if n.away != "" else 0
	for n: NPC in w2.npcs:
		away2 += 1 if n.away != "" and not n.alive else 0
	check(away > 0 and away == away2, "the villagers who moved away are still away after loading (%d)" % away)
	check(_same(_books(w), _books(w2)) and w2.regions.move_counts == w.regions.move_counts and _sound(w2), "the books and the counts survive the save")
	var kept := false
	for h in w2.regions.by_id["wulstead"].hh:
		for mm in h.mem:
			kept = kept or (mm.size() > 4 and mm[4] is Dictionary and str(mm[4].n) != "")
	check(kept, "and the settlement's members keep the names they carried")
	# the loaded copy goes on exactly as the original
	for d in 3:
		w.regions.step_day(w.day() + 1 + d)
		w2.regions.step_day(w2.day() + 1 + d)
	check(JSON.stringify(w.regions.to_dict(), "", true, true) == JSON.stringify(w2.regions.to_dict(), "", true, true), "three days on, the loaded settlements and the original are identical")


func test_old_save() -> void:
	var w := _world()
	_make_moves(w)
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true))
	var r: Dictionary = d.regions
	for k in ["moves", "move_counts", "suits"]:
		r.erase(k)
	for sd in r.settlements:
		sd.erase("tax")
		sd.erase("journal")
		for h in sd.hh:
			for k in ["low", "rate", "landless"]:
				h.erase(k)
			h.mem = (h.mem as Array).map(func(m): return [m[0], m[1], m[2], m[3]])
		for t in sd.biz:
			sd.biz[t].erase("rate")
	for nd in d.npcs:
		nd.erase("away")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	check(w2.regions != null and w2.regions.list.size() == 5 and w2.regions.moves.is_empty(), "a save from before migration loads: no log, no courtships")
	var any := false
	for n: NPC in w2.npcs:
		any = any or n.away != ""
	check(not any, "and nobody is away")
	for s: OffMapSettlement in w2.regions.list:
		s.step_day(s.day + 1)
	check(w2.regions.audit() == "", "its settlements go on a day with their books balanced")
	check(Migration.visit(w2) >= 0, "and a visit day runs on it")


func test_determinism() -> void:
	var a := _world(3)
	var b := _world(3)
	for w in [a, b]:
		_make_moves(w)
		w.minutes += 13.0 * World.DAY
		w.regions.step_day(w.day())
		Migration.visit(w)
	check(JSON.stringify(a.regions.to_dict(), "", true, true) == JSON.stringify(b.regions.to_dict(), "", true, true), "the same world and the same day give the same moves, byte for byte")
	var ids_a := a.npcs.map(func(n): return "%d%s%s%s" % [n.id, n.name, n.alive, n.away])
	var ids_b := b.npcs.map(func(n): return "%d%s%s%s" % [n.id, n.name, n.alive, n.away])
	check(ids_a == ids_b, "and the same villagers, names and whereabouts")
