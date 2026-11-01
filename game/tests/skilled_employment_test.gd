extends SceneTree
## B25-EMPLOY-IMPL and the hiring part of B25-CAREER-IMPL (owner B25-EMPLOY-D3, B25-CAREER-D1, 2026-11-01,
## docs/directives/2026-11-01_career_business_employment_final_decisions.md Decisions 1 and 3, sections 4 and 6): skilled
## trades hire by their workplaces' room, the work there and what the trade earns, with no fixed headcount; the employer
## weighs the candidates' skill and experience; retraining from another trade; no promotion by a level (X18-D3). Shows:
## the work done at a station is recorded; no fixed cap (a trade grows past its starting strength when the signals hold);
## no growth without work, room or earnings, and nobody dismissed when they go; a merchant's place needs a vacant stall; a
## skilled candidate preferred to an unskilled one (a new place and a vacancy); an unskilled willing candidate taken when
## nobody skilled wants it; retraining from another trade; no threshold promotion; determinism; save and load. Run headless:
##   godot --headless --path game --script res://tests/skilled_employment_test.gd

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
	test_station_record()
	test_no_fixed_cap()
	test_no_growth_without_signals()
	test_merchant_place()
	test_skilled_preferred()
	test_unskilled_when_nobody_skilled()
	test_retraining()
	test_no_threshold_promotion()
	test_shipped_weighing()
	test_determinism()
	test_save_load()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func world(seed := 1, live := true) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	if live:
		live_rule(w)
	return w


## The live job rule without the career weighing (job_choice off): these tests set who looks for work themselves.
## test_shipped_weighing runs the shipped switches.
func live_rule(w: World) -> void:
	if w.judgment != null:
		w.judgment.cfg.decision.integration.job_choice = false


func of_job(w: World, job: String) -> Array:
	return w.npcs.filter(func(o: NPC) -> bool: return o.alive and o.role == "adult" and o.job == job)


## The forge's and the anvil's last window_days days: `forge` and `anvil` minutes a day by smiths (and `other` minutes a
## day at the forge by someone else), as the work there would have recorded them.
func smithy_load(w: World, forge: float, anvil: float, other := 0.0) -> void:
	var f: String = w.stations_of("forge")[0]
	var a: String = w.stations_of("anvil")[0]
	var past := []
	for i in int(GameData.b("skilled_places").window_days):
		var day := {f: {"smith": forge}, a: {"smith": anvil}}
		if other > 0.0:
			day[f]["tanner"] = other
		past.append(day)
	w.station_load = {"day": w.day(), "today": {}, "past": past}


## Every smith settled in the trade and earning `pay` a day; every household's position known.
func smiths_earn(w: World, pay: int) -> void:
	for o: NPC in of_job(w, "smith"):
		o.income_days = [pay, pay, pay, pay, pay]
		o.left_job = ""
		o.job_since = w.day() - 30
	for h in w.households.size():
		w.brain.evaluate_household(h, false)


## An adult out of work, free to take a place (not a guard or an official), with no skills and no earnings yet.
func idle_adult(w: World, skip := []) -> NPC:
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 3 and o.job in ["miner", "woodcutter", "farmer"] and not skip.has(o):
			w.brain._change_job(o, "", "test")
			o.left_job = ""
			o.skills = {}
			o.income_days = []
			o.hunger = 100.0
			return o
	return null


# ---------------------------------------------------------------- the record -----------------------
func test_station_record() -> void:
	var w := world()
	var s: NPC = of_job(w, "smith")[0]
	var f: String = w.stations_of("forge")[0]
	w._note_work(s, {"act": "craft", "args": {"recipe": "smelt_iron", "station": f}}, 30.0)
	w._note_work(s, {"act": "craft", "args": {"recipe": "smelt_iron", "station": f}}, 15.0)
	check(is_equal_approx(float(w.station_load.today[f].smith), 45.0), "the work done at the forge is recorded by trade (45 minutes)")
	check(w.brain.station_minutes(f) == 0.0, "today's work is not yet a past day")
	w.minutes += 1440.0
	check(is_equal_approx(w.brain.station_minutes(f, "smith"), 45.0) and is_equal_approx(w.brain.station_minutes(f, "tanner"), 0.0), "a day later: 45 minutes a day by smiths, none by tanners")
	w.minutes += 1440.0 * 10
	check(w.brain.station_minutes(f) == 0.0 and (w.station_load.past as Array).size() == int(GameData.b("skilled_places").window_days),
			"days without work count as empty days, and only window_days days are kept")
	w.dispose()


