class_name Ventures
extends RefCounted
## B25-BUSINESS-IMPL (owner B25-BUSINESS-D2, 2026-11-01, docs/directives/2026-11-01_career_business_employment_final_decisions.md
## Decision 2 and sections 5-6; design docs/expansion20/BUSINESS_FOUNDING.md): villagers found businesses of their own.
##
## A villager business ("venture") is a workshop of the founder's trade built beside their household's own house through the
## existing construction rules (Construction.place with the house as anchor: the ground bought from the manor on the spot, the
## materials delivered by the household and its hired helpers, hh.build), plus a record of who keeps it. Nothing is made here:
## coins move only through the land office and the builders' purchases, goods only through the site's deliveries, and the
## workshop's goods are made and sold through the existing crafting and trade paths (no guaranteed customer, no stock given).
##
## Each dawn (daily, after the housing work of Construction.daily):
## - a finished venture site opens: the record moves to the workshop (`building.venture`), the founder works its stations;
## - an open venture is checked: a keeper who died or left the trade is followed by a household member of the trade (a change
##   of hands), else it closes; one with no work at its stations for close_idle_days days in a row closes; one whose building
##   left the household closes. Closing takes nothing: the workshop stays its owner's property under the existing rules;
## - a villager on their own weekly morning (looks_today) is considered for founding when ability, experience, premises,
##   capital and household finances allow (eligible), and decides through the shared weighing (JudgmentWeighting, profile
##   "business_found"), the trade's demand one of its factors (B25-ECON-P1, owner 2026-11-05: idle benches no longer refuse);
##   with the judgment layer off nobody founds.
## Hiring: an open venture's stations are room for its trade in the labour market (NPCBrain.skilled_place); a hand taken for
## one is given the keeper's leave (World.permit) and works there under the existing skilled model (took_place).
##
## State: household.venture {founder, trade, kind, plot, day} while setting up; building.venture {founder, keeper, trade, day,
## opened, household, idle, hands} once open. Both saved with their dicts (older saves: none).
##
## B25-BIZ-OWN (owner, 2026-11-01, docs/directives/2026-11-01_business_ownership_employment_final_decisions.md; specification
## docs/expansion20/BUSINESS_OWNERSHIP.md):
## - D1: an open venture keeps its own till in its record (till, earned, paid, costs, invested, drawn: BusinessMoney's
##   settlement, ref "venture:<building id>"). On opening the household invests working capital. The business's goods are
##   bookkept, never moved: the keeper's in `venture.goods`, a paid employee's in their employment record's `owed`; they are
##   the units bought with the till's money (budget, fund) or made at its stations by its people (craft_begin/craft_end), and
##   their sale pays the till (on_sale). Optional keys; an older open venture reads as an empty till.
## - D2: the hands stay independent craftspeople (their own materials and sales); a venture also hires paid employees
##   (_hire, Employment.hire_for) when it has work, room and the money.

var w: World
## Diagnostics only (B25 economic investigation, economy_sim's FUNNEL line): the key of the stage at which `refusal` last
## stopped ("" when it did not). Written by refusal, read by _consider for its venture_refused_<key> counts; nothing in the
## game decides by it, and it is not saved.
var last_refusal := ""


func _init(world: World) -> void:
	w = world


static func cfg() -> Dictionary:
	return GameData.b("ventures")


## The workshop kind trade `job` founds ("" none).
static func kind_for(job: String) -> String:
	return str((cfg().get("kinds", {}) as Dictionary).get(job, ""))


# ---------------------------------------------------------------- reading -----------------------
## Open ventures' workshops, in building id order.
func open_ventures() -> Array:
	var out := []
	var ids: Array = w.buildings.keys()
	ids.sort()
	for id in ids:
		if (w.buildings[id] as Dictionary).has("venture"):
			out.append(w.buildings[id])
	return out


## The open venture whose workshop holds station `st` ({} none).
func venture_at(st: String) -> Dictionary:
	if not w.stations.has(st):
		return {}
	var b: Dictionary = w.buildings.get(str(w.stations[st].get("building", "")), {})
	return b if b.has("venture") else {}


## Whether station `st` is an open venture's, so a hire may be placed there with the keeper's leave (skilled_place).
func hiring_station(st: String) -> bool:
	return not venture_at(st).is_empty()


## The stations of `b` that trade `job` works at, in id order.
func trade_stations(b: Dictionary, job: String) -> Array:
	var kinds: Array = NPCBrain.TRADE_STATIONS.get(job, [])
	var out := []
	var ids: Array = w.stations.keys()
	ids.sort()
	for id in ids:
		var st: Dictionary = w.stations[id]
		if str(st.get("building", "")) == str(b.id) and kinds.has(str(st.type)):
			out.append(id)
	return out


## The venture stations of kind `kind` that `n` keeps or works at (tried first by NPCBrain._station_for), in id order.
func stations_for(n: NPC, kind: String) -> Array:
	var out := []
	for b in open_ventures():
		var v: Dictionary = b.venture
		if int(v.keeper) != n.id and not (v.hands as Array).has(n.id) and str(w.employment.record_of(n).get("employer", "")) != ref_of(b):
			continue
		for id in trade_stations(b, str(v.trade)):
			if str(w.stations[id].type) == kind:
				out.append(id)
	return out


## The venture `n` keeps ({} none).
func kept_by(n: NPC) -> Dictionary:
	for b in open_ventures():
		if int(b.venture.keeper) == n.id:
			return b
	return {}


## Ventures being set up: household index -> its record.
func setting_up() -> Dictionary:
	var out := {}
	for h in w.households.size():
		if (w.households[h] as Dictionary).has("venture"):
			out[h] = w.households[h].venture
	return out


# ---------------------------------------------------------------- each dawn ---------------------
func daily() -> void:
	_review_setup()
	_open_finished()
	for b in open_ventures():
		_check(b)
	for b in open_ventures():
		_hire(b)
	_list_unused()
	_consider()


