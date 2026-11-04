class_name Presence
extends RefCounted
## B25R1-019 (owner decisions B25R1-Q6, Q7): the one authority for what is LIVE (drawn, animated, interactive) and what is
## CALCULATED (a record the simulation carries on without drawing). Design: docs/design/PRESENCE_B25R1.md.
##
## The live range is each active player's visible view rect grown by a margin. main.gd reports the host's view (camera
## centre and size in tiles) whenever the zoom, window size or camera moves (set_view); a guest, or a headless run (the
## economy simulation, the tests), uses the player's position and DEFAULT_VIEW. Being live changes only what is drawn and
## animated: every villager's rules run on World's one fixed tick either way (World.TICK), so who is watching changes no
## decision, no transaction and no draw of the world's random numbers.
##
## Providers (the region worker's settlement people) keep their own records outside World.npcs and are made live through
## register(provider): Presence asks each provider for its candidates each update and calls materialise / fold with the same
## hysteresis as everything else (enter inside the rect grown by MARGIN_IN, leave only outside MARGIN_OUT).

signal entered(kind: String, id: int)
signal left(kind: String, id: int)

static func cfg() -> Dictionary:
	return GameData.b("presence")      # every tunable number of presence and crowds, in balance.json "presence" (EA-01: one place)


static var MARGIN_IN: float:
	get: return float(cfg().margin_in)
static var MARGIN_OUT: float:
	get: return float(cfg().margin_out)
static var DEFAULT_VIEW: Vector2:
	get: return Vector2(float(cfg().default_view[0]), float(cfg().default_view[1]))
const PACE := 1.3                 # tiles per game minute on the road: walk_tiles_per_second 2.6 / game_minutes_per_second 2
const REST_FROM := 20             # Journeys.REST_FROM: travellers stop for the night at 20:00
const REST_TO := 6                # and walk on at 06:00

var w                             # World (untyped: World preloads this class)
var views := {}                   # pid -> {size: Vector2 tiles, centre: Vector2 tiles or Vector2.INF (the player's position)}
var rects: Array = []             # Rect2 in tiles: the visible rects of the players in play (before the margins)
var version := 0                  # bumped whenever `rects` changes: cache what you derive from them against this
var providers: Array = []         # objects with presence_candidates(), materialise(id), fold(npc)
var listeners: Array = []         # Callables (presence) -> void, after each refresh
var _live_by_provider := {}       # provider index -> {id: NPC}
var _animal_live := {}            # animal id -> true while live (for the signals only)


func _init(world = null) -> void:
	w = world


# ---------------------------------------------------------------- the live range ---------------
## The host's (or a guest's) view: `size_tiles` the visible size in tiles (viewport size / zoom / 16), `centre` the camera's
## centre in tiles (Vector2.INF: follow the player). Called by main.gd on zoom, resize and camera moves.
func set_view(pid: int, size_tiles: Vector2, centre := Vector2.INF) -> void:
	views[pid] = {"size": size_tiles, "centre": centre}


## Recompute the rects from the players in play. World.update calls it at the start of every update.
func refresh() -> void:
	var out: Array = []
	if w != null:
		for pl in w.active_players():
			if not pl.alive:
				continue
			var v: Dictionary = views.get(pl.pid, {})
			var size: Vector2 = v.get("size", DEFAULT_VIEW)
			var c: Vector2 = v.get("centre", Vector2.INF)
			if c == Vector2.INF:
				c = pl.pos
			out.append(Rect2(c - size / 2.0, size))
	if out != rects:
		rects = out
		version += 1


## The live rects: each visible rect grown by MARGIN_IN.
func live_rects() -> Array:
	return rects.map(func(r: Rect2) -> Rect2: return r.grow(MARGIN_IN))


func in_live_range(pos: Vector2) -> bool:
	return _inside(pos, MARGIN_IN)


func cell_live(c: Vector2i) -> bool:
	return _inside(Vector2(c) + Vector2(0.5, 0.5), MARGIN_IN)


