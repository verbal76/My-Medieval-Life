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
##   work      out: an adult without a trade, in a household that cannot live on its income (the seek_work condition), while the
##             village's labour market (NPCBrain.job_market) has no open place, goes to a settlement business that paid its workers
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
## Deterministic: no random numbers (names of settlement-born members come from OffMapSettlement._roll). Saved: the log and counts
## in Regions ("moves", "move_counts"), the people in the settlements (members' fifth entry) and in World.npcs (NPC.away).

const REASONS := ["hunger", "work", "land", "marriage"]
const LOG_MAX := 200                 # moves kept in the log (Regions.moves); the counts are kept for good
## A settlement trade's village job (for the skills a member of that trade would have, and the trade a post suits), and the
## business a village job joins in a settlement. "" is a trade the village has no job for.
const TRADE_JOB := {"farmer": "farmer", "herder": "farmer", "forester": "woodcutter", "miner": "miner", "sawyer": "carpenter",
	"mason": "miner", "smith": "smith", "tanner": "tanner", "cook": "cook", "weaver": "", "healer": "", "merchant": "merchant", "official": ""}
const JOB_BIZ := {"farmer": "farm", "woodcutter": "forest", "miner": "quarry", "hunter": "herd", "smith": "smith", "carpenter": "sawyer",
	"tanner": "tanner", "cook": "cook", "tavernkeeper": "cook", "laborer": "farm", "manor_hand": "farm"}
const OFFICES := ["guard", "reeve", "sage", "preacher", "church_assistant", "tailor", "barber"]
const WORK_PLACES := ["manor_hand", "farmer", "hunter"]          # market places that need no tool (a migrant arrives with none)
const WHY := {"hunger": "for want of food", "work": "for work", "land": "for land", "marriage": "to marry"}


static var enabled := true           # a test switch (never cleared in the game): with it off nobody moves

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
## Somebody who cannot leave: an office-holder, a market trader (their stock is the market's), someone tied to the player, a
## child of the founding households' care, or a bandit.
static func _barred(w: World, n: NPC) -> bool:
	if n.role == "bandit" or n.clan != "" or n.household < 3:
		return true
	if n.id == w.reeve_id or n.id == w.sage_id or OFFICES.has(n.job):
		return true
	if n.partner == Life.PLAYER_ID or n.mother == Life.PLAYER_ID or n.father == Life.PLAYER_ID:
		return true
	return SettlementHoldings.MARKET_ROLES.has(w.brain.buy_role(n))


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


## Before packing: what the leaving villagers had set aside for the player's quests and contracts is released to them as for a death
## (a refund lands in their purse, which then goes with them).
static func _pre_leave(w: World, ms: Array) -> void:
	for o: NPC in ms:
		w.quests.on_giver_died(o)
		w.contracts.on_death(o)


## They have gone: the villagers leave the living (alive false, `away` the settlement), the village's accounts of coins and goods
## that crossed, and the posts and stalls they held are handed on exactly as after a death (NPCBrain.on_death).
static func _gone(w: World, s: OffMapSettlement, ms: Array, load_: Dictionary, pantry: Inventory, reason: String) -> void:
	for o: NPC in ms:
		o.coins = 0
		o.inv = Inventory.new()
		o.alive = false
		o.away = s.id
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
	_returning.erase(n.id)
	for hh in w.households:
		var list: Array = hh.members
		var keep: bool = int(hh.id) == n.household
		while list.has(n.id):
			list.erase(n.id)
		if keep:
			list.append(n.id)
	Identity.move(w, n.id, Identity.VILLAGE)
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
		if hh.get("ended", false) or int(hh.id) == int(nh.id) or not w.buildings.has(str(hh.home)) or w.brain._members(int(hh.id)).is_empty():
			continue
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
		if not hh.get("ended", false) and w.buildings.has(str(hh.home)) and not w.brain._members(int(hh.id)).is_empty():
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
static func _household_out(w: World, s: OffMapSettlement, ms: Array, whole: bool, reason: String, bt: String) -> bool:
	if ms.is_empty() or bt == "" or not s.biz.has(bt):
		return false
	var pantry: Inventory = w.households[ms[0].household].pantry if whole else null
	_pre_leave(w, ms)
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
		if w.households[h].get("ended", false):
			continue
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
	for h in range(3, w.households.size()):
		var hh: Dictionary = w.households[h]
		var econ: Dictionary = hh.get("econ", {})
		if hh.get("ended", false) or econ.is_empty() or int(econ.streak) < int(GameData.b("mobility_unsustainable_days")):
			continue
		var ms: Array = w.brain._members(h)
		ms.sort_custom(func(a: NPC, b: NPC) -> bool: return a.id < b.id)
		for o: NPC in ms:
			if o.role == "adult" and o.job == "" and not _barred(w, o) and Life._may_move(w, o):
				who = o
				break
		if who != null:
			break
	if who == null:
		return false
	var market: Dictionary = market_ if not market_.is_empty() else w.brain.job_market()      # work in the village comes first: nobody leaves with a place open
	for job in ["manor_hand", "farmer", "woodcutter", "hunter", "miner", "prospector", "tailor", "barber", "preacher", "church_assistant"]:
		if int(market[job].open) > 0:
			return false
	_pre_leave(w, [who])
	var load_ := _pack(w, [who])
	var h := s.receive_person(load_.people[0], int(load_.coins), load_.goods, bt)
	_gone(w, s, [who], load_, null, "work")
	w.note("%s %s leaves for %s, where work is to be had." % [who.name, who.family, s.name])
	s.note("%s arrives from the village for work, and joins the %s." % [who.name, OffMapSettlement.btype(bt).get("name", bt)])
	return h >= 0


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
		if not h.alive or str(h.trade) == "official" or int(h.hungry) <= 0 or int(h.coins) >= s._day_food_cost(h) \
				or s._pantry_pts(h) >= s._need_pts(h) or s._workers(s.biz[OffMapSettlement.TRADE_BIZ[h.trade]]) < 2:
			continue
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
		if not h.alive or int(h.get("landless", 0)) != 1 or str(h.trade) == "official" or int(h.adults) != 2 or h.mem.size() < 2 \
				or s._workers(s.biz[OffMapSettlement.TRADE_BIZ[h.trade]]) < 2:
			continue
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
			var load_ := _pack(w, [bride])
			s.wed_in(g[0], g[1], load_.people[0], int(load_.coins), load_.goods)
			_gone(w, s, [bride], load_, null, "marriage")
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
