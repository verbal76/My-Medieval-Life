class_name Construction
extends RefCounted
## Property phase 2: what can be built and where, hired helpers, and households that outgrow their
## house. Building itself is World.start_site / deliver / cancel_site (one construction for all
## builders); land is bought or leased only through the land office (Property.can_claim / claim); who
## owns what only through the World owner API. Nothing here makes or destroys coins or goods: wages
## and purchases move coins between purses, helpers carry the employer's goods.
##
## Owner rules (2026-10-18, docs/DECISIONS.md "Property and construction"): building is free placement
## anywhere legal, the ground bought or leased from the manor on the spot; a frame site with a
## progress bar, materials only, cancelling returns everything; NPCs build by the same rules; a house
## first, then workshops; helpers are hired for coin and carry the owner's goods, the owner keeps the
## building; crowded households split: a grown member founds a household, gets land (or an empty
## house), builds by the player's rules (or moves into the empty house) and moves in; workshops are
## buildings with stations, used by their owner or tenant, others with permission. Every number is an
## agent proposal in balance.json, provisional until the balance review.

## Every kind of building (PL2-008/014: one modular foundation). A house is the property's first
## building; every other kind is a module that can be added to a property later, beside what is there
## and without touching it, or stand alone as a shop on its own ground (STANDALONE; the owner's rule
## "a house first" still holds for a new property). Storage and living quarters only make sense as
## rooms of a property. No kind locks anybody into a trade: villagers and the player use any station.
const KINDS := ["house", "smithy", "carpentry", "bakehouse", "kitchen", "apothecary", "storage", "quarters"]
const STANDALONE := ["house", "smithy", "carpentry", "bakehouse", "kitchen", "apothecary"]
const MODULES := ["smithy", "carpentry", "bakehouse", "kitchen", "apothecary", "storage", "quarters"]
const NAMES := {"house": "house", "smithy": "smithy", "carpentry": "carpenter's shop", "bakehouse": "bakehouse",
	"kitchen": "kitchen", "apothecary": "apothecary", "storage": "storeroom", "quarters": "living quarters"}
## What each module is for, in a few words (menus and the wiki).
const PURPOSE := {"smithy": "a forge and an anvil", "carpentry": "a workbench and a sawhorse", "bakehouse": "an oven and a stove",
	"kitchen": "a stove for cooking and brewing", "apothecary": "a stove for tonics and poultices",
	"storage": "a room that opens the family chest from here", "quarters": "more beds for the household"}
const ATTACH_MIN := 3         # cells two buildings must share along a wall to count as joined
const HIRABLE := ["", "manor_hand", "laborer"]     # out of work, or labouring: free to be hired for a day
## Who sells each building material (NPCBrain.buy_role), in order of preference.
const SELLERS := {"plank": ["carpenter", "merchant_raw"], "stone": ["merchant_raw", "laborer"],
	"log": ["woodcutter", "merchant_raw"], "iron_bar": ["smith", "merchant_goods"]}

var w: World
var why := ""                 # why the last place() or hire() failed
## Helpers hired for the day: {worker: npc id, employer: reference, site: parcel id, day, wage,
## budget: coins they may spend on materials, spent, load: Inventory (the employer's goods they carry)}
var contracts: Array = []


func _init(world: World) -> void:
	w = world


# ---------------------------------------------------------------- kinds ----------------------
## "house", "smithy", "carpenter's shop"; with `article`, "a house", "a smithy".
static func kind_name(kind: String, article := false) -> String:
	var n: String = NAMES.get(kind, kind)
	return ("a " + n) if article else n


static func stamp_name(kind: String) -> String:
	return "house" if kind == "house" or kind == "quarters" else "workshop_" + kind


static func is_workshop(kind: String) -> bool:
	return kind != "house" and KINDS.has(kind)


## Materials a building of this kind takes (balance.json house_cost, workshop_cost).
func cost_of(kind: String) -> Dictionary:
	if kind == "house":
		return GameData.b("house_cost")
	return (GameData.b("workshop_cost") as Dictionary).get(kind, GameData.b("house_cost"))


## The ground a building of this kind covers (its stamp's size).
func footprint(kind: String) -> Vector2i:
	var st: Dictionary = w.map.data.stamps.get(stamp_name(kind), w.map.data.stamps.house)
	return Vector2i(int(st.w), int(st.h))


## The stations a workshop of this kind has ("forge", "anvil"), from its stamp.
func stations_of_kind(kind: String) -> Array:
	var st: Dictionary = w.map.data.stamps.get(stamp_name(kind), {})
	return st.get("stations", []).map(func(s): return str(s.type))


## Owner rule: a house first, then workshops. A workshop needs a house the builder owns.
func may_build(kind: String, ref: String, anchor := {}) -> String:
	if not KINDS.has(kind):
		return "Nothing of that kind can be built."
	if not anchor.is_empty():
		return module_refusal(kind, anchor, ref)
	if not STANDALONE.has(kind):
		return "A %s is added to a property you hold; it does not stand alone." % kind_name(kind)
	if kind == "house":
		return ""
	for id in w.property.homes_of(ref):
		if w.owner_of(w.buildings[id]) == ref:
			return ""
	return "A house comes first: own a house before building a workshop."


## Why a building of this kind cannot go on this ground for `ref`, "" if it can: the house-first
## rule, the land office's check (Property.can_claim), and a door step that is clear and reachable
## from the village, so nobody builds a door into a wall or a house nobody can reach.
func can_place(kind: String, rect: Rect2i, ref: String, anchor := {}) -> String:
	var no := may_build(kind, ref, anchor)
	if no != "":
		return no
	if rect.size != footprint(kind):
		return "a %s needs %dx%d ground" % [kind_name(kind), footprint(kind).x, footprint(kind).y]
	no = w.property.can_claim(rect)
	if no != "":
		return no
	if not anchor.is_empty():
		no = attach_refusal(rect, anchor)
		if no != "":
			return no
	var step := door_step(kind, rect)
	if w.map.is_solid(step):
		return "the door would open onto %s" % ("the edge of the village" if step.y >= w.map.h - 1 else "something in the way")
	var sp = w.map.data.spawns.player
	if w.map.find_path(step, Vector2i(int(sp[0]), int(sp[1]))).is_empty():
		return "nobody could reach the door"
	return ""


