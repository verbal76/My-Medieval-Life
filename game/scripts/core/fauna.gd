class_name Fauna
extends RefCounted
## The village's animals: livestock in the fenced pens and wild animals in the woods.
##
## Rules (owner decision 2026-10-17, numbers in balance.json "animals", recorded in
## docs/BUILD_DECISIONS.md):
##  - animals get hungry like the villagers: hunger falls every hour, a hungry animal eats
##    (livestock `feed` wheat from its pen's trough, wild animals by grazing while the wood is not
##    overcrowded), and at zero hunger it loses health until it dies;
##  - a well-fed adult female gives birth when a well-fed adult male of her kind shares her pen or
##    woods, then not again for breed_days; a litter never takes the area over its cap;
##  - babies are drawn with the baby sheet (half scale of the adult sheet where there is none) until grow_days
##    old; B8-029 adds the stages newborn / juvenile / adult / elderly, the elderly move slower, do not breed and
##    die naturally within death_days;
##  - every animal becomes meat (and hide, if its kind has one) when it is killed; babies give half;
##  - WR-01: each wood keeps a hidden breeding refuge per wild species (Refuges, balance.json "refuges"), out of
##    everyone's reach, whose young leave in season into woods below their capacity and disperse to settle.

var w
var animals: Array = []      # Animal, ordered by id
var pens := {}               # id -> {kind, x, y, w, h, gate, feed_at, trough, owner, tenant}: the manor's,
                             # let to its keeper (tenant "npc:<id>"; World "ownership", World.pen_keeper)
var woods := {}              # id -> {x, y, w, h}
var next_id := 1
var seeded: Array = []       # wild species that have been started in the woods (saved; B14 adds species to old saves)
var refuges: Refuges         # WR-01: the woods' protected breeding refuges (saved)
var claims := {}             # animal id -> npc id hunting it (not saved; hunters re-plan after loading)
var _cells := {}             # area id -> Array[Vector2i] of cells an animal may stand on
var _cell_set := {}          # area id -> {Vector2i: true}, the same cells for membership tests (PERF-04)


func _init(world) -> void:
	w = world
	for p in w.map.data.get("pens", []):
		var pd: Dictionary = p.duplicate(true)
		pd.trough = 0
		pd.owner = "manor"
		pd.tenant = ""
		pens[pd.id] = pd
	for wd in w.map.data.get("woods", []):
		woods[wd.id] = wd.duplicate(true)
	refuges = Refuges.new(self)


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
	var members := {}
	for c in out:
		members[c] = true
	_cell_set[area] = members
	return out


## Whether `c` is one of the cells of `area` (cells(area).has(c), without searching the list).
func in_area(area: String, c: Vector2i) -> bool:
	if not _cell_set.has(area):
		cells(area)
	return _cell_set[area].has(c)


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
			if GameData.b("animals")[k].has("only") and not (GameData.b("animals")[k].only as Array).has(id):
				continue
			_start(id, k)
	seeded = wild_species()
	refuges.ensure()


func wild_species() -> Array:
	var kinds := []
	for k in GameData.b("animals"):
		if not k.begins_with("_") and GameData.b("animals")[k].kind == "wild":
			kinds.append(k)
	kinds.sort()
	return kinds


