class_name Business
extends RefCounted
## The player's market stall (PL1-10, stages 1 and 2; docs/BUILD_DECISIONS.md "Player businesses").
##
## Stage 1: the manor keeps a few open market pitches (World.stalls entries with `pitch: true`, drawn beside
## the merchants' stalls). The player rents one for stall_rent_day coins a day (paid to the manor's treasury at
## the first morning and then each morning; the first day is paid on renting), moves goods from the pack into the
## stall's sale stock, sets a price per item, edits or removes listings, reads the stock and the sales record,
## collects the till, and closes the stall without losing anything. Rent not paid (from the pack, then the
## till) for stall_evict_days mornings gives the pitch back: the unsold goods and the till return to the
## player, whatever does not fit the pack lies at the stall as loot. Sales happen only while the player is at
## the stall (within stall_range tiles of it), or while an attendant is at it (stage 4, below).
##
## Stage 2: villagers buy from the open stall only for needs they really have (needs()), with their own coins
## (never below a cash floor), only when the price is not above what they would pay the merchants (ceiling()),
## and the goods go into their pack (or their household's pantry). Needs are the ones the brain already
## models: a trade's stock thresholds (NPCBrain.BUYS / wants), a missing tool, the guards' gear, the
## household's firewood and food (NPCBrain._plan_provision), and the materials open building sites ask for
## (Construction.open_need). A met need buys nothing more. Evaluated once an hour (hour()), at most
## stall_buyers_per_hour buyers walk to the stall (a "buy_stall" step in their plan, resolved by arrive()).
##
## State lives in the stall's own dict (saved with World.stalls): tenant, stock {id: qty}, prices {id: coins},
## sales [{day, hour, who, item, qty, price}], till, earned, paid_day, missed, costs {rent, wages, upgrade}.
##
## Stage 3: the same record also serves a larger stall (an upgrade: `large`, more kinds, a display, a wider
## reach, higher rent) and a permanent shop. A shop is a counter placed in a room of the player's (Fitting) with
## the shop's record in that building's own dict (`building.shop`, saved with the building): the same stock,
## prices, sales, till and rent fields, a daily licence in place of the stall's rent, shelves that raise the
## kinds it can hold, stock chests that hold spare stock (`store`) which refills a shelf that sells out, and the
## trade it is following its equipment (Fitting.trade). Revenue, expenses (rent or licence, wages) and profit
## are kept for both.
##
## B18-DP-01: an attendant also works the player's own workshop stations on the player's production orders (BusinessWorks).
##
## Stage 4: the player may hire an attendant for a stall or shop: an adult without a trade of their own (NPCBrain plans
## their day through plan_attendant, so they are a real villager walking to the counter in the working day and
## sleeping at night). The wage is paid every morning from the till, then the purse. A premises sells
## while the player is near or its attendant is at the counter; with neither it does not sell.
##
## Market stalls (STALL-01..06, owner 2026-10-21; scripts/core/stalls.gd, `stalls`): a stall built from three planks
## (`built`) sells unattended while OPEN, and every market stall (built, pitch, merchant's) settles each session's
## sales on closing, 5% to the manor. A pitch is open from its renting until it is closed (collect() closes it and
## settles), and its open session's proceeds cannot be taken or spent (Q13). Shops and storefronts keep their terms.

## The manor's open pitches are village.json "pitches" since generator v16 (GP-MARKET-SPACING): {id, x, y, use, service}; the
## tailor's and the barber's (TAILOR-18, BARBER-18) are let to them, never to the player.
static func pitch_specs(m: VillageMap) -> Array:
	return m.data.get("pitches", [])
const AWNING := [1890, 3502]          # the merchants' stall art (ground layer "below0"), two tiles wide
const PRICE_CAP := 4                  # a listing may be priced up to this many times the item's value
const HIRABLE := Construction.HIRABLE   # villagers free to be hired for a day: out of work, a manor hand with no job taken, a labourer

var w: World
var heading := {}                     # npc id -> game hour they set out for the stall (not saved)
var stalls: Stalls                    # market stalls: building, sessions and the 5% settlement (STALL-01..06)
var money: BusinessMoney              # villagers' storefront tills and the owner's pay (ECON-P3)
var works: BusinessWorks              # the attendant's production at the player's own stations (B18-DP-01)


func _init(world: World) -> void:
	w = world
	stalls = Stalls.new(world, self)
	money = BusinessMoney.new(world)
	works = BusinessWorks.new(world, self)


# ---------------------------------------------------------------- pitches --------------------
## Add the manor's open pitches (new worlds, and saves made before they existed) and draw them.
static func add_pitches(world: World, m: VillageMap) -> void:
	var lay: Dictionary = {}
	for l in m.data.layers:
		if str(l.name) == "below0":
			lay = l
	for p in pitch_specs(m):
		var id: String = p.id
		if not world.stalls.has(id):
			# made as a loaded one is (JSON numbers), so a save of an upgraded old save is the same as of the next load
			world.stalls[id] = JSON.parse_string(JSON.stringify({"id": id, "x": int(p.x), "y": int(p.y), "use": [int(p.x), int(p.y) + 1],
				"kind": "pitch", "pitch": true, "owner": World.MANOR, "tenant": "", "service": str(p.get("service", ""))}))
	seat_market(world, m, lay)
	for p in pitch_specs(m):
		var s: Dictionary = world.stalls[str(p.id)]
		if not lay.is_empty():
			for k in 2:
				lay.data[int(s.y) * m.w + int(s.x) + k] = AWNING[k]
		for k in 2:
			m.set_solid(Vector2i(int(s.x) + k, int(s.y)), true)
	var ids: Array = world.buildings.keys()
	ids.sort()
	for id in ids:
		if world.buildings[id].has("front"):
			_draw_front(world, m, world.buildings[id].front, lay)
	var sids: Array = world.stalls.keys()
	sids.sort()
	for id in sids:
		if Stalls.is_built(world.stalls[id]):          # stalls built by the player and villagers (STALL-01)
			Stalls.draw(world, m, world.stalls[id])


## GP-MARKET-SPACING (generator v16): a save made before the market was laid out anew keeps its market stalls and pitches
## where the map had them then. Each one (the merchants' stalls and the manor's pitches, never a stall someone built) is moved to
## its place on the map, with its use cell; everything it holds (tenant, stock, prices, till, sales, sessions) stays as saved,
## and its id is kept. If a built stall stands on the new place, the stall stays where it was: its old cells are made solid
## and the new place's drawn table taken up and made walkable, so the drawing and the collision agree. Couriers' booths at a
## stall follow it (CourierService.seat_at_desks).
static func seat_market(world: World, m: VillageMap, lay: Dictionary) -> void:
	var places := {}
	for s in m.data.stalls:
		places[str(s.id)] = Vector2i(int(s.x), int(s.y))
	for p in pitch_specs(m):
		places[str(p.id)] = Vector2i(int(p.x), int(p.y))
	var built_cells := {}
	for id in world.stalls:
		var b: Dictionary = world.stalls[id]
		if Stalls.is_built(b):
			for c in [Vector2i(int(b.x), int(b.y)), Vector2i(int(b.x) + 1, int(b.y)), Vector2i(int(b.x), int(b.y) + 1), Vector2i(int(b.x) + 1, int(b.y) + 1)]:
				built_cells[c] = true
	var ids: Array = places.keys()
	ids.sort()
	for id in ids:
		if not world.stalls.has(id) or Stalls.is_built(world.stalls[id]):
			continue
		var s: Dictionary = world.stalls[id]
		var to: Vector2i = places[id]
		var was := Vector2i(int(s.x), int(s.y))
		if was == to:
			continue
		var cells := [to, to + Vector2i(1, 0), to + Vector2i(0, 1), to + Vector2i(1, 1)]
		if cells.any(func(c): return built_cells.has(c)):
			for k in 2:
				m.set_solid(was + Vector2i(k, 0), true)
				if not id.begins_with("pitch"):
					m.set_solid(to + Vector2i(k, 0), false)
					if not lay.is_empty():
						lay.data[to.y * m.w + to.x + k] = -1
			world.stat("market_stall_kept_in_place")
			continue
		s.x = float(to.x)                     # as a loaded one is (JSON numbers), so a save of it is the same as of the next load
		s.y = float(to.y)
		s.use = [float(to.x), float(to.y + 1)]
		if id.begins_with("pitch"):
			continue                          # its old cells were never map data: add_pitches makes only the new ones solid
		world.stat("market_stall_moved")