## The cell in front of the door of a building of this kind on this ground.
func door_step(kind: String, rect: Rect2i) -> Vector2i:
	var st: Dictionary = w.map.data.stamps.get(stamp_name(kind), w.map.data.stamps.house)
	return rect.position + Vector2i(int(st.door[0]), int(st.door[1]) + 1)


## What the ground costs: {price, rent} (Property land price and a week's rent for its size).
func ground_terms(rect: Rect2i) -> Dictionary:
	var price: int = w.property.land_price(rect.size.x, rect.size.y)
	return {"price": price, "rent": maxi(1, ceili(price * float(GameData.b("weekly_rent_share"))))}


## The whole flow in one (owner rule): survey the ground, buy or lease it from the manor on the spot,
## and mark out the site. Returns the parcel, or {} with the reason in `why`.
func place(kind: String, rect: Rect2i, ref: String, lease := false, anchor := {}) -> Dictionary:
	why = can_place(kind, rect, ref, anchor)
	if why != "":
		return {}
	var p: Dictionary = w.property.claim(rect, ref, lease)
	if p.is_empty():
		why = w.property.why
		return {}
	if not anchor.is_empty():
		p.estate = w.property.estate_id(anchor)       # the same property from now on
	w.start_site(p, kind, ref)
	return p


# ---------------------------------------------------------------- modules (PL2-008, PL2-014) -----
## Why `ref` cannot add a module of this kind to the property of `anchor` (any of its parcels), ""
## if it can: the property is theirs (owned or leased), its first building stands, nothing is being
## built on it, and it has no room of that kind yet (one of each).
func module_refusal(kind: String, anchor: Dictionary, ref: String) -> String:
	if not MODULES.has(kind):
		return "A %s cannot be added to a property." % kind_name(kind)
	var head: Dictionary = w.property.anchor_of(anchor)
	if not w.holds(ref, head):
		return "It is not your property."
	if w.property.building_on(head).is_empty():
		return "Finish the first building before adding to the property."
	for q in w.property.estate_parcels(head):
		if not q.site.is_empty() and not q.site.get("done", false):
			return "Finish the building on the property first."
	if w.property.has_module(head, kind):
		return "The property already has a %s." % kind_name(kind)
	return ""


## A module must touch what the property already has: its wall shares at least ATTACH_MIN cells with
## a building (or a site) of the property, and it must not cover any of their door steps.
func attach_refusal(rect: Rect2i, anchor: Dictionary) -> String:
	var touches := false
	for q in w.property.estate_parcels(anchor):
		var r := Rect2i(int(q.x), int(q.y), int(q.w), int(q.h))
		var step := Vector2i(int(q.door[0]), int(q.door[1]) + 1)
		if rect.has_point(step):
			return "it would cover the door of %s" % w.property.describe(q)
		var along_x := mini(rect.end.x, r.end.x) - maxi(rect.position.x, r.position.x)
		var along_y := mini(rect.end.y, r.end.y) - maxi(rect.position.y, r.position.y)
		if ((rect.end.y == r.position.y or r.end.y == rect.position.y) and along_x >= ATTACH_MIN) \
				or ((rect.end.x == r.position.x or r.end.x == rect.position.x) and along_y >= ATTACH_MIN):
			touches = true
	return "" if touches else "it must stand against the property's buildings"


## A good place for a module: the first (nearest the property's first building) ground that
## can_place accepts, searched beside each building of the property; failing that, ground where only
## trees stand in the way (the ghost shows it red with "fell it first"); or an empty rect.
func find_module_slot(kind: String, anchor: Dictionary, ref: String) -> Rect2i:
	var size := footprint(kind)
	var head: Dictionary = w.property.anchor_of(anchor)
	var best := Rect2i()
	var best_d := 1 << 30
	var treed := Rect2i()
	var treed_d := 1 << 30
	for q in w.property.estate_parcels(head):
		var cands := []
		for dy in range(-size.y, int(q.h) + 1, 1):
			for dx in [-size.x, int(q.w)]:
				cands.append([Rect2i(int(q.x) + dx, int(q.y) + dy, size.x, size.y), absi(dy) * 2 + absi(dx) / 4])
		for dx in range(-size.x, int(q.w) + 1, 1):
			for dy in [-size.y, int(q.h)]:
				cands.append([Rect2i(int(q.x) + dx, int(q.y) + dy, size.x, size.y), absi(dx) * 2 + absi(dy) / 4 + 3])
		for cd in cands:
			var no := can_place(kind, cd[0], ref, head)
			if no == "" and cd[1] < best_d:
				best = cd[0]
				best_d = cd[1]
			elif no.begins_with("a tree") and cd[1] < treed_d:
				treed = cd[0]
				treed_d = cd[1]
	return best if best.size != Vector2i.ZERO else treed


## Unfinished sites `ref` is building (the site's owner), in registry order.
func sites_of(ref: String) -> Array:
	return w.plots.filter(func(p): return not p.site.is_empty() and not p.site.get("done", false) and str(p.site.get("owner", "")) == ref)


## What every open site still needs of an item: kept on sale for builders (public works and repairs
## leave it; the audit's "public works starve builders").
func open_need(id: String) -> int:
	var n := 0
	for p in w.plots:
		if not p.site.is_empty() and not p.site.get("done", false):
			n += int(p.site.need.get(id, 0))
	return n


## What the rest of a site would cost at the market now (the cheapest seller of each item).
func estimate(need: Dictionary) -> int:
	var total := 0
	for id in need:
		var price := ceili(GameData.value(id) * 1.5)
		for o: NPC in w.npcs:
			if o.alive and o.role == "adult" and _sells(o, id) and o.inv.has(id):
				price = mini(price, w.sell_price(o, id))
		total += price * int(need[id])
	return total


# ---------------------------------------------------------------- helpers --------------------
## Why this villager cannot be hired to carry today, "" if they can: an adult awake, out of work or
## labouring (HIRABLE), not hired by anyone else today.
func can_hire(n: NPC) -> String:
	if n == null or not n.alive or n.role != "adult" or n.household < 0:
		return "They cannot work for you."
	if not n.job in HIRABLE:
		return "%s has work of their own." % n.name
	if not contract_of(n).is_empty():
		return "%s is already hired for today." % n.name
	if w.business != null and w.business.is_attendant(n):
		return "%s minds a counter already." % n.name
	return ""


