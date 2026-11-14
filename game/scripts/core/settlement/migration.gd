class_name Migration
extends RefCounted
## Expansion 18 (MIGRATE-18; owner Q18-7, 2026-10-23: "Both ways, for reasons"): people move between the village and the five
## off-map settlements for work, land, marriage or hunger, carrying their age, name, skills, purse and goods.
##
## How and when: with the caravan. On a visit day (World, noon, NPCBrain.caravan) the settlements whose traders are on the road
## (Regions.visiting: the nearer ones come more often) take and send travellers, so a move is immediate on the day and the
## farther a settlement the rarer its traffic (provisional; the road itself is not walked). Each reason is tested for each
## settlement on the road, in this order, and in both directions; at most one move (a person, a couple or a household) for each
## reason, direction and settlement per visit, a pace like the settlements' one new household a day, not a population cap.
## Every move needs a real signal from the rules the game already has, on both ends:
##
##   hunger    out: a village household whose food is under `relief_trigger_days` while the village is in famine (the manor's
##             relief cannot cover it) goes to a settlement whose food businesses hold food above its own claim
##             (OffMapSettlement.food_claim_pts, REG-BUY-P1). in: a settlement household that is hungry and cannot buy a day's
##             food (PAR-02A, `hungry` and `_day_food_cost`) goes to the village when the village is out of famine and holds food
##             above `reserve_days` of its need, and a home or a room can be had.
##   work      out: an adult with no job and no earnings for `emigrate_work_idle_days` (B42-Q-EMIG-WORK, owner 2026-11-14: judged per
##             person, whatever the household's food; long_idle), while the village's labour market (NPCBrain.job_market) has no open place, goes to a settlement business that paid its workers
##             at least `switch_to_at_least` a day last week (the settlement's own job-change measure). in: an adult of a settlement
##             household that earned under `switch_below` a day for a week (`low`; the settlement's own measure of short work) and
##             has others to stay with takes a village post nobody could fill: a succession vacancy past `succession_days` with no
##             apprentice (the newcomer's place, which a real migrant now gets first), else an open place in the labour market
##             that pays more than their household earned.
##   land      out: a village household whose housing goal ("no home", "crowded", Construction.housing_goals) has waited on
##             coins for `mobility_unsustainable_days` goes (the whole household, or the grown member who would have founded a
##             household, with their partner) to a settlement whose land yields food above its claim; the off-map has no houses, so a
##             new household needs none there. in: a settlement household formed by a marriage there (landless) that could pay
##             for a house on the manor's market by the village's own rule (Construction._home_plan: buy, or two weeks' rent).
##   marriage  a grown, unpartnered, willing person of each side who meets the village's partnering rules (partner_min_age,
##             partner_max_age, partner_max_gap, marry_min_days for a settlement member) and are not kin; the bride goes to the
##             groom's place: into his household's home when it has a bed, or he founds a settlement household with her.
##
## Conservation: a purse and a pack cross the boundary exactly like the couriers' goods (CourierService): the village's
## coin_sources, `caravan_coins_in/out`, `exported_`/`imported_` counts, the settlement's `outside_*` flow lines and a count of
## people (stats `migrants_in/out` and the settlement's flows `migrants_in/out`). Nobody is made or lost: the villager who leaves
## stays in World.npcs as no longer alive with `away` set (their experience goes with them, as at a death), and a person who
## arrives is a new villager with the carried name, age, sex and skills.
##
## REG-05 (owner 2026-11-08, docs/directives/2026-11-08_recovered_owner_messages.md "REG-05 - Households physically migrate"; B42):
## a villager or household that leaves for a settlement WALKS there (Journeys, purpose {kind: "migrate"}: the same road, pace,
## nights, food and dangers as every traveller, one walk each, the party set out together). The departure transactions happen
## when they set out (_set_out): PROP-06's property settlement, the quests, contracts, rentals and repairs (_pre_leave), the
## stalls, tills, debts (REG-02) and the household's pantry (_take_own), which goes into the head's pack and is carried. On the
## road they are still the village's people, alive, ageing, able to die (what they carry passes as at any death). The population
## transfer happens on arrival (at_site): when every living member of the party has reached the site (or two days after the first),
## they join the settlement (receive_household, receive_person, wed_in) with what they carry, and leave the village's books
## (_gone), as a runaway already did (B25R1-014). A walk that turns back brings them home (their property already settled: the
## owner's question R5-Q4). Not walked yet: arrivals in the village from a settlement (the "in" moves, owner question R5-IN), and
## any move in a world with no roads (the abstract tests).
##
## Deterministic: no random numbers (names of settlement-born members come from OffMapSettlement._roll). Saved: the log and counts
## in Regions ("moves", "move_counts"), the people in the settlements (members' fifth entry) and in World.npcs (NPC.away).

const REASONS := ["hunger", "work", "land", "marriage"]
const LOG_MAX := 200                 # moves kept in the log (Regions.moves); the counts are kept for good
## A settlement trade's village job (for the skills a member of that trade would have, and the trade a post suits), and the
## business a village job joins in a settlement. "" is a trade the village has no job for.
const TRADE_JOB := {"farmer": "farmer", "herder": "farmer", "forester": "woodcutter", "miner": "miner", "sawyer": "carpenter",
	"mason": "miner", "smith": "smith", "tanner": "tanner", "cook": "cook", "weaver": "", "healer": "", "merchant": "merchant", "official": ""}
const JOB_BIZ := {"farmer": "farm", "woodcutter": "forest", "miner": "quarry", "hunter": "herd", "smith": "smith", "carpenter": "sawyer",
	"tanner": "tanner", "cook": "cook", "tavernkeeper": "cook", "laborer": "farm", "manor_hand": "farm",
	"merchant": "merchant"}                       # REG-X20-D1: a village trader may now leave; where they join is receive_household's rule
const OFFICES := ["guard", "reeve", "sage", "preacher", "church_assistant", "tailor", "barber"]
const WORK_PLACES := ["manor_hand", "farmer", "hunter"]          # market places that need no tool (a migrant arrives with none)
const WHY := {"hunger": "for want of food", "work": "for work", "land": "for land", "marriage": "to marry"}


static var enabled := true           # a test switch (never cleared in the game): with it off nobody moves
static var walk := true              # a test switch (never cleared in the game): off, a move is made at once as before REG-05 (the
                                     # decision-rule suites written for the instant move set it; reg05_household_walks_test tests the walk)

## One visit day: the settlements on the road take and send travellers. Returns how many moves were made.
static func visit(w: World) -> int:
	if not enabled or w.regions == null:
		return 0
	var d := w.day()
	var made := 0
	for s: OffMapSettlement in w.regions.visiting(d):             # (by noon each has taken the morning's step: Regions.step_hour)
		for reason in REASONS:
			if _try(w, s, reason, "out"):
				made += 1
			if _try(w, s, reason, "in"):
				made += 1
	return made


static func _try(w: World, s: OffMapSettlement, reason: String, dir: String) -> bool:
	match reason:
		"hunger":
			return _hunger_out(w, s) if dir == "out" else _hunger_in(w, s)
		"work":
			return _work_out(w, s) if dir == "out" else _work_in(w, s)
		"land":
			return _land_out(w, s) if dir == "out" else _land_in(w, s)
	return _marry_out(w, s) if dir == "out" else _marry_in(w, s)


