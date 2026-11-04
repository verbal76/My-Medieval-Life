class_name Homesteads
extends RefCounted
## B25R1-010 (owner directive 2026-11-03, docs/directives/2026-11-03_b25r1_homesteading.md; design and audit
## docs/design/HOMESTEADING_B25R1.md): independent homesteads on free wilderness land outside the settlements' control.
##
## Land: a claim is real ground in the overworld (village coordinates), outside the village's and every settlement's control
## area (their rectangles grown by `village_control` / `site_control`), off the roads, on open ground (no tree, boulder,
## cliff, mountain top), not overlapping another claim. It records its owner (an ownership reference: "hh:<n>" or the player's),
## bounds, the house's footprint inside it and the site of the house, the village's own house (stamp, cost, one construction
## for everybody). A claim creates no village, government or tax jurisdiction.
##
## People: the moments are household formation (Construction._found, _found_couple) for a young adult and, much more rarely, an
## established adult's relocation event. WHO chooses to go is LifeDecisions' judged choice (see "deciding" below). Once
## chosen, the settlement must be healthy (no decline over `health_days`, enough working adults and households left, the
## household viable, nobody from it lately), a site found and the coins in hand, or nothing happens (the gates, begin / _go).
##
## The sequence (directive section 6) through the game's own acts: outfit at the village market, walk the road and the last
## cells, claim on arrival, carry and buy materials, deliver them to the frame (World's site rule), the house stands (drawn and
## solid in the overworld, its interior spots used), then a life by the existing needs: sleep, the pantry, firewood, felling or
## quarrying by trade, market trips to sell and buy (World.trade through NPCBrain's acts). A failure (not built in time, no food
## and no coin) returns the delivered materials to the household's pantry (cancel_site's rule) and walks them back; nobody and
## nothing is erased. Homesteaders are ordinary villagers in World.npcs: offscreen they run in the abstract tier like anyone.
##
## Deterministic: no random draw (every list is in a fixed order). Saved (World "homesteads", optional:
## an older save has none). Numbers: balance.json "homestead" (agent proposals, provisional; the 1-3 % is the owner's tuning
## hypothesis).

const FORMAT := "mml-homesteads/1"
const STAMP := "house"

static var enabled := true           # a test switch (never cleared in the game): with it off nobody decides to homestead

var w: World
var claims: Array = []               # in creation order (see the header); ids "hs<n>"
var next_id := 1
var pop_history: Array = []          # [day, villagers living in the village] at each dawn, the last health_days + 1
var last_left := {}                  # str(household) -> the day a homesteader last left it
var returning := {}                  # str(npc id) -> true: walking back to the village from the country
var trips := {}                      # str(npc id) -> {claim, leg: out | market | back, n: errands, day, tried: {}}
var counts := {}                     # decided, claimed, built, failed, abandoned, returned, relocated, gate_<why>
var _roads := {}                     # "gate:sid" -> the road route (a pure function of the seed; not saved)
var _seen_cell := {}                 # player pid -> the last cell discovery was checked from (not saved)
var _claim_cache := {}               # player cell -> the refusal there (cleared when claims change; not saved)


func _init(world: World) -> void:
	w = world


static func cfg() -> Dictionary:
	return GameData.b("homestead")


func _count(key: String, k := 1) -> void:
	counts[key] = int(counts.get(key, 0)) + k
	w.stat("homestead_" + key, float(k))


# ---------------------------------------------------------------- claims -------------------------
func claim(id: String) -> Dictionary:
	for c in claims:
		if str(c.id) == id:
			return c
	return {}


## The claim household `h` lives on (its "homestead" key), or {}.
func claim_of_household(h: int) -> Dictionary:
	if h < 0 or h >= w.households.size():
		return {}
	var id := str(w.households[h].get("homestead", ""))
	return claim(id) if id != "" else {}


func claim_of(n: NPC) -> Dictionary:
	return claim_of_household(n.household)


## Whether `n` lives the homestead life (their household is on a claim) or is walking back from one: the village's own
## schedulers leave them alone (hiring, job search, apprenticeship, stall buyers, migration).
func away(n: NPC) -> bool:
	if n == null:
		return false
	if returning.has(str(n.id)):
		return true
	return n.household >= 0 and n.household < w.households.size() and w.households[n.household].has("homestead")


## Whether `n` is out in the country on homestead business (not in the village): nobody trades with them from the village.
func remote(n: NPC) -> bool:
	return away(n) and not w.map.in_village(n.cell())


## B25R1-016: a homestead household's day for the recorder (homestead_sustain), and a year lived there (homestead_year).
func _sustain(c: Dictionary, h: int, members: Array) -> void:
	if w.recorder == null:
		return
	var pantry: Inventory = w.households[h].pantry
	var food := 0
	for f in NPCBrain.EDIBLE:
		food += pantry.count(f)
	var coins := 0
	for o: NPC in members:
		coins += o.coins
	_rec("homestead_sustain", {"claim": str(c.id), "household": World.hh_ref(h), "food_units": food, "food_days": snappedf(w.brain.household_food_days(h), 0.1),
		"water": int(c.get("water", 0)), "coins": coins, "employed": false, "outcome": "failed" if int(c.get("poor_days", 0)) > 0 or int(c.get("dry_days", 0)) > 0 else "ok"})
	var since := int(c.get("built_day", c.get("claimed_day", c.day)))
	if w.day() > since and (w.day() - since) % Life.year_days() == 0:
		_rec("homestead_year", {"claim": str(c.id), "household": World.hh_ref(h), "years": (w.day() - since) / Life.year_days(), "people": members.size()})


## B25R1-016: the recorder's dawn rows (read only): one a living claim.
func recorder_rows() -> Array:
	var out := []
	for c in claims:
		if str(c.status) == "abandoned":
			continue
		var ref := str(c.owner)
		var h := World.ref_id(ref)
		var pop := 0
		var coins := 0
		var food := 0
		if ref.begins_with("hh:") and h >= 0 and h < w.households.size():
			for o: NPC in w.brain._members(h):
				pop += 1
				coins += o.coins
			for f in NPCBrain.EDIBLE:
				food += (w.households[h].pantry as Inventory).count(f)
		var herd := 0
		var pen: Dictionary = w.wilds.pen_of_claim(c) if w.wilds != null else {}
		if not pen.is_empty():
			herd = w.fauna.count(str(pen.id), str(pen.kind))
		out.append({"id": str(c.id), "population": pop, "households": 1 if pop > 0 else 0, "food_units": food, "water": int(c.get("water", 0)),
			"stores": (c.store as Inventory).items.duplicate(), "coins": coins, "livestock": herd, "path": str(c.get("path", "player" if World.is_player_ref(ref) else "")),
			"faction": str(c.get("faction", "lawful")), "status": str(c.status)})
	return out


## The claim whose land holds cell `c` (any owner), {} none.
func claim_at(c: Vector2i) -> Dictionary:
	for cl in claims:
		if str(cl.status) != "abandoned" and rect_of(cl).has_point(c):
			return cl
	return {}


func claims_of(ref: String) -> Array:
	return claims.filter(func(c): return str(c.owner) == ref)


static func rect_of(c: Dictionary) -> Rect2i:
	return Rect2i(int(c.x), int(c.y), int(c.w), int(c.h))


static func house_of(c: Dictionary) -> Rect2i:
	var hr: Dictionary = c.house
	return Rect2i(int(hr.x), int(hr.y), int(hr.w), int(hr.h))


## The doorway cell of a claim's house and the step in front of it (where its frame is worked from).
static func door_of(c: Dictionary) -> Vector2i:
	return Vector2i(int(c.house.door[0]), int(c.house.door[1]))


static func step_of(c: Dictionary) -> Vector2i:
	return door_of(c) + Vector2i(0, 1)


## The house's interior spots (the stamp's: chest, tables, hearths, beds), placed at the house.
func spots_of(c: Dictionary, kind := "") -> Array:
	var st: Dictionary = w.map.data.stamps.get(STAMP, {})
	var o := Vector2i(int(c.house.x), int(c.house.y))
	var out := []
	for s in st.get("interior", {}).get("spots", []):
		if kind != "" and str(s.kind) != kind:
			continue
		out.append({"kind": str(s.kind), "at": Vector2i(int(s.at[0]), int(s.at[1])) + o, "use": Vector2i(int(s.use[0]), int(s.use[1])) + o,
			"tile": int(s.get("tile", -1))})
	return out


## The house's footprint and claim for a house whose door step is `step`.
func _layout(step: Vector2i) -> Dictionary:
	var st: Dictionary = w.map.data.stamps[STAMP]
	var size := Vector2i(int(st.w), int(st.h))
	var door := Vector2i(int(st.door[0]), int(st.door[1]))
	var pos := step - door - Vector2i(0, 1)
	var house := Rect2i(pos, size)
	var land := house.grow(int(cfg().claim_margin))
	return {"house": house, "land": land, "door": pos + door}


## What stands on a cell as ground for a house: "open" (wilderness ground: flat grass, a wild flower or bush cleared for the
## floor), "tree" (a tree of any stage, or a stump: felled or grubbed up to make room, as the manor's land office grubs a
## building ground, Property.claim) or "blocked" (a cliff, a mountain top or rim, a boulder, a road, the village).
func _ground(c: Vector2i) -> String:
	var o: Overworld = w.map.overworld
	if o.village.has_point(c) or o.is_road(c) or o.is_top(c) or o.is_rim(c):
		return "blocked"
	var ch := o.get_chunk(Overworld.chunk_of(c))
	var i := o._cell_of(ch, c)
	if o.changes.has(c):
		if str(o.changes[c].get("state", "")) == "cleared":
			return "open"
		return "tree"
	if ch.kind[i] != Overworld.NO_TREE:
		return "tree"
	if ch.solid[i] != 0 or (ch.deco[i] == int(o.tiles.rock) and not o.rock_gone(c)):
		return "blocked"
	var flat := false
	for g in (o.tiles.cliff[0] as Array):
		flat = flat or int(g) == ch.ground[i]
	return "open" if flat else "blocked"


## The cells of a house's ground still holding a tree or stump (its footprint and the ring round its walls), in row order.
func trees_on(house: Rect2i) -> Array:
	var out := []
	var ring := house.grow(1)
	for y in range(ring.position.y, ring.end.y):
		for x in range(ring.position.x, ring.end.x):
			var c := Vector2i(x, y)
			if _ground(c) == "tree":
				out.append(c)
	return out


## Grub up what needs no axe on a claim's house ground (stumps, saplings, young and growing trees: Property.claim's rule for a
## building ground); a mature tree must be felled first (its logs are the feller's), then its stump goes. Returns the mature
## trees still standing there.
func clear_ground(c: Dictionary) -> Array:
	return clear_rect(house_of(c))


