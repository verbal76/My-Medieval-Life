extends Node2D
## Game scene: owns the World (simulation), draws it, runs the player's controls and actions.
## Everything the player does goes through the same World rules as the NPCs.

const T := 16
const SAVE_PATH := "user://save1.json"

var map: VillageMap
var world: World
var view: MapView
var actors: Node2D
var above: Node2D
var camera: Camera2D
var ui: GameUI
var sprites := {}              # npc id -> ActorSprite
var animal_sprites := {}       # animal id -> AnimalSprite
var player_sprite: ActorSprite
var loot_nodes: Array = []
var projectiles: Array = []    # {node, pos, dir, left}
var target := {}               # current interaction target
var action := {}               # {label, left, total, done: Callable}
var paused := true             # the title screen starts paused
var running := false
var move_to: Vector2 = Vector2.INF   # tap-to-move destination (tiles)
var walk_path := PackedVector2Array()  # the route to move_to, cell by cell (the villagers' pathfinder)
var walk_i := 0
var walk_goal := Vector2i(-1, -1)      # the cell walk_path leads to
var walk_stuck := 0.0                  # seconds without progress along the route
var talk_to: NPC = null                # a tapped villager the player walks up to, to talk
var touch_points := {}
var pinch_start := 0.0
var zoom_start := 3.0
var autosave_hour := -1
var shot_path := ""
var shot_frames := 0
var shot_warp := Vector2.INF
var shot_advance := 0.0
var shot_zoom := 0.0
var shot_panel := ""
var view_scale := 1.0          # phones draw the interface larger; the camera zoom makes up for it
var attack_mode := false       # toggled by the Attack button: a tap on a person or animal targets it
var chase: Object = null       # the NPC or Animal marked with the sword: the player walks to it to strike
var strike_pending := false    # strike the target once in reach (a tap on it, or arriving at it)
var target_marker: Sprite2D    # the sword shown over the target
var settings := GameSettings.new()
var scheme := "kbm"            # the controls in use, from the last input: touch | gamepad | kbm
var blood_layer: Node2D        # blood where someone was slain, under the actors
var dying := {}                # npc id -> seconds left of the death flicker
var fading: Array = []         # [sprite, seconds left]: killed animals flickering out
var bubble_layer: CanvasLayer  # speech bubbles over villagers' heads, in screen space
var bubbles := {}              # npc id -> SpeechBubble (at most one each)
const FLICKER := 1.2           # seconds a body flickers before it disappears
const BLOOD_FADE := 90.0       # seconds blood takes to fade away


func _ready() -> void:
	_setup_input()
	GameData.ensure()
	# the interface is laid out for the screen (larger on a phone) and the camera zoom makes up for it
	settings.load_file()
	settings.apply(get_tree())
	view_scale = settings.layout_height() / 720.0
	scheme = "touch" if settings.phone else "kbm"
	ui = GameUI.new()
	add_child(ui)
	ui.build(self)
	ui.set_scheme(scheme)
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if i + 1 >= args.size():
			continue
		match args[i]:
			"--screenshot":
				shot_path = args[i + 1]
			"--warp":
				var xy: PackedStringArray = args[i + 1].split(",")
				shot_warp = Vector2(float(xy[0]), float(xy[1]))
			"--advance":
				shot_advance = float(args[i + 1])
			"--zoom":
				shot_zoom = float(args[i + 1])
			"--panel":
				shot_panel = args[i + 1]
	if shot_path != "":
		new_game()
		ui.hide_all()
		# fast-forward the simulation (game minutes) for screenshots of the living village
		var steps := int(shot_advance / float(GameData.b("game_minutes_per_second")) / 0.5)
		for k in steps:
			world.player.hunger = 100.0          # the camera's stand-in does not starve while it waits
			world.update(0.5)
		if shot_warp != Vector2.INF:
			world.player.pos = shot_warp
		if shot_zoom > 0.0:
			camera.zoom = Vector2(shot_zoom, shot_zoom) * view_scale
		camera.position_smoothing_enabled = false
		match shot_panel:
			"skills":
				ui.show_skills()
			"inventory":
				ui.show_inventory("")
			"title":
				ui.show_title(false)
			"creation":
				ui.show_creation({"name": "Ada", "family": "Thorne", "sex": "female"})
			"origin":
				ui.show_origin()
			"settings":
				ui.show_settings(ui.hide_all)
			"controls":
				ui.show_controls(ui.hide_all)
			"journal":
				ui.show_journal(-1)
			"marker":
				attack_mode = true
				ui.set_attack_mode(true)
				ui.set_scheme("touch")
				for n: NPC in world.near(world.player.pos, 8.0):
					chase = n
					break
			"blood":
				_on_bled(world.player.pos + Vector2(1.5, 0))
				ui.prompt("Talk to Mabel Reed")
				ui.message("You take 3 coins and 1 items.")
			"talk":
				ui.show_talk(world.npcs[2])
			"talk_home":
				ui.show_talk(world.npcs[2])
				ui._talk_view(world.npcs[2], Dialogue.home(world, world.npcs[2]))
			"bubble":
				for n: NPC in world.near(world.player.pos, 8.0):
					if n.role != "bandit" and not n.hidden:
						say(n, Dialogue.brush_off(world, n))
						break
			"trade":
				for n: NPC in world.npcs:
					if n.job == "smith":
						ui.show_trade(n)
						break
			"craft":
				ui.show_craft(world.stations_of("anvil")[0])
		return
	ui.show_title(FileAccess.file_exists(SAVE_PATH))


