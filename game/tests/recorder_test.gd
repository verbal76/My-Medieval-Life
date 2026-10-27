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
	test_identity_events()
	test_succession_events()
	test_save_load_events()
	test_life_events()
	test_employment_events()
	test_government_events()
	test_crime_events()
	test_chase_events()
	test_player_verbs()
	test_scripted_equivalence()
	test_person_refs()
	test_judgment_and_relations()
	test_x20_phase3()
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
	check(first.header.schema == FlightRecorder.SCHEMA and first.header.session == r.session and first.footer.rows == first.rows.size() and int(first.header.first_seq) == int(first.rows[0][0]), "a chunk's header names schema and session, its footer counts its rows")
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
	var decisions: Array = d.decision.filter(func(x): return x.kind == "plan_next")     # the brain's chain (judgment-weighted choices are D5's, tested below)
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
	# SIM-GATE-01: one village snapshot an hour, every column filled, counts that agree with the event rows of the same hours
	var snaps: Array = d.snapshot
	var snap_hours := {}
	for sn in snaps:
		snap_hours["%d|%d" % [sn.day, sn.hour]] = true
	check(snaps.size() >= 47 and snap_hours.size() == snaps.size(), "live: one snapshot row an hour (%d rows)" % snaps.size())
	var full := true
	for f in DirAccess.get_files_at(session_dir(rec) + "/d0001"):
		if f.begins_with("snapshot."):
			for r in RecorderArchive.read_chunk(session_dir(rec) + "/d0001/" + f).rows:
				full = full and (r as Array).size() == FlightRecorder.COLUMNS.snapshot.size()
	check(full, "live: each snapshot row has every column of the schema (%d)" % FlightRecorder.COLUMNS.snapshot.size())
	var trades_h := 0
	for sn in snaps:
		trades_h += int(sn.trades_h)
	var trades_all: Array = d.event.filter(func(e): return e.subtype == "trade")
	var last: Dictionary = snaps[-1]
	check(trades_h <= trades_all.size() and trades_h >= trades_all.size() - 200 and int(last.alive) > 0 and int(last.total_coins) > 0 and last.stats_delta is Dictionary,
		"live: the snapshots' hourly trade counts add up to the trade events before the last hour (%d of %d); alive %d, coins %d" % [trades_h, trades_all.size(), int(last.alive), int(last.total_coins)])
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


# ======================================================================== D3: identity, life, employment, government, crime, player, save and load
func identity_world(seed := 1) -> World:
	var w := new_world(seed)
	w.regions.step_day(w.day())
	return w


func rows(rec: WorldRecorder, table: String) -> Array:
	rec.flush()
	return RecorderArchive.read_table(session_dir(rec), table)


func evs(rec: WorldRecorder, subtype: String) -> Array:
	return rows(rec, "event").filter(func(e): return e.subtype == subtype)


func changes_of(rec: WorldRecorder, ev_id: int) -> Array:
	return rows(rec, "state_change").filter(func(c): return int(c.event) == ev_id)


func parts_of(rec: WorldRecorder, ev_id: int) -> Array:
	return rows(rec, "participant").filter(func(c): return int(c.event) == ev_id)


func plain_adult(w: World) -> NPC:
	for h in range(3, w.households.size()):
		if w.households[h].get("ended", false):
			continue
		var ms: Array = w.brain._members(h)
		if ms.is_empty() or Migration._any_barred(w, ms):
			continue
		for o: NPC in ms:
			if o.role == "adult" and Life._may_move(w, o):
				return o
	return null


func leave_to(w: World, s: OffMapSettlement, who: NPC) -> void:
	Migration._pre_leave(w, [who])
	var load_ := Migration._pack(w, [who])
	s.receive_person(load_.people[0], int(load_.coins), load_.goods, Migration.hiring(s) if Migration.hiring(s) != "" else "farm")
	Migration._gone(w, s, [who], load_, null, "work")


func come_back(w: World, id: int) -> NPC:
	var at: Array = []
	for s: OffMapSettlement in w.regions.list:
		for hi in s.hh.size():
			for j in (s.hh[hi].mem as Array).size():
				if OffMapSettlement.member_id(s.hh[hi].mem[j]) == id:
					at = [s, hi, j]
	var s: OffMapSettlement = at[0]
	var load_ := s.person_load(at[1], at[2])
	var n := Migration._villager(w, Migration._with_who(s, load_.people[0], str(s.hh[at[1]].trade)), int(load_.coins))
	var h := Migration._house(w, [n])
	s.release_person(at[1], at[2])
	Migration._settled(w, s, [n], h, load_.goods, int(load_.coins), "work")
	return n


func test_identity_events() -> void:
	var w := identity_world()
	var rec := WorldRecorder.attach(w, {"root": sub("ident")})
	var s: OffMapSettlement = w.regions.by_id["higham"]
	var who := plain_adult(w)
	var id := who.id
	var ref := "p:%d" % id
	leave_to(w, s, who)
	var left := evs(rec, "left_village")
	check(left.size() == 1 and left[0].actor == ref and left[0].category == "identity", "migration: leaving the village is an identity event on the person's permanent reference (%s)" % ref)
	var lc := changes_of(rec, int(left[0].id))
	check(lc.size() == 1 and lc[0].prop == "where" and lc[0].before == "village" and lc[0].after == "higham", "leave: the state change says where, village -> higham")
	var back := come_back(w, id)
	var ret := evs(rec, "returned_to_village")
	check(back == who and ret.size() == 1 and ret[0].actor == ref and back.id == id, "migration: returning is an identity event on the identical reference (same NPC record, same id)")
	var rc := changes_of(rec, int(ret[0].id))
	check(rc.size() == 1 and rc[0].before == "higham" and rc[0].after == "village", "return: higham -> village")
	var refs := {}
	for e in rows(rec, "event"):
		if e.category == "identity" and (e.actor == ref):
			refs[e.actor] = true
	check(refs.keys() == [ref], "a person's reference is identical before and after leave/return (only %s)" % ref)
	# no second person was made for them: no 'arrival' registration for this id
	check(evs(rec, "registered_arrival").filter(func(e): return e.actor == ref).is_empty(), "no new registration was made for the returning person (their register entry is the same)")
	# the person acts again under the same reference
	run_minutes(w, 4 * 60)
	check(rows(rec, "event").any(func(e): return e.actor == ref and e.category in ["decision", "action"]), "after returning they decide and act under the same reference")
	# a person born in a settlement: a band id in the register event
	var known := {}
	for h in s.hh:
		for m in h.mem:
			known[OffMapSettlement.member_id(m)] = true
	var guard := 0
	var born := 0
	while born == 0 and guard < 400:
		guard += 1
		w.minutes += World.DAY
		w.regions.step_day(w.day())
		for h in s.hh:
			for m in h.mem:
				var mid := OffMapSettlement.member_id(m)
				if mid > 0 and not known.has(mid):
					born = mid
	var births := evs(rec, "registered_settlement_birth")
	check(born >= World.BAND_START and births.any(func(e): return e.actor == "p:%d" % born and "band id" in e.detail), "a settlement birth is a register event with its band id (p:%d)" % born)
	var bc := changes_of(rec, int(births.filter(func(e): return e.actor == "p:%d" % born)[0].id))
	check(bc.size() == 1 and bc[0].before == "unregistered" and bc[0].after == "higham", "and its state change says unregistered -> higham")
	# death: the villager dies, the register moves them to dead under the same reference
	var victim := plain_adult(w)
	w.kill(victim, "old age")
	var died := evs(rec, "died").filter(func(e): return e.actor == "p:%d" % victim.id)
	check(died.size() == 1 and changes_of(rec, int(died[0].id))[0].after == "dead", "death is also a register transition on the same reference")
	check(rec.unknown_codes.is_empty(), "identity: no code outside recorder_codes.json (%s)" % str(rec.unknown_codes))
	w.dispose()