## clear_ground's rule for any building's ground (Wilds: a workshop beside the house).
func clear_rect(rect: Rect2i) -> Array:
	var o: Overworld = w.map.overworld
	var left := []
	for cell: Vector2i in trees_on(rect):
		var t := o.tree_at(cell)
		if t.is_empty() or Vector2i(int(t.x), int(t.y)) != cell:
			t = o.base_tree(cell) if not o.changes.has(cell) else o.changes[cell]
		if t.is_empty():
			continue
		w.sync_tree(t)
		if str(t.state) == "grown":
			left.append(cell)
			continue
		t.state = "cleared"
		t.erase("born")
		t.regrow = 1.0e15
		o.changes[cell] = t                    # (Overworld.note_tree would forget a grown base tree; a cleared one is kept)
		w.tree_changed.emit(t)
		w.stat("homestead_grubbed")
	return left


## Why `land` (a claim: the house's footprint grown by claim_margin) cannot be claimed, "" if it can. `ignore` is a claim id not
## counted against it (its own). The land must lie outside the village's and every settlement's control area, hold no road
## (roads are for everybody), overlap no other claim; the house's ground must be open (_open), with nothing solid round its
## walls or in front of its door.
func refusal(land: Rect2i, ignore := "") -> String:
	var o: Overworld = w.map.overworld
	if o == null:
		return "There is no open country here."
	var cf := cfg()
	if land.intersects(o.village.grow(int(cf.village_control))):
		return "This is the village's land, under the manor."
	for st in o.sites:
		if land.intersects((st.rect as Rect2i).grow(int(cf.site_control))):
			return "This land is %s's." % str(st.name)
	for c in claims:
		if str(c.id) == ignore or not _holds_land(c):
			continue
		if land.intersects(rect_of(c).grow(int(cf.claim_gap))):
			return "Someone has claimed this land already."
	var house := land.grow(-int(cf.claim_margin))
	var near := house.grow(int(cf.road_gap))
	for y in range(near.position.y, near.end.y):
		for x in range(near.position.x, near.end.x):
			if o.is_road(Vector2i(x, y)):
				return "A road runs here: land by the road is for everybody."
	var trees := 0
	var ring := house.grow(1)
	for y in range(ring.position.y, ring.end.y):
		for x in range(ring.position.x, ring.end.x):
			var g := _ground(Vector2i(x, y))
			if g == "blocked":
				return "The ground is not fit for a house here: rocks, a slope or a cliff are in the way."
			if g == "tree":
				trees += 1
	if trees > int(cf.max_clear):
		return "Too many trees stand here to clear for a house (%d)." % trees
	return ""


## A claim holds its land while it is intended, claimed or built; an abandoned claim only while its house stands.
static func _holds_land(c: Dictionary) -> bool:
	return str(c.status) != "abandoned" or str(c.get("building", "")) != ""


func _new_claim(owner: String, lay: Dictionary, founder: int, status: String) -> Dictionary:
	var land: Rect2i = lay.land
	var house: Rect2i = lay.house
	var door: Vector2i = lay.door
	var c := {"id": "hs%d" % next_id, "owner": owner, "founder": founder, "x": land.position.x, "y": land.position.y,
		"w": land.size.x, "h": land.size.y, "house": {"x": house.position.x, "y": house.position.y, "w": house.size.x,
		"h": house.size.y, "door": [door.x, door.y]}, "site": {}, "status": status, "stage": "travel", "day": w.day(),
		"store": Inventory.new(), "building": "", "trade": "", "trades": {}, "why": "", "anchor": {}, "known": [], "members": [],
		"poor_days": 0, "faction": "lawful", "concealed": false, "allegiance": [[w.day(), "lawful"]]}
	next_id += 1
	claims.append(c)
	_claim_cache.clear()
	return c


## Mark out the house on a claim (World.start_site's record: kind, cost, need, done, owner): the frame stands.
func _mark_site(c: Dictionary) -> void:
	var cost := {}
	for id in w.construction.cost_of("house"):
		cost[str(id)] = int(w.construction.cost_of("house")[id])
	c.site = {"kind": "house", "cost": cost, "need": cost.duplicate(), "done": false, "owner": str(c.owner)}
	c.status = "claimed"
	c.claimed_day = w.day()
	_sync_overworld()


## Deliver materials from `inv` to a claim's frame (World.deliver's rule: raw-stone work takes rubble, every unit counted
## against what is still needed). Returns true when the house is complete.
func deliver(c: Dictionary, inv: Inventory, by := "") -> bool:
	if c.site.is_empty() or bool(c.site.done):
		return false
	var need: Dictionary = c.site.need
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
		w.stat("homestead_loads", float(given))
		_rec("homestead_materials", {"claim": str(c.id), "by": by, "loads": given, "need": c.site.need.duplicate()})
		if by != "" and by != str(c.owner):
			w.stat("site_loads_by_others", given)
	if need.is_empty() and clear_ground(c).is_empty():
		_finish(c)
		return true
	return false


## The last load is in: the house stands on the claim (its materials used up in it, counted as World._finish_site counts).
func _finish(c: Dictionary) -> void:
	c.site.done = true
	for id in c.site.cost:
		w.stat("used_building_" + str(id), float(c.site.cost[id]))
	c.building = "hs_house_" + str(c.id)
	c.status = "built"
	c.stage = "live"
	c.built_day = w.day()
	_count("built")
	_rec("homestead_built", {"claim": str(c.id), "owner": str(c.owner), "cost": c.site.cost.duplicate(), "house": str(c.building)})
	_sync_overworld()
	w.note("Your house in the country is finished." if World.is_player_ref(str(c.owner)) else "%s's house in the country is finished." % _owner_name(c))


## What a claim's delivered materials are (item -> count), as World.site_delivered.
static func delivered(c: Dictionary) -> Dictionary:
	var out := {}
	if c.site.is_empty() or bool(c.site.done):
		return out
	for id in c.site.cost:
		var k := int(c.site.cost[id]) - int(c.site.need.get(id, 0))
		if k > 0:
			out[id] = k
	return out


## Goods held on the claims, item -> count (the census's "homesteads" holder): materials lying on unfinished frames and
## what is stored in the player's homestead chests.
func goods() -> Dictionary:
	var out := {}
	if w.wilds != null:
		var lw: Dictionary = w.wilds.loose_well_goods()          # wells being dug that no claim owns (settlements')
		for id in lw:
			out[id] = int(out.get(id, 0)) + int(lw[id])
	for c in claims:
		var got := delivered(c)
		var wd: Dictionary = w.wilds.work_delivered(c) if w.wilds != null else {}
		for id in wd:
			got[id] = int(got.get(id, 0)) + int(wd[id])
		for id in got:
			out[id] = int(out.get(id, 0)) + int(got[id])
		for id in (c.store as Inventory).items:
			out[id] = int(out.get(id, 0)) + int(c.store.items[id])
	return out


## The overworld draws and collides the houses and frames standing on the claims (Overworld.homes).
func _sync_overworld() -> void:
	var o: Overworld = w.map.overworld
	if o == null:
		return
	var list := []
	for c in claims:
		if str(c.get("building", "")) != "":
			list.append({"id": str(c.id), "stamp": STAMP, "rect": house_of(c), "door": door_of(c)})
		elif not c.site.is_empty() and not bool(c.site.done):
			var hr := house_of(c)
			list.append({"id": str(c.id), "stamp": "", "rect": hr, "door": door_of(c),
				"frame": Vector2i(hr.position.x + hr.size.x / 2, hr.position.y + hr.size.y - 2), "tile": int(w.map.data.tiles.frame)})
		if w.wilds != null:
			list.append_array(w.wilds.overworld_entries(c))
	o.homes = list
	o.homes_version += 1


func _owner_name(c: Dictionary) -> String:
	var ref := str(c.owner)
	if World.is_player_ref(ref):
		return "Your"
	var h := World.ref_id(ref)
	if ref.begins_with("hh:") and h >= 0 and h < w.households.size():
		return "The %s family" % str(w.households[h].family)
	return "Somebody"


# ---------------------------------------------------------------- the player ---------------------
## The house a player standing at `at` and facing north would mark out: its door step their cell.
func player_layout(at: Vector2) -> Dictionary:
	return _layout(Vector2i(at.floor()) + Vector2i(0, 0))


## Why the player cannot claim the ground north of them now, "" if they can (cached by cell while no claim changes).
func player_claim_refusal(p: PlayerState) -> String:
	if w.map.overworld == null or p.map_level != 0:
		return "There is no open country here."
	if w.mirrors():
		return "Only the host can claim land for now."
	for c in claims_of(w.player_ref(p)):
		if not c.site.is_empty() and not bool(c.site.done) and str(c.status) == "claimed":
			return "Finish the house on your homestead first."
	var cell := Vector2i(p.pos.floor())
	if w.map.in_village(cell):
		return "This is the village's land, under the manor."
	var key := "%d,%d" % [cell.x, cell.y]
	if not _claim_cache.has(key):
		_claim_cache[key] = refusal(player_layout(p.pos).land)
	return str(_claim_cache[key])


## The player claims the ground north of them and marks out a house on it (the same frame and materials as anybody's).
## "" when done, else why not.
func player_claim(p: PlayerState) -> String:
	var why := player_claim_refusal(p)
	if why != "":
		return why
	var c := _new_claim(w.player_ref(p), player_layout(p.pos), w.person_id(p), "claimed")
	c.stage = "build"
	if not (c.known as Array).has(p.pid):
		c.known.append(p.pid)
	_mark_site(c)
	clear_ground(c)
	_count("player_claimed")
	_rec("homestead_claimed", {"claim": str(c.id), "owner": str(c.owner), "by": w.person_id(p), "land": [c.x, c.y, c.w, c.h]})
	w.note("You claim a piece of open country and mark out a house on it.")
	return ""


## The player brings what they carry to their homestead's frame. "" when something was delivered (or the house finished).
func player_deliver(p: PlayerState, id: String) -> String:
	var c := claim(id)
	if c.is_empty() or str(c.owner) != w.player_ref(p):
		return "This is not your homestead."
	if c.site.is_empty() or bool(c.site.done):
		return "Your house here is finished."
	var before := 0
	for k in c.site.need:
		before += int(c.site.need[k])
	var done := deliver(c, p.inv, w.player_ref(p))
	if done:
		return ""
	var after := 0
	for k in c.site.need:
		after += int(c.site.need[k])
	if after == 0:
		return "Every load is in, but trees still stand on the house's ground: fell them (%d) and the house goes up." % clear_ground(c).size()
	return "" if after < before else "You have nothing the house still needs."


