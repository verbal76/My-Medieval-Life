extends RefCounted
## SIM-GATE-01: reads one flight recorder session (an archive directory, schema mml-recorder/1 or /2) and turns it into the
## analysis tables the workbook shows. One implementation for the CI gate (tests/sim_workbook.gd) and the desktop game's
## live export (live_export.gd). It reads the archive only, chunk by chunk (memory holds the aggregates, the hourly snapshot
## rows and at most `event_rows_max` event records), and never touches a running World. Desktop and CI only (excluded from
## the Android export). The groupings it applies come from res://data/sim_workbook.json.
##
##   var a: Dictionary = preload("res://scripts/recorder_export/recorder_analysis.gd").analyse(session_dir, defs)
## Returns {session, chunks: {ok, skipped}, hourly: [snapshot rows], daily: [{day, ...}], events: {kind: n}, actions:
## {kind: [ok, failed]}, decisions: {chosen|outcome: n}, interruptions, life, employment, civic, crime: [records],
## chases: [records], chase_summary, alerts: {rule: n}, stats: {key: total}, groups: {production, consumption, trade},
## activity: {class: person-hours}, activity_daily, stuck, wealth: {bucket: people}, records: [notable events],
## performance: {...}, witnesses: {event id: n}}.

const SKIP_TABLES := ["alternative", "factor", "decision", "link"]     # decision detail: not needed for the workbook (volume)


static func load_defs() -> Dictionary:
	var f := FileAccess.open("res://data/sim_workbook.json", FileAccess.READ)
	return JSON.parse_string(f.get_as_text()) if f != null else {}


## Iterate one table's complete chunks: `fn` gets (row Array, column index Dictionary). Returns [ok chunks, skipped chunks].
static func each_row(session_dir: String, table: String, fn: Callable) -> Array:
	var ok := 0
	var skipped := 0
	for rel in RecorderArchive.chunk_files(session_dir):
		if not rel.get_file().begins_with(table + "."):
			continue
		var c := RecorderArchive.read_chunk(session_dir + "/" + rel)
		if not c.ok:
			skipped += 1
			continue
		ok += 1
		var idx := {}
		var cols: Array = c.header.columns
		for i in cols.size():
			idx[cols[i]] = i
		for r in c.rows:
			fn.call(r, idx)
	return [ok, skipped]


static func _inc(d: Dictionary, k, n := 1) -> void:
	d[k] = d.get(k, 0) + n


## "key=value key2=value2" detail text -> Dictionary of the numbers in it (the chase events' detail).
static func detail_numbers(detail: String) -> Dictionary:
	var out := {}
	for part in detail.split(" "):
		if "=" in part:
			var kv := part.split("=", true, 1)
			if kv[1].is_valid_float():
				out[kv[0]] = float(kv[1])
	return out


static func activity_class(doing: String, defs: Dictionary) -> String:
	if doing == "":
		return "idle"
	var ac: Dictionary = defs.get("activity_classes", {})
	for cls in ac.get("order", []):
		for pat in ac.get("patterns", {}).get(cls, []):
			if str(pat) != "" and doing.contains(str(pat)):
				return str(cls)
	return "work"


static func group_of(key: String, groups: Dictionary) -> String:
	for g in groups:
		for pre in groups[g]:
			if key.begins_with(str(pre)):
				return str(g)
	return ""


