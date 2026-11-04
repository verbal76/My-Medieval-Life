class_name Wilds
extends RefCounted
## B25R1-014 / B25R1-017 (owner directives 2026-11-03: docs/directives/2026-11-03_b25r1_outlaw_communities.md, the
## full-scope directive, the integration and water directive; design docs/design/HOMESTEADING_B25R1.md section 11): the life of
## the wilderness settlements that Homesteads' claims hold, lawful and outlaw alike. ONE foundation: everything here works on a
## Homesteads claim and its household, whatever its faction; the differences are the claim's faction and concealment and what
## its people choose.
##
##   water      a claim's water comes from a stream within stream_reach (Overworld.nearest_water) or a well built on it; a
##              site with neither, nor the means to dig a well, is refused (water_access). Each dawn every resident drinks
##              water_per_person from the claim's store (c.water); short: wild_shortage, thirst harm, and a homestead long
##              without water is given up (the band goes on thirsty). Adults draw water (a walk and a wait at the source).
##   works      a well, a pen or a workshop on a claim: a site of World's shape (kind, cost, need, done) fed with real materials
##              and then labour (work minutes at it); materials lying on an unfinished work are counted (goods) and go back to
##              the household when the claim is given up.
##   livestock  a claim pen is a Fauna pen (fed from the pantry's grain through the village's feed_pen act, products collected,
##              surplus slaughtered, bred by Fauna's rules); animals are bought from the manor pens' keepers (Farming's price,
##              the keeper paid) and led home.
##   crafting   a built workshop's stations serve the existing recipes through World.work_craft (skill, tools, inputs, wear,
##              Skills.gain): no outlaw bonus. Inputs come from the household's pantry; the band's members buy what they need
##              from one another (World.trade): the members-only market. Trusted outsiders trade there too (player_trade_refusal).
##   the band   (owner B25R1-Q2 option a) the bandits are a household on a concealed outlaw claim in the open country: they
##              build, fell, farm, keep livestock, craft and trade there by the same rules as any homestead. A raid is chosen at
##              dawn by the band's eldest (profile band_raid: need, opportunity, risk), walked along the road to the village
##              and back; in the village at night the existing bandit AI (NPCBrain._bandit, _prey_for, fight) does the robbing.
##   danger     countryside animals within country_radius of a lived-in claim are adopted into Fauna (Fauna.COUNTRY), so a
##              wolf may go for a lone homesteader by the fauna's own rules, near the player or not.
## Deterministic: no World.rng draw here (choices by JudgmentWeighting with keyed margins; the crafting rules' own draws are
## World.work_craft's). Saved (World "wilds"; works live in the claims, pens in Fauna). Numbers: balance.json "wilds" (agent
## proposals, provisional).

const FORMAT := "mml-wilds/1"
const NONE := Vector2i(1 << 30, 0)

var w: World
var raiders := {}          # str(npc id) -> {claim, leg: wait | out | village | back, day, coins0, goods0, hp0, night}
var last_raid := {}        # claim id -> day of its last raid
var led := {}              # animal id (str) -> npc id leading it home from the village
var counts := {}
var defended_day := {}     # claim id -> the day its defence was last recorded
var _cs: Countryside       # the countryside's ambient animals (a pure function of the seed and the clock; not saved)
var next_work := 1


func _init(world: World) -> void:
	w = world


static func cfg() -> Dictionary:
	return GameData.b("wilds")


func _count(key: String, k := 1) -> void:
	counts[key] = int(counts.get(key, 0)) + k
	w.stat("wilds_" + key, float(k))


func _rec(kind: String, data: Dictionary) -> void:
	w.homesteads._rec(kind, data)


func _hs() -> Homesteads:
	return w.homesteads


# ---------------------------------------------------------------- water --------------------------
## The water a claim laid out as `lay` can have (owner B25R1-Q3; integration directive section 6): a stream within
## stream_reach of its door step, else a well dug on it if the household can pay for its materials or win them itself (an axe for
## the logs and a pickaxe or the coins for the stone). {source: stream | well, cell, distance} or {} (no water: refused).
func water_access(lay: Dictionary, coins: int, tools: Array = []) -> Dictionary:
	var o: Overworld = w.map.overworld
	var step: Vector2i = lay.door + Vector2i(0, 1)
	var cf := cfg()
	if o != null:
		var s := o.nearest_water(step, int(cf.stream_reach))
		if s != NONE:
			return {"source": "stream", "cell": s, "distance": absi(s.x - step.x) + absi(s.y - step.y)}
	var cost: Dictionary = cf.well_cost
	var buy := {}
	for id in cost:
		if (id == "log" and tools.has("axe")) or (id == "stone" and tools.has("pickaxe")):
			continue
		buy[id] = int(cost[id])
	if w.construction.estimate(buy) > coins:
		return {}
	return {"source": "well", "cell": _well_cell_of(lay), "distance": 2}


## The well's place on a claim: beside the house, two cells right of its door step.
static func _well_cell_of(lay: Dictionary) -> Vector2i:
	return Vector2i(lay.door) + Vector2i(3, 1)


## The cell water is drawn at on claim `c` (the stream's bank or the built well), NONE when there is none yet.
func source_of(c: Dictionary) -> Vector2i:
	var src: Dictionary = c.get("water_src", {})
	if src.is_empty():
		return NONE
	if str(src.source) == "stream":
		return Vector2i(int(src.cell[0]), int(src.cell[1]))
	var wk := work_of(c, "well")
	if wk.is_empty() or not bool(wk.done):
		return NONE
	return Vector2i(int(wk.cell[0]), int(wk.cell[1]))


## A claim's source chosen when it is marked out (Homesteads._mark_site, the band's camp): recorded once.
func choose_water(c: Dictionary, acc: Dictionary) -> void:
	if acc.is_empty():
		return
	var cell: Vector2i = acc.cell
	c.water_src = {"source": str(acc.source), "cell": [cell.x, cell.y]}
	if not c.has("water"):
		c.water = 0
	_rec("water_source_selected", {"claim": str(c.id), "source": str(acc.source), "cell": [cell.x, cell.y], "distance": int(acc.distance)})
	if str(acc.source) == "well" and work_of(c, "well").is_empty():
		_new_work(c, "well", Rect2i(cell, Vector2i.ONE))


## Homesteads.act "home": back from the village, `n` brings water from the village's well in a skin (carry_units; real water of
## the village, carried by them), so a new homestead lives until its own well is dug.
func carried_home(n: NPC, c: Dictionary) -> void:
	var cf := cfg()
	var got := mini(int(cf.carry_units), int(cf.water_store) - int(c.get("water", 0)))
	if got <= 0:
		return
	c.water = int(c.get("water", 0)) + got
	_rec("water_drawn", {"claim": str(c.id), "person": n.id, "units": got, "source": "village_well"})


## Homesteads._wants_trip: a claim with no stream and no well dug yet, its store under a day's drinking: water is fetched from
## the village's well on a trip (carried_home).
func wants_water_trip(c: Dictionary) -> bool:
	if source_of(c) != NONE:
		return false
	var h := World.ref_id(str(c.owner))
	return h >= 0 and h < w.households.size() and int(c.get("water", 0)) < w.brain._members(h).size() * int(cfg().water_per_person)


## Hunting round the claim (the village's hunt act, on the open country's game adopted into Fauna round lived-in claims, Wilds
## .country_hour): by a hunter's trade, or by anyone armed when the household's food runs low. The kill's meat and hide go home
## (stow). True when it laid the plan.
func plan_hunt(n: NPC, c: Dictionary) -> bool:
	if n.role == "child":
		return false
	var trade := str((c.trades as Dictionary).get(str(n.id), c.trade))
	var armed := n.inv.has("copper_sword") or n.inv.has("iron_sword") or n.inv.has("steel_sword") or n.inv.has("bow") or n.inv.has("rusty_sword")
	if not (trade == "hunter" or (armed and w.brain.household_food_days(n.household) < float(Homesteads.cfg().food_low_days))):
		return false
	if not armed and trade != "hunter":
		return false
	var home := Vector2(Homesteads.step_of(c)) + Vector2(0.5, 0.5)
	var best: Animal = null
	var bd := float(cfg().country_radius) * 2.0
	for a: Animal in w.fauna.animals:
		if not a.alive or a.area != Fauna.COUNTRY or not a.wild() or not bool(a.spec().get("game", true)) or w.fauna.claims.has(a.id) or bool(a.spec().get("people", false)):
			continue
		var d := a.pos.distance_to(home)
		if d < bd or (is_equal_approx(d, bd) and best != null and a.id < best.id):
			bd = d
			best = a
	if best == null:
		return false
	w.fauna.claims[best.id] = n.id
	var br: NPCBrain = w.brain
	n.doing = "hunting in the country round the claim"
	n.plan = [br.go(Vector2i(best.pos.floor()), 1.1), br.work(20.0, "hunt", {"animal": best.id}, "work"), br.doit("homestead", {"step": "stow"})]
	_count("hunts")
	return true


## Each dawn: the residents drink (water_per_person each, from the claim's store); short, they go thirsty (thirst_damage),
## recorded. Returns the units short.
func _drink(c: Dictionary, members: Array) -> int:
	var cf := cfg()
	var want := members.size() * int(cf.water_per_person)
	var have := int(c.get("water", 0))
	var drunk := mini(want, have)
	c.water = have - drunk
	if drunk > 0:
		_rec("water_drunk", {"claim": str(c.id), "units": drunk, "people": members.size()})
		_rec("wild_consumption", {"claim": str(c.id), "action": "drink", "units": drunk})
	var short := want - drunk
	if short > 0:
		c.dry_days = int(c.get("dry_days", 0)) + 1
		var k := 0
		for o: NPC in members:
			if k * int(cf.water_per_person) >= drunk:
				w.harm_npc(o, float(cf.thirst_damage))
				if o.hp <= 0.0:
					w.kill(o, "thirst")
			k += 1
		_count("water_short", short)
		_rec("wild_shortage", {"claim": str(c.id), "need": "water", "short": short, "dry_days": int(c.dry_days), "source": str(c.get("water_src", {}).get("source", "none"))})
	else:
		c.dry_days = 0
	return short


