extends SceneTree
## B8-029: the calendar, ages, life stages, partners, births, old-age death, the family heir, and the
## animals' life stages. Pure World (no scene); time is stepped by dawns, not frames. Run headless:
##   godot --headless --path game --script res://tests/aging_test.gd

var failures := 0
var checks := 0


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
	test_calendar()
	test_start_population()
	test_coming_of_age_and_retiring()
	test_old_age_and_inheritance()
	test_partners_and_births()
	test_player()
	test_save_load()
	test_animals()
	test_baby_art()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func at_dawn(w: World, days := 1) -> void:
	for i in days:
		w.minutes = float(w.day() + 1) * 1440.0 + 6.0 * 60.0
		w.last_hour = int(w.minutes / 60.0)
		w._new_day()


func living(w: World, h: int) -> int:
	var c := 0
	for m in w.households[h].members:
		if w.npc(int(m)).alive:
			c += 1
	return c


# ---------------------------------------------------------------- calendar -------------------
func test_calendar() -> void:
	var cal: Dictionary = GameData.b("calendar")
	var Y := float(cal.year_days) * 1440.0
	check(int(cal.year_days) == 8 and cal.seasons == ["Spring", "Summer", "Autumn", "Winter"], "the year is 8 days in four seasons (balance.json)")
	check(Life.season(0.0) == "Spring" and Life.season(1.9 * 1440.0) == "Spring" and Life.season(2.0 * 1440.0) == "Summer", "spring is days 1-2, summer follows")
	check(Life.season(4.0 * 1440.0) == "Autumn" and Life.season(7.9 * 1440.0) == "Winter" and Life.season(8.0 * 1440.0) == "Spring", "autumn, winter, then spring again")
	check(Life.year(0.0) == 1 and Life.year(Y - 1.0) == 1 and Life.year(Y) == 2 and Life.year(5.0 * Y) == 6, "the year counts from 1")
	check(absf(Life.age_years(-10.0 * Y, 0.0) - 10.0) < 1e-6 and absf(Life.age_years(0.0, 2.5 * Y) - 2.5) < 1e-6, "age in years is (now - born) / year")
	var w := new_world()
	check(w.clock_text() == "Spring, Year 1  Day 1  07:00", "the HUD clock reads '%s'" % w.clock_text())
	w.minutes = 2.0 * 1440.0 + 13.0 * 60.0 + 5.0
	check(w.clock_text() == "Summer, Year 1  Day 3  13:05" and w.season() == "Summer" and w.year() == 1, "season, year and day of the year in the clock")
	check(w.clock_text().length() <= 30, "the clock text is short for the phone HUD (%d characters)" % w.clock_text().length())
	check(Life.stage_of(11.9) == "child" and Life.stage_of(12.0) == "adolescent" and Life.stage_of(15.9) == "adolescent" \
			and Life.stage_of(16.0) == "adult" and Life.stage_of(54.9) == "adult" and Life.stage_of(55.0) == "elder", "stages: child 0-12, adolescent 12-16, adult 16-55, elder 55+")
	check(Life.death_chance(59.9) == 0.0 and Life.death_chance(70.0) > 0.0 and Life.death_chance(70.0) < Life.death_chance(79.0) and Life.death_chance(80.0) == 1.0, "the chance of old-age death rises from 60 to certain at 80")