func player_children(w: World) -> Array:
	var p := w.player
	p.sex = "male"
	var mother: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.sex == "female" and n.partner < 0 and n.household >= 3 and Life.npc_age(w, n) >= 18.0)[0]
	var h := mother.household
	var k1 := Life.birth(w, mother, p, h)
	var k2 := Life.birth(w, mother, p, h)
	var Y := Life.year_minutes()
	k1.born = w.minutes - 17.0 * Y
	k2.born = w.minutes - 19.0 * Y
	p.born = w.minutes - 60.0 * Y
	return [k1, k2]


func test_succession_events() -> void:
	var w := identity_world()
	var rec := WorldRecorder.attach(w, {"root": sub("succ")})
	var kids := player_children(w)
	var k2: NPC = kids[1]
	var villager: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.household >= 3 and n.id != k2.id and n.inv.total() > 0)[0]
	w.relations.tie(Life.PLAYER_ID, villager.id).regard = 37.0
	w.relations.tie(Life.PLAYER_ID, villager.id).friends = true
	var old_pid := w.player.pid
	var old_ref := "p:%d" % old_pid
	check(WorldRecorder.ref_of(w.player) == old_ref and old_pid > 0, "the player is referred to by the permanent person id, not p:player (%s)" % old_ref)
	# a trade by the player, before the succession
	var item: String = villager.inv.ids()[0]
	villager.inv.add(item, 3)
	w.player.coins = 500
	check(w.trade(w.player, villager, item, 1, 0, 3), "the predecessor buys from a villager")
	var ties_before := rec._player_view_ties()
	w.damage_player(1000.0, "test")
	w.continue_as_heir()
	var heir_ref := "p:%d" % w.player.pid
	check(w.player.pid == k2.id and heir_ref == "p:%d" % k2.id and heir_ref != old_ref, "succession: the heir (the player's child) keeps the child's own reference %s; the predecessor %s is a different reference" % [heir_ref, old_ref])
	var su := evs(rec, "succession")
	check(su.size() == 1 and su[0].actor == old_ref, "one succession event, acting on the predecessor")
	var sp := parts_of(rec, int(su[0].id))
	check(sp.any(func(x): return x.ref == old_ref and x.role == "predecessor:player") and sp.any(func(x): return x.ref == heir_ref and x.role == "heir:player"), "its participants are two different references: the predecessor and the heir, each marked as holding the player role")
	var sc := changes_of(rec, int(su[0].id))
	check(sc.size() == 1 and sc[0].ref == "role:player" and sc[0].before == old_ref and sc[0].after == heir_ref, "the state change is the player role passing from the predecessor to the heir")
	check(("live_view_ties(-2) before=%d after=%d" % [ties_before, rec._player_view_ties()]) in su[0].detail and ties_before > 0 and rec._player_view_ties() == ties_before, "the live -2 view continues unchanged for the heir (%d ties before and after)" % ties_before)
	check("tie_history_for_predecessor=" in su[0].detail and not str(su[0].detail).ends_with("=0"), "and a snapshot of the predecessor's ties is kept under their id")
	var moves := rows(rec, "event").filter(func(e): return int(e.parent) == int(su[0].id) and e.category == "identity")
	check(moves.any(func(e): return e.subtype == "became_ancestor" and e.actor == old_ref) and moves.any(func(e): return e.subtype == "became_player" and e.actor == heir_ref), "the identity moves are children of the succession: predecessor -> ancestor, heir -> player")
	# the heir acts under the new reference with the role marker; the predecessor's old events keep the old one
	w.player.coins = 500
	check(w.trade(w.player, villager, item, 1, 0, 3), "the heir buys from a villager")
	var trades := evs(rec, "trade").filter(func(e): return e.outcome == "ok")
	var tr_parts := parts_of(rec, int(trades[0].id)) + parts_of(rec, int(trades[-1].id))
	check(trades.size() == 2 and trades[0].actor == old_ref and trades[1].actor == heir_ref, "trades: the predecessor's is on %s, the heir's on %s" % [old_ref, heir_ref])
	check(tr_parts.any(func(x): return x.ref == old_ref and x.role == "buyer:player") and tr_parts.any(func(x): return x.ref == heir_ref and x.role == "buyer:player"), "both appear as buyer:player (the marker), under their own permanent references")
	check(not rows(rec, "event").any(func(e): return e.actor == "p:player") and not rows(rec, "participant").any(func(x): return x.ref == "p:player"), "no event or participant uses a p:player identity")
	var deaths := evs(rec, "death").filter(func(e): return e.actor == old_ref)
	check(deaths.size() == 1 and "cause=test" in str(deaths[0].detail) and changes_of(rec, int(deaths[0].id))[0].after == false, "the player's own death is recorded on the predecessor's reference, with its cause")
	# a relative heir: a new band id, still a single stable reference
	var w2 := identity_world(2)
	var rec2 := WorldRecorder.attach(w2, {"root": sub("succ2")})
	var o2 := "p:%d" % w2.player.pid
	w2.player.alive = false
	w2.continue_as_heir()
	var n2 := "p:%d" % w2.player.pid
	var su2 := evs(rec2, "succession")
	check(su2.size() == 1 and n2 != o2 and w2.player.pid >= World.BAND_START and ("heir_is_the_players_child=false" in su2[0].detail), "a relative heir: a new band-id reference (%s), a different person from %s" % [n2, o2])
	w2.dispose()
	check(rec.unknown_codes.is_empty() and rec2.unknown_codes.is_empty(), "succession: no code outside recorder_codes.json")
	w.dispose()


func test_save_load_events() -> void:
	var w := identity_world()
	var rec := WorldRecorder.attach(w, {"root": sub("saveload")})
	var who := plain_adult(w)
	var id := who.id
	leave_to(w, w.regions.by_id["higham"], who)
	run_minutes(w, 120)
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true))
	rec.saved(d)
	var sv := evs(rec, "world_saved")
	check(sv.size() == 1 and ("save_version=%d" % World.SAVE_VERSION) in sv[0].detail, "saving: a session event with the save version")
	var people_before := w.people.keys().duplicate()
	var w2 := World.new()
	var rec2 := WorldRecorder.attach(w2, {"root": sub("saveload2")})
	w2.load_dict(VillageMap.load_default(), d)
	var lo := evs(rec2, "world_loaded")
	check(lo.size() == 1 and ("save_version=%d" % World.SAVE_VERSION) in lo[0].detail and "ids_unchanged=true" in lo[0].detail, "loading: a session note that the world was loaded, its save version and that the ids are unchanged")
	var lc := changes_of(rec2, int(lo[0].id))
	check(lc.size() == 1 and lc[0].prop == "people" and lc[0].before == lc[0].after and int(lc[0].after) == people_before.size(), "the people count before and after the load is identical (%d)" % people_before.size())
	check(rows(rec2, "alert").filter(func(a): return a.rule == "identity.ids_changed_on_load").is_empty(), "no identity alert")
	check(w2.people.keys().size() == people_before.size() and people_before.all(func(k): return w2.people.has(k)), "every person id of the saved world is in the loaded one")
	# a person away at save time comes back under the same reference in the loaded session
	var back := come_back(w2, id)
	var ret := evs(rec2, "returned_to_village")
	check(back.id == id and ret.size() == 1 and ret[0].actor == "p:%d" % id, "mid-journey: the person comes back in the loaded session on the same reference p:%d" % id)
	run_minutes(w2, 3 * 60)
	check(rows(rec2, "event").any(func(e): return e.actor == "p:%d" % id and e.category in ["decision", "action"]), "and acts under it")
	# the audit starts afresh after a load: a clean hour raises no total alert
	check(rows(rec2, "alert").filter(func(a): return a.rule == "coin.unattributed_total").is_empty(), "the coin audit re-baselines after a load: no total alert")
	check(rec.unknown_codes.is_empty() and rec2.unknown_codes.is_empty(), "save/load: no code outside recorder_codes.json")
	w2.dispose()
	w.dispose()