## A finished venture site opens; a site that is gone (cancelled, the household ended) ends the setting up.
func _open_finished() -> void:
	for h in w.households.size():
		var hh: Dictionary = w.households[h]
		if not hh.has("venture"):
			continue
		var rec: Dictionary = hh.venture
		var p: Dictionary = w.plot(str(rec.plot))
		if hh.get("ended", false) or p.is_empty() or p.site.is_empty():
			hh.erase("venture")
			w.stat("ventures_abandoned")
			continue
		if not p.site.get("done", false) or not w.buildings.has(str(p.get("building", ""))):
			continue
		hh.erase("venture")
		var b: Dictionary = w.buildings[str(p.building)]
		_open(b, int(rec.founder), str(rec.trade), h, int(rec.day), bool(rec.get("expansion", false)))
		_check(b)


## A venture opens in workshop `b` (built, bought or taken on): the record, the founder at its stations, and (B25-BIZ-D1) the
## household's working capital invested in its till: working_days of its daily costs, as far as its head's coins above the
## necessity reserve allow (World.spendable; never the protected reserve).
func _open(b: Dictionary, founder: int, trade: String, h: int, day: int, expansion := false) -> void:
	b.venture = {"founder": founder, "keeper": founder, "trade": trade, "day": day,
		"opened": w.day(), "household": h, "idle": 0, "hands": [], "till": 0, "earned": 0, "paid": 0, "costs": {}, "goods": {}}
	w.stat("ventures_opened")
	var head: NPC = w.party(World.hh_ref(h))
	if expansion:
		# its working capital comes from the keeper's first business (the runway kept for staffing it), through the household
		var first: Dictionary = {}
		for o in open_ventures():
			if o != b and int(o.venture.keeper) == founder and not bool(o.venture.get("expansion", false)):
				first = o
				break
		var runway: int = w.employment.market_wage(trade) * int(cfg().get("hire_runway_days", 7))
		var move := mini(runway, BusinessMoney.venture_till_of(first)) if not first.is_empty() else 0
		if head != null and move > 0 and w.business.money.pay_out(first, "venture", head, move, "premises"):
			w.business.money.invest(b, "venture", head, move)
	else:
		var econ: Dictionary = w.households[h].get("econ", {}) if h >= 0 and h < w.households.size() else {}
		var working := ceili(float(econ.get("cost", 0.0)) * float(cfg().working_days))
		var put := mini(working, w.spendable(head)) if head != null else 0
		if put > 0 and w.business.money.invest(b, "venture", head, put):
			w.stat("venture_capital", put)
	if expansion:
		b.venture.expansion = true          # B25-BIZ-D5: a second workshop of the keeper's, staffed by hiring
		w.stat("ventures_expanded")
		w.note("%s now has a second workshop: %s." % [w.ref_name(World.hh_ref(h), true), w.property.describe(b)])
		return
	var k := w.npc(founder)
	if k != null and k.alive and k.job == trade and k.household == h:
		_work_here(k, b)
		w.note("%s %s opens %s %s." % [k.name, k.family, "a" if not str(b.kind).begins_with("a") else "an", Construction.kind_name(str(b.kind))])


## An open venture's morning: its hands, its keeper (a change of hands or closing), its work.
func _check(b: Dictionary) -> void:
	if not b.has("venture"):
		return
	var v: Dictionary = b.venture
	var h := int(v.household)
	var trade := str(v.trade)
	if h >= w.households.size() or w.households[h].get("ended", false) or w.owner_of(b) != World.hh_ref(h):
		close(b, "the workshop is no longer the family's")
		return
	var hands := []
	for id in v.hands:
		var o := w.npc(int(id))
		if o != null and o.alive and o.job == trade:
			hands.append(int(id))
		elif o != null:
			w.permit(b, World.npc_ref(o.id), false)
	v.hands = hands
	var k := w.npc(int(v.keeper))
	if k == null or not k.alive or k.job != trade or k.household != h:
		var next: NPC = null
		for o: NPC in w.brain._members(h):
			if o.alive and o.role == "adult" and o.job == trade and (next == null or o.id < next.id):
				next = o
		if next == null:
			close(b, "nobody of the family keeps it on")
			w.stat("ventures_closed_keeper")
			return
		v.keeper = next.id
		v.hands.erase(next.id)
		_work_here(next, b)
		w.stat("venture_handovers")
		w.note("%s %s now keeps %s." % [next.name, next.family, w.property.describe(b)])
	# yesterday's work at its stations (World.station_load, the record skilled hiring reads)
	w.brain._roll_station_load()
	var past: Array = w.station_load.get("past", [])
	if past.is_empty() or int(v.opened) >= w.day():
		return
	var mins := 0.0
	var yday: Dictionary = past.back()
	for st in trade_stations(b, trade):
		var by: Dictionary = yday.get(st, {})
		for j in by:
			mins += float(by[j])
	v.idle = 0 if mins > 0.0 else int(v.idle) + 1
	if int(v.idle) >= int(cfg().close_idle_days):
		close(b, "there was no work for it")
		w.stat("ventures_closed_idle")


## The venture closes: its hands lose the keeper's leave, everyone who worked there goes back to a station they may use, and
## the record leaves the building. The workshop, its stations and everything in them stay the owner's (existing rules).
func close(b: Dictionary, why: String) -> void:
	if not b.has("venture"):
		return
	var v: Dictionary = b.venture
	for rec in w.employment.of_employer(ref_of(b)):      # B25-BIZ-D2: its paid employees' employment ends with it
		w.employment.end(rec, "the business closed")
	w.business.money._keep(b, "venture", w.business.money.venture_owner(b))   # B25-BIZ-D1, TILL-D1: its till goes to its household
	b.erase("venture")
	var people: Array = (v.hands as Array).duplicate()
	people.append(int(v.keeper))
	for id in people:
		var o := w.npc(int(id))
		if o == null:
			continue
		if (v.hands as Array).has(int(id)):
			w.permit(b, World.npc_ref(o.id), false)
		if w.stations.has(o.workplace) and str(w.stations[o.workplace].get("building", "")) == str(b.id) and int(id) != int(v.keeper):
			o.workplace = _other_station(o, str(v.trade))
	w.stat("ventures_closed")
	w.note("%s closes: %s." % [w.property.describe(b).capitalize(), why])


## A station of trade `job` that `n` may use outside any venture ("" none).
func _other_station(n: NPC, job: String) -> String:
	for kind in NPCBrain.TRADE_STATIONS.get(job, []):
		for st in w.stations_of(kind):
			if venture_at(st).is_empty() and w.npc_may_use(n, w.stations[st]):
				return st
	return ""


