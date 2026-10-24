extends RefCounted
## SIM-GATE-01: builds the flight recorder analysis workbook (the sheets of res://data/sim_workbook.json) from recorder
## analyses (recorder_analysis.gd) and, for the CI gate, the gate's own results (tools/sim_suite.py gate.json). One builder
## for the CI gate workbook (tests/sim_workbook.gd) and the desktop game's live export (live_export.gd); desktop and CI only.
##
##   build(path, runs, gate, defs) -> {ok, error, sheets, charts}
## runs: [{run, scenario, seed, days, recorded, result, wall_seconds, alive_start, analysis (or null for a run without the
## recorder)}]; gate: {} for a live export, else gate.json (result, commit, build, run_id, schema, findings, history,
## proposals, profile, perf_sizes, notes, coverage).

const XlsxWriter := preload("res://scripts/recorder_export/xlsx_writer.gd")

var x
var defs := {}
var charts := 0


static func _fmt(v, nd := 2):
	if v is float:
		return snappedf(v, pow(10.0, -nd))
	return v


func build(path: String, runs: Array, gate: Dictionary, workbook_defs: Dictionary) -> Dictionary:
	defs = workbook_defs
	x = XlsxWriter.new()
	if not x.open(path):
		return {"ok": false, "error": x.error}
	var rec_runs := runs.filter(func(r): return r.get("analysis") != null)
	var chart_runs := rec_runs.slice(0, int(defs.get("chart_runs", 4)))
	executive(runs, gate)
	population(rec_runs, chart_runs)
	economy(rec_runs, chart_runs)
	activity(rec_runs, chart_runs)
	relations(rec_runs, chart_runs)
	crime(rec_runs, chart_runs, gate)
	production(rec_runs, chart_runs)
	performance(runs, rec_runs, chart_runs, gate)
	history(gate)
	register(runs, rec_runs, gate)
	runs_sheet(runs)
	proposed(gate, rec_runs)
	events(rec_runs)
	var ok: bool = x.close()
	return {"ok": ok, "error": x.error, "sheets": x.sheets.map(func(s): return s.name), "charts": x.chart_count}


func _label(r: Dictionary) -> String:
	return str(r.run)


## A wide table for charts: one row a day, `metrics` x runs columns; returns [first data row, last data row].
func _wide(chart_runs: Array, metrics: Array) -> Array:
	var header := ["day"]
	for m in metrics:
		for r in chart_runs:
			header.append("%s · %s" % [m[1], _label(r)])
	var days := {}
	for r in chart_runs:
		for d in r.analysis.daily:
			days[int(d.day)] = true
	var dl := days.keys()
	dl.sort()
	x.begin_sheet(_sheet_name, header)
	for day in dl:
		var row := [day]
		for m in metrics:
			for r in chart_runs:
				var found = null
				for d in r.analysis.daily:
					if int(d.day) == day:
						found = d.get(m[0])
						break
				row.append(_fmt(found) if found is int or found is float else null)
		x.row(row)
	return [2, dl.size() + 1]


var _sheet_name := ""


func _blank(n := 1) -> void:
	for i in n:
		x.row([])


func _chart(kind: String, title: String, first_col: int, ncols: int, rows: Array, x_title := "day", y_title := "") -> void:
	if rows[1] < rows[0]:
		return
	var ys := []
	for i in ncols:
		ys.append(first_col + i)
	x.chart({"type": kind, "title": title, "x_col": 0, "y_cols": ys, "first_row": rows[0], "last_row": rows[1], "x_title": x_title, "y_title": y_title})
	charts += 1


