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
# VIS-AXE-01 (owner, Build 18): the held tool's pose for each frame of the swing, by the way the swinger faces ("side" is
# east, mirrored for west; NE/SE use it): [hand x, hand y (pixels from the feet, at the body's hand height), the
# direction the head points (degrees: 0 ahead, 90 down), mirror the icon (so the edge leads the stroke), drawn behind
# the body]. Wind-up raised behind the head (never across the face), the stroke to the trunk of the neighbouring cell,
# the recovery lowered. The icons (Survival RPG Icons, Tools) all lie handle low right, head high left.
const SWING_POSES := {
	"side": [[-1, -5, -155.0, true, true], [4, -4, 15.0, true, false], [4, -3, 50.0, true, false]],
	"south": [[4, -5, -70.0, true, true], [2, -1, 92.0, true, false], [3, -2, 120.0, true, false]],
	"north": [[-3, -5, -150.0, false, true], [-2, -6, -85.0, false, true], [2, -5, -40.0, false, true]],
}
const ICON_HEAD := -135.0                      # where an icon's head points, unmirrored (degrees, from the grip)

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
var weapon_icon: Sprite2D      # WEAPON-VISIBLE-01: the weapon carried in the hand while standing or walking
var weapon_item := ""          # the item id of the weapon carried ("" = none)
var striking := false          # a swing of the carried weapon is playing through (strike)
# WEAPON-VISIBLE-01 (owner, 2026-10-26: "walk around with it drawn so we get a chance to see it"): how a carried weapon is
# held, by the way the carrier faces ("side" is east, mirrored for west, as SWING_POSES): [hand x, hand y (from the feet),
# the direction its head points (degrees: 0 ahead, -90 up), mirror the icon, drawn behind the body]. Held low at the side,
# point raised; behind the body when facing away.
const CARRY_POSES := {"south": [5, -3, -70.0, false, false], "side": [2, -3, -60.0, true, false], "away": [-4, -4, -110.0, false, true]}
const CARRY_SCALE := 0.75


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


## WEAPON-VISIBLE-01: carry this weapon (an item id; "" for none). It is drawn while standing and walking; a swing with
## it is a "swing" with the weapon held (hold), as the axe's.
func wield(item: String) -> void:
	if item == weapon_item:
		return
	weapon_item = item
	if item == "":
		if weapon_icon:
			weapon_icon.visible = false
		return
	if weapon_icon == null:
		weapon_icon = Sprite2D.new()
		weapon_icon.name = "Weapon"
		weapon_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		weapon_icon.offset = Vector2(-5, -5)          # the grip, as the swung tool's
		add_child(weapon_icon)
	var path := "res://assets/icons/%s.png" % item
	weapon_icon.texture = load(path) if ResourceLoader.exists(path) else null


## WEAPON-VISIBLE-01: one blow with the carried weapon: the axe's swing (the throw frames, the swing poses) with the weapon in
## hand, played once through.
func strike() -> void:
	hold(weapon_item)
	play("swing", true)
	striking = true


## The carried weapon for this frame: shown standing or walking (not lying, sitting, at work, swinging or dead).
func _place_weapon(i: int) -> void:
	if weapon_icon == null:
		return
	weapon_icon.visible = weapon_item != "" and weapon_icon.texture != null and pose == "" and anim in ["idle", "walk"]
	if not weapon_icon.visible:
		return
	var key := "south" if dir == 0 else ("away" if dir in [3, 4, 5] else "side")
	var c: Array = CARRY_POSES[key]
	var hand := Vector2(float(c[0]), float(c[1]) - (1.0 if anim == "walk" and i % 2 == 1 else 0.0))     # a step's bob
	var head := float(c[2])
	var mirror: bool = c[3]
	if dir in [5, 6, 7]:                                    # faced west: mirrored
		hand.x = -hand.x
		head = 180.0 - head
		mirror = not mirror
	weapon_icon.scale = Vector2(-CARRY_SCALE if mirror else CARRY_SCALE, CARRY_SCALE)
	weapon_icon.rotation = deg_to_rad(head - ((-180.0 - ICON_HEAD) if mirror else ICON_HEAD))
	weapon_icon.position = hand
	weapon_icon.show_behind_parent = c[4]
	weapon_icon.z_index = 0 if c[4] else 1


## WEAPON-VISIBLE-01: the weapon a villager is drawn with: a guard's or a bandit's best (most damage, then id) at all
## times; anyone else's only while fighting ("sword"); "" for none. View only: nothing in the world reads it.
static func npc_weapon(n: NPC) -> String:
	if n == null or not n.alive:
		return ""
	if not (n.role == "bandit" or n.job == "guard" or n.anim == "sword"):
		return ""
	var best := ""
	for id in n.inv.ids():
		var it := GameData.item(str(id))
		if str(it.get("type", "")) != "weapon":
			continue
		if best == "" or int(it.get("damage", 0)) > int(GameData.item(best).get("damage", 0)) or \
				(int(it.get("damage", 0)) == int(GameData.item(best).get("damage", 0)) and str(id) < best):
			best = str(id)
	return best


## Where the held tool is for this frame of the swing (the node's own offset is (0, -7), so the hand is
## given from the sprite's centre).
func _place_tool(i: int) -> void:
	if tool_icon == null:
		return
	tool_icon.visible = anim == "swing" and tool_item != "" and tool_icon.texture != null
	if not tool_icon.visible:
		return
	var key := "south" if dir == 0 else ("north" if dir == 4 else "side")
	var poses: Array = SWING_POSES[key]
	var pose: Array = poses[i % poses.size()]
	var hand := Vector2(float(pose[0]), float(pose[1]))
	var head := float(pose[2])
	var mirror: bool = pose[3]
	if dir in [5, 6, 7]:                                    # faced west: the east pose mirrored
		hand.x = -hand.x
		head = 180.0 - head
		mirror = not mirror
	tool_icon.scale = Vector2(-0.85 if mirror else 0.85, 0.85)
	tool_icon.rotation = deg_to_rad(head - ((-180.0 - ICON_HEAD) if mirror else ICON_HEAD))   # mirrored, the head rests at -45
	tool_icon.position = hand
	tool_icon.show_behind_parent = pose[4]
	tool_icon.z_index = 0 if pose[4] else 1               # a relative z above the body would override drawing behind it


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
	striking = false


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
			striking = false
	if pose == "lie":
		frame = pose_row * 29 + 24
		if weapon_icon:
			weapon_icon.visible = false
		return
	frame = dir * 29 + int(cols[i % cols.size()])
	_place_tool(i % cols.size())
	_place_weapon(i % cols.size())