# ---------------------------------------------------------------- the starting people ---------
func test_start_population() -> void:
	var w := new_world()
	var ok := true
	var bad := ""
	var partnered := 0
	var parents_ok := true
	for n: NPC in w.npcs:
		var age := Life.npc_age(w, n)
		match n.role:
			"child":
				ok = ok and age >= 1.0 and age < 16.0
			"adult":
				ok = ok and age >= 17.0 and age <= 55.0
			"elder":
				ok = ok and age >= 56.0 and age <= 75.0
		if not ok and bad == "":
			bad = "%s %s %.1f" % [n.name, n.role, age]
		if n.role != "bandit":
			ok = ok and Life.role_for(w, n) == n.role
		if n.partner >= 0:
			partnered += 1
			var p := w.npc(n.partner)
			ok = ok and p != null and p.partner == n.id and p.sex != n.sex
		for pid in [n.mother, n.father]:
			if pid >= 0:
				var par := w.npc(pid)
				parents_ok = parents_ok and par != null and par.children.has(n.id) and Life.npc_age(w, par) - age >= 16.0 and Life.npc_age(w, par) - age <= 50.0
	check(ok, "every starting age matches the role (%s)" % bad)
	check(partnered >= 10 and partnered % 2 == 0, "the households' couples are recorded as explicit partners (%d people)" % partnered)
	check(parents_ok, "recorded parents are 16+ years older than their children, and list them as children")
	var kids_with_parents := w.npcs.filter(func(n: NPC) -> bool: return n.role == "child" and (n.mother >= 0 or n.father >= 0)).size()
	check(kids_with_parents >= 15, "most children have recorded parents (%d)" % kids_with_parents)
	# sharing a house is not a romance: opposite-sex adults in one household stay unlinked unless recorded
	var unlinked_mixed := 0
	for hh in w.households:
		var m := 0
		var f := 0
		for id in hh.members:
			var n := w.npc(int(id))
			if n.role == "adult" and n.partner < 0:
				if n.sex == "male":
					m += 1
				else:
					f += 1
		if m > 0 and f > 0:
			unlinked_mixed += 1
	var before := w.npcs.filter(func(n: NPC) -> bool: return n.partner >= 0).size()
	GameData.b("life").partner_chance_per_year = 0.0
	for i in 20:
		Life.partnering(w)
	GameData.b("life").partner_chance_per_year = 0.5
	check(w.npcs.filter(func(n: NPC) -> bool: return n.partner >= 0).size() == before, "adults sharing a house are not made partners by living together (%d such households)" % unlinked_mixed)
	var w2 := new_world()
	var same := w.npcs.size() == w2.npcs.size()
	for i in w.npcs.size():
		var a: NPC = w.npcs[i]
		var b: NPC = w2.npcs[i]
		same = same and a.born == b.born and a.sex == b.sex and a.partner == b.partner and a.mother == b.mother and a.father == b.father
	check(same, "ages and families are deterministic from the seed")
	check(absf(Life.age_years(w.player.born, w.minutes) - 19.0) < 1.01 and Life.age_years(w.player.born, w.minutes) >= 18.0, "the player starts at 18-20 (%.1f)" % Life.age_years(w.player.born, w.minutes))


# ---------------------------------------------------------------- stages and jobs ------------
func _all_adults_work(w: World) -> void:
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and NPCBrain.APPRENTICE_FROM.has(o.job):
			o.job = "farmer"
			o.workplace = w.fields[0].id


func test_coming_of_age_and_retiring() -> void:
	var w := new_world()
	var Y := Life.year_minutes()
	_all_adults_work(w)
	var kid: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.role == "child" and n.household >= 3)[0]
	kid.born = w.minutes - 15.9 * Y
	Life.sync_roles(w)
	check(kid.role == "child" and Life.stage(kid, w.minutes) == "adolescent", "a 15.9-year-old is an adolescent, still role child")
	check(w.brain._apprentice_for({"job": "smith", "household": kid.household}) == null, "an adolescent is nobody's apprentice (adults only)")
	check(is_equal_approx(Life.npc_scale(kid, w.minutes), 0.75) and is_equal_approx(Life.npc_scale(w.npcs.filter(func(n: NPC) -> bool: return n.role == "adult")[0], w.minutes), 1.0), "adolescents are drawn at 0.75, adults at 1")
	var little: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.role == "child" and Life.npc_age(w, n) < 11.0)[0]
	check(is_equal_approx(Life.npc_scale(little, w.minutes), 0.5), "children are drawn at half size")
	w.minutes += 0.2 * Y
	at_dawn(w)
	check(kid.alive and kid.role == "adult" and kid.job == "", "crossing 16 at dawn makes the child an adult without a trade")
	check(w.brain._apprentice_for({"job": "smith", "household": kid.household}) == kid, "and it is in the pool for a trade (succession)")
	# an adult who reaches 55 retires; the reeve and the sage serve for life
	var farmer: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.role == "adult" and n.job == "farmer")[0]
	farmer.born = w.minutes - 54.9 * Y
	var sage: NPC = w.npc(w.sage_id)
	sage.born = w.minutes - 54.9 * Y
	w.minutes += 0.3 * Y
	Life.sync_roles(w)
	check(farmer.role == "elder" and farmer.job == "", "an adult turning 55 becomes an elder and retires from the trade")
	check(sage.role == "adult" and sage.job == "sage", "the sage keeps the post past 55")
	check(Life.walk_factor(farmer) < 1.0 and is_equal_approx(Life.walk_factor(farmer), float(GameData.b("life").elder_speed)), "elders walk at 0.8x")
	var bandit: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.role == "bandit")[0]
	bandit.born = w.minutes - 70.0 * Y
	Life.sync_roles(w)
	check(bandit.role == "bandit", "bandits age but keep their role")


