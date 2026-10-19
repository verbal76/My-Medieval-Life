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
	# Build 8 (B8-007): the sheet has no pickaxe or axe animation, only a sword (5-8) and a staff (13-15)
	# swing with that weapon drawn in. "swing" is the bare-handed throw frames (16-18, nothing in hand)
	# with the tool's icon drawn in the hand over them (see hold); "gather" is the arms-forward carry
	# frames, for picking and harvesting. docs/BUILD_DECISIONS.md records the missing art.
	"swing": [[16, 17, 18], 0.16],
	"gather": [[26, 25, 27, 25], 0.2],
}
const SWING_ANGLES := [-15.0, 120.0, 95.0]    # degrees, per swing frame: the tool raised, down, following through
const SWING_HAND := Vector2(6, -8)            # the hand, from the feet (pixels), on the side faced

var anim := "idle"
var dir := 0
var t := 0.0
var speed_scale := 1.0         # animation speed (a sprint plays the walk faster; the screenshots freeze it at 0)
var once := false
var label: Label
var cover: Sprite2D            # the blanket drawn over someone lying in bed
var tool_icon: Sprite2D        # the tool held in the hand while swinging
var tool_item := ""            # the item id of the tool shown ("" = none)


## Lie in a bed (or on a pallet) whose cell centre is `at` (pixels), head toward `head` ("up", "left",
## "right"), under `blanket` (the bed tile's blanket, or null): the standing frame turned on its side
## (or, head up, as it is), the body over the bed cell and the head on the pillow.
func lie(at: Vector2, head: String, blanket: Texture2D) -> void:
	var turn := float({"up": 0.0, "left": -PI / 2.0, "right": PI / 2.0}.get(head, -PI / 2.0))
	# the drawn body's centre is 8 px from the feet (the position) toward the head: put it 2 px from
	# the bed's middle toward the foot, so the head lies on the pillow
	var to_body := Vector2(0, -8).rotated(turn)
	var toward_head := to_body.normalized()
	position = at - to_body - toward_head * 2.0
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
		cover.global_position = at - toward_head * 4.0


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


## Hold this item (a pickaxe or an axe) in the hand for the "swing" animation; "" puts it away.
func hold(item: String) -> void:
	tool_item = item
	if item == "":
		if tool_icon:
			tool_icon.visible = false
		return
	if tool_icon == null:
		tool_icon = Sprite2D.new()
		tool_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tool_icon.offset = Vector2(-5, -5)          # the grip (the icon's lower corner) is the pivot
		tool_icon.z_index = 1
		add_child(tool_icon)
		tool_icon.position = Vector2.ZERO
	tool_icon.texture = load("res://assets/icons/%s.png" % item)


## Where the held tool is for this frame of the swing (the node's own offset is (0, -7), so the hand is
## given from the sprite's centre).
func _place_tool(i: int) -> void:
	if tool_icon == null:
		return
	tool_icon.visible = anim == "swing" and tool_item != "" and tool_icon.texture != null
	if not tool_icon.visible:
		return
	var side := -1.0 if dir in [5, 6, 7, 4] else 1.0        # faced west (and north: the left) or east (and south)
	var a: float = SWING_ANGLES[i % SWING_ANGLES.size()]
	tool_icon.scale = Vector2(side, 1.0) * 0.85
	tool_icon.rotation = side * deg_to_rad(a + 45.0)
	tool_icon.position = Vector2(SWING_HAND.x * side, SWING_HAND.y)
	tool_icon.show_behind_parent = dir in [3, 4, 5]        # facing away: the tool is behind the body


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
	t += delta * speed_scale
	var a: Array = ANIMS.get(anim, ANIMS.idle)
	var cols: Array = a[0]
	var i := int(t / a[1])
	if once and i >= cols.size():
		i = cols.size() - 1
		if anim != "death":
			anim = "idle"
			once = false
	frame = dir * 29 + int(cols[i % cols.size()])
	_place_tool(i % cols.size())
