class_name FlightRecorder
extends RefCounted
## The flight recorder core (REC-19, schema mml-recorder/2; docs/design/FLIGHT_RECORDER.md). A passive, game-agnostic
## event store: tables of rows (event, participant, decision, alternative, factor, state_change, link, alert, sample), a
## snapshot (schema 2: one village-wide aggregate row an hour), a context stack that gives events their causal parent, object threads, a bounded buffer, and an append-only gzip
## archive of chunk files with headers and footers.
##
## Rules it keeps (owner decisions REC-D1..D4, 2026-10-23):
##   - it is only ever created when enabled (game/data/recorder.json "enabled", false, or a test/harness override);
##     World.recorder is null otherwise and every instrumentation point is one guarded call;
##   - it never draws from any random generator, never calls planning or decision code, never changes game state: it
##     receives calls at instrumentation points and stores what it was given;
##   - a value the engine did not evaluate is stored as NOT_EVALUATED, never invented;
##   - when the storage cap is reached it stops, keeps everything written, and marks the session incomplete with the day
##     and sequence (never deletes or overwrites); a full buffer is flushed early, rows are never dropped silently.
## Subclasses (WorldRecorder) add the instrumentation points that know the game.

const SCHEMA := "mml-recorder/2"     # 2 (SIM-GATE-01): adds the hourly snapshot table and the combat chase events; /1 archives read the same
const NOT_EVALUATED := "not evaluated"
const CONFIG_PATH := "res://data/recorder.json"
const CODES_PATH := "res://data/recorder_codes.json"

## Column order of every table; the first column of every row is `seq`, the session-wide row sequence.
const COLUMNS := {
	"event": ["seq", "id", "parent", "interaction", "object", "day", "minute", "settlement", "x", "y", "system", "subsystem",
		"category", "subtype", "actor", "outcome", "reason", "rule", "detail"],
	"participant": ["seq", "event", "ref", "role"],
	"decision": ["seq", "event", "actor", "kind", "chosen", "basis", "tiebreak"],
	"alternative": ["seq", "event", "option", "evaluated", "feasible", "reason", "score"],
	"factor": ["seq", "event", "option", "factor", "value", "unit", "source", "evaluated"],
	"state_change": ["seq", "event", "ref", "prop", "before", "after", "delta", "authority"],
	"link": ["seq", "from", "to", "kind", "via"],
	"alert": ["seq", "id", "severity", "rule", "entities", "values", "event", "day"],
	"sample": ["seq", "day", "hour", "entity", "hunger", "hp", "x", "y", "doing", "coins"],
	# SIM-GATE-01: one village-wide aggregate row an hour (WorldRecorder.snapshot_row; docs/design/FLIGHT_RECORDER.md section 3).
	# The *_h columns count what the recorder saw in the hour before; stats_delta is the game's own w.stats counters that changed
	# in that hour ({key: change}); wall_ms and mem_bytes are measurements of the machine, never part of a determinism comparison.
	"snapshot": ["seq", "day", "hour", "alive", "households", "adults", "employed", "children", "elders", "bandits", "mean_hunger",
		"min_hunger", "starving", "mean_hp", "idle", "lost", "fighting", "guards", "guards_engaged", "total_coins", "villager_coins",
		"treasury", "coin_sources", "hh_purse_min", "hh_purse_median", "hh_purse_max", "food_days", "granary_wheat", "births", "deaths",
		"ties", "friends", "courting", "facts", "player_crimes", "events_h", "trades_h", "trade_coins_h", "transfers_h", "actions_h",
		"actions_failed_h", "walk_lost_h", "crimes_h", "chases_h", "alerts_h", "stats_delta", "wall_ms", "mem_bytes"],
}
const TABLES := ["event", "participant", "decision", "alternative", "factor", "state_change", "link", "alert", "sample", "snapshot"]
const EV_ID := 1
const EV_PARENT := 2
const EV_INTERACTION := 3
const EV_OBJECT := 4
const EV_OUTCOME := 15
const EV_REASON := 16
const EV_DETAIL := 18

## Tests only: switch the recorder on without editing recorder.json (like JudgmentLive.test_enabled).
static var test_enabled := false
## SIM-GATE-01 amendment: the desktop game's own switch (Settings, Saves, "Record gameplay"; GameSettings.record_gameplay), set by
## main before a game starts or loads. Only on Windows and Linux; never set on Android. recorder.json stays "enabled": false.
static var live_enabled := false
static var _cfg_cache := {}
static var _codes_cache := {}