func _start(area: String, species: String) -> void:
	var s: Dictionary = GameData.b("animals")[species]
	var start: Array = s.start
	for i in int(start[0]) + int(start[1]):
		var a := spawn(area, species, "m" if i < int(start[0]) else "f", null)
		var age: float = float(s.grow_days) + w.rng.randf_range(0.0, 3.0)        # a breeding adult
		var n_start := int(start[0]) + int(start[1])
		if i == 1:                                                         # a juvenile among them (B8-029)
			age = w.rng.randf_range(float(s.juvenile_days), float(s.grow_days) * 0.9)
		elif i == n_start - 1 and n_start >= 4:                            # and, in the larger groups, an elderly one
			age = float(s.elder_days) + w.rng.randf_range(0.0, (float(s.death_days[0]) - float(s.elder_days)) * 0.5)
		a.born = w.minutes - age * 1440.0
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
	var skins: Array = s.get("skins_m", s.skins) if sex == "m" else s.skins       # the stag and the doe (B14)
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
## Hunger, like the villagers': it falls every game hour; a hungry animal eats (livestock from
## its pen's trough, wild animals by grazing); at zero it loses health and dies.
func tick(gm: float) -> void:
	var per_hour := float(GameData.b("animal_hunger_per_hour"))
	var eat_below := float(GameData.b("animal_eat_below"))
	for a: Animal in animals.duplicate():
		if not a.alive:
			continue
		a.hunger = maxf(0.0, a.hunger - gm / 60.0 * float(a.spec().get("hunger_per_hour", per_hour)))     # a kill lasts a hunter days (B14)
		if a.hunger < eat_below:
			_eat(a, gm)
		if a.hunger <= 0.0 and a.wild() and a.diet() in ["hunt", "omnivore"] and count(a.area, a.species) <= int(a.spec().keep):
			a.hunger = float(wl().scavenge_hunger)             # the last pair scavenges carrion and scraps (B14): it lives on, lean
			w.stat("scavenged_" + a.species)
		if a.hunger <= 0.0:
			a.hp -= gm / 60.0 * float(a.spec().hp) * float(GameData.b("animal_starve_hp_per_hour"))
			if a.hp <= 0.0:
				w.note("A %s starved %s." % [a.label(), "in the woods" if a.wild() else "in the pens: nobody fed it"])
				w.stat("starved_" + a.species)
				remove(a)


func _eat(a: Animal, gm := 60.0) -> void:
	if a.wild():
		match a.diet():
			"graze":
				if _may_graze(a):
					a.hunger = 100.0
			"seeds":
				a.hunger = 100.0                       # birds pick seeds anywhere in the wood
			"hunt", "omnivore":
				if a.diet() == "omnivore" and _forage_berries(a):
					return
				if a.species == "fox" and _raid(a, gm):
					return
				_predate(a, gm)
		return
	var pen: Dictionary = pens[a.area]
	var need := int(a.spec().feed)
	if int(pen.trough) >= need:
		pen.trough = int(pen.trough) - need
		w.stat("feed_eaten_wheat", float(need))
		a.hunger = 100.0
		a.hp = minf(float(a.spec().hp), a.hp + float(a.spec().hp) * 0.25)


# ---------------------------------------------------------------- the food chain (B14) ------
static func wl() -> Dictionary:
	return GameData.b("wildlife")


## Whether `pred` may take `prey` now: one of its prey species, grown or young, in the same wood, and the
## prey's kind left with at least its breeding stock.
func can_take(pred: Animal, prey: Animal) -> bool:
	return prey.alive and prey != pred and prey.area == pred.area and (pred.spec().get("prey", []) as Array).has(prey.species) \
			and spare(prey)


## Whether `a` can be taken (by a hunter, a predator or a poacher) without breaking its wood's stock: more than
## its kind's `keep` (plus `extra`) in the area, and not the last grown male or female there (B14: a pair
## always remains to breed).
func spare(a: Animal, extra := 0) -> bool:
	if count(a.area, a.species) <= int(a.spec().keep) + extra:
		return false
	if not a.adult(w.minutes):
		return true
	for b: Animal in animals:
		if b != a and b.alive and b.area == a.area and b.species == a.species and b.sex == a.sex and b.adult(w.minutes):
			return true
	return false


## The prey animals in a hunter's wood beyond what must be spared (their kinds' keep).
func _spare_prey(a: Animal) -> int:
	var n := 0
	for k in (a.spec().get("prey", []) as Array):
		n += maxi(0, count(a.area, k) - int(GameData.b("animals")[k].keep))
	return n


## A hungry hunter makes a kill in its wood at most hunt_chance_per_hour an hour, wherever the player is.
## Near the player it is seen chasing the nearest prey (_move), which it may also catch sooner; the hourly
## chance still feeds it, so a quick runner cannot starve a hunter that is watched.
func _predate(a: Animal, gm: float) -> void:
	if a.pos.distance_to(w.player.pos) <= w.detail_radius and (by_id(a.hunt) == null or not can_take(a, by_id(a.hunt))):
		a.hunt = -1
		var bd := 1e9
		for b: Animal in animals:
			if can_take(a, b) and a.pos.distance_to(b.pos) < bd:
				bd = a.pos.distance_to(b.pos)
				a.hunt = b.id
	if w.rng.randf() >= float(wl().hunt_chance_per_hour) * gm / 60.0:
		return
	if a.hunt != -1 and by_id(a.hunt) != null:
		take(a, by_id(a.hunt))
		return
	var options := []
	for b: Animal in animals:
		if can_take(a, b):
			options.append(b)
	if not options.is_empty():
		take(a, options[w.rng.randi() % options.size()])