func _work_here(n: NPC, b: Dictionary) -> void:
	var sts := trade_stations(b, str(b.venture.trade))
	if not sts.is_empty():
		n.workplace = str(sts[0])
		n.plan.clear()


## NPCBrain._take_place: `n` took the labour market's place `place`; when it is a venture's station, the keeper gives their leave
## and `n` is one of its hands. The keeper chose them among the applicants by suitability (NPCBrain._hire_skilled).
func took_place(n: NPC, place: String) -> void:
	var b := venture_at(place)
	if b.is_empty() or n.job != str(b.venture.trade) or int(b.venture.keeper) == n.id:
		return
	w.permit(b, World.npc_ref(n.id), true)
	if not (b.venture.hands as Array).has(n.id):
		b.venture.hands.append(n.id)
	w.stat("venture_hires")
	var k := w.npc(int(b.venture.keeper))
	w.note("%s %s takes %s %s on at %s." % [k.name if k != null else "The keeper", k.family if k != null else "", n.name, n.family, w.property.describe(b)])


# ---------------------------------------------------------------- founding ----------------------
## Whether `n` considers founding this morning: their own seeded morning once every look_days.
func looks_today(n: NPC) -> bool:
	var every := maxi(1, int(cfg().look_days))
	return (w.day() + JudgmentMath.hash_ints([w.seed, n.id, 7411]) % every) % every == 0


func _consider() -> void:
	if not JudgmentLive.on(w, "business_found"):
		return
	var busy := {}                       # trades with a venture being set up
	for h in setting_up():
		busy[str(setting_up()[h].trade)] = true
	var markets := {}
	# The venture_* counts below are diagnostics (the founding funnel, B25 economic investigation): w.stat only adds to the
	# world's counters; no decision reads them, and they draw no random number and change no order.
	for n: NPC in w.npcs:
		if kind_for(n.job) == "" or not looks_today(n):
			continue
		var counted := n.alive and n.role == "adult"   # a dead villager's record keeps its job; it is not a look
		if counted:
			w.stat("venture_looks")
		if busy.has(n.job):
			if counted:
				w.stat("venture_refused_trade_setting_up")
			continue
		var opt := eligible(n, markets)
		if opt.is_empty() and counted:
			w.stat("venture_refused_" + last_refusal)
		if opt.is_empty() and not kept_by(n).is_empty():
			opt = expansion(n, markets)        # B25-BIZ-D5: a keeper whose business has the money may open another
		if opt.is_empty():
			continue
		w.stat("ventures_considered")
		w.stat("venture_option_" + ("expand" if opt.has("expand") else "reopen" if opt.has("reopen") else "buy" if opt.has("buy") else "build"))
		if not decides(n, opt):
			w.stat("ventures_declined")
			continue
		if found(n, opt):
			busy[n.job] = true
		else:
			w.stat("ventures_found_failed")


## Why `n` cannot found a business now ("" when they could, the option in `out`): ability and experience, premises, capital
## and household finances (the trade's demand is weighed in `decides`, B25-ECON-P1). `markets`: the trade readings of this morning.
func eligible(n: NPC, markets := {}, out := {}) -> Dictionary:
	var why := refusal(n, markets, out)
	return out if why == "" else {}


func refusal(n: NPC, markets := {}, out := {}) -> String:
	last_refusal = ""
	var c := cfg()
	var job := n.job
	var kind := kind_for(job)
	if kind == "" or not n.alive or n.role != "adult" or n.household < 0:
		last_refusal = "trade"
		return "not in a founding trade"
	var sk: String = w.brain._trade_skill(job)
	var lv := Skills.level(n, sk) if sk != "" and int(n.skills.get(sk, 0)) > 0 else 0
	if lv < int(c.min_level):
		last_refusal = "skill"
		return "not skilled enough yet"
	var ind: String = NPCBrain.TRADE_INDUSTRY.get(job, "")
	var days := w.experience.days(World.npc_ref(n.id), ind) if ind != "" else float(w.day() - n.job_since)
	if days < float(c.min_trade_days):
		last_refusal = "experience"
		return "too little experience in the trade"
	if not kept_by(n).is_empty():
		last_refusal = "keeps_one"
		return "keeps a business already"
	var h := n.household
	var hh: Dictionary = w.households[h]
	var ref := World.hh_ref(h)
	if hh.get("ended", false) or hh.has("venture") or str(hh.get("build", "")) != "" or not (hh.get("housing", {}) as Dictionary).is_empty():
		last_refusal = "household_ended" if hh.get("ended", false) else "household_venture" if hh.has("venture") \
				else "household_building" if str(hh.get("build", "")) != "" else "household_housing_goal"
		return "the household has building or a home to see to first"
	var house: Dictionary = w.buildings.get(str(hh.get("home", "")), {})
	if house.is_empty():
		last_refusal = "no_home"
		return "the household has no home to start from"
	if not markets.has(job):
		markets[job] = w.brain.skilled_place(job)
	# B25-ECON-P1 (owner 2026-11-05): no gate on the trade's benches. A qualified villager with the capital may found while the
	# trade's benches stand idle; the trade's demand (its workers' share of a working day at its stations) is one factor of
	# their own judgment (decides), never a refusal.
	var m: Dictionary = markets[job]
	var econ: Dictionary = hh.get("econ", {})
	if econ.is_empty():
		last_refusal = "means_unknown"
		return "the household's means are not known"
	var spare: int = w.property.purse(ref) - w.construction._keep(h, w.brain._members(h).size()) - w.construction._tool_reserve(h)
	var working := ceili(float(econ.get("cost", 0.0)) * float(c.working_days))
	if spare <= working:
		last_refusal = "money_working"
		return "the household cannot spare the money"
	# B25-BIZ-D5: a workshop of the trade the household already owns opens again; one on sale is bought before one is built
	# ("A person should not be forced to construct a new business when an existing business is available for purchase")
	var info := {"kind": kind, "spare": spare, "busy": float(m.get("busy", 0.0)), "skill": lv}
	var own := own_unused(n)
	if not own.is_empty():
		out.merge(info.merged({"reopen": own, "start": 0, "need": working}), true)
		return ""
	var listed := listed_for(n)
	if not listed.is_empty() and spare >= price_for(listed, n) + working:
		var price := price_for(listed, n)
		out.merge(info.merged({"buy": listed, "price": price, "start": price, "need": price + working}), true)
		return ""
	# Owner 2026-11-02 (B25-BIZ-TENANT-Q Option B): a household that owns its house adds the workshop to that property first;
	# a tenant household (its rented home satisfies "a house first") builds a standalone workshop on ground it buys and never
	# builds onto the landlord's house. Reopening or buying (above) needs no owned residence.
	var anchor := house
	var rect := Rect2i()
	if w.owner_of(house) == ref:
		if w.property.anchor_of(house).is_empty():
			w.property.survey_under(house)   # HOUSE-09: an original house's ground is surveyed (nothing paid, nothing changes hands)
		rect = w.construction.find_module_slot(kind, house, ref)
		if rect.size != Vector2i.ZERO and w.construction.can_place(kind, rect, ref, house) != "":
			rect = Rect2i()
	if rect.size == Vector2i.ZERO:
		anchor = {}                          # else a workshop on its own ground near the house (owner rule: a house first)
		rect = w.construction.find_ground(kind, w.building_door(str(house.id)), ref)
		if rect.size == Vector2i.ZERO:
			last_refusal = "no_ground"
			return "no ground for a workshop"
	var land: int = w.property.land_price(rect.size.x, rect.size.y)
	var start: int = w.construction._start_of(h, w.construction.cost_of(kind), land)
	if spare < start + working:
		last_refusal = "money_start"
		return "the household cannot spare the money"
	out.merge({"kind": kind, "rect": rect, "house": anchor, "start": start, "need": start + working, "spare": spare,
		"busy": float(m.get("busy", 0.0)), "skill": lv}, true)
	return ""


