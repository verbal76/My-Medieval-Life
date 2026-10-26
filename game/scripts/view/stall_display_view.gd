class_name StallDisplayView
extends Node2D
## B18-DP-01 (PL1-10 stage 3): a stall's or shop's goods shown on its counter, drawn with the game's existing item icons
## (assets/icons/<item>.png, the same ones the pack and the windows use) at half size, two to a tile along the counter's
## top edge, from the premises' REAL stock (Business.displays). A child of the village's MapView just over the "below1"
## layer (the awning and counters) and under the characters. Looks only: it reads the stock and never changes it, and a
## kind that sells out leaves the counter on the next look.
## GP-MARKET-SHELVES (owner, 2026-10-24): it also keeps one StallShelf per market stall in the y-sorted actors node, the
## goods from Business.shelves (merchants', villagers' and the player's stalls alike), and takes the stall's old table,
## crate and awning tiles off the drawn map at its two cells (the map data, its containers and collision are unchanged).

const T := 16
const HALF := 8
const EVERY := 0.5

var world: World
var shown: Array = []
var wait := 0.0
var icons := {}
var actors: Node2D                # GP-MARKET-SHELVES: where the shelves go (y-sorted with the characters)
var map_view: MapView
var shelves := {}                 # stall id -> StallShelf


func setup(w: World, actor_node: Node2D = null, view: MapView = null) -> void:
	world = w
	actors = actor_node
	map_view = view
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	refresh()


func _process(dt: float) -> void:
	wait -= dt
	if wait <= 0.0:
		wait = EVERY
		refresh()


func refresh() -> void:
	if world == null or world.business == null or world.brain == null:     # (a world being replaced is disposed: no brain)
		return
	var now: Array = world.business.displays()
	if now != shown:
		shown = now
		queue_redraw()
	if actors != null:
		_refresh_shelves()


func _refresh_shelves() -> void:
	var seen := {}
	for d in world.business.shelves():
		var id := str(d.id)
		seen[id] = true
		var sh: StallShelf = shelves.get(id)
		if sh == null or not is_instance_valid(sh):
			sh = StallShelf.new()
			sh.name = "Shelf_" + id
			sh.setup(Vector2i(int(d.x), int(d.y)), str(d.look))
			actors.add_child(sh)
			shelves[id] = sh
			_clear_tiles(Vector2i(int(d.x), int(d.y)))
		sh.show_goods(d.goods)
	for id in shelves.keys():
		if not seen.has(id):
			if is_instance_valid(shelves[id]):
				shelves[id].queue_free()
			shelves.erase(id)


## The stall's old art (a table and a crate or barrel, or the awning) off the drawn ground layer at its two cells.
func _clear_tiles(at: Vector2i) -> void:
	if map_view == null:
		return
	var l := map_view.layer("below0")
	if l == null:
		return
	for k in 2:
		l.erase_cell(at + Vector2i(k, 0))


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
