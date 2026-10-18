class_name Property
extends RefCounted
## The manor's land office: the land registry (parcels), sales and leases of land and houses, weekly
## rent, eviction, houses that fall back to the manor, and the check that a rectangle of ground is
## free to claim (phase 2 builds anywhere legal on it).
##
## Owner rules (2026-10-18, docs/DECISIONS.md "Property and construction"): the manor, households and
## the player own land and buildings, the player counting as their own household; unsold land and
## empty houses are the manor's; ground is bought or leased from the manor; rent is weekly and only
## the manor lets; a house whose family dies out goes back to the manor, which can sell or lease it
## again; the player may own several houses and sell one back. Who owns and holds what is asked and
## changed only through World.owner_of / tenant_of / holder_of / set_owner / set_tenant (one owner
## reference for everything, see World "ownership"). Prices, rents and the eviction rule are agent
## proposals, provisional until the balance review (docs/BUILD_DECISIONS.md "Property and land").
## Coins only move between purses and the treasury.

const HOME_TYPES := ["house", "player_house"]     # buildings the manor sells or lets as homes
const WEEK := 7

var w
var next_parcel := 0               # parcels claimed with claim(): "parcel0", "parcel1", ...
var _road := {}                    # road cells (map data), for the legality check
var why := ""                      # why the last claim() failed


func _init(world) -> void:
	w = world


# ---------------------------------------------------------------- the registry ---------------
## Every parcel (World.plots: the two plots the map surveyed, then any claimed) and building,
## in a fixed order: parcels by registry order, buildings by id.
func records() -> Array:
	var out: Array = w.plots.duplicate()
	var ids: Array = w.buildings.keys()
	ids.sort()
	for id in ids:
		out.append(w.buildings[id])
	return out


func is_parcel(thing: Dictionary) -> bool:
	return thing.has("site")


func is_home(thing: Dictionary) -> bool:
	return not is_parcel(thing) and str(thing.get("type", "")) in HOME_TYPES


## The building on a parcel, or the parcel under a building ({} if none).
func building_on(parcel: Dictionary) -> Dictionary:
	return w.buildings.get(str(parcel.get("building", "")), {})


func parcel_under(b: Dictionary) -> Dictionary:
	return w.plot(str(b.get("parcel", ""))) if str(b.get("parcel", "")) != "" else {}


## What changes hands together: a parcel and the building on it, or a building and its parcel. The
## first is the deal's record: it carries the rent.
func unit(thing: Dictionary) -> Array:
	if is_parcel(thing):
		var b := building_on(thing)
		return [thing] if b.is_empty() else [thing, b]
	var p := parcel_under(thing)
	return [thing] if p.is_empty() else [p, thing]


func head(thing: Dictionary) -> Dictionary:
	return unit(thing)[0]


## The deals the land office offers and the things a party holds are listed by their head record.
func heads() -> Array:
	return records().filter(func(r): return is_parcel(r) or (is_home(r) and parcel_under(r).is_empty()))


## Somebody lives in it: a household's home with a member alive (the player's homes are theirs).
func lived_in(thing: Dictionary) -> bool:
	for r in unit(thing):
		if not is_parcel(r) and w.household_in(str(r.id)) >= 0:
			return true
	return false


## On the market: the manor's, let to nobody, nobody living in it, no building work going on.
func for_sale(thing: Dictionary) -> bool:
	if not (is_parcel(thing) or is_home(thing)):
		return false
	for r in unit(thing):
		if w.owner_of(r) != World.MANOR or w.tenant_of(r) != "":
			return false
		if is_parcel(r) and not r.site.is_empty() and not r.site.get("done", false):
			return false
	return not lived_in(thing)


## What the manor offers now (head records).
func market() -> Array:
	return heads().filter(func(r): return for_sale(r))


## What a party owns or leases (head records).
func held_by(ref: String) -> Array:
	return heads().filter(func(r): return w.holds(ref, r))


## The homes (buildings a family can live in) a party holds, by id.
func homes_of(ref: String) -> Array:
	var out := []
	for r in records():
		if is_home(r) and w.holds(ref, r):
			out.append(str(r.id))
	return out


# ---------------------------------------------------------------- prices ---------------------
## Provisional (balance review pending): land at plot_price for a 9x10 house plot, by area; a house
## with its ground at house_price; a week's rent weekly_rent_share of the price; the manor buys back
## at sell_back_share.
func land_price(wd: int, ht: int) -> int:
	return maxi(1, ceili(float(GameData.b("plot_price")) * wd * ht / 90.0))