func _setup_input() -> void:
	var keys := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN], "interact": [KEY_E, KEY_ENTER], "attack": [KEY_SPACE, KEY_J],
		"fireball": [KEY_F, KEY_K], "inventory": [KEY_I, KEY_TAB], "skills": [KEY_L], "journal": [KEY_B], "pause": [KEY_ESCAPE, KEY_P],
		"zoom_in": [KEY_EQUAL, KEY_KP_ADD], "zoom_out": [KEY_MINUS, KEY_KP_SUBTRACT],
	}
	var pads := {"interact": JOY_BUTTON_A, "attack": JOY_BUTTON_X, "fireball": JOY_BUTTON_Y,
		"inventory": JOY_BUTTON_BACK, "pause": JOY_BUTTON_START, "skills": JOY_BUTTON_RIGHT_SHOULDER}
	for a in keys:
		if not InputMap.has_action(a):
			InputMap.add_action(a)
		for k in keys[a]:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(a, e)
		if pads.has(a):
			var j := InputEventJoypadButton.new()
			j.button_index = pads[a]
			InputMap.action_add_event(a, j)
	for pair in [["move_left", JOY_AXIS_LEFT_X, -1.0], ["move_right", JOY_AXIS_LEFT_X, 1.0],
			["move_up", JOY_AXIS_LEFT_Y, -1.0], ["move_down", JOY_AXIS_LEFT_Y, 1.0]]:
		var m := InputEventJoypadMotion.new()
		m.axis = pair[1]
		m.axis_value = pair[2]
		InputMap.action_add_event(pair[0], m)


# ---------------------------------------------------------------- starting -------------------
## A new world with the character from character creation (name, family, sex, look, sprite); with
## no spec (tests, screenshots) the default character.
func new_game(spec := {}) -> void:
	_clear_world()
	map = VillageMap.load_default()
	world = World.new()
	world.setup(map, 1)
	var p := world.player
	if not spec.is_empty():
		p.name = spec.name
		p.family = spec.family
		p.sex = spec.sex
		p.look = spec.look
		p.sprite = spec.sprite
		p.heir_sprite = spec.sprite
	_build_scene()
	if spec.is_empty():
		_start()
	else:
		paused = true
		running = true
		ui.show_origin()


func resume_after_origin() -> void:
	_start()
	save_game(false)


func continue_game() -> void:
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	var d = JSON.parse_string(text)
	if not d is Dictionary or not int(d.get("save_version", 0)) in [1, 2, 3]:
		ui.message("The save file could not be read; it was kept unchanged. Starting a new game.")
		new_game()
		return
	_clear_world()
	map = VillageMap.load_default()
	world = World.new()
	world.load_dict(map, d)
	_build_scene()
	_apply_world_changes()
	_start()


func _start() -> void:
	paused = false
	running = true
	autosave_hour = int(world.minutes / 60.0)
	ui.hide_all()
	ui.message("%s %s, %s. Explore the village: talk to people, work, trade, build." % [world.player.name, world.player.family, world.clock_text()])


func _clear_world() -> void:
	if world:
		world.dispose()
	chase = null
	talk_to = null
	move_to = Vector2.INF
	walk_goal = Vector2i(-1, -1)
	strike_pending = false
	if attack_mode:
		attack_mode = false
		ui.set_attack_mode(false)
	for c in get_children():
		if c != ui:
			c.queue_free()
	sprites.clear()
	animal_sprites.clear()
	bubbles.clear()
	loot_nodes.clear()
	projectiles.clear()


func _build_scene() -> void:
	view = MapView.new()
	add_child(view)
	blood_layer = Node2D.new()
	add_child(blood_layer)
	actors = Node2D.new()
	actors.y_sort_enabled = true
	add_child(actors)
	above = Node2D.new()
	above.z_index = 10
	add_child(above)
	target_marker = Sprite2D.new()
	target_marker.texture = load("res://assets/icons/iron_sword.png")
	target_marker.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	target_marker.rotation = PI * 1.25           # the icon's blade points up-left: turn it to point down
	target_marker.scale = Vector2(1.5, 1.5)
	target_marker.visible = false
	above.add_child(target_marker)
	view.build(map, above)
	bubble_layer = CanvasLayer.new()
	bubble_layer.layer = 5               # over the map, under the interface (layer 20)
	add_child(bubble_layer)
	for n: NPC in world.npcs:
		var s := ActorSprite.new()
		s.setup(n.sprite)
		actors.add_child(s)
		sprites[n.id] = s
	player_sprite = ActorSprite.new()
	player_sprite.setup(world.player.sprite)
	actors.add_child(player_sprite)
	camera = Camera2D.new()
	camera.zoom = Vector2(3, 3) * view_scale
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 10.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = map.w * T
	camera.limit_bottom = map.h * T
	add_child(camera)
	camera.make_current()
	camera.position = world.player.pos * T
	world.tile_changed.connect(_on_tile_changed)
	world.bled.connect(_on_bled)
	dying.clear()
	fading.clear()
	for n: NPC in world.npcs:
		if not n.alive:
			dying[n.id] = 0.0          # long dead: no flicker after loading
	world.event.connect(func(t): ui.log_line(t))
	world.building_added.connect(_on_building_added)