## `pred` kills and eats `prey`: the prey is gone (counted, a pool of blood where it fell) and the hunter fed.
func take(pred: Animal, prey: Animal) -> void:
	w.stat("eaten_%s_by_%s" % [prey.species, pred.species])
	w.bled.emit(prey.pos)
	remove(prey)
	pred.hunger = 100.0
	pred.hunt = -1
	pred.act = "attack"
	pred.act_left = 0.6


## The bear eats a ripe berry bush within berry_range of its wood (the bush is picked, as by anyone).
func _forage_berries(a: Animal) -> bool:
	var r: Dictionary = woods.get(a.area, {})
	if r.is_empty():
		return false
	var m := int(wl().berry_range)
	for pl in w.plants:
		if pl.state == "ripe" and str(pl.kind) in ["redberry", "blueberry"] and int(pl.x) >= int(r.x) - m and int(pl.x) < int(r.x) + int(r.w) + m \
				and int(pl.y) >= int(r.y) - m and int(pl.y) < int(r.y) + int(r.h) + m:
			var got: Dictionary = w.pick_plant(pl)
			for id in got:
				w.stat("wild_eaten_" + id, float(got[id]))    # eaten on the bush: no item reaches anyone (economy ledger)
			w.stat("bear_ate_berries")
			a.hunger = 100.0
			return true
	return false


## A hungry fox takes a pen chicken at night, never below the pen's breeding stock.
func _raid(a: Animal, gm: float) -> bool:
	var h: float = w.hour()
	if not (h >= float(wl().night_from) or h < float(wl().night_to)) or w.rng.randf() >= float(wl().fox_raid_chance_per_hour) * gm / 60.0:
		return false
	var ids := pens.keys()
	ids.sort()
	for id in ids:
		var pen: Dictionary = pens[id]
		if pen.kind != str(a.spec().get("raids", "")) or count(id, pen.kind) <= int(GameData.b("animals")[pen.kind].keep):
			continue
		for c: Animal in animals:
			if c.alive and c.area == id:
				w.stat("fox_took_" + c.species)
				w.note("A fox took a %s from the %s in the night." % [c.label(), "your pen" if pen.get("player", false) else "pens"])
				remove(c)
				a.hunger = 100.0
				return true
	return false


## Someone struck it: a wolf or a bear fights back for anger_seconds (`who`: "player" or "npc:<id>").
func provoke(a: Animal, who: String) -> void:
	a.act = "hit"
	a.act_left = 0.4
	if bool(a.spec().get("people", false)):
		a.anger = who
		a.anger_left = float(wl().anger_seconds)


## The position of whoever `who` names, or INF if they are gone.
func _foe_pos(who: String) -> Vector2:
	if who == "player":
		return w.player.pos if w.player.alive else Vector2.INF
	var n: NPC = w.npc(int(who.trim_prefix("npc:")))
	return n.pos if n != null and n.alive else Vector2.INF


## A starving wolf or bear goes for a person standing in its wood with nobody else within alone_radius.
func _hunt_people(a: Animal) -> void:
	if a.anger != "" or not bool(a.spec().get("people", false)) or a.hunger >= float(wl().people_hunger):
		return
	var people := [["player", w.player.pos]] if w.player.alive else []
	for n: NPC in w.npcs:
		if n.alive and not w.asleep(n) and n.pos.distance_to(a.pos) <= w.detail_radius:
			people.append(["npc:%d" % n.id, n.pos])
	for p in people:
		var at: Vector2 = p[1]
		if not in_area(a.area, Vector2i(floori(at.x), floori(at.y))) or at.distance_to(a.pos) > 8.0:
			continue
		var alone := true
		for q in people:
			if q != p and (q[1] as Vector2).distance_to(at) <= float(wl().alone_radius):
				alone = false
		if alone:
			a.anger = p[0]
			a.anger_left = float(wl().anger_seconds)
			w.stat("animal_went_for_" + ("player" if p[0] == "player" else "villager"))
			return


