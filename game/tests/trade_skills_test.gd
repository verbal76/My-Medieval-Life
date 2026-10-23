extends SceneTree
## SKILL-TRADES-18, LAW-SKILL and DVW-B8 (owner Q18-1, Q18-14, DVW-B8; 2026-10-23): Carpentry, Masonry and Tanning start from
## each person's Crafting (new world and older save), their recipes train them, Law rises from witnessing and carrying
## documents and from the reeve's lessons and the notary check uses it, Farming starts from the recorded farming
## experience and Farming, Husbandry, Hunting and Healing are trained by the work.
##   godot --headless --path game --script res://tests/trade_skills_test.gd

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
	test_recipes()
	test_new_world()
	test_old_save()
	test_law()
	test_work_xp()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func test_recipes() -> void:
	var want := {"saw_planks": "carpentry", "make_cart_wheel": "carpentry", "build_handcart": "carpentry", "make_ladder": "carpentry",
			"dress_stone": "masonry", "tan_leather": "tanning", "tan_pelts": "tanning", "leather_armor": "tanning", "leather_cap": "tanning",
			"weave_cloth": "crafting", "craft_plough": "crafting", "brew_tonic": "healing", "brew_strong_tonic": "healing", "brew_ale": "cooking"}
	for r in want:
		check(str(GameData.recipes[r].skill) == want[r], "%s trains %s" % [r, want[r]])
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var p := w.player
	p.inv.add("log", 1)
	var res := w.work_craft(p, "saw_planks", p.inv)
	check(res.result == "ok" and int(p.skills.get("carpentry", 0)) == int(GameData.recipes.saw_planks.xp) and not p.skills.has("crafting"), "sawing earns Carpentry, not Crafting")
	var inds: Dictionary = SettlementIndustries.data().industries
	var ok := true
	for pair in [["carpentry", "carpentry"], ["masonry", "masonry"], ["tanning", "tanning"]]:
		ok = ok and str(inds[pair[0]].levels[0].needs[0].skill) == pair[1]
	check(ok, "the carpentry, masonry and tanning industries count their own skill's practitioners")
	check(WorkExperience.SKILL_OF.carpentry == "carpentry" and WorkExperience.SKILL_OF.masonry == "masonry" and WorkExperience.SKILL_OF.tanning == "tanning", "experience starts read the new skills")


func test_new_world() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var carp := 0
	for n: NPC in w.npcs:
		if not n.alive or n.skills.is_empty():
			continue
		var c := int(n.skills.get("crafting", 0))
		for sk in ["carpentry", "masonry", "tanning"]:
			if c > 0:
				carp += 1
				if int(n.skills.get(sk, 0)) != c:
					check(false, "%s %d starts %s from Crafting %d, has %d" % [n.name, n.id, sk, c, int(n.skills.get(sk, 0))])
			else:
				if n.skills.has(sk):
					check(false, "no Crafting, no %s" % sk)
		check(not n.skills.has("law"), "Law starts at 0 for everyone")
	check(carp > 0, "someone had Crafting to carry over (%d)" % carp)
	check(w.player.skills.is_empty() and Skills.level(w.player, "law") == 1, "the player starts with nothing")
	check(bool(w.to_dict().get("trade_skills", false)), "the save marks the trade skills as started")


func test_old_save() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.player.skills = {"crafting": 700, "mining": 50}
	var smith: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.job == "carpenter":
			smith = n
	smith.skills = {"crafting": 450, "cooking": 300}
	var d := w.to_dict()
	d.erase("trade_skills")                                   # a save from before the trade skills
	for pn in d.npcs:
		if int(pn.id) == smith.id:
			pn.skills = {"crafting": 450, "cooking": 300}
	d.player.skills = {"crafting": 700, "mining": 50}
	var back = JSON.parse_string(JSON.stringify(d))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), back)
	var s2: NPC = w2.npc(smith.id)
	check(int(w2.player.skills.carpentry) == 700 and int(w2.player.skills.masonry) == 700 and int(w2.player.skills.tanning) == 700 and int(w2.player.skills.crafting) == 700, "an older save's player keeps Crafting and starts the three from it")
	check(int(s2.skills.carpentry) == 450 and int(s2.skills.tanning) == 450 and int(s2.skills.crafting) == 450, "and so does a villager (no one loses progress)")
	check(int(s2.skills.healing) == 300 and int(s2.skills.cooking) == 300, "Healing starts from Cooking, which brewed the tonics")
	check(not w2.player.skills.has("law") and not w2.player.skills.has("hunting") and not w2.player.skills.has("husbandry"), "Law, Hunting and Husbandry start at nothing")
	var again = JSON.parse_string(JSON.stringify(w2.to_dict()))
	again.player.skills.carpentry = 5
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), again)
	check(int(w3.player.skills.carpentry) == 5, "a save with the mark is never re-seeded")


