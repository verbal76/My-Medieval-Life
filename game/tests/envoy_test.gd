extends SceneTree
## REGION-NAV-01 S4, the envoy post (plan AD-3, AD-5). Acceptance (plan, S4): each interview reads that person's real books;
## refused or absent recorded; nothing known at home before the return; succession of the reeve or the envoy mid-mission.
## Also: the reeve posts one envoy job at a time to the place it knows least about; a villager takes it from the board; the
## wage is set aside when taken and paid when done (no coin made). Pure World. Run headless:
##   godot --headless --path game --script res://tests/envoy_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _run(w: World, cond: Callable, max_minutes: float) -> bool:
	var until := w.minutes + max_minutes
	while w.minutes < until:
		w.update(0.5)
		if cond.call():
			return true
	return false


func _villager(w: World, but: Array = []) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 0 and n.home != "" and not n.job in ["guard", "reeve", "manor_hand", "sage"] and not but.has(n):
			return n
	return null


func _world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.minutes = 1440.0 + 7.0 * 60.0
	w.treasury += 0
	return w


func _envoy_job(w: World) -> Dictionary:
	for j in w.manor_work.jobs:
		if str(j.kind) == "envoy":
			return j
	return {}


## Post and hand the job to `n` as the board would; returns the job.
func _send(w: World, n: NPC) -> Dictionary:
	Envoys.post(w)
	var j := _envoy_job(w)
	if j.is_empty() or not w.manor_work.take(j, World.npc_ref(n.id)):
		return {}
	n.plan.clear()
	return j


func _init() -> void:
	_test_mission()
	_test_interview_reads_books()
	_test_envoy_dies()
	_test_reeve_succession()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _test_mission() -> void:
	var w := _world()
	check(w.reeve_id >= 0, "the village has a reeve")
	var first := Envoys.target(w)
	var nearest := ""
	var nd := INF
	for s: OffMapSettlement in w.regions.list:
		if Envoys.trip_days(w, s.id) < nd:
			nd = Envoys.trip_days(w, s.id)
			nearest = s.id
	check(first == nearest, "the reeve's first envoy goes to the nearest place never surveyed (%s)" % first)
	Envoys.post(w)
	Envoys.post(w)
	check(w.manor_work.jobs.filter(func(j): return str(j.kind) == "envoy").size() == 1, "one envoy job at a time on the manor's board")
	var n := _villager(w)
	var coins0 := w.total_coins() - w.coin_sources
	var t0 := w.treasury
	var e0 := n.earned
	var j := _envoy_job(w)
	check(not w.manor_work.open_for("player").has(j), "the player is not offered the envoy post (a villager's work)")
	check(w.manor_work.take(j, World.npc_ref(n.id)) and w.treasury == t0 - int(j.reserved) and int(j.reserved) > 0, "%s takes it from the board; its wage (%d) is set aside from the treasury" % [n.name, int(j.reserved)])
	var wage := int(j.reserved)
	n.plan.clear()
	var sid := str(j.sid)
	check(_run(w, func() -> bool: return Journeys.active(n), 120.0) and str(n.journey.to) == sid, "the envoy sets off on foot for %s" % sid)
	var at_site := _run(w, func() -> bool: return str(n.journey.get("leg", "")) == "there", 4 * 1440.0)
	check(at_site, "and reaches the site (day %d)" % w.day())
	var people := SettlementFolk.people(w, sid)
	var far := {"max": 0.0}
	check(_run(w, func() -> bool:
		if str(n.doing).begins_with("speaking with"):
			far.max = maxf(float(far.max), float(w.map.overworld.site(sid).center.distance_to(n.cell())))
		return str(j.get("stage", "")) == "back", 2 * 1440.0), "at the site they go to each person in turn (%d people), then turn for home" % people.size())
	check(float(far.max) < 30.0, "every interview is at the site, face to face (at most %.0f tiles from its centre)" % float(far.max))
	check((Envoys.book(w).records as Array).is_empty(), "nothing is known at home while the envoy is away (the reeve's book is empty)")
	var met: Array = j.met
	check(met.size() == people.size(), "everyone a visitor can meet was met or recorded away (%d of %d)" % [met.size(), people.size()])
	var absent := (j.carried as Array).filter(func(r): return str(r.kind) == "absent")
	for r in absent:
		check(str(r.get("why", "")) != "", "%s was away and is recorded so, with the reason (%s), not as surveyed" % [str(r.person), str(r.why)])
	check(_run(w, func() -> bool: return not w.manor_work.jobs.has(j), 5 * 1440.0), "home, they report to the reeve and survey the village's trades; the mission ends (day %d)" % w.day())
	var b := Envoys.book(w)
	var recs := (b.records as Array).filter(func(r): return str(r.place) == sid)
	check(not recs.is_empty() and recs.all(func(r): return str(r.told_by) == World.npc_ref(n.id) and int(r.heard_day) >= int(r.collected_day)), "the reeve's book holds %d records about %s, each with who told it and when it was collected" % [recs.size(), sid])
	check((b.visits as Dictionary).has(sid) and int(b.visits[sid].met) > 0, "the visit is noted (%d met, %d away)" % [int(b.visits.get(sid, {}).get("met", 0)), int(b.visits.get(sid, {}).get("absent", 0))])
	check(int(b.home_day) >= 0 and not (b.home as Dictionary).is_empty(), "the home survey records %d village tradespeople's wants and goods" % (b.home as Dictionary).size())
	check(n.earned - e0 >= wage and w.total_coins() - w.coin_sources == coins0, "the wage (%d) is paid from what was set aside: no coin made or lost" % wage)
	check(Envoys.target(w) != sid, "the reeve's next envoy goes elsewhere (%s): %s is surveyed and fresh" % [Envoys.target(w), sid])
	# the book is saved and loaded
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	check((Envoys.book(w2).records as Array).size() == (b.records as Array).size() and (Envoys.book(w2).visits as Dictionary).has(sid), "the reeve's book is saved and loaded")