func _apply_world_changes() -> void:
	for t in world.trees:
		if t.state == "stump":
			_on_tile_changed(Vector2i(t.x, t.y), "below", map.data.tiles.stump)
			_on_tile_changed(Vector2i(t.x, t.y - 1), "above", -1)
		elif t.state == "sapling":
			_on_tile_changed(Vector2i(t.x, t.y), "below", map.data.tiles.sapling)
			_on_tile_changed(Vector2i(t.x, t.y - 1), "above", -1)
	for d in world.deposits:
		if int(d.amount) <= 0:
			_on_tile_changed(Vector2i(d.x, d.y), "below", map.data.tiles.depleted_rock)
	for f in world.fields:
		world._field_tiles(f)
	for p in world.plots:
		if not p.site.is_empty() and not p.site.done:
			_on_tile_changed(Vector2i(int(p.x) + 4, int(p.y) + 8), "below", map.data.tiles.frame)
	for id in world.buildings:
		if world.buildings[id].type == "player_house":
			_on_building_added(world.buildings[id])


func _on_tile_changed(cell: Vector2i, kind: String, value: int) -> void:
	var layer_name: String = {"below": "below0", "above": "above0", "field": "path1", "path": "path0"}.get(kind, "below0")
	var layer := view.layer(layer_name)
	if layer:
		view.set_tile(layer, cell, value)


func _on_building_added(b: Dictionary) -> void:
	var stamp: Dictionary = map.data.stamps.house
	for lname in stamp.layers:
		var layer := view.layer(lname)
		if layer == null:
			continue
		var cells: Array = stamp.layers[lname]
		for j in int(stamp.h):
			for i in int(stamp.w):
				var v := int(cells[j * int(stamp.w) + i])
				if v >= 0:
					view.set_tile(layer, Vector2i(int(b.x) + i, int(b.y) + j), v)


# ---------------------------------------------------------------- frame ----------------------
func _process(delta: float) -> void:
	if world == null:
		return
	if shot_path != "":
		_screenshot_step(delta)
	if not paused and world.player.alive:
		world.update(delta)
		_player_step(delta)
		_projectiles_step(delta)
		var h := int(world.minutes / 60.0)
		if h != autosave_hour:
			autosave_hour = h
			save_game(false)
	if running and not world.player.alive and not ui.is_open("death"):
		ui.show_death()
	_sync_sprites()
	ui.update_hud()


func _sync_sprites() -> void:
	var cam := camera.get_screen_center_position() / T
	for n: NPC in world.npcs:
		var s: ActorSprite = sprites[n.id]
		var near := n.pos.distance_to(cam) < 30.0
		if not n.alive:
			# the body falls, flickers and is gone
			var left: float = dying.get(n.id, FLICKER) - get_process_delta_time()
			dying[n.id] = left
			s.visible = left > 0.0 and near and not n.hidden and int(left * 12.0) % 2 == 0
			if s.visible:
				s.position = n.pos * T
				if s.anim != "death":
					s.play("death", true)
			continue
		s.visible = not n.hidden and near
		if not s.visible:
			continue
		s.position = n.pos * T
		s.face(n.facing)
		s.play(n.anim)
	var p := world.player
	player_sprite.position = p.pos * T
	if not p.alive:
		if player_sprite.anim != "death":
			player_sprite.play("death", true)
	camera.position = p.pos * T
	target_marker.visible = chase != null and chase.alive
	if target_marker.visible:
		var bob := sin(Time.get_ticks_msec() / 150.0) * 1.5
		target_marker.position = chase.pos * T + Vector2(0, -42 + bob)
	_sync_animals()
	_sync_loot()
	_sync_bubbles()


## Bubbles follow their speaker, fade out, and go when the time is up or the speaker is gone.
func _sync_bubbles() -> void:
	var xf := get_canvas_transform()
	for id in bubbles.keys():
		var b: SpeechBubble = bubbles[id]
		var n := world.npc(id)
		if not b.tick(get_process_delta_time()) or n == null or not n.alive or n.hidden:
			b.queue_free()
			bubbles.erase(id)
			continue
		b.point_at(xf * (n.pos * T + Vector2(0, -30)))


## A villager calls out a line in a bubble over their head.
func say(n: NPC, text: String) -> void:
	var b: SpeechBubble = bubbles.get(n.id)
	if b:
		b.say(text)
		return
	b = SpeechBubble.new()
	b.setup(n.id, text, 20)
	bubble_layer.add_child(b)
	bubbles[n.id] = b
	b.point_at(get_canvas_transform() * (n.pos * T + Vector2(0, -30)))


## The player speaks to a villager: someone busy (walking somewhere, working, fighting) calls out a
## line and carries on; anyone else stops for a conversation.
func approach(n: NPC) -> void:
	if n.role != "bandit" and Dialogue.busy(n):
		say(n, Dialogue.brush_off(world, n))
	else:
		ui.show_talk(n)


