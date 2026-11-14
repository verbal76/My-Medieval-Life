class_name Envoys
extends RefCounted
## REGION-NAV-01 S4, the envoy post (plan AD-3, AD-5; owner 2026-11-02: "the envoy must systematically attempt to meet with every
## accessible business owner and independent crafter ... The information must originate from the actual NPC's inventory, needs,
## production, business records, and willingness to trade"; owner 2026-11-03 Q4: "envoys interview every relevant crafter").
##
## The reeve (the village's acting leadership, AD-3) posts one envoy job at a time on the manor's job board (ManorWork, kind
## "envoy"): to the settlement the reeve knows least about (one never surveyed first, nearest first; then the one whose survey is
## oldest, once it is `refresh_days` old). A villager takes it as any manor job (the labour market, ManorWork.seek); the wage, the
## manor's day wage for the trip's days, is set aside from the treasury when taken and paid when the work is done (no new money).
##
## The mission, each step a real action in the world:
##   go       the envoy walks to the settlement (Journeys, kind "envoy"); a road that cannot be found fails the trip (recorded)
##   there    at the site they go to each person a visitor can meet (SettlementFolk.people: keepers, the official, the crafters),
##            one after another; a person at their place is interviewed (envoy_talk: what they will sell and want, read from their
##            own books, SettlementFolk.offers), one away is recorded absent, never as surveyed
##   back     they walk home; what they learnt is carried in the job (j.carried), not known at home until they report
##   report   at the reeve: the records go into the reeve's book (World.intel_book), each with its source (the person and the
##            settlement), who told it (the envoy) and the day it was collected; the settlement's visit is noted
##   survey   the home survey: at the manor the envoy records each village tradesperson's wants and what they hold of their trade's
##            goods (the home side the reeve's book matches against, S5); then the wage is paid
## An envoy who dies on the way loses what they carried (the job is released; the reeve posts again). If the reeve's office is
## empty when they come home, they wait; the book belongs to the office, so a new reeve has it.
##
## Records: {about: party ref, person, role, place: settlement id, item, side: "have" | "want", qty, price, kind: "confirmed" |
## "absent" | "none", told_by, collected_day, heard_day}. kind "none": met, with nothing to sell or want; "absent": not met.

const SIDES := ["have", "want"]


static func cfg() -> Dictionary:
	var c: Dictionary = OffMapSettlement.data().get("envoy", {})
	return {"day_wage": int(c.get("day_wage", 4)), "refresh_days": int(c.get("refresh_days", 4)), "talk_minutes": float(c.get("talk_minutes", 20.0)),
		"survey_minutes": float(c.get("survey_minutes", 60.0)), "spare_days": int(c.get("spare_days", 3))}


## The reeve's book: {records: [...], visits: {sid: {day, met, absent, failed}}, home: {ref: {wants, has, day}}, home_day}.
static func book(w: World) -> Dictionary:
	if w.intel_book.is_empty():
		w.intel_book = {"records": [], "visits": {}, "home": {}, "home_day": -1}
	# REG-07: an expired market offer isn't immortal just because no envoy
	# has revisited that settlement. Visit history is kept for scheduling.
	else:
		var max_age := int(Intel.cfg().forget_days)
		w.intel_book.records = (w.intel_book.get("records", []) as Array).filter(
			func(r): return Intel.age(w, r) <= max_age)
	return w.intel_book


static func trip_days(w: World, sid: String) -> float:
	var r: Dictionary = w.regions.village_route_table().get("village>" + sid, {})
	return float(r.get("days", 1.0))


