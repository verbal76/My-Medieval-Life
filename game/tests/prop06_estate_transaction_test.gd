extends SceneTree
## PROP-06 (owner decisions 2026-11-08, docs/directives/2026-11-08_prop06_estate_tenancy_migration.md): a household that leaves
## settles everything it holds as one transaction (Migration._settle_departure_property): separate parcels and whole estates sold
## to the manor at their valuation, each counted once; property it lets to another household sold with the lease intact (the
## manor the landlord); its own leases surrendered (sites and delivered materials to the manor); a full preflight, and on any
## failure everything restored; nothing sold when the manor cannot pay; nothing settled when only part of the household goes.
## The 18 cases the directive lists, numbered as there.
var checks := 0
var fails := 0


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		fails += 1


func _init() -> void:
	GameData.ensure()
	_owned_parcels()
	_estates()
	_let_to_tenant()
	_leases()
	_sites()
	_funds_and_rollback()
	_save_load()
	_departures()
	_business()
	_other_buildings()
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)


# ------------------------------------------------------------------------------------------------ fixtures
## A world whose household `h` (one with a storefront place at its home) holds nothing but what each case gives it, and a
## treasury that can pay.
func world(seed_ := 8906) -> World:
	EconomyFoundation.set_override(EconomyFoundation.off_config())
	var w := World.new()
	w.setup(VillageMap.load_default(), seed_)
	w.minutes = 1440.0 + 10.0 * 60.0
	w.treasury = maxi(w.treasury, 20000)
	return w


func seller(w: World) -> NPC:
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 0 and o.home != "" and w.buildings.has(o.home) \
				and w.owner_of(w.buildings[o.home]) == World.hh_ref(o.household) and w.business.front_place(w.buildings[o.home]).size() > 0 \
				and w.property.held_by(World.hh_ref(o.household)).has(w.buildings[o.home]) and w.brain._members(o.household).size() > 1:
			return o
	return null


## A household other than `skip`'s that lives in a house it owns (to be the tenant or the venture's household).
func other(w: World, skip: int) -> NPC:
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 0 and o.household != skip and o.home != "" and w.buildings.has(o.home):
			return o
	return null


## A new parcel of land (a copy of the map's first, with its own id), alone or a module of `estate`.
func parcel(w: World, id: String, estate := "") -> Dictionary:
	var p: Dictionary = (w.plots[0] as Dictionary).duplicate(true)
	p.id = id
	for k in ["owner", "tenant", "estate", "building", "rent", "due_day", "arrears", "missed"]:
		p.erase(k)
	p.site = {}
	if estate != "":
		p.estate = estate
	w.plots.append(p)
	return p


func members(w: World, h: int) -> Array:
	return w.brain._members(h)


func purse(w: World, h: int) -> int:
	return w.property.purse(World.hh_ref(h))


## Every log the village holds that a settlement can move: pantries, granary, sites, loot.
func logs(w: World) -> int:
	var n: int = w.granary.count("log") + int(w.site_goods().get("log", 0))
	for hh in w.households:
		n += (hh.pantry as Inventory).count("log")
	for l in w.loot:
		n += (l.inv as Inventory).count("log")
	return n


func site(ref: String, kind := "house") -> Dictionary:
	return {"owner": ref, "kind": kind, "done": false, "cost": {"log": 5}, "need": {"log": 2}}     # 3 logs delivered


## What a settlement could change, as text, for "nothing changed" and "everything restored".
func fingerprint(w: World, recs: Array, notes_added := 0) -> String:
	var r := []
	for x in recs:
		r.append([x.id, w.owner_of(x), w.tenant_of(x), x.get("rent", 0), x.get("due_day", -1), x.get("arrears", 0), x.get("site", {}),
			x.get("front", {}).get("till", 0) if x.has("front") else 0])
	var coins := []
	for n: NPC in w.npcs:
		coins.append([n.id, n.coins, n.earned, n.spent])
	var pantries := []
	for hh in w.households:
		pantries.append((hh.pantry as Inventory).items)
	return JSON.stringify([r, w.treasury, coins, pantries, w.granary.items, w.loot.size(), w.stats, w.log_lines.size() - notes_added, w.total_coins()])


