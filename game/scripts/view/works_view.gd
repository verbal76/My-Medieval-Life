class_name WorksView
extends Node2D
## MIN-F: the track and timber supports of one level (MineWorks; docs/build17/MIN_F_UNDERGROUND.md). Below the surface
## it is a child of the level's LevelView (it fades in and out with the level); on the surface (track in the mine's
## yard) a child of the village's MapView, under the characters, so it fades with the surface.
##
## No rail or timber-set art is among the imported packs (the paid Puny World atlas has the mine carts, drawn with its
## tiles by Main; Puny Dungeon's log beam and poles are "planned", not imported): the rails are drawn here as a few
## procedural pixels at the 16 px tile, as PitView's stakes and mounds are. A track cell shows wooden sleepers across
## its way and two iron rails, joined to the track beside it (four ways); a lone section lies east to west. A support is
## a timber set: two posts and a cap beam across the top of its cell.

const WOOD := Color(0.42, 0.28, 0.15)
const WOOD_DARK := Color(0.25, 0.16, 0.08)
const WOOD_LIGHT := Color(0.58, 0.41, 0.23)
const IRON := Color(0.62, 0.63, 0.66)
const IRON_DARK := Color(0.30, 0.31, 0.34)

var tile := 16
var works: MineWorks
var level := 0


func setup(mine_works: MineWorks, lv: int) -> void:
	works = mine_works
	level = lv
	if works != null and not works.changed.is_connected(_on_changed):
		works.changed.connect(_on_changed)
	queue_redraw()


func _on_changed(lv: int, _c: Vector2i) -> void:
	if lv == level:
		queue_redraw()


func _draw() -> void:
	if works == null:
		return
	for c in works.track_cells(level):
		_draw_track(c)
	for c in works.support_cells(level):
		_draw_support(c)


func _draw_track(c: Vector2i) -> void:
	var o := Vector2(c) * tile
	var e := works.track_at(level, c + Vector2i.RIGHT)
	var wv := works.track_at(level, c + Vector2i.LEFT)
	var n := works.track_at(level, c + Vector2i.UP)
	var s := works.track_at(level, c + Vector2i.DOWN)
	var across := e or wv or not (n or s)            # east-west (a lone section too)
	var along := n or s
	if across:                                        # sleepers north to south, rails east to west, edge to edge
		for x in [1, 5, 9, 13]:
			draw_rect(Rect2(o + Vector2(x, 3), Vector2(2, 10)), WOOD)
			draw_rect(Rect2(o + Vector2(x, 12), Vector2(2, 1)), WOOD_DARK)
		for y in [5, 10]:
			draw_rect(Rect2(o + Vector2(0, y), Vector2(16, 1)), IRON)
			draw_rect(Rect2(o + Vector2(0, y + 1), Vector2(16, 1)), IRON_DARK)
	if along:                                         # sleepers east to west, rails north to south
		for y in [1, 5, 9, 13]:
			draw_rect(Rect2(o + Vector2(3, y), Vector2(10, 2)), WOOD)
			draw_rect(Rect2(o + Vector2(3, y + 1), Vector2(10, 1)), WOOD_DARK)
		for x in [5, 10]:
			draw_rect(Rect2(o + Vector2(x, 0), Vector2(1, 16)), IRON)
			draw_rect(Rect2(o + Vector2(x + 1, 0), Vector2(1, 16)), IRON_DARK)


func _draw_support(c: Vector2i) -> void:
	var o := Vector2(c) * tile + Vector2(0, -6)        # it stands up: drawn a little above its cell
	draw_rect(Rect2(o + Vector2(3, 4), Vector2(10, 18)), Color(0, 0, 0, 0.28))     # the shadow under the set
	for x in [0, 12]:                                  # the two posts, full height
		draw_rect(Rect2(o + Vector2(x, 2), Vector2(4, 20)), WOOD_DARK)
		draw_rect(Rect2(o + Vector2(x, 2), Vector2(3, 19)), WOOD)
		draw_rect(Rect2(o + Vector2(x, 2), Vector2(1, 19)), WOOD_LIGHT)
		draw_rect(Rect2(o + Vector2(x + 1, 8), Vector2(1, 3)), WOOD_DARK)          # grain
	draw_rect(Rect2(o + Vector2(-1, 0), Vector2(18, 5)), WOOD_DARK)    # the cap beam across the posts
	draw_rect(Rect2(o + Vector2(-1, 0), Vector2(18, 4)), WOOD)
	draw_rect(Rect2(o + Vector2(-1, 0), Vector2(18, 1)), WOOD_LIGHT)
	draw_rect(Rect2(o + Vector2(3, 5), Vector2(2, 2)), WOOD_DARK)       # the wedges
	draw_rect(Rect2(o + Vector2(11, 5), Vector2(2, 2)), WOOD_DARK)
