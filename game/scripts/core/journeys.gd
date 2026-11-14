class_name Journeys
extends RefCounted
## REGION-NAV-01 AD-4 (owner 2026-11-02: "Envoys are physical NPCs operating within the existing world. They must travel to other
## settlements ... and return home"; "No instant inventory transfers between villages"; no fast travel): a villager walks to a
## neighbouring settlement and back along the roads, in the world's own movement (World._walk on a path laid out here).
##
## n.journey (saved, optional NPC key): {to: settlement id, purpose: {kind, ...}, leg: "out" | "there" | "back", since: day,
## gate: the village gate index}. Only that is saved: the route is a pure function of the seed (Overworld.road_route), so when the
## villager has no plan (just started, an interruption, or a loaded save whose plan had no step left; plans themselves are saved,
## TEST-AUDIT-Q1, but the walked path is laid out again) the leg goes on from where they stand
## (resume). Out: the village's own path to the south gate, then the road; there: the purpose's work at the site (purpose hook,
## World.journey_hook), else they stay till the next morning; back: the road, then the village path home. At night (20:00 to
## 6:00) a traveller rests where they are on the road (the homeless rest rule, KI-HOME-DOOR), and when hungry eats from their pack.
## A route that cannot be found fails the journey (recorded: journey_failed_no_road): refused at the start, and on the way out
## (a road closed ahead, Overworld.close_node) the traveller turns home along the road they came by (journey_ended_turned_back). Nothing
## is created or destroyed: what they carry is in their pack all the way (a death on the road leaves it where they fall).

const REST_FROM := 20
const REST_TO := 6
const EAT_BELOW := 40.0
const MARGIN_MINUTES := 720.0      # B25R1-009: food for half a day more than the walk (provision, buy_food)
const SITE_PATH_CELLS := 300       # the bound of the walk between a road's end and a place in its site (the largest site is 251 cells)


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
		record(w, n, "refused", {"to": sid, "purpose": purpose.duplicate(true), "why": "no road"})
		return "There is no road to %s." % w.map.overworld.site(sid).name
	# B42 envoy starvation (flight recorder run 43332151718, seed 1, p:168: an envoy with an empty purse set out with food for
	# one leg, could buy none at the site and starved on the road home): a round trip is provisioned for the whole way there,
	# the stay and the way home, within the same half-pantry cap; a traveller who still could not get home safely (short of
	# food and without the coins to buy what is missing at the site) is not sent. A one-way walk (ONE_WAY: a runaway, a
	# migrant) is provisioned for its one leg and never refused for food, as before (the road's hunger is theirs).
	var need := walk_minutes(w, sid, purpose)
	if not ONE_WAY.has(str(purpose.get("kind", ""))) and not fed_for(w, n, sid, purpose):
		w.stat("journey_refused_no_food")
		record(w, n, "refused", {"to": sid, "purpose": purpose.duplicate(true), "why": "no food for the road home"})
		return "%s has not the food for the road to %s and back." % [n.name, w.map.overworld.site(sid).name]
	n.journey = {"to": sid, "purpose": purpose.duplicate(true), "leg": "out", "since": w.day(), "gate": gi}
	n.plan.clear()
	provision(w, n, need)                                       # B25R1-009: food for the road from the household's pantry
	w.stat("journey_started")
	record(w, n, "started", {"from": "village", "to": sid, "purpose": purpose.duplicate(true), "trigger": str(purpose.get("kind", "visit")),
		"seed": bool(purpose.get("seed", false)), "coins": n.coins, "gate": gi})
	w.stat("journey_started_" + str(purpose.get("kind", "visit")))
	return ""