func test_life_events() -> void:
	var w := identity_world()
	var rec := WorldRecorder.attach(w, {"root": sub("life")})
	var mother: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.sex == "female" and n.partner >= 0 and n.household >= 3)[0]
	var father: NPC = w.npc(mother.partner)
	var k := Life.birth(w, mother, father, mother.household)
	var b := rows(rec, "event").filter(func(e): return e.subtype == "birth" and e.category == "life")
	check(b.size() == 1 and b[0].actor == "p:%d" % k.id, "birth: one event on the child's permanent reference")
	var bp := parts_of(rec, int(b[0].id))
	check(bp.any(func(x): return x.ref == "p:%d" % mother.id and x.role == "mother") and bp.any(func(x): return x.ref == "p:%d" % father.id and x.role == "father") and bp.any(func(x): return x.ref == "p:%d" % k.id and x.role == "child"), "with child, mother and father as participants")
	check(rows(rec, "event").any(func(e): return e.subtype == "registered_birth" and e.category == "identity" and e.actor == "p:%d" % k.id), "and the register's own birth record on the same id")
	# ageing into a role
	k.born = w.minutes - 17.0 * Life.year_minutes()
	Life.sync_roles(w)
	var rc := evs(rec, "role_changed").filter(func(e): return e.actor == "p:%d" % k.id)
	check(rc.size() == 1 and changes_of(rec, int(rc[0].id))[0].before == "child" and changes_of(rec, int(rc[0].id))[0].after == "adult", "ageing: a child becomes an adult (role state change)")
	# death with its cause and the heir
	var old: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.partner >= 0 and n.coins > 0 and n.household >= 3 and n.id != mother.id and n.id != father.id)[0]
	var coins: int = old.coins
	var heir: NPC = w._heir(old)
	w.kill(old, "old age")
	var dx := evs(rec, "death").filter(func(e): return e.actor == "p:%d" % old.id)
	check(dx.size() == 1 and "cause=old age" in dx[0].detail, "death: an event with its cause")
	var dc := changes_of(rec, int(dx[0].id))
	check(dc.any(func(c): return c.prop == "alive" and c.before == true and c.after == false), "and the state change alive true -> false")
	check(dc.any(func(c): return c.prop == "coins" and c.ref == "p:%d" % old.id and int(c.delta) == -coins) and (heir == null or dc.any(func(c): return c.prop == "coins" and c.ref == "p:%d" % heir.id and int(c.delta) == coins)), "the purse passes to the heir as two coin state changes of equal size (%d coins)" % coins)
	# a slain villager's coins lie in the loot
	var slain: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.coins > 0 and n.household >= 3)[0]
	var sc: int = slain.coins
	w.kill(slain, "slain by test")
	var sx := evs(rec, "death").filter(func(e): return e.actor == "p:%d" % slain.id)
	var scs := changes_of(rec, int(sx[0].id))
	check(scs.any(func(c): return c.ref == "loot" and int(c.delta) == sc), "a slain villager's coins are recorded going to the loot (%d)" % sc)
	# partners: the player and a villager
	var cand: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and Life.partner_refusal(w, n) == "":
			cand = n
			break
	if cand != null:
		check(Life.partner_player(w, cand) == "", "the player and a villager become partners")
		var pe := evs(rec, "partnership")
		check(pe.size() == 1 and parts_of(rec, int(pe[0].id)).size() == 2 and changes_of(rec, int(pe[0].id)).size() == 2, "partnership: an event with both people and a partner state change each")
	# guardianship
	var orphan: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "child" and n.household >= 3)[0]
	var target_h: int = (w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.household >= 3 and n.household != orphan.household)[0] as NPC).household
	var from_h := orphan.household
	Guardianship.move(w, orphan, target_h, "relative")
	var ge := evs(rec, "guardianship_placement")
	check(ge.size() == 1 and ge[0].actor == "p:%d" % orphan.id and "tier=relative" in ge[0].detail and int(changes_of(rec, int(ge[0].id))[0].before) == from_h and int(changes_of(rec, int(ge[0].id))[0].after) == target_h, "guardianship: a placement event with the household before and after")
	check(rec.unknown_codes.is_empty(), "life: no code outside recorder_codes.json (%s)" % str(rec.unknown_codes))
	w.dispose()


func test_employment_events() -> void:
	var w := identity_world()
	var rec := WorldRecorder.attach(w, {"root": sub("employ")})
	var smith: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.job == "smith")[0]
	var hand: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.job not in ["smith", "guard", "reeve", "sage"] and n.household >= 3)[0]
	w.brain._change_job(hand, "", "make them free")
	var jt0 := evs(rec, "job_taken").size()
	w.brain._change_job(hand, "woodcutter", "test hire")
	var jt := evs(rec, "job_taken").slice(jt0)
	check(jt.size() == 1 and jt[0].actor == "p:%d" % hand.id and changes_of(rec, int(jt[0].id))[0].before == "" and changes_of(rec, int(jt[0].id))[0].after == "woodcutter", "job change: job_taken with the job before and after")
	w.brain._change_job(hand, "", "test layoff")
	check(evs(rec, "job_lost").size() == 2, "and job_lost (the free-up and this one)")
	var n_vac := w.vacancies.size()
	w.kill(smith, "old age")
	var vo := evs(rec, "vacancy_opened")
	check(vo.size() == 1 and "job=smith" in vo[0].detail and w.vacancies.size() == n_vac + 1 and int(changes_of(rec, int(vo[0].id))[0].delta) == 1, "vacancy opened by the smith's death: an event with the vacancy count +1")
	for v in w.vacancies:
		v.day = w.day() - 100
	w.brain.succession_dawn()
	var vf := evs(rec, "vacancy_filled")
	check(vf.size() >= 1 and "job=smith" in vf[0].detail and int(changes_of(rec, int(vf[0].id))[0].delta) == -1, "and filled at the next succession: an event on the new smith with the vacancy count -1")
	check(evs(rec, "job_taken").size() + evs(rec, "job_switched").size() >= 2, "the filling is also a job change on the same person")
	# hiring competition: wage offers
	var cfg: Dictionary = GameData.b("hiring_competition")
	for i in int(cfg.unfilled_days) + 1:
		w.brain._hiring_competition(3, 5)
	var wo := evs(rec, "wage_offer_raised")
	check(wo.size() >= 1 and int(changes_of(rec, int(wo[0].id))[0].after) > int(changes_of(rec, int(wo[0].id))[0].before), "hiring competition: a raised wage offer with the raise before and after")
	for i in int(cfg.unfilled_days) * 4:
		w.brain._hiring_competition(0, 0)
	check(evs(rec, "wage_offer_eased").size() >= 1, "and an eased one when the places fill")
	check(rec.unknown_codes.is_empty(), "employment: no code outside recorder_codes.json (%s)" % str(rec.unknown_codes))
	w.dispose()