# ---------------------------------------------------------------- no fixed cap --------------------
func test_no_fixed_cap() -> void:
	var w := world()
	var b: NPCBrain = w.brain
	var start := NPCBrain.staff_target("smith")
	check(of_job(w, "smith").size() == start, "the village starts with %d smiths" % start)
	smithy_load(w, 500.0, 300.0)
	smiths_earn(w, 40)
	var m: Dictionary = b.skilled_place("smith")
	check(bool(m.room) and bool(m.work) and bool(m.afford) and int(m.open) == 1, "with work, room and earnings to share, a smith's place opens (room %s, work %s, afford %s)" % [m.room, m.work, m.afford])
	check(is_equal_approx(float(m.pay), 80.0 / 3.0), "offered at the trade's earnings shared with one more (%.1f)" % float(m.pay))
	check(b.job_market().smith.open == 1 and str(b.job_market().smith.place) == w.stations_of("anvil")[0], "listed in the labour market, at the station with the most free time")
	var first := idle_adult(w)
	b.seek_work()
	check(first.job == "smith" and of_job(w, "smith").size() == start + 1, "a villager out of work takes it: %d smiths, above the starting %d" % [of_job(w, "smith").size(), start])
	check(first.workplace == w.stations_of("anvil")[0], "working at the smithy's station with room")
	check(int(b.skilled_place("smith").open) == 0, "the new hand is new to the trade: no further place until they have settled in")
	smiths_earn(w, 40)
	check(int(b.skilled_place("smith").open) == 1, "settled in, with the smithy still busy and earning, another place opens")
	var second := idle_adult(w, [first])
	b.seek_work()
	check(second.job == "smith" and of_job(w, "smith").size() == start + 2, "and the trade grows again: %d smiths (no fixed cap)" % of_job(w, "smith").size())
	check(float(w.stats.get("skilled_hires_smith", 0)) == 2.0, "both hires are counted")
	w.dispose()


# ---------------------------------------------------------------- no growth without the signals ---
func test_no_growth_without_signals() -> void:
	var w := world()
	var b: NPCBrain = w.brain
	smiths_earn(w, 40)
	smithy_load(w, 60.0, 30.0)
	var m: Dictionary = b.skilled_place("smith")
	check(not bool(m.work) and int(m.open) == 0, "no work: smiths idle most of the day waiting for materials open no place")
	smithy_load(w, 660.0, 660.0)
	m = b.skilled_place("smith")
	check(bool(m.work) and not bool(m.room) and int(m.open) == 0, "no room: the forge and the anvil are busy all day, so no place")
	smithy_load(w, 500.0, 300.0, 160.0)
	m = b.skilled_place("smith")
	check(bool(m.work) and not bool(m.room) and int(m.open) == 0, "the room is the workplace's: a tanner's hours at the forge count against it")
	smithy_load(w, 500.0, 300.0)
	smiths_earn(w, 1)
	m = b.skilled_place("smith")
	check(bool(m.room) and bool(m.work) and not bool(m.afford) and int(m.open) == 0, "earnings that would not keep another worker: no place")
	w.station_load = {}
	smiths_earn(w, 40)
	check(int(b.skilled_place("smith").open) == 0, "nothing recorded yet: no evidence of work, no place")
	# a struggling trade stops hiring; nobody is dismissed
	var idle := idle_adult(w)
	smithy_load(w, 60.0, 30.0)
	var n0 := of_job(w, "smith").size()
	for d in 3:
		b.seek_work()
	check(of_job(w, "smith").size() == n0 and idle.job != "smith", "with no work at the forge the smiths keep their trade and nobody new is taken on")
	# below the starting strength the post is succession's, not the market's
	smithy_load(w, 500.0, 300.0)
	var dead: NPC = of_job(w, "smith")[0]
	w.kill(dead, "fever")
	check(b.open_posts("smith") == 1 and int(b.skilled_place("smith").open) == 0, "a smith's death opens a succession post (B8-016 kept), not a market place")
	w.dispose()


