class_name GameEffects
extends Node2D
## JUICE J1 and J2 (owner Decision 9, 2026-11-01; docs/juice/PRELIMINARY_ASSESSMENT.md): the one lightweight visual-effects helper.
## Short-lived particles (chips, dust, sparks, sawdust, a poof) drawn from art the game already has (the Living Forest
## fx_chip_*, fx_dust_* and fx_poof_* in assets/trees, tinted), from a fixed pool of sprites, and two small tweens (flash,
## pulse) for interface feedback. Presentation only:
## - a caller triggers it from a real event (a successful swing, a delivery, a building finished, a seam worked out, damage
##   taken), never on a timer of its own;
## - it reads nothing of the world and changes nothing in it; its randomness is its own generator (`_rng`), never World.rng,
##   so the simulation draws exactly what it drew before (game/tests/juice_test.gd checks World.rng's state);
## - at most CAP particles live at once (a burst past the cap is cut short, never queued), each is gone within a second, and a
##   burst farther than CULL_TILES from `focus` (the camera's centre, set each frame by Main) draws nothing;
## - `reduce` (Settings, Interface, Reduce effects) turns every burst into one faint puff that does not fly, and drops the
##   flashes and pulses, so the cue that something happened stays and the motion goes.
## Multiplayer: it is fed from what each machine already shows (its own player's results, the villagers' animation and the
## world's records as the host's snapshots give them), so a guest sees the host's events and adds none of its own.

const T := 16.0
const CAP := 48                       # particles alive at once, at most (Android: a mid-range phone is the slowest target)
const CULL_TILES := 30.0              # the same distance the villagers' sprites are drawn within (Main._sync_sprites)
const ART := "res://assets/trees/%s.png"
const CHIPS := ["fx_chip_0", "fx_chip_1", "fx_chip_2", "fx_chip_3"]
const DUST := ["fx_dust_0", "fx_dust_1"]
const POOF := ["fx_poof_0", "fx_poof_1", "fx_poof_2", "fx_poof_3", "fx_poof_4", "fx_poof_5"]
# a kind of burst: the art it draws, how many, their tint, the speed they fly at (px/s), gravity (px/s2), life (s), and how
# far round the point they start (px). Tints darken or warm the wood-and-dust colours of the existing art; nothing is new art.
const KINDS := {
	"dust": {"art": DUST, "n": 3, "tint": Color(1, 1, 1, 0.9), "speed": 10.0, "gravity": -8.0, "life": 0.6, "spread": 4.0},
	"earth": {"art": DUST, "n": 4, "tint": Color(0.78, 0.62, 0.45, 0.95), "speed": 16.0, "gravity": 20.0, "life": 0.55, "spread": 5.0},
	"stone": {"art": CHIPS, "n": 5, "tint": Color(0.62, 0.62, 0.66), "speed": 40.0, "gravity": 150.0, "life": 0.5, "spread": 3.0, "with": "dust"},
	"sparks": {"art": ["fx_chip_3"], "n": 5, "tint": Color(1.6, 1.15, 0.45), "speed": 46.0, "gravity": 90.0, "life": 0.35, "spread": 2.0},
	"sawdust": {"art": CHIPS, "n": 4, "tint": Color(1.1, 1.02, 0.85), "speed": 18.0, "gravity": 60.0, "life": 0.6, "spread": 4.0},
	"deliver": {"art": CHIPS, "n": 3, "tint": Color(1, 1, 1), "speed": 22.0, "gravity": 110.0, "life": 0.45, "spread": 6.0, "with": "dust"},
	"poof": {"art": POOF, "n": 1, "tint": Color(1, 1, 1), "speed": 0.0, "gravity": 0.0, "life": 0.36, "spread": 0.0, "frames": true},
	"complete": {"art": POOF, "n": 3, "tint": Color(1, 1, 1), "speed": 6.0, "gravity": 0.0, "life": 0.36, "spread": 14.0, "frames": true, "with": "dust"},
	"deplete": {"art": POOF, "n": 1, "tint": Color(0.75, 0.75, 0.8), "speed": 0.0, "gravity": 0.0, "life": 0.36, "spread": 0.0, "frames": true, "with": "stone"},
}

var reduce := false                   # Settings, Interface, Reduce effects (Main sets it from GameSettings.reduce_effects)
var focus := Vector2.INF              # pixels: the camera's centre; INF draws everywhere (tests, before the first frame)
var bursts := 0                       # bursts that drew something (tests)
var _rng := RandomNumberGenerator.new()     # looks only: never the world's RNG
var _pool: Array[Sprite2D] = []
var _vel: Array[Vector2] = []
var _age: Array[float] = []
var _life: Array[float] = []
var _grav: Array[float] = []
var _frames: Array = []               # per particle: the textures it steps through ([] for one)
var _alpha: Array[float] = []
static var _tex := {}