func test_government_events() -> void:
	var w := identity_world()
	var rec := WorldRecorder.attach(w, {"root": sub("gov")})
	run_minutes(w, 60)
	w.treasury = 0
	for n: NPC in w.npcs:
		if n.alive and n.household >= 0:
			n.coins += 300
			w.coin_sources += 300                      # (the test's own purse, counted as money from outside)
	rec._audit_coins()
	var total0 := w.total_coins()
	w.brain.reeve_day()
	var pass_ev := evs(rec, "reeve_day")
	check(pass_ev.size() == 1 and pass_ev[0].category == "civic", "reeve_day: one pass event")
	var pid := int(pass_ev[0].id)
	var kids := rows(rec, "event").filter(func(e): return int(e.parent) == pid)
	var taxes := kids.filter(func(e): return e.subtype == "tax")
	check(taxes.size() > 0, "tax: collected per payer as children of the pass (%d payments)" % taxes.size())
	var tax_ok := true
	var manor_sum := 0
	var by_ev := {}
	for c in rows(rec, "state_change"):
		if not by_ev.has(int(c.event)):
			by_ev[int(c.event)] = []
		by_ev[int(c.event)].append(c)
	for t in taxes:
		var cs: Array = by_ev.get(int(t.id), [])
		tax_ok = tax_ok and cs.size() == 2 and int(cs[0].delta) < 0 and int(cs[0].delta) + int(cs[1].delta) == 0 and cs[1].ref == "manor"
		manor_sum += int(cs[1].delta)
	check(tax_ok, "each tax payment is two coin state changes that net to zero: the payer's purse down, the treasury up")
	var summary: Array = by_ev.get(pid, []).filter(func(c): return c.ref == "manor" and c.prop == "coins")
	check(summary.size() == 1 and summary[0].authority == "summary" and int(summary[0].before) == 0, "the pass writes the treasury before (0) and after as a summary row")
	var flows := 0
	for k in kids:
		if k.category == "civic" and k.subsystem == "manor":
			for c in by_ev.get(int(k.id), []):
				if c.ref == "manor":
					flows += int(c.delta)
	check(flows == int(summary[0].delta), "the treasury change of the pass (%d) equals the sum of its recorded flows (%d): nothing moved unrecorded" % [int(summary[0].delta), flows])
	check(w.total_coins() == total0, "conservation: the pass created or lost no coin")
	var before_alerts: int = rows(rec, "alert").filter(func(a): return a.rule == "coin.unattributed_total").size()
	rec._audit_coins()
	check(rows(rec, "alert").filter(func(a): return a.rule == "coin.unattributed_total").size() == before_alerts, "the coin audit has no total alert for the pass")
	# wages and layoffs
	var guard: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.job == "guard")[0]
	var hand: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.job not in ["smith", "guard", "reeve", "sage"] and n.household >= 3)[0]
	w.brain._change_job(hand, "manor_hand", "test")
	w.treasury = 20
	var gc := guard.coins
	w.brain.pay_guards()
	var pg := evs(rec, "pay_guards")
	check(pg.size() == 1, "pay_guards: one pass event")
	var wages := rows(rec, "event").filter(func(e): return e.subtype == "wage" and int(e.parent) == int(pg[0].id))
	check(wages.size() >= 1 and wages.any(func(e): return e.actor == "manor") , "wages: paid by the manor, each a child of the pass (%d)" % wages.size())
	check(guard.coins >= gc and by_ev.size() > 0, "a guard was paid")
	check(evs(rec, "layoff").size() == 1 and rows(rec, "event").any(func(e): return e.subtype == "job_lost" and e.actor == "p:%d" % hand.id and int(e.parent) == int(pg[0].id)), "the manor, short of coin, let its most recent hand go: a layoff event and the job loss, children of the pass")
	w.treasury = 0
	w.brain.pay_guards()
	var unpaid := evs(rec, "wage_unpaid")
	check(unpaid.size() >= 1 and unpaid[0].outcome == "failed" and unpaid[0].reason == "treasury_short", "wages the empty treasury could not pay are failed events with the reason treasury_short (%d)" % unpaid.size())
	check(rec.unknown_codes.is_empty(), "government: no code outside recorder_codes.json (%s)" % str(rec.unknown_codes))
	w.dispose()


func test_crime_events() -> void:
	var w := identity_world()
	var rec := WorldRecorder.attach(w, {"root": sub("crime")})
	w.minutes = float(World.DAY) * 2.0 + 11.0 * 60.0              # a working morning
	var g: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.job == "guard")[0]
	var victim: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.job != "guard" and n.household >= 3)[0]
	w.player.pos = g.pos
	g.target = -1
	g.doing = "idle"
	w.player.coins = 40
	var back := Inventory.new()
	w.player.inv.add("bread", 1)
	var seen := w.witness("theft", "a loaf", victim, {"bread": 1}, back)
	var we := evs(rec, "theft")
	check(we.size() == 1 and we[0].category == "crime" and we[0].actor == "p:%d" % w.player.pid, "witness: a theft event on the player's permanent reference (%d seen)" % seen)
	var wc := changes_of(rec, int(we[0].id))
	check(wc.size() == 1 and wc[0].prop == "crimes" and int(wc[0].delta) == 1, "with the player's crime count +1 as a state change")
	var wp := parts_of(rec, int(we[0].id))
	check(wp.any(func(x): return x.role == "offender:player") and wp.any(func(x): return x.role == "victim" and x.ref == "p:%d" % victim.id), "participants: the offender (player marker) and the victim")
	var gc := evs(rec, "guard_confront")
	if seen > 0 and w.last_guard != "":
		check(gc.size() == 1 and int(gc[0].parent) == int(we[0].id), "guard_confront is a child of the witness event")
		var cs := changes_of(rec, int(gc[0].id))
		var pc := cs.filter(func(c): return c.prop == "coins" and c.ref == "p:%d" % w.player.pid)
		var mc := cs.filter(func(c): return c.prop == "coins" and c.ref == "manor")
		check(pc.size() == 1 and mc.size() == 1 and int(pc[0].delta) < 0 and int(pc[0].delta) + int(mc[0].delta) == 0, "the fine: the player's coins before/after and the treasury's, equal and opposite (%d)" % int(pc[0].delta))
		check(cs.any(func(c): return c.prop == "item:bread" and int(c.delta) == -1), "and the stolen goods returned, as an item state change")
	else:
		check(false, "a guard stood beside the player and answered the theft")
	# alarm and reports
	var n_before := rows(rec, "event").size()
	var aware: Dictionary = w.aware_of_attack(victim.pos, victim)
	w.player.pos = victim.pos
	var cast := NPC.new()
	cast.id = -99
	var bystander: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.job != "guard" and n != victim and n.household >= 3)[0]
	aware.seen = [bystander]
	w.raise_alarm(aware, Life.PLAYER_ID)
	var ae := evs(rec, "raise_alarm")
	check(ae.size() == 1 and ae[0].actor == "p:%d" % w.player.pid, "raise_alarm: an event; the attacker is the player's permanent reference")
	var rp := evs(rec, "report_crime")
	check(rp.size() >= 2 and rp.all(func(e): return int(e.parent) == int(ae[0].id)), "report_crime: one event per person carrying word, children of the alarm (%d)" % rp.size())
	check(changes_of(rec, int(rp[0].id))[0].prop == "report", "each with the report as a state change")
	# robbery by a bandit
	var bandit: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "bandit")[0]
	var prey: NPC = victim
	prey.coins = 30
	prey.inv.add("log", 1)
	bandit.pos = prey.pos + Vector2(0.5, 0)
	bandit.target = prey.id
	bandit.attack_cd = 0.0
	var bc := bandit.coins
	w.brain.fight(bandit, 0.1)
	var rb := evs(rec, "robbery")
	check(rb.size() == 1 and rb[0].actor == "p:%d" % bandit.id, "robbery: an event on the bandit's reference")
	var rbc := changes_of(rec, int(rb[0].id))
	var coin_rows := rbc.filter(func(c): return c.prop == "coins")
	check(coin_rows.size() == 2 and int(coin_rows[0].delta) + int(coin_rows[1].delta) == 0 and int(coin_rows[0].delta) == bandit.coins - bc, "with coin state changes for robber and victim that net to zero (%d)" % int(coin_rows[0].delta))
	check(rows(rec, "event").size() > n_before, "events recorded")
	check(rec.unknown_codes.is_empty(), "crime: no code outside recorder_codes.json (%s)" % str(rec.unknown_codes))
	cast = null
	w.dispose()