# ------------------------------------------------------------------ the village's side ----------------
## Somebody who cannot leave: an office-holder, someone tied to the player, a child of the founding households' care, or a
## bandit. A market trader may leave like anyone (REG-X20-D1, owner 2026-10-27: no special restriction for traders): the stock
## in their own pack goes with them and their stall is let again exactly as after a death (_gone, NPCBrain.on_death).
static func _barred(w: World, n: NPC) -> bool:
	if n.role == "bandit" or n.clan != "" or n.household < 3:
		return true
	if Journeys.active(n):
		return true                        # REG-05: on the road already (a walk of their own, or a move under way)
	if w.homesteads != null and w.homesteads.away(n):
		return true                        # B25R1-010: a homesteader leaves their land by its own rules (Homesteads)
	if n.id == w.reeve_id or n.id == w.sage_id or OFFICES.has(n.job):
		return true
	return Life.is_player_id(n.partner) or Life.is_player_id(n.mother) or Life.is_player_id(n.father)


static func _any_barred(w: World, ms: Array) -> bool:
	for o: NPC in ms:
		if _barred(w, o):
			return true
	return false


static func _food_need_pts(ms: Array) -> float:
	var pts := 0.0
	for o: NPC in ms:
		pts += NPCBrain.food_factor(o) * 24.0 * float(GameData.b("hunger_per_hour")) * float(GameData.b("reserve_days"))
	return pts


## The record of a villager that travels (their age in years, sex, the will to marry, name, skills).
static func _person_of(w: World, n: NPC) -> Dictionary:
	return {"age": Life.npc_age(w, n), "sex": 1 if n.sex == "female" else 0, "unw": 0 if w.relations.willing(n) else 1, "pair": 0,
		"n": n.name, "f": n.family, "sk": n.skills.duplicate(), "id": n.id}


## Pack up villagers who are leaving for `s`: their records, purses and everything they carry (and, with `pantry` set, the
## household's pantry). Nothing is removed yet.
static func _pack(w: World, ms: Array, pantry: Inventory = null) -> Dictionary:
	var packs := []
	var coins := 0
	var goods := {}
	for o: NPC in ms:
		var p := _person_of(w, o)
		if o.partner >= 0 and Life.has_partner(w, o) and ms.has(w.npc(o.partner)):
			p.pair = 1
		packs.append(p)
		coins += o.coins
		for id in o.inv.ids():
			goods[id] = int(goods.get(id, 0)) + o.inv.count(id)
	if pantry != null:
		for id in pantry.ids():
			goods[id] = int(goods.get(id, 0)) + pantry.count(id)
	return {"people": packs, "coins": coins, "goods": goods}


## Before packing: what the leaving villagers had set aside for the player's quests and contracts, and the escrows of their LE-05
## rentals and paid repairs (B25-LEAK2), is released to them as for a death (a refund lands in their purse, which then goes with them).
static func _pre_leave(w: World, ms: Array) -> void:
	for o: NPC in ms:
		w.quests.on_giver_died(o)
		w.contracts.on_death(o)
		if w.economy != null:
			w.economy.rentals.on_leave(o)       # B25-LEAK2: a tool on rent goes back, the deposit's rest to their purse
			w.economy.repairs.on_leave(o)       # B25-LEAK2: a paid repair not yet done is refunded to them (or to its customers)


## PROP-06 (owner decisions 2026-11-08, docs/directives/2026-11-08_prop06_estate_tenancy_migration.md): when a whole household
## leaves at its departure point it settles every property it holds, as ONE transaction:
## - what it owns outright is sold to the manor at sale_value (the property's own valuation, each parcel once), every parcel of an
##   estate together (its modules before its anchor, so Property.sell's rule that an anchor goes last is kept), the buildings
##   standing; the treasury pays the household's head; a lease of the property to another household continues with the manor as
##   landlord (rent already goes to the manor: Property.collect_rents); materials delivered to an unfinished site on its own ground
##   are the seller's (into the household's pantry);
## - what it leases is surrendered (Property._release: an unfinished site and its delivered materials stay with the manor, no
##   compensation; rent owed is paid as far as the purse allows, as Property.end_lease does).
## A preflight checks everything first (ownership, tenancy, estates, the manor's funds); if any check fails nothing is changed and
## the household stays, free to try again. If a step fails anyway, every change is undone (records, treasury, purses, pantry,
## granary, loot, stats). A household only part of which leaves settles nothing here (its property stays with those who stay).
## Called where the household actually leaves (today the instant departure; REG-05's physical departure must call it at the start of
## the walk, not when migration is merely considered).
static var test_fail_at := -1          # tests only: make the n-th step of the next settlement fail (-1: never)


static func _settle_departure_property(w: World, ms: Array) -> bool:
	var plan := _departure_plan(w, ms)
	if not bool(plan.ok):
		return false
	if plan.steps.is_empty():
		return true
	var snap := _snapshot(w, plan)
	var n := 0
	for st in plan.steps:
		n += 1
		var ok := n != test_fail_at and _do_step(w, st)
		if not ok:
			test_fail_at = -1
			_restore(w, snap)
			w.note("The %s household could not settle its property, so it stays for now." % str(w.households[int(st.h)].get("name", "")))
			return false
	test_fail_at = -1
	return true


## What the departure would do, checked in full before anything changes: {ok, steps: [{kind: "sell"|"surrender", unit, ref, h,
## value}], total}. Modules come before their anchor; a sale's value is counted once per parcel.
static func _departure_plan(w: World, ms: Array) -> Dictionary:
	var steps := []
	var total := 0
	var seen := {}
	for h in _households_of(ms):
		var living: Array = w.brain._members(h)
		if living.is_empty() or not living.all(func(n): return ms.has(n)):
			continue                                      # only part of the household leaves: nothing is settled
		var ref := World.hh_ref(h)
		var estates := {}                                 # anchor id -> [units of this estate held by ref]
		for rec in w.property.records():                  # every record it owns or leases, not only the land office's heads
			if not w.holds(ref, rec):                     # (an owned hut or other building that is no home is property too)
				continue
			var u: Array = w.property.unit(rec)
			if not w.holds(ref, u[0]):
				u = [rec]                                 # a building of its own on someone else's ground: the building alone
			if u.is_empty() or seen.has(str(u[0].id)):
				continue
			seen[str(u[0].id)] = true
			var anchor: Dictionary = w.property.anchor_of(u[0])
			var aid := str(anchor.get("id", u[0].id))
			if not estates.has(aid):
				estates[aid] = []
			estates[aid].append(u)
		for aid in estates:
			var units: Array = estates[aid]
			units.sort_custom(func(a, b): return int(str(a[0].id) == aid) < int(str(b[0].id) == aid))      # the anchor last
			for u in units:
				var head: Dictionary = u[0]
				if w.owner_of(head) == ref:
					var value: int = w.property.sale_value(head)
					total += value
					steps.append({"kind": "sell", "unit": u, "ref": ref, "h": h, "value": value})
				elif w.tenant_of(head) == ref:
					steps.append({"kind": "surrender", "unit": u, "ref": ref, "h": h, "value": 0})
	if w.treasury < total:
		return {"ok": false, "steps": [], "total": total, "why": "the manor cannot pay %d coins" % total}
	for st in steps:
		if st.kind == "sell" and w.party(str(st.ref)) == null:
			return {"ok": false, "steps": [], "total": total, "why": "nobody of the household to be paid"}
	return {"ok": true, "steps": steps, "total": total}


