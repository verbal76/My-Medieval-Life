extends SceneTree
## LIFE-03: dying or retiring sage gets a delayed, qualified successor.
var checks := 0
var failed := 0
func check(ok: bool, note: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + note)
	if not ok:
		failed += 1
func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 8753)
	var sage: NPC = w.npc(w.sage_id)
	check(sage != null and sage.alive and sage.job == "sage","LIFE-03: the village begins with an active sage")
	var candidate: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n != sage and n.household >= 3 and candidate == null:
			candidate = n
	check(candidate != null,"LIFE-03: qualified local candidate can be trained")
	if candidate == null:
		quit(1)
		return
	# Test-only: prepare an otherwise available adult with real healing training.
	candidate.job = ""
	candidate.skills["healing"] = Skills.xp_for_level(2)
	for n: NPC in w.npcs:
		if n != candidate and n.alive and n.job in NPCBrain.APPRENTICE_FROM:
			n.skills["healing"] = 0
	var old_id := sage.id
	w.kill(sage,"old age")
	check(not sage.alive,"LIFE-03: original sage died")
	var vacancies: Array = w.vacancies.filter(func(v): return str(v.job) == "sage")
	check(vacancies.size() == 1,"LIFE-03: sage's death opens a vacancy")
	check(w.sage_id == old_id,"LIFE-03: no instant replacement on death")
	w.minutes += float(GameData.b("succession_days")) * 1440.0
	w.brain.succession_dawn()
	check(w.sage_id == candidate.id and candidate.job == "sage","LIFE-03: trained candidate succeeds after normal delay")
	check(candidate.workplace == "hut","LIFE-03: successor assumes apothecary workplace")
	check(w.vacancies.filter(func(v): return str(v.job) == "sage").is_empty(),"LIFE-03: sage vacancy closes exactly once")
	check(w.npc(w.sage_id).alive,"LIFE-03: current sage reference is a living NPC")
	print("%d checks, %d failures" % [checks,failed])
	quit(1 if failed > 0 else 0)
