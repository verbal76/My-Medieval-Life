class_name Stalls
extends RefCounted
## Market stalls under the realm's 5% sales lease (STALL-01..STALL-06; owner directive 2026-10-21, decisions Q8,
## Q10, Q12 and Q13: docs/directives/2026-10-21_build16_master_completion_directive.md section 4).
##
## Every market stall (World.stalls) is one of three kinds, and all three pay the same commission (Q12):
##  - a built stall (`built`): put up by anyone, the player or a villager household, on clear open ground (or ground
##    they hold) from stall_cost (Q10: three planks) taken from the builder's own pack (Construction.build_stall). It is
##    the builder's (owner and tenant: their reference); it holds its own sale stock (`stock`, goods moved in from the
##    pack or the household's pantry: in one place only), and while OPEN it sells unattended to villagers who really
##    need the goods, through Business's one customer and sale path (needs, offer, arrive, sell);
##  - the manor's pitches (`pitch`, Business): rented by the day as before; they sell while the player or an
##    attendant is at them and the session is open;
##  - the merchants' stalls (stall0-stall5): a merchant at their post sells through World.trade; a sale there is a
##    stall sale (after_trade), the merchant's session open while they stand at the stall.
##
## A session is the run of sales between opening and closing (`session`: gross coins, pieces sold by item, the day and
## hour it began, the seller's reference). Its proceeds wait in the stall's till and cannot be taken while it is open
## (Q13); the till's settled remainder (an older save's) is the seller's at any time. Closing settles it (settle()):
##  1. the session's completed sales are reconciled (gross);
##  2. the commission is gross x stall_commission_pct / 100, exactly: kept in hundredths of a coin, plus the fraction
##     carried from this stall's last settlement (`frac`, 0..99); only the whole coins move now and the new remainder is
##     carried to the next settlement (Q8), so no coin is created or destroyed and none is fractional;
##  3. those coins go from the till to the manor's treasury (World.treasury, stat gov_stall_commission);
##  4. the rest of the till goes to the seller (the player's purse, the villager's, or their household's head; one
##     whose household is gone leaves it to the manor, as an ended household's goods are);
##  5. the unsold goods stay in the stall; 6. one line goes into the stall's `settlements` and the notes; 7. coins
##     move only between holders World.total_coins counts.
## A session closes by hand (CLOSE STALL), when its stock sells out, or (a merchant's) when the merchant leaves the
## stall; it may be opened again at once. An empty session settles nothing and charges nothing.
##
## Villager households (STALL-06) build, stock, open and restock stalls by the same rules (plan_npc): the household's
## surplus (NPCBrain.front_goods: what it has beyond what it keeps), planks from their own pack or bought with their own
## coins within their reserve, nothing free; a stall that sells out closes and settles like the player's.
##
## Saved with World.stalls (no new top-level field): a built stall's record, and on any stall `open`, `session`, `frac`
## and `settlements`. Older saves have none of them and load as closed, unsettled-free stalls (a pitch rented in an
## older save counts as open).

## GP-MARKET-SPACING (owner, 2026-10-26: "The booths are too close together. Space them farther apart"): a stall stands at
## least this far (tiles, between footprint origins, along x or along y) from any other, the market's own spacing (generator
## v16, tools/build_village.py): the 53 px Craftpix shelf overhangs its two cells by 0.65 tile each side and rises 1.3 tiles
## above them, so 5 leaves three walkable cells and 1.7 tiles of open ground between two shelves side by side, and a clear
## lane between a row's customers and the shelves behind them. (Before Build 22: 3 tiles apart.)
const SPACING := Vector2i(5, 5)

var w: World
var biz: Business
var _looked := {}                     # household index -> the day it last looked for stall ground (not saved)
var _road := {}                       # the map's road cells (map data: never changes)


func _init(world: World, business: Business) -> void:
	w = world
	biz = business


# ---------------------------------------------------------------- kinds and terms ------------
static func cost() -> Dictionary:
	return GameData.b("stall_cost")


static func pct() -> int:
	return int(GameData.b("stall_commission_pct"))