# ---------------------------------------------------------------- storefronts (B14) ---------
## A storefront (owner, Build 14: "house should be able to progress to adding a storefront"): a counter
## built from materials against the front wall of a house its holder owns, beside the door. It is the
## house's own (b.front, saved with the building) and opens as a shop (b.shop with "front": true): the
## same listings, prices, villager demand, attendant and books as a shop. It stands on the household's own
## ground, so no rent or licence is due (villagers' storefronts the same). Closing keeps the counter.
static func _draw_front(world: World, m: VillageMap, f: Dictionary, lay: Dictionary) -> void:
	for k in 2:
		var c := Vector2i(int(f.x) + k, int(f.y))
		if not lay.is_empty():
			lay.data[c.y * m.w + c.x] = AWNING[k]
		m.set_solid(c, true)
		world.tile_changed.emit(c, "below0", AWNING[k])


## Where a storefront would stand for house `b`: two open cells in the yard just outside the front wall, at
## least two from the door, off the road (the counter never blocks a road), with an open cell below to
## serve from (the road in front will do). {} if the yard has no room.
func front_place(b: Dictionary) -> Dictionary:
	var door := w.building_door(str(b.id))
	var road := {}
	for c in w.map.data.get("road", []):
		road[Vector2i(int(c[0]), int(c[1]))] = true
	for off in [Vector2i(2, 1), Vector2i(-3, 1), Vector2i(3, 1), Vector2i(-4, 1), Vector2i(4, 1), Vector2i(-5, 1),
			Vector2i(2, 2), Vector2i(-3, 2), Vector2i(3, 2), Vector2i(-4, 2)]:
		var c0: Vector2i = door + off
		var cells := [c0, c0 + Vector2i(1, 0)]
		var use := c0 + Vector2i(0, 1)
		var ok := true
		for c: Vector2i in cells + [use]:
			if not w.map.in_village(c) or w.map.is_solid(c) or not w.plant_at(c).is_empty() or not w.tree_at(c).is_empty() or w.place_of(Vector2(c) + Vector2(0.5, 0.5)) != "":
				ok = false
			if c != use and road.has(c):
				ok = false
		for st in w.stalls.values():
			if Vector2i(int(st.x), int(st.y)).distance_to(c0) < 3.0:
				ok = false
		if ok:
			return {"x": c0.x, "y": c0.y, "use": [use.x, use.y]}
	return {}


static func storefront_cost() -> Dictionary:
	return GameData.b("storefront_cost")


func storefront_refusal(b: Dictionary) -> String:
	if b.is_empty() or not str(b.get("type", "")) in ["house", "player_house"] or not w.holds(w.acting_ref(), b):
		return "Only a house you hold can have a storefront."
	if b.has("front"):
		return "This house has its storefront already."
	if front_place(b).is_empty():
		return "There is no room beside the door for a counter."
	var c := storefront_cost()
	for id in c:
		if w.player.inv.count(id) < int(c[id]):
			return "A storefront takes %s." % ", ".join(c.keys().map(func(k): return "%d %s" % [int(c[k]), GameData.item_name(k).to_lower()]))
	return ""


## Build the counter (the materials come from the pack), then open it as a shop. "" when done, else why not.
func build_storefront(b: Dictionary, actor: PlayerState = null) -> String:
	# MP C (World.mirror): a guest's verb goes to the host
	if w.mirrors():
		return w.mirror("business.build_storefront", build_storefront.bind(b), [b])
	if actor != null and actor != w.player:
		return w.as_actor(actor, build_storefront.bind(b))
	var why := storefront_refusal(b)
	if why != "":
		return why
	var f := front_place(b)
	var c := storefront_cost()
	w.player.inv.remove_all(c)
	for id in c:
		w.stat("used_" + id, float(c[id]))
	b["front"] = f
	var lay: Dictionary = {}
	for l in w.map.data.layers:
		if str(l.name) == "below0":
			lay = l
	_draw_front(w, w.map, f, lay)
	w.stat("storefront_built")
	w.note("%s %s built a storefront at %s." % [w.player.name, w.player.family, w.property.describe(b)])
	return open_front(b)


## A villager builds their household's storefront from the materials they carry (bought with their own
## coins, NPCBrain._plan_storefront). True when built.
func build_npc_front(b: Dictionary, n: NPC) -> bool:
	if b.is_empty() or b.has("front") or n.household < 0 or not w.holds(World.hh_ref(n.household), b):
		return false
	var f := front_place(b)
	var c := storefront_cost()
	if f.is_empty() or not n.inv.has_all(c):
		return false
	n.inv.remove_all(c)
	for id in c:
		w.stat("used_" + id, float(c[id]))
	b["front"] = f
	var lay: Dictionary = {}
	for l in w.map.data.layers:
		if str(l.name) == "below0":
			lay = l
	_draw_front(w, w.map, f, lay)
	w.stat("storefront_built_villager")
	w.note("%s %s built a storefront at the %s family's house." % [n.name, n.family, n.family])
	return true


## Open the storefront's shop (no licence: the household's own ground).
func open_front(b: Dictionary, actor: PlayerState = null) -> String:
	# MP C (World.mirror): a guest's verb goes to the host
	if w.mirrors():
		return w.mirror("business.open_front", open_front.bind(b), [b])
	if actor != null and actor != w.player:
		return w.as_actor(actor, open_front.bind(b))
	if not b.has("front"):
		return "There is no storefront here."
	if b.has("shop"):
		return "The storefront is open already."
	if not w.holds(w.acting_ref(), b):
		return "It is not your house."
	var f: Dictionary = b.front
	b.shop = {"shop": true, "front": true, "id": str(b.id), "building": str(b.id), "x": int(f.x), "y": int(f.y), "use": [int(f.use[0]), int(f.use[1])],
		"stock": {}, "prices": {}, "sales": [], "store": {}, "till": 0, "earned": 0, "paid_day": w.day(), "missed": 0,
		"costs": {}, "attendant": -1, "wage_day": -1}
	if not w.is_host(w.player):
		b.shop.by = w.acting_ref()        # MP C4: a guest's shop (absent: the host's, as every save has it)
	w.stat("shop_opened")
	return ""


