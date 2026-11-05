class_name OffMapSettlement
extends RefCounted
## Expansion 18 (SET-C-SIM; owner Q18-3, 2026-10-23: "Those settlements have simulated economies just like this one, it comes
## from their villagers, or village political structure or companies"; follow-up: "same rules, lighter detail"): ONE off-map
## settlement as a small economy of its own, stepped once a day without walking anyone.
##
##   households   members (adults, children), a purse, a pantry; they work for a business or serve the government, buy food
##                and the goods of daily life in the settlement's market, pay tax, eat, and go hungry when they cannot
##                (a household that starves loses its members; an empty one is dissolved and its coins and food pass
##                to the treasury)
##   businesses   farm, herd, forest, quarry, sawyer, mason, smith, tanner, cook, weaver, healer, merchant: each
##                with its own till, stock and workers (households); natural output (fields, woods, a quarry's finite
##                reserve) or the village's real recipes (game/data/recipes.json) from inputs it bought; it pays its
##                workers from its till above its working reserve and pays tax
##   treasury     the manor, abbey or council: collects the village's tax rule (balance.json tax_rate_*, tax_exemption_*)
##                from households and businesses, pays its officials, buys the settlement's upkeep goods and relieves a
##                hungry household with food it buys
##   market       one price per good, floating with yesterday's imbalance inside the village's own band (price_min,
##                price_max); every sale moves goods and coins together
## The merchants are the settlement's TRADER (owner ECON-P1.3, 2026-10-23): the only party that meets the village's
## caravan (Regions, NPCBrain.caravan) and other settlements' traders; it carries only what its own stock holds and pays only
## from its own till.
##
## Conservation (SIM rules): coins and goods change only by the lines in `flows`, so
##   coins(now) = start + coins_from_village - coins_to_village + road_coins_in - road_coins_out + migrated_in
##                + regional_coins_in - regional_coins_out + outside_coins_in - outside_coins_out
##   goods(now) = start + produced - used + from_village - to_village + road_in - road_out
##                + regional_in - regional_out + outside_in - outside_out
## (REG-PARTY-01, SettlementParty: `regional_*` is trade between holders of two of the five settlements, matched by the other
## settlement's opposite line, which Regions.audit checks; `outside_*` is an exchange with a party that is none of the five
## settlements' holders (the courier service's booths and packs, the village's people, an analysis fixture), whose own books
## carry the other end.)
## and `audit()` checks both. Nothing is created but natural output (fields, woods, quarries, herbs) and nothing is
## destroyed but use (eating, recipes' inputs, upkeep).
##
## Deterministic: a settlement is made once from (world seed, index) and every step after that uses no random numbers.
## Everything is plain Dictionaries and Arrays (saved as they are).

const FORMAT := "mml-offmap/1"
const TRADE_BIZ := {"farmer": "farm", "herder": "herd", "forester": "forest", "miner": "quarry", "sawyer": "sawyer",
	"mason": "mason", "smith": "smith", "tanner": "tanner", "cook": "cook", "weaver": "weaver", "healer": "healer",
	"merchant": "merchant"}
const PREPARED := ["pottage", "roast_meat", "bread", "cheese"]       # foods the cookshop makes (a share of a household's food)
const PREPARED_SHARE := 0.3
const FLOW_GOODS := ["produced", "used", "from_village", "to_village", "road_in", "road_out", "unmet", "regional_in", "regional_out",
	"outside_in", "outside_out"]
const FLOW_COUNTS := ["coins_from_village", "coins_to_village", "road_coins_in", "road_coins_out", "migrated_in", "deaths",
	"wage_short", "relief_units", "tax_households", "tax_businesses", "wages_paid", "official_pay", "horses_foaled",
	"horses_died", "horses_sold", "horses_start", "tolls", "day_labour", "job_moves", "births", "age_deaths", "households_formed",
	"inheritances", "orphans_fostered", "regional_coins_in", "regional_coins_out",
	"outside_coins_in", "outside_coins_out", "migrants_in", "migrants_out", "biz_opened", "biz_closed",
	"food_bought", "food_sold", "food_delivered", "food_unmet", "own_started", "own_ended"]
## A member of a household (REG-DEMO-01): [born, sex, partnered, unwilling]. `born` is a settlement day number (negative before the
## first step), so age in years is (day - born) / the calendar's year length and needs no daily update; sex 1 is female; partnered 1
## means the member is one of the household's couple; unwilling 1 is a person who will not marry (decided once, at birth or founding).
const M_BORN := 0
const M_SEX := 1
const M_PAIR := 2
const M_UNWILLING := 3
## A member who came from, or went to, the village (MIGRATE-18) carries a fifth entry, [4]: {n: name, f: family, sk: {skill: xp}}, so
## the person keeps their name and what they learned across the move. A member born here has only the four entries.
const M_WHO := 4
## ID-01: every member has a person id, the sixth entry [5] (World.people; never reused; a member with no carried name has {} at [4]).
## An older save has none (0): Identity.upgrade gives them, in settlement, household and member order.
const M_ID := 5
## B25R1-019 (owner: everything carries over between calculated and live): the seventh entry {hp, sk} once the member has been live:
## their health (NPC.hp) and their skills in the village's shape (skill -> xp, PAR-01). Absent: full health, no recorded skills (an
## older save, or someone never seen).
const M_BODY := 6
const JOURNAL_MAX := 100             # lines of the settlement's own journal kept (the village's log keeps 300)

## ID-01: the world's register of people, when this settlement lives in one (Regions.bind_world); not saved. Called as
## hook.call(event, info) with "birth" {sex, born, mother, father} (returns the new person's id) or "death" {id}.
var person_hook := Callable()
## X20-SETTLE-FOOD: Regions' report of a delivery (flight recorder), when it lives in a world; not saved.
var trade_hook := Callable()
## X20-SETTLE-FOOD: Regions._arrive, which closes a shipment through the transaction authority (set by Regions._add); not saved.
var arrive_hook := Callable()

static var _data := {}
static var _rules := {}               # _data.rules and _data.business_types, once loaded (the step reads them thousands of times)
static var _types := {}
static var profile := false              # diagnostics (tests/regions_sim.gd --profile): microseconds a phase of the step took
static var laps := {}
static var _pts_cache := {}
static var _val_cache := {}
var _yd := 8                         # the calendar's days in a year (Life.year_days), read at the start of each step
var _lim := 16.0                     # the village's adolescent_until, and the age old-age death starts, cached like _yd
var _mort_from := 60.0

var id := ""
var name := ""
var kind := ""
var gov_name := ""
var miles := 0
var pos := Vector2i.ZERO
var industries: Array = []
var hh: Array = []                   # households: {id, trade, adults, children, mem[[born, sex, pair, unwilling]], parents[], kids[], coins, pantry{}, credit, hungry, acc{}, alive}
var own: Dictionary = {}             # REGION-NAV-01 Q4 (option C): str(household id) -> the household's own trade, a business-shaped record {type, workers: [that household], till, stock, ...}: a self-employed crafter (see _setup_own)
var biz: Dictionary = {}             # business type -> {type, workers[], till, stock{}, reserves{}, out{}, acc{}, reserve, horses, foal, fed_miss}
var gov: Dictionary = {}             # {coins, granary{}, officials[], acc{}}
var prices: Dictionary = {}          # item -> float, the market price (today's whole-coin price is its rounding)
var flows: Dictionary = {}
var start: Dictionary = {}           # the opening books {coins, goods}
var day := -1
## Diagnostic only (MML_TRACE_TRADERS=1): print why a trader's households leave it; never changes state.
static var _trace := OS.get_environment("MML_TRACE_TRADERS") == "1"


func _ttrace(what: String, hid: int) -> void:
	if not _trace or not biz.has("merchant") or not hid in biz.merchant.workers:
		return
	var h: Dictionary = hh[hid]
	print("TTRACE day %d %s %s hid %d alive %s mem %d coins %d inc %s rate %s stay %d workers %s till %d" % [day, id, what, hid, h.alive, (h.mem as Array).size(), int(h.coins), str(h.get("inc", 0)), str(h.get("rate", 0)), int(h.get("stay", 0)), str(biz.merchant.workers), int(biz.merchant.till)])
var closed: Dictionary = {}          # SET-D: business type -> the record of a business that closed (its fields, woods, quarry reserve and horses stay; till and stock were handed on)
var dev: Dictionary = {"seen": {}, "streak": {}}             # SET-D: {seen: {item: unmet units at the last weekly look}, streak: {business type: weeks of sustained unmet demand}}
var tax: Dictionary = {}             # DVW-B5: the tax band and any announced change (TaxPolicy), this settlement's own; empty until the first step
var journal: Array = []              # the settlement's own record: [{day, text}], oldest first (tax announcements, arrivals and departures); not the village log
var _dem: Dictionary = {}            # today's requests and offers (not saved)
var _sup: Dictionary = {}
var _offers: Dictionary = {}         # item -> [{b, n}] while the market is open
var _pcache: Dictionary = {}         # today's whole-coin prices (cleared when a day starts and when prices move)
var _avail: Dictionary = {}          # item -> units on offer in all open offers
var _toll_acc := 0.0
var _want_left: Dictionary = {}      # what the settlement still wants this visit (begin_visit)
## X20-SETTLE-FOOD: shipments this settlement's trader has bought from another settlement and awaits (the goods are in the transaction
## authority's transit custody, still the seller's, and the price in escrow, still the buyer's, until delivery: Regions.tx_ship).
## Each entry {tx (the shipment's transaction id), to (holder: "trader"), item, n, from (the seller's ref), sent, due, coins};
## at the first step on or after `due` the settlement asks for delivery (`arrive_hook`, Regions._arrive) and removes the entry once
## delivered, so a save made while it travels delivers it once after loading.
var transit: Array = []
## B25R1-018 section 5 (hamlets; docs/design/REGION_RECONSTRUCTION_B25R1.md (d), (f)): a hamlet or thorp (settlements.json "hamlet":
## true) has no trader and no officials; its elder keeps the lord's box (gov.coins: the tolls and the tax), which the elder carries to
## the lord's treasury (`lord`, a settlement id; "" no lord: no toll, no tax). `market`: where its people go to buy and sell.
## `water`: "stream" or "well"; `well`: the well registry's id once its well stands ("" not yet).
var hamlet := false
var lord := ""
var market := ""
var water := ""
var well := ""
## B25R1-019 (trips, SettlementTrips): the errands this settlement's people are on, each one walker carrying a pack of coins and
## goods that stay their owner's (a household, a business) and are counted in this settlement's books; saved.
var trips: Array = []
var trip_seq := 0
## B25R1-019: person id -> true while the member is a live NPC in the world (SettlementPeople); their own acts (a trip's
## progress, an old-age death) wait until they are folded back. Not saved: a save folds everyone first.
var live: Dictionary = {}
var fold_hook := Callable()          # SettlementPeople.fold_id while the settlements live in a world with residents made live; not saved


# ------------------------------------------------------------------ data ----------------
static func data() -> Dictionary:
	if _data.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string("res://data/settlements.json"))
		assert(d is Dictionary, "bad data file settlements.json")
		_data = d
		_rules = d.rules
		_types = d.business_types
	return _data


static func rules() -> Dictionary:
	data()
	return _rules


static func btype(t: String) -> Dictionary:
	return _types.get(t, {})


static func _add(d: Dictionary, k: String, n: int) -> void:
	if n != 0:
		d[k] = int(d.get(k, 0)) + n
		if int(d[k]) == 0:
			d.erase(k)


## Take up to `n` of `k` from `d`; returns how many were taken.
static func _take(d: Dictionary, k: String, n: int) -> int:
	var t := mini(n, int(d.get(k, 0)))
	if t > 0:
		_add(d, k, -t)
	return t


## A fractional accumulator or price rounded to a millionth (the fraction as a decimal that prints and parses back to the same
## number), so a saved and reloaded settlement is the same to the last digit and goes on exactly as the original would.
static func _q(v: float) -> float:
	return float(roundi(v * 1000000.0)) / 1000000.0


static func _pts(item: String) -> float:
	if not _pts_cache.has(item):
		_pts_cache[item] = NPCBrain.food_points(item)
	return _pts_cache[item]


static func _val(item: String) -> float:
	if not _val_cache.has(item):
		_val_cache[item] = float(GameData.value(item))
	return _val_cache[item]


# ------------------------------------------------------------------ making ----------------
## A settlement as the data describes it, its people and stocks drawn once from the world seed.
static func create(spec: Dictionary, world_seed: int, index: int) -> OffMapSettlement:
	var s := OffMapSettlement.new()
	s.id = str(spec.id)
	s.name = str(spec.name)
	s.kind = str(spec.kind)
	s.miles = int(spec.miles)
	s.pos = Vector2i(int(spec.get("x", 0)), s.miles * int(data().tiles_per_mile))
	if RegionGeo.has_anchor(s.id):                   # B25R1-018 (overworld GEN_VERSION 4): the region layout's anchor, from the village's centre
		var v: Dictionary = RegionGeo.data().village
		s.pos = RegionGeo.anchor(s.id) - Vector2i(int(v.x), int(v.y))
	s.industries = (spec.get("industries", []) as Array).duplicate()
	s.gov_name = str(spec.government.name)
	s.hamlet = bool(spec.get("hamlet", false))
	s.lord = str(spec.government.get("lord", ""))
	s.market = str(spec.get("market", ""))
	s.water = str(spec.get("water", ""))
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed * 7919 + (index + 1) * 104729 + 17
	var trades: Dictionary = spec.trades
	var tids := trades.keys()
	tids.sort()
	var pantry_per := int(GameData.b("start_household_wheat_per_member"))
	for t in tids:
		for k in int(trades[t]):
			var adults := 1 + (1 if rng.randf() < 0.6 else 0)
			var children := rng.randi_range(0, 3) if adults == 2 else rng.randi_range(0, 1)
			var h := {"id": s.hh.size(), "trade": t, "adults": adults, "children": children,
				"coins": rng.randi_range(int(data().rules.household_coins[0]), int(data().rules.household_coins[1])), "pantry": {"wheat": pantry_per * (adults + children)},
				"credit": 0.0, "hungry": 0, "acc": {}, "alive": true, "inc": 0, "stay": 0, "low": 0, "rate": 0.0, "landless": 0}
			s.hh.append(h)
	var quarry_out: Dictionary = spec.get("quarry", {})
	var reserves: Dictionary = spec.get("reserves", {})
	var tills: Dictionary = spec.get("tills", {})
	var starts: Dictionary = spec.get("start", {})
	for h in s.hh:
		if h.trade == "official":
			continue
		var bt: String = TRADE_BIZ[h.trade]
		if not s.biz.has(bt):
			var T := btype(bt)
			var b := {"type": bt, "workers": [], "till": int(tills.get(bt, int(data().rules.business_till))), "stock": {}, "reserves": {},
				"out": (T.get("out", {}) as Dictionary).duplicate(), "acc": {}, "reserve": int(T.get("reserve", 12)),
				"horses": 0, "foal": 0, "fed_miss": 0, "paid": 0, "week": 0, "rate": 0.0, "idle": 0}
			if bt == "quarry":
				b.out = quarry_out.duplicate()
				for k in reserves:
					b.reserves[k] = int(reserves[k])
			for k in starts.get(bt, {}):
				b.stock[k] = int(starts[bt][k])
			if bt == "merchant":
				b.reserve = int(float(b.till) * 0.85)         # a trader keeps its trading capital; only the margin above it is paid out
			if bt == "farm":
				b.horses = int(spec.get("horses", 0))          # the settlement's working horses (the traders lead them to the road)
			s.biz[bt] = b
		s.biz[bt].workers.append(h.id)
	for t in s.biz:                                   # every trade starts with the tools it wants in hand
		var T := btype(t)
		for tool in T.get("tools", {}):
			_add(s.biz[t].stock, tool, s._tool_stock(T, tool, s.biz[t].workers.size()))
	s.gov = {"coins": int(spec.government.coins), "granary": {}, "officials": [], "acc": {}}
	for k in spec.get("granary", {}):                 # B25R1-018: a hamlet's store of the stone and logs its well is built of
		s.gov.granary[str(k)] = int(spec.granary[k])
	for h in s.hh:
		if h.trade == "official":
			s.gov.officials.append(h.id)
	s._yd = Life.year_days()
	s._lim = float(Life.cfg().adolescent_until)
	s._mort_from = float(Life.cfg().mortality_from)
	var arng := RandomNumberGenerator.new()          # ages have their own stream: the draws above (and so every founding number) are unchanged
	arng.seed = world_seed * 7919 + (index + 1) * 104729 + 31
	for h in s.hh:
		s._seed_ages(h, arng, 0)
	s.flows = _blank_flows()
	s._setup_own(spec, world_seed, index)
	s.flows.horses_start = s.horses()
	s.start = {"coins": s.coins(), "goods": s.goods()}
	return s