## A bite at whoever it is fighting, if within reach.
func _bite(a: Animal, foe: Vector2) -> void:
	if a.bite_cd > 0.0 or foe.distance_to(a.pos) > 1.0:
		return
	a.bite_cd = float(a.spec().get("bite_seconds", 1.0))
	a.act = "attack"
	a.act_left = 0.5
	var dmg := float(a.spec().get("bite", 0))
	if a.anger == "player":
		w.damage_player(dmg, "a " + a.label())
	else:
		var n: NPC = w.npc(int(a.anger.trim_prefix("npc:")))
		if n == null:
			return
		n.hp -= maxf(0.5, dmg - n.armor * 0.5)
		if n.hp <= 0.0:
			w.kill(n, "killed by a %s" % a.label())
			a.anger = ""


## Wild animals a wood can feed: one per `graze_cells_per_animal` open cells.
func graze_capacity(area: String) -> int:
	return cells(area).size() / int(GameData.b("graze_cells_per_animal"))


## Whether a grazer finds grass (WR-02): all do while the wood is within its capacity; over it, only as many
## as the wood can feed, the strongest and best fed first, so the weakest and hungriest go short rather than
## the whole herd at once (ties by id, deterministic).
func _may_graze(a: Animal) -> bool:
	var cap := graze_capacity(a.area)
	var herd := []
	for b: Animal in animals:
		if b.alive and b.area == a.area and b.diet() == "graze":
			herd.append(b)
	if herd.size() <= cap:
		return true
	var ahead := 0
	var mine := [a.hp / maxf(1.0, float(a.spec().hp)), a.hunger, -a.id]
	for b: Animal in herd:
		if b == a:
			continue
		var theirs := [b.hp / maxf(1.0, float(b.spec().hp)), b.hunger, -b.id]
		if theirs > mine:
			ahead += 1
			if ahead >= cap:
				return false
	return true


func grazers(area: String) -> int:
	var c := 0
	for a: Animal in animals:
		if a.alive and a.area == area and a.diet() == "graze":
			c += 1
	return c


## Fed enough to breed.
func well_fed(a: Animal) -> bool:
	return a.hunger >= float(GameData.b("animal_breed_min_hunger"))


## Morning: births.
func new_day() -> void:
	var now: float = w.minutes
	_old_age(now)
	var born := {}
	for a: Animal in animals.duplicate():
		if not a.alive or a.sex != "f" or not well_fed(a) or not a.breeds(now) or now < a.next_birth:
			continue
		if not _has_mate(a):
			continue
		var s := a.spec()
		if a.wild() and a.diet() in ["hunt", "omnivore"] and _spare_prey(a) < int(wl().prey_per_predator) * (count(a.area, a.species) + 1):
			continue                                    # a hunter breeds only where its prey can feed one more (B14)
		var room := cap(a.area, a.species) - count(a.area, a.species)
		var n := mini(int(s.litter), room)
		if n <= 0:
			continue
		# breeding slows as the area fills (B8-029): full chance up to `animal_breed_slow_from` of the cap, then
		# falling to nothing at the cap (a day's chance; the female tries again tomorrow)
		var chance := breed_chance(a.area, a.species)
		if chance < 1.0 and w.rng.randf() >= chance:
			continue
		for i in n:
			spawn(a.area, a.species, "m" if w.rng.randf() < 0.5 else "f", a)
		w.stat("born_" + a.species, n)
		a.next_birth = now + float(s.breed_days) * 1440.0
		if not a.wild():
			born[a.spec().name] = int(born.get(a.spec().name, 0)) + n
	for k in born:
		w.note("%d new %s born in the pens." % [born[k], k.to_lower()])
	refuges.new_day()                                   # WR-01: the refuges' young, in season, where there is room


## Natural death of the elderly (B8-029): no chance before the species' death_days[0]; after it a daily chance
## of 1 in the days left to death_days[1] (so the age at death is spread evenly over the range), certain at the end.
func _old_age(now: float) -> void:
	for a: Animal in animals.duplicate():
		if not a.alive or not a.elderly(now):
			continue
		var dd: Array = a.spec().death_days
		var age: float = a.age_days(now)
		if age < float(dd[0]):
			continue
		var left := float(dd[1]) - age
		if left <= 1.0 or w.rng.randf() < 1.0 / left:
			w.stat("old_age_" + a.species)
			if not a.wild():
				w.note("An old %s died in the pens." % a.label())
			remove(a)


## The chance a ready female breeds on a day: 1 while the area holds less than `animal_breed_slow_from` of its cap,
## then falling in a line to 0 at the cap (B8-029).
func breed_chance(area: String, species: String) -> float:
	var frac := float(count(area, species)) / float(cap(area, species))
	return clampf((1.0 - frac) / (1.0 - float(GameData.b("animal_breed_slow_from"))), 0.0, 1.0)