func contract_of(n: NPC) -> Dictionary:
	for c in contracts:
		if int(c.worker) == n.id:
			return c
	return {}


## Hire `n` for the rest of the day to carry the employer's goods to site `p` (the employer must be the
## site's owner). The wage (helper_wage; none for a member of the employer's own household) is paid
## from the employer's purse at once, all or nothing. `budget`: coins the helper may spend of the
## employer's on materials at the market (0: only fetch from the employer's own store). "" when done.
## A member of the employer's own household may carry for it whatever their work (no wage; a day
## away from it): a founder building their own house.
func hire(employer: String, n: NPC, p: Dictionary, budget: int) -> String:
	var own := n != null and n.household >= 0 and employer == World.hh_ref(n.household)
	why = can_hire(n) if not own else ("" if n.alive and contract_of(n).is_empty() else "They cannot carry today.")
	if why == "" and (p.site.is_empty() or p.site.get("done", false) or str(p.site.get("owner", "")) != employer):
		why = "There is no building site of yours to carry to."
	if why != "":
		return why
	# a friend of the player carries as a favour, for no wage (CRT-06)
	var favour: bool = employer == World.PLAYER and w.relations.player_friend(n)
	var wage := 0 if own or favour else int(GameData.b("helper_wage"))
	if not _pay(employer, n, wage):
		why = "You need %d coins for the wage." % wage if employer == World.PLAYER else "They cannot pay the wage."
		return why
	# the day's work: today's, or tomorrow's when hired after working hours
	var day: int = w.day() + (1 if w.hour() >= NPCBrain.WORK_END else 0)
	contracts.append({"worker": n.id, "employer": employer, "site": str(p.id), "day": day, "wage": wage,
		"budget": maxi(0, budget), "spent": 0, "load": Inventory.new()})
	n.plan.clear()
	w.stat("helper_wages", wage)
	if own:
		w.note("%s %s carries materials to %s." % [n.name, n.family, w.property.describe(p)])
	else:
		w.note("%s hires %s %s for %d coins to carry materials to %s." % [w.ref_name(employer, true), n.name, n.family, wage, w.property.describe(p)])
	return ""


## The wage, from the employer's purse to the worker's (the player's coins, or a household's members'
## richest first). Nothing moves unless all of it can.
func _pay(employer: String, n: NPC, amount: int) -> bool:
	if amount <= 0:
		return true
	if w.property.purse(employer) < amount:
		return false
	_take(employer, amount)
	n.coins += amount
	n.earned += amount
	return true


## Take `amount` from a party's purse (it has been checked to hold it).
func _take(ref: String, amount: int) -> void:
	if ref == World.PLAYER:
		w.player.coins -= amount
		return
	var left := amount
	for o: NPC in w.property._payers(ref):
		var k := mini(left, o.coins)
		o.coins -= k
		o.spent += k
		left -= k
	assert(left == 0)


## Where the employer keeps goods: the player's family chest (at their home), a household's pantry
## (its crates at home, or its corner of the house it lodges in). Null when it is out of reach (a
## homeless player).
func store_of(ref: String) -> Inventory:
	if ref == World.PLAYER:
		return w.player.chest if w.player.home != "" and w.buildings.has(w.player.home) else null
	var h := World.ref_id(ref)
	if ref.begins_with("hh:") and h >= 0 and h < w.households.size() and w.buildings.has(_home_of(ref)):
		return w.households[h].pantry
	return null


## The house where the employer's store is: the player's home, a household's home or the house it
## lodges in.
func _home_of(ref: String) -> String:
	if ref == World.PLAYER:
		return w.player.home
	var home := str(w.households[World.ref_id(ref)].home)
	if home == "" and w.party(ref) != null:
		home = w.party(ref).home
	return home


func _store_cell(ref: String) -> Vector2i:
	return w.building_door(_home_of(ref))


## The helper's next steps (NPCBrain.decide, in working hours), or false when they have no contract
## (or it is over). One load at a time, really carried: what they carry for the site to the site; else
## fetch the next needed material from the employer's store, or buy it with the employer's coins.
func plan_helper(n: NPC) -> bool:
	var c := contract_of(n)
	if c.is_empty():
		return false
	if int(c.day) > w.day():
		return false                       # hired for tomorrow
	var p: Dictionary = w.plot(str(c.site))
	if p.is_empty() or p.site.is_empty() or p.site.get("done", false) or int(c.day) < w.day():
		end_contract(c, "the work is done" if not p.is_empty() and p.site.get("done", false) else "the day's work is over")
		return false
	var b: NPCBrain = w.brain
	var site_cell := Vector2i(int(p.door[0]), int(p.door[1]))
	var load: Inventory = c.load
	var need: Dictionary = p.site.need
	for id in need:
		if load.has(id):
			n.doing = "carrying %s to %s" % [GameData.item_name(id).to_lower(), "the building site"]
			n.plan = [b.go(site_cell), b.doit("helper_deliver")]
			return true
	var ids: Array = need.keys()
	ids.sort()
	var store := store_of(str(c.employer))
	for id in ids:
		if store != null and store.has(id):
			n.doing = "fetching %s for the building site" % GameData.item_name(id).to_lower()
			n.plan = [b.go(_store_cell(str(c.employer))), b.doit("helper_take", {"item": id})]
			return true
	for id in ids:
		var seller := _seller(id, n, c)
		if seller != null:
			n.doing = "buying %s for the building site" % GameData.item_name(id).to_lower()
			n.plan = [b.go(b._workplace_cell(seller) if seller.job != "laborer" else seller.cell()), b.doit("helper_buy", {"item": id, "seller": seller.id})]
			return true
	b.once("helper_idle_%d_%d" % [n.id, w.day()], "%s %s can find no materials to carry to %s." % [n.name, n.family, w.property.describe(p)])
	n.doing = "waiting for building materials"
	n.plan = [b.go(site_cell), b.work(45, "", {}, "idle")]
	return true