func _sync_animals() -> void:
	var cam := camera.get_screen_center_position() / T
	var seen := {}
	for a: Animal in world.fauna.animals:
		seen[a.id] = true
		var s: AnimalSprite = animal_sprites.get(a.id)
		if s == null:
			s = AnimalSprite.new()
			s.setup(a)
			actors.add_child(s)
			animal_sprites[a.id] = s
		s.visible = a.pos.distance_to(cam) < 30.0
		if s.visible:
			s.position = a.pos * T
			s.show_state(a, world.minutes, get_process_delta_time())
	for id in animal_sprites.keys():
		if not seen.has(id):
			fading.append([animal_sprites[id], FLICKER])
			animal_sprites.erase(id)
	for f in fading.duplicate():
		f[1] -= get_process_delta_time()
		if f[1] <= 0.0:
			f[0].queue_free()
			fading.erase(f)
		else:
			f[0].visible = int(f[1] * 12.0) % 2 == 0


## A pool of blood where someone or something was slain; it fades away over BLOOD_FADE seconds.
func _on_bled(pos: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = load("res://assets/fx/blood_%d.png" % (randi() % 8))     # looks only: not the world's RNG
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.position = (pos + Vector2(0, 0.25)) * T
	s.rotation = float(randi() % 4) * PI / 2.0
	s.modulate.a = 0.9
	blood_layer.add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "modulate:a", 0.0, BLOOD_FADE).set_ease(Tween.EASE_IN)
	tw.tween_callback(s.queue_free)


func _sync_loot() -> void:
	while loot_nodes.size() < world.loot.size():
		var tr := TextureRect.new()
		tr.texture = load("res://assets/icons/coins.png")
		var holder := Node2D.new()
		holder.add_child(tr)
		tr.position = Vector2(-8, -12)
		actors.add_child(holder)
		loot_nodes.append(holder)
	while loot_nodes.size() > world.loot.size():
		loot_nodes.pop_back().queue_free()
	for i in world.loot.size():
		loot_nodes[i].position = world.loot[i].pos * T


# ---------------------------------------------------------------- player ---------------------
func _player_step(delta: float) -> void:
	var p := world.player
	if not action.is_empty():
		action.left -= delta
		player_sprite.play("work")
		if action.left <= 0.0:
			var done: Callable = action.done
			action = {}
			done.call()
		return
	if ui.modal():
		player_sprite.play("idle")
		return
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if v.length() > 0.1:
		chase = null
		talk_to = null
	_chase_step()
	_talk_step()
	if v.length() > 0.1:
		move_to = Vector2.INF
	elif move_to != Vector2.INF:
		v = _route_step(delta)
	if v.length() > 0.1:
		var speed := float(GameData.b("player_tiles_per_second"))
		var step := v.normalized() * minf(v.length(), 1.0) * speed * delta
		var before := p.pos
		_try_move(Vector2(step.x, 0))
		_try_move(Vector2(0, step.y))
		walk_stuck = walk_stuck + delta if p.pos.distance_to(before) < step.length() * 0.3 else 0.0
		player_sprite.face(v)
		player_sprite.play("walk")
	elif player_sprite.anim == "walk":
		player_sprite.play("idle")
	_find_target()
	if Input.is_action_just_pressed("interact"):
		interact()
	if Input.is_action_just_pressed("attack"):
		attack()
	if Input.is_action_just_pressed("fireball"):
		fireball()
	if Input.is_action_just_pressed("inventory"):
		ui.toggle_inventory()
	if Input.is_action_just_pressed("skills"):
		ui.toggle_skills()
	if Input.is_action_just_pressed("journal"):
		ui.show_journal(-1)


## The direction to walk this frame towards move_to, around walls and trees: the route comes
## from the map's pathfinder and is found again when the goal moves to another cell or the player
## gets stuck. Arriving (or finding no way) clears move_to.
func _route_step(_delta: float) -> Vector2:
	var p := world.player
	var goal := Vector2i(floori(move_to.x), floori(move_to.y))
	if goal != walk_goal or walk_stuck > 0.5:
		walk_goal = goal
		walk_stuck = 0.0
		walk_path = map.find_path(Vector2i(floori(p.pos.x), floori(p.pos.y)), goal)
		walk_i = 1                       # the first point is the cell the player stands in
		if walk_path.is_empty():
			move_to = Vector2.INF
			walk_goal = Vector2i(-1, -1)
			return Vector2.ZERO
	# the last stretch goes to the exact point; before it, to the centre of each cell on the way
	var target := move_to if walk_i >= walk_path.size() - 1 else walk_path[walk_i] + Vector2(0.5, 0.5)
	if map.is_solid(goal) and walk_i >= walk_path.size() - 1:
		target = walk_path[walk_path.size() - 1] + Vector2(0.5, 0.5)
	var d := target - p.pos
	if d.length() < 0.15:
		if walk_i >= walk_path.size() - 1:
			move_to = Vector2.INF
			walk_goal = Vector2i(-1, -1)
			return Vector2.ZERO
		walk_i += 1
		return _route_step(_delta)
	return d.normalized()


## Walk up to a tapped villager, following as they move, and talk once beside them.
func _talk_step() -> void:
	if talk_to == null:
		return
	if not talk_to.alive or talk_to.hidden or talk_to.pos.distance_to(world.player.pos) > 25.0:
		talk_to = null
		move_to = Vector2.INF
		return
	var d := talk_to.pos - world.player.pos
	if d.length() > 1.3:
		move_to = talk_to.pos
		return
	move_to = Vector2.INF
	player_sprite.face(d)
	var who := talk_to
	talk_to = null
	approach(who)


