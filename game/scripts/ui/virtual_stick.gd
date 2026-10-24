class_name VirtualStick
extends Control
## GP-JOYSTICK (owner, 2026-10-24): the optional on-screen thumbstick for touch (Settings, Interface, "Moving by touch":
## tap, the default, or joystick). A finger put down on it and dragged presses the same move actions a keyboard or a
## gamepad's stick presses (Input.action_press with the push's strength), so walking keeps one path: Main._player_step
## and the world's own speed, collision and navigation rules (GP-INPUT-CONSIST). Lifting the finger, a window opening or
## the stick hiding releases every action. Drawn in the game's wood and parchment colours, in the HUD's lower-left
## corner inside the safe area.

const RADIUS := 52.0                # the base ring (interface units)
const KNOB := 22.0
const DEAD := 0.18                  # a push smaller than this is no push
const ACTIONS := {"move_left": Vector2.LEFT, "move_right": Vector2.RIGHT, "move_up": Vector2.UP, "move_down": Vector2.DOWN}

var finger := -1                    # the touch index holding it, -1 for none
var push := Vector2.ZERO            # -1..1 each way


func _init() -> void:
	name = "VirtualStick"
	custom_minimum_size = Vector2(RADIUS, RADIUS) * 2.0 + Vector2(8, 8)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP


func centre() -> Vector2:
	return size / 2.0


func _gui_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		if e.pressed and finger == -1:
			finger = e.index
			_aim(e.position)
		elif not e.pressed and e.index == finger:
			release()
		accept_event()
	elif e is InputEventScreenDrag and e.index == finger:
		_aim(e.position)
		accept_event()


## The push from a finger at `local` (the stick's own coordinates).
func _aim(local: Vector2) -> void:
	var v := (local - centre()) / RADIUS
	push = v.limit_length(1.0)
	_apply()
	queue_redraw()


func _apply() -> void:
	for a in ACTIONS:
		var s: float = maxf(0.0, push.dot(ACTIONS[a]))
		if push.length() >= DEAD and s > 0.05:
			Input.action_press(a, clampf(s, 0.0, 1.0))
		elif Input.is_action_pressed(a):
			Input.action_release(a)


## Let go: every move action released, the knob back in the middle.
func release() -> void:
	finger = -1
	push = Vector2.ZERO
	for a in ACTIONS:
		if Input.is_action_pressed(a):
			Input.action_release(a)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree() and finger != -1:
		release()


func _draw() -> void:
	var c := centre()
	draw_circle(c, RADIUS, Color8(43, 29, 19, 150))
	draw_arc(c, RADIUS, 0.0, TAU, 48, Color8(236, 214, 170, 200), 2.0)
	draw_circle(c + push * (RADIUS - KNOB * 0.5), KNOB, Color8(111, 74, 44, 230))
	draw_arc(c + push * (RADIUS - KNOB * 0.5), KNOB, 0.0, TAU, 32, Color8(236, 214, 170, 230), 2.0)
