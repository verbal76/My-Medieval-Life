extends SceneTree
## B25-AUD-NPC-03 (audit 007): a manor hand who takes over an untended field becomes a farmer by the planner's own shortcut
## (NPCBrain._plan_job, "manor_hand"), which set n.job without the job-change bookkeeping every other change has: the
## "job_changes" statistic and the flight recorder's job_switched event (REC-19). Both are now booked, so the reports count
## every change of trade once. The behaviour is unchanged: the same hand takes the same field.
## The other half of the finding, a miner whose mine is worked out becoming a manor hand without opening a miner's post
## (_change_job without _post_left), is kept on purpose: a post at a mine with no ore left would be one nobody can work.
##   godot --headless --path game --script res://tests/npc03_field_takeover_bookkeeping_test.gd

var checks := 0
var failures := 0
var tmp_root := ""


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL: " + what)


func _init() -> void:
	GameData.ensure()
	tmp_root = OS.get_cache_dir() + "/mml_npc03_test_%d" % int(Time.get_unix_time_from_system())
	DirAccess.make_dir_recursive_absolute(tmp_root)
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var rec := WorldRecorder.attach(w, {"root": tmp_root})
	for f: NPC in w.npcs:                            # every field untended: their farmers turn woodcutters
		if f.alive and f.job == "farmer":
			w.brain._change_job(f, "woodcutter", "test")
	var n: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 0 and o.job not in ["guard", "woodcutter"]:
			n = o
			break
	w.brain._change_job(n, "manor_hand", "test")
	var field: Dictionary = w.fields[0]
	for f in w.fields:
		check(w.field_workers(f).is_empty(), "fixture: field %s is untended" % str(f.id))
		break
	var stat0 := float(w.stats.get("job_changes", 0.0))
	rec.flush()
	var ev0 := _switched(rec, n).size()
	w.brain._plan_job(n)
	check(n.job == "farmer" and n.workplace == str(field.id) and n.left_job == "manor_hand",
		"the manor hand takes over the untended field %s (%s at %s)" % [str(field.id), n.job, n.workplace])
	check(float(w.stats.get("job_changes", 0.0)) == stat0 + 1.0, "the change is counted once in job_changes (%.0f -> %.0f)" % [stat0, float(w.stats.get("job_changes", 0.0))])
	var evs := _switched(rec, n)
	check(evs.size() == ev0 + 1, "the recorder writes one job_switched event for it (%d -> %d)" % [ev0, evs.size()])
	_remove(tmp_root)
	w.dispose()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## The recorder's job_switched events whose actor is `n`.
func _switched(rec: WorldRecorder, n: NPC) -> Array:
	rec.flush()
	var ref := WorldRecorder.ref_of(n)
	return RecorderArchive.read_table(FlightRecorder._abs(rec.dir), "event").filter(func(e): return e.subtype == "job_switched" and str(e.actor) == ref)


func _remove(path: String) -> void:
	for d in DirAccess.get_directories_at(path):
		_remove(path + "/" + d)
	for f in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path + "/" + f)
	DirAccess.remove_absolute(path)