# --- configuration (recorder.json, or the caller's) ---
var cfg := {}
var codes := {}
var root := ""                  # directory holding the sessions
var session := ""               # this session's id
var dir := ""                   # root/session

# --- the clock (a subclass overrides _now) ---
var day := 0
var minute := 0.0

# --- state ---
var seq := 0                    # last row sequence given
var next_event := 1
var next_alert := 1
var buffer := {}                # table -> Array of row Arrays not yet written
var buffered := 0
var peak_buffer := 0
var early_flushes := 0
var buf_day := -1
var buf_hour := -1
var parts := {}                 # "day|hour|table" -> next part number
var counts := {}                # table -> rows recorded
var chunks := 0
var bytes := 0
var stopped := false            # the storage cap was reached: nothing more is recorded
var finished := false
var incomplete_at := {}         # {day, seq} when stopped by the cap
var recovered: Array = []       # chunks of earlier sessions found without a footer at start
var unknown_codes := {}         # "kind:code" -> count of codes missing from the table
var meta := {}                  # session facts a caller adds (build, commit, seed, save version ...)
var started_unix := 0.0

var _stack: Array = []          # ids of open events, innermost last
var _open := {}                 # event id -> row Array of an event begun and not yet ended
var _last_by_object := {}       # object key -> id of its latest event (object threads)
var _cap := 0
var _buffer_rows := 50000


## Configuration from recorder.json, read once; each caller gets its own copy.
static func default_cfg() -> Dictionary:
	if _cfg_cache.is_empty():
		var f := FileAccess.open(CONFIG_PATH, FileAccess.READ)
		_cfg_cache = JSON.parse_string(f.get_as_text())
	return _cfg_cache.duplicate(true)


static func default_codes() -> Dictionary:
	if _codes_cache.is_empty():
		var f := FileAccess.open(CODES_PATH, FileAccess.READ)
		_codes_cache = JSON.parse_string(f.get_as_text())
	return _codes_cache


static func enabled() -> bool:
	return test_enabled or live_enabled or bool(default_cfg().get("enabled", false))


## Start a session. `config` overrides recorder.json keys (root, buffer_rows, storage_cap_bytes, ...).
func _init(config := {}, session_meta := {}) -> void:
	cfg = default_cfg()
	for k in config:
		cfg[k] = config[k]
	codes = default_codes()
	meta = session_meta.duplicate(true)
	root = str(cfg.get("root", "user://recorder"))
	_cap = int(cfg.get("storage_cap_bytes", 0))
	_buffer_rows = maxi(16, int(cfg.get("buffer_rows", 50000)))
	for t in TABLES:
		buffer[t] = []
		counts[t] = 0
	started_unix = Time.get_unix_time_from_system()
	session = "s%d" % int(started_unix)
	var base := session
	var n := 1
	while DirAccess.dir_exists_absolute(_abs("%s/%s" % [root, session])):
		session = "%s_%d" % [base, n]
		n += 1
	dir = "%s/%s" % [root, session]
	DirAccess.make_dir_recursive_absolute(_abs(dir))
	_recover_earlier()
	_write_session()


static func _abs(path: String) -> String:
	return ProjectSettings.globalize_path(path) if path.begins_with("user://") or path.begins_with("res://") else path


## The clock a subclass reads from its world.
func _now() -> Array:
	return [day, minute]


# ---------------------------------------------------------------- recording ------------------
func _code(kind: String, value: String) -> String:
	var list = codes.get(kind, [])
	var ok := false
	if list is Array:
		ok = list.has(value)
	elif list is Dictionary:
		ok = list.has(value)
	if not ok:
		var k := kind + ":" + value
		unknown_codes[k] = int(unknown_codes.get(k, 0)) + 1
	return value


func recording() -> bool:
	return not stopped and not finished


func _add(table: String, row: Array) -> void:
	if stopped or finished:
		return
	var now := _now()
	if buffered > 0 and (int(now[0]) != buf_day):
		flush()                                     # a chunk set is one game day: never mix days in a chunk
		if stopped:
			return
	if buffered == 0:
		buf_day = int(now[0])
		buf_hour = int(float(now[1]) / 60.0)
	seq += 1
	row[0] = seq
	(buffer[table] as Array).append(row)
	counts[table] = int(counts[table]) + 1
	buffered += 1
	if buffered > peak_buffer:
		peak_buffer = buffered
	if buffered >= _buffer_rows:
		early_flushes += 1
		flush()


