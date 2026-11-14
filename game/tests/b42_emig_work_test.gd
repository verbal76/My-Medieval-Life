extends SceneTree
## B42-Q-EMIG-WORK (owner 2026-11-14): "Judge per person: an adult with no job and no earnings for about a week may leave for work,
## whatever the household's food. Keep the spouse rule. Measured in the Build 42 campaign." Agent H's finding: Migration._work_out took
## an adult with no trade only from a household whose econ.streak reached mobility_unsustainable_days, which the chapel's alms keep
## resetting (chain 12 seed 2 day 300: 69 unemployed, 3 departures for work). Now: no job and nothing earned for
## emigrate_work_idle_days (7) days, per person; the spouse rule (B25-EMIG-MARRIAGE-D1) kept; the emigrant walks (REG-05).
## FAILING FIRST before the change (a fed household's long-idle adult stays). Pure World. Run headless:
##   godot --headless --path game --script res://tests/b42_emig_work_test.gd

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL: ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	GameData.ensure()
	Migration.enabled = false                    # no caravan-day moves of its own: the test calls the rule
	test_idle_adult_leaves()
	test_not_idle_stays()
	test_spouse_rule()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## Migration.long_idle, called by name so this test loads before the rule exists (failing first).
func _idle(w: World, o: NPC) -> bool:
	var mig: Variant = Migration
	return mig.has_method("long_idle") and bool(mig.call("long_idle", w, o))


func _closed_market() -> Dictionary:
	var m := {}
	for j in ["manor_hand", "farmer", "woodcutter", "hunter", "miner", "prospector", "tailor", "barber", "preacher", "church_assistant"]:
		m[j] = {"pay": 9.0, "open": 0, "tool": "", "at": Vector2i.ZERO}
	return m


## A world, a settlement whose farm pays well, and a fed household's unpartnered adult made long idle. [w, s, who, h]
func _fixture() -> Array:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.minutes = 12.0 * 1440.0 + 7.0 * 60.0
	w.regions.step_day(w.day())
	var s: OffMapSettlement = w.regions.by_id["higham"]
	s.biz.farm.rate = 12.0
	for o: NPC in w.npcs:                         # nobody else is long idle (so the rule's pick is this test's adult)
		o.income_days = [1, 1, 1, 1, 1, 1, 1]
	var who: NPC = null
	var h := -1
	for hh in range(3, w.households.size()):
		for o: NPC in w.brain._members(hh):
			if who == null and o.role == "adult" and not Life.has_partner(w, o) and not Migration._barred(w, o) and Life._may_move(w, o):
				who = o
				h = hh
	who.job = ""
	who.job_since = w.day() - 10
	who.income_days = [0, 0, 0, 0, 0, 0, 0]
	w.households[h].pantry.add("bread", 60)       # a fed household
	w.households[h].econ = {"streak": 0}          # living on its income: the old rule sent nobody
	w.treasury = maxi(w.treasury, 100000)
	return [w, s, who, h]


func test_idle_adult_leaves() -> void:
	var f := _fixture()
	var w: World = f[0]
	var s: OffMapSettlement = f[1]
	var who: NPC = f[2]
	check(w.brain.household_food_days(int(f[3])) > 0.0, "fixture: the household has food (%.1f days)" % w.brain.household_food_days(int(f[3])))
	check(_idle(w, who), "an adult with no job and nothing earned for 7 days is long idle")
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var who2: NPC = w2.npc(who.id)
	check(who2 != null and _idle(w2, who2), "still long idle after a save and load (job_since and income_days are saved)")
	check(Migration._work_out(w, s, _closed_market()), "a fed household's long-idle adult leaves for work")
	check(who.alive and Journeys.active(who) and str(who.journey.purpose.get("kind", "")) == "migrate" and str(who.journey.purpose.get("reason", "")) == "work",
		"and walks there as a migrant (REG-05)")
	var open := _closed_market()
	open.farmer.open = 1
	var g := _fixture()
	check(not Migration._work_out(g[0], g[1], open), "nobody leaves while the village has a place open")


func test_not_idle_stays() -> void:
	var f := _fixture()
	var who: NPC = f[2]
	who.income_days = [0, 0, 0, 0, 0, 0, 3]
	check(not Migration._work_out(f[0], f[1], _closed_market()), "an adult who earned in the last week stays")
	var g := _fixture()
	var w2: NPC = g[2]
	w2.job = "laborer"
	check(not Migration._work_out(g[0], g[1], _closed_market()), "an adult with a job stays")
	var k := _fixture()
	var w3: NPC = k[2]
	w3.job_since = (k[0] as World).day() - 3
	check(not Migration._work_out(k[0], k[1], _closed_market()), "an adult out of work for only 3 days stays")
	var m := _fixture()
	var w4: NPC = m[2]
	w4.income_days = [0, 0, 0]
	check(not Migration._work_out(m[0], m[1], _closed_market()), "an adult with under a week of record is not judged yet")


func test_spouse_rule() -> void:
	var f := _fixture()
	var w: World = f[0]
	var who: NPC = f[2]
	var p: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o != who and o.sex != who.sex and not Life.has_partner(w, o) and not Migration._barred(w, o) and Life._may_move(w, o):
			p = o
			break
	Life._link_partners(who, p)
	p.job = "guard"                               # an office: the spouse cannot relocate
	check(not Migration._work_out(w, f[1], _closed_market()), "a married adult whose spouse cannot go stays (B25-EMIG-MARRIAGE-D1)")
	p.job = "laborer"
	check(Migration._work_out(w, f[1], _closed_market()), "with a spouse who can go, they leave together")
	check(Journeys.active(who) and Journeys.active(p) and str(p.journey.purpose.get("party", "")) == str(who.journey.purpose.get("party", "")), "both walk as one party")