func price_of(thing: Dictionary) -> int:
	for r in unit(thing):
		if not is_parcel(r):
			return int(GameData.b("workshop_price" if str(r.get("type", "")) == "workshop" else "house_price"))
	return land_price(int(thing.w), int(thing.h))


func rent_of(thing: Dictionary) -> int:
	return maxi(1, ceili(price_of(thing) * float(GameData.b("weekly_rent_share"))))


func sale_value(thing: Dictionary) -> int:
	return roundi(price_of(thing) * float(GameData.b("sell_back_share")))


## A place's name as the player reads it, never an internal id (property phase 2): "the Reed family's
## house", "the Ford family's old house", "the Ashdown family's smithy", "the clearing north of the
## Reed family's house", "the ground west of the tavern". A name two places would share gets where
## the place lies added ("the Reed family's house east of the market").
func describe(thing: Dictionary) -> String:
	var name := _base_name(thing)
	for r in heads():
		if r != thing and r != head(thing) and _base_name(r) == name:
			return "%s %s" % [name, w.where(_rect(thing), _own_id(thing), name)]
	return name


func _rect(thing: Dictionary) -> Rect2i:
	return Rect2i(int(thing.x), int(thing.y), int(thing.w), int(thing.h))


func _own_id(thing: Dictionary) -> String:
	var b := building_on(thing) if is_parcel(thing) else thing
	return str(b.get("id", ""))


func _base_name(thing: Dictionary) -> String:
	var b := building_on(thing) if is_parcel(thing) else thing
	if b.is_empty():
		var site: Dictionary = thing.get("site", {})
		var by := str(site.get("owner", ""))
		if not site.is_empty() and not site.get("done", false) and (by == World.PLAYER or by.begins_with("hh:")):
			return "the %s family's building site for %s" % [_family(by), Construction.kind_name(str(site.get("kind", "house")), true)]
		var what := "clearing" if w.map.data.plots.any(func(mp): return str(mp.id) == str(thing.id)) else "ground"
		return "the %s %s" % [what, w.where(_rect(thing), "")]
	return building_name(b)


const PLACES := {"manor": "the manor house", "tavern": "the tavern", "hut": "the sage's hut", "smithy": "the smithy"}


## "the Reed family's house" (who lives there or holds it), "the Ford family's old house" (fallen to
## the manor when the family died out), or "the empty house north of the well".
func building_name(b: Dictionary) -> String:
	var kind := Construction.kind_name(str(b.get("kind", "house")) if World.is_built(b) else "house")
	if PLACES.has(str(b.get("type", ""))):
		return PLACES[str(b.type)]
	var h: int = w.household_in(str(b.id))
	if h >= 0:
		return "the %s family's %s" % [w.households[h].family, kind]
	var by: String = w.holder_of(b)
	if by == World.PLAYER or (by.begins_with("hh:") and _anyone_alive(World.ref_id(by))):
		return "the %s family's %s" % [_family(by), kind]
	for hh in w.households:
		if str(hh.home) == str(b.id):
			return "the %s family's old %s" % [hh.family, kind]
	return "the empty %s %s" % [kind, w.where(_rect(b), str(b.id))]


func _family(ref: String) -> String:
	if ref == World.PLAYER:
		return w.player.family
	if ref.begins_with("hh:") and World.ref_id(ref) < w.households.size():
		return str(w.households[World.ref_id(ref)].family)
	return "manor's"


# ---------------------------------------------------------------- purses ---------------------
## Coins a party can pay with: the player's purse, a villager's, a household's members' together.
func purse(ref: String) -> int:
	if ref == World.PLAYER:
		return w.player.coins
	var n := 0
	for o: NPC in _payers(ref):
		n += o.coins
	return n


func _payers(ref: String) -> Array:
	var out := []
	if ref.begins_with("npc:"):
		var o: NPC = w.npc(World.ref_id(ref))
		if o and o.alive:
			out.append(o)
	elif ref.begins_with("hh:"):
		var h := World.ref_id(ref)
		if h >= 0 and h < w.households.size():
			for m in w.households[h].members:
				var o: NPC = w.npc(int(m))
				if o and o.alive:
					out.append(o)
		out.sort_custom(func(a: NPC, b: NPC) -> bool: return a.coins > b.coins or (a.coins == b.coins and a.id < b.id))
	return out


