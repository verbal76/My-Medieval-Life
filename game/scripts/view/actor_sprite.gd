class_name ActorSprite
extends Sprite2D
## An 8-direction PUNY CHARACTERS sheet (29 x 8 frames of 32 px; rows S, SE, E, NE, N, NW, W, SW).
## The node's position is the character's feet.

const DIRS := ["S", "SE", "E", "NE", "N", "NW", "W", "SW"]
# animation -> [columns, seconds per frame]; columns from tools/puny_chargen.py ANIMS
const ANIMS := {
	"idle": [[0, 1], 0.25],
	"walk": [[2, 3, 4], 0.13],
	"sword": [[5, 6, 7, 8], 0.08],
	"bow": [[9, 10, 11, 12], 0.1],
	"throw": [[16, 17, 18], 0.1],
	"hurt": [[19, 20, 21], 0.1],
	"death": [[22, 23, 24], 0.15],
	"carry": [[26, 25, 27], 0.13],
	"work": [[13, 14, 15], 0.18],
}

var anim := "idle"
var dir := 0
var t := 0.0
var once := false
var label: Label
var cover: Sprite2D            # the blanket drawn over someone lying in bed


## Lie in a bed (or on a pallet) whose cell centre is `at` (pixels), head toward `head` ("up", "left",
## "right"), under `blanket` (the bed tile's blanket, or null): the standing frame turned on its side
## (or, head up, as it is), the body over the bed cell and the head on the pillow.
func lie(at: Vector2, head: String, blanket: Texture2D) -> void:
	var turn := float({"up": 0.0, "left": -PI / 2.0, "right": PI / 2.0}.get(head, -PI / 2.0))
	# the drawn body's centre is 8 px from the feet (the position) toward the head: put it 1 px from
	# the bed's middle toward the foot, so the head lies on the pillow
	var to_body := Vector2(0, -8).rotated(turn)
	var toward_head := to_body.normalized()
	position = at - to_body - toward_head
	rotation = turn
	dir = 0
	if anim != "idle":
		play("idle")
	if cover == null:
		cover = Sprite2D.new()
		cover.top_level = true
		cover.z_index = 1
		cover.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(cover)
	cover.visible = blanket != null and visible
	if blanket != null:
		cover.texture = blanket
		cover.global_position = at - toward_head * 3.0


## Up again (any other animation).
func stand() -> void:
	rotation = 0.0
	if cover:
		cover.visible = false


func setup(sheet_path: String) -> void:
	texture = load(sheet_path)
	hframes = 29
	vframes = 8
	offset = Vector2(0, -7)          # the drawn feet (frame row 23) on the position, where collision has them
	frame = 0


func face(v: Vector2) -> void:
	if v.length_squared() < 0.0001:
		return
	var a := fposmod(atan2(v.x, v.y), TAU)        # 0 = south, counter-clockwise toward east
	dir = int(round(a / (TAU / 8.0))) % 8


func play(name: String, play_once := false) -> void:
	if name == anim and not play_once:
		return
	anim = name
	once = play_once
	t = 0.0


func _process(delta: float) -> void:
	t += delta
	var a: Array = ANIMS.get(anim, ANIMS.idle)
	var cols: Array = a[0]
	var i := int(t / a[1])
	if once and i >= cols.size():
		i = cols.size() - 1
		if anim != "death":
			anim = "idle"
			once = false
	frame = dir * 29 + int(cols[i % cols.size()])