## Each update of a traveller with no plan: lay out the rest of the current leg from where they stand. Returns true while the
## journey goes on (the brain does not plan for them), false once it is over.
static func resume(w: World, n: NPC) -> bool:
	if not active(n):
		return false
	if n.journey.has("trip"):                            # B25R1-019: a settlement's resident made live on their trip or at home
		return w.regions != null and w.regions.people != null and w.regions.people.resume(n)
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
		var home_trip := trip_minutes(w, str(n.journey.to)) + MARGIN_MINUTES
		if w.hour() < float(SettlementFolk.WORK_FROM) and _short(n, home_trip) > 0.0 and n.coins > 0:
			return _rest(n)                                # B25R1-009: short of food for the road home: wait for the sellers' doors to open
		n.journey.leg = "back"
		w.stat("journey_leaving_" + str(n.journey.to))
		buy_food(w, n, home_trip)                          # B25R1-009: food for the road home, bought at the site
		leg = "back"
	var road := PackedVector2Array()
	if leg == "out":
		road = ow.road_route(int(n.journey.gate), str(n.journey.to))
		if road.is_empty():                                # the way ahead is blocked: the journey fails, recorded, and they turn home
			w.stat("journey_failed_no_road")
			n.journey.leg = "back"
			n.journey.failed = true
			leg = "back"
	if leg == "back":
		road = ow.road_route(int(n.journey.gate), str(n.journey.to), false)       # home the way they came
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
		var spot := Vector2i(st.slots[0].spot)
		var walk := _site_walk(w, Vector2i(path[path.size() - 1]) if not path.is_empty() else n.cell(), spot)
		if walk.is_empty():
			path.append(Vector2(spot))                     # no way found: a straight step, as before
		else:
			path.append_array(walk.slice(1))
	else:
		var from := road.size() - 1
		if not ow.site_at(n.cell()).is_empty():
			var walk := _site_walk(w, n.cell(), Vector2i(road[from]))
			if walk.is_empty():
				path.append(Vector2(st.gate))              # no way found: by the gate, as before
			else:
				path.append_array(walk.slice(0, walk.size() - 1))    # (the road's first cell follows)
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


## The steps between the road's end at a site and a place in it (either way), walked round the site's buildings by the world's
## collision (VillageMap.find_path_world): the road ends at the site's edge and the place may lie across the site, and a straight
## line there went through its buildings (the simulation gate's playtest probe, B25). Ends at `to`; empty when no way is found.
static func _site_walk(w: World, from: Vector2i, to: Vector2i) -> PackedVector2Array:
	var walk := w.map.find_path_world(from, to, SITE_PATH_CELLS)
	if walk.size() < 2:
		return PackedVector2Array()
	if walk[walk.size() - 1] != Vector2(to):
		walk.append(Vector2(to))
	return walk


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
	if n.journey.has("trip"):                            # B25R1-019: SettlementPeople's walker
		if w.regions != null and w.regions.people != null:
			w.regions.people.leg_done(n)
		return
	if not active(n):
		return
	match str(n.journey.leg):
		"out":
			n.journey.leg = "there"
			n.journey.arrived = w.day()
			n.journey.stay_until = float((w.day() + 1) * 1440 + REST_TO * 60)
			w.stat("journey_arrived")
			record(w, n, "arrived", {"to": str(n.journey.to), "since": int(n.journey.since)})
			w.stat("journey_arrived_" + str(n.journey.to))
		"back":
			end(w, n, "turned_back" if bool(n.journey.get("failed", false)) else "home")


static func end(w: World, n: NPC, how: String) -> void:
	w.stat("journey_ended_" + how)
	record(w, n, "ended", {"to": str(n.journey.get("to", "")), "how": how, "purpose": (n.journey.get("purpose", {}) as Dictionary).duplicate(true),
		"coins": n.coins, "at": [n.cell().x, n.cell().y]})
	if bool(n.journey.get("purpose", {}).get("seed", false)):
		w.stat("seed_travelers_ended_" + how)      # B25R1-009 (SeedTravelers)
	n.journey = {}
	n.plan.clear()


