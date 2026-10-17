class_name Fauna
extends RefCounted
## The village's animals: livestock in the fenced pens and wild animals in the woods.
##
## Rules (owner decision 2026-10-17, numbers in balance.json "animals", recorded in
## docs/BUILD_DECISIONS.md):
##  - a fed adult female gives birth when a fed adult male of her kind shares her pen or woods,
##    then not again for breed_days; a litter never takes the area over its cap;
##  - babies are drawn at half scale until grow_days old, then at full scale;
##  - livestock is fed from its pen's trough every morning (feed wheat each); an animal that goes
##    unfed for starve_days dies; wild animals forage and are always fed;
##  - every animal becomes meat (and hide, if its kind has one) when it is killed; babies give half.

var w
var animals: Array = []      # Animal, ordered by id
var pens := {}               # id -> {kind, x, y, w, h, gate, feed_at, trough, owner}
var woods := {}              # id -> {x, y, w, h}
var next_id := 1
var claims := {}             # animal id -> npc id hunting it (not saved; hunters re-plan after loading)
var _cells := {}             # area id -> Array[Vector2i] of cells an animal may stand on


func _init(world) -> void:
	w = world
	for p in w.map.data.get("pens", []):
		var pd: Dictionary = p.duplicate(true)
		pd.trough = 0
		pd.owner = -1
		pens[pd.id] = pd
	for wd in w.map.data.get("woods", []):
		woods[wd.id] = wd.duplicate(true)


# ---------------------------------------------------------------- areas ----------------------
func cells(area: String) -> Array:
	if _cells.has(area):
		return _cells[area]
	var out := []
	var r: Dictionary = pens[area] if pens.has(area) else woods[area]
	var inset := 1 if pens.has(area) else 0       # a pen's fence is its border
	for y in range(int(r.y) + inset, int(r.y) + int(r.h) - inset):
		for x in range(int(r.x) + inset, int(r.x) + int(r.w) - inset):
			if not w.map.is_solid(Vector2i(x, y)):
				out.append(Vector2i(x, y))
	_cells[area] = out
	return out


func count(area: String, species: String, adults_only := false) -> int:
	var c := 0
	for a: Animal in animals:
		if a.alive and a.area == area and a.species == species and (not adults_only or a.adult(w.minutes)):
			c += 1
	return c


func cap(area: String, species: String) -> int:
	var s: Dictionary = GameData.b("animals")[species]
	return int(s.pen_cap) if pens.has(area) else int(s.woods_cap)


func pen_of(species: String) -> Dictionary:
	for id in pens:
		if pens[id].kind == species:
			return pens[id]
	return {}


# ---------------------------------------------------------------- creation -------------------
func populate() -> void:
	var ids := pens.keys()
	ids.sort()
	for id in ids:
		_start(id, pens[id].kind)
	ids = woods.keys()
	ids.sort()
	for id in ids:
		var kinds := []
		for k in GameData.b("animals"):
			if not k.begins_with("_") and GameData.b("animals")[k].kind == "wild":
				kinds.append(k)
		kinds.sort()
		for k in kinds:
			_start(id, k)


func _start(area: String, species: String) -> void:
	var s: Dictionary = GameData.b("animals")[species]
	var start: Array = s.start
	for i in int(start[0]) + int(start[1]):
		var a := spawn(area, species, "m" if i < int(start[0]) else "f", null)
		a.born = w.minutes - (float(s.grow_days) + w.rng.randf_range(0.0, 3.0)) * 1440.0
		a.next_birth = w.minutes + w.rng.randf_range(0.0, float(s.breed_days)) * 1440.0


## A new animal on a free cell of its area (next to `mother` for a birth).
func spawn(area: String, species: String, sex: String, mother: Animal) -> Animal:
	var s: Dictionary = GameData.b("animals")[species]
	var a := Animal.new()
	a.id = next_id
	next_id += 1
	a.species = species
	a.sex = sex
	a.area = area
	a.born = w.minutes
	a.hp = float(s.hp)
	var skins: Array = s.skins
	a.skin = skins[w.rng.randi() % skins.size()]
	var cs := cells(area)
	if mother != null:
		a.pos = mother.pos + Vector2(w.rng.randf_range(-0.4, 0.4), w.rng.randf_range(-0.4, 0.4))
	elif not cs.is_empty():
		a.pos = Vector2(cs[w.rng.randi() % cs.size()]) + Vector2(0.5, 0.5)
	a.wait = w.rng.randf_range(0.0, 3.0)
	animals.append(a)
	return a


