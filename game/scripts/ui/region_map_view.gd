class_name RegionMapPanel
extends Control
## REGION-NAV-01 (owner 2026-11-02, "a toggle between the local map and a regional world map"; docs/region_nav/
## IMPLEMENTATION_PLAN.md AD-8): the region as THIS player knows it. Ground they have seen is drawn from the summaries
## Atlas took of the real overworld chunks (woods, rock, roads, open ground), in the game's own coordinates; ground they have
## not seen stays dark. The home village, the settlements whose place they know (visited or told: Atlas places) with their
## names, and where they are now. Nothing they have not legitimately learned is shown: a settlement they were told of is a
## named mark on dark ground until they walk there. Drawing only (the rules live in Atlas).

const COLOURS := [Color8(30, 22, 15), Color8(104, 128, 70), Color8(46, 78, 42), Color8(132, 124, 112),
		Color8(196, 164, 112), Color8(176, 132, 84), Color8(176, 132, 84)]      # by Atlas class: unknown, grass, wood, rock, road, site, village
const BACK := Color8(43, 29, 19)
const PALE := Color8(236, 214, 170)
const HOME := Color8(255, 214, 90)
const YOU := Color8(214, 52, 36)
const TOLD := Color8(170, 150, 120)
const LEGEND := 22.0

var main
var tex: ImageTexture
var bounds := Rect2i()              # the tiles the image covers


func setup(m) -> void:
	main = m
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var img := build_image(main.world, main.world.player)
	tex = ImageTexture.create_from_image(img)
	_fit()


## The tiles the map covers: the village, every chunk the player explored and every place they know, with a margin.
static func region_bounds(w: World, p: PlayerState) -> Rect2i:
	var ow: Overworld = w.map.overworld
	var b := ow.village.grow(Overworld.CHUNK)
	for cc: Vector2i in p.explored:
		b = b.merge(Rect2i(cc * Overworld.CHUNK, Vector2i(Overworld.CHUNK, Overworld.CHUNK)))
	for id in p.places:
		var st: Dictionary = ow.site(str(id))
		if not st.is_empty():
			b = b.merge((st.rect as Rect2i).grow(Overworld.CHUNK))
	b = b.merge(Rect2i(Vector2i(p.pos.floor()), Vector2i.ONE).grow(Overworld.CHUNK))
	# whole blocks, so a pixel is one Atlas block
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
			img.set_pixel((x - b.position.x) / Atlas.BLOCK, (y - b.position.y) / Atlas.BLOCK, COLOURS[Atlas.VILLAGE])
	return img


func map_rect() -> Rect2:
	var b := region_bounds(main.world, main.world.player)
	var room := size - Vector2(0, LEGEND)
	var s := maxf(0.05, minf(room.x / b.size.x, room.y / b.size.y))
	var dim := Vector2(b.size) * s
	return Rect2(Vector2((size.x - dim.x) / 2.0, (room.y - dim.y) / 2.0), dim)


func _to_screen(r: Rect2, tile: Vector2) -> Vector2:
	var b := region_bounds(main.world, main.world.player)
	return r.position + (tile - Vector2(b.position)) * (r.size.x / float(b.size.x))


func _fit() -> void:
	var scroll := get_parent().get_parent() as Control if get_parent() else null
	var h: float = scroll.size.y if scroll and scroll.size.y > 100.0 else main.get_viewport().get_visible_rect().size.y - 100.0
	var first := get_parent().get_child(0) as Control if get_parent() else null
	if first != null and first != self:
		h -= first.size.y + 8.0                    # REGION-NAV-01: the Village | Region bar above the map
	if absf(custom_minimum_size.y - h) > 0.5:
		custom_minimum_size = Vector2(0, h)


func _process(_delta: float) -> void:
	_fit()
	queue_redraw()


func _draw() -> void:
	var w: World = main.world
	var p: PlayerState = w.player
	var r := map_rect()
	draw_rect(r.grow(3), BACK)
	draw_texture_rect(tex, r, false)
	var font := get_theme_default_font()
	var fs := 14
	# home: the village
	var v := Rect2(w.map.overworld.village)
	var hp := _to_screen(r, v.get_center())
	draw_rect(Rect2(_to_screen(r, v.position), v.size * (r.size.x / float(region_bounds(w, p).size.x))), HOME, false, 2.0)
	draw_string_outline(font, hp + Vector2(6, -6), "Home", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color.BLACK)
	draw_string(font, hp + Vector2(6, -6), "Home", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, HOME)
	# the settlements this player knows
	for id in p.places:
		var st: Dictionary = w.map.overworld.site(str(id))
		if st.is_empty():
			continue
		var at := _to_screen(r, Vector2(st.center))
		var col := PALE if str(p.places[id].how) == "visited" else TOLD
		draw_rect(Rect2(at - Vector2(4, 4), Vector2(8, 8)), col)
		draw_rect(Rect2(at - Vector2(4, 4), Vector2(8, 8)), Color.BLACK, false, 1.0)
		var label := str(st.name) + ("" if str(p.places[id].how) == "visited" else " (heard of)")
		draw_string_outline(font, at + Vector2(7, 5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color.BLACK)
		draw_string(font, at + Vector2(7, 5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	# you
	var me := _to_screen(r, p.pos)
	var pulse := fposmod(Time.get_ticks_msec() / 900.0, 1.0)
	draw_arc(me, 5.0 + pulse * 10.0, 0, TAU, 24, Color(YOU, 1.0 - pulse), 2.0)
	draw_circle(me, 6.5, Color.BLACK)
	draw_circle(me, 5.0, YOU)
	var hint := "Dark ground: not yet seen. A place you have heard of is marked; walk there to see it."
	draw_string_outline(font, Vector2(8, size.y - 6), hint, HORIZONTAL_ALIGNMENT_LEFT, size.x - 16, 13, 4, Color.BLACK)
	draw_string(font, Vector2(8, size.y - 6), hint, HORIZONTAL_ALIGNMENT_LEFT, size.x - 16, 13, PALE)
