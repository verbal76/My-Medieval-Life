class_name VillageMapPanel
extends Control
## The village map window's content: the whole village, or a settlement the player has found, from overhead, the named
## places, the player's home, what the screen shows now, and the player. A tap on the map looks there (main.look_at_tile).
## B25R1-025 (owner 2026-11-05): an aerial view of the real village (AerialMap: the world's own tile art at 8 px a tile, the
## village's layers as they stand, its trees and crops; a settlement's buildings as the world draws them; the explored country
## round it), zoomed and panned: the mouse wheel, a pinch or a trackpad zooms about the pointer, a drag pans, a pad's right stick
## pans and its triggers zoom. The labels are placed so they overlap neither each other nor the marks (the less important ones
## left out when there is no room, more shown closer in). The one-pixel-a-tile picture (build_image) shows under it until the
## close pictures are drawn. Ground the player has not explored stays dark, as on the Region map.

const T := 16
# one colour per kind of ground, in the interface's wood-brown and parchment tones
const GRASS := Color8(104, 128, 70)
const TREE := Color8(46, 78, 42)
const PATH := Color8(196, 164, 112)
const ROCK := Color8(132, 124, 112)
const WATER := Color8(72, 110, 150)
const ROOF := Color8(111, 74, 44)
const WALL := Color8(58, 38, 22)
const FIELD := {"ripe": Color8(222, 186, 92), "growing": Color8(150, 162, 70), "tilled": Color8(140, 104, 64)}
const PEN := Color8(160, 136, 90)
const PLOT := Color8(150, 140, 100)
const BACK := Color8(43, 29, 19)
const PALE := Color8(236, 214, 170)
const HOME := Color8(255, 214, 90)
const YOU := Color8(214, 52, 36)
const LEGEND := 22.0             # height of the legend line under the map

const MARGIN := 10               # tiles of country shown round the place
const MAX_ZOOM := 16.0
const HI_ZOOM := 2.6            # screen pixels a tile from which the close (8 px a tile) pictures are drawn
const DRAG := 12.0
const PAD_ZOOM := 2.2
const PAN_SPEED := 520.0

var main
var tex: ImageTexture
var target := ""                 # "" the home village, else a settlement's id (Overworld.sites)
var frame := Rect2i()            # the tiles the map is about (the village or the site, with MARGIN round it)
var aerial: AerialMap
var zoom := 1.0                  # screen pixels a tile
var centre := Vector2.ZERO       # the tile at the middle of the map
var fitted := false
var moved := false
var _fit_size := Vector2.ZERO
var _press := Vector2.INF
var _dragging := false
var _gesture := false
var _touches := {}
var _pinch_d := 0.0
var _pinch_zoom := 1.0
var _pinch_mid := Vector2.ZERO
var _labels_cache: Array = []
static var _img: Image
static var _key := ""
static var _tile_colours := {}     # tile value -> average colour


func setup(m, place := "") -> void:
	main = m
	target = place
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tex = ImageTexture.create_from_image(image_for(main.map, main.world))
	var ow: Overworld = main.world.map.overworld
	var st: Dictionary = ow.site(target) if target != "" else {}
	if st.is_empty():
		target = ""
	frame = (ow.village if target == "" else st.rect as Rect2i).grow(MARGIN)
	aerial = AerialMap.of(main)
	aerial.refresh()
	_labels_cache = places_here()
	_fit()


## The settlements whose map can be opened: those the player has walked into or whose ground they explored ([id, name]).
static func known_sites(w: World) -> Array:
	var out := []
	var p: PlayerState = w.player
	for st in w.map.overworld.sites:
		var seen := p.places.has(str(st.id)) and str(p.places[str(st.id)].get("how", "")) == "visited"
		if not seen:
			for cc in AerialMap._chunks_of(st.rect):
				if p.explored.has(cc):
					seen = true
					break
		if seen:
			out.append([str(st.id), str(st.name)])
	return out