# ---------------------------------------------------------------- old age --------------------
func _adult_with_partner(w: World, not_in: Array = []) -> NPC:
	for n: NPC in w.npcs:
		if n.role == "adult" and n.partner >= 0 and Life.has_partner(w, n) and n.household >= 3 and not not_in.has(n.id):
			var kids := n.children.filter(func(c): return w.npc(int(c)).role != "child")
			if kids.is_empty():
				return n
	return null


func test_old_age_and_inheritance() -> void:
	var w := new_world()
	var Y := Life.year_minutes()
	# 1. an 80-year-old dies at dawn of old age; the partner inherits (no adult child)
	var a := _adult_with_partner(w)
	var mate := w.npc(a.partner)
	a.born = w.minutes - 80.5 * Y
	a.coins = 50
	mate.born = w.minutes - 30.0 * Y
	var mate_coins := mate.coins
	Life._natural_deaths(w)
	check(not a.alive, "an 80-year-old dies of old age at dawn")
	check(w.log_lines.any(func(l: String) -> bool: return l.contains(a.name) and l.contains("(old age)")), "the cause is old age")
	check(mate.coins == mate_coins + 50, "with no adult child the partner inherits")
	# 2. children before the partner: the eldest adult child
	var b := _adult_with_partner(w, [a.id, mate.id])
	var kid1: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.partner < 0 and n.household != b.household and n.mother < 0 and n.father < 0 and n.id != a.id)[0]
	var kid2: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.partner < 0 and n.household != b.household and n.mother < 0 and n.father < 0 and n.id != kid1.id and n.id != a.id)[0]
	kid1.born = w.minutes - 22.0 * Y
	kid2.born = w.minutes - 28.0 * Y                       # the elder of the two
	Life._link_child(kid1, b if b.sex == "female" else null, b if b.sex == "male" else null)
	Life._link_child(kid2, b if b.sex == "female" else null, b if b.sex == "male" else null)
	var partner_b := w.npc(b.partner)
	partner_b.born = w.minutes - 40.0 * Y
	b.born = w.minutes - 81.0 * Y
	b.coins = 90
	var c1 := kid1.coins
	var c2 := kid2.coins
	var cp := partner_b.coins
	Life._natural_deaths(w)
	check(not b.alive and kid2.coins == c2 + 90 and kid1.coins == c1 and partner_b.coins == cp, "the eldest adult child inherits before the partner and the other child")
	# 3. a skilled trade left by an old smith opens a post (the existing succession flow)
	var smith: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.job == "smith")[0]
	var posts := w.vacancies.size()
	smith.born = w.minutes - 85.0 * Y
	Life._natural_deaths(w)
	check(not smith.alive and w.vacancies.size() == posts + 1 and w.vacancies[-1].job == "smith", "a smith's old-age death opens his post: succession runs")
	# 4. nobody under 60 dies of age
	var w2 := new_world()
	var young := w2.npcs.filter(func(n: NPC) -> bool: return n.role != "bandit" and Life.npc_age(w2, n) < 59.0).size()
	for i in 10:
		Life._natural_deaths(w2)
	check(w2.npcs.filter(func(n: NPC) -> bool: return n.alive and Life.npc_age(w2, n) < 59.0 and n.role != "bandit").size() == young, "nobody dies of age before 60")
	# 5. a full dawn: the elders of the village thin out over the years, not all at once
	var w3 := new_world()
	var elders0 := w3.alive_count("elder")
	at_dawn(w3, 8)
	check(w3.alive_count("elder") >= elders0 - 8 and w3.alive_count("elder") <= elders0, "a year of dawns takes some elders, not all (%d to %d)" % [elders0, w3.alive_count("elder")])