# ---------------------------------------------------------------- merchants -----------------------
func test_merchant_place() -> void:
	var w := world()
	var b: NPCBrain = w.brain
	for o: NPC in of_job(w, "merchant"):
		o.income_days = [30, 30, 30, 30, 30]
		o.job_since = w.day() - 30
		o.coins = 400
	for h in w.households.size():
		b.evaluate_household(h, false)
	var m: Dictionary = b.skilled_place("merchant")
	check(not bool(m.room) and int(m.open) == 0, "every merchants' stall is let: no place (the stalls are the workplace)")
	var s: Dictionary = (w.stalls.stall0 as Dictionary).duplicate(true)
	s.id = "stall9"
	w.set_tenant(s, "")
	w.stalls["stall9"] = s
	m = b.skilled_place("merchant")
	check(bool(m.room) and bool(m.work) and bool(m.afford) and int(m.open) == 1 and str(m.place) == "stall9", "a vacant stall, traders able to buy and earnings to share: a merchant's place at it")
	(of_job(w, "merchant")[0] as NPC).coins = 0
	check(int(b.skilled_place("merchant").open) == 0, "a merchant unable to buy stock: no place")
	(of_job(w, "merchant")[0] as NPC).coins = 400
	var poor := idle_adult(w)
	poor.coins = 0
	b.seek_work()
	check(poor.job != "merchant", "one without the coins to stock a stall is not offered it")
	if poor.job != "":
		b._change_job(poor, "", "test")
		poor.left_job = ""
	poor.coins = int(GameData.b("stall_min_coins")) + 40
	w.brain.evaluate_household(poor.household, false)
	b.seek_work()
	check(poor.job == "merchant" and poor.workplace == "stall9" and w.tenant_of(w.stalls.stall9) == World.npc_ref(poor.id), "with the coins, they take the vacant stall")
	w.dispose()


# ---------------------------------------------------------------- the employer's choice -----------
func test_skilled_preferred() -> void:
	var w := world()
	var b: NPCBrain = w.brain
	smithy_load(w, 500.0, 300.0)
	smiths_earn(w, 40)
	var plain := idle_adult(w)
	var able := idle_adult(w, [plain])
	able.skills = {"smithing": Skills.xp_for_level(5)}
	var m := b.job_market()
	b._hire_skilled([{"n": plain, "job": "smith", "why": "out of work", "unemployed": true, "econ": {}, "looker": false},
			{"n": able, "job": "smith", "why": "out of work", "unemployed": true, "econ": {}, "looker": false}], m, false)
	check(able.job == "smith" and plain.job != "smith", "the trade takes the one with smithing 5 over the one with none")
	check(plain.job != "" or int(m.manor_hand.open) <= 0, "the one not taken chooses again among the other places (now %s)" % (plain.job if plain.job != "" else "none"))
	# the same through the morning's own search: both apply, the skilled one is taken
	var w2 := world(2)
	smithy_load(w2, 500.0, 300.0)
	smiths_earn(w2, 40)
	var p2 := idle_adult(w2)
	var a2 := idle_adult(w2, [p2])
	a2.skills = {"smithing": Skills.xp_for_level(4)}
	w2.brain.seek_work()
	check(a2.job == "smith" and p2.job != "smith", "seek_work: of two applicants the skilled one is hired (%s, %s)" % [a2.job, p2.job])
	w2.dispose()
	# experience in the trade's industry breaks a tie of skill
	var w3 := world(3)
	smithy_load(w3, 500.0, 300.0)
	smiths_earn(w3, 40)
	var x := idle_adult(w3)
	var y := idle_adult(w3, [x])
	w3.experience.credit(World.npc_ref(maxi(x.id, y.id)), "smithing", 480.0 * 4, w3.minutes)
	var m3: Dictionary = w3.brain.job_market()
	w3.brain._hire_skilled([{"n": x, "job": "smith", "why": "t", "unemployed": true, "econ": {}, "looker": false},
			{"n": y, "job": "smith", "why": "t", "unemployed": true, "econ": {}, "looker": false}], m3, false)
	var exp_one: NPC = x if x.id > y.id else y
	check(exp_one.job == "smith", "at the same skill, the one with days worked at a forge is taken")
	w3.dispose()
	# a vacancy (succession) too: the skilled adult before the dead smith's own household
	var dead: NPC = of_job(w, "smith")[0]
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and NPCBrain.APPRENTICE_FROM.has(o.job):
			o.job = "farmer"
			o.workplace = w.fields[0].id
	var kin := idle_adult(w)
	kin.household = dead.household
	var skilled := idle_adult(w, [kin])
	skilled.skills = {"smithing": Skills.xp_for_level(3)}
	var v := {"job": "smith", "household": dead.household, "workplace": dead.workplace, "home": dead.home, "day": 0, "who": "x"}
	check(b._apprentice_for(v) == skilled, "succession: the skilled adult is taken before the late smith's unskilled kin")
	skilled.skills = {}
	check(b._apprentice_for(v) == kin, "at equal (no) skill the old order holds: the late smith's household first")
	w.dispose()