static func _do_step(w: World, st: Dictionary) -> bool:
	var u: Array = st.unit
	var ref := str(st.ref)
	if str(st.kind) == "sell":
		if w.owner_of(u[0]) != ref:
			return false
		for r in u:
			if w.property.is_parcel(r) and w.tenant_of(r) in ["", ref] and not (r.site as Dictionary).is_empty() \
					and not bool(r.site.get("done", false)):
				w.cancel_site(r, w.households[int(st.h)].pantry)          # delivered materials are the seller's (a tenant's site stays the tenant's)
		var value := int(st.value)
		if value > 0:
			var to: NPC = w.party(ref)
			if to == null or w.treasury < value:
				return false
			w.treasury -= value
			to.coins += value
			to.earned += value
		for r in u:
			if w.owner_of(r) == ref:
				w.set_owner(r, World.MANOR)              # a tenant of another household keeps the lease, the manor its landlord
		w.stat("gov_land_bought", float(value))
		w.note("%s sold %s to the manor for %d coins before leaving." % [w.ref_name(ref, true), w.property.describe(u[0]), value])
		return true
	if w.tenant_of(u[0]) != ref:
		return false
	var owed := mini(int(u[0].get("arrears", 0)), w.property.purse(ref))
	if owed > 0 and not w.property._pay_manor(ref, owed):
		return false
	w.property._release(u, ref)                           # the manor keeps the ground, the buildings and a site's materials
	w.note("%s gave up the lease of %s before leaving." % [w.ref_name(ref, true), w.property.describe(u[0])])
	return true


## Everything a settlement can change, for _restore.
static func _snapshot(w: World, plan: Dictionary) -> Dictionary:
	var recs := []
	for st in plan.steps:
		for r in st.unit:
			recs.append([r, (r as Dictionary).duplicate(true)])
	var people := []
	for n: NPC in w.npcs:
		people.append([n, n.coins, n.earned, n.spent])
	var players := []
	for pl: PlayerState in w.player_list():
		players.append([pl, pl.coins])
	var pantries := {}
	for st in plan.steps:
		pantries[int(st.h)] = (w.households[int(st.h)].pantry as Inventory).items.duplicate(true)
	return {"recs": recs, "treasury": w.treasury, "people": people, "pantries": pantries,
		"granary": w.granary.items.duplicate(true), "loot": w.loot.size(), "stats": w.stats.duplicate(true), "players": players,
		"log": w.log_lines.duplicate()}


static func _restore(w: World, snap: Dictionary) -> void:
	for e in snap.recs:
		var r: Dictionary = e[0]
		var old: Dictionary = e[1]
		if w.owner_of(r) != str(old.get("owner", World.MANOR)):
			w.set_owner(r, str(old.get("owner", World.MANOR)))
		if w.tenant_of(r) != str(old.get("tenant", "")):
			w.set_tenant(r, str(old.get("tenant", "")), int(old.get("rent", 0)))
		var had_site := r.has("site") and not (r.site as Dictionary).is_empty()
		r.clear()
		r.merge(old.duplicate(true), true)
		var has_site := r.has("site") and not (r.site as Dictionary).is_empty()
		if w.property.is_parcel(r) and had_site != has_site:
			w.tile_changed.emit(w._frame_cell(r), "below", -1)      # a cancelled site stands again on the map
	w.treasury = int(snap.treasury)
	for e in snap.people:
		e[0].coins = int(e[1])
		e[0].earned = int(e[2])
		e[0].spent = int(e[3])
	for h in snap.pantries:
		w.households[h].pantry.items = (snap.pantries[h] as Dictionary).duplicate(true)
	w.granary.items = (snap.granary as Dictionary).duplicate(true)
	if w.loot.size() > int(snap.loot):
		w.loot.resize(int(snap.loot))
	w.stats = (snap.stats as Dictionary).duplicate(true)
	for e in snap.players:
		e[0].coins = int(e[1])
	w.log_lines = (snap.log as Array).duplicate()                 # the notes of steps that were undone go too


## Just before they pack (Build 24 review; owner 2026-10-30: a living household or person that leaves keeps what is theirs): every
## stall whose open session or seller is one of the leavers, or a household they are the last of, is closed and settled to them
## (Stalls.close: the manor's commission, the rest to their purse); and a household they are everyone left of keeps its storefront
## tills (TILL-D1: to their purse) and its pantry, which goes with them. Returns that pantry (null when someone stays behind), so
## nothing of theirs is left to escheat to the manor once they have gone. Moves coins and goods only between village holders.
static func _take_own(w: World, ms: Array) -> Inventory:
	if w.credit != null:
		w.credit.on_departure(ms)                 # REG-02 debt part (B25-REG02-DEBT-D1): debts settled as they pack
	var emptied: Array = []
	for h in _households_of(ms):
		var left := 0
		for o: NPC in w.brain._members(h):
			if not ms.has(o):
				left += 1
		if left == 0:
			emptied.append(h)
	if w.business != null:
		var refs := {}
		for o: NPC in ms:
			refs[World.npc_ref(o.id)] = true
		for h in emptied:
			refs[World.hh_ref(h)] = true
		var ids: Array = w.stalls.keys()
		ids.sort()
		for id in ids:
			var st: Dictionary = w.stalls[id]
			var seller := str(st.get("session", {}).get("seller", w.business.stalls.seller_ref(st)))
			if refs.has(seller) and (int(st.get("till", 0)) > 0 or w.business.stalls.unsettled(st) > 0):
				w.business.stalls.close(st, "moved away")
		for h in emptied:
			w.business.money.keep_tills_of(World.hh_ref(h))
	if emptied.is_empty():
		return null
	return w.households[emptied[0]].pantry


## They have gone: the villagers leave the living (alive false, `away` the settlement), the village's accounts of coins and goods
## that crossed, and the posts and stalls they held are handed on exactly as after a death (NPCBrain.on_death).
static func _gone(w: World, s: OffMapSettlement, ms: Array, load_: Dictionary, pantry: Inventory, reason: String) -> void:
	for o: NPC in ms:
		o.coins = 0
		o.inv = Inventory.new()
		o.alive = false
		o.away = s.id
		if w.civic != null:
			w.civic.on_departure(o, s.id)          # P21-01: the legacy record and the end of any tenure (observes only)
		if not o.journey.is_empty():
			Journeys.end(w, o, "emigrated")        # REG-02: a trip under way ends when its traveller leaves the village
		o.plan.clear()
		o.target = -1
		Identity.move(w, o.id, s.id)                  # ID-01: the same person, now in the settlement
	if pantry != null:
		pantry.items.clear()
	if int(load_.coins) > 0:
		w.coin_sources -= int(load_.coins)
		w.stat("caravan_coins_out", float(load_.coins))
		w.stat("migrant_coins_out", float(load_.coins))               # (the same coins, named for the report: caravan_coins_* also holds trade)
	for id in load_.goods:
		w.stat("exported_" + str(id), float(load_.goods[id]))
	for o: NPC in ms:
		w.brain.on_death(o)
	for h in _households_of(ms):
		if not w.property._anyone_alive(h):
			w.property.household_ended(h)
	_book(w, s, "out", reason, ms.size(), int(load_.coins), load_.goods)


static func _households_of(ms: Array) -> Array:
	var out := []
	for o: NPC in ms:
		if o.household >= 0 and not out.has(o.household):
			out.append(o.household)
	return out


