class_name StallDisplayView
extends Node2D
## B18-DP-01 (PL1-10 stage 3): a stall's or shop's goods shown on its counter, drawn with the game's existing item icons
## (assets/icons/<item>.png, the same ones the pack and the windows use) at half size, two to a tile along the counter's
## top edge, from the premises' REAL stock (Business.displays). A child of the village's MapView just over the "below1"
## layer (the awning and counters) and under the characters. Looks only: it reads the stock and never changes it, and a
## kind that sells out leaves the counter on the next look.

const T := 16
const HALF := 8
const EVERY := 0.5

var world: World
var shown: Array = []
var wait := 0.0
var icons := {}


func setup(w: World) -> void:
	world = w
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	refresh()


func _process(dt: float) -> void:
	wait -= dt
	if wait <= 0.0:
		wait = EVERY
		refresh()


func refresh() -> void:
	if world == null or world.business == null:
		return
	var now: Array = world.business.displays()
	if now != shown:
		shown = now
		queue_redraw()


func _icon(id: String) -> Texture2D:
	if not icons.has(id):
		var path := "res://assets/icons/%s.png" % id
		icons[id] = load(path) if ResourceLoader.exists(path) else null
	return icons[id]


func _draw() -> void:
	for d in shown:
		var goods: Array = d.goods
		for i in goods.size():
			var tex := _icon(str(goods[i]))
			if tex == null:
				continue
			var at := Vector2(int(d.x) * T + i * HALF, int(d.y) * T + 5)
			draw_texture_rect(tex, Rect2(at, Vector2(HALF, HALF)), false)
