extends SceneTree
## The flight recorder (REC-19, schema mml-recorder/1; stage D1 core + the first D2 choke points). Disabled: nothing exists,
## nothing is written, the world is unchanged. Enabled: the archive is written and reads back (headers, footers, counts), the
## context stack links an action to its decision and a trade's changes to the trade, object threads link, a truncated chunk
## is found on the next start, the storage cap stops the session incomplete without losing anything, and a coin change
## outside any recorded event raises an alert. Run headless:
##   godot --headless --path game --script res://tests/recorder_test.gd
## The 10-day on/off fingerprint comparison is economy_sim.gd (--record DIR) against the same run without it.

var failures := 0
var checks := 0
var tmp_root := ""


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _init() -> void:
	tmp_root = OS.get_cache_dir() + "/mml_recorder_test_%d" % int(Time.get_unix_time_from_system())
	DirAccess.make_dir_recursive_absolute(tmp_root)
	test_disabled()
	test_core_archive()
	test_context_and_threads()
	test_truncated_chunk()
	test_storage_cap()
	test_live_world()
	test_unattributed_coins()
	test_interruptions()
	test_coverage_file()
	print("%d checks, %d failures" % [checks, failures])
	_remove(tmp_root)
	quit(1 if failures > 0 else 0)


func _remove(path: String) -> void:
	for d in DirAccess.get_directories_at(path):
		_remove(path + "/" + d)
	for f in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path + "/" + f)
	DirAccess.remove_absolute(path)