## The travellers' accounts, once: the counts, the log and the lines in the village log and the settlement's journal.
static func _book(w: World, s: OffMapSettlement, dir: String, reason: String, people: int, coins: int, goods: Dictionary) -> void:
	w.stat("migrants_" + dir, float(people))
	w.stat("migrant_%s_%s" % [dir, reason], float(people))
	w.regions.log_move({"day": w.day(), "settlement": s.id, "dir": dir, "reason": reason, "people": people, "coins": coins, "goods": _count(goods)})
	if w.recorder != null:
		w.recorder.migration(str(s.id), dir, reason, people, coins, _count(goods))     # REC-DIAG


static func _count(goods: Dictionary) -> int:
	var n := 0
	for k in goods:
		n += int(goods[k])
	return n


static func _names(ms: Array) -> String:
	return ", ".join(ms.map(func(o): return "%s %s" % [o.name, o.family]))


# ------------------------------------------------------------------ arrivals in the village ----------------
## The villager a traveller's record is. ID-01: the same person, never a replacement: a traveller who left the village (their record
## names an NPC kept with alive false and `away` set) is reactivated, with the age, skills and purse they come back with; their old
## ties, memories, family links and civic history, all keyed by that id, are simply there again. A person born in a settlement (an id
## from the settlement band, no record yet) gets their first villager record under that id. The name, age, sex and skills are what
## they carried (a settlement-born member's skills come from the village's own starting rule for their trade, `_who`), with a full
## stomach and the purse they brought. Until `_settled` they are not in a household; `_undo_villager` takes them back.
static func _villager(w: World, p: Dictionary, coins: int) -> NPC:
	var id := int(p.get("id", 0))
	var old: NPC = w.by_id.get(id) if id > 0 else null
	if old != null and not old.alive and old.away != "" and not old.became_player:
		return _reactivate(w, old, p, coins)
	var n := NPC.new()
	n.id = id if id > 0 and old == null else w.new_person_id()
	n.name = str(p.n)
	n.family = str(p.f)
	n.sex = "female" if int(p.sex) == 1 else "male"
	n.born = Life.born_for_age(float(p.age), w.minutes)
	n.role = Life.role_for(w, n)
	n.sprite = "res://assets/characters/villager_%02d.png" % (n.id % 48)
	n.coins = coins
	n.hunger = 100.0
	for k in p.sk:
		n.skills[str(k)] = int(p.sk[k])
	Skills.seed_trades_for(n)
	w.npcs.append(n)
	w.by_id[n.id] = n
	if not w.people.has(n.id):
		Identity.register_npc(w, n, "arrival")                     # (a person the register does not know yet: it always does after a world loads)
	return n


## Static: the state a reactivated villager had when the move began, by id, for `_undo_villager`; cleared by `_settled`.
static var _returning := {}


static func _reactivate(w: World, n: NPC, p: Dictionary, coins: int) -> NPC:
	_returning[n.id] = {"alive": n.alive, "away": n.away, "household": n.household, "home": n.home, "workplace": n.workplace, "job": n.job,
		"role": n.role, "coins": n.coins, "hunger": n.hunger, "hp": n.hp, "born": n.born, "skills": n.skills.duplicate(), "doing": n.doing,
		"partner": n.partner, "pos": n.pos, "family": n.family}
	n.alive = true
	n.away = ""
	n.born = Life.born_for_age(float(p.age), w.minutes)
	n.skills = {}
	for k in p.get("sk", {}):
		n.skills[str(k)] = int(p.sk[k])
	Skills.seed_trades_for(n)
	n.coins = coins
	n.hunger = 100.0
	n.hp = n.max_hp
	n.household = -1
	n.home = ""
	n.job = ""
	n.workplace = ""
	n.doing = "idle"
	n.plan.clear()
	n.journey = {}                                      # REG-02: no trip of their old life comes back with them
	n.target = -1
	n.role = Life.role_for(w, n)
	if n.partner >= 0:                                  # a partner link survives only if it is still mutual (or the partner is away too)
		var o := w.npc(n.partner)
		if o == null or o.partner != n.id:
			n.partner = -1
	return n


## The move did not go through (no home or room could be had): the person is as they were before `_villager`.
static func _undo_villager(w: World, n: NPC) -> void:
	if _returning.has(n.id):
		var snap: Dictionary = _returning[n.id]
		for k in snap:
			n.set(k, snap[k])
		n.plan.clear()
		_returning.erase(n.id)
		return
	w.npcs.erase(n)
	w.by_id.erase(n.id)
	if w.people.has(n.id) and str(w.people[n.id].where) == Identity.VILLAGE:     # (made for this move: a member's own entry says where they are)
		w.release_person_id(n.id)


## After the people are housed: each is in exactly one household's list, the register says they are in the village (and under what
## name), and the undo record is done with.
static func _arrived(w: World, n: NPC) -> void:
	var rejoined := _returning.has(n.id)               # a former villager's own record, reactivated (no new person: the population count does not grow)
	_returning.erase(n.id)
	for hh in w.households:
		var list: Array = hh.members
		var keep: bool = int(hh.id) == n.household
		while list.has(n.id):
			list.erase(n.id)
		if keep:
			list.append(n.id)
	Identity.move(w, n.id, Identity.VILLAGE, "rejoined" if rejoined else "")     # REC-19: the recorder tells a return from a first arrival
	if w.people.has(n.id):
		w.people[n.id].name = n.name
		w.people[n.id].family = n.family


## Where `ms` (new villagers, one purse) live: with `prefer_h` if it lives, else a home of their own leased from the manor if they
## can pay the rent (the dead worker's old house first), else a room in the smallest household (the newcomer's rule,
## NPCBrain._newcomer_for). Returns the household id, or -1 if the village has none to lodge them (nobody was made homeless).
static func _house(w: World, ms: Array, prefer_h := -1, prefer_home := "", host_only := false) -> int:
	if prefer_h >= 0 and prefer_h < w.households.size() and not w.households[prefer_h].get("ended", false) \
			and not w.brain._members(prefer_h).is_empty() and w.buildings.has(str(w.households[prefer_h].home)):
		for o: NPC in ms:
			w.brain._lodge(o, prefer_h)
		return prefer_h
	var purse := 0
	for o: NPC in ms:
		purse += o.coins
	var nh := {"id": w.households.size(), "family": ms[0].family, "home": "", "members": [], "pantry": Inventory.new(), "founded_day": w.day()}
	w.households.append(nh)
	for o: NPC in ms:
		o.household = int(nh.id)
		(nh.members as Array).append(o.id)
	if not host_only:
		var homes := []
		if w.buildings.has(prefer_home):
			homes.append(prefer_home)
		var ids: Array = w.buildings.keys()
		ids.sort()
		for id in ids:
			if not homes.has(id):
				homes.append(id)
		for id in homes:
			var b: Dictionary = w.buildings[id]
			if w.property.is_home(b) and w.property.for_sale(b) and purse >= w.property.rent_of(b):
				if w.property.lease(b, World.hh_ref(int(nh.id))) == "":
					nh.home = id
					break
	if str(nh.home) != "":
		for o: NPC in ms:
			o.home = str(nh.home)
		return int(nh.id)
	var host := -1                                   # no house to lease: a room with the smallest household
	for hh in w.households:
		if hh.get("ended", false) or int(hh.id) == int(nh.id) or not w.buildings.has(str(hh.home)) or w.brain._members(int(hh.id)).is_empty() or Life.is_couple(hh):
			continue                                 # (never in a player couple's home: MP-PLAYER-FAMILY)
		if host < 0 or w.brain._members(int(hh.id)).size() < w.brain._members(host).size():
			host = int(hh.id)
	w.households.erase(nh)
	if host < 0:
		return -1
	for o: NPC in ms:
		w.brain._lodge(o, host)
	return host