func _init() -> void:
	_rng.seed = 0x4A3155            # fixed: the same looks every run, and independent of the world
	z_index = 12                     # over the characters and the ground, under the roofs' markers and the interface
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


static func tex(id: String) -> Texture2D:
	if not _tex.has(id):
		_tex[id] = load(ART % id)
	return _tex[id]


## A burst of `kind` (KINDS) at `at` (pixels). Returns how many particles it drew: 0 when culled, out of room or unknown.
func burst(kind: String, at: Vector2) -> int:
	var k: Dictionary = KINDS.get(kind, {})
	if k.is_empty() or (focus != Vector2.INF and at.distance_to(focus) > CULL_TILES * T):
		return 0
	var drawn := 0
	if reduce:
		# one faint puff that stays where it is: the cue without the motion
		drawn = _spawn(tex(DUST[0]), [], at, Vector2.ZERO, 0.0, 0.45, Color(1, 1, 1, 0.6))
	else:
		var art: Array = k.art
		for i in int(k.n):
			var off := Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 0.5)) * float(k.spread)
			var dirv := Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, -0.3)).normalized()
			var vel := dirv * float(k.speed) * _rng.randf_range(0.6, 1.0)
			var frames: Array = []
			var first: Texture2D
			if bool(k.get("frames", false)):
				for f in art:
					frames.append(tex(str(f)))
				first = frames[0]
			else:
				first = tex(str(art[_rng.randi() % art.size()]))
			drawn += _spawn(first, frames, at + off, vel, float(k.gravity), float(k.life), k.tint)
		if k.has("with"):
			drawn += burst(str(k.with), at) if drawn > 0 else 0
	if drawn > 0:
		bursts += 1
	return drawn


## A short red-or-other flash on a drawn thing (a site's bar): none with Reduce effects.
func flash(item: CanvasItem, colour := Color(1.6, 1.6, 1.2), secs := 0.25) -> void:
	if reduce or item == null or not is_instance_valid(item):
		return
	item.modulate = colour
	item.create_tween().tween_property(item, "modulate", Color.WHITE, secs)


## A brief brightening of an interface element (the prompt when its target changes, the coins when they change): none with
## Reduce effects.
func pulse(item: CanvasItem, colour := Color(1.35, 1.3, 1.1), secs := 0.3) -> void:
	flash(item, colour, secs)


## Particles alive now.
func live() -> int:
	var n := 0
	for i in _pool.size():
		if _life[i] > 0.0:
			n += 1
	return n


## Put every particle away (a new world).
func clear() -> void:
	for i in _pool.size():
		_life[i] = 0.0
		_pool[i].visible = false


func _spawn(t: Texture2D, frames: Array, at: Vector2, vel: Vector2, grav: float, life: float, tint: Color) -> int:
	var i := -1
	for j in _pool.size():
		if _life[j] <= 0.0:
			i = j
			break
	if i < 0:
		if _pool.size() >= CAP:
			return 0                      # bounded: a burst past the cap is cut short
		var s := Sprite2D.new()
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(s)
		_pool.append(s)
		_vel.append(Vector2.ZERO)
		_age.append(0.0)
		_life.append(0.0)
		_grav.append(0.0)
		_frames.append([])
		_alpha.append(1.0)
		i = _pool.size() - 1
	var s: Sprite2D = _pool[i]
	s.texture = t
	s.position = at
	s.modulate = tint
	s.visible = true
	_vel[i] = vel
	_age[i] = 0.0
	_life[i] = life
	_grav[i] = grav
	_frames[i] = frames
	_alpha[i] = tint.a
	return 1


func _process(delta: float) -> void:
	step(delta)


## Move the live particles on by `delta` seconds: they fly, fall, step through their frames and fade over their last third.
func step(delta: float) -> void:
	for i in _pool.size():
		if _life[i] <= 0.0:
			continue
		_age[i] += delta
		var s: Sprite2D = _pool[i]
		if _age[i] >= _life[i]:
			_life[i] = 0.0
			s.visible = false
			continue
		var v: Vector2 = _vel[i]
		v.y += _grav[i] * delta
		_vel[i] = v
		s.position += v * delta
		var f: float = _age[i] / _life[i]
		var fr: Array = _frames[i]
		if not fr.is_empty():
			s.texture = fr[mini(int(f * fr.size()), fr.size() - 1)]
		s.modulate.a = _alpha[i] * (1.0 if f < 0.66 else (1.0 - f) / 0.34)