## Move coins from a party to the manor's treasury (all or nothing).
func _pay_manor(ref: String, amount: int) -> bool:
	if amount <= 0:
		return true
	if purse(ref) < amount:
		return false
	if ref == World.PLAYER:
		w.player.coins -= amount
	else:
		var left := amount
		for o: NPC in _payers(ref):
			var k := mini(left, o.coins)
			o.coins -= k
			o.spent += k
			left -= k
		assert(left == 0)
	w.treasury += amount
	return true


## Move coins from the treasury to a party (all or nothing).
func _manor_pays(ref: String, amount: int) -> bool:
	if amount <= 0:
		return true
	if w.treasury < amount:
		return false
	var to: NPC = null
	if ref != World.PLAYER:
		to = w.party(ref)
		if to == null:
			return false
	w.treasury -= amount
	if to:
		to.coins += amount
		to.earned += amount
	else:
		w.player.coins += amount
	return true


# ---------------------------------------------------------------- deals ----------------------
## Buy from the manor; "" when done, else why not. The price goes to the treasury.
func buy(thing: Dictionary, ref: String) -> String:
	if not for_sale(thing):
		return "The manor is not selling that."
	var price := price_of(thing)
	if not _pay_manor(ref, price):
		return "You need %d coins." % price if ref == World.PLAYER else "They cannot pay %d coins." % price
	for r in unit(thing):
		w.set_owner(r, ref)
	w.stat("gov_land_sales", float(price))
	w.note("%s bought %s from the manor for %d coins." % [w.ref_name(ref, true), describe(thing), price])
	_settle(ref)
	return ""


## Lease from the manor; "" when done. The first week's rent is paid at once, then weekly.
func lease(thing: Dictionary, ref: String) -> String:
	if not for_sale(thing):
		return "The manor is not letting that."
	var rent := rent_of(thing)
	if not _pay_manor(ref, rent):
		return "You need %d coins for the first week's rent." % rent if ref == World.PLAYER else "They cannot pay the rent."
	var u := unit(thing)
	for r in u:
		w.set_tenant(r, ref, rent if r == u[0] else 0)
	w.stat("gov_rent", float(rent))
	w.note("%s leased %s from the manor for %d coins a week." % [w.ref_name(ref, true), describe(thing), rent])
	_settle(ref)
	return ""


## Sell what a party owns back to the manor (the treasury pays sale_value); "" when done.
func sell(thing: Dictionary, ref: String) -> String:
	var u := unit(thing)
	if w.owner_of(u[0]) != ref:
		return "That is not yours to sell."
	for r in u:
		if w.tenant_of(r) != "":
			return "It is let; it cannot be sold now."
		if is_parcel(r) and not r.site.is_empty() and not r.site.get("done", false):
			return "Finish or give up the building site first."
	var value := sale_value(thing)
	if not _manor_pays(ref, value):
		return "The manor cannot pay %d coins now." % value
	for r in u:
		w.set_owner(r, World.MANOR)
	w.stat("gov_land_bought", float(value))
	w.note("%s sold %s to the manor for %d coins." % [w.ref_name(ref, true), describe(thing), value])
	_settle(ref)
	return ""


## Give up a lease. Rent owed is paid as far as the purse allows; the rest is let go.
func end_lease(thing: Dictionary, ref: String) -> String:
	var u := unit(thing)
	if w.tenant_of(u[0]) != ref:
		return "You do not lease that."
	var owed := mini(int(u[0].get("arrears", 0)), purse(ref))
	_pay_manor(ref, owed)
	_release(u, ref)
	w.note("%s gave up the lease of %s." % [w.ref_name(ref, true), describe(thing)])
	_settle(ref)
	return ""


## A tenant leaves: the lease ends, and a building the tenant put up on the leased ground passes to
## the manor with it (provisional).
func _release(u: Array, ref: String) -> void:
	for r in u:
		if w.tenant_of(r) == ref:
			w.set_tenant(r, "")
			r.erase("arrears")
		if w.owner_of(r) == ref and r != u[0]:
			w.set_owner(r, World.MANOR)


