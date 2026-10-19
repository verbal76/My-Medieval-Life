class_name Refuges
extends RefCounted
## WR-01 (owner directive 2026-10-19, docs/directives/2026-10-19_memory_refuges_politics.md Part II; World Design
## Rule 018): protected wildlife breeding refuges, their offspring cohorts and the young animals' dispersal.
##
## Every wood a wild species may live in holds one refuge of that species (a wolf den, a bear's cave, a rabbit
## burrow, a boar's concealed shelter, the deer's sheltered habitat, a nesting area for birds, a fox's earth). A
## refuge is a count, not animals: its breeding `stock` is never in Fauna.animals, so nothing can see, strike, hunt,
## loot or eat it, and no population update ever lowers it. It is a recovery source, not a supply:
##  - at dawn, a refuge whose reproductive interval has passed may produce one cohort of young (the species'
##    litter), only in its breeding seasons (Life.season), only while the woods it can send young to are under
##    `release_below` of the species' woods_cap (counting young already on their way), and only where they can
##    feed: grazers while the wood's grass is not overgrazed (Fauna.graze_capacity), hunters while the wood holds
##    `wildlife.prey_per_predator` spare prey for each of their kind and one more; otherwise it waits (the timer is
##    not reset);
##  - the cohort stays in the refuge as newborns until `juvenile_days` old, then leaves at dawn as juveniles into
##    the ordinary simulation (Fauna.animals: hunger, predators, hunters, breeding when grown). If there is no room
##    by the time they would be grown, they stay hidden (counted refuge_held_<kind>) and never enter the woods;
##  - each young picks where to settle: the wood with the lowest share of its cap (another wood only if its own is
##    fuller by `cross_wood_penalty`), then, in that wood, a point `disperse` tiles from where it enters, chosen
##    among sampled cells as the one farthest from others of its kind and from its littermates' chosen points
##    (`spacing`), so a litter spreads out in different directions. It walks there (off-screen too, at
##    `disperse_speed` of its speed) and settles; young bound for another wood travel unseen and may be lost on
##    the way (`transit_loss`). Settled, they are ordinary animals.
## Numbers: balance.json "refuges" (agent proposal, provisional). Saved in the fauna block ("refuges"): an older
## save gains its refuges once, on loading.

var fauna
var w
var list: Array = []        # {id, species, area, site, x, y, stock, next_birth, cohort: {n, born} or {}}, sorted by id
var migrants: Array = []    # young travelling unseen to another wood: {species, sex, born, from, to, x, y, arrive}


func _init(f) -> void:
	fauna = f
	w = f.w


static func cfg() -> Dictionary:
	return GameData.b("refuges")


static func spec(species: String) -> Dictionary:
	return cfg().species.get(species, {})


## Every (wood, wild species) pair the species may live in that has no refuge yet gets one. New worlds call it
## once; an older save calls it on loading, so it gains its refuges once (they are saved from then on).
func ensure() -> void:
	var have := {}
	for r in list:
		have[r.id] = true
	var ids: Array = fauna.woods.keys()
	ids.sort()
	for area in ids:
		for k in fauna.wild_species():
			if spec(k).is_empty() or not lives_in(k, area):
				continue
			var id := "refuge_%s_%s" % [area, k]
			if have.has(id):
				continue
			var at := _site(area, k)
			list.append({"id": id, "species": k, "area": area, "site": str(spec(k).site), "x": at.x, "y": at.y,
				"stock": int(spec(k).stock), "cohort": {},
				"next_birth": w.minutes + w.rng.randf_range(0.0, float(spec(k).interval_days)) * World.DAY})
	list.sort_custom(func(a, b): return str(a.id) < str(b.id))


static func lives_in(species: String, area: String) -> bool:
	var s: Dictionary = GameData.b("animals")[species]
	return not s.has("only") or (s.only as Array).has(area)


## Where a refuge lies: dens, caves, earths and shelters ("deep") on the wood's cells farthest from the village
## (the player's spawn), burrows, nests and the deer's habitat ("any") anywhere in it; picked by the seeded rng.
func _site(area: String, species: String) -> Vector2i:
	var cs: Array = fauna.cells(area)
	if cs.is_empty():
		var r: Dictionary = fauna.woods[area]
		return Vector2i(int(r.x), int(r.y))
	var pool := cs
	if str(spec(species).get("place", "any")) == "deep":
		var sp: Array = w.map.data.spawns.player
		var village := Vector2(float(sp[0]), float(sp[1]))
		pool = cs.duplicate()
		pool.sort_custom(func(a, b): return Vector2(a).distance_to(village) > Vector2(b).distance_to(village))
		pool = pool.slice(0, maxi(1, pool.size() / 5))
	return pool[w.rng.randi() % pool.size()]


func by_id(id: String) -> Dictionary:
	for r in list:
		if r.id == id:
			return r
	return {}