func _has_mate(f: Animal) -> bool:
	for m: Animal in animals:
		if m.alive and m.sex == "m" and m.area == f.area and m.species == f.species and well_fed(m) and m.breeds(w.minutes):
			return true
	return false


## Put wheat in a pen's trough (from any inventory). Returns how much went in.
func feed(pen: Dictionary, from: Inventory, qty: int) -> int:
	var n := mini(qty, from.count("wheat"))
	if n > 0:
		from.remove("wheat", n)
		pen.trough = int(pen.trough) + n
	return n


## Wheat a pen eats in a day (an animal eats about twice a day).
func daily_need(pen: Dictionary) -> int:
	var n := 0
	for a: Animal in animals:
		if a.alive and a.area == pen.id:
			n += int(a.spec().feed) * 2
	return n


## Animals in a pen that are hungry now.
func hungry(pen: Dictionary) -> int:
	var n := 0
	for a: Animal in animals:
		if a.alive and a.area == pen.id and a.hunger < float(GameData.b("animal_eat_below")):
			n += 1
	return n


# ---------------------------------------------------------------- death ----------------------
## Kill an animal; returns what it yields (meat; hide, rabbit pelt or feathers for the kinds that have them).
func kill(a: Animal) -> Inventory:
	var bag := Inventory.new()
	var s := a.spec()
	var adult := a.adult(w.minutes)
	var meat := int(s.meat) if adult else (maxi(1, int(s.meat) / 2) if int(s.meat) > 0 else 0)
	if meat > 0:                                # a bird gives only a feather
		bag.add("meat", meat)
		w.stat("made_meat", float(meat))
	w.bled.emit(a.pos)
	if adult and int(s.hide) > 0:
		bag.add("hide", int(s.hide))
		w.stat("made_hide", float(s.hide))
	if adult:                                   # PL2-004: a rabbit's pelt, a chicken's feathers
		for key in ["pelt", "feathers"]:
			var item: String = "rabbit_pelt" if key == "pelt" else "feather"
			if int(s.get(key, 0)) > 0:
				bag.add(item, int(s[key]))
				w.stat("made_" + item, float(s[key]))
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
		if not a.alive or not a.wild() or not a.adult(w.minutes) or claims.has(a.id) or not bool(a.spec().get("game", true)):
			continue                                    # the village hunter leaves wolves, foxes and bears alone (B14)
		if count(a.area, a.species, true) - _claimed(a.area, a.species) <= int(a.spec().keep) or not spare(a, int(wl().hunter_spare)):
			continue                                    # the hunter leaves the predators their share (B14)
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
	tick(dt * float(GameData.b("game_minutes_per_second")))
	refuges.update(dt)                                  # WR-01: young from the refuges disperse and settle
	for a: Animal in animals.duplicate():
		if not a.alive:
			continue
		a.bite_cd = maxf(0.0, a.bite_cd - dt)
		a.act_left = maxf(0.0, a.act_left - dt)
		if a.act_left <= 0.0:
			a.act = ""
		if a.anger != "":
			a.anger_left -= dt
			if a.anger_left <= 0.0 or _foe_pos(a.anger) == Vector2.INF:
				a.anger = ""
		if a.pos.distance_to(w.player.pos) > w.detail_radius:
			a.moving = false
			continue
		_move(a, dt)