static func is_built(s: Dictionary) -> bool:
	return bool(s.get("built", false))


## A merchant's stall of the manor's market (not a pitch, not a built stall).
func is_merchant_stall(s: Dictionary) -> bool:
	return not s.is_empty() and w.stalls.has(str(s.get("id", ""))) and not Business.is_pitch(s) and not is_built(s)


## Any market stall (a shop in a room or a storefront is not one: CTR-04, they keep their own terms).
func is_market(s: Dictionary) -> bool:
	return not s.is_empty() and not Business.is_shop(s) and w.stalls.has(str(s.get("id", "")))


func sorted_ids() -> Array:
	var ids: Array = w.stalls.keys()
	ids.sort()
	return ids


## The built stalls, by id; `ref` "" for all, else those a party holds.
func built(ref := "") -> Array:
	var out := []
	for id in sorted_ids():
		var s: Dictionary = w.stalls[id]
		if is_built(s) and (ref == "" or w.holds(ref, s)):
			out.append(s)
	return out


## Villagers' built stalls (the player's are among Business.premises()).
func npc_built() -> Array:
	return built().filter(func(s): return not (World.is_player_ref(w.owner_of(s)) or World.is_player_ref(w.tenant_of(s))))


## Who sells at the stall now: the player, a household, a merchant.
func seller_ref(s: Dictionary) -> String:
	if is_merchant_stall(s):
		return w.tenant_of(s)
	return w.holder_of(s)


## Whether the stall is open for sales now. A merchant's while they stand at it; a pitch from its renting until it is
## closed; a built stall only after OPEN STALL.
func is_open(s: Dictionary) -> bool:
	if is_merchant_stall(s):
		var m := w.party(w.tenant_of(s))
		return m != null and m.job == "merchant" and m.workplace == str(s.id) and w.at_post(m)
	if is_built(s):
		return bool(s.get("open", false))
	return w.tenant_of(s) != "" and bool(s.get("open", true))


## Coins of the open session's sales, held in the till until it is settled.
func unsettled(s: Dictionary) -> int:
	return int(s.get("session", {}).get("gross", 0))


## What may be taken from the till now: anything but the open session's proceeds (Q13).
func withdrawable(s: Dictionary) -> int:
	return maxi(0, int(s.get("till", 0)) - unsettled(s))


## The commission the session would pay if it closed now, in whole coins, and the fraction it would carry.
func due(s: Dictionary) -> Vector2i:
	var h := unsettled(s) * pct() + int(s.get("frac", 0))
	return Vector2i(h / 100, h % 100)


# ---------------------------------------------------------------- sales and settlement -------
## One completed sale at a market stall (its coins already in the till).
func record_sale(s: Dictionary, seller: String, id: String, qty: int, total: int) -> void:
	if not s.has("session"):
		s.session = {"gross": 0, "sold": {}, "day": w.day(), "hour": int(w.hour()), "seller": seller}
	var ses: Dictionary = s.session
	ses.gross = int(ses.gross) + total
	ses.sold[id] = int(ses.sold.get(id, 0)) + qty
	ses.seller = seller
	w.stat("stall_session_sales", total)


## World.trade's hook: a merchant standing at their market stall sells; the proceeds go into the stall's till for the
## session (Q12: the merchants' stalls pay the commission too; Q13: not spendable until the session is settled).
func after_trade(seller: Object, id: String, qty: int, total: int) -> void:
	if not (seller is NPC) or total <= 0:
		return
	var n: NPC = seller
	if n.job != "merchant" or not w.stalls.has(n.workplace):
		return
	var s: Dictionary = w.stalls[n.workplace]
	if not is_merchant_stall(s) or w.tenant_of(s) != World.npc_ref(n.id) or not w.at_post(n):
		return
	n.coins -= total
	s.till = int(s.get("till", 0)) + total
	if w.recorder != null:
		w.recorder.till_flow(till_ref(s), n, total, int(s.till), "sale")     # REC-DIAG
	record_sale(s, World.npc_ref(n.id), id, qty, total)