## Begin an event; it is the parent of everything recorded until end() (unless `parent` is given). Returns its id (0 when
## not recording). opts: parent, interaction, object (object-thread key), x, y, detail, rule, settlement.
func begin(system: String, subsystem: String, category: String, subtype: String, actor: String, opts := {}) -> int:
	if stopped or finished:
		return 0
	var id := next_event
	next_event += 1
	var parent := int(opts.get("parent", _stack[-1] if not _stack.is_empty() else -1))
	var inter := int(opts.get("interaction", -1))
	if inter < 0:
		inter = id
		if parent > 0 and _open.has(parent):
			inter = int((_open[parent] as Array)[EV_INTERACTION])
	var now := _now()
	var obj := str(opts.get("object", ""))
	var row := [0, id, parent, inter, obj, int(now[0]), snappedf(float(now[1]), 0.01), str(opts.get("settlement", "")),
		int(opts.get("x", -1)), int(opts.get("y", -1)), _code("systems", system), _code("subsystems", subsystem),
		_code("categories", category), subtype, actor, "unfinished", "", str(opts.get("rule", "")), str(opts.get("detail", ""))]
	_open[id] = row
	_stack.append(id)
	if obj != "":
		if _last_by_object.has(obj):
			link(id, int(_last_by_object[obj]), "same_object", obj)
		_last_by_object[obj] = id
	return id


## End an event (it leaves the context stack) and put its row in the buffer.
func end(id: int, outcome := "ok", reason := "", detail := "") -> void:
	if id <= 0 or not _open.has(id):
		return
	var row: Array = _open[id]
	_open.erase(id)
	var at := _stack.rfind(id)
	if at >= 0:
		_stack.remove_at(at)
	row[EV_OUTCOME] = _code("outcomes", outcome)
	if reason != "":
		row[EV_REASON] = _code("reasons", reason)
	if detail != "":
		row[EV_DETAIL] = detail
	_add("event", row)


## An event with no children: begin and end together.
func event(system: String, subsystem: String, category: String, subtype: String, actor: String, outcome := "ok", reason := "", opts := {}) -> int:
	var id := begin(system, subsystem, category, subtype, actor, opts)
	end(id, outcome, reason)
	return id


func current() -> int:
	return -1 if _stack.is_empty() else int(_stack[-1])


func participant(ev: int, ref: String, role: String) -> void:
	if ev > 0:
		_add("participant", [0, ev, ref, role])


## One typed change. `delta` is computed when both values are integers.
func state_change(ev: int, ref: String, prop: String, before, after, authority: String) -> void:
	if ev <= 0:
		return
	var delta = NOT_EVALUATED
	if typeof(before) == TYPE_INT and typeof(after) == TYPE_INT:
		delta = int(after) - int(before)
	_code("state_properties", prop.get_slice(":", 0))
	_code("authorities", authority)
	_add("state_change", [0, ev, ref, prop, before, after, delta, authority])
	_note_state_change(ref, prop, delta, authority)


## Subclass hook: every recorded state change (the coin audit sums the coin ones).
func _note_state_change(_ref: String, _prop: String, _delta, _authority: String) -> void:
	pass


func decision(ev: int, actor: String, kind: String, chosen: String, basis: String, tiebreak := "") -> void:
	if ev > 0:
		_add("decision", [0, ev, actor, _code("decision_kinds", kind), chosen, _code("decision_basis", basis), tiebreak])


func alternative(ev: int, option: String, evaluated: String, feasible, reason := "", score = NOT_EVALUATED) -> void:
	if ev > 0:
		_add("alternative", [0, ev, option, evaluated, feasible, _code("reasons", reason) if reason != "" else "", score])


func factor(ev: int, option: String, name: String, value, unit: String, source: String, evaluated := "yes") -> void:
	if ev > 0:
		_add("factor", [0, ev, option, name, value, unit, source, evaluated])


func link(from_ev: int, to_ev: int, kind: String, via := "") -> void:
	if from_ev > 0 and to_ev > 0:
		_add("link", [0, from_ev, to_ev, _code("link_kinds", kind), via])


func alert(severity: String, rule: String, entities: String, values: String, ev := -1) -> int:
	if stopped or finished:
		return 0
	var id := next_alert
	next_alert += 1
	_code("alert_severities", severity)
	_code("alert_rules", rule)
	_add("alert", [0, id, severity, rule, entities, values, ev, int(_now()[0])])
	return id


