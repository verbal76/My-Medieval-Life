class_name RegionMapPanel
extends Control
## REGION-NAV-01 (owner 2026-11-02) and Build 25 Revision 1 (owner directive 2026-11-03, sections 1, 3, 4 and 7C; B25R1-003,
## B25R1-005, B25R1-006): the region map, a navigation tool.
##
## What it shows, in the game's own coordinates and true proportions:
##  - every settlement of the world (Overworld.sites) and the home village, named from day 1 with the distance and one of eight
##    directions from the player: the major places are common knowledge (no conversation or visit unlocks them; what a
##    settlement's people tell, Atlas.places, is extra knowledge for trade, not the map);
##  - the established roads and trails, read from the overworld's road network itself (RegionRoads), even where not yet walked:
##    "road" (the ways between the places) wide and pale, "trail" (the rest of the network) narrow and brown;
##  - the ground the player has seen (Atlas.explored), as it is; unseen ground stays dark;
##  - the smaller places the player has found on foot (Landmarks: mine entrances, the quarry, the bandit camp, ore seams), each
##    with its icon, kept through saves;
##  - the player, prominently; the destination chosen and the route planned to it (TravelDriver).
## Controls: it opens zoomed out on the whole settlement network; the mouse wheel, a pinch or a trackpad zooms (about the
## pointer); a drag (mouse or finger) pans; Centre on me (the window's bar) recentres. A tap or click, one that did not move
## more than DRAG pixels and was not part of a pinch, chooses that point as the destination (TravelDriver.start): the route is
## planned, the window closes and the character sets off; a point that cannot be reached is refused with the reason.
## Gamepad (B25R1-012, owner 2026-11-03): any pad input shows a cursor; the D-pad or the left stick moves it (the map scrolls
## to keep it in view), A (Interact/Confirm) travels to the point under it through the same `tap` as a touch or a click, the
## triggers zoom (LT out, RT in) about the cursor, the right stick pans, a click of the right stick (Recenter) centres on the
## player, X resumes and Y dismisses the destination, B closes the window as it closes every window. The pad's buttons are
## taken here while the map is open, so they neither move the focus nor reach the character (who stands still behind any
## window). A mouse or a touch hides the cursor.

const COLOURS := [Color8(30, 22, 15), Color8(104, 128, 70), Color8(46, 78, 42), Color8(132, 124, 112),
		Color8(120, 126, 76), Color8(138, 82, 52), Color8(111, 74, 44)]      # by Atlas class: unknown, grass, wood, rock, road, settlement (roofs), village
# (B25R1: a road block is ground with a road through it, a shade off the grass: the roads themselves are drawn as lines)
const BACK := Color8(30, 22, 15)             # the unknown ground's colour: the terrain image has no edge
const PALE := Color8(236, 214, 170)
const HOME := Color8(255, 214, 90)
const YOU := Color8(214, 52, 36)
const ROAD := Color8(222, 204, 164)
const ROAD_EDGE := Color8(58, 42, 28)
const TRAIL := Color8(170, 124, 78)
const STONE := Color8(178, 182, 176)          # B25R1-Q1: stone road, the paving's grey
const WATER := Color8(40, 160, 200)           # B25R1-Q3: streams and pools
const BRIDGE := Color8(150, 96, 44)
const SITE := Color8(150, 92, 58)
const DEST := Color8(96, 196, 232)
const DRAG := 12.0              # pixels a press may move and still be a tap
const MAX_ZOOM := 16.0          # screen pixels a tile, at most
const LEGEND_H := 30.0

var main
var tex: ImageTexture
var bounds := Rect2i()          # the tiles the terrain image covers
var network := Rect2i()         # the village and every settlement: what the map opens on
var roads: Array = []           # [{pts: PackedVector2Array (tile centres), kind, box: Rect2}]
var worn: Array = []            # B25R1-011: [cell, kind] of the ways footfall or paving made, beyond the generated ones
var streams: Array = []         # B25R1-Q3: the streams in the map (Overworld.streams_in: lines, widths, pools)
var bridges: Array = []         # B25R1-Q3: where a road crosses one (tile positions)
var zoom := 1.0                 # screen pixels a tile
var centre := Vector2.ZERO      # the tile at the middle of the map
var fitted := false
var moved := false              # the player has zoomed or panned: a change of the window's size no longer refits
var _fit_size := Vector2.ZERO
var status := ""                # a refusal, shown for a while
var status_until := 0
var _press := Vector2.INF       # where a mouse button (or the first finger) went down
var _dragging := false
var _gesture := false           # two fingers were down since the press: never a tap
var _touches := {}              # finger index -> position
var _pinch_d := 0.0
var _pinch_zoom := 1.0
var _pinch_mid := Vector2.ZERO
var _icons := {}
var _placed: Array[Rect2] = []  # the screen rects of the marks and labels drawn this frame
var cursor := Vector2.INF       # B25R1-012: the pad's cursor (tiles); INF while no pad has been used on the map
const CURSOR_SPEED := 420.0     # screen pixels a second at full tilt
const PAD_ZOOM := 2.2           # zoom factor a second with a trigger held