## The nearest villager selling a material whom the helper can pay (from the employer's purse,
## within the budget left), awake; none of the helper's own goods.
func _seller(id: String, n: NPC, c: Dictionary) -> NPC:
	if not SELLERS.has(id):
		return null
	var left := mini(int(c.budget) - int(c.spent), w.property.purse(str(c.employer)))
	var best: NPC = null
	var bd := 1e9
	for o: NPC in w.npcs:
		if o == n or not o.alive or w.asleep(o) or not _sells(o, id) or o.inv.count(id) <= _keeps(o, id):
			continue
		if w.sell_price(o, id) > left:
			continue
		var d := n.pos.distance_to(o.pos)
		if d < bd:
			bd = d
			best = o
	return best


func _sells(o: NPC, id: String) -> bool:
	return o.role == "adult" and (SELLERS.get(id, []) as Array).has(w.brain.buy_role(o))


## What a seller holds back of a material for their own work: a smith the bars for a day's forging.
func _keeps(o: NPC, id: String) -> int:
	return 4 if o.job == "smith" and id == "iron_bar" else 0


## A helper's actions (NPCBrain.act): take from the employer's store, buy with the employer's coins,
## deliver to the site (World.deliver: the building is the site owner's, whoever delivers).
func act(n: NPC, what: String, a: Dictionary) -> bool:
	var c := contract_of(n)
	if c.is_empty():
		return false
	var p: Dictionary = w.plot(str(c.site))
	if p.is_empty() or p.site.is_empty() or p.site.get("done", false):
		return false
	var load: Inventory = c.load
	match what:
		"helper_take":
			var store := store_of(str(c.employer))
			var id := str(a.item)
			var k := mini(int(p.site.need.get(id, 0)) - load.count(id), store.count(id) if store else 0)
			if k <= 0:
				return false
			store.remove(id, k)
			load.add(id, k)
			w.stat("helper_took_" + id, k)
			if c.employer == World.PLAYER:
				w.player.trim_stolen()
			return true
		"helper_buy":
			var seller := w.npc(int(a.seller))
			var id := str(a.item)
			if seller == null or not seller.alive:
				return false
			var want := int(p.site.need.get(id, 0)) - load.count(id)
			var got := 0
			while got < want and seller.inv.count(id) > _keeps(seller, id):
				var price := w.sell_price(seller, id)
				if int(c.spent) + price > int(c.budget) or w.property.purse(str(c.employer)) < price:
					break
				_take(str(c.employer), price)
				seller.inv.remove(id)
				seller.coins += price
				seller.earned += price
				load.add(id)
				c.spent = int(c.spent) + price
				w.stat("helper_bought", price)
				w.stat("helper_bought_" + id)
				got += 1
			return got > 0
		"helper_deliver":
			if w.deliver(p, load, World.npc_ref(n.id)):
				end_contract(c, "the building is finished")
			return true
	return false


## The contract ends: what the helper still carries goes back to the employer's store (or, out of
## reach, lies in a bundle at the site), and they go back to their own day.
func end_contract(c: Dictionary, reason := "") -> void:
	if not contracts.has(c):
		return
	contracts.erase(c)
	var load: Inventory = c.load
	if load.total() > 0:
		var to := _return_store(str(c.employer))
		var p: Dictionary = w.plot(str(c.site))
		if to != null:
			for id in load.ids():
				to.add(id, load.count(id))
		elif not p.is_empty():
			var bag := Inventory.new()
			for id in load.ids():
				bag.add(id, load.count(id))
			w.loot.append({"pos": Vector2(float(p.door[0]) + 0.5, float(p.door[1]) + 0.5), "inv": bag, "coins": 0, "from": "the building site"})
		load.items.clear()
	var n: NPC = w.npc(int(c.worker))
	if n and n.alive:
		n.plan.clear()
		if reason != "":
			n.remember("carried for %s: %s" % [w.ref_name(str(c.employer)), reason])


## Goods carried back go to the employer's store, wherever it is (the family chest, the household's
## pantry); a household that has died out: the manor's stores (escheat, as Property.household_ended).
func _return_store(ref: String) -> Inventory:
	if ref == World.PLAYER:
		return w.player.chest
	var h := World.ref_id(ref)
	if ref.begins_with("hh:") and h >= 0 and h < w.households.size():
		return w.granary if w.households[h].get("ended", false) else w.households[h].pantry
	return w.granary


func on_death(n: NPC) -> void:
	var c := contract_of(n)
	if not c.is_empty():
		end_contract(c)


func employer_ended(ref: String) -> void:
	for c in contracts.duplicate():
		if str(c.employer) == ref:
			end_contract(c)


## Goods helpers carry, item -> count (the goods ledger).
func carried() -> Dictionary:
	var out := {}
	for c in contracts:
		var load: Inventory = c.load
		for id in load.ids():
			out[id] = int(out.get(id, 0)) + load.count(id)
	return out


# ---------------------------------------------------------------- households -----------------
## Beds a home has for its household: its real beds; straw pallets are for lodgers and guests.
func beds_in(home: String) -> int:
	var n := 0
	for room in w.property.rooms_of(home):           # the house and the living quarters added to it
		for s in w.interiors.get(room, {}).get("spots", []):
			if s.kind == "bed" and int(s.get("tile", -1)) % 100000 != 593:
				n += 1
	return n


## A household too big for its house (owner rule; definition an agent proposal): more living members
## than the house has beds (a birth needs no free bed, owner 2026-10-19, so babies crowd a house), in a
## house it holds, with two grown members or more (one founds a new household and one stays with the rest).
func crowded(h: int) -> bool:
	var hh: Dictionary = w.households[h]
	if hh.get("ended", false) or not w.buildings.has(str(hh.home)) or not w.property.is_home(w.buildings[hh.home]):
		return false
	if not w.holds(World.hh_ref(h), w.buildings[hh.home]):
		return false
	var members: Array = w.brain._members(h)
	return members.size() > beds_in(str(hh.home)) and members.filter(func(o: NPC) -> bool: return o.role == "adult").size() >= 2