func _move(a: Animal, dt: float) -> void:
	var s := a.spec()
	var flee := float(s.get("flee", 0.0))
	var fleeing := false
	_hunt_people(a)
	if a.anger != "":                                       # fighting someone: after them, biting in reach
		var foe := _foe_pos(a.anger)
		_bite(a, foe)
		a.goal = foe
		a.wait = 0.0
	elif a.hunt != -1 and by_id(a.hunt) != null:            # a hunter's chase, seen near the player
		var prey := by_id(a.hunt)
		if prey.pos.distance_to(a.pos) <= float(wl().kill_range):
			take(a, prey)
			return
		a.goal = prey.pos
		a.wait = 0.0
	else:
		var threat: Vector2 = w.player.pos if w.player.alive and w.player.pos.distance_to(a.pos) < flee else Vector2.INF
		if flee > 0.0:
			for b: Animal in animals:                       # prey run from a hunter that could take them (the last one found)
				if b.alive and b.area == a.area and b.pos.distance_to(a.pos) < flee and (b.spec().get("prey", []) as Array).has(a.species):
					threat = b.pos
		if threat != Vector2.INF:
			a.goal = a.pos + (a.pos - threat).normalized() * 3.0
			a.wait = 0.0
			fleeing = true
	if a.goal == Vector2.INF:
		a.wait -= dt
		a.moving = false
		if a.wait > 0.0:
			return
		var cs := cells(a.area)
		if cs.is_empty():
			return
		var c: Vector2i = cs[w.rng.randi() % cs.size()]
		if a.dest != Vector2.INF and w.rng.randf() >= float(Refuges.cfg().wander_share):
			c = Vector2i((a.dest - a.pos).limit_length(5.0) + a.pos)       # WR-01: dispersing, it heads for its settling point
		if not a.wild() and a.hunger < float(GameData.b("animal_eat_below")) + 10.0:
			var pen: Dictionary = pens[a.area]
			c = Vector2i(int(pen.gate[0]), int(pen.gate[1]) + 1)          # the trough is by the gate
		if Vector2(c).distance_to(a.pos) > 5.0:
			c = Vector2i((Vector2(c) - a.pos).limit_length(5.0) + a.pos)
		a.goal = Vector2(c) + Vector2(0.5, 0.5)
	var d: Vector2 = a.goal - a.pos
	var speed := float(s.speed) * (float(GameData.b("animal_elder_speed")) if a.elderly(w.minutes) else 1.0) * (2.2 if fleeing else 1.0) \
			* (float(wl().chase_speed) if a.anger != "" or a.hunt != -1 else 1.0)
	var step := speed * dt
	if d.length() <= step:
		a.goal = Vector2.INF
		a.wait = w.rng.randf_range(1.0, 4.0)
		a.moving = false
		return
	var nxt: Vector2 = a.pos + d / d.length() * step
	var nc := Vector2i(floori(nxt.x), floori(nxt.y))
	if w.map.is_solid(nc) or (not in_area(a.area, nc) and in_area(a.area, a.cell())):
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
	var mine := []                                      # the player's pens (PL2-015) are not on the map: saved whole
	for id in pens:
		ps[id] = {"trough": pens[id].trough, "owner": pens[id].owner, "tenant": pens[id].tenant, "products": pens[id].get("products", {}).duplicate()}
		if pens[id].get("player", false):
			mine.append(pens[id])
	return {"next_id": next_id, "animals": as_, "pens": ps, "player_pens": mine, "seeded": seeded.duplicate(),
		"refuges": refuges.to_dict()}


func load_dict(d: Dictionary) -> void:
	next_id = int(d.next_id)
	seeded = (d.get("seeded", ["boar", "rabbit"]) as Array).duplicate()     # saves before B14 had the boar and the rabbit
	refuges.load_dict(d.get("refuges", {}))     # saves before WR-01 have none: seed_new_species gives them their refuges once
	for rec in d.get("player_pens", []):
		pens[str(rec.id)] = rec.duplicate(true)
	for ad in d.animals:
		animals.append(Animal.from_dict(ad))
	for id in d.pens:
		if pens.has(id):
			pens[id].trough = int(d.pens[id].trough)
			var sp: Dictionary = d.pens[id]
			if not pens[id].get("player", false):
				pens[id]["products"] = sp.get("products", {}).duplicate()      # waiting eggs, milk and wool (Build 13)
			if sp.has("tenant"):
				pens[id].owner = str(sp.owner)
				pens[id].tenant = str(sp.tenant)
			else:
				# saves before property (1-4): `owner` was the keeper's id, -1 for none
				var k = w.npc(int(sp.get("owner", -1)))
				pens[id].tenant = World.npc_ref(k.id) if k != null and k.alive else ""


## A save made before a wild species existed gets that species started in the woods (B14 forest animals),
## once: a species the player later hunts out stays gone.
func seed_new_species() -> void:
	var ids := woods.keys()
	ids.sort()
	for k in wild_species():
		if seeded.has(k):
			continue
		for id in ids:
			if not (GameData.b("animals")[k].has("only") and not (GameData.b("animals")[k].only as Array).has(id)):
				_start(id, k)
		seeded.append(k)
	seeded.sort()
	refuges.ensure()                            # WR-01: any wood and species without a refuge gets one (once: it is saved)