# ---------------------------------------------------------------- dawn: births and releases --
func new_day() -> void:
	var now: float = w.minutes
	for r in list:
		if not r.cohort.is_empty():
			_release(r, now)
		elif now >= float(r.next_birth):
			_breed(r, now)


## A due refuge produces a cohort if it is in season and the woods it feeds have room and food.
func _breed(r: Dictionary, now: float) -> void:
	var s := spec(r.species)
	if not (s.seasons as Array).has(Life.season(now)):
		return
	var room := 0
	for area in _targets(r.species):
		if fed(area, r.species):
			room += _room(area, r.species)
	var n := mini(int(GameData.b("animals")[r.species].litter) * maxi(1, int(r.stock) / 2), room)
	if n <= 0:
		return
	r.cohort = {"n": n, "born": now}
	r.next_birth = now + float(s.interval_days) * World.DAY
	w.stat("refuge_born_" + r.species, n)


## Young old enough to leave go out at dawn, as many as the woods have room for; the rest wait, and any still
## without room when grown stay hidden for good.
func _release(r: Dictionary, now: float) -> void:
	var a_spec: Dictionary = GameData.b("animals")[r.species]
	var age := (now - float(r.cohort.born)) / World.DAY
	if age < float(a_spec.juvenile_days):
		return
	var taken := []
	while int(r.cohort.n) > 0:
		var to := _destination(r)
		if to == "":
			break
		r.cohort.n = int(r.cohort.n) - 1
		var sex := "m" if w.rng.randf() < 0.5 else "f"
		if to == r.area:
			var a: Animal = _enter(r.species, sex, float(r.cohort.born), r.area, Vector2(int(r.x), int(r.y)), taken)
			a.origin = r.id
			w.stat("refuge_released_" + r.species)
		else:
			var entry := _entry(to, Vector2(int(r.x), int(r.y)))
			var dist := Vector2(int(r.x), int(r.y)).distance_to(Vector2(entry))
			var secs := dist / (float(a_spec.speed) * float(cfg().disperse_speed))
			migrants.append({"species": r.species, "sex": sex, "born": float(r.cohort.born), "from": r.id, "to": to,
				"x": entry.x, "y": entry.y, "arrive": now + secs * float(GameData.b("game_minutes_per_second"))})
			w.stat("refuge_released_" + r.species)
			w.stat("migrating_" + r.species)
	if int(r.cohort.n) <= 0:
		r.cohort = {}
	elif age >= float(a_spec.grow_days):
		w.stat("refuge_held_" + r.species, int(r.cohort.n))
		r.cohort = {}


## The woods a refuge's young may go to: every wood the species lives in.
func _targets(species: String) -> Array:
	var out := []
	var ids: Array = fauna.woods.keys()
	ids.sort()
	for area in ids:
		if lives_in(species, area):
			out.append(area)
	return out


## Young a wood can still take from refuges: up to `release_below` of the cap, counting young on their way.
func _room(area: String, species: String) -> int:
	var limit := floori(float(fauna.cap(area, species)) * float(cfg().release_below))
	return maxi(0, limit - fauna.count(area, species) - _incoming(area, species))


func _incoming(area: String, species: String) -> int:
	var n := 0
	for m in migrants:
		if m.to == area and m.species == species:
			n += 1
	return n


## Whether a wood can feed one more of the species: grazers while its grass is not overgrazed, hunters and
## omnivores while it holds prey_per_predator spare prey for each of their kind and one more; seed eaters always.
func fed(area: String, species: String) -> bool:
	var s: Dictionary = GameData.b("animals")[species]
	match str(s.get("diet", "graze")):
		"graze":
			return fauna.grazers(area) < fauna.graze_capacity(area)
		"hunt", "omnivore":
			var spare := 0
			for k in (s.get("prey", []) as Array):
				spare += maxi(0, fauna.count(area, k) - int(GameData.b("animals")[k].keep))
			return spare >= int(Fauna.wl().prey_per_predator) * (fauna.count(area, species) + _incoming(area, species) + 1)
	return true


## The wood one young of refuge `r` goes to, or "" if none has room and food: the one with the lowest share of
## its cap, its own wood counting `cross_wood_penalty` less (moving away is a cost).
func _destination(r: Dictionary) -> String:
	var best := ""
	var best_score := INF
	for area in _targets(r.species):
		if _room(area, r.species) <= 0 or not fed(area, r.species):
			continue
		var share := float(fauna.count(area, r.species) + _incoming(area, r.species)) / float(fauna.cap(area, r.species))
		var score := share + (0.0 if area == r.area else float(cfg().cross_wood_penalty))
		if score < best_score:
			best_score = score
			best = area
	return best