# ------------------------------------------------------------------------------------------------ cases 1, 2
func _owned_parcels() -> void:
	var w := world()
	var s := seller(w)
	var h := s.household
	var ref := World.hh_ref(h)
	var house: Dictionary = w.buildings[s.home]
	var v := w.property.sale_value(house)
	var p0 := purse(w, h)
	var t0 := w.treasury
	var c0 := w.total_coins()
	check(Migration._settle_departure_property(w, members(w, h)), "#1 one owned property: the household that leaves sells it")
	check(w.owner_of(house) == World.MANOR, "#1 the house is the manor's, the building standing")
	check(purse(w, h) == p0 + v and w.treasury == t0 - v, "#1 its sale value (%d) went from the treasury to the household" % v)
	check(w.total_coins() == c0, "#1 no coin made or lost")
	# 2: several separate properties
	w = world()
	s = seller(w)
	h = s.household
	ref = World.hh_ref(h)
	house = w.buildings[s.home]
	var a := parcel(w, "pa")
	var b := parcel(w, "pb")
	for x in [a, b]:
		w.set_owner(x, ref)
	var total := w.property.sale_value(house) + w.property.sale_value(a) + w.property.sale_value(b)
	p0 = purse(w, h)
	t0 = w.treasury
	check(Migration._settle_departure_property(w, members(w, h)), "#2 several separate parcels: all sold together")
	check([house, a, b].all(func(x): return w.owner_of(x) == World.MANOR), "#2 every one is the manor's")
	check(purse(w, h) == p0 + total and w.treasury == t0 - total, "#2 the household got the sum of their values (%d), each once" % total)


# ------------------------------------------------------------------------------------------------ cases 3, 4
func _estates() -> void:
	var w := world()
	var s := seller(w)
	var h := s.household
	var ref := World.hh_ref(h)
	w.set_owner(w.buildings[s.home], World.MANOR)          # the estate is all it owns
	var anchor := parcel(w, "ea")
	var m1 := parcel(w, "em1", "ea")
	var m2 := parcel(w, "em2", "ea")
	for x in [anchor, m1, m2]:
		w.set_owner(x, ref)
	check(w.property.estate_parcels(anchor).size() == 3, "#3 fixture: one estate of an anchor and two modules")
	var total := 0
	for x in [anchor, m1, m2]:
		total += w.property.sale_value(x)
	var p0 := purse(w, h)
	var t0 := w.treasury
	check(Migration._settle_departure_property(w, members(w, h)), "#3 an estate with modules does not block departure")
	check([anchor, m1, m2].all(func(x): return w.owner_of(x) == World.MANOR), "#3 the anchor and every module are the manor's")
	check(purse(w, h) == p0 + total and w.treasury == t0 - total, "#3 the estate's value (%d) paid once, parcel by parcel" % total)
	check(m1.get("estate", "") == "ea" and m2.get("estate", "") == "ea", "#3 the estate stays whole (its modules still belong to it)")
	check(w.property.for_sale(anchor) and w.property.for_sale(m1), "#3 the manor can sell or let the estate again")
	# 4: two estates and a house
	w = world()
	s = seller(w)
	h = s.household
	ref = World.hh_ref(h)
	var house: Dictionary = w.buildings[s.home]
	var e := [parcel(w, "e1"), parcel(w, "e1m", "e1"), parcel(w, "e2"), parcel(w, "e2m", "e2"), parcel(w, "e2n", "e2")]
	for x in e:
		w.set_owner(x, ref)
	total = w.property.sale_value(house)
	for x in e:
		total += w.property.sale_value(x)
	p0 = purse(w, h)
	t0 = w.treasury
	var c0 := w.total_coins()
	check(Migration._settle_departure_property(w, members(w, h)), "#4 two estates and a house: all settled in one departure")
	check(e.all(func(x): return w.owner_of(x) == World.MANOR) and w.owner_of(house) == World.MANOR, "#4 everything is the manor's")
	check(purse(w, h) == p0 + total and w.treasury == t0 - total and w.total_coins() == c0, "#4 paid %d, nothing counted twice, no coin made" % total)