# ---------------------------------------------------------------- wells (the one registry) ------
## B25R1-Q3, coordinated (lead 2026-11-03): every well in the world is one record here, whoever owns it: a claim ("claim:<id>"),
## a household ("hh:<n>") or a settlement ("settlement:<id>"). {id "wl<n>", kind "well", owner, cell [x, y], rect, cost, need,
## labour (minutes still to dig), done, day, built_day}. Built: materials (cost) delivered and the labour done (deliver_well,
## dig_well), or registered built by a caller that has itself taken `cost` from its stock (add_well built=true: the goods
## ledger counts them used_building_<item>). Saved (Wilds "wells"). Read-only lookups for other systems: well, well_at,
## wells_near, wells_of.
var wells := {}            # id -> the well record
var next_well := 1


## Register a well of `owner` at `cell`. built=false: a site still needing `cost` (default the balance's well_cost) and its
## labour; built=true: standing now, `cost` already taken from the caller's stock (counted as used in the village's ledger,
## used_building_<item>, unless `count` is false: a settlement building its own well from its own store books that use in its
## own flows, so the village's ledger is left alone). Returns the record.
func add_well(owner: String, cell: Vector2i, built := false, cost := {}, count := true) -> Dictionary:
	var c2: Dictionary = cost if not cost.is_empty() else _cost("well")
	var ints := {}
	for id in c2:
		ints[str(id)] = int(c2[id])
	var wl := {"id": "wl%d" % next_well, "kind": "well", "owner": owner, "cell": [cell.x, cell.y], "rect": [cell.x, cell.y, 1, 1], "cost": ints,
		"need": {} if built else ints.duplicate(), "labour": 0.0 if built else _labour("well"), "done": built, "day": w.day()}
	if not count:
		wl.uncounted = true                             # its cost is in its settlement's own flows, never the village's ledger
	next_well += 1
	wells[str(wl.id)] = wl
	if built:
		wl.built_day = w.day()
		if count:
			for id in ints:
				w.stat("used_building_" + str(id), float(ints[id]))
		_rec("well_built", {"owner": owner, "well": str(wl.id), "cell": [cell.x, cell.y], "cost": ints.duplicate()})
	else:
		_rec("settlement_construction", {"owner": owner, "action": "begun", "what": "well", "well": str(wl.id), "need": ints.duplicate()})
	if w.homesteads != null:
		w.homesteads._sync_overworld()
	return wl


## The well record `id`, {} none.
func well(id: String) -> Dictionary:
	return wells.get(id, {})


## The well standing or being dug at `cell`, {} none.
func well_at(cell: Vector2i) -> Dictionary:
	for id in _well_ids():
		var wl: Dictionary = wells[id]
		if int(wl.cell[0]) == cell.x and int(wl.cell[1]) == cell.y:
			return wl
	return {}


## The wells within `radius` tiles (Chebyshev) of `cell`, nearest first (ties by id); built ones only unless built_only is false.
func wells_near(cell: Vector2i, radius: int, built_only := true) -> Array:
	var out := []
	for id in _well_ids():
		var wl: Dictionary = wells[id]
		var at := Vector2i(int(wl.cell[0]), int(wl.cell[1]))
		var d := maxi(absi(at.x - cell.x), absi(at.y - cell.y))
		if d <= radius and (bool(wl.done) or not built_only):
			out.append([d, id, wl])
	out.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0] or (a[0] == b[0] and str(a[1]) < str(b[1])))
	return out.map(func(e: Array) -> Dictionary: return e[2])


## The wells of `owner` (an ownership reference), in id order.
func wells_of(owner: String) -> Array:
	return _well_ids().filter(func(id) -> bool: return str(wells[id].owner) == owner).map(func(id) -> Dictionary: return wells[id])


## Deliver materials for well `id` from `inv` (the same rule as a claim's works). True when it took any.
func deliver_well(id: String, inv: Inventory, by := "") -> bool:
	var wl := well(id)
	return not wl.is_empty() and _deliver_into(wl, inv, by, str(wl.owner))


## Dig at well `id` for `mins` minutes (its materials all in); true when it stands now.
func dig_well(id: String, mins: float, n: NPC = null) -> bool:
	var wl := well(id)
	if wl.is_empty() or bool(wl.done) or not (wl.need as Dictionary).is_empty():
		return false
	var c := _hs().claim(str(wl.owner).trim_prefix("claim:")) if str(wl.owner).begins_with("claim:") else {}
	if not c.is_empty():
		labour(c, wl, mins, n)
	else:
		wl.labour = maxf(0.0, float(wl.labour) - mins)
		if float(wl.labour) <= 0.0:
			wl.done = true
			wl.built_day = w.day()
			if not bool(wl.get("uncounted", false)):
				for k in wl.cost:
					w.stat("used_building_" + str(k), float(wl.cost[k]))
			_rec("well_built", {"owner": str(wl.owner), "well": id, "cell": wl.cell, "by": n.id if n != null else -1})
	return bool(wl.done)


## Materials lying on wells not owned by a claim (census goods, Homesteads.goods).
func loose_well_goods() -> Dictionary:
	var out := {}
	for id in _well_ids():
		var wl: Dictionary = wells[id]
		if bool(wl.done) or str(wl.owner).begins_with("claim:") or bool(wl.get("uncounted", false)):
			continue                                    # (an uncounted well's materials are its settlement's own)
		for k in wl.cost:
			var got := int(wl.cost[k]) - int((wl.need as Dictionary).get(k, 0))
			if got > 0:
				out[k] = int(out.get(k, 0)) + got
	return out


func _well_ids() -> Array:
	var ids := wells.keys()
	ids.sort_custom(func(a, b) -> bool: return int(str(a).trim_prefix("wl")) < int(str(b).trim_prefix("wl")))
	return ids


## A claim's works: its wells (the registry's) then its other works.
func _all_works(c: Dictionary) -> Array:
	return wells_of("claim:" + str(c.get("id", ""))) + (c.get("works", []) as Array)


## The player's well on their own claim (B25R1-Q3, "a well on any claim"): marked out where they stand on their claim's land, then
## the same site: stone and logs from the pack (deliver_well), then digging, player_dig_minutes a Use. Target entries for
## Homesteads.player_targets.
func player_targets(p: PlayerState, probe: Vector2) -> Array:
	var out := []
	var mine := w.player_ref(p)
	var cell := Vector2i(p.pos.floor())
	for c in _hs().claims:
		if str(c.owner) != mine or str(c.get("building", "")) == "":
			continue
		var wl := work_of(c, "well")
		if wl.is_empty():
			if Homesteads.rect_of(c).has_point(cell) and not Homesteads.house_of(c).grow(1).has_point(cell) and well_at(cell).is_empty():
				out.append({"d": 1.5, "kind": "wild_well_mark", "id": str(c.id), "label": "Mark out a well here (%s)" % _need_text(_cost("well"))})
			continue
		if bool(wl.done):
			continue
		var at := Vector2(int(wl.cell[0]), int(wl.cell[1])) + Vector2(0.5, 0.5)
		var d := at.distance_to(probe)
		if d < 1.6:
			var lab := "Your well: bring %s" % _need_text(wl.need) if not (wl.need as Dictionary).is_empty() else "Dig your well (about %d minutes of digging left)" % ceili(float(wl.labour))
			out.append({"d": d, "kind": "wild_well", "id": str(wl.id), "label": lab})
	# B25R1-010 (the player's homestead, as an NPC claim's): a pen and a workshop beside the house, then their materials and work
	for c in _hs().claims:
		if str(c.owner) != mine or str(c.get("building", "")) == "" or not Homesteads.rect_of(c).grow(4).has_point(cell):
			continue
		var open := open_work(c)
		var near_door := Vector2(Homesteads.step_of(c)).distance_to(probe) < 1.6
		if open.is_empty() or str(open.kind) == "well":
			if near_door and work_of(c, "pen").is_empty() and _pen_rect(c) != Rect2i():
				out.append({"d": 1.55, "kind": "wild_work_begin", "id": "%s|pen" % c.id, "label": "Fence a pen beside your house (%s)" % _need_text(_cost("pen"))})
			for kind in ["workshop_smithy", "workshop_carpentry"]:
				if near_door and work_of(c, kind).is_empty() and _workshop_rect(c, kind) != Rect2i():
					out.append({"d": 1.56, "kind": "wild_work_begin", "id": "%s|%s" % [c.id, kind], "label": "Mark out a %s beside your house (%s)" % [kind.trim_prefix("workshop_").replace("carpentry", "carpentry workshop"), _need_text(_cost(kind))]})
		if not open.is_empty() and str(open.kind) != "well":
			var r := Rect2i(int(open.rect[0]), int(open.rect[1]), int(open.rect[2]), int(open.rect[3]))
			var at2 := Vector2(r.position.x + r.size.x / 2, r.end.y) + Vector2(0.5, 0.5)
			var d2 := at2.distance_to(probe)
			if d2 < 1.6:
				var name := str(open.kind).trim_prefix("workshop_")
				var standing: Array = clear_rect(r) if str(open.kind).begins_with("workshop_") else []
				var lab2 := ("Your %s: bring %s" % [name, _need_text(open.need)]) if not (open.need as Dictionary).is_empty() else \
					("Your %s: fell the %d trees on its ground first" % [name, standing.size()]) if not standing.is_empty() else ("Build your %s (about %d minutes of work left)" % [name, ceili(float(open.labour))])
				out.append({"d": d2, "kind": "wild_work", "id": "%s|%s" % [c.id, open.id], "label": lab2})
	return out


## The player's verbs at a claim's pen or workshop (wild_work_begin, wild_work). "" done, else why not.
func player_work(p: PlayerState, kind: String, ref: String) -> String:
	var parts := ref.split("|")
	var c := _hs().claim(parts[0])
	if c.is_empty() or str(c.owner) != w.player_ref(p) or str(c.get("building", "")) == "":
		return "That is not your homestead."
	if kind == "wild_work_begin":
		var what := parts[1]
		var open := open_work(c)
		if not open.is_empty() and str(open.kind) != "well":
			return "Finish the %s first." % str(open.kind).trim_prefix("workshop_")
		var r := _pen_rect(c) if what == "pen" else _workshop_rect(c, what)
		if r == Rect2i() or not work_of(c, what).is_empty():
			return "There is no room for it here."
		var wk := _new_work(c, what, r)
		if what == "pen":
			wk.animal = str(cfg().pen_kinds[0])
		return ""
	var wk2 := open_work(c)
	if wk2.is_empty() or str(wk2.id) != parts[1]:
		return "There is nothing to work on here."
	if not (wk2.need as Dictionary).is_empty():
		if not deliver_work(c, p.inv, w.player_ref(p)):
			return "You carry none of what it needs: %s." % _need_text(wk2.need)
		return ""
	var r2 := Rect2i(int(wk2.rect[0]), int(wk2.rect[1]), int(wk2.rect[2]), int(wk2.rect[3]))
	if str(wk2.kind).begins_with("workshop_") and not clear_rect(r2).is_empty():
		return "Fell the trees on its ground first."
	labour(c, wk2, float(cfg().player_dig_minutes), null)
	return ""