## The founding decision (JudgmentWeighting, profile business_found): ambition, demand, capital and skill against doing without.
func decides(n: NPC, opt: Dictionary) -> bool:
	var j = w.judgment
	if j == null:
		return false
	var a: JudgmentAspiration = j.asp
	var prio := a.eff_priority(n, JudgmentAspiration.PROFESSION, a.survival(n, w), w) if a.enabled else 1000
	var share := float(GameData.b("skilled_places").busy_share)
	var f := {
		"ambition": clampi((prio - 500) * 100, 0, 100000),
		"demand": clampi(roundi(float(opt.busy) / maxf(0.01, 2.0 * share) * 100000.0), 0, 100000),
		"capital": clampi(int(opt.spare) * 50000 / maxi(1, int(opt.need)), 0, 100000),
		"skill": maxi(0, a.skill_fit(n, n.job)),
	}
	var r := JudgmentWeighting.choose(j, j.cfg, n.id, "business_found", [{"id": "found", "factors": f}], [w.day(), n.id])
	return str(r.chosen) == "found"


## `n` founds: the site is marked out beside the household's house, or on ground of its own near it (the ground paid to the
## manor), and the household builds it as
## it builds its rooms (Construction._keep_building). True when the site was marked out.
func found(n: NPC, opt: Dictionary) -> bool:
	var h := n.household
	var ref := World.hh_ref(h)
	if _found_refusal(n, opt) != "":
		return false                       # BIZ-01/02: nothing ended or paid for a founding that cannot happen
	var rec: Dictionary = w.employment.record_of(n)
	if not rec.is_empty():
		w.employment.end(rec, "to run a business of their own")      # B25-BIZ-D4: an employee may leave to set up
	if opt.has("reopen"):                  # B25-BIZ-D5: the household's own workshop opens again
		var rb: Dictionary = opt.reopen
		rb.erase("sale")
		_open(rb, n.id, n.job, h, w.day())
		w.stat("ventures_reopened")
		return true
	if opt.has("expand"):                  # B25-BIZ-D5: the business pays its household for new premises (its cost "premises")
		var biz: Dictionary = opt.expand
		var head: NPC = w.party(ref)
		if head == null or not w.business.money.pay_out(biz, "venture", head, int(opt.start), "premises"):
			return false
		if opt.has("buy"):
			var eb: Dictionary = opt.buy
			if buy_refusal(eb, ref, n) != "" or _transfer(eb, ref, price_for(eb, n), null) != "":
				return false
			_open(eb, n.id, n.job, h, w.day(), true)
			return true
	elif opt.has("buy"):                   # B25-BIZ-D5: bought from a willing seller at the agreed price
		var bb: Dictionary = opt.buy
		return buy_refusal(bb, ref, n) == "" and _transfer(bb, ref, price_for(bb, n), n) == ""
	var p: Dictionary = w.construction.place(str(opt.kind), opt.rect, ref, false, opt.house)
	if p.is_empty():
		return false
	var hh: Dictionary = w.households[h]
	hh.build = str(p.id)
	hh.venture = {"founder": n.id, "trade": n.job, "kind": str(opt.kind), "plot": str(p.id), "day": w.day()}
	if opt.has("expand"):
		hh.venture.expansion = true
	w.stat("ventures_founded")
	w.stat("ventures_founded_" + n.job)
	RegionTrade.note_founding(w, n)          # REGION-NAV-01 S7: counted with its cause (regional demand or local)
	w.note("%s %s sets about building %s of their own." % [n.name, n.family, Construction.kind_name(str(opt.kind), true)])
	w.construction._keep_building(h)
	return true


## BIZ-01/02 (Build 25 audit): why founding `opt` would fail, "" when it can go ahead, checked before anything changes (the
## founder's employment ends, an expanding business pays for the premises): the premises payment (a household head to receive
## it, the till holding it), the workshop on sale at a price the household can pay (with the premises payment, for an
## expansion), else the ground placeable and its price payable to the manor (likewise). A reopening cannot fail.
func _found_refusal(n: NPC, opt: Dictionary) -> String:
	if opt.has("reopen"):
		return ""
	var ref := World.hh_ref(n.household)
	var extra := 0
	if opt.has("expand"):
		extra = int(opt.start)
		if extra <= 0 or w.party(ref) == null or BusinessMoney.venture_till_of(opt.expand) < extra:
			return "the business cannot pay for the premises"
	if opt.has("buy"):
		return buy_refusal(opt.buy, ref, n, extra)
	var rect: Rect2i = opt.rect
	var why: String = w.construction.can_place(str(opt.kind), rect, ref, opt.house)
	if why != "":
		return why
	if w.property.purse(ref) + extra < w.property.land_price(rect.size.x, rect.size.y):
		return "the household cannot pay for the ground"
	return ""


