class_name AnimalSprite
extends Sprite2D
## An animal sheet. Two layouts:
##  - "cozy" (Cozy Farm): 4 frames x 5 rows of square frames: down, up, left, right, sleep (imported with a 1 px
##    transparent gutter round each frame, VIS-ANIMAL-01, so a frame never samples its neighbour);
##  - "puny" (Puny Monsters): 12 x 8 frames of 32 px, rows S, SE, E, NE, N, NW, W, SW; frames 0-3
##    are used as the walk (the sheet has no frame notes, so this choice is marked uncertain in
##    docs/BUILD_DECISIONS.md).
##  - "minifolks" (MiniFolks Forest Animals, B14): side views facing right (flipped for left), one row per
##    animation; ROWS gives each sheet's [row, frames] for idle, walk, attack, hit and death, counted from the
##    sheets and the pack's page (the bunny's and the bird's rows are not named there: marked uncertain in
##    docs/BUILD_DECISIONS.md).
##  - "farm" (Animal Farm, B14-11): 32 px frames read left to right (FARM): standing facing right, down, left,
##    up; walking left, down, up (two frames each; walking right is the left walk flipped); grazing facing
##    left (three frames, flipped for right), drawn while it stands facing sideways.
## Babies use the Cozy Farm baby sheet at full scale (B8-029); a species with no baby art (boar) is drawn at half scale. The node's position is the animal's feet.

const ROWS := {
	"mini_bear": {"idle": [0, 4], "walk": [1, 6], "attack": [3, 6], "hit": [6, 2], "death": [7, 4]},
	"mini_wolf": {"idle": [0, 4], "walk": [1, 6], "attack": [3, 5], "hit": [6, 2], "death": [7, 4]},
	"mini_boar": {"idle": [0, 4], "walk": [1, 4], "attack": [3, 5], "hit": [4, 2], "death": [5, 4]},
	"mini_doe": {"idle": [0, 4], "walk": [1, 4], "attack": [3, 5], "hit": [4, 2], "death": [5, 4]},
	"mini_stag": {"idle": [0, 4], "walk": [1, 4], "attack": [3, 5], "hit": [5, 2], "death": [6, 4]},
	"mini_fox": {"idle": [0, 4], "walk": [1, 4], "attack": [3, 6], "hit": [4, 2], "death": [5, 4]},
	"mini_bunny": {"idle": [0, 4], "walk": [1, 4], "attack": [0, 4], "hit": [2, 2], "death": [3, 3]},
	"mini_bird": {"idle": [0, 4], "walk": [1, 4], "attack": [0, 4], "hit": [0, 4], "death": [2, 3]},
}

const FARM := {"idle": {"r": 0, "d": 1, "l": 2, "u": 3}, "walk": {"l": [4, 5], "d": [6, 7], "u": [8, 9]}, "graze": [10, 11, 12]}

var layout := "cozy"
var t := 0.0
var baby := false          # drawing the baby sheet
var skin_now := ""


func setup(a: Animal, now := -1.0) -> void:
	var s := a.spec()
	var bs := a.baby_skin() if now >= 0.0 and not a.adult(now) else ""
	baby = bs != ""
	skin_now = bs if baby else a.skin
	texture = load("res://assets/animals/%s.png" % skin_now)
	var art := a.art()
	layout = str(art.layout)
	if layout == "puny":
		hframes = 12
		vframes = 8
	elif layout == "minifolks" or layout == "farm":
		hframes = texture.get_width() / int(art.frame)
		vframes = texture.get_height() / int(art.frame)
	else:
		hframes = 4
		vframes = 5
	var frame_px := float(s.get("baby_frame", s.frame)) if baby else float(art.frame)
	offset = Vector2(0, -frame_px / 2.0 + 3.0)


func show_state(a: Animal, now: float, dt: float) -> void:
	var bs := a.baby_skin() if not a.adult(now) else ""
	if (bs != "") != baby or (bs == "" and skin_now != a.skin):
		setup(a, now)                       # grew up (or loaded as a baby): the sheet changes
	scale = Vector2.ONE if (a.adult(now) or baby) else Vector2(0.5, 0.5)
	t += dt
	if layout == "minifolks":
		var rows: Dictionary = ROWS.get(skin_now, ROWS.mini_doe)
		var r: Array = rows.get(a.act, rows.walk if a.moving else rows.idle) if a.act != "" else (rows.walk if a.moving else rows.idle)
		flip_h = a.facing.x < 0.0
		frame = int(r[0]) * hframes + int(t / 0.15) % int(r[1])
		return
	if layout == "farm":
		var side := absf(a.facing.x) > absf(a.facing.y)
		var dir := ("r" if a.facing.x > 0.0 else "l") if side else ("d" if a.facing.y >= 0.0 else "u")
		flip_h = side and a.facing.x > 0.0           # the sheet walks and grazes facing left only
		if a.moving:
			var fr: Array = FARM.walk.get(dir, FARM.walk.l)
			frame = int(fr[int(t / 0.2) % fr.size()])
		elif side:
			frame = int(FARM.graze[int(t / 0.4) % FARM.graze.size()])
		else:
			frame = int(FARM.idle[dir])
		return
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