static func is_pitch(s: Dictionary) -> bool:
	return bool(s.get("pitch", false))


func mine() -> Dictionary:
	for id in sorted_ids():
		var s: Dictionary = w.stalls[id]
		if is_pitch(s) and not Stalls.is_built(s) and w.is_acting_ref(w.tenant_of(s)):     # MP C4: the acting player's own pitch
			return s
	return {}


## A premises record by id: a pitch's (World.stalls) or a shop's (the building's `shop`); {} when none.
func record(id: String) -> Dictionary:
	if w.stalls.has(id):
		return w.stalls[id]
	return w.buildings.get(id, {}).get("shop", {})


static func is_shop(s: Dictionary) -> bool:
	return bool(s.get("shop", false))


## The player's shops that are open (a counter placed, the licence taken), by building id.
func shops() -> Array:
	var out := []
	var ids: Array = w.buildings.keys()
	ids.sort()
	for id in ids:
		var b: Dictionary = w.buildings[id]
		if b.has("shop") and str(b.shop.get("by", World.PLAYER)) == w.acting_ref():     # MP C4: the player who opened it ("by"; absent: the host's)
			out.append(b.shop)
	return out


## MP C4: every player's premises (the world's own daily and hourly work, its census and decay), each once, the host's first.
func all_premises() -> Array:
	if w.player_list().size() == 1:
		return premises()
	var out := []
	for p: PlayerState in w.player_list():
		for s in w.as_actor(p, premises):
			if not out.has(s):
				out.append(s)
	return out


## MP C4: every shop of every player (tills are counted for the world).
func every_shop() -> Array:
	var out := []
	var ids: Array = w.buildings.keys()
	ids.sort()
	for id in ids:
		if w.buildings[id].has("shop"):
			out.append(w.buildings[id].shop)
	return out


## Everything the player sells from: their pitch, the stalls they built, then their shops.
func premises() -> Array:
	var out := []
	var m := mine()
	if not m.is_empty():
		out.append(m)
	out.append_array(stalls.built(w.acting_ref()))
	out.append_array(shops())
	return out


func building_of(s: Dictionary) -> Dictionary:
	return w.buildings.get(str(s.get("building", "")), {})


## Whether the record is the player's to run: their stall, or a shop in a room they hold.
func is_mine(s: Dictionary) -> bool:
	if s.is_empty():
		return false
	if is_shop(s):
		return w.holds(w.acting_ref(), building_of(s))
	return w.is_acting_ref(w.tenant_of(s))            # MP C4: the acting player's (a guest's stall is not the host's)


func _daily_premises() -> void:
	for s in premises():
		if is_shop(s) and not is_mine(s):
			w.note(close(s, "You no longer hold the shop's room."))
			continue
		if Stalls.is_built(s):
			continue                      # no rent: the 5% sales lease (Stalls)
		_rent_due(s)
		if s.has("stock"):
			_wage_due(s)


## The day's rent of a stall (more for a larger one) or licence of a shop.
func rent_of(s: Dictionary) -> int:
	if bool(s.get("front", false)) or Stalls.is_built(s):
		return 0                          # a storefront: the household's own ground; a built stall pays the 5% (Stalls)
	if is_shop(s):
		return int(GameData.b("shop_licence_day"))
	return int(GameData.b("stall_large_rent_day")) if bool(s.get("large", false)) else rent_day()


## How many kinds of goods it can hold on sale. A shop's grow with its shelves (`shelves` overrides the count).
func listing_cap(s: Dictionary, shelves := -1) -> int:
	if is_shop(s):
		var n := shelves if shelves >= 0 else w.fitting.count(building_of(s), "shelves")
		return int(GameData.b("shop_listings")) + n * int(GameData.b("shop_shelf_listings"))
	return int(GameData.b("stall_large_listings")) if bool(s.get("large", false)) else int(GameData.b("stall_max_listings"))


func expenses(s: Dictionary) -> int:
	var t := 0
	for k in s.get("costs", {}):
		t += int(s.costs[k])
	return t


func profit(s: Dictionary) -> int:
	return int(s.get("earned", 0)) - expenses(s)


func _cost(s: Dictionary, kind: String, n: int) -> void:
	if not s.has("costs"):
		s.costs = {}
	s.costs[kind] = int(s.costs.get(kind, 0)) + n


func sorted_ids() -> Array:
	var ids: Array = w.stalls.keys()
	ids.sort()
	return ids


func free_pitch() -> Dictionary:
	for id in sorted_ids():
		var s: Dictionary = w.stalls[id]
		if is_free_pitch(s):
			return s
	return {}


## TAILOR-18 / BARBER-18: the pitch kept for a service trade ("tailor", "barber"), or {}.
static func service_pitch(w: World, job: String) -> Dictionary:
	for id in w.stalls.keys():
		if is_pitch(w.stalls[id]) and str(w.stalls[id].get("service", "")) == job:
			return w.stalls[id]
	return {}


## Let the service pitch of `job` to `n` (rent-free like the merchants' stalls: no villager pays rent yet); it never sells
## goods (not open). "" when done, else why not.
static func let_service_pitch(w: World, n: NPC, job: String) -> String:
	var s := service_pitch(w, job)
	if s.is_empty():
		return "no pitch"
	var t := w.tenant_of(s)
	if t != "" and t != World.npc_ref(n.id):
		return "let already"
	w.set_tenant(s, World.npc_ref(n.id))
	s.open = false
	n.workplace = str(s.id)
	return ""


static func rent_day() -> int:
	return int(GameData.b("stall_rent_day"))


func use_cell(s: Dictionary) -> Vector2:
	return Vector2(int(s.use[0]) + 0.5, int(s.use[1]) + 0.5)


## B18-DP-01 (stalls display goods with existing item icons): the goods shown over a counter, from its REAL stock: the
## featured item of a larger stall first, then the kinds it holds most of (ties by id), at most `slots`. A sold-out kind is
## gone from the stock and so from the display. Looks only (StallDisplayView draws it).
static func display_goods(s: Dictionary, slots: int) -> Array:
	var stock: Dictionary = s.get("stock", {})
	var ids := []
	for id in stock:
		if int(stock[id]) > 0:
			ids.append(str(id))
	ids.sort_custom(func(a, b): return int(stock[a]) > int(stock[b]) or (int(stock[a]) == int(stock[b]) and a < b))
	var feat := str(s.get("display", ""))
	if feat != "" and ids.has(feat):
		ids.erase(feat)
		ids.push_front(feat)
	return ids.slice(0, maxi(0, slots))


## GP-MARKET-SHELVES (owner, 2026-10-24): goods a market stall's shelf shows, at most ten kinds (five a board).
const SHELF_SLOTS := 10


## GP-MARKET-SHELVES: every market stall's shelf, in a fixed order: [{id, x, y, look, goods}]. A pitch or a built stall
## (the player's or a villager household's) shows its own stall stock (display_goods); a merchant's stall shows what the
## merchant at it offers (NPCBrain.for_sale, most held first) while the merchant stands at it, and nothing when they are
## away. Empty stock, an empty shelf. Read only: it moves no goods and no coins; on a guest's machine it reads the
## synchronized stalls and villagers.
func shelves() -> Array:
	var out := []
	for id in sorted_ids():
		var s: Dictionary = w.stalls[id]
		if not s.has("x"):
			continue
		var goods := []
		if stalls.is_merchant_stall(s):
			if stalls.is_open(s):
				goods = merchant_goods(w.party(w.tenant_of(s)), SHELF_SLOTS)
		else:
			goods = display_goods(s, SHELF_SLOTS)
		out.append({"id": str(id), "x": int(s.x), "y": int(s.y), "look": "dark" if Stalls.is_built(s) else "light", "goods": goods})
	return out