## The map image for this world, made once and again only when a building is added or a tree
## felled or regrown.
static func image_for(map: VillageMap, world: World) -> Image:
	var grown := 0
	for t in world.trees:
		if Trees.solid(str(t.state)):
			grown += 1
	var key := "%d/%d/%d" % [world.get_instance_id(), world.buildings.size(), grown]
	if _img == null or key != _key:
		_img = build_image(map, world)
		_key = key
	return _img


## One pixel per tile. The ground's kind comes from the colour of the tile drawn there (the ground and
## path layers; on blocked cells also what stands on them): grey is rock, blue water, brown a path,
## green grass, and anything else that blocks the way a tree or bush. Over that, roads, fields by
## their state, pens, building plots, standing trees and buildings (roof with a dark edge).
static func build_image(map: VillageMap, world: World) -> Image:
	var img := Image.create(map.w, map.h, false, Image.FORMAT_RGBA8)
	var atlases: Array[Image] = []
	for a in map.data.atlases:
		var im: Image = load(a.image).get_image()
		if im.is_compressed():
			im.decompress()
		im.convert(Image.FORMAT_RGBA8)
		atlases.append(im)
	var layers := []
	for lay in map.data.layers:
		if lay.z != "above":
			layers.append([lay.z == "below", lay.data])
	for y in map.h:
		for x in map.w:
			var i := y * map.w + x
			var solid := map.solid[i] == 1
			var c := Color(0, 0, 0, 0)
			for lay in layers:
				var v := int(lay[1][i])
				if v < 0 or (lay[0] and not solid):
					continue
				var tc := _tile_colour(map, atlases, v)
				if tc.a > 0.0:
					c = tc
			var kind := GRASS
			if c.h > 0.5 and c.h < 0.72 and c.s > 0.25:
				kind = WATER
			elif c.a > 0.0 and c.s < 0.22:
				kind = ROCK
			elif solid:
				kind = TREE
			elif c.a > 0.0 and c.h <= 0.17:
				kind = PATH
			img.set_pixel(x, y, kind)
	for c in map.data.road:
		img.set_pixel(int(c[0]), int(c[1]), PATH)
	for pen in map.data.pens:
		_box(img, Rect2i(int(pen.x), int(pen.y), int(pen.w), int(pen.h)), PEN, WALL)
	for pl in world.plots:
		if not world.holds(world.acting_ref(), pl) or pl.site.is_empty():
			_box(img, Rect2i(int(pl.x), int(pl.y), int(pl.w), int(pl.h)), GRASS, PLOT)
	for f in world.fields:
		_box(img, Rect2i(int(f.x), int(f.y), int(f.w), int(f.h)), FIELD.get(f.state, FIELD.tilled), FIELD.get(f.state, FIELD.tilled))
	for t in world.trees:
		if Trees.solid(str(t.state)):
			img.set_pixel(int(t.x), int(t.y), TREE)
			if int(t.y) > 0:
				img.set_pixel(int(t.x), int(t.y) - 1, TREE)
	var ids: Array = world.buildings.keys()
	ids.sort()
	for id in ids:
		var b: Dictionary = world.buildings[id]
		# the bottom row of a building is its front wall and door step: drawn as roof too
		_box(img, Rect2i(int(b.x), int(b.y), int(b.w), int(b.h) - 1), ROOF, WALL)
	return img


## The average colour of a tile (atlas * 100000 + id), weighted by its opacity; clear (alpha 0)
## for a tile that is mostly transparent. Kept for the next map.
static func _tile_colour(map: VillageMap, atlases: Array[Image], v: int) -> Color:
	if _tile_colours.has(v):
		return _tile_colours[v]
	var a := v / 100000
	var t := v % 100000
	var cols := int(map.data.atlases[a].columns)
	var x0 := (t % cols) * T
	var y0 := (t / cols) * T
	var sum := Color(0, 0, 0, 0)
	var weight := 0.0
	for y in T:
		for x in T:
			var p := atlases[a].get_pixel(x0 + x, y0 + y)
			sum += Color(p.r * p.a, p.g * p.a, p.b * p.a, 0)
			weight += p.a
	var c := Color(sum.r / weight, sum.g / weight, sum.b / weight, 1.0) if weight >= T * T / 4.0 else Color(0, 0, 0, 0)
	_tile_colours[v] = c
	return c


