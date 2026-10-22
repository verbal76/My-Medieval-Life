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
	"outside_coins_in", "outside_coins_out"]
## A member of a household (REG-DEMO-01): [born, sex, partnered, unwilling]. `born` is a settlement day number (negative before the
## first step), so age in years is (day - born) / the calendar's year length and needs no daily update; sex 1 is female; partnered 1
## means the member is one of the household's couple; unwilling 1 is a person who will not marry (decided once, at birth or founding).
const M_BORN := 0
const M_SEX := 1
const M_PAIR := 2
const M_UNWILLING := 3

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
var biz: Dictionary = {}             # business type -> {type, workers[], till, stock{}, reserves{}, out{}, acc{}, reserve, horses, foal, fed_miss}
var gov: Dictionary = {}             # {coins, granary{}, officials[], acc{}}
var prices: Dictionary = {}          # item -> float, the market price (today's whole-coin price is its rounding)
var flows: Dictionary = {}
var start: Dictionary = {}           # the opening books {coins, goods}
var day := -1
var _dem: Dictionary = {}            # today's requests and offers (not saved)
var _sup: Dictionary = {}
var _offers: Dictionary = {}         # item -> [{b, n}] while the market is open
var _pcache: Dictionary = {}         # today's whole-coin prices (cleared when a day starts and when prices move)
var _avail: Dictionary = {}          # item -> units on offer in all open offers
var _toll_acc := 0.0
var _want_left: Dictionary = {}      # what the settlement still wants this visit (begin_visit)


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
	s.industries = (spec.get("industries", []) as Array).duplicate()
	s.gov_name = str(spec.government.name)
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
				"credit": 0.0, "hungry": 0, "acc": {}, "alive": true, "inc": 0, "stay": 0}
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
				"horses": 0, "foal": 0, "fed_miss": 0, "paid": 0, "week": 0}
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
			var p := Life.death_chance(ag) if ag >= _mort_from else 0.0
			if p > 0.0 and (p >= 1.0 or _roll(salt, day * 7 + 1, int(m[M_BORN]) * 64 + i) < p):
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
	h.mem.append([day, sex, 0, unw])
	flows.births += 1
	_recount(h)


## Take member `j` out of a household (death); the caller then runs _after_loss.
func _remove_member(h: Dictionary, j: int) -> void:
	var m: Array = h.mem[j]
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
	var heir := _heir(h)
	if heir < 0 and not h.mem.is_empty():
		heir = _guardian(h)
	h.alive = false
	if heir < 0:
		flows.deaths += h.mem.size()                         # no household anywhere to take the children in
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
		"alive": true, "inc": 0, "stay": 0, "mem": [wm, mm], "parents": [int(wh.id), int(mh.id)], "kids": []}
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
		n += int(biz[t].till)
	return n


func goods() -> Dictionary:
	var g := {}
	for h in hh:
		for k in h.pantry:
			_add(g, k, int(h.pantry[k]))
	for t in biz:
		for k in biz[t].stock:
			_add(g, k, int(biz[t].stock[k]))
	for k in gov.granary:
		_add(g, k, int(gov.granary[k]))
	return g


func horses() -> int:
	return int(biz.farm.horses) if biz.has("farm") else 0


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
	_market()
	if profile:
		t0 = _lap("market", t0)
	_produce()
	if profile:
		t0 = _lap("produce", t0)
	_pay_wages()
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
	for k in types.size():
		var b: Dictionary = biz[types[(k + rot) % types.size()]]
		var keep := _keep(b)
		var items: Array = b.stock.keys()
		items.sort()
		for item in items:
			var n := int(b.stock[item]) - int(keep.get(item, 0))
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
	for t in types:
		var b: Dictionary = biz[t]
		var T := btype(t)
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
	var holiday := float(ob) * float(GameData.b("treasury_tax_holiday_days"))
	var reserve := float(ob) * float(GameData.b("treasury_reserve_days"))
	if float(gov.coins) < holiday:
		var rate := float(GameData.b("tax_rate_low_treasury")) if float(gov.coins) < reserve else float(GameData.b("tax_rate_normal"))
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
	var best := ""
	for t in types:
		if t != "merchant" and _workers(biz[t]) > 0 and float(pay[t]) >= float(_rules.switch_to_at_least) and (best == "" or float(pay[t]) > float(pay[best])):
			best = t
	if best != "":
		for t in types:
			var b: Dictionary = biz[t]
			if t == best or _workers(b) <= 1:
				continue                       # a trade is never left with no household: the settlement keeps its character
			for i in b.workers.duplicate():
				var h: Dictionary = hh[i]
				if h.alive and int(h.stay) >= int(_rules.switch_stay_days) and float(h.inc) / 7.0 < float(_rules.switch_below) \
						and float(pay[best]) >= 2.0 * float(h.inc) / 7.0:
					b.workers.erase(i)
					biz[best].workers.append(i)
					h.trade = _trade_of(best)
					h.stay = 0
					flows.job_moves += 1
					break                      # one household a business a week
	for t in types:
		biz[t].week = 0
	for h in hh:
		h.inc = 0


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