## What a merchant offers, by kind, most held first (then by id), at most `slots` kinds.
func merchant_goods(m, slots: int) -> Array:
	if not (m is NPC):
		return []
	var ids: Array = w.brain.for_sale(m)
	ids.sort_custom(func(a, b): return m.inv.count(a) > m.inv.count(b) or (m.inv.count(a) == m.inv.count(b) and str(a) < str(b)))
	return ids.slice(0, slots)


## Every counter that shows goods: [{x, y, wide (tiles), goods}] for the player's shops and storefronts, in a fixed order;
## counters with nothing in stock show nothing. (Market stalls show theirs on their shelves since GP-MARKET-SHELVES: shelves.)
func displays() -> Array:
	var out := []
	var seen := {}
	var recs := []
	recs.append_array(every_shop())
	for s: Dictionary in recs:
		if seen.has(str(s.get("id", ""))) or not s.has("stock") or not s.has("x"):
			continue
		seen[str(s.get("id", ""))] = true
		var wide := 1 if (is_shop(s) and not bool(s.get("front", false))) else 2
		var goods := display_goods(s, wide * 2)
		if not goods.is_empty():
			out.append({"x": int(s.x), "y": int(s.y), "wide": wide, "goods": goods})
	return out


## GP-TABLE-ITEMS (owner clarification 2026-10-24: tables are not item-pickup containers; they show a visual preview of what
## the business offers): the goods a business's counter desk shows on its table, [{x, y, wide: 1, goods}], two kinds a table
## cell (BusinessDesks.table_cells), in a fixed order: the tavern's from its keeper's offer, a skilled trade's counter from the
## keeper serving it or else its first keeper (NPCBrain.for_sale, most held first: merchant_goods). Nothing for sale, nothing
## shown. Read only: no goods or coins move, nothing is taken from a table, and buying is at the desk (GP-BUSINESS-DESK).
func desk_previews() -> Array:
	var out := []
	for d in BusinessDesks.all(w):
		if str(d.kind) != "counter":
			continue
		var cells := BusinessDesks.table_cells(w, d)
		var goods := merchant_goods(desk_keeper(str(d.id)), cells.size() * 2)
		for i in cells.size():
			var part := goods.slice(i * 2, i * 2 + 2)
			if not part.is_empty():
				out.append({"x": int(cells[i].x), "y": int(cells[i].y), "wide": 1, "goods": part})
	return out


## Whose goods counter `id` offers: the tavern's keeper, or the keeper serving a skilled trade's counter, else its first keeper.
func desk_keeper(id: String) -> NPC:
	if str(w.stations.get(id, {}).get("type", "")) == "tavern_counter":
		return w.tavern_keeper()
	if not w.counters.is_counter(id):
		return null
	var s := w.counters.server(id)
	if s != null:
		return s
	var ks := w.counters.keepers(id)
	return ks[0] if not ks.is_empty() else null


func stock_of(s: Dictionary) -> Dictionary:
	return s.get("stock", {})


func price_of(s: Dictionary, id: String) -> int:
	return int(s.get("prices", {}).get(id, GameData.value(id)))


## Whether `s` is a pitch the player may rent now: an open pitch, not built on, let to nobody, not kept for a service trade.
func is_free_pitch(s: Dictionary) -> bool:
	return not s.is_empty() and is_pitch(s) and not Stalls.is_built(s) and w.tenant_of(s) == "" and str(s.get("service", "")) == ""


## Why the player cannot rent now, or "". With `pitch` (the pitch whose window is open, GP-STALL-RENT-WRONG-PITCH), why not
## that one.
func rent_refusal(pitch: Dictionary = {}) -> String:
	if not mine().is_empty():
		return "You already rent a stall."
	if not pitch.is_empty() and not is_free_pitch(pitch):
		return "That pitch is not free to rent."
	if free_pitch().is_empty():
		return "Every open pitch is let."
	if w.player.coins < rent_day():
		return "You need %d coins for the first day's rent." % rent_day()
	return ""


## Rent `pitch` (the pitch whose window the player used), or with none the first free pitch: the first day is paid now. "" when
## done, else why not. GP-STALL-RENT-WRONG-PITCH (owner, 2026-10-26: "it never gives me the one I clicked on and rented"): the
## chosen pitch is the one rented, never another.
func rent(pitch: Dictionary = {}, actor: PlayerState = null) -> String:
	# MP C (World.mirror): a guest's verb goes to the host, naming the pitch
	if w.mirrors():
		return w.mirror("business.rent", rent.bind(pitch), [pitch] if not pitch.is_empty() else [])
	if actor != null and actor != w.player:
		return w.as_actor(actor, rent.bind(pitch))
	var why := rent_refusal(pitch)
	if why != "":
		return why
	var s := pitch if not pitch.is_empty() else free_pitch()
	if not w.property._pay_manor(w.acting_ref(), rent_day()):
		return "You cannot pay the rent."
	w.set_tenant(s, w.acting_ref())
	s.stock = {}
	s.prices = {}
	s.sales = []
	s.till = 0
	s.earned = 0
	s.paid_day = w.day()
	s.missed = 0
	s.costs = {"rent": rent_day()}
	s.open = true                         # a rented pitch is open for sales until it is closed (Stalls)
	w.stat("stall_rented")
	w.note("%s %s rented a market stall for %d coins a day." % [w.player.name, w.player.family, rent_day()])
	return ""


# ---------------------------------------------------------------- the player's stock ---------
## How many of an item in the pack may be put up: not goods marked stolen (no fencing through a stall).
func listable(id: String) -> int:
	return maxi(0, w.player.inv.count(id) - w.player.stolen_count(id, false))


func can_list(id: String) -> bool:
	return GameData.items.has(id) and GameData.value(id) > 0


## Move `qty` of an item from the pack to the sale stock. "" when done, else why not.
func list_item(s: Dictionary, id: String, qty: int, actor: PlayerState = null) -> String:
	if actor != null and actor != w.player:
		return w.as_actor(actor, list_item.bind(s, id, qty))
	if not is_mine(s):
		return "That is not your stall."
	if not can_list(id) or qty <= 0:
		return "That cannot be sold."
	if qty > listable(id):
		return "You do not have that many that you can sell."
	if not s.stock.has(id) and s.stock.size() >= listing_cap(s):
		return "It has room for %d kinds of goods%s." % [listing_cap(s), (" (more shelves hold more)" if is_shop(s) else "")]
	w.player.inv.remove(id, qty)
	s.stock[id] = int(s.stock.get(id, 0)) + qty
	if not s.prices.has(id):
		s.prices[id] = GameData.value(id)
	return ""


## Take `qty` back to the pack (all or nothing); the price is forgotten with the last of it.
func unlist(s: Dictionary, id: String, qty: int, actor: PlayerState = null) -> String:
	if actor != null and actor != w.player:
		return w.as_actor(actor, unlist.bind(s, id, qty))
	var have := int(s.stock.get(id, 0))
	if qty <= 0 or qty > have:
		return "The stall does not hold that many."
	if not w.player.inv.can_add(id):
		return w.player.inv.full_text(id)
	s.stock[id] = have - qty
	w.player.inv.add(id, qty)
	if int(s.stock[id]) == 0:
		s.stock.erase(id)
		s.prices.erase(id)
	return ""