## The party a settlement pays: the seller, else (dead) their household's head; null when nobody is left.
func _payee(ref: String) -> Object:
	if World.is_player_ref(ref):
		return w.player_for(ref)                      # MP C4: the stall's player, whoever is acting
	if ref.begins_with("npc:"):
		var o := w.npc(World.ref_id(ref))
		if o != null and o.alive:
			return o
		if o != null and o.household >= 0:
			return w.party(World.hh_ref(o.household))
		return null
	return w.party(ref)


## REC-DIAG: the economy model's ref of this premises' till ("stall:<id>", or "shop:<building id>" for a shop).
static func till_ref(s: Dictionary) -> String:
	return ("shop:" if s.has("building") else "stall:") + str(s.get("id", ""))


## Settle the stall's session (Q13): the commission from the till to the treasury, the rest of the till to the seller.
## Returns {gross, commission, net, frac}; an empty session with an empty till moves nothing.
func settle(s: Dictionary, why := "closed") -> Dictionary:
	var ses: Dictionary = s.get("session", {})
	var gross := int(ses.get("gross", 0))
	var till := int(s.get("till", 0))
	var h := gross * pct() + int(s.get("frac", 0))
	var c := mini(h / 100, till)
	var out := {"gross": gross, "commission": c, "net": 0, "frac": h - c * 100}
	if gross == 0 and till == 0:
		s.erase("session")
		return out
	s.frac = h - c * 100
	s.till = till - c
	w.treasury += c
	var net := int(s.till)
	var ref := str(ses.get("seller", seller_ref(s)))
	var to: Object = _payee(ref)
	if to == w.player:
		w.player.coins += net
	elif to != null:
		var o: NPC = to
		o.coins += net
		if not is_merchant_stall(s):
			o.earned += net               # a merchant's earnings were counted at each sale (World.trade)
	else:
		w.treasury += net                 # nobody of theirs is left: to the manor, as an ended household's goods
		w.stat("stall_net_escheat", net)
	if w.recorder != null:                # REC-DIAG: the commission, then the rest, out of the till
		w.recorder.till_flow(till_ref(s), null, -c, till - c, "commission")
		w.recorder.till_flow(till_ref(s), to, -net, 0, "settle" if to != null else "escheat")
	s.till = 0
	out.net = net
	s.erase("session")
	if gross > 0:
		var log: Array = s.get("settlements", [])
		log.append({"day": w.day(), "hour": int(w.hour()), "gross": gross, "commission": c, "net": net, "frac": int(s.frac),
			"sold": ses.get("sold", {}), "why": why})
		while log.size() > int(GameData.b("stall_settle_log")):
			log.pop_front()
		s.settlements = log
		w.stat("gov_stall_commission", c)
		w.stat("stall_settlements")
		w.stat("stall_net_paid", net)
	return out


## The settlement's line for the seller.
func settle_text(s: Dictionary, r: Dictionary) -> String:
	if int(r.gross) == 0:
		return "No sales to settle." if int(r.net) == 0 else "%d coins from the till." % int(r.net)
	return "Sales %d coins: %d to the manor (%d%%%s), %d to the seller." % [int(r.gross), int(r.commission), pct(),
		(", %d hundredths carried" % int(r.frac)) if int(r.frac) > 0 else "", int(r.net)]


## CLOSE STALL: sales stop, the session is settled, the unsold goods stay in the stall. Returns the settlement.
func close(s: Dictionary, why := "closed") -> Dictionary:
	if Business.is_pitch(s):
		s.open = false
	var r := settle(s, why)
	w.stat("stall_sessions_closed")
	return r


## Why the stall cannot be opened by `ref` now, or "".
func open_refusal(s: Dictionary, ref: String) -> String:
	if s.is_empty() or is_merchant_stall(s) or not w.holds(ref, s):
		return "It is not your stall."
	if is_open(s):
		return "It is open already."
	if int(s.get("missed", 0)) > 0:
		return "Pay the rent owing first."
	if s.get("stock", {}).is_empty():
		return "There is nothing in it to sell."
	return ""


