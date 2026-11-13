extends SceneTree
## B25-ANIMAL-HUNT-AI visual check (owner directive 2026-11-12, section 2: "a visual gameplay test, because passing AI unit
## tests alone will not establish that the animations look natural"). In the real game scene: the player strikes a deer
## from behind, the deer turns, then runs; the player chases and strikes again; then a bear is struck and comes on. Frames
## are captured at fixed steps (the world is driven at 30 steps a second, the game paused so nothing else moves it) and laid
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
const DT := 1.0 / 30.0
const CROP := Vector2i(480, 300)


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
	main.camera.zoom = Vector2(4, 4)
	main.camera.position_smoothing_enabled = false
	main._start(true)
	main.paused = true
	main.ui.dismiss_message()
	_stage("deer")
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


func _stage(species: String) -> void:
	var w: World = main.world
	for b: Animal in w.fauna.animals:
		b.hunger = 100.0
		b.anger = ""
	a = w.fauna.animals.filter(func(x): return x.alive and x.species == species and x.area == "woods_w" and x.adult(w.minutes))[0]
	var c := _open_cell("woods_w", 3)
	a.pos = Vector2(c) + Vector2(0.5, 0.5)
	a.goal = Vector2.INF
	a.wait = 30.0
	a.moving = false
	a.facing = Vector2.RIGHT                 # its back to the player, who comes from the west
	for b: Animal in w.fauna.animals:        # nobody else in the picture
		if b != a and b.area == "woods_w" and b.pos.distance_to(a.pos) < 8.0:
			b.pos = Vector2(-50, -50)
	w.player.pos = a.pos + Vector2(-1.1, 0.0)
	w.player.hp = float(GameData.b("player_max_hp"))
	t = -0.5
	cd = 0.0
	chase = species == "deer"
	plan = [-0.4, 0.05, 0.3, 0.7, 1.1, 1.6, 2.4, 3.2, 4.0] if species == "deer" else [-0.4, 0.05, 0.4, 0.9, 1.4, 2.0]
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
	if t < 0.0 and t + DT >= 0.0:
		_strike()
		cd = float(Combat.cfg().swing_time)
	if t >= 0.0:
		w.fauna.update(DT)
		if a.anger != "":
			a.bite_cd = 99.0                 # the bear comes on but the picture is of its approach, not of the player falling
		if chase:
			var gap := a.pos - w.player.pos
			if gap.length() > 0.9:
				w.player.pos += gap.normalized() * minf(float(GameData.b("player_tiles_per_second")) * 0.9 * DT, gap.length() - 0.9)
				main.player_sprite.face(gap)
			cd -= DT
			if cd <= 0.0 and gap.length() <= float(Combat.cfg().reach) and t < 2.5:
				_strike()
				cd = float(Combat.cfg().swing_time) * 1.5
	t += DT
	main.camera.position = w.player.pos * main.T
	main._sync_sprites()
	main.camera.position = w.player.pos * main.T
	if not plan.is_empty() and t >= float(plan[0]):
		plan.pop_front()
		var img: Image = root.get_texture().get_image()
		var size := img.get_size()
		var r := Rect2i((size - CROP) / 2, CROP)
		shots.append([img.get_region(r), "%s t=%.2fs %s%s face(%.1f,%.1f)" % [a.species, t, "moving" if a.moving else "standing",
			(" act=" + a.act) if a.act != "" else "", a.facing.normalized().x, a.facing.normalized().y]])
		print("shot ", shots[-1][1], " deer-player %.2f" % a.pos.distance_to(w.player.pos))
	if plan.is_empty():
		_sheet(phase)
		shots.clear()
		if phase == "deer":
			_stage("bear")
		else:
			phase = "done"
			quit(0)


## The frames side by side, three to a row.
func _sheet(name: String) -> void:
	var cols := 3
	var rows := ceili(shots.size() / float(cols))
	var sheet := Image.create(CROP.x * cols, CROP.y * rows, false, Image.FORMAT_RGBA8)
	for i in shots.size():
		var im: Image = shots[i][0]
		im.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(im, Rect2i(Vector2i.ZERO, CROP), Vector2i((i % cols) * CROP.x, (i / cols) * CROP.y))
	var half := sheet.duplicate()
	half.resize(sheet.get_width() / 2, sheet.get_height() / 2, Image.INTERPOLATE_NEAREST)
	var p := out.path_join("hunt_%s.png" % name)
	sheet.save_png(p)
	half.save_png(out.path_join("hunt_%s_half.png" % name))
	var labels := []
	for s in shots:
		labels.append(s[1])
	print("saved ", p, " ", sheet.get_size(), " frames: ", " | ".join(labels))
