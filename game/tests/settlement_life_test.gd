extends SceneTree
## Expansion 18, REG-DEMO-01: the people of the five neighbouring settlements age, are born, die of old age, grow up, marry,
## found households and leave their goods to kin, by the village's own life rules (balance.json life, relations) at household level.
##   godot --headless --path game --script res://tests/settlement_life_test.gd

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
	test_founding()
	test_ageing_and_old_age()
	test_births()
	test_marriage_and_growing_up()
	test_inheritance()
	test_hunger_choice()
	test_save_and_old_save()
	test_determinism_and_books()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _s(index := 1, seed_ := 7) -> OffMapSettlement:
	return OffMapSettlement.create(OffMapSettlement.data().settlements[index], seed_, index)


func _members(s: OffMapSettlement) -> int:
	var n := 0
	for h in s.hh:
		if h.alive:
			n += h.mem.size()
	return n


func _years(s: OffMapSettlement, m: Array, day := 0) -> float:
	return float(day - int(m[0])) / float(Life.year_days())


func test_founding() -> void:
	var c: Dictionary = Life.cfg()
	var ok := true
	var ranges := true
	var couples := true
	var total := 0
	for i in OffMapSettlement.data().settlements.size():
		var s := _s(i)
		for h in s.hh:
			ok = ok and h.mem.size() == int(h.adults) + int(h.children)
			var pairs := 0
			for m in h.mem:
				total += 1
				var a := _years(s, m)
				if a < float(c.adolescent_until):
					ranges = ranges and a >= float(c.start_child_age[0]) - 0.07 and a <= float(c.start_child_age[1]) + 0.07
				else:
					ranges = ranges and a >= float(c.start_adult_age[0]) - 0.07 and a <= float(c.start_adult_age[1]) + 0.07
				pairs += int(m[2])
			couples = couples and pairs == (2 if int(h.adults) == 2 else 0)
	check(ok, "every founded household's members equal its adults and children")
	check(ranges, "founded ages lie in the village's start ranges (children %s, adults %s)" % [str(c.start_child_age), str(c.start_adult_age)])
	check(couples, "a household of two adults is a couple (one woman, one man)")
	var again := _s(2)
	check(JSON.stringify(again.to_dict(), "", true, true) == JSON.stringify(_s(2).to_dict(), "", true, true), "founding is deterministic (%d people in five settlements)" % total)
	# the ages use a stream of their own: the founding numbers are those of a settlement without ages
	check(_s(1, 7).population() == _s(1, 7).population() and _s(1, 7).coins() > 0 and _s(1, 7).audit() == "", "the founding books balance")


func test_ageing_and_old_age() -> void:
	var s := _s()
	var h: Dictionary = s.hh[0]
	h.mem = [[0 - 30 * 8, 1, 0, 1], [-int(15.9 * 8.0), 0, 0, 1]]
	h.adults = 1
	h.children = 1
	s.step_day(0)
	check(int(h.adults) == 1 and int(h.children) == 1, "a boy of 15.9 years is still a child")
	for d in range(1, 4):
		s.step_day(d)
	check(int(h.adults) == 2 and int(h.children) == 0, "and an adult by his 16th birthday (the village's adolescent_until)")
	var yd := Life.year_days()
	check(yd == 8, "one calendar year is %d game days (OD-21)" % yd)
	# old age: certain death at mortality_certain_at, none before mortality_from
	h.mem = [[s.day - 79 * 8 - 1, 1, 0, 1], [s.day - 50 * 8, 0, 0, 1], [s.day - 80 * 8 - 1, 0, 0, 1]]
	h.adults = 3
	h.children = 0
	var before: int = int(s.flows.age_deaths)
	s.step_day(s.day + 1)
	check(int(s.flows.age_deaths) - before >= 1 and h.mem.any(func(m): return _years(s, m, s.day) >= 80.0) == false, "a villager past the certain age dies at once of old age")
	check(h.mem.any(func(m): return _years(s, m, s.day) < 55.0), "a man of 50 does not")
	check(int(s.flows.deaths) == 0, "old-age deaths are not counted as hunger deaths")
	# the daily hazard follows Life.death_chance: at 70 about mortality_yearly_max * (10/20)^2 / 8 a day
	var deaths := 0
	var t := _s(3)
	var th: Dictionary = t.hh[0]
	for k in 4000:
		th.mem = [[t.day - 70 * 8, 1, 0, 1], [t.day - 40 * 8, 0, 0, 1]]
		th.adults = 2
		t.day = k
		th.mem[0][0] = k - 70 * 8
		th.mem[1][0] = k - 40 * 8
		t._old_age(1)
		if th.mem.size() < 2:
			deaths += 1
	var expect := Life.death_chance(70.0) * 4000.0
	check(absf(float(deaths) - expect) < expect * 0.3, "a 70-year-old dies at the village's daily chance (%d of 4000 days, expected about %.0f)" % [deaths, expect])