static func analyse(session_dir: String, defs: Dictionary) -> Dictionary:
	var a := {"session": RecorderArchive.read_json(session_dir + "/session.json"), "chunks": {"ok": 0, "skipped": 0}}
	if not (a.session is Dictionary):
		a.session = {}
	var max_records := int(defs.get("event_rows_max", 20000))
	var t0 := Time.get_ticks_msec()
	# ---- hourly snapshots (schema 2) -------------------------------------------------------
	var hourly := []
	var r := each_row(session_dir, "snapshot", func(row, idx):
		var d := {}
		for k in idx:
			d[k] = row[idx[k]]
		hourly.append(d))
	a.chunks.ok += r[0]
	a.chunks.skipped += r[1]
	hourly.sort_custom(func(x, y): return int(x.seq) < int(y.seq))
	a.hourly = hourly
	# ---- events -----------------------------------------------------------------------------
	var ev := {}
	var actions := {}
	var decisions := {}
	var interruptions := {}
	var life := {}
	var employment := {}
	var civic := {}
	var crime := []
	var chases := []
	var records := []
	var deaths := []
	var crime_ids := {}
	r = each_row(session_dir, "event", func(row, idx):
		var cat := str(row[idx.category])
		var sub := str(row[idx.subtype])
		var out := str(row[idx.outcome])
		_inc(ev, "%s|%s|%s" % [cat, sub, out])
		match cat:
			"action":
				if not actions.has(sub):
					actions[sub] = [0, 0]
				actions[sub][0 if out == "ok" else 1] += 1
				return
			"decision":
				_inc(decisions, out)
				return
			"interruption":
				_inc(interruptions, "%s|%s" % [sub, str(row[idx.reason])])
			"life":
				_inc(life, sub)
				if sub == "death":
					deaths.append([int(row[idx.day]), float(row[idx.minute]), str(row[idx.actor]), str(row[idx.detail])])
			"employment":
				_inc(employment, sub)
			"civic":
				_inc(civic, sub)
			"crime", "verb":
				if cat == "crime" or sub in ["strike", "loot"]:
					crime_ids[int(row[idx.id])] = true
					crime.append({"id": int(row[idx.id]), "day": int(row[idx.day]), "minute": float(row[idx.minute]), "kind": sub, "actor": str(row[idx.actor]),
						"outcome": out, "detail": str(row[idx.detail]), "x": int(row[idx.x]), "y": int(row[idx.y])})
			"combat":
				var dn := detail_numbers(str(row[idx.detail]))
				chases.append({"id": int(row[idx.id]), "day": int(row[idx.day]), "minute": float(row[idx.minute]), "who": sub.trim_prefix("chase_"),
					"actor": str(row[idx.actor]), "outcome": out, "reason": str(row[idx.reason]), "seconds": float(dn.get("seconds", 0.0)),
					"start_day": int(dn.get("start_day", row[idx.day])), "start_minute": float(dn.get("start_minute", row[idx.minute])),
					"d0": float(dn.get("d0", -1.0)), "d_end": float(dn.get("d_end", -1.0)), "strikes": int(dn.get("strikes", 0))})
		if records.size() < max_records:
			records.append([int(row[idx.seq]), int(row[idx.id]), int(row[idx.parent]), int(row[idx.day]), float(row[idx.minute]), cat, sub,
				str(row[idx.actor]), out, str(row[idx.reason]), str(row[idx.detail]).left(240)]))
	a.chunks.ok += r[0]
	a.chunks.skipped += r[1]
	crime.sort_custom(func(x, y): return int(x.id) < int(y.id))
	chases.sort_custom(func(x, y): return int(x.id) < int(y.id))
	records.sort()
	a.events = ev
	a.actions = actions
	a.decisions = decisions
	a.interruptions = interruptions
	a.life = life
	a.deaths = deaths
	a.employment = employment
	a.civic = civic
	a.crime = crime
	a.chases = chases
	a.records = records
	# ---- participants of crime events: witnesses and the chase targets ------------------------
	var witnesses := {}
	var targets := {}
	r = each_row(session_dir, "participant", func(row, idx):
		var e := int(row[idx.event])
		var role := str(row[idx.role])
		if crime_ids.has(e) and role.begins_with("witness"):
			_inc(witnesses, e)
		elif role.begins_with("target"):
			targets[e] = str(row[idx.ref]) + ("|player" if role.ends_with(":player") else ""))
	a.chunks.ok += r[0]
	a.chunks.skipped += r[1]
	for c in a.crime:
		c.witnesses = int(witnesses.get(int(c.id), 0))
	var player_refs := {}
	for c in a.chases:
		var t: String = targets.get(int(c.id), "")
		c.target = t.get_slice("|", 0)
		c.target_is_player = t.ends_with("|player")
		if c.target_is_player:
			player_refs[c.target] = true
	# chase summary: fighter kind x reason
	var cs := {}
	for c in a.chases:
		var k := "%s|%s" % [c.who, c.reason]
		if not cs.has(k):
			cs[k] = {"who": c.who, "reason": c.reason, "n": 0, "seconds": [], "on_player": 0, "strikes": 0}
		cs[k].n += 1
		cs[k].seconds.append(float(c.seconds))
		cs[k].strikes += int(c.strikes)
		if c.target_is_player:
			cs[k].on_player += 1
	a.chase_summary = cs
	# ---- alerts -------------------------------------------------------------------------------
	var alerts := {}
	r = each_row(session_dir, "alert", func(row, idx): _inc(alerts, str(row[idx.rule])))
	a.chunks.ok += r[0]
	a.chunks.skipped += r[1]
	a.alerts = alerts
	# ---- hourly samples: activity, stuck villagers, final wealth --------------------------------
	var activity := {}
	var activity_daily := {}
	var last_cell := {}            # entity -> [x, y, doing class, hours in a row there]
	var stuck := {}                # entity -> longest run of hours on one cell while working or travelling
	var final_hour := [-1, -1]
	var final_coins := {}
	var doing_hours := {}
	r = each_row(session_dir, "sample", func(row, idx):
		var ent := str(row[idx.entity])
		var doing := str(row[idx.doing])
		var day := int(row[idx.day])
		var hour := int(row[idx.hour])
		if int(ent.trim_prefix("p:")) >= 1000000 or ent == "p:player":
			return                                   # the player character (band ids from 1,000,000): not a villager
		var cls := activity_class(doing, defs)
		_inc(activity, cls)
		if not activity_daily.has(day):
			activity_daily[day] = {}
		_inc(activity_daily[day], cls)
		_inc(doing_hours, doing)
		var cell := [int(row[idx.x]), int(row[idx.y])]
		var lc = last_cell.get(ent)
		if lc != null and lc[0] == cell[0] and lc[1] == cell[1] and lc[2] == cls and cls in ["work", "travel", "lost"]:
			lc[3] += 1
		else:
			lc = [cell[0], cell[1], cls, 1]
		last_cell[ent] = lc
		if cls in ["work", "travel", "lost"] and int(lc[3]) > int(stuck.get(ent, [0])[0]):
			stuck[ent] = [int(lc[3]), day, hour, doing, cell[0], cell[1]]
		if day > final_hour[0] or (day == final_hour[0] and hour > final_hour[1]):
			final_hour[0] = day                      # (a lambda cannot reassign a captured variable: change it in place)
			final_hour[1] = hour
			final_coins.clear()
		if day == final_hour[0] and hour == final_hour[1]:
			final_coins[ent] = row[idx.coins])
	a.chunks.ok += r[0]
	a.chunks.skipped += r[1]
	a.activity = activity
	a.activity_daily = activity_daily
	a.doing_hours = doing_hours
	a.stuck = stuck
	var buckets: Array = defs.get("wealth_buckets", [0, 1, 25, 50, 100, 200, 500])
	var wealth := {}
	for b in buckets:
		wealth[int(b)] = 0
	for ent in final_coins:
		var c := int(final_coins[ent])
		var at := int(buckets[0])
		for b in buckets:
			if c >= int(b):
				at = int(b)
		wealth[at] += 1
	a.wealth = wealth
	# ---- the game's own counters, summed over the session, and grouped ------------------------
	var stats := {}
	for h in hourly:
		var sd = h.get("stats_delta", {})
		if sd is Dictionary:
			for k in sd:
				stats[k] = float(stats.get(k, 0.0)) + float(sd[k])
	a.stats = stats
	var groups := {"production": {}, "consumption": {}, "trade": {}, "facilities": {}}
	for k in stats:
		var g := group_of(k, defs.get("production_groups", {}))
		if g != "":
			groups.production[g] = float(groups.production.get(g, 0.0)) + float(stats[k])
		g = group_of(k, defs.get("consumption_groups", {}))
		if g != "":
			groups.consumption[g] = float(groups.consumption.get(g, 0.0)) + float(stats[k])
		g = group_of(k, defs.get("trade_groups", {}))
		if g != "":
			groups.trade[g] = float(groups.trade.get(g, 0.0)) + float(stats[k])
		for pre in defs.get("facility_prefixes", []):
			if k.begins_with(str(pre)):
				groups.facilities[k.trim_prefix(str(pre))] = float(stats[k])
	a.groups = groups
	a.daily = daily(hourly, defs)
	a.performance = performance(hourly, a.session)
	a.analysis_ms = Time.get_ticks_msec() - t0
	return a


