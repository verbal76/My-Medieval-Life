extends SceneTree
## SAV-01: an hourly food-days cache at save time must survive a load
## without one hour of mistaken famine decisions. Legacy saves recover via calculation.
var checks := 0
var failures := 0
func check(ok: bool, what: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + what)
	if not ok:
		failures += 1

func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 8222)
	# A fresh food-days measurement is taken hourly. Simulate a last-hour famine
	# reading; between hours the decision cache is deliberately not recomputed.
	w.food_days = float(GameData.b("famine_food_days")) * 0.5
	check(w.famine(), "SAV-01: saved world reports an active famine")
	var snap: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true))
	var restored := World.new()
	restored.load_dict(VillageMap.load_default(), snap.duplicate(true))
	check(restored.load_error == "", "SAV-01: save loads normally")
	check(is_equal_approx(restored.food_days, w.food_days), "SAV-01: exact last-hour food-days cache survives reload")
	check(restored.famine() == w.famine(), "SAV-01: famine decision unchanged immediately after loading")
	# Older saves have no snapshot, and should derive a meaningful current
	# value from restored inventories rather than keep the 99.0 initializer.
	var old_save := snap.duplicate(true)
	old_save.erase("food_days")
	var legacy := World.new()
	legacy.load_dict(VillageMap.load_default(), old_save)
	var expected := World.new()
	expected.load_dict(VillageMap.load_default(), old_save.duplicate(true))
	expected._update_food_days()
	check(is_equal_approx(legacy.food_days, expected.food_days), "SAV-01: old save without food_days calculates cache from stores")
	w.dispose()
	restored.dispose()
	expected.dispose()
	legacy.dispose()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
