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
	if lv == level or lv == level + 1:
		queue_redraw()


## MIN-F2: also the spoil a cell holds (backfill: brown earth, more of it the fuller; fallen rock: grey stones), shafts
## (a dark hole with the ladder's top at the mouth, its foot against the wall at the landing below) and how worn each
## support is (greyer as it weakens). Procedural pixels, as the rails.
const FILL := Color(0.45, 0.32, 0.19)
const FILL_DARK := Color(0.30, 0.21, 0.12)
const RUBBLE := Color(0.52, 0.50, 0.47)
const RUBBLE_DARK := Color(0.28, 0.27, 0.26)
const HOLE := Color(0.02, 0.02, 0.03)


func _draw() -> void:
	if works == null:
		return
	for k in works.cells:
		var p: PackedStringArray = str(k).split(",")
		if int(p[0]) == level:
			_draw_held(Vector2i(int(p[1]), int(p[2])), int(works.cells[k].get("fill", 0)), int(works.cells[k].get("rubble", 0)))
	for c in works.track_cells(level):
		_draw_track(c)
	for sh in works.shafts:
		if int(sh.level) == level:
			_draw_shaft_mouth(sh)
		elif int(sh.level) - 1 == level and works.shaft_done(sh) and int(sh.ladder) >= 0:
			_draw_ladder_foot(sh)
	for c in works.support_cells(level):
		_draw_support(c)


func _draw_held(c: Vector2i, fill: int, rubble: int) -> void:
	var o := Vector2(c) * tile
	var units := MineWorks.cell_units()
	if rubble > 0:
		draw_rect(Rect2(o, Vector2(16, 16)), RUBBLE_DARK)
		for i in 9:                                    # a heap of fallen stones, the same each time
			var h := Overworld.hash32(c.x, c.y, 91, i)
			var at := o + Vector2(1 + h % 12, 1 + (h / 16) % 12)
			draw_rect(Rect2(at, Vector2(3 + h % 2, 3)), RUBBLE)
			draw_rect(Rect2(at + Vector2(0, 2), Vector2(3 + h % 2, 1)), RUBBLE_DARK)
		return
	var share := float(fill) / float(units)
	if fill >= units:
		draw_rect(Rect2(o, Vector2(16, 16)), FILL_DARK)
		draw_rect(Rect2(o + Vector2(1, 1), Vector2(14, 14)), FILL)
		for i in 6:
			var h := Overworld.hash32(c.x, c.y, 93, i)
			draw_rect(Rect2(o + Vector2(2 + h % 11, 2 + (h / 16) % 11), Vector2(2, 1)), FILL_DARK)
		return
	var hgt := 16.0 * share                            # a partly filled passage: earth heaped from its foot
	draw_rect(Rect2(o + Vector2(0, 16.0 - hgt), Vector2(16, hgt)), Color(FILL, 0.85))
	draw_rect(Rect2(o + Vector2(0, 16.0 - hgt), Vector2(16, 1)), FILL_DARK)


func _draw_shaft_mouth(sh: Dictionary) -> void:
	var o := Vector2(int(sh.x), int(sh.y)) * tile
	draw_rect(Rect2(o, Vector2(16, 16)), WOOD_DARK)
	draw_rect(Rect2(o + Vector2(1, 1), Vector2(14, 14)), HOLE)
	if int(sh.rubble) > 0:
		draw_rect(Rect2(o + Vector2(3, 3), Vector2(10, 10)), RUBBLE)
		return
	if int(sh.ladder) >= 0:
		var worn := 1.0 - 0.5 * (1.0 - float(sh.ladder) / float(MineWorks.cfg().stability.full))
		for x in [4, 10]:
			draw_rect(Rect2(o + Vector2(x, 1), Vector2(2, 14)), WOOD * worn)
		for y in [3, 7, 11]:
			draw_rect(Rect2(o + Vector2(4, y), Vector2(8, 1)), WOOD_LIGHT * worn)


func _draw_ladder_foot(sh: Dictionary) -> void:
	var c := Vector2i(int(sh.x), int(sh.y))
	var o := Vector2(c) * tile
	draw_rect(Rect2(o + Vector2(2, 2), Vector2(12, 12)), Color(0, 0, 0, 0.25))
	for x in [4, 10]:
		draw_rect(Rect2(o + Vector2(x, -6), Vector2(2, 20)), WOOD)
	for y in [-3, 1, 5, 9]:
		draw_rect(Rect2(o + Vector2(4, y), Vector2(8, 1)), WOOD_LIGHT)


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
	var cond := clampf(float(works.support_condition(level, c)) / float(MineWorks.cfg().stability.full), 0.0, 1.0)
	var grey := Color(0.36, 0.34, 0.32)
	var wood := WOOD.lerp(grey, 1.0 - cond)            # MIN-F2: greyer as it weakens
	var light := WOOD_LIGHT.lerp(grey, 1.0 - cond)
	var o := Vector2(c) * tile + Vector2(0, -6)        # it stands up: drawn a little above its cell
	draw_rect(Rect2(o + Vector2(3, 4), Vector2(10, 18)), Color(0, 0, 0, 0.28))     # the shadow under the set
	for x in [0, 12]:                                  # the two posts, full height
		draw_rect(Rect2(o + Vector2(x, 2), Vector2(4, 20)), WOOD_DARK)
		draw_rect(Rect2(o + Vector2(x, 2), Vector2(3, 19)), wood)
		draw_rect(Rect2(o + Vector2(x, 2), Vector2(1, 19)), light)
		draw_rect(Rect2(o + Vector2(x + 1, 8), Vector2(1, 3)), WOOD_DARK)          # grain
	var sag := 1.0 if cond < 0.5 else 0.0               # a weak cap sags in the middle and cracks
	draw_rect(Rect2(o + Vector2(-1, 0), Vector2(18, 5)), WOOD_DARK)    # the cap beam across the posts
	draw_rect(Rect2(o + Vector2(-1, 0), Vector2(18, 4)), wood)
	draw_rect(Rect2(o + Vector2(-1, 0), Vector2(18, 1)), light)
	if sag > 0.0:
		draw_rect(Rect2(o + Vector2(5, 4), Vector2(6, 1 + sag)), WOOD_DARK)
		draw_rect(Rect2(o + Vector2(7, 0), Vector2(1, 4)), Color(0.08, 0.05, 0.03))
	draw_rect(Rect2(o + Vector2(3, 5), Vector2(2, 2)), WOOD_DARK)       # the wedges
	draw_rect(Rect2(o + Vector2(11, 5), Vector2(2, 2)), WOOD_DARK)