func setup(m) -> void:
	main = m
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var w: World = main.world
	network = settlement_network(w)
	bounds = region_bounds(w, w.player)
	tex = ImageTexture.create_from_image(build_image(w, w.player))
	roads = road_lines(w.map.overworld, bounds)
	worn = worn_ways(w.map.overworld)
	streams = w.map.overworld.streams_in(bounds)
	bridges = bridge_points(w.map.overworld, streams, bounds)
	for k in ["mineral", "combat", "tool"]:
		_icons[k] = load("res://assets/markers/%s.png" % k)
	_icons.home = load("res://assets/ui/home.png")
	_fit()


## The village and every settlement site, with a road node's spacing round them: the network the map opens on.
static func settlement_network(w: World) -> Rect2i:
	var ow: Overworld = w.map.overworld
	var b := ow.village
	for st in ow.sites:
		b = b.merge(st.rect)
	return b.grow(Overworld.NODE / 2)


## The tiles the map covers: the settlement network, every chunk the player explored, the places they found, where they are and
## where they are going, with a margin; whole Atlas blocks, so a pixel of the terrain image is one block.
static func region_bounds(w: World, p: PlayerState) -> Rect2i:
	var b := settlement_network(w).grow(Overworld.NODE)
	for cc: Vector2i in p.explored:
		b = b.merge(Rect2i(cc * Overworld.CHUNK, Vector2i(Overworld.CHUNK, Overworld.CHUNK)))
	for id in p.landmarks:
		b = b.merge(Rect2i(Vector2i(int(p.landmarks[id].x), int(p.landmarks[id].y)), Vector2i.ONE).grow(Overworld.CHUNK))
	if RegionTravel.has_destination(p):
		b = b.merge(Rect2i(RegionTravel.destination(p), Vector2i.ONE).grow(Overworld.CHUNK))
	b = b.merge(Rect2i(Vector2i(p.pos.floor()), Vector2i.ONE).grow(Overworld.CHUNK))
	var lo := Vector2i(floori(b.position.x / float(Atlas.BLOCK)), floori(b.position.y / float(Atlas.BLOCK))) * Atlas.BLOCK
	var hi := Vector2i(ceili(b.end.x / float(Atlas.BLOCK)), ceili(b.end.y / float(Atlas.BLOCK))) * Atlas.BLOCK
	return Rect2i(lo, hi - lo)


## One pixel per Atlas block (8 x 8 tiles): explored blocks by their class, the village as itself, the rest unknown.
static func build_image(w: World, p: PlayerState) -> Image:
	var b := region_bounds(w, p)
	var bw := b.size.x / Atlas.BLOCK
	var bh := b.size.y / Atlas.BLOCK
	var img := Image.create(maxi(1, bw), maxi(1, bh), false, Image.FORMAT_RGBA8)
	img.fill(COLOURS[Atlas.UNKNOWN])
	for cc: Vector2i in p.explored:
		var sm: PackedByteArray = p.explored[cc]
		for by in Atlas.PER:
			for bx in Atlas.PER:
				var px := (cc.x * Overworld.CHUNK + bx * Atlas.BLOCK - b.position.x) / Atlas.BLOCK
				var py := (cc.y * Overworld.CHUNK + by * Atlas.BLOCK - b.position.y) / Atlas.BLOCK
				if px >= 0 and py >= 0 and px < bw and py < bh:
					img.set_pixel(px, py, COLOURS[sm[by * Atlas.PER + bx]])
	var v: Rect2i = w.map.overworld.village
	for y in range(v.position.y, v.end.y, Atlas.BLOCK):
		for x in range(v.position.x, v.end.x, Atlas.BLOCK):
			if not v.has_point(Vector2i(x, y) + Vector2i(Atlas.BLOCK, Atlas.BLOCK) / 2):
				continue                                   # a block mostly outside the village (its last row): its own ground
			img.set_pixel((x - b.position.x) / Atlas.BLOCK, (y - b.position.y) / Atlas.BLOCK, COLOURS[Atlas.VILLAGE])
	return img