static func _place(w: World, ms: Array) -> void:
	for o: NPC in ms:
		var home: String = o.home if w.buildings.has(o.home) else w.brain._manor_id()          # a household still seeking a home arrives at the manor
		o.pos = Vector2(w.building_door(home)) + Vector2(0.5, 0.5)
		o.plan.clear()


## Whether the village has a home or a room for a household of `ms`-sized, coins `purse` (checked before anyone is released).
static func _can_house(w: World, purse: int, need_home: bool) -> bool:
	for r in w.property.market():
		if (w.property.is_home(r) or w.property.is_home(w.property.unit(r).back())) and (purse >= w.property.price_of(r) or purse >= w.property.rent_of(r) * 2):
			return true
	if need_home:
		return false
	for hh in w.households:
		if not hh.get("ended", false) and w.buildings.has(str(hh.home)) and not w.brain._members(int(hh.id)).is_empty() and not Life.is_couple(hh):
			return true
	return false


## The travellers settle in the village: the goods go to the new household's pantry (or a lone person's pack), the coins and goods
## crossing are booked, and the lines written. `ms` are already lodged (household `h`); `find_home` has the household seek a home on the
## manor's market by the village's own rule before they are set down.
static func _settled(w: World, s: OffMapSettlement, ms: Array, h: int, goods: Dictionary, coins: int, reason: String, find_home := false) -> void:
	var own: bool = h >= 0 and (w.households[h].members as Array).size() == ms.size()
	var store: Inventory = w.households[h].pantry if own else ms[0].inv
	for id in goods:
		store.add(str(id), int(goods[id]))
		w.stat("imported_" + str(id), float(goods[id]))
	if coins > 0:
		w.coin_sources += coins
		w.stat("caravan_coins_in", float(coins))
		w.stat("migrant_coins_in", float(coins))
	if find_home and own and str(w.households[h].home) == "":
		w.construction._find_home(h)
	_place(w, ms)
	for o: NPC in ms:
		_arrived(w, o)
	_book(w, s, "in", reason, ms.size(), coins, goods)
	var names := _names(ms)
	w.note("%s %s from %s %s." % [names, "arrives" if ms.size() == 1 else "arrive", s.name, WHY[reason]])
	s.note("%s leave%s for the village %s." % [names, "s" if ms.size() == 1 else "", WHY[reason]])
	for o: NPC in ms:
		w.brain.evaluate_household(o.household)


# ------------------------------------------------------------------ the village's people leaving ----------------
static func _bt_for(s: OffMapSettlement, job: String) -> String:
	var bt: String = JOB_BIZ.get(job, "")
	return bt if bt != "" and s.biz.has(bt) else hiring(s)


## The settlement business that paid its workers best last week, at least `switch_to_at_least` a day (the settlement's own
## measure of a trade that pays well); "" when none.
static func hiring(s: OffMapSettlement) -> String:
	var types := s.biz.keys()
	types.sort()
	var best := ""
	for t in types:
		var b: Dictionary = s.biz[t]
		if t == "merchant" or s._workers(b) == 0 or float(b.get("rate", 0.0)) < float(OffMapSettlement.rules().switch_to_at_least):
			continue
		if best == "" or float(b.rate) > float(s.biz[best].rate):
			best = t
	return best


## Food the settlement's food businesses hold above its own claim (food points): what it can spare for newcomers.
static func spare_food_pts(s: OffMapSettlement) -> float:
	var foods := s.food_items()
	var held := 0.0
	var types := s.biz.keys()
	types.sort()
	for t in types:
		var b: Dictionary = s.biz[t]
		if b.type == "merchant" or s._workers(b) == 0 or not s._makes_food(b):
			continue
		var keep := s._keep(b)
		for item in foods:
			held += float(s._food_spare(b, item, keep)) * s._pts(item)
	return maxf(0.0, held - s.food_claim_pts())


## A household (or the part of one) of the village goes to `s`: it joins a business as a new household.
static func _household_out(w: World, s: OffMapSettlement, ms: Array, _whole: bool, reason: String, bt: String) -> bool:
	if ms.is_empty() or bt == "" or not s.biz.has(bt):
		return false
	if walks(w, s, ms):
		return _set_out(w, s, ms, reason, {"mode": "household", "bt": bt})          # REG-05: they walk; they join on arrival
	if not _settle_departure_property(w, ms):
		return false
	_pre_leave(w, ms)
	var pantry := _take_own(w, ms)                                          # TILL-D1: a household that leaves takes its till and stores
	var load_ := _pack(w, ms, pantry)
	var names := _names(ms)
	var h := s.receive_household(load_.people, int(load_.coins), load_.goods, bt)
	_gone(w, s, ms, load_, pantry, reason)
	w.note("%s leave for %s %s." % [names, s.name, WHY[reason]])
	s.note("%s arrive from the village %s and take up work in the %s." % [names, WHY[reason], OffMapSettlement.btype(bt).get("name", bt)])
	return h >= 0


static func _hunger_out(w: World, s: OffMapSettlement) -> bool:
	if not w.famine():
		return false
	var cap := float(GameData.b("relief_trigger_days"))
	var best := -1
	var best_days := INF
	for h in range(3, w.households.size()):
		if w.households[h].get("ended", false) or Life.is_couple(w.households[h]):
			continue                                     # a player couple's children do not leave without them (MP-PLAYER-FAMILY)
		var ms: Array = w.brain._members(h)
		if ms.is_empty() or _any_barred(w, ms):
			continue
		var fd: float = w.brain.household_food_days(h)
		if fd < cap and fd < best_days:
			best_days = fd
			best = h
	if best < 0:
		return false
	var members: Array = w.brain._members(best)
	if spare_food_pts(s) < _food_need_pts(members):
		return false
	var head: NPC = members[0]
	for o: NPC in members:
		if o.role == "adult" and o.job != "":
			head = o
			break
	return _household_out(w, s, members, true, "hunger", _bt_for(s, head.job))


static func _work_out(w: World, s: OffMapSettlement, market_: Dictionary = {}) -> bool:
	var bt := hiring(s)
	if bt == "":
		return false
	var who: NPC = null
	var spouse: NPC = null
	for h in range(3, w.households.size()):
		var hh: Dictionary = w.households[h]
		if hh.get("ended", false):
			continue                     # B42-Q-EMIG-WORK (owner 2026-11-14): judged per person, whatever the household's food
		var ms: Array = w.brain._members(h)
		ms.sort_custom(func(a: NPC, b: NPC) -> bool: return a.id < b.id)
		for o: NPC in ms:
			if o.role == "adult" and long_idle(w, o) and not _barred(w, o) and Life._may_move(w, o):
				# B25-EMIG-MARRIAGE-D1 (owner 2026-11-12, option A): a married adult leaves for work only with their spouse, as the
				# land move takes the partner along. A spouse who cannot relocate keeps them both here: a solo emigration would
				# count the emigrant gone (alive false, away) and free the spouse left behind to remarry (Life.free_to_partner).
				var p: NPC = _spouse_to_take(w, o)
				if Life.has_partner(w, o) and p == null:
					continue
				who = o
				spouse = p
				break
		if who != null:
			break
	if who == null:
		return false
	var market: Dictionary = market_ if not market_.is_empty() else w.brain.job_market()      # work in the village comes first: nobody leaves with a place open
	for job in ["manor_hand", "farmer", "woodcutter", "hunter", "miner", "prospector", "tailor", "barber", "preacher", "church_assistant"]:
		if int(market[job].open) > 0:
			return false
	if spouse != null:
		return _household_out(w, s, [who, spouse], false, "work", bt)
	if walks(w, s, [who]):
		return _set_out(w, s, [who], "work", {"mode": "person", "bt": bt})       # REG-05
	if not _settle_departure_property(w, [who]):
		return false
	_pre_leave(w, [who])
	var pantry := _take_own(w, [who])                                       # the last of a household takes its stores along
	var load_ := _pack(w, [who], pantry)
	var h := s.receive_person(load_.people[0], int(load_.coins), load_.goods, bt)
	_gone(w, s, [who], load_, pantry, "work")
	w.note("%s %s leaves for %s, where work is to be had." % [who.name, who.family, s.name])
	s.note("%s arrives from the village for work, and joins the %s." % [who.name, OffMapSettlement.btype(bt).get("name", bt)])
	return h >= 0