## A player's claim workshop's stations, registered as the village's are (World.stations: the player's crafting reaches them;
## its owner the player, so leave is theirs). NPC claims craft through Wilds itself and register none.
func _register_stations(c: Dictionary, wk: Dictionary) -> void:
	if not World.is_player_ref(str(c.owner)) or not str(wk.kind).begins_with("workshop_") or not bool(wk.done):
		return
	var o := Vector2i(int(wk.rect[0]), int(wk.rect[1]))
	for s in (w.map.data.stamps[str(wk.kind)] as Dictionary).get("stations", []):
		var id := "cs_%s_%s_%s" % [c.id, wk.id, str(s.type)]
		var old: Dictionary = w.stations.get(id, {})
		w.stations[id] = {"id": id, "type": str(s.type), "building": "claim:" + str(c.id), "users": old.get("users", {}), "owner": str(c.owner), "tenant": "",
			"at": [o.x + int(s.at[0]), o.y + int(s.at[1])], "use": [o.x + int(s.use[0]), o.y + int(s.use[1])]}


static func _need_text(need: Dictionary) -> String:
	var ids: Array = need.keys()
	ids.sort()
	return ", ".join(ids.map(func(id): return "%d %s" % [int(need[id]), GameData.item_name(str(id)).to_lower()]))


## The player's verbs at a well target. "" done (and what happened is in the well's record), else why not.
func player_well(p: PlayerState, kind: String, id: String) -> String:
	if kind == "wild_well_mark":
		var c := _hs().claim(id)
		if c.is_empty() or str(c.owner) != w.player_ref(p) or not work_of(c, "well").is_empty():
			return "You cannot mark out a well here."
		add_well("claim:" + id, Vector2i(p.pos.floor()), false)
		if not c.has("water_src"):
			c.water_src = {"source": "well", "cell": [floori(p.pos.x), floori(p.pos.y)]}
		return ""
	var wl := well(id)
	if wl.is_empty() or bool(wl.done):
		return "There is no well to work on here."
	if not (wl.need as Dictionary).is_empty():
		if not deliver_well(id, p.inv, w.player_ref(p)):
			return "You carry none of what it needs: %s." % _need_text(wl.need)
		return ""
	dig_well(id, float(cfg().player_dig_minutes))
	return ""


# ---------------------------------------------------------------- works (well, pen, workshop) ----
func work_of(c: Dictionary, kind: String) -> Dictionary:
	for wk in _all_works(c):
		if str(wk.kind) == kind:
			return wk
	return {}


func _cost(kind: String) -> Dictionary:
	var cf := cfg()
	var src: Dictionary = cf.well_cost if kind == "well" else cf.pen_cost if kind == "pen" else w.construction.cost_of(kind.trim_prefix("workshop_"))
	var out := {}
	for id in src:
		out[str(id)] = int(src[id])
	return out


func _labour(kind: String) -> float:
	var cf := cfg()
	return float(cf.well_labour) if kind == "well" else float(cf.pen_labour) if kind == "pen" else float(cf.workshop_labour)


func _new_work(c: Dictionary, kind: String, rect: Rect2i) -> Dictionary:
	if not c.has("works"):
		c.works = []
	var cost := _cost(kind)
	if kind == "well":
		return add_well("claim:" + str(c.id), rect.position, false)
	var wk := {"id": "wk%d" % next_work, "kind": kind, "cell": [rect.position.x, rect.position.y], "rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y],
		"cost": cost, "need": cost.duplicate(), "labour": _labour(kind), "done": false, "day": w.day()}
	next_work += 1
	c.works.append(wk)
	_rec("settlement_construction", {"claim": str(c.id), "action": "begun", "what": kind, "need": cost.duplicate()})
	_hs()._sync_overworld()
	return wk


## The unfinished work of claim `c` that materials go to now (the first in order), {} none.
func open_work(c: Dictionary) -> Dictionary:
	for wk in _all_works(c):
		if not bool(wk.done):
			return wk
	return {}


## What the open work still needs (item -> count), for market trips (Homesteads._errand).
func work_need(c: Dictionary) -> Dictionary:
	var wk := open_work(c)
	return {} if wk.is_empty() else (wk.need as Dictionary)


## Deliver materials from `inv` to the open work (World.deliver's rule: raw-stone work takes rubble). True when it took any.
func deliver_work(c: Dictionary, inv: Inventory, by: String) -> bool:
	var wk := open_work(c)
	if wk.is_empty():
		return false
	return _deliver_into(wk, inv, by, str(c.id))


func _deliver_into(wk: Dictionary, inv: Inventory, by: String, place: String) -> bool:
	var need: Dictionary = wk.need
	if need.has("stone"):
		w.rubble_cover(inv, int(need.stone) - inv.count("stone"))
	var given := 0
	for id in need.keys():
		var k := mini(int(need[id]), inv.count(id))
		if k > 0:
			inv.remove(id, k)
			given += k
			need[id] = int(need[id]) - k
			if int(need[id]) <= 0:
				need.erase(id)
	if given > 0:
		_rec("settlement_construction", {"claim": place.trim_prefix("claim:"), "action": "materials", "what": str(wk.kind), "by": by, "loads": given, "need": need.duplicate()})
		if need.is_empty() and str(wk.kind) == "well" and w.homesteads != null:
			w.homesteads._sync_overworld()             # the stone heap is laid: the well's ring is drawn (overworld_entries)
	return given > 0


## Labour at the open work (its materials all in): `mins` of work; the work stands when its labour is done.
func labour(c: Dictionary, wk: Dictionary, mins: float, n: NPC) -> void:
	if bool(wk.done) or not (wk.need as Dictionary).is_empty():
		return
	wk.labour = maxf(0.0, float(wk.labour) - mins)
	if float(wk.labour) > 0.0:
		return
	wk.done = true
	wk.built_day = w.day()
	for id in wk.cost:
		w.stat("used_building_" + str(id), float(wk.cost[id]))
	_count("built_" + str(wk.kind))
	var kind := str(wk.kind)
	if kind == "well":
		_rec("well_built", {"claim": str(c.id), "by": n.id if n != null else -1, "cell": wk.cell, "cost": (wk.cost as Dictionary).duplicate()})
	elif kind == "pen":
		_open_pen(c, wk)
	_register_stations(c, wk)
	_rec("settlement_construction", {"claim": str(c.id), "action": "finished", "what": kind, "cost": (wk.cost as Dictionary).duplicate()})
	var built := 0
	for x in _all_works(c):
		built += 1 if bool(x.done) else 0
	if built >= 2 and str(c.get("stage", "")) != "community":
		c.stage = "community"
		_rec("settlement_construction", {"claim": str(c.id), "action": "established", "what": "community", "works": built})
	_hs()._sync_overworld()
	var what := kind.trim_prefix("workshop_").replace("_", " ").replace("carpentry", "carpentry workshop")
	w.note(("Your %s is finished." % what) if World.is_player_ref(str(c.owner)) else "%s: the %s on the claim is finished." % [_hs()._owner_name(c), what])


## Materials lying on unfinished works (item -> count).
func work_delivered(c: Dictionary) -> Dictionary:
	var out := {}
	for wk in _all_works(c):
		if bool(wk.done):
			continue
		for id in wk.cost:
			var k := int(wk.cost[id]) - int((wk.need as Dictionary).get(id, 0))
			if k > 0:
				out[id] = int(out.get(id, 0)) + k
	return out


## A claim given up or ended: what lies on its unfinished works goes into `pantry` (cancelling returns everything); the
## unfinished works are struck off, built ones stay with the land.
func strip_works(c: Dictionary, pantry: Inventory) -> Dictionary:
	var back := work_delivered(c)
	for id in back:
		pantry.add(id, int(back[id]))
	c.works = (c.get("works", []) as Array).filter(func(wk) -> bool: return bool(wk.done))
	for wl in wells_of("claim:" + str(c.id)):
		if not bool(wl.done):
			wells.erase(str(wl.id))                     # an unfinished well struck off with the claim's other unfinished works
	return back


## The overworld's drawing of the works (Homesteads._sync_overworld): a workshop by its stamp; a workshop being built by the
## frame tile; a pen by its fence (Larchrow's: _pen_entry; the gate in the bottom row; solid but for the gate) or, while it
## is being built, by its four corner posts; a well by Larchrow's one-tile stone well (well_tile) or, while it is being
## dug, by the dig (a patch of turned earth, a heap of stone beside it while materials are still owed) and then the stone ring
## of its shaft without its roof once the digging has begun. Entries with `layers` ([{cell: tile}], drawn in order) and
## `solid` ({cell: true}) are drawn and collided cell by cell (Overworld.home_building_at, OverworldView._draw_homes).
func overworld_entries(c: Dictionary) -> Array:
	var out := []
	var cf := cfg()
	for wk in _all_works(c):
		var r := Rect2i(int(wk.rect[0]), int(wk.rect[1]), int(wk.rect[2]), int(wk.rect[3]))
		var kind := str(wk.kind)
		var id := "%s_%s" % [c.id, wk.id]
		if kind == "pen":
			out.append(_pen_entry(id, r, bool(wk.done)))
		elif kind == "well" and not bool(wk.done):
			var dig := {r.position: DIG_TILE}
			var top := {}
			if not (wk.need as Dictionary).is_empty():
				top[r.position + Vector2i(1, 0)] = Farming.COZY + STONE_HEAP_TILE
			else:
				top[r.position] = int(cf.well_ring_tile)
			out.append({"id": id, "stamp": "", "rect": r, "door": r.position, "layers": [dig, top], "solid": {}})
		elif not bool(wk.done):
			out.append({"id": id, "stamp": "", "rect": r, "door": r.position, "frame": Vector2i(r.position.x + r.size.x / 2, r.end.y - 1),
				"tile": int(w.map.data.tiles.frame)})
		elif kind == "well":
			out.append({"id": id, "stamp": "", "rect": r, "door": r.position, "layers": [{r.position: int(cf.well_tile)}], "solid": {}})
		elif kind.begins_with("workshop_"):
			var st: Dictionary = w.map.data.stamps[kind]
			out.append({"id": id, "stamp": kind, "rect": r, "door": r.position + Vector2i(int(st.door[0]), int(st.door[1]))})
	return out


