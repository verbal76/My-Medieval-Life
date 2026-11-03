class_name LookPreview
extends TextureRect
## B25R1-008 (owner directive 2026-11-03, 7A: "Prominent animated character preview"): a character sheet (29 x 8 frames of
## 32 px, ActorSprite's layout) drawn large and animated: standing, walking, a sword swing or carrying (ActorSprite.ANIMS,
## the frames play uses), facing one of the eight directions, turning by itself until a direction is chosen. Its texture is
## an AtlasTexture of the sheet (tests read texture.atlas). Put it on a LookPreview.Stage, which draws it at a whole-number
## scale (crisp pixels) on a shadow.

const POSES := {"walk": "Walking", "idle": "Standing", "sword": "Sword swing", "carry": "Carrying"}
const TURN_SECONDS := 1.6          # while turning by itself: this long on each direction
const CROP := 2                     # the frame less this many pixels each side (the figure and its swing stay whole)
const SIDE := 32 - 2 * CROP
const FEET := 22.5                  # the feet's line in the cropped frame (px), where the shadow lies

var anim := "walk"
var dir := 0                        # row of ActorSprite.DIRS
var turning := true
var _t := 0.0
var _turn_t := 0.0


func _init(sheet: Texture2D, pose := "walk", facing := 0, auto_turn := true) -> void:
	anim = pose
	dir = facing
	turning = auto_turn
	var at := AtlasTexture.new()
	at.atlas = sheet
	texture = at
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stretch_mode = TextureRect.STRETCH_SCALE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame()


func _process(delta: float) -> void:
	_t += delta
	if turning:
		_turn_t += delta
		if _turn_t >= TURN_SECONDS:
			_turn_t = 0.0
			dir = (dir + 1) % 8
	_frame()


func _frame() -> void:
	var a: Array = ActorSprite.ANIMS.get(anim, ActorSprite.ANIMS.idle)
	var cols: Array = a[0]
	var col := int(cols[int(_t / float(a[1])) % cols.size()])
	(texture as AtlasTexture).region = Rect2(col * 32 + CROP, dir * 32 + CROP, SIDE, SIDE)


## The box a LookPreview stands in: it sizes the figure to the largest whole multiple of its frame that fits, centred, with
## a soft shadow under its feet. At least `least` units square.
class Stage extends Control:
	var fig: LookPreview

	func _init(f: LookPreview, least: float) -> void:
		fig = f
		custom_minimum_size = Vector2(least, least)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		size_flags_vertical = Control.SIZE_EXPAND_FILL
		clip_contents = true
		add_child(f)
		resized.connect(_place)

	func _place() -> void:
		var k := maxf(1.0, floorf(minf(size.x, size.y) / float(LookPreview.SIDE)))
		fig.size = Vector2.ONE * LookPreview.SIDE * k
		fig.position = ((size - fig.size) / 2.0).floor()
		queue_redraw()

	func _draw() -> void:
		var k := fig.size.x / float(LookPreview.SIDE)
		var c := fig.position + Vector2(LookPreview.SIDE / 2.0, LookPreview.FEET) * k
		var pts := PackedVector2Array()
		for i in 24:
			var a := TAU * i / 24.0
			pts.append(c + Vector2(cos(a) * 6.0 * k, sin(a) * 1.6 * k))
		draw_colored_polygon(pts, Color(0, 0, 0, 0.35))