static func _blank_flows() -> Dictionary:
	var f := {}
	for k in FLOW_GOODS:
		f[k] = {}
	for k in FLOW_COUNTS:
		f[k] = 0
	return f


# ------------------------------------------------------------------ people (REG-DEMO-01) ----------------
## Give a household's `adults` and `children` ages, as Life.seed_population does for the village (same start ranges): a couple is a
## woman and a man (his age follows hers), the one adult of a household is a woman or a man by a coin, the mother of children is
## 28-42 (inside the start range), children are start_child_age years old but 16 years younger than their mother. `ref` is the
## settlement day the ages are measured at (0 at founding, the saved day for an older save without ages).
func _seed_ages(h: Dictionary, rng: RandomNumberGenerator, ref: int) -> void:
	var c: Dictionary = Life.cfg()
	var yd := Life.year_days()
	var a_lo := float(c.start_adult_age[0])
	var a_hi := float(c.start_adult_age[1])
	var kids := int(h.children)
	var mem: Array = []
	var anchor := 0.0
	if int(h.adults) >= 2:
		anchor = rng.randf_range(maxf(a_lo, 28.0), minf(a_hi, 42.0)) if kids > 0 else rng.randf_range(a_lo, a_hi)
		var man := clampf(anchor + rng.randf_range(-4.0, 8.0), a_lo, a_hi)
		mem.append([ref - roundi(anchor * yd), 1, 1, _unwilling(rng)])
		mem.append([ref - roundi(man * yd), 0, 1, _unwilling(rng)])
		for k in int(h.adults) - 2:
			mem.append([ref - roundi(rng.randf_range(a_lo, a_hi) * yd), rng.randi_range(0, 1), 0, _unwilling(rng)])
	elif int(h.adults) == 1:
		anchor = rng.randf_range(maxf(a_lo, 28.0), minf(a_hi, 42.0)) if kids > 0 else rng.randf_range(a_lo, a_hi)
		mem.append([ref - roundi(anchor * yd), rng.randi_range(0, 1), 0, _unwilling(rng)])
	var c_lo := float(c.start_child_age[0])
	for k in kids:
		var top := maxf(c_lo, minf(float(c.start_child_age[1]), anchor - 16.0)) if anchor > 0.0 else float(c.start_child_age[1])
		mem.append([ref - roundi(rng.randf_range(c_lo, top) * yd), rng.randi_range(0, 1), 0, _unwilling(rng)])
	h.mem = mem
	h.parents = []
	h.kids = []
	_recount(h)


## The village's share of people who do not mean to marry (balance.json relations.unwilling_percent).
static func _unwilling(rng: RandomNumberGenerator) -> int:
	return 1 if rng.randf() * 100.0 < float(GameData.b("relations").unwilling_percent) else 0


## A reproducible number in [0, 1) from three integers (no random stream to save: a settlement's days stay the same after a reload).
static func _roll(a: int, b: int, c: int) -> float:
	var x: int = a * 0x2545F4914F6CDD1D + b * 0x1E3779B97F4A7C15 + c * 0x2A09E667F3BCC909 + 0x1234567
	x = x ^ ((x >> 29) & 0x7FFFFFFFF)
	x = x * 0x2127599BF4325C37
	x = x ^ ((x >> 32) & 0xFFFFFFFF)
	x = x * 0x165667B19E3779F9
	x = x ^ ((x >> 28) & 0xFFFFFFFFF)
	return float((x >> 20) & 0xFFFFFF) / 16777216.0


## The id of a member (0: none yet).
static func member_id(m: Array) -> int:
	return int(m[M_ID]) if m.size() > M_ID else 0


static func set_member_id(m: Array, id: int) -> void:
	while m.size() < M_WHO:
		m.append(0)
	if m.size() == M_WHO:
		m.append({})
	while m.size() < M_ID:
		m.append({})
	if m.size() == M_ID:
		m.append(id)
	else:
		m[M_ID] = id


## Whether the member carries a name (they came from the village).
static func has_who(m: Array) -> bool:
	return m.size() > M_WHO and m[M_WHO] is Dictionary and not (m[M_WHO] as Dictionary).is_empty()


static func who_of(m: Array) -> Dictionary:
	return m[M_WHO] if has_who(m) else {}


static func body_of(m: Array) -> Dictionary:
	return m[M_BODY] if m.size() > M_BODY and m[M_BODY] is Dictionary else {}


static func set_body(m: Array, b: Dictionary) -> void:
	while m.size() < M_WHO:
		m.append(0)
	while m.size() < M_ID:
		m.append({})
	if m.size() == M_ID:
		m.append(0)
	if m.size() == M_BODY:
		m.append(b)
	else:
		m[M_BODY] = b


## B25R1-019: a live member leaves the world before their household's record changes under them (a move, a loss): SettlementPeople
## folds them back first (fold_hook, (person id) -> void), so nothing they carry or know is lost and no NPC is left without a record.
func _fold_live(ms: Array) -> void:
	if live.is_empty() or not fold_hook.is_valid():
		return
	for m in ms.duplicate():
		if live.has(member_id(m)):
			fold_hook.call(member_id(m))


## A person is born here: the world gives them their id (0 in a settlement that lives outside a world).
func _new_person(sex: int, mother: Array, father: Array) -> int:
	if not person_hook.is_valid():
		return 0
	return int(person_hook.call("birth", {"sex": sex, "born": day, "settlement": id, "mother": member_id(mother) if not mother.is_empty() else -1,
		"father": member_id(father) if not father.is_empty() else -1}))


## A member dies: the register learns it. Nothing else changes.
func _died(m: Array, cause := "") -> void:
	if person_hook.is_valid() and member_id(m) > 0:
		person_hook.call("death", {"id": member_id(m), "settlement": id, "cause": cause})     # REC-DIAG: the cause, for the record only


func _age(m: Array) -> float:
	return float(day - int(m[M_BORN])) / float(_yd)


## Adults and children counts from the members' ages (a child is under the village's adolescent_until; elders count as adults
## here, as they always did) and the couple flag cleared when the couple is not both there.
func _recount(h: Dictionary) -> void:
	var lim := _lim
	var a := 0
	var k := 0
	var f := 0
	var m := 0
	for x in h.mem:
		if _age(x) < lim:
			k += 1
		else:
			a += 1
		if int(x[M_PAIR]) == 1:
			if int(x[M_SEX]) == 1:
				f += 1
			else:
				m += 1
	if f != 1 or m != 1:
		for x in h.mem:
			x[M_PAIR] = 0
	h.adults = a
	h.children = k


func _is_adult(m: Array) -> bool:
	return _age(m) >= _lim


## The dawn of a settlement's day: ageing, old-age deaths, births to couples, new couples founding households. The village's own
## rules (balance.json life, relations) at household level; every roll is a reproducible function of (settlement, day, person).
func _life() -> void:
	_yd = Life.year_days()
	var c: Dictionary = Life.cfg()
	_lim = float(c.adolescent_until)
	_mort_from = float(c.mortality_from)
	var salt := id.hash() & 0xFFFFFF
	var n0 := hh.size()
	_old_age(salt)
	var tt := Time.get_ticks_usec() if profile else 0
	var chance := 1.0 / (float(c.birth_interval_years) * _yd)
	for i in n0:
		var h: Dictionary = hh[i]
		if h.alive:
			_try_birth(h, chance, salt)
	if profile:
		tt = _lap("life:births", tt)
	_found_household(salt)
	if profile:
		tt = _lap("life:marry", tt)


## Old-age deaths, by the village's mortality curve (Life.death_chance) rolled once a day for each member.
func _old_age(salt: int) -> void:
	for i in hh.size():
		var h: Dictionary = hh[i]
		if not h.alive:
			continue
		var dead := false
		for j in range(h.mem.size() - 1, -1, -1):
			var m: Array = h.mem[j]
			var ag := _age(m)
			var p := Life.death_chance(ag) if ag >= _mort_from and not live.has(member_id(m)) else 0.0
			if p > 0.0 and (p >= 1.0 or _roll(salt, day * 7 + 1, int(m[M_BORN]) * 64 + i) < p):
				_died(m, "old_age")
				_remove_member(h, j)
				flows.age_deaths += 1
				dead = true
		if dead:
			_after_loss(h)
		else:
			_recount(h)


func _try_birth(h: Dictionary, chance: float, salt: int) -> void:
	var c: Dictionary = Life.cfg()
	var mother: Array = []
	for m in h.mem:
		if int(m[M_PAIR]) == 1 and int(m[M_SEX]) == 1:
			mother = m
	if mother.is_empty():
		return
	var age := _age(mother)
	if age < float(c.birth_mother_min_age) or age > float(c.birth_mother_max_age):
		return
	for m in h.mem:
		if _age(m) < float(c.birth_min_gap_years):
			return
	if _roll(salt, day * 7 + 2, int(h.id)) >= chance:
		return
	if _pantry_pts(h) < float(c.birth_min_food_days) * _need_pts(h):
		return
	var sex := 1 if _roll(salt, day * 7 + 3, int(h.id)) < 0.5 else 0
	var unw := 1 if _roll(salt, day * 7 + 4, int(h.id)) * 100.0 < float(GameData.b("relations").unwilling_percent) else 0
	var father: Array = []
	for m in h.mem:
		if int(m[M_PAIR]) == 1 and int(m[M_SEX]) == 0:
			father = m
	h.mem.append([day, sex, 0, unw, {}, _new_person(sex, mother, father)])
	flows.births += 1
	_recount(h)


## Take member `j` out of a household (death); the caller then runs _after_loss.
func _remove_member(h: Dictionary, j: int) -> void:
	var m: Array = h.mem[j]
	if live.has(member_id(m)):
		_fold_live([m])                                     # (a live member's fold may itself remove a dead NPC's record)
		j = h.mem.find(m)
		if j < 0:
			return
	h.mem.remove_at(j)
	if int(m[M_PAIR]) == 1:
		for x in h.mem:
			x[M_PAIR] = 0                                   # a couple ends when one of them dies


## After a household lost a member: when no adult is left it is closed. Its children (if any) and its coins and goods pass by the
## inheritance rule: to the nearest living kin household (the households its members founded, eldest first; then those its
## founders came from; then their other offspring: the village's order, Life.heir_of), else children go to the settlement's
## smallest living household (the village's Guardianship: kin or a household that takes them in), and with no children and no kin
## the coins and food pass to the treasury (the rule of Build 18's first settlements).
func _after_loss(h: Dictionary) -> void:
	_recount(h)
	if int(h.adults) > 0:
		return
	_ttrace("no_adult_left", int(h.id))
	_wind_up_own(h)
	var heir := _heir(h)
	if heir < 0 and not h.mem.is_empty():
		heir = _guardian(h)
	h.alive = false
	if heir < 0:
		flows.deaths += h.mem.size()                         # no household anywhere to take the children in
		for m in h.mem:
			_died(m, "no_household_left")
		h.mem = []
		gov.coins += int(h.coins)
		h.coins = 0
		for k in h.pantry:
			_add(gov.granary, k, int(h.pantry[k]))
		h.pantry = {}
		return
	var e: Dictionary = hh[heir]
	e.coins += int(h.coins)
	h.coins = 0
	for k in h.pantry:
		_add(e.pantry, k, int(h.pantry[k]))
	h.pantry = {}
	e.credit = _q(float(e.credit) + float(h.credit))
	h.credit = 0.0
	if not h.mem.is_empty():
		flows.orphans_fostered += h.mem.size()
		e.mem.append_array(h.mem)
		h.mem = []
		_recount(e)
	flows.inheritances += 1


func _heir(h: Dictionary) -> int:
	var order: Array = []
	order.append_array(h.kids)
	order.append_array(h.parents)
	for p in h.parents:
		order.append_array(hh[int(p)].kids)
	for i in order:
		var k := int(i)
		if k != int(h.id) and hh[k].alive and int(hh[k].adults) > 0:
			return k
	return -1


func _guardian(h: Dictionary) -> int:
	var best := -1
	for e in hh:
		if e.alive and int(e.id) != int(h.id) and int(e.adults) > 0 and (best < 0 or e.mem.size() < hh[best].mem.size()):
			best = int(e.id)
	return best


## Two grown, unpartnered people of different, unrelated households who are of an age to marry (the village's partner_min_age,
## partner_max_age, partner_max_gap), have been of age marry_min_days and do not refuse (unwilling_percent) marry and found a
## household of their own: one pair a day at most. They leave with an equal share of their households' coins and pantries (all of
## it when it is the last of the household), take up the man's trade (an official's household, a farm's) and join its
## business. The off-map has no houses: a new household needs none (lighter detail; provisional).
func _found_household(salt: int) -> void:
	var c: Dictionary = Life.cfg()
	var lo := float(c.partner_min_age)
	var hi := float(c.partner_max_age)
	var wait := lo * _yd + float(GameData.b("relations").marry_min_days)
	var women: Array = []
	var men: Array = []
	for h in hh:
		if not h.alive:
			continue
		for j in h.mem.size():
			var m: Array = h.mem[j]
			var a := _age(m)
			if int(m[M_PAIR]) == 1 or int(m[M_UNWILLING]) == 1 or a < lo or a > hi or float(day - int(m[M_BORN])) < wait:
				continue
			if int(h.adults) < 2 and int(h.children) > 0:
				continue                                            # the only adult of a household with children does not leave it
			if h.mem.size() == 1 and not _may_close(h):
				continue
			(women if int(m[M_SEX]) == 1 else men).append([int(h.id), j])
	for w in women:
		var wh: Dictionary = hh[w[0]]
		var wa := _age(wh.mem[w[1]])
		for mm in men:
			var mh: Dictionary = hh[mm[0]]
			if int(mh.id) == int(wh.id) or _related(wh, mh) or absf(_age(mh.mem[mm[1]]) - wa) > float(c.partner_max_gap):
				continue
			_marry(wh, int(w[1]), mh, int(mm[1]))
			return