func sample(entity: String, hunger, hp, x: int, y: int, doing: String, coins) -> void:
	var now := _now()
	_add("sample", [0, int(now[0]), int(float(now[1]) / 60.0), entity, hunger, hp, x, y, doing, coins])


## One snapshot row (the values in COLUMNS.snapshot order after seq).
func snapshot(values: Array) -> void:
	_add("snapshot", [0] + values)


# ---------------------------------------------------------------- archive --------------------
## Write the buffered rows to chunk files (one per table that has rows) and update the session record.
func flush() -> void:
	if buffered == 0:
		return
	var hour_key := "%d|%d" % [buf_day, buf_hour]
	var ddir := "%s/d%04d" % [dir, buf_day]
	DirAccess.make_dir_recursive_absolute(_abs(ddir))
	for t in TABLES:
		var rows: Array = buffer[t]
		if rows.is_empty():
			continue
		var pk := "%s|%s" % [hour_key, t]
		var part := int(parts.get(pk, 0))
		parts[pk] = part + 1
		var path := "%s/%s.h%02d.p%d.jsonl.gz" % [ddir, t, buf_hour, part]
		bytes += RecorderArchive.write_chunk(_abs(path), {"schema": SCHEMA, "session": session, "table": t, "day": buf_day,
			"hour": buf_hour, "part": part, "columns": COLUMNS[t], "first_seq": rows[0][0], "last_seq": rows[-1][0]}, rows)
		chunks += 1
		buffer[t] = []
	buffered = 0
	if _cap > 0 and bytes >= _cap:
		stopped = true                             # REC-D2: stop, keep everything, mark the session incomplete
		incomplete_at = {"day": buf_day, "seq": seq}
	_write_session()


## Close the session: write everything, close open events as unfinished, record the end.
func finish() -> void:
	if finished:
		return
	for id in _open.keys():
		end(int(id), "unfinished", "")
	flush()
	finished = true
	_write_session(true)


func completeness() -> String:
	if stopped:
		return "incomplete: storage cap reached at day %d, sequence %d" % [int(incomplete_at.day), int(incomplete_at.seq)]
	return "complete" if finished else "recording"


func session_record(ended := false) -> Dictionary:
	var rec := {"schema": SCHEMA, "session": session, "start_unix": started_unix, "ended": ended, "completeness": completeness(),
		"chunk_count": chunks, "bytes": bytes, "storage_cap_bytes": _cap, "counts": counts.duplicate(), "last_seq": seq,
		"events": next_event - 1, "alerts": next_alert - 1, "buffer_rows": _buffer_rows, "peak_buffer_rows": peak_buffer,
		"early_flushes": early_flushes, "recovered": recovered, "unknown_codes": unknown_codes,
		"coverage": "recorder_coverage.json (what is instrumented; everything not listed there is not recorded)"}
	for k in meta:
		rec[k] = meta[k]
	if stopped:
		rec["incomplete_at"] = incomplete_at
	if ended:
		rec["end_unix"] = Time.get_unix_time_from_system()
	return rec


func _write_session(ended := false) -> void:
	var f := FileAccess.open(_abs(dir + "/session.json"), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(session_record(ended), "  ", false))
		f.close()


## Earlier sessions of this root that never wrote their end: look for chunks without a footer, record each in this
## session's record (and leave a recovery.json in that session so it is reported once). Nothing is deleted or changed.
func _recover_earlier() -> void:
	for sid in DirAccess.get_directories_at(_abs(root)):
		if sid == session:
			continue
		var sdir := "%s/%s" % [root, sid]
		if FileAccess.file_exists(_abs(sdir + "/recovery.json")):
			continue
		var rec = RecorderArchive.read_json(_abs(sdir + "/session.json"))
		if rec is Dictionary and bool(rec.get("ended", false)):
			continue
		var age := Time.get_unix_time_from_system() - float(FileAccess.get_modified_time(_abs(sdir + "/session.json")))
		if age < float(cfg.get("live_grace_seconds", 120)):
			continue                                # written to a moment ago: probably still recording (another process), not interrupted
		var found := RecorderArchive.scan_session(_abs(sdir))
		for item in found.truncated:
			recovered.append({"session": sid, "file": item.file, "state": item.state})
		var f := FileAccess.open(_abs(sdir + "/recovery.json"), FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify({"found_by": session, "chunks_ok": found.ok, "truncated": found.truncated}, "  ", false))
			f.close()