## True when `r` (tiles) touches any live rect: for chunks, water areas and settlements.
func rect_live(r: Rect2) -> bool:
	for v: Rect2 in rects:
		if v.grow(MARGIN_IN).intersects(r, true):
			return true
	return false


## The hysteresis rule: something already live stays live until it is past MARGIN_OUT.
func keeps_live(pos: Vector2, was_live: bool) -> bool:
	return _inside(pos, MARGIN_OUT if was_live else MARGIN_IN)


func _inside(pos: Vector2, margin: float) -> bool:
	for v: Rect2 in rects:
		var g := v.grow(margin)
		if pos.x >= g.position.x and pos.y >= g.position.y and pos.x < g.end.x and pos.y < g.end.y:
			return true
	return false


# ---------------------------------------------------------------- people and animals -------------
## Mark each villager and animal live or calculated (presentation only; no rule reads these flags), emit the transitions,
## then run the providers and listeners. World.update calls it once per update after refresh().
func classify() -> void:
	if w == null:
		return
	for n in w.npcs:
		var live: bool = n.alive and n.depth == int(w.player_level) and keeps_live(n.pos, n.live)    # below: the host's own level
		if live != n.live:
			n.live = live
			(entered if live else left).emit("npc", n.id)
	if w.fauna != null:
		for a in w.fauna.animals:
			var was := _animal_live.has(a.id)
			var live: bool = a.alive and keeps_live(a.pos, was)
			if live != was:
				if live:
					_animal_live[a.id] = true
				else:
					_animal_live.erase(a.id)
				(entered if live else left).emit("animal", a.id)
	_run_providers()
	for cb: Callable in listeners:
		if cb.is_valid():
			cb.call(self)


func animal_live(id: int) -> bool:
	return _animal_live.has(id)


func listen(cb: Callable) -> void:
	listeners.append(cb)


## A provider keeps people outside World.npcs (the settlements' residents). It implements:
##   presence_candidates() -> Array of {id: int, pos: Vector2}: where each of its people is at this minute (Presence.road_tiles)
##   materialise(id) -> NPC: the person as a live NPC, already in World.npcs with the same identity id (one record: the
##       provider marks its own record as live while the NPC exists)
##   fold(npc) -> void: the NPC's changes back into the provider's record and the NPC out of World.npcs, in that one call
func register(provider: Object) -> void:
	if provider not in providers:
		providers.append(provider)


func unregister(provider: Object) -> void:
	var i := providers.find(provider)
	if i >= 0:
		providers.remove_at(i)
		_live_by_provider.erase(i)


func _run_providers() -> void:
	for i in providers.size():
		var p: Object = providers[i]
		var live: Dictionary = _live_by_provider.get(i, {})
		for id in live.keys():                          # leaving range: fold back (or the NPC is gone: died, left)
			var n = live[id]
			if n == null or not w.by_id.has(n.id):
				live.erase(id)
				continue
			if not keeps_live(n.pos, true):
				p.fold(n)
				live.erase(id)
				left.emit("npc", n.id)
		for c: Dictionary in p.presence_candidates():
			var id := int(c.id)
			if live.has(id) or not keeps_live(c.pos as Vector2, false):
				continue
			var n = p.materialise(id)
			if n != null:
				live[id] = n
				n.live = true
				entered.emit("npc", n.id)
		_live_by_provider[i] = live


# ---------------------------------------------------------------- crowds (B25R1-020) ---------------
## The owner's one exception to observation neutrality (docs/directives/2026-11-03_b25r1_anticipatory_crowd_management.md;
## DECISIONS 2026-11-03): when more ordinary people stand in and round a player's view than CROWD_TARGET, an ELIGIBLE one
## who is only passing the time (a "loose" step: resting, taking the air, playing, keeping company; NPCBrain marks them) ends
## that pastime now, and the brain makes the decision it would have made when it ended. Nothing else changes: the same
## decide(), the same paths, the same coins and goods. Protected people are never touched (crowd_protected). Runs at the
## start of each World tick, before the villagers, from the previous tick's positions: tick-based, not frame-based.
static var CROWD_TARGET: int:
	get: return int(cfg().crowd_target)
