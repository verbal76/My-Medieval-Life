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


## The roads in `area` as lines through their cells' centres (every other cell; the ends kept), with their kind. A road is
## never drawn inside the village (its cells there are the village's own streets, as the world draws them: Overworld._stamp).
static func road_lines(ow: Overworld, area: Rect2i) -> Array:
	var out := []
	for seg in RegionRoads.segments(ow, area):
		var cells: PackedInt32Array = seg.cells
		var n := cells.size() / 2
		var kind := RegionRoads.kind_of(ow, seg)
		var pts := PackedVector2Array()
		for q in n:
			var cell := Vector2i(cells[q * 2], cells[q * 2 + 1])
			var inside := ow.village.has_point(cell)
			if not inside and (q % 2 == 0 or q == n - 1 or pts.is_empty()):
				pts.append(Vector2(cell) + Vector2(0.5, 0.5))
			if (inside or q == n - 1) and pts.size() >= 2:
				out.append(_line(pts, kind))
			if inside:
				pts = PackedVector2Array()
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


func _process(_delta: float) -> void:
	_fit()
	if size.x > 10.0 and size.y > 10.0 and (not fitted or (not moved and size != _fit_size)):
		fit_network()                              # opens on the whole network, and stays so while the window settles
	queue_redraw()


# ------------------------------------------------------------------ input ---------------------
func _gui_input(e: InputEvent) -> void:
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
	for pass_kind in ["trail", "road"]:
		for r in roads:
			if r.kind != pass_kind or not (r.box as Rect2).grow(1.0).intersects(view):
				continue
			var pts := PackedVector2Array()
			for c in r.pts:
				pts.append(to_screen(c))
			if pass_kind == "road":
				var wd := clampf(zoom * 1.1, 2.0, 12.0)
				draw_polyline(pts, ROAD_EDGE, wd + 2.0)
				draw_polyline(pts, ROAD, wd)
			else:
				draw_polyline(pts, TRAIL, clampf(zoom * 0.7, 1.2, 8.0))
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
	draw_line(Vector2(x, yy), Vector2(x + 24, yy), ROAD_EDGE, 6.0)
	draw_line(Vector2(x, yy), Vector2(x + 24, yy), ROAD, 4.0)
	x = _legend_word(font, x + 30, yy, "Road")
	draw_line(Vector2(x, yy), Vector2(x + 24, yy), TRAIL, 2.0)
	x = _legend_word(font, x + 30, yy, "Trail")
	draw_rect(Rect2(Vector2(x, yy - 6), Vector2(12, 12)), SITE)
	x = _legend_word(font, x + 18, yy, "Settlement")
	draw_texture_rect(_icons.mineral, Rect2(Vector2(x, yy - 9), Vector2(18, 18)), false)
	x = _legend_word(font, x + 22, yy, "Place you found")
	for hint in ["Dark: not yet explored.  Tap a point to travel there; drag to move, pinch or wheel to zoom.",
			"Dark: unexplored.  Tap to travel, drag to move, pinch to zoom.", "Tap to travel"]:
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