# ------------------------------------------------------------------------------------------------ cases 5, 6, 7
func _let_to_tenant() -> void:
	var w := world()
	var s := seller(w)
	var h := s.household
	var ref := World.hh_ref(h)
	var t := other(w, h)
	var tref := World.hh_ref(t.household)
	var let := parcel(w, "let")
	var cot := parcel(w, "cot")
	w.set_owner(let, ref)
	w.set_owner(cot, ref)
	w.set_tenant(let, tref, 7)
	let.arrears = 2
	let.missed = 1
	w.set_tenant(cot, tref, 3)
	let.site = site(tref)                                  # the tenant's own unfinished building on the let ground
	var terms := [let.rent, let.due_day, let.arrears, let.missed, let.site.duplicate(true)]
	var tp0 := purse(w, t.household)
	var tpan := (w.households[t.household].pantry as Inventory).items.duplicate(true)
	var total := w.property.sale_value(w.buildings[s.home]) + w.property.sale_value(let) + w.property.sale_value(cot)
	var p0 := purse(w, h)
	check(Migration._settle_departure_property(w, members(w, h)), "#5 owned property let to another household: the owner can leave")
	check(w.owner_of(let) == World.MANOR and w.owner_of(cot) == World.MANOR, "#5 the manor bought the let parcels")
	check(purse(w, h) == p0 + total, "#5 the owner got the sale proceeds (%d)" % total)
	check(w.tenant_of(let) == tref and w.tenant_of(cot) == tref, "#6 the tenant was not evicted: the leases continue")
	check([let.rent, let.due_day, let.arrears, let.missed, let.site] == terms, "#6 rent, due day, arrears and the tenant's own site unchanged")
	check(purse(w, t.household) == tp0 and (w.households[t.household].pantry as Inventory).items == tpan, "#6 the tenant's coins and goods untouched")
	# 7: the next rent day pays the manor, the new landlord, and nobody else
	var sp0 := purse(w, h)
	var t0 := w.treasury
	tp0 = purse(w, t.household)
	let.due_day = w.day()
	cot.due_day = w.day() + 3
	w.property.collect_rents()
	var owed := 7 + 2
	check(w.treasury == t0 + owed and purse(w, t.household) == tp0 - owed, "#7 the rent due (%d with arrears) reached the manor" % owed)
	check(purse(w, h) == sp0, "#7 the former owner receives no rent")
	check(int(let.arrears) == 0 and int(let.due_day) == w.day() + Property.WEEK, "#7 the lease runs on: paid up, next due in a week")


# ------------------------------------------------------------------------------------------------ case 8
func _leases() -> void:
	var w := world()
	var s := seller(w)
	var h := s.household
	var ref := World.hh_ref(h)
	var l1 := parcel(w, "l1")
	var l2 := parcel(w, "l2")
	var l3 := parcel(w, "l3m", "l1")                         # a leased module of the leased l1
	for x in [l1, l2, l3]:
		w.set_tenant(x, ref, 4)
	l2.arrears = 5
	var p0 := purse(w, h)
	var t0 := w.treasury
	var v := w.property.sale_value(w.buildings[s.home])
	check(Migration._settle_departure_property(w, members(w, h)), "#8 several leases (one of them an estate) surrendered on leaving")
	check([l1, l2, l3].all(func(x): return w.tenant_of(x) == "" and w.owner_of(x) == World.MANOR), "#8 each lease ended, the manor keeps the land")
	check(purse(w, h) == p0 + v - 5 and w.treasury == t0 - v + 5, "#8 no compensation for leases; the 5 coins of rent owed were paid")


# ------------------------------------------------------------------------------------------------ cases 9, 10
func _sites() -> void:
	var w := world()
	var s := seller(w)
	var h := s.household
	var ref := World.hh_ref(h)
	var own := parcel(w, "os")
	var lease := parcel(w, "ls")
	w.set_owner(own, ref)
	own.site = site(ref)
	w.set_tenant(lease, ref, 2)
	lease.site = site(ref)
	var pan := w.households[h].pantry as Inventory
	var pl0 := pan.count("log")
	var g0 := w.granary.count("log")
	var all0 := logs(w)
	var c0 := w.total_coins()
	check(Migration._settle_departure_property(w, members(w, h)), "#9/#10 owned and leased unfinished sites do not block departure")
	check(w.owner_of(own) == World.MANOR and (own.site as Dictionary).is_empty(), "#9 the owned parcel sold, its unfinished site given up")
	var loose := 0
	for l in w.loot:
		loose += (l.inv as Inventory).count("log")
	check(pan.count("log") + loose == pl0 + 3, "#9 the 3 logs delivered to the household's own site are the household's")
	check(w.tenant_of(lease) == "" and (lease.site as Dictionary).is_empty(), "#10 the leased parcel surrendered, its site cleared for the manor")
	check(w.granary.count("log") == g0 + 3, "#10 the 3 logs delivered to the leased site went to the manor, uncompensated")
	check(logs(w) == all0 and w.total_coins() == c0, "#14 conservation: every log and coin is still in the village")