## The settlement the reeve would send an envoy to now, or "". Never surveyed first (nearest), then the oldest survey once it is
## refresh_days old; a settlement whose last trip failed (no road) waits refresh_days too.
static func target(w: World) -> String:
	if w.regions == null or w.map.overworld == null:
		return ""
	var b := book(w)
	var best := ""
	var best_key := []
	for s: OffMapSettlement in w.regions.list:
		if w.map.overworld.site(s.id).is_empty():
			continue
		var v: Dictionary = b.visits.get(s.id, {})
		var age := w.day() - int(v.get("day", -100000))
		if not v.is_empty() and age < int(cfg().refresh_days):
			continue
		var key := [0 if v.is_empty() else 1, -age, trip_days(w, s.id), s.id]
		if best == "" or key < best_key:
			best = s.id
			best_key = key
	return best


## The reeve's evening (NPCBrain): one envoy job at a time, while the village has a reeve and somewhere worth a visit.
static func post(w: World) -> void:
	var mw: ManorWork = w.manor_work
	if w.reeve_id < 0 or mw.jobs.any(func(j): return str(j.kind) == "envoy"):
		return
	var sid := target(w)
	if sid == "":
		return
	var days := trip_days(w, sid)
	var c := cfg()
	mw._post({"kind": "envoy", "sid": sid, "qty": 1, "wage": int(ceil(2.0 * days + 1.0)) * int(c.day_wage), "stage": "go",
		"days_allowed": int(ceil(2.0 * days)) + 1 + int(c.spare_days), "carried": [], "met": []})
	w.stat("envoy_posted")


## ManorWork.step for an envoy job.
static func step(j: Dictionary) -> String:
	return "envoy_" + str(j.get("stage", "go"))


## ManorWork.plan for an envoy job: the next part of the mission. False when there is nothing to plan (the job was given up).
static func plan(w: World, n: NPC, j: Dictionary) -> bool:
	var b: NPCBrain = w.brain
	match str(j.stage):
		"go":
			if Journeys.active(n):
				return false
			if bool(j.get("started", false)):          # the trip ended without reaching the site (no road): nothing to report
				j.stage = "report"
				return plan(w, n, j)
			if not Journeys.fed_for(w, n, str(j.sid), {"kind": "envoy", "job": int(j.id)}):
				# B42 (envoy starvation): no food for the road home and no coins to buy it at the site: they do not go. The job is
				# given up (posted again for whoever can go); the settlement is not marked as visited.
				w.stat("envoy_refused_no_food")
				Journeys.record(w, n, "refused", {"to": str(j.sid), "purpose": {"kind": "envoy", "job": int(j.id)}, "why": "no food for the road home"})
				w.manor_work.release(j)
				return false
			var why := Journeys.start(w, n, str(j.sid), {"kind": "envoy", "job": int(j.id)})
			if why != "":
				var bv: Dictionary = book(w)
				bv.visits[str(j.sid)] = {"day": w.day(), "met": 0, "absent": 0, "failed": true}
				w.stat("envoy_failed_no_road")
				w.manor_work.release(j)
				return false
			j.started = true
			n.doing = "setting off as the reeve's envoy to %s" % w.map.overworld.site(str(j.sid)).name
			n.plan = [b.work(1.0, "", {}, "idle")]
			return true
		"back":
			if Journeys.active(n):
				return false
			j.stage = "report"                           # home: to the reeve
			return plan(w, n, j)
		"report":
			var rv := w.npc(w.reeve_id) if w.reeve_id >= 0 else null
			if rv == null or not rv.alive:
				n.doing = "waiting to report to the reeve"
				n.plan = [b.go(w.manor_work.yard_cell()), b.work(60.0, "", {}, "idle")]
				return true
			n.doing = "reporting to the reeve"
			n.plan = [b.go(b.beside(rv.cell(), n.cell())), b.work(15.0, "envoy_report", {"job": int(j.id)}, "work")]
			return true
		"tell":
			while not (j.get("tell", []) as Array).is_empty():
				var ref: String = j.tell[0]
				var o := w.npc(int(ref.substr(4)))
				if o == null or not o.alive:
					(j.tell as Array).pop_front()
					continue
				n.doing = "telling %s what the reeve's envoy learnt" % o.name
				n.plan = [b.go(b.beside(o.cell(), n.cell())), b.work(float(Intel.cfg().tell_minutes), "envoy_tell", {"job": int(j.id), "to": ref}, "talk")]
				return true
			w.manor_work._finish(j, World.npc_ref(n.id))
			w.stat("envoy_missions_done")
			return false
		"survey":
			n.doing = "surveying the village's trades for the reeve"
			n.plan = [b.go(w.manor_work.yard_cell()), b.work(float(cfg().survey_minutes), "envoy_survey", {"job": int(j.id)}, "work")]
			return true
	return false