func test_births() -> void:
	var s := _s()
	var h: Dictionary = s.hh[0]
	s.day = 40
	s._yd = 8
	var salt := 1
	h.pantry = {"wheat": 200}
	h.mem = [[s.day - 25 * 8, 1, 1, 1], [s.day - 28 * 8, 0, 1, 1]]
	h.alive = true
	s._recount(h)
	s._try_birth(h, 2.0, salt)
	check(h.mem.size() == 3 and int(s.flows.births) == 1 and int(h.children) == 1, "a couple with a mother of 25 and food has a child")
	check(int(h.mem[2][0]) == s.day and int(h.mem[2][2]) == 0, "the baby is born today and unpartnered")
	s._try_birth(h, 2.0, salt)
	check(h.mem.size() == 3, "no second child within birth_min_gap_years (%s)" % str(Life.cfg().birth_min_gap_years))
	var cases := {"a mother of 45": [[s.day - 45 * 8, 1, 1, 1], [s.day - 45 * 8, 0, 1, 1]], "a mother of 17": [[s.day - 17 * 8, 1, 1, 1], [s.day - 20 * 8, 0, 1, 1]],
		"a woman with no partner": [[s.day - 25 * 8, 1, 0, 1], [s.day - 28 * 8, 0, 0, 1]], "two men": [[s.day - 25 * 8, 0, 1, 1], [s.day - 28 * 8, 0, 1, 1]]}
	for k in cases:
		h.mem = cases[k].duplicate(true)
		s._recount(h)
		s._try_birth(h, 2.0, salt)
		check(h.mem.size() == 2, "%s has no child" % k)
	h.mem = [[s.day - 25 * 8, 1, 1, 1], [s.day - 28 * 8, 0, 1, 1]]
	h.pantry = {}
	h.credit = 0.0
	s._try_birth(h, 2.0, salt)
	check(h.mem.size() == 2, "a couple with no food has no child (birth_min_food_days)")
	h.pantry = {"wheat": 200}
	var born := 0
	for k in 3200:                                           # 400 years: about one birth in two years apart from the gap
		s.day = 100 + k
		h.mem = [[s.day - 25 * 8, 1, 1, 1], [s.day - 28 * 8, 0, 1, 1]]
		s._try_birth(h, 1.0 / 16.0, 3)
		born += h.mem.size() - 2
	check(born > 3200 / 16 * 0.6 and born < 3200 / 16 * 1.4, "births come at one in birth_interval_years (%d in 3200 days, about %d)" % [born, 200])


func _two_singles(s: OffMapSettlement) -> Array:
	var a: Dictionary = s.hh[0]
	var b: Dictionary = s.hh[1]
	for h in [a, b]:
		h.alive = true
		h.coins = 40
		h.pantry = {"wheat": 12}
		h.mem = []
	return [a, b]