## Who leaves to found the new household: a grown son or daughter first, else an adult with no partner in
## the household; the last such by id, never the reeve or the sage (their posts go with the manor house and
## the hut), a guard, or a parent of young children at home. Partners are never split: a founder's partner
## in the household leaves too (_found). Null when nobody can go.
func founder_of(h: int) -> NPC:
	var adults: Array = w.brain._members(h).filter(func(o: NPC) -> bool: return o.role == "adult" and _may_found(o))
	adults.sort_custom(func(a: NPC, b: NPC) -> bool: return a.id < b.id)
	var grown: Array = adults.filter(func(o: NPC) -> bool: return _grown_child(o))
	if not grown.is_empty():
		return grown.back()
	var single: Array = adults.filter(func(o: NPC) -> bool: return not _partner_here(o))
	return single.back() if not single.is_empty() else null


func _partner_here(o: NPC) -> bool:
	var p := w.npc(o.partner) if o.partner >= 0 else null
	return p != null and p.alive and p.household == o.household


## What the household keeps for those who stay (split_keep_base + split_keep_per_member each).
func _keep(h: int, staying: int) -> int:
	return int(GameData.b("split_keep_base")) + int(GameData.b("split_keep_per_member")) * staying


## Each dawn: helpers' contracts from yesterday end; households building carry on (hire a helper, or
## carry themselves); every household with a housing need works toward it (HOUSE-01..06): a crowded
## household splits when a grown member can leave (at most one a day), else enlarges its own house with
## living quarters; couples who need a home of their own found one. A need that cannot be met yet stays
## as the household's housing goal with its plan and the reason it waits (housing_goals).
func daily() -> void:
	for c in contracts.duplicate():
		if int(c.day) < w.day():
			end_contract(c, "the day's work is over")
	var needs := {}                    # household -> goal keys still true today
	for h in w.households.size():
		var hh: Dictionary = w.households[h]
		if hh.get("ended", false) or w.brain._members(h).is_empty():
			continue
		_rehouse(h)
		if str(hh.get("build", "")) != "":
			_keep_building(h)
		elif str(hh.home) == "":
			_find_home(h)                  # lodging: a house of its own when it can pay for one
			if str(hh.home) == "":
				_note_need(needs, h, "no home")
	var split := false
	for h in w.households.size():
		if not crowded(h):
			continue
		_note_need(needs, h, "crowded")
		if str(w.households[h].get("build", "")) != "":
			continue                       # already building toward it
		if founder_of(h) != null:
			if not split and _found(h):
				split = true
		else:
			_enlarge(h)
	var founded := false
	for pair in couples_needing_home():
		var f: NPC = pair[0]
		var m: NPC = pair[1]
		if f.household != m.household and Life._move_in(w, f, m):
			w.note("%s %s and %s %s now live under one roof." % [f.name, f.family, m.name, m.family])
			continue
		_note_need(needs, f.household, "couple:%d:%d" % [f.id, m.id])
		if not founded and _found_couple(f, m):
			founded = true
	for h in w.households.size():         # a need that has gone takes its goal with it
		var goals: Dictionary = w.households[h].get("housing", {})
		for k in goals.keys():
			if not (needs.get(h, []) as Array).has(k):
				goals.erase(k)
		if goals.is_empty():
			w.households[h].erase("housing")


# ---------------------------------------------------------------- housing goals (HOUSE-01..06) -
## The household's housing goals (owner directive 2026-10-20): need -> {need, since (day), by (the
## responsible adult's id), plan ("split", "quarters", "home", "couple"), cost (coins the next step
## needs), short (coins still to put by), why (what it waits on, "" while it is being built)}. Saved with
## the household. Need keys: "crowded", "no home", "couple:<id>:<id>".
func housing_goals(h: int) -> Dictionary:
	return w.households[h].get("housing", {}) if h >= 0 and h < w.households.size() else {}


func _note_need(needs: Dictionary, h: int, key: String) -> void:
	if h < 0:
		return
	if not needs.has(h):
		needs[h] = []
	(needs[h] as Array).append(key)


## Record or refresh a goal; a new need starts its `since` day, and keeps it while it lasts.
func _goal(h: int, key: String, plan: String, cost: int, short: int, why: String) -> void:
	var hh: Dictionary = w.households[h]
	if not hh.has("housing"):
		hh.housing = {}
	var g: Dictionary = hh.housing.get(key, {"need": key.get_slice(":", 0), "since": w.day()})
	var by := responsible_adult(h)
	g.by = by.id if by != null else -1
	g.plan = plan
	g.cost = cost
	g.short = maxi(0, short)
	g.why = why
	hh.housing[key] = g


## Whether `n`'s household is putting money by for a home (HOUSE-04): a goal that waits on coins, or a
## house being built and bought for. Lower-priority purchases (courting gifts) wait.
func saving_for_home(n: NPC) -> bool:
	if n.household < 0 or n.household >= w.households.size():
		return false
	if str(w.households[n.household].get("build", "")) != "":
		return true
	for g in housing_goals(n.household).values():
		if int(g.get("short", 0)) > 0:
			return true
	return false


## The adult who decides for a household (HOUSE-02, FAM-01): of its living adults (elders when it has
## none, never a child), a parent of someone living in it first, then the eldest; the lowest id on a tie.
## When one parent dies the other is the parent left, so they decide; sex plays no part.
func responsible_adult(h: int) -> NPC:
	var members: Array = w.brain._members(h)
	var grown: Array = members.filter(func(o: NPC) -> bool: return o.role == "adult")
	if grown.is_empty():
		grown = members.filter(func(o: NPC) -> bool: return o.role == "elder")
	if grown.is_empty():
		return null
	grown.sort_custom(func(a: NPC, b: NPC) -> bool:
		var pa := _parent_here(a)
		var pb := _parent_here(b)
		if pa != pb:
			return pa
		if a.born != b.born:
			return a.born < b.born
		return a.id < b.id)
	return grown[0]


func _parent_here(o: NPC) -> bool:
	for cid in o.children:
		var k := w.npc(int(cid))
		if k != null and k.alive and k.household == o.household:
			return true
	return false


## What starting a building of this kind on ground of this size takes in hand (EQ-07): the ground and
## found_start_share of the materials at today's prices; the rest is bought as the household earns.
func start_cost(kind: String, size: Vector2i) -> int:
	return w.property.land_price(size.x, size.y) + ceili(estimate(cost_of(kind)) * float(GameData.b("found_start_share")))