## What a site still needs, as text: "12 planks, 20 building blocks".
static func need_text(c: Dictionary) -> String:
	var need: Dictionary = c.site.get("need", {})
	var ids: Array = need.keys()
	ids.sort()
	return ", ".join(ids.map(func(id): return "%d %s" % [int(need[id]), GameData.item_name(str(id)).to_lower()]))


## The homestead targets round the player (Main's target list): their frame, a house's chest and bed, and the claim itself.
## Each is {d (distance to the probe), kind, label, ...}.
func player_targets(p: PlayerState, probe: Vector2, facing_up: bool) -> Array:
	var out := []
	if w.map.overworld == null or p.map_level != 0 or w.map.in_village(Vector2i(p.pos.floor())):
		return out
	var mine := w.player_ref(p)
	for c in claims:
		var hr := house_of(c)
		if not Rect2(hr.grow(2)).has_point(p.pos):
			continue
		if not c.site.is_empty() and not bool(c.site.done):
			var at := Vector2(step_of(c)) + Vector2(0.5, 0.5)
			var d := at.distance_to(probe)
			if d < 1.6 and str(c.owner) == mine:
				var standing := clear_ground(c).size()
				out.append({"d": d, "kind": "homestead_site", "id": str(c.id), "label": "Your homestead: bring materials (still needs %s%s)" % [need_text(c),
					("; %d trees to fell on its ground" % standing) if standing > 0 else ""]})
			elif d < 1.6:
				out.append({"d": d, "kind": "info", "label": "%s homestead frame" % _owner_name(c), "text": "Someone is building a house here: it still needs %s." % need_text(c)})
				if not (c.members as Array).is_empty() and str(c.status) != "abandoned":
					out.append({"d": d + 0.05, "kind": "chest", "id": "homestead:" + str(c.id), "label": "Open the stores at the %s camp (theft)" % _owner_name(c).to_lower().trim_prefix("the "),
						"theft": true})        # B25R1-014: what the camp's people really keep there (their household's stores)
			continue
		if str(c.get("building", "")) == "":
			continue
		for s in spots_of(c, "chest"):
			var at := Vector2(s.at) + Vector2(0.5, 0.5)
			var d := at.distance_to(probe)
			if d < 0.9:
				var own := str(c.owner) == mine
				out.append({"d": d, "kind": "chest", "id": "homestead:" + str(c.id), "label": "Your homestead chest: store things" if own
					else "Open the %s chest (theft)" % _owner_name(c).to_lower().trim_prefix("the "), "theft": not own})
		if str(c.owner) == mine:
			for s in spots_of(c, "bed"):
				var at := Vector2(s.at) + Vector2(0.5, 0.5)
				var d := at.distance_to(probe)
				if d < 0.9:
					out.append({"d": d, "kind": "rest", "label": "Your bed: sleep"})
					break
	if w.wilds != null:
		out.append_array(w.wilds.player_targets(p, probe))     # B25R1-Q3: a well on the player's own claim
	if facing_up and player_claim_refusal(p) == "":
		var cost: Dictionary = w.construction.cost_of("house")
		var ids: Array = cost.keys()
		ids.sort()
		out.append({"d": 1.45, "kind": "homestead_claim", "label": "Claim this land and mark out a homestead here (a house: %s)" %
			", ".join(ids.map(func(id): return "%d %s" % [int(cost[id]), GameData.item_name(str(id)).to_lower()]))})
	return out


## A player comes near a claim: they know it from now on (the region map's icon). Called each update (cheap: only on a
## change of the player's cell, and the claims are few).
func note_player(p: PlayerState) -> void:
	if claims.is_empty() or not p.alive or p.map_level != 0:
		return
	var cell := Vector2i(p.pos.floor())
	if _seen_cell.get(p.pid, Vector2i(1 << 30, 0)) == cell:
		return
	_seen_cell[p.pid] = cell
	for c in claims:
		if (c.known as Array).has(p.pid):
			continue
		var r := float(cfg().discover_hidden) if bool(c.get("concealed", false)) else float(cfg().discover_radius)
		if Vector2(cell).distance_to(Vector2(house_of(c).get_center())) <= r:
			c.known.append(p.pid)
			_count("discovered")
			if p == w.player and str(c.owner) != w.player_ref(p):
				w.note("You come upon a homestead in the country: %s." % _owner_name(c).to_lower().trim_prefix("the "))


## B25R1-010 hook for the region map (wip/b25r1-map): the homesteads player `p` knows, [{id, cell, name, own, built}], in claim
## order. Every homestead is unknown until the player claims it or comes near it (no homestead is revealed at world creation).
func known_markers(p: PlayerState) -> Array:
	var out := []
	for c in claims:
		if not (c.known as Array).has(p.pid):
			continue
		var own := str(c.owner) == w.player_ref(p)
		out.append({"id": str(c.id), "cell": house_of(c).get_center(), "name": "Your homestead" if own else "%s homestead" % _owner_name(c),
			"own": own, "built": str(c.get("building", "")) != "", "abandoned": str(c.status) == "abandoned",
			"faction": str(c.get("faction", "lawful")), "concealed": bool(c.get("concealed", false))})
	return out


# ---------------------------------------------------------------- allegiance ---------------------
## B25R1-014 section 2 (one wilderness settlement foundation for lawful and outlaw places): a claim's faction ("lawful" or
## "outlaw") and concealment change with its people, never the claim itself: its id, land, buildings, stores, owner, residents,
## discovery and history stay as they are; the change is dated in `allegiance`. A concealed claim is found only from
## discover_hidden tiles (Homesteads.note_player), the region map's hook reports both. Returns true when anything changed.
func set_faction(c: Dictionary, faction: String, concealed: bool, why := "") -> bool:
	if str(c.get("faction", "lawful")) == faction and bool(c.get("concealed", false)) == concealed:
		return false
	c.faction = faction
	c.concealed = concealed
	if not c.has("allegiance"):
		c.allegiance = []
	c.allegiance.append([w.day(), faction, why])
	_count("allegiance_" + faction)
	_rec("settlement_affiliation", {"claim": str(c.id), "faction": faction, "concealed": concealed, "why": why})
	return true


## A claim's faction follows its people: outlaw when every living resident adult is of the band (or its clan), lawful when none
## is. Called each dawn for the claims with residents (Homesteads.dawn).
func _allegiance(c: Dictionary, members: Array) -> void:
	var adults := members.filter(func(o: NPC) -> bool: return o.role != "child")
	if adults.is_empty():
		return
	var outl := adults.filter(func(o: NPC) -> bool: return o.role == "bandit" or o.clan != "")
	if outl.size() == adults.size():
		set_faction(c, "outlaw", true, "its people are outlaws")
	elif outl.is_empty():
		set_faction(c, "lawful", false, "its people live by the law")


# ---------------------------------------------------------------- deciding -----------------------
## Who chooses to homestead is LifeDecisions.homestead_decider (owner decision D1/D2 on B25R1-010, 2026-11-03: the judged
## choice homestead_choice, with the 1-3 % as a population brake), installed by World as `decider`: at household formation
## (consider, consider_couple: young adults) and at an established adult's relocation event (LifeDecisions._adults_dawn).
## Unset (a test, or the judgment layer off), nobody decides. begin() is the start after the choice, the gates, the site, the
## coins, then travel, claim, construction and life on the land.
var decider := Callable()
var pending_site := {}               # the site the decision weighed (LifeDecisions), used by the _go that follows it; not saved


func _decide(h: int, founder: NPC, leaving: Array, path: String) -> NPC:
	if not enabled or not bool(cfg().enabled) or w.map.overworld == null or not decider.is_valid():
		return null
	return decider.call(h, founder, leaving, path)


## An explicit start (tests and measurement; the approved decision model will call it): `who` (and `leaving`, their partner) of
## household `h` set out to found a homestead, if the gates, a site and the coins allow. True when they went.
func begin(h: int, who: NPC, leaving: Array, path := "test", h2 := -1) -> bool:
	return _go(h, who, leaving, path, h2)


## The village's living people (not the band, not on a claim) and its working-age adults.
func village_people() -> Dictionary:
	var alive := 0
	var adults := 0
	for n: NPC in w.npcs:
		if not n.alive or n.role == "bandit" or n.clan != "" or away(n):
			continue
		alive += 1
		if n.role == "adult":
			adults += 1
	var hhs := 0
	for h in w.households.size():
		var hh: Dictionary = w.households[h]
		if not hh.get("ended", false) and not hh.has("homestead") and not w.brain._members(h).is_empty():
			hhs += 1
	return {"alive": alive, "adults": adults, "households": hhs}


## Why the village cannot spare `leaving` from household `h` now, "" if it can (directive section 4).
func gate(h: int, leaving: Array) -> String:
	var cf := cfg()
	var setting_out := 0
	for c in claims:
		if str(c.get("path", "")) == "band":
			continue                                    # (the band's camp is no household setting out from the village)
		if str(c.status) == "intended" or (str(c.status) == "claimed" and not World.is_player_ref(str(c.owner))):
			setting_out += 1
	if setting_out >= int(cf.max_starting):
		return "busy"
	for o: NPC in leaving:
		if Migration._barred(w, o) or (w.employment != null and w.employment.is_employed(o)) or o.job in ["merchant", "guard", "smith", "carpenter", "cook", "tavernkeeper"]:
			return "barred"
		if w.business != null and w.business.is_attendant(o):
			return "barred"
	var vp := village_people()
	var adults_leaving := leaving.filter(func(o: NPC) -> bool: return o.role == "adult").size()
	if int(vp.adults) - adults_leaving < int(cf.min_working_adults):
		return "few_workers"
	if int(vp.households) < int(cf.min_households):
		return "few_households"
	var past := _alive_days_ago(int(cf.health_days))
	if past > 0 and float(vp.alive) < float(past) * float(cf.decline_share):
		return "declining"
	if last_left.has(str(h)) and w.day() - int(last_left[str(h)]) < int(cf.household_gap_days):
		return "household_recent"
	var staying: Array = w.brain._members(h).filter(func(o: NPC) -> bool: return o.role == "adult" and not leaving.has(o))
	if staying.is_empty() and w.brain._members(h).size() > leaving.size():
		return "household_viability"           # children or elders would be left with no working adult
	return ""


func _alive_days_ago(days: int) -> int:
	var want := w.day() - days
	for e in pop_history:
		if int(e[0]) == want:
			return int(e[1])
	return 0


## Construction._found: household `h` is crowded and `founder` (with their partner, `leaving`) would found a household. True
## when one of them chooses a homestead instead (the household and its coins are made by _go, as _found makes them).
func consider(h: int, founder: NPC, leaving: Array) -> bool:
	var who := _decide(h, founder, leaving, "young")
	return who != null and _go(h, who, leaving, "young")