## A one-person household may leave to marry only if no post is left empty: not an official's, and its business keeps a household.
func _may_close(h: Dictionary) -> bool:
	if str(h.trade) == "official" or not TRADE_BIZ.has(str(h.trade)):
		return false
	return biz.has(TRADE_BIZ[h.trade]) and _workers(biz[TRADE_BIZ[h.trade]]) >= 2


func _related(a: Dictionary, b: Dictionary) -> bool:
	if a.parents.has(int(b.id)) or b.parents.has(int(a.id)):
		return true
	for p in a.parents:
		if b.parents.has(p):
			return true
	return false


func _marry(wh: Dictionary, wj: int, mh: Dictionary, mj: int) -> void:
	var wm: Array = wh.mem[wj]
	var mm: Array = mh.mem[mj]
	var trade := str(mh.trade)
	var bt := ""
	if trade != "official" and TRADE_BIZ.has(trade) and biz.has(TRADE_BIZ[trade]):
		bt = TRADE_BIZ[trade]
	else:
		bt = "farm" if biz.has("farm") else str(biz.keys()[0])
		trade = _trade_of(bt)
	var h := {"id": hh.size(), "trade": trade, "adults": 2, "children": 0, "coins": 0, "pantry": {}, "credit": 0.0, "hungry": 0, "acc": {},
		"alive": true, "inc": 0, "stay": 0, "mem": [wm, mm], "parents": [int(wh.id), int(mh.id)], "kids": [], "low": 0, "rate": 0.0, "landless": 1}
	wm[M_PAIR] = 1
	mm[M_PAIR] = 1
	for src in [[wh, wj], [mh, mj]]:
		var o: Dictionary = src[0]
		var n: int = o.mem.size()
		var cs: int = int(o.coins) if n == 1 else int(o.coins) / n
		o.coins -= cs
		h.coins += cs
		for k in o.pantry.keys():
			var q: int = int(o.pantry[k]) if n == 1 else int(o.pantry[k]) / n
			if q > 0:
				_take(o.pantry, k, q)
				_add(h.pantry, k, q)
		if n == 1:
			h.credit = _q(float(h.credit) + float(o.credit))
			o.credit = 0.0
		o.mem.remove_at(int(src[1]))
		o.kids.append(h.id)
	hh.append(h)
	biz[bt].workers.append(h.id)
	flows.households_formed += 1
	for o in [wh, mh]:
		if o.mem.is_empty():                                         # the last of a household goes with the couple: it closes, nothing left behind
			_wind_up_own(o)
			_ttrace("emptied_by_marriage_into_" + bt, int(o.id))
			o.alive = false
			_recount(o)
			for k in o.pantry:
				_add(h.pantry, k, int(o.pantry[k]))
			o.pantry = {}
			h.coins += int(o.coins)
			o.coins = 0
		else:
			_recount(o)
	_recount(h)


# ------------------------------------------------------------------ books ----------------
func coins() -> int:
	var n := int(gov.coins)
	for h in hh:
		n += int(h.coins)
	for t in biz:
		n += int(biz[t].till) + consign_due_coins(biz[t])     # B25-ECON-P6: pay a trader holds for another place's sources
	n += consign_due_coins(gov)
	for k in own:
		n += int(own[k].till)
	for t in trips:
		n += int(t.coins)                            # B25R1-019: coins in a walker's pack are still their owner's
	return n


func goods() -> Dictionary:
	var g := {}
	for h in hh:
		for k in h.pantry:
			_add(g, k, int(h.pantry[k]))
	for t in biz:
		for k in biz[t].stock:
			_add(g, k, int(biz[t].stock[k]))
	for o in own:
		for k in own[o].stock:
			_add(g, k, int(own[o].stock[k]))
	for k in gov.granary:
		_add(g, k, int(gov.granary[k]))
	for t in trips:
		for k in t.pack:
			_add(g, k, int(t.pack[k]))
	return g


func horses() -> int:
	return (int(biz.farm.horses) if biz.has("farm") else 0) + int(closed.get("farm", {}).get("horses", 0))


func population() -> int:
	var n := 0
	for h in hh:
		if h.alive:
			n += int(h.adults) + int(h.children)
	return n


func households() -> int:
	var n := 0
	for h in hh:
		if h.alive:
			n += 1
	return n


func treasury() -> int:
	return int(gov.coins)


func trader() -> Dictionary:
	return biz.get("merchant", {})


## B25R1-018: a hamlet with no lord collects no toll and no tax (Rushford, Ashcombe: Upmeads has no lord's officials in the game).
func untaxed() -> bool:
	return hamlet and lord == ""


## "" when every coin and good is accounted for by a flow line, else what is not.
func audit() -> String:
	var f := flows
	var want_c: int = int(start.coins) + int(f.coins_from_village) - int(f.coins_to_village) + int(f.road_coins_in) \
		- int(f.road_coins_out) + int(f.migrated_in) + int(f.regional_coins_in) - int(f.regional_coins_out) \
		+ int(f.outside_coins_in) - int(f.outside_coins_out)
	if want_c != coins():
		return "%s coins %d, books say %d" % [id, coins(), want_c]
	var have := goods()
	var ids := {}
	for k in start.goods:
		ids[k] = true
	for k in have:
		ids[k] = true
	for k in ids:
		var w := int(start.goods.get(k, 0)) + int(f.produced.get(k, 0)) - int(f.used.get(k, 0)) + int(f.from_village.get(k, 0)) \
			- int(f.to_village.get(k, 0)) + int(f.road_in.get(k, 0)) - int(f.road_out.get(k, 0)) \
			+ int(f.regional_in.get(k, 0)) - int(f.regional_out.get(k, 0)) + int(f.outside_in.get(k, 0)) - int(f.outside_out.get(k, 0))
		if w != int(have.get(k, 0)):
			return "%s %s %d, books say %d" % [id, k, int(have.get(k, 0)), w]
	var hs := int(f.horses_start) + int(f.horses_foaled) - int(f.horses_died) - int(f.horses_sold)
	if hs != horses():
		return "%s horses %d, books say %d" % [id, horses(), hs]
	return ""


# ------------------------------------------------------------------ prices ----------------
func price(item: String) -> int:
	var p = _pcache.get(item)
	if p == null:
		p = maxi(1, roundi(float(prices.get(item, _val(item)))))
		_pcache[item] = p
	return p


func _need_pts(h: Dictionary) -> float:
	return (float(h.adults) + float(h.children) * float(GameData.b("child_food_factor"))) * 24.0 * float(GameData.b("hunger_per_hour"))


## What a day's food costs a household at today's price of wheat, the cheapest staple.
func _day_food_cost(h: Dictionary) -> int:
	return ceili(_need_pts(h) / _pts("wheat")) * price("wheat")


func _pantry_pts(h: Dictionary) -> float:
	var p := 0.0
	for f in _rules.foods:
		p += float(h.pantry.get(f, 0)) * _pts(f)
	return p + float(h.credit)


func _update_prices() -> void:
	var step := float(_rules.price_step)
	var lo := float(GameData.b("price_min"))
	var hi := float(GameData.b("price_max"))
	var ids := {}
	for k in _dem:
		ids[k] = true
	for k in _sup:
		ids[k] = true
	var keys := ids.keys()
	keys.sort()
	for k in keys:
		var d := float(_dem.get(k, 0))
		var s := float(_sup.get(k, 0))
		var v := float(_val(k))
		var p := float(prices.get(k, v)) * (1.0 + step * (d - s) / maxf(1.0, maxf(d, s)))
		prices[k] = _q(clampf(p, v * lo, v * hi))


# ------------------------------------------------------------------ the day ----------------
func step_day(d: int) -> void:
	data()
	day = d
	_dem = {}
	_sup = {}
	_pcache = {}
	var t0 := Time.get_ticks_usec() if profile else 0
	_consign_return()                      # B25-ECON-P4: what the trader carried on consignment and did not sell goes home first
	if not transit.is_empty():
		_deliver()
	_market()
	_imported_left()
	if profile:
		t0 = _lap("market", t0)
	_produce()
	if profile:
		t0 = _lap("produce", t0)
	_pay_wages()
	_pay_own()
	_taxes_and_officials()
	if profile:
		t0 = _lap("wages+tax", t0)
	_eat()
	_stable()
	if profile:
		t0 = _lap("eat", t0)
	_life()
	if profile:
		t0 = _lap("life", t0)
	_update_prices()
	_pcache = {}
	_move_jobs()
	if profile:
		t0 = _lap("prices", t0)


func _lap(what: String, t0: int) -> int:
	var t := Time.get_ticks_usec()
	laps[what] = int(laps.get(what, 0)) + t - t0
	return t


## A line in the settlement's own journal (never the village log).
func note(text: String) -> void:
	journal.append({"day": day, "text": text})
	if journal.size() > JOURNAL_MAX:
		journal.pop_front()


# --- market
func _keep(b: Dictionary) -> Dictionary:
	var keep := {}
	var T := btype(b.type)
	var n := _workers(b)
	for rid in T.get("runs", {}):
		var r: Dictionary = GameData.recipes[rid]
		for i in r["in"]:
			keep[i] = int(keep.get(i, 0)) + ceili(float(T.runs[rid]) * n * int(r["in"][i]) * float(_rules.input_days_ahead))
	for tool in T.get("tools", {}):
		keep[tool] = int(keep.get(tool, 0)) + _tool_stock(T, tool, n)
	if b.type == "merchant":
		for i in _rules.carry_keep:
			keep[i] = int(_rules.carry_keep[i])
	return keep


## The tools of one kind a business keeps in hand: one, or the wear of twenty days if that is more.
func _tool_stock(T: Dictionary, tool: String, workers: int) -> int:
	return maxi(1, ceili(float(T.tools[tool]) * float(workers) * 20.0)) if workers > 0 else 0


## REG-X20-D1 (owner 2026-10-27): leaving is each household's own decision, so two households in the same plight may choose
## differently. A household's patience is how many hungry days it bears before it will go: 1 to `move_patience_days_max`, its
## own, drawn once from the settlement and the household (reproducible, saved by being derived; no RNG state).
func move_patience(h: Dictionary) -> int:
	var top := maxi(1, int(_rules.get("move_patience_days_max", 1)))
	return 1 + int(_roll(id.hash() & 0xFFFFFF, int(h.id), 21) * float(top))


func _workers(b: Dictionary) -> int:
	var n := 0
	for i in b.workers:
		if hh[i].alive:
			n += 1
	return n


func _open_offers() -> void:
	_offers = {}
	_avail = {}
	var types := biz.keys()
	types.sort()
	var rot := day % maxi(1, types.size())
	var sellers: Array = []
	for k in types.size():
		sellers.append(biz[types[(k + rot) % types.size()]])
	for k in _own_ids():
		sellers.append(own[k])                     # REGION-NAV-01 Q4: a self-employed crafter sells in the same market
	for b: Dictionary in sellers:
		var keep := _keep(b)
		var items: Array = b.stock.keys()
		items.sort()
		for item in items:
			var n := int(b.stock[item]) - int(keep.get(item, 0)) - consigned_in(b, str(item))   # B25-ECON-P4/P6: consigned goods are the village's to buy only
			if n > 0:
				if not _offers.has(item):
					_offers[item] = []
				_offers[item].append({"b": b, "n": n})
				_sup[item] = int(_sup.get(item, 0)) + n
				_avail[item] = int(_avail.get(item, 0)) + n


## Buy up to `want` of `item` for the buyer (its purse `key` pays) into `store` (null: used at once). Returns the units bought.
func _purchase(buyer: Dictionary, key: String, store, item: String, want: int, budget := -1, self_b = null) -> int:
	if want <= 0:
		return 0
	var p := price(item)
	var cash := int(buyer[key]) if budget < 0 else mini(int(buyer[key]), budget)
	var n := mini(want, cash / p)
	_dem[item] = int(_dem.get(item, 0)) + n                  # what it would buy with the coins it has: a price follows paying demand
	if int(_avail.get(item, 0)) <= 0:
		_add(flows.unmet, item, want)
		return 0
	var got := 0
	for o in _offers.get(item, []):
		if got >= n:
			break
		if o.b == self_b:
			continue
		var take := mini(n - got, int(o.n))
		if take <= 0:
			continue
		o.n -= take
		_avail[item] = int(_avail.get(item, 0)) - take
		_take(o.b.stock, item, take)
		if store != null:
			_add(store, item, take)
		else:
			_add(flows.used, item, take)
		var toll := _toll(take * p)
		o.b.till += take * p - toll
		gov.coins += toll
		buyer[key] = int(buyer[key]) - take * p
		got += take
	if want > got:
		_add(flows.unmet, item, want - got)
	return got


## The market toll (or the abbey's tithe) on a sale of `amount` coins: whole coins as the fractions add up.
func _toll(amount: int) -> int:
	if untaxed():
		return 0                                     # B25R1-018: a hamlet with no lord pays no toll
	_toll_acc = _q(_toll_acc + float(amount) * float(_rules.toll_rate))
	var t := int(floor(_toll_acc + 1e-9))
	_toll_acc = _q(_toll_acc - float(t))
	flows.tolls += t
	return mini(t, amount)


func _market() -> void:
	var t0 := Time.get_ticks_usec() if profile else 0
	_open_offers()
	if profile:
		t0 = _lap("m:offers", t0)
	var n := hh.size()
	var rot := day % maxi(1, n)
	for k in n:
		var h: Dictionary = hh[(k + rot) % n]
		if h.alive and (day + int(h.id)) % int(_rules.shop_every_days) == 0:        # market days: each household every other day
			_household_buys(h)
	if profile:
		t0 = _lap("m:households", t0)
	_relief()
	_upkeep()
	if profile:
		t0 = _lap("m:relief+upkeep", t0)
	var types := biz.keys()
	types.sort()
	for t in types:
		_business_buys(biz[t])
	for k in _own_ids():
		_business_buys(own[k])                     # REGION-NAV-01 Q4: a crafter buys its inputs and tools from its own working purse
	if profile:
		t0 = _lap("m:businesses", t0)
	_trader_collects()
	if profile:
		t0 = _lap("m:trader", t0)


func _household_buys(h: Dictionary) -> void:
	var need := _need_pts(h)
	var want := float(_rules.food_days_ahead) * need - _pantry_pts(h)
	# a share of the food is prepared food from the cookshop (a household's own hearth does the rest), cheapest first
	var prep := want * PREPARED_SHARE
	_buy_food(h, prep, PREPARED)
	_buy_food(h, want - prep + maxf(0.0, prep - 0.0) * 0.0, _rules.foods)
	var members := float(h.adults) + float(h.children)
	var items: Array = _rules.basket.keys()
	items.sort()
	for item in items:
		h.acc[item] = _q(minf(4.0, float(h.acc.get(item, 0.0)) + float(_rules.basket[item]) * members))
		var n := int(floor(float(h.acc[item]) + 1e-9))
		if n > 0:
			var got := _purchase(h, "coins", null, item, n)
			h.acc[item] = _q(float(h.acc[item]) - float(got))
	# a household with savings above what it keeps spends some of it on the comforts of the settlement's market
	var keep_cash := int(_rules.keep_cash_base) + int(_rules.keep_cash_per_member) * int(members)
	var budget := int(float(int(h.coins) - keep_cash) * float(_rules.spend_rate))
	var wish: Array = _rules.wish
	var left := int(_rules.wishes_a_day)
	for k in wish.size():
		if budget <= 0 or left <= 0:
			break
		var item: String = wish[(k + day + int(h.id)) % wish.size()]
		if price(item) <= budget:
			var before := int(h.coins)
			if _purchase(h, "coins", null, item, 1) > 0:
				budget -= before - int(h.coins)
				left -= 1