# ---------------------------------------------------------------- the business's money and goods (B25-BIZ-D1) -----
static func ref_of(b: Dictionary) -> String:
	return "venture:" + str(b.get("id", ""))


## The open venture an employer reference names ({} none).
func by_ref(ref: String) -> Dictionary:
	if not ref.begins_with("venture:"):
		return {}
	var b: Dictionary = w.buildings.get(ref.trim_prefix("venture:"), {})
	return b if b.has("venture") else {}


## The business `n` works for: the venture that employs them, else the one they keep ({} none). Hands (independent) have none.
func business_of(n: NPC) -> Dictionary:
	if n == null:
		return {}
	var rec: Dictionary = w.employment.record_of(n)
	if not rec.is_empty():
		return by_ref(str(rec.employer))
	return kept_by(n)


## The business's goods `n` holds for business `b`: a paid employee's employment record (`owed`), the keeper's `venture.goods`.
func _holdings(n: NPC, b: Dictionary) -> Dictionary:
	var rec: Dictionary = w.employment.record_of(n)
	if not rec.is_empty() and str(rec.employer) == ref_of(b):
		return rec.owed
	if int(b.venture.keeper) == n.id:
		if not b.venture.has("goods"):
			b.venture.goods = {}
		return b.venture.goods
	return {}


static var _inputs := {}              # trade -> {item: true}: what its recipes consume (derived from recipes.json, not saved)


## Every input of a recipe made at trade `trade`'s stations (NPCBrain.TRADE_STATIONS): what its business buys with its money.
static func trade_inputs(trade: String) -> Dictionary:
	if not _inputs.has(trade):
		var out := {}
		var kinds: Array = NPCBrain.TRADE_STATIONS.get(trade, [])
		for r in GameData.recipes:
			if kinds.has(str(GameData.recipes[r].station)):
				for id in GameData.recipes[r]["in"]:
					out[str(id)] = true
		_inputs[trade] = out
	return _inputs[trade]


## The coins `n` may spend on `item` for a business (its till), or -1 when the purchase is not a business's (NPCBrain.buy_qty).
func budget(n: NPC, item: String) -> int:
	var b := business_of(n)
	if b.is_empty() or not trade_inputs(str(b.venture.trade)).has(item):
		return -1
	return BusinessMoney.venture_till_of(b)


## The buy_from act: the business's coins for a purchase of `amount` go to its worker `n` for the deal. The business it was
## drawn from, or {} (nothing moved).
func fund(n: NPC, item: String, amount: int) -> Dictionary:
	if budget(n, item) < amount or amount <= 0:
		return {}
	var b := business_of(n)
	if not w.business.money.pay_out(b, "venture", n, amount, "materials"):
		return {}
	w.stat("venture_materials", amount)
	return b


## The deal is done: `qty` of `item` are the business's goods in `n`'s hands; what was not spent of `drawn` goes back.
func bought(n: NPC, b: Dictionary, item: String, qty: int, drawn: int, spent: int) -> void:
	if b.is_empty() or not b.has("venture"):
		return
	if drawn > spent:
		w.business.money.pay_in(b, "venture", n, mini(drawn - spent, n.coins), "refund")
	if qty > 0:
		var h := _holdings(n, b)
		h[item] = int(h.get(item, 0)) + qty


## Before a craft at station `a.station` (NPCBrain act "craft"): when it is a station of the business `n` works for, what `n`
## holds of the recipe's goods now ({} otherwise: the work is the worker's own).
func craft_begin(n: NPC, a: Dictionary) -> Dictionary:
	var b := business_of(n)
	if b.is_empty() or str(venture_at(str(a.get("station", ""))).get("id", "")) != str(b.id) or not GameData.recipes.has(str(a.get("recipe", ""))):
		return {}
	var r: Dictionary = GameData.recipes[str(a.recipe)]
	var counts := {}
	for id in r["in"]:
		counts[str(id)] = n.inv.count(str(id))
	for id in r.out:
		counts[str(id)] = n.inv.count(str(id))
	return {"b": b, "counts": counts, "recipe": str(a.recipe)}


## After it: inputs used leave the business's goods (as far as they were its), what came out is the business's.
func craft_end(n: NPC, snap: Dictionary) -> void:
	if snap.is_empty() or not (snap.b as Dictionary).has("venture"):
		return
	var h := _holdings(n, snap.b)
	var r: Dictionary = GameData.recipes[str(snap.recipe)]
	for id in r["in"]:
		var used := int(snap.counts[str(id)]) - n.inv.count(str(id))
		if used > 0 and h.has(str(id)):
			var left := int(h[str(id)]) - used
			if left > 0:
				h[str(id)] = left
			else:
				h.erase(str(id))
	for id in r.out:
		var made := n.inv.count(str(id)) - int(snap.counts[str(id)])
		if made > 0:
			h[str(id)] = int(h.get(str(id), 0)) + made
			w.stat("venture_made", made)


## BusinessMoney.after_trade: `n` sold `qty` of `id` for `total`; the units that were the business's goods pay their share of
## the price into its till. True when any were (the sale was the business's).
func on_sale(n: NPC, id: String, qty: int, total: int) -> bool:
	var b := business_of(n)
	if b.is_empty():
		return false
	var h := _holdings(n, b)
	var k := mini(qty, int(h.get(id, 0)))
	if k <= 0:
		return false
	if int(h[id]) - k > 0:
		h[id] = int(h[id]) - k
	else:
		h.erase(id)
	var share := total * k / qty
	if share > 0 and w.business.money.pay_in(b, "venture", n, share, "sale"):
		w.stat("venture_sales", share)
	return true