## OPEN STALL: the stall sells from now until it is closed or sold out. "" when done.
func open(s: Dictionary, ref: String) -> String:
	var why := open_refusal(s, ref)
	if why != "":
		return why
	s.open = true
	w.stat("stall_sessions_opened")
	return ""


## After a sale at a built stall or a pitch: an emptied stall closes and settles (Q13), with a notice.
func after_sale(s: Dictionary) -> void:
	if not s.get("stock", {}).is_empty() or not is_open(s):
		return
	var r := close(s, "sold out")
	var whose := "Your" if w.holds(w.acting_ref(), s) else "The %s" % w.ref_name(seller_ref(s), false).trim_prefix("the ")
	w.note("%s market stall sold out and closed. %s" % [whose, settle_text(s, r)])


# ---------------------------------------------------------------- building -------------------
## The stall's cells: its two awning tiles, and the cell below the first that buyers and the seller stand on.
static func cells_at(c: Vector2i) -> Array:
	return [c, c + Vector2i(1, 0)]


static func use_at(c: Vector2i) -> Vector2i:
	return c + Vector2i(0, 1)


## Why a stall cannot be built with its awning at `c` (and `c` + 1 east) by `ref`, or "": clear, open ground inside the
## village (or ground `ref` holds), off the road, no tree, plant, crop, building, field, pen, station, container or mine
## seam, at least three tiles from any other stall, with an open cell below to serve from.
func site_refusal(c: Vector2i, ref: String) -> String:
	var m: VillageMap = w.map
	var use := use_at(c)
	if _road.is_empty():
		for r in m.data.get("road", []):
			_road[Vector2i(int(r[0]), int(r[1]))] = true
	var road := _road
	for x in cells_at(c) + [use]:
		var cell: Vector2i = x
		if cell.x < 1 or cell.y < 1 or cell.x >= m.w - 1 or cell.y >= m.h - 1:
			return "outside the village"
		if m.is_solid(cell):
			return "the ground is not clear"
		if not w.tree_at(cell).is_empty():
			return "a tree is in the way"
		if not w.plant_at(cell).is_empty():
			return "a plant is in the way"
		if w.farm != null and w.farm.cells.has(cell):
			return "the ground is tilled"
		if w.place_of(Vector2(cell) + Vector2(0.5, 0.5)) != "":
			return "it is inside a building"
		if cell != use and road.has(cell):
			return "the road"
		for b in w.property.records():
			if Rect2i(int(b.x), int(b.y), int(b.w), int(b.h)).has_point(cell) and not w.holds(ref, b):
				return "someone's land"
		for f in w.fields:
			if Rect2i(int(f.x), int(f.y), int(f.w), int(f.h)).has_point(cell):
				return "the manor's fields"
		for pid in w.fauna.pens:
			var p: Dictionary = w.fauna.pens[pid]
			if Rect2i(int(p.x), int(p.y), int(p.w), int(p.h)).has_point(cell):
				return "an animal pen"
		for sid in w.stations:
			var st: Dictionary = w.stations[sid]
			if Vector2i(int(st.at[0]), int(st.at[1])) == cell or Vector2i(int(st.use[0]), int(st.use[1])) == cell:
				return "a workplace"
		for k in w.containers:
			if Vector2i(int(k.x), int(k.y)) == cell:
				return "a container"
		for d in w.deposits:
			if Vector2i(int(d.x), int(d.y)) == cell:
				return "the mine"
		if w.pits != null and w.pits.ground_refusal(cell) != "":
			return "an open pit"
	for sid in w.stalls:
		var o: Dictionary = w.stalls[sid]
		var gap := (c - Vector2i(int(o.x), int(o.y))).abs()
		if (gap.x < SPACING.x and gap.y < SPACING.y) or Vector2i(int(o.use[0]), int(o.use[1])).distance_to(Vector2(c)) < 2.0:
			return "too close to another stall"
	return ""