## World.journey_hook: at the site, the envoy meets the next person not yet met. True when that gave them work.
static func at_site(w: World, n: NPC) -> bool:
	if str(n.journey.get("purpose", {}).get("kind", "")) != "envoy":
		return false
	var j := w.manor_work.job(int(n.journey.purpose.job))
	if j.is_empty() or str(j.taker) != World.npc_ref(n.id):
		return false
	var sid := str(j.sid)
	for p in SettlementFolk.people(w, sid):
		if (j.met as Array).has(str(p.ref)):
			continue
		var hr := w.hour()
		if hr < float(SettlementFolk.WORK_FROM) or hr + float(cfg().talk_minutes) / 60.0 >= float(SettlementFolk.WORK_TO):
			n.doing = "waiting for the morning to meet the people of %s" % w.map.overworld.site(sid).name
			n.plan = [w.brain.work(30.0, "", {}, "idle")]       # out of hours nobody keeps their door: wait at the site
			return true
		if not SettlementFolk.present(w, p):
			_record_absent(w, n, j, p)                   # in working hours, away (a trader on the road, a crafter with nothing to sell)
			continue
		n.doing = "speaking with %s, the %s" % [p.name, str(p.trade if str(p.role) != "official" else "official")]
		n.plan = [w.brain.go(Vector2i(p.spot) + Vector2i(0, 1)), w.brain.work(float(cfg().talk_minutes), "envoy_talk", {"job": int(j.id), "ref": str(p.ref)}, "talk")]
		return true
	if str(j.stage) == "go":
		j.stage = "back"
		w.stat("envoy_interviews_done")
	return false


## The brain's act for the envoy's steps (envoy_talk, envoy_report, envoy_survey).
static func act(w: World, n: NPC, what: String, a: Dictionary) -> bool:
	var j := w.manor_work.job(int(a.get("job", -1)))
	if j.is_empty() or str(j.taker) != World.npc_ref(n.id):
		return true
	match what:
		"envoy_talk":
			var p := _person(w, str(j.sid), str(a.ref))
			if p.is_empty() or (j.met as Array).has(str(a.ref)):
				return true
			if not SettlementFolk.present(w, p) or n.pos.distance_to(Vector2(p.spot) + Vector2(0.5, 1.5)) > 3.0:
				_record_absent(w, n, j, p)                   # away, or out of the envoy's reach: never surveyed from afar
				return true
			_interview(w, n, j, p)
		"envoy_report":
			_report(w, n, j)
		"envoy_survey":
			_home_survey(w, n, j)
			j.stage = "tell"
			var refs := []
			for x in Intel.to_tell(w, book(w)):
				refs.append(World.npc_ref(x[0].id))
			j.tell = refs                                # S5: the tradespeople the book has news for, most first
		"envoy_tell":
			var o := w.npc(int(str(a.get("to", "")).substr(4)))
			if o != null and o.alive:
				var ints := Intel.interests(w, o)
				for r in book(w).records:
					if Intel.fresh(w, r) and Intel.concerns(w, o, r, ints) and Intel.hear(w, o, r, World.npc_ref(n.id)):
						w.stat("intel_told_by_envoy")
			(j.tell as Array).erase(str(a.get("to", "")))
	return true


static func _person(w: World, sid: String, ref: String) -> Dictionary:
	for p in SettlementFolk.people(w, sid):
		if str(p.ref) == ref:
			return p
	return {}