## B42-Q-EMIG-WORK (owner 2026-11-14): an adult with no job and no earnings for about a week (`emigrate_work_idle_days`, 7): no job
## since that many days (NPC.job_since, the day of the last change of job) and nothing earned on each of the last that many days
## (NPC.income_days, kept for the last 7). A day not yet in the record counts as not known, so a newcomer is not judged early.
static func long_idle(w: World, o: NPC) -> bool:
	var days := int(GameData.b("emigrate_work_idle_days"))
	if o.job != "" or w.day() - o.job_since < days:
		return false
	var need := mini(days, 7)
	if o.income_days.size() < need:
		return false
	for v in o.income_days.slice(-need):
		if int(v) > 0:
			return false
	return true


## B25-EMIG-MARRIAGE-D1: the living spouse who would go along with `o`, or null when `o` has none or the spouse cannot relocate (an
## office, a player's family, a homestead, young children at home: the land move's and Life._may_move's own reasons).
static func _spouse_to_take(w: World, o: NPC) -> NPC:
	if not Life.has_partner(w, o) or Life.is_player_id(o.partner):
		return null
	var p := w.npc(o.partner)
	if p == null or not p.alive or p.role != "adult" or _barred(w, p) or not Life._may_move(w, p):
		return null
	return p


static func _land_out(w: World, s: OffMapSettlement) -> bool:
	var wait := int(GameData.b("mobility_unsustainable_days"))
	var best := -1
	var best_since := 1 << 30
	var best_key := ""
	for h in range(3, w.households.size()):
		if w.households[h].get("ended", false):
			continue
		var goals: Dictionary = w.construction.housing_goals(h)
		for key in ["no home", "crowded"]:
			var g: Dictionary = goals.get(key, {})
			if not g.is_empty() and int(g.short) > 0 and w.day() - int(g.since) >= wait and int(g.since) < best_since:
				best = h
				best_since = int(g.since)
				best_key = key
	if best < 0:
		return false
	var ms: Array = w.brain._members(best)
	var whole := best_key == "no home"
	if not whole:
		var f: NPC = w.construction.founder_of(best)           # the grown member who would have founded a household, with a partner
		if f == null:
			return false
		ms = [f]
		if w.construction._partner_here(f):
			ms.append(w.npc(f.partner))
	if ms.is_empty() or _any_barred(w, ms) or spare_food_pts(s) < _food_need_pts(ms):
		return false
	var head: NPC = ms[0]
	return _household_out(w, s, ms, whole, "land", _bt_for(s, head.job))


# ------------------------------------------------------------------ REG-05: the walk ----------------
const MIGRATE := "migrate"
const WAIT_DAYS := 2                 # how long the first of a party to arrive waits at the site for the rest (then they join without them)


## Whether `ms` leave for `s` on foot: the settlement stands in the world with a road from the village to it.
static func walks(w: World, s: OffMapSettlement, ms: Array) -> bool:
	if not walk:
		return false
	var ow: Overworld = w.map.overworld if w.map != null else null
	if ow == null or ow.site(s.id).is_empty() or ow.road_route(Journeys.gate_index(w), s.id).is_empty():
		return false
	return not ms.any(func(o): return Journeys.active(o))


## REG-05: the party sets out. The departure transactions now (PROP-06 property, quests and contracts, stalls, tills, debts, the
## pantry into the head's pack), then each member's walk. Nothing crosses to the settlement yet. False (nothing changed) when the
## property cannot be settled or a walk cannot start.
static func _set_out(w: World, s: OffMapSettlement, ms: Array, reason: String, how: Dictionary) -> bool:
	if not _settle_departure_property(w, ms):
		return false
	_pre_leave(w, ms)
	var pantry := _take_own(w, ms)
	var head: NPC = ms[0]
	for o: NPC in ms:
		if o.role == "adult":
			head = o
			break
	var ids_ := []
	for o: NPC in ms:
		ids_.append(o.id)
	var purpose := {"kind": MIGRATE, "party": "%s:%d:%d" % [s.id, w.day(), int(ms[0].id)], "reason": reason, "members": ids_}
	purpose.merge(how)
	var started := []
	for o: NPC in ms:                                    # each takes food for their own walk from the pantry (Journeys.provision)
		if Journeys.start(w, o, s.id, purpose) != "":
			for x: NPC in started:                         # (cannot happen after walks(): a walk that will not start leaves nobody on the road)
				Journeys.end(w, x, "cancelled")
			w.stat("migration_set_out_failed")
			return false
		started.append(o)
	if pantry != null:                                   # the rest of the household's stores are carried by its head
		var ids: Array = pantry.ids()
		ids.sort()
		for id in ids:
			w.transfer(pantry, head.inv, str(id), pantry.count(str(id)))
	w.stat("migration_set_out")
	w.stat("migration_set_out_" + reason)
	w.note("%s set%s out for %s %s." % [_names(ms), "s" if ms.size() == 1 else "", s.name, WHY[reason]])
	return true


## World.journey_hook: a migrant at the settlement. When every living member of the party still on this walk is there (or the first
## has waited WAIT_DAYS), they join it together; until then they wait at the site. True while this has them (waiting or joining).
static func at_site(w: World, n: NPC) -> bool:
	var p: Dictionary = n.journey.get("purpose", {})
	if str(p.get("kind", "")) != MIGRATE or w.regions == null:
		return false
	var s: OffMapSettlement = w.regions.by_id.get(str(n.journey.to))
	if s == null:
		return false
	var ms := []
	var waiting := false
	for id in p.get("members", []):
		var o := w.npc(int(id))
		if o == null or not o.alive or str(o.journey.get("purpose", {}).get("party", "")) != str(p.party):
			continue                                     # died on the road, turned back, or never left: not in the party now
		if str(o.journey.get("leg", "")) != "there":
			waiting = true
		ms.append(o)
	if waiting and w.day() - int(n.journey.get("arrived", w.day())) < WAIT_DAYS:
		n.doing = "waiting at %s for the rest of the household" % s.name
		n.plan = [{"k": "work", "min": 60.0, "anim": "idle"}]
		n.work_left = 60.0
		return true
	ms = ms.filter(func(o): return str(o.journey.get("leg", "")) == "there")
	_join(w, s, ms, p)
	return true