func set_price(s: Dictionary, id: String, price: int) -> String:
	# MP C (World.mirror): a guest's verb goes to the host
	if w.mirrors():
		return w.mirror("business.set_price", set_price.bind(s, id, price), [s, id, price])
	if not s.stock.has(id):
		return "That is not for sale at your stall."
	if price < 1 or price > GameData.value(id) * PRICE_CAP:
		return "A price from 1 to %d coins." % (GameData.value(id) * PRICE_CAP)
	s.prices[id] = price
	return ""


## Collect the till into the purse; the coins taken. A market stall's proceeds come only by closing it: its session is
## settled (5% to the manor) and the rest is the player's (Q13).
func collect(s: Dictionary, actor: PlayerState = null) -> int:
	if actor != null and actor != w.player:
		return w.as_actor(actor, collect.bind(s))
	if stalls.is_market(s):
		return int(stalls.close(s, "closed to collect").net)
	var t := int(s.get("till", 0))
	w.player.coins += t
	s.till = 0
	return t


## ECON-P3: the owner's choice to move money between the purse and the till. "" when done, else why not. A market
## stall's open session proceeds are not taken out (Q13).
func deposit(s: Dictionary, amount: int, actor: PlayerState = null) -> String:
	if actor != null and actor != w.player:
		return w.as_actor(actor, deposit.bind(s, amount))
	if amount <= 0 or w.player.coins < amount:
		return "You do not have %d coins." % amount
	w.player.coins -= amount
	s.till = int(s.get("till", 0)) + amount
	w.stat("till_deposited", amount)
	return ""


func withdraw(s: Dictionary, amount: int, actor: PlayerState = null) -> String:
	if actor != null and actor != w.player:
		return w.as_actor(actor, withdraw.bind(s, amount))
	var avail := stalls.withdrawable(s) if stalls.is_market(s) else int(s.get("till", 0))
	if amount <= 0 or avail < amount:
		return "The till holds %d coins%s." % [avail, " you can take now" if stalls.is_market(s) else ""]
	s.till = int(s.till) - amount
	w.player.coins += amount
	w.stat("till_withdrawn", amount)
	return ""


## Give the pitch (or the shop's trade) back with nothing lost: the unsold goods, the back room's stock and
## the till return to the player; what does not fit the pack lies at the stall as loot. No refund of rent
## paid. A closed shop leaves its counter and shelves standing. Returns a summary line.
func close(s: Dictionary, because := "You closed your stall.", actor: PlayerState = null) -> String:
	if actor != null and actor != w.player:
		return w.as_actor(actor, close.bind(s, because))
	if Stalls.is_built(s):                # a built stall is the builder's: closing ends the session, the goods stay in it
		return "%s %s" % [because, stalls.settle_text(s, stalls.close(s))]
	var bag := Inventory.new()
	var back := 0
	for pool: Dictionary in [s.stock, s.get("store", {})]:
		for id in pool.keys():
			var n := int(pool[id])
			if w.player.inv.add(id, n):
				back += n
			else:
				bag.add(id, n)
	back += works.clear_into(s, bag)      # the workroom's materials and goods come back too (B18-DP-01)
	var coins := collect(s)
	var left := bag.total()
	if left > 0:
		w.loot.append({"pos": use_cell(s), "inv": bag, "coins": 0, "from": "your shop" if is_shop(s) else "your stall"})
	dismiss(s, "")
	if is_shop(s):
		w.buildings[str(s.building)].erase("shop")
		w.stat("shop_closed")
	else:
		for k in ["stock", "prices", "sales", "till", "earned", "paid_day", "missed", "costs", "large", "display", "attendant", "wage_day"]:
			s.erase(k)
		w.set_tenant(s, "")
		w.stat("stall_closed")
	return "%s %d goods returned to your pack%s%s." % [because, back, (", %d coins from the till" % coins) if coins > 0 else "",
		(", %d left at the %s" % [left, "shop" if is_shop(s) else "stall"]) if left > 0 else ""]


# ---------------------------------------------------------------- rent ------------------------
## Each morning: the day's rent (a shop's licence), from the purse and then the till. Unpaid, selling stops;
## after stall_evict_days unpaid mornings the pitch is taken back (close()). Then the attendant's wage.
func daily() -> void:
	money.daily()                     # the villagers' storefront tills: necessity, the owner's pay, the float (ECON-P3)
	for p: PlayerState in w.player_list():       # MP C4: each player's own premises, their rent and wages from their own purse
		w.as_actor(p, _daily_premises)
	stalls.daily()


func _rent_due(s: Dictionary) -> void:
	if int(s.get("paid_day", 0)) >= w.day():
		return
	var owed := rent_of(s) * (w.day() - int(s.paid_day))
	if _charge(s, owed):
		w.property._pay_manor(w.acting_ref(), owed)
		_cost(s, "licence" if is_shop(s) else "rent", owed)
		w.stat("stall_rent_paid", owed)
		s.paid_day = w.day()
		s.missed = 0
		return
	s.missed = int(s.get("missed", 0)) + 1
	var what := "shop licence" if is_shop(s) else "market stall"
	if int(s.missed) >= int(GameData.b("stall_evict_days")):
		w.note("The manor took back %s's %s: it was not paid." % [w.player.name, what])
		var line := close(s, "The manor took back your %s: it was not paid." % ("shop licence" if is_shop(s) else "stall"))
		w.note(line)
	else:
		w.note("You could not pay the %s (%d coins). Sales are stopped until you do; the manor takes it back after %d days." % ["shop's licence" if is_shop(s) else "stall's rent", owed, int(GameData.b("stall_evict_days"))])


## Make `amount` ready in the purse for a business expense (ECON-P3: the business pays from its own till first). The
## purse covers only what the till cannot, and only from the coins above the necessity reserve (World.spendable): a
## failing shop does not silently eat the family's food money, the player moves money in by choice (deposit). False (and
## nothing moved) when the two cannot cover it. An open market session's proceeds are not drawn on (Q13: not
## withdrawable until the session is settled).
func _charge(s: Dictionary, amount: int) -> bool:
	var from_till := mini(amount, stalls.withdrawable(s) if stalls.is_market(s) else int(s.get("till", 0)))
	if maxi(0, amount - from_till) > w.spendable(w.player):
		return false
	s.till = int(s.get("till", 0)) - from_till
	w.player.coins += from_till
	return true


## Pay what is owed now (the window's button): "" when done, else why not.
func pay_arrears(s: Dictionary, actor: PlayerState = null) -> String:
	if actor != null and actor != w.player:
		return w.as_actor(actor, pay_arrears.bind(s))
	var owed := rent_of(s) * maxi(1, w.day() - int(s.get("paid_day", 0)))
	if w.player.coins < owed:
		return "You need %d coins." % owed
	w.property._pay_manor(w.acting_ref(), owed)
	_cost(s, "licence" if is_shop(s) else "rent", owed)
	w.stat("stall_rent_paid", owed)
	s.paid_day = w.day()
	s.missed = 0
	return ""


