extends SceneTree
## Sword combat responsiveness and hit detection (B14 combat-quality issue CQ-01). Drives the real game
## scene (main.gd) and counts presses, accepted presses, swings and hits separately. Run headless:
##   godot --headless --path game --script res://tests/combat_test.gd
## Desktop and headless only: the feel of touch on a real Android phone is not tested here.

var main
var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://test_saves/combat_test/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	main.new_game()
	test_buffer()
	test_one_blow_one_hit()
	test_reach_and_directions()
	test_walls()
	test_moving()
	test_touch()
	test_keyboard_route()
	test_foe_first()
	test_npc_combat_and_reload()
	print("combat_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ---------------------------------------------------------------- helpers ----------------------
var spot := Vector2.INF


## An open outdoor spot (a 7 x 7 block of free cells) away from everyone else, found once.
func open_spot() -> Vector2:
	if spot != Vector2.INF:
		return spot
	var w: World = main.world
	for y in range(10, w.map.h - 10):
		for x in range(10, w.map.w - 10):
			var ok := true
			for dy in range(-3, 4):
				for dx in range(-3, 4):
					var c := Vector2i(x + dx, y + dy)
					if w.map.is_solid_world(c) or w.place_of(Vector2(c) + Vector2(0.5, 0.5)) != "" or w.roof_over(Vector2(c) + Vector2(0.5, 0.5)) != "":
						ok = false
			if ok and w.present(Vector2(x, y) + Vector2(0.5, 0.5), 6.0).is_empty() and w.fauna.near(Vector2(x, y) + Vector2(0.5, 0.5), 6.0).is_empty():
				spot = Vector2(x, y) + Vector2(0.5, 0.5)
				return spot
	return Vector2.INF


func bandit() -> NPC:
	for n: NPC in main.world.npcs:
		if n.alive and n.role == "bandit":
			n.hp = 10000.0
			n.max_hp = 10000.0
			n.plan.clear()
			n.target = -1
			return n
	return null


## The player at the open spot facing `dir`, a bandit at `off` from them; a fresh swing state.
func stage(dir: Vector2, off: Vector2) -> NPC:
	var p: PlayerState = main.world.player
	main.swing = Combat.new()
	main.action = {}
	p.pos = open_spot()
	main.player_sprite.face(dir)
	var b := bandit()
	b.pos = p.pos + off
	return b


func run_out(max_steps := 200) -> void:
	var guard := 0
	while main.swing.busy() and guard < max_steps:
		main._swing_step(0.02)
		guard += 1


func swing_hits(dir: Vector2, off: Vector2) -> bool:
	var b := stage(dir, off)
	var hp := b.hp
	main.attack()
	run_out()
	return b.hp < hp


# ---------------------------------------------------------------- tests ------------------------
## Presses during a swing: early ones are ignored, one inside the buffer is kept, and a second is not.
func test_buffer() -> void:
	var b := stage(Vector2.RIGHT, Vector2(1.0, 0))
	var cfg := Combat.cfg()
	var st: float = main.swing_time()
	check(main.attack() == "start", "a press with no swing running starts one at once")
	check(main.player_sprite.anim == "swing" and main.player_sprite.striking, "the strike starts on the press itself (immediate feedback)")
	main._swing_step(0.05)
	check(main.attack() == "ignored", "a press early in the swing (%.2f s left, buffer %.2f s) is not kept" % [main.swing.remaining(st), float(cfg.buffer)])
	var guard := 0
	while main.swing.remaining(st) > float(cfg.buffer) and guard < 100:
		main._swing_step(0.02)
		guard += 1
	check(main.attack() == "queued", "a press in the last %.2f s of the swing is kept for the next swing" % float(cfg.buffer))
	check(main.attack() == "ignored" and main.attack() == "ignored", "only one press is kept: two more are not queued")
	var hp := b.hp
	run_out()
	check(main.swing.presses == 5 and main.swing.accepted == 2 and main.swing.swings == 2, "5 presses, 2 accepted, 2 swings (presses %d, accepted %d, swings %d)" % [main.swing.presses, main.swing.accepted, main.swing.swings])
	check(main.swing.hits == 2 and b.hp < hp, "both swings hit (%d hits)" % main.swing.hits)
	check(not main.swing.busy(), "then it stops: no repeating attack")
	# a mash: 20 presses, one every 0.05 s, gives one swing per swing time, never more
	main.swing = Combat.new()
	var t := 0.0
	for i in 20:
		main.attack()
		main._swing_step(0.05)
		t += 0.05
	run_out()
	var most := ceili(t / st) + 1
	check(main.swing.swings >= 2 and main.swing.swings <= most and main.swing.presses == 20, "mashing 20 presses over %.1f s gives %d swings (at most %d), each press counted" % [t, main.swing.swings, most])


## One swing deals its damage once, on the slash frame, not on the press.
func test_one_blow_one_hit() -> void:
	var b := stage(Vector2.RIGHT, Vector2(1.0, 0))
	var hp := b.hp
	main.attack()
	check(b.hp == hp, "no damage on the press itself (windup)")
	var guard := 0
	while b.hp == hp and guard < 100:
		main._swing_step(0.02)
		guard += 1
	check(absf(guard * 0.02 - float(Combat.cfg().windup)) <= 0.021, "the blow lands at the slash frame, %.2f s after the press" % (guard * 0.02))
	var after := b.hp
	run_out()
	check(b.hp == after and main.swing.hits == 1, "the rest of the swing deals no more damage (one hit)")


## Reach without sprite overlap, in all eight directions; nothing behind or beyond reach.
func test_reach_and_directions() -> void:
	var reach := float(Combat.cfg().reach)
	check(swing_hits(Vector2.RIGHT, Vector2(reach - 0.1, 0)), "a bandit %.1f tiles in front is hit (no overlap: the sprites are a tile apart)" % (reach - 0.1))
	check(swing_hits(Vector2.RIGHT, Vector2(1.2, 0)), "and at 1.2 tiles")
	check(not swing_hits(Vector2.RIGHT, Vector2(reach + 0.3, 0)), "one %.1f tiles away is out of reach" % (reach + 0.3))
	check(not swing_hits(Vector2.RIGHT, Vector2(-1.2, 0)), "one 1.2 tiles behind is not hit")
	var all := true
	var names := ["S", "SE", "E", "NE", "N", "NW", "W", "SW"]
	for i in 8:
		var a := float(i) * TAU / 8.0
		var dir := Vector2(sin(a), cos(a))
		main.player_sprite.face(dir)
		var ok := swing_hits(dir, dir * 1.2)
		if not ok:
			all = false
			print("     missed facing ", names[i])
	check(all, "facing each of the 8 directions, a bandit 1.2 tiles that way is hit")
	check(swing_hits(Vector2.RIGHT, Vector2(0.9, 0.7)), "one ahead and to the side (inside the arc) is hit")
	check(swing_hits(Vector2.RIGHT, Vector2(0, 0.5)), "one pressed against the side is hit (close range, any direction)")


## A wall or other solid cell between stops the blow.
func test_walls() -> void:
	var w: World = main.world
	var found := false
	for y in range(5, w.map.h - 5):
		for x in range(5, w.map.w - 5):
			if found:
				break
			var c := Vector2i(x, y)
			if w.map.is_solid_world(c) and not w.map.is_solid_world(c + Vector2i.LEFT) and not w.map.is_solid_world(c + Vector2i.RIGHT):
				var from := Vector2(x - 1, y) + Vector2(0.85, 0.5)
				var to := Vector2(x + 1, y) + Vector2(0.15, 0.5)
				if w.place_of(from) != "" or w.place_of(to) != "":
					continue
				found = true
				main.swing = Combat.new()
				var p: PlayerState = w.player
				p.pos = from
				main.player_sprite.face(Vector2.RIGHT)
				var b := bandit()
				b.pos = to
				var hp := b.hp
				main.attack()
				run_out()
				check(b.hp == hp and main.swing.hits == 0, "a bandit %.1f tiles away behind a solid cell (%d, %d) is not hit through it" % [from.distance_to(to), x, y])
	check(found, "a one-cell wall with open ground either side was found to test")


## Moving while swinging: the blow lands where the player is at the slash frame.
func test_moving() -> void:
	var b := stage(Vector2.RIGHT, Vector2(1.9, 0))
	var hp := b.hp
	main.attack()
	Input.action_press("move_right")
	for i in 8:
		main._player_step(0.02)
	Input.action_release("move_right")
	run_out()
	check(b.hp < hp, "walking toward a bandit 1.9 tiles away while swinging, the blow lands (moved %.2f tiles)" % (main.world.player.pos.x - open_spot().x))
	var b2 := stage(Vector2.RIGHT, Vector2(1.2, 0))
	var hp2 := b2.hp
	Input.action_press("move_right")
	main._player_step(0.02)
	main.attack()
	for i in 20:
		main._player_step(0.02)
	Input.action_release("move_right")
	check(b2.hp < hp2, "a swing started while walking hits")


## The touch Attack button swings at a foe in reach; tap-to-strike strikes from sword reach.
func test_touch() -> void:
	var b := stage(Vector2.LEFT, Vector2(1.3, 0))     # facing away: the button turns to the foe
	main.attack_mode = false
	var hp := b.hp
	main.attack_button()
	check(main.swing.swings == 1 and not main.attack_mode, "the Attack button with a bandit in reach swings at once (no mode toggle)")
	run_out()
	check(b.hp < hp, "and the blow lands on the bandit it turned to")
	for i in 4:
		main.attack_button()
		main._swing_step(0.12)
	run_out()
	check(main.swing.swings >= 3 and not main.attack_mode, "four quick presses of the button: %d swings, never a mode toggle" % main.swing.swings)
	# with nobody in reach the button still toggles attack mode
	b.pos = open_spot() + Vector2(6, 0)
	main.attack_button()
	check(main.attack_mode, "with no foe in reach the button turns attack mode on")
	# a tap on a bandit 1.3 tiles away: no walking needed, the swing starts
	b.pos = main.world.player.pos + Vector2(1.3, 0)
	main.swing = Combat.new()
	main.strike(b)
	main._chase_step()
	check(main.move_to == Vector2.INF and main.swing.swings == 1, "a tap on a bandit within sword reach strikes without walking onto it")
	run_out()
	# a tap on one farther off walks only into reach
	b.pos = main.world.player.pos + Vector2(4.0, 0)
	main.swing = Combat.new()
	main.strike(b)
	main._chase_step()
	check(main.move_to != Vector2.INF and main.swing.swings == 0, "a tap on a bandit 4 tiles off walks toward it")
	main.world.player.pos = b.pos - Vector2(float(Combat.cfg().reach) - 0.3, 0)
	main._chase_step()
	check(main.move_to == Vector2.INF and main.swing.swings == 1, "and strikes from %.1f tiles, not from on top of it" % (float(Combat.cfg().reach) - 0.3))
	run_out()
	main.chase = null
	main.strike_pending = false
	b.pos = open_spot() + Vector2(6, 0)
	main.attack_button()                     # attack mode off again (no foe in reach)
	check(not main.attack_mode, "attack mode off")


## The keyboard and the pad press the same "attack" action that reaches attack() through the game's step.
func test_keyboard_route() -> void:
	var keys: Array = InputMap.action_get_events("attack")
	var key_ok := keys.any(func(e): return e is InputEventKey and e.physical_keycode in [KEY_SPACE, KEY_J] or e is InputEventKey and e.keycode in [KEY_SPACE, KEY_J])
	var pad_ok := keys.any(func(e): return e is InputEventJoypadButton and e.button_index == JOY_BUTTON_X)
	check(key_ok and pad_ok, "Space / J and the pad's X are bound to attack")
	var b := stage(Vector2.RIGHT, Vector2(1.2, 0))
	var hp := b.hp
	Input.action_press("attack")
	main._player_step(0.02)
	Input.action_release("attack")
	check(main.swing.presses == 1 and main.swing.swings == 1, "an attack press read by the game's step starts a swing")
	run_out()
	check(b.hp < hp, "and hits")


## A bandit in front is struck before a villager beside it (no accidental crime).
func test_foe_first() -> void:
	var b := stage(Vector2.RIGHT, Vector2(1.3, 0))
	var v: NPC = null
	for n: NPC in main.world.npcs:
		if n.alive and n.role == "adult" and n.target == -1:
			v = n
			break
	v.pos = main.world.player.pos + Vector2(0.9, 0.3)
	var vhp := v.hp
	var hp := b.hp
	main.attack()
	run_out()
	check(b.hp < hp and v.hp == vhp, "the bandit is struck, not the nearer villager beside the line")
	v.pos = open_spot() + Vector2(20, 20)


## Bandits still fight; a swing in progress does not survive a reload or a new world.
func test_npc_combat_and_reload() -> void:
	var b := stage(Vector2.RIGHT, Vector2(0.8, 0))
	b.hp = 30.0
	b.max_hp = 30.0
	b.target = -2
	var php: float = main.world.player.hp
	for i in 200:
		main.world.update(0.05)
		b.pos = main.world.player.pos + Vector2(0.8, 0)
		if main.world.player.hp < php:
			break
	check(main.world.player.hp < php, "a bandit fighting the player still lands blows (%.0f -> %.0f)" % [php, main.world.player.hp])
	main.world.player.hp = main.world.player.max_hp
	main.attack()
	check(main.swing.busy(), "a swing in progress...")
	var hits: int = main.swing.hits
	check(main.save_game(false), "the game saves mid-swing")
	main.continue_game()
	check(not main.swing.busy(), "...is gone after loading the save")
	for i in 30:
		main._swing_step(0.02)
	check(main.swing.hits == hits, "and no blow is carried over into the loaded world")
	main.attack()
	main.new_game()
	check(not main.swing.busy(), "and after starting a new world")
