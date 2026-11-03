class_name TravelBar
extends PanelContainer
## B25R1-006 (owner directive 2026-11-03, section 4, "Manual interruption"): the HUD strip shown while the player has a
## destination chosen on the Region map: where it is (name, distance and direction), whether the character is walking there,
## and the two controls the owner asked for: Resume Destination (planned again from where the player stands, then walking on)
## and Dismiss Destination (the journey cancelled, the destination and route cleared). Touch and mouse; the buttons never take
## focus, so keys and the pad stay with play (the Region map's bar has the same two controls for keys and the pad).

var ui
var info: Label
var resume_btn: Button
var dismiss_btn: Button


func setup(game_ui) -> void:
	ui = game_ui
	add_theme_stylebox_override("panel", ui._style(Color(GameUI.WINDOW, 0.9)))
	set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	add_child(h)
	info = Label.new()
	info.add_theme_font_size_override("font_size", 16)
	info.add_theme_color_override("font_color", GameUI.PALE)
	info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(info)
	resume_btn = _small("Resume destination", func(): ui.resume_travel())
	h.add_child(resume_btn)
	dismiss_btn = _small("Dismiss destination", func(): ui.dismiss_travel())
	h.add_child(dismiss_btn)


func _small(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 40)
	b.add_theme_font_size_override("font_size", 15)
	b.pressed.connect(cb)
	return b


func _process(_delta: float) -> void:
	var m = ui.main
	var want: bool = m.world != null and m.running and not ui.panel.visible and RegionTravel.has_destination(m.world.player)
	if visible != want:
		visible = want
	if not want:
		return
	var p: PlayerState = m.world.player
	var dest := RegionTravel.destination(p)
	var name := RegionTravel.place_name(m.world, p, dest)
	var where := RegionTravel.bearing(p.pos, Vector2(dest) + Vector2(0.5, 0.5))
	var walking := RegionTravel.active(p)
	var t := ("Travelling to %s · %s" if walking else "Destination: %s · %s") % [name, where]
	if info.text != t or resume_btn.visible == walking:
		info.text = t
		resume_btn.visible = not walking
		reset_size()
		# the foot of the screen, above the interaction prompt (the top edge has the messages and the corner log)
		set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, int(GameUI.PROMPT_EDGE) + 64)