# ---------------------------------------------------------------- the larger stall --------------
## Why the stall cannot be made larger now, or "".
func upgrade_refusal(s: Dictionary) -> String:
	if is_shop(s) or not is_mine(s):
		return "Only your market stall can be made larger."
	if bool(s.get("large", false)):
		return "It is a larger stall already."
	if int(s.get("missed", 0)) > 0:
		return "Pay the rent owing first."
	if w.player.coins < int(GameData.b("stall_large_cost")):
		return "You need %d coins." % int(GameData.b("stall_large_cost"))
	return ""


## Pay the manor for a bigger frontage: more kinds of goods, a display, a wider reach, higher daily rent.
func upgrade(s: Dictionary, actor: PlayerState = null) -> String:
	# MP C (World.mirror): a guest's verb goes to the host
	if w.mirrors():
		return w.mirror("business.upgrade", upgrade.bind(s), [s])
	if actor != null and actor != w.player:
		return w.as_actor(actor, upgrade.bind(s))
	var why := upgrade_refusal(s)
	if why != "":
		return why
	w.property._pay_manor(w.acting_ref(), int(GameData.b("stall_large_cost")))
	_cost(s, "upgrade", int(GameData.b("stall_large_cost")))
	s.large = true
	w.stat("stall_enlarged")
	w.note("%s %s enlarged their market stall." % [w.player.name, w.player.family])
	return ""


## The goods shown on the larger stall's display ("" none): it draws buyers from further off.
func set_display(s: Dictionary, id: String) -> String:
	# MP C (World.mirror): a guest's verb goes to the host
	if w.mirrors():
		return w.mirror("business.set_display", set_display.bind(s, id), [s, id])
	if not bool(s.get("large", false)):
		return "Only a larger stall has a display."
	if id != "" and not s.stock.has(id):
		return "Only goods on sale can be displayed."
	if id == "":
		s.erase("display")
	else:
		s.display = id
	return ""


# ---------------------------------------------------------------- a shop -------------------------
## Why the shop cannot be opened in this room now, or "".
func open_refusal(b: Dictionary) -> String:
	if b.is_empty() or not w.holds(w.acting_ref(), b):
		return "It is not your room."
	if w.fitting.count(b, "counter") == 0:
		return "A shop needs a counter."
	if b.has("shop"):
		return "The shop is open already."
	if w.player.coins < int(GameData.b("shop_licence_day")):
		return "You need %d coins for the first day's licence." % int(GameData.b("shop_licence_day"))
	return ""


## Open the shop at the room's counter: the first day's licence goes to the manor. "" when done, else why not.
func open_shop(b: Dictionary, actor: PlayerState = null) -> String:
	# MP C (World.mirror): a guest's verb goes to the host
	if w.mirrors():
		return w.mirror("business.open_shop", open_shop.bind(b), [b])
	if actor != null and actor != w.player:
		return w.as_actor(actor, open_shop.bind(b))
	var why := open_refusal(b)
	if why != "":
		return why
	var e := w.fitting.entry(b, "counter")
	var licence := int(GameData.b("shop_licence_day"))
	if not w.property._pay_manor(w.acting_ref(), licence):
		return "You cannot pay the licence."
	b.shop = {"shop": true, "id": str(b.id), "building": str(b.id), "x": int(e.at[0]), "y": int(e.at[1]), "use": [int(e.use[0]), int(e.use[1])],
		"stock": {}, "prices": {}, "sales": [], "store": {}, "till": 0, "earned": 0, "paid_day": w.day(), "missed": 0,
		"costs": {"licence": licence}, "attendant": -1, "wage_day": -1}
	if not w.is_host(w.player):
		b.shop.by = w.acting_ref()        # MP C4: a guest's shop (absent: the host's)
	w.stat("shop_opened")
	w.note("%s %s opened a shop in %s." % [w.player.name, w.player.family, w.property.describe(b)])
	return ""


func store_total(s: Dictionary) -> int:
	var t := 0
	for id in s.get("store", {}):
		t += int(s.store[id])
	return t


func store_cap(s: Dictionary) -> int:
	return w.fitting.count(building_of(s), "stock_chest") * int(GameData.b("shop_store_per_chest")) if is_shop(s) else 0


## Move goods from the pack into the back room (stock chests). "" when done, else why not.
func store_item(s: Dictionary, id: String, qty: int, actor: PlayerState = null) -> String:
	# MP C (World.mirror): a guest's verb goes to the host
	if w.mirrors():
		return w.mirror("business.store_item", store_item.bind(s, id, qty), [s, id, qty])
	if actor != null and actor != w.player:
		return w.as_actor(actor, store_item.bind(s, id, qty))
	if not is_shop(s) or not is_mine(s):
		return "There is no back room here."
	if not can_list(id) or qty <= 0 or qty > listable(id):
		return "You cannot store that."
	if store_total(s) + qty > store_cap(s):
		return "The stock chests are full (%d of %d)." % [store_total(s), store_cap(s)]
	w.player.inv.remove(id, qty)
	s.store[id] = int(s.store.get(id, 0)) + qty
	return ""


## Bring goods from the back room to the pack.
func fetch(s: Dictionary, id: String, qty: int, actor: PlayerState = null) -> String:
	if actor != null and actor != w.player:
		return w.as_actor(actor, fetch.bind(s, id, qty))
	var have := int(s.get("store", {}).get(id, 0))
	if qty <= 0 or qty > have:
		return "The back room does not hold that many."
	if not w.player.inv.can_add(id):
		return w.player.inv.full_text(id)
	w.player.inv.add(id, qty)
	s.store[id] = have - qty
	if int(s.store[id]) == 0:
		s.store.erase(id)
	return ""


## A shelf that has sold out is filled again from the back room (the price stays).
func _restock(s: Dictionary, id: String) -> void:
	var have := int(s.get("store", {}).get(id, 0))
	if have <= 0:
		return
	var k := mini(have, int(GameData.b("shop_restock")))
	s.stock[id] = k
	s.store[id] = have - k
	if int(s.store[id]) == 0:
		s.store.erase(id)


# ---------------------------------------------------------------- attendants (stage 4) -----------
func attendant_of(s: Dictionary) -> NPC:
	var n: NPC = w.npc(int(s.get("attendant", -1)))
	if n == null or not n.alive:
		return null
	return n


## Whether this villager is somebody's attendant (any of the player's premises).
func is_attendant(n: NPC) -> bool:
	for s in premises():
		if int(s.get("attendant", -1)) == n.id:
			return true
	return false


func wage() -> int:
	return int(GameData.b("attendant_wage"))


## Why this villager cannot be hired to mind a counter, "": an adult without a trade of their own (out of work,
## a manor hand with no job taken, or a labourer: Construction.HIRABLE), not hired for building work or by another
## counter.
func hire_refusal(n: NPC) -> String:
	if n == null or not n.alive or n.role != "adult" or n.household < 0:
		return "They cannot work for you."
	if not n.job in HIRABLE:
		return "%s has work of their own." % n.name
	if n.job == "manor_hand" and not w.manor_work.job_of("npc:%d" % n.id).is_empty():
		return "%s is doing a job for the manor." % n.name
	if not w.construction.contract_of(n).is_empty():
		return "%s is hired for building work today." % n.name
	if is_attendant(n):
		return "%s minds a counter already." % n.name
	return ""