# ---------------------------------------------------------------- sheets ---------------------
func executive(runs: Array, gate: Dictionary) -> void:
	x.begin_sheet("Executive Summary", ["item", "value"], [34, 120])
	var live := gate.is_empty()
	var days := 0
	var seeds := {}
	var scen := {}
	var pops := {}
	for r in runs:
		days += int(r.get("days", 0))
		seeds[int(r.get("seed", 0))] = true
		scen[str(r.get("scenario", ""))] = true
		if r.get("alive_start") != null:
			pops[int(r.alive_start)] = true
	x.row(["what this is", "live gameplay recording (desktop export)" if live else "pre-build simulation gate (SIM-GATE-01)"])
	x.row(["build", str(gate.get("build", ProjectSettings.get_setting("application/config/version", "")))])
	x.row(["commit", str(gate.get("commit", runs[0].analysis.session.get("commit", "unknown") if not runs.is_empty() and runs[0].get("analysis") != null else "unknown"))])
	x.row(["overall result", str(gate.get("result", "not a gate: a recording"))])
	x.row(["recorder schema", str(gate.get("schema", defs.get("schema", "")))])
	x.row(["run id", str(gate.get("run_id", runs[0].analysis.session.get("session", "") if not runs.is_empty() and runs[0].get("analysis") != null else ""))])
	x.row(["simulated game days (all runs)", days])
	x.row(["runs", runs.size()])
	var sl := seeds.keys()
	sl.sort()
	x.row(["seeds", ", ".join(sl.map(func(s): return str(s)))])
	var sc := scen.keys()
	sc.sort()
	x.row(["scenarios", ", ".join(sc)])
	var pl := pops.keys()
	pl.sort()
	x.row(["starting populations (villagers)", ", ".join(pl.map(func(s): return str(s)))])
	var blocking: Array = gate.get("findings", []).filter(func(f): return bool(f.get("blocking", false)))
	x.row(["release-blocking defects", blocking.size()])
	for f in blocking.slice(0, 30):
		x.row(["  blocking", "%s: %s" % [f.get("scenario", ""), f.get("description", "")]])
	var hist: Array = gate.get("history", []).filter(func(h): return str(h.get("verdict", "")) == "REGRESSION")
	x.row(["historical regressions (against the accepted baseline)", hist.size()])
	for line in gate.get("notes", []):
		x.row(["major finding", str(line)])
	if live:
		for r in runs:
			var a: Dictionary = r.analysis
			x.row(["recording", "%s: %s; %d snapshot hours; %d events; archive %d bytes" % [r.run, str(a.performance.completeness), a.hourly.size(), int(a.session.get("events", 0)), int(a.performance.archive_bytes)]])
	x.row(["read me", "A village is allowed to fail; the simulation is not (WDR-022). Hardship, deaths, shortages and collapse are outcomes and are reported here, never gate failures. The gate fails only on defects: determinism, conservation of coins and goods, save and load, crashes, recorder integrity, missing sheets or scenarios, and unapproved changes against the accepted baseline."])


func population(rec_runs: Array, chart_runs: Array) -> void:
	_sheet_name = "Population and Households"
	var w := _wide(chart_runs, [["alive", "villagers alive"], ["hh_purse_median", "median household purse"], ["starving", "starving at day end"]])
	var n := chart_runs.size()
	_chart("line", "Population over time", 1, n, w, "day", "villagers alive")
	_chart("line", "Household wealth (median purse)", 1 + n, n, w, "day", "coins")
	_blank(2)
	x.row(["run", "day", "alive", "adults", "employed", "children", "elders", "households", "births (since start)", "deaths (since start)",
		"mean hunger", "min hunger", "starving now", "starving person-hours", "household purse min", "median", "max", "food days in store"])
	for r in rec_runs:
		for d in r.analysis.daily:
			x.row([_label(r), d.day, d.get("alive"), d.get("adults"), d.get("employed"), d.get("children"), d.get("elders"), d.get("households"),
				d.get("births"), d.get("deaths"), _fmt(d.get("mean_hunger")), _fmt(d.get("min_hunger")), d.get("starving"), d.get("starving_hours"),
				d.get("hh_purse_min"), d.get("hh_purse_median"), d.get("hh_purse_max"), _fmt(d.get("food_days"))])
	_blank(2)
	x.row(["run", "deaths: day", "minute", "person", "detail (cause, role, household)"])
	for r in rec_runs:
		for d in r.analysis.deaths:
			x.row([_label(r), d[0], d[1], d[2], d[3]])