# ---------------------------------------------------------------- partners and births --------
func test_partners_and_births() -> void:
	var w := new_world()
	var Y := Life.year_minutes()
	# a couple in a house with one bed free
	var mother: NPC = null
	var h := -1
	for n: NPC in w.npcs:
		if n.sex == "female" and n.role == "adult" and Life.has_partner(w, n) and n.household >= 3 and Life.has_room(w, n.household):
			mother = n
			h = n.household
			break
	check(mother != null, "a couple lives in a house with a free bed")
	var father := w.npc(mother.partner)
	mother.born = w.minutes - 30.0 * Y
	father.born = w.minutes - 33.0 * Y
	for cid in mother.children:
		w.npc(int(cid)).born = w.minutes - 6.0 * Y
	w.households[h].pantry.add("wheat", 100)
	var first_new := w.brain._next_npc_id()
	var born_to_her := 0
	var beds: int = w.construction.beds_in(str(w.households[h].home))
	var over := false
	var nobirth_without_partner := true
	for day in 48:                                           # six years
		w.minutes += 1440.0
		Life.births(w)
		over = over or living(w, h) > beds
		born_to_her = mother.children.size()
	check(born_to_her >= 1 and born_to_her <= 1 + 4, "the couple has a child over six years (%d children recorded)" % mother.children.size())
	check(not over and living(w, h) == beds, "births stop at the house's capacity (%d beds, %d living)" % [beds, living(w, h)])
	var baby: NPC = null
	for id in mother.children:
		if int(id) >= first_new:
			baby = w.npc(int(id))
	check(baby != null and baby.role == "child" and baby.household == h and baby.home == str(w.households[h].home) and baby.mother == mother.id and baby.father == father.id, "the newborn is a child of the household, recording both parents")
	check(baby != null and baby.name != "" and baby.sprite != "" and baby.family == w.households[h].family and w.by_id.has(baby.id) and father.children.has(baby.id), "with a name, a sprite, the family's name, a place among the people and the father's child list")
	check(baby != null and Life.npc_age(w, baby) >= 0.0 and Life.npc_age(w, baby) < 6.0 and baby.born > 0.0, "born at the time it was born")
	var strangers := true
	for n: NPC in w.npcs:
		if n.id >= first_new:
			var m := w.npc(n.mother)
			var f := w.npc(n.father)
			strangers = strangers and m != null and f != null and m.partner == f.id and f.partner == m.id
	check(strangers, "every child born had partners for parents")
	# the pace: about one birth per pair per two years
	var w2 := new_world()
	var pairs := 0
	for n: NPC in w2.npcs:
		if n.sex == "female" and n.role == "adult" and Life.has_partner(w2, n):
			pairs += 1
			n.born = w2.minutes - 25.0 * Y
			w2.npc(n.partner).born = w2.minutes - 28.0 * Y
			for cid in n.children:
				w2.npc(int(cid)).born = w2.minutes - 6.0 * Y
	for hh in w2.households:
		hh.pantry.add("wheat", 200)
	var rooms := 0
	for hh in w2.households:
		rooms += maxi(0, w2.construction.beds_in(str(hh.home)) - living(w2, int(hh.id)))
	var n0 := w2.npcs.size()
	for day in 16:
		w2.minutes += 1440.0
		Life.births(w2)
	var born := w2.npcs.size() - n0
	check(born >= 1 and born <= pairs and born <= rooms, "two years bring births to some of the %d couples, never past the free beds (%d born, %d beds free)" % [pairs, born, rooms])
	# partnering: a single man and woman of 18+, a room for one of them
	var w3 := new_world()
	GameData.b("life").partner_chance_per_year = 8.0                     # a certain chance each day
	var before_pairs := w3.npcs.filter(func(n: NPC) -> bool: return n.partner >= 0).size()
	Life.partnering(w3)
	GameData.b("life").partner_chance_per_year = 0.5
	var after_pairs := w3.npcs.filter(func(n: NPC) -> bool: return n.partner >= 0).size()
	check(after_pairs > before_pairs and after_pairs % 2 == 0, "unpartnered adults pair up (%d new people partnered)" % (after_pairs - before_pairs))
	var sound := true
	for n: NPC in w3.npcs:
		if n.partner >= 0:
			var p := w3.npc(n.partner)
			sound = sound and p.partner == n.id and p.sex != n.sex and Life.npc_age(w3, n) >= 18.0 and not Life.kin(n.id, n.mother, n.father, p.id, p.mother, p.father)
	for hh in w3.households:
		sound = sound and living(w3, int(hh.id)) <= maxi(w3.construction.beds_in(str(hh.home)), 6) and (hh.members as Array).size() > 0
	check(sound, "new couples are symmetrical, of opposite sex, 18+, not kin, and nobody moved into a full house")
	# the player can have a partner too
	var p3 := w3.player
	var cand: NPC = w3.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.sex != p3.sex and n.partner < 0 and Life.npc_age(w3, n) >= 18.0)[0]
	check(Life.partner_player(w3, cand) == "" and p3.partner == cand.id and cand.partner == Life.PLAYER_ID and Life.has_partner(w3, cand), "the player can partner an unattached adult (explicit link both ways)")
	check(Life.partner_player(w3, cand) != "", "and not twice")