## Weekly rent, collected each morning for every lease due (owner rule: weekly, to the manor). A
## tenant who cannot pay all that is owed falls into arrears; after rent_evict_missed unpaid weeks the
## manor takes the lease back and the arrears are let go (agent proposal, provisional).
func collect_rents() -> void:
	var d: int = w.day()
	for r in _all_things():
		var ref: String = w.tenant_of(r)
		if ref == "" or int(r.get("rent", 0)) <= 0 or int(r.get("due_day", -1)) > d:
			continue
		var rent := int(r.rent)
		var owed := rent + int(r.get("arrears", 0))
		r.due_day = int(r.due_day) + WEEK
		if _pay_manor(ref, owed):
			r.arrears = 0
			r.missed = 0
			w.stat("gov_rent", float(owed))
			continue
		r.arrears = owed
		r.missed = int(r.get("missed", 0)) + 1
		if int(r.missed) >= int(GameData.b("rent_evict_missed")):
			_release(unit(r), ref)
			w.note("The manor took back %s: %s owed %d coins of rent." % [describe(r), w.ref_name(ref, false), owed])
			_settle(ref)
		else:
			w.note("%s could not pay the rent for %s: %d coins owed, due with the next week's." % [w.ref_name(ref, true), describe(r), owed])


## A household whose last member died: what it owned goes back to the manor (owner rule), what it
## leased ends, and the stores of its house pass to the manor's granary (escheat; agent proposal),
## so the house can be sold or let again with nothing in it. Nothing is created or lost.
func household_ended(h: int) -> void:
	var hh: Dictionary = w.households[h]
	if hh.get("ended", false):
		return
	hh.ended = true
	var ref := World.hh_ref(h)
	var home_name := describe(w.buildings[hh.home]) if w.buildings.has(str(hh.home)) else ""
	# a house it was building comes down: the materials delivered go to the manor's stores with the
	# rest (cancel_site returns every load), and its hired help goes home
	w.construction.employer_ended(ref)
	for p in w.plots:
		if not p.site.is_empty() and not p.site.get("done", false) and str(p.site.get("owner", "")) == ref:
			w.cancel_site(p, w.granary)
	for r in _all_things():
		if w.tenant_of(r) == ref:
			w.set_tenant(r, "")
		if w.owner_of(r) == ref:
			w.set_owner(r, World.MANOR)
	var pantry: Inventory = hh.pantry
	var moved := 0
	for id in pantry.ids():
		var c := pantry.count(id)
		w.granary.add(id, c)
		moved += c
	pantry.items.clear()
	w.stat("escheat_items", moved)
	w.note("The %s household is no more; %s goes back to the manor%s." % [hh.family, home_name if home_name != "" else "what it held",
			(", and its stores (%d things) to the manor's granary" % moved) if moved > 0 else ""])


## Every household with nobody alive that has not been settled yet (saves from before property).
func settle_ended_households() -> void:
	for h in w.households.size():
		if not w.households[h].get("ended", false) and w.household_in(w.households[h].home) < 0 and not _anyone_alive(h):
			household_ended(h)


func _anyone_alive(h: int) -> bool:
	for m in w.households[h].members:
		var o: NPC = w.npc(int(m))
		if o and o.alive:
			return true
	return false


func _all_things() -> Array:
	var out := records()
	for dict in [w.stalls, w.stations, w.fauna.pens if w.fauna else {}]:
		var ids: Array = dict.keys()
		ids.sort()
		for id in ids:
			out.append(dict[id])
	out.append_array(w.fields)
	return out


## After a deal: the player's home must be a house they hold. A home given up moves to another
## house they hold (lowest id), or they are homeless (the family chest stays theirs, reached again
## from their next home; owner question answered by agent proposal). A first house becomes the home.
func _settle(ref: String) -> void:
	if ref != World.PLAYER:
		return
	var homes := homes_of(World.PLAYER)
	var p: PlayerState = w.player
	if p.home != "" and homes.has(p.home):
		return
	var was := p.home
	p.home = homes[0] if not homes.is_empty() else ""
	if p.home != was:
		w.note("%s %s's home is now %s." % [p.name, p.family, describe(w.buildings[p.home]) if p.home != "" else "nowhere: the family chest waits for the next house"])


## Choose which held house is the player's home (respawn point, bed and chest); "" when done.
func set_home(id: String) -> String:
	if not homes_of(World.PLAYER).has(id):
		return "That is not your house."
	w.player.home = id
	return ""