func _try_move(step: Vector2) -> void:
	var p := world.player
	var np := p.pos + step
	for c in [Vector2(-0.3, -0.15), Vector2(0.3, -0.15), Vector2(-0.3, 0.2), Vector2(0.3, 0.2)]:
		var q: Vector2 = np + c
		if map.is_solid(Vector2i(floori(q.x), floori(q.y))):
			return
	p.pos = np


func facing_vec() -> Vector2:
	var a := float(player_sprite.dir) * TAU / 8.0
	return Vector2(sin(a), cos(a))


func _find_target() -> void:
	var p := world.player
	var probe := p.pos + facing_vec() * 0.9
	var best := {}
	var bd := 1.5
	for n: NPC in world.near(p.pos, 2.5):
		var d := n.pos.distance_to(probe)
		if d < bd:
			bd = d
			best = {"kind": "npc", "npc": n, "label": "Talk to %s" % _who(n)}
	for i in world.loot.size():
		var d: float = world.loot[i].pos.distance_to(probe)
		if d < bd:
			bd = d
			var from: String = world.loot[i].from
			best = {"kind": "loot", "i": i, "label": ("Take what is left of %s" % from) if from.begins_with("the ") else ("Search %s's belongings" % from)}
	for a: Animal in world.fauna.near(probe, 1.2):
		var d := a.pos.distance_to(probe)
		if d < bd:
			bd = d
			var what := "%s (%s%s)" % [a.label().to_lower(), "young, " if not a.adult(world.minutes) else "", "male" if a.sex == "m" else "female"]
			best = {"kind": "animal", "animal": a, "label": ("A " if a.wild() else "The keeper's ") + what + (": attack to hunt it" if a.wild() else "")}
	var c := Vector2i(floori(probe.x), floori(probe.y))
	if best.is_empty():
		for dc in [Vector2i.ZERO, Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1)]:
			var cell: Vector2i = c + dc
			var dep := world.deposit_at(cell)
			if not dep.is_empty() and int(dep.amount) > 0:
				best = {"kind": "deposit", "dep": dep, "label": "Mine %s (%d left)" % [GameData.item_name(dep.ore).to_lower(), int(dep.amount)]}
				break
			var tr := world.tree_at(cell)
			if not tr.is_empty() and tr.state == "grown":
				best = {"kind": "tree", "tree": tr, "label": "Fell this tree"}
				break
			for f in world.fields:
				if f.state == "ripe" and Rect2i(int(f.x), int(f.y), int(f.w), int(f.h)).has_point(cell):
					var whose := ""
					for o in f.owner:
						var fo := world.npc(int(o))
						if fo and fo.alive:
							whose = "%s %s's" % [fo.name, fo.family]
							break
					best = {"kind": "field", "field": f, "label": "Harvest wheat (%d left)%s" % [int(f.get("crop", 0)), ("  —  " + whose + " field: taking it is theft") if whose != "" else ""]}
					break
			if not best.is_empty():
				break
	if best.is_empty():
		for id in world.stations:
			var st: Dictionary = world.stations[id]
			var u := Vector2(int(st.use[0]) + 0.5, int(st.use[1]) + 0.5)
			if u.distance_to(p.pos) < 1.2 and st.type in ["forge", "anvil", "workbench", "sawhorse", "stove", "oven"]:
				best = {"kind": "station", "id": id, "label": "Use the %s" % st.type}
		for pl in world.plots:
			var r := Rect2(Vector2(pl.x, pl.y), Vector2(pl.w, pl.h + 1))
			if r.has_point(p.pos):
				var lab := "Building plot (%d coins)" % int(pl.price) if pl.owner == "" else ("Your building site" if not pl.site.get("done", false) else "Your house")
				best = {"kind": "plot", "plot": pl, "label": lab}
		for id in world.fauna.pens:
			var pen: Dictionary = world.fauna.pens[id]
			var fa := Vector2(int(pen.feed_at[0]) + 0.5, int(pen.feed_at[1]) + 0.5)
			if fa.distance_to(p.pos) < 1.3:
				best = {"kind": "pen", "pen": pen, "label": "%s pen: %d hungry, trough %d wheat (they eat about %d a day). Feed them" % [GameData.b("animals")[pen.kind].name, world.fauna.hungry(pen), int(pen.trough), world.fauna.daily_need(pen)]}
		if p.home != "" and world.buildings.has(p.home):
			var door := Vector2(world.building_door(p.home)) + Vector2(0.5, 0.5)
			if door.distance_to(p.pos) < 1.3:
				best = {"kind": "home", "label": "Your house: rest, store things"}
	target = best
	ui.prompt(target.get("label", ""))


func _who(n: NPC) -> String:
	if n.role == "bandit":
		return n.name
	return "%s %s" % [n.name, n.family]