func test_law() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var cs := CourierService.new(w)
	var fa := FormalAgreements.new(cs)
	var notary: NPC = w.npcs.filter(func(n): return n.alive and n.role == "adult" and n.job != "reeve")[0]
	var nref := "npc:%d" % notary.id
	check(str(CourierService.cfg().notary.skill) == "law" and fa.notary_qualified(nref) == false, "the notary check is Law, and nobody has it at the start")
	notary.skills["trading"] = Skills.xp_for_level(8)
	check(not fa.notary_qualified(nref), "Trading no longer qualifies a notary")
	Law.carried(w, nref)
	Law.witnessed(w, nref)
	check(int(notary.skills.law) == 30 and not fa.notary_qualified(nref), "witnessing and carrying raise Law (30 xp, still below the notary level)")
	for i in 4:
		Law.carried(w, nref)
	check(Skills.level(notary, "law") >= int(CourierService.cfg().notary.min_level) and fa.notary_qualified(nref), "enough documents carried make a notary")
	# the reeve teaches, one lesson a day, up to the reeve's ceiling
	var reeve: NPC = w.npc(w.reeve_id)
	check(Law.teaches(reeve) and not Law.teaches(notary), "the reeve teaches the law; the others do not")
	var r := Law.teach(w, World.PLAYER, reeve)
	check(r.ok and int(w.player.skills.law) == int(CourierService.cfg().law.lesson_xp), "a lesson gives the player Law experience")
	r = Law.teach(w, World.PLAYER, reeve)
	check(not r.ok and int(w.player.skills.law) == int(CourierService.cfg().law.lesson_xp), "a second lesson the same day is refused")
	var cap := int(CourierService.cfg().law.teachers.reeve)
	for i in 30:
		w.minutes += World.DAY
		Law.teach(w, World.PLAYER, reeve)
	check(Skills.level(w.player, "law") == cap and Law.teach(w, World.PLAYER, reeve).ok == false, "the reeve teaches up to Law %d and no further" % cap)
	var back = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), back)
	check(int(w2.player.skills.law) == int(w.player.skills.law) and w2.law_lessons.size() == w.law_lessons.size(), "Law and the day's lessons are saved")
	# a signature before a notary is witnessed
	var a: NPC = w.npcs.filter(func(n): return n.alive and n.role == "adult" and n != notary)[1]
	var xp0 := int(notary.skills.law)
	var ag := fa.draft("commercial", [nref, "npc:%d" % a.id], 400)
	ag.holder = nref
	Law.witnessed(w, nref)
	check(int(notary.skills.law) == xp0 + int(CourierService.cfg().law.witness_xp), "witnessing a signature gives the notary Law")


func test_work_xp() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var p := w.player
	var xp0 := Skills.action_xp("harvest")
	check(xp0 > 0 and Skills.step_xp("feed_pen").skill == "husbandry" and Skills.step_xp("harvest").skill == "farming", "the work-xp table maps acts to Farming and Husbandry")
	w.player_xp("healing", 1)
	p.hp = 1.0
	p.inv.add("herbal_poultice", 1)
	check(w.player_use_medicine("herbal_poultice") and int(p.skills.healing) >= 1 + Skills.action_xp("treat"), "dressing a wound trains Healing")
	# Farming starts from recorded experience: a farmer with 9 days of 18 is level 5
	var f: NPC = w.npcs.filter(func(n): return n.alive and n.job == "farmer")[0]
	f.skills.erase("farming")
	w.experience.minutes[World.npc_ref(f.id)] = {"farming": 9.0 * 480.0}
	Skills.seed_farming(w)
	check(Skills.level(f, "farming") == 5, "Farming starts at level 5 from 9 of 18 recorded farming days (level %d)" % Skills.level(f, "farming"))