## The party joins `s`: its people, purses and packs cross the boundary now, by the instant move's own rules.
static func _join(w: World, s: OffMapSettlement, ms: Array, p: Dictionary) -> void:
	var reason := str(p.get("reason", "work"))
	var load_ := _pack(w, ms, null)
	var names := _names(ms)
	match str(p.get("mode", "household")):
		"wed":
			var gi := int(p.get("gi", -1))
			var gj := -1
			if gi >= 0 and gi < s.hh.size() and bool(s.hh[gi].alive):
				for j in (s.hh[gi].mem as Array).size():
					if OffMapSettlement.member_id(s.hh[gi].mem[j]) == int(p.get("groom", -1)):
						gj = j
			if gj >= 0 and int(s.hh[gi].mem[gj][OffMapSettlement.M_PAIR]) == 0:
				s.wed_in(gi, gj, load_.people[0], int(load_.coins), load_.goods)
				w.stat("partnerships")
				s.note("%s arrives from the village and marries." % ms[0].name)
			else:                                          # the groom is gone or wed since she set out: she joins the place to work
				s.receive_person(load_.people[0], int(load_.coins), load_.goods, hiring(s))
				w.stat("migration_wed_groom_gone")
				s.note("%s arrives from the village to marry, finds the match gone, and stays to work." % ms[0].name)
		"person":
			s.receive_person(load_.people[0], int(load_.coins), load_.goods, str(p.get("bt", "")))
			s.note("%s arrives from the village for work." % names)
		_:
			s.receive_household(load_.people, int(load_.coins), load_.goods, str(p.get("bt", "")))
			s.note("%s arrive from the village %s." % [names, WHY.get(reason, "")])
	_gone(w, s, ms, load_, null, reason)              # (each walk ends here: Journeys.end "emigrated")
	w.stat("migration_arrived")
	w.note("%s reached %s and %s there." % [names, s.name, "stays" if ms.size() == 1 else "stay"])


## Journeys.end of a migrant's walk that did not reach the settlement (`how`: turned_back, no road, lost, died). A death is any death's
## (World.kill). One who comes home has left nothing in the settlement: their property was settled when they set out (R5-Q4).
static func walk_ended(w: World, n: NPC, how: String) -> void:
	if how in ["emigrated", "died", "cancelled"]:
		return
	w.stat("migration_walk_ended_" + how)
	w.note("%s %s could not reach %s and is back in the village." % [n.name, n.family, str(n.journey.get("to", ""))])


# ------------------------------------------------------------------ the settlements' people arriving ----------------
## Village posts nobody could fill: vacancies past succession_days with no apprentice (the posts that would otherwise take a
## newcomer made for them).
static func open_vacancies(w: World) -> Array:
	var out := []
	var wait := int(GameData.b("succession_days"))
	for v in w.vacancies:
		if w.day() - int(v.day) >= wait and w.brain.living_in(v.job) < w.brain.staff_target(v.job) and w.brain._apprentice_for(v) == null:
			out.append(v)
	return out


static func _work_in(w: World, s: OffMapSettlement, market_: Dictionary = {}) -> bool:
	var order := range(s.hh.size())
	order.sort_custom(func(a, b): return int(s.hh[b].low) < int(s.hh[a].low) or (int(s.hh[b].low) == int(s.hh[a].low) and a < b))
	var cand: Array = []                       # [household index, member index]
	for i in order:
		var h: Dictionary = s.hh[i]
		if not h.alive or int(h.low) < 1 or str(h.trade) == "official" or int(h.adults) < 2 or h.mem.size() < 2:
			continue
		for j in h.mem.size():
			var m: Array = h.mem[j]
			if s._is_adult(m) and int(m[OffMapSettlement.M_PAIR]) == 0 and s._age(m) < s._mort_from:
				cand = [i, j]
				break
		if not cand.is_empty():
			break
	if cand.is_empty():
		return false
	var h: Dictionary = s.hh[cand[0]]
	var trade_job: String = TRADE_JOB.get(str(h.trade), "")
	var vac: Dictionary = {}
	var vs := open_vacancies(w)
	for v in vs:
		if str(v.job) == trade_job:
			vac = v
			break
	if vac.is_empty() and not vs.is_empty():
		vac = vs[0]
	var job := ""
	if vac.is_empty():
		var market: Dictionary = market_ if not market_.is_empty() else w.brain.job_market()
		var best_pay := float(h.rate)
		for jb in WORK_PLACES:
			var opt: Dictionary = market[jb]
			if int(opt.open) > 0 and float(opt.pay) > best_pay:
				best_pay = float(opt.pay)
				job = jb
		if job == "":
			return false
	if not _can_house(w, 0, false):
		return false
	var load_ := s.person_load(cand[0], cand[1])              # what they would take: nothing changes until a place is certain
	var n := _villager(w, _with_who(s, load_.people[0], str(h.trade)), int(load_.coins))
	var ms := [n]
	var at := _house(w, ms, int(vac.get("household", -1)), str(vac.get("home", "")))
	if at < 0:
		_undo_villager(w, n)
		return false
	s.release_person(cand[0], cand[1])
	if not vac.is_empty():
		w.vacancies.erase(vac)
		_settled(w, s, ms, at, load_.goods, int(load_.coins), "work")
		w.brain._install(n, vac, "a migrant")
	else:
		_settled(w, s, ms, at, load_.goods, int(load_.coins), "work")
		w.brain._change_job(n, job, "came for work")
	return true


## A settlement member's record for the village: the carried name and skills, or (born in the settlement) a name drawn
## reproducibly from the settlement, day and sex, and the skills of the village's starting rule (PAR-01A) for their trade.
static func _with_who(s: OffMapSettlement, p: Dictionary, trade: String) -> Dictionary:
	if p.has("n") and str(p.n) != "":
		return p
	var salt := s.id.hash() & 0xFFFFFF
	var born := int(p.born)
	var names: Array = Population.FIRST.filter(func(x): return (Life.sex_of_name(x) == "female") == (int(p.sex) == 1))
	p.n = names[int(OffMapSettlement._roll(salt, born, 11) * names.size()) % names.size()]
	p.f = Population.FAMILY[int(OffMapSettlement._roll(salt, born, 12) * Population.FAMILY.size()) % Population.FAMILY.size()]
	var job: String = TRADE_JOB.get(trade, "")
	p.sk = Skills.start_xp(job, float(p.age), OffMapSettlement._roll(salt, born, 13)) if job != "" and float(p.age) >= float(Life.cfg().adolescent_until) else {}
	return p


static func _hunger_in(w: World, s: OffMapSettlement) -> bool:
	if w.famine() or w.food_days < float(GameData.b("reserve_days")):
		return false
	var pick := -1
	var pick_hungry := 0
	for i in s.hh.size():
		var h: Dictionary = s.hh[i]
		if not h.alive or str(h.trade) == "official" or int(h.hungry) < s.move_patience(h) or int(h.coins) >= s._day_food_cost(h) \
				or s._pantry_pts(h) >= s._need_pts(h):
			continue                                   # REG-X20-D1: a business's only household may leave too; each waits its own patience
		if int(h.hungry) > pick_hungry:
			pick_hungry = int(h.hungry)
			pick = i
	if pick < 0:
		return false
	var h: Dictionary = s.hh[pick]
	if (w.food_days - float(GameData.b("reserve_days"))) * w.brain.village_day_food() < s._need_pts(h) * float(GameData.b("reserve_days")):
		return false
	if not _can_house(w, int(h.coins), false):
		return false
	return _household_in(w, s, pick, "hunger")