const DIG_TILE := 100084            # the free Puny World sheet's lone patch of bare earth (overworld dirt, row 3 col 3): the dig
const STONE_HEAP_TILE := 28 * 54 + 9   # Cozy Farm's grey stones (row 28): the stone waiting by the dig
const FENCE_H := MapView.LARCHROW + 134     # Larchrow's fence_h, fence_v and fence_gate (B25R1-Q8, docs/assets/LARCHROW_TILES.md)
const FENCE_V := MapView.LARCHROW + 135
const FENCE_GATE := MapView.LARCHROW + 136


## A pen's fence as an overworld entry (Larchrow's fence, which has no corner pieces: the sides run the full height, their
## posts closing the corners, the rails between them): the gate in the middle of the bottom row (where _open_pen puts it, its
## keeper feeding from the cell below), solid but for the gate. Unfinished: a post at each corner, open.
static func _pen_entry(id: String, r: Rect2i, done: bool) -> Dictionary:
	var gate := Vector2i(r.position.x + r.size.x / 2, r.end.y - 1)
	var tiles := {}
	var solid := {}
	for cell: Vector2i in Farming.fence_ring(r):
		var side := cell.x == r.position.x or cell.x == r.end.x - 1
		var corner := side and (cell.y == r.position.y or cell.y == r.end.y - 1)
		if not done:
			if corner:
				tiles[cell] = FENCE_V
			continue
		tiles[cell] = FENCE_GATE if cell == gate else FENCE_V if side else FENCE_H
		if cell != gate:
			solid[cell] = true
	return {"id": id, "stamp": "", "rect": r, "door": gate, "layers": [tiles], "solid": solid}


## Where a workshop of stamp `kind` could stand beside claim `c`'s house: its footprint and the ring round it open ground
## (trees grubbed or felled as for the house), off roads and other claims. Rect2i() none.
func _workshop_rect(c: Dictionary, kind: String) -> Rect2i:
	var st: Dictionary = w.map.data.stamps[kind]
	var size := Vector2i(int(st.w), int(st.h))
	var hr := Homesteads.house_of(c)
	var hs := _hs()
	var cf := Homesteads.cfg()
	for off in [Vector2i(hr.size.x + 2, 0), Vector2i(-size.x - 2, 0), Vector2i(0, hr.size.y + 3), Vector2i(hr.size.x + 2, hr.size.y + 3)]:
		var r := Rect2i(hr.position + off, size)
		var ok := true
		var trees := 0
		for y in range(r.position.y - 1, r.end.y + 1):
			for x in range(r.position.x - 1, r.end.x + 1):
				var g := hs._ground(Vector2i(x, y))
				if g == "blocked" or w.map.overworld.is_road(Vector2i(x, y)):
					ok = false
				trees += 1 if g == "tree" else 0
		if not ok or trees > int(cf.max_clear):
			continue
		for o in hs.claims:
			if o != c and Homesteads._holds_land(o) and r.intersects(Homesteads.rect_of(o).grow(int(cf.claim_gap))):
				ok = false
		if ok:
			return r
	return Rect2i()


## The pen's ground on a claim: below the house, left of the door's way.
func _pen_rect(c: Dictionary) -> Rect2i:
	var cf := cfg()
	var size := Vector2i(int(cf.pen_size[0]), int(cf.pen_size[1]))
	var hr := Homesteads.house_of(c)
	var door := Homesteads.step_of(c)
	var best := Rect2i()
	var bd := 1 << 30
	for dy in range(-size.y - 6, hr.size.y + 8):
		for dx in range(-size.x - 8, hr.size.x + 8):
			var r := Rect2i(hr.position + Vector2i(dx, dy), size)
			if r.grow(1).intersects(hr) or r.has_point(door) or r.has_point(door + Vector2i(0, 1)):
				continue
			var d := absi(r.get_center().x - door.x) + absi(r.get_center().y - door.y)
			if d >= bd:
				continue
			var ok := true
			for y in range(r.position.y, r.end.y):
				for x in range(r.position.x, r.end.x):
					var cell := Vector2i(x, y)
					if ok and (w.map.is_solid_world(cell) or w.map.overworld.is_road(cell) or w.map.in_village(cell)):
						ok = false
			if ok:
				for o in _hs().claims:
					if o != c and Homesteads._holds_land(o) and r.intersects(Homesteads.rect_of(o)):
						ok = false
			if ok:
				best = r
				bd = d
	return best


# ---------------------------------------------------------------- livestock -----------------------
func pen_of_claim(c: Dictionary) -> Dictionary:
	var wk := work_of(c, "pen")
	if wk.is_empty() or not bool(wk.done):
		return {}
	return w.fauna.pens.get("cp_%s" % str(c.id), {})


## The finished pen becomes a Fauna pen of the claim (the kind its keeper chose when the work began).
func _open_pen(c: Dictionary, wk: Dictionary) -> void:
	var id := "cp_%s" % str(c.id)
	var r := Rect2i(int(wk.rect[0]), int(wk.rect[1]), int(wk.rect[2]), int(wk.rect[3]))
	var gate := Vector2i(r.position.x + r.size.x / 2, r.end.y - 1)
	w.fauna.pens[id] = {"id": id, "kind": str(wk.get("animal", "chicken")), "x": r.position.x, "y": r.position.y, "w": r.size.x, "h": r.size.y,
		"gate": [gate.x, gate.y], "feed_at": [gate.x, gate.y + 1], "trough": 0, "owner": str(c.owner), "tenant": "", "claim": str(c.id), "products": {}}
	if World.is_player_ref(str(c.owner)):
		w.fauna.pens[id].player = true                  # the player's own pen (Farming: buying animals into it, feeding, products)
	w.fauna._cells.erase(id)
	w.fauna._cell_set.erase(id)


## Buy one animal of `sex` for the claim's pen from the manor pen of its kind (Farming's price and spare-animal rule; the coins
## go to its keeper, else the manor's treasury, as Farming.buy_animal). The animal is led home by `n` (Wilds.led). True if bought.
func buy_animal(n: NPC, c: Dictionary, sex: String) -> bool:
	var pen := pen_of_claim(c)
	if pen.is_empty() or w.fauna.count(pen.id, pen.kind) >= w.fauna.cap(pen.id, pen.kind):
		return false
	var src := w.fauna.pen_of(str(pen.kind))
	if src.is_empty() or src.get("player", false) or src.has("claim") or not (w.farm.cfg().animal_price as Dictionary).has(str(pen.kind)):
		return false
	var a: Animal = w.farm.spare_animal(src, sex)
	if a == null:
		return false
	var price: int = w.farm.animal_price(a)
	if n.coins - w.reserve_of(n) < price:
		return false
	var keeper: NPC = w.pen_keeper(src)
	var before := n.coins
	n.coins -= price
	n.spent += price
	var moves := [["p:%d" % n.id, before, n.coins]]
	if keeper != null:
		moves.append(["p:%d" % keeper.id, keeper.coins, keeper.coins + price])
		keeper.coins += price
		keeper.earned += price
	else:
		moves.append(["treasury", w.treasury, w.treasury + price])
		w.treasury += price
	a.area = str(pen.id)
	a.goal = Vector2.INF
	led[str(a.id)] = n.id
	_count("bought_" + a.species)
	_rec("livestock_change", {"claim": str(c.id), "person": n.id, "action": "bought", "species": a.species, "animal": a.id, "coins": moves, "price": price})
	w.note("%s %s buys a %s for the homestead." % [n.name, n.family, a.label().to_lower()])
	return true


## Fauna.update: an animal being led home walks at its leader's heel, moved on the world's fixed tick (lead_step real seconds:
## World.TICK where the world has one, else the same half second accumulated from Fauna's per-frame update), never per frame;
## AnimalSprite.glide draws it between the steps. `dt`: the real seconds since the last call.
func leading(a: Animal, dt := 0.0) -> bool:
	var key := str(a.id)
	if not led.has(key):
		return false
	var n := w.npc(int(led[key]))
	if n == null or not n.alive:
		led.erase(key)
		_lead_acc.erase(key)
		_settle(a)
		return true
	var acc := float(_lead_acc.get(key, lead_step())) + dt     # the first call steps at once
	if acc >= lead_step() - 0.000001:
		acc = fmod(acc, lead_step())
		var heel := n.pos - (n.facing.normalized() if n.facing != Vector2.ZERO else Vector2.DOWN) * 0.7
		if heel.distance_to(a.pos) > 0.05:
			a.facing = heel - a.pos
		a.pos = heel
	_lead_acc[key] = acc
	a.moving = true
	return true


var _lead_acc := {}        # animal id (str) -> real seconds since its last lead step (not saved: a loaded lead steps at once)


## The lead's step: World.TICK when the world runs on a fixed tick (wip/b25r1-presence), else half a second.
static func lead_step() -> float:
	return float((World as Script).get_script_constant_map().get("TICK", 0.5))


func _settle(a: Animal) -> void:
	var cs: Array = w.fauna.cells(a.area)
	if not cs.is_empty():
		a.pos = Vector2(cs[a.id % cs.size()]) + Vector2(0.5, 0.5)
	a.goal = Vector2.INF


## At home: the animals `n` led in go into the pen.
func led_home(n: NPC) -> void:
	for k in led.keys():
		if int(led[k]) != n.id:
			continue
		led.erase(k)
		_lead_acc.erase(k)
		var a: Animal = w.fauna.by_id(int(k))
		if a != null and a.alive:
			_settle(a)


## Each dawn per claim pen: births and deaths since yesterday recorded (Fauna's own rules made them).
func _herd_dawn(c: Dictionary) -> void:
	var pen := pen_of_claim(c)
	if pen.is_empty():
		return
	var now := w.fauna.count(pen.id, pen.kind)
	var was := int(c.get("herd", now))
	if now != was:
		_rec("livestock_change", {"claim": str(c.id), "action": "born" if now > was else "died", "species": str(pen.kind), "change": now - was, "now": now})
	c.herd = now