func new_world(seed := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


func sub(name: String) -> String:
	var p := tmp_root + "/" + name
	DirAccess.make_dir_recursive_absolute(p)
	return p


func run_minutes(w: World, minutes: int) -> void:
	for i in minutes:
		w.update(0.5)
		w.player.hunger = 100.0


func world_hash(w: World) -> String:
	return JSON.stringify(w.to_dict(), "", true).md5_text() + "|" + str(w.rng.state)


func session_dir(rec: FlightRecorder) -> String:
	return FlightRecorder._abs(rec.dir)


# ----------------------------------------------------------------------------
func test_disabled() -> void:
	check(not FlightRecorder.enabled(), "switched off by default (recorder.json enabled is false)")
	var default_root := OS.get_user_data_dir() + "/recorder"
	var before := DirAccess.get_directories_at(default_root).size() if DirAccess.dir_exists_absolute(default_root) else 0
	var a := new_world()
	check(a.recorder == null, "disabled: World.recorder is null, no recorder object is constructed")
	run_minutes(a, 24 * 60)
	var after := DirAccess.get_directories_at(default_root).size() if DirAccess.dir_exists_absolute(default_root) else 0
	check(before == after, "disabled: no session directory or file is created")
	check(not a.to_dict().has("recorder"), "disabled: the saved world has no recorder section")
	var ha := world_hash(a)
	# the same day with a recorder: the world and the random state are identical (it never draws from w.rng, never mutates)
	var b := new_world()
	WorldRecorder.attach(b, {"root": sub("equal")})
	check(b.recorder != null, "enabled by attach: World.recorder exists")
	run_minutes(b, 24 * 60)
	var rec: WorldRecorder = b.recorder
	check(world_hash(b) == ha, "recording changes nothing: to_dict and the RNG state after one day are identical to an unrecorded world")
	check(not b.to_dict().has("recorder"), "enabled: the saved world still has no recorder section")
	check(int(rec.counts.event) > 0, "enabled: events were recorded (%d)" % int(rec.counts.event))
	b.dispose()


func test_core_archive() -> void:
	var r := FlightRecorder.new({"root": sub("core"), "buffer_rows": 64}, {"seed": 7})
	check(DirAccess.dir_exists_absolute(session_dir(r)), "a session directory exists under the root")
	for i in 150:                                     # more rows than the buffer holds: flushed early, never dropped
		r.event("world", "coins", "audit", "probe", "p:1", "ok", "", {"x": i})
	check(r.early_flushes >= 1, "a full buffer is flushed early (%d early flushes)" % r.early_flushes)
	check(r.peak_buffer <= 64, "the buffer never exceeds its bound (peak %d)" % r.peak_buffer)
	r.minute = 70.0
	r.event("world", "coins", "audit", "probe", "p:2")
	r.flush()
	r.day = 1
	r.event("world", "coins", "audit", "probe", "p:3")
	r.finish()
	var dir := session_dir(r)
	var scan := RecorderArchive.scan_session(dir)
	check(scan.truncated.is_empty(), "every chunk written has its footer (none truncated)")
	check(int(scan.rows.get("event", 0)) == 152 and r.counts.event == 152, "rows read back equal rows recorded (152 events)")
	var days := DirAccess.get_directories_at(dir)
	days.sort()
	check(days == PackedStringArray(["d0000", "d0001"]), "one directory per game day: %s" % str(days))
	var evs := RecorderArchive.read_table(dir, "event")
	var seqs_ok := true
	for i in range(1, evs.size()):
		seqs_ok = seqs_ok and int(evs[i].seq) > int(evs[i - 1].seq)
	check(evs.size() == 152 and seqs_ok, "events read back in sequence order")
	var first := RecorderArchive.read_chunk(dir + "/" + RecorderArchive.chunk_files(dir)[0])
	check(first.header.schema == "mml-recorder/1" and first.header.session == r.session and first.footer.rows == first.rows.size() and int(first.header.first_seq) == int(first.rows[0][0]), "a chunk's header names schema and session, its footer counts its rows")
	var sess = RecorderArchive.read_json(dir + "/session.json")
	check(sess.ended and sess.completeness == "complete" and sess.seed == 7 and sess.counts.event == 152, "session.json: ended, complete, with the caller's metadata and counts")
	check(r.unknown_codes.is_empty(), "every code used is in recorder_codes.json (unknown: %s)" % str(r.unknown_codes))


func test_context_and_threads() -> void:
	var r := FlightRecorder.new({"root": sub("ctx")})
	var plan := r.begin("brain", "decide", "decision", "plan_next", "p:1")
	var act := r.begin("brain", "act", "action", "buy_from", "p:1")
	var trade := r.begin("economy", "trade", "transaction", "trade", "p:1")
	r.state_change(trade, "p:1", "coins", 10, 7, "world.trade")
	r.end(trade)
	r.end(act, "failed", "act_returned_false")
	r.end(plan)
	var later := r.event("world", "coins", "audit", "probe", "p:9")
	var evs := {}
	for e in r.buffer.event:
		evs[int(e[FlightRecorder.EV_ID])] = e
	check(int(evs[act][FlightRecorder.EV_PARENT]) == plan and int(evs[trade][FlightRecorder.EV_PARENT]) == act, "children inherit the open parent (act under decision, trade under act)")
	check(int(evs[trade][FlightRecorder.EV_INTERACTION]) == plan and int(evs[later][FlightRecorder.EV_PARENT]) == -1, "children share the root's interaction id; an event outside any context has no parent")
	check(r.buffer.state_change[0][1] == trade and r.buffer.state_change[0][6] == -3, "a state change references its event and carries before, after and delta")
	r.state_change(later, "p:9", "item:log", 1, FlightRecorder.NOT_EVALUATED, "world.transfer")
	check(r.buffer.state_change[1][6] == FlightRecorder.NOT_EVALUATED, "an unevaluated value is stored as 'not evaluated', no delta invented")
	var o1 := r.event("economy", "trade", "transaction", "offer", "p:1", "ok", "", {"object": "contract:5"})
	var o2 := r.event("economy", "trade", "transaction", "accept", "p:2", "ok", "", {"object": "contract:5"})
	var o3 := r.event("economy", "trade", "transaction", "deliver", "p:2", "ok", "", {"object": "contract:5"})
	check(r.buffer.link.size() == 2 and r.buffer.link[0][1] == o2 and r.buffer.link[0][2] == o1 and r.buffer.link[1][1] == o3 and r.buffer.link[1][2] == o2 and r.buffer.link[1][3] == "same_object", "an object thread links each event to the object's previous one")
	var open_id := r.begin("brain", "act", "action", "craft", "p:3")
	r.finish()
	check(r.finished and RecorderArchive.read_table(session_dir(r), "event").any(func(e): return int(e.id) == open_id and e.outcome == "unfinished"), "an event still open at finish is written as unfinished")
	check(r.unknown_codes.is_empty(), "context test used only listed codes")


func test_truncated_chunk() -> void:
	var cfg := {"root": sub("trunc"), "live_grace_seconds": 0}
	var a := FlightRecorder.new(cfg)
	for h in 3:
		a.minute = h * 60.0
		for i in 20:
			a.event("world", "coins", "audit", "probe", "p:1")
		a.flush()
	var dir := session_dir(a)
	var files := RecorderArchive.chunk_files(dir)
	check(files.size() == 3, "three hourly chunks for the event table")
	var path: String = dir + "/" + files[1]                         # the session is never finished: it was interrupted
	var f := FileAccess.open(path, FileAccess.READ)
	var raw := f.get_buffer(f.get_length())
	f.close()
	var g := FileAccess.open(path, FileAccess.WRITE)
	g.store_buffer(raw.slice(0, raw.size() / 2))                    # the file cut in half
	g.close()
	check(not RecorderArchive.read_chunk(path).ok, "a chunk cut in half does not read as complete")
	var torn := dir + "/d0000/event.h09.p0.jsonl.gz"                # a chunk written without its footer
	RecorderArchive.write_chunk(torn, {"schema": "mml-recorder/1", "table": "event", "columns": FlightRecorder.COLUMNS.event}, [[1, 1]], false)
	check(RecorderArchive.read_chunk(torn).state == "no_footer", "a chunk without a footer reads as no_footer")
	var b := FlightRecorder.new(cfg)                                # the next start
	var names := b.recovered.map(func(x): return str(x.file))
	check(b.recovered.size() == 2 and names.has(files[1]) and names.has("d0000/event.h09.p0.jsonl.gz"), "next start: the interrupted session's two bad chunks are recorded in the new session record (%s)" % str(names))
	check(not names.has(files[0]) and not names.has(files[2]), "next start: the complete chunks are not reported")
	check(FileAccess.file_exists(path) and FileAccess.file_exists(dir + "/" + files[0]), "nothing is deleted")
	var rec = RecorderArchive.read_json(session_dir(b) + "/session.json")
	check(rec.recovered.size() == 2, "the new session.json lists them")
	var c := FlightRecorder.new(cfg)
	check(c.recovered.is_empty(), "a session already examined is not reported again")
	b.finish()
	c.finish()


func test_storage_cap() -> void:
	var r := FlightRecorder.new({"root": sub("cap"), "storage_cap_bytes": 6000})
	var stopped_day := -1
	for h in 400:
		r.day = h / 24
		r.minute = (h % 24) * 60.0
		for i in 30:
			r.event("world", "coins", "audit", "probe", "p:%d" % i, "ok", "", {"detail": "row %d" % (h * 30 + i)})
		r.flush()
		if r.stopped and stopped_day < 0:
			stopped_day = r.day
			break
	check(r.stopped and r.completeness().begins_with("incomplete: storage cap reached at day"), "the cap stops recording and marks the session incomplete: %s" % r.completeness())
	var kept: int = r.counts.event
	r.event("world", "coins", "audit", "probe", "p:1")
	check(r.counts.event == kept and r.buffered == 0, "after the stop nothing more is recorded")
	r.finish()
	var dir := session_dir(r)
	var scan := RecorderArchive.scan_session(dir)
	check(scan.truncated.is_empty() and int(scan.rows.event) == kept, "everything recorded before the stop is on disk and complete (%d rows)" % kept)
	var sess = RecorderArchive.read_json(dir + "/session.json")
	check(sess.completeness.begins_with("incomplete") and int(sess.incomplete_at.day) == stopped_day and int(sess.incomplete_at.seq) == r.seq, "session.json records the day and sequence where it stopped")


func read_all(rec: WorldRecorder) -> Dictionary:
	var out := {}
	for t in FlightRecorder.TABLES:
		out[t] = RecorderArchive.read_table(session_dir(rec), t)
	return out


func test_live_world() -> void:
	var w := new_world()
	var rec := WorldRecorder.attach(w, {"root": sub("live")})
	run_minutes(w, 2 * 24 * 60)
	var counts := rec.counts.duplicate()
	var alive := w.npcs.filter(func(n): return n.alive).size()
	w.dispose()
	var d := read_all(rec)
	var scan := RecorderArchive.scan_session(session_dir(rec))
	check(scan.truncated.is_empty() and scan.ok == rec.chunks, "live: every chunk is complete (%d chunks)" % rec.chunks)
	var same := true
	for t in FlightRecorder.TABLES:
		same = same and (d[t] as Array).size() == int(counts[t])
	check(same, "live: rows on disk equal rows recorded in every table %s" % str(counts))
	check(rec.completeness() == "complete" and rec.unknown_codes.is_empty(), "live: session complete, no unknown codes (%s)" % str(rec.unknown_codes))
	var ev := {}
	for e in d.event:
		ev[int(e.id)] = e
	# decisions: one per decide call; the chosen branch is the one the chain returned; later branches are not evaluated
	var decisions: Array = d.decision
	var chosen_ok := not decisions.is_empty()
	var by_ev := {}
	for a in d.alternative:
		if not by_ev.has(int(a.event)):
			by_ev[int(a.event)] = []
		by_ev[int(a.event)].append(a)
	var chain_ok := true
	var branches := {}
	for x in decisions:
		branches[x.chosen] = true
		var alts: Array = by_ev.get(int(x.event), [])
		var yes := alts.filter(func(a): return a.evaluated == "yes")
		var winners := yes.filter(func(a): return a.feasible == true)
		chain_ok = chain_ok and winners.size() == 1 and winners[0].option == x.chosen
		chosen_ok = chosen_ok and ev[int(x.event)].category == "decision" and ev[int(x.event)].actor == x.actor
		if not alts.is_empty() and alts[-1].option.begins_with("after:"):
			chain_ok = chain_ok and alts[-1].evaluated == FlightRecorder.NOT_EVALUATED and alts[-1].option == "after:" + str(x.chosen)
	check(chosen_ok and chain_ok, "live: each decision event has one winning branch among its evaluated alternatives, later branches 'not evaluated' (%d decisions, branches %s)" % [decisions.size(), str(branches.keys())])
	check(d.factor.any(func(f): return f.factor == "hunger" and typeof(f.value) == TYPE_FLOAT), "live: the hunger value a guard read is stored as a factor")
	# actions: parent is the plan's decision (same actor) or none
	var acts: Array = d.event.filter(func(e): return e.category == "action")
	var linked := 0
	var bad_parent := 0
	for a in acts:
		if int(a.parent) > 0:
			linked += 1
			var p = ev.get(int(a.parent))
			if p == null or p.category != "decision" or p.actor != a.actor or int(a.interaction) != int(p.interaction):
				bad_parent += 1
	check(acts.size() > 0 and linked > 0 and bad_parent == 0, "live: an action's parent is its own decision (%d actions, %d linked, %d mislinked)" % [acts.size(), linked, bad_parent])
	check(acts.any(func(e): return e.outcome == "ok") and acts.any(func(e): return e.outcome == "failed" and e.reason == "act_returned_false"), "live: actions record ok and failed outcomes")
	# trades and transfers: participants and state changes reference the transaction event
	var trades: Array = d.event.filter(func(e): return e.subtype == "trade" and e.outcome == "ok")
	var sc_by_ev := {}
	for s in d.state_change:
		if not sc_by_ev.has(int(s.event)):
			sc_by_ev[int(s.event)] = []
		sc_by_ev[int(s.event)].append(s)
	var trade_ok := not trades.is_empty()
	var under_act := 0
	for t in trades:
		var sc: Array = sc_by_ev.get(int(t.id), [])
		var coins := sc.filter(func(s): return s.prop == "coins")
		var items := sc.filter(func(s): return str(s.prop).begins_with("item:"))
		trade_ok = trade_ok and coins.size() == 2 and items.size() == 2 and int(coins[0].delta) + int(coins[1].delta) == 0 and int(items[0].delta) + int(items[1].delta) == 0 and int(coins[0].delta) != 0
		if int(t.parent) > 0 and ev[int(t.parent)].category == "action":
			under_act += 1
	check(trade_ok, "live: every trade has two coin and two item state changes that net to zero (%d trades)" % trades.size())
	check(under_act > 0, "live: a trade bought by a villager is a child of its action (%d of %d), so decision -> action -> trade is one chain" % [under_act, trades.size()])
	var moves: Array = d.event.filter(func(e): return e.subtype == "transfer" and e.outcome == "ok")
	var move_ok := not moves.is_empty()
	for t in moves:
		var sc: Array = sc_by_ev.get(int(t.id), [])
		move_ok = move_ok and sc.size() == 2 and int(sc[0].delta) + int(sc[1].delta) == 0
	check(move_ok, "live: every transfer has two item state changes that net to zero (%d transfers)" % moves.size())
	# hourly samples
	var hours := {}
	for s in d.sample:
		hours["%d|%d" % [s.day, s.hour]] = true
	check(hours.size() >= 47 and d.sample.size() >= 47 * (alive - 5), "live: hourly samples of the living villagers (%d rows over %d hours)" % [d.sample.size(), hours.size()])
	var total_alerts: Array = d.alert.filter(func(a): return a.rule == "coin.unattributed_total")
	check(total_alerts.is_empty(), "live: no coin was created or lost outside the books in two days (World.coin_sources accounts every crossing)")
	for a in d.alert:
		if a.rule == "coin.unattributed_holder":
			check(ev.has(int(a.event)) and ev[int(a.event)].outcome == "unattributed", "live: an unattributed holder alert points at its unattributed event")
			break


func test_unattributed_coins() -> void:
	var w := new_world()
	var rec := WorldRecorder.attach(w, {"root": sub("audit")})
	run_minutes(w, 3 * 60)
	rec._audit_coins()                                  # a clean baseline
	var pair: Array = w.npcs.filter(func(n): return n.role == "adult" and n.job in ["farmer", "miner", "woodcutter"])
	var a: NPC = pair[0]                                # (a tavern keeper's sale goes partly to the till, a coin site the audit rightly flags)
	var b: NPC = pair[1]
	a.coins += 20
	b.inv.add("log", 2)
	rec._audit_coins()                                  # the +20 is a coin change outside any event: it is flagged here, and the books are clean again
	var n0: int = rec.counts.alert
	var logs_before := a.inv.count("log")
	check(w.trade(a, b, "log", 2, 3), "a villager buys two logs through World.trade")
	rec._audit_coins()
	check(rec.counts.alert == n0 and a.inv.count("log") == logs_before + 2, "a recorded trade moves coins and raises no alert")
	# a coin change outside any event
	var victim: NPC = w.npcs[2]
	victim.coins += 7
	var mark: int = rec.buffer.alert.size()
	rec._audit_coins()
	var fresh: Array = rec.buffer.alert.slice(mark)
	var holder_alerts: Array = fresh.filter(func(r): return r[3] == "coin.unattributed_holder" and r[4] == "p:%d" % victim.id)
	var total_alerts: Array = fresh.filter(func(r): return r[3] == "coin.unattributed_total")
	check(holder_alerts.size() == 1 and "delta=7" in str(holder_alerts[0][5]), "7 coins added outside any event: one holder alert for that villager, delta 7")
	check(total_alerts.size() == 1 and "delta=7" in str(total_alerts[0][5]) and total_alerts[0][2] == "violation", "and a total alert (a violation): World.total_coins grew with no source")
	var ev_row: Array = rec.buffer.event.filter(func(r): return int(r[FlightRecorder.EV_ID]) == int(holder_alerts[0][6]))[0]
	check(ev_row[15] == "unattributed" and ev_row[13] == "unattributed_coins", "the alert points at an 'unattributed' event with the state change")
	# coins crossing the village boundary are recorded in World.coin_sources: a holder alert, but no total alert
	mark = rec.buffer.alert.size()
	victim.coins += 5
	w.coin_sources += 5
	rec._audit_coins()
	check(rec.buffer.alert.slice(mark).filter(func(r): return r[3] == "coin.unattributed_total").is_empty(), "coins that cross the boundary through World.coin_sources are no total alert")
	w.dispose()


func test_interruptions() -> void:
	var w := new_world()
	var rec := WorldRecorder.attach(w, {"root": sub("interrupt")})
	var n: NPC = w.npcs[3]
	n.plan = [{"k": "go", "to": Vector2i(60, 40), "level": 7}]            # a level no portal reaches
	w._run_plan(n, 0.5, 1.0)
	var lost: Array = rec.buffer.event.filter(func(r): return r[13] == "walk_lost")
	check(lost.size() == 1 and lost[0][15] == "interrupted" and lost[0][16] == "no_level_route" and lost[0][14] == "p:%d" % n.id and lost[0][2] == -1, "a lost walk: an interrupted event, reason no_level_route, no parent invented (the plan had no decision)")
	check(n.plan.is_empty() and n.doing == "lost", "and the game's own handling is unchanged (plan cleared, doing 'lost')")
	var st_id: String = str(w.stations.keys()[0])
	w.stations[st_id]["player_until"] = w.minutes + 1000.0
	n.plan = [{"k": "work", "act": "craft", "args": {"station": st_id}, "min": 10.0}]
	w._run_plan(n, 0.5, 50.0)
	var gave: Array = rec.buffer.event.filter(func(r): return r[13] == "station_giveup")
	check(gave.size() == 1 and gave[0][15] == "abandoned" and gave[0][16] == "station_wait_exceeded" and n.plan.is_empty(), "a station wait run out: an abandoned event")
	# a plan made by decide: the act's parent is the decision
	var m: NPC = w.npcs[4]
	m.plan.clear()
	w.brain.decide(m)
	var dec: Array = rec.buffer.decision.filter(func(r): return r[2] == "p:%d" % m.id)
	check(dec.size() == 1, "decide records exactly one decision event for the call")
	w.dispose()


func test_coverage_file() -> void:
	var f := FileAccess.open("res://data/recorder_coverage.json", FileAccess.READ)
	var cov = JSON.parse_string(f.get_as_text())
	check(cov is Dictionary and cov.format == "mml-recorder-coverage/1", "recorder_coverage.json is present")
	var src := FileAccess.open("res://tests/recorder_test.gd", FileAccess.READ).get_as_text()
	var ok := true
	var fully := 0
	var statuses := ["Fully instrumented", "Partially instrumented", "Not instrumented"]
	for row in cov.rows:
		ok = ok and statuses.has(row.status)
		if row.status == "Fully instrumented":
			fully += 1
			ok = ok and row.has("test") and src.contains("func " + str(row.test) + "(")
		if row.status == "Not instrumented":
			ok = ok and not row.has("test")
	check(ok and fully > 0, "coverage: every status is valid and every 'Fully' row names a test that exists here (%d rows 'Fully')" % fully)
