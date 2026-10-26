class_name LockpickWindow
extends VBoxContainer
## GP-LOCKPICK (owner directive 2026-10-24 section 2; amendment 2026-10-26 section 13): the pin-tumbler lockpicking
## minigame, in place of the old passive meter. A cutaway of the lock, drawn in the game's own pixel style (not the
## reference picture): the housing with one chamber per tumbler, in each a spring, a steel driver pin and a brass key
## pin, the gold setting (shear) line across them, and the lockpick reaching in from the left to lift the pin it works.
## The rules are LockpickPlay's; this window draws them and takes the inputs.
##
## Every tumbler has its own input and its own column, all the same size whatever the lock (never smaller for a harder
## one), side by side with a gap between them, so one touch or click lands on one tumbler only; the whole column is the
## target. Pad: A, B, X, Y, then LB and RB for a fifth and sixth tumbler; keyboard 1 to 6; the prompt is under each
## column. Every press event is taken once, in _input, as it arrives (rapid alternating presses are neither dropped nor
## doubled) and marked handled, so it never reaches the window's other controls or the world. Stop: the Stop button,
## Esc, the pad's Menu or View button, or the window's X; stopping, or anything else closing the window, leaves the
## lock as it was: no attempt is made and nothing is recorded (as the old meter's cancel). The world is not paused.
##
## On the end of a game `finished` is emitted once with "open" or "fail"; Main then makes the one attempt through
## World.player_pick_lock (host authoritative in a shared world), which keeps the existing rules: the lock open until
## dawn, a snapped pick on a failure by the existing chance, the witnesses, the crime and the Stealth experience.

signal finished(result: String)
signal stopped

const PAD := [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_Y, JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]
const PAD_ICON := ["xbox_button_a", "xbox_button_b", "xbox_button_x", "xbox_button_y", "xbox_lb", "xbox_rb"]
const KEYS := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6]
const COL_W := 92.0              # every tumbler's column, the same at every difficulty
const COL_GAP := 10.0
const ART_H := 236.0
const SET_Y := 104.0             # the setting (shear) line, from the top of the art
const LIFT := 34.0               # how far a pin rises from rest to the line
const STEEL := Color8(150, 156, 166)
const STEEL_DARK := Color8(78, 82, 92)
const BRASS := Color8(214, 168, 64)
const BRASS_DARK := Color8(132, 96, 30)
const HOUSING := Color8(96, 100, 110)
const HOUSING_DARK := Color8(52, 54, 62)
const PLUG := Color8(176, 136, 60)
const LINE := Color8(255, 214, 92)
const SPRING := Color8(200, 204, 212)

var play: LockpickPlay
var art: Control
var columns: Array = []          # one Button per tumbler (its whole column)
var status: Label
var scheme := "kbm"
var flash: Array = []            # per pin: seconds of the catch flash left
var _done := false
var sounds := Callable()         # optional: (id: String) -> void, the game's sound effects


