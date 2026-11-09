extends SceneTree
## EMP-03 (owner 2026-11-08, docs/directives/2026-11-09_overnight_autonomous_development.md): "Count everyone actively seeking
## work for hiring-competition purposes." An ambitious employed villager who looks for better work on their look day is
## actively seeking work and is counted among the morning's seekers (NPCBrain.seek_work -> _hiring_competition), as those out
## of work or in need already are. Two identical worlds differ only in whether two manor hands are ambitious: the seeker
## count must differ by exactly those two. Run headless:
##   godot --headless --path game --script res://tests/emp03_seeker_count_test.gd

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
	var keen := morning(300)
	var calm := morning(-300)
	check(keen.looks == 2, "fixture: the two ambitious manor hands look for better work this morning (%d looks)" % keen.looks)
	check(calm.looks == 0, "fixture: content manor hands do not look (%d looks)" % calm.looks)
	check(keen.seekers - calm.seekers == 2,
			"both ambitious lookers are counted as seeking work for the hiring competition (seekers %d vs %d)" % [keen.seekers, calm.seekers])
	check(keen.seekers >= 2, "the count includes them (%d)" % keen.seekers)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## One morning of seek_work in a fixed world: two skilled manor hands not in need, with `shift` set on the profession aspiration
## (+300 ambitious, -300 content). Returns {seekers, looks}.
func morning(shift: int) -> Dictionary:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.judgment.cfg.decision.trait_spread_permille = 0
	w.judgment.cfg.decision.selection = "argmax"
	var a: JudgmentAspiration = w.judgment.asp
	a.c.job.look_days = 1
	for k in ["priority_spread", "young_step", "old_step", "old_profession_step"]:
		a.c[k] = 0
	var ps := w.npcs.filter(func(o: NPC) -> bool: return o.alive and o.role == "adult" and o.household >= 0 and o.job not in ["guard", "farmer"])
	var pair := [ps[0], ps[1]]
	for n: NPC in pair:
		w.brain._change_job(n, "manor_hand", "test")
		n.left_job = ""
		n.job_since = w.day() - 30
		n.hunger = 100.0
		n.hp = n.max_hp
		n.income_days = [10, 10, 10, 10, 10]
		n.skills = {"farming": Skills.xp_for_level(7)}
	for h in w.households.size():
		w.brain.evaluate_household(h, false)
	for n: NPC in pair:
		w.households[n.household].econ.streak = 0          # not in need: only ambition sends them looking
	a.dawn(w)
	for n: NPC in pair:
		a.rows[n.id].shift[A.PROFESSION] = shift
	var looks0 := int(w.judgment.stats.get("ambition_looks", 0))
	w.brain.seek_work()
	var out := {"seekers": w.brain.seekers_today, "looks": int(w.judgment.stats.get("ambition_looks", 0)) - looks0}
	w.dispose()
	return out