## Adults the player could hire, by id.
func candidates() -> Array:
	var out := []
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and hire_refusal(n) == "":
			out.append(n)
	return out


## Hire `n` to mind this stall or shop: today's wage is paid now (the till first, then the purse). "" when done.
func hire(s: Dictionary, n: NPC, actor: PlayerState = null) -> String:
	# MP C (World.mirror): a guest's verb goes to the host
	if w.mirrors():
		return w.mirror("business.hire", hire.bind(s, n), [s, n])
	if actor != null and actor != w.player:
		return w.as_actor(actor, hire.bind(s, n))
	if not is_mine(s):
		return "That is not your stall."
	if attendant_of(s) != null:
		return "You have an attendant already."
	var why := hire_refusal(n)
	if why == "" and w.judgment != null:
		why = JudgmentLive.work_refusal(w, n, w.acting_id(), wage())   # PROSPECTIVE (PROS-19, Q14): off unless attached
	if why != "":
		return why
	if not _charge(s, wage()):
		return "You need %d coins for the wage." % wage()
	_pay_wage(s, n)
	s.attendant = n.id
	n.plan.clear()
	w.stat("attendants_hired")
	w.note("%s %s hired %s %s to mind their %s for %d coins a day." % [w.player.name, w.player.family, n.name, n.family, "shop" if is_shop(s) else "stall", wage()])
	return ""


func _pay_wage(s: Dictionary, n: NPC) -> void:
	w.player.coins -= wage()
	n.coins += wage()
	n.earned += wage()
	_cost(s, "wages", wage())
	s.wage_day = w.day()
	w.stat("attendant_wages", wage())


## Let the attendant go. They keep what they were paid.
func dismiss(s: Dictionary, because := "You let your attendant go.") -> void:
	var n := attendant_of(s)
	s.attendant = -1
	if n != null:
		n.plan.clear()
		n.doing = ""
		if because != "":
			w.note("%s %s no longer minds the counter: %s" % [n.name, n.family, because])


## Each morning, the attendant is paid for the new day; when the till and purse cannot pay, they leave.
func _wage_due(s: Dictionary) -> void:
	if int(s.get("attendant", -1)) < 0:
		return
	var n := attendant_of(s)
	if n == null:
		s.attendant = -1
		return
	if int(s.get("wage_day", -1)) >= w.day():
		return
	if _charge(s, wage()):
		_pay_wage(s, n)
	else:
		dismiss(s, "the wage could not be paid.")


## Where customers and the attendant stand.
func counter_cell(s: Dictionary) -> Vector2i:
	return Vector2i(int(s.use[0]), int(s.use[1]))


## True when the attendant is awake at the counter now.
func attendant_present(s: Dictionary) -> bool:
	var n := attendant_of(s)
	return n != null and not w.asleep(n) and n.pos.distance_to(use_cell(s)) <= 2.0


## The attendant's day (NPCBrain.decide, in working hours): to the counter, and
## minding it (inside a shop they stand at its counter). False when this villager is nobody's attendant.
func plan_attendant(n: NPC) -> bool:
	for s in all_premises():
		if int(s.get("attendant", -1)) != n.id:
			continue
		if works.plan_work(s, n):         # orders to make at the player's own stations (B18-DP-01)
			return true
		n.doing = "minding the player's %s" % ("shop" if is_shop(s) else "stall")
		n.plan = [w.brain.go(counter_cell(s)), w.brain.work(60, "", {}, "idle")]
		n.plan[1]["industry"] = "trade"      # X18-D4: hours keeping the stall open are trade experience
		return true
	return false


# ---------------------------------------------------------------- selling ----------------------
## The player stands at the counter.
func player_near(s: Dictionary) -> bool:
	return w.player.pos.distance_to(use_cell(s)) <= float(GameData.b("stall_range"))


## Sales run only while the premises are open: the rent not owing, and the player near or the attendant at the
## counter. Nobody sells unattended.
## A built stall sells unattended while it is open (STALL-03); a pitch only while its session is open as well.
func attended(s: Dictionary) -> bool:
	if Stalls.is_built(s):
		return stalls.is_open(s) and int(s.get("missed", 0)) == 0
	if stalls.is_market(s) and not stalls.is_open(s):
		return false
	return is_mine(s) and int(s.get("missed", 0)) == 0 and (player_near(s) or attendant_present(s))


## What a villager will pay at most, per piece: the cheapest price among those who sell the item in the
## village now (the merchants, the smith and the carpenter), or the dearest ordinary price when nobody does;
## a little more for an urgent need (urgency 0..2).
## (`s`, the stall or shop being weighed, does not count towards the others' local supply; `buyer` is not
## an alternative seller to themselves.)
func ceiling(id: String, urgency: int, s := {}, buyer: NPC = null) -> int:
	var alt := maxi(1, roundi(GameData.value(id) * float(GameData.b("price_max"))))
	for o: NPC in w.npcs:
		if o != buyer and o.alive and o.role == "adult" and o.inv.has(id) and not w.brain.keeps(o, id) and \
				(o.job in ["smith", "carpenter", "cook", "tavernkeeper", "merchant", "farmer", "woodcutter"]):
			alt = mini(alt, w.sell_price(o, id, s))
	return floori(alt * (1.0 + float(GameData.b("stall_urgency_step")) * urgency))


## The coins `n` keeps back from a purchase at a stall (OD-19): none for a household need (`for_need`: the stall's
## customers buy food and firewood for their own pantries, needs()), else their reserve.
func cash_floor(n: NPC, for_need := false) -> int:
	return 0 if for_need else w.reserve_of(n)


## What an adult really needs: [{item, qty, urgency (0..2), pantry}], most urgent first. Merchants and
## children do not shop for stock or play.
func needs(n: NPC) -> Array:
	var out := []
	if not n.alive or n.role != "adult" or n.job == "merchant":
		return out
	var b: NPCBrain = w.brain
	var caps: Dictionary = NPCBrain.BUYS.get(b.buy_role(n), {})
	for id in caps:                       # a trade restocks when under half its stock cap
		var gap: int = b.wants(n, id)
		if gap > 0 and n.inv.count(id) * 2 < int(caps[id]):
			out.append({"item": id, "qty": gap, "urgency": 1 if n.inv.count(id) == 0 else 0, "pantry": false})
	if n.job in ["carpenter", "smith", "laborer"]:      # what open building sites ask for (construction.gd)
		for id in ["plank", "building_block", "stone", "log", "iron_bar"]:      # STONE-01: blocks; stone for older sites
			var short: int = w.construction.open_need(id) - n.inv.count(id)
			if short > 0 and (Construction.SELLERS.get(id, []) as Array).has(b.buy_role(n)):
				out.append({"item": id, "qty": short, "urgency": 1, "pantry": false})
	var tool := "pickaxe" if n.job in ["miner", "laborer"] else ("axe" if n.job == "woodcutter" else "")
	if tool != "" and not n.inv.has(tool):
		out.append({"item": tool, "qty": 1, "urgency": 2, "pantry": false})
	if n.job == "guard":
		for id in NPCBrain.KEEPS.guard:
			if not n.inv.has(id):
				out.append({"item": id, "qty": 1, "urgency": 1, "pantry": false})
	if n.household >= 0 and n.household < w.households.size() and w.party("hh:%d" % n.household) == n:
		var hh: Dictionary = w.households[n.household]
		if (hh.pantry as Inventory).count("log") < 1:
			out.append({"item": "log", "qty": 2, "urgency": 2, "pantry": true})
		var short: int = b._dependants(hh) + 1 - b._stocked(hh)
		if short > 0:                     # any food the household counts as food (NPCBrain.FOOD) will do; fruit too (STALL-06)
			for id in ["wheat", "pottage", "roast_meat", "bread", "cheese", "apple", "red_berries", "blueberries"]:
				out.append({"item": id, "qty": short * (2 if id == "wheat" else 1), "urgency": 2 if b._stocked(hh) == 0 else 1, "pantry": true})
	# a hurt adult with no medicine to hand buys one, as NPCBrain._plan_heal would from the Apothecary (STALL-06)
	if n.hp < n.max_hp * float(NPCBrain.hp_cfg().medicine_use_below) and not NPCBrain.MEDICINES.any(func(m): return n.inv.has(m) or (n.household >= 0 and (w.households[n.household].pantry as Inventory).has(m))):
		out.append({"item": "herbal_poultice", "qty": 1, "urgency": 2, "pantry": false})
	out.sort_custom(func(x, y): return int(x.urgency) > int(y.urgency))
	return out