func setup(p: LockpickPlay, p_scheme: String) -> LockpickWindow:
	play = p
	scheme = p_scheme
	name = "LockpickWindow"
	add_theme_constant_override("separation", 6)
	for i in play.n:
		flash.append(0.0)
	var help := Label.new()
	help.text = "Each pin is lifted to the gold line by the pick and wobbles there: catch it with its own %s before it drops. Keep every pin set until the lock turns." % \
		{"gamepad": "button", "touch": "tap", "kbm": "key or click"}.get(scheme, "input")
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_font_size_override("font_size", 15)
	add_child(help)
	var holder := CenterContainer.new()
	add_child(holder)
	var box := Control.new()
	var w := play.n * COL_W + (play.n - 1) * COL_GAP + 48.0
	box.custom_minimum_size = Vector2(w, ART_H + 48.0)
	holder.add_child(box)
	art = Control.new()
	art.position = Vector2.ZERO
	art.size = Vector2(w, ART_H)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.draw.connect(_draw_lock)
	box.add_child(art)
	for i in play.n:
		var b := Button.new()
		b.name = "Tumbler%d" % (i + 1)
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE                # the pad's buttons are the tumblers: no focus to move
		b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS     # at the touch, not on release
		b.position = Vector2(_col_x(i), 0)
		b.size = Vector2(COL_W, ART_H + 48.0)
		var empty := StyleBoxEmpty.new()
		for st in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
			b.add_theme_stylebox_override(st, empty)
		var k := i
		b.pressed.connect(func(): _press(k))
		var icon := TextureRect.new()
		var path := "res://assets/prompts/%s.png" % _prompt(i)
		if ResourceLoader.exists(path):
			icon.texture = load(path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.position = Vector2((COL_W - 40.0) / 2.0, ART_H + 4.0)
		icon.size = Vector2(40, 40)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(icon)
		box.add_child(b)
		columns.append(b)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 16)
	add_child(status)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(row)
	var stop := Button.new()
	stop.name = "Stop"
	stop.text = "Stop" + {"gamepad": " (Menu)", "kbm": " (Esc)"}.get(scheme, "")
	stop.custom_minimum_size = Vector2(160, 44)
	stop.pressed.connect(stop_now)                    # (the pad's A, B, X, Y never reach it: _input takes them first)
	row.add_child(stop)
	_status()
	return self


func _prompt(i: int) -> String:
	match scheme:
		"gamepad":
			return PAD_ICON[i]
		"touch":
			return "touch_tap"
	return "keyboard_%d" % (i + 1)


func _col_x(i: int) -> float:
	return 24.0 + i * (COL_W + COL_GAP)


## The column a point (in the art's own coordinates) falls in, -1 for none (the gaps and the margins).
func column_at(p: Vector2) -> int:
	for i in play.n:
		if Rect2(_col_x(i), 0, COL_W, ART_H + 48.0).has_point(p):
			return i
	return -1


func _process(dt: float) -> void:
	if play == null or _done:
		return
	play.step(dt)
	for i in flash.size():
		flash[i] = maxf(0.0, flash[i] - dt)
	for e in play.take_events():
		match str(e[0]):
			"catch":
				flash[int(e[1])] = 0.25
				_sound("hit_on_brick_1")
			"fall":
				_sound("fruit_drop_1")
			"miss":
				_sound("hit_on_wood_1")
	_status()
	art.queue_redraw()
	if play.result != "":
		_done = true
		finished.emit(play.result)


func _sound(id: String) -> void:
	if sounds.is_valid():
		sounds.call(id)


func _status() -> void:
	var set := 0
	for s in play.state:
		if s == LockpickPlay.SET:
			set += 1
	status.text = "Pins set: %d of %d  ·  caught %d  ·  dropped %d (the pick bears %d)" % [set, play.n, play.caught, play.fallen, play.falls]


## One tumbler's input. Every press reaches here once (a button's signal or _input), never two tumblers at once.
func _press(i: int) -> void:
	if _done or play == null:
		return
	play.press(i)


func _input(e: InputEvent) -> void:
	if _done or not is_visible_in_tree():
		return
	if e is InputEventJoypadButton and e.pressed:
		var i := PAD.find(e.button_index)
		if i >= 0 and i < play.n:
			_press(i)
			get_viewport().set_input_as_handled()
		elif i >= 0 or e.button_index in [JOY_BUTTON_START, JOY_BUTTON_BACK]:
			if e.button_index in [JOY_BUTTON_START, JOY_BUTTON_BACK]:
				stop_now()
			get_viewport().set_input_as_handled()        # a fifth or sixth button on a smaller lock: nothing, and not the world's
	elif e is InputEventKey and e.pressed and not e.echo:
		var k := KEYS.find(e.physical_keycode)
		if k >= 0 and k < play.n:
			_press(k)
			get_viewport().set_input_as_handled()
		elif e.physical_keycode == KEY_ESCAPE:
			stop_now()
			get_viewport().set_input_as_handled()


## Stop without an attempt: the lock stays as it was, nothing is recorded.
func stop_now() -> void:
	if _done:
		return
	_done = true
	stopped.emit()