## The roads in `area` as lines through their cells' centres (every other cell; the ends kept), split where the road's type
## changes (B25R1-Q1: stone, road or trail, RegionRoads, the same types the world draws). A road is never drawn inside the
## village (its cells there are the village's own streets, as the world draws them: Overworld._stamp).
static func road_lines(ow: Overworld, area: Rect2i) -> Array:
	var out := []
	var kinds := RegionRoads.main_kinds(ow)
	for seg in RegionRoads.segments(ow, area):
		var cells: PackedInt32Array = seg.cells
		var n := cells.size() / 2
		var pts := PackedVector2Array()
		var kind := ""
		for q in n:
			var cell := Vector2i(cells[q * 2], cells[q * 2 + 1])
			var inside := ow.village.has_point(cell)
			var k := str(kinds.get(cell, "trail"))
			var at := Vector2(cell) + Vector2(0.5, 0.5)
			if inside:
				if pts.size() >= 2:
					out.append(_line(pts, kind))
				pts = PackedVector2Array()
				continue
			if k != kind and not pts.is_empty():
				pts.append(at)                         # the two types meet here
				if pts.size() >= 2:
					out.append(_line(pts, kind))
				pts = PackedVector2Array()
			kind = k
			if pts.is_empty() or q % 2 == 0 or q == n - 1:
				pts.append(at)
		if pts.size() >= 2:
			out.append(_line(pts, kind))
	return out


## B25R1-011: the cells whose way now differs from the generated network's (worn in by footfall, paved): [cell, kind],
## kind as the legend's ("stone", "road", "trail"), in cell order.
static func worn_ways(ow: Overworld) -> Array:
	var out := []
	var cells: Array = ow.road_state.keys()
	cells.sort()
	for c: Vector2i in cells:
		var lv := RoadWear.level(ow, c)
		if lv >= 1 and lv != RoadWear.base_level(ow, c):
			out.append([c, ["", "trail", "road", "stone"][lv]])
	return out


## B25R1-Q3: where the roads cross the streams: a point of a stream's line within its width of a road cell (the road's own
## cells, RegionRoads.segments), one mark per crossing. From the data, without generating a chunk.
static func bridge_points(ow: Overworld, sts: Array, area: Rect2i) -> Array:
	var roads := {}
	for seg in RegionRoads.segments(ow, area):
		var cells: PackedInt32Array = seg.cells
		for q in cells.size() / 2:
			roads[Vector2i(cells[q * 2], cells[q * 2 + 1])] = true
	var out := []
	for st in sts:
		var pts: Array = st.pts
		for q in range(pts.size() - 1):
			var a: Vector2 = pts[q]
			var b: Vector2 = pts[q + 1]
			var n := maxi(1, int(a.distance_to(b) * 2.0))
			for k in n:
				var p := a.lerp(b, k / float(n))
				var hit := false
				for d in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					if roads.has(Vector2i(p.floor()) + d):
						hit = true
				if hit and not out.any(func(o: Vector2): return o.distance_to(p) < 4.0):
					out.append(p)
	return out


static func _line(pts: PackedVector2Array, kind: String) -> Dictionary:
	var lo := Vector2(INF, INF)
	var hi := -lo
	for c in pts:
		lo = lo.min(c)
		hi = hi.max(c)
	return {"pts": pts, "kind": kind, "box": Rect2(lo, hi - lo)}


# ------------------------------------------------------------------ view ----------------------
func to_screen(tile: Vector2) -> Vector2:
	return (tile - centre) * zoom + map_size() / 2.0


func to_tile(screen: Vector2) -> Vector2:
	return (screen - map_size() / 2.0) / zoom + centre


func map_size() -> Vector2:
	return Vector2(size.x, maxf(1.0, size.y - LEGEND_H))


func min_zoom() -> float:
	var room := map_size()
	return 0.6 * minf(room.x / float(bounds.size.x), room.y / float(bounds.size.y))


## Zoomed out on the whole settlement network and where the player is.
func fit_network() -> void:
	var p: PlayerState = main.world.player
	var b := Rect2(network).merge(Rect2(p.pos - Vector2(8, 8), Vector2(16, 16)))
	var room := map_size() - Vector2(40, 40)
	zoom = clampf(minf(room.x / b.size.x, room.y / b.size.y), min_zoom(), MAX_ZOOM)
	centre = b.get_center()
	fitted = true
	moved = false
	_fit_size = size


func centre_on_player() -> void:
	centre = main.world.player.pos
	zoom = maxf(zoom, 3.0)
	moved = true
	queue_redraw()


