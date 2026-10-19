class_name TreeView
extends Node2D
## Draws every tree (Trees, the one tree model) as a sprite: the village's trees and the overworld's trees chunk by chunk (OverworldView hands them over as it loads
## and frees chunks). Sits inside Main's y-sorted `actors` node, so a character is drawn behind a tree
## when they are north of its trunk and in front when south; a canopy fades while the player is
## under it. The sprite is the stage: sapling, young, growing, mature, or the stump after felling.
##
## It only draws what the model says. It listens to World.tree_changed / tree_hit / tree_felled, and
## twice a second brings up to the clock the trees whose next stage is due (growing, stumps, hurt):
## each waits for its own game minute, so a mature or not-yet-due tree costs nothing.
## The pictures are reduced to the game's 16 px scale at import (tools/living_forest.py), so they
## are drawn at scale 1 with nearest filtering.

const T := 16
const BASE_Y := 14.0                 # the trunk's base inside its cell (pixels from the top)
const FADE_ALPHA := 0.4
const BUILD_PER_FRAME := 160         # overworld trees added a frame (a loaded chunk can hold hundreds)

class TreeNode extends Sprite2D:
	var rec: Dictionary = {}
	var drawn := ""
	var hits := 0
	var cuts: Sprite2D = null
	var alpha_to := 1.0

var world: World
var nodes := {}                      # trunk cell -> TreeNode
var live := {}                       # trunk cell -> game minute it next changes, for trees not mature or hurt
var chunk_cells := {}                # overworld chunk -> Array of trunk cells
var _queue: Array = []               # [chunk, record] waiting to be drawn
var _fading := {}                    # cells whose canopy is faded or on its way
var _poll := 0.0


func setup(w: World) -> void:
	world = w
	y_sort_enabled = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	w.tree_changed.connect(refresh)
	w.tree_hit.connect(_on_hit)
	w.tree_felled.connect(_on_felled)
	for t in w.trees:
		add_tree(t)


static func base_of(rec: Dictionary) -> Vector2:
	return Vector2(int(rec.x) * T + T / 2, int(rec.y) * T + BASE_Y)


# ---------------------------------------------------------------- nodes ----------------------
func add_tree(rec: Dictionary) -> void:
	var cell := Vector2i(int(rec.x), int(rec.y))
	var n: TreeNode = nodes.get(cell)
	if n == null:
		n = TreeNode.new()
		n.centered = false
		n.position = base_of(rec)
		add_child(n)
		nodes[cell] = n
	n.rec = rec
	_dress(n)


## The trees of an overworld chunk (OverworldView calls this as it builds the chunk).
func load_chunk(cc: Vector2i, list: Array) -> void:
	unload_chunk(cc)
	chunk_cells[cc] = []
	for t in list:
		_queue.append([cc, t])


func unload_chunk(cc: Vector2i) -> void:
	if not chunk_cells.has(cc):
		return
	for cell: Vector2i in chunk_cells[cc]:
		_remove(cell)
	chunk_cells.erase(cc)
	_queue = _queue.filter(func(e): return e[0] != cc)


## Draw everything queued now (a first view, a teleport, tests).
func flush() -> void:
	while not _queue.is_empty():
		_add_queued(_queue.size())


func _add_queued(n: int) -> void:
	for k in mini(n, _queue.size()):
		var e: Array = _queue.pop_front()
		if not chunk_cells.has(e[0]):
			continue
		var cell := Vector2i(int(e[1].x), int(e[1].y))
		chunk_cells[e[0]].append(cell)
		add_tree(e[1])


func _remove(cell: Vector2i) -> void:
	var n: TreeNode = nodes.get(cell)
	if n != null:
		n.queue_free()
	nodes.erase(cell)
	live.erase(cell)
	_fading.erase(cell)


func node_at(cell: Vector2i) -> TreeNode:
	return nodes.get(cell)


## Redraw a tree whose record changed (a signal of the world, or a poll).
func refresh(rec: Dictionary) -> void:
	var cell := Vector2i(int(rec.x), int(rec.y))
	var n: TreeNode = nodes.get(cell)
	if n == null:
		if rec.get("ow", false):
			var cc := Overworld.chunk_of(cell)
			if not chunk_cells.has(cc):
				return                      # outside the loaded chunks: drawn when its chunk is
			chunk_cells[cc].append(cell)    # a new tree (planted) goes when its chunk does
		add_tree(rec)
		return
	n.rec = rec
	_dress(n)


