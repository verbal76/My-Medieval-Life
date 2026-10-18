class_name SpeechBubble
extends PanelContainer
## A comic-book speech bubble over a villager's head: dark ink on parchment, rounded, with a tail
## pointing down at the speaker. Drawn on a screen-space layer (sharp text at any zoom) and placed
## each frame from the speaker's map position. It stays SECONDS, fading out over the last FADE.

const SECONDS := 2.5
const FADE := 0.5
const TAIL := 10.0
const PAPER := Color8(236, 222, 186)
const INK := Color8(58, 38, 22)
const RIM := Color8(120, 84, 48)

var npc_id := -1
var left := SECONDS
var label: Label
var tip_x := 0.0          # where the tail meets the bubble, from its left edge


func setup(id: int, text: String, font_size: int) -> void:
	npc_id = id
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s := StyleBoxFlat.new()
	s.bg_color = PAPER
	s.border_color = RIM
	s.set_border_width_all(2)
	s.set_corner_radius_all(10)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	add_theme_stylebox_override("panel", s)
	label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", INK)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	say(text)


## Show a (new) line and start the time again: one line when it fits, wrapped to a narrow bubble
## when it does not.
func say(text: String) -> void:
	label.text = text
	var font_size := label.get_theme_font_size("font_size")
	var wide := label.get_theme_font("font").get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var most := font_size * 16.0
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wide > most else TextServer.AUTOWRAP_OFF
	label.custom_minimum_size = Vector2(most if wide > most else 0.0, 0)
	left = SECONDS
	modulate.a = 1.0


## Count down; false once it has gone.
func tick(delta: float) -> bool:
	left -= delta
	modulate.a = clampf(left / FADE, 0.0, 1.0)
	return left > 0.0


## Put the tail's tip at this screen point (just above the speaker's head).
func point_at(tip: Vector2) -> void:
	reset_size()
	var at := tip - Vector2(size.x / 2.0, size.y + TAIL)
	var screen := get_viewport_rect().size
	at.x = clampf(at.x, 4.0, maxf(4.0, screen.x - size.x - 4.0))      # kept on screen at the edges
	at.y = maxf(at.y, 4.0)
	position = at.round()
	if absf(tip_x - (tip.x - position.x)) > 0.5:
		tip_x = tip.x - position.x
		queue_redraw()


func _draw() -> void:
	var cx := clampf(tip_x, 14.0, size.x - 14.0)
	var y := size.y - 2.0
	var tri := PackedVector2Array([Vector2(cx - 8, y), Vector2(cx + 8, y), Vector2(cx, y + TAIL + 2.0)])
	draw_colored_polygon(tri, PAPER)
	draw_polyline(PackedVector2Array([Vector2(cx - 8, y + 1), Vector2(cx, y + TAIL + 2.0), Vector2(cx + 8, y + 1)]), RIM, 2.0)
