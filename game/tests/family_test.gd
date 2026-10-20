extends SceneTree
## FAM-02..06 (owner directive 2026-10-20, docs/directives/2026-10-20_housing_succession_adoption.md, Parts 3-4
## and 6; owner answers OD-11 and OD-12): when both parents die, the children are taken in by a surviving
## parent elsewhere, then grandparents, then the nearest eligible blood relative, then another villager's
## household with room; equally close relatives are chosen by ability, capacity, food, relationship and
## proximity; genealogy and the birth surname survive the move; children never found households or build;
## the receiving household's occupancy and housing need are its own and no house is built for it. A child no
## household can take joins the bandit clan (FAM-07, OD-11): identity, age and genealogy kept, fed and safe at the camp,
## a bandit at coming of age. Run:
##   godot --headless --path game --script res://tests/family_test.gd

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
	test_grandparents_first()
	test_nearest_relative()
	test_equal_relatives_by_capacity()
	test_another_villager()
	test_genealogy_and_surname()
	test_orphans_do_not_build()
	test_occupancy_and_no_house()
	test_nobody_can_take()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func new_world(seed := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


## A household of two partners and at least one child; returns [household, mother, father, child].
func family(w: World) -> Array:
	for hh in w.households:
		var h := int(hh.id)
		var ms: Array = w.brain._members(h)
		var ad: Array = ms.filter(func(o: NPC) -> bool: return o.role == "adult")
		var kids: Array = ms.filter(func(o: NPC) -> bool: return o.role == "child")
		if h < 3 or ad.size() != 2 or ad[0].partner != ad[1].id or kids.is_empty():
			continue
		var mom: NPC = ad[0] if ad[0].sex == "female" else ad[1]
		var kid: NPC = kids[0]
		kid.mother = mom.id
		kid.father = mom.partner
		return [h, mom, w.npc(mom.partner), kid]
	return []


## Leave household `h` with only its children alive (the parents die, any elder too).
func orphan(w: World, h: int) -> void:
	for o: NPC in w.brain._members(h).duplicate():
		if o.alive and o.role != "child":
			w.kill(o, "fever")


## An adult or elder of another household with a home of its own, not `but` (and not one of `skip`).
func other_adult(w: World, but: int, skip: Array = []) -> NPC:
	for o: NPC in w.npcs:
		if o.alive and o.role in ["adult", "elder"] and o.household >= 3 and o.household != but and not skip.has(o.household) \
				and w.buildings.has(str(w.households[o.household].home)) and w.construction.responsible_adult(o.household) != null:
			return o
	return null


func test_grandparents_first() -> void:
	var w := new_world()
	var f := family(w)
	check(not f.is_empty(), "a family with a child")
	if f.is_empty():
		return
	var mom: NPC = f[1]
	var kid: NPC = f[3]
	var gran := other_adult(w, f[0])
	var stranger := other_adult(w, f[0], [gran.household])
	mom.mother = gran.id
	gran.children.append(mom.id)
	orphan(w, f[0])
	check(Guardianship.orphans(w, f[0]).has(kid), "with both parents dead, the children are orphans")
	var tier := Guardianship.place(w, kid)
	check(tier == "grandparent" and kid.household == gran.household, "the grandmother takes the child in (%s, household %d)" % [tier, kid.household])
	check(kid.home == str(w.households[gran.household].home) and w.households[gran.household].members.has(kid.id), "the child lives in her house as a member")
	check(stranger != null and kid.household != stranger.household, "not an unrelated household")


func test_nearest_relative() -> void:
	var w := new_world()
	var f := family(w)
	if f.is_empty():
		return
	var mom: NPC = f[1]
	var kid: NPC = f[3]
	# the grandmother is dead; an adult sibling (distance 2) and an aunt (distance 3) live elsewhere
	var gran := other_adult(w, f[0])
	var sib := other_adult(w, f[0], [gran.household])
	var aunt := other_adult(w, f[0], [gran.household, sib.household])
	mom.mother = gran.id
	gran.children.append_array([mom.id, aunt.id])
	aunt.mother = gran.id
	sib.mother = mom.id
	mom.children.append(sib.id)
	w.kill(gran, "fever")
	orphan(w, f[0])
	var d := Guardianship.kin_distances(w, kid)
	check(int(d.get(sib.id, -1)) == 2 and int(d.get(aunt.id, -1)) == 3, "the sibling is nearer (2) than the aunt (3) by the family tree")
	var tier := Guardianship.place(w, kid)
	check(tier == "relative" and kid.household == sib.household, "the nearest eligible relative, the adult sibling, takes the child in (%s)" % tier)


func test_equal_relatives_by_capacity() -> void:
	var w := new_world()
	var f := family(w)
	if f.is_empty():
		return
	var mom: NPC = f[1]
	var kid: NPC = f[3]
	var a := other_adult(w, f[0])
	var b := other_adult(w, f[0], [a.household])
	for s: NPC in [a, b]:                       # two adult siblings: equally close
		s.mother = mom.id
		mom.children.append(s.id)
	for o: NPC in w.brain._members(a.household) + w.brain._members(b.household):
		o.coins = 500                          # both able to provide care
	# b's household is made crowded (births to a woman of it): a has more room
	var bh := b.household
	var moms: Array = w.brain._members(bh).filter(func(o: NPC) -> bool: return o.alive and o.sex == "female" and o.role != "child")
	if moms.is_empty():
		check(false, "a woman in the second household to make it crowded")
		return
	while w.construction.beds_in(str(w.households[bh].home)) - w.construction.beds_needed(bh) >= 0:
		Life.birth(w, moms[0], null, bh)
	orphan(w, f[0])
	var c: Dictionary = Guardianship.candidates(w, kid)
	check((c.relative as Array).size() == 2, "two equally close relatives qualify (%s)" % [c.relative])
	Guardianship.place(w, kid)
	check(kid.household == a.household, "the one with room to spare takes the child (OD-12: ability, then capacity)")


func test_another_villager() -> void:
	var w := new_world()
	var f := family(w)
	if f.is_empty():
		return
	var kid: NPC = f[3]
	orphan(w, f[0])
	var tier := Guardianship.place(w, kid)
	check(tier == "villager" and kid.household != f[0], "with no kin, another villager's household takes the child in (%s)" % tier)
	check(Life.has_room(w, kid.household) or w.construction.beds_in(str(w.households[kid.household].home)) >= w.construction.beds_needed(kid.household), "a household that had room for the child")


func test_genealogy_and_surname() -> void:
	var w := new_world()
	var f := family(w)
	if f.is_empty():
		return
	var mom: NPC = f[1]
	var dad: NPC = f[2]
	var kid: NPC = f[3]
	var born_as := kid.family
	orphan(w, f[0])
	Guardianship.place(w, kid)
	check(kid.mother == mom.id and kid.father == dad.id and mom.children.has(kid.id), "the birth parents stay recorded both ways")
	if kid.family != born_as:
		check(kid.birth_family == born_as, "the new surname %s keeps the birth surname %s" % [kid.family, kid.birth_family])
	else:
		check(kid.birth_family == "", "the surname is unchanged and nothing else is recorded")
	var back := NPC.from_dict(JSON.parse_string(JSON.stringify(kid.to_dict())))
	check(back.birth_family == kid.birth_family and back.mother == mom.id and back.father == dad.id, "and survive saving and loading")


func test_orphans_do_not_build() -> void:
	var w := new_world()
	var f := family(w)
	if f.is_empty():
		return
	var kid: NPC = f[3]
	orphan(w, f[0])
	check(not w.construction._may_found(kid), "an orphaned child may not found a household")
	check(w.construction.responsible_adult(f[0]) == null or w.construction.responsible_adult(f[0]).role != "child", "no child becomes a household's responsible adult")
	w.construction.daily()
	check(str(w.households[f[0]].get("build", "")) == "", "the children's household starts no building")


func test_occupancy_and_no_house() -> void:
	var w := new_world()
	var f := family(w)
	if f.is_empty():
		return
	var kid: NPC = f[3]
	var mom: NPC = f[1]
	var gran := other_adult(w, f[0])
	mom.mother = gran.id
	gran.children.append(mom.id)
	var gh := gran.household
	var need_before := w.construction.beds_needed(gh)
	var sites := w.plots.filter(func(p): return not p.site.is_empty() and not p.site.get("done", false)).size()
	orphan(w, f[0])
	Guardianship.place(w, kid)
	check(w.construction.beds_needed(gh) >= need_before, "the receiving household's sleeping places needed count the child (%d to %d)" % [need_before, w.construction.beds_needed(gh)])
	check(w.plots.filter(func(p): return not p.site.is_empty() and not p.site.get("done", false)).size() == sites and str(w.households[gh].get("build", "")) == "", "no house is built because a child was taken in")
	check(w.construction.crowded(gh) == (w.construction.beds_in(str(w.households[gh].home)) < w.construction.beds_needed(gh)), "crowding is the receiving household's own, from its members")


func test_nobody_can_take() -> void:
	var w := new_world()
	var f := family(w)
	if f.is_empty():
		return
	var kid: NPC = f[3]
	var mom: NPC = f[1]
	var name0 := kid.name
	var family0 := kid.family
	var age0 := Life.npc_age(w, kid)
	orphan(w, f[0])
	for hh in w.households:                     # no household with a home anywhere
		if int(hh.id) != f[0]:
			hh.home = ""
	var before := int(w.stats.get("orphans_to_clan", 0))
	var tier := Guardianship.place(w, kid)
	check(tier == "clan" and kid.clan == "bandit" and kid.household == -1, "with no household able, the child joins the bandit clan (FAM-07, OD-11) (%s)" % tier)
	check(int(w.stats.get("orphans_to_clan", 0)) == before + 1, "and the case is counted")
	check(kid.alive and kid.role == "child" and kid.name == name0 and kid.family == family0 and absf(Life.npc_age(w, kid) - age0) < 0.01, "the child keeps name, age and role: still a child")
	check(kid.mother == mom.id and mom.children.has(kid.id), "and the family tree")
	check(kid.damage <= 3.0 and not kid.inv.has("copper_sword"), "no adult combat ability")
	check(not w.households[f[0]].members.has(kid.id), "no limbo: the child left the empty household")
	# fed and safe at the camp
	kid.hunger = 10.0
	w.brain.decide(kid)
	check(str(kid.doing).contains("bandits' camp"), "a hungry clan child eats at the camp (%s)" % kid.doing)
	# FSE-B06: from the band's stores, never from nothing
	var feeder: NPC = w.npcs.filter(func(o): return o.alive and o.role == "bandit")[0]
	feeder.inv.add("bread", 2)
	var bread0 := 0
	for o: NPC in w.npcs:
		if o.alive and o.role == "bandit":
			bread0 += o.inv.count("bread")
	w.brain.act(kid, "camp_meal", {})
	var bread1 := 0
	for o: NPC in w.npcs:
		if o.alive and o.role == "bandit":
			bread1 += o.inv.count("bread")
	check(kid.hunger > 10.0 and bread1 < bread0, "with the band: fed from the band's stores (hunger %.0f, bread %d -> %d)" % [kid.hunger, bread0, bread1])
	kid.coins = 50
	kid.pos = Vector2(w.bandit_camp) + Vector2(2, 0)
	for o: NPC in w.npcs:
		if o.alive and o.role == "bandit":
			check(w.brain._prey_for(o) != kid, "never a bandit's prey")
			break
	# saved
	var back := NPC.from_dict(JSON.parse_string(JSON.stringify(kid.to_dict())))
	check(back.clan == "bandit" and back.mother == mom.id, "the clan survives saving and loading")
	# coming of age with nowhere to go: they stay with the band (a bandit's health and blow, nothing made for them)
	var items0: int = kid.inv.total()
	Life._set_role(w, kid, "adult")
	check(kid.role == "bandit" and kid.max_hp == 25.0 and kid.inv.total() == items0, "with no kin or household able to take them, the young adult stays with the band")
	check(kid.mother == mom.id and kid.name == name0, "still who they were")
	# coming of age with a place in the village (owner, 2026-10-20: staying is one possible outcome, not a mandatory one)
	var w3 := new_world()                        # a village with its houses and room in them; a clan child of it
	var k3: NPC = w3.npc(kid.id)
	k3.clan = "bandit"
	(w3.households[k3.household].members as Array).erase(k3.id)
	k3.household = -1
	k3.home = ""
	Life._set_role(w3, k3, "adult")
	check(k3.role == "adult" and k3.clan == "" and k3.household >= 0 and w3.buildings.has(k3.home), "with a household able to take them, the young adult leaves the camp for the village (%s, household %d)" % [k3.role, k3.household])
	check(k3.job == "" and k3.mother == kid.mother, "as an adult without a trade, family tree kept")
