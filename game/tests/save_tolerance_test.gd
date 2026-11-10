extends SceneTree
## ND-15 (B25-ND15-TOL-01, owner 2026-11-10, docs/directives/2026-11-10_build25_merge_decisions.md item 2): Godot's
## full-precision JSON (the game's save format, JSON.stringify(d, "", true, true)) does not round-trip every double exactly: a few
## fractional values (a villager's hunger, a position) come back one unit in the last place off. The owner accepts this only where it
## is proven harmless and exact values stay exact. Tolerances (docs/design/SAVE_NUMERIC_TOLERANCE.md):
##   - every whole number in the save (coins, item counts, prices, amounts, ids, days, minutes on the minute, contract terms,
##     household members, the random stream) must come back EXACTLY, whether stored as an int or as a whole-valued float;
##   - text and true/false must come back exactly;
##   - a fractional value may differ by at most REL_TOL of its size (REL_TOL = 1e-12; observed: about 1e-16, one unit in the last place).
## Harmlessness: the same save loaded from an exact copy and from the game's JSON goes on for two days and the two worlds then agree
## under the same rule in every part of the save (money, items, contracts, people, random stream), so the difference does not change
## what happens next.
##   godot --headless --path game --script res://tests/save_tolerance_test.gd

const REL_TOL := 1e-12

var checks := 0
var fails := 0


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		fails += 1


## Compares a candidate save (a) with the reference it should equal (b: the values as they were) leaf by leaf; a value is a whole
## number when the REFERENCE is one (an int, or a whole-valued float). Returns {exact, within (fractional values that differ inside the tolerance), bad (paths that
## break the rule), worst (largest relative difference)}.
func compare(a, b, path: String, out: Dictionary) -> void:
	if (a is Dictionary) and (b is Dictionary):
		var keys: Array = (a as Dictionary).keys()
		for k in (b as Dictionary).keys():
			if not (a as Dictionary).has(k):
				keys.append(k)
		for k in keys:
			if not (a as Dictionary).has(k) or not (b as Dictionary).has(k):
				_bad(out, "%s/%s (present in one only)" % [path, str(k)])
			else:
				compare(a[k], b[k], "%s/%s" % [path, str(k)], out)
		return
	if (a is Array) and (b is Array):
		if (a as Array).size() != (b as Array).size():
			_bad(out, "%s (length %d vs %d)" % [path, (a as Array).size(), (b as Array).size()])
			return
		for i in (a as Array).size():
			compare(a[i], b[i], "%s[%d]" % [path, i], out)
		return
	var an := typeof(a) == TYPE_INT or typeof(a) == TYPE_FLOAT
	var bn := typeof(b) == TYPE_INT or typeof(b) == TYPE_FLOAT
	if an and bn:
		var x := float(a)
		var y := float(b)
		if x == y:
			out.exact += 1
		elif typeof(b) == TYPE_INT or y == floorf(y):
			_bad(out, "%s (whole number %s vs %s)" % [path, String.num_scientific(x), String.num_scientific(y)])
		else:
			var rel := absf(x - y) / maxf(absf(x), 1.0)
			out.worst = maxf(out.worst, rel)
			if rel <= REL_TOL:
				out.within += 1
			else:
				_bad(out, "%s (%s vs %s, relative %s)" % [path, str(a), str(b), str(rel)])
		return
	if str(a) == str(b) and typeof(a) == typeof(b):
		out.exact += 1
	else:
		_bad(out, "%s (%s vs %s)" % [path, str(a).left(40), str(b).left(40)])


func _bad(out: Dictionary, what: String) -> void:
	out.bad.append(what)


func run_days(w: World, days: int) -> void:
	for m in 1440 * days:
		w.update(0.5)


func json_copy(d: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(d, "", true, true))


func result() -> Dictionary:
	return {"exact": 0, "within": 0, "bad": [], "worst": 0.0}


func _init() -> void:
	var a := World.new()
	a.setup(VillageMap.load_default(), 1)
	run_days(a, 3)
	var saved := a.to_dict()

	# 1 what a save holds comes back under the rule, read straight from the game's JSON
	var r1 := result()
	compare(json_copy(saved), saved, "", r1)
	check(r1.bad.is_empty(), "the game's JSON keeps every whole number, text and flag exactly and every fraction within %s (%d exact, %d fractional within, worst %s; breaks: %s)" % [str(REL_TOL), r1.exact, r1.within, String.num_scientific(r1.worst), str(r1.bad.slice(0, 4))])
	check(r1.within > 0, "the probe does contain fractional values that come back off in the last place (%d), so the rule is exercised" % r1.within)

	# 2 loaded into a world and saved again: the same
	var exact := World.new()
	exact.load_dict(VillageMap.load_default(), bytes_to_var(var_to_bytes(saved)))       # an exact copy (binary, every double as it was)
	var j := World.new()
	j.load_dict(VillageMap.load_default(), json_copy(saved))                             # what the game's save file gives back
	var r2 := result()
	compare(j.to_dict(), exact.to_dict(), "", r2)
	check(r2.bad.is_empty(), "loaded from the game's JSON, the world holds what the exact copy holds under the rule (%d fractional within, worst %s; breaks: %s)" % [r2.within, String.num_scientific(r2.worst), str(r2.bad.slice(0, 4))])

	# 3 harmless: both go on for two days and agree in every part of the save
	var c0 := j.total_coins()
	run_days(exact, 2)
	run_days(j, 2)
	var r3 := result()
	compare(j.to_dict(), exact.to_dict(), "", r3)
	check(r3.bad.is_empty(), "two days later the two worlds agree in every part (money, items, contracts, people, random stream) under the rule (%d exact, %d fractional within, worst %s; breaks: %s)" % [r3.exact, r3.within, String.num_scientific(r3.worst), str(r3.bad.slice(0, 4))])
	check(j.total_coins() == exact.total_coins() and j.rng.state == exact.rng.state, "money and the random stream are identical (%d coins, before %d)" % [j.total_coins(), c0])
	exact.dispose()
	j.dispose()
	a.dispose()
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)