## The cell of `area` nearest a point: where a migrant coming from there enters the wood.
func _entry(area: String, from: Vector2) -> Vector2i:
	var best := Vector2i(int(fauna.woods[area].x), int(fauna.woods[area].y))
	var bd := INF
	for c: Vector2i in fauna.cells(area):
		var d := Vector2(c).distance_to(from)
		if d < bd:
			bd = d
			best = c
	return best


## A young animal enters the woods at `at` (counted as born there for the ledger) and sets off for its settling point.
func _enter(species: String, sex: String, born: float, area: String, at: Vector2, taken: Array) -> Animal:
	var a: Animal = fauna.spawn(area, species, sex, null)
	a.born = born
	a.pos = at + Vector2(0.5, 0.5) + Vector2(w.rng.randf_range(-0.3, 0.3), w.rng.randf_range(-0.3, 0.3))
	a.dest = settle_point(area, species, at, taken)
	a.settle_by = w.minutes + float(cfg().settle_days) * World.DAY
	taken.append(a.dest)
	w.stat("born_" + species)
	return a


## Where a young animal entering `area` at `from` settles: among `samples` cells of the wood `disperse` tiles
## away (the species' [min, max]; any cell if none is that far), the one farthest from others of its kind (their
## settling points while they disperse) and from `taken` (its littermates' points), up to 3 x `spacing`.
func settle_point(area: String, species: String, from: Vector2, taken: Array) -> Vector2:
	var cs: Array = fauna.cells(area)
	if cs.is_empty():
		return from
	var s := spec(species)
	var lo := float(s.disperse[0])
	var hi := float(s.disperse[1])
	var others := taken.duplicate()
	for b: Animal in fauna.animals:
		if b.alive and b.area == area and b.species == species:
			others.append(b.dest if b.dest != Vector2.INF else b.pos)
	var best := Vector2.INF
	var best_score := -1.0
	var tries := int(cfg().samples)
	var looked := 0
	for i in tries * 4:
		var c: Vector2 = Vector2(cs[w.rng.randi() % cs.size()]) + Vector2(0.5, 0.5)
		var d := c.distance_to(from)
		if (d < lo or d > hi) and (i < tries * 2 or best != Vector2.INF):
			continue                                # a cell at the dispersal distance, if the wood has one
		var near := 3.0 * float(s.spacing)
		for o: Vector2 in others:
			near = minf(near, c.distance_to(o))
		if near > best_score:
			best_score = near
			best = c
		looked += 1
		if looked >= tries:
			break
	return best if best != Vector2.INF else from


# ---------------------------------------------------------------- dispersal (every update) ----
## Dispersing young walk to their settling points (off-screen as a straight line; near the player Fauna._move
## steers them); migrants reach their wood. Settled at the point, or when settle_days run out.
func update(dt: float) -> void:
	if not migrants.is_empty():
		_arrivals()
	for a: Animal in fauna.animals:
		if a.dest == Vector2.INF or not a.alive:
			continue
		if a.pos.distance_to(a.dest) <= 1.0 or w.minutes >= a.settle_by:
			a.dest = Vector2.INF
			w.stat("settled_" + a.species)
			continue
		if a.pos.distance_to(w.player.pos) > w.detail_radius:
			var step := float(a.spec().speed) * float(cfg().disperse_speed) * dt
			var d: Vector2 = a.dest - a.pos
			a.pos = a.dest if d.length() <= step else a.pos + d / d.length() * step


func _arrivals() -> void:
	var now: float = w.minutes
	var left := []
	for m in migrants:
		if now < float(m.arrive):
			left.append(m)
			continue
		if w.rng.randf() < float(cfg().transit_loss):
			w.stat("lost_migrating_" + m.species)     # a movement hazard: never reached the woods (never counted born)
			continue
		var a: Animal = _enter(m.species, m.sex, float(m.born), m.to, Vector2(int(m.x), int(m.y)), [])
		a.origin = str(m.from)
		w.stat("migrated_" + m.species)
	migrants = left


# ---------------------------------------------------------------- save -----------------------
func to_dict() -> Dictionary:
	return {"list": list.duplicate(true), "migrants": migrants.duplicate(true)}


func load_dict(d: Dictionary) -> void:
	list = []
	for r in d.get("list", []):
		var rec: Dictionary = r.duplicate(true)
		rec.x = int(rec.x)
		rec.y = int(rec.y)
		rec.stock = int(rec.stock)
		rec.next_birth = float(rec.next_birth)
		if not rec.cohort.is_empty():
			rec.cohort = {"n": int(rec.cohort.n), "born": float(rec.cohort.born)}
		list.append(rec)
	migrants = []
	for m in d.get("migrants", []):
		var rec: Dictionary = m.duplicate(true)
		rec.x = int(rec.x)
		rec.y = int(rec.y)
		rec.born = float(rec.born)
		rec.arrive = float(rec.arrive)
		migrants.append(rec)
	list.sort_custom(func(a, b): return str(a.id) < str(b.id))