func zoom_at(screen: Vector2, factor: float) -> void:
	var before := to_tile(screen)
	zoom = clampf(zoom * factor, min_zoom(), MAX_ZOOM)
	centre += before - to_tile(screen)          # the point under the pointer stays under it
	moved = true
	queue_redraw()


func pan(screen_delta: Vector2) -> void:
	centre -= screen_delta / zoom
	var b := Rect2(bounds)
	centre = centre.clamp(b.position, b.end)
	moved = true
	queue_redraw()


func _fit() -> void:
	var scroll := get_parent().get_parent() as Control if get_parent() else null
	var h: float = scroll.size.y if scroll and scroll.size.y > 100.0 else main.get_viewport().get_visible_rect().size.y - 100.0
	var first := get_parent().get_child(0) as Control if get_parent() else null
	if first != null and first != self:
		h -= first.size.y + 8.0                    # the Village | Region bar above the map
	if absf(custom_minimum_size.y - h) > 0.5:
		custom_minimum_size = Vector2(0, h)


func _process(delta: float) -> void:
	_fit()
	if size.x > 10.0 and size.y > 10.0 and (not fitted or (not moved and size != _fit_size)):
		fit_network()                              # opens on the whole network, and stays so while the window settles
	if cursor != Vector2.INF and is_visible_in_tree():
		pad_step(pad_vector(), pad_triggers(), pad_look(), delta)
	queue_redraw()


# ------------------------------------------------------------------ gamepad (B25R1-012) -----
func _pad_device() -> int:
	var pads := Input.get_connected_joypads()
	return int(pads[0]) if not pads.is_empty() else 0


## The cursor's direction: the D-pad (held) or the left stick.
func pad_vector() -> Vector2:
	var d := _pad_device()
	var v := Vector2(Input.get_joy_axis(d, JOY_AXIS_LEFT_X), Input.get_joy_axis(d, JOY_AXIS_LEFT_Y))
	if v.length() < 0.25:
		v = Vector2.ZERO
	if Input.is_joy_button_pressed(d, JOY_BUTTON_DPAD_LEFT): v.x -= 1.0
	if Input.is_joy_button_pressed(d, JOY_BUTTON_DPAD_RIGHT): v.x += 1.0
	if Input.is_joy_button_pressed(d, JOY_BUTTON_DPAD_UP): v.y -= 1.0
	if Input.is_joy_button_pressed(d, JOY_BUTTON_DPAD_DOWN): v.y += 1.0
	return v.limit_length(1.0)


## RT minus LT: >0 zooms in.
func pad_triggers() -> float:
	var d := _pad_device()
	var t := Input.get_joy_axis(d, JOY_AXIS_TRIGGER_RIGHT) - Input.get_joy_axis(d, JOY_AXIS_TRIGGER_LEFT)
	return t if absf(t) > 0.2 else 0.0


func pad_look() -> Vector2:
	var d := _pad_device()
	var v := Vector2(Input.get_joy_axis(d, JOY_AXIS_RIGHT_X), Input.get_joy_axis(d, JOY_AXIS_RIGHT_Y))
	return v if v.length() > 0.25 else Vector2.ZERO


## A frame of the pad's cursor: moved by `dir` (the stick or D-pad), the map zoomed by `zoom_dir` about it and panned by `look`;
## the map scrolls to keep the cursor inside it.
func pad_step(dir: Vector2, zoom_dir: float, look: Vector2, delta: float) -> void:
	if cursor == Vector2.INF:
		return
	if dir != Vector2.ZERO:
		cursor += dir * CURSOR_SPEED * delta / zoom
		cursor = cursor.clamp(Vector2(bounds.position), Vector2(bounds.end))
	if zoom_dir != 0.0:
		zoom_at(to_screen(cursor), pow(PAD_ZOOM, zoom_dir * delta))
	if look != Vector2.ZERO:
		pan(-look * CURSOR_SPEED * delta)
	var sc := to_screen(cursor)
	var ms := map_size()
	var margin := 48.0
	var push := Vector2(minf(0.0, sc.x - margin) + maxf(0.0, sc.x - (ms.x - margin)), minf(0.0, sc.y - margin) + maxf(0.0, sc.y - (ms.y - margin)))
	if push != Vector2.ZERO:
		centre += push / zoom
		moved = true