## A crowded household that nobody can leave (the parents of young children, HOUSE-06) enlarges its own
## house with living quarters, the existing module that adds beds, started and built as a house is
## (start_cost, then _keep_building). What the household keeps to live on (_keep) is never spent on it.
## When it cannot start yet, its goal says why: coins to put by, no ground, or quarters already built.
func _enlarge(h: int) -> void:
	var hh: Dictionary = w.households[h]
	var ref := World.hh_ref(h)
	var house: Dictionary = w.buildings[str(hh.home)]
	if w.property.anchor_of(house).is_empty():
		_goal(h, "crowded", "quarters", 0, 0, "the house stands on no parcel that can be added to")
		return
	if w.property.has_module(house, "quarters"):
		_goal(h, "crowded", "quarters", 0, 0, "the house has its living quarters already; it waits until a grown child can leave")
		return
	var rect := find_module_slot("quarters", house, ref)
	var no := "no ground beside the house for living quarters" if rect.size == Vector2i.ZERO else can_place("quarters", rect, ref, house)
	if no != "":
		_goal(h, "crowded", "quarters", 0, 0, no)
		return
	var cost := start_cost("quarters", rect.size)
	var spare: int = w.property.purse(ref) - _keep(h, w.brain._members(h).size())
	if spare < cost:
		_goal(h, "crowded", "quarters", cost, cost - spare, "saving for living quarters")
		return
	var p := place("quarters", rect, ref, false, house)
	if p.is_empty():
		_goal(h, "crowded", "quarters", cost, 0, why)
		return
	hh.build = str(p.id)
	_goal(h, "crowded", "quarters", cost, 0, "")
	var by := responsible_adult(h)
	w.note("The %s house is crowded: %s sets about adding living quarters to it." % [hh.family, by.name if by != null else "the family"])
	w.stat("quarters_started")
	_keep_building(h)


## Couples who want a home of their own (EQ-07): partners who live in different households, or a grown
## child and their partner in their parents' full house. Never the reeve, the sage or a guard (their posts
## come with a house), nor anyone with young children at home. Any two partners (HOUSE-02: sex decides
## nothing); each pair once, led by the woman of a man and a woman (whose family name the household
## takes, as before), else by the lower id. In id order of the one who leads.
func couples_needing_home() -> Array:
	var out := []
	for f: NPC in w.npcs:
		if not f.alive or f.role != "adult" or f.partner < 0:
			continue
		var m := w.npc(f.partner)
		if m == null or not m.alive or m.partner != f.id or not (_may_found(f) and _may_found(m)):
			continue
		if (f.sex == m.sex and f.id > m.id) or (f.sex != m.sex and f.sex != "female"):
			continue
		if Life._building(w, f) and Life._building(w, m):
			continue                       # each finishes the house they started (Life._move_in)
		if f.household != m.household:
			out.append([f, m])
		elif not Life.has_room(w, f.household) and (_grown_child(f) or _grown_child(m)):
			out.append([f, m])
	return out


func _may_found(o: NPC) -> bool:
	if o.household < 3 or o.id == w.reeve_id or o.id == w.sage_id or o.job == "guard":
		return false
	for cid in o.children:
		var k := w.npc(int(cid))
		if k != null and k.alive and k.role == "child" and k.household == o.household:
			return false
	return true


## A grown son or daughter still living with a parent.
func _grown_child(o: NPC) -> bool:
	for pid in [o.mother, o.father]:
		var p := w.npc(int(pid)) if int(pid) >= 0 else null
		if p != null and p.alive and p.household == o.household:
			return true
	return false


## A couple founds a household of their own (EQ-07): their own coins and what their families can spare
## (above what those who stay keep, _keep) pay for a home by _home_plan. Both leave their households;
## until the new house stands they sleep where they did. False when nothing can be paid for.
func _found_couple(f: NPC, m: NPC) -> bool:
	var pair := [f, m]
	var homes: Array = [f.household] if f.household == m.household else [f.household, m.household]
	var gifts := {}
	var spare := f.coins + m.coins
	for h in homes:
		var others: Array = w.brain._members(h).filter(func(o: NPC) -> bool: return not pair.has(o))
		var theirs := 0
		for o: NPC in others:
			theirs += o.coins
		gifts[h] = maxi(0, theirs - _keep(h, others.size()))
		spare += int(gifts[h])
	var nid := w.households.size()
	var plan := _home_plan(spare, w.building_door(str(w.households[homes[0]].home)), World.hh_ref(nid))
	if plan.is_empty():
		var need := start_cost("house", footprint("house"))
		_goal(f.household, "couple:%d:%d" % [f.id, m.id], "couple", need, need - spare, "saving to found a household of their own")
		return false
	# the families make up what the couple's own coins do not cover, richest members first
	var short := int(plan.cost) - f.coins - m.coins
	for h in homes:
		var give := mini(maxi(0, short), int(gifts[h]))
		short -= give
		var others: Array = w.brain._members(h).filter(func(o: NPC) -> bool: return not pair.has(o))
		others.sort_custom(func(a: NPC, b: NPC) -> bool: return a.coins > b.coins or (a.coins == b.coins and a.id < b.id))
		for o: NPC in others:
			var k := mini(give, o.coins)
			o.coins -= k
			o.spent += k
			f.coins += k
			give -= k
	var family := str(w.households[homes[0]].family)
	var nh := {"id": nid, "family": family, "home": "", "members": [], "pantry": Inventory.new(),
		"founded_from": int(homes[0]), "founded_day": w.day()}
	w.households.append(nh)
	for o: NPC in pair:
		var old := o.household
		(w.households[old].members as Array).erase(o.id)
		o.household = nid
		o.family = family
		(nh.members as Array).append(o.id)
		o.plan.clear()
		if not w.property._anyone_alive(old):
			w.property.household_ended(old)
	w.note("%s %s and %s %s leave to found a household of their own." % [f.name, f.family, m.name, m.family])
	_find_home(nid)
	for h in homes:
		w.brain.evaluate_household(int(h))
	w.brain.evaluate_household(nid)
	w.stat("households_founded")
	w.stat("couples_founded")
	return true