## Food worth `pts` points from the listed foods on offer, the cheapest per point first, while the purse lasts.
func _buy_food(h: Dictionary, pts: float, foods: Array) -> void:
	var guard := 0
	while pts > 0.5 and guard < 6:
		guard += 1
		var best := ""
		var best_cost := INF
		for f in foods:
			if int(_avail.get(f, 0)) > 0 and price(f) <= int(h.coins):
				var cost := float(price(f)) / maxf(1.0, _pts(f))
				if cost < best_cost:
					best_cost = cost
					best = f
		if best == "":
			return
		var units := ceili(pts / _pts(best))
		var got := _purchase(h, "coins", h.pantry, best, units)
		if got == 0:
			return
		pts -= float(got) * _pts(best)


## A household with under a day of food gets wheat the treasury buys for it, while the treasury keeps a day's wages.
func _relief() -> void:
	var floor_coins: int = int(_rules.official_wage) * gov.officials.size() + 2
	for h in hh:
		if not h.alive:
			continue
		var need := _need_pts(h)
		if _pantry_pts(h) >= need or int(gov.coins) <= floor_coins:
			continue
		var units := ceili((2.0 * need - _pantry_pts(h)) / _pts("wheat"))
		var got := _purchase(gov, "coins", h.pantry, "wheat", units, int(gov.coins) - floor_coins)
		flows.relief_units += got


func _obligations() -> int:
	return int(_rules.official_wage) * gov.officials.size() + 2


func _upkeep() -> void:
	var reserve := _obligations() * int(_rules.gov_reserve_days)
	var budget := int(maxf(0.0, float(int(gov.coins) - reserve)) * float(_rules.gov_budget_share))
	var items: Array = _rules.gov_upkeep.keys()
	items.sort()
	for item in items:
		gov.acc[item] = _q(minf(6.0, float(gov.acc.get(item, 0.0)) + float(_rules.gov_upkeep[item]) * float(households())))
		var n := int(floor(float(gov.acc[item]) + 1e-9))
		if n > 0 and budget > 0:
			var before := int(gov.coins)
			var got := _purchase(gov, "coins", null, item, n, budget)
			budget -= before - int(gov.coins)
			gov.acc[item] = _q(float(gov.acc[item]) - float(got))


func _business_buys(b: Dictionary) -> void:
	if b.type == "merchant":
		return                                   # a trader buys leftovers (_trader_collects) and the village's goods; its horses' feed is bought there
	var short := _inputs_short(b)
	var items: Array = short.keys()
	items.sort()
	for item in items:
		_purchase(b, "till", b.stock, item, int(short[item]), -1, b)


## The inputs and tools a business will buy today and how many of each (item -> units short): what its workers' recipes and
## tools take for `input_days_ahead` days that its stock does not hold. What _business_buys buys, and what the cash it needs
## for them is reckoned from (_expense_due).
func _inputs_short(b: Dictionary) -> Dictionary:
	var out := {}
	if b.type == "merchant":
		return out
	var T := btype(b.type)
	var n := _workers(b)
	if n == 0:
		return out
	var need := {}
	for rid in T.get("runs", {}):
		var r: Dictionary = GameData.recipes[rid]
		for i in r["in"]:
			if not (T.get("out", {}) as Dictionary).has(i):
				need[i] = int(need.get(i, 0)) + ceili(float(T.runs[rid]) * n * int(r["in"][i]) * float(_rules.input_days_ahead))
	for tool in T.get("tools", {}):
		need[tool] = int(need.get(tool, 0)) + _tool_stock(T, tool, n)
	var items: Array = need.keys()
	items.sort()
	for item in items:
		# an input a recipe of its own makes is not bought (the smith's iron bars for its forging)
		var made := false
		for rid in T.get("runs", {}):
			if (GameData.recipes[rid].out as Dictionary).has(item):
				made = true
		var short := int(need[item]) - int(b.stock.get(item, 0))
		if short > 0 and (not made or int(b.stock.get(item, 0)) < int(need[item]) / 2):
			out[item] = short
	return out


## The trader buys what the producers have left over of the goods it carries (ore, stone, bars, seed, medicine), at the
## price the glut left them, from its own till above its floor.
func _trader_collects() -> void:
	var m := trader()
	if m.is_empty():
		return
	var items: Array = _rules.carry.keys()
	items.sort()
	var share := float(_rules.trader_pays_share)
	for item in items:
		var room := int(_rules.carry[item]) - int(m.stock.get(item, 0))
		var p := maxi(1, roundi(float(price(item)) * share))
		for o in _offers.get(item, []):
			if room <= 0:
				break
			if o.b == m:
				continue
			var cash := int(m.till) - maxi(int(_rules.trader_reserve_floor), int(m.reserve))
			var take := mini(mini(room, int(o.n)), cash / p)
			if take <= 0:
				continue
			o.n -= take
			_avail[item] = int(_avail.get(item, 0)) - take
			_take(o.b.stock, item, take)
			_add(m.stock, item, take)
			o.b.till += take * p
			m.till -= take * p
			room -= take


# --- production
func _produce() -> void:
	var types := biz.keys()
	types.sort()
	var makers: Array = []
	for t in types:
		makers.append(biz[t])
	for k in _own_ids():
		makers.append(own[k])                      # REGION-NAV-01 Q4: a crafter works by the same rules, one household's hands
	for b: Dictionary in makers:
		var T := btype(str(b.type))
		var n := _workers(b)
		if n == 0:
			continue
		var cap := int(T.get("cap", 150))
		var pace := 1.0
		for item in (b.out as Dictionary).keys():
			b.acc[item] = _q(float(b.acc.get(item, 0.0)) + float(b.out[item]) * n * pace)
			var q := int(floor(float(b.acc[item]) + 1e-9))
			q = mini(q, maxi(0, cap - int(b.stock.get(item, 0))))
			if b.reserves.has(item):
				q = mini(q, int(b.reserves[item]))
			if q > 0:
				b.acc[item] = _q(float(b.acc[item]) - float(q))
				if b.reserves.has(item):
					b.reserves[item] = int(b.reserves[item]) - q
				_add(b.stock, item, q)
				_add(flows.produced, item, q)
			else:
				b.acc[item] = minf(float(b.acc[item]), 1.0)
		var runs: Dictionary = T.get("runs", {})
		var rids := runs.keys()
		for rid in rids:
			var key: String = "r:" + rid
			b.acc[key] = _q(minf(float(b.acc.get(key, 0.0)) + float(runs[rid]) * n * pace, float(runs[rid]) * n * 2.0 + 1.0))
			var r: Dictionary = GameData.recipes[rid]
			while float(b.acc[key]) >= 1.0 - 1e-9:
				if not _run_recipe(b, T, r):
					break
				b.acc[key] = _q(float(b.acc[key]) - 1.0)
			if float(b.acc[key]) >= 1.0:
				b.acc[key] = 0.0                    # no inputs or no room: the day's work is not saved up
		_wear_tools(b, T, n)


func _wear_tools(b: Dictionary, T: Dictionary, n: int) -> void:
	for tool in T.get("tools", {}):
		var key: String = "t:" + tool
		b.acc[key] = _q(minf(float(b.acc.get(key, 0.0)) + float(T.tools[tool]) * n, 2.0))
		if float(b.acc[key]) >= 1.0 and int(b.stock.get(tool, 0)) > 0:
			_take(b.stock, tool, 1)
			_add(flows.used, tool, 1)
			b.acc[key] = _q(float(b.acc[key]) - 1.0)


func _run_recipe(b: Dictionary, T: Dictionary, r: Dictionary) -> bool:
	var targets: Dictionary = T.get("targets", {})
	for o in r.out:
		if int(b.stock.get(o, 0)) >= int(targets.get(o, 60)):
			return false
	for i in r["in"]:
		if int(b.stock.get(i, 0)) < int(r["in"][i]):
			return false
	for i in r["in"]:
		_take(b.stock, i, int(r["in"][i]))
		_add(flows.used, i, int(r["in"][i]))
	for o in r.out:
		_add(b.stock, o, int(r.out[o]))
		_add(flows.produced, o, int(r.out[o]))
	return true


# --- REGION-NAV-01 Q4 (owner 2026-11-03, option C): self-employed crafters
## A household working on its own account: its own trade is a business-shaped record (own[str(id)]) whose only worker is that
## household, run by the same rules as a business (production by its trade's recipes and natural outputs, _produce; inputs and
## tools bought from its own working purse, _business_buys; sales in the same market, _open_offers; the same keep), and whose
## profit is the household's living (_pay_own): not a business of the settlement, not employed by one.
##   Who: the settlement's data names some at the start (settlements.json "independent": [{trade, capital, reserves}]: a new
##     household of that trade, part of the opening books); and once a week one craft household that earns under `switch_below`
##     and has savings of at least own_start_capital, two weeks running short of work, may set up on its own (_own_week): those
##     coins become its working purse.
##     Not every worker household: one a week, by need and means.
##   Going back: one whose working purse and stock are both spent for own_fail_days rejoins its trade's business (or, with none,
##     stays and earns what it can).
##   An ended household (death with no adult, the last leaving, moving to the village, marrying in) first winds up its trade:
##     purse to its coins, stock to its pantry, so the existing rules carry them on (_wind_up_own). Nothing is created.
const OWN_TRADES := ["smith", "sawyer", "mason", "tanner", "weaver", "cook", "healer", "miner"]


func _own_ids() -> Array:
	var ks: Array = own.keys()
	ks.sort_custom(func(a, b) -> bool: return int(a) < int(b))
	return ks


func _own_record(bt: String, hid: int, till: int) -> Dictionary:
	var T := btype(bt)
	return {"type": bt, "workers": [hid], "till": till, "stock": {}, "reserves": {}, "out": (T.get("out", {}) as Dictionary).duplicate(),
		"acc": {}, "reserve": int(T.get("reserve", 12)), "horses": 0, "foal": 0, "fed_miss": 0, "paid": 0, "week": 0, "rate": 0.0,
		"idle": 0, "own": true}


## The data's self-employed crafters of a new settlement: a household each, with its working purse and the tools its trade wants.
func _setup_own(spec: Dictionary, world_seed: int, index: int) -> void:
	var list: Array = (data().get("independent", {}) as Dictionary).get(str(spec.id), [])
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed * 7919 + (index + 1) * 104729 + 9001
	for e in list:
		var t := str(e.trade)
		if not TRADE_BIZ.has(t):
			continue
		var bt: String = TRADE_BIZ[t]
		var pantry_per := int(GameData.b("start_household_wheat_per_member"))
		var adults := 1 + (1 if rng.randf() < 0.5 else 0)
		var h := {"id": hh.size(), "trade": t, "adults": adults, "children": 0,
			"coins": rng.randi_range(int(data().rules.household_coins[0]), int(data().rules.household_coins[1])),
			"pantry": {"wheat": pantry_per * adults}, "credit": 0.0, "hungry": 0, "acc": {}, "alive": true, "inc": 0, "stay": 0,
			"low": 0, "rate": 0.0, "landless": 0}
		hh.append(h)
		_seed_ages(h, rng, maxi(0, day))
		var rec := _own_record(bt, int(h.id), int(e.get("capital", 40)))
		if bt == "quarry":
			rec.out = (e.get("out", {}) as Dictionary).duplicate()       # an independent miner digs a claim of its own, never the quarry's
			for k in e.get("reserves", {}):
				rec.reserves[k] = int(e.reserves[k])
		var T := btype(bt)
		for tool in T.get("tools", {}):
			rec.stock[tool] = _tool_stock(T, tool, 1)
		own[str(h.id)] = rec


## Each day after wages: of what a crafter's working purse holds above its reserve, the household takes its living (all of it:
## there are no other workers); counted as the household's income, as a wage is.
func _pay_own() -> void:
	for k in _own_ids():
		var o: Dictionary = own[k]
		var h: Dictionary = hh[int(k)]
		if not bool(h.alive):
			continue
		var pay := maxi(0, int(o.till) - int(o.reserve))
		if pay > 0:
			o.till -= pay
			h.coins += pay
			h.inc = int(h.get("inc", 0)) + pay
			o.paid = int(o.get("paid", 0)) + pay
			o.week = int(o.get("week", 0)) + pay
		o.idle = int(o.get("idle", 0)) + 1 if int(o.till) <= 1 else 0      # a day the working purse is spent (its tools stay in stock, so stock is not asked)


## Once a week: one craft household short of work sets up on its own (its savings become its working purse), and a crafter
## whose trade has failed for own_fail_days goes back to its trade's business.
func _own_week() -> void:
	var cap := int((data().get("independent", {}) as Dictionary).get("own_start_capital", 30))
	for i in hh.size():
		var h: Dictionary = hh[i]
		var t := str(h.trade)
		if not bool(h.alive) or not t in OWN_TRADES or own.has(str(i)) or int(h.get("low", 0)) < 2 or int(h.coins) < cap:
			continue
		var bt: String = TRADE_BIZ.get(t, "")
		if bt == "" or bt == "quarry":
			continue                                     # a miner needs a claim of its own: only the data gives one
		if biz.has(bt):
			biz[bt].workers.erase(i)
		h.coins -= cap
		var rec := _own_record(bt, i, cap)
		own[str(i)] = rec
		flows.own_started += 1
		note("%s set up on their own account as a %s." % ["A household", t])
		break
	for k in _own_ids():
		var o: Dictionary = own[k]
		if int(o.get("idle", 0)) >= int((data().get("independent", {}) as Dictionary).get("own_fail_days", 14)):
			var h: Dictionary = hh[int(k)]
			_wind_up_own(h)
			if biz.has(str(o.type)) and bool(h.alive):
				biz[str(o.type)].workers.append(int(k))
			flows.own_ended += 1


## A household's own trade is wound up into the household: its working purse into its coins, its stock into its pantry.
func _wind_up_own(h: Dictionary) -> void:
	var k := str(h.id)
	if not own.has(k):
		return
	var o: Dictionary = own[k]
	h.coins += int(o.till)
	for i in o.stock:
		_add(h.pantry, i, int(o.stock[i]))
	own.erase(k)


func _own_save() -> Dictionary:
	var out := {}
	for k in _own_ids():
		var o: Dictionary = (own[k] as Dictionary).duplicate(true)
		_clean(o.acc)
		out[k] = o
	return out


# --- wages, tax, officials
func _wage_bill(b: Dictionary) -> int:
	return _workers(b) * int(btype(b.type).get("wage", 8))