## The sprite for the tree's state; cut marks for the blows it has taken.
func _dress(n: TreeNode) -> void:
	var rec := n.rec
	var state := str(rec.state)
	var cell := Vector2i(int(rec.x), int(rec.y))
	if state == "cleared":
		_remove(cell)
		return
	var v: Dictionary = Trees.variant(str(rec.get("species", "oak_summer")))
	var file := ""
	var pivot := Vector2.ZERO
	var off := Vector2.ZERO
	match state:
		"stump":
			var s: Dictionary = v.stump
			file = s.file
			pivot = Vector2(v.pivot[0], v.pivot[1])
			off = Vector2(s.off[0], s.off[1])
		"sapling":
			var s: Dictionary = v.sapling
			file = s.file
			pivot = Vector2(s.pivot[0], s.pivot[1])
		_:
			var s: Dictionary = v.sizes[state if state != "grown" else "mature"]
			if state == "grown" and v.has("fruit") and world != null and Trees.fruit_ripe(rec, world.day(), world.season()):
				s = v.fruit                    # B14: the fruit hangs on it
			file = s.file
			pivot = Vector2(s.pivot[0], s.pivot[1])
	n.texture = Trees.texture(file)
	n.offset = off - pivot
	n.drawn = state
	var hits := world.tree_hits(cell) if world != null and state == "grown" else 0
	n.hits = hits
	_cuts(n, v, pivot, hits, cell)
	if state == "grown" and hits == 0:
		live.erase(cell)
	elif world != null:
		# the game minute it is next worth a look: its next stage, or within the hour while hurt (healing)
		live[cell] = minf(Trees.next_change(rec), world.minutes + 60.0) if hits > 0 else Trees.next_change(rec)


func _cuts(n: TreeNode, v: Dictionary, pivot: Vector2, hits: int, cell: Vector2i) -> void:
	if hits <= 0:
		if n.cuts != null:
			n.cuts.queue_free()
			n.cuts = null
		return
	if n.cuts == null:
		n.cuts = Sprite2D.new()
		n.cuts.centered = false
		n.add_child(n.cuts)
	var side: int = int(world.tree_damage.get(cell, {}).get("side", 1))
	var c: Dictionary = v.cuts["left" if side < 0 else "right"][mini(hits, 3) - 1]
	n.cuts.texture = Trees.texture(c.file)
	n.cuts.position = Vector2(c.off[0], c.off[1]) - pivot


# ---------------------------------------------------------------- effects --------------------
func _on_hit(rec: Dictionary, side: int, _hits: int) -> void:
	var cell := Vector2i(int(rec.x), int(rec.y))
	var n: TreeNode = nodes.get(cell)
	if n == null:
		return
	_dress(n)
	var x0 := n.position.x
	var tw := create_tween()                # the trunk shudders
	for dx in [-side, side, -side * 0.5, 0.0]:
		tw.tween_property(n, "position:x", x0 + dx, 0.035)
	var base := n.position
	for k in 4:
		var chip := Sprite2D.new()
		chip.texture = Trees.texture(str(Trees.art().effects.chips[k % Trees.art().effects.chips.size()].file))
		chip.position = base + Vector2(side * 2.0, -10.0 + k)
		add_child(chip)
		var vel := Vector2(side * (-18.0 - 12.0 * k) + (k - 1.5) * 4.0, -34.0 - 8.0 * (k % 2))
		_fly(chip, vel, 0.55)
	var leaves: Array = Trees.variant(str(rec.get("species", "oak_summer"))).leaves
	for k in 3:
		var leaf := Sprite2D.new()
		leaf.texture = Trees.texture(str(leaves[(k * 2 + int(rec.x)) % leaves.size()]))
		leaf.position = base + Vector2((k - 1) * 9.0, -38.0 - k * 6.0)
		add_child(leaf)
		_fly(leaf, Vector2((k - 1) * 6.0 + side * 4.0, 4.0), 1.1, 22.0)