# ---------------------------------------------------------------- drawing --------------------
func _draw_lock() -> void:
	var c := art
	var w := c.size.x
	c.draw_rect(Rect2(0, 0, w, ART_H), HOUSING_DARK)
	c.draw_rect(Rect2(4, 4, w - 8, SET_Y - 4), HOUSING)                         # the housing over the line
	c.draw_rect(Rect2(4, SET_Y, w - 8, ART_H - SET_Y - 4), PLUG)               # the plug (the key's way) under it
	c.draw_rect(Rect2(4, SET_Y + 92, w - 8, 18), PLUG.darkened(0.35))          # the keyway the pick comes in by
	var active := -1
	for i in play.n:
		var x0 := _col_x(i)
		var cx := x0 + COL_W / 2.0
		var st: int = play.state[i]
		var h := play.height(i)
		var wob := play.wobble(i)
		var jit := 0.0
		if st == LockpickPlay.WOBBLE:
			active = i
			jit = sin(play.t * lerpf(14.0, 40.0, wob)) * lerpf(1.5, 3.5, wob)   # faster and wider as the window runs out
		elif st == LockpickPlay.RISING:
			active = i
		# the chamber
		var warn := st == LockpickPlay.WOBBLE
		c.draw_rect(Rect2(cx - 17, 10, 34, SET_Y + 84), Color8(232, 120, 40) if warn else HOUSING_DARK)
		c.draw_rect(Rect2(cx - 15, 12, 30, SET_Y + 80), Color8(28, 28, 34))
		var junction := SET_Y + LIFT * (1.0 - h)                                 # where driver and key pin meet
		var drv_top := junction - 30.0
		# the spring, from the chamber's top to the driver pin
		var pts := PackedVector2Array()
		var coils := 7
		for k in coils * 2 + 1:
			var y := lerpf(14.0, drv_top, float(k) / float(coils * 2))
			pts.append(Vector2(cx + jit + (8.0 if k % 2 == 0 else -8.0), y))
		c.draw_polyline(pts, SPRING, 2.0)
		# the driver pin (steel) and the key pin (brass)
		c.draw_rect(Rect2(cx - 11 + jit, drv_top, 22, 30), STEEL_DARK)
		c.draw_rect(Rect2(cx - 10 + jit, drv_top + 1, 18, 28), STEEL)
		c.draw_rect(Rect2(cx - 11 + jit, junction, 22, 34), BRASS_DARK)
		c.draw_rect(Rect2(cx - 10 + jit, junction + 1, 18, 30), BRASS)
		c.draw_rect(Rect2(cx - 6 + jit, junction + 31, 10, 4), BRASS_DARK)      # its rounded tip
		# set: a green light over the chamber; a catch flashes it
		if st == LockpickPlay.SET:
			c.draw_rect(Rect2(cx - 8, 0, 16, 8), Color8(96, 214, 96).lerp(Color.WHITE, flash[i] * 3.0))
		elif st == LockpickPlay.WOBBLE:
			c.draw_rect(Rect2(cx - 8, 0, 16, 8), Color8(255, 150, 40).lerp(Color8(230, 40, 30), wob))
	# the setting line across every chamber
	c.draw_rect(Rect2(4, SET_Y - 1, w - 8, 3), LINE)
	# the lockpick: in from the left along the keyway, its tip raised under the pin it works
	var tip_x := _col_x(active) + COL_W / 2.0 if active >= 0 else 30.0
	var tip_y := SET_Y + LIFT * (1.0 - (play.height(active) if active >= 0 else 0.0)) + 36.0
	c.draw_line(Vector2(0, SET_Y + 102), Vector2(tip_x - 14, SET_Y + 102), STEEL_DARK, 5.0)
	c.draw_line(Vector2(0, SET_Y + 101), Vector2(tip_x - 14, SET_Y + 101), STEEL, 2.0)
	c.draw_line(Vector2(tip_x - 14, SET_Y + 102), Vector2(tip_x, tip_y), STEEL_DARK, 5.0)
	c.draw_line(Vector2(tip_x - 14, SET_Y + 101), Vector2(tip_x, tip_y - 1), STEEL, 2.0)