func test_marriage_and_growing_up() -> void:
	var s := _s(0)
	var p := _two_singles(s)
	s.day = 400
	s._yd = 8
	p[0].mem = [[s.day - 20 * 8, 1, 0, 0]]
	p[1].mem = [[s.day - 23 * 8, 0, 0, 0]]
	for h in p:
		s._recount(h)
	s.reopen_books()
	var n_hh := s.hh.size()
	s._found_household(1)
	check(s.hh.size() == n_hh + 1 and int(s.flows.households_formed) == 1, "a woman of 20 and a man of 23 from different households found a household")
	var nh: Dictionary = s.hh[n_hh]
	check(nh.alive and nh.adults == 2 and nh.mem.size() == 2 and int(nh.mem[0][2]) == 1 and int(nh.mem[1][2]) == 1, "of two adults, recorded as a couple")
	check(nh.parents == [p[0].id, p[1].id] and p[0].kids.has(nh.id) and p[1].kids.has(nh.id), "with the households they came from recorded as kin")
	check(s.biz.values().any(func(b): return b.workers.has(nh.id)), "the new household is a worker of a business (a grown child becomes a worker)")
	check(int(nh.coins) == 80 and int(nh.pantry.wheat) == 24 and not p[0].alive and not p[1].alive, "a last member takes all the coins and food of a household: nothing is lost")
	check(s.audit() == "", "and the books balance")
	# not related, not under age, not unwilling, not waiting
	for case in [["siblings' children are kin", 0, 0, true], ["under 18", 17, 20, false], ["unwilling", 20, 23, false], ["gap over 12 years", 20, 40, false]]:
		var q := _s(0)
		var pp := _two_singles(q)
		q.day = 400
		q._yd = 8
		var wa := int(case[1]) if int(case[1]) > 0 else 20
		var ma := int(case[2]) if int(case[2]) > 0 else 23
		pp[0].mem = [[q.day - wa * 8, 1, 0, 1 if case[0] == "unwilling" else 0]]
		pp[1].mem = [[q.day - ma * 8, 0, 0, 0]]
		if case[3]:
			pp[0].parents = [5]
			pp[1].parents = [5]
		else:
			pp[0].parents = []
		for h in pp:
			q._recount(h)
		var n0: int = q.hh.size()
		q._found_household(1)
		check(q.hh.size() == n0, "%s: no marriage" % case[0])
	var w := _s(0)
	var pw := _two_singles(w)
	w.day = 400
	w._yd = 8
	pw[0].mem = [[w.day - int(18.0 * 8) - 5, 1, 0, 0]]            # 5 days past 18: marry_min_days (12) not yet served
	pw[1].mem = [[w.day - 23 * 8, 0, 0, 0]]
	var n1: int = w.hh.size()
	w._found_household(1)
	check(w.hh.size() == n1, "a person must have been of age for marry_min_days (%s)" % str(GameData.b("relations").marry_min_days))
	# a household with a child keeps its only adult; a household keeps its other members when one leaves
	var x := _s(0)
	var px := _two_singles(x)
	x.day = 400
	x._yd = 8
	px[0].mem = [[x.day - 25 * 8, 1, 0, 0], [x.day - 3 * 8, 0, 0, 0]]
	px[1].mem = [[x.day - 25 * 8, 0, 0, 0]]
	for h in px:
		x._recount(h)
	var nx: int = x.hh.size()
	x._found_household(1)
	check(x.hh.size() == nx, "the only adult of a household with a child does not leave it")
	# an official's household is not left empty
	var o := _s(0)
	var po := _two_singles(o)
	o.day = 400
	o._yd = 8
	po[0].trade = "official"
	po[0].mem = [[o.day - 25 * 8, 1, 0, 0]]
	po[1].mem = [[o.day - 25 * 8, 0, 0, 0]]
	for h in po:
		o._recount(h)
	var no: int = o.hh.size()
	o._found_household(1)
	check(o.hh.size() == no, "a one-person official's household does not leave its post")
	# children grow up and the settlement's households and workers grow: forty years on, on the real settlement
	var g := _s(0)
	var kids0 := 0
	for h in g.hh:
		kids0 += int(h.children)
	var hh0 := g.households()
	var all_adults := 0
	for d in 40 * 8:
		g.step_day(d)
	for h in g.hh:
		if h.alive:
			all_adults += int(h.adults)
	check(int(g.flows.households_formed) > 0 and g.households() != hh0, "over forty years grown children marry and found households (%d founded)" % int(g.flows.households_formed))
	check(int(g.flows.births) > 0 and g.audit() == "", "children are born, and the books balance after forty years (%d births, %d old-age deaths, %d hunger deaths)" % [int(g.flows.births), int(g.flows.age_deaths), int(g.flows.deaths)])
	var consistent := true
	for h in g.hh:
		consistent = consistent and h.mem.size() == int(h.adults) + int(h.children) and (h.alive or h.mem.is_empty())
	check(consistent, "every household's adults and children equal its members")