func economy(rec_runs: Array, chart_runs: Array) -> void:
	_sheet_name = "Economy"
	var w := _wide(chart_runs, [["total_coins", "currency in circulation"], ["treasury", "treasury"], ["food_days", "food days in store"], ["trade_coins_h", "coins traded"]])
	var n := chart_runs.size()
	_chart("line", "Currency circulation", 1, n, w, "day", "coins")
	_chart("line", "Resource shortages: food in store", 1 + 2 * n, n, w, "day", "days of the village's food")
	_blank(2)
	# wealth distribution (bar chart): people per purse bucket at the last hour, per charted run
	var buckets: Array = defs.get("wealth_buckets", [])
	var start_row := int(x.cur.rows) + 1
	var head := ["purse at the last hour (coins, at least)"]
	for r in chart_runs:
		head.append("villagers · " + _label(r))
	x.row(head)
	for b in buckets:
		var row: Array = ["%d+" % int(b)]
		for r in chart_runs:
			row.append(int(r.analysis.wealth.get(int(b), 0)))
		x.row(row)
	if not buckets.is_empty() and not chart_runs.is_empty():
		var ys := []
		for i in chart_runs.size():
			ys.append(1 + i)
		x.chart({"type": "bar", "title": "Household wealth distribution", "x_col": 0, "y_cols": ys, "first_row": start_row + 1, "last_row": start_row + buckets.size(),
			"header_row": start_row, "x_title": "coins at the last hour", "y_title": "villagers", "anchor": [XlsxWriter.CHART_COL + 11, 1]})
		charts += 1
	_blank(2)
	x.row(["run", "day", "currency total", "villagers' coins", "treasury", "coins from outside (cumulative)", "trades", "coins traded", "transfers",
		"granary wheat", "unattributed coin alerts (holder, warning)", "unattributed total (violation)"])
	for r in rec_runs:
		for d in r.analysis.daily:
			x.row([_label(r), d.day, d.get("total_coins"), d.get("villager_coins"), d.get("treasury"), d.get("coin_sources"), d.get("trades_h"),
				d.get("trade_coins_h"), d.get("transfers_h"), d.get("granary_wheat"), d.get("alerts_h"), null])
	_blank(2)
	x.row(["run", "integrity: currency created or lost outside the books (coin.unattributed_total alerts)", "holder alerts (REC-D4: coin sites not instrumented, detected hourly)", "imports", "exports", "stall sales", "contracts", "manor work"])
	for r in rec_runs:
		var a: Dictionary = r.analysis
		var t: Dictionary = a.groups.trade
		x.row([_label(r), int(a.alerts.get("coin.unattributed_total", 0)), int(a.alerts.get("coin.unattributed_holder", 0)), _fmt(t.get("Imports", 0.0)),
			_fmt(t.get("Exports", 0.0)), _fmt(t.get("Stalls", 0.0)), _fmt(t.get("Contracts", 0.0)), _fmt(t.get("Manor work", 0.0))])


func activity(rec_runs: Array, chart_runs: Array) -> void:
	_sheet_name = "NPC Activity"
	var classes: Array = defs.get("activity_classes", {}).get("order", [])
	var header := ["day"]
	var r0: Dictionary = chart_runs[0] if not chart_runs.is_empty() else {}
	for c in ["work", "travel", "idle", "lost"]:
		header.append("%s (share of villager-hours) · %s" % [c, _label(r0) if not r0.is_empty() else ""])
	x.begin_sheet(_sheet_name, header)
	var nrows := 0
	if not r0.is_empty():
		var days: Array = r0.analysis.activity_daily.keys()
		days.sort()
		for d in days:
			var ad: Dictionary = r0.analysis.activity_daily[d]
			var tot := 0.0
			for k in ad:
				tot += float(ad[k])
			tot = maxf(1.0, tot)
			x.row([d, _fmt(ad.get("work", 0) / tot, 4), _fmt(ad.get("travel", 0) / tot, 4), _fmt(ad.get("idle", 0) / tot, 4), _fmt(ad.get("lost", 0) / tot, 4)])
			nrows += 1
	_chart("line", "Employment and idle time", 1, 4, [2, nrows + 1], "day", "share of villager-hours")
	_blank(2)
	x.row(["run", "activity class", "villager-hours", "share"])
	for r in rec_runs:
		var tot := 0
		for c in r.analysis.activity:
			tot += int(r.analysis.activity[c])
		for c in classes:
			x.row([_label(r), c, int(r.analysis.activity.get(c, 0)), _fmt(float(r.analysis.activity.get(c, 0)) / maxf(1.0, tot), 4)])
	_blank(2)
	x.row(["run", "action (plan step)", "ok", "failed", "failure share"])
	for r in rec_runs:
		var keys: Array = r.analysis.actions.keys()
		keys.sort_custom(func(p, q): return int(r.analysis.actions[p][0]) + int(r.analysis.actions[p][1]) > int(r.analysis.actions[q][0]) + int(r.analysis.actions[q][1]))
		for k in keys:
			var v: Array = r.analysis.actions[k]
			x.row([_label(r), k, v[0], v[1], _fmt(float(v[1]) / maxf(1.0, float(v[0]) + float(v[1])), 4)])
	_blank(2)
	x.row(["run", "decisions with a plan", "decisions with no plan (empty)", "walk lost (navigation failures)", "station waits given up", "employment events", "schedule compliance"])
	for r in rec_runs:
		var a: Dictionary = r.analysis
		var lost := 0
		var gave := 0
		for k in a.interruptions:
			if str(k).begins_with("walk_lost"):
				lost += int(a.interruptions[k])
			elif str(k).begins_with("station_giveup"):
				gave += int(a.interruptions[k])
		var emp := 0
		for k in a.employment:
			emp += int(a.employment[k])
		x.row([_label(r), int(a.decisions.get("ok", 0)), int(a.decisions.get("empty", 0)), lost, gave, emp, "not recorded: the game keeps no schedule to compare against"])
	_blank(2)
	x.row(["run", "longest hours on one cell while working, travelling or lost", "person", "day", "hour", "doing", "x", "y"])
	for r in rec_runs:
		var st: Dictionary = r.analysis.stuck
		var ents: Array = st.keys()
		ents.sort_custom(func(p, q): return int(st[p][0]) > int(st[q][0]))
		for e in ents.slice(0, 10):
			var v: Array = st[e]
			x.row([_label(r), v[0], e, v[1], v[2], v[3], v[4], v[5]])
	_blank(2)
	x.row(["run", "what villagers were doing (top 40)", "villager-hours"])
	for r in rec_runs:
		var dh: Dictionary = r.analysis.doing_hours
		var ks: Array = dh.keys()
		ks.sort_custom(func(p, q): return int(dh[p]) > int(dh[q]))
		for k in ks.slice(0, 40):
			x.row([_label(r), k if str(k) != "" else "(nothing)", dh[k]])


