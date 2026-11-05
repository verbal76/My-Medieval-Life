extends SceneTree
## B25R1-022 (owner 2026-11-04): Szadi's Fantasy Lands houses as the southern region's house style and the towns' elite houses.
##   styles      every home of a place whose layout plan names a house_style is drawn in it; a town with elite_style has its
##               manors as the great house and some homes of its better quarter styled; no other place has a styled house
##   footprint   a style stamp keeps its slot's layout stamp's size and door (the settlement's layout is unchanged)
##   collision   on the base only: nothing below the door's row is solid; the door is open, the way in reaches the rooms
##   roof        the doorway and the rooms are the building's inside (Overworld.site_inside_at), the roof over them lifts
##   determinism the same seed gives the same styles
## Pure Overworld. Run headless:
##   godot --headless --path game --script res://tests/fl_houses_test.gd

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
	var a := _one(1)
	var b := _styles(Overworld.create(1, VillageMap.load_default()))
	check(a == b, "seed 1 twice: the same %d styled houses" % a.size())
	_one(2)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _styles(o: Overworld) -> Array:
	var out := []
	for st in o.sites:
		for k in st.slots.size():
			if st.slots[k].has("style"):
				out.append([str(st.id), k, str(st.slots[k].style)])
	return out


func _one(seed_value: int) -> Array:
	var o := Overworld.create(seed_value, VillageMap.load_default())
	check(not o.styles.is_empty() and o.stamps.has("fl_hall@manor"), "seed %d: the style stamps are loaded" % seed_value)
	var plans := {}
	for s in RegionGeo.data().settlements:
		plans[str(s.id)] = s.get("plan", {})
	for st in o.sites:
		var plan: Dictionary = plans.get(str(st.id), {})
		var regional := str(plan.get("house_style", "")) != ""
		var elite := str(plan.get("elite_style", "")) != ""
		var homes := 0
		var styled := 0
		var manors := 0
		var halls := 0
		var ok := true
		var bad := ""
		for sl in st.slots:
			if str(sl.kind) == "home":
				homes += 1
				if str(sl.stamp) == "manor":
					manors += 1
					if str(sl.get("style", "")).begins_with("fl_hall"):
						halls += 1
			if not sl.has("style"):
				continue
			styled += 1
			var why := _house_ok(o, sl)
			if why != "":
				ok = false
				bad = why
		if regional:
			check(styled == homes and homes > 0, "seed %d %s: every home in the regional style (%d of %d)" % [seed_value, st.name, styled, homes])
		elif elite:
			check(halls == manors and styled > manors, "seed %d %s: its %d manors are great houses, %d better-quarter homes styled" % [seed_value, st.name, manors, styled - manors])
		else:
			check(styled == 0, "seed %d %s: no styled house (%d)" % [seed_value, st.name, styled])
		if styled > 0:
			check(ok, "seed %d %s: every styled house keeps its footprint and door, solid on its base only, its door leads in under a roof that lifts %s" % [seed_value, st.name, bad])
	return _styles(o)


## "" when the styled slot is right, else what is wrong.
func _house_ok(o: Overworld, sl: Dictionary) -> String:
	var lay: Dictionary = o.stamps[str(sl.stamp)]
	var sd: Dictionary = o.stamps.get(str(sl.style), {})
	if sd.is_empty():
		return "(%s: no stamp)" % sl.style
	if int(sd.w) != int(lay.w) or int(sd.h) != int(lay.h) or int(sd.door[0]) != int(lay.door[0]) or int(sd.door[1]) != int(lay.door[1]):
		return "(%s: footprint differs from %s)" % [sl.style, sl.stamp]
	if str(sl.look) != "":
		return "(%s: a colour look as well)" % sl.style
	var r: Rect2i = sl.rect
	var door: Vector2i = sl.door
	if o.is_solid(door) or o.is_solid(sl.spot):
		return "(%s: door or its spot solid)" % sl.style
	for y in range(door.y + 1, r.end.y):
		for x in range(r.position.x, r.end.x):
			if o.site_building_at(Vector2i(x, y)):
				return "(%s: solid below its base at %s)" % [sl.style, Vector2i(x, y)]
	if o.site_inside_at(door) != sl:
		return "(%s: the doorway is not its inside)" % sl.style
	# the way in: open cells of its inside reached from the door
	var seen := {door: true}
	var todo: Array[Vector2i] = [door]
	var inside := 0
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		inside += 1
		for d: Vector2i in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
			var n := c + d
			if not seen.has(n) and r.has_point(n) and not o.is_solid(n) and o.site_inside_at(n) == sl:
				seen[n] = true
				todo.append(n)
	if inside < 3:
		return "(%s: only %d inside cells reached)" % [sl.style, inside]
	var fl := 0
	for v in (sd.layers as Dictionary).get("above3", []):
		if int(v) / 100000 == MapView.EXTRA_ATLASES.size() + 3:
			fl += 1
	if fl == 0:
		return "(%s: no Fantasy Lands tile on its roof layer)" % sl.style
	return ""