func test_inheritance() -> void:
	var s := _s(0)
	var h: Dictionary = s.hh[0]
	var e: Dictionary = s.hh[1]
	var f: Dictionary = s.hh[2]
	s.day = 0
	s._yd = 8
	for x in [h, e, f]:
		x.alive = true
		x.parents = []
		x.kids = []
		x.mem = [[s.day - 30 * 8, 1, 0, 1]]
	h.kids = [e.id]
	e.parents = [h.id]
	h.mem = [[s.day - 81 * 8, 0, 0, 1]]
	h.coins = 100
	h.pantry = {"wheat": 9}
	for x in [h, e, f]:
		s._recount(x)
	s.reopen_books()
	var e_coins := int(e.coins)
	s._old_age(1)
	check(not h.alive and int(h.coins) == 0 and int(e.coins) == e_coins + 100 and int(e.pantry.get("wheat", 0)) >= 9, "a household whose last member dies passes its coins and food to the kin household its child founded")
	check(int(s.flows.inheritances) == 1 and int(f.coins) == int(f.coins), "recorded as an inheritance")
	check(s.audit() == "", "and the books balance (no coin created or lost)")
	# no kin: the treasury, as before
	var t := _s(0)
	var th: Dictionary = t.hh[0]
	t.day = 0
	t._yd = 8
	th.mem = [[t.day - 81 * 8, 0, 0, 1]]
	th.parents = []
	th.kids = []
	th.coins = 50
	th.pantry = {"wheat": 4}
	t._recount(th)
	t.reopen_books()
	var tr: int = int(t.gov.coins)
	t._old_age(1)
	check(not th.alive and int(t.gov.coins) == tr + 50 and int(t.gov.granary.get("wheat", 0)) >= 4 and t.audit() == "", "with no kin the coins and food pass to the treasury")
	# orphans: taken in by kin, with the property
	var o := _s(0)
	var oh: Dictionary = o.hh[0]
	var ok: Dictionary = o.hh[1]
	o.day = 0
	o._yd = 8
	oh.mem = [[o.day - 81 * 8, 1, 0, 1], [o.day - 4 * 8, 0, 0, 1], [o.day - 9 * 8, 1, 0, 1]]
	oh.parents = [ok.id]
	oh.kids = []
	oh.coins = 30
	ok.alive = true
	ok.kids = [oh.id]
	ok.mem = [[o.day - 55 * 8, 0, 0, 1]]
	for x in [oh, ok]:
		o._recount(x)
	o.reopen_books()
	var okc := int(ok.coins)
	o._old_age(1)
	check(not oh.alive and ok.mem.size() == 3 and int(o.flows.orphans_fostered) == 2 and int(ok.coins) == okc + 30, "orphaned children go to their kin with the property")
	check(o.audit() == "", "and the books balance")
	# orphans with no kin go to the smallest living household
	var q := _s(0)
	var qh: Dictionary = q.hh[0]
	q.day = 0
	q._yd = 8
	qh.mem = [[q.day - 81 * 8, 1, 0, 1], [q.day - 4 * 8, 0, 0, 1]]
	qh.parents = []
	qh.kids = []
	q._recount(qh)
	q.reopen_books()
	var people := _members(q)
	q._old_age(1)
	check(not qh.alive and _members(q) == people - 1 and q.audit() == "", "orphans with no kin are taken in by another household (the village's Guardianship)")


