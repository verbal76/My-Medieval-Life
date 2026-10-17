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


func setup(sheet_path: String) -> void:
	texture = load(sheet_path)
	hframes = 29
	vframes = 8
	offset = Vector2(0, -12)
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
