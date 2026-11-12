extends SceneTree
## EMP-05 (Build 25 audit, WP-1): NPCBrain.job_market reads w.fields[0] (the farmer's place in the job market) and
## LandClearing.find_blocks guards the same read; the audit asked whether a village can ever have zero fields. Reachability:
## the game has one village map (VillageMap.load_default, main.gd), whose fields World.setup copies into w.fields; nothing in the
## game removes a field (fields are only appended, by land clearing), and a save carries them whole (World.load_dict). So zero
## fields is not reachable and no guard is added. This test is the evidence and the guard: if a later map, save or rule lets the
## field list empty or shrink, it fails here before job_market can index an empty list.
##   godot --headless --path game --script res://tests/emp05_fields_present_test.gd

const STEP := 0.5

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL: ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	GameData.ensure()
	test_fields_present()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func test_fields_present() -> void:
	var m := VillageMap.load_default()
	check(not (m.data.fields as Array).is_empty(), "the village map defines fields (%d)" % (m.data.fields as Array).size())
	var w := World.new()
	w.setup(m, 1)
	var start := w.fields.size()
	check(start == (m.data.fields as Array).size(), "a new village has every field of its map (%d)" % start)
	var market: Dictionary = w.brain.job_market()
	check(market.has("farmer") and market.farmer.at == Vector2i(int(w.fields[0].x), int(w.fields[0].y)), "the job market places the farmer's work at the first field")
	# a game day of the real world: the field list never shrinks
	var per_day := int(1440.0 / float(GameData.b("game_minutes_per_second")) / STEP)
	for s in per_day:
		w.update(STEP)
	check(w.fields.size() >= start, "after a day the village still has its fields (%d)" % w.fields.size())
	# a save and load keeps them whole
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true)))
	check(w2.fields.size() == w.fields.size(), "a saved and loaded village keeps its fields (%d of %d)" % [w2.fields.size(), w.fields.size()])
	check(not w2.fields.is_empty() and w2.brain.job_market().has("farmer"), "the loaded village's job market reads its first field")