func test_hunger_choice() -> void:
	var s := _s()
	var h: Dictionary = s.hh[0]
	s.day = 100
	s._yd = 8
	h.mem = [[s.day - 30 * 8, 1, 0, 1], [s.day - 2 * 8, 0, 0, 1], [s.day - 6 * 8, 1, 0, 1]]
	s._recount(h)
	s._lose_member(h)
	check(h.mem.size() == 2 and h.mem.all(func(m): return int(m[0]) != s.day - 2 * 8), "hunger takes the youngest child first")
	s._lose_member(h)
	s._lose_member(h)
	check(h.mem.is_empty() and not h.alive and int(s.flows.deaths) == 3, "and then the adult; an empty household is closed")


func test_save_and_old_save() -> void:
	var s := _s(3)
	for d in 90:
		s.step_day(d)
	var text := JSON.stringify(s.to_dict(), "", true, true)
	var counts: Array = s.hh.map(func(h): return [h.adults, h.children])
	var pop_before := s.population()
	var l := OffMapSettlement.from_dict(JSON.parse_string(text))
	check(JSON.stringify(l.to_dict(), "", true, true) == text, "ages, couples and kin survive a save and load unchanged")
	for d in range(90, 120):
		s.step_day(d)
		l.step_day(d)
	check(JSON.stringify(l.to_dict(), "", true, true) == JSON.stringify(s.to_dict(), "", true, true), "and the loaded copy goes on exactly as the original")
	# a save from before the people had ages
	var old: Dictionary = JSON.parse_string(text)
	for h in old.hh:
		h.erase("mem")
		h.erase("parents")
		h.erase("kids")
	for k in ["births", "age_deaths", "households_formed", "inheritances", "orphans_fostered"]:
		old.flows.erase(k)
	var a := OffMapSettlement.from_dict(old.duplicate(true))
	var b := OffMapSettlement.from_dict(old.duplicate(true))
	var counts_ok := true
	for i in a.hh.size():
		counts_ok = counts_ok and a.hh[i].mem.size() == int(a.hh[i].adults) + int(a.hh[i].children) and a.hh[i].adults == counts[i][0] and a.hh[i].children == counts[i][1]
	check(counts_ok and a.population() == pop_before, "an older save without ages loads with ages that match each household's adults and children")
	check(JSON.stringify(a.to_dict(), "", true, true) == JSON.stringify(b.to_dict(), "", true, true), "the ages given on loading are the same each time")
	for d in range(90, 130):
		a.step_day(d)
	check(a.audit() == "", "and an older save goes on with balanced books")


func test_determinism_and_books() -> void:
	var a := Regions.create(11)
	var b := Regions.create(11)
	var bad := ""
	for d in 120:
		a.step_day(d)
		b.step_day(d)
		if d % 10 == 9 and bad == "":
			bad = a.audit()
	check(JSON.stringify(a.to_dict(), "", true, true) == JSON.stringify(b.to_dict(), "", true, true), "two settlement sets from one seed are identical after 120 days (15 years)")
	check(bad == "", "every sample of the books balances (%s)" % bad)
	var born := 0
	var aged := 0
	for s in a.list:
		born += int(s.flows.births)
		aged += int(s.flows.age_deaths)
	check(born > 0, "people are born in 15 years (%d births, %d old-age deaths)" % [born, aged])