## Build a stall at `c` for `ref` from `inv` (the builder's own pack): stall_cost is consumed. "" when done, else why not.
## (Called through Construction.build_stall.)
func build(ref: String, c: Vector2i, inv: Inventory) -> String:
	var why := site_refusal(c, ref)
	if why != "":
		return "A stall cannot stand here: %s." % why
	var need := cost()
	if not inv.has_all(need):
		return "A stall takes %s." % ", ".join(need.keys().map(func(k): return "%d %s" % [int(need[k]), GameData.item_name(k).to_lower()]))
	inv.remove_all(need)
	for id in need:
		w.stat("used_building_" + id, float(need[id]))
	var k := 0
	while w.stalls.has("bstall%d" % k):
		k += 1
	var id := "bstall%d" % k
	var s: Dictionary = JSON.parse_string(JSON.stringify({"id": id, "x": c.x, "y": c.y, "use": [use_at(c).x, use_at(c).y], "kind": "built",
		"pitch": true, "built": true, "owner": ref, "tenant": ref, "built_day": w.day(), "stock": {}, "prices": {}, "sales": [],
		"till": 0, "earned": 0, "costs": {}, "paid_day": w.day(), "missed": 0, "attendant": -1, "open": false, "frac": 0}))
	w.stalls[id] = s
	draw(w, w.map, s, true)
	w.stat("stalls_built")
	if not World.is_player_ref(ref):
		w.stat("stalls_built_villager")
	w.note("%s built a market stall %s." % [w.ref_name(ref, true), w.where(Rect2i(c, Vector2i(2, 1)))])
	return ""


## Draw a built stall with the merchants' awning art and make it solid (`live`: tell the view, after loading too).
static func draw(world: World, m: VillageMap, s: Dictionary, live := false) -> void:
	var lay: Dictionary = {}
	for l in m.data.layers:
		if str(l.name) == "below0":
			lay = l
	for k in 2:
		var c := Vector2i(int(s.x) + k, int(s.y))
		if not lay.is_empty():
			lay.data[c.y * m.w + c.x] = Business.AWNING[k]
		m.set_solid(c, true)
		if live:
			world.tile_changed.emit(c, "below0", Business.AWNING[k])


# ---------------------------------------------------------------- the hour and the day -------
## Each hour: a merchant who has left their stall has closed it; the session is settled.
func hour() -> void:
	for id in sorted_ids():
		var s: Dictionary = w.stalls[id]
		if is_merchant_stall(s) and (s.has("session") or int(s.get("till", 0)) > 0) and not is_open(s):
			close(s, "the merchant left the stall")


## Each morning: a built stall whose holder is gone (a household that ended passes what it held to the manor) is
## closed and settled, its goods go to the manor's granary with the household's other stores, and it stays the manor's.
func daily() -> void:
	for s in built():
		var ref := w.holder_of(s)
		if World.is_player_ref(ref) or (ref != World.MANOR and ref != "" and w.party(ref) != null):
			continue
		if s.has("session") or int(s.get("till", 0)) > 0:
			close(s, "its holder is gone")
		s.open = false
		var moved := 0
		var stock: Dictionary = s.get("stock", {})
		for id in stock.keys():
			w.granary.add(id, int(stock[id]))
			moved += int(stock[id])
		s.stock = {}
		s.prices = {}
		if w.recorder != null:
			w.recorder.business_abandoned(till_ref(s), ref, moved)     # REC-DIAG: before the manor takes it
		s.owner = World.MANOR
		s.tenant = World.MANOR            # never a vacancy a new merchant could be let (NPCBrain._install)
		if moved > 0:
			w.stat("escheat_items", moved)


# ---------------------------------------------------------------- villager households (STALL-06) --
## A household's built stall, or {}.
func of_household(h: int) -> Dictionary:
	var b := built(World.hh_ref(h))
	return b[0] if not b.is_empty() else {}


func _surplus_total(h: int) -> int:
	var t := 0
	var g: Dictionary = w.brain.front_goods(h)
	for id in g:
		t += int(g[id])
	return t