func _test_interview_reads_books() -> void:
	var w := _world()
	var n := _villager(w)
	var j := _send(w, n)
	var sid := str(j.sid)
	w.minutes = 2 * 1440.0 + 11.0 * 60.0
	w.regions.catch_up(w.day())
	var p := {}
	for q in SettlementFolk.people(w, sid):
		if SettlementFolk.present(w, q) and str(q.role) == "keeper":
			p = q
			break
	check(not p.is_empty(), "a keeper at their door in %s" % sid)
	var o := SettlementFolk.offers(w, p)
	Envoys._interview(w, n, j, p)
	var said := (j.carried as Array).filter(func(r): return str(r.about) == str(p.ref))
	var ok := said.size() == (o.sells as Array).size() + (o.wants as Array).size() or (said.size() == 1 and str(said[0].kind) == "none")
	for line in o.sells:
		ok = ok and said.any(func(r): return str(r.side) == "have" and str(r.item) == str(line.item) and int(r.qty) == int(line.n) and int(r.price) == int(line.price))
	for line in o.wants:
		ok = ok and said.any(func(r): return str(r.side) == "want" and str(r.item) == str(line.item) and int(r.qty) == int(line.n) and int(r.price) == int(line.price))
	check(ok, "the interview with %s, the %s, records exactly what their own books will sell and want (%d things)" % [p.name, p.trade, said.size()])
	w.minutes = 2 * 1440.0 + 21.0 * 60.0
	var away := {}
	for q in SettlementFolk.people(w, sid):
		if not SettlementFolk.present(w, q) and not (j.met as Array).has(str(q.ref)):
			away = q
			break
	check(not away.is_empty(), "out of hours a person is away")
	check(Envoys.act(w, n, "envoy_talk", {"job": int(j.id), "ref": str(away.ref)}) and (j.carried as Array).any(func(r): return str(r.about) == str(away.ref) and str(r.kind) == "absent"), "a person not there is recorded absent, never surveyed")


func _test_envoy_dies() -> void:
	var w := _world()
	var n := _villager(w)
	var j := _send(w, n)
	var wage := int(j.reserved)
	_run(w, func() -> bool: return str(j.get("stage", "")) == "back" or not w.manor_work.jobs.has(j), 6 * 1440.0)
	check(str(j.get("stage", "")) == "back" and not (j.carried as Array).is_empty(), "an envoy on the way home carries what they learnt (%d records)" % (j.carried as Array).size())
	var t1 := w.treasury
	w.kill(n, "slain by a bandit")
	check(not w.manor_work.jobs.has(j) and (Envoys.book(w).records as Array).is_empty() and w.treasury == t1 + wage, "slain on the road: what they knew is lost, the book stays empty, the wage set aside (%d) goes back to the treasury" % wage)
	Envoys.post(w)
	check(not _envoy_job(w).is_empty(), "and the reeve sends another")


func _test_reeve_succession() -> void:
	var w := _world()
	var n := _villager(w)
	var j := _send(w, n)
	_run(w, func() -> bool: return Journeys.active(n) and str(n.journey.get("leg", "")) == "there", 4 * 1440.0)
	var old_reeve := w.npc(w.reeve_id)
	w.kill(old_reeve, "old age")                       # the reeve dies while the envoy is away
	check(_run(w, func() -> bool: return not w.manor_work.jobs.has(j), 6 * 1440.0), "the envoy comes home and finishes the mission (day %d)" % w.day())
	var recs := Envoys.book(w).records as Array
	check(not recs.is_empty() and w.reeve_id >= 0 and w.reeve_id != old_reeve.id, "the report reaches the reeve's successor (%s): the book is the office's, not the person's (%d records)" % [w.npc(w.reeve_id).name if w.reeve_id >= 0 else "-", recs.size()])
	# with the office empty the envoy waits: nothing reaches the book until there is a reeve
	var w2 := _world()
	var n2 := _villager(w2)
	var j2 := _send(w2, n2)
	_run(w2, func() -> bool: return str(j2.get("stage", "")) == "back", 6 * 1440.0)
	j2.stage = "report"
	n2.journey = {}
	var keep := w2.reeve_id
	w2.reeve_id = -1
	check(Envoys.plan(w2, n2, j2) and n2.doing == "waiting to report to the reeve" and (Envoys.book(w2).records as Array).is_empty(), "with the office empty the envoy waits to report; the book learns nothing yet")
	w2.reeve_id = keep
	check(Envoys.plan(w2, n2, j2) and n2.doing == "reporting to the reeve", "and reports once there is a reeve again")