# ---------------------------------------------------------------- the player -----------------
func test_player() -> void:
	var w := new_world()
	var Y := Life.year_minutes()
	var p := w.player
	var old_name := p.name
	check(Life.age_years(p.born, w.minutes) >= 18.0, "the player has an age")
	# a child of 16+ who is the player's: the heir
	p.sex = "male"
	var cand: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.sex == "female" and n.partner < 0 and n.household >= 3 and Life.npc_age(w, n) >= 18.0)[0]
	check(Life.partner_player(w, cand) == "", "the player takes a partner")
	var h := cand.household
	var k1 := Life.birth(w, cand, p, h)
	var k2 := Life.birth(w, cand, p, h)
	check(k1.father == Life.PLAYER_ID and k1.mother == cand.id and p.children.has(k1.id) and cand.children.has(k1.id), "the player's child records the player as father")
	check(Life.player_heir_child(w) == null, "a baby is not yet an heir")
	k1.born = w.minutes - 17.0 * Y
	k2.born = w.minutes - 19.0 * Y
	var kid2_name := k2.name
	var kid2_sprite := k2.sprite
	p.born = w.minutes - 79.9 * Y
	var members_before := (w.households[h].members as Array).size()
	at_dawn(w)                                            # 80 years old at dawn: certain death
	check(not p.alive and p.death_cause == "old age" and p.deaths == 1, "the player dies of old age at 80")
	var ui_text := GameUI.death_text("old age")
	check(ui_text == "You died of old age.", "the death screen says so")
	w.continue_as_heir()
	var heir := w.player
	check(heir.alive and heir.name == kid2_name and heir.sprite == kid2_sprite and heir.generation == 2, "the eldest child of 16+ becomes the player (%s)" % heir.name)
	check(absf(Life.age_years(heir.born, w.minutes) - 19.0) < 0.2, "and keeps their age")
	check(w.npcs.all(func(n: NPC) -> bool: return n.id != k2.id) and not w.by_id.has(k2.id) and not (w.households[h].members as Array).has(k2.id) and (w.households[h].members as Array).size() <= members_before + 2, "the child leaves the villagers")
	check(w.npc(k1.id) != null and w.npc(k1.id).father == Life.FORMER_PLAYER, "the other child stays a villager, its father now the former player")
	check(heir.partner == -1 and heir.children.is_empty() and heir.father == Life.FORMER_PLAYER, "the heir starts with no partner or children of their own")
	check(old_name != "" and w.alive_count() > 0, "the world goes on")
	# without a child: the relative heir flow, as before
	var w2 := new_world()
	w2.player.alive = false
	w2.player.death_cause = "old age"
	w2.continue_as_heir()
	check(w2.player.alive and w2.player.generation == 2 and Life.age_years(w2.player.born, w2.minutes) >= 17.9, "with no grown child a relative takes over, a young adult (the existing heir flow)")