func _pay_wages() -> void:
	var types := biz.keys()
	types.sort()
	for t in types:
		var b: Dictionary = biz[t]
		var wage := int(btype(t).get("wage", 8))
		var live := []
		for i in b.workers:
			if hh[i].alive:
				live.append(i)
		if live.is_empty():
			continue
		# the business keeps its working reserve; of what it has above it, it pays out at least the wages and up to its
		# payout share, equally among its worker households (the owners' and workers' living is its profit)
		var surplus := maxi(0, int(b.till) - int(b.reserve))
		var due := wage * live.size()
		var total := mini(surplus, maxi(due, int(float(surplus) * float(_rules.payout_share))))
		var each: int = total / live.size()
		var rem: int = total - each * live.size()
		for k in live.size():
			var h: Dictionary = hh[live[k]]
			var pay: int = each + (rem if k == 0 else 0)
			b.till -= pay
			h.coins += pay
		b.paid = int(b.get("paid", 0)) + total
		b.week = int(b.get("week", 0)) + total
		for k in live.size():
			hh[live[k]].inc = int(hh[live[k]].inc) + each + (rem if k == 0 else 0)
		# PAR-02A (owner, OD-19): a reserve protects necessities, it never keeps them from being met. A worker household
		# already hungry that cannot buy a day's food is paid its wage from the till even below the working reserve.
		var need_paid := 0
		for i in live:
			var h: Dictionary = hh[i]
			var paid_now: int = each + (rem if i == live[0] else 0)
			var short := wage - paid_now
			if short <= 0 or int(h.hungry) <= 0 or int(h.coins) >= _day_food_cost(h) or int(b.till) <= 0:
				continue
			var pay := mini(short, int(b.till))
			b.till -= pay
			h.coins += pay
			h.inc = int(h.inc) + pay
			need_paid += pay
		total += need_paid
		b.paid = int(b.paid) + need_paid
		b.week = int(b.week) + need_paid
		flows.wages_paid += total
		flows.wage_short += maxi(0, due - total)


func _taxes_and_officials() -> void:
	var ob := _obligations()
	# DVW-B5: the village's banded, announced rule (TaxPolicy), on this settlement's own treasury and wages; its announcements
	# go to the settlement's own journal. Same rates, boundaries, margin and notice as the village.
	var ts := TaxPolicy.step(tax, float(gov.coins), float(ob), day)
	for line: String in ts.notes:
		note(line)
	var rate := float(ts.rate) if not untaxed() else 0.0
	if rate > 0.0:
		for h in hh:
			if not h.alive:
				continue
			var members := int(h.adults) + int(h.children)
			var exempt := int(GameData.b("tax_exemption_base")) + int(GameData.b("tax_exemption_per_member")) * members
			var t := int(maxi(0, int(h.coins) - exempt) * rate)
			h.coins -= t
			gov.coins += t
			flows.tax_households += t
		var types := biz.keys()
		types.sort()
		for tp in types:
			var b: Dictionary = biz[tp]
			var t := int(maxi(0, int(b.till) - int(b.reserve) - int(_rules.business_tax_exempt)) * rate)
			b.till -= t
			gov.coins += t
			flows.tax_businesses += t
	for i in gov.officials:
		var h: Dictionary = hh[i]
		if h.alive:
			var pay := mini(int(_rules.official_wage), int(gov.coins))
			gov.coins -= pay
			h.coins += pay
			flows.official_pay += pay
	# day labour on the settlement's works (the village's own rule, balance.json day_labour_wage) for a household nearly out
	# of coins, while the treasury holds more than three days of its wages
	var wage := int(_rules.day_labour_wage)
	for h in hh:
		if h.alive and int(h.coins) < int(_rules.day_labour_below) and int(gov.coins) - wage >= 3 * ob:
			gov.coins -= wage
			h.coins += wage
			flows.day_labour += wage


## Once a week a household whose trade pays it next to nothing takes up a trade that pays well (the village's own job
## changes): it joins the business that paid its workers most this week, if that is at least `switch_to_at_least` a worker a
## day and at least twice its own pay, after `switch_stay_days` in its trade. Officials stay officials, and every
## business keeps at least one household. No coin or good moves; the settlement's trades follow what pays.
func _move_jobs() -> void:
	for h in hh:
		h.stay = int(h.stay) + 1
	var every := int(_rules.switch_every_days)
	if every <= 0 or day % every != every - 1:
		return
	var types := biz.keys()
	types.sort()
	var pay := {}
	for t in types:
		var b: Dictionary = biz[t]
		pay[t] = float(b.week) / 7.0 / maxf(1.0, float(_workers(b)))
	for t in types:
		biz[t].rate = _q(float(pay[t]))                      # MIGRATE-18: what a worker of the trade was paid a day last week (a place is open where it is high)
	for h in hh:
		h.rate = _q(float(h.inc) / 7.0)                      # and what the household earned a day: a week under `switch_below` is a week short of work
		h.low = int(h.get("low", 0)) + 1 if float(h.rate) < float(_rules.switch_below) else 0
	var best := ""
	for t in types:
		if t != "merchant" and _workers(biz[t]) > 0 and float(pay[t]) >= float(_rules.switch_to_at_least) and (best == "" or float(pay[t]) > float(pay[best])):
			best = t
	if best != "":
		for t in types:
			var b: Dictionary = biz[t]
			if t == best:
				continue                       # REG-X20-D1: a trade may be left with no household (it closes when idle, _close_idle)
			for i in b.workers.duplicate():
				var h: Dictionary = hh[i]
				if h.alive and int(h.stay) >= int(_rules.switch_stay_days) and float(h.inc) / 7.0 < float(_rules.switch_below) \
						and float(pay[best]) >= 2.0 * float(h.inc) / 7.0:
					_ttrace("job_move_to_" + best, i)
					b.workers.erase(i)
					biz[best].workers.append(i)
					h.trade = _trade_of(best)
					h.stay = 0
					flows.job_moves += 1
					break                      # one household a business a week
	_own_week()
	_develop()
	for t in biz:
		biz[t].week = 0
	for h in hh:
		h.inc = 0


# ------------------------------------------------------------------ development (SET-D, owner B18-DP-05) ----------------
## Once a week, after the job moves, a settlement's businesses follow its people and its needs, by the numbers the job moves use:
##   closing  a business with no living worker household for `switch_stay_days` (two looks) closes, the traders too (Build 24
##            review, owner 2026-10-30: whichever way the last household went: a trade switch, death, leaving, another business). Its till passes to the treasury; its stock is bought by the traders at market
##            price as far as their till above its reserve reaches, and the rest goes into the treasury's granary (the rule of
##            a household with no kin). The fields, woods, quarry reserve and horses stay with the place (`closed`).
##   opening  a trade the settlement does not have opens when its goods went unmet (units wanted and not found for sale, priced)
##            worth at least `switch_to_at_least` a day in each of `switch_stay_days / switch_every_days` weeks running, a
##            household settled `switch_stay_days` in a trade with more than one household, earning under half that a day,
##            takes it up and puts its coins above its keep-cash into the till, the trade's working reserve at least. A trade made
##            from what the land gives (fields, flocks, woods, herbs) reopens only where it was before; a trade made from
##            inputs (the village's recipes) opens only if the settlement has or makes an input of one of its recipes. One a week.
## No random numbers, no cap on people or businesses; capacity is what its living workers make (_produce).
func _develop() -> void:
	var delta := {}
	for item in flows.unmet:
		delta[item] = maxi(0, int(flows.unmet[item]) - int((dev.get("seen", {}) as Dictionary).get(item, 0)))
	dev["seen"] = (flows.unmet as Dictionary).duplicate()
	_close_idle()
	_open_trade(delta)


func _close_idle() -> void:
	var types := biz.keys()
	types.sort()
	for t in types:
		var b: Dictionary = biz[t]                   # the traders too (Build 24 review): a trade nobody is left to work closes
		if _workers(b) > 0:
			b.idle = 0
			continue
		b.idle = int(b.get("idle", 0)) + 1
		if int(b.idle) * int(_rules.switch_every_days) >= int(_rules.switch_stay_days):
			_close_business(t)


func _close_business(t: String) -> void:
	if _trace and t == "merchant":
		print("TTRACE day %d %s merchant_closes workers %s till %d consign %s due %s" % [day, id, str(biz.merchant.workers), int(biz.merchant.till), str(biz.merchant.get("consign", {})), str(biz.merchant.get("consign_due", {}))])
	if t == "merchant" and not transit.is_empty():
		# X20-SETTLE-FOOD: food its traders bought and are still bringing home is taken in now (the shipment delivered early, the
		# seller paid), so it follows the trader's stock to the granary instead of waiting on the road for a trader who is gone
		for e in transit:
			e.due = mini(int(e.due), day)
		_deliver()
	var b: Dictionary = biz[t]
	gov.coins += int(b.till)
	_consign_to_treasury(b)                    # B25-ECON-P6: what it carries for, and owes to, another place's sources is the treasury's to settle
	var m: Dictionary = biz.get("merchant", {}) if t != "merchant" else {}     # a closing trader's own stock goes to the council
	var items: Array = b.stock.keys()
	items.sort()
	for item in items:
		var n := int(b.stock[item])
		if not m.is_empty():
			var u := mini(n, maxi(0, int(m.till) - int(m.reserve)) / price(item))
			if u > 0:
				m.till -= u * price(item)
				gov.coins += u * price(item)
				_add(m.stock, item, u)
				n -= u
		_add(gov.granary, item, n)
	b.till = 0
	b.stock = {}
	b.erase("imported")
	b.acc = {}
	b.workers = []
	b.idle = 0
	b.week = 0
	closed[t] = b
	biz.erase(t)
	dev.get("streak", {}).erase(t)
	flows.biz_closed += 1
	note("The %s closed: no household was left to work it." % str(btype(t).get("name", t)))


## The goods a trade would sell: its recipes' outputs, and a closed place's natural output.
func _trade_goods(t: String) -> Array:
	var out := {}
	if t == "merchant":                          # X20-SETTLE-REOPEN: what traders bring a place: the goods they carry and food
		for item in _rules.carry:
			out[item] = true
		for item in _rules.foods:
			out[item] = true
	for rid in btype(t).get("runs", {}):
		for o in GameData.recipes[rid].out:
			out[o] = true
	for item in (closed[t].out if closed.has(t) else {}):
		out[item] = true
	var k := out.keys()
	k.sort()
	return k


func _inputs_exist(t: String) -> bool:
	var have := {}
	for bt in biz:
		var b: Dictionary = biz[bt]
		for item in b.stock:
			have[item] = true
		if _workers(b) > 0:
			for item in b.out:
				have[item] = true
			for rid in btype(bt).get("runs", {}):
				for o in GameData.recipes[rid].out:
					have[o] = true
	for rid in btype(t).get("runs", {}):
		var ok := true
		for i in GameData.recipes[rid]["in"]:
			ok = ok and have.has(i)
		if ok:
			return true
	return false


func _open_trade(delta: Dictionary) -> void:
	var streak: Dictionary = dev.get("streak", {})
	dev["streak"] = streak
	var cands: Array = []
	for t in _types:
		if biz.has(t) or (t == "merchant" and not closed.has(t)):      # X20-SETTLE-REOPEN: a closed trader may be taken up again
			continue
		if closed.has(t) or (not btype(t).get("runs", {}).is_empty() and (btype(t).get("out", {}) as Dictionary).is_empty()):
			cands.append(t)
	cands.sort()
	var weeks := maxi(1, int(_rules.switch_stay_days) / maxi(1, int(_rules.switch_every_days)))
	var best := ""
	var best_pay := 0.0
	for t in cands:
		var worth := 0.0
		for item in _trade_goods(t):
			worth += float(delta.get(item, 0)) * float(price(item))
		var pay := worth / float(_rules.switch_every_days)
		if pay >= float(_rules.switch_to_at_least):
			streak[t] = int(streak.get(t, 0)) + 1
		else:
			streak.erase(t)
		var feasible := _place_left(closed[t]) if closed.has(t) else _inputs_exist(t)
		if int(streak.get(t, 0)) >= weeks and feasible and (best == "" or pay > best_pay):
			best = t
			best_pay = pay
	if best == "":
		return
	var rec: Dictionary = closed.get(best, {})
	var reserve: int = int(rec.reserve) if not rec.is_empty() else int(btype(best).get("reserve", 12))
	var pick := -1
	var pick_cash := -1
	for h in hh:
		if not h.alive or not TRADE_BIZ.has(str(h.trade)) or int(h.stay) < int(_rules.switch_stay_days):
			continue
		if own.has(str(h.id)):
			continue                       # REGION-NAV-01 Q4: a household working on its own account is in no business to leave
		var ob: String = TRADE_BIZ[h.trade]
		if not biz.has(ob) or best_pay < 2.0 * float(h.rate):        # REG-X20-D1: a business's only household may go too
			continue
		var cash := int(h.coins) - int(_rules.keep_cash_base) - int(_rules.keep_cash_per_member) * (int(h.adults) + int(h.children))
		if cash >= reserve and cash > pick_cash:
			pick = int(h.id)
			pick_cash = cash
	if pick < 0:
		return
	var h: Dictionary = hh[pick]
	var nb: Dictionary
	if rec.is_empty():
		var T := btype(best)
		nb = {"type": best, "workers": [], "till": 0, "stock": {}, "reserves": {}, "out": (T.get("out", {}) as Dictionary).duplicate(), "acc": {},
			"reserve": int(T.get("reserve", 12)), "horses": 0, "foal": 0, "fed_miss": 0, "paid": 0, "week": 0, "rate": 0.0, "idle": 0}
	else:
		# X20-SETTLE-REOPEN (owner 2026-10-30): the place's own fields, woods, deposit and horses stay with it (`out`, `reserves`,
		# `horses`), but nothing of the former owner's comes back: its till and stock were handed on when it closed, and its
		# workforce, accounts and trading capital start afresh from what the new household brings, as for a new business
		nb = rec
		closed.erase(best)
		nb.till = 0
		nb.stock = {}
		nb.erase("imported")
		nb.acc = {}
		nb.paid = 0
		nb.week = 0
		nb.rate = 0.0
		nb.idle = 0
		nb.fed_miss = 0
		nb.reserve = int(btype(best).get("reserve", 12))
	_ttrace("opens_" + best, pick)
	var old: Dictionary = biz[TRADE_BIZ[h.trade]]
	old.workers.erase(pick)
	nb.workers = [pick]
	nb.till = pick_cash
	h.coins -= pick_cash
	h.trade = _trade_of(best)
	h.stay = 0
	biz[best] = nb
	streak.erase(best)
	flows.biz_opened += 1
	flows.job_moves += 1
	note("A household took up %s and opened the %s." % [h.trade, str(btype(best).get("name", best))])


## A closed place that still has what it gave: a quarry with ore or stone left, or any other that never ran out.
static func _place_left(rec: Dictionary) -> bool:
	if (rec.reserves as Dictionary).is_empty():
		return true
	for k in rec.reserves:
		if int(rec.reserves[k]) > 0:
			return true
	return false


static func _trade_of(bt: String) -> String:
	for k in TRADE_BIZ:
		if TRADE_BIZ[k] == bt:
			return k
	return bt


# --- eating, hunger, the stable
func _eat() -> void:
	var foods: Array = _rules.foods.duplicate()
	foods.sort_custom(func(a, b): return float(GameData.value(a)) / _pts(a) < float(GameData.value(b)) / _pts(b))
	for h in hh:
		if not h.alive:
			continue
		var need := _need_pts(h)
		var have := float(h.credit)
		for f in foods:
			while have < need and int(h.pantry.get(f, 0)) > 0:
				_take(h.pantry, f, 1)
				_add(flows.used, f, 1)
				have += _pts(f)
		h.credit = _q(maxf(0.0, have - need))
		if have < need * float(_rules.hungry_below):
			h.hungry += 1
			if int(h.hungry) >= int(_rules.hungry_days_to_death):
				_lose_member(h)
				h.hungry = int(_rules.hungry_days_to_death) - 3
		else:
			h.hungry = 0