func interact() -> void:
	if target.is_empty():
		return
	var p := world.player
	match target.kind:
		"npc":
			approach(target.npc)
		"loot":
			var l: Dictionary = world.loot[target.i]
			var taken: int = l.inv.total()
			for id in l.inv.ids():
				var n: int = l.inv.count(id)
				if p.inv.add(id, n):
					l.inv.remove(id, n)
			taken -= l.inv.total()
			p.coins += int(l.coins)
			ui.message("You take %d coins and %d items." % [int(l.coins), taken])
			l.coins = 0
			if l.inv.total() == 0:
				world.loot.remove_at(target.i)
		"deposit":
			var dep: Dictionary = target.dep
			var pick := p.tool_of("pickaxe")
			if pick == "":
				ui.message("You need a pickaxe. The smith sells them.")
				return
			if dep.ore == "gold_ore" and p.level("mining") < 3:
				ui.message("Gold needs Mining level 3.")
				return
			var secs := float(GameData.b("mine_minutes")) / float(GameData.b("game_minutes_per_second")) * 0.6 / float(GameData.item(pick).get("speed", 1.0))
			start_action("Mining", secs, func():
				var ore := world.mine_unit(dep)
				if ore == "":
					ui.message("The seam is worked out.")
					return
				var n := 1
				if p.level("mining") >= 2 and world.rng.randf() < 0.25:
					var extra := world.mine_unit(dep)
					if extra != "":
						n += 1
				if not p.inv.add(ore, n):
					ui.message("Your pack is full.")
				if p.inv.wear(pick, 1 if p.level("mining") < 4 or world.rng.randf() < 0.5 else 0):
					ui.message("Your %s broke." % GameData.item_name(pick).to_lower())
					if p.tool == pick:
						p.tool = ""
				ui.message("Mined %d %s." % [n, GameData.item_name(ore).to_lower()])
				_xp("mining", 8 * n))
		"tree":
			var axe := p.tool_of("axe")
			if axe == "":
				ui.message("You need an axe. The smith sells them.")
				return
			var secs := float(GameData.b("chop_minutes")) / float(GameData.b("game_minutes_per_second")) * 0.5 / float(GameData.item(axe).get("speed", 1.0))
			if p.level("woodcutting") >= 3:
				secs *= 0.7
			var tr: Dictionary = target.tree
			start_action("Felling", secs, func():
				var logs := world.fell(tr, 1 if p.level("woodcutting") >= 2 else 0)
				if logs > 0:
					if not p.inv.add("log", logs):
						ui.message("Your pack is full.")
					p.inv.wear(axe, 3)
					ui.message("Felled the tree: %d logs." % logs)
					_xp("woodcutting", 12))
		"station":
			ui.show_craft(target.id)
		"field":
			var f: Dictionary = target.field
			start_action("Harvesting", 2.5, func():
				var got := world.player_harvest(f)
				ui.message("You gather %d wheat." % got if got > 0 else "Nothing left to harvest."))
		"pen":
			var put := world.fauna.feed(target.pen, p.inv, 5)
			ui.message("You put %d wheat in the trough." % put if put > 0 else "You have no wheat to feed them.")
		"animal":
			ui.message("Attack (Space) to hunt it." if target.animal.wild() else "These belong to the keeper. Killing them is theft.")
		"plot":
			ui.show_build(target.plot)
		"home":
			ui.show_home()


func start_action(label: String, secs: float, done: Callable) -> void:
	action = {"label": label, "left": secs, "total": secs, "done": done}
	move_to = Vector2.INF


func _xp(skill: String, n: int) -> void:
	var up := world.player.gain(skill, n)
	if up > 0:
		var s: Dictionary = GameData.skills[skill]
		var unlock: String = s.unlocks.get(str(up), "")
		ui.message("%s is now level %d!%s" % [s.name, up, (" Unlocked: " + unlock) if unlock != "" else ""])


## Craft a recipe at a station (called from the craft panel). Same recipe data as the NPCs.
func craft(recipe: String) -> void:
	var r: Dictionary = GameData.recipes[recipe]
	var p := world.player
	if p.level(r.skill) < int(r.level):
		ui.message("Needs %s level %d." % [GameData.skills[r.skill].name, int(r.level)])
		return
	if not p.inv.has_all(r.in):
		ui.message("You do not have the materials.")
		return
	var secs := float(r.minutes) / float(GameData.b("game_minutes_per_second")) * 0.5
	ui.hide_all()
	start_action("Crafting", secs, func():
		if not p.inv.remove_all(r.in):
			return
		for id in r.out:
			p.inv.add(id, int(r.out[id]))
		_xp(r.skill, int(r.xp))
		ui.message("Made %s." % ", ".join(r.out.keys().map(func(k): return GameData.item_name(k)))))


# ---------------------------------------------------------------- combat ---------------------
## A swing of the weapon at whatever is in front; with `only`, it can hit nobody else.
func attack(only: Object = null) -> void:
	var p := world.player
	if p.attack_cd > 0.0 or not action.is_empty():
		return
	p.attack_cd = 0.6
	player_sprite.play("sword", true)
	var probe := p.pos + facing_vec() * 0.8
	for n: NPC in world.near(probe, 1.1):
		if only == null or only == n:
			_hit(n, p.damage())
			_xp("combat", 4)
			return
	for a: Animal in world.fauna.near(probe, 1.1):
		if only == null or only == a:
			_hit_animal(a, p.damage())
			return


## The touch Attack button: fight a foe within reach (a bandit, someone fighting you, or game);
## with none, wait for a tap on who or what to attack. Villagers are only attacked by choice.
func attack_button() -> void:
	attack_mode = not attack_mode
	if not attack_mode:
		chase = null
		strike_pending = false
	ui.set_attack_mode(attack_mode)
	ui.message("Attack mode: tap who or what to attack. Tap Attack again to stop." if attack_mode else "Attack mode off.")