# ---------------------------------------------------------------- stalls ---------------------
## The manor lets a vacant market stall again (audit defect 2): each morning, to the first villager
## (by id) who is out of work or a manor hand and has stall_min_coins to stock it. Rent-free for now
## (provisional). The new merchant keeps the stall's kind.
func relet_stalls() -> void:
	var ids: Array = w.stalls.keys()
	ids.sort()
	for sid in ids:
		var s: Dictionary = w.stalls[sid]
		var t: NPC = w.party(w.tenant_of(s))
		if t != null and t.job == "merchant" and t.workplace == sid:
			continue
		if w.tenant_of(s) != "":
			w.set_tenant(s, "")
		for n: NPC in w.npcs:
			if n.alive and n.role == "adult" and n.job in ["", "manor_hand"] and n.coins >= int(GameData.b("stall_min_coins")):
				w.brain._change_job(n, "merchant", "the manor let them the vacant %s" % sid, sid)
				break


# ---------------------------------------------------------------- claiming ground ------------
## Why a rectangle of ground cannot be claimed, or "" if it can (phase 2 places buildings with it):
## inside the village with a margin, nothing built or kept there (buildings, fields, pens, stalls,
## stations, containers, the mine's seams), not on the road, no tree (fell it first), the ground
## walkable, and no surveyed parcel on it (an unsold one is bought as it is, not re-cut).
func can_claim(rect: Rect2i) -> String:
	var m: VillageMap = w.map
	if rect.size.x < 3 or rect.size.y < 3:
		return "too small"
	if rect.position.x < 1 or rect.position.y < 1 or rect.end.x > m.w - 1 or rect.end.y > m.h - 1:
		return "outside the village"
	for b in records():
		if Rect2i(int(b.x), int(b.y), int(b.w), int(b.h)).intersects(rect):
			return ("surveyed land (%s)" % describe(b)) if is_parcel(b) else ("a building (%s)" % describe(b))
	for f in w.fields:
		if Rect2i(int(f.x), int(f.y), int(f.w), int(f.h)).intersects(rect):
			return "the manor's fields"
	var pens: Array = w.fauna.pens.keys()
	pens.sort()
	for id in pens:
		var p: Dictionary = w.fauna.pens[id]
		if Rect2i(int(p.x), int(p.y), int(p.w), int(p.h)).intersects(rect):
			return "the %s pen" % p.kind
	var spots := []
	for id in w.stalls:
		spots.append([w.stalls[id].x, w.stalls[id].y, "the market"])
		spots.append([w.stalls[id].use[0], w.stalls[id].use[1], "the market"])
	for id in w.stations:
		spots.append([w.stations[id].at[0], w.stations[id].at[1], "the " + str(w.stations[id].type)])
		spots.append([w.stations[id].use[0], w.stations[id].use[1], "the " + str(w.stations[id].type)])
	for c in w.containers:
		spots.append([c.x, c.y, "a " + str(c.kind)])
	for d in w.deposits:
		spots.append([d.x, d.y, "the mine"])
	for t in w.trees:
		if t.state == "grown":             # a stump or sapling is grubbed up when the ground is claimed
			spots.append([t.x, t.y, "a tree (fell it first)"])
	for s in spots:
		if rect.has_point(Vector2i(int(s[0]), int(s[1]))):
			return s[2]
	if _road.is_empty():
		for c in m.data.road:
			_road[Vector2i(int(c[0]), int(c[1]))] = true
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if _road.has(Vector2i(x, y)):
				return "the road"
			if m.is_solid(Vector2i(x, y)):
				return "the ground is not clear"
	return ""


## Survey a new parcel on clear ground and buy or lease it from the manor on the spot (owner rule:
## "free placement anywhere legal"). Returns the parcel, or {} with the reason in `why`.
func claim(rect: Rect2i, ref: String, lease_it := false) -> Dictionary:
	why = can_claim(rect)
	if why != "":
		return {}
	var p := {"id": "parcel%d" % next_parcel, "x": rect.position.x, "y": rect.position.y, "w": rect.size.x, "h": rect.size.y,
		"door": [rect.position.x + rect.size.x / 2, rect.end.y - 1], "price": land_price(rect.size.x, rect.size.y),
		"owner": World.MANOR, "tenant": "", "site": {}, "building": ""}
	w.plots.append(p)
	why = lease(p, ref) if lease_it else buy(p, ref)
	if why != "":
		w.plots.erase(p)
		return {}
	next_parcel += 1
	# the stumps and saplings of felled trees on it are grubbed up: they will not grow again there
	for t in w.trees:
		if t.state != "grown" and t.state != "cleared" and rect.has_point(Vector2i(int(t.x), int(t.y))):
			t.state = "cleared"
			w.tile_changed.emit(Vector2i(int(t.x), int(t.y)), "below", -1)
	return p
