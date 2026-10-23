class_name Countryside
extends RefCounted
## WORLD-LIFE-01: ambient life in the overworld, outside the village: wild animals roaming the country and travellers
## (pedlars, pilgrims, wayfarers, and the merchant caravan's wagon on its visit days) walking the trails between the
## road network and the village's gates.
##
## It is a pure function of the world seed and the game clock (CLAUDE.md section 6): the same seed and minute give the
## same animals and walkers on every machine, with no random generator, no wall-clock time and nothing saved. The
## memoised legs and chunk lists below only save work; a fresh instance returns the same answers. It is ambient only:
## nothing here is in Fauna, the population, a ledger, a coin or an item, so the village economy and its tests
## are untouched (an animal here cannot be hunted, a traveller cannot be talked to or robbed). Numbers: balance.json
## "countryside". The view (Main._sync_countryside) draws what `animals_near` and `travellers_near` return, culled to
## the camera. Other towns stay off the map.

const ANIMAL_SALT := 600
const TRAVEL_SALT := 800
const FAR_BORN := -1.0e6                # game minutes: an adult, for the sprite

var o: Overworld
var _chunks := {}                       # Vector2i -> Array of {key, species, sex, skin, home}
var _legs := {}                         # animal key -> {n, to} the memoised target of its current leg
var _animals := {}                      # animal key -> Animal (drawn through AnimalSprite)
var _trails: Array = []


func _init(overworld: Overworld) -> void:
	o = overworld
	_trails = o.gate_trails()


static func cfg() -> Dictionary:
	return GameData.b("countryside")


# ---------------------------------------------------------------- animals --------------------
## The wild animals of overworld chunk `cc`: {key, species, sex, skin, home}. Pure in (seed, chunk).
func chunk_animals(cc: Vector2i) -> Array:
	if _chunks.has(cc):
		return _chunks[cc]
	if _chunks.size() > 128:
		_chunks.clear()
		_legs.clear()
		_animals.clear()
	var out := []
	var a: Dictionary = cfg().animals
	if not o.chunk_in_village(cc):
		var ch := o.get_chunk(cc)
		var forest: bool = ch.trees.size() / 3 >= int(a.forest_trees)
		var n := Overworld.hash32(o.seed, cc.x, cc.y, ANIMAL_SALT) % ((int(a.forest_max) if forest else int(a.open_max)) + 1)
		var kinds: Array = a.forest if forest else a.open
		for i in n:
			var h := Overworld.hash32(o.seed, cc.x, cc.y, ANIMAL_SALT + 1 + i)
			var home := _home(cc, h)
			if home.x == -(1 << 30):
				continue
			var species: String = kinds[(h >> 8) % kinds.size()]
			var sp: Dictionary = GameData.b("animals")[species]
			var sex := "m" if (h >> 16) % 2 == 0 else "f"
			var skins: Array = sp.skins_m if (sex == "m" and sp.has("skins_m")) else sp.skins
			out.append({"key": Overworld.hash32(o.seed, cc.x, cc.y, ANIMAL_SALT + 20 + i) & 0x3FFFFFFF, "species": species, "sex": sex,
					"skin": skins[(h >> 20) % skins.size()], "home": home})
	_chunks[cc] = out
	return out


## A free home cell in the chunk, tried from the hash `h`; (-2^30, 0) when none is found in a few tries.
func _home(cc: Vector2i, h: int) -> Vector2i:
	for t in 8:
		var hh := Overworld.hash32(h, t, 17)
		var c := Vector2i(cc.x * Overworld.CHUNK + hh % Overworld.CHUNK, cc.y * Overworld.CHUNK + (hh >> 8) % Overworld.CHUNK)
		if _open(c) and not o.is_road(c):
			return c
	return Vector2i(-(1 << 30), 0)


## Whether an animal may stand on `c`: open ground, outside the village and its margin, not on a mountain top.
func _open(c: Vector2i) -> bool:
	return not o.village.grow(int(cfg().animals.village_margin)).has_point(c) and not o.is_solid(c) and not o.is_top(c)


func _target(e: Dictionary, n: int) -> Vector2i:
	var memo: Dictionary = _legs.get(e.key, {})
	if memo.get("n", -1) == n:
		return memo.to
	var r := int(cfg().animals.roam)
	var home: Vector2i = e.home
	var h := Overworld.hash32(int(e.key), n, ANIMAL_SALT + 40)
	var to := home + Vector2i(h % (2 * r + 1) - r, (h >> 10) % (2 * r + 1) - r)
	if not _line_open(home, to):
		to = home
	_legs[e.key] = {"n": n, "to": to}
	return to