func test_unskilled_when_nobody_skilled() -> void:
	var w := world()
	smithy_load(w, 500.0, 300.0)
	smiths_earn(w, 40)
	var lad := idle_adult(w)
	w.brain.seek_work()
	check(lad.job == "smith" and int(lad.skills.get("smithing", 0)) == 0, "nobody skilled applied: the willing unskilled villager is taken on")
	check(float(w.stats.get("skilled_hires_untrained", 0)) == 1.0, "counted as an apprentice who learns at the work")
	var xp0 := int(lad.skills.get("smithing", 0))
	lad.inv.add("iron_ore", 2)
	lad.inv.add("coal", 1)
	w.brain._plan_job(lad)
	var step: Dictionary = lad.plan[-1] if not lad.plan.is_empty() else {}
	check(str(step.get("act", "")) == "craft", "the new smith works the forge's recipes (%s)" % str(step.get("act", "")))
	w.dispose()


# ---------------------------------------------------------------- retraining ----------------------
func test_retraining() -> void:
	var w := world()
	var b: NPCBrain = w.brain
	smiths_earn(w, 40)
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and NPCBrain.APPRENTICE_FROM.has(o.job):
			o.job = "farmer"                        # nobody without a trade
			o.workplace = w.fields[0].id
	var miner: NPC = of_job(w, "miner")[0]
	miner.income_days = [2, 2, 2, 2, 2]
	miner.job_since = w.day() - 30
	var dead: NPC = of_job(w, "smith")[0]
	w.kill(dead, "fever")
	var v: Dictionary = w.vacancies.filter(func(x): return x.job == "smith")[0]
	check(b._apprentice_for(v) == miner, "a miner earning 2 a day would move to the smith's post (the job-switch rule): a candidate")
	var n0 := w.npcs.size()
	w.minutes += 1440.0 * int(GameData.b("succession_days"))
	b.succession_dawn()
	check(miner.job == "smith" and w.npcs.size() == n0, "the miner retrains as the smith; no newcomer is needed")
	check(miner.left_job == "miner", "their old trade is recorded")
	var w2 := world()
	smiths_earn(w2, 40)
	var well: NPC = of_job(w2, "miner")[0]
	well.income_days = [60, 60, 60, 60, 60]
	well.job_since = w2.day() - 30
	check(not w2.brain._would_retrain(well, "smith"), "a miner earning more than the smiths would not")
	var fresh: NPC = of_job(w2, "miner")[1]
	fresh.income_days = [2, 2]
	check(not w2.brain._would_retrain(fresh, "smith"), "nor one with too few days' earnings to judge by")
	var guard: NPC = of_job(w2, "guard")[0]
	guard.income_days = [1, 1, 1, 1, 1]
	check(not w2.brain._would_retrain(guard, "smith"), "nor a guard (an appointed post)")
	# through the open market: a needy worker of another trade applies and is taken
	var w3 := world(4)
	smithy_load(w3, 500.0, 300.0)
	smiths_earn(w3, 40)
	var cutter: NPC = of_job(w3, "woodcutter")[0]
	cutter.income_days = [1, 1, 1, 1, 1]
	cutter.job_since = w3.day() - 30
	w3.brain.evaluate_household(cutter.household, false)
	w3.households[cutter.household].econ.streak = int(GameData.b("mobility_unsustainable_days"))
	w3.households[cutter.household].econ.cost = 50.0
	w3.brain.seek_work()
	check(cutter.job == "smith" and float(w3.stats.get("skilled_hires_retrained", 0)) == 1.0, "a woodcutter whose household cannot live on it retrains as a smith (%s)" % cutter.job)
	w3.dispose()
	w2.dispose()
	w.dispose()


# ---------------------------------------------------------------- no promotion --------------------
func test_no_threshold_promotion() -> void:
	var w := world()
	var b: NPCBrain = w.brain
	smithy_load(w, 500.0, 300.0)
	smiths_earn(w, 40)
	var master: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job == "miner":
			master = o
			break
	master.skills = {"smithing": Skills.xp_for_level(Skills.max_level())}
	master.income_days = [8, 8, 8, 8, 8]
	master.job_since = w.day() - 30
	for h in w.households.size():
		b.evaluate_household(h, false)
	w.households[master.household].econ.streak = 0
	for d in 3:
		b.seek_work()
	check(master.job == "miner", "a master of smithing who is not looking for work stays a miner: a level moves nobody (X18-D3)")
	var smith: NPC = of_job(w, "smith")[0]
	smith.skills = {"smithing": Skills.xp_for_level(Skills.max_level())}
	b.seek_work()
	check(smith.job == "smith", "and a smith reaching the top level is still a smith, nothing more")
	w.dispose()