## One row a game day: the levels at the day's last snapshot, the hourly counts summed, the day's production and consumption.
static func daily(hourly: Array, defs: Dictionary) -> Array:
	var by_day := {}
	var order := []
	for h in hourly:
		var d := int(h.day)
		if not by_day.has(d):
			by_day[d] = {"day": d, "hours": 0, "wall_ms": 0.0, "produced": 0.0, "consumed": 0.0, "max_guards_engaged": 0, "starving_hours": 0}
			for k in ["events_h", "trades_h", "trade_coins_h", "transfers_h", "actions_h", "actions_failed_h", "walk_lost_h", "crimes_h", "chases_h", "alerts_h"]:
				by_day[d][k] = 0
			order.append(d)
		var row: Dictionary = by_day[d]
		row.hours += 1
		for k in h:
			if str(k).ends_with("_h"):
				row[k] = int(row.get(k, 0)) + int(h[k])
			elif not (k in ["seq", "stats_delta", "wall_ms"]):
				row[k] = h[k]                          # a level: the last of the day
		if typeof(h.get("wall_ms")) in [TYPE_INT, TYPE_FLOAT]:
			row.wall_ms += float(h.wall_ms)
		row.max_guards_engaged = maxi(int(row.max_guards_engaged), int(h.get("guards_engaged", 0)))
		row.starving_hours += int(h.get("starving", 0))
		var sd = h.get("stats_delta", {})
		if sd is Dictionary:
			for k in sd:
				if group_of(k, defs.get("production_groups", {})) != "":
					row.produced += float(sd[k])
				if group_of(k, defs.get("consumption_groups", {})) != "" and not str(k).begins_with("eaten_food"):
					row.consumed += float(sd[k])
	order.sort()
	return order.map(func(d): return by_day[d])


static func performance(hourly: Array, session: Dictionary) -> Dictionary:
	var walls := []
	var mem := 0
	for h in hourly:
		if typeof(h.get("wall_ms")) in [TYPE_INT, TYPE_FLOAT]:
			walls.append(float(h.wall_ms))
		mem = maxi(mem, int(h.get("mem_bytes", 0)))
	walls.sort()
	var p := func(q: float) -> float: return walls[mini(walls.size() - 1, int(q * walls.size()))] if not walls.is_empty() else 0.0
	var total := 0.0
	for x in walls:
		total += x
	return {"hours": walls.size(), "wall_ms_total": total, "wall_ms_p50": p.call(0.5), "wall_ms_p95": p.call(0.95), "wall_ms_max": p.call(1.0),
		"mem_bytes_max": mem, "archive_bytes": int(session.get("bytes", 0)), "chunks": int(session.get("chunk_count", 0)),
		"rows": session.get("counts", {}), "peak_buffer_rows": int(session.get("peak_buffer_rows", 0)), "early_flushes": int(session.get("early_flushes", 0)),
		"completeness": str(session.get("completeness", "unknown"))}