## Mark a person or animal with the sword and strike it: the player walks over if needed. Each
## further tap (or right-click) on it is another strike; picking someone else moves the sword.
func strike(who: Object) -> void:
	chase = who
	strike_pending = true


## The person or animal drawn at a map position (sprites stand above their feet), or null.
func _creature_at(wpos: Vector2) -> Object:
	var at := wpos + Vector2(0, 0.4)
	var best: Object = null
	var bd := 0.9
	for n: NPC in world.near(at, bd):
		if not n.hidden and n.pos.distance_to(at) < bd:
			bd = n.pos.distance_to(at)
			best = n
	for a: Animal in world.fauna.near(at, bd):
		if a.pos.distance_to(at) < bd:
			bd = a.pos.distance_to(at)
			best = a
	return best


## Follow the marked target, and strike when a strike is pending and it is in reach. The mark is
## dropped when it falls, hides indoors or gets away.
func _chase_step() -> void:
	if chase == null:
		return
	var p := world.player
	if not chase.alive or (chase is NPC and chase.hidden) or chase.pos.distance_to(p.pos) > 12.0:
		chase = null
		strike_pending = false
		move_to = Vector2.INF
		return
	var d: Vector2 = chase.pos - p.pos
	if d.length() > 1.0:
		move_to = chase.pos
		return
	move_to = Vector2.INF
	if strike_pending and p.attack_cd <= 0.0 and action.is_empty():
		player_sprite.face(d)
		attack(chase)
		strike_pending = false


## Hunting: a wild animal killed by the player leaves its meat (and hide) where it fell. Killing
## livestock is theft from its keeper, a crime like attacking a villager.
func _hit_animal(a: Animal, dmg: float) -> void:
	a.hp -= dmg
	_xp("combat", 2)
	if a.hp > 0.0:
		return
	var keeper: NPC = null
	if not a.wild():
		keeper = world.npc(int(world.fauna.pens[a.area].owner))
	var what := a.label().to_lower()
	var bag: Inventory = world.fauna.kill(a)
	world.loot.append({"pos": a.pos, "inv": bag, "coins": 0, "from": "the " + what})
	if keeper != null:
		_crime(keeper)
		world.note("%s %s killed one of %s %s's animals." % [world.player.name, world.player.family, keeper.name, keeper.family])


func _hit(n: NPC, dmg: float) -> void:
	n.hp -= maxf(0.5, dmg - n.armor * 0.5)
	if n.role != "bandit":
		_crime(n)
	elif n.target == -1:
		n.target = -2
	if n.hp <= 0.0:
		world.kill(n, "slain by %s %s" % [world.player.name, world.player.family])


## Attacking a villager is a crime: guards who see it and adults who are hit fight back.
func _crime(victim: NPC) -> void:
	victim.remember("attacked by %s" % world.player.name)
	if victim.role == "adult":
		victim.target = -2
	for g: NPC in world.near(victim.pos, 15.0):
		if g.job == "guard":
			g.target = -2
	world.note("%s %s attacked %s %s." % [world.player.name, world.player.family, victim.name, victim.family])


func fireball() -> void:
	var p := world.player
	if not p.spells.get("fireball", false):
		ui.message("You do not know any spells. The Sage in the hut north of the tavern teaches them.")
		return
	var cd := float(GameData.b("fireball_cooldown"))
	if p.level("magic") >= 2:
		cd = 4.0
	if p.fireball_cd > 0.0 or p.stamina < float(GameData.b("fireball_stamina")):
		return
	p.fireball_cd = cd
	p.stamina -= float(GameData.b("fireball_stamina"))
	player_sprite.play("throw", true)
	var node := Sprite2D.new()
	node.texture = load("res://assets/icons/fireball.png")
	node.z_index = 5
	actors.add_child(node)
	projectiles.append({"node": node, "pos": p.pos + facing_vec() * 0.6, "dir": facing_vec(), "left": 8.0})
	_xp("magic", 6)


func _projectiles_step(delta: float) -> void:
	for pr in projectiles.duplicate():
		var step: Vector2 = pr.dir * 9.0 * delta
		pr.pos += step
		pr.left -= step.length()
		pr.node.position = pr.pos * T
		pr.node.rotation += delta * 12.0
		var hit := false
		var dmg := 14.0 * (1.5 if world.player.level("magic") >= 3 else 1.0)
		for n: NPC in world.near(pr.pos, 0.6):
			_hit(n, dmg)
			hit = true
			break
		if not hit:
			for a: Animal in world.fauna.near(pr.pos, 0.6):
				_hit_animal(a, dmg)
				hit = true
				break
		if hit or pr.left <= 0.0 or map.is_solid(Vector2i(floori(pr.pos.x), floori(pr.pos.y))):
			pr.node.queue_free()
			projectiles.erase(pr)


