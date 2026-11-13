extends SceneTree
## B25-ANIMAL-HUNT-AI visual check (owner directive 2026-11-12, section 2: "a visual gameplay test, because passing AI unit
## tests alone will not establish that the animations look natural"). In the real game scene: the player strikes a deer
## from behind, the deer turns, then runs; the player chases and strikes again; then a bear is struck and comes on. Frames
## are captured at fixed steps (World.update at 30 frames a second, as play runs it, the scene's own update paused so only this drives it) and laid
## out as two contact sheets, each frame cropped round the player and labelled with its time. Needs a display:
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --resolution 1920x1080 --path game \
##       --script res://tests/hunt_shot.gd -- OUT_DIR

var main
var out := "/tmp"
var frames := 0
var phase := "setup"
var a: Animal
var t := 0.0
var cd := 0.0
var shots := []        # [Image, label]
var plan := []         # times (seconds after the first blow) to capture
var chase := true
var chase_until := 2.5
var pending := ""     # the label of the frame to capture next tick
const DT := 1.0 / 30.0
const CROP := Vector2i(576, 384)
const STEP := 0.15
var order := ["deer", "boar", "bear"]
var log_lines := []


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	main.save_path = "user://test_saves/hunt_shot/save1.json"
	main.new_game()
	main.ui.hide_all()
	main.camera.zoom = Vector2(3, 3)
	main.camera.position_smoothing_enabled = false
	main._start(true)
	main.paused = true
	main.ui.dismiss_message()
	_stage(order.pop_front())
	process_frame.connect(_tick)


func _open_cell(area: String, r: int) -> Vector2i:
	var w: World = main.world
	for c: Vector2i in w.fauna.cells(area):
		var ok := true
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var q := c + Vector2i(dx, dy)
				if not w.fauna.in_area(area, q) or w.map.is_solid(q):
					ok = false
		if ok:
			return c
	return Vector2i(-1, -1)


## The cell of a wood with the most open ground of that wood within 6 cells (ties: the first in the wood's order).
func _most_open(area: String) -> Vector2i:
	var w: World = main.world
	var best := Vector2i(-1, -1)
	var bn := -1
	for c: Vector2i in w.fauna.cells(area):
		var n := 0
		for dy in range(-6, 7):
			for dx in range(-6, 7):
				var q := c + Vector2i(dx, dy)
				if w.fauna.in_area(area, q) and not w.map.is_solid(q):
					n += 1
		if n > bn:
			bn = n
			best = c
	return best


func _stage(species: String) -> void:
	var w: World = main.world
	for b: Animal in w.fauna.animals:
		b.hunger = 100.0
		b.anger = ""
	var area := "woods_e" if species == "deer" else "woods_w"    # the deer where the east wood is most open, to see it look back
	a = w.fauna.animals.filter(func(x): return x.alive and x.species == species and x.area == area and x.adult(w.minutes))[0]
	var c := _most_open(area)
	a.pos = Vector2(c) + Vector2(0.5, 0.5)
	a.goal = Vector2.INF
	a.wait = 30.0
	a.moving = false
	a.facing = Vector2.RIGHT                 # its back to the player, who comes from the west
	for b: Animal in w.fauna.animals:        # nobody else in the picture
		if b != a and b.area == area and b.pos.distance_to(a.pos) < 8.0:
			b.pos = Vector2(-50, -50)
	w.player.pos = a.pos + Vector2(-1.1, 0.0)
	w.player.hp = float(GameData.b("player_max_hp"))
	t = -0.5
	cd = 0.0
	chase = species != "bear"
	chase_until = 2.5 if species == "deer" else 3.0
	var span := 6.0 if species == "deer" else (5.0 if species == "boar" else 3.0)
	plan = []
	var k := -0.3
	while k <= span:
		plan.append(k)
		k += STEP
	phase = species


func _strike() -> void:
	var w: World = main.world
	main.player_sprite.face(a.pos - w.player.pos)
	main.player_sprite.strike()
	var before := a.hp
	w.player_hit_animal(a, 0.01)
	main._hit_fx(main.animal_sprites.get(a.id), before, a.hp, 0.01)


func _tick() -> void:
	frames += 1
	var w: World = main.world
	if frames < 15:                          # let the scene settle
		main._sync_sprites()
		return
	if phase == "done":
		return
	if pending != "":                        # the frame drawn after the last step: the state the label describes
		var img: Image = root.get_texture().get_image()
		var r := Rect2i((img.get_size() - CROP) / 2, CROP)
		img.get_region(r).save_png(out.path_join("%s_%03d.png" % [phase, shots.size()]))
		shots.append(pending)
		log_lines.append("%s_%03d %s" % [phase, shots.size() - 1, pending])
		print(log_lines[-1])
		pending = ""
		if plan.is_empty():
			_next()
		return
	if t < 0.0 and t + DT >= 0.0:
		_strike()
		cd = float(Combat.cfg().swing_time)
	w.update(DT)                             # the whole world, as play runs it (animals step on its half-second ticks)
	if t >= 0.0:
		w.player.hp = float(GameData.b("player_max_hp"))      # the bear bites; the picture is of the fight, not of the player falling
		if chase and t < chase_until:
			var gap := a.pos - w.player.pos
			if gap.length() > 1.3:
				w.player.pos += gap.normalized() * minf(float(GameData.b("player_tiles_per_second")) * 0.9 * DT, gap.length() - 1.3)
				main.player_sprite.face(gap)
			cd -= DT
			if cd <= 0.0 and gap.length() <= float(Combat.cfg().reach) :
				_strike()
				cd = float(Combat.cfg().swing_time) * 1.5
	t += DT
	var mid := (w.player.pos + a.pos) / 2.0
	main.cam_free = true                     # the camera on the hunter and the hunted (main's own follow keeps to cam_at)
	main.cam_at = mid * main.T
	main.camera.position = main.cam_at
	main._sync_sprites()
	if not plan.is_empty() and t >= float(plan[0]):
		plan.pop_front()
		pending = "%s t=%.2f %s%s%s face=(%.2f,%.2f) gap=%.2f pos=(%.2f,%.2f) player=(%.2f,%.2f)" % [a.species, t,
			"RUN" if a.moving else "STAND", (" act=" + a.act) if a.act != "" else "",
			(" startle" if a.startle_left > 0.0 else "") + (" lookback" if a.pause_left > 0.0 else "") + (" atbay" if a.at_bay else "") + (" break" if a.breaking else "") + (" anger" if a.anger != "" else ""),
			a.facing.normalized().x, a.facing.normalized().y, a.pos.distance_to(w.player.pos), a.pos.x, a.pos.y, w.player.pos.x, w.player.pos.y]


func _next() -> void:
	shots.clear()
	if not order.is_empty():
		_stage(order.pop_front())
	else:
		phase = "done"
		var f := FileAccess.open(out.path_join("frames.txt"), FileAccess.WRITE)
		f.store_string("\n".join(log_lines) + "\n")
		f.close()
		quit(0)