func _lose_member(h: Dictionary) -> void:
	# hunger takes the youngest child first, else the oldest (as it always took children first)
	var pick := -1
	for j in h.mem.size():
		var m: Array = h.mem[j]
		if pick < 0:
			pick = j
			continue
		var p: Array = h.mem[pick]
		if _is_adult(m) == _is_adult(p):
			if int(m[M_BORN]) > int(p[M_BORN]) if not _is_adult(m) else int(m[M_BORN]) < int(p[M_BORN]):
				pick = j
		elif not _is_adult(m):
			pick = j
	if pick >= 0:
		_died(h.mem[pick], "hunger")
		_remove_member(h, pick)
	flows.deaths += 1
	_after_loss(h)


## The settlement's working horses eat the farms' wheat (from their own stock: grain they grew), and a fed pair breeds.
func _stable() -> void:
	if not biz.has("farm"):
		return
	var b: Dictionary = biz.farm
	var T := btype("farm")
	if int(b.horses) <= 0 or _workers(b) == 0:
		return
	b.acc["feed"] = _q(float(b.acc.get("feed", 0.0)) + float(T.feed) * int(b.horses))
	var units := int(floor(float(b.acc.feed) + 1e-9))
	if units > 0:
		var ate := _take(b.stock, "wheat", units)
		_add(flows.used, "wheat", ate)
		b.acc["feed"] = _q(float(b.acc.feed) - float(units))
		if ate < units:
			b.fed_miss += 1
		else:
			b.fed_miss = 0
	if int(b.fed_miss) >= 10:
		b.horses -= 1
		b.fed_miss = 5
		flows.horses_died += 1
	elif int(b.fed_miss) == 0 and int(b.horses) >= 2 and int(b.horses) < int(T.horses_max):
		b.foal += 1
		if int(b.foal) >= int(T.foal_days):
			b.foal = 0
			b.horses += 1
			flows.horses_foaled += 1


# ------------------------------------------------------------------ trade with the village ----------------
## Open a visit: what the settlement wants from the village this time (begin_visit), and the food its trader takes along to sell
## (stock_trader_food, REG-BUY-01).
func begin_visit() -> void:
	_want_left = wants()
	stock_trader_food()
	consign_out()


# ------------------------------------------------------------------ consignment (B25-ECON-P4) ----------------
## B25-ECON-P4 (owner 2026-11-05: "a neighbour trader may carry REAL ore stock on consignment, paying its source when the village
## buys it"; only real stocks, nothing created; OD-01, ECON-P1.3). The rule:
##   take     when a caravan visit opens (begin_visit), the trader takes along, without paying, the goods of rules.consign that
##            its own settlement's businesses hold above what they keep (_keep), up to its carry room (rules.carry less its stock),
##            the businesses in type order; the units stay owed to their source (the trader's `consign` {item: {type: n}});
##   sell     only to the village (sell_to_village): the trader's own stock goes first, then the consigned; each consigned unit
##            sold pays its source trader_pays_share of the settlement's price (never more than the sale) from the coins the
##            village just paid; nobody else may buy a consigned unit (sale_cap, Regions.road_trade);
##   return   at the settlement's next morning (step_day, before its market) every unsold consigned unit goes back to its source's
##            stock; a source that has closed meanwhile is the treasury's (its goods to the granary, its pay to gov.coins), the
##            rule of a closed business (_close_business).
## Goods and coins move inside the settlement's own books (no flow line), so its audit holds; the village side is sell_to_village's.
func consign_out() -> void:
	var m := trader()
	if m.is_empty():
		return
	var items: Array = _rules.get("consign", [])
	if items.is_empty():
		return
	var types := biz.keys()
	types.sort()
	for item in items:
		var room := int(_rules.carry.get(item, 0)) - int(m.stock.get(item, 0))
		for t in types:
			if room <= 0:
				break
			if t == "merchant":
				continue
			var b: Dictionary = biz[t]
			var n := mini(room, int(b.stock.get(item, 0)) - int(_keep(b).get(item, 0)))
			if n <= 0:
				continue
			_take(b.stock, item, n)
			_add(m.stock, item, n)
			if not m.has("consign"):
				m["consign"] = {}
			if not (m.consign as Dictionary).has(item):
				m.consign[item] = {}
			_add(m.consign[item], str(t), n)
			room -= n


## Units of `item` the trader holds on consignment (owed to their sources).
func consigned(item: String) -> int:
	var m := trader()
	if m.is_empty() or not m.has("consign"):
		return 0
	var n := 0
	for t in (m.consign as Dictionary).get(item, {}):
		n += int(m.consign[item][t])
	return n


## B25-ECON-P6: a consignment key "<settlement>/<business type>" is another place's source (a key with no "/" is this place's own).
static func is_remote(key: String) -> bool:
	return key.contains("/")


## Units of `item` the holder record `rec` (a business or the treasury) holds on consignment for any source.
static func consigned_in(rec: Dictionary, item: String) -> int:
	var n := 0
	var c: Dictionary = (rec.get("consign", {}) as Dictionary).get(item, {})
	for t in c:
		n += int(c[t])
	return n


## B25-ECON-P6: coins `rec` has set aside for other places' sources (counted in the settlement's coins, never spent).
static func consign_due_coins(rec: Dictionary) -> int:
	var n := 0
	var due: Dictionary = rec.get("consign_due", {})
	for k in due:
		n += int(due[k])
	return n


## B25-ECON-P6: the other places whose sources `rec` holds goods or coins for, sorted.
static func consign_sources(rec: Dictionary) -> Array:
	var out := {}
	for k in rec.get("consign_due", {}):
		out[str(k).get_slice("/", 0)] = true
	var c: Dictionary = rec.get("consign", {})
	for item in c:
		for k in c[item]:
			if is_remote(str(k)):
				out[str(k).get_slice("/", 0)] = true
	var l := out.keys()
	l.sort()
	return l


## B25-ECON-P6: a closing trader's goods and pay held for other places' sources pass to the treasury (the goods with its stock to the
## granary, the pay set aside there), which sends them home as the trader would have (Regions.consign_round).
func _consign_to_treasury(b: Dictionary) -> void:
	var due: Dictionary = b.get("consign_due", {})
	for k in due:
		if not gov.has("consign_due"):
			gov["consign_due"] = {}
		_add(gov.consign_due, str(k), int(due[k]))
	b.erase("consign_due")
	var c: Dictionary = b.get("consign", {})
	for item in c:
		for k in c[item]:
			if is_remote(str(k)):
				if not gov.has("consign"):
					gov["consign"] = {}
				if not (gov.consign as Dictionary).has(item):
					gov.consign[item] = {}
				_add(gov.consign[item], str(k), int(c[item][k]))
	b.erase("consign")
	var since: Dictionary = b.get("consign_since", {})
	for k in since:
		if not gov.has("consign_since"):
			gov["consign_since"] = {}
		gov.consign_since[k] = mini(int(gov.consign_since.get(k, since[k])), int(since[k]))
	b.erase("consign_since")


static func _consign_from(rec: Dictionary) -> void:
	for k in ["consign_due", "consign_since"]:
		if rec.has(k):
			rec[k] = _ints(rec[k])


## What a consigned unit of `item` pays its source when sold at `unit`.
func consign_pay(item: String, unit: int) -> int:
	return mini(unit, maxi(1, roundi(float(price(item)) * float(_rules.trader_pays_share))))


## `n` consigned units of `item` were sold at `unit`: each source is paid in type order and its debt struck off.
func _consign_sold(item: String, n: int, unit: int) -> void:
	var m := trader()
	var owed: Dictionary = (m.get("consign", {}) as Dictionary).get(item, {})
	var types: Array = owed.keys()
	types.sort()
	var pay := consign_pay(item, unit)
	for t in types:
		if n <= 0:
			break
		var k := mini(n, int(owed[t]))
		m.till -= k * pay
		if is_remote(str(t)):
			# B25-ECON-P6: another place's source: the pay is set aside for it, out of the till, until a walker carries it there
			if not m.has("consign_due"):
				m["consign_due"] = {}
			_add(m.consign_due, str(t), k * pay)
		elif biz.has(t):
			biz[t].till += k * pay
		else:
			gov.coins += k * pay
		_take(owed, str(t), k)
		n -= k
	if owed.is_empty():
		m.consign.erase(item)
	if (m.get("consign", {}) as Dictionary).is_empty():
		m.erase("consign")


## The morning after a visit: every unsold consigned unit goes back to its source (a closed source's to the treasury's granary).
func _consign_return() -> void:
	var m := trader()
	if m.is_empty() or not m.has("consign"):
		return
	var items: Array = (m.consign as Dictionary).keys()
	items.sort()
	for item in items:
		var owed: Dictionary = m.consign[item]
		var types: Array = owed.keys()
		types.sort()
		for t in types:
			if is_remote(str(t)):
				continue                               # B25-ECON-P6: another place's goods go home by a walker (Regions.consign_round)
			var k := mini(int(owed[t]), int(m.stock.get(item, 0)))
			_take(m.stock, str(item), k)
			if biz.has(t):
				_add(biz[t].stock, str(item), k)
			else:
				_add(gov.granary, str(item), k)
			owed.erase(t)
		if owed.is_empty():
			m.consign.erase(item)
	if (m.consign as Dictionary).is_empty():
		m.erase("consign")


func want_left(item: String) -> int:
	return int(_want_left.get(item, 0))


func trader_cash() -> int:
	var m := trader()
	return 0 if m.is_empty() else maxi(0, int(m.till) - int(_rules.trader_reserve_floor))


## What the trader has of `item` to sell on the road: its stock, less food it bought from another settlement for its own people
## (X20-SETTLE-FOOD: imported food is for the local market, not for the caravan, while its place still needs it).
func trader_has(item: String) -> int:
	var m := trader()
	return 0 if m.is_empty() else maxi(0, int(m.stock.get(item, 0)) - int((m.get("imported", {}) as Dictionary).get(item, 0)))


## The trader sells `n` of `item` to the village at `unit` coins each: the goods leave its stock, the coins enter its till.
func sell_to_village(item: String, n: int, unit: int) -> bool:
	var m := trader()
	if m.is_empty() or n <= 0 or trader_has(item) < n:
		return false
	var own_left := int(m.stock.get(item, 0)) - consigned(item)       # B25-ECON-P4: its own stock first, then the consigned
	_take(m.stock, item, n)
	m.till += n * unit
	_add(flows.to_village, item, n)
	flows.coins_from_village += n * unit
	if n > own_left:
		_consign_sold(item, n - maxi(0, own_left), unit)
	return true


## The trader buys `n` of `item` from the village at `unit` each: the coins leave its till (never past its floor), the goods
## enter its stock.
func buy_from_village(item: String, n: int, unit: int) -> bool:
	var m := trader()
	if m.is_empty() or n <= 0 or trader_cash() < n * unit:
		return false
	m.till -= n * unit
	_add(m.stock, item, n)
	_add(flows.from_village, item, n)
	flows.coins_to_village += n * unit
	_want_left[item] = maxi(0, int(_want_left.get(item, 0)) - n)
	if _rules.foods.has(item) or item == "meat":
		_want_left["_food_pts"] = maxf(0.0, float(_want_left.get("_food_pts", 0.0)) - float(n) * _pts(item))
	return true


## The plough horse a farm of the settlement sells (a trader leads it to the road): price in coins, into the farm's till.
func sell_horse(unit: int) -> bool:
	if not biz.has("farm") or int(biz.farm.horses) <= 0:
		return false
	biz.farm.horses -= 1
	biz.farm.till += unit
	flows.horses_sold += 1
	flows.coins_from_village += unit
	return true


func has_horse() -> bool:
	return horses() > 0


## Units of each good the settlement would take now: a few days' use that neither its stocks nor its own workings cover
## (the demand of its people, its businesses and its treasury, less what its workers make), and food when its people hold
## under three days of it. Only things it can use; never more than it can pay for is decided at the till.
func wants() -> Dictionary:
	data()
	var daily := {}
	var made := {}
	var members := float(population())
	var rl := rules()
	for item in rl.basket:
		daily[item] = float(daily.get(item, 0.0)) + float(rl.basket[item]) * members
	for item in rl.gov_upkeep:
		daily[item] = float(daily.get(item, 0.0)) + float(rl.gov_upkeep[item]) * float(households())
	for t in biz:
		var b: Dictionary = biz[t]
		var T := btype(t)
		var n := float(_workers(b))
		if n == 0.0:
			continue
		for item in b.out:
			if not b.reserves.has(item) or int(b.reserves[item]) > 0:
				made[item] = float(made.get(item, 0.0)) + float(b.out[item]) * n
		for rid in T.get("runs", {}):
			var r: Dictionary = GameData.recipes[rid]
			for i in r["in"]:
				daily[i] = float(daily.get(i, 0.0)) + float(T.runs[rid]) * n * int(r["in"][i])
			for o in r.out:
				made[o] = float(made.get(o, 0.0)) + float(T.runs[rid]) * n * int(r.out[o])
		for tool in T.get("tools", {}):
			daily[tool] = float(daily.get(tool, 0.0)) + float(T.tools[tool]) * n
	var have := goods()
	var out := {}
	for item in daily:
		var gap := float(daily[item]) - float(made.get(item, 0.0))
		if gap <= 0.0:
			continue
		var w := ceili(gap * float(rl.want_days)) - int(have.get(item, 0))
		if w > 0:
			out[item] = w
	var pts := 0.0
	var need := 0.0
	for h in hh:
		if h.alive:
			need += _need_pts(h)
			pts += _pantry_pts(h)
	for b in biz.values():
		for f in rl.foods:
			pts += float(b.stock.get(f, 0)) * _pts(f)
	for f in rl.foods:
		pts += float(gov.granary.get(f, 0)) * _pts(f)
	pts += transit_food_pts()                       # X20-SETTLE-FOOD: food already bought and on its way is not wanted again
	out["_food_pts"] = maxf(0.0, 3.0 * need - pts)
	return out


## Whether the settlement still wants `n` of `item` this visit (a food counts against the food it still lacks).
func wants_item(item: String, n := 1) -> bool:
	if _rules.foods.has(item):
		return float(_want_left.get("_food_pts", 0.0)) >= _pts(item) * float(n) * 0.5
	return int(_want_left.get(item, 0)) >= n


# ------------------------------------------------------------------ food for the village (REG-BUY-01, REG-BUY-P1) ----------------
## The foods a settlement's trader may carry: the settlement's foods (settlements.json rules.foods) and raw meat.
func food_items() -> Array:
	data()
	var out: Array = _rules.foods.duplicate()
	out.append("meat")
	return out


## Whether a business makes food: a food among its natural output or its recipes' products (farm, herd, cookshop).
func _makes_food(b: Dictionary) -> bool:
	var foods := food_items()
	var T := btype(b.type)
	for item in (T.get("out", {}) as Dictionary).keys() + b.out.keys():
		if foods.has(item):
			return true
	for rid in T.get("runs", {}):
		for o in GameData.recipes[rid].out:
			if foods.has(o):
				return true
	return false