## SIM-GATE-01: a fighter's chase is one event from the tick its target is new to the line of fight() that clears it.
func test_chase_events() -> void:
	var w := identity_world()
	var rec := WorldRecorder.attach(w, {"root": sub("chase")})
	w.minutes = float(World.DAY) * 2.0 + 11.0 * 60.0
	var g: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.job == "guard")[0]
	w.player.pos = g.pos + Vector2(3, 0)
	w.player_level = g.depth
	g.target = Life.PLAYER_ID
	w.brain.fight(g, 0.1)
	check(rec._chases.has(g.id), "chase: a guard given the player as target opens a chase")
	w.player.pos = g.pos + Vector2(40, 0)          # beyond the 25 tiles fight() follows
	w.brain.fight(g, 0.1)
	var ce := evs(rec, "chase_guard")
	check(g.target == -1 and ce.size() == 1 and ce[0].category == "combat" and ce[0].outcome == "abandoned" and ce[0].reason == "out_of_range",
		"chase: the guard's chase ends as abandoned, out_of_range, at the line that drops it (%s)" % (str(ce[0]) if not ce.is_empty() else "none"))
	var cp := parts_of(rec, int(ce[0].id)) if not ce.is_empty() else []
	check(cp.any(func(x): return x.role == "guard" and x.ref == "p:%d" % g.id) and cp.any(func(x): return x.role == "target:player" and x.ref == "p:%d" % w.player.pid),
		"chase: participants the guard and the player (role marker), on permanent references")
	check(not ce.is_empty() and str(ce[0].detail).contains("d0=3.00") and str(ce[0].detail).contains("strikes=0"), "chase: the detail has the start distance and the strikes (%s)" % (str(ce[0].detail) if not ce.is_empty() else ""))
	w.player.pos = g.pos + Vector2(2, 0)
	g.target = Life.PLAYER_ID                       # cleared by other code: closed at the next hour
	w.brain.fight(g, 0.0)
	g.target = -1
	rec.hour()
	check(evs(rec, "chase_guard").any(func(e): return e.reason == "cleared_elsewhere"), "chase: a target cleared outside fight() is closed at the hour as cleared_elsewhere")
	check(rec.unknown_codes.is_empty(), "chase: no code outside recorder_codes.json (%s)" % str(rec.unknown_codes))
	w.dispose()


func test_player_verbs() -> void:
	var w := identity_world()
	var rec := WorldRecorder.attach(w, {"root": sub("verbs")})
	var pref := "p:%d" % w.player.pid
	w.minutes = float(World.DAY) * 2.0 + 11.0 * 60.0
	var vendor: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.inv.total() > 0 and n.household >= 3)[0]
	var item: String = vendor.inv.ids()[0]
	w.player.coins = 200
	var r := w.player_buy_many(vendor, item, 1)
	var buy := evs(rec, "buy")
	check(r.result == "bought" and buy.size() == 1 and buy[0].actor == pref and buy[0].category == "verb", "trade: the player's purchase is a verb event on the player's permanent reference")
	var kids := rows(rec, "event").filter(func(e): return int(e.parent) == int(buy[0].id) and e.subtype == "trade")
	check(kids.size() == 1 and kids[0].outcome == "ok", "and the trade it caused is its child")
	var bc := changes_of(rec, int(buy[0].id))
	check(bc.any(func(c): return c.prop == "coins" and int(c.delta) < 0) and bc.any(func(c): return c.prop == "item:" + item and int(c.delta) == 1), "the verb's summary: coins down, the item up")
	var before_total := rows(rec, "alert").filter(func(a): return a.rule == "coin.unattributed_total").size()
	rec._audit_coins()
	check(rows(rec, "alert").filter(func(a): return a.rule == "coin.unattributed_total").size() == before_total, "the verb's summary is not counted twice by the coin audit")
	# sell
	w.player.inv.add(item, 1)
	var price: int = w.player_quote(vendor, item, 1, false)[0]
	var rs := w.player_sell(vendor, item, price)
	var sell := evs(rec, "sell")
	check(sell.size() == 1 and sell[0].outcome == ("ok" if rs.result == "sold" else "failed"), "sell: a verb event with the result (%s)" % str(rs.result))
	# take from a container
	var took := false
	for c in w.containers:
		w.player.pos = Vector2(c.pos) if c.has("pos") else w.player.pos
		var res := w.player_take(c)
		if res != "far" and res != "" and res != "full":
			took = true
			break
	var tk := evs(rec, "take")
	check(tk.size() > 0 and (not took or tk.any(func(e): return e.outcome == "ok")), "take: a verb event for every attempt (%d); a taken item is a state change" % tk.size())
	# strike
	var target: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.job != "guard" and n.household >= 3 and n != vendor)[0]
	w.player.pos = target.pos
	var hp0 := target.hp
	var hit := w.player_hit_npc(target, 2.0)
	var st := evs(rec, "strike")
	check(st.size() == 1 and st[0].actor == pref, "strike: a verb event on the player's reference")
	check(changes_of(rec, int(st[0].id)).any(func(c): return c.prop == "hp" and c.ref == "p:%d" % target.id and float(c.after) < float(c.before)) and target.hp < hp0, "the target's health before and after is a state change (%.1f -> %.1f)" % [hp0, target.hp])
	check(rows(rec, "event").any(func(e): return e.subtype == "raise_alarm" and int(e.parent) == int(st[0].id)), "an assault raises the alarm, recorded as a child of the strike")
	# loot
	w.loot.append({"pos": w.player.pos, "inv": Inventory.new(), "coins": 9, "from": "test"})
	w.loot[-1].inv.add("log", 1)
	var pc0 := w.player.coins
	var lr := w.player_loot(w.loot.size() - 1)
	var lt := evs(rec, "loot")
	check(lt.size() == 1 and w.player.coins == pc0 + 9 and changes_of(rec, int(lt[0].id)).any(func(c): return c.prop == "coins" and int(c.delta) == 9), "loot: coins and goods picked up are the verb's state changes (%s)" % str(lr.coins))
	rec._audit_coins()
	check(rows(rec, "alert").filter(func(a): return a.rule == "coin.unattributed_holder" and a.entities == pref).is_empty(), "and the player's purse raises no unattributed alert for them")
	# craft
	var crafted := false
	for id in GameData.recipes:
		var rcp: Dictionary = GameData.recipes[id]
		w.player.inv = Inventory.new()
		for k in rcp["in"]:
			w.player.inv.add(k, int(rcp["in"][k]))
		if w.player_craft_refusal(id) == "":
			var res := w.player_craft(id)
			crafted = res.result == "ok"
			break
	var cf := evs(rec, "craft")
	check(crafted and cf.size() == 1 and cf[0].outcome == "ok" and changes_of(rec, int(cf[0].id)).size() > 0, "craft: a verb event with the pack's items before and after")
	check(rec.unknown_codes.is_empty(), "player verbs: no code outside recorder_codes.json (%s)" % str(rec.unknown_codes))
	w.dispose()


