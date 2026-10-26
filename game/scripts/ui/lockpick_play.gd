class_name LockpickPlay
extends RefCounted
## GP-LOCKPICK (owner directive 2026-10-24, docs/directives/2026-10-24_gameplay_controls_interaction_directive.md section 2;
## amendment 2026-10-26 section 13): the rules of the pin-tumbler minigame, apart from its drawing and input
## (LockpickWindow), so a test can play it frame by frame. Deterministic: the same lock, difficulty and presses give the
## same game; nothing is drawn at random. What happens is all on screen, in time to react: a pin is lifted by the pick
## and rises to the setting line (RISING), wobbles there (WOBBLE: the catch window, its wobble faster as the window runs
## out), and either is caught by its own input (SET) or falls back on its spring (FALLING, then DOWN, and it is lifted
## again later). A set pin may slip and wobble again (a relapse) and must be caught again. The lock opens when every pin
## is set, no relapse is due and none is unstable; it fails when more pins have fallen than the pick can bear (`falls`).
##
## Difficulty (from() below) comes from the existing rules only (Chests): the lock's level sets the number of tumblers
## (4, 5 or 6) and how many pins may be unstable at once; the player's chance against it (Chests.pick_chance: Stealth
## against the lock's level) sets how slowly the pins rise and wobble and how long the catch window is. Touch targets are
## never made smaller: the window gives every tumbler a column of the same size.
##
## Easy (a level 1 lock): 4 tumblers, one unstable at a time, 3 relapses: 7 catches open it (the owner's six to eight).

enum { DOWN, RISING, WOBBLE, SET, FALLING }

const FALL_TIME := 0.35         # seconds a missed pin takes to drop back
const EARLY := 0.25             # a press in the last quarter of a pin's rise catches it (generous, never punishing)
const OPEN_HOLD := 0.5          # the last pin set, the plug turns after this long

var n := 4                      # tumblers
var rise := 0.8                 # seconds a lifted pin takes to reach the line
var window := 1.6               # seconds a pin wobbles at the line before it falls
var gap := 0.9                  # seconds between one pin made unstable and the next
var concurrent := 1             # pins unstable at once at most
var relapses := 3               # set pins that slip again before the lock can open
var falls := 4                  # pins that may fall before the attempt fails

var state: Array = []           # per pin: DOWN, RISING, WOBBLE, SET or FALLING
var t_in: Array = []            # per pin: seconds in its state
var order: Array = []           # the lock's pattern: pin indices in the order they are lifted
var queue: Array = []           # pins waiting to be lifted (DOWN), in order
var relapse_left := 0
var since := 99.0               # seconds since a pin was last made unstable
var t := 0.0
var caught := 0                 # successful catches
var fallen := 0                 # pins that fell
var mistaps := 0                # presses on a pin with nothing to catch (feedback only; never punished)
var result := ""                # "", "open" or "fail": set once, never changed after
var _open_t := -1.0
var events: Array = []          # what happened since the view last read it: [kind, pin] (lift, wobble, catch, fall, miss, relapse, open, fail)


## A game for a lock of `level` (1..3) with the player's chance `chance` (0..1, Chests.pick_chance) and the lock's
## own pattern from `seed` (its unit id's hash).
static func from(level: int, chance: float, seed: int) -> LockpickPlay:
	var g := LockpickPlay.new()
	var lv := clampi(level, 1, 3)
	var e := clampf((chance - 0.1) / 0.8, 0.0, 1.0)          # ease: 0 the hardest the rules allow, 1 the easiest
	g.n = 3 + lv
	g.concurrent = 1 if lv == 1 else 2
	g.relapses = 3 if lv == 1 else lv + 2
	g.falls = 4 if lv == 1 else 3
	g.rise = lerpf(0.5, 0.9, e)
	g.window = lerpf(0.8, 1.8, e)
	g.gap = lerpf(0.55, 1.0, e)
	g.setup(seed)
	return g


func setup(seed: int) -> void:
	state.clear()
	t_in.clear()
	for i in n:
		state.append(DOWN)
		t_in.append(0.0)
	order = range(n)
	for i in range(n - 1, 0, -1):                           # the lock's own pattern: a shuffle by its seed, fixed
		var j := Overworld.hash32(seed, i, 41, n) % (i + 1)
		var tmp = order[i]
		order[i] = order[j]
		order[j] = tmp
	queue = order.duplicate()
	relapse_left = relapses
	since = gap                                             # the first pin is lifted at once


func unstable() -> int:
	var k := 0
	for s in state:
		if s == RISING or s == WOBBLE:
			k += 1
	return k


## How far pin `i` stands (0 down on its spring, 1 at the setting line) and how much it wobbles (0..1), for drawing.
func height(i: int) -> float:
	match state[i]:
		RISING:
			return clampf(t_in[i] / rise, 0.0, 1.0)
		WOBBLE, SET:
			return 1.0
		FALLING:
			return clampf(1.0 - t_in[i] / FALL_TIME, 0.0, 1.0)
	return 0.0


func wobble(i: int) -> float:
	return clampf(t_in[i] / window, 0.0, 1.0) if state[i] == WOBBLE else 0.0


## Advance `dt` seconds.
func step(dt: float) -> void:
	if result != "":
		return
	t += dt
	since += dt
	for i in n:
		t_in[i] += dt
		match state[i]:
			RISING:
				if t_in[i] >= rise:
					_to(i, WOBBLE)
					events.append(["wobble", i])
			WOBBLE:
				if t_in[i] >= window:
					_to(i, FALLING)
					fallen += 1
					events.append(["fall", i])
					if fallen > falls:
						result = "fail"
						events.append(["fail", -1])
						return
			FALLING:
				if t_in[i] >= FALL_TIME:
					_to(i, DOWN)
					queue.append(i)
	if unstable() < concurrent and since >= gap:
		var next := _next()
		if next >= 0:
			since = 0.0
	if _open_t < 0.0 and queue.is_empty() and relapse_left <= 0 and state.all(func(s): return s == SET):
		_open_t = t
	if _open_t >= 0.0 and t - _open_t >= OPEN_HOLD:
		result = "open"
		events.append(["open", -1])


func _next() -> int:
	if not queue.is_empty():
		var i: int = queue.pop_front()
		_to(i, RISING)
		events.append(["lift", i])
		return i
	if relapse_left > 0:
		for k in n:                                          # the next set pin in the lock's pattern after the last lifted
			var i: int = order[(k + relapses - relapse_left) % n]
			if state[i] == SET:
				relapse_left -= 1
				_to(i, WOBBLE)
				t_in[i] = 0.0
				events.append(["relapse", i])
				return i
	return -1


func _to(i: int, s: int) -> void:
	state[i] = s
	t_in[i] = 0.0


## The player pressed pin `i`'s input. Only that pin is touched. True when it was caught.
func press(i: int) -> bool:
	if result != "" or i < 0 or i >= n:
		return false
	if state[i] == WOBBLE or (state[i] == RISING and t_in[i] >= rise * (1.0 - EARLY)):
		_to(i, SET)
		caught += 1
		_open_t = -1.0
		events.append(["catch", i])
		return true
	mistaps += 1
	events.append(["miss", i])
	return false


func take_events() -> Array:
	var e := events
	events = []
	return e
