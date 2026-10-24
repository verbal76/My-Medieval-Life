class_name VillageMapPanel
extends Control
## The village map window's content: the whole village drawn small (one pixel per tile from the map
## data, scaled up with nearest filtering to fit the window), the named places, the player's home,
## what the screen shows now, and the player. A tap on the map looks there (main.look_at).

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

var main
var tex: ImageTexture
static var _img: Image
static var _key := ""
static var _tile_colours := {}     # tile value -> average colour


func setup(m) -> void:
	main = m
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tex = ImageTexture.create_from_image(image_for(main.map, main.world))
	_fit()


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


## Where the map image is drawn: the largest size that fits above the legend, centred.
func map_rect() -> Rect2:
	var map: VillageMap = main.map
	var room := size - Vector2(0, LEGEND)
	var s := maxf(0.5, minf(room.x / map.w, room.y / map.h))
	var dim := Vector2(map.w, map.h) * s
	return Rect2(Vector2((size.x - dim.x) / 2.0, (room.y - dim.y) / 2.0), dim)


## Where the player's marker is drawn, in this control.
func player_point() -> Vector2:
	var r := map_rect()
	var at: Vector2 = r.position + main.world.player.pos * (r.size.x / float(main.map.w))
	return at.clamp(r.position, r.end)            # outside the village the marker stays on the map's edge


## Where the player is when beyond the village map (MAP-01, owner: "the map isn't following me"): {tiles (from the
## nearest edge of the village), way ("south-west"), dir (unit vector, screen axes)}; {} inside it.
func outside() -> Dictionary:
	var map: VillageMap = main.map
	var at: Vector2 = main.world.player.pos
	var edge := at.clamp(Vector2.ZERO, Vector2(map.w, map.h))
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
	if absf(custom_minimum_size.y - h) > 0.5:
		custom_minimum_size = Vector2(0, h)


func _process(_delta: float) -> void:
	_fit()
	queue_redraw()                    # the player marker pulses


func _draw() -> void:
	var r := map_rect()
	var s := r.size.x / float(main.map.w)
	draw_rect(r.grow(3), WALL)
	draw_texture_rect(tex, r, false)
	var font := get_theme_default_font()
	var fs := 13 if size.y < 420.0 else 16
	var taken: Array[Rect2] = []
	var p: PlayerState = main.world.player
	if p.home != "" and main.world.buildings.has(p.home):
		var b: Dictionary = main.world.buildings[p.home]
		var hr := Rect2(r.position + Vector2(b.x, b.y) * s, Vector2(b.w, b.h - 1) * s)
		draw_rect(hr, HOME, false, 2.0)
		_label(font, fs, "Home", hr.get_center(), HOME, taken)
	for pl in places():
		_label(font, fs, pl[0], r.position + pl[1] * s, PALE, taken)
	# what the screen shows now
	var cam: Camera2D = main.camera
	var view: Vector2 = main.get_viewport().get_visible_rect().size / cam.zoom / T
	var at: Vector2 = cam.get_screen_center_position() / T
	draw_rect(Rect2(r.position + (at - view / 2.0) * s, view * s).intersection(r), PALE, false, 1.5)
	# the player: a red dot with a dark rim and a pulsing ring
	var pos := player_point()
	var rad := maxf(4.0, s * 1.3)
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
		var say := "You: %d tiles %s of the village" % [int(away.tiles), str(away.way)]
		var w := font.get_string_size(say, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var lp := Vector2(clampf(pos.x - w / 2.0, r.position.x + 2, r.end.x - w - 2), clampf(pos.y - dir.y * 28.0 - rad, r.position.y + fs, r.end.y - 4))
		draw_string_outline(font, lp, say, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color.BLACK)
		draw_string(font, lp, say, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, PALE)
	# the legend
	var y := size.y - 6.0
	var x := r.position.x
	draw_circle(Vector2(x + 6, y - 5), 5, YOU)
	x += 16
	draw_string_outline(font, Vector2(x, y), "You", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color.BLACK)
	draw_string(font, Vector2(x, y), "You", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, PALE)
	x += 44
	draw_rect(Rect2(x, y - 11, 18, 11), PALE, false, 1.5)
	x += 24
	var hint := "What the screen shows  ·  tap the map to look there"
	draw_string_outline(font, Vector2(x, y), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color.BLACK)
	draw_string(font, Vector2(x, y), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, PALE)


## A label centred on a point, with a dark outline so it reads on any ground; kept inside the map,
## and moved down a line while it would cover a label already drawn (`taken`).
func _label(font: Font, fs: int, text: String, at: Vector2, colour: Color, taken: Array[Rect2]) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var r := map_rect()
	var pos := Vector2(clampf(at.x - w / 2.0, r.position.x + 2, r.end.x - w - 2), at.y + fs / 3.0)
	var box := Rect2(pos - Vector2(2, fs), Vector2(w + 4, fs + 4))
	for k in 4:
		if not taken.any(func(o: Rect2): return o.intersects(box)):
			break
		box.position.y += fs + 2
	pos.y = box.position.y + fs
	taken.append(box)
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color.BLACK)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, colour)


## A tap or click on the map: close it and look at that spot (Recenter brings the view back).
func _gui_input(e: InputEvent) -> void:
	var at := Vector2.INF
	if e is InputEventScreenTouch and e.pressed:
		at = e.position
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and e.device != InputEvent.DEVICE_ID_EMULATION:
		at = e.position
	var r := map_rect()
	if at == Vector2.INF or not r.has_point(at):
		return
	accept_event()
	main.ui.hide_all()
	main.look_at_tile((at - r.position) / (r.size.x / float(main.map.w)))
