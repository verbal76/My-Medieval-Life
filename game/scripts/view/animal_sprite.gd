class_name AnimalSprite
extends Sprite2D
## An animal sheet. Two layouts:
##  - "cozy" (Cozy Farm): 4 frames x 5 rows of square frames: down, up, left, right, sleep;
##  - "puny" (Puny Monsters): 12 x 8 frames of 32 px, rows S, SE, E, NE, N, NW, W, SW; frames 0-3
##    are used as the walk (the sheet has no frame notes, so this choice is marked uncertain in
##    docs/BUILD_DECISIONS.md).
## Babies are drawn at half scale. The node's position is the animal's feet.

var layout := "cozy"
var t := 0.0


func setup(a: Animal) -> void:
	var s := a.spec()
	texture = load("res://assets/animals/%s.png" % a.skin)
	layout = s.layout
	if layout == "puny":
		hframes = 12
		vframes = 8
	else:
		hframes = 4
		vframes = 5
	offset = Vector2(0, -float(s.frame) / 2.0 + 3.0)


func show_state(a: Animal, now: float, dt: float) -> void:
	scale = Vector2.ONE if a.adult(now) else Vector2(0.5, 0.5)
	t += dt
	var col := int(t / 0.2) % 4 if a.moving else 0
	var row := 0
	var v := a.facing
	if layout == "puny":
		var ang := fposmod(atan2(v.x, v.y), TAU)
		row = int(round(ang / (TAU / 8.0))) % 8
	elif absf(v.x) > absf(v.y):
		row = 3 if v.x > 0.0 else 2
	else:
		row = 0 if v.y >= 0.0 else 1
	frame = row * hframes + col
