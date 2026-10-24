class_name StallShelf
extends Node2D
## GP-MARKET-SHELVES (owner, 2026-10-24): one market stall drawn as the owner's Craftpix shelf (game/assets/props/
## market_shelf_<look>.png, 53 x 43, the empty two-shelf unit widened by whole planks: tools/craftpix_shelves.py) over its
## two-cell footprint, with the goods it offers on its boards: up to ten kinds (Business.SHELF_SLOTS), five a board, top
## board first, each the game's own item icon at half size (8 px) standing on the board. A child of the y-sorted actors
## node, its position the middle of the footprint's bottom edge, so a customer in front is drawn over it and anyone
## behind it under it. Looks only (StallDisplayView sets `goods` from Business.shelves); collision is the stall's own.

const W := 53
const HALF_W := 26             # the drawing's left edge is this far left of the footprint's middle
const H := 43
const SLOT := 9                  # 8 px goods, 1 px apart
const FIRST_X := 4               # the boards begin after the left post
const BOTTOMS := [17, 36]        # the row each board's goods stand on (top board, lower board)
const PER_BOARD := 5
## The drawing stands this far below the footprint's bottom edge (its feet on the serving side's edge): the market's rows of
## stalls are two tiles apart and a 43 px shelf otherwise hid the lower board of the row behind it. Sorting is unchanged
## (the node's place): a customer at the use cell is still drawn in front.
const DROP := 6

static var _textures := {}
static var _icons := {}

var look := "light"
var goods: Array = []


func setup(at: Vector2i, shelf_look: String) -> void:
	look = shelf_look
	position = Vector2((at.x + 1) * 16, (at.y + 1) * 16)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func show_goods(now: Array) -> void:
	if now != goods:
		goods = now.duplicate()
		queue_redraw()


## Where goods slot `i` (0..9) is drawn, its top-left corner relative to the node.
static func slot_pos(i: int) -> Vector2:
	var board := floori(float(i) / PER_BOARD)
	return Vector2(-HALF_W + FIRST_X + (i % PER_BOARD) * SLOT, -H + DROP + int(BOTTOMS[board]) - 7)


static func texture_of(kind: String) -> Texture2D:
	if not _textures.has(kind):
		_textures[kind] = load("res://assets/props/market_shelf_%s.png" % kind)
	return _textures[kind]


static func icon(id: String) -> Texture2D:
	if not _icons.has(id):
		var path := "res://assets/icons/%s.png" % id
		_icons[id] = load(path) if ResourceLoader.exists(path) else null
	return _icons[id]


func _draw() -> void:
	draw_texture(texture_of(look), Vector2(-HALF_W, -H + DROP))
	for i in mini(goods.size(), PER_BOARD * BOTTOMS.size()):
		var tex := icon(str(goods[i]))
		if tex != null:
			draw_texture_rect(tex, Rect2(slot_pos(i), Vector2(8, 8)), false)