## A household that has lost its house (sold, or the lease taken back) lodges with the family it came
## from, or the first household of its family, until it has a home again.
func _rehouse(h: int) -> void:
	var hh: Dictionary = w.households[h]
	if hh.get("ended", false) or not w.buildings.has(str(hh.home)) or w.holds(World.hh_ref(h), w.buildings[hh.home]):
		return
	var from := int(hh.get("founded_from", -1))
	var host := str(w.households[from].home) if from >= 0 else ""
	w.note("The %s household no longer holds %s and lodges with family." % [hh.family, w.property.describe(w.buildings[hh.home])])
	hh.home = ""
	for o: NPC in w.brain._members(h):
		if host != "" and w.buildings.has(host):
			o.home = host


## A crowded household splits (owner rule): its founder takes a share of the family's coins for a home
## and founds a household of the same family. An empty house on the market is bought (or leased, two
## weeks' rent in hand); else ground near home is bought and a house built by the player's rules.
## Only when the family keeps enough to live on afterwards (_keep). Returns true when it split.
func _found(h: int) -> bool:
	var hh: Dictionary = w.households[h]
	var founder := founder_of(h)
	if founder == null:
		return false
	var leaving: Array = [founder]
	if _partner_here(founder):
		leaving.append(w.npc(founder.partner))
	var spare: int = w.property.purse(World.hh_ref(h)) - _keep(h, w.brain._members(h).size() - leaving.size())
	var plan := _home_plan(spare, w.building_door(str(hh.home)), World.hh_ref(h))
	if plan.is_empty():
		var need := start_cost("house", footprint("house"))
		_goal(h, "crowded", "split", need, need - spare, "saving so %s can found a household of their own" % founder.name)
		return false
	# the family (the founder among them) puts together what the new home costs and gives it to the
	# founder, who leaves with it (and with their partner) to found a household of their own
	_take(World.hh_ref(h), int(plan.cost))
	founder.coins += int(plan.cost)
	var nh := {"id": w.households.size(), "family": hh.family, "home": "", "members": [], "pantry": Inventory.new(),
		"founded_from": h, "founded_day": w.day()}
	w.households.append(nh)
	for o: NPC in leaving:
		(hh.members as Array).erase(o.id)
		(nh.members as Array).append(o.id)
		o.household = int(nh.id)
		o.plan.clear()
	w.note("The %s house is crowded: %s %s leaves to found a household of their own%s." % [hh.family, founder.name, founder.family,
			"" if leaving.size() == 1 else " with " + leaving[1].name])
	_find_home(int(nh.id))
	w.brain.evaluate_household(h)
	w.brain.evaluate_household(int(nh.id))
	w.stat("households_founded")
	return true


## How a household with `spare` coins gets a home (owner rule): an empty house on the market, bought,
## or leased with two weeks' rent in hand; else ground as near `near` as is legal, bought, and a house
## built there by the player's rules: started with the ground and found_start_share of the materials at
## today's prices, the rest bought as the household earns. {} when it cannot pay for any of them.
func _home_plan(spare: int, near: Vector2i, ref: String) -> Dictionary:
	for r in w.property.market():
		if w.property.is_home(r) or w.property.is_home(w.property.unit(r).back()):
			var price: int = w.property.price_of(r)
			var rent: int = w.property.rent_of(r)
			if spare >= price:
				return {"house": r, "lease": false, "cost": price}
			if spare >= rent * 2:
				return {"house": r, "lease": true, "cost": rent * 2}
	# a new house is started with the ground and a first share of the materials in hand, and built as
	# the household earns (_keep_building buys what its purse allows); EQ-07, found_start_share
	var cost: int = w.property.land_price(footprint("house").x, footprint("house").y) \
			+ ceili(estimate(cost_of("house")) * float(GameData.b("found_start_share")))
	if spare < cost:
		return {}
	# ground the manor has surveyed already (the clearings), nearest first, then new ground
	var fp := footprint("house")
	var plots: Array = w.property.market().filter(func(r): return w.property.is_parcel(r) and w.property.building_on(r).is_empty() and Vector2i(int(r.w), int(r.h)) == fp)
	plots.sort_custom(func(a, b): return (Vector2(int(a.x), int(a.y)) - Vector2(near)).length() < (Vector2(int(b.x), int(b.y)) - Vector2(near)).length())
	if not plots.is_empty():
		return {"plot": plots[0], "cost": cost - w.property.land_price(footprint("house").x, footprint("house").y) + w.property.price_of(plots[0])}
	var rect := find_ground("house", near, ref)
	if rect.size == Vector2i.ZERO:
		return {}
	return {"rect": rect, "cost": cost}


## A household without a home of its own (just founded, or lodging since it lost one) gets one with
## its own coins: moves into an empty house, or marks out a house on new ground and starts building.
func _find_home(h: int) -> void:
	var hh: Dictionary = w.households[h]
	var ref := World.hh_ref(h)
	var near := w.building_door(w.party(ref).home) if w.party(ref) != null and w.buildings.has(w.party(ref).home) else Vector2i(w.map.data.spawns.player[0], w.map.data.spawns.player[1])
	var plan := _home_plan(w.property.purse(ref), near, ref)
	if plan.is_empty():
		var need := start_cost("house", footprint("house"))
		_goal(h, "no home", "home", need, need - w.property.purse(ref), "saving for a home of its own")
		return
	if plan.has("house"):
		var r: Dictionary = plan.house
		if (w.property.lease(r, ref) if plan.lease else w.property.buy(r, ref)) == "":
			move_in(h, str(w.property.unit(r).back().id))
		return
	if plan.has("plot"):
		var pl: Dictionary = plan.plot
		if w.property.buy(pl, ref) == "":
			w.start_site(pl, "house", ref)
			hh.build = str(pl.id)
			_keep_building(h)
		return
	var p := place("house", plan.rect, ref)
	if not p.is_empty():
		hh.build = str(p.id)
		_keep_building(h)