# ---------------------------------------------------------------- saving ---------------------
func test_save_load() -> void:
	var w := new_world()
	var Y := Life.year_minutes()
	var cand: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.sex == "female" and n.partner < 0 and n.household >= 3)[0]
	w.player.sex = "male"
	Life.partner_player(w, cand)
	var kid := Life.birth(w, cand, w.player, cand.household)
	at_dawn(w, 3)
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var same := w.npcs.size() == w2.npcs.size()
	for i in w.npcs.size():
		var a: NPC = w.npcs[i]
		var b: NPC = w2.npcs[i]
		same = same and a.born == b.born and a.sex == b.sex and a.role == b.role and a.partner == b.partner and a.mother == b.mother and a.father == b.father and a.children == b.children
	check(same, "born, sex, role, partner, parents and children survive a save")
	check(w2.player.born == w.player.born and w2.player.partner == cand.id and w2.player.children == [kid.id], "the player's age and family survive")
	var an := w.fauna.animals
	var an2 := w2.fauna.animals
	var fsame := an.size() == an2.size()
	for i in an.size():
		fsame = fsame and an[i].born == an2[i].born and an[i].sex == an2[i].sex and an[i].stage(w.minutes) == an2[i].stage(w2.minutes)
	check(fsame and an.size() > 0, "animals keep born, sex and so their stage")
	# an adolescent about to come of age: the role follows the age on load
	var teen: NPC = w2.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "child" and n.household >= 3)[0]
	teen.born = w2.minutes - 17.0 * Y
	var d2: Dictionary = JSON.parse_string(JSON.stringify(w2.to_dict()))
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), d2)
	check(w3.npc(teen.id).role == "adult", "a saved child who is now 17 loads as an adult")
	var d3: Dictionary = JSON.parse_string(JSON.stringify(w3.to_dict()))
	for k in ["born", "sex", "mother", "father", "partner", "children"]:
		for nd in d3.npcs:
			nd.erase(k)
	var w4 := World.new()
	w4.load_dict(VillageMap.load_default(), d3)
	check(w4.npcs.size() == w.npcs.size(), "an older save without the fields still loads")