# ------------------------------------------------------------------------------------------------ cases 11, 12, 13
func _funds_and_rollback() -> void:
	var w := world()
	var s := seller(w)
	var h := s.household
	var ref := World.hh_ref(h)
	var t := other(w, h)
	var a := parcel(w, "fa")
	var b := parcel(w, "fb", "fa")
	var c := parcel(w, "fc")
	w.set_owner(a, ref)
	w.set_owner(b, ref)
	w.set_owner(c, ref)
	w.set_tenant(c, World.hh_ref(t.household), 6)
	var lease := parcel(w, "fl")
	w.set_tenant(lease, ref, 2)
	lease.site = site(ref)
	b.site = site(ref)
	var recs := [w.buildings[s.home], a, b, c, lease]
	var total := 0
	for x in [w.buildings[s.home], a, b, c]:
		total += w.property.sale_value(x)
	w.treasury = total - 1
	var before := fingerprint(w, recs)
	check(not Migration._settle_departure_property(w, members(w, h)), "#11 the manor one coin short of %d: the household does not leave" % total)
	check(fingerprint(w, recs) == before, "#11 nothing changed: titles, tenancy, sites, treasury, purses, records")
	w.treasury = total + 50
	check(Migration._departure_plan(w, members(w, h)).steps.size() == 5, "#11 multiple parcels and a tenant do not themselves fail a valid sale")
	before = fingerprint(w, recs)
	var logs0 := logs(w)
	var log0 := w.log_lines.size()
	Migration.test_fail_at = 4                              # the 4th of 5 steps fails, after three have been done
	check(not Migration._settle_departure_property(w, members(w, h)), "#12 a step failing partway: the departure is refused")
	check(fingerprint(w, recs, 1) == before, "#13 complete rollback: titles, tenancy, sites, tills, treasury, purses, pantries, granary, records")
	check(w.log_lines.size() == log0 + 1 and "stays for now" in str(w.log_lines[-1]), "#13 the undone steps left no notes, only that the household stays")
	check(logs(w) == logs0 and Migration.test_fail_at == -1, "#13 every delivered log back on its site; the failure hook spent")
	check(Migration._settle_departure_property(w, members(w, h)), "#13 a later attempt, with nothing failing, succeeds")
	check(w.owner_of(c) == World.MANOR and w.tenant_of(c) == World.hh_ref(t.household), "#13 and settles everything, the tenant kept")


# ------------------------------------------------------------------------------------------------ case 15
func _save_load() -> void:
	var w := world()
	var s := seller(w)
	var h := s.household
	var ref := World.hh_ref(h)
	var t := other(w, h)
	var tref := World.hh_ref(t.household)
	var house: Dictionary = w.buildings[s.home]
	var e := parcel(w, "sa")
	w.set_owner(e, ref)
	w.set_tenant(e, tref, 5)
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	check(w2.owner_of(w2.plot("sa")) == ref and w2.tenant_of(w2.plot("sa")) == tref, "#15 saved before: the title and the lease load back")
	var ok1 := Migration._settle_departure_property(w, members(w, h))
	var ok2 := Migration._settle_departure_property(w2, members(w2, h))
	check(ok1 and ok2 and w.treasury == w2.treasury and purse(w, h) == purse(w2, h), "#15 the loaded world settles exactly as the original")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	var e3 := w3.plot("sa")
	check(w3.owner_of(e3) == World.MANOR and w3.tenant_of(e3) == tref and int(e3.rent) == 5 and int(e3.due_day) == int(e.due_day),
		"#15 saved after: the manor's title and the continuing lease load back")
	check(w3.owner_of(w3.buildings[str(house.id)]) == World.MANOR and w3.total_coins() == w.total_coins(), "#15 and the sold house, coins equal")