## Before each update of a traveller: rest at night where they stand (unless already at rest), and eat from their pack when
## hungry (at the site with nothing in the pack, they first buy a day's food there: buy_food). Returns true when they rest this
## update (World._update_npc skips the plan).
static func night_and_food(w: World, n: NPC) -> bool:
	if n.hunger < EAT_BELOW and str(n.journey.leg) == "there" and food_in(n.inv) <= 0.0:
		buy_food(w, n, 1440.0)
	if n.hunger < EAT_BELOW:
		for f in Decay.eat_order(NPCBrain.EDIBLE):     # MML-INV-02 F6(b): the most perishable first while INV-02 is on
			if n.inv.has(f):
				n.inv.remove(f)
				n.hunger = minf(100.0, n.hunger + float(GameData.item(f).food))
				w.stat("eaten_food", float(GameData.item(f).food))
				w.stat("eaten_" + f)
				break
	var ow: Overworld = w.map.overworld
	if ow != null and int(n.journey.get("rev", 0)) != ow.closed_rev:
		n.journey.rev = ow.closed_rev                  # a road was closed or opened: the way ahead is planned again (resume)
		if str(n.journey.leg) == "out":
			n.plan.clear()
	var hr := w.hour()
	if (hr >= float(REST_FROM) or hr < float(REST_TO)) and str(n.journey.leg) != "there":
		n.anim = "idle"
		n.doing = "resting by the road"
		return true
	return false


# ---------------------------------------------------------------- food for the road (B25R1-009) ----------
## B25R1-009 (a seed traveller's journey showed it: a traveller ate only from their pack, so one who set out with none starved
## on the road; a mechanic failing its function, fixed within the existing rules): a traveller takes food for the road from their
## household's pantry when they set off (provision), and buys food at the settlement for the road home and while they wait there
## (buy_food, from the people there who sell it, SettlementFolk.buy_from). Nothing is created: a pantry-to-pack transfer
## (World.transfer) and an ordinary purchase. What cannot be had is not had: an empty pantry, no food on sale or no coins, and
## they go hungry by the existing rules.

## Game minutes a walk to `sid` takes by the road at the walking pace, with the nights' rest (REST_FROM to REST_TO) in between.
static func trip_minutes(w: World, sid: String) -> float:
	var ow: Overworld = w.map.overworld
	if ow == null:
		return 0.0
	var tiles := float(ow.road_route(gate_index(w), sid).size())
	var per_min := float(GameData.b("walk_tiles_per_second")) / float(GameData.b("game_minutes_per_second"))
	var walk := tiles / maxf(0.01, per_min)
	var day := float(REST_FROM - REST_TO) * 60.0
	return walk + floorf(walk / day) * float(24 - REST_FROM + REST_TO) * 60.0


## Journeys that do not come back (the walker settles where they go): provisioned for the way there only.
const ONE_WAY := ["runaway", "migrate"]
const STAY_MINUTES := 1440.0       # the most a traveller waits at the site before the road home (leg_done: till the next morning)


## The game minutes of food a journey to `sid` for `purpose` is provisioned for: there (one way), else there, a stay and back.
static func walk_minutes(w: World, sid: String, purpose: Dictionary) -> float:
	var leg := trip_minutes(w, sid)
	if ONE_WAY.has(str(purpose.get("kind", ""))):
		return leg + MARGIN_MINUTES
	return 2.0 * leg + STAY_MINUTES + MARGIN_MINUTES


## Whether `n` can set out for `sid` with `purpose` and get home fed: food from the household's pantry (within provision's cap)
## and their pack, else a purse that could buy what is missing at the site (_can_buy).
static func fed_for(w: World, n: NPC, sid: String, purpose: Dictionary) -> bool:
	var short := _short_after_provision(w, n, walk_minutes(w, sid, purpose))
	return short <= 0.0 or _can_buy(n, short)


## The food points `n` would still lack for `minutes` after provision took what it may (nothing is moved: a dry run of provision).
static func _short_after_provision(w: World, n: NPC, minutes: float) -> float:
	var short := _short(n, minutes)
	if short <= 0.0 or n.household < 0 or n.household >= w.households.size():
		return short
	var pantry: Inventory = w.households[n.household].pantry
	var cap := food_in(pantry) * 0.5
	var taken := 0.0
	for f in NPCBrain.EDIBLE:
		var pts := float(GameData.item(f).get("food", 0))
		var have := pantry.count(f)
		while pts > 0.0 and have > 0 and short - taken > 0.0 and taken + pts <= cap:
			taken += pts
			have -= 1
	return maxf(0.0, short - taken)