## The pad's buttons on the open map (taken here: no focus moves, nothing reaches the character).
func _input(e: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if e is InputEventJoypadMotion:
		if cursor == Vector2.INF and absf((e as InputEventJoypadMotion).axis_value) > 0.5:
			cursor = main.world.player.pos
		return
	if not (e is InputEventJoypadButton):
		return
	var b := e as InputEventJoypadButton
	if b.button_index == JOY_BUTTON_B or b.button_index == JOY_BUTTON_LEFT_SHOULDER or b.button_index == JOY_BUTTON_START:
		return                                     # closing the window (and the map's own button) work as everywhere
	get_viewport().set_input_as_handled()
	if not b.pressed:
		return
	if cursor == Vector2.INF:
		cursor = main.world.player.pos             # the first press shows the cursor, on the player
		if b.button_index in [JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN]:
			return
	pad_button(b.button_index)


## What a pad button does on the map (tests call it with the button).
func pad_button(button: int) -> void:
	if cursor == Vector2.INF:
		cursor = main.world.player.pos
	match button:
		JOY_BUTTON_A:
			tap(to_screen(cursor))                 # the same route planning as a touch or a click
		JOY_BUTTON_RIGHT_STICK:
			centre_on_player()
			cursor = main.world.player.pos
		JOY_BUTTON_X:
			if RegionTravel.has_destination(main.world.player) and not RegionTravel.active(main.world.player):
				main.ui.resume_travel()
		JOY_BUTTON_Y:
			if RegionTravel.has_destination(main.world.player):
				main.ui.dismiss_travel()
		JOY_BUTTON_RIGHT_SHOULDER:
			zoom_at(to_screen(cursor), 1.4)


# ------------------------------------------------------------------ input ---------------------
func _gui_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch or e is InputEventMouseButton:
		cursor = Vector2.INF                       # a touch or the mouse: the pad's cursor goes
	if e is InputEventScreenTouch:
		if e.pressed:
			_touches[e.index] = e.position
			if _touches.size() >= 2:
				_gesture = true
				_pinch_start()
		else:
			_touches.erase(e.index)
			if _touches.size() >= 2:
				_pinch_start()
		accept_event()
	elif e is InputEventScreenDrag:
		_touches[e.index] = e.position
		if _touches.size() >= 2:
			var pts: Array = _touches.values()
			var d := (pts[0] as Vector2).distance_to(pts[1])
			var mid := ((pts[0] as Vector2) + (pts[1] as Vector2)) / 2.0
			if _pinch_d > 1.0:
				var before := to_tile(_pinch_mid)
				zoom = clampf(_pinch_zoom * d / _pinch_d, min_zoom(), MAX_ZOOM)
				centre += before - to_tile(mid)
				_pinch_mid = mid
				_pinch_zoom = zoom
				_pinch_d = d
				moved = true
				queue_redraw()
		accept_event()
	elif e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			zoom_at(mb.position, 1.15)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			zoom_at(mb.position, 1.0 / 1.15)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if _touches.size() <= 1:
					_gesture = false
				_press = mb.position
				_dragging = false
			else:
				var was_tap := _press != Vector2.INF and not _dragging and not _gesture
				_press = Vector2.INF
				_dragging = false
				if was_tap:
					tap(mb.position)
		accept_event()
	elif e is InputEventMouseMotion:
		var mm := e as InputEventMouseMotion
		if _press != Vector2.INF and (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0 and _touches.size() < 2:
			if not _dragging and mm.position.distance_to(_press) > DRAG:
				_dragging = true
			if _dragging:
				pan(mm.relative)
		accept_event()
	elif e is InputEventMagnifyGesture and _touches.size() < 2:
		zoom_at((e as InputEventMagnifyGesture).position, (e as InputEventMagnifyGesture).factor)
		accept_event()
	elif e is InputEventPanGesture:
		pan(-(e as InputEventPanGesture).delta * 8.0)
		accept_event()


func _pinch_start() -> void:
	var pts: Array = _touches.values()
	_pinch_d = (pts[0] as Vector2).distance_to(pts[1])
	_pinch_mid = ((pts[0] as Vector2) + (pts[1] as Vector2)) / 2.0
	_pinch_zoom = zoom


## A tap or click that was not a drag: travel there (the window closes), or say why not.
func tap(screen: Vector2) -> void:
	var cell := Vector2i(to_tile(screen).floor())
	var why: String = main.travel.start(main, cell)
	if why != "":
		status = why
		status_until = Time.get_ticks_msec() + 4000
		queue_redraw()
		return
	var p: PlayerState = main.world.player
	var dest := RegionTravel.destination(p)
	var name := RegionTravel.place_name(main.world, p, dest)
	main.ui.hide_all()
	main.ui.message("You set off for %s (%s)." % [name, RegionTravel.bearing(p.pos, Vector2(dest) + Vector2(0.5, 0.5))], 5.0)


# ------------------------------------------------------------------ drawing -------------------
func _text(font: Font, at: Vector2, s: String, fs: int, col: Color, centred := false) -> void:
	var x := at.x
	if centred:
		x -= font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x / 2.0
	draw_string_outline(font, Vector2(x, at.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color(0, 0, 0, 0.9))
	draw_string(font, Vector2(x, at.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


## Draw `s` beside `mark` where it overlaps nothing placed yet: right, left, below, above. A label that `must` show and finds
## no free place goes to the right anyway; another is left out.
func _label(font: Font, mark: Rect2, s: String, fs: int, col: Color, must: bool) -> void:
	var sz := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs) + Vector2(4, 0)
	var h := float(fs) + 2.0
	var c := mark.get_center()
	var tries := [Vector2(mark.end.x + 5, c.y - h / 2), Vector2(mark.position.x - 5 - sz.x, c.y - h / 2),
		Vector2(c.x - sz.x / 2, mark.end.y + 3), Vector2(c.x - sz.x / 2, mark.position.y - 3 - h)]
	var pick := Vector2.INF
	for t: Vector2 in tries:
		var r := Rect2(t, Vector2(sz.x, h))
		if not _placed.any(func(o: Rect2): return o.intersects(r)):
			pick = t
			break
	if pick == Vector2.INF:
		if not must:
			return
		pick = tries[0]
	_placed.append(Rect2(pick, Vector2(sz.x, h)))
	_text(font, pick + Vector2(2, h - 4), s, fs, col)


func _draw() -> void:
	var w: World = main.world
	var p: PlayerState = w.player
	var ow: Overworld = w.map.overworld
	var font := get_theme_default_font()
	var ms := map_size()
	draw_rect(Rect2(Vector2.ZERO, size), BACK)
	draw_texture_rect(tex, Rect2(to_screen(Vector2(bounds.position)), Vector2(bounds.size) * zoom), false)
	var view := Rect2(to_tile(Vector2.ZERO), ms / zoom).grow(4.0)
	# roads: trails under roads
	for pass_kind in ["trail", "road", "stone"]:
		for r in roads:
			if r.kind != pass_kind or not (r.box as Rect2).grow(1.0).intersects(view):
				continue
			var pts := PackedVector2Array()
			for c in r.pts:
				pts.append(to_screen(c))
			if pass_kind == "stone":
				var ws := clampf(zoom * 1.3, 3.0, 14.0)
				draw_polyline(pts, ROAD_EDGE, ws + 2.0)
				draw_polyline(pts, STONE, ws)
			elif pass_kind == "road":
				var wd := clampf(zoom * 1.1, 2.0, 12.0)
				draw_polyline(pts, ROAD_EDGE, wd + 2.0)
				draw_polyline(pts, ROAD, wd)
			else:
				draw_polyline(pts, TRAIL, clampf(zoom * 0.7, 1.2, 8.0))
	# B25R1-Q3: the streams and their pools, under the roads' bridges
	for st in streams:
		if not (Rect2(st.box) as Rect2).intersects(view):
			continue
		var line := PackedVector2Array()
		for sp in st.pts:
			line.append(to_screen(sp))
		draw_polyline(line, WATER, clampf(zoom * 2.6, 2.0, 40.0))
		for pool in st.pools:
			draw_circle(to_screen(pool[0]), maxf(2.0, float(pool[1]) * zoom), WATER)
	for b in bridges:
		var bs := clampf(zoom * 2.0, 4.0, 24.0)
		draw_rect(Rect2(to_screen(b) - Vector2(bs, bs) / 2.0, Vector2(bs, bs)), BRIDGE)
		draw_rect(Rect2(to_screen(b) - Vector2(bs, bs) / 2.0, Vector2(bs, bs)), ROAD_EDGE, false, 1.0)
	# B25R1-011: the ways worn in or paved since, cell by cell
	var cs := maxf(zoom, 2.0)
	for e in worn:
		var col: Color = STONE if e[1] == "stone" else ROAD if e[1] == "road" else TRAIL
		draw_rect(Rect2(to_screen(Vector2(e[0])) - Vector2(cs, cs) * 0.5 + Vector2(zoom, zoom) * 0.5, Vector2(cs, cs)), col)
	# the route planned to the destination, from where the player is
	var tv = main.travel
	if RegionTravel.has_destination(p):
		var dest := Vector2(RegionTravel.destination(p)) + Vector2(0.5, 0.5)
		if RegionTravel.active(p) and tv.route.size() > tv.idx:
			var line := PackedVector2Array([to_screen(p.pos)])
			for q in range(tv.idx, tv.route.size()):
				line.append(to_screen(tv.route[q] + Vector2(0.5, 0.5)))
			draw_polyline(line, Color(DEST, 0.85), 3.0)
		else:
			_dashed(to_screen(p.pos), to_screen(dest), Color(DEST, 0.8))
	# the marks first (the home village, every settlement, the places found, the destination, you), then their labels, each
	# put where it overlaps no mark or label already placed (right, left, below, above), so names stay legible at any zoom
	_placed.clear()
	var labels: Array = []          # [mark rect, text, font size, colour, must]: in priority order
	var v := Rect2(ow.village)
	var vr := Rect2(to_screen(v.position), v.size * zoom)
	draw_rect(vr, Color(HOME, 0.18))
	draw_rect(vr, HOME, false, 2.0)
	var hc := to_screen(v.get_center())
	var isz := clampf(zoom * 18.0, 20.0, 30.0)
	var hr := Rect2(hc - Vector2(isz, isz) / 2.0, Vector2(isz, isz))
	draw_texture_rect(_icons.home, hr, false)
	_placed.append(hr)
	labels.append([vr if vr.size.x < 80.0 else hr, "Home", 16, HOME, true])
	for st in ow.sites:
		var sr := Rect2(to_screen(Vector2((st.rect as Rect2i).position)), Vector2((st.rect as Rect2i).size) * zoom)
		var sc := sr.get_center()
		var visited := p.places.has(str(st.id)) and str(p.places[str(st.id)].how) == "visited"
		if sr.size.x < 12.0:
			sr = Rect2(sc - Vector2(6, 6), Vector2(12, 12))
		draw_rect(sr, SITE)
		draw_rect(sr, PALE if visited else Color8(20, 12, 8), false, 2.0)
		_placed.append(sr)
		labels.append([sr, "%s  %s" % [str(st.name), RegionTravel.bearing(p.pos, Vector2(st.center))], 16, PALE, true])
	var me := to_screen(p.pos)
	var dc := Vector2.INF
	if RegionTravel.has_destination(p):
		dc = to_screen(Vector2(RegionTravel.destination(p)) + Vector2(0.5, 0.5))
		_placed.append(Rect2(dc - Vector2(4, 24), Vector2(20, 28)))
	_placed.append(Rect2(me - Vector2(9, 9), Vector2(18, 18)))
	labels.append([Rect2(me - Vector2(9, 9), Vector2(18, 18)), "You", 15, Color8(255, 150, 130), true])
	if dc != Vector2.INF:
		var nm := RegionTravel.place_name(w, p, RegionTravel.destination(p))
		labels.append([Rect2(dc - Vector2(4, 24), Vector2(20, 28)), ("Going to " if RegionTravel.active(p) else "Destination: ") + nm, 14, DEST, true])
	# the smaller places found on foot (named when there is room)
	var lr := 13.0 if zoom >= 1.0 else 9.0
	for lm in Landmarks.known(w, p):
		var at := to_screen(Vector2(lm.at) + Vector2(0.5, 0.5))
		var icon: Texture2D = _icons.combat if lm.kind == "camp" else _icons.mineral
		draw_circle(at, lr, PALE)
		draw_circle(at, lr - 1.5, Color8(43, 29, 19))
		draw_texture_rect(icon, Rect2(at - Vector2(lr, lr) * 0.7, Vector2(lr, lr) * 1.4), false)
		_placed.append(Rect2(at - Vector2(lr, lr), Vector2(lr, lr) * 2.0))
		if zoom >= 2.0:
			labels.append([Rect2(at - Vector2(lr, lr), Vector2(lr, lr) * 2.0), str(lm.name), 13, PALE, false])
	# the destination's flag
	if dc != Vector2.INF:
		draw_line(dc, dc - Vector2(0, 22), Color.BLACK, 4.0)
		draw_line(dc, dc - Vector2(0, 22), PALE, 2.0)
		draw_colored_polygon(PackedVector2Array([dc - Vector2(0, 22), dc - Vector2(-14, 17), dc - Vector2(0, 12)]), DEST)
		draw_circle(dc, 3.0, DEST)
	# you
	var pulse := fposmod(Time.get_ticks_msec() / 900.0, 1.0)
	draw_arc(me, 8.0 + pulse * 14.0, 0, TAU, 28, Color(YOU, 1.0 - pulse), 3.0)
	draw_circle(me, 8.5, Color.BLACK)
	draw_circle(me, 6.5, YOU)
	draw_circle(me, 2.5, PALE)
	for l in labels:
		_label(font, l[0], l[1], l[2], l[3], l[4])
	if cursor != Vector2.INF:                      # B25R1-012: the pad's cursor, and what A would do
		var cur_s := to_screen(cursor)
		var ring := Color8(255, 236, 140)
		draw_arc(cur_s, 13.0, 0, TAU, 32, Color.BLACK, 5.0)
		draw_arc(cur_s, 13.0, 0, TAU, 32, ring, 2.5)
		for dv in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			draw_line(cur_s + dv * 7.0, cur_s + dv * 20.0, Color.BLACK, 4.0)
			draw_line(cur_s + dv * 7.0, cur_s + dv * 20.0, ring, 2.0)
		var what := "A: travel here  ·  %s" % RegionTravel.bearing(main.world.player.pos, cursor)
		_text(font, cur_s + Vector2(18, -16), what, 14, ring)
	# north and the status line
	var nx := Vector2(ms.x - 26, 30)
	draw_colored_polygon(PackedVector2Array([nx + Vector2(0, -16), nx + Vector2(8, 6), nx + Vector2(-8, 6)]), PALE)
	_text(font, nx + Vector2(0, 24), "N", 14, PALE, true)
	if status != "" and Time.get_ticks_msec() < status_until:
		var sw := font.get_string_size(status, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		draw_rect(Rect2(Vector2(8, 8), Vector2(sw + 20, 30)), Color(0.1, 0.04, 0.02, 0.9))
		_text(font, Vector2(18, 29), status, 16, Color8(255, 190, 150))
	# the legend, along the foot
	var ly := size.y - LEGEND_H
	draw_rect(Rect2(Vector2(0, ly), Vector2(size.x, LEGEND_H)), Color8(43, 29, 19))
	draw_line(Vector2(0, ly), Vector2(size.x, ly), Color8(111, 74, 44), 2.0)
	var x := 12.0
	var yy := ly + LEGEND_H / 2.0
	draw_line(Vector2(x, yy), Vector2(x + 24, yy), ROAD_EDGE, 7.0)
	draw_line(Vector2(x, yy), Vector2(x + 24, yy), STONE, 5.0)
	x = _legend_word(font, x + 30, yy, "Stone road")
	draw_line(Vector2(x, yy), Vector2(x + 24, yy), ROAD_EDGE, 6.0)
	draw_line(Vector2(x, yy), Vector2(x + 24, yy), ROAD, 4.0)
	x = _legend_word(font, x + 30, yy, "Dirt road")
	draw_line(Vector2(x, yy), Vector2(x + 24, yy), TRAIL, 2.0)
	x = _legend_word(font, x + 30, yy, "Trail")
	draw_line(Vector2(x, yy), Vector2(x + 24, yy), WATER, 4.0)
	x = _legend_word(font, x + 30, yy, "Stream")
	draw_rect(Rect2(Vector2(x, yy - 5), Vector2(10, 10)), BRIDGE)
	x = _legend_word(font, x + 16, yy, "Bridge")
	draw_rect(Rect2(Vector2(x, yy - 6), Vector2(12, 12)), SITE)
	x = _legend_word(font, x + 18, yy, "Settlement")
	draw_texture_rect(_icons.mineral, Rect2(Vector2(x, yy - 9), Vector2(18, 18)), false)
	x = _legend_word(font, x + 22, yy, "Place you found")
	var hints := ["Dark: not yet explored.  Tap a point to travel there; drag to move, pinch or wheel to zoom.",
			"Dark: unexplored.  Tap to travel, drag to move, pinch to zoom.", "Tap to travel"]
	if cursor != Vector2.INF:
		hints = ["D-pad move  ·  A travel  ·  LT/RT zoom  ·  R3 centre on me  ·  X resume  ·  Y dismiss  ·  B close",
			"D-pad move · A travel · LT/RT zoom · R3 centre · X resume · Y dismiss", "A travel · LT/RT zoom"]
	for hint in hints:
		if x + 6 + font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x <= size.x - 8:
			_text(font, Vector2(x + 6, yy + 5), hint, 13, Color8(214, 196, 160))
			break


func _legend_word(font: Font, x: float, y: float, s: String) -> float:
	_text(font, Vector2(x, y + 5), s, 14, PALE)
	return x + font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 16.0


func _dashed(a: Vector2, b: Vector2, col: Color) -> void:
	var n := int(a.distance_to(b) / 12.0)
	for k in n:
		if k % 2 == 0:
			draw_line(a.lerp(b, k / float(n)), a.lerp(b, (k + 1) / float(n)), col, 2.0)