## Construction._found_couple: partners in different households (or a grown child and partner) would found a household.
func consider_couple(f: NPC, m: NPC) -> bool:
	var who := _decide(f.household, f, [f, m], "young")
	return who != null and _go(f.household, who, [f, m], "young", m.household)


## The decision made: gates, a site, the coins; the household is founded and sets out. False (nothing changed) when any is
## missing. `h2`: the partner's household when a couple from two households goes.
func _go(h: int, who: NPC, leaving: Array, path: String, h2 := -1) -> bool:
	var why := gate(h, leaving)
	if why == "" and h2 >= 0 and h2 != h:
		why = gate(h2, leaving)
	if why != "":
		_count("gate_" + why)
		return false
	var site := pending_site if not pending_site.is_empty() else find_site(who)
	pending_site = {}
	if site.is_empty():
		_count("gate_no_site")
		return false
	var start := ceili(w.construction.estimate(w.construction.cost_of("house")) * float(GameData.b("found_start_share")))
	var homes: Array = [h] if h2 < 0 or h2 == h else [h, h2]
	var own := 0
	for o: NPC in leaving:
		own += o.coins
	var gifts := {}
	var spare := own
	for hi: int in homes:
		var others: Array = w.brain._members(hi).filter(func(o: NPC) -> bool: return not leaving.has(o))
		var theirs := 0
		for o: NPC in others:
			theirs += o.coins
		gifts[hi] = maxi(0, theirs - w.construction._keep(hi, others.size()))
		spare += int(gifts[hi])
	if spare < start:
		_count("gate_coins")
		return false
	# the family puts together what the leavers' own coins do not cover (as _found and _found_couple do): coins move, none is made
	var short := maxi(0, start - own)
	for hi: int in homes:
		var give := mini(short, int(gifts[hi]))
		if give <= 0:
			continue
		var others: Array = w.brain._members(hi).filter(func(o: NPC) -> bool: return not leaving.has(o))
		others.sort_custom(func(a: NPC, b: NPC) -> bool: return a.coins > b.coins or (a.coins == b.coins and a.id < b.id))
		for o: NPC in others:
			var k := mini(give, o.coins)
			o.coins -= k
			o.spent += k
			who.coins += k
			give -= k
			short -= k
	var hh: Dictionary = w.households[h]
	var nid := w.households.size()
	var c := _new_claim(World.hh_ref(nid), site.lay, who.id, "intended")
	c.anchor = site.anchor
	c.why = str(site.why)
	c.path = path
	c.origin = h
	c.pending_water = site.get("water", {})
	var nh := {"id": nid, "family": str(hh.family), "home": "", "members": [], "pantry": Inventory.new(), "founded_from": h,
		"founded_day": w.day(), "homestead": str(c.id)}
	w.households.append(nh)
	_depart(leaving)
	for o: NPC in leaving:
		var old := o.household
		(w.households[old].members as Array).erase(o.id)
		o.household = nid
		o.family = str(hh.family)
		Identity.sync_name(w, o)
		(nh.members as Array).append(o.id)
		c.members.append(o.id)
		o.plan.clear()
		if not w.property._anyone_alive(old):
			w.property.household_ended(old)
		last_left[str(old)] = w.day()
	trips[str(who.id)] = {"claim": str(c.id), "leg": "market", "n": 0, "day": w.day(), "tried": {}, "outfit": true}
	_count("decided")
	_count("decided_" + path)
	_rec("household_formed", {"person": who.id, "household": World.hh_ref(nid), "origin": World.hh_ref(h), "track": "couple" if h2 >= 0 and h2 != h else path,
		"homestead": true})
	_rec("homestead_set_out", {"claim": str(c.id), "household": World.hh_ref(nid), "from": World.hh_ref(h), "people": leaving.map(func(o: NPC) -> int: return o.id),
		"path": path, "site": [c.x, c.y], "why": str(c.why)})
	if w.life != null:
		w.life.homestead_started(path)
	w.note("%s %s leaves the village to make a home in the open country, %s%s." % [who.name, who.family, str(site.why),
		"" if leaving.size() == 1 else ", with " + (leaving[1] if leaving[0] == who else leaving[0]).name])
	for hi: int in homes:
		w.brain.evaluate_household(hi)
	w.brain.evaluate_household(nid)
	return true


## They leave their posts in the village as a migrant does (Migration._pre_leave, the posts handed on as after a death); the
## trade they had is kept on the claim (their skills stay theirs), and they hold no village job while on the land.
func _depart(ms: Array) -> void:
	Migration._pre_leave(w, ms)
	for o: NPC in ms:
		var cl := {}
		for c in claims:
			if str(c.status) == "intended" and int(c.founder) in ms.map(func(x: NPC) -> int: return x.id):
				cl = c
		if not cl.is_empty():
			cl.trades[str(o.id)] = o.job
			if int(cl.founder) == o.id:
				cl.trade = o.job
		w.brain._hand_over_pens(o)
		w.brain._give_up_stall(o)
		w.brain._open_vacancy(o)
		w.construction.on_death(o)
		w.manor_work.on_death(o)
		o.job = ""
		o.workplace = ""
		o.home = ""


# ---------------------------------------------------------------- choosing land ------------------
func _gate_index() -> int:
	return Journeys.gate_index(w)


func _road(sid: String) -> PackedVector2Array:
	var gi := _gate_index()
	var key := "%d:%s" % [gi, sid]
	if not _roads.has(key):
		_roads[key] = w.map.overworld.road_route(gi, sid, false) if gi >= 0 else PackedVector2Array()
	return _roads[key]


## Where `n` would make a homestead: along the roads from the village's south gate to the settlements, beside the road,
## on eligible land, the best by what the land offers their trade (directive section 5). {lay, anchor, why} or {}.
## `outlaw` (the band's camp, Wilds.found_band): off the road in cover (outlaw_offset cells at least), the bandits' camp no
## danger to it. Every site must have water (Wilds.water_access, B25R1-Q3: a stream in reach, else a well the household can pay
## for or win the materials of; `coins` the purse it has, -1 the founder's household's): one without is refused, recorded.
func find_site(n: NPC, outlaw := false, coins := -1) -> Dictionary:
	var o: Overworld = w.map.overworld
	var cf := cfg()
	var trade := n.job
	if coins < 0:
		coins = w.property.purse(World.hh_ref(n.household)) if n.household >= 0 else n.coins
	var tools := []
	for t in ["axe", "pickaxe"]:
		if n.inv.has(t):
			tools.append(t)
	var min_off := int(cf.outlaw_offset) if outlaw else 8
	var dry := 0
	var cands := []
	for st in o.sites:
		var sid := str(st.id)
		var road := _road(sid)
		if road.size() < int(cf.road_from) + 2:
			continue
		var i := int(cf.road_from)
		while i < mini(int(cf.road_to), road.size() - 2):
			var a := Vector2i(road[i])
			var reach := int(cf.reach)
			for dy in range(-reach, reach + 1, int(cf.grid)):
				for dx in range(-reach, reach + 1, int(cf.grid)):
					if absi(dx) < min_off and absi(dy) < min_off:
						continue                            # on the road itself (an outlaw camp: well off it)
					var lay := _layout(a + Vector2i(dx, dy) + Vector2i(0, 5))     # the house's door step is five rows below its middle
					cands.append({"lay": lay, "anchor": {"sid": sid, "i": i}})
			i += int(cf.road_step)
	var scored := []
	var seen := {}
	for cd in cands:
		var land: Rect2i = cd.lay.land
		var k := "%d,%d" % [land.position.x, land.position.y]
		if seen.has(k):
			continue
		seen[k] = true
		if refusal(land) != "":
			continue
		var acc: Dictionary = w.wilds.water_access(cd.lay, coins, tools) if w.wilds != null else {"source": "none"}
		if acc.is_empty():
			dry += 1
			continue                                    # no water to be had there (integration directive s.6)
		cd.water = acc
		var sc := _score(cd, trade, n, outlaw)
		scored.append([-float(sc.score), land.position.y, land.position.x, cd, sc])
	scored.sort_custom(func(a: Array, b: Array) -> bool:
		if a[0] != b[0]:
			return a[0] < b[0]
		if a[1] != b[1]:
			return a[1] < b[1]
		return a[2] < b[2])
	for e in scored:
		var cd: Dictionary = e[3]
		var road := _road(str(cd.anchor.sid))
		var from: Vector2i = Vector2i(road[int(cd.anchor.i)])
		var to: Vector2i = cd.lay.house.position + Vector2i(int(w.map.data.stamps[STAMP].door[0]), int(w.map.data.stamps[STAMP].door[1]) + 1)
		if w.map.find_path_world(from, to).is_empty():
			continue
		return {"lay": cd.lay, "anchor": cd.anchor, "why": _why_text(e[4], str(cd.anchor.sid)), "water": cd.get("water", {})}
	if dry > 0:
		_rec("settlement_attempt_failed", {"person": n.id, "reason": "no_water", "sites_without_water": dry, "path": "outlaw" if outlaw else "lawful"})
	return {}


## What the land round a candidate offers: grown trees (timber), boulders (stone), open ground (fields to come, grazing),
## the road's distance to the village (the market), and danger (dense woods for wild animals; the bandits' camp near).
func _score(cd: Dictionary, trade: String, n: NPC, outlaw := false) -> Dictionary:
	var o: Overworld = w.map.overworld
	var cf := cfg()
	var c: Vector2i = (cd.lay.house as Rect2i).get_center()
	var r := int(cf.scan)
	var timber := 0
	var stone := 0
	var open := 0
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var cell := c + Vector2i(dx, dy)
			var t := o.base_tree(cell)
			if not t.is_empty() and not o.changes.has(cell) and not o.is_top(cell):
				timber += 1
			elif o.has_boulder(cell) and not o.rock_gone(cell) and not o.is_top(cell):
				stone += 1
			elif not o.is_solid(cell):
				open += 1
	var cells := float((2 * r + 1) * (2 * r + 1))
	var wt := {"timber": 1.5, "stone": 1.0, "open": 1.0}
	match trade:
		"woodcutter":
			wt = {"timber": 3.0, "stone": 0.5, "open": 0.5}
		"miner":
			wt = {"timber": 1.0, "stone": 4.0, "open": 0.5}
		"farmer", "herder", "manor_hand":
			wt = {"timber": 1.0, "stone": 0.5, "open": 2.5}
		"hunter":
			wt = {"timber": 2.0, "stone": 0.5, "open": 1.0}
	wt.timber = float(wt.timber) + 0.1 * float(n.level("woodcutting"))
	wt.stone = float(wt.stone) + 0.1 * float(n.level("mining"))
	var t_share := float(timber) / cells
	var s_share := float(stone) / cells * 6.0          # boulders are scattered: a few is a good quarry
	var o_share := float(open) / cells
	var market := float(int(cd.anchor.i)) / float(maxi(1, int(cf.road_to)))
	var camp := Vector2(c).distance_to(Vector2(w.bandit_camp))
	var danger := maxf(0.0, t_share - 0.35) * 2.0 + (0.5 if camp < 70.0 and not outlaw else 0.0)
	var wat: Dictionary = cd.get("water", {})
	var water := 0.3 if str(wat.get("source", "")) == "stream" else 0.0      # a stream near beats digging a well
	var score := float(wt.timber) * minf(t_share, 0.4) + float(wt.stone) * minf(s_share, 0.6) + float(wt.open) * o_share * 0.5 \
		- float(cf.market_weight) * market - float(cf.danger_weight) * danger + water
	if outlaw:
		score = t_share + 0.3 * float(int(cd.anchor.i) <= int(cf.outlaw_road_to)) - 0.5 * market + water     # cover, and the village within a night's walk
	return {"score": score, "timber": timber, "stone": stone, "open": open, "market": int(cd.anchor.i), "danger": danger}