## The same scripted sequence in two worlds, with and without a recorder: the world and the random state are identical.
func scripted(w: World) -> void:
	var s: OffMapSettlement = w.regions.by_id["higham"]
	var who := plain_adult(w)
	leave_to(w, s, who)
	run_minutes(w, 90)
	come_back(w, who.id)
	var mother: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.sex == "female" and n.partner >= 0 and n.household >= 3)[0]
	Life.birth(w, mother, w.npc(mother.partner), mother.household)
	w.kill(w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.job == "smith")[0], "old age")
	w.treasury = 0
	for n: NPC in w.npcs:
		if n.alive and n.household >= 0:
			n.coins += 100
	w.brain.reeve_day()
	w.brain.pay_guards()
	w.player.coins = 100
	var g: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.job == "guard")[0]
	w.player.pos = g.pos
	w.witness("theft", "a loaf", w.npcs[5], {"bread": 1}, Inventory.new())
	w.player.alive = false
	w.continue_as_heir()
	run_minutes(w, 120)


func test_scripted_equivalence() -> void:
	var a := identity_world()
	scripted(a)
	var ha := world_hash(a)
	var b := identity_world()
	var rec := WorldRecorder.attach(b, {"root": sub("equiv")})
	scripted(b)
	check(world_hash(b) == ha, "recording changes nothing: leave, return, birth, death, reeve_day, pay_guards, a theft, a succession and two hours leave to_dict and the RNG state identical to the unrecorded run")
	check(int(rec.counts.event) > 50 and rec.unknown_codes.is_empty(), "and the recorded run produced events (%d) with no unknown code" % int(rec.counts.event))
	a.dispose()
	b.dispose()


## Every person reference in an archive is a registered permanent id; none is p:player.
func test_person_refs() -> void:
	var w := identity_world()
	var rec := WorldRecorder.attach(w, {"root": sub("refs")})
	scripted(w)
	var bad := []
	var seen_refs := {}
	for e in rows(rec, "event"):
		seen_refs[e.actor] = true
	for x in rows(rec, "participant"):
		seen_refs[x.ref] = true
	for c in rows(rec, "state_change"):
		seen_refs[c.ref] = true
	for sm in rows(rec, "sample"):
		seen_refs[sm.entity] = true
	for r in seen_refs:
		if str(r).begins_with("p:") and not w.people.has(int(str(r).substr(2))):
			bad.append(r)
	check(bad.is_empty() and not seen_refs.has("p:player"), "every person reference in the archive is a permanent id the register knows; none is p:player (%d refs, bad: %s)" % [seen_refs.size(), str(bad)])
	w.dispose()


## REC-19 D5 and D4 relations (Expansion 20, batch R3; REC-STORE, FAM-SAC-01): judgment facts, beliefs, gossip, ledger posts, trust
## moves, every weighted choice with every alternative and factor, family-priority decisions, and the relations' shared hours,
## gifts and harm. The same steps with and without the recorder leave the world, the judgment store and the RNG identical.
func judgment_steps(w: World) -> void:
	run_minutes(w, 26 * 60)
	var j: JudgmentStore = w.judgment
	var adults: Array = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.household >= 3)
	var a: NPC = adults[0]
	var b: NPC = adults[1]
	# a weighted choice with an infeasible candidate and a forgo (contract_accept), as the live code hands it
	JudgmentWeighting.choose(j, j.cfg, a.id, "contract_accept", [
		{"id": "deal_b", "counterparty": b.id, "factors": {"live_order": 100000, "necessity": 40000}},
		{"id": "deal_x", "counterparty": adults[2].id, "feasible": false, "why": "no stock"}], [w.day(), 77])
	# a family-priority decision through the real record path
	var r := JudgmentWeighting.choose(j, j.cfg, a.id, "family_meal", [
		{"id": "eat", "counterparty": -1, "factors": {"self_need": 60000}},
		{"id": "give", "counterparty": -1, "factors": {"family_child_need": 50000}}], [w.day(), a.id, 5])
	JudgmentFamily._record(w, a, "meal_pantry", r, {"tier": 3, "temperament": "ordinary"})
	# a deed, seen: a fact, beliefs, ledger posts
	var ev := j.publish("theft", [a.id], [b.id], [], 5)
	j.observe_all(ev, [adults[3].id])
	j.observe_all(j.publish("trade_fair", [a.id], [], [b.id], 5), [])     # a fair deal: the beneficiary's trust in the dealer moves
	# the player's gift and harm
	w.player.inv.add("bread", 1)
	w.relations.give(Life.PLAYER_ID, b, "bread")
	w.relations.harmed(b, 3.0)
	run_minutes(w, 60)


