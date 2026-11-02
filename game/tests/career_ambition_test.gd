extends SceneTree
## B25-AMBITION-IMPL (owner B25-AMBITION-D4, 2026-11-01, docs/directives/2026-11-01_career_business_employment_final_decisions.md
## Decision 4): the career ambition switched on. The skills each trade's work really trains (the corrected mapping), the
## shipped switches (aspirations and job_choice on, the layer's other readers off), villagers differing in ambition, an
## ambitious skilled villager choosing a better-matching place while a content one stays, no promotion by a skill level
## (X18-D3), determinism, and the state kept through save and load. Run headless:
##   godot --headless --path game --script res://tests/career_ambition_test.gd

const A := preload("res://scripts/core/judgment/judgment_aspiration.gd")

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
	test_mapping()
	test_switches()
	test_ambition_varies()
	test_ambitious_moves_content_stays()
	test_no_threshold_promotion()
	test_determinism()
	test_save_load()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func world(seed := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


func adults(w: World) -> Array:
	var out := []
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 0 and n.job != "guard":
			out.append(n)
	return out


## Exact weighing for a test that computes the outcome: no per-person weight spread, argmax selection.
func exact(w: World) -> void:
	w.judgment.cfg.decision.trait_spread_permille = 0
	w.judgment.cfg.decision.selection = "argmax"


# ---------------------------------------------------------------- the mapping ---------------------
func test_mapping() -> void:
	var w := world()
	var a: JudgmentAspiration = w.judgment.asp
	var r := GameData.recipes
	# what each trade's own work trains, read from the data the work uses
	check(a.trade_skills("carpenter") == [str(r.saw_planks.skill)] and str(r.make_ladder.skill) == "carpentry", "carpenter: carpentry (saw_planks, make_ladder), not crafting")
	check(a.trade_skills("tanner") == [str(r.tan_leather.skill)] and str(r.tan_pelts.skill) == "tanning" and str(r.leather_cap.skill) == "tanning", "tanner: tanning (tan_leather, tan_pelts, leather_cap), not crafting")
	check(a.trade_skills("stonecutter") == [str(r.dress_stone.skill)] and a.trade_skills("stonecutter") == ["masonry"], "stonecutter: masonry (dress_stone)")
	check(a.trade_skills("farmer") == [str(Skills.step_xp("harvest").skill)] and str(Skills.step_xp("sow").skill) == "farming", "farmer: farming (the field work's act_skill)")
	check(a.trade_skills("sage") == [str(r.brew_poultice.skill)] and a.trade_skills("sage") == ["healing"], "sage: healing (brew_poultice)")
	check(a.trade_skills("smith") == [str(r.smelt_iron.skill)] and a.trade_skills("cook") == [str(r.cook_pottage.skill)], "smith: smithing; cook: cooking")
	check(a.trade_skills("hunter") == ["hunting"] and a.trade_skills("miner") == ["mining"] and a.trade_skills("prospector") == ["mining"], "hunter: hunting (DVW-B8); miner and prospector: mining")
	for j in ["manor_hand", "tailor", "barber", "reeve", "preacher", "church_assistant", ""]:
		check(a.trade_skills(j).is_empty(), "%s: no skill its work trains (tenure stands for it)" % (j if j != "" else "no job"))
	for j in a.c.job_skills:
		if not str(j).begins_with("_"):
			for sk in a.c.job_skills[j]:
				check(GameData.skills.has(str(sk)), "%s's %s is a real skill (skills.json)" % [j, sk])
	# world generation untouched: the starting-experience table is what it was
	var js: Dictionary = GameData.b("skill_start").job_skills
	check(js.carpenter == ["crafting"] and js.tanner == ["crafting"] and not js.has("farmer"), "skill_start.job_skills (new worlds' starting experience) is unchanged")
	# the fit reads the corrected skills
	var n: NPC = adults(w)[0]
	n.skills = {"carpentry": Skills.xp_for_level(6)}
	check(a.skill_fit(n, "carpenter") == 6 * 100000 / 8, "skill_fit: a carpenter's carpentry counts (level 6 of 8: %d)" % a.skill_fit(n, "carpenter"))
	n.skills = {"crafting": Skills.xp_for_level(6)}
	check(a.skill_fit(n, "carpenter") == 0, "skill_fit: crafting alone is not carpentry")
	n.skills = {"masonry": Skills.xp_for_level(4), "farming": Skills.xp_for_level(8)}
	check(a.skill_fit(n, "stonecutter") == 50000 and a.skill_fit(n, "farmer") == 100000, "skill_fit: masonry for the stonecutter, farming for the farmer")
	check(a.growth_fit(n, "farmer") > 0 and a.growth_fit(n, "tanner") == 0, "growth_fit: room to grow only in a skill already practised")
	w.dispose()


# ---------------------------------------------------------------- switches ------------------------
func test_switches() -> void:
	var c := JudgmentStore.default_cfg()
	check(bool(c.aspiration.enabled) and bool(c.decision.integration.job_choice), "shipped (B25-AMBITION-D4): aspiration.enabled and integration.job_choice on")
	check(not bool(c.aspiration.apply.factors) and not bool(c.aspiration.apply.court) and not bool(c.aspiration.apply.proposal),
			"shipped: the layer's other readers (yes-or-forgo factor, courting, proposals) stay off")
	var w := world(3)
	var j: JudgmentStore = w.judgment
	check(JudgmentLive.on(w, "job_choice") and j.asp.enabled, "a new world: job_choice consults the career ambition")
	w.brain.dawn()
	var ps := adults(w)
	var r := JudgmentWeighting.choose(j, j.cfg, ps[0].id, "work_accept", [{"id": "yes", "counterparty": ps[1].id, "factors": {"live_order": 100000, "necessity": 0}}], [1])
	check(not JSON.stringify(r).contains("aspiration"), "apply.factors off: no aspiration factor in work_accept")
	var r2 := JudgmentWeighting.choose(j, j.cfg, ps[0].id, "court_choice", [{"id": 1, "counterparty": ps[1].id, "factors": {"attraction": 60000}}], [1])
	check((r2.trace[0].contributions as Dictionary).keys().size() == 2, "apply.court off: court_choice weighs attraction and disposition only")
	check(int(j.stats.get("aspire_dawns", 0)) == 1 and not j.asp.rows.is_empty(), "the dawn update runs (%d rows)" % j.asp.rows.size())
	w.dispose()


# ---------------------------------------------------------------- ambition varies ------------------
func test_ambition_varies() -> void:
	var w := world(2)
	var a: JudgmentAspiration = w.judgment.asp
	w.brain.dawn()
	var yes := 0
	var no := 0
	var pr := {}
	var days := {}
	for n: NPC in adults(w):
		if not a.rows.has(n.id):
			continue
		if a.ambitious(n, w):
			yes += 1
		else:
			no += 1
		pr[a.priority(n, A.PROFESSION, w)] = true
		for d in 7:
			if a.looks_today(n, d):
				days[n.id] = d
	check(yes > 0 and no > 0 and no > yes, "some villagers are ambitious, most are not (%d ambitious, %d not)" % [yes, no])
	check(pr.size() > 5, "profession priorities differ person to person (%d distinct)" % pr.size())
	var spread := {}
	for id in days:
		spread[days[id]] = true
	check(days.size() == yes + no and spread.size() >= 5, "each looks on one morning of their own a week (%d different mornings)" % spread.size())
	w.dispose()


# ---------------------------------------------------------------- the career decision -------------
## A skilled, ambitious manor hand takes the farm place that suits their farming; a content one with the same skill and an
## ambitious one without it stay. Run through the live seek_work.
func career_world(seed := 1) -> Dictionary:
	var w := world(seed)
	exact(w)
	var a: JudgmentAspiration = w.judgment.asp
	a.c.job.look_days = 1                      # every morning a look day, so the test needs one morning
	for k in ["priority_spread", "young_step", "old_step", "old_profession_step"]:
		a.c[k] = 0                             # no temperament or age: the shifts below set who is ambitious
	GameData.balance["field_workers_max"] = 6  # room on the fields, so the farm places are open
	var ps := adults(w).filter(func(o): return o.job != "farmer" and o.role == "adult")
	var keen: NPC = ps[0]
	var calm: NPC = ps[1]
	var plain: NPC = ps[2]
	for n: NPC in [keen, calm, plain]:
		w.brain._change_job(n, "manor_hand", "test")
		n.left_job = ""
		n.job_since = w.day() - 30
		n.hunger = 100.0
		n.hp = n.max_hp
		n.income_days = [10, 10, 10, 10, 10]
	for o: NPC in w.npcs:
		if o.alive and o.job == "farmer":
			o.income_days = [9, 9, 9, 9, 9]          # what the farm places pay (job_market: what farmers have earned)
	keen.skills = {"farming": Skills.xp_for_level(7)}
	calm.skills = {"farming": Skills.xp_for_level(7)}
	plain.skills = {}
	for h in w.households.size():
		w.brain.evaluate_household(h, false)
	a.dawn(w)
	a.rows[keen.id].shift[A.PROFESSION] = 300            # life has made work matter to them
	a.rows[plain.id].shift[A.PROFESSION] = 300
	a.rows[calm.id].shift[A.PROFESSION] = -300           # and not to this one
	return {"w": w, "a": a, "keen": keen, "calm": calm, "plain": plain}


func test_ambitious_moves_content_stays() -> void:
	var f := career_world()
	var w: World = f.w
	var a: JudgmentAspiration = f.a
	var keen: NPC = f.keen
	var calm: NPC = f.calm
	var plain: NPC = f.plain
	for n: NPC in [keen, calm, plain]:
		w.households[n.household].econ.streak = 0      # not in need: only ambition sends anyone looking
	check(a.ambitious(keen, w) and a.ambitious(plain, w) and not a.ambitious(calm, w), "keen and plain are ambitious, calm is content")
	check(int(w.brain.job_market().farmer.open) > 0, "farm places are open (%d)" % int(w.brain.job_market().farmer.open))
	var opts := [["farmer", 9.0]]
	check(JudgmentLive.pick_job(w, keen, opts, false, 10.0, "farmer", false, {"streak": 0}) == "farmer",
			"pick_job: an ambitious manor hand with farming level 7 takes the farm place over staying")
	check(JudgmentLive.pick_job(w, plain, opts, false, 10.0, "farmer", false, {"streak": 0}) == "",
			"pick_job: an ambitious manor hand with no farming stays (no skill, no room to grow there)")
	var looks0 := int(w.judgment.stats.get("ambition_looks", 0))
	w.brain.seek_work()
	check(keen.job == "farmer", "seek_work: the ambitious, skilled villager moves to the work that suits them (now %s)" % keen.job)
	check(calm.job == "manor_hand", "seek_work: the content villager with the same skill stays (no look)")
	check(plain.job == "manor_hand", "seek_work: the ambitious villager without the skill weighs and stays")
	check(int(w.judgment.stats.get("ambition_looks", 0)) - looks0 >= 2 and int(w.judgment.stats.get("ambition_moves", 0)) >= 1, "the looks and the move are counted")
	GameData.balance["field_workers_max"] = 2
	w.dispose()


## X18-D3: no skill level promotes anyone. Off, a master manor hand never moves on skill; on, a content master stays too;
## and the weighing offers only job_market's open places: a skilled trade (smith, carpenter, tanner, cook) only when its
## work justifies one (B25-EMPLOY-IMPL; skilled_employment_test shows the places opening).
func test_no_threshold_promotion() -> void:
	for on in [false, true]:
		var f := career_world(4)
		var w: World = f.w
		var a: JudgmentAspiration = f.a
		var calm: NPC = f.calm
		calm.skills = {"farming": Skills.xp_for_level(Skills.max_level()), "smithing": Skills.xp_for_level(Skills.max_level())}
		if not on:
			a.enabled = false
		for n: NPC in [f.keen, calm, f.plain]:
			w.households[n.household].econ.streak = 0
		for d in 3:
			w.brain.seek_work()
		check(calm.job == "manor_hand", "%s: a content master of farming and smithing stays a manor hand (no promotion by level)" % ("on" if on else "off"))
		if not on:
			check((f.keen as NPC).job == "manor_hand", "off: nobody not in need looks for other work (the live rule)")
		# B25-EMPLOY-IMPL (owner B25-EMPLOY-D3): the skilled trades are in the market now, but only with the places their
		# workplaces, work and earnings justify (skilled_place); a new world has seen no work yet, so none is open to anyone
		var m: Dictionary = w.brain.job_market()
		for t in ["smith", "carpenter", "tanner", "cook", "merchant"]:
			check(m.has(t) and int(m[t].open) == 0, "%s: %s is listed and has no place open without evidence of work" % ["on" if on else "off", t])
		GameData.balance["field_workers_max"] = 2
		w.dispose()


# ---------------------------------------------------------------- determinism ---------------------
func run_once() -> String:
	var w := world(6)
	for d in 8:
		w.brain.dawn()
	var out := JSON.stringify(w.judgment.asp.to_dict()) + JSON.stringify(w.judgment.stats)
	for n: NPC in w.npcs:
		out += "%d:%s:%d;" % [n.id, n.job, n.job_since]
	w.dispose()
	return out


func test_determinism() -> void:
	var x := run_once()
	var y := run_once()
	check(x == y and x.contains("rows"), "determinism: the same seed gives the same aspirations, looks and jobs over eight mornings")


# ---------------------------------------------------------------- save and load -------------------
func test_save_load() -> void:
	var w := world(7)
	for d in 3:
		w.brain.dawn()
	var a: JudgmentAspiration = w.judgment.asp
	var ps := adults(w)
	a.rows[ps[0].id].shift[A.PROFESSION] = 250
	var wd: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	check(int(wd.judgment.version) == JudgmentStore.ASPIRE_VERSION and wd.judgment.has("aspire"), "the save carries the aspirations (judgment version 4, aspire)")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), wd)
	var b: JudgmentAspiration = w2.judgment.asp
	check(b.enabled and JudgmentLive.on(w2, "job_choice"), "a loaded world has the career ambition on")
	var same := true
	for n: NPC in ps:
		var m: NPC = w2.npc(n.id)
		same = same and m != null and a.ambitious(n, w) == b.ambitious(m, w2) and a.priority(n, A.PROFESSION, w) == b.priority(m, A.PROFESSION, w2) \
				and a.looks_today(n, w.day()) == b.looks_today(m, w2.day())
	check(same, "after loading every villager's ambition, profession priority and look day are as before")
	check(int(b.rows[ps[0].id].shift[A.PROFESSION]) == 250, "the profession shift life made is kept")
	var again := JSON.stringify(JSON.parse_string(JSON.stringify(w2.to_dict().judgment.aspire)))
	check(again == JSON.stringify(wd.judgment.aspire), "and saved again byte for byte")
	w.brain.dawn()
	w2.brain.dawn()
	var jobs := func(x: World) -> String:
		var s := ""
		for n: NPC in x.npcs:
			s += "%d:%s;" % [n.id, n.job]
		return s
	check(jobs.call(w) == jobs.call(w2), "the next morning's career decisions are the same in the saved and the loaded world")
	w2.dispose()
	w.dispose()