# ---------------------------------------------------------------- daily work on a claim ----------
## Homesteads.plan, for an adult at home in working hours: the claim's own work beyond the house (water, works, livestock,
## crafting). True when it laid a plan.
func plan_work(n: NPC, c: Dictionary) -> bool:
	if n.role == "child":
		return false
	var b: NPCBrain = w.brain
	var cf := cfg()
	var members: Array = b._members(n.household)
	# water: the store below a day's drinking and a source to draw from
	var src := source_of(c)
	if src != NONE and int(c.get("water", 0)) < members.size() * int(cf.water_per_person) * 2 and int(c.get("drawing", -1)) != n.id:
		c.drawing = n.id
		n.doing = "fetching water"
		n.plan = [b.go(b.beside(src, n.cell(), 0, true) if str(c.water_src.source) == "stream" else src + Vector2i(0, 1)),
			b.work(float(cf.draw_minutes), "homestead", {"step": "draw_water"}, "gather")]
		return true
	var wk0 := open_work(c)
	if str(c.status) != "built" and (wk0.is_empty() or str(wk0.kind) != "well"):
		return false                                    # (before the house stands only the well is worked on: water first)
	if str(c.status) == "built":
		_maybe_begin(n, c)
	var wk := open_work(c)
	if not wk.is_empty():
		var at := Vector2i(int(wk.cell[0]), int(wk.cell[1])) + Vector2i(0, int(wk.rect[3]))
		if not (wk.need as Dictionary).is_empty():
			for id in wk.need:
				if n.inv.has(str(id)) or (w.households[n.household].pantry as Inventory).has(str(id)) or (str(id) == "stone" and n.inv.has("rubble")):
					n.doing = "carrying materials to the %s" % str(wk.kind).trim_prefix("workshop_")
					n.plan = [b.go(at), b.doit("homestead", {"step": "deliver_work"})]
					return true
		var standing := clear_rect(Rect2i(int(wk.rect[0]), int(wk.rect[1]), int(wk.rect[2]), int(wk.rect[3]))) if str(wk.kind).begins_with("workshop_") else []
		if (wk.need as Dictionary).is_empty() and standing.is_empty():
			n.doing = "building the %s" % str(wk.kind).trim_prefix("workshop_")
			n.plan = [b.go(at), b.work(60.0, "homestead", {"step": "labour", "work": str(wk.id)}, "work", at - Vector2i(0, 1))]
			return true
		if (wk.need as Dictionary).is_empty() and n.inv.has("axe"):
			var t: Vector2i = standing[0]
			var mins := CapabilityHook.work_time(float(GameData.b("chop_minutes")), "forestry", Skills.value(n, "woodcutting", "chop_time", 1.0), n)
			n.doing = "clearing ground for the workshop"
			n.plan = [b.go(b.beside(t, n.cell(), 0, true)), b.work(mins, "chop", {"x": t.x, "y": t.y}, "work", t)]
			return true
	if _plan_pen(n, c):
		return true
	if _plan_craft(n, c):
		return true
	return false


## What the claim's people begin next, once the house stands (one open work at a time): a pen when a member keeps animals
## by trade or the band has coins for a pair; a workshop when a member has the skill of its stations.
func _maybe_begin(n: NPC, c: Dictionary) -> void:
	if not open_work(c).is_empty():
		return
	var members: Array = w.brain._members(n.household)
	var cf := cfg()
	if work_of(c, "pen").is_empty():
		var keeper := false
		var coins := 0
		for o: NPC in members:
			coins += o.coins
			var tr := str((c.trades as Dictionary).get(str(o.id), c.trade))
			keeper = keeper or tr in ["farmer", "herder", "manor_hand"]
		var kind := str(cf.pen_kinds[0])
		var price := int(w.farm.cfg().animal_price.get(kind, 99)) * 2
		if keeper or coins >= price + w.construction.estimate(_cost("pen")) + 10:
			var r := _pen_rect(c)
			if r != Rect2i():
				var wk := _new_work(c, "pen", r)
				wk.animal = kind
				return
	if work_of(c, "workshop_smithy").is_empty() and work_of(c, "workshop_carpentry").is_empty():
		var best := ""
		var lv := 0
		for o: NPC in members:
			for pair in [["smithing", "workshop_smithy"], ["leatherworking", "workshop_carpentry"], ["carpentry", "workshop_carpentry"]]:
				var l := Skills.level(o, str(pair[0]))
				if l > lv and l >= int(cf.workshop_skill):
					lv = l
					best = str(pair[1])
		if best != "":
			var r2 := _workshop_rect(c, best)
			if r2 != Rect2i():
				_new_work(c, best, r2)
			else:
				_rec("settlement_attempt_failed", {"claim": str(c.id), "reason": "terrain", "what": best})
				c.no_workshop = w.day()


## Grub what needs no axe on `rect`'s ground (Homesteads.clear_ground's rule); the mature trees still standing.
func clear_rect(rect: Rect2i) -> Array:
	return _hs().clear_rect(rect)


func _plan_pen(n: NPC, c: Dictionary) -> bool:
	var pen := pen_of_claim(c)
	if pen.is_empty():
		return false
	var b: NPCBrain = w.brain
	var at := Vector2i(int(pen.feed_at[0]), int(pen.feed_at[1]))
	var gate := Vector2i(int(pen.gate[0]), int(pen.gate[1]))
	if str(pen.tenant) == "":
		w.set_tenant(pen, World.npc_ref(n.id))
	if not w.farm.products_in(pen).is_empty():
		n.doing = "collecting from the pen"
		n.plan = [b.go(at), b.work(10.0, "collect_pen", {"pen": pen.id}, "work", gate), b.doit("homestead", {"step": "stow"})]
		return true
	var need := w.fauna.daily_need(pen)
	var pantry: Inventory = w.households[n.household].pantry
	if need > 0 and int(pen.trough) < need * 2 and (pantry.count("wheat") > need * 2 or n.inv.has("wheat")):
		var q := mini(need * 2, pantry.count("wheat") - need) if not n.inv.has("wheat") else 0
		if q > 0:
			w.transfer(pantry, n.inv, "wheat", q)
		n.doing = "feeding the animals"
		n.plan = [b.go(at), b.work(15.0, "feed_pen", {"pen": pen.id}, "work", gate)]
		return true
	var hungry_home := b.household_food_days(n.household) < 1.0
	var spare: Animal = w.fauna.surplus(pen, hungry_home)
	if spare != null and w.fauna.count(pen.id, pen.kind) > int(GameData.b("animals")[pen.kind].keep):
		n.doing = "slaughtering a %s" % str(pen.kind)
		n.plan = [b.go(at), b.work(30.0, "slaughter", {"pen": pen.id, "animal": spare.id, "why": "hunger" if hungry_home else "surplus"}, "work", gate),
			b.doit("homestead", {"step": "slaughtered", "species": str(pen.kind)})]
		return true
	return false


# ---------------------------------------------------------------- crafting ------------------------
## The stations of claim `c`'s built workshops.
func stations_of(c: Dictionary) -> Array:
	var out := []
	for wk in _all_works(c):
		if bool(wk.done) and str(wk.kind).begins_with("workshop_"):
			for s in (w.map.data.stamps[str(wk.kind)] as Dictionary).get("stations", []):
				out.append(str(s.type))
	return out


## A recipe worth making now at the claim's workshop: gear a member lacks (a weapon, armour, an axe or pickaxe), else what is
## worth more than its inputs and the household holds little of; inputs from the crafter's pack and the pantry; the crafter's
## skill, level and tools by World.work_craft's own rule. "" none.
func craft_pick(n: NPC, c: Dictionary) -> String:
	var st := stations_of(c)
	if st.is_empty():
		return ""
	var pantry: Inventory = w.households[n.household].pantry
	var members: Array = w.brain._members(n.household)
	var lacking := {}
	for o: NPC in members:
		if o.role == "child":
			continue
		if not (o.inv.has("copper_sword") or o.inv.has("iron_sword") or o.inv.has("steel_sword")):
			lacking["weapon"] = true
		for t in ["axe", "pickaxe"]:
			if not o.inv.has(t):
				lacking[t] = true
	var best := ""
	var best_v := -1.0
	var ids: Array = GameData.recipes.keys()
	ids.sort()
	for rid in ids:
		var r: Dictionary = GameData.recipes[rid]
		if not st.has(str(r.get("station", ""))) or Skills.level(n, str(r.skill)) < int(r.level) or w.craft_tool(n, rid) == "-":
			continue
		var ok := true
		var cost := 0.0
		for id in r["in"]:
			if n.inv.count(id) + pantry.count(id) < int(r["in"][id]):
				ok = false
			cost += GameData.value(str(id)) * float(r["in"][id])
		if not ok:
			continue
		var v := 0.0
		for id in r.out:
			var item := str(id)
			v += GameData.value(item) * float(r.out[id])
			if (lacking.has("weapon") and item.ends_with("_sword")) or lacking.has(item):
				v += 1000.0
			if pantry.count(item) + n.inv.count(item) >= 3:
				v -= 500.0
		if v - cost > best_v and v > cost:
			best_v = v - cost
			best = rid
	return best


func _plan_craft(n: NPC, c: Dictionary) -> bool:
	var rid := craft_pick(n, c)
	if rid == "":
		return false
	var b: NPCBrain = w.brain
	var r: Dictionary = GameData.recipes[rid]
	var pantry: Inventory = w.households[n.household].pantry
	for id in r["in"]:
		var short := int(r["in"][id]) - n.inv.count(id)
		if short > 0:
			w.transfer(pantry, n.inv, str(id), short)
	var at := Homesteads.step_of(c)
	for wk in _all_works(c):
		if bool(wk.done) and str(wk.kind).begins_with("workshop_"):
			var st: Dictionary = w.map.data.stamps[str(wk.kind)]
			at = Vector2i(int(wk.rect[0]), int(wk.rect[1])) + Vector2i(int(st.door[0]), int(st.door[1]) - 1)
	n.doing = "working at the %s" % GameData.item_name(str(r.out.keys()[0])).to_lower()
	n.plan = [b.go(at), b.work(float(cfg().craft_minutes), "homestead", {"step": "wild_craft", "recipe": rid})]
	return true


