class_name Combat
extends RefCounted
## The player's sword swing (B14 combat-quality issue CQ-01: presses dropped during the cooldown, hits that
## needed the sprites to overlap). A swing has three phases, timed from balance "player_combat":
##  - windup: from the press to the blow, `windup` seconds (the sword sheet's first two frames, 0.16 s;
##    the slash is drawn on the third frame, when the blow lands);
##  - the blow: one target, chosen at that moment, takes the damage once;
##  - recovery: the rest of the swing time (0.6 s times the Combat tier's attack_time).
## A press while swinging is kept when the swing has `buffer` seconds or less to run, and starts the next
## swing the moment this one ends; only one press is kept (a bounded buffer, never a repeating attack).
## The target is the nearest person or animal within `reach` tiles in front (inside the `arc`), or within
## `close` tiles in any direction, with a clear line: no building wall and no solid cell between.
## Foes (bandits, anyone fighting the player) are chosen before villagers and livestock, so a blow at a
## bandit does not land on a bystander. Counters (presses, accepted, swings, hits) are kept for tests.

var phase := ""                # "", "windup", "recovery"
var t := 0.0                   # seconds left in the phase
var queued := false            # one buffered press
var only: Object = null        # this swing may hit nobody else (a marked target)
var queued_only: Object = null
var presses := 0
var accepted := 0
var swings := 0
var hits := 0


static func cfg() -> Dictionary:
	return GameData.b("player_combat")


## A press of Attack. "start" (a swing begins), "queued" (it will follow the current swing) or "ignored".
func press(swing_time: float, who: Object = null) -> String:
	presses += 1
	if phase == "":
		accepted += 1
		_start(swing_time, who)
		return "start"
	if not queued and remaining(swing_time) <= float(cfg().buffer):
		queued = true
		queued_only = who
		accepted += 1
		return "queued"
	return "ignored"


func _start(swing_time: float, who: Object) -> void:
	phase = "windup"
	t = minf(float(cfg().windup), swing_time)
	only = who
	swings += 1


## Seconds until a new swing could start.
func remaining(swing_time: float) -> float:
	if phase == "windup":
		return t + maxf(0.0, swing_time - float(cfg().windup))
	return t if phase == "recovery" else 0.0


## Advance by `dt`. Returns "blow" when the blow lands this step, "start" when a queued swing begins, else "".
func step(dt: float, swing_time: float) -> String:
	if phase == "":
		return ""
	t -= dt
	if t > 0.0:
		return ""
	if phase == "windup":
		phase = "recovery"
		t += maxf(0.0, swing_time - float(cfg().windup))
		return "blow"
	phase = ""
	if queued:
		queued = false
		_start(swing_time, queued_only)
		queued_only = null
		return "start"
	return ""


func busy() -> bool:
	return phase != ""


func cancel() -> void:
	phase = ""
	t = 0.0
	queued = false
	only = null
	queued_only = null


## The person or animal a blow from `from` facing `facing` lands on, or null. `only` restricts it to one.
static func target(w: World, from: Vector2, facing: Vector2, who: Object = null) -> Object:
	var c := cfg()
	var reach := float(c.reach)
	var best: Object = null
	var best_score := INF
	for n: NPC in w.present(from, reach):
		if n.alive and (who == null or who == n) and in_reach(w, from, facing, n.pos):
			var s := from.distance_to(n.pos) + (0.0 if foe(n) else 100.0)
			if s < best_score:
				best_score = s
				best = n
	for a: Animal in w.fauna.near(from, reach):
		if a.alive and (who == null or who == a) and in_reach(w, from, facing, a.pos):
			var s := from.distance_to(a.pos) + (50.0 if a.wild() else 100.0)
			if s < best_score:
				best_score = s
				best = a
	return best


## A bandit, or anyone fighting the player.
static func foe(n: NPC) -> bool:
	return n.role == "bandit" or Life.is_player_id(n.target)


## Whether a blow from `from` facing `facing` reaches a body standing at `to`.
static func in_reach(w: World, from: Vector2, facing: Vector2, to: Vector2) -> bool:
	var c := cfg()
	var d := to - from
	var dist := d.length()
	if dist > float(c.reach):
		return false
	if dist > float(c.close) and facing.length() > 0.0 and d.normalized().dot(facing.normalized()) < float(c.arc_cos):
		return false
	return clear_line(w, from, to)


## No building wall (World.reaches) and no solid map cell between two points; their own cells are not counted.
static func clear_line(w: World, from: Vector2, to: Vector2) -> bool:
	if not w.reaches(from, to):
		return false
	var a := Vector2i(floori(from.x), floori(from.y))
	var b := Vector2i(floori(to.x), floori(to.y))
	var steps := maxi(1, ceili(from.distance_to(to) / 0.2))
	for k in range(1, steps):
		var s := from.lerp(to, float(k) / float(steps))
		var cell := Vector2i(floori(s.x), floori(s.y))
		if cell != a and cell != b and w.map.is_solid_world(cell):
			return false
	return true