static func _box(img: Image, r: Rect2i, fill: Color, edge: Color) -> void:
	r = r.intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	img.fill_rect(r, fill)
	for x in range(r.position.x, r.end.x):
		img.set_pixel(x, r.position.y, edge)
		img.set_pixel(x, r.end.y - 1, edge)
	for y in range(r.position.y, r.end.y):
		img.set_pixel(r.position.x, y, edge)
		img.set_pixel(r.end.x - 1, y, edge)


## The places named on the map: [text, tile position of the label's centre].
func places() -> Array:
	var out := []
	var map: VillageMap = main.map
	for b in map.data.buildings:
		if b.has("name"):
			out.append([b.name, Vector2(b.x + b.w / 2.0, b.y + b.h / 2.0)])
		elif b.type == "manor":
			out.append(["Manor", Vector2(b.x + b.w / 2.0, b.y + b.h / 2.0)])
	out.append(["Mine", Vector2(map.data.mine.entrance[0] + 0.5, map.data.mine.entrance[1] - 1.5)])
	out.append(["Market", _centre(map.data.stalls) + Vector2(0, -1.5)])
	out.append(["Fields", _centre(map.data.fields)])
	out.append(["Animal pens", _centre(map.data.pens)])
	out.append(["Plots for sale", _centre(main.world.plots.filter(func(q): return map.data.plots.any(func(mp): return str(mp.id) == str(q.id)))) + Vector2(0, -6)])   # the world's own plots: a saved world keeps its old ones (ROOMS-18)
	return out


func _centre(rects: Array) -> Vector2:
	var r := Rect2(Vector2(rects[0].x, rects[0].y), Vector2(rects[0].get("w", 1), rects[0].get("h", 1)))
	for e in rects:
		r = r.merge(Rect2(Vector2(e.x, e.y), Vector2(e.get("w", 1), e.get("h", 1))))
	return r.get_center()


## Where the place itself (the village, or the settlement's site) is drawn: on screen at the current zoom and centre (the
## whole of it, with the country round it, when the map opens).
func map_rect() -> Rect2:
	var ow: Overworld = main.world.map.overworld
	var place: Rect2i = ow.village if target == "" else ow.site(target).rect
	return Rect2(to_screen(Vector2(place.position)), Vector2(place.size) * zoom)


func map_size() -> Vector2:
	return Vector2(size.x, maxf(1.0, size.y - LEGEND))


func to_screen(t: Vector2) -> Vector2:
	return (t - centre) * zoom + map_size() / 2.0


func to_tile(sc: Vector2) -> Vector2:
	return (sc - map_size() / 2.0) / zoom + centre


func min_zoom() -> float:
	var room := map_size()
	return 0.5 * minf(room.x / float(frame.size.x), room.y / float(frame.size.y))


## The whole place in the window.
func fit() -> void:
	var room := map_size() - Vector2(8, 8)
	zoom = clampf(minf(room.x / float(frame.size.x), room.y / float(frame.size.y)), 0.05, MAX_ZOOM)
	centre = Vector2(frame.position) + Vector2(frame.size) / 2.0
	fitted = true
	moved = false
	_fit_size = size


func zoom_at(sc: Vector2, factor: float) -> void:
	var before := to_tile(sc)
	zoom = clampf(zoom * factor, min_zoom(), MAX_ZOOM)
	centre += before - to_tile(sc)
	_clamp()
	moved = true
	queue_redraw()


func pan(d: Vector2) -> void:
	centre -= d / zoom
	_clamp()
	moved = true
	queue_redraw()


func _clamp() -> void:
	centre = centre.clamp(Vector2(frame.position), Vector2(frame.end))