## The business's goods of `b` that `n` still holds (never more than they carry), item -> count.
func goods_of(n: NPC, b: Dictionary) -> Dictionary:
	var out := {}
	var h := _holdings(n, b)
	var ids: Array = h.keys()
	ids.sort()
	for id in ids:
		var k := mini(int(h[id]), n.inv.count(str(id)))
		if k > 0:
			out[str(id)] = k
	return out


# ---------------------------------------------------------------- paid employees (B25-BIZ-D2) ---------------
## Each dawn, an open venture hires one paid employee when it needs and can afford one: its trade has work (skilled_place
## `work`: the trade's people are busy at their stations), its own stations have room (fewer people work there than the
## stations hold), and its till holds hire_runway_days days of its whole payroll with the new wage (BIZ-03). The candidate: the most suitable willing adult
## of the trade or without a trade of their own, with some skill in it (NPCBrain.suitability: skill, then experience; then
## the poorer, then by id), free of other obligations; they agree through JudgmentLive.work_refusal (Employment.hire_for).
func _hire(b: Dictionary) -> void:
	var v: Dictionary = b.venture
	var trade := str(v.trade)
	var places := 0
	for st in trade_stations(b, trade):
		places += int(w.stations[st].get("capacity", 1))
	if 1 + (v.hands as Array).size() + w.employment.of_employer(ref_of(b)).size() >= places:
		return
	var wage: int = w.employment.market_wage(trade)
	# BIZ-03 (owner, Option B): the till must carry the whole payroll with the new employee, not one wage
	if BusinessMoney.venture_till_of(b) < (w.employment.payroll(ref_of(b)) + wage) * int(cfg().get("hire_runway_days", 7)):
		return
	if not bool(w.brain.skilled_place(trade).work):
		return
	var sk: String = w.brain._trade_skill(trade)
	var cands := []
	var hands := {}
	for id in v.hands:
		hands[int(id)] = true          # BIZ-05: a hand already fills one of its places (counted above); not hired into a second
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 0 and o.id != int(v.keeper) and not hands.has(o.id) and (o.job in Construction.HIRABLE or o.job == trade) \
				and sk != "" and int(o.skills.get(sk, 0)) > 0 and Skills.level(o, sk) >= 1 and kept_by(o).is_empty() \
				and w.employment.refusal(o, trade, ref_of(b)) == "":
			cands.append(o)
	cands.sort_custom(func(a: NPC, c: NPC) -> bool: return w.brain._key_less(w.brain.suitability(a, trade) + [a.coins, a.id], w.brain.suitability(c, trade) + [c.coins, c.id]))
	for o: NPC in cands:
		if w.employment.hire_for(ref_of(b), o, trade, wage) == "":
			w.stat("venture_employees_hired")
			return


# ---------------------------------------------------------------- buying and selling (B25-BIZ-D5) -----------
## A business building that can change hands: a finished workshop (its stations and fittings go with it).
static func is_business(b: Dictionary) -> bool:
	return not b.is_empty() and str(b.get("type", "")) == "workshop" and World.is_built(b)


## The trades that work a workshop of `kind` (the founding kinds read backwards: a carpenter's shop serves a carpenter or a
## tanner).
static func trades_for(kind: String) -> Array:
	var out := []
	var kinds: Dictionary = cfg().get("kinds", {})
	var ids: Array = kinds.keys()
	ids.sort()
	for job in ids:
		if str(kinds[job]) == kind:
			out.append(str(job))
	return out


## A seller's asking price for workshop `b` (a villager's; PROVISIONAL): what the land office values the building with its
## ground at (Property.price_of), the price anyone would pay the manor for the same.
func asking(b: Dictionary) -> int:
	return w.property.price_of(b)


## Why `ref` cannot offer workshop `b` for sale, "" when it can: its owner (not a tenant), finished, nothing let or being built,
## not the first building of a property whose other rooms would be cut off, no shop of the seller's open in it.
func offer_refusal(b: Dictionary, ref: String) -> String:
	if not is_business(b):
		return "That is not a workshop."
	if w.owner_of(b) != ref:
		return "It is not yours to sell."
	var p: Dictionary = w.property.parcel_under(b)
	if p.is_empty():
		return "It has no ground of its own to sell with it."
	for r in w.property.unit(b):
		if w.tenant_of(r) != "":
			return "It is let; it cannot be sold now."
	if w.property.estate_id(p) == str(p.id) and w.property.estate_parcels(p).size() > 1:
		return "Rooms are built onto it; it cannot be sold apart from them."
	if b.has("shop"):
		return "Close the shop there first."
	return ""


## The acting player offers their workshop `b` for sale at `price` coins. "" when done, else why not.
func offer(b: Dictionary, price: int, actor: PlayerState = null) -> String:
	if w.mirrors():
		return w.mirror("ventures.offer", offer.bind(b, price), [b, price])
	if actor != null and actor != w.player:
		return w.as_actor(actor, offer.bind(b, price))
	var why := offer_refusal(b, w.acting_ref())
	if why == "" and price < 1:
		why = "Name a price."
	if why != "":
		return why
	_offer(b, w.acting_ref(), price)
	return ""


func _offer(b: Dictionary, ref: String, price: int) -> void:
	b.sale = {"by": ref, "price": price, "day": w.day()}
	w.stat("businesses_offered")
	w.note("%s offers %s for sale for %d coins." % [w.ref_name(ref, true), w.property.describe(b), price])


## The acting player takes their offer back.
func withdraw(b: Dictionary, actor: PlayerState = null) -> String:
	if w.mirrors():
		return w.mirror("ventures.withdraw", withdraw.bind(b), [b])
	if actor != null and actor != w.player:
		return w.as_actor(actor, withdraw.bind(b))
	if not b.has("sale") or not w.is_acting_ref(str(b.sale.by)):
		return "You have not offered it for sale."
	b.erase("sale")
	return ""


## Workshops offered for sale whose seller still owns them, in building id order (a stale offer is dropped).
func offers() -> Array:
	var out := []
	var ids: Array = w.buildings.keys()
	ids.sort()
	for id in ids:
		var b: Dictionary = w.buildings[id]
		if not b.has("sale"):
			continue
		if offer_refusal(b, str(b.sale.by)) != "":
			b.erase("sale")
			continue
		out.append(b)
	return out