## A short-lived particle: thrown with velocity `vel` (pixels a second), falling under `gravity`.
func _fly(s: Sprite2D, vel: Vector2, secs: float, gravity := 140.0) -> void:
	var from := s.position
	var tw := create_tween()
	tw.tween_method(func(t: float): s.position = from + vel * t + Vector2(0, gravity * t * t * 0.5), 0.0, secs, secs)
	tw.parallel().tween_property(s, "modulate:a", 0.0, secs * 0.3).set_delay(secs * 0.7)
	tw.tween_callback(s.queue_free)


## The top of a mature tree falls away from the axe, a poof where it lands; the stump is drawn by
## the refresh that follows.
func _on_felled(rec: Dictionary, side: int) -> void:
	var cell := Vector2i(int(rec.x), int(rec.y))
	var n: TreeNode = nodes.get(cell)
	if n == null or not is_inside_tree():
		return
	var v: Dictionary = Trees.variant(str(rec.get("species", "oak_summer")))
	var pivot := Vector2(v.pivot[0], v.pivot[1])
	var hinge := Vector2(0, -float(v.stump.h) * 0.55)          # where the trunk breaks, a little above the stump's foot
	var top := Sprite2D.new()
	top.texture = Trees.texture(str(v.top.file))
	top.centered = false
	top.offset = -pivot - hinge
	top.position = n.position + hinge
	add_child(top)
	var dir := float(-side)
	var tw := create_tween()
	tw.tween_property(top, "rotation", dir * deg_to_rad(88.0), 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var land := n.position + Vector2(dir * float(v.top.h) * 0.45, 2.0)
	tw.tween_callback(_poof.bind(land))
	tw.tween_property(top, "modulate:a", 0.0, 0.5).set_delay(0.25)
	tw.tween_callback(top.queue_free)
	for k in 8:
		var leaf := Sprite2D.new()
		var leaves: Array = v.leaves
		leaf.texture = Trees.texture(str(leaves[k % leaves.size()]))
		leaf.position = n.position + Vector2(dir * (6.0 + k * 3.0), -34.0 + (k % 3) * 8.0)
		add_child(leaf)
		_fly(leaf, Vector2(dir * 10.0, 8.0), 1.0 + 0.05 * k, 30.0)


func _poof(at: Vector2) -> void:
	var frames: Array = Trees.art().effects.poof
	var s := Sprite2D.new()
	s.position = at + Vector2(0, -2)
	add_child(s)
	var tw := create_tween()
	for f in frames:
		tw.tween_callback(func(): s.texture = Trees.texture(str(f.file)))
		tw.tween_interval(0.06)
	tw.tween_callback(s.queue_free)


# ---------------------------------------------------------------- per frame ------------------
## `feet`: the player's position (tiles). Fades the canopy over them, adds queued trees and brings
## the changing ones up to the clock.
func update(feet: Vector2, delta: float) -> void:
	if not _queue.is_empty():
		_add_queued(BUILD_PER_FRAME)
	_poll += delta
	if _poll >= 0.5 and world != null:
		_poll = 0.0
		for cell: Vector2i in live.keys():
			if float(live[cell]) > world.minutes:
				continue                    # not due: nothing to grow or heal yet
			var n: TreeNode = nodes.get(cell)
			if n == null:
				live.erase(cell)
				continue
			world.sync_tree(n.rec)
			if n.drawn != str(n.rec.state) or (n.drawn == "grown" and n.hits != world.tree_hits(cell)):
				_dress(n)
	# canopies over the player: the trees south of them whose sprite covers their head
	var p := feet * T
	var now := {}
	var c := Vector2i(floori(feet.x), floori(feet.y))
	for dy in range(0, 9):
		for dx in range(-4, 5):
			var cell := c + Vector2i(dx, dy)
			var n: TreeNode = nodes.get(cell)
			if n == null or n.texture == null:
				continue
			var r := Rect2(n.position + n.offset, n.texture.get_size())
			if p.y < n.position.y and r.has_point(p + Vector2(0, -8)):
				now[cell] = true
				_fading[cell] = true
				n.alpha_to = FADE_ALPHA
	for cell: Vector2i in _fading.keys():
		var n: TreeNode = nodes.get(cell)
		if n == null:
			_fading.erase(cell)
			continue
		if not now.has(cell):
			n.alpha_to = 1.0
		n.modulate.a = move_toward(n.modulate.a, n.alpha_to, delta * 4.0)
		if n.alpha_to == 1.0 and n.modulate.a >= 1.0:
			_fading.erase(cell)
