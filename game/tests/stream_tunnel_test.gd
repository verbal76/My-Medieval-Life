extends SceneTree
## Stream fix (2026-11-13, B25-MOVE-STUTTER-INV finding "catch-up"): the player's step is speed * the frame's delta, and
## World.try_step checks only where a step ends. One long frame (a stall of 0.7 s) while walking into a one-tile wall moved the
## player 3.15 tiles straight through it. Main._player_step now walks a long frame's movement in short steps (MAX_STEP_TILES), each
## through try_step: the same distance in open ground, never through a wall. A normal frame's step is unchanged (one step).
##   godot --headless --path game -s res://tests/stream_tunnel_test.gd

var main
var checks := 0
var failures := 0


func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("ok   " if ok else "FAIL ") + what)


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://test_stream_tunnel/save.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _free(w: World, x: int, y: int) -> bool:
	return not w.map.is_solid(Vector2i(x, y)) and not w.body_blocked(w.player, Vector2(x + 0.5, y + 0.5))


## A solid cell with open ground for 4 cells west and east of it (a one-tile wall across the way east), near the start.
func _wall(w: World) -> Vector2i:
	var s := Vector2i(w.player.pos)
	for r in range(2, 120):
		for y in range(s.y - r, s.y + r + 1):
			for x in range(s.x - r, s.x + r + 1):
				if maxi(absi(x - s.x), absi(y - s.y)) != r or not w.map.is_solid(Vector2i(x, y)):
					continue
				var ok := true
				for k in range(1, 5):
					ok = ok and _free(w, x - k, y) and _free(w, x + k, y)
				if ok:
					return Vector2i(x, y)
	return Vector2i(-1, -1)


## Open ground for 8 cells east of a cell, near the start.
func _open(w: World) -> Vector2i:
	var s := Vector2i(w.player.pos)
	for r in range(0, 120):
		for y in range(s.y - r, s.y + r + 1):
			for x in range(s.x - r, s.x + r + 1):
				if maxi(absi(x - s.x), absi(y - s.y)) != r:
					continue
				var ok := true
				for k in range(0, 9):
					ok = ok and _free(w, x + k, y) and _free(w, x + k, y - 1) and _free(w, x + k, y + 1)
				if ok:
					return Vector2i(x, y)
	return Vector2i(-1, -1)


func _walk_right(delta: float, from: Vector2) -> Vector2:
	var p = main.world.player
	p.pos = from
	main.move_to = Vector2.INF
	Input.action_press("move_right")
	main._player_step(delta)
	Input.action_release("move_right")
	return p.pos


func _run() -> void:
	main.new_game()
	await process_frame
	var w: World = main.world
	var speed := float(GameData.b("player_tiles_per_second"))
	var wall := _wall(w)
	check(wall.x >= 0, "a one-tile wall with open ground either side near the start: %s" % str(wall))
	if wall.x >= 0:
		var from := Vector2(wall.x - 1.5, wall.y + 0.5)
		var to := _walk_right(0.7, from)
		check(to.x < wall.x, "one 0.7 s frame walking east into the wall at %s leaves the player west of it (from %s to %s)" % [str(wall), str(from), str(to)])
	var open := _open(w)
	check(open.x >= 0, "open ground near the start: %s" % str(open))
	if open.x >= 0:
		var from := Vector2(open.x + 0.5, open.y + 0.5)
		var d1 := _walk_right(1.0 / 60.0, from).x - from.x
		check(absf(d1 - speed / 60.0) < 1e-4, "a normal frame's step is unchanged: %.5f tiles (speed %.2f / 60 = %.5f)" % [d1, speed, speed / 60.0])
		var d2 := _walk_right(0.7, from).x - from.x
		check(absf(d2 - speed * 0.7) < 1e-3, "a 0.7 s frame in open ground still walks the whole way: %.4f tiles (%.4f)" % [d2, speed * 0.7])
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