static func _base(w: World, n: NPC, j: Dictionary, p: Dictionary) -> Dictionary:
	return {"about": str(p.ref), "person": str(p.name), "role": str(p.role), "place": str(j.sid), "told_by": World.npc_ref(n.id),
		"collected_day": w.day(), "heard_day": -1}


## What the person says, from their own books (SettlementFolk.offers): each thing they will sell and each they want.
static func _interview(w: World, n: NPC, j: Dictionary, p: Dictionary) -> void:
	var o := SettlementFolk.offers(w, p)
	var said := 0
	for side in SIDES:
		for line in (o.sells if side == "have" else o.wants):
			var r := _base(w, n, j, p)
			r.merge({"item": str(line.item), "side": side, "qty": int(line.n), "price": int(line.price), "kind": "confirmed"})
			(j.carried as Array).append(r)
			said += 1
	if said == 0:
		var r := _base(w, n, j, p)
		r.merge({"item": "", "side": "", "qty": 0, "price": 0, "kind": "none"})
		(j.carried as Array).append(r)
	(j.met as Array).append(str(p.ref))
	w.stat("envoy_interviews")


static func _record_absent(w: World, n: NPC, j: Dictionary, p: Dictionary) -> void:
	var r := _base(w, n, j, p)
	r.merge({"item": "", "side": "", "qty": 0, "price": 0, "kind": "absent", "why": SettlementFolk.absent_reason(w, p)})
	(j.carried as Array).append(r)
	(j.met as Array).append(str(p.ref))
	w.stat("envoy_absent")


## The envoy's records go into the reeve's book: the settlement's earlier records are replaced by these (newer), the visit noted.
static func _report(w: World, n: NPC, j: Dictionary) -> void:
	var b := book(w)
	var sid := str(j.sid)
	var carried: Array = j.carried
	if not carried.is_empty():
		b.records = (b.records as Array).filter(func(r): return str(r.place) != sid)
	var absent := 0
	var people := {}
	for r in carried:
		var x: Dictionary = r.duplicate()
		x.heard_day = w.day()
		(b.records as Array).append(x)
		if str(x.kind) == "absent":
			absent += 1
		else:
			people[str(x.about)] = true
	var met := people.size()
	b.visits[sid] = {"day": int(carried[0].collected_day) if not carried.is_empty() else w.day(), "met": met, "absent": absent, "failed": carried.is_empty()}
	j.carried = []
	j.stage = "survey"
	w.stat("envoy_reports")
	w.note("%s %s, the reeve's envoy, reports on %s: %d people met, %d away." % [n.name, n.family, w.map.overworld.site(sid).get("name", sid), met, absent])


## The home survey: each village tradesperson's wants (NPCBrain.wants, beyond what they hold) and what they hold of their trade's goods.
static func _home_survey(w: World, n: NPC, j: Dictionary) -> void:
	var b := book(w)
	var home := {}
	for o: NPC in w.npcs:
		if not o.alive or o.role != "adult" or o.job == "" or o.job in ["guard", "reeve", "manor_hand", "sage", "preacher"]:
			continue
		var wants := {}
		var buys: Dictionary = NPCBrain.BUYS.get(w.brain.buy_role(o), {})
		var ids: Array = buys.keys()
		ids.sort()
		for id in ids:
			var want: int = w.brain.wants(o, str(id)) - o.inv.count(str(id))
			if want > 0:
				wants[str(id)] = want
		var has := {}
		for id in NPCBrain.TRADE_GOODS.get(o.job, []):
			if o.inv.count(str(id)) > 0:
				has[str(id)] = o.inv.count(str(id))
		if not wants.is_empty() or not has.is_empty():
			home[World.npc_ref(o.id)] = {"wants": wants, "has": has, "day": w.day()}
	b.home = home
	b.home_day = w.day()
	w.stat("envoy_home_surveys")