# ---------------------------------------------------------------- daily ----------------------
## Morning: feeding from the troughs, then births.
func new_day() -> void:
	var now: float = w.minutes
	var starved := {}
	for a: Animal in animals.duplicate():
		if not a.alive:
			continue
		if a.wild():
			a.fed = true
			continue
		var need := int(a.spec().feed)
		var pen: Dictionary = pens[a.area]
		if int(pen.trough) >= need:
			pen.trough = int(pen.trough) - need
			a.fed = true
			a.unfed_days = 0
		else:
			a.fed = false
			a.unfed_days += 1
			if a.unfed_days >= int(GameData.b("animal_starve_days")):
				starved[a.spec().name] = int(starved.get(a.spec().name, 0)) + 1
				remove(a)
	for k in starved:
		w.note("%d %s starved in the pens: nobody fed them." % [starved[k], k.to_lower()])
	var born := {}
	for a: Animal in animals.duplicate():
		if not a.alive or a.sex != "f" or not a.fed or not a.adult(now) or now < a.next_birth:
			continue
		if not _has_mate(a):
			continue
		var s := a.spec()
		var room := cap(a.area, a.species) - count(a.area, a.species)
		var n := mini(int(s.litter), room)
		if n <= 0:
			continue
		for i in n:
			spawn(a.area, a.species, "m" if w.rng.randf() < 0.5 else "f", a)
		a.next_birth = now + float(s.breed_days) * 1440.0
		if not a.wild():
			born[a.spec().name] = int(born.get(a.spec().name, 0)) + n
	for k in born:
		w.note("%d new %s born in the pens." % [born[k], k.to_lower()])


func _has_mate(f: Animal) -> bool:
	for m: Animal in animals:
		if m.alive and m.sex == "m" and m.area == f.area and m.species == f.species and m.fed and m.adult(w.minutes):
			return true
	return false


## Put wheat in a pen's trough (from any inventory). Returns how much went in.
func feed(pen: Dictionary, from: Inventory, qty: int) -> int:
	var n := mini(qty, from.count("wheat"))
	if n > 0:
		from.remove("wheat", n)
		pen.trough = int(pen.trough) + n
	return n


## Wheat a pen eats each morning.
func daily_need(pen: Dictionary) -> int:
	var n := 0
	for a: Animal in animals:
		if a.alive and a.area == pen.id:
			n += int(a.spec().feed)
	return n


# ---------------------------------------------------------------- death ----------------------
## Kill an animal; returns what it yields (meat, and hide for kinds that have one).
func kill(a: Animal) -> Inventory:
	var bag := Inventory.new()
	var s := a.spec()
	var adult := a.adult(w.minutes)
	var meat := int(s.meat) if adult else maxi(1, int(s.meat) / 2)
	bag.add("meat", meat)
	if adult and int(s.hide) > 0:
		bag.add("hide", int(s.hide))
	remove(a)
	return bag


func remove(a: Animal) -> void:
	a.alive = false
	animals.erase(a)
	claims.erase(a.id)


func by_id(id: int) -> Animal:
	for a: Animal in animals:
		if a.id == id:
			return a
	return null


## Live animals within `r` tiles of a point.
func near(p: Vector2, r: float) -> Array:
	var out := []
	for a: Animal in animals:
		if a.alive and a.pos.distance_to(p) <= r:
			out.append(a)
	return out


## The nearest wild adult that nobody is hunting yet, leaving every kind at least its breeding stock.
func nearest_game(from: Vector2, max_d := 200.0) -> Animal:
	var best: Animal = null
	var bd := max_d
	for a: Animal in animals:
		if not a.alive or not a.wild() or not a.adult(w.minutes) or claims.has(a.id):
			continue
		if count(a.area, a.species, true) - _claimed(a.area, a.species) <= int(a.spec().keep):
			continue
		var d := a.pos.distance_to(from)
		if d < bd:
			bd = d
			best = a
	return best