static var DECIDE_MARGIN: float:
	get: return float(cfg().decide_margin)
static var CROWD_MIN_STAY: float:
	get: return float(cfg().crowd_min_stay)
static var CROWD_COOLDOWN: float:
	get: return float(cfg().crowd_cooldown)
static var LOCK_RADIUS: float:
	get: return float(cfg().lock_radius)
static var LOCK_MINUTES: float:
	get: return float(cfg().lock_minutes)

var crowd_enabled := true         # the economy simulation's --no-crowd turns it off, to measure the exception on its own
var crowd_after := {}             # npc id -> game minute before which they are not hurried again; not saved (presentation-led)
var locks := {}                   # npc id -> game minute their availability lock ends (lock()); not saved
var crowd_stats := {"ticks_over": 0, "brought_forward": 0, "protected_over_target": 0, "max_round_view": 0}


## An availability lock: the player is talking to, trading with or heading for this person (main.gd calls it).
func lock(id: int, minutes: float, for_minutes := -1.0) -> void:
	locks[id] = maxf(float(locks.get(id, 0.0)), minutes + (LOCK_MINUTES if for_minutes < 0.0 else for_minutes))


func decide_rects() -> Array:
	return rects.map(func(r: Rect2) -> Rect2: return r.grow(DECIDE_MARGIN))


func _in_decide(pos: Vector2) -> bool:
	for r: Rect2 in rects:
		var g := r.grow(DECIDE_MARGIN)
		if pos.x >= g.position.x and pos.y >= g.position.y and pos.x < g.end.x and pos.y < g.end.y:
			return true
	return false


## Never hurried for a crowd: traders the player can use, quest givers and anyone with a marker over them, people fighting,
## pursuing or on a journey, at a feast, below the surface, near a player or locked, and anyone whose step is not a pastime.
func crowd_protected(n) -> bool:
	if n.target != -1 or not n.pursuit.is_empty() or not n.journey.is_empty() or n.depth != 0 or not n.report.is_empty():
		return true
	if w.brain != null and not _loose_step(n) and w.brain.buy_role(n) != "":
		return true                                              # at their trade, selling to the player (a merchant, a keeper, a crafter)
	if w.quests != null and w.quests.marker(n) != "":
		return true                                              # a quest or an icon over them
	if float(locks.get(n.id, -1.0)) > w.minutes:
		return true
	for pl in w.active_players():
		if pl.alive and pl.pos.distance_to(n.pos) <= LOCK_RADIUS:
			return true
	return false


func _loose_step(n) -> bool:
	if n.plan.is_empty():
		return false
	var s: Dictionary = n.plan[0]
	return str(s.k) == "work" and bool(s.get("loose", false)) and str(s.get("act", "")) == ""