func relations(rec_runs: Array, chart_runs: Array) -> void:
	_sheet_name = "Relationships and Morality"
	var w := _wide(chart_runs, [["ties", "ties"], ["friends", "friendships"], ["courting", "courting pairs"], ["facts", "judgment facts"]])
	_chart("line", "Relationship changes", 1, chart_runs.size(), w, "day", "ties between people")
	_blank(2)
	x.row(["run", "gifts given", "friendships formed", "partnerships", "crime reports made", "reports delivered", "witnesses of the player's crimes", "judgment facts at the end"])
	for r in rec_runs:
		var a: Dictionary = r.analysis
		var wit := 0
		for c in a.crime:
			wit += int(c.witnesses)
		var last: Dictionary = a.daily[-1] if not a.daily.is_empty() else {}
		x.row([_label(r), _fmt(a.stats.get("gifts_given", 0.0)), _fmt(a.stats.get("friendships", 0.0)), int(a.life.get("partnership", 0)),
			_fmt(a.stats.get("crime_reports_made", 0.0)), _fmt(a.stats.get("crime_reports_delivered", 0.0)), wit, last.get("facts")])
	_blank(2)
	x.row(["not recorded yet", "Good/Bad opinion ledgers, gossip propagation and each relation's change are not instrumented (recorder_coverage.json: Relationships, Judgment, stages D4 and D5); the counts above are the game's own counters and the hourly totals of ties, friendships, courting pairs and judgment facts."])