func _claimed(area: String, species: String) -> int:
	var c := 0
	for id in claims:
		var a := by_id(id)
		if a != null and a.area == area and a.species == species:
			c += 1
	return c


## The pen animal a keeper should slaughter: an adult beyond the breeding stock when the pen is
## near its cap (spare males first), or null.
## With `short_of_feed`, the pen does not have to be full: the keeper culls rather than let the
## breeding stock starve (young ones last, as they give only half the meat).
func surplus(pen: Dictionary, short_of_feed := false) -> Animal:
	var kind: String = pen.kind
	if not short_of_feed and count(pen.id, kind) < cap(pen.id, kind) - 1:
		return null
	var males := []
	var females := []
	var young := []
	for a: Animal in animals:
		if a.alive and a.area == pen.id:
			if not a.adult(w.minutes):
				young.append(a)
			else:
				(males if a.sex == "m" else females).append(a)
	var keep := int(GameData.b("animals")[kind].keep)
	if males.size() > 1:
		return males[0]
	if females.size() > keep:
		return females[0]
	if short_of_feed and not young.is_empty():
		return young[0]
	return null


# ---------------------------------------------------------------- movement -------------------
## Wandering (and wild animals shying away from people), only near the player: far away nobody
## sees them move, and births, feeding and hunting do not depend on where they stand.
func update(dt: float) -> void:
	for a: Animal in animals:
		if a.pos.distance_to(w.player.pos) > w.detail_radius:
			a.moving = false
			continue
		_move(a, dt)


func _move(a: Animal, dt: float) -> void:
	var s := a.spec()
	var flee := float(s.get("flee", 0.0))
	if flee > 0.0 and w.player.alive and w.player.pos.distance_to(a.pos) < flee:
		var away: Vector2 = (a.pos - w.player.pos).normalized()
		a.goal = a.pos + away * 3.0
		a.wait = 0.0
	if a.goal == Vector2.INF:
		a.wait -= dt
		a.moving = false
		if a.wait > 0.0:
			return
		var cs := cells(a.area)
		if cs.is_empty():
			return
		var c: Vector2i = cs[w.rng.randi() % cs.size()]
		if Vector2(c).distance_to(a.pos) > 5.0:
			c = Vector2i((Vector2(c) - a.pos).limit_length(5.0) + a.pos)
		a.goal = Vector2(c) + Vector2(0.5, 0.5)
	var d: Vector2 = a.goal - a.pos
	var speed := float(s.speed) * (2.2 if flee > 0.0 and w.player.pos.distance_to(a.pos) < flee else 1.0)
	var step := speed * dt
	if d.length() <= step:
		a.goal = Vector2.INF
		a.wait = w.rng.randf_range(1.0, 4.0)
		a.moving = false
		return
	var nxt: Vector2 = a.pos + d / d.length() * step
	var nc := Vector2i(floori(nxt.x), floori(nxt.y))
	if w.map.is_solid(nc) or not cells(a.area).has(nc):
		a.goal = Vector2.INF
		a.wait = w.rng.randf_range(0.5, 2.0)
		a.moving = false
		return
	a.facing = d
	a.pos = nxt
	a.moving = true


# ---------------------------------------------------------------- save -----------------------
func to_dict() -> Dictionary:
	var as_ := []
	for a: Animal in animals:
		as_.append(a.to_dict())
	var ps := {}
	for id in pens:
		ps[id] = {"trough": pens[id].trough, "owner": pens[id].owner}
	return {"next_id": next_id, "animals": as_, "pens": ps}


func load_dict(d: Dictionary) -> void:
	next_id = int(d.next_id)
	for ad in d.animals:
		animals.append(Animal.from_dict(ad))
	for id in d.pens:
		if pens.has(id):
			pens[id].trough = int(d.pens[id].trough)
			pens[id].owner = int(d.pens[id].owner)