func _line_open(a: Vector2i, b: Vector2i) -> bool:
	var steps := maxi(absi(b.x - a.x), absi(b.y - a.y)) * 4
	for i in range(1, steps + 1):
		var c := Vector2i((Vector2(a) + Vector2(0.5, 0.5) + Vector2(b - a) * (float(i) / float(maxi(1, steps)))).floor())
		if not _open(c):
			return false
	return true


## Where one animal is at game minute `now`, and whether it is walking: even legs go from home out to a target, odd
## legs back from the previous leg's target to home; each leg walks, then rests (grazes) for the rest of the leg.
func animal_state(e: Dictionary, now: float) -> Dictionary:
	var a: Dictionary = cfg().animals
	var leg := float(a.leg_minutes)
	var n := int(floor(now / leg))
	var f := (now - float(n) * leg)
	var home: Vector2 = Vector2(e.home) + Vector2(0.5, 0.5)
	var even := n % 2 == 0
	var tgt := Vector2(_target(e, n if even else n - 1)) + Vector2(0.5, 0.5)
	var from := home if even else tgt
	var to := tgt if even else home
	var dist := from.distance_to(to)
	var spd: float = float(GameData.b("walk_tiles_per_second")) * float(GameData.b("animals")[e.species].speed) * 0.4 \
			/ float(GameData.b("game_minutes_per_second"))          # tiles per game minute (a stroll)
	var walk := minf(dist / spd, leg * (1.0 - float(a.rest_share))) if dist > 0.01 else 0.0
	var t := 1.0 if walk <= 0.0 else minf(1.0, f / walk)
	var dir := (to - from).normalized() if dist > 0.01 else Vector2.DOWN
	return {"pos": from.lerp(to, t), "moving": walk > 0.0 and f < walk, "facing": dir}


## The ambient animals within `radius` tiles of `center` at game minute `now`, as Animal objects (key in `id`) ready for
## AnimalSprite. The same Animal object is returned for the same animal while it stays cached.
func animals_near(center: Vector2, radius: float, now: float) -> Array:
	var out := []
	var c0 := Overworld.chunk_of(Vector2i(floori(center.x - radius), floori(center.y - radius)))
	var c1 := Overworld.chunk_of(Vector2i(floori(center.x + radius), floori(center.y + radius)))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			for e: Dictionary in chunk_animals(Vector2i(cx, cy)):
				var st := animal_state(e, now)
				if (st.pos as Vector2).distance_to(center) > radius:
					continue
				var an: Animal = _animals.get(e.key)
				if an == null:
					an = Animal.new()
					an.id = int(e.key)
					an.species = e.species
					an.skin = e.skin
					an.sex = e.sex
					an.born = FAR_BORN
					_animals[e.key] = an
				an.pos = st.pos
				an.facing = st.facing
				an.moving = st.moving
				out.append(an)
	return out


# ---------------------------------------------------------------- travellers -----------------
func trail_count() -> int:
	return _trails.size()


func _speed(share: float) -> float:
	return float(GameData.b("walk_tiles_per_second")) * share / float(GameData.b("game_minutes_per_second"))       # tiles per game minute


## A walker's place on trail `t` after `tau` game minutes of a journey that starts at the road node end (index 0) and
## goes in to the gate (the last cell), waits `pause`, and goes back out: {pos, facing, moving} or {} once it has gone.
func _on_trail(t: int, tau: float, v: float, pause: float) -> Dictionary:
	var cells: Array = _trails[t].cells
	var last := cells.size() - 1
	var walk := float(last) / v
	if tau < 0.0 or tau > 2.0 * walk + pause:
		return {}
	var idx := 0.0
	var dir := 1
	var moving := true
	if tau <= walk:
		idx = tau * v
	elif tau <= walk + pause:
		idx = float(last)
		moving = false
	else:
		idx = float(last) - (tau - walk - pause) * v
		dir = -1
	idx = clampf(idx, 0.0, float(last))
	var i := mini(int(idx), last - 1)
	var a: Vector2 = Vector2(cells[i]) + Vector2(0.5, 0.5)
	var b: Vector2 = Vector2(cells[i + 1]) + Vector2(0.5, 0.5)
	var step := b - a
	return {"pos": a.lerp(b, idx - float(i)), "facing": step * float(dir) if step != Vector2.ZERO else Vector2.DOWN, "moving": moving}