## Legal ground for a building of this kind as near `near` as can be found (deterministic: offsets by
## distance, then row, then column); a zero rectangle if there is none within reach.
func find_ground(kind: String, near: Vector2i, ref: String) -> Rect2i:
	var size := footprint(kind)
	var W: int = w.map.w
	var sums := _free_sums()
	var cands := []
	for y in range(1, w.map.h - size.y):
		for x in range(1, W - size.x):
			var blocked := sums[(y + size.y) * (W + 1) + x + size.x] - sums[y * (W + 1) + x + size.x] - sums[(y + size.y) * (W + 1) + x] + sums[y * (W + 1) + x]
			if blocked == 0:
				var d := (Vector2i(x, y) + size / 2 - near).length_squared()
				cands.append([d, y, x])
	cands.sort()
	for cnd in cands:
		var rect := Rect2i(int(cnd[2]), int(cnd[1]), size.x, size.y)
		if can_place(kind, rect, ref) == "":
			return rect
	return Rect2i()


## A summed table of the cells that rule ground out (as Property.can_claim does: solid, road,
## buildings, parcels, fields, pens, stalls, stations, containers, seams, grown trees), so ground can be
## searched quickly; can_place still decides each candidate.
func _free_sums() -> PackedInt32Array:
	var W: int = w.map.w
	var H: int = w.map.h
	var blocked := PackedByteArray()
	blocked.resize(W * H)
	for y in H:
		for x in W:
			if w.map.is_solid(Vector2i(x, y)):
				blocked[y * W + x] = 1
	var mark := func(r: Rect2i) -> void:
		r = r.intersection(Rect2i(0, 0, W, H))
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				blocked[y * W + x] = 1
	for c in w.map.data.road:
		mark.call(Rect2i(int(c[0]), int(c[1]), 1, 1))
	for r in w.property.records() + w.fields + w.fauna.pens.values():
		mark.call(Rect2i(int(r.x), int(r.y), int(r.w), int(r.h)))
	for id in w.stalls:
		mark.call(Rect2i(int(w.stalls[id].x), int(w.stalls[id].y), 1, 1))
		mark.call(Rect2i(int(w.stalls[id].use[0]), int(w.stalls[id].use[1]), 1, 1))
	for id in w.stations:
		mark.call(Rect2i(int(w.stations[id].at[0]), int(w.stations[id].at[1]), 1, 1))
		mark.call(Rect2i(int(w.stations[id].use[0]), int(w.stations[id].use[1]), 1, 1))
	for e in w.containers + w.deposits:
		mark.call(Rect2i(int(e.x), int(e.y), 1, 1))
	for t in w.trees:
		if t.state == "grown":
			mark.call(Rect2i(int(t.x), int(t.y), 1, 1))
	var sums := PackedInt32Array()
	sums.resize((W + 1) * (H + 1))
	for y in H:
		var row := 0
		for x in W:
			row += blocked[y * W + x]
			sums[(y + 1) * (W + 1) + x + 1] = sums[y * (W + 1) + x + 1] + row
	return sums


## A founding household building its house: each morning a helper is hired for the day (out of work
## or labouring, by id), or the founder carries the materials themselves (no wage). Materials are
## bought with the household's coins, keeping a little for food.
func _keep_building(h: int) -> void:
	var hh: Dictionary = w.households[h]
	var p: Dictionary = w.plot(str(hh.get("build", "")))
	if p.is_empty() or p.site.is_empty() or p.site.get("done", false):
		hh.erase("build")
		return
	var ref := World.hh_ref(h)
	for c in contracts:
		if str(c.site) == str(p.id):
			return
	var wage := int(GameData.b("helper_wage"))
	var reserve := 10 + _tool_reserve(h)
	var budget: int = w.property.purse(ref) - reserve
	var helper: NPC = null
	if budget - wage >= estimate(p.site.need):
		for o: NPC in w.npcs:
			if o.household != h and can_hire(o) == "":
				helper = o
				break
	if helper != null:
		hire(ref, helper, p, budget - wage)
		return
	# a household carries its own only when it can buy something or has something put by; otherwise its
	# people work and save (EQ-07)
	var cheapest := 1 << 30
	for id in p.site.need:
		cheapest = mini(cheapest, estimate({id: 1}))
	var pantry: Inventory = hh.pantry
	var stocked := false
	for id in p.site.need:
		stocked = stocked or pantry.count(id) > 0
	if budget < cheapest and not stocked:
		return
	var founder: NPC = responsible_adult(h)
	if founder != null:
		hire(ref, founder, p, budget)


## What a household keeps back from its building for its workers' missing tools (EQ-07): the price of
## each tool a member's trade needs and they have not got, so a house never takes the means of earning.
func _tool_reserve(h: int) -> int:
	var keep := 0
	for o: NPC in w.brain._members(h):
		var tool: String = NPCBrain.JOB_TOOL.get(o.job, "")
		if o.role == "adult" and tool != "" and not o.inv.has(tool):
			var p: int = w.brain.tool_price(o, tool)
			keep += p if p > 0 else ceili(GameData.value(tool) * 1.5)
	return keep


## The house is built (World._finish_site): a household that was founding moves in.
func on_finished(b: Dictionary) -> void:
	var ref: String = w.owner_of(b)
	if not ref.begins_with("hh:") or not w.property.is_home(b):
		return
	var h := World.ref_id(ref)
	var hh: Dictionary = w.households[h]
	hh.erase("build")
	if str(hh.home) == "" or not w.buildings.has(str(hh.home)):
		move_in(h, str(b.id))


## A household moves into its new home: every member's home is it from now on.
func move_in(h: int, building: String) -> void:
	var hh: Dictionary = w.households[h]
	hh.home = building
	for o: NPC in w.brain._members(h):
		o.home = building
		o.plan.clear()
	w.note("The %s household moves into %s." % [hh.family, w.property.describe(w.buildings[building])])
	w.brain.evaluate_household(h)


# ---------------------------------------------------------------- saving ---------------------
func to_dict() -> Dictionary:
	var out := []
	for c in contracts:
		var d: Dictionary = c.duplicate()
		d.load = (c.load as Inventory).to_dict()
		out.append(d)
	return {"contracts": out}


func load_dict(d: Dictionary) -> void:
	contracts.clear()
	for c in d.get("contracts", []):
		var e: Dictionary = c.duplicate()
		e.worker = int(e.worker)
		e.day = int(e.day)
		e.wage = int(e.wage)
		e.budget = int(e.budget)
		e.spent = int(e.spent)
		e.load = Inventory.from_dict(c.get("load", {}))
		contracts.append(e)
