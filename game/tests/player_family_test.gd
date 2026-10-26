extends SceneTree
## MP-PLAYER-FAMILY (owner decisions 2026-10-24: docs/directives/2026-10-24_owner_decision_player_marriage_children.md and
## 2026-10-24_mp_player_family_minimal_fix.md; amendment 2026-10-26): children of two married players, in one process.
##  - marriage founds the couple's household (Life.found_couple_household): the host's line first, no members, the couple's home;
##  - a man and a woman have children by Life.births' own rules (ages, food, interval, chance): both recorded as parents, a new person
##    in the couple's household; a couple of one sex (two women, two men) never has a birth;
##  - adoption is the player's own act (Guardianship.player_adopt), for any couple: both spouses the child's adoptive parents (mother
##    and father stay as born), the child in the couple's household, each spouse's child, the population unchanged; never automatic
##    (no orphan is placed with a couple by the village);
##  - the couple's household is cared for while either lives, away or not (not orphaned, never ended, nobody lodged in it);
##  - save and load keep every link, twice the same; a save 22 (Build 21, tests/fixtures/mp_save_v22_couple.json) migrates to 23 with
##    everything kept and the couple's household founded once; single player is unchanged (no couple household, no adoptive links);
##  - a spouse's death: the dead is an ancestor in the couple's record, the heir is not the spouse, the children stay.
##   godot --headless --path game --script res://tests/player_family_test.gd

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
	test_marriage_founds_household()
	test_birth_man_and_woman()
	test_no_birth_one_sex()
	test_adoption_any_couple()
	test_never_automatic_and_cared_for()
	test_save_round_trip()
	test_migration_from_22()
	test_spouse_dies()
	test_single_player_unchanged()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ------------------------------------------------------------------ helpers ----------------------
func _world(seed_ := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed_)
	return w


func _guest(w: World, sex: String, nm := "Gwen") -> PlayerState:
	var g := PlayerState.new()
	g.name = nm
	g.family = "Fairlight"
	g.sex = sex
	g.born = w.player.born
	Identity.register_player(w, g)
	w.give_start_kit(g)
	g.pos = w.player.pos + Vector2(1, 0)
	g.net_key = "ab".repeat(32)
	w.add_guest(g)
	return g


## A house with beds made the host's home (no household lives in it).
func _home(w: World) -> String:
	var ids: Array = w.buildings.keys()
	ids.sort()
	for id in ids:
		var b: Dictionary = w.buildings[id]
		if str(b.type) == "house" and w.construction.beds_in(str(id)) >= 2 and w.household_in(str(id)) < 0:
			w.set_owner(b, World.PLAYER)
			w.set_tenant(b, "")
			w.player.home = str(id)
			return str(id)
	for id in ids:                                   # every house lived in: one of them, emptied of its claim on it
		var b: Dictionary = w.buildings[id]
		if str(b.type) == "house" and w.construction.beds_in(str(id)) >= 2:
			w.set_owner(b, World.PLAYER)
			w.set_tenant(b, "")
			w.player.home = str(id)
			return str(id)
	return ""


## The host (sex `a`) and a guest (sex `b`), adults of 25, married by both agreeing (MP-D8); the host with a house.
func _couple(w: World, a: String, b: String) -> PlayerState:
	w.player.sex = a
	w.player.born = Life.born_for_age(25.0, w.minutes)
	var g := _guest(w, b)
	_home(w)
	w.player_offer("partner", g.pid)
	w.player_answer(int(w.offers_to(g)[0].id), true, g)
	return g


func _feed(w: World, ps: Array) -> void:
	for p: PlayerState in ps:
		p.chest.add("wheat", 60)


## Run Life.births up to `days` times (each a dawn's roll) and return the children born to a player mother or father (the village's
## own births go on beside them, as they would).
func _births(w: World, days: int) -> Array:
	var before := w.npcs.size()
	var got := []
	for i in days:
		Life.births(w)
		got = w.npcs.slice(before).filter(func(o: NPC) -> bool: return Life.is_player_id(o.mother) or Life.is_player_id(o.father))
		if not got.is_empty():
			break
	return got


