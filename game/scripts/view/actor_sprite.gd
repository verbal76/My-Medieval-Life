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
const LIE_BODY_Y := -4.5      # the lying frame's body centre, from the feet (px; measured on the sheets: rows 12..24 of 32)
const LIE_FOOT_SHIFT := 1.5   # the body (17 px) is a little longer than the bed (16): shifted toward the foot this much
const SIT_DROP := -1.0        # seated: the feet are this far below the chair's centre (the cut line, 5 px above it, is the stool's top: the stool shows under the body)
const SIT_CUT := -4.0         # seated: nothing below this local y (the knees) is drawn
const SWING_ANGLES := [-15.0, 120.0, 95.0]    # degrees, per swing frame: the tool raised, down, following through
const SWING_HAND := Vector2(6, -8)            # the hand, from the feet (pixels), on the side faced

var anim := "idle"
var dir := 0
var t := 0.0
var speed_scale := 1.0         # animation speed (a sprint plays the walk faster; the screenshots freeze it at 0)
var once := false
var label: Label
var cover: Sprite2D            # the blanket drawn over someone lying in bed
var pose := ""                 # "" standing, "lie" in a bed, "sit" on a chair (PL1-07)
var pose_row := 2              # the sheet row of the lying frame (2 east: head left; 6 west: head right)
var tool_icon: Sprite2D        # the tool held in the hand while swinging
var tool_item := ""            # the item id of the tool shown ("" = none)


## Lie in a bed (or on a pallet) whose cell centre is `at` (pixels), head toward `head` ("up", "left",
## "right"), under `blanket` (the bed tile's blanket, or null). PL1-07: the sheet has a lying frame (the
## last frame of the fall, "death" column 24: the body flat, head to the west in the east row), so the
## sleeper is drawn from that, not the standing frame turned on its side: head left = the east row, head
## right = the west row, head up = the east row turned a quarter. The body's centre is put on the bed's
## middle and the sprite is drawn above the bed's own tiles (it lies ON the bed), the blanket over it.
func lie(at: Vector2, head: String, blanket: Texture2D) -> void:
	pose = "lie"
	pose_row = 6 if head == "right" else 2
	var turn := PI / 2.0 if head == "up" else 0.0
	var body := Vector2(0, LIE_BODY_Y).rotated(turn) * scale.x          # the lying body's centre, from the feet
	var to_foot: Vector2 = {"up": Vector2(0, 1), "left": Vector2(1, 0), "right": Vector2(-1, 0)}.get(head, Vector2(1, 0))
	position = at - body + to_foot * LIE_FOOT_SHIFT * scale.x          # the head a little inside the headboard
	rotation = turn
	z_index = 1
	_set_cut(false)
	if anim != "idle":
		play("idle")
	if cover == null:
		cover = Sprite2D.new()
		cover.top_level = true
		cover.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(cover)
	cover.z_index = 2
	cover.visible = blanket != null and visible
	if blanket != null:
		cover.texture = blanket
		cover.global_position = at + {"up": Vector2(0, 4), "left": Vector2(4, 0), "right": Vector2(-4, 0)}.get(head, Vector2(4, 0))


## Sit on a chair whose cell centre is `at` (pixels), looking toward direction index `d` (0 = south, see
## DIRS). PL1-07: the sheet has no sitting frames, so the standing frame is cut off at the knees (a shader,
## no art invented) and set down on the seat: the hips on the chair, the legs under whatever table or tile
## is drawn in front of it, or the stool's own top showing under the body.
func sit(at: Vector2, d: int) -> void:
	pose = "sit"
	dir = d
	rotation = 0.0
	z_index = 1                     # over the chair's own tile (a solid cell's overlay sorts by its bottom edge), whose seat shows under the hips
	if cover:
		cover.visible = false
	position = at + Vector2(0, SIT_DROP) * scale.x
	_set_cut(true)
	if anim != "idle":
		play("idle")


## Up again (any other animation).
func stand() -> void:
	if pose == "":
		return
	pose = ""
	rotation = 0.0
	z_index = 0
	_set_cut(false)
	if cover:
		cover.visible = false


## Seated: the lower legs are not drawn (local y below SIT_CUT, the feet being 0).
func _set_cut(on: bool) -> void:
	if not on:
		material = null
		return
	if material == null:
		var sh := Shader.new()
		sh.code = "shader_type canvas_item;\nvarying float ly;\nuniform float cut = -4.0;\nvoid vertex() { ly = VERTEX.y; }\nvoid fragment() { if (ly > cut) { discard; } }"
		var m := ShaderMaterial.new()
		m.shader = sh
		material = m
	(material as ShaderMaterial).set_shader_parameter("cut", SIT_CUT)


func setup(sheet_path: String) -> void:
	setup_texture(load(sheet_path))


## The same with a sheet already in hand (CC-01: the player's, composed from their recipe by CharacterLook).
func setup_texture(sheet: Texture2D) -> void:
	texture = sheet
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
	if pose == "lie":
		frame = pose_row * 29 + 24
		return
	frame = dir * 29 + int(cols[i % cols.size()])
	_place_tool(i % cols.size())
