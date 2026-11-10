extends SceneTree
## EMP-01 (Build 25 audit): a permanent employee (EMP-PERM-01) keeps the place their employer gave them. The morning labour market
## already passes them by (NPCBrain.seek_work); a trade's succession (NPCBrain._apprentice_for) must too, or the employee is put
## into the dead worker's post while their employment record stays. Fixture: the smith dies and leaves a post; the best-suited
## adult for it (the most smithing) is the player's employed labourer. After the wait, someone else takes the post; the employee's
## job and employment record are as they were.
##   godot --headless --path game --script res://tests/emp01_apprentice_employed_test.gd

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL: ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	GameData.ensure()
	test_employee_not_apprenticed()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## A home of the player's own with its chest (as business_founding_test.gd: the coins and materials given here).
func player_home(w: World) -> void:
	if w.player.home != "" and w.buildings.has(w.player.home):
		return
	var sp = w.map.data.spawns.player
	var c: Construction = w.construction
	var rect := c.find_ground("house", Vector2i(int(sp[0]), int(sp[1])), World.PLAYER)
	w.player.coins += w.property.land_price(rect.size.x, rect.size.y)
	var p: Dictionary = c.place("house", rect, World.PLAYER)
	for id in p.site.need.duplicate():
		w.player.inv.add(id, int(p.site.need[id]))
	w.deliver(p, w.player.inv)
	w.property.set_home(str(p.building))


func test_employee_not_apprenticed() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.judgment.cfg.decision.integration.work_accept = false      # the villager's own yes is JudgmentLive's test; here the terms
	var b: NPCBrain = w.brain
	var smith: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job == "smith":
			smith = o
			break
	check(smith != null, "fixture: a smith")
	player_home(w)
	w.player.coins += 500
	var emp: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 0 and o.household != smith.household and o.job in ["", "laborer", "manor_hand"] \
				and w.employment.refusal(o, "builder") == "":
			emp = o
			break
	check(emp != null, "fixture: an adult the player can employ")
	if smith == null or emp == null:
		return
	check(w.employment.employ(emp, "builder") == "", "fixture: the player employs them as a labourer")
	var rec: Dictionary = w.employment.record_of(emp).duplicate(true)
	check(emp.job == "laborer" and not rec.is_empty(), "fixture: their job is labouring for the player (%s)" % emp.job)
	# the most suitable for a smith's post: by far the most smithing in the village
	emp.skills["smithing"] = Skills.xp_for_level(10)
	var key := World.npc_ref(emp.id)
	if not w.experience.minutes.has(key):
		w.experience.minutes[key] = {}
	w.experience.minutes[key]["smithing"] = 480.0 * 600.0
	w.kill(smith, "old age")
	var v: Dictionary = {}
	for x in w.vacancies:
		if str(x.job) == "smith":
			v = x
	if v.is_empty():                   # the trade's staffing left no post open: open the dead smith's own (as _open_vacancy does)
		v = {"job": "smith", "workplace": smith.workplace, "home": smith.home, "household": smith.household, "day": w.day(),
				"who": "%s %s" % [smith.name, smith.family], "left_by": -1}
		w.vacancies.append(v)
	check(not v.is_empty(), "fixture: the smith's post is open")
	var pick: NPC = b._apprentice_for(v)
	check(pick != emp, "the succession does not choose the permanent employee (%s)" % (pick.name if pick != null else "nobody"))
	w.minutes += float(int(GameData.b("succession_days"))) * 1440.0
	b.succession_dawn()
	var heir: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.job == "smith" and o != smith:
			heir = o
	check(emp.job == "laborer", "the employee's job is unchanged (%s)" % emp.job)
	check(w.employment.record_of(emp) == rec, "and their employment record is unchanged")
	check(heir == null or heir != emp, "someone else, or nobody yet, takes the smith's post (%s)" % (heir.name if heir != null else "nobody"))