func _craft(n: NPC, c: Dictionary, rid: String) -> bool:
	var r: Dictionary = GameData.recipes[rid]
	var skill := str(r.skill)
	var lv := Skills.level(n, skill)
	var before := {}
	for id in r["in"]:
		before[str(id)] = n.inv.count(str(id))
	for id in r.out:
		before[str(id)] = n.inv.count(str(id))
	var res: Dictionary = w.work_craft(n, rid, n.inv)
	if str(res.result) != "ok":
		_count("craft_refused_" + str(res.result))
		return false
	var items := []
	for id in before:
		var now := n.inv.count(str(id))
		if now != int(before[id]):
			items.append(["p:%d" % n.id, str(id), int(before[id]), now])
	_count("crafted")
	_rec("wild_craft", {"claim": str(c.id), "person": n.id, "recipe": rid, "summary": items, "faction": str(c.get("faction", "lawful"))})
	var lv2 := Skills.level(n, skill)
	if lv2 != lv:
		_rec("skill_progress", {"claim": str(c.id), "person": n.id, "skill": skill, "summary": [["p:%d" % n.id, "skill:" + skill, lv, lv2]]})
	_members_market(n, c)
	return true


## The members-only market: a member who lacks a weapon (or an axe, a pickaxe) buys one the crafter just made, at the village's
## price, through World.trade (the one transaction rule); one who cannot pay goes without.
func _members_market(maker: NPC, c: Dictionary) -> void:
	for o: NPC in w.brain._members(maker.household):
		if o == maker or o.role == "child":
			continue
		for id in maker.inv.ids():
			var item := str(id)
			var want := (item.ends_with("_sword") and not (o.inv.has("copper_sword") or o.inv.has("iron_sword") or o.inv.has("steel_sword"))) or \
				(item in ["axe", "pickaxe"] and not o.inv.has(item))
			if not want:
				continue
			var price := w.sell_price(maker, item)
			if o.coins >= price and w.trade(o, maker, item, 1, price):
				_count("members_trade")
				_rec("wild_trade", {"claim": str(c.id), "by": maker.id, "to": "p:%d" % o.id, "item": item, "qty": 1, "summary": [["p:%d" % o.id, "coins", o.coins + price, o.coins]],
					"members_only": true})
				break


## Whether player `p` may trade with `seller` at an outlaw claim (members-only: the band trades with its own and with trusted
## outsiders only): "" if they may, else why not.
func player_trade_refusal(p: PlayerState, seller: NPC) -> String:
	var c := _hs().claim_of(seller)
	if c.is_empty() or str(c.get("faction", "lawful")) != "outlaw" or not _hs().remote(seller):
		return ""
	if w.judgment == null:
		return "They trade with their own here."
	var disp := int(w.judgment.disposition(seller.id, w.person_id(p)))
	return "" if disp >= int(cfg().trust_at) else "They trade with their own here, and with friends they trust. You are neither yet."


# ---------------------------------------------------------------- acts --------------------------
## Homesteads.act's steps of the claim's own work.
func act(n: NPC, c: Dictionary, step: String, a: Dictionary) -> bool:
	match step:
		"draw_water":
			if int(c.get("drawing", -1)) == n.id:
				c.erase("drawing")
			if source_of(c) == NONE:
				return false
			var cf := cfg()
			var cap := int(cf.water_store)
			var got := mini(int(cf.draw_units), cap - int(c.get("water", 0)))
			if got <= 0:
				return true
			c.water = int(c.get("water", 0)) + got
			_rec("water_drawn", {"claim": str(c.id), "person": n.id, "units": got, "source": str(c.water_src.source)})
			_rec("wild_production", {"claim": str(c.id), "action": "water", "units": got})
			return true
		"deliver_work":
			var pantry: Inventory = w.households[n.household].pantry
			var wk := open_work(c)
			if not wk.is_empty():
				for id in (wk.need as Dictionary).keys():
					var k := mini(int(wk.need[id]) - n.inv.count(str(id)), pantry.count(str(id)))
					if k > 0:
						w.transfer(pantry, n.inv, str(id), k)
			return deliver_work(c, n.inv, World.npc_ref(n.id))
		"labour":
			var wk2 := open_work(c)
			if wk2.is_empty() or str(wk2.id) != str(a.get("work", "")):
				return false
			labour(c, wk2, 60.0, n)
			return true
		"wild_craft":
			return _craft(n, c, str(a.get("recipe", "")))
		"stow":
			_hs()._unpack(n, c)
			return true
		"slaughtered":
			_rec("livestock_change", {"claim": str(c.id), "person": n.id, "action": "slaughtered", "species": str(a.get("species", ""))})
			_rec("wild_production", {"claim": str(c.id), "action": "livestock", "person": n.id})
			_hs()._unpack(n, c)
			return true
		"raid_in":
			var r: Dictionary = raiders.get(str(n.id), {})
			if not r.is_empty() and w.map.in_village(n.cell()):
				r.leg = "village"
			return true
		"raid_home":
			_raid_home(n, c)
			_hs()._unpack(n, c)
			return true
	return false


## Homesteads._errand, at the village market: a pair of animals for the claim pen, then what the open work needs.
func errand(n: NPC, c: Dictionary, trip: Dictionary) -> bool:
	var tried: Dictionary = trip.tried
	var pen := pen_of_claim(c)
	if not pen.is_empty() and not tried.has("animal"):
		tried.animal = true
		for sex in ["f", "m"]:
			var have := false
			for a: Animal in w.fauna.animals:
				have = have or (a.alive and a.area == str(pen.id) and a.sex == sex)
			if not have and buy_animal(n, c, sex):
				break
	var need := work_need(c)
	var b: NPCBrain = w.brain
	for id in ["plank", "building_block", "log", "stone", "iron_bar"]:
		if not need.has(id) or tried.has("work_" + id):
			continue
		tried["work_" + id] = true
		if (id == "log" and n.inv.has("axe")) or (id == "stone" and n.inv.has("pickaxe")):
			continue
		var want := int(need[id]) - n.inv.count(id)
		if want <= 0:
			continue
		var s := _hs()._material_seller(id, n)
		var q := b.buy_qty(n, s, id, want) if s != null else 0
		if q > 0:
			n.doing = "buying %s for the claim" % GameData.item_name(id).to_lower()
			n.plan = [b.go(b._workplace_cell(s)), b.doit("buy_from", {"vendor": s.id, "item": id, "qty": q})]
			return true
	return false


# ---------------------------------------------------------------- the band ----------------------
## The household of the band (the outlaws' wilderness settlement), -1 none.
func band_household() -> int:
	for h in w.households.size():
		var hh: Dictionary = w.households[h]
		if hh.get("band", false) and not hh.get("ended", false):
			return h
	return -1


func band_claim() -> Dictionary:
	var h := band_household()
	return _hs().claim_of_household(h) if h >= 0 else {}


## The bandits and clan children not (yet) of a household: the old village-camp band, new arrivals from the road.
func _homeless_band() -> Array:
	var out := []
	for o: NPC in w.npcs:
		if o.alive and (o.role == "bandit" or o.clan == "bandit") and (o.household < 0 or o.household >= w.households.size()):
			out.append(o)
	return out


## The band moves to the wild (owner B25R1-Q2 option a): the band becomes a household of its own on a concealed outlaw claim in
## the open country, found by the same site search as any homestead (outlaw: off the road, in cover, water to be had). Its
## people walk there; nothing is made for them (the house is a frame to be built). `why`: setup (a new world), load (an older
## save, band_migrated_on_load) or arrival (outlaws in from the road), or "rejoin". Returns the claim, {} when none was possible.
func found_band(why: String) -> Dictionary:
	var o: Overworld = w.map.overworld
	var people := _homeless_band()
	if o == null or people.is_empty():
		return {}
	var h := band_household()
	var c := band_claim()
	if h < 0:
		c = _reopen_camp()
		if not c.is_empty():
			h = World.ref_id(str(c.owner))
	if h < 0:
		var leader: NPC = people[0]
		for p: NPC in people:
			if p.role == "bandit" and (leader.role != "bandit" or p.born < leader.born):
				leader = p
		var coins := 0
		for p: NPC in people:
			coins += p.coins
		var site := _hs().find_site(leader, true, coins)
		if site.is_empty():
			_rec("settlement_attempt_failed", {"person": leader.id, "reason": "no_site", "what": "band_camp", "why": why})
			_count("band_no_site")
			return {}
		h = w.households.size()
		w.households.append({"id": h, "family": "Outlaw", "home": "", "members": [], "pantry": Inventory.new(), "founded_day": w.day(), "band": true})
		c = _hs()._new_claim(World.hh_ref(h), site.lay, leader.id, "intended")
		c.anchor = site.anchor
		c.why = str(site.why)
		c.path = "band"
		c.origin = -1
		w.households[h].homestead = str(c.id)
		_hs().set_faction(c, "outlaw", true, "the band's camp")
		_hs()._mark_site(c)
		_hs().clear_ground(c)
		c.stage = "build"
		choose_water(c, site.get("water", {}))
		_rec("settlement_created", {"claim": str(c.id), "path": "outlaw", "faction": "outlaw", "why": why})
	for p: NPC in people:
		p.household = h
		p.home = ""
		p.plan.clear()
		(w.households[h].members as Array).append(p.id)
		if not (c.members as Array).has(p.id):
			c.members.append(p.id)
	var was := w.bandit_camp
	w.bandit_camp = Homesteads.step_of(c)
	_count("band_" + why)
	var kind := "band_migrated_on_load" if why == "load" else "band_relocated"
	_rec(kind, {"claim": str(c.id), "household": World.hh_ref(h), "people": people.map(func(p: NPC) -> int: return p.id), "from": [was.x, was.y],
		"site": [c.x, c.y], "why": why, "faction": "outlaw"})
	if why != "setup":
		w.note("The outlaws make their camp in the wild country, away from the village.")
	return c