## The purchase this villager would make at the stall now, or {}: the first need the stall can meet at a
## price inside the ceiling and within what the villager can pay above their cash floor.
func offer(n: NPC, s: Dictionary) -> Dictionary:
	if Stalls.is_built(s) and n.household >= 0 and w.holds(World.hh_ref(n.household), s):
		return {}                         # a household does not buy its own goods back
	for need in needs(n):
		var id: String = need.item
		var have := int(s.stock.get(id, 0))
		if have <= 0:
			continue
		var price := price_of(s, id)
		if price > ceiling(id, int(need.urgency), s, n):
			continue
		var afford := (n.coins - cash_floor(n, bool(need.get("pantry", false)) or World.is_necessity(id))) / price
		var qty := mini(mini(int(need.qty), have), mini(afford, int(GameData.b("stall_buy_max"))))
		if qty >= 1 and n.inv.can_add(id):
			return {"item": id, "qty": qty, "price": price, "pantry": bool(need.pantry)}
	return {}


## Every game hour: while a stall or shop of the player's is open (the player near or an attendant at the
## counter), send the first few villagers with a need it can meet (idle ones, nearest id first) to walk over
## and buy. A larger stall with a display draws them from further off.
func hour() -> void:
	var h := w.day() * 24 + int(w.hour())
	for id in heading.keys():
		if h - int(heading[id]) >= 2:
			heading.erase(id)
	for s in all_premises():
		_send_buyers(s, h)
	for s in stalls.npc_built():          # villagers' built stalls sell unattended to the same buyers (STALL-06)
		_send_buyers(s, h)
	stalls.hour()


func _send_buyers(s: Dictionary, h: int) -> void:
	if not attended(s) or s.stock.is_empty():
		return
	var reach := float(GameData.b("stall_walk_range"))
	if bool(s.get("large", false)) and s.stock.has(str(s.get("display", ""))):
		reach *= float(GameData.b("stall_large_reach"))
	var sent := 0
	for n: NPC in w.npcs:
		if sent >= int(GameData.b("stall_buyers_per_hour")):
			break
		if heading.has(n.id) or not n.alive or n.role != "adult" or w.asleep(n) or not _free(n) or is_attendant(n):
			continue
		if n.pos.distance_to(use_cell(s)) > reach:
			continue
		var o := offer(n, s)
		if o.is_empty():
			continue
		n.doing = "going to the %s to buy %s" % ["shop" if is_shop(s) else "market stall", GameData.item_name(o.item).to_lower()]
		n.plan = [w.brain.go(counter_cell(s)), w.brain.doit("buy_stall", {"stall": s.id, "item": o.item, "pantry": o.pantry})]
		heading[n.id] = h
		sent += 1


func _free(n: NPC) -> bool:
	return n.plan.is_empty() or (n.plan[0].k == "work" and n.plan[0].get("anim", "") == "idle")


## The villager reaches the counter (the "buy_stall" step): everything is checked again, since the player may have
## left, changed the price or sold out. True when something was bought.
func arrive(n: NPC, a: Dictionary) -> bool:
	heading.erase(n.id)
	var s: Dictionary = record(str(a.stall))
	if s.is_empty() or not attended(s):
		return false
	var o := offer(n, s)
	if o.is_empty() or o.item != str(a.item):
		return false
	return sell(s, n, o.item, int(o.qty), int(o.price), bool(o.pantry))


## One sale at the counter: coins from the buyer to the till, goods from the stock to the buyer (or the
## household's pantry). All or nothing. A sold-out shelf is filled from the back room.
func sell(s: Dictionary, n: NPC, id: String, qty: int, price: int, pantry := false) -> bool:
	# MP C (World.mirror): a guest's verb goes to the host
	if w.mirrors():
		return w.mirror("business.sell", sell.bind(s, n, id, qty, price, pantry), [s, n, id, qty, price, pantry])
	var total := qty * price
	var dest: Inventory = (w.households[n.household].pantry as Inventory) if pantry else n.inv
	if qty <= 0 or int(s.stock.get(id, 0)) < qty or n.coins < total or not dest.can_add(id):
		return false
	if not w.claims_release(n, EconReservations.COINS, total, id, pantry or World.is_necessity(id)):
		return false                       # LE-03: coins its own offers hold back are not spent here (nothing while the economy is off)
	s.stock[id] = int(s.stock[id]) - qty
	if int(s.stock[id]) == 0:
		s.stock.erase(id)
		if int(s.get("store", {}).get(id, 0)) > 0:
			_restock(s, id)               # the price stays with it
		else:
			s.prices.erase(id)
			if str(s.get("display", "")) == id:
				s.erase("display")
	dest.add(id, qty)
	n.coins -= total
	n.spent += total
	s.till = int(s.till) + total
	s.earned = int(s.earned) + total
	var players := is_mine(s)
	var by_attendant := not player_near(s) or not players
	var by := "you" if not by_attendant else ("unattended" if Stalls.is_built(s) and attendant_of(s) == null else "attendant")
	s.sales.append({"day": w.day(), "hour": int(w.hour()), "who": "%s %s" % [n.name, n.family], "item": id, "qty": qty, "price": price, "by": by})
	while s.sales.size() > int(GameData.b("stall_sales_log")):
		s.sales.pop_front()
	w.stat("stall_sold_" + id, qty)
	w.stat("stall_coins", total)
	if not by_attendant:
		w.player.gain("trading", 2)
	if players:
		w.note("%s %s bought %d %s from your %s for %d coins." % [n.name, n.family, qty, GameData.item_name(id).to_lower(), "shop" if is_shop(s) else "stall", total])
	else:
		w.stat("stall_sold_villager_" + id, qty)
	if stalls.is_market(s):               # a market stall's session: settled on closing, 5% to the manor (Stalls)
		stalls.record_sale(s, stalls.seller_ref(s), id, qty, total)
		stalls.after_sale(s)
	return true


## Coins held in stall and shop tills (counted with the village's money, so totals still balance).
func tills() -> int:
	var t := 0
	for id in w.stalls:
		t += int(w.stalls[id].get("till", 0))
	for s in every_shop():
		t += int(s.get("till", 0))
	return t + money.front_tills() + money.counter_tills()