func test_judgment_and_relations() -> void:
	var plain := identity_world()
	judgment_steps(plain)
	var ha := world_hash(plain) + str(plain.judgment.state_hash())
	var w := identity_world()
	var rec := WorldRecorder.attach(w, {"root": sub("judgment")})
	check(w.judgment != null and w.judgment.rec == rec, "D5: the judgment store reports to the attached recorder (JudgmentStore.rec)")
	judgment_steps(w)
	check(world_hash(w) + str(w.judgment.state_hash()) == ha, "D5/D4: recording judgment and relations changes nothing: to_dict, the judgment store's hash and the RNG state equal the unrecorded run")
	rec.flush()
	var d := read_all(rec)
	check(rec.unknown_codes.is_empty(), "D5/D4: no unknown code (%s)" % str(rec.unknown_codes))
	var ev := {}
	var kids := {}
	for e in d.event:
		ev[int(e.id)] = e
		if int(e.parent) > 0:
			if not kids.has(int(e.parent)):
				kids[int(e.parent)] = []
			kids[int(e.parent)].append(e)
	var by := func(table: String) -> Dictionary:
		var m := {}
		for x in d[table]:
			if not m.has(int(x.event)):
				m[int(x.event)] = []
			m[int(x.event)].append(x)
		return m
	var parts: Dictionary = by.call("participant")
	var sc: Dictionary = by.call("state_change")
	var alts: Dictionary = by.call("alternative")
	var facs: Dictionary = by.call("factor")
	var jev: Array = d.event.filter(func(e): return e.system == "judgment")
	var facts: Array = jev.filter(func(e): return e.subsystem == "fact")
	var beliefs: Array = jev.filter(func(e): return e.subsystem == "belief")
	var gossip: Array = jev.filter(func(e): return e.subsystem == "gossip")
	var choices: Array = jev.filter(func(e): return e.subsystem == "choice")
	check(facts.size() > 0 and facts.all(func(e): return e.actor == "world" or (parts.get(int(e.id), []) as Array).any(func(p): return str(p.role).begins_with("actor") and p.ref == e.actor)) and facts.any(func(e): return e.subtype == "fact:theft" and str(e.object).begins_with("fact:")),
		"D5: every published fact is an event with its actors (%d facts)" % facts.size())
	var thread_ok: bool = beliefs.size() > 0
	for e in beliefs:
		thread_ok = thread_ok and str(e.object).begins_with("fact:") and e.subtype in JudgmentStore.SOURCES
	check(thread_ok, "D5: every belief taken in is an event on the fact's thread, with its source (%d beliefs)" % beliefs.size())
	var posted: Array = beliefs.filter(func(e): return (sc.get(int(e.id), []) as Array).any(func(c): return str(c.prop).begins_with("judgment_bad:") or str(c.prop).begins_with("judgment_good:")))
	check(posted.size() > 0 and posted.any(func(e): return e.subtype == "witnessed"), "D5: ledger posts are the beliefs' state rows, contribution before and after (%d beliefs posted)" % posted.size())
	check(d.state_change.any(func(c): return str(c.prop).begins_with("trust:") and c.authority == "judgment"), "D5: trust moves are state rows with before and after")
	var told_ok: bool = gossip.size() > 0
	for g in gossip:
		told_ok = told_ok and g.outcome == "ok" and not (kids.get(int(g.id), []) as Array).is_empty()
	var with_told := gossip.filter(func(g): return (kids.get(int(g.id), []) as Array).any(func(k): return k.subsystem == "belief" and k.subtype in ["told", "rumour"]))
	check(told_ok and not with_told.is_empty(), "D5: each recorded telling passed something on: its children are what it gave (%d tellings, %d with told beliefs; one with nothing writes no row)" % [gossip.size(), with_told.size()])
	# every weighted choice, in full
	var dec: Array = d.decision.filter(func(x): return x.kind == "judgment_weighted")
	check(dec.size() == choices.size() and dec.size() >= 2, "D5: every JudgmentWeighting.choose is a decision (%d)" % dec.size())
	var mine: Array = choices.filter(func(e): return e.subtype == "contract_accept" and str(e.detail).contains("77"))
	check(mine.size() == 1, "D5: the scripted contract choice is recorded once")
	if mine.size() == 1:
		var id := int(mine[0].id)
		var al: Array = alts.get(id, [])
		var fa: Array = facs.get(id, [])
		var opts := al.map(func(x): return x.option)
		check(opts.has("deal_b") and opts.has("deal_x") and opts.has("forgo") and al.size() == 3, "REC-STORE: every candidate and forgo is an alternative (%s)" % str(opts))
		var x: Array = al.filter(func(x): return x.option == "deal_x")
		check(not x.is_empty() and x[0].feasible == false and x[0].reason == "not_feasible" and fa.any(func(f): return f.option == "deal_x" and f.factor == "why" and f.value == "no stock"), "REC-STORE: an infeasible candidate keeps its why")
		var wts: Dictionary = JudgmentStore.default_cfg().decision.profiles.contract_accept.weights
		var full := true
		for k in wts:
			full = full and fa.any(func(f): return f.option == "deal_b" and f.factor == k) and fa.any(func(f): return f.option == "deal_b" and f.factor == "weighted:" + k)
		check(full and fa.any(func(f): return f.option == "deal_b" and f.factor == "disposition" and f.source == "judgment"), "REC-STORE: every factor the profile weighs and its weighted contribution are kept for each feasible option")
		var dd: Array = d.decision.filter(func(q): return int(q.event) == id)
		var bu: Array = al.filter(func(x): return x.option == "deal_b")
		var fo: Array = al.filter(func(x): return x.option == "forgo")
		check(dd.size() == 1 and dd[0].chosen in ["deal_b", "forgo"] and typeof(bu[0].score) != TYPE_STRING and typeof(fo[0].score) != TYPE_STRING, "D5: the chosen option and each utility are stored (chose %s)" % (dd[0].chosen if dd.size() == 1 else "?"))
	var all_full: bool = true
	for e in choices:
		var al2: Array = alts.get(int(e.id), [])
		all_full = all_full and not al2.is_empty()
		for a2 in al2:
			if a2.feasible == true and a2.option != "forgo":
				all_full = all_full and (facs.get(int(e.id), []) as Array).any(func(f): return f.option == a2.option and str(f.factor).begins_with("weighted:"))
	check(all_full, "REC-STORE: each of the %d recorded choices has its alternatives, and every feasible one its weighted factors" % choices.size())
	# family priority
	var fam: Array = jev.filter(func(e): return e.subsystem == "family")
	var fam_ok: bool = fam.any(func(e): return e.subtype == "meal_pantry" and (facs.get(int(e.id), []) as Array).any(func(f): return f.factor == "tier" and int(f.value) == 3))
	var linked: bool = d.link.any(func(l): return l.kind == "part_of" and ev.has(int(l.to)) and ev[int(l.to)].subsystem == "family" and ev.has(int(l.from)) and ev[int(l.from)].subtype == "family_meal")
	var fam_factors: bool = d.factor.any(func(f): return f.factor == "family_child_need")
	check(fam_ok and linked and fam_factors, "FAM-SAC-01: a family-priority decision is an event with its rule values, linked to the weighing that carries the family factors")
	# relations D4
	var rel: Array = d.event.filter(func(e): return e.system == "relations")
	var shared: Array = rel.filter(func(e): return e.subsystem == "shared")
	check(shared.size() > 0 and shared.all(func(e): return (parts.get(int(e.id), []) as Array).size() == 2 and str(e.object).begins_with("tie:")) and shared.any(func(e): return (sc.get(int(e.id), []) as Array).any(func(c): return c.prop == "regard")),
		"D4: each shared hour is an event on the pair's tie, with regard rows when it moved (%d hours)" % shared.size())
	var gifts: Array = rel.filter(func(e): return e.subsystem == "gift")
	var gift_ok: bool = gifts.size() == 1
	if gift_ok:
		var gr: Array = (sc.get(int(gifts[0].id), []) as Array).filter(func(c): return c.prop == "item:bread")
		gift_ok = gr.size() == 2 and int(gr[0].delta) + int(gr[1].delta) == 0 and int(gr[0].delta) == -1 and (sc.get(int(gifts[0].id), []) as Array).any(func(c): return c.prop == "regard") and gifts[0].actor == "p:%d" % w.player.pid
	check(gift_ok, "D4: the gift is one event: the bread leaves the player and reaches the receiver, and the tie's regard moves")
	var harms: Array = rel.filter(func(e): return e.subsystem == "harm")
	check(harms.size() == 1 and (sc.get(int(harms[0].id), []) as Array).any(func(c): return c.prop == "regard" and float(c.after) < float(c.before)), "D4: the harm is one event with the ties it lowered")
	var bad := []
	for x in d.participant:
		if str(x.ref).begins_with("p:") and not w.people.has(int(str(x.ref).substr(2))):
			bad.append(x.ref)
	check(bad.is_empty(), "D5/D4: every person in a judgment or relations row is a registered permanent id (bad: %s)" % str(bad.slice(0, 5)))
	plain.dispose()
	w.dispose()