## Where the player's marker is drawn, in this control.
func player_point() -> Vector2:
	var r := map_rect()
	return to_screen(main.world.player.pos).clamp(r.position, r.end)       # outside the place the marker stays on its edge


## Where the player is when beyond the village (or the settlement shown) (MAP-01, owner: "the map isn't following me"): {tiles (from the
## nearest edge of the village), way ("south-west"), dir (unit vector, screen axes)}; {} inside it.
func outside() -> Dictionary:
	var ow: Overworld = main.world.map.overworld
	var place: Rect2i = ow.village if target == "" else ow.site(target).rect
	var at: Vector2 = main.world.player.pos
	var edge := at.clamp(Vector2(place.position), Vector2(place.end))
	var off := at - edge
	if off.length() < 0.5:
		return {}
	var names := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]
	var i := int(round(fposmod(off.angle(), TAU) / (TAU / 8.0))) % 8
	return {"tiles": roundi(off.length()), "way": names[i], "dir": off.normalized()}


## The control fills the window under its title: the panel body scrolls, so its height is set here.
func _fit() -> void:
	var scroll := get_parent().get_parent() as Control if get_parent() else null
	var h: float = scroll.size.y if scroll and scroll.size.y > 100.0 else main.get_viewport().get_visible_rect().size.y - 100.0
	var first := get_parent().get_child(0) as Control if get_parent() else null
	if first != null and first != self:
		h -= first.size.y + 8.0                    # REGION-NAV-01: the Village | Region bar above the map
	if absf(custom_minimum_size.y - h) > 0.5:
		custom_minimum_size = Vector2(0, h)


func _process(delta: float) -> void:
	_fit()
	if size.x > 10.0 and size.y > 10.0 and (not fitted or (not moved and size != _fit_size)):
		fit()
	if is_visible_in_tree():
		_pad_step(delta)
		if aerial != null and not aerial.hi_queue.is_empty():
			aerial.pump_hi(8000)
	queue_redraw()                    # the player marker pulses


## A pad on the open map: the right stick pans, the triggers zoom about the middle (the left stick and the buttons work the
## window as everywhere: B closes it).
func _pad_step(delta: float) -> void:
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		return
	var d := int(pads[0])
	var v := Vector2(Input.get_joy_axis(d, JOY_AXIS_RIGHT_X), Input.get_joy_axis(d, JOY_AXIS_RIGHT_Y))
	if v.length() > 0.25:
		pan(-v * PAN_SPEED * delta)
	var t := Input.get_joy_axis(d, JOY_AXIS_TRIGGER_RIGHT) - Input.get_joy_axis(d, JOY_AXIS_TRIGGER_LEFT)
	if absf(t) > 0.2:
		zoom_at(map_size() / 2.0, pow(PAD_ZOOM, t * delta))