func _why_text(sc: Dictionary, sid: String) -> String:
	var best := "open ground"
	if int(sc.timber) >= int(sc.open) / 3 and int(sc.timber) >= int(sc.stone) * 4:
		best = "good timber"
	elif int(sc.stone) * 6 > int(sc.timber):
		best = "stone to quarry"
	var st := w.map.overworld.site(sid)
	return "to %s by the road to %s" % [best, str(st.get("name", sid))]


# ---------------------------------------------------------------- daily --------------------------
## Each dawn (World._new_day, after the construction): the village's population is noted for the decline gate; adults with a
## long housing wait may go; each claim's people are checked (who left its household walks back), a household that cannot
## feed itself or finish its house in time gives up, an ended household's claim is abandoned.
func dawn() -> void:
	var vp := village_people()
	pop_history.append([w.day(), int(vp.alive)])
	var keep := int(cfg().health_days) + 1
	while pop_history.size() > keep:
		pop_history.pop_front()
	for c in claims.duplicate():
		if World.is_player_ref(str(c.owner)) or str(c.status) == "abandoned":
			continue
		var h := World.ref_id(str(c.owner))
		if h < 0 or h >= w.households.size():
			continue
		var hh: Dictionary = w.households[h]
		var members: Array = w.brain._members(h)
		for id in (c.members as Array).duplicate():
			var o := w.npc(int(id))
			if o == null or not o.alive or o.household == h:
				continue
			c.members.erase(id)
			trips.erase(str(id))
			_rec("homestead_member_left", {"claim": str(c.id), "person": int(id), "now": World.hh_ref(o.household)})
			if not w.map.in_village(o.cell()):
				returning[str(id)] = true
				o.plan.clear()
		for o: NPC in members:
			if not (c.members as Array).has(o.id):
				c.members.append(o.id)                 # born there, or joined
				_rec("homestead_member_joined", {"claim": str(c.id), "person": o.id})
		if hh.get("ended", false) or members.is_empty():
			_abandon(c, "ended")
			continue
		_allegiance(c, members)
		_sustain(c, h, members)
		var cash := 0
		for o: NPC in members:
			cash += o.coins
		var unit: Array = w.cheapest_food_unit()
		var broke: bool = w.brain.household_food_days(h) < 0.5 and (int(unit[0]) <= 0 or cash < int(unit[0]))
		c.poor_days = int(c.poor_days) + 1 if broke else 0
		if str(c.get("faction", "lawful")) == "outlaw":
			continue                                    # outlaws do not give up and walk back to the village: they go hungry (WDR-022)
		if int(c.get("dry_days", 0)) >= int(Wilds.cfg().water_fail_days):
			_fail(c, "had no water")
		elif int(c.poor_days) >= int(cfg().starve_days) and w.wilds != null and w.wilds.weigh_turn(c, h):
			continue                                    # they stay on the land, outside the law
		elif int(c.poor_days) >= int(cfg().starve_days):
			_fail(c, "ran out of food and money")
		elif str(c.status) != "built" and w.day() - int(c.day) > int(cfg().give_up_days):
			_fail(c, "could not finish the house")


## A homestead given up (directive section 6, failed attempts): what was delivered to the frame goes back to the household's
## stores (cancelling returns everything), the land is freed, and its people walk back to the village, a village household
## again (Construction finds them a home by the village's rules). Nobody and nothing is erased.
func _fail(c: Dictionary, why: String) -> void:
	var h := World.ref_id(str(c.owner))
	var back := delivered(c)
	if not back.is_empty() and h >= 0:
		var pantry: Inventory = w.households[h].pantry
		for id in back:
			pantry.add(id, int(back[id]))
	if h >= 0 and w.wilds != null:
		var wb := w.wilds.strip_works(c, w.households[h].pantry)
		for id in wb:
			back[id] = int(back.get(id, 0)) + int(wb[id])
	if not c.site.is_empty() and not bool(c.site.done):
		c.site = {}
	c.status = "abandoned"
	c.stage = "gone"
	c.end_day = w.day()
	c.end_why = why
	_count("failed")
	_rec("homestead_failed", {"claim": str(c.id), "owner": str(c.owner), "why": why, "returned": back.duplicate()})
	if h >= 0 and h < w.households.size():
		w.households[h].erase("homestead")
		for o: NPC in w.brain._members(h):
			trips.erase(str(o.id))
			o.plan.clear()
			if not w.map.in_village(o.cell()):
				returning[str(o.id)] = true
		w.note("The %s household gives up its homestead in the country (it %s) and comes back to the village." % [str(w.households[h].family), why])
		w.brain.evaluate_household(h)
	_claim_cache.clear()
	_sync_overworld()


## Property.household_ended: a homestead household with nobody left. Its claim is abandoned; a house standing on it stays
## (an abandoned homestead), materials on an unfinished frame go with the household's stores (the existing escheat rule).
func household_ended(h: int) -> void:
	var c := claim_of_household(h)
	if c.is_empty():
		return
	var back := delivered(c)
	for id in back:
		w.households[h].pantry.add(id, int(back[id]))
	_abandon(c, "ended")


func _abandon(c: Dictionary, why: String) -> void:
	if str(c.status) == "abandoned":
		return
	var hx := World.ref_id(str(c.owner))
	if w.wilds != null and not w.wilds.work_delivered(c).is_empty():
		var into: Inventory = w.households[hx].pantry if hx >= 0 and hx < w.households.size() and not w.households[hx].get("ended", false) else w.granary
		var wb := w.wilds.strip_works(c, into)
		if into == w.granary:
			for id in wb:
				w.stat("escheat_items", float(wb[id]))
	if not c.site.is_empty() and not bool(c.site.done):
		var h := World.ref_id(str(c.owner))
		var back := delivered(c)
		if not back.is_empty() and h >= 0 and h < w.households.size() and not w.households[h].get("ended", false):
			for id in back:
				w.households[h].pantry.add(id, int(back[id]))
		elif not back.is_empty():
			for id in back:
				w.granary.add(id, int(back[id]))        # nobody left to take them: the manor's stores, as a house's goods escheat
				w.stat("escheat_items", float(back[id]))
		c.site = {}
	c.status = "abandoned"
	c.stage = "gone"
	c.end_day = w.day()
	c.end_why = why
	_count("abandoned")
	_rec("homestead_abandoned", {"claim": str(c.id), "owner": str(c.owner), "why": why, "standing": str(c.get("building", "")) != ""})
	_claim_cache.clear()
	_sync_overworld()


# ---------------------------------------------------------------- driving a homesteader ----------
## World._update_npc: `n` is a homesteader (or walking back from a claim) and is not fighting: true when this drives them
## (their plan is laid here, never by the village brain, whose map stops at the village's edge).
func drives(n: NPC) -> bool:
	if returning.has(str(n.id)):
		return true
	if n.household < 0 or n.household >= w.households.size():
		return false
	return w.households[n.household].has("homestead")


## Before each update of a homesteader: eat from the pack when hungry on the way (as a traveller does, Journeys).
func tick(n: NPC) -> void:
	if n.hunger < 40.0 and not n.plan.is_empty():
		for f in NPCBrain.EDIBLE:
			if n.inv.has(f) and f != "wheat":
				n.inv.remove(f)
				n.hunger = minf(100.0, n.hunger + float(GameData.item(f).food))
				w.stat("eaten_food", float(GameData.item(f).food))
				w.stat("eaten_" + f)
				break


## Lay out `n`'s next steps (their plan is empty).
func plan(n: NPC) -> void:
	if returning.has(str(n.id)):
		_plan_return(n)
		return
	var c := claim_of(n)
	if c.is_empty():
		_idle(n, n.cell(), "resting")
		return
	var b: NPCBrain = w.brain
	var hr := w.hour()
	if w.wilds != null and w.wilds.plan_first(n, c):
		return                                          # a raid's legs (the outlaws' own)
	var trip: Dictionary = trips.get(str(n.id), {})
	if not trip.is_empty():
		_plan_trip(n, c, trip)
		return
	var home := _home_cell(c)
	var near_home := n.cell().distance_to(home) <= float(cfg().home_radius)
	if not near_home:
		_lay_home(n, c, "arrive")
		return
	if str(c.status) == "intended":
		_arrive(n, c)                                   # (a loaded save: they were at the site)
		return
	if hr >= NPCBrain.SLEEP or hr < NPCBrain.WAKE:
		_plan_sleep(n, c)
		return
	if n.hunger < float(GameData.b("eat_below")) and _plan_eat(n, c):
		return
	if n.role != "adult" and n.role != "bandit":        # (an outlaw works the claim as any adult does)
		_idle(n, home, "playing by the house" if n.role == "child" else "sitting by the house")
		return
	if str(c.status) == "claimed" and _carries_need(n, c):
		n.doing = "carrying materials to the frame"
		n.plan = [b.go(step_of(c)), b.doit("homestead", {"step": "deliver"})]
		return
	if hr >= NPCBrain.WORK_START and hr < 12.0 and _wants_trip(n, c):
		_start_trip(n, c)
		return
	if hr >= NPCBrain.WORK_START and hr < NPCBrain.WORK_END and w.wilds != null and w.wilds.plan_work(n, c):
		return                                          # water, the claim's works, its animals, its workshop
	if hr >= NPCBrain.WORK_START and hr < NPCBrain.WORK_END and w.wilds != null and w.wilds.plan_hunt(n, c):
		return                                          # game in the open country round the claim, when food runs low (or a hunter's trade)
	if hr >= NPCBrain.WORK_START and hr < NPCBrain.WORK_END and _plan_livelihood(n, c):
		return
	_idle(n, home, "about the homestead")