# ------------------------------------------------------------------------------------------------ cases 16, 17
func _departures() -> void:
	var w := world()
	var s := seller(w)
	var h := s.household
	var ref := World.hh_ref(h)
	var house: Dictionary = w.buildings[s.home]
	var e := parcel(w, "da")
	w.set_owner(e, ref)
	var site_: OffMapSettlement = w.regions.by_id["wulstead"]
	var bt := Migration.hiring(site_) if Migration.hiring(site_) != "" else "farm"
	var ms := members(w, h)
	check(ms.size() > 1, "#16 fixture: a household of more than one")
	var one: NPC = ms.filter(func(n: NPC): return n.role == "adult" and n != s)[0] if ms.any(func(n: NPC): return n.role == "adult" and n != s) else ms[-1]
	var t0 := w.treasury
	Migration._household_out(w, site_, [one], false, "hunger", bt)
	check(w.owner_of(house) == ref and w.owner_of(e) == ref and w.treasury == t0, "#16 part of the household goes: its property stays with those who stay")
	var rest := members(w, h)
	var value := w.property.sale_value(house) + w.property.sale_value(e)
	var bought0 := float(w.stats.get("gov_land_bought", 0.0))
	t0 = w.treasury
	check(Migration._household_out(w, site_, rest, true, "hunger", bt), "#17 the whole household (with an estate parcel) goes")
	check(w.owner_of(house) == World.MANOR and w.owner_of(e) == World.MANOR, "#17 everything it owned is the manor's")
	check(float(w.stats.get("gov_land_bought", 0.0)) - bought0 == float(value), "#17 bought for %d coins, its valuation" % value)


# ------------------------------------------------------------------------------------------------ case 18
func _business() -> void:
	var w := world()
	var s := seller(w)
	var h := s.household
	var ref := World.hh_ref(h)
	var house: Dictionary = w.buildings[s.home]
	for id in w.business.storefront_cost():
		s.inv.add(id, int(w.business.storefront_cost()[id]))
	check(w.business.build_npc_front(house, s), "#18 fixture: the household's storefront")
	house.front.till = 41
	var t := other(w, h)
	house["venture"] = {"household": t.household, "till": 25}       # another household's business run in the house (B25-BIZ-D1)
	var p0 := purse(w, h)
	var tp0 := purse(w, t.household)
	var t0 := w.treasury
	var c0 := w.total_coins()
	var v := w.property.sale_value(house)
	check(Migration._settle_departure_property(w, members(w, h)), "#18 a household with a storefront and another's business in its house leaves")
	check(int(house.front.till) == 0 and purse(w, h) == p0 + v + 41, "#18 the storefront till (41) went to the household with the proceeds (TILL-D1)")
	check(int(house.venture.household) == t.household and purse(w, t.household) + int(house.venture.till) == tp0 + 25,
		"#18 the other household's business money stays its own (its till or its purse), never the seller's")
	check(w.treasury == t0 - v, "#18 the manor paid the valuation and took no till")
	check(w.total_coins() == c0, "#18 no coin made or lost")


# ------------------------------------------------------------------------------------------------ #1 (every property it owns)
## A building the household owns that is not one of the land office's listed homes (the Lorekeeper's hut) is property too.
func _other_buildings() -> void:
	var w := world()
	var who: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.household >= 0 and o.home != "" and w.buildings.has(o.home) and w.owner_of(w.buildings[o.home]) == World.hh_ref(o.household) \
				and not w.property.held_by(World.hh_ref(o.household)).has(w.buildings[o.home]):
			who = o
			break
	check(who != null, "#1 fixture: a household owning a building the land office does not list (a hut)")
	if who == null:
		return
	var hut: Dictionary = w.buildings[who.home]
	var v := w.property.sale_value(hut)
	var p0 := purse(w, who.household)
	var t0 := w.treasury
	check(Migration._settle_departure_property(w, members(w, who.household)), "#1 its household leaves")
	check(w.owner_of(hut) == World.MANOR and purse(w, who.household) == p0 + v and w.treasury == t0 - v,
		"#1 the hut was sold to the manor too, for its value (%d), not left owned by nobody" % v)