## The places named on the map, most important first: [text, tile position of the mark, priority (0 always shown, 1 when
## there is room, 2 only when zoomed in)].
func places_here() -> Array:
	var out := []
	if target == "":
		for pl in places():
			out.append([pl[0], pl[1], 0])
		var map: VillageMap = main.map
		for b in map.data.buildings:
			if not b.has("name") and b.type != "manor":
				out.append([World.cap(str(b.type)), Vector2(b.x + b.w / 2.0, b.y + b.h / 2.0), 2])
		return out
	var ow: Overworld = main.world.map.overworld
	var st: Dictionary = ow.site(target)
	out.append([str(st.name), Vector2((st.rect as Rect2i).position) + Vector2((st.rect as Rect2i).size.x / 2.0, -1.5), 0])
	for sl in st.slots:
		var stamp := Overworld.slot_stamp(sl)
		var r: Rect2i = sl.rect
		var at := Vector2(r.position) + Vector2(r.size) / 2.0
		var trade := str(sl.get("trade", ""))
		var name := ""
		var pri := 1
		if stamp.begins_with("church"):
			name = "Church"
			pri = 0
		elif stamp.ends_with("@manor") or stamp == "manor":
			name = "Manor"
			pri = 0
		elif stamp == "buttercross":
			name = "Market cross"
			pri = 0
		elif stamp == "fountain":
			name = "Fountain"
		elif trade != "":
			name = _trade_name(trade, stamp)
		elif stamp.begins_with("house") or "@house" in stamp:
			continue
		else:
			name = World.cap(stamp.get_slice("@", 0).replace("_", " "))
			pri = 2
		out.append([name, at, pri])
	for pr in st.get("props", []):
		var r: Rect2i = pr.rect
		var kind := str(pr.get("stamp", ""))
		if kind == "well":
			out.append(["Well", Vector2(r.position) + Vector2(r.size) / 2.0, 1])
		elif kind == "churchyard":
			out.append(["Churchyard", Vector2(r.position) + Vector2(r.size) / 2.0, 2])
		elif kind == "stall":
			out.append(["Market", Vector2(r.position) + Vector2(r.size) / 2.0, 1])
	if bool(st.get("walled", false)):
		out.append(["Town wall", Vector2((st.rect as Rect2i).position) + Vector2(2, 1), 2])
	var streams: Array = ow.streams_in(frame)
	for b in RegionMapPanel.bridge_points(ow, streams, frame):
		out.append(["Bridge", b, 1])
	return out


static func _trade_name(trade: String, stamp: String) -> String:
	var shop := {"workshop_bakehouse": "Bakehouse", "workshop_carpentry": "Carpenter", "workshop_apothecary": "Apothecary",
			"workshop_storage": "Storehouse", "workshop_kitchen": "Kitchen", "workshop_smithy": "Smithy", "workshop_tavern": "Inn"}
	if shop.has(stamp):
		return "%s (%s)" % [shop[stamp], trade]
	return World.cap(trade) + "'s house"