func _home_cell(c: Dictionary) -> Vector2i:
	return step_of(c)


func _idle(n: NPC, around: Vector2i, doing: String) -> void:
	var b: NPCBrain = w.brain
	var to := around
	for k in 6:
		var cell := around + Vector2i((n.id * 7 + k * 3 + int(w.minutes / 60.0)) % 7 - 3, (n.id * 5 + k * 11 + int(w.minutes / 90.0)) % 5 - 2)
		if not w.map.is_solid_world(cell):
			to = cell
			break
	n.doing = doing
	n.plan = [b.go(to, 0.7), b.work(45.0, "", {}, "idle")]


func _plan_sleep(n: NPC, c: Dictionary) -> void:
	var b: NPCBrain = w.brain
	var until := NPCBrain.WAKE + 24.0 if w.hour() >= NPCBrain.SLEEP else NPCBrain.WAKE
	var mins := maxf((until - w.hour()) * 60.0, 10.0)
	var at := step_of(c)
	if str(c.get("building", "")) != "":
		var beds := spots_of(c, "bed")
		var members: Array = c.members
		var k := maxi(0, members.find(n.id))
		if not beds.is_empty():
			at = beds[k % beds.size()].use
		n.doing = "asleep at home"
	else:
		n.doing = "sleeping rough by the frame"
	n.plan = [b.go(at), b.work(mins, "rest_end", {"min": mins, "morning": true}, "sleep")]


func _plan_eat(n: NPC, c: Dictionary) -> bool:
	var b: NPCBrain = w.brain
	var pantry: Inventory = w.households[n.household].pantry
	var has := false
	for f in NPCBrain.EDIBLE:
		has = has or pantry.has(f) or n.inv.has(f)
	if not has:
		return false
	var at := step_of(c)
	if str(c.get("building", "")) != "":
		var tables := spots_of(c, "table")
		if not tables.is_empty():
			at = tables[0].use
	n.doing = "eating at home"
	n.plan = [b.go(at), b.work(15.0, "eat_home", {}, "idle")]
	return true


func _carries_need(n: NPC, c: Dictionary) -> bool:
	for id in c.site.get("need", {}):
		if n.inv.has(str(id)) or (str(id) == "stone" and n.inv.has("rubble")):
			return true
	return false


## The work their trade and the land give (directive section 7): felling the trees round the homestead (an axe), or
## breaking its boulders for stone (a miner with a pickaxe), through the village's own acts (chop, mine).
func _plan_livelihood(n: NPC, c: Dictionary) -> bool:
	var b: NPCBrain = w.brain
	var trade := str((c.trades as Dictionary).get(str(n.id), c.trade))
	if str(c.status) == "claimed" and n.inv.has("axe"):
		var standing := clear_ground(c)
		if not standing.is_empty():
			var at: Vector2i = standing[0]
			var mins0 := CapabilityHook.work_time(float(GameData.b("chop_minutes")), "forestry", Skills.value(n, "woodcutting", "chop_time", 1.0), n)
			n.doing = "clearing the ground for the house"
			n.plan = [b.go(b.beside(at, n.cell(), 0, true)), b.work(mins0, "chop", {"x": at.x, "y": at.y}, "work", at)]
			return true
	if n.inv.count("log") + n.inv.count("stone") >= int(cfg().sell_at) * 2:
		return false                                    # the pack is full of goods: a trip is due (or nobody buys)
	if trade == "miner" and n.inv.has("pickaxe"):
		var rock := _near_boulder(c, n)
		if rock.x != 1 << 30:
			n.doing = "breaking stone"
			n.plan = [b.go(b.beside(rock, n.cell(), 0, true)), b.work(float(GameData.b("mine_minutes")), "mine", {"x": rock.x, "y": rock.y}, "work", rock)]
			return true
	if str(c.status) != "intended" and _plan_field(n, c, trade):      # (food is grown from the claiming on, not only once the house stands)
		return true
	if n.inv.has("axe"):
		var t := _near_tree(c, n)
		if t.x != 1 << 30:
			var mins := CapabilityHook.work_time(float(GameData.b("chop_minutes")), "forestry", Skills.value(n, "woodcutting", "chop_time", 1.0), n)
			n.doing = "felling a tree"
			n.plan = [b.go(b.beside(t, n.cell(), 0, true)), b.work(mins, "chop", {"x": t.x, "y": t.y}, "work", t)]
			return true
	return false


## B25R1-014: a homestead's own field, by the village's farming rules (Farming: its cells, one seed a cell, the season's
## growth, the crop's yield and seed back), worked by its people: harvest what is ripe into the pantry, sow tilled soil with
## seed from the pantry, till new ground on the claim (outside the house's ground, off the door's way) up to field_cells.
## Farmers, herders and hands first; anyone when the household's food runs low.
func field_cells(c: Dictionary) -> Array:
	var out := []
	var land := rect_of(c)
	for y in range(land.position.y, land.end.y):
		for x in range(land.position.x, land.end.x):
			if w.farm.cells.has(Vector2i(x, y)):
				out.append(Vector2i(x, y))
	return out


func _field_spot(c: Dictionary) -> Vector2i:
	var land := rect_of(c)
	var ring := house_of(c).grow(1)
	var door := door_of(c)
	for y in range(land.position.y, land.end.y):
		for x in range(land.position.x, land.end.x):
			var cell := Vector2i(x, y)
			if ring.has_point(cell) or absi(x - door.x) <= 1 or w.farm.cells.has(cell) or _ground(cell) != "open" or not w.farm.obstacle(cell).is_empty():
				continue
			return cell
	return Vector2i(1 << 30, 0)


func _plan_field(n: NPC, c: Dictionary, trade: String) -> bool:
	var farmer: bool = trade in ["farmer", "herder", "manor_hand"] or w.brain.household_food_days(n.household) < float(cfg().food_low_days)
	if not farmer:
		return false
	var pantry: Inventory = w.households[n.household].pantry
	var cells := field_cells(c)
	for cell: Vector2i in cells:
		if str(w.farm.cells[cell].state) == "ripe":
			n.doing = "harvesting the field"
			return _field_step(n, cell, "farm_harvest", 20.0)
	if not w.farm.can_sow_now():
		return false
	for cell: Vector2i in cells:
		if str(w.farm.cells[cell].state) == "tilled" and _seed_in(pantry) != "":
			n.doing = "sowing the field"
			return _field_step(n, cell, "farm_sow", 10.0)
	if cells.size() < int(cfg().field_cells):
		var spot := _field_spot(c)
		if spot.x != 1 << 30:
			n.doing = "breaking ground for a field"
			return _field_step(n, spot, "farm_till", 60.0)
	return false


func _field_step(n: NPC, cell: Vector2i, step: String, mins: float) -> bool:
	var b: NPCBrain = w.brain
	n.plan = [b.go(b.beside(cell, n.cell(), 0, true)), b.work(mins, "homestead", {"step": step, "x": cell.x, "y": cell.y}, "work", cell)]
	return true


func _seed_in(inv: Inventory) -> String:
	for id in Farming.crops():
		var seed := str(Farming.crops()[id].seed)
		if inv.has(seed):
			return seed
	return ""


## The field work's end (NPCBrain.act "homestead"): the cell's change by Farming's own record and stats.
func _field_act(n: NPC, c: Dictionary, step: String, cell: Vector2i) -> bool:
	if claim_at(cell) != c or n.cell().distance_to(cell) > 2.5:
		return false
	var pantry: Inventory = w.households[n.household].pantry
	match step:
		"farm_till":
			if w.farm.cells.has(cell) or not w.farm.obstacle(cell).is_empty():
				return false
			w.farm.cells[cell] = {"crop": "", "state": "tilled", "progress": 0.0}
			w.stat("farm_tilled")
			Skills.gain(n, "farming", Skills.action_xp("till"))
			w.farm._show_around(cell)
		"farm_sow":
			var seed := _seed_in(pantry)
			if seed == "" or not w.farm.cells.has(cell) or str(w.farm.cells[cell].state) != "tilled" or not w.farm.can_sow_now():
				return false
			pantry.remove(seed, 1)
			w.stat("used_" + seed)
			w.farm.cells[cell] = {"crop": Farming.crop_of_seed(seed), "state": "growing", "progress": 0.0}
			Skills.gain(n, "farming", Skills.action_xp("sow"))
			w.farm._show_around(cell)
		"farm_harvest":
			var got := w.farm.harvest_into(cell, pantry)
			if got.is_empty():
				return false
			Skills.gain(n, "farming", Skills.action_xp("harvest"))
			_count("field_harvests")
			_rec("wild_production", {"claim": str(c.id), "by": n.id, "action": "farm", "goods": got})
	return true


func _near_tree(c: Dictionary, n: NPC) -> Vector2i:
	var o: Overworld = w.map.overworld
	var home := house_of(c).get_center()
	var r := int(cfg().home_radius)
	var best := Vector2i(1 << 30, 0)
	var bd := 1 << 30
	var seen := {}
	for dy in [-r, 0, r]:
		for dx in [-r, 0, r]:
			var cc := Overworld.chunk_of(home + Vector2i(dx, dy))
			if seen.has(cc):
				continue
			seen[cc] = true
			for t in o.chunk_trees(cc):
				if t.is_empty() or str(t.state) != "grown":
					continue
				var at := Vector2i(int(t.x), int(t.y))
				if absi(at.x - home.x) > r or absi(at.y - home.y) > r or o.is_top(at) or house_of(c).grow(1).has_point(at):
					continue
				var d := absi(at.x - n.cell().x) + absi(at.y - n.cell().y)
				if d < bd or (d == bd and (at.y < best.y or (at.y == best.y and at.x < best.x))):
					bd = d
					best = at
	return best


func _near_boulder(c: Dictionary, n: NPC) -> Vector2i:
	var o: Overworld = w.map.overworld
	var home := house_of(c).get_center()
	var r := int(cfg().home_radius)
	var best := Vector2i(1 << 30, 0)
	var bd := 1 << 30
	for y in range(home.y - r, home.y + r + 1):
		for x in range(home.x - r, home.x + r + 1):
			var at := Vector2i(x, y)
			if not o.has_boulder(at) or o.boulder_at(at).is_empty() or o.is_top(at):
				continue
			var d := absi(at.x - n.cell().x) + absi(at.y - n.cell().y)
			if d < bd:
				bd = d
				best = at
	return best


