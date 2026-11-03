class_name Journeys
extends RefCounted
## REGION-NAV-01 AD-4 (owner 2026-11-02: "Envoys are physical NPCs operating within the existing world. They must travel to other
## settlements ... and return home"; "No instant inventory transfers between villages"; no fast travel): a villager walks to a
## neighbouring settlement and back along the roads, in the world's own movement (World._walk on a path laid out here).
##
## n.journey (saved, optional NPC key): {to: settlement id, purpose: {kind, ...}, leg: "out" | "there" | "back", since: day,
## gate: the village gate index}. Only that is saved: the route is a pure function of the seed (Overworld.road_route), so when the
## villager has no plan (just started, an interruption, a loaded save: plans are not saved) the leg goes on from where they stand
## (resume). Out: the village's own path to the south gate, then the road; there: the purpose's work at the site (purpose hook,
## World.journey_hook), else they stay till the next morning; back: the road, then the village path home. At night (20:00 to
## 6:00) a traveller rests where they are on the road (the homeless rest rule, KI-HOME-DOOR), and when hungry eats from their pack.
## A route that cannot be found fails the journey (recorded: journey_failed_no_road) and the villager stays or turns home. Nothing
## is created or destroyed: what they carry is in their pack all the way (a death on the road leaves it where they fall).

const REST_FROM := 20
const REST_TO := 6
const EAT_BELOW := 40.0


static func active(n: NPC) -> bool:
	return not n.journey.is_empty()


## The village gate a journey leaves by: the south gate (the road the settlements lie on), else the first.
static func gate_index(w: World) -> int:
	var ex: Array = w.map.exits()
	for k in ex.size():
		if int(ex[k].side) == 2:
			return k
	return 0 if not ex.is_empty() else -1


## Send `n` to settlement `sid` for `purpose` ({kind: ...}). "" when they set off, else why not (recorded).
static func start(w: World, n: NPC, sid: String, purpose: Dictionary) -> String:
	if w.map.overworld == null or w.map.overworld.site(sid).is_empty():
		return "There is no such place."
	if active(n):
		return "%s is already on a journey." % n.name
	var gi := gate_index(w)
	if w.map.overworld.road_route(gi, sid).is_empty():
		w.stat("journey_failed_no_road")
		return "There is no road to %s." % w.map.overworld.site(sid).name
	n.journey = {"to": sid, "purpose": purpose.duplicate(true), "leg": "out", "since": w.day(), "gate": gi}
	n.plan.clear()
	w.stat("journey_started")
	w.stat("journey_started_" + str(purpose.get("kind", "visit")))
	return ""


## Each update of a traveller with no plan: lay out the rest of the current leg from where they stand. Returns true while the
## journey goes on (the brain does not plan for them), false once it is over.
static func resume(w: World, n: NPC) -> bool:
	if not active(n):
		return false
	var ow: Overworld = w.map.overworld
	var st: Dictionary = ow.site(str(n.journey.to))
	if st.is_empty():
		end(w, n, "lost")
		return false
	var leg := str(n.journey.leg)
	if leg == "there":
		var hook: Callable = w.journey_hook
		if hook.is_valid() and bool(hook.call(n)):
			return true                                    # the purpose has given them work at the site (it plans it)
		if w.hour() < float(REST_TO) or n.journey.get("stay_until", -1) > w.minutes:
			return _rest(n)
		n.journey.leg = "back"
		w.stat("journey_leaving_" + str(n.journey.to))
		leg = "back"
	var road := ow.road_route(int(n.journey.gate), str(n.journey.to))
	if road.is_empty():
		w.stat("journey_failed_no_road")
		end(w, n, "no road")
		return false
	var gate: Dictionary = w.map.exits()[int(n.journey.gate)]
	var inside: Vector2i = Vector2i(gate.out) - Vector2i(gate.dir)
	var path := PackedVector2Array()
	if leg == "out":
		if w.map.in_village(n.cell()):
			path = w.map.find_path(n.cell(), inside)
			path.append(Vector2(gate.out))
		var from := _nearest(road, n.cell()) if not w.map.in_village(n.cell()) else 0
		for q in range(from, road.size()):
			path.append(road[q])
		path.append(Vector2(st.slots[0].spot))
	else:
		var from := road.size() - 1
		if not ow.site_at(n.cell()).is_empty():
			path.append(Vector2(st.gate))
		else:
			from = _nearest(road, n.cell())
		for q in range(from, -1, -1):
			path.append(road[q])
		var home := w.home_cell(n, "door")
		var back := w.map.find_path(inside, home)
		for c in back:
			path.append(c)
	n.path = path
	n.path_i = 0
	var dest := Vector2i(path[path.size() - 1]) if not path.is_empty() else n.cell()
	n.plan = [{"k": "go", "to": dest, "pathed": true}, {"k": "do", "act": "journey_leg", "args": {}}]
	n.doing = ("on the road to %s" if leg == "out" else "on the road home from %s") % st.name
	return true


static func _nearest(road: PackedVector2Array, c: Vector2i) -> int:
	var best := 0
	var bd := 1 << 30
	for q in road.size():
		var d := absi(int(road[q].x) - c.x) + absi(int(road[q].y) - c.y)
		if d < bd:
			bd = d
			best = q
	return best


static func _rest(n: NPC) -> bool:
	n.plan = [{"k": "work", "min": 30.0, "anim": "idle"}]
	n.work_left = 30.0
	n.doing = "resting"
	return true


## The end of a leg (the brain's "journey_leg" act): out -> there (arrived), back -> home (the journey is over).
static func leg_done(w: World, n: NPC) -> void:
	if not active(n):
		return
	match str(n.journey.leg):
		"out":
			n.journey.leg = "there"
			n.journey.arrived = w.day()
			n.journey.stay_until = float((w.day() + 1) * 1440 + REST_TO * 60)
			w.stat("journey_arrived")
			w.stat("journey_arrived_" + str(n.journey.to))
		"back":
			end(w, n, "home")


static func end(w: World, n: NPC, how: String) -> void:
	w.stat("journey_ended_" + how)
	n.journey = {}
	n.plan.clear()


## Before each update of a traveller: rest at night where they stand (unless already at rest), and eat from their pack when
## hungry. Returns true when they rest this update (World._update_npc skips the plan).
static func night_and_food(w: World, n: NPC) -> bool:
	if n.hunger < EAT_BELOW:
		for f in NPCBrain.EDIBLE:
			if n.inv.has(f):
				n.inv.remove(f)
				n.hunger = minf(100.0, n.hunger + float(GameData.item(f).food))
				w.stat("eaten_food", float(GameData.item(f).food))
				w.stat("eaten_" + f)
				break
	var hr := w.hour()
	if (hr >= float(REST_FROM) or hr < float(REST_TO)) and str(n.journey.leg) != "there":
		n.anim = "idle"
		n.doing = "resting by the road"
		return true
	return false