## An abandoned band camp (its house standing) taken up again by newcomers: the same claim, buildings and history, a new
## household. {} none.
func _reopen_camp() -> Dictionary:
	for c in _hs().claims:
		if str(c.get("path", "")) != "band" or str(c.status) != "abandoned" or str(c.get("building", "")) == "":
			continue
		if _hs().refusal(Homesteads.rect_of(c), str(c.id)) == "A road runs here: land by the road is for everybody.":
			continue
		var h := w.households.size()
		w.households.append({"id": h, "family": "Outlaw", "home": "", "members": [], "pantry": Inventory.new(), "founded_day": w.day(), "band": true,
			"homestead": str(c.id)})
		c.owner = World.hh_ref(h)
		c.status = "built"
		c.stage = "live"
		c.members = []
		c.poor_days = 0
		_hs().set_faction(c, "outlaw", true, "outlaws took up the old camp")
		_rec("settlement_occupancy", {"claim": str(c.id), "action": "reoccupied", "household": World.hh_ref(h)})
		_hs()._claim_cache.clear()
		_hs()._sync_overworld()
		return c
	return {}


## World.load_dict: an older save's band still lives at the village camp: the camp claim is made now and the band walks there
## (never losing a bandit, an item or a coin: they carry what they had).
func migrate_on_load() -> void:
	if band_household() >= 0 or _homeless_band().is_empty():
		return
	found_band("load")


## Where a bandit's camp is for the bandit AI (NPCBrain._bandit, fight's retreat, _prey_for): a raider in the village keeps to
## the old camp ground by the village (World.village_camp) as the band always did; otherwise the band's own camp.
func camp_for(n: NPC) -> Vector2i:
	if raiders.has(str(n.id)) and w.map.in_village(n.cell()):
		return w.village_camp
	return w.bandit_camp


## Members of outlaw claims who are bandits, by claim.
func _outlaw_claims() -> Array:
	var out := []
	for c in _hs().claims:
		if str(c.status) == "abandoned" or str(c.get("faction", "")) != "outlaw":
			continue
		var h := World.ref_id(str(c.owner))
		if h < 0 or h >= w.households.size():
			continue
		out.append(c)
	return out


## Each dawn, per outlaw claim with fit bandits: the eldest weighs a raid tonight (JudgmentWeighting, profile band_raid):
## the claim's need (food, coins), the village's opportunity (coins carried by its people) and risk (guards, the band's wounded
## and dead). Nobody is made to raid; a fed, prosperous camp seldom does.
func _raid_dawn() -> void:
	if w.judgment == null or not JudgmentLive.on(w, "band_raid"):
		return
	var cf := cfg()
	for c in _outlaw_claims():
		var h := World.ref_id(str(c.owner))
		var members: Array = w.brain._members(h)
		var band := members.filter(func(o: NPC) -> bool: return o.role == "bandit")
		if band.is_empty() or w.day() - int(last_raid.get(str(c.id), -99)) < int(cf.raid_gap_days):
			continue
		var fit := band.filter(func(o: NPC) -> bool: return o.hp >= o.max_hp * float(cf.raid_fit) and not raiders.has(str(o.id)) and o.target == -1)
		if fit.is_empty():
			continue
		var leader: NPC = band[0]
		for o: NPC in band:
			if o.born < leader.born:
				leader = o
		var food: float = w.brain.household_food_days(h)
		var coins := 0
		for o: NPC in members:
			coins += o.coins
		var guards := 0
		var purse := 0
		var folk := 0
		for o: NPC in w.npcs:
			if o.alive and o.job == "guard":
				guards += 1
			elif o.alive and o.role == "adult" and not _hs().away(o):
				purse += o.coins
				folk += 1
		var wounded := band.filter(func(o: NPC) -> bool: return o.hp < o.max_hp * 0.7).size()
		var cands := [{"id": "stay", "factors": {"live_order": 100000, "fed": LifeDecisions._clamp(minf(food / 4.0, 1.0) * 100000.0),
				"risk": LifeDecisions._clamp(minf(float(guards) / 6.0, 1.0) * 60000.0 + float(wounded) / float(band.size()) * 40000.0)}},
			{"id": "raid", "factors": {"need": LifeDecisions._clamp((1.0 - minf(food / 3.0, 1.0)) * 70000.0 + (30000.0 if coins < members.size() * 10 else 0.0)),
				"opportunity": LifeDecisions._clamp(minf(float(purse) / float(maxi(1, folk) * 30), 1.0) * 100000.0),
				"strength": LifeDecisions._clamp(float(fit.size()) / float(band.size()) * 100000.0)}}]
		var r := JudgmentWeighting.choose(w.judgment, w.judgment.cfg, leader.id, "band_raid", cands, [w.day(), leader.id, 5])
		var pick := str(r.chosen) if r.chosen != null else "stay"
		_count("raid_weighed")
		if pick != "raid":
			continue
		fit.sort_custom(func(a: NPC, b: NPC) -> bool: return a.hp > b.hp or (a.hp == b.hp and a.id < b.id))
		var keep := mini(int(cf.raid_keep_home), band.size() - 1)
		var go := fit.slice(0, maxi(1, fit.size() - maxi(0, keep - (band.size() - fit.size()))))
		last_raid[str(c.id)] = w.day()
		for o: NPC in go:
			raiders[str(o.id)] = {"claim": str(c.id), "leg": "wait", "day": w.day(), "coins0": o.coins, "goods0": o.inv.total(), "hp0": o.hp, "night": false}
		_count("raids")
		_rec("raid", {"claim": str(c.id), "person": leader.id, "action": "set_out", "raiders": go.map(func(o: NPC) -> int: return o.id), "food_days": snappedf(food, 0.1),
			"target": "village", "outcome": "ok"})


## Homesteads.plan, before anything else: a raider's legs (wait for the afternoon, the road to the village, the night's robbing by
## the band's own AI, the road home). True when it laid the plan (or the bandit AI did).
func plan_first(n: NPC, c: Dictionary) -> bool:
	var r: Dictionary = raiders.get(str(n.id), {})
	if r.is_empty():
		return false
	var hr := w.hour()
	var night := hr >= 21.0 or hr < 4.5
	match str(r.leg):
		"wait":
			if hr < float(cfg().raid_from_hour) and not night:
				return false
			r.leg = "out"
			return plan_first(n, c)
		"out":
			if w.map.in_village(n.cell()):
				r.leg = "village"
				return plan_first(n, c)
			var gate: Vector2i = _hs()._gate_cells()[1]
			if not night and n.cell().distance_to(gate) <= float(cfg().raid_lie_low):
				var b0: NPCBrain = w.brain
				n.doing = "lying low by the road till dark"        # outside the village, out of the guards' rounds, as the old camp was
				n.plan = [b0.wait(n, 30.0)]
				return true
			_lay_raid(n, c, true)
			return true
		"village":
			if not w.map.in_village(n.cell()):
				r.leg = "out"
				_lay_raid(n, c, true)
				return true
			var gained := n.coins > int(r.coins0) or n.inv.total() > int(r.goods0)
			if gained or (bool(r.night) and not night) or n.hp < float(r.hp0) * 0.5:
				r.leg = "back"
				_lay_raid(n, c, false)
				return true
			if night:
				r.night = true
				w.brain._bandit(n, hr)
				if n.plan.is_empty() and n.target == -1:
					n.plan = [w.brain.wait(n, 20.0)]
				return true
			r.leg = "back"                                # in the village by daylight: not the plan; home again
			_lay_raid(n, c, false)
			return true
		_:
			_lay_raid(n, c, false)
			return true
	return false


func _lay_raid(n: NPC, c: Dictionary, out: bool) -> void:
	var hs := _hs()
	if out:
		var road := hs._road(str(c.anchor.get("sid", "")))
		var path := hs._path_village(n, road, int(c.anchor.get("i", -1)))
		var hr := w.hour()
		if not (hr >= 21.0 or hr < 4.5):
			var gate: Vector2i = hs._gate_cells()[1]
			while path.size() > 1 and Vector2i(path[path.size() - 1]).distance_to(gate) < float(cfg().raid_lie_low) - 2.0:
				path.remove_at(path.size() - 1)             # by day the walk stops short of the gate, to lie low till dark
		hs._lay(n, path, "raid_in", "on the road to the village by night")
	else:
		hs._lay(n, hs._path_home(n, c), "raid_home", "slipping back to the camp")


## A raider home again: the raid's take restated (the robbery's own events hold the moves: summary only), and whether the village
## turned them back (raid_defended).
func _raid_home(n: NPC, c: Dictionary) -> void:
	var r: Dictionary = raiders.get(str(n.id), {})
	if r.is_empty():
		return
	raiders.erase(str(n.id))
	var dc := n.coins - int(r.coins0)
	var dg := n.inv.total() - int(r.goods0)
	var ok := dc > 0 or dg > 0
	_count("raid_" + ("ok" if ok else "empty"))
	_rec("raid", {"claim": str(c.id), "person": n.id, "action": "returned", "outcome": "ok" if ok else "failed", "reason": "" if ok else "nothing_taken",
		"summary": [["p:%d" % n.id, "coins", int(r.coins0), n.coins], ["p:%d" % n.id, "goods", int(r.goods0), n.inv.total()]], "target": "village"})
	if not ok and n.hp < float(r.hp0) - 1.0:
		_rec("raid_defended", {"claim": str(c.id), "person": n.id, "place": "village", "outcome": "ok", "reason": "repelled", "hp": [snappedf(float(r.hp0), 0.1), snappedf(n.hp, 0.1)]})
	led_home(n)


## Hourly: a band member at its camp fighting someone not of the band is its camp defended (recorded once a day a claim).
func _defence_hour() -> void:
	for c in _outlaw_claims():
		if int(defended_day.get(str(c.id), -1)) == w.day():
			continue
		var land := Homesteads.rect_of(c).grow(6)
		for o: NPC in w.brain._members(World.ref_id(str(c.owner))):
			if o.target == -1 or not land.has_point(o.cell()):
				continue
			var foe = w.player_of_id(o.target) if Life.is_player_id(o.target) else w.npc(o.target)
			if foe == null or (foe is NPC and (foe.role == "bandit" or foe.clan != "")):
				continue
			defended_day[str(c.id)] = w.day()
			_rec("raid_defended", {"claim": str(c.id), "person": o.id, "place": "homestead:" + str(c.id), "outcome": "ok", "reason": "camp_defended",
				"foe": ("player" if foe is PlayerState else "p:%d" % foe.id)})
			break