# ---------------------------------------------------------------- the shipped career weighing -----
## With the shipped switches (B25-AMBITION-D4: job_choice on) the skilled places are among the options the career weighing
## sees: an ambitious miner with smithing skill, not in need, looks on their look day and takes the smith's place; a
## content one with the same skill stays.
func test_shipped_weighing() -> void:
	var w := world(5, false)
	check(JudgmentLive.on(w, "job_choice"), "the shipped switches: the career weighing is on")
	w.judgment.cfg.decision.trait_spread_permille = 0
	w.judgment.cfg.decision.selection = "argmax"
	var a: JudgmentAspiration = w.judgment.asp
	a.c.job.look_days = 1
	for k in ["priority_spread", "young_step", "old_step", "old_profession_step"]:
		a.c[k] = 0
	smithy_load(w, 500.0, 300.0)
	var miners := of_job(w, "miner")
	var keen: NPC = miners[0]
	var calm: NPC = miners[1]
	for n: NPC in [keen, calm]:
		n.skills = {"smithing": Skills.xp_for_level(6)}
		n.income_days = [8, 8, 8, 8, 8]
		n.job_since = w.day() - 30
		n.hunger = 100.0
	smiths_earn(w, 40)
	a.dawn(w)
	a.rows[keen.id].shift[JudgmentAspiration.PROFESSION] = 300
	a.rows[calm.id].shift[JudgmentAspiration.PROFESSION] = -300
	for n: NPC in [keen, calm]:
		w.households[n.household].econ.streak = 0
	check(a.ambitious(keen, w) and not a.ambitious(calm, w), "one is ambitious, the other content")
	w.brain.seek_work()
	check(keen.job == "smith", "the ambitious miner with smithing 6 takes the smith's place (now %s)" % keen.job)
	check(calm.job == "miner", "the content one stays a miner: staying is a choice")
	w.dispose()


# ---------------------------------------------------------------- determinism ---------------------
func run_once() -> String:
	var w := world(6)
	smithy_load(w, 500.0, 300.0)
	smiths_earn(w, 40)
	idle_adult(w)
	var out := ""
	for d in 4:
		w.brain.seek_work()
		w.minutes += 1440.0
		smiths_earn(w, 40)
		for o: NPC in w.npcs:
			out += "%d:%s:%s;" % [o.id, o.job, o.workplace]
	out += JSON.stringify(w.station_load) + JSON.stringify(w.brain.job_market().smith)
	w.dispose()
	return out


func test_determinism() -> void:
	var x := run_once()
	var y := run_once()
	check(x == y and x.contains("smith"), "determinism: the same seed gives the same places and hires")


# ---------------------------------------------------------------- save and load -------------------
func test_save_load() -> void:
	var w := world(7)
	smithy_load(w, 500.0, 300.0)
	smiths_earn(w, 40)
	var s: NPC = of_job(w, "smith")[0]
	w._note_work(s, {"act": "craft", "args": {"recipe": "smelt_iron", "station": w.stations_of("forge")[0]}}, 20.0)
	var wd: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	check(wd.has("station_load") and int(wd.save_version) == World.SAVE_VERSION, "the save carries the workplaces' record (save_version %d unchanged)" % int(wd.save_version))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), wd)
	live_rule(w2)
	var p1: Dictionary = w.brain.skilled_place("smith")
	var p2: Dictionary = w2.brain.skilled_place("smith")
	check(JSON.stringify(p1) == JSON.stringify(p2) and int(p2.open) == 1, "a loaded world offers the same smith's place")
	check(is_equal_approx(float(w2.station_load.today[w.stations_of("forge")[0]].smith), 20.0), "today's work at the forge is kept")
	var old := wd.duplicate(true)
	old.erase("station_load")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), old)
	live_rule(w3)
	check(w3.station_load.is_empty() and int(w3.brain.skilled_place("smith").open) == 0, "a save from before it loads with an empty record: no place until work is seen")
	idle_adult(w)
	idle_adult(w2)
	w.brain.seek_work()
	w2.brain.seek_work()
	var jobs := func(x: World) -> String:
		var t := ""
		for n: NPC in x.npcs:
			t += "%d:%s;" % [n.id, n.job]
		return t
	check(jobs.call(w) == jobs.call(w2), "the next morning's hiring is the same in the saved and the loaded world")
	w3.dispose()
	w2.dispose()
	w.dispose()