## What the businesses expect to produce of food over `days` days, in food points: their natural output (a field's wheat, a
## herd's meat) at the workers they have, as wants() reckons what they make; a deposit-limited output counts only while it lasts.
## A cookshop's pottage and roast meat are made from food already counted, so they add nothing.
func expected_food_pts(days: float) -> float:
	var foods := food_items()
	var p := 0.0
	for t in biz:
		var b: Dictionary = biz[t]
		var n := float(_workers(b))
		if n == 0.0:
			continue
		for item in b.out:
			if foods.has(item) and (not b.reserves.has(item) or int(b.reserves[item]) > 0):
				p += float(b.out[item]) * n * days * _pts(item)
	return p


## The settlement's local claim on its food, in food points (REG-BUY-P1 rule 2, the rule of the village's World.necessity and
## NPCBrain._sale_stock): what its households foreseeably need over the village's reserve_days (balance.json), household by
## household, less what each pantry holds, less what its businesses expect to produce over those days. Food above the claim
## is what the settlement can spare.
func food_claim_pts() -> float:
	var days := float(GameData.b("reserve_days"))
	var need := 0.0
	for h in hh:
		if h.alive:
			need += maxf(0.0, _need_pts(h) * days - _pantry_pts(h))
	return maxf(0.0, need - expected_food_pts(days))


## The units of `item` business `b` holds that are its own to sell: its stock less what its recipes and tools keep (_keep) and,
## for a farm's wheat, the feed its horses eat over reserve_days (the stable's rate).
func _food_spare(b: Dictionary, item: String, keep: Dictionary) -> int:
	var n := int(b.stock.get(item, 0)) - int(keep.get(item, 0))
	if item == "wheat" and b.type == "farm" and int(b.horses) > 0:
		n -= ceili(float(btype("farm").feed) * float(b.horses) * float(GameData.b("reserve_days")))
	return maxi(0, n)


## The cash a business needs for its essential operating expenses today (REG-BUY-P1 rule 3): the wage bill of its workers
## (_wage_bill) and the cost, at today's prices, of the inputs and tools it lacks (_inputs_short, what _business_buys buys).
func _expense_due(b: Dictionary) -> int:
	var due := _wage_bill(b)
	var short := _inputs_short(b)
	for item in short:
		due += int(short[item]) * price(item)
	return due


## The demonstrated cash shortfall of a business: what its essential operating expenses exceed its till by (0 when it can pay).
func cash_shortfall(b: Dictionary) -> int:
	return maxi(0, _expense_due(b) - int(b.till))


## The trader takes along food bought from its settlement's food businesses (farms, herds, cookshop; REG-BUY-P1), to sell to the
## village on this visit. Rules, in order:
##  2. only food above the local claim (food_claim_pts) is released: the food the food businesses hold, net of their recipes'
##     and tools' keep and the horses' feed, less the claim, a business at a time (types in order) and its items in the foods'
##     order. The households shopped this morning before the trader, so local buyers have had first call (the step ran at
##     six, the visit is at noon);
##  3. a business with a demonstrated cash shortfall (cash_shortfall) also sells, out of the part the claim protects, food
##     worth at most that shortfall at the price the trader pays: never a business without a shortfall, never beyond it;
##  4. the trader pays the settlement's own floating price (price) less trader_pays_share (as _trader_collects), from its
##     own till above its trading capital. Coins and goods change hands inside the settlement: nothing is made.
func stock_trader_food() -> void:
	var m := trader()
	if m.is_empty():
		return
	var foods := food_items()
	var srcs: Array = []                       # [business, keep]
	var types := biz.keys()
	types.sort()
	var held := 0.0
	for t in types:
		var b: Dictionary = biz[t]
		if b.type == "merchant" or _workers(b) == 0 or not _makes_food(b):
			continue
		var keep := _keep(b)
		srcs.append([b, keep])
		for item in foods:
			held += float(_food_spare(b, item, keep)) * _pts(item)
	var free := maxf(0.0, held - food_claim_pts())
	var cash := int(m.till) - maxi(int(_rules.trader_reserve_floor), int(m.reserve))
	var share := float(_rules.trader_pays_share)
	for pass_no in 2:
		for src in srcs:
			var b: Dictionary = src[0]
			var short := cash_shortfall(b) if pass_no == 1 else 0
			if pass_no == 1 and short <= 0:
				continue
			for item in foods:
				var spare := _food_spare(b, item, src[1])
				var p := maxi(1, roundi(float(price(item)) * share))
				var n := mini(spare, cash / p)
				if pass_no == 0:
					n = mini(n, floori(free / _pts(item)))
				else:
					n = mini(n, short / p)
				if n <= 0:
					continue
				_take(b.stock, item, n)
				_add(m.stock, item, n)
				b.till += n * p
				m.till -= n * p
				cash -= n * p
				if pass_no == 0:
					free -= float(n) * _pts(item)
				else:
					short -= n * p


## The village's price for a unit of `item` from this settlement's trader: the settlement's own floating price.
func food_price(item: String) -> int:
	return price(item)


# ------------------------------------------------------------------ food bought from other settlements (X20-SETTLE-FOOD) ----------------
## The name of one of the five places by its id (settlements.json), or the id.
static func place_name(pid: String) -> String:
	for sp in data().settlements:
		if str(sp.id) == pid:
			return str(sp.name)
	return pid


## X20-SETTLE-FOOD: what this settlement's food businesses may sell of `items` to another settlement's trader, by the rules they
## release food to the village's caravan by (stock_trader_food, REG-BUY-P1), read only: {business type: {item: units}}.
##  2. food above the local claim (food_claim_pts): the businesses' food net of their keep and the horses' feed, less the claim, a
##     business at a time (types in order) and its items in the given order;
##  3. a business with a demonstrated cash shortfall (cash_shortfall) also out of the protected part, worth at most that shortfall
##     at the settlement's own price (the price the buyer pays it: no trader in between takes a margin).
## The buyer's coins, not a trader's, pay for it, so no trader's capital limits it.
func food_release(items: Array) -> Dictionary:
	var out := {}
	var srcs: Array = []                       # [business, keep]
	var types := biz.keys()
	types.sort()
	var held := 0.0
	for t in types:
		var b: Dictionary = biz[t]
		if b.type == "merchant" or _workers(b) == 0 or not _makes_food(b):
			continue
		var keep := _keep(b)
		srcs.append([b, keep])
		for item in food_items():
			held += float(_food_spare(b, item, keep)) * _pts(item)
	var free := maxf(0.0, held - food_claim_pts())
	for pass_no in 2:
		for src in srcs:
			var b: Dictionary = src[0]
			var short := cash_shortfall(b) if pass_no == 1 else 0
			if pass_no == 1 and short <= 0:
				continue
			if not out.has(b.type):
				out[b.type] = {}
			for item in items:
				var spare := _food_spare(b, item, src[1]) - int(out[b.type].get(item, 0))
				var n := spare
				if pass_no == 0:
					n = mini(n, floori(free / _pts(item)))
				else:
					n = mini(n, short / maxi(1, price(item)))
				if n <= 0:
					continue
				out[b.type][item] = int(out[b.type].get(item, 0)) + n
				if pass_no == 0:
					free -= float(n) * _pts(item)
				else:
					short -= n * price(item)
	for t in out.keys():
		if (out[t] as Dictionary).is_empty():
			out.erase(t)
	return out


## Food points of the goods bought and still on the road home.
func transit_food_pts() -> float:
	var p := 0.0
	for e in transit:
		if _rules.foods.has(str(e.item)):
			p += float(e.n) * _pts(str(e.item))
	for t in trips:                                  # B25R1-019: food a walker is sent for, or carries home
		if str(t.purpose.get("kind", "")) != "food":
			continue
		if str(t.leg) == "out":
			for l in t.purpose.get("lines", []):
				p += float(l.n) * _pts(str(l.item))
		else:
			for k in t.pack:
				if _rules.foods.has(str(k)):
					p += float(t.pack[k]) * _pts(str(k))
	return p


## A shipment this settlement's trader bought leaves for home (Regions.food_round, after the authority accepted it): the record the
## settlement keeps of what it awaits.
func await_shipment(tx: String, to: String, item: String, n: int, from: String, sent: int, due: int, coins_: int) -> Dictionary:
	var e := {"tx": tx, "to": to, "item": item, "n": n, "from": from, "sent": sent, "due": due, "coins": coins_}
	transit.append(e)
	return e


## Called by the settlement's step: every shipment due today or earlier is delivered (Regions._arrive -> the transaction authority's
## deliver: the goods to the trader, the escrowed price to the seller, together), in the order bought, and marked imported (for the
## local market). An entry is removed once its shipment is closed (delivered, or failed and refunded), so nothing arrives twice; one
## the authority cannot close yet (a party unavailable) stays and is asked again at the next step, its goods and coins where they are.
func _deliver() -> void:
	var keep: Array = []
	for e in transit:
		if int(e.due) > day:
			keep.append(e)
			continue
		var res: Dictionary = arrive_hook.call(e, day) if arrive_hook.is_valid() else {"ok": false, "code": "no_authority", "state": "open"}
		var state := str(res.get("state", ""))
		if state == "open" or (not bool(res.get("ok", false)) and state == ""):
			keep.append(e)                             # cannot be closed now: asked again tomorrow
			continue
		if state == "delivered":
			var m := trader()
			if str(e.to) == "trader" and not m.is_empty():
				if not m.has("imported"):
					m["imported"] = {}
				_add(m.imported, str(e.item), mini(int(e.n), int(m.stock.get(str(e.item), 0))))
			flows.food_delivered += int(e.n)
			note("%d %s bought in %s arrived." % [int(e.n), GameData.item_name(str(e.item)).to_lower(), place_name(str(e.from).trim_prefix("region:").get_slice("/", 0))])
		else:
			note("%d %s bought in %s never arrived (%s); the price was refunded." % [int(e.n), GameData.item_name(str(e.item)).to_lower(),
				place_name(str(e.from).trim_prefix("region:").get_slice("/", 0)), str(res.get("code", state))])
		if trade_hook.is_valid():
			trade_hook.call("delivered", {"settlement": id, "entry": e, "state": state, "households": households()})
	transit = keep


## After the morning market: imported food the locals bought is no longer marked (the mark never exceeds the stock).
func _imported_left() -> void:
	var m := trader()
	if m.is_empty() or not m.has("imported"):
		return
	var keys: Array = (m.imported as Dictionary).keys()
	for k in keys:
		var left := mini(int(m.imported[k]), int(m.stock.get(k, 0)))
		if left <= 0:
			m.imported.erase(k)
		else:
			m.imported[k] = left
	if (m.imported as Dictionary).is_empty():
		m.erase("imported")


## Once the settlement no longer wants food, what its trader imported is ordinary stock again (it may sell it on the road).
func release_imported() -> void:
	var m := trader()
	if not m.is_empty():
		m.erase("imported")


# ------------------------------------------------------------------ a report ----------------
func summary() -> Dictionary:
	var hungry := 0
	var food_pts := 0.0
	var need := 0.0
	for h in hh:
		if h.alive:
			need += _need_pts(h)
			food_pts += _pantry_pts(h)
			if int(h.hungry) > 0:
				hungry += 1
	var cash := 0
	for h in hh:
		cash += int(h.coins)
	var tills := 0
	for t in biz:
		tills += int(biz[t].till)
	for k in own:
		tills += int(own[k].till)                        # REGION-NAV-01 Q4: the crafters' working purses are tills too
	return {"id": id, "population": population(), "households": households(), "hungry": hungry, "deaths": int(flows.deaths),
		"coins": coins(), "household_coins": cash, "tills": tills, "treasury": int(gov.coins),
		"trader": int(trader().get("till", 0)), "pantry_days": food_pts / maxf(1.0, need), "horses": horses(),
		"wage_short": int(flows.wage_short), "relief": int(flows.relief_units), "births": int(flows.births),
		"age_deaths": int(flows.age_deaths), "households_formed": int(flows.households_formed),
		"biz_opened": int(flows.biz_opened), "biz_closed": int(flows.biz_closed), "businesses": biz.size(),
		"food_bought": int(flows.food_bought), "food_sold": int(flows.food_sold), "food_unmet": int(flows.food_unmet),
		"in_transit": transit.size()}


# ------------------------------------------------------------------ people moving to and from the village (MIGRATE-18) ----------------
## What Migration (migration.gd) asks of a settlement. A traveller's record is {age (years), sex, unw, pair, born (the settlement day,
## for a member born here), n, f, sk (name, family, skills: only for a person who came from the village)}.
func _pack_of(m: Array, pair: int) -> Dictionary:
	var out := {"age": _age(m), "sex": int(m[M_SEX]), "unw": int(m[M_UNWILLING]), "pair": pair, "born": int(m[M_BORN]), "id": member_id(m)}
	if has_who(m):
		out.n = str(m[M_WHO].n)
		out.f = str(m[M_WHO].f)
		out.sk = (m[M_WHO].sk as Dictionary).duplicate()
	var b := body_of(m)                                      # B25R1-019: what they learned while live goes with them
	if not b.is_empty():
		if not out.has("sk"):
			out.sk = {}
		for k in b.get("sk", {}):
			out.sk[k] = maxi(int(out.sk.get(k, 0)), int(b.sk[k]))
	return out


## The member a traveller becomes here (always with the fifth entry: they keep their name and skills for good).
func _member_of(p: Dictionary) -> Array:
	return [day - roundi(float(p.age) * _yd), int(p.sex), int(p.get("pair", 0)), int(p.unw), {"n": str(p.n), "f": str(p.f), "sk": (p.sk as Dictionary).duplicate()}, int(p.get("id", 0))]


func _cross_in(coins: int, goods: Dictionary, people: int) -> void:
	flows.outside_coins_in += coins
	for k in goods:
		_add(flows.outside_in, k, int(goods[k]))
	flows.migrants_in += people


func _cross_out(coins: int, goods: Dictionary, people: int) -> void:
	flows.outside_coins_out += coins
	for k in goods:
		_add(flows.outside_out, k, int(goods[k]))
	flows.migrants_out += people


## What would leave with member `j` of household `hi`: their share of its coins and pantry (all of it when they are its last
## member, as in _marry). Nothing is changed.
func person_load(hi: int, j: int) -> Dictionary:
	var h: Dictionary = hh[hi]
	var n: int = h.mem.size()
	var goods := {}
	for k in h.pantry:
		var q: int = int(h.pantry[k]) if n == 1 else int(h.pantry[k]) / n
		if q > 0:
			goods[k] = q
	if n == 1:
		_with_own(h, goods)                 # the last member takes the household's own trade too (release_person winds it up)
	return {"people": [_pack_of(h.mem[j], 0)], "coins": int(h.coins) + _own_till(h) if n == 1 else int(h.coins) / n, "goods": goods}


## Member `j` leaves household `hi` with person_load's coins and goods; the household closes if they were its last.
func release_person(hi: int, j: int) -> Dictionary:
	_fold_live([hh[hi].mem[j]])
	if (hh[hi].mem as Array).size() <= 1:
		_wind_up_own(hh[hi])                                     # REGION-NAV-01 Q4: the last of the household takes its own trade's purse and stock
	var l := person_load(hi, j)
	var h: Dictionary = hh[hi]
	h.coins -= int(l.coins)
	for k in l.goods:
		_take(h.pantry, k, int(l.goods[k]))
	_remove_member(h, j)
	if h.mem.is_empty():
		_ttrace("last_member_leaves", hi)
		h.alive = false
		h.credit = 0.0
	_recount(h)
	_cross_out(int(l.coins), l.goods, 1)
	return l