## A market trip is due (one adult of a household a day): food for the pantry runs low, goods pile up to sell, the house
## needs materials the household can pay for, or a tool of their work is missing.
func _wants_trip(n: NPC, c: Dictionary) -> bool:
	if int(c.get("trip_day", -1)) == w.day():
		return false
	if w.wilds != null and w.wilds.wants_water_trip(c):
		return true                                     # no water of their own yet: to the village's well
	var cf := cfg()
	var h := n.household
	if w.brain.household_food_days(h) < float(cf.food_low_days) and n.coins >= 3:
		return true
	var unsold := w.day() - int(c.get("unsold_day", -99)) < 3          # nobody bought what they brought lately
	if not unsold and (n.inv.count("log") - int(cf.keep_logs) >= int(cf.sell_at) or n.inv.count("stone") >= int(cf.sell_at)):
		return true
	var trade := str((c.trades as Dictionary).get(str(n.id), c.trade))
	if not n.inv.has("axe") and not (trade == "miner" and n.inv.has("pickaxe")) and n.coins >= 10:
		return true
	if str(c.status) == "claimed":
		for id in c.site.need:
			if str(id) == "log" and n.inv.has("axe"):
				continue
			if n.coins - w.reserve_of(n) >= ceili(GameData.value(str(id)) * 1.5):
				return true
	return false


func _start_trip(n: NPC, c: Dictionary) -> void:
	c.trip_day = w.day()
	var pantry: Inventory = w.households[n.household].pantry
	var spare := pantry.count("log") - int(cfg().keep_logs)
	if spare > 0:
		w.transfer(pantry, n.inv, "log", spare)          # the logs beyond the hearth's go to market
	trips[str(n.id)] = {"claim": str(c.id), "leg": "out", "n": 0, "day": w.day(), "tried": {}}
	_count("trips")
	_rec("homestead_trip", {"claim": str(c.id), "by": n.id, "pantry_days": snappedf(w.brain.household_food_days(n.household), 0.1), "coins": n.coins})
	_lay_village(n, c)


func _plan_trip(n: NPC, c: Dictionary, trip: Dictionary) -> void:
	match str(trip.leg):
		"out":
			if w.map.in_village(n.cell()):
				trip.leg = "market"
				_plan_trip(n, c, trip)
				return
			_lay_village(n, c)
		"market":
			if not w.map.in_village(n.cell()):
				_lay_village(n, c)
				return
			if not _errand(n, c, trip):
				trip.leg = "back"
				_lay_home(n, c, "home")
		_:
			_lay_home(n, c, "home")


## One errand at the village market (directive section 8, through the village's own trade): a meal when hungry; selling the
## logs and stone they brought; a tool of their work; grain and food for the household's pantry; the materials the house
## still needs, within what they may spend (NPCBrain.buy_qty: a reserve kept above necessities). False when nothing is left
## to do (they go home).
func _errand(n: NPC, c: Dictionary, trip: Dictionary) -> bool:
	var b: NPCBrain = w.brain
	var cf := cfg()
	var tried: Dictionary = trip.tried
	trip.n = int(trip.n) + 1
	if int(trip.n) > int(cf.trip_errands) or w.hour() >= 16.0:
		return false
	if n.hunger < float(GameData.b("eat_below")) and not tried.has("meal"):
		tried.meal = true
		var v := b._vendor_with_food(n)
		if v != null:
			n.doing = "buying a meal in the village"
			n.plan = [b.go(b._workplace_cell(v)), b.doit("buy_food", {"vendor": v.id, "pantry": false}), b.work(10.0, "eat", {}, "idle")]
			return true
	var need: Dictionary = c.site.get("need", {}) if str(c.status) == "claimed" else \
		w.construction.cost_of("house") if str(c.status) == "intended" else {}
	for id in ["log", "stone", "rubble"]:
		var keep := int(cf.keep_logs) + int(need.get(id, 0)) if id == "log" else int(need.get("stone", 0)) if id == "stone" else 0
		if n.inv.count(id) > keep and not tried.has("sell_" + id):
			tried["sell_" + id] = true
			if b._buyer_for(n, id) != null:
				b._plan_sell(n, id)
				return true
			if id == "log":
				var hh := _firewood_buyer(n)
				if hh >= 0:
					n.doing = "selling firewood at a door"
					n.plan = [b.go(w.household_cell(hh, n.cell())), b.doit("homestead", {"step": "firewood", "hh": hh})]
					return true
			c.unsold_day = w.day()                      # nobody in the village buys it today
			_count("unsold_" + id)
	var trade := str((c.trades as Dictionary).get(str(n.id), c.trade))
	var tool := "pickaxe" if trade == "miner" else "axe"
	if not n.inv.has(tool) and not tried.has("tool"):
		tried.tool = true
		if b._buy_tool(n, tool):
			return true
		n.plan.clear()
	if w.brain.household_food_days(n.household) < float(cf.food_target_days) and int(tried.get("food", 0)) < 4:
		tried.food = int(tried.get("food", 0)) + 1
		var grain := b._grain_seller(n)
		var want := 2 * maxi(1, w.brain._members(n.household).size())
		var q := b.buy_qty(n, grain, "wheat", want, true) if grain != null else 0
		if q > 0:
			n.doing = "buying grain for the homestead"
			n.plan = [b.go(b._workplace_cell(grain) if grain.job != "farmer" else grain.cell()), b.doit("buy_from", {"vendor": grain.id, "item": "wheat", "qty": q, "pantry": true})]
			return true
		var v := b._vendor_with_food(n)
		if v != null and n.coins >= 3:
			n.doing = "buying food for the homestead"
			n.plan = [b.go(b._workplace_cell(v)), b.doit("buy_food", {"vendor": v.id, "pantry": true})]
			return true
	var trade_s := str((c.trades as Dictionary).get(str(n.id), c.trade))
	if str(c.status) != "intended" and (trade_s in ["farmer", "herder", "manor_hand"] or w.brain.household_food_days(n.household) < float(cf.food_low_days)) and _seed_in(w.households[n.household].pantry) == "" and not tried.has("seed"):
		tried.seed = true
		for sv: NPC in w.npcs:
			if sv.alive and sv != n and not away(sv) and not w.asleep(sv) and w.farm.sells_seed(sv):
				for cid in Farming.crops():
					var sd := str(Farming.crops()[cid].seed)
					var sq := b.buy_qty(n, sv, sd, 4, true) if sv.inv.count(sd) > 0 else 0
					if sq > 0:
						n.doing = "buying seed for the homestead's field"
						n.plan = [b.go(b._workplace_cell(sv) if sv.job != "farmer" else sv.cell()), b.doit("buy_from", {"vendor": sv.id, "item": sd, "qty": sq, "pantry": true})]
						return true
	if (w.households[n.household].pantry as Inventory).count("log") < 1 and not n.inv.has("log") and not tried.has("firewood"):
		tried.firewood = true
		var s := b._seller_of("log", n)
		if s != null and b.buy_qty(n, s, "log", 2, true) > 0:
			n.doing = "buying firewood"
			n.plan = [b.go(b._workplace_cell(s)), b.doit("buy_from", {"vendor": s.id, "item": "log", "qty": b.buy_qty(n, s, "log", 2, true), "pantry": true})]
			return true
	if str(c.status) != "intended" and w.wilds != null and w.wilds.errand(n, c, trip):
		return true                                     # animals for the pen, what the claim's open work needs
	for id in ["plank", "building_block", "log", "stone", "iron_bar"]:
		if not need.has(id) or tried.has("buy_" + id):
			continue
		if id == "log" and n.inv.has("axe"):
			continue                                    # they fell their own
		var want := int(need[id]) - n.inv.count(id)
		if want <= 0:
			continue
		var s := _material_seller(id, n)
		var q := b.buy_qty(n, s, id, want) if s != null else 0
		tried["buy_" + id] = true
		if q > 0:
			n.doing = "buying %s for the house" % GameData.item_name(id).to_lower()
			n.plan = [b.go(b._workplace_cell(s)), b.doit("buy_from", {"vendor": s.id, "item": id, "qty": q})]
			return true
	return false


## A village household short of firewood (fewer than two logs in its pantry, NPCBrain's evening provisioning would buy them)
## whose purse can pay a log's price: the homesteader sells at its door (World.trade, the household's payer, logs into its
## pantry). B25R1-014: the village's businesses are often stocked by their own woodcutters; households are buyers too. -1 none.
func _firewood_buyer(n: NPC) -> int:
	var price := w.sell_price(n, "log")
	for h in w.households.size():
		var hh: Dictionary = w.households[h]
		if hh.get("ended", false) or hh.has("homestead") or str(hh.home) == "" or (hh.pantry as Inventory).count("log") >= 2:
			continue
		for o: NPC in w.brain._members(h):
			if o.role != "child" and o.coins >= price + w.reserve_of(o):
				return h
	return -1


func _sell_firewood(n: NPC, h: int) -> bool:
	var price := w.sell_price(n, "log")
	var keep := int(cfg().keep_logs)
	var q := mini(2 - (w.households[h].pantry as Inventory).count("log"), n.inv.count("log") - keep)
	if q <= 0:
		return false
	var payer: NPC = null
	for o: NPC in w.brain._members(h):
		if o.role != "child" and o.coins >= price * q + w.reserve_of(o) and (payer == null or o.coins > payer.coins):
			payer = o
	if payer == null or not w.trade(payer, n, "log", q, price):
		return false
	w.transfer(payer.inv, w.households[h].pantry, "log", q)
	_count("firewood_sold", q)
	_rec("homestead_trade", {"by": n.id, "to": World.hh_ref(h), "item": "log", "qty": q, "price": price})
	return true


## The nearest villager awake who sells a building material (Construction.SELLERS) and holds some to spare.
func _material_seller(id: String, n: NPC) -> NPC:
	var best: NPC = null
	var bd := 1e9
	for o: NPC in w.npcs:
		if o == n or not o.alive or w.asleep(o) or away(o) or not w.construction._sells(o, id) or o.inv.count(id) <= w.construction._keeps(o, id):
			continue
		var d := n.pos.distance_to(o.pos)
		if d < bd:
			bd = d
			best = o
	return best


# ---------------------------------------------------------------- routes -------------------------
## A walk laid out like a journey's (Journeys.resume): the village's path to the gate, the road, the last cells over the
## world's ground; then an act at the end.
func _lay(n: NPC, path: PackedVector2Array, step: String, doing: String) -> void:
	var b: NPCBrain = w.brain
	if path.is_empty():
		_count("no_path")
		n.doing = "resting"
		n.plan = [b.wait(n, 60.0)]
		return
	n.path = path
	n.path_i = 0
	n.doing = doing
	n.plan = [{"k": "go", "to": Vector2i(path[path.size() - 1]), "pathed": true}, b.doit("homestead", {"step": step})]


func _gate_cells() -> Array:
	var gi := _gate_index()
	var gate: Dictionary = w.map.exits()[gi]
	return [Vector2i(gate.out) - Vector2i(gate.dir), Vector2i(gate.out)]