## The price `buyer` (a villager or a player) and the seller agree on: the asking price, pulled each way by their Trading
## (World.deal_price, the one bargaining rule for every deal).
func price_for(b: Dictionary, buyer: Object) -> int:
	var by := str(b.sale.by)
	var seller: Object = w.player_for(by) if World.is_player_ref(by) else w.party(by)
	return w.deal_price(int(b.sale.price), buyer, seller)


## Why `ref` cannot buy workshop `b` now ("" when it can): a current offer by someone else, the money.
## `extra`: coins the buyer will have by then (an expanding business's premises payment to its household, BIZ-02).
func buy_refusal(b: Dictionary, ref: String, buyer: Object, extra := 0) -> String:
	if not b.has("sale") or offer_refusal(b, str(b.sale.by)) != "":
		return "It is not for sale."
	if str(b.sale.by) == ref:
		return "It is yours already."
	if not World.is_player_ref(str(b.sale.by)) and w.party(str(b.sale.by)) == null:
		return "Nobody is left to sell it."
	var price := price_for(b, buyer)
	if w.property.purse(ref) + extra < price:
		return "You need %d coins." % price if World.is_player_ref(ref) else "They cannot pay %d coins." % price
	return ""


## The acting player buys workshop `b` at the agreed price. "" when done, else why not.
func buy(b: Dictionary, actor: PlayerState = null) -> String:
	if w.mirrors():
		return w.mirror("ventures.buy", buy.bind(b), [b])
	if actor != null and actor != w.player:
		return w.as_actor(actor, buy.bind(b))
	var why := buy_refusal(b, w.acting_ref(), w.player)
	if why != "":
		return why
	return _transfer(b, w.acting_ref(), price_for(b, w.player), null)


## The sale itself (one rule for the player and the villagers): the buyer pays the seller the agreed price (all or nothing);
## the seller's business there closes (its till goes to the seller's household, TILL-D1; its employees' employment and its
## hands' leave end: nothing of the seller's obligations passes on); a workshop added to the seller's house is detached from
## that property (the house, its ground and its other rooms stay the seller's); the workshop with its ground, stations and
## fittings passes to the buyer (World.set_owner). A villager buyer (`founder`) opens a business there at once.
func _transfer(b: Dictionary, buyer: String, price: int, founder: NPC) -> String:
	var seller := str(b.sale.by)
	if not _pay(buyer, seller, price):
		return "The money could not be paid."
	b.erase("sale")
	if b.has("venture"):
		var keeper := w.npc(int(b.venture.keeper))
		close(b, "it was sold")
		if keeper != null and w.stations.has(keeper.workplace) and str(w.stations[keeper.workplace].get("building", "")) == str(b.id):
			keeper.workplace = _other_station(keeper, keeper.job)
	b.erase("allow")                       # the seller's leave to others does not pass with the building
	detach(b)
	for r in w.property.unit(b):
		w.set_owner(r, buyer)
	w.stat("businesses_sold")
	w.stat("business_sale_coins", price)
	w.note("%s buys %s from %s for %d coins." % [w.ref_name(buyer, true), w.property.describe(b), w.ref_name(seller), price])
	if founder != null:
		_open(b, founder.id, founder.job, founder.household, w.day())
		w.stat("ventures_bought")
	return ""


## Coins from `from`'s purse (a player's, or a household's members', richest first) to `to` (a player, or a household's
## head), all or nothing. With the Living Economy on, through the transaction authority, part by part.
func _pay(from: String, to: String, amount: int) -> bool:
	if amount <= 0:
		return true
	if w.property.purse(from) < amount:
		return false
	var dest: Object = w.player_for(to) if World.is_player_ref(to) else w.party(to)
	if dest == null:
		return false
	if w.economy != null:
		var parts := []
		if World.is_player_ref(from):
			parts.append([from, w.player_for(from), amount])
		else:
			var left := amount
			for o: NPC in w.property._payers(from):
				var k := mini(left, o.coins)
				if k > 0:
					parts.append([World.npc_ref(o.id), o, k])
					left -= k
		for p in parts:
			if not w.claims_allow(p[1], EconReservations.COINS, int(p[2])):
				return false
		var to_ref := to if World.is_player_ref(to) else World.npc_ref((dest as NPC).id)
		for p in parts:
			if str(p[0]) == to_ref:
				continue
			var tx: Dictionary = w.transactions.transfer_coins(w.transactions.next_txid("business"), str(p[0]), to_ref, int(p[2]), "business_sale", true)
			if not bool(tx.ok):
				return false
		return true
	w.construction._take(from, amount)
	dest.coins += amount
	if dest is NPC:
		dest.earned += amount
	return true


## A workshop module added to a house (its parcel marked with the property's `estate`) becomes a property of its own: the
## mark goes, the doorway that joined it to the house is gone with it (doorways are derived: its wall cells are solid and drawn
## again), and nothing else of the property changes. The smallest separation of a business from a residence (D5 D).
func detach(b: Dictionary) -> void:
	var p: Dictionary = w.property.parcel_under(b)
	if p.is_empty() or str(p.get("estate", "")) == "" or str(p.estate) == str(p.id):
		return
	var before: Array = w.doorways.duplicate()
	p.erase("estate")
	w.index_interiors()
	var still := {}
	for dw: Dictionary in w.doorways:
		for c: Vector2i in dw.cells:
			still[c] = true
	for dw: Dictionary in before:
		for c: Vector2i in dw.cells:
			if not still.has(c):
				w.map.set_solid(c, true)
				w.tile_changed.emit(c, "below", Doorways.WALL)
	w.stat("workshops_detached")


## A household offers a workshop it owns that nobody of the household works any more (its business closed, nobody of a trade
## that works it at home), at the asking price; and takes the offer back when one of them takes the trade up again.
func _list_unused() -> void:
	var ids: Array = w.buildings.keys()
	ids.sort()
	for id in ids:
		var b: Dictionary = w.buildings[id]
		if not is_business(b) or b.has("venture"):
			continue
		var ref := w.owner_of(b)
		if not ref.begins_with("hh:"):
			continue
		var h := World.ref_id(ref)
		if h < 0 or h >= w.households.size() or w.households[h].get("ended", false):
			continue
		var trades := trades_for(str(b.get("kind", "")))
		var works: bool = w.brain._members(h).any(func(o: NPC) -> bool: return o.alive and o.role == "adult" and trades.has(o.job))
		if b.has("sale") and str(b.sale.by) == ref:
			if works:
				b.erase("sale")
			continue
		if not works and not b.has("sale") and not trades.is_empty() and offer_refusal(b, ref) == "":
			_offer(b, ref, asking(b))
			w.stat("businesses_offered_unused")