## What would leave with the whole of household `hi`.
func household_load(hi: int) -> Dictionary:
	var h: Dictionary = hh[hi]
	var people := []
	for m in h.mem:
		people.append(_pack_of(m, int(m[M_PAIR])))
	var goods: Dictionary = (h.pantry as Dictionary).duplicate()
	_with_own(h, goods)                     # REGION-NAV-01 Q4: and its own trade's purse and stock (release_household winds it up)
	return {"people": people, "coins": int(h.coins) + _own_till(h), "goods": goods}


## A household's own trade, counted into what it would take when it leaves (nothing changes: the wind-up is at the release).
func _own_till(h: Dictionary) -> int:
	return int((own.get(str(h.id), {}) as Dictionary).get("till", 0))


func _with_own(h: Dictionary, goods: Dictionary) -> void:
	var o: Dictionary = own.get(str(h.id), {})
	for i in o.get("stock", {}):
		goods[i] = int(goods.get(i, 0)) + int(o.stock[i])


## The whole household leaves with its coins and pantry; it is dissolved (its business keeps its other households).
func release_household(hi: int) -> Dictionary:
	_ttrace("household_leaves", hi)
	_fold_live(hh[hi].mem)
	_wind_up_own(hh[hi])                                         # REGION-NAV-01 Q4: its own trade goes with it (purse and stock)
	var l := household_load(hi)
	var h: Dictionary = hh[hi]
	h.coins = 0
	h.pantry = {}
	h.credit = 0.0
	h.mem = []
	h.alive = false
	_recount(h)
	_cross_out(int(l.coins), l.goods, l.people.size())
	return l


## A household arrives and joins business `bt` (a settlement has no houses: a new household needs none). Returns its id.
func receive_household(people: Array, coins: int, goods: Dictionary, bt: String) -> int:
	if not biz.has(bt) or bt == "merchant":
		bt = "farm" if biz.has("farm") else str(biz.keys()[0])
	var mem := []
	for p in people:
		mem.append(_member_of(p))
	var h := {"id": hh.size(), "trade": _trade_of(bt), "adults": 0, "children": 0, "coins": coins, "pantry": goods.duplicate(), "credit": 0.0,
		"hungry": 0, "acc": {}, "alive": true, "inc": 0, "stay": 0, "mem": mem, "parents": [], "kids": [], "low": 0, "rate": 0.0, "landless": 0}
	hh.append(h)
	biz[bt].workers.append(h.id)
	_recount(h)
	_cross_in(coins, goods, people.size())
	return int(h.id)


## One person arrives to work in business `bt`: they join its smallest living worker household.
func receive_person(p: Dictionary, coins: int, goods: Dictionary, bt: String) -> int:
	if not biz.has(bt) or bt == "merchant":
		bt = "farm" if biz.has("farm") else str(biz.keys()[0])
	var host := -1
	for i in biz[bt].workers:
		if hh[i].alive and (host < 0 or hh[i].mem.size() < hh[host].mem.size()):
			host = int(i)
	if host < 0:
		return receive_household([p], coins, goods, bt)
	var h: Dictionary = hh[host]
	h.mem.append(_member_of(p))
	h.coins += coins
	for k in goods:
		_add(h.pantry, k, int(goods[k]))
	_recount(h)
	_cross_in(coins, goods, 1)
	return host


## A bride from the village marries the member `gj` of household `gi`: they found a household of their own with an equal share of his
## household's coins and pantry and everything she brought, take up his trade and join its business (as _marry does for two members).
func wed_in(gi: int, gj: int, p: Dictionary, coins: int, goods: Dictionary) -> int:
	var gh: Dictionary = hh[gi]
	var gm: Array = gh.mem[gj]
	var trade := str(gh.trade)
	var bt := ""
	if trade != "official" and TRADE_BIZ.has(trade) and biz.has(TRADE_BIZ[trade]):
		bt = TRADE_BIZ[trade]
	else:
		bt = "farm" if biz.has("farm") else str(biz.keys()[0])
		trade = _trade_of(bt)
	var bm := _member_of(p)
	bm[M_PAIR] = 1
	gm[M_PAIR] = 1
	var h := {"id": hh.size(), "trade": trade, "adults": 2, "children": 0, "coins": coins, "pantry": goods.duplicate(), "credit": 0.0, "hungry": 0,
		"acc": {}, "alive": true, "inc": 0, "stay": 0, "mem": [bm, gm], "parents": [int(gh.id)], "kids": [], "low": 0, "rate": 0.0, "landless": 1}
	var n: int = gh.mem.size()
	var cs: int = int(gh.coins) if n == 1 else int(gh.coins) / n
	gh.coins -= cs
	h.coins += cs
	for k in gh.pantry.keys():
		var q: int = int(gh.pantry[k]) if n == 1 else int(gh.pantry[k]) / n
		if q > 0:
			_take(gh.pantry, k, q)
			_add(h.pantry, k, q)
	if n == 1:
		h.credit = _q(float(gh.credit))
		gh.credit = 0.0
	gh.mem.remove_at(gj)
	gh.kids.append(h.id)
	hh.append(h)
	biz[bt].workers.append(h.id)
	flows.households_formed += 1
	if gh.mem.is_empty():
		_wind_up_own(gh)
		gh.alive = false
		for k in gh.pantry:
			_add(h.pantry, k, int(gh.pantry[k]))
		gh.pantry = {}
		h.coins += int(gh.coins)
		gh.coins = 0
	_recount(gh)
	_recount(h)
	_cross_in(coins, goods, 1)
	return int(h.id)


# ------------------------------------------------------------------ saving ----------------
## Take the present coins, goods and horses as the opening books and clear the flow lines (a test that sets a purse or a
## stock by hand does this so audit() measures from there).
func reopen_books() -> void:
	flows = _blank_flows()
	flows.horses_start = horses()
	dev["seen"] = {}
	start = {"coins": coins(), "goods": goods()}


## Float accumulators with the arithmetic's dust (1e-17, minus zero) taken off, so a saved and loaded settlement is the same
## to the last digit.
static func _clean(d: Dictionary) -> void:
	for k in d:
		if d[k] is float and absf(d[k]) < 1e-9:
			d[k] = 0.0


func to_dict() -> Dictionary:
	var hs: Array = hh.duplicate(true)
	for h in hs:
		_clean(h.acc)
		if absf(float(h.credit)) < 1e-9:
			h.credit = 0.0
	var bs: Dictionary = biz.duplicate(true)
	for t in bs:
		_clean(bs[t].acc)
	var gv: Dictionary = gov.duplicate(true)
	_clean(gv.acc)
	return {"id": id, "name": name, "kind": kind, "gov_name": gov_name, "miles": miles, "x": pos.x, "y": pos.y,
		"industries": industries.duplicate(), "hh": hs, "biz": bs, "gov": gv, "own": _own_save(),
		"prices": prices.duplicate(), "toll_acc": _toll_acc, "flows": flows.duplicate(true), "start": start.duplicate(true), "day": day,
		"tax": tax.duplicate(true), "journal": journal.duplicate(true), "closed": closed.duplicate(true), "dev": dev.duplicate(true),
		"transit": transit.duplicate(true), "hamlet": hamlet, "lord": lord, "market": market, "water": water, "well": well,
		"trips": trips.duplicate(true), "trip_seq": trip_seq}


static func from_dict(d: Dictionary) -> OffMapSettlement:
	data()
	var s := OffMapSettlement.new()
	s.id = str(d.id)
	s.name = str(d.name)
	s.kind = str(d.kind)
	s.gov_name = str(d.gov_name)
	s.miles = int(d.miles)
	s.pos = Vector2i(int(d.x), int(d.y))
	s.industries = (d.industries as Array).duplicate()
	s.day = int(d.day)
	for h in d.hh:
		var c: Dictionary = h.duplicate(true)
		for k in ["id", "adults", "children", "coins", "hungry"]:
			c[k] = int(c[k])
		c.inc = int(c.get("inc", 0))
		c.stay = int(c.get("stay", 0))
		c.low = int(c.get("low", 0))                       # MIGRATE-18 (optional keys: an older save has none)
		c.rate = float(c.get("rate", 0.0))
		c.landless = int(c.get("landless", 0))
		c.parents = (c.get("parents", []) as Array).map(func(x): return int(x))
		c.kids = (c.get("kids", []) as Array).map(func(x): return int(x))
		if c.has("mem"):
			c.mem = (c.mem as Array).map(func(m): return _member_from(m))
		c.credit = float(c.credit)
		c.pantry = _ints(c.pantry)
		var acc := {}
		for k in c.acc:
			acc[k] = float(c.acc[k])
		c.acc = acc
		s.hh.append(c)
	s._yd = Life.year_days()
	s._lim = float(Life.cfg().adolescent_until)
	s._mort_from = float(Life.cfg().mortality_from)
	var nrng := RandomNumberGenerator.new()           # a save from before REG-DEMO-01 has no ages: drawn from the settlement's own id and day
	nrng.seed = str(d.id).hash() + s.day * 7919 + 31
	for c in s.hh:
		if not c.has("mem"):
			s._seed_ages(c, nrng, s.day)
		else:
			s._recount(c)
	for t in d.biz:
		s.biz[t] = _biz_from(d.biz[t])
	for k in d.get("own", {}):                         # REGION-NAV-01 Q4 (optional key): older saves have no self-employed crafters
		s.own[str(k)] = _biz_from(d.own[k])
	for t in d.get("closed", {}):
		s.closed[t] = _biz_from(d.closed[t])
	s.add_new_outputs()
	var dv: Dictionary = d.get("dev", {})
	s.dev = {"seen": _ints(dv.get("seen", {})), "streak": _ints(dv.get("streak", {}))}
	var g: Dictionary = (d.gov as Dictionary).duplicate(true)
	g.coins = int(g.coins)
	g.granary = _ints(g.granary)
	g.officials = (g.officials as Array).map(func(x): return int(x))
	if g.has("consign"):                                       # B25-ECON-P6 (another place's goods and pay a closed trader left; optional)
		var gc := {}
		for item in g.consign:
			gc[str(item)] = _ints(g.consign[item])
		g.consign = gc
	_consign_from(g)
	var gacc := {}
	for k in g.acc:
		gacc[k] = float(g.acc[k])
	g.acc = gacc
	s.gov = g
	for k in d.prices:
		s.prices[k] = float(d.prices[k])
	s.flows = _blank_flows()
	for k in FLOW_GOODS:
		s.flows[k] = _ints(d.flows.get(k, {}))
	for k in FLOW_COUNTS:
		s.flows[k] = int(d.flows.get(k, 0))
	s._toll_acc = float(d.get("toll_acc", 0.0))
	s.tax = (d.get("tax", {}) as Dictionary).duplicate(true)             # DVW-B5 (optional key: an older save starts in the band the treasury shows)
	if s.tax.has("band"):
		s.tax.band = int(s.tax.band)
		var pd: Dictionary = s.tax.get("pending", {})
		if not pd.is_empty():
			pd.to = int(pd.to)
			pd.announced = int(pd.announced)
			pd.effective = int(pd.effective)
	for e in d.get("journal", []):
		s.journal.append({"day": int(e.day), "text": str(e.text)})
	s.start = {"coins": int(d.start.coins), "goods": _ints(d.start.goods)}
	for e in d.get("transit", []):                             # X20-SETTLE-FOOD (optional keys: an older save has nothing on the road)
		s.transit.append({"tx": str(e.tx), "to": str(e.to), "item": str(e.item), "n": int(e.n), "from": str(e.from),
			"sent": int(e.sent), "due": int(e.due), "coins": int(e.get("coins", 0))})
	s.hamlet = bool(d.get("hamlet", false))                  # B25R1-018/019 (optional keys)
	s.lord = str(d.get("lord", ""))
	s.market = str(d.get("market", ""))
	s.water = str(d.get("water", ""))
	s.well = str(d.get("well", ""))
	s.trip_seq = int(d.get("trip_seq", 0))
	for t in d.get("trips", []):
		s.trips.append(SettlementTrips.from_dict(t))
	return s


## A business as saved (an older save has no `idle`).
## B25 Decision 5 (additive save migration): a business saved before an output was added to its type (the weavers' raw
## silk) or to its settlement's diggings (Garton's tin and its finite reserve) gains it, as a new world would have it;
## nothing it already has changes. The ground's reserve is geology (like the hill's hidden veins, regenerated from the
## data), never goods: nothing enters any stock until it is worked.
func add_new_outputs() -> void:
	var spec := {}
	for sp in data().settlements:
		if str(sp.id) == id:
			spec = sp
	for t in biz:
		var b: Dictionary = biz[t]
		if not b.has("out"):
			b.out = {}
		var outs: Dictionary = spec.get("quarry", {}) if str(t) == "quarry" else btype(str(t)).get("out", {})
		for k in outs:
			if not (b.out as Dictionary).has(k):
				b.out[k] = outs[k]
				if str(t) == "quarry" and (spec.get("reserves", {}) as Dictionary).has(k) and not (b.reserves as Dictionary).has(k):
					b.reserves[k] = int(spec.reserves[k])


static func _biz_from(bd: Dictionary) -> Dictionary:
	var b: Dictionary = bd.duplicate(true)
	for k in ["till", "reserve", "horses", "foal", "fed_miss"]:
		b[k] = int(b[k])
	b.paid = int(b.get("paid", 0))
	b.week = int(b.get("week", 0))
	b.idle = int(b.get("idle", 0))
	b.rate = float(b.get("rate", 0.0))
	b.workers = (b.workers as Array).map(func(x): return int(x))
	b.stock = _ints(b.stock)
	b.reserves = _ints(b.reserves)
	if b.has("imported"):                                      # X20-SETTLE-FOOD (a trader's imported food; optional)
		b.imported = _ints(b.imported)
	if b.has("consign"):                                       # B25-ECON-P4 (a trader's consigned goods by source; optional)
		var c := {}
		for item in b.consign:
			c[str(item)] = _ints(b.consign[item])
		b.consign = c
	_consign_from(b)                                           # B25-ECON-P6 (pay set aside for another place's sources; optional)
	var acc := {}
	for k in b.acc:
		acc[k] = float(b.acc[k])
	b.acc = acc
	return b


## A member as saved: the four numbers, and the fifth entry (the person's name and skills) when they came from the village.
static func _member_from(m: Array) -> Array:
	var out := [int(m[0]), int(m[1]), int(m[2]), int(m[3])]
	if m.size() > M_WHO and m[M_WHO] is Dictionary:
		var w: Dictionary = m[M_WHO]
		if w.is_empty():
			out.append({})                                  # ID-01: a member born here has no carried name
		else:
			var sk := {}
			for k in w.get("sk", {}):
				sk[str(k)] = int(w.sk[k])
			out.append({"n": str(w.get("n", "")), "f": str(w.get("f", "")), "sk": sk})
	if m.size() > M_ID:
		out.append(int(m[M_ID]))                            # ID-01 (save 20; absent in an older save)
	if m.size() > M_BODY and m[M_BODY] is Dictionary:      # B25R1-019 (optional: absent in an older save)
		var b: Dictionary = m[M_BODY]
		var sk := {}
		for k in b.get("sk", {}):
			sk[str(k)] = int(b.sk[k])
		out.append({"hp": float(b.get("hp", 30.0)), "max": float(b.get("max", 30.0)), "sk": sk})
	return out


static func _ints(d: Dictionary) -> Dictionary:
	var o := {}
	for k in d:
		o[k] = int(d[k])
	return o