# ---------------------------------------------------------------- touch ----------------------
func _unhandled_input(e: InputEvent) -> void:
	if world == null:
		return
	if e is InputEventScreenTouch:
		if e.pressed:
			touch_points[e.index] = e.position
			if touch_points.size() == 2:
				pinch_start = touch_points.values()[0].distance_to(touch_points.values()[1])
				zoom_start = camera.zoom.x
		else:
			touch_points.erase(e.index)
			if touch_points.is_empty() and not ui.modal():
				_tap(e.position)
	elif e is InputEventScreenDrag:
		touch_points[e.index] = e.position
		if touch_points.size() == 2 and pinch_start > 0.0:
			var d: float = touch_points.values()[0].distance_to(touch_points.values()[1])
			_set_zoom(zoom_start * d / pinch_start)
	elif e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(camera.zoom.x * 1.1)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(camera.zoom.x / 1.1)
		elif e.button_index == MOUSE_BUTTON_LEFT and e.device != InputEvent.DEVICE_ID_EMULATION and not ui.modal():
			_tap(e.position)
		elif e.button_index == MOUSE_BUTTON_RIGHT and not ui.modal() and not paused:
			# right-click: strike whoever is under the pointer, without attack mode
			var who := _creature_at((get_canvas_transform().affine_inverse() * e.position) / T)
			if who != null:
				strike(who)
	if e is InputEventJoypadButton and e.is_action_pressed("ui_cancel") and ui.modal() and not ui.panel_kind in ["title", "creation", "origin", "death"]:
		ui.hide_all()
	if e.is_action_pressed("zoom_in"):
		_set_zoom(camera.zoom.x * 1.2)
	if e.is_action_pressed("zoom_out"):
		_set_zoom(camera.zoom.x / 1.2)
	if e.is_action_pressed("pause"):
		if ui.modal():
			ui.hide_all()
		elif running:
			ui.show_pause()


## Which controls are in use, from the latest input: the HUD follows (touch buttons, prompts).
func _input(e: InputEvent) -> void:
	var s := scheme
	if e is InputEventScreenTouch or e is InputEventScreenDrag:
		s = "touch"
	elif e is InputEventJoypadButton or (e is InputEventJoypadMotion and absf(e.axis_value) > 0.5):
		s = "gamepad"
	elif e is InputEventKey and get_viewport().gui_get_focus_owner() is LineEdit:
		pass                          # typing into a text box (a phone's on-screen keyboard sends keys too)
	elif e is InputEventKey or (e is InputEventMouseButton and e.device != InputEvent.DEVICE_ID_EMULATION) \
			or (e is InputEventMouseMotion and e.device != InputEvent.DEVICE_ID_EMULATION and e.relative.length() > 3.0):
		s = "kbm"
	if s != scheme:
		scheme = s
		ui.set_scheme(s)


## A changed interface size: relayout, and keep the map the same size on screen.
func apply_settings() -> void:
	settings.apply(get_tree())
	var vs := settings.layout_height() / 720.0
	if camera:
		camera.zoom *= vs / view_scale
	view_scale = vs
	settings.save_file()
	ui.set_scheme(scheme)


func _set_zoom(z: float) -> void:
	z = clampf(z, 1.5 * view_scale, 6.0 * view_scale)
	camera.zoom = Vector2(z, z)


## Tap or click: on something next to the player, act on it; elsewhere, walk there.
func _tap(screen_pos: Vector2) -> void:
	if world == null or paused:
		return
	if ui.blocks(screen_pos):
		return
	var wpos := (get_canvas_transform().affine_inverse() * screen_pos) / T
	if attack_mode:
		var who := _creature_at(wpos)
		if who != null:
			strike(who)
			return
		chase = null                  # open ground: walk there, still in attack mode
		strike_pending = false
		move_to = wpos
		return
	chase = null
	talk_to = null
	var tapped := _creature_at(wpos)
	if tapped is NPC and tapped.role != "bandit":
		talk_to = tapped                  # walk up to them (following if they move) and talk
		return
	if wpos.distance_to(world.player.pos) < 1.8:
		player_sprite.face(wpos - world.player.pos)
		_find_target()
		if not target.is_empty():
			interact()
			return
	move_to = wpos


# ---------------------------------------------------------------- saving ---------------------
func save_game(show := true) -> void:
	if world == null or not world.player.alive:
		return
	var tmp := SAVE_PATH + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		ui.message("Could not save: %s" % error_string(FileAccess.get_open_error()))
		return
	f.store_string(JSON.stringify(world.to_dict(), "", true, true))          # full precision: times and positions reload exactly
	f.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(SAVE_PATH))
	if show:
		ui.message("Saved.")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if running:
			save_game(false)


func continue_as_heir() -> void:
	world.continue_as_heir()
	player_sprite.setup(world.player.sprite)
	player_sprite.play("idle")
	ui.hide_all()
	save_game(false)


## Sleep at home until morning: the world keeps running (same rules), just quickly.
func rest() -> void:
	var p := world.player
	var h := world.hour()
	var until := 6.0 if h < 6.0 else 30.0
	var mins := (until - h) * 60.0 if h >= 18.0 or h < 6.0 else 120.0
	var steps := int(mins / float(GameData.b("game_minutes_per_second")) / 0.5)
	for i in steps:
		world.update(0.5)
	p.hp = p.max_hp
	p.stamina = 100.0
	ui.message("You rest. It is now %s." % world.clock_text())
	save_game(false)


# ---------------------------------------------------------------- screenshots ----------------
func _screenshot_step(_delta: float) -> void:
	shot_frames += 1
	if shot_frames == 30:
		var img := get_viewport().get_texture().get_image()
		img.save_png(shot_path)
		print("screenshot saved to ", shot_path)
		get_tree().quit()