func crime(rec_runs: Array, chart_runs: Array, gate: Dictionary) -> void:
	_sheet_name = "Crime and Justice"
	x.begin_sheet(_sheet_name, ["fighter and how the chase ended", "chases", "on the player", "median seconds", "longest seconds", "blows struck"])
	var summary := {}
	for r in rec_runs:
		for k in r.analysis.chase_summary:
			var s: Dictionary = r.analysis.chase_summary[k]
			if not summary.has(k):
				summary[k] = {"n": 0, "p": 0, "secs": [], "strikes": 0}
			summary[k].n += int(s.n)
			summary[k].p += int(s.on_player)
			summary[k].secs.append_array(s.seconds)
			summary[k].strikes += int(s.strikes)
	var keys := summary.keys()
	keys.sort()
	for k in keys:
		var secs: Array = summary[k].secs
		secs.sort()
		x.row([str(k).replace("|", ": "), summary[k].n, summary[k].p, _fmt(secs[secs.size() / 2] if not secs.is_empty() else 0.0), _fmt(secs[-1] if not secs.is_empty() else 0.0), summary[k].strikes])
	_chart("bar", "Crime and guard response", 1, 2, [2, keys.size() + 1], "how chases ended", "chases")
	_blank(2)
	x.row(["run", "crime events", "of which by the player", "witnesses (sum)", "guard alarms answered", "robberies by bandits", "player deaths", "guard chases of the player",
		"ended by a wall (blocked)", "ended out of range", "player escaped (no blow landed)"])
	for r in rec_runs:
		var a: Dictionary = r.analysis
		var by_player := 0
		var wit := 0
		var answered := 0
		var robberies := 0
		for c in a.crime:
			wit += int(c.witnesses)
			if str(c.kind) in ["theft", "strike", "loot", "pickpocket"] or (str(c.kind) == "raise_alarm" and int(str(c.actor).trim_prefix("p:")) >= 1000000):
				by_player += 1
			if str(c.kind) == "raise_alarm":
				answered += int(RecorderAnalysisLike.num(str(c.detail), "guards_answered"))
			if str(c.kind) == "robbery":
				robberies += 1
		var pd: int = a.deaths.filter(func(d): return str(d[3]).contains("player character died")).size()
		var gp: Array = a.chases.filter(func(c): return c.who == "guard" and c.target_is_player)
		x.row([_label(r), a.crime.size(), by_player, wit, answered, robberies, pd, gp.size(), gp.filter(func(c): return c.reason == "blocked").size(),
			gp.filter(func(c): return c.reason == "out_of_range").size(), gp.filter(func(c): return c.reason in ["blocked", "out_of_range"] and int(c.strikes) == 0).size()])
	_blank(2)
	x.row(["run", "player crime", "day", "minute", "witnesses", "first guard chase of the player after it (game minutes)", "its end", "its seconds", "outcome"])
	for r in rec_runs:
		var a: Dictionary = r.analysis
		for c in a.crime:
			if not (str(c.kind) in ["theft", "strike", "pickpocket", "loot"]):
				continue
			var t := float(c.day) * 1440.0 + float(c.minute)
			var resp = null
			for ch in a.chases:
				var s := float(ch.start_day) * 1440.0 + float(ch.start_minute)
				if ch.who == "guard" and ch.target_is_player and s >= t:
					resp = ch
					break
			x.row([_label(r), c.kind, c.day, c.minute, c.witnesses, (_fmt(float(resp.start_day) * 1440.0 + float(resp.start_minute) - t) if resp != null else "no guard chased"),
				resp.reason if resp != null else "", resp.seconds if resp != null else null, c.detail])
	_blank(2)
	x.row(["not in the game yet", "Wanted status, reinforcements (guards calling guards), arrests and a pursuit that survives loss of sight do not exist in this build: GP-CRIME-PURSUIT (owner approved, not started). Guards learn of a crime by seeing it or by a report delivered face to face; a chase ends at the first wall step, beyond 25 tiles or near the bandit camp. The pursuit probe below reproduces the owner's corner case."])
	var probe: Dictionary = gate.get("pursuit", {})
	if not probe.is_empty():
		x.row(["corner pursuit probe", "meets GP-CRIME-PURSUIT: %s; chase held %s minutes; closest %s tiles; ended: %s; guard then: %s" % [str(probe.get("meets_requirement")), str(probe.get("chase_held_minutes")), str(probe.get("closest_tiles")), str(probe.get("end_reason")), str(probe.get("guard_doing_after"))]])


func production(rec_runs: Array, chart_runs: Array) -> void:
	_sheet_name = "Production and Resources"
	var w := _wide(chart_runs.slice(0, 1), [["produced", "units produced"], ["consumed", "units consumed"]])
	_chart("line", "Production versus consumption", 1, 2, w, "day", "units a day")
	_blank(2)
	x.row(["run", "kind", "group", "units"])
	for r in rec_runs:
		for kind in ["production", "consumption", "trade"]:
			var g: Dictionary = r.analysis.groups[kind]
			var ks := g.keys()
			ks.sort()
			for k in ks:
				x.row([_label(r), kind, k, _fmt(g[k])])
	_blank(2)
	x.row(["run", "facility (station) busy when wanted", "times"])
	for r in rec_runs:
		var f: Dictionary = r.analysis.groups.facilities
		var ks := f.keys()
		ks.sort()
		for k in ks:
			x.row([_label(r), k, _fmt(f[k])])
	_blank(2)
	x.row(["run", "the game's counter (w.stats)", "total over the run"])
	for r in rec_runs:
		var st: Dictionary = r.analysis.stats
		var ks := st.keys()
		ks.sort()
		for k in ks:
			x.row([_label(r), k, _fmt(st[k])])