func _orphan_for_adoption(w: World) -> NPC:
	for hh in w.households:
		var h := int(hh.id)
		if h < 3 or Life.is_couple(hh):
			continue
		var ms: Array = w.brain._members(h)
		var kids: Array = ms.filter(func(o: NPC) -> bool: return o.role == "child")
		if kids.is_empty():
			continue
		var kid: NPC = kids[0]
		if not Life.parent_ids(kid).all(func(pid): return int(pid) < 0 or w.npc(int(pid)) == null or ms.has(w.npc(int(pid))) or not w.npc(int(pid)).alive):
			continue                                     # a parent living elsewhere would keep the child
		for o: NPC in ms:
			if o.alive and o.role != "child":
				w.kill(o, "fever")
		var tier := Guardianship.place(w, kid)
		if tier in ["villager", "clan"]:
			return kid
	return null


func _reload(d: Dictionary) -> World:
	var w := World.new()
	w.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d, "", true, true)))
	return w


func _fixture(name: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/" + name))


func _links(w: World) -> String:
	var out := []
	for n: NPC in w.npcs:
		out.append([n.id, n.mother, n.father, n.adoptive, n.children, n.household, n.home, n.alive])
	for p: PlayerState in w.player_list():
		out.append([p.pid, p.partner, p.children, p.mother, p.father])
	for hh in w.households:
		out.append([hh.id, hh.get("couple", []), hh.members, hh.home, hh.family, hh.get("ended", false)])
	return JSON.stringify(World._whole_numbers(out))      # as a save holds them (JSON reads whole numbers as floats)


# ------------------------------------------------------------------ tests ------------------------
func test_marriage_founds_household() -> void:
	var w := _world()
	var n0 := w.households.size()
	var g := _couple(w, "male", "female")
	check(w.player.partner == w.person_id(g) and g.partner == -2, "the host and the guest are married (MP-D8)")
	var h := Life.couple_household(w, w.player, g)
	check(h == n0 and w.households.size() == n0 + 1, "the marriage founds one household (%d)" % h)
	var hh: Dictionary = w.households[h]
	check(JSON.stringify(hh.couple) == JSON.stringify([-2, w.person_id(g)]) and (hh.members as Array).is_empty() and str(hh.family) == w.player.family,
		"its record: the two players' ids, the host's line first; no member yet; the host's family name")
	Life.sync_couple_homes(w)
	check(str(hh.home) == w.player.home and w.player.home != "", "it lives in the couple's home (%s)" % hh.home)
	check(Guardianship.player_household(w, w.player) == h and Guardianship.player_household(w, g) == h, "it is each spouse's household")
	check(Life.found_couple_household(w, g, w.player) == h and w.households.size() == n0 + 1, "founding again finds the same one (no duplicate)")
	w.dispose()


func test_birth_man_and_woman() -> void:
	for host_sex in ["male", "female"]:
		var w := _world(2)
		var g := _couple(w, host_sex, "female" if host_sex == "male" else "male")
		var mom: PlayerState = g if g.sex == "female" else w.player
		var dad: PlayerState = w.player if mom == g else g
		var h := Life.couple_household(w, w.player, g)
		Life.sync_couple_homes(w)
		_feed(w, [w.player, g])
		var pop := w.npcs.size()
		var got := _births(w, 6000)
		check(got.size() == 1, "%s host: a child is born to the man and the woman by Life.births' own chance (%d)" % [host_sex, got.size()])
		if got.is_empty():
			w.dispose()
			continue
		var k: NPC = got[0]
		check(k.mother == w.person_id(mom) and k.father == w.person_id(dad), "both recorded as parents: mother %d, father %d" % [k.mother, k.father])
		check(mom.children.has(k.id) and dad.children.has(k.id) and k.adoptive.is_empty(), "the child is each spouse's, born to them (not adopted)")
		check(k.household == h and (w.households[h].members as Array).has(k.id) and k.home == str(w.households[h].home) and k.role == "child",
			"a child of the couple's household, in its home")
		check(w.npcs.size() > pop and w.people.has(k.id) and w.npcs.filter(func(o: NPC) -> bool: return Life.is_player_id(o.mother)).size() == 1, "a new person, in the register of people")
		var again := _births(w, 50)
		check(again.is_empty(), "the interval holds: no second birth at once")
		check(Guardianship.orphans(w, h).is_empty(), "the couple's household is cared for: its child is no orphan")
		w.dispose()
	# away: the father a guest out of play still fathers (owner: in play or away)
	var w2 := _world(2)
	var g2 := _couple(w2, "female", "male")
	g2.away = true
	Life.sync_couple_homes(w2)
	_feed(w2, [w2.player])
	var got2 := _births(w2, 6000)
	check(got2.size() == 1 and (got2[0] as NPC).father == w2.person_id(g2), "a husband away (MP-D1) is still the father")
	w2.dispose()
	# no house: no birth (a newborn lives in its household's house)
	var w3 := _world(2)
	var g3 := _couple(w3, "male", "female")
	w3.player.home = ""
	w3.households[Life.couple_household(w3, w3.player, g3)].home = ""
	_feed(w3, [w3.player, g3])
	check(_births(w3, 6000).is_empty(), "a couple without a house has no child born (none would have a home)")
	w3.dispose()


func test_no_birth_one_sex() -> void:
	for sx in ["female", "male"]:
		var w := _world(2)
		var g := _couple(w, sx, sx)
		Life.sync_couple_homes(w)
		_feed(w, [w.player, g])
		check(w.player.partner == w.person_id(g), "two %s players marry" % sx)
		check(_births(w, 6000).is_empty(), "two %s players never have a birth (6000 dawns)" % sx)
		w.dispose()


func test_adoption_any_couple() -> void:
	for sexes in [["female", "female"], ["male", "male"], ["male", "female"]]:
		var w := _world(3)
		var g := _couple(w, sexes[0], sexes[1])
		Life.sync_couple_homes(w)
		var h := Life.couple_household(w, w.player, g)
		var kid := _orphan_for_adoption(w)
		check(kid != null, "%s/%s: an orphan cared for by strangers" % sexes)
		if kid == null:
			w.dispose()
			continue
		var mom0 := kid.mother
		var dad0 := kid.father
		var pop := w.npcs.size()
		var living := w.npcs.filter(func(o: NPC) -> bool: return o.alive).size()
		var from := kid.household
		var why := Guardianship.player_adopt(w, kid, g)        # the guest's own act
		check(why == "", "%s/%s: the guest takes the child in (%s)" % [sexes[0], sexes[1], why])
		check(JSON.stringify(kid.adoptive) == JSON.stringify([-2, w.person_id(g)]) and w.player.children.has(kid.id) and g.children.has(kid.id),
			"both spouses are the child's parents (adoptive), and it is each spouse's child")
		check(kid.mother == mom0 and kid.father == dad0, "its birth parents stay recorded")
		check(kid.household == h and (w.households[h].members as Array).has(kid.id) and not (w.households[from].members as Array).has(kid.id) if from >= 0 else kid.household == h,
			"it joins the couple's household and leaves the one it was in")
		check(w.npcs.size() == pop and w.npcs.filter(func(o: NPC) -> bool: return o.alive).size() == living, "no new person: the population is unchanged")
		check(Guardianship.player_adopt_refusal(w, kid).contains("already"), "and not twice")
		check(Dialogue.bond_words(w, kid) == "your child (taken in)", "the talk window names the child the host's own (%s)" % Dialogue.bond_words(w, kid))
		var d := Guardianship.kin_distances(w, kid)
		check(int(d.get(-2, -1)) == 1 and int(d.get(w.person_id(g), -1)) == 1, "by the family tree both spouses are its parents (distance 1)")
		check(Life.partner_refusal(w, kid) != "", "a parent cannot court their child")
		w.dispose()


func test_never_automatic_and_cared_for() -> void:
	var w := _world(3)
	var g := _couple(w, "female", "female")
	Life.sync_couple_homes(w)
	var h := Life.couple_household(w, w.player, g)
	var kid := _orphan_for_adoption(w)
	if kid == null:
		check(false, "an orphan")
		return
	check(kid.household != h and not (Guardianship.candidates(w, kid).get("villager", []) as Array).has(h), "the village never places an orphan with a player couple (adoption is their act)")
	for i in 3:
		w.minutes += World.DAY
		w._new_day()
	check(kid.household != h and (w.households[h].members as Array).is_empty(), "three dawns later the couple has adopted nobody by itself")
	Guardianship.player_adopt(w, kid)
	g.away = true
	for i in 3:
		w.minutes += World.DAY
		w._new_day()
	check(kid.household == h and not w.households[h].get("ended", false) and w.property._anyone_alive(h), "with one spouse away the household is kept, the child in it")
	check(not w.construction.housing_goals(h).size() > 0, "the village leaves the couple's housing to them")
	w.dispose()


func test_save_round_trip() -> void:
	var w := _world(2)
	var g := _couple(w, "male", "female")
	Life.sync_couple_homes(w)
	_feed(w, [w.player, g])
	var born := _births(w, 6000)
	var kid := _orphan_for_adoption(w)
	if kid != null:
		Guardianship.player_adopt(w, kid)
	g.away = true
	var d := w.to_dict()
	check(int(d.save_version) == 23, "the save is version 23")
	var w2 := _reload(d)
	check(born.size() == 1 and kid != null, "a born child and an adopted child")
	var l1 := _links(w)
	var l2 := _links(w2)
	check(l2 == _links(_reload(w.to_dict())) and l1 == l2, "every family link comes back as it was (parents, adoptive parents, children, households, partners)%s" % ("" if l1 == l2 else "\n  %s\n  %s" % [l1.right(500), l2.right(500)]))
	var g2 := w2.player_by_pid(g.pid)
	check(g2 != null and g2.away and g2.partner == -2 and g2.children.size() == 2, "the guest away keeps its partner and both children")
	check(JSON.stringify(w2.to_dict(), "", true) == JSON.stringify(_reload(w2.to_dict()).to_dict(), "", true), "a second round trip changes nothing")
	var w3 := _reload(w2.to_dict())
	var hh3 := Life.couple_household(w3, w3.player, w3.player_by_pid(g.pid))
	var n3 := 0
	for hh in w3.households:
		if hh.has("couple"):
			n3 += 1
	check(hh3 >= 0 and n3 == 1, "one couple household after loading twice (none duplicated)")
	w.dispose()
	w2.dispose()
	w3.dispose()


func test_migration_from_22() -> void:
	var d := _fixture("mp_save_v22_couple.json")
	check(int(d.save_version) == 22, "the Build 21 fixture is a save 22 (written by 6567c04)")
	var m1 := World.migrate_22_to_23(d)
	check(int(m1.save_version) == 23 and JSON.stringify(World.migrate_22_to_23(m1)) == JSON.stringify(m1), "the raw step names version 23 and is idempotent")
	check((m1.households as Array).size() == (d.households as Array).size() + 1 and (m1.households[-1] as Dictionary).has("couple") and int(m1._migrated_22.couples) == 1,
		"it founds the married players' household on the saved data (%s)" % JSON.stringify(m1.households[-1]))
	var w := _reload(d)
	check(w.load_error == "", "it loads (%s)" % w.load_error)
	var gk := ""
	for k in d.players.by_pid:
		if int(k) != int(d.players.host):
			gk = k
	var gd: Dictionary = d.players.by_pid[gk]
	var g := w.player_by_pid(int(gk))
	check(g != null and g.away and g.partner == -2 and w.player.partner == w.person_id(g), "the married guest is back, away, both still partners")
	var h := Life.couple_household(w, w.player, g)
	check(h == (d.households as Array).size() and w.households.size() == (d.households as Array).size() + 1, "the couple's household is founded once, after every saved household")
	check(g.coins == int(gd.coins) and JSON.stringify(g.inv.items) == JSON.stringify(PlayerState.from_dict(gd).inv.items) and JSON.stringify(g.chest.items) == JSON.stringify(PlayerState.from_dict(gd).chest.items),
		"the guest's purse, pack and chest as saved")
	var hp := PlayerState.from_dict(d.player)
	check(w.player.coins == hp.coins and JSON.stringify(w.player.inv.items) == JSON.stringify(hp.inv.items) and JSON.stringify(w.player.chest.items) == JSON.stringify(hp.chest.items),
		"the host's purse, pack and chest as saved")
	var ties_ok := true
	for k in d.relations.ties:
		var parts := str(k).split(":")
		var t: Dictionary = w.relations.peek(int(parts[0]), int(parts[1]))
		ties_ok = ties_ok and absf(float(t.regard) - float(d.relations.ties[k].get("regard", 0.0))) < 0.0001
	check(ties_ok and (d.relations.ties as Dictionary).size() > 0, "every tie as saved (%d)" % (d.relations.ties as Dictionary).size())
	var out := w.to_dict()
	var same := (out.npcs as Array).size() == (d.npcs as Array).size()
	for i in (d.npcs as Array).size():
		same = same and int(out.npcs[i].id) == int(d.npcs[i].id) and int(out.npcs[i].coins) == int(d.npcs[i].coins) and int(out.npcs[i].mother) == int(d.npcs[i].mother) \
			and JSON.stringify((out.npcs[i].children as Array).map(func(x): return int(x))) == JSON.stringify((d.npcs[i].children as Array).map(func(x): return int(x))) \
			and not out.npcs[i].has("adoptive")
	check(same, "every villager as saved (ids, purses, parents, children); nobody given an adoptive parent")
	var hsame := true
	for i in (d.households as Array).size():
		hsame = hsame and JSON.stringify((out.households[i].members as Array).map(func(x): return int(x))) == JSON.stringify((d.households[i].members as Array).map(func(x): return int(x))) \
			and not out.households[i].has("couple")
	check(hsame, "every saved household as it was")
	var lost := []
	for k in d:
		if not out.has(k):
			lost.append(k)
	check(lost.is_empty(), "no section dropped%s" % ("" if lost.is_empty() else ": " + str(lost)))
	check(w.total_coins() == _reload(out).total_coins(), "the coin census is the same (%d)" % w.total_coins())
	var once := _reload(out).to_dict()
	check(JSON.stringify(once, "", true) == JSON.stringify(_reload(once).to_dict(), "", true), "loading the migrated save again gives the same save (deterministic)")
	var w2 := _reload(d)
	check(JSON.stringify(w2.to_dict(), "", true) == JSON.stringify(out, "", true), "loading the Build 21 save twice gives the same world")
	var mt := SaveTransfer.migrate(d, VillageMap.load_default())
	check(mt.ok and int(mt.data.save_version) == 23, "an imported Build 21 save migrates to 23 through SaveTransfer (%s)" % mt.get("reason", ""))
	w.dispose()
	w2.dispose()


func test_spouse_dies() -> void:
	var w := _world(2)
	var g := _couple(w, "male", "female")
	Life.sync_couple_homes(w)
	_feed(w, [w.player, g])
	var got := _births(w, 6000)
	if got.is_empty():
		check(false, "a child")
		return
	var k: NPC = got[0]
	var h := Life.couple_household(w, w.player, g)
	w.player.alive = false
	w.continue_as_heir()
	check(int(w.households[h].couple[0]) == Life.FORMER_PLAYER and k.father == Life.FORMER_PLAYER and g.partner == Life.FORMER_PLAYER,
		"the dead husband is an ancestor in the couple's record, the child's and the widow's links (%s, %d, %d)" % [str(w.households[h].couple), k.father, g.partner])
	check(w.player.partner == -1 and Guardianship.player_household(w, w.player) != h, "the heir is not the widow's spouse")
	check(k.household == h and Life.couple_parents(w, h) == [g] and Guardianship.orphans(w, h).is_empty(), "the child stays with its mother in the household (hh %d of %d, parents %d)" % [k.household, h, Life.couple_parents(w, h).size()])
	g.alive = false
	check(Guardianship.orphans(w, h).has(k), "with both parents gone, the child is an orphan as any other (the guardianship order takes it)")
	w.dispose()


func test_single_player_unchanged() -> void:
	var w := _world(2)
	var hs := w.households.size()
	check(Life.ensure_couple_households(w) == 0 and w.households.size() == hs, "single player: no couple household")
	var w2 := _reload(w.to_dict())
	var any := false
	for hh in w2.households:
		any = any or hh.has("couple")
	for n: NPC in w2.npcs:
		any = any or not n.adoptive.is_empty()
	check(not any and w2.households.size() == hs, "and none on load; no adoptive link")
	w.dispose()
	w2.dispose()
