extends SceneTree
## TEST-AUDIT-01 gap G10 (requirement B8R-002, "Trapped inside a door"): someone standing just inside a building's door can always
## walk out of it. Seeds 1 and 2, every built building's interior and every door it has: the door cell is open, there is an open
## cell inside beside it and an open cell outside beside it, and the village's own path-finding leads from the inside cell to the
## outside one in a few steps. A door two or more cells wide is one doorway (a corner cell opens out through its partner); a door with no
## room beside it is a gate in a yard's fence and must be open on two sides. (Before, no suite checked it: the fix of B8R-002 could regress unseen.)
##   godot --headless --path game -s res://tests/door_exit_test.gd

const MAX_STEPS := 6
var checks := 0
var failures := 0


func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("ok   " if ok else "FAIL ") + what)


static func _cells(v) -> Dictionary:
	var out := {}
	if v is Dictionary:
		for k in v:
			out[k if k is Vector2i else Vector2i(int(k[0]), int(k[1]))] = true
	elif v is Array:
		for c in v:
			out[c if c is Vector2i else Vector2i(int(c[0]), int(c[1]))] = true
	return out


func _init() -> void:
	GameData.ensure()
	for seed in [1, 2]:
		var w := World.new()
		w.setup(VillageMap.load_default(), seed)
		var doors := 0
		var bad := []
		var ids := w.interiors.keys()
		ids.sort()
		for id in ids:
			var it: Dictionary = w.interiors[id]
			var area := _cells(it.get("area", []))
			var door_set := {}
			for d in it.get("doors", []):
				door_set[Vector2i(int(d[0]), int(d[1]))] = true
			for d in it.get("doors", []):
				var door := Vector2i(int(d[0]), int(d[1]))
				doors += 1
				# a doorway is the door with the door cells joined to it (a door two cells wide opens out through its partner)
				var group := {door: true}
				var todo: Array[Vector2i] = [door]
				while not todo.is_empty():
					var q: Vector2i = todo.pop_back()
					for step in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
						if door_set.has(q + step) and not group.has(q + step):
							group[q + step] = true
							todo.append(q + step)
				var inside := Vector2i(-1, -1)
				var outside := Vector2i(-1, -1)
				var open_out := 0
				for g: Vector2i in group:
					for step in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
						var c: Vector2i = g + step
						if group.has(c) or w.map.is_solid(c):
							continue
						if area.has(c):
							if inside.x < 0:
								inside = c
						else:
							open_out += 1
							if outside.x < 0:
								outside = c
				var why := ""
				if w.map.is_solid(door):
					why = "the door cell is solid"
				elif inside.x < 0 and open_out < 2:
					why = "a gate (no room beside it) open on fewer than two sides"
				elif inside.x >= 0 and outside.x < 0:
					why = "no open cell outside the doorway"
				elif inside.x >= 0:
					var path := w.map.find_path(inside, outside)
					if path.is_empty() or path.size() > MAX_STEPS:
						why = "no short way out (%d steps)" % path.size()
				if why != "":
					bad.append("%s door %s: %s" % [id, str(door), why])
		check(doors >= 10, "seed %d: doors of built buildings to try (%d)" % [seed, doors])
		check(bad.is_empty(), "seed %d: from just inside every door the way out is open (%d not: %s)" % [seed, bad.size(), str(bad.slice(0, 4))])
		w.dispose()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