## Ground for a household's stall near the market: the first site (nearest ring first, then by row and column) within
## stall_site_radius of the market's middle. (-1, -1) when none.
func find_site(ref: String) -> Vector2i:
	var ms := []
	for id in sorted_ids():
		if not Business.is_pitch(w.stalls[id]):
			ms.append(Vector2(int(w.stalls[id].x), int(w.stalls[id].y)))
	if ms.is_empty():
		return Vector2i(-1, -1)
	var mid := Vector2.ZERO
	for p: Vector2 in ms:
		mid += p
	mid /= float(ms.size())
	var o := Vector2i(roundi(mid.x), roundi(mid.y))
	var r_max := int(GameData.b("stall_site_radius"))
	for r in range(2, r_max + 1):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var c := o + Vector2i(dx, dy)
				if site_refusal(c, ref) == "" and not w.map.find_path(Vector2i(int(ms[0].x), int(ms[0].y) + 1), use_at(c)).is_empty():
					return c
	return Vector2i(-1, -1)


## An adult's evening (NPCBrain._plan_home_work): a household with a built stall that is closed and surplus to sell
## stocks and opens it; one without a stall, with stall_npc_min_goods of surplus and the planks in hand or bought with
## its own coins inside its reserve (OD-19), builds one near the market. True when a plan was made.
func plan_npc(n: NPC, house: Dictionary) -> bool:
	if n.role != "adult" or n.household < 0 or house.is_empty():
		return false
	var b: NPCBrain = w.brain
	var ref := World.hh_ref(n.household)
	var s := of_household(n.household)
	var surplus := _surplus_total(n.household)
	if not s.is_empty():
		if is_open(s) or surplus < 1:
			return false
		n.doing = "stocking the %s family's market stall" % n.family
		n.plan = [b.go(Vector2i(int(s.use[0]), int(s.use[1]))), b.doit("stall_stock", {"stall": str(s.id)})]
		return true
	if surplus < int(GameData.b("stall_npc_min_goods")) or int(_looked.get(n.household, -1)) == w.day():
		return false
	_looked[n.household] = w.day()
	var site := find_site(ref)
	if site.x < 0:
		return false
	var plan := []
	var need := cost()
	for id in need:
		var short := int(need[id]) - n.inv.count(id)
		if short <= 0:
			continue
		var seller := b._seller_of(id, n)
		if seller == null or seller.inv.count(id) < short:
			return false
		if not w.can_afford(n, w.deal_price(w.sell_price(seller, id), n, seller) * short):
			return false
		plan.append_array([b.go(b._workplace_cell(seller)), b.doit("buy_from", {"vendor": seller.id, "item": id, "qty": short})])
	plan.append_array([b.go(use_at(site)), b.work(30, "build_stall", {"x": site.x, "y": site.y}, "work")])
	n.doing = "building a market stall"
	n.plan = plan
	return true


## The "build_stall" step: the villager builds the household's stall from the planks they carry.
func npc_build(n: NPC, a: Dictionary) -> bool:
	if n.household < 0 or not of_household(n.household).is_empty():
		return false
	return w.construction.build_stall(World.hh_ref(n.household), Vector2i(int(a.x), int(a.y)), n.inv) == ""


## The "stall_stock" step: the household's surplus moves from its pantry into the stall's stock (in one place only), each
## listed at its market value, and the stall opens. True when it opened.
func npc_stock(n: NPC, a: Dictionary) -> bool:
	var s: Dictionary = w.stalls.get(str(a.get("stall", "")), {})
	if n.household < 0 or s.is_empty() or not w.holds(World.hh_ref(n.household), s) or is_open(s):
		return false
	var pantry: Inventory = w.households[n.household].pantry
	var g: Dictionary = w.brain.front_goods(n.household)
	var ids: Array = g.keys()
	ids.sort()
	for id in ids:
		if not s.stock.has(id) and s.stock.size() >= biz.listing_cap(s):
			continue
		var q := mini(int(g[id]), pantry.count(id))
		if q <= 0 or GameData.value(id) <= 0:
			continue
		pantry.remove(id, q)
		s.stock[id] = int(s.stock.get(id, 0)) + q
		if not s.prices.has(id):
			s.prices[id] = GameData.value(id)
		w.stat("stall_stocked_villager", q)
	return open(s, World.hh_ref(n.household)) == ""