## A whole settlement household moves to the village: new villagers in a home or a room (for land, a home of their own that they
## buy or lease on the manor's market).
static func _household_in(w: World, s: OffMapSettlement, hi: int, reason: String) -> bool:
	var trade := str(s.hh[hi].trade)
	var load_ := s.household_load(hi)                          # nothing changes until they are housed
	var ms := []
	for i in load_.people.size():
		ms.append(_villager(w, _with_who(s, load_.people[i], trade), int(load_.coins) if i == 0 else 0))
	for i in ms.size():                                        # the couple the household held stays a couple
		for j in range(i + 1, ms.size()):
			if int(load_.people[i].pair) == 1 and int(load_.people[j].pair) == 1 and ms[i].sex != ms[j].sex and ms[i].partner < 0 and ms[j].partner < 0:
				Life._link_partners(ms[i], ms[j])
	var at := -1
	if reason == "land":
		var nh := {"id": w.households.size(), "family": ms[0].family, "home": "", "members": [], "pantry": Inventory.new(), "founded_day": w.day()}
		w.households.append(nh)
		for o: NPC in ms:
			o.household = int(nh.id)
			(nh.members as Array).append(o.id)
		at = int(nh.id)
	else:
		at = _house(w, ms)
	if at < 0:
		for o: NPC in ms:
			_undo_villager(w, o)
		return false
	s.release_household(hi)
	_settled(w, s, ms, at, load_.goods, int(load_.coins), reason, reason == "land")
	return true


static func _land_in(w: World, s: OffMapSettlement) -> bool:
	for i in s.hh.size():
		var h: Dictionary = s.hh[i]
		if not h.alive or int(h.get("landless", 0)) != 1 or str(h.trade) == "official" or int(h.adults) != 2 or h.mem.size() < 2:
			continue                                   # REG-X20-D1: no household is kept back for its business
		if not _can_house(w, int(h.coins), true):
			continue
		if _household_in(w, s, i, "land"):                       # the manor's market, by the village's own rule (buy, else two weeks' rent)
			return true
	return false


# ------------------------------------------------------------------ marriage ----------------
## Whether a village person may be matched: a grown, unpartnered, willing adult of marrying age.
static func _marriageable(w: World, n: NPC) -> bool:
	var c: Dictionary = Life.cfg()
	var age := Life.npc_age(w, n)
	return n.alive and n.role == "adult" and not Life.has_partner(w, n) and w.relations.willing(n) \
			and age >= float(c.partner_min_age) and age <= float(c.partner_max_age) and not _barred(w, n)


## The settlement's grown people who may marry, as OffMapSettlement._found_household reckons them: [household, member], by sex.
static func _marriageable_in(s: OffMapSettlement, sex: int) -> Array:
	var c: Dictionary = Life.cfg()
	var lo := float(c.partner_min_age)
	var hi := float(c.partner_max_age)
	var wait := lo * s._yd + float(GameData.b("relations").marry_min_days)
	var out := []
	for h in s.hh:
		if not h.alive:
			continue
		for j in h.mem.size():
			var m: Array = h.mem[j]
			var a := s._age(m)
			if int(m[OffMapSettlement.M_PAIR]) == 1 or int(m[OffMapSettlement.M_UNWILLING]) == 1 or a < lo or a > hi \
					or float(s.day - int(m[OffMapSettlement.M_BORN])) < wait or int(m[OffMapSettlement.M_SEX]) != sex:
				continue
			if int(h.adults) < 2 and int(h.children) > 0:
				continue
			if h.mem.size() == 1 and not s._may_close(h):
				continue
			out.append([int(h.id), j])
	return out


## Whether the pair that meets at the caravan have known each other long enough (the village's `marry_min_days`, the time its own
## courting takes before a proposal): the first visit that finds them a pair begins it, and it ends when another pair comes to the
## top. True once, when the days have passed.
static func _courted(w: World, s: OffMapSettlement, dir: String, pair: String) -> bool:
	var k := "%s|%s" % [s.id, dir]
	var c: Dictionary = w.regions.suits.get(k, {})
	if str(c.get("pair", "")) != pair:
		w.regions.suits[k] = {"pair": pair, "since": w.day()}
		return false
	if w.day() - int(c.since) < int(GameData.b("relations").marry_min_days):
		return false
	w.regions.suits.erase(k)
	return true


## A villager bride goes to a settlement groom: she is the village's grown woman of the lowest id who meets his age bounds.
static func _marry_out(w: World, s: OffMapSettlement) -> bool:
	var c: Dictionary = Life.cfg()
	var men := _marriageable_in(s, 0)
	if men.is_empty():
		w.regions.suits.erase("%s|out" % s.id)
		return false
	var women: Array = w.npcs.filter(func(n: NPC) -> bool: return n.sex == "female" and _marriageable(w, n) and Life._may_move(w, n))
	women.sort_custom(func(a: NPC, b: NPC) -> bool: return a.id < b.id)
	for bride: NPC in women:
		var ba := Life.npc_age(w, bride)
		for g in men:
			var gh: Dictionary = s.hh[g[0]]
			if absf(s._age(gh.mem[g[1]]) - ba) > float(c.partner_max_gap):
				continue
			_pre_leave(w, [bride])
			if not _courted(w, s, "out", "%d:%d:%d" % [bride.id, g[0], int(gh.mem[g[1]][OffMapSettlement.M_BORN])]):
				return false
			if walks(w, s, [bride]):                            # REG-05: she walks to him; they marry when she arrives
				return _set_out(w, s, [bride], "marriage", {"mode": "wed", "gi": int(g[0]), "groom": OffMapSettlement.member_id(gh.mem[g[1]])})
			if not _settle_departure_property(w, [bride]):
				return false
			var pantry := _take_own(w, [bride])
			var load_ := _pack(w, [bride], pantry)
			s.wed_in(g[0], g[1], load_.people[0], int(load_.coins), load_.goods)
			_gone(w, s, [bride], load_, pantry, "marriage")
			w.stat("partnerships")
			w.note("%s %s leaves to marry a man of %s." % [bride.name, bride.family, s.name])
			s.note("%s arrives from the village and marries." % bride.name)
			return true
	return false


## A settlement bride goes to a village groom: the village's grown man of the lowest id whose household has a bed (the bride
## shares his), who meets her age bounds, and who is not her kin (none can be: she is not of the village).
static func _marry_in(w: World, s: OffMapSettlement) -> bool:
	var c: Dictionary = Life.cfg()
	var brides := _marriageable_in(s, 1)
	if brides.is_empty():
		w.regions.suits.erase("%s|in" % s.id)
		return false
	var men: Array = w.npcs.filter(func(n: NPC) -> bool: return n.sex == "male" and _marriageable(w, n) and n.household >= 3 \
			and w.construction.beds_in(str(w.households[n.household].home)) >= w.construction.beds_needed(n.household))
	men.sort_custom(func(a: NPC, b: NPC) -> bool: return a.id < b.id)
	for groom: NPC in men:
		var ga := Life.npc_age(w, groom)
		for b in brides:
			var bh: Dictionary = s.hh[b[0]]
			if absf(s._age(bh.mem[b[1]]) - ga) > float(c.partner_max_gap):
				continue
			if not _courted(w, s, "in", "%d:%d:%d" % [groom.id, b[0], int(bh.mem[b[1]][OffMapSettlement.M_BORN])]):
				return false
			var load_ := s.release_person(b[0], b[1])
			var n := _villager(w, _with_who(s, load_.people[0], str(bh.trade)), int(load_.coins))
			w.brain._lodge(n, groom.household)
			Life._link_partners(n, groom)
			_settled(w, s, [n], groom.household, load_.goods, int(load_.coins), "marriage")
			w.stat("partnerships")
			w.note("%s %s and %s %s become partners." % [n.name, n.family, groom.name, groom.family])
			return true
	return false