## Whether `n`'s purse could buy `pts` food points at the site at the cheapest food's own value a point (an estimate made before
## setting out: the site's sellers may ask more, or have none, and then the traveller waits by buy_food's rules).
static func _can_buy(n: NPC, pts: float) -> bool:
	var per := INF
	for f in NPCBrain.EDIBLE:
		var fp := float(GameData.item(f).get("food", 0))
		if fp > 0.0:
			per = minf(per, float(GameData.value(f)) / fp)
	return per < INF and float(n.coins) >= ceilf(pts * per)


## Food points held in `inv` (the items a traveller eats from: NPCBrain.EDIBLE).
static func food_in(inv: Inventory) -> float:
	var pts := 0.0
	for f in NPCBrain.EDIBLE:
		pts += float(inv.count(f)) * float(GameData.item(f).get("food", 0))
	return pts


## Food points `n` eats over `minutes` of game time (hunger_per_hour), less what they hold.
static func _short(n: NPC, minutes: float) -> float:
	return minutes / 60.0 * float(GameData.b("hunger_per_hour")) * NPCBrain.food_factor(n) - food_in(n.inv)


## Setting off: take food for `minutes` on the road from the household's pantry into the pack, at most half the pantry's food
## (the household at home eats too), in NPCBrain.EDIBLE order. Returns the food points taken.
static func provision(w: World, n: NPC, minutes: float) -> float:
	if n.household < 0 or n.household >= w.households.size():
		return 0.0
	var pantry: Inventory = w.households[n.household].pantry
	var cap := food_in(pantry) * 0.5
	var taken := 0.0
	for f in NPCBrain.EDIBLE:
		var pts := float(GameData.item(f).get("food", 0))
		while pts > 0.0 and _short(n, minutes) > 0.0 and taken + pts <= cap and pantry.has(f):
			if not w.transfer(pantry, n.inv, f, 1):
				break
			taken += pts
	if taken > 0.0:
		w.stat("journey_provisioned_food", taken)
		record(w, n, "provisioned", {"food_points": taken, "from": "household %d pantry" % n.household})
	return taken


## At the site: buy food for `minutes` from the people there who sell it (cheapest a food point first), one unit at a time, while
## their coins pay. Returns the food points bought.
static func buy_food(w: World, n: NPC, minutes: float) -> float:
	if w.regions == null or not n.journey.has("to"):
		return 0.0
	var offers := []
	for q in SettlementFolk.people(w, str(n.journey.to)):
		if not SettlementFolk.present(w, q):
			continue
		for line in SettlementFolk.offers(w, q).sells:
			var pts := float(GameData.item(str(line.item)).get("food", 0))
			if NPCBrain.EDIBLE.has(str(line.item)) and pts > 0.0 and int(line.price) > 0:
				offers.append({"who": q, "item": str(line.item), "price": int(line.price), "per": float(line.price) / pts})
	offers.sort_custom(func(a, b): return a.per < b.per if a.per != b.per else str(a.item) < str(b.item))
	var got := 0.0
	var me := World.npc_ref(n.id)
	for o in offers:
		while _short(n, minutes) > 0.0 and n.coins >= int(o.price):
			if SettlementFolk.buy_from(w, me, o.who, str(o.item), 1) != "":
				break
			got += float(GameData.item(str(o.item)).food)
	if got > 0.0:
		w.stat("journey_bought_food", got)
		record(w, n, "bought_food", {"to": str(n.journey.to), "food_points": got, "coins": n.coins})
	return got


## B25R1-016 (the 365-day flight recorder campaign): every step of a journey goes to the flight recorder, when one is attached, as
## one event: started (decision, trigger, origin, destination), refused, arrived, provisioned, bought_food, bought, failed (why),
## waited, ended (home, turned_back, died, lost, no road). `n` by its stable person id (NPC.id is the Identity id, ID-01). Only
## read: nothing here changes the world. The recorder's own vocabulary call (journey_event) is defined by the recorder worker;
## until it exists the call is skipped.
static func record(w: World, n: NPC, what: String, data: Dictionary) -> void:
	if w.recorder != null and w.recorder.has_method("journey_event"):
		w.recorder.journey_event(n.id, World.npc_ref(n.id), what, data)