## X20-FINAL phase 3 (owner directive 2026-10-27): contracts, credit, relations' other channels, memory and personality over time,
## grievances, production flows, the day's summaries, the flags and the network digest. The same steps with and without the
## recorder leave the world, the judgment store and the RNG identical.
class FakeNet:
	var role := "host"
	var by_peer := {}


func x20_item(n: NPC) -> String:
	var ids: Array = n.inv.items.keys()
	ids.sort()
	for id in ids:
		if n.inv.count(str(id)) > 0 and not GameData.item(str(id)).is_empty() and not Skills.is_gear(str(id)):
			return str(id)
	return ""


func x20_steps(w: World) -> Dictionary:
	run_minutes(w, 26 * 60)
	var out := {}
	var adults: Array = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.household >= 3 and n.job != "guard" and x20_item(n) != "")
	var a: NPC = adults[0]
	var b: NPC = adults[1]
	var item := x20_item(a)
	b.coins += 50
	b.pos = a.pos + Vector2(0.4, 0)
	var r: Dictionary = w.contracts.propose(World.npc_ref(b.id), a, item, 1, maxi(1, w.sell_price(a, item)), 2)
	out.contract = str(r.get("answer", ""))
	if r.has("contract"):
		out.delivered = w.contracts.deliver(r.contract, 1)
	var cr := {"result": "no pair", "debt": {}}
	for s_ in adults:                         # a pair that trusts each other (trust is regard: set high here, the same in both runs)
		for b_ in adults:
			if s_ == b_ or str(cr.result) == "credited" or x20_item(s_) == "":
				continue
			w.relations.tie(s_.id, b_.id).regard = 100.0
			cr = w.credit.sell_on_credit(s_, b_, x20_item(s_), 1, 3)
			if str(cr.result) == "credited":
				a = b_
	out.credit = str(cr.result)
	if not (cr.debt as Dictionary).is_empty():
		a.coins += 3
		out.repaid = w.credit.repay(int(cr.debt.id), true)
	w.relations.helped(b.id, a)
	w.relations.talked(a)
	out.court = w.relations.ask_court(Life.PLAYER_ID, a)
	var j: JudgmentStore = w.judgment
	var ev := j.publish("theft", [b.id], [a.id], [], 5)
	j.observe_all(ev, [a.id, adults[2].id])
	j.pers.mistake(a.id, "trade", 30000, w.day())
	run_minutes(w, 24 * 60)
	return out


func test_x20_phase3() -> void:
	var plain := identity_world()
	var oa := x20_steps(plain)
	var ha := world_hash(plain) + str(plain.judgment.state_hash())
	var w := identity_world()
	var rec := WorldRecorder.attach(w, {"root": sub("x20")})
	var ob := x20_steps(w)
	rec.net = FakeNet.new()
	rec.net_state_maybe()                     # the digest reads World.to_dict: it must change nothing either
	check(oa == ob and world_hash(w) + str(w.judgment.state_hash()) == ha, "X20: recording contracts, credit, relations, memory, flows, the days and a network digest changes nothing (%s)" % JSON.stringify(ob))
	check(rec.unknown_codes.is_empty(), "X20: no unknown code (%s)" % str(rec.unknown_codes))
	rec.flush()
	var d := read_all(rec)
	var sub_n := func(cat: String, st: String) -> int:
		return d.event.filter(func(e): return e.category == cat and (st == "" or e.subtype == st)).size()
	if str(ob.contract) == "accept":
		check(sub_n.call("contract", "opened") == 1 and sub_n.call("contract", "delivered") == 1 and sub_n.call("contract", "paid") == 1 and sub_n.call("contract", "fulfilled") == 1,
			"X20: a contract is opened, delivered, paid and fulfilled on one object thread")
		var cc := 0
		for c in d.state_change:
			if str(c.ref).begins_with("contract:") and str(c.prop) == "coins":
				cc += int(c.delta)
		check(cc == 0, "X20: the contract's set-aside coins come back to zero (%d)" % cc)
	else:
		check(false, "X20: the test contract was accepted (answer %s)" % str(ob.contract))
	check(sub_n.call("credit", "extended") >= 1 and sub_n.call("credit", "repaid") + sub_n.call("credit", "repaid_late") >= 1, "X20: a debt extended and repaid (%s)" % str(ob.credit))
	check(sub_n.call("relation", "help") >= 1 and sub_n.call("relation", "talk") >= 1 and sub_n.call("relation", "court_ask") >= 1,
		"X20: help, talk and the player's court asking (answer: %s) are events" % str(ob.court))
	check(sub_n.call("relation", "cooling") >= 1, "X20: the dawn's cooling is one row")
	check(sub_n.call("judgment", "grievance") + sub_n.call("judgment", "betrayal") >= 1, "X20: the victim's grievance is an event")
	check(sub_n.call("judgment", "mistake") >= 1, "X20: a personality change (a costly mistake) is an event")
	check(sub_n.call("summary", "judgment_day") >= 2 and sub_n.call("summary", "world_day") >= 2, "X20: a judgment and a world summary each day")
	var flows: Array = d.state_change.filter(func(c): return str(c.authority) == "world.stat")
	var kinds := {}
	for c in flows:
		kinds[str(c.prop).get_slice(":", 0)] = true
	var bad_parent: Array = flows.filter(func(c): return d.event.filter(func(e): return int(e.id) == int(c.event)).is_empty())
	check(kinds.has("produced") and kinds.has("consumed") and bad_parent.is_empty(), "X20: production and consumption flows are rows under recorded events (%s; %d flows)" % [str(kinds.keys()), flows.size()])
	check(sub_n.call("network", "net_state") == 1 and d.factor.filter(func(f): return str(f.option) == "section").size() > 5, "X20: the network digest holds a hash per shared section")
	var fl: Dictionary = rec.meta.flags
	check(fl.has("aspiration") and fl.has("economy") and fl.has("judgment_integration") and not fl.has("civic"), "X20: the session's flags name the real switches (%s)" % JSON.stringify(fl))
	w.dispose()
	plain.dispose()
	# the LE-01 model on: its daily integrity summary, and the flag in the archive
	EconomyFoundation.set_override({"enabled": true})
	var we := identity_world()
	var re := WorldRecorder.attach(we, {"root": sub("x20_economy")})
	run_minutes(we, 26 * 60)
	var em: Array = rows(re, "event").filter(func(e): return e.subtype == "economy_model")
	check(not em.is_empty() and em[-1].outcome == "ok" and bool(re.meta.flags.economy), "X20: the LE-01 model's daily summary (ok: nothing unbacked) and economy=true in the flags")
	we.dispose()
	EconomyFoundation.set_override({})


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