# ---------------------------------------------------------------- animals --------------------
func test_animals() -> void:
	var w := new_world()
	var f := w.fauna
	var day := 1440.0
	var specs: Dictionary = GameData.b("animals")
	check(float(specs.rabbit.grow_days) < float(specs.cow.grow_days) and float(specs.rabbit.elder_days) < float(specs.cow.elder_days), "a rabbit matures and ages faster than a cow")
	for sp in ["rabbit", "chicken", "pig", "boar", "sheep", "cow"]:
		var s: Dictionary = specs[sp]
		f.animals.clear()
		var area: String = "woods_w" if s.kind == "wild" else str(f.pen_of(sp).id)
		var a := f.spawn(area, sp, "f", null)
		var now: float = w.minutes
		a.born = now
		var ok := a.stage(now) == "newborn"
		a.born = now - (float(s.juvenile_days) + 0.01) * day
		ok = ok and a.stage(now) == "juvenile" and not a.adult(now)
		a.born = now - (float(s.grow_days) + 0.01) * day
		ok = ok and a.stage(now) == "adult" and a.adult(now) and a.breeds(now)
		a.born = now - (float(s.elder_days) + 0.01) * day
		ok = ok and a.stage(now) == "elderly" and a.adult(now) and not a.breeds(now)
		check(ok, "%s: newborn -> juvenile -> adult -> elderly by age" % sp)
		a.born = w.minutes - float(s.elder_days) * day
		var died_at := -1.0
		for i in 400:
			w.minutes += day
			f._old_age(w.minutes)
			if not a.alive:
				died_at = a.age_days(w.minutes)
				break
		check(died_at >= float(s.death_days[0]) and died_at <= float(s.death_days[1]), "%s: dies of old age at %.1f days, within %s" % [sp, died_at, str(s.death_days)])
		check(f.by_id(a.id) == null, "%s: the dead animal leaves the pen or wood" % sp)
	# elderly do not breed
	f.animals.clear()
	var pen: Dictionary = f.pen_of("pig")
	var sow := f.spawn(pen.id, "pig", "f", null)
	var boar := f.spawn(pen.id, "pig", "m", null)
	sow.born = w.minutes - float(specs.pig.elder_days) * day - 1.0
	boar.born = w.minutes - float(specs.pig.grow_days) * day - 1.0
	sow.next_birth = 0.0
	f.new_day()
	check(f.count(pen.id, "pig") == 2, "an elderly sow does not breed")
	sow.born = w.minutes - float(specs.pig.grow_days) * day - 1.0
	var n0 := f.count(pen.id, "pig")
	f.new_day()
	check(f.count(pen.id, "pig") > n0, "the same sow in her prime breeds (existing rules kept)")
	# breeding slows near the cap
	check(f.breed_chance(pen.id, "pig") > 0.0 and f.breed_chance(pen.id, "pig") <= 1.0, "chance is a probability")
	f.animals.clear()
	var cap := f.cap(pen.id, "pig")
	for i in cap:
		f.spawn(pen.id, "pig", "m" if i % 2 == 0 else "f", null)
	check(is_equal_approx(f.breed_chance(pen.id, "pig"), 0.0), "no breeding at the cap")
	f.animals.clear()
	for i in cap / 4:
		f.spawn(pen.id, "pig", "m", null)
	var low := f.breed_chance(pen.id, "pig")
	for i in cap / 2:
		f.spawn(pen.id, "pig", "m", null)
	var high := f.breed_chance(pen.id, "pig")
	check(is_equal_approx(low, 1.0) and high < low and high > 0.0, "the chance falls as the pen fills (%.2f at a quarter, %.2f at three quarters)" % [low, high])
	# one year (8 days) with a breeding stock never passes the cap
	for sp in ["pig", "chicken"]:
		f.animals.clear()
		var pn: Dictionary = f.pen_of(sp)
		var cp := f.cap(pn.id, sp)
		for i in cp - 2:
			var an := f.spawn(pn.id, sp, "m" if i % 3 == 0 else "f", null)
			an.born = w.minutes - float(specs[sp].grow_days) * day - 1.0
			an.next_birth = 0.0
		var most := 0
		for d in 8:
			w.minutes += day
			for an: Animal in f.animals:
				an.hunger = 100.0
				an.hp = float(specs[sp].hp)
			f.new_day()
			most = maxi(most, f.count(pn.id, sp))
		check(most <= cp, "%s: the pen holds at most its cap over a year (%d of %d)" % [sp, most, cp])
	# the starting animals have mixed ages
	var w2 := new_world()
	var stages := {}
	for an: Animal in w2.fauna.animals:
		stages[an.stage(w2.minutes)] = int(stages.get(an.stage(w2.minutes), 0)) + 1
	check(stages.has("adult") and stages.has("juvenile") and stages.has("elderly"), "the starting animals are adults, a few juveniles and a few elderly %s" % str(stages))
	var ok2 := true
	for pid in w2.fauna.pens:
		var kind: String = w2.fauna.pens[pid].kind
		ok2 = ok2 and w2.fauna.animals.filter(func(a: Animal) -> bool: return a.area == pid and a.sex == "m" and a.breeds(w2.minutes)).size() >= 1 \
				and w2.fauna.animals.filter(func(a: Animal) -> bool: return a.area == pid and a.sex == "f" and a.breeds(w2.minutes)).size() >= 1
	check(ok2, "every pen still starts with a breeding pair")
	var w3 := new_world()
	var same := w3.fauna.animals.size() == w2.fauna.animals.size()
	for i in w2.fauna.animals.size():
		same = same and w2.fauna.animals[i].born == w3.fauna.animals[i].born
	check(same, "the starting animals' ages are deterministic")


func test_baby_art() -> void:
	var prov: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/PROVENANCE.json"))
	var text := JSON.stringify(prov)
	var all := true
	for skin in ["cow_baby", "cow_brown_baby", "pig_baby", "sheep_baby", "chicken_baby", "chicken_brown_baby", "rabbit_baby", "rabbit_grey_baby"]:
		all = all and FileAccess.file_exists("res://assets/animals/%s.png" % skin) and text.contains("animals/%s.png" % skin)
	check(all, "the Cozy Farm baby sheets are imported with provenance")
	var w := new_world()
	var a := w.fauna.spawn(w.fauna.pen_of("cow").id, "cow", "f", null)
	a.skin = "cow"
	check(a.baby_skin() == "cow_baby", "a calf draws the baby sheet")
	var b := w.fauna.spawn("woods_w", "boar", "f", null)
	check(b.baby_skin() == "", "the boar has no baby art (drawn at half scale)")