## One tick's crowd check (World._tick). Returns how many pastimes it ended.
func crowd_step() -> int:
	# only for a screen: with no view ever reported (the economy simulation, headless tests) there is no crowd in view to ease,
	# so the inert stand-in player does not reshape the village's day (housing_test, seed 3: 1739 pastimes ended in 18 days)
	if not crowd_enabled or views.is_empty() or rects.is_empty() or w.player_level != 0:
		return 0
	var ordinary: Array = []
	var protected := 0
	for n in w.npcs:
		if not n.alive or w.asleep(n) or not _in_decide(n.pos) or w.place_of(n.pos) != "":
			continue                                             # indoors (under a roof) nobody adds to the crowd in view
		if crowd_protected(n):
			protected += 1
		else:
			ordinary.append(n)
	crowd_stats.max_round_view = maxi(int(crowd_stats.max_round_view), ordinary.size() + protected)
	if protected > CROWD_TARGET:
		crowd_stats.protected_over_target += 1                   # they stay: the target is soft
	var over := ordinary.size() - CROWD_TARGET
	if over <= 0:
		return 0
	crowd_stats.ticks_over += 1
	# the first to go are those farthest from the view's centre (in the buffer, unseen), then by id: a fixed order
	var c: Vector2 = (rects[0] as Rect2).get_center()
	ordinary.sort_custom(func(a, b) -> bool:
		var da: float = a.pos.distance_squared_to(c)
		var db: float = b.pos.distance_squared_to(c)
		return da > db if da != db else a.id < b.id)
	var done := 0
	for n in ordinary:
		if done >= over:
			break
		if not _loose_step(n) or float(crowd_after.get(n.id, -1.0)) > w.minutes:
			continue
		var s: Dictionary = n.plan[0]
		if float(s.min) - n.work_left < CROWD_MIN_STAY:
			continue
		n.work_left = 0.0                                        # the pastime ends now; the brain decides what comes next
		crowd_after[n.id] = w.minutes + CROWD_COOLDOWN
		done += 1
	crowd_stats.brought_forward += done
	if done > 0:
		w.stat("crowd_brought_forward", float(done))
	return done


# ---------------------------------------------------------------- the road's one pace ---------------
## Tiles walked on the road between game minute `depart` and `m` at `pace` tiles a game minute, the night stops
## (REST_FROM to REST_TO) excluded: one rule for the village's travellers (Journeys) and the settlements' trips, so two
## travellers on the same road move alike. A pure function: no state, no random numbers.
static func road_tiles(depart: float, m: float, pace := PACE) -> float:
	if m <= depart:
		return 0.0
	return walking_minutes(depart, m) * pace


## Game minutes between `depart` and `m` that fall in the walking hours (REST_TO to REST_FROM).
static func walking_minutes(depart: float, m: float) -> float:
	if m <= depart:
		return 0.0
	var day := 1440.0
	var from := float(REST_TO) * 60.0
	var to := float(REST_FROM) * 60.0
	var per_day := to - from
	var d0 := floorf(depart / day)
	var d1 := floorf(m / day)
	var t0 := clampf(depart - d0 * day, from, to)
	var t1 := clampf(m - d1 * day, from, to)
	if d0 == d1:
		return maxf(0.0, t1 - t0)
	return (to - t0) + (d1 - d0 - 1.0) * per_day + (t1 - from)


## The game minute a walk of `tiles` started at `depart` arrives (the inverse of road_tiles).
static func arrival(depart: float, tiles: float, pace := PACE) -> float:
	var need := tiles / maxf(0.0001, pace)
	var day := 1440.0
	var from := float(REST_TO) * 60.0
	var to := float(REST_FROM) * 60.0
	var t := depart
	var tod := t - floorf(t / day) * day
	if tod < from:
		t += from - tod
	elif tod >= to:
		t += day - tod + from
	while need > 0.0:
		tod = t - floorf(t / day) * day
		var left := to - tod
		if need <= left:
			return t + need
		need -= left
		t += left + (day - to) + from
	return t


## The point `tiles` along the polyline `path` (cell coordinates; feet at the cells' centres), and the direction of travel there.
static func along(path: PackedVector2Array, tiles: float) -> Array:
	if path.is_empty():
		return [Vector2.ZERO, Vector2.DOWN]
	var at := path[0] + Vector2(0.5, 0.5)
	var left := maxf(0.0, tiles)
	for i in range(1, path.size()):
		var nxt := path[i] + Vector2(0.5, 0.5)
		var l := at.distance_to(nxt)
		if l >= left and l > 0.0:
			return [at + (nxt - at) / l * left, nxt - at]
		left -= l
		at = nxt
	var dir := Vector2.DOWN if path.size() < 2 else path[path.size() - 1] - path[path.size() - 2]
	return [at, dir]
