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
##   capital, household finances and the trade's demand all allow (eligible), and decides through the shared weighing
##   (JudgmentWeighting, profile "business_found"); with the judgment layer off nobody founds.
## Hiring: an open venture's stations are room for its trade in the labour market (NPCBrain.skilled_place); a hand taken for
## one is given the keeper's leave (World.permit) and works there under the existing skilled model (took_place).
##
## State: household.venture {founder, trade, kind, plot, day} while setting up; building.venture {founder, keeper, trade, day,
## opened, household, idle, hands} once open. Both saved with their dicts (older saves: none).

var w: World


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
		if int(v.keeper) != n.id and not (v.hands as Array).has(n.id):
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
	_open_finished()
	for b in open_ventures():
		_check(b)
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
		b.venture = {"founder": int(rec.founder), "keeper": int(rec.founder), "trade": str(rec.trade), "day": int(rec.day),
			"opened": w.day(), "household": h, "idle": 0, "hands": []}
		w.stat("ventures_opened")
		var k := w.npc(int(rec.founder))
		if k != null and k.alive and k.job == str(rec.trade) and k.household == h:
			_work_here(k, b)
			w.note("%s %s opens %s %s." % [k.name, k.family, "a" if not str(b.kind).begins_with("a") else "an", Construction.kind_name(str(b.kind))])
		_check(b)


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
	for n: NPC in w.npcs:
		if kind_for(n.job) == "" or busy.has(n.job) or not looks_today(n):
			continue
		var opt := eligible(n, markets)
		if opt.is_empty():
			continue
		w.stat("ventures_considered")
		if not decides(n, opt):
			continue
		if found(n, opt):
			busy[n.job] = true


## Why `n` cannot found a business now ("" when they could, the option in `out`): ability and experience, premises, the
## trade's demand and competition, capital and household finances. `markets`: the trade readings of this morning.
func eligible(n: NPC, markets := {}, out := {}) -> Dictionary:
	var why := refusal(n, markets, out)
	return out if why == "" else {}


func refusal(n: NPC, markets := {}, out := {}) -> String:
	var c := cfg()
	var job := n.job
	var kind := kind_for(job)
	if kind == "" or not n.alive or n.role != "adult" or n.household < 0:
		return "not in a founding trade"
	var sk: String = w.brain._trade_skill(job)
	var lv := Skills.level(n, sk) if sk != "" and int(n.skills.get(sk, 0)) > 0 else 0
	if lv < int(c.min_level):
		return "not skilled enough yet"
	var ind: String = NPCBrain.TRADE_INDUSTRY.get(job, "")
	var days := w.experience.days(World.npc_ref(n.id), ind) if ind != "" else float(w.day() - n.job_since)
	if days < float(c.min_trade_days):
		return "too little experience in the trade"
	if not kept_by(n).is_empty():
		return "keeps a business already"
	var h := n.household
	var hh: Dictionary = w.households[h]
	var ref := World.hh_ref(h)
	if hh.get("ended", false) or hh.has("venture") or str(hh.get("build", "")) != "" or not (hh.get("housing", {}) as Dictionary).is_empty():
		return "the household has building or a home to see to first"
	var house: Dictionary = w.buildings.get(str(hh.get("home", "")), {})
	if house.is_empty() or w.owner_of(house) != ref:
		return "the household does not own its house"
	if not markets.has(job):
		markets[job] = w.brain.skilled_place(job)
	var m: Dictionary = markets[job]
	if not bool(m.work) or bool(m.room):
		return "no opening for another workshop of the trade"
	var econ: Dictionary = hh.get("econ", {})
	if econ.is_empty():
		return "the household's means are not known"
	var spare: int = w.property.purse(ref) - w.construction._keep(h, w.brain._members(h).size()) - w.construction._tool_reserve(h)
	var working := ceili(float(econ.get("cost", 0.0)) * float(c.working_days))
	if spare <= working:
		return "the household cannot spare the money"
	if w.property.anchor_of(house).is_empty():
		w.property.survey_under(house)       # HOUSE-09: an original house's ground is surveyed (nothing paid, nothing changes hands)
	var anchor := house                      # a room of the property beside the house first (find_module_slot)
	var rect: Rect2i = w.construction.find_module_slot(kind, house, ref)
	if rect.size != Vector2i.ZERO and w.construction.can_place(kind, rect, ref, house) != "":
		rect = Rect2i()
	if rect.size == Vector2i.ZERO:
		anchor = {}                          # else a workshop on its own ground near the house (owner rule: a house first)
		rect = w.construction.find_ground(kind, w.building_door(str(house.id)), ref)
		if rect.size == Vector2i.ZERO:
			return "no ground for a workshop"
	var land: int = w.property.land_price(rect.size.x, rect.size.y)
	var start: int = w.construction._start_of(h, w.construction.cost_of(kind), land)
	if spare < start + working:
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
	var p: Dictionary = w.construction.place(str(opt.kind), opt.rect, ref, false, opt.house)
	if p.is_empty():
		return false
	var hh: Dictionary = w.households[h]
	hh.build = str(p.id)
	hh.venture = {"founder": n.id, "trade": n.job, "kind": str(opt.kind), "plot": str(p.id), "day": w.day()}
	w.stat("ventures_founded")
	w.stat("ventures_founded_" + n.job)
	w.note("%s %s sets about building %s of their own." % [n.name, n.family, Construction.kind_name(str(opt.kind), true)])
	w.construction._keep_building(h)
	return true