## The cheapest workshop on sale that `n`'s trade works, not their own household's ({} none).
func listed_for(n: NPC) -> Dictionary:
	var best := {}
	var best_price := 0
	for b in offers():
		if not trades_for(str(b.get("kind", ""))).has(n.job) or str(b.sale.by) == World.hh_ref(n.household):
			continue
		var p := price_for(b, n)
		if best.is_empty() or p < best_price:
			best = b
			best_price = p
	return best


## A workshop of `n`'s trade their household already owns and nobody runs ({} none): it opens again without building.
func own_unused(n: NPC) -> Dictionary:
	var ids: Array = w.buildings.keys()
	ids.sort()
	for id in ids:
		var b: Dictionary = w.buildings[id]
		if is_business(b) and not b.has("venture") and w.owner_of(b) == World.hh_ref(n.household) and trades_for(str(b.get("kind", ""))).has(n.job):
			return b
	return {}



# ---------------------------------------------------------------- expansion (B25-BIZ-D5 E) --------------
## A keeper's option to open another workshop of their trade paid by their business ({} none): the trade has work and no room
## (the founding test), the household builds nothing else, and the business's till holds the start (a workshop on sale at the
## agreed price, else a standalone workshop's ground and first materials near the business) plus hire_runway_days of the market
## wage to staff it. Several businesses are limited only by money, ground, sellers, staff and work.
func expansion(n: NPC, markets := {}) -> Dictionary:
	var biz := kept_by(n)
	var kind := kind_for(n.job)
	if biz.is_empty() or kind == "" or str(biz.venture.trade) != n.job or n.household < 0:
		return {}
	var h := n.household
	var hh: Dictionary = w.households[h]
	var ref := World.hh_ref(h)
	var bp: Dictionary = w.plot(str(hh.get("build", "")))
	var building: bool = not bp.is_empty() and not bp.site.is_empty() and not bp.site.get("done", false)
	if hh.get("ended", false) or hh.has("venture") or building or not (hh.get("housing", {}) as Dictionary).is_empty():
		return {}
	if not markets.has(n.job):
		markets[n.job] = w.brain.skilled_place(n.job)
	var m: Dictionary = markets[n.job]
	if not bool(m.work) or bool(m.room):
		return {}
	var till := BusinessMoney.venture_till_of(biz)
	var working: int = w.employment.market_wage(n.job) * int(cfg().get("hire_runway_days", 7))
	var info := {"kind": kind, "expand": biz, "spare": till, "busy": float(m.get("busy", 0.0)), "skill": Skills.level(n, w.brain._trade_skill(n.job))}
	var listed := listed_for(n)
	if not listed.is_empty():
		var price := price_for(listed, n)
		if till >= price + working:
			return info.merged({"buy": listed, "price": price, "start": price, "need": price + working})
	var rect: Rect2i = w.construction.find_ground(kind, w.building_door(str(biz.id)), ref)
	if rect.size == Vector2i.ZERO:
		return {}
	var land: int = w.property.land_price(rect.size.x, rect.size.y)
	var start: int = w.construction._start_of(h, w.construction.cost_of(kind), land)
	if till < start + working:
		return {}
	return info.merged({"rect": rect, "house": {}, "start": start, "need": start + working})


# ---------------------------------------------------------------- abandoning a site (B25-BIZ-D3) -----------
## The household gives up the business it is setting up: the existing cancellation (World.cancel_site) takes the frame down and
## returns every delivered load to the household's store (what does not fit lies at the door); nothing is refunded as money
## and the ground stays the household's; its helpers' day contracts on the site end; the household is free of the building
## goal (hh.build) to see to its home and its living. False when it was setting nothing up.
func abandon(h: int, why: String) -> bool:
	if h < 0 or h >= w.households.size() or not w.households[h].has("venture"):
		return false
	var hh: Dictionary = w.households[h]
	var p: Dictionary = w.plot(str(hh.venture.plot))
	if not p.is_empty():
		for c in w.construction.contracts.duplicate():
			if str(c.site) == str(p.id):
				w.construction.end_contract(c, "the building was given up")
		if not p.site.is_empty() and not p.site.get("done", false):
			var store: Inventory = w.construction.store_of(World.hh_ref(h))
			w.cancel_site(p, store if store != null else hh.pantry)
	hh.erase("venture")
	if not p.is_empty() and str(hh.get("build", "")) == str(p.id):
		hh.erase("build")
	w.stat("ventures_abandoned")
	w.stat("ventures_abandoned_given_up")
	w.note("The %s family gives up the workshop it was building: %s." % [hh.family, why])
	return true


## Each dawn, a business being set up whose completion has become unreasonable is given up: the household has a home to see to
## (a housing goal: crowded, without a home, a couple without one: home first), or the site has made no progress for
## stall_days days and the household cannot spare what its remaining materials cost (Construction.estimate).
func _review_setup() -> void:
	for h in w.households.size():
		var hh: Dictionary = w.households[h]
		if not hh.has("venture") or hh.get("ended", false):
			continue
		var rec: Dictionary = hh.venture
		var p: Dictionary = w.plot(str(rec.plot))
		if p.is_empty() or p.site.is_empty() or p.site.get("done", false):
			continue
		if not w.construction.housing_goals(h).is_empty():
			abandon(h, "the family needs its home seen to first")
			continue
		var prog: float = w.site_progress(p)
		if prog > float(rec.get("progress", -1.0)):
			rec.progress = prog
			rec.moved = w.day()
			continue
		if w.day() - int(rec.get("moved", rec.day)) < int(cfg().get("stall_days", 30)):
			continue
		var spare: int = w.property.purse(World.hh_ref(h)) - w.construction._keep(h, w.brain._members(h).size()) - w.construction._tool_reserve(h)
		if spare < w.construction.estimate(p.site.need):
			abandon(h, "it could not be finished")