func performance(runs: Array, rec_runs: Array, chart_runs: Array, gate: Dictionary) -> void:
	_sheet_name = "Performance"
	var w := _wide(chart_runs, [["wall_ms", "milliseconds of machine time a game day"]])
	_chart("line", "Simulation performance", 1, chart_runs.size(), w, "day", "ms a game day")
	_blank(2)
	x.row(["run", "recorded", "wall seconds", "seconds a game day", "hour p50 ms", "hour p95 ms", "worst hour ms", "max static memory (bytes)", "archive bytes", "chunks", "rows",
		"peak buffer rows", "early flushes", "completeness"])
	for r in runs:
		var a = r.get("analysis")
		var p: Dictionary = a.performance if a != null else {}
		var rows := 0
		for k in p.get("rows", {}):
			rows += int(p.rows[k])
		x.row([_label(r), a != null, _fmt(r.get("wall_seconds")), _fmt(float(r.get("wall_seconds", 0.0)) / maxf(1.0, float(r.get("days", 1)))),
			_fmt(p.get("wall_ms_p50")), _fmt(p.get("wall_ms_p95")), _fmt(p.get("wall_ms_max")), p.get("mem_bytes_max"), p.get("archive_bytes"), p.get("chunks"), rows if a != null else null,
			p.get("peak_buffer_rows"), p.get("early_flushes"), p.get("completeness")])
	for k in ["recorder_overhead", "parallel"]:
		if gate.has(k):
			x.row([k, JSON.stringify(gate[k])])
	if gate.has("profile"):
		_blank(2)
		x.row(["system hotspot (economy_sim --profile)", "seconds", "share of the run", "calls"])
		for p in gate.profile:
			x.row([p.get("system"), p.get("seconds"), p.get("share"), p.get("calls")])
	if gate.has("population_scaling"):
		_blank(2)
		x.row(["population scaling (tests/judgment_perf.gd, synthetic judgment load)", "people", "result"])
		for p in gate.population_scaling:
			x.row(["judgment_perf", p.get("size"), p.get("line")])


func history(gate: Dictionary) -> void:
	x.begin_sheet("Historical Comparison", ["comparison", "baseline", "seed", "day", "value", "baseline value", "current value", "verdict", "note"])
	var h: Array = gate.get("history", [])
	if h.is_empty():
		x.row(["none", "", null, null, "", "", "", "not applicable", "A live recording has no baseline: historical comparison is made by the CI gate with identical seeds and rules."])
		return
	var rows := 0
	for e in h:
		x.row([e.get("comparison"), e.get("baseline"), e.get("seed"), e.get("day"), e.get("value"), JSON.stringify(e.get("base")) if not (e.get("base") is int or e.get("base") is float) else e.get("base"),
			JSON.stringify(e.get("now")) if not (e.get("now") is int or e.get("now") is float) else e.get("now"), e.get("verdict"), e.get("note", "")])
		rows += 1
	# chart: alive and currency at the last compared day, by build (the "changes from previous builds" chart)
	var builds: Array = gate.get("build_points", [])
	if not builds.is_empty():
		_blank(2)
		var start := int(x.cur.rows) + 1
		x.row(["baseline (seed 1, day 30)", "villagers alive", "currency / 10"])
		for b in builds:
			x.row([b.label, b.alive, b.currency_tenths])
		x.chart({"type": "bar", "title": "Changes from previous builds", "x_col": 0, "y_cols": [1, 2], "first_row": start + 1, "last_row": start + builds.size(),
			"header_row": start, "x_title": "baseline", "y_title": "value"})
		charts += 1