# ---------------------------------------------------------------- remote danger -----------------
## Hourly: the countryside's animals within country_radius of a lived-in claim become real animals of the fauna (Fauna.COUNTRY,
## B25R1-002's rule, which the player's nearness alone triggered before), and an adopted animal that is unharmed and far from every
## claim and player goes back to the countryside. A dead one stays gone (World.country_taken).
func country_hour() -> void:
	if w.map.overworld == null:
		return
	if _cs == null:
		_cs = Countryside.new(w.map.overworld)
	_cs.taken = w.country_taken
	var r := float(cfg().country_radius)
	var centers := claim_centers()
	for key in w.country_taken.keys():
		var id := int(w.country_taken[key])
		if id < 0:
			continue
		var a: Animal = w.fauna.by_id(id)
		if a == null or not a.alive:
			w.country_taken[key] = -1
			continue
		if a.anger == "" and a.hp >= float(a.spec().hp) - 0.01 and not near(centers, a.pos, r * 2.0) and w.nearest_player_distance(a.pos) > w.detail_radius + 10.0:
			w.fauna.animals.erase(a)
			w.country_taken.erase(key)
	for at: Vector2 in centers:
		for amb: Animal in _cs.animals_near(at, r, w.minutes):
			var real := w.fauna.adopt_country(amb.species, amb.sex, amb.skin, amb.pos)
			real.facing = amb.facing
			w.country_taken[str(amb.id)] = real.id
			_count("country_adopted")


## The middle of each lived-in claim (its door step).
func claim_centers() -> Array:
	var out := []
	for c in _hs().claims:
		if str(c.status) == "abandoned" or World.is_player_ref(str(c.owner)):
			continue
		if not (c.members as Array).is_empty():
			out.append(Vector2(Homesteads.step_of(c)) + Vector2(0.5, 0.5))
	return out


static func near(centers: Array, p: Vector2, r: float) -> bool:
	for at: Vector2 in centers:
		if at.distance_to(p) <= r:
			return true
	return false


## Fauna.update: whether animal `a` (of the countryside) is near enough a lived-in claim to be simulated there (moving,
## hunting people) as near the player.
func active_near(a: Animal) -> bool:
	return a.area == Fauna.COUNTRY and near(claim_centers(), a.pos, float(cfg().country_radius) * 2.0)


# ---------------------------------------------------------------- discovery ----------------------
## Landmarks.all: the hidden places of outlaw claims (a workshop, the camp of an outlaw homestead) as landmarks the player finds
## on foot (Landmarks.note, from discover_hidden tiles when concealed); the band's own camp is Landmarks' "bandit_camp".
func landmarks() -> Array:
	var out := []
	var see := int(Homesteads.cfg().discover_hidden)
	var band := str(band_claim().get("id", ""))
	for c in _outlaw_claims():
		var hidden := bool(c.get("concealed", false))
		if str(c.id) != band:
			out.append({"id": "outlaw:" + str(c.id), "kind": "camp", "name": "Outlaw homestead", "at": Homesteads.step_of(c), "see": see if hidden else Landmarks.SEE})
		for wk in _all_works(c):
			if bool(wk.done) and str(wk.kind).begins_with("workshop_"):
				out.append({"id": "workshop:%s:%s" % [c.id, wk.id], "kind": "workshop", "name": "Hidden " + str(wk.kind).trim_prefix("workshop_") if hidden else str(wk.kind).trim_prefix("workshop_").capitalize(),
					"at": Vector2i(int(wk.rect[0]), int(wk.rect[1])) + Vector2i(int(wk.rect[2]) / 2, int(wk.rect[3])), "see": see if hidden else Landmarks.SEE})
	return out


# ---------------------------------------------------------------- allegiance ---------------------
## Homesteads.dawn, a lawful household out of food and coin for starve_days: before giving up, its adults weigh living outside
## the law on their land (profile outlaw_turn) against going back. Outlaw: they become outlaws themselves (role bandit; their
## children of the clan): the same people, household, claim and buildings; the claim's faction follows (Homesteads._allegiance).
## True when they turned.
func weigh_turn(c: Dictionary, h: int) -> bool:
	if w.judgment == null or not JudgmentLive.on(w, "outlaw_turn") or str(c.get("faction", "lawful")) != "lawful" or str(c.get("building", "")) == "":
		return false
	var members: Array = w.brain._members(h)
	var adults := members.filter(func(o: NPC) -> bool: return o.role == "adult")
	if adults.is_empty():
		return false
	var head: NPC = adults[0]
	for o: NPC in adults:
		if o.born < head.born:
			head = o
	var kin := 0
	for pid in [head.mother, head.father] + (head.children as Array):
		var k := w.npc(int(pid)) if int(pid) >= 0 else null
		if k != null and k.alive and not _hs().away(k):
			kin += 1
	var cands := [{"id": "return", "factors": {"live_order": 100000, "kin": LifeDecisions._clamp(minf(float(kin) / 3.0, 1.0) * 100000.0)}},
		{"id": "outlaw", "factors": {"hardship": LifeDecisions._clamp(float(c.poor_days) / 6.0 * 100000.0), "home": 100000 if str(c.get("building", "")) != "" else 0,
			"isolation": LifeDecisions._clamp(float(int(c.anchor.get("i", 0))) / 200.0 * 100000.0)}}]
	var r := JudgmentWeighting.choose(w.judgment, w.judgment.cfg, head.id, "outlaw_turn", cands, [w.day(), head.id, 6])
	var pick := str(r.chosen) if r.chosen != null else "return"
	_count("turn_weighed")
	_rec("faction_changed" if pick == "outlaw" else "homestead_sustain", {"claim": str(c.id), "person": head.id, "chosen": pick, "faction_before": "homestead:" + str(c.id),
		"faction": "outlaw" if pick == "outlaw" else "homestead:" + str(c.id), "legal_before": "lawful", "legal": "outlaw" if pick == "outlaw" else "lawful",
		"outcome": "ok" if pick == "outlaw" else "failed", "reason": "turned_outlaw" if pick == "outlaw" else "weighed_outlaw_life"})
	if pick != "outlaw":
		return false
	for o: NPC in members:
		if o.role == "adult":
			o.role = "bandit"
			o.job = ""
		elif o.role == "child":
			o.clan = "bandit"
		JudgmentLive.on_news(w, "turned_outlaw", "npc:%d" % o.id, [], o.pos)
	c.poor_days = 0
	c.path = "outlaw"
	_count("turned_outlaw")
	_hs()._allegiance(c, members)
	w.note("The %s household, starving on its land, turns to living outside the law." % str(w.households[h].family))
	return true


# ---------------------------------------------------------------- daily ---------------------------
## Each dawn (World._new_day, after Homesteads.dawn): every lived-in claim drinks and counts its herd; outlaws weigh raids;
## raiders lost on the way are struck off.
func dawn() -> void:
	for k in raiders.keys():
		var o := w.npc(int(k))
		if o == null or not o.alive or o.role != "bandit":
			var r: Dictionary = raiders[k]
			raiders.erase(k)
			_rec("raid", {"claim": str(r.claim), "person": int(k), "action": "ended", "outcome": "failed", "reason": "died" if o == null or not o.alive else "left_band", "target": "village"})
		elif str(raiders[k].leg) != "back" and w.day() > int(raiders[k].day) + 1:
			raiders[k].leg = "back"              # a raid lasts one night: the road home
	for c in _hs().claims:
		if str(c.status) == "abandoned" or World.is_player_ref(str(c.owner)):
			continue
		var h := World.ref_id(str(c.owner))
		if h < 0 or h >= w.households.size() or w.households[h].get("ended", false):
			continue
		var members: Array = w.brain._members(h)
		if members.is_empty():
			continue
		if not c.has("water_src"):
			var coins := 0
			for o: NPC in members:
				coins += o.coins
			choose_water(c, water_access({"door": Homesteads.door_of(c)}, coins + 1000, []))     # an older claim: a stream, else a well to dig
		_drink(c, members)
		_herd_dawn(c)
	_raid_dawn()
	if band_household() < 0 and not _homeless_band().is_empty():
		found_band("arrival")


## Each game hour (World._on_hour).
func hour() -> void:
	country_hour()
	_defence_hour()


func report() -> Dictionary:
	var built := {}
	var water := 0
	for c in _hs().claims:
		water += int(c.get("water", 0))
		for wk in _all_works(c):
			if bool(wk.done):
				built[str(wk.kind)] = int(built.get(str(wk.kind), 0)) + 1
	var bc := band_claim()
	return {"band_claim": str(bc.get("id", "")), "band_status": str(bc.get("status", "")), "works": built, "water": water, "raiders": raiders.size(),
		"counts": counts.duplicate()}


func to_dict() -> Dictionary:
	return {"format": FORMAT, "wells": wells.duplicate(true), "next_well": next_well, "raiders": raiders.duplicate(true), "last_raid": last_raid.duplicate(), "led": led.duplicate(), "counts": counts.duplicate(),
		"defended_day": defended_day.duplicate(), "next_work": next_work}


func load_dict(d: Dictionary) -> void:
	raiders = (d.get("raiders", {}) as Dictionary).duplicate(true)
	for k in raiders:
		for f in ["coins0", "goods0", "day"]:
			raiders[k][f] = int(raiders[k].get(f, 0))
	last_raid = (d.get("last_raid", {}) as Dictionary).duplicate()
	led = (d.get("led", {}) as Dictionary).duplicate()
	counts = (d.get("counts", {}) as Dictionary).duplicate()
	defended_day = (d.get("defended_day", {}) as Dictionary).duplicate()
	next_work = int(d.get("next_work", 1))
	wells = {}
	for k in (d.get("wells", {}) as Dictionary):
		wells[str(k)] = (d.wells[k] as Dictionary).duplicate(true)
	next_well = int(d.get("next_well", wells.size() + 1))
	var recs: Array = wells.values()
	for c in _hs().claims:
		recs.append_array(_all_works(c))
	for wk in recs:
		for k in ["cost", "need"]:
			var ints := {}
			for id in wk[k]:
				ints[str(id)] = int(wk[k][id])
			wk[k] = ints
		wk.labour = float(wk.labour)
	for c in _hs().claims:
		if c.has("water"):
			c.water = int(c.water)
	var bc := band_claim()
	if not bc.is_empty():
		w.bandit_camp = Homesteads.step_of(bc)
	_hs()._sync_overworld()                             # (the wells are drawn with the claims: Homesteads loaded before them)
	for c in _hs().claims:
		for wk in c.get("works", []):
			_register_stations(c, wk)