## What a traveller of `key` is: "pedlar" (carries a pack), "pilgrim" or "wayfarer", by the weights in balance.json.
func kind_of(h: int) -> String:
	var kinds: Dictionary = cfg().travellers.kinds
	var total := 0
	for k in kinds:
		total += int(kinds[k])
	var r := h % total
	for k in kinds:
		if r < int(kinds[k]):
			return k
		r -= int(kinds[k])
	return "wayfarer"


## The walkers and wagons within `radius` tiles of `center` at game minute `now`: dictionaries {key, kind, pos, facing,
## moving, sheet} (kind "wagon" has no sheet). Pure in (seed, now).
func travellers_near(center: Vector2, radius: float, now: float) -> Array:
	var out := []
	var tc: Dictionary = cfg().travellers
	var slot := float(tc.slot_minutes)
	var v := _speed(float(tc.speed))
	var pause := float(tc.pause_minutes)
	for t in _trails.size():
		if (_trails[t].cells as Array).size() < int(tc.min_trail):
			continue
		var total := 2.0 * float((_trails[t].cells as Array).size() - 1) / v + pause
		var s1 := int(floor(now / slot))
		var s0 := s1 - int(ceil(total / slot))
		for s in range(s0, s1 + 1):
			var h := Overworld.hash32(o.seed, t, s, TRAVEL_SALT)
			if float(h % 1000) >= float(tc.chance) * 1000.0:
				continue
			var start := float(s) * slot + float((h >> 10) % int(slot))
			var hour := fposmod(start, 1440.0) / 60.0
			if hour < float(tc.from_hour) or hour >= float(tc.to_hour):
				continue
			var st := _on_trail(t, now - start, v, pause)
			if st.is_empty() or (st.pos as Vector2).distance_to(center) > radius:
				continue
			var h2 := Overworld.hash32(h, 7, 11)
			var kind := kind_of(h2 >> 8)
			out.append({"key": Overworld.hash32(o.seed, t, s, TRAVEL_SALT + 1) & 0x3FFFFFFF, "kind": kind, "pos": st.pos,
					"facing": st.facing, "moving": st.moving, "sheet": h2 % 25})
	_caravan(out, center, radius, now)
	return out


## The merchant caravan on its way to its stop and away again (farming.caravan_horse: the visit days and hours): on a visit
## day the wagon and its driver come in along the trail of the gate nearest the stop, arriving at the gate as the visit
## begins (they are then at the stop, drawn by the village), and leave along it when the visit ends.
func _caravan(out: Array, center: Vector2, radius: float, now: float) -> void:
	if _trails.is_empty():
		return
	var ch: Dictionary = GameData.b("farming").caravan_horse
	var every := int(GameData.b("caravan_every_days"))
	var stop := Vector2(float(ch.stop[0]), float(ch.stop[1]))
	var gate := 0
	var best := INF
	for g in o.gates.size():
		var d := Vector2(o.gates[g].out).distance_to(stop)
		if d < best:
			best = d
			gate = g
	var mine := []
	for t in _trails.size():
		if int(_trails[t].gate) == gate and (_trails[t].cells as Array).size() >= int(cfg().travellers.min_trail):
			mine.append(t)
	if mine.is_empty():
		return
	var v := _speed(float(cfg().travellers.caravan_speed))
	var day := int(floor(now / 1440.0))
	for d in [day - 1, day]:
		if d < 0 or d % every != 1:
			continue
		var t: int = mine[Overworld.hash32(o.seed, d, 3, TRAVEL_SALT + 2) % mine.size()]
		var walk := float((_trails[t].cells as Array).size() - 1) / v
		var arrive := float(d) * 1440.0 + float(ch.from_hour) * 60.0
		var leave := arrive + float(ch.hours) * 60.0
		var pos := {}
		if now >= arrive - walk and now < arrive:
			pos = _on_trail(t, now - (arrive - walk), v, 0.0)
		elif now >= leave and now < leave + walk:
			pos = _on_trail(t, walk + (now - leave), v, 0.0)       # the way out: back along the same cells
		if pos.is_empty() or (pos.pos as Vector2).distance_to(center) > radius:
			continue
		var f: Vector2 = pos.facing
		var base := Overworld.hash32(o.seed, d, t, TRAVEL_SALT + 3) & 0x3FFFFFFF
		out.append({"key": base, "kind": "wagon", "pos": pos.pos, "facing": f, "moving": true, "sheet": -1})
		out.append({"key": base + 1, "kind": "driver", "pos": (pos.pos as Vector2) + f.normalized() * 1.4, "facing": f, "moving": true,
				"sheet": Overworld.hash32(o.seed, d, 5, TRAVEL_SALT + 4) % 25})
