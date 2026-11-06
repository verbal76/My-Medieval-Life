class_name TravelBar
extends PanelContainer
## B25R1-006 (owner directive 2026-11-03, section 4, "Manual interruption"): the HUD strip shown while the player has a
## destination chosen on the Region map: where it is (name, distance and direction), whether the character is walking there,
## and the two controls the owner asked for: Resume Destination (planned again from where the player stands, then walking on)
## and Dismiss Destination (the journey cancelled, the destination and route cleared). Touch and mouse as before.
## B25R2 playtest repair (owner directive 2026-11-06, item 4): the pad reaches them too. With fewer than two targets to choose
## between (Main.cycle_target has nothing to do), D-pad Left or Right moves focus onto the bar (pad_enter); Left and Right then
## move between the two buttons, the theme's focus frame shows which, A presses it, and B or a push of the left stick gives the
## pad back to play (pad_input, _process). The keyboard keeps play: the bar takes focus only from the pad.

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
	b.focus_mode = Control.FOCUS_ALL             # B25R2: the pad reaches it (pad_enter); nothing else gives it focus
	b.custom_minimum_size = Vector2(0, 40)
	b.add_theme_font_size_override("font_size", 15)
	b.pressed.connect(cb)
	return b


## B25R2: put the pad's focus on the bar (Resume when it is shown, else Dismiss; `dir` -1 from the right end). True when the
## bar is shown and took it.
func pad_enter(dir := 1) -> bool:
	if not is_visible_in_tree():
		return false
	var order: Array = [resume_btn, dismiss_btn].filter(func(b: Button): return b.visible)
	if order.is_empty():
		return false
	(order[0] if dir >= 0 else order[order.size() - 1] as Button).grab_focus()
	return true


## B25R2: whether one of the bar's buttons has the pad's focus.
func has_pad_focus() -> bool:
	var f := get_viewport().gui_get_focus_owner()
	return f != null and (f == resume_btn or f == dismiss_btn)


## B25R2: the pad's events while the bar has focus (Main._unhandled_input, before play sees them): B gives the pad back to play;
## D-pad Up and Down stay on the bar (they would open the Journal or start gathering). True when used.
func pad_input(e: InputEvent) -> bool:
	if not has_pad_focus():
		return false
	if e.is_action_pressed("ui_cancel"):
		release_pad()
		return true
	if e is InputEventJoypadButton and (e as InputEventJoypadButton).button_index in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN]:
		return true
	return false


func release_pad() -> void:
	if has_pad_focus():
		get_viewport().gui_get_focus_owner().release_focus()


func _process(_delta: float) -> void:
	var m = ui.main
	var want: bool = m.world != null and m.running and not ui.panel.visible and RegionTravel.has_destination(m.world.player)
	if visible != want:
		visible = want
	if has_pad_focus() and (not want or Input.get_vector("move_left", "move_right", "move_up", "move_down").length() > 0.3):
		release_pad()                              # B25R2: the bar gone, or the stick pushed: the pad is play's again
	if not want:
		return
	var p: PlayerState = m.world.player
	var dest := RegionTravel.destination(p)
	var name := RegionTravel.place_name(m.world, p, dest)
	var where := RegionTravel.bearing(p.pos, Vector2(dest) + Vector2(0.5, 0.5))
	var walking := RegionTravel.active(p)
	var t := ("Travelling to %s · %s" if walking else "Destination: %s · %s") % [name, where]
	if ui.scheme == "pad":
		t += "   ◀ ▶ choose" if not has_pad_focus() else "   A press · B back"   # B25R2: how the pad reaches the buttons
	if info.text != t or resume_btn.visible == walking:
		info.text = t
		var had := has_pad_focus() and get_viewport().gui_get_focus_owner() == resume_btn
		resume_btn.visible = not walking
		if had and walking:
			dismiss_btn.grab_focus()               # B25R2: Resume pressed: the pad's focus stays on the bar (Dismiss), never lost
		reset_size()
		# the foot of the screen, above the interaction prompt (the top edge has the messages and the corner log)
		set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, int(GameUI.PROMPT_EDGE) + 64)