func want_left(item: String) -> int:
	return int(_want_left.get(item, 0))


func trader_cash() -> int:
	var m := trader()
	return 0 if m.is_empty() else maxi(0, int(m.till) - int(_rules.trader_reserve_floor))


func trader_has(item: String) -> int:
	var m := trader()
	return 0 if m.is_empty() else int(m.stock.get(item, 0))


## The trader sells `n` of `item` to the village at `unit` coins each: the goods leave its stock, the coins enter its till.
func sell_to_village(item: String, n: int, unit: int) -> bool:
	var m := trader()
	if m.is_empty() or n <= 0 or int(m.stock.get(item, 0)) < n:
		return false
	_take(m.stock, item, n)
	m.till += n * unit
	_add(flows.to_village, item, n)
	flows.coins_from_village += n * unit
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
	return {"id": id, "population": population(), "households": households(), "hungry": hungry, "deaths": int(flows.deaths),
		"coins": coins(), "household_coins": cash, "tills": tills, "treasury": int(gov.coins),
		"trader": int(trader().get("till", 0)), "pantry_days": food_pts / maxf(1.0, need), "horses": horses(),
		"wage_short": int(flows.wage_short), "relief": int(flows.relief_units), "births": int(flows.births),
		"age_deaths": int(flows.age_deaths), "households_formed": int(flows.households_formed)}


# ------------------------------------------------------------------ saving ----------------
## Take the present coins, goods and horses as the opening books and clear the flow lines (a test that sets a purse or a
## stock by hand does this so audit() measures from there).
func reopen_books() -> void:
	flows = _blank_flows()
	flows.horses_start = horses()
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
		"industries": industries.duplicate(), "hh": hs, "biz": bs, "gov": gv,
		"prices": prices.duplicate(), "toll_acc": _toll_acc, "flows": flows.duplicate(true), "start": start.duplicate(true), "day": day}


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
		c.parents = (c.get("parents", []) as Array).map(func(x): return int(x))
		c.kids = (c.get("kids", []) as Array).map(func(x): return int(x))
		if c.has("mem"):
			c.mem = (c.mem as Array).map(func(m): return [int(m[0]), int(m[1]), int(m[2]), int(m[3])])
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
		var b: Dictionary = (d.biz[t] as Dictionary).duplicate(true)
		for k in ["till", "reserve", "horses", "foal", "fed_miss"]:
			b[k] = int(b[k])
		b.paid = int(b.get("paid", 0))
		b.week = int(b.get("week", 0))
		b.workers = (b.workers as Array).map(func(x): return int(x))
		b.stock = _ints(b.stock)
		b.reserves = _ints(b.reserves)
		var acc := {}
		for k in b.acc:
			acc[k] = float(b.acc[k])
		b.acc = acc
		s.biz[t] = b
	var g: Dictionary = (d.gov as Dictionary).duplicate(true)
	g.coins = int(g.coins)
	g.granary = _ints(g.granary)
	g.officials = (g.officials as Array).map(func(x): return int(x))
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
	s.start = {"coins": int(d.start.coins), "goods": _ints(d.start.goods)}
	return s


static func _ints(d: Dictionary) -> Dictionary:
	var o := {}
	for k in d:
		o[k] = int(d[k])
	return o