func _draw() -> void:
	var ms := map_size()
	draw_rect(Rect2(Vector2.ZERO, size), BACK)
	var r := map_rect()
	var view := Rect2(to_tile(Vector2.ZERO), ms / zoom)
	var ow: Overworld = main.world.map.overworld
	# under the close pictures: the one-pixel-a-tile village, then the region's pages, as placeholders while drawing
	var v := Rect2(ow.village)
	draw_texture_rect(tex, Rect2(to_screen(v.position), v.size * zoom), false)
	if aerial != null:
		var a := AerialMap.page_of(Overworld.chunk_of(Vector2i(view.position.floor())))
		var z := AerialMap.page_of(Overworld.chunk_of(Vector2i(view.end.floor())))
		for py in range(a.y, z.y + 1):
			for px in range(a.x, z.x + 1):
				var t := aerial.page_tex(Vector2i(px, py))
				if t != null:
					var pr := AerialMap.page_rect(Vector2i(px, py))
					draw_texture_rect(t, Rect2(to_screen(pr.position), pr.size * zoom), false)
		var keep := {}
		var c0 := Overworld.chunk_of(Vector2i(view.position.floor()).max(frame.position))
		var c1 := Overworld.chunk_of(Vector2i(view.end.floor()).min(frame.end))
		if zoom < HI_ZOOM:
			c1 = c0 - Vector2i.ONE                 # zoomed out on a large town: its 2 px a tile pages are enough
		var mid := Overworld.chunk_of(Vector2i(centre.floor()))
		var want: Array[Vector2i] = []
		for cy in range(c0.y, c1.y + 1):
			for cx in range(c0.x, c1.x + 1):
				if aerial.shown(Vector2i(cx, cy)):
					want.append(Vector2i(cx, cy))
		want.sort_custom(func(p: Vector2i, q: Vector2i): return (p - mid).length_squared() < (q - mid).length_squared())
		for cc in want.slice(0, AerialMap.HI_VIEW):
			keep[cc] = true
			var t := aerial.hi_tex(cc)
			if t != null:
				draw_texture_rect(t, Rect2(to_screen(Vector2(cc * Overworld.CHUNK)), Vector2(Overworld.CHUNK, Overworld.CHUNK) * zoom), false)
		aerial.hi_trim(keep)
	var font := get_theme_default_font()
	var fs := 13 if size.y < 420.0 else 16
	var taken: Array[Rect2] = []
	var p: PlayerState = main.world.player
	var pos := player_point()
	var rad := clampf(zoom * 0.9, 5.0, 9.0)
	taken.append(Rect2(pos - Vector2(rad, rad) * 1.5, Vector2(rad, rad) * 3.0))
	if target == "" and p.home != "" and main.world.buildings.has(p.home):
		var b: Dictionary = main.world.buildings[p.home]
		var hr := Rect2(to_screen(Vector2(b.x, b.y)), Vector2(b.w, b.h - 1) * zoom)
		draw_rect(hr, HOME, false, 2.0)
		_label(font, fs, "Home", hr.get_center(), HOME, taken, true)
	for pl in _labels_cache:
		var pri := int(pl[2])
		if pri == 2 and zoom < 5.0:
			continue
		_label(font, fs if pri == 0 else fs - 2, pl[0], to_screen(pl[1]), PALE, taken, pri == 0)
	if target == "":
		# what the screen shows now
		var cam: Camera2D = main.camera
		var vw: Vector2 = main.get_viewport().get_visible_rect().size / cam.zoom / T
		var at: Vector2 = cam.get_screen_center_position() / T
		draw_rect(Rect2(to_screen(at - vw / 2.0), vw * zoom).intersection(r), PALE, false, 1.5)
	# the player: a red dot with a dark rim and a pulsing ring
	var pulse := fmod(Time.get_ticks_msec() / 900.0, 1.0)
	draw_arc(pos, rad + pulse * rad * 2.0, 0, TAU, 24, Color(YOU, 1.0 - pulse), 2.0)
	draw_circle(pos, rad + 1.5, WALL)
	draw_circle(pos, rad, YOU)
	var away := outside()                          # MAP-01: beyond the map, an arrow at its edge toward the player, and how far
	if not away.is_empty():
		var dir: Vector2 = away.dir
		var tip := pos + dir * (rad + 14.0)
		var side := Vector2(-dir.y, dir.x) * 6.0
		draw_colored_polygon(PackedVector2Array([tip, pos + dir * (rad + 4.0) + side, pos + dir * (rad + 4.0) - side]), YOU)
		var say := "You: %d tiles %s of %s" % [int(away.tiles), str(away.way), "the village" if target == "" else str(ow.site(target).name)]
		var w := font.get_string_size(say, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var lp := Vector2(clampf(pos.x - w / 2.0, 2, ms.x - w - 2), clampf(pos.y - dir.y * 28.0 - rad, fs, ms.y - 4))
		draw_string_outline(font, lp, say, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color.BLACK)
		draw_string(font, lp, say, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, PALE)
	if aerial != null and not aerial.hi_queue.is_empty():
		var note := "Drawing the map…"
		draw_string_outline(font, Vector2(10, ms.y - 10), note, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color.BLACK)
		draw_string(font, Vector2(10, ms.y - 10), note, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, PALE)
	# the legend
	draw_rect(Rect2(0, ms.y, size.x, LEGEND), BACK)
	var y := size.y - 6.0
	var x := 8.0
	draw_circle(Vector2(x + 6, y - 5), 5, YOU)
	x += 16
	draw_string_outline(font, Vector2(x, y), "You", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color.BLACK)
	draw_string(font, Vector2(x, y), "You", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, PALE)
	x += 44
	if target == "":
		draw_rect(Rect2(x, y - 11, 18, 11), PALE, false, 1.5)
		x += 24
	var hints := ["What the screen shows  ·  tap to look there  ·  drag to move, pinch or wheel to zoom",
			"Tap to look there · drag to move · pinch to zoom", "Tap to look"]
	if target != "":
		hints = ["Tap to look there  ·  drag to move, pinch or wheel to zoom  ·  dark: not yet explored",
				"Tap to look · drag · pinch to zoom", "Tap to look"]
	for hint in hints:
		if x + font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x <= size.x - 4:
			draw_string_outline(font, Vector2(x, y), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color.BLACK)
			draw_string(font, Vector2(x, y), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, PALE)
			break


## A label beside a point, with a dark outline so it reads on any ground: centred under it, else above, right or left of
## it, wherever it covers no label or mark already placed (`taken`); a label that `must` show and finds no room goes in
## the first place anyway, another is left out. Kept inside the map.
func _label(font: Font, fs: int, text: String, at: Vector2, colour: Color, taken: Array[Rect2], must := true) -> void:
	var ms := map_size()
	if at.x < -40 or at.y < -20 or at.x > ms.x + 40 or at.y > ms.y + 20:
		return
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var h := float(fs) + 4.0
	var tries := [Vector2(at.x - w / 2.0, at.y - h / 2.0), Vector2(at.x - w / 2.0, at.y + 6.0), Vector2(at.x - w / 2.0, at.y - 6.0 - h),
			Vector2(at.x + 8.0, at.y - h / 2.0), Vector2(at.x - 8.0 - w, at.y - h / 2.0)]
	var pick := Vector2.INF
	for t: Vector2 in tries:
		var box := Rect2(t - Vector2(2, 0), Vector2(w + 4, h))
		if not taken.any(func(o: Rect2): return o.intersects(box)):
			pick = t
			break
	if pick == Vector2.INF:
		if not must:
			return
		pick = tries[0]
	pick.x = clampf(pick.x, 2.0, maxf(2.0, ms.x - w - 2.0))
	pick.y = clampf(pick.y, 0.0, maxf(0.0, ms.y - h))
	taken.append(Rect2(pick - Vector2(2, 0), Vector2(w + 4, h)))
	var base := pick + Vector2(0, fs)
	draw_string_outline(font, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color.BLACK)
	draw_string(font, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, colour)


## A tap or click that was not a drag: close the map and look at that spot (Recenter brings the view back). A drag pans,
## a pinch or the wheel zooms.
func _gui_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		if e.pressed:
			_touches[e.index] = e.position
			if _touches.size() >= 2:
				_gesture = true
				_pinch_start()
			else:
				_gesture = false
				_press = e.position
				_dragging = false
		else:
			_touches.erase(e.index)
			if _touches.size() >= 2:
				_pinch_start()
			elif _touches.is_empty():
				var was_tap: bool = _press != Vector2.INF and not _dragging and not _gesture
				_press = Vector2.INF
				if was_tap:
					_tap(e.position)
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
				_clamp()
				_pinch_mid = mid
				_pinch_zoom = zoom
				_pinch_d = d
				moved = true
		elif _press != Vector2.INF:
			if not _dragging and e.position.distance_to(_press) > DRAG:
				_dragging = true
			if _dragging:
				pan(e.relative)
		accept_event()
	elif e is InputEventMouseButton and e.device != InputEvent.DEVICE_ID_EMULATION:
		var mb := e as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			zoom_at(mb.position, 1.15)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			zoom_at(mb.position, 1.0 / 1.15)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_press = mb.position
				_dragging = false
			else:
				var was_tap := _press != Vector2.INF and not _dragging
				_press = Vector2.INF
				_dragging = false
				if was_tap:
					_tap(mb.position)
		accept_event()
	elif e is InputEventMouseMotion and e.device != InputEvent.DEVICE_ID_EMULATION:
		var mm := e as InputEventMouseMotion
		if _press != Vector2.INF and (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			if not _dragging and mm.position.distance_to(_press) > DRAG:
				_dragging = true
			if _dragging:
				pan(mm.relative)
		accept_event()
	elif e is InputEventMagnifyGesture:
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


func _tap(at: Vector2) -> void:
	if at.y > map_size().y:
		return
	main.ui.hide_all()
	main.look_at_tile(to_tile(at))