func register(runs: Array, rec_runs: Array, gate: Dictionary) -> void:
	x.begin_sheet("Regression Register", ["seed", "scenario", "run", "day", "hour", "entity or household", "event id", "failure description", "severity", "blocking", "expected", "actual", "reproduction"], [8, 16, 14, 6, 6, 18, 9, 60, 10, 9, 40, 40, 60])
	var n := 0
	for f in gate.get("findings", []):
		x.row([f.get("seed"), f.get("scenario"), f.get("run"), f.get("day"), f.get("hour"), f.get("entity", ""), f.get("event", ""), f.get("description"), f.get("severity"),
			"yes" if bool(f.get("blocking", false)) else "no", f.get("expected", ""), f.get("actual", ""), f.get("reproduce", "")])
		n += 1
	if gate.is_empty():
		for r in rec_runs:
			var a: Dictionary = r.analysis
			if int(a.alerts.get("coin.unattributed_total", 0)) > 0:
				x.row([a.session.get("seed"), "live", _label(r), null, null, "world", "", "coins created or lost outside the books (coin.unattributed_total)", "critical", "n/a",
					"no change of the world's coins without a recorded cause", "%d alerts" % int(a.alerts["coin.unattributed_total"]), "see the Events sheet (audit, unattributed_coins)"])
				n += 1
			if int(a.chunks.skipped) > 0 or str(a.performance.completeness) != "complete":
				x.row([a.session.get("seed"), "live", _label(r), null, null, "recorder", "", "recording incomplete or chunks unreadable", "major", "n/a", "complete",
					"%s; %d chunks skipped" % [a.performance.completeness, int(a.chunks.skipped)], ""])
				n += 1
	if n == 0:
		x.row([null, "", "", null, null, "", "", "no problem detected", "none", "no", "", "", ""])


func runs_sheet(runs: Array) -> void:
	var cols: Array = defs.get("runs_columns", [])
	x.begin_sheet("Runs", cols)
	for r in runs:
		var vals: Dictionary = r.duplicate()
		var a = r.get("analysis")
		if a != null:                                  # a recorded run: its outcomes as the recorder saw them
			var last: Dictionary = a.hourly[-1] if not a.hourly.is_empty() else {}
			vals.alive_end = last.get("alive")
			vals.currency_end = last.get("total_coins")
			vals.treasury_end = last.get("treasury")
			vals.households_end = last.get("households")
			vals.villager_deaths = a.deaths.filter(func(d): return str(d[3]).contains("role=") and not str(d[3]).contains("role=bandit")).size()
			vals.births = int(a.life.get("birth", 0))
			var nc := 0
			for k in a.events:
				if str(k).begins_with("identity|registered_newcomer|") or str(k).begins_with("identity|registered_outlaw|") or str(k).begins_with("identity|registered_arrival|"):
					nc += int(a.events[k])
			vals.newcomers = nc
			var tr := 0
			for k in a.events:
				if str(k) == "transaction|trade|ok":
					tr += int(a.events[k])
			vals.trades = tr
			vals.crimes = a.crime.size()
			vals.chases = a.chases.size()
			vals.unattributed_total_alerts = int(a.alerts.get("coin.unattributed_total", 0))
		var row := []
		for c in cols:
			var v = vals.get(c)
			row.append(_fmt(v) if v is float or v is int or v is bool else (str(v) if v != null else null))
		x.row(row)


func proposed(gate: Dictionary, rec_runs: Array) -> void:
	x.begin_sheet("Proposed Thresholds", ["measure", "value measured", "proposed limit", "status", "why"], [40, 18, 18, 22, 90])
	var p: Array = gate.get("proposals", [])
	for e in p:
		x.row([e.get("measure"), e.get("value"), e.get("proposed"), "PROPOSED (owner decision)", e.get("why", "")])
	if p.is_empty():
		x.row(["(none)", null, null, "", "Proposed thresholds come from the CI gate; a live recording only measures."])


func events(rec_runs: Array) -> void:
	x.begin_sheet("Events", ["run", "seq", "event id", "parent", "day", "minute", "category", "subtype", "actor", "outcome", "reason", "detail"], [12, 9, 9, 9, 6, 8, 12, 22, 12, 12, 18, 90])
	var budget := int(defs.get("event_rows_max", 20000))
	for r in rec_runs:
		for e in r.analysis.records:
			if budget <= 0:
				return
			x.row([_label(r), e[0], e[1], e[2], e[3], e[4], e[5], e[6], e[7], e[8], e[9], e[10]])
			budget -= 1


## (a tiny helper the crime sheet uses; no state)
class RecorderAnalysisLike:
	static func num(detail: String, key: String) -> float:
		for part in detail.split(" "):
			if part.begins_with(key + "="):
				return float(part.get_slice("=", 1))
		return 0.0