func _append(out: PackedVector2Array, cells: PackedVector2Array) -> void:
	for p in cells:
		if out.is_empty() or out[out.size() - 1] != p:
			out.append(p)


## From where `n` stands to their claim's door step.
func _path_home(n: NPC, c: Dictionary) -> PackedVector2Array:
	var out := PackedVector2Array()
	var road := _road(str(c.anchor.get("sid", "")))
	var ai := int(c.anchor.get("i", -1))
	var to := step_of(c)
	var at := n.cell()
	if road.is_empty() or ai < 0 or ai >= road.size():
		return w.map.find_path_world(at, to)
	if w.map.in_village(at):
		var g: Array = _gate_cells()
		_append(out, w.map.find_path(at, g[0]))
		out.append(Vector2(g[1]))
		for q in range(0, ai + 1):
			out.append(road[q])
		at = Vector2i(road[ai])
	elif at.distance_to(to) > 30.0:
		var k := Journeys._nearest(road, at)
		if absi(Vector2i(road[k]).x - at.x) + absi(Vector2i(road[k]).y - at.y) > 1:
			_append(out, w.map.find_path_world(at, Vector2i(road[k])))
		var stepq := 1 if k <= ai else -1
		var q := k
		while q != ai:
			out.append(road[q])
			q += stepq
		out.append(road[ai])
		at = Vector2i(road[ai])
	_append(out, w.map.find_path_world(at, to))
	return out


## From where `n` stands to inside the village's gate (their claim's road back, or the nearest road).
func _path_village(n: NPC, road: PackedVector2Array, ai: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	var g: Array = _gate_cells()
	var at := n.cell()
	if w.map.in_village(at):
		return w.map.find_path(at, g[0])
	if road.is_empty():
		return w.map.find_path_world(at, g[1])
	var k := Journeys._nearest(road, at) if ai < 0 or at.distance_to(Vector2(road[ai])) > 30.0 else ai
	var start := Vector2i(road[k])
	if at != start:
		_append(out, w.map.find_path_world(at, start))
	for q in range(k, -1, -1):
		out.append(road[q])
	out.append(Vector2(g[0]))
	return out


func _lay_home(n: NPC, c: Dictionary, step: String) -> void:
	_lay(n, _path_home(n, c), step, "on the way home to the homestead")


func _lay_village(n: NPC, c: Dictionary) -> void:
	var road := _road(str(c.anchor.get("sid", "")))
	_lay(n, _path_village(n, road, int(c.anchor.get("i", -1))), "village", "on the road to the village market")


## A villager whose homestead is no more, or who left its household, walks back to the village.
func _plan_return(n: NPC) -> void:
	if w.map.in_village(n.cell()):
		returning.erase(str(n.id))
		_count("returned")
		n.plan.clear()
		if not away(n):
			w.brain.decide(n)
		return
	var road := PackedVector2Array()
	var bk := 1 << 30
	for st in w.map.overworld.sites:
		var r := _road(str(st.id))
		if r.is_empty():
			continue
		var k := Journeys._nearest(r, n.cell())
		var d := absi(Vector2i(r[k]).x - n.cell().x) + absi(Vector2i(r[k]).y - n.cell().y)
		if d < bk:
			bk = d
			road = r
	_lay(n, _path_village(n, road, -1), "returned", "walking back to the village")


## A homesteader's act at the end of a walk (NPCBrain.act "homestead").
func act(n: NPC, a: Dictionary) -> bool:
	var step := str(a.get("step", ""))
	if step == "returned":
		if w.map.in_village(n.cell()):
			returning.erase(str(n.id))
			_count("returned")
		return true
	var c := claim_of(n)
	if c.is_empty():
		return false
	match step:
		"village":
			var trip: Dictionary = trips.get(str(n.id), {})
			if not trip.is_empty():
				trip.leg = "market"
			return true
		"home", "arrive":
			if w.wilds != null and (trips.has(str(n.id)) or str(c.status) == "intended"):
				w.wilds.carried_home(n, c)               # water carried from the village's well on the way
			trips.erase(str(n.id))
			if str(c.status) == "intended":
				if n.cell().distance_to(step_of(c)) > float(cfg().home_radius):
					_count("walk_short")
					return false                        # the walk ended short of the land (a bounded path): they walk on next
				_arrive(n, c)
			_unpack(n, c)
			return true
		"firewood":
			return _sell_firewood(n, int(a.get("hh", -1)))
		"farm_till", "farm_sow", "farm_harvest":
			return _field_act(n, c, step, Vector2i(int(a.get("x", 0)), int(a.get("y", 0))))
		"deliver":
			if n.cell().distance_to(step_of(c)) > 2.5:
				return false
			deliver(c, n.inv, World.npc_ref(n.id))
			return true
	return w.wilds.act(n, c, step, a) if w.wilds != null else false


## At home: the food carried goes into the household's pantry (the family chest) and logs for the hearth up to keep_logs; the
## rest of the logs stay in the pack, to be sold (a homesteader holds no village trade, so NPCBrain.stock_family_chest would
## take every log for the hearth).
func _unpack(n: NPC, c: Dictionary) -> void:
	var pantry: Inventory = w.households[n.household].pantry
	for f in NPCBrain.EDIBLE + ["meat"]:
		var k := n.inv.count(f)
		if k > 0 and w.transfer(n.inv, pantry, f, k):
			w.stat("family_chest_stocked", k)
	var need_logs := int(c.site.get("need", {}).get("log", 0)) if str(c.status) == "claimed" else 0
	var spare := n.inv.count("log") - need_logs
	var want := int(cfg().keep_logs) - pantry.count("log")
	if want > 0 and spare > 0:
		w.transfer(n.inv, pantry, "log", mini(want, spare))
	elif want < 0:
		w.transfer(pantry, n.inv, "log", -want)        # more on the hearth than it burns: back into the pack, for sale


## The first of them reaches the chosen land: it is claimed now if it is still free (else they look again from where they
## stand, and give up when there is no land to be had), and the house is marked out.
func _arrive(n: NPC, c: Dictionary) -> void:
	if str(c.status) != "intended":
		return
	if refusal(rect_of(c), str(c.id)) != "":
		var site := find_site(n)
		if site.is_empty():
			_fail(c, "found the land taken and no other")
			return
		var land: Rect2i = site.lay.land
		var house: Rect2i = site.lay.house
		c.x = land.position.x
		c.y = land.position.y
		c.w = land.size.x
		c.h = land.size.y
		c.house = {"x": house.position.x, "y": house.position.y, "w": house.size.x, "h": house.size.y, "door": [int(site.lay.door.x), int(site.lay.door.y)]}
		c.anchor = site.anchor
		c.why = str(site.why)
		_count("relocated")
		n.plan.clear()
		return
	_mark_site(c)
	c.claimed_at = [n.cell().x, n.cell().y]             # where the claimant stood when claiming (on the land)
	clear_ground(c)
	c.stage = "build"
	if w.wilds != null:
		w.wilds.choose_water(c, c.get("pending_water", {}))
	c.erase("pending_water")
	_count("claimed")
	_rec("homestead_claimed", {"claim": str(c.id), "owner": str(c.owner), "by": n.id, "land": [c.x, c.y, c.w, c.h]})
	w.note("%s %s claims a piece of open country and marks out a house on it." % [n.name, n.family])


# ---------------------------------------------------------------- measurement --------------------
## The demographic line (tests/economy_sim.gd HOMESTEAD; directive section 14): the village by age, the rural people, the
## claims by state and the counts.
func report() -> Dictionary:
	var ages := {"child": 0, "adolescent": 0, "adult": 0, "elder": 0}
	var rural := 0
	var rural_hh := {}
	var village := 0
	for n: NPC in w.npcs:
		if not n.alive or n.role == "bandit" or n.clan != "":
			continue
		if drives(n) and not returning.has(str(n.id)):
			rural += 1
			rural_hh[n.household] = true
			continue
		village += 1
		var st := Life.stage(n, w.minutes)
		ages[st] = int(ages.get(st, 0)) + 1
	var by := {}
	for c in claims:
		var k := str(c.status)
		by[k] = int(by.get(k, 0)) + 1
	var total := village + rural
	return {"village": village, "village_ages": ages, "rural": rural, "rural_households": rural_hh.size(),
		"rural_share": snappedf(float(rural) / float(maxi(1, total)), 0.001), "claims": by, "counts": counts.duplicate(),
		"births": int(w.stats.get("births", 0)), "deaths_old_age": int(w.stats.get("old_age_deaths", 0)),
		"households_founded": int(w.stats.get("households_founded", 0))}


# ---------------------------------------------------------------- saving -------------------------
func to_dict() -> Dictionary:
	var cl := []
	for c in claims:
		var d: Dictionary = c.duplicate(true)
		d.store = (c.store as Inventory).to_dict()
		cl.append(d)
	return {"format": FORMAT, "claims": cl, "next_id": next_id, "pop_history": pop_history.duplicate(true),
		"last_left": last_left.duplicate(), "returning": returning.duplicate(), "trips": trips.duplicate(true), "counts": counts.duplicate()}


func load_dict(d: Dictionary) -> void:
	claims.clear()
	for e in d.get("claims", []):
		var c: Dictionary = (e as Dictionary).duplicate(true)
		c.store = Inventory.from_dict(e.get("store", {}))
		c.members = (c.get("members", []) as Array).map(func(x): return int(x))
		c.known = (c.get("known", []) as Array).map(func(x): return int(x))
		c.founder = int(c.get("founder", -1))
		var site: Dictionary = c.get("site", {})
		for k in ["cost", "need"]:
			if site.has(k):
				var ints := {}
				for id in site[k]:
					ints[str(id)] = int(site[k][id])     # (a JSON save reads numbers as floats)
				site[k] = ints
		claims.append(c)
	next_id = int(d.get("next_id", claims.size() + 1))
	pop_history = (d.get("pop_history", []) as Array).duplicate(true)
	last_left = (d.get("last_left", {}) as Dictionary).duplicate()
	returning = (d.get("returning", {}) as Dictionary).duplicate()
	trips = (d.get("trips", {}) as Dictionary).duplicate(true)
	counts = (d.get("counts", {}) as Dictionary).duplicate()
	_claim_cache.clear()
	_sync_overworld()


## B25R1-016 (the 365-day flight recorder): every stage of a homestead's life and every life choice is offered to the recorder,
## read only (never a state change, never a random number): recorder.life_event(kind, data) when the recorder has it (its
## vocabulary is the recorder worker's, wip/b25r1-recorder); people by their Identity ids, households "hh:<n>", claims by id.
func _rec(kind: String, data: Dictionary) -> void:
	if w.recorder != null and w.recorder.has_method("life_event"):
		data["day"] = w.day()
		w.recorder.life_event(kind, data)
