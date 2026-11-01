class_name CivicRecords
extends RefCounted
## P21-01 (Expansion 21, owner directive 2026-10-23, VP-01): tenure history, succession and the legacy record. RECORDS ONLY,
## behind a disabled switch (data/civic.json "enabled"). It OBSERVES today's succession and changes nothing: the world calls
## it from the paths where a post changes hands, each through one guarded call (`if civic != null`), and it reads the
## world, never writes it. No rng draw, no money, no goods, no per-frame work (event-driven, nothing scanned each tick).
##   World.civic is null when disabled: nothing is constructed, the save has no "civic" key.
##
## A TENURE: {id, office, holder "npc:<id>", name, family, from (day), to (-1 while open), how, cause, observed}
##   - exactly one open tenure per office (a new holder closes the old tenure as "replaced"), one office per holder at a time
##   - `how` when closed: "death", "migration", "left_post", "replaced"
##   - `observed` true: opened by the seeding when the records were attached ("observed from" that day), not by a seen change
## The holder is kept as a reference, with name and family copied in, so a reference resolves after death or departure.
## A VACANCY is the gap between one tenure's `to` and the next's `from` (nothing stored twice).
## The LEGACY of a person: {name, family, end ("death"|"departure"), day, cause, destination, trades [{job, since}],
## offices [office ids]}, kept apart from NPC.memory and World.log_lines, never erased.
## Saved as the optional key "civic" (written only when non-empty; SAVE_VERSION unchanged).

const KEY := "civic"
const FORMAT := "mml-civic/1"

static var override := -1          # tests and the simulation's --civic flag: 1 on, 0 off, -1 the file decides

var w: World
var tenures: Array = []            # append-only, in the order they opened
var legacy: Dictionary = {}        # "npc:<id>" -> record
var seeded_day := -1               # the day the records began to observe (-1: none yet)
var unslotted := 0                 # guards beyond the watch's strength that no slot could hold (should stay 0)
var _open: Dictionary = {}         # office id -> index in tenures (derived)
var _by_holder: Dictionary = {}    # "npc:<id>" -> [tenure indexes] (derived)


static func enabled() -> bool:
	if override >= 0:
		return override == 1
	return bool(CivicOffices.config().get("enabled", false))


## The one attach point. Null (nothing built) when disabled. `saved` is World.to_dict()'s "civic" section, if the save had one.
static func attach(world: World, saved: Dictionary = {}) -> CivicRecords:
	if not enabled():
		return null
	var c := CivicRecords.new()
	c.w = world
	c.load_dict(saved)
	if c.seeded_day < 0:
		c.seed_current()
	return c


func is_empty() -> bool:
	return tenures.is_empty() and legacy.is_empty()


# ------------------------------------------------------------- seeding ----------------------
## Open a tenure for whoever holds a post now (reeve, the guards by id, the sage), "observed from" today.
func seed_current() -> void:
	seeded_day = w.day()
	var rv := w.npc(w.reeve_id)
	if rv != null and rv.alive:
		_open_tenure(CivicOffices.office_id("reeve"), rv, true)
	var slot := 0
	for n: NPC in w.npcs:
		if n.alive and n.job == "guard":
			slot += 1
			if slot <= CivicOffices.guard_count():
				_open_tenure(CivicOffices.office_id("guard", slot), n, true)
			else:
				unslotted += 1
	var sg := w.npc(w.sage_id)
	if sg != null and sg.alive and sg.job == "sage":
		_open_tenure(CivicOffices.office_id("sage"), sg, true)


# ------------------------------------------------------------- observers --------------------
## NPCBrain._reeve_succession: `n` has become reeve (World.reeve_id was just set).
func on_reeve(n: NPC) -> void:
	_open_tenure(CivicOffices.office_id("reeve"), n, false)


## NPCBrain._install: `n` was put in a post (apprentice or newcomer). A reeve takes the office at _reeve_succession, not here.
func on_installed(n: NPC, job: String) -> void:
	match CivicOffices.kind_of_job(job):
		"guard":
			var slot := _free_guard_slot()
			if slot > 0:
				_open_tenure(CivicOffices.office_id("guard", slot), n, false)
			else:
				unslotted += 1
		"sage":
			_open_tenure(CivicOffices.office_id("sage"), n, false)


## NPCBrain._post_left: `n` gave up a post (job) for other work.
func on_post_left(n: NPC, job: String) -> void:
	_close_holder(World.npc_ref(n.id), "left_post", "")


## World.kill: `n` has died of `cause`.
func on_death(n: NPC, cause: String) -> void:
	var ref := World.npc_ref(n.id)
	_close_holder(ref, "death", cause)
	legacy[ref] = _legacy_of(n, "death", cause if cause != "" else "unknown", "")


## Migration._gone: `n` left the village for settlement `to`.
func on_departure(n: NPC, to: String) -> void:
	var ref := World.npc_ref(n.id)
	_close_holder(ref, "migration", "")
	legacy[ref] = _legacy_of(n, "departure", "", to)


# ------------------------------------------------------------- queries ----------------------
## The holder of an office now ("npc:<id>"), "" when vacant.
func holder_of(office: String) -> String:
	return str(tenures[int(_open[office])].holder) if _open.has(office) else ""


func open_tenure_of(office: String) -> Dictionary:
	return tenures[int(_open[office])] if _open.has(office) else {}


func open_count(office: String) -> int:
	return 1 if _open.has(office) else 0


func tenures_of_office(office: String) -> Array:
	return tenures.filter(func(t): return t.office == office)


func tenures_of(ref: String) -> Array:
	var out := []
	for i in _by_holder.get(ref, []):
		out.append(tenures[int(i)])
	return out


func offices_held(ref: String) -> Array:
	var out := []
	for t in tenures_of(ref):
		if not out.has(t.office):
			out.append(t.office)
	return out


## "Name Family" of a person the records name, alive or not; "" when never recorded.
func label_of(ref: String) -> String:
	var n := w.npc(World.ref_id(ref)) if ref.begins_with("npc:") else null
	if n != null:
		return "%s %s" % [n.name, n.family] if n.family != "" else n.name
	if legacy.has(ref):
		var l: Dictionary = legacy[ref]
		return "%s %s" % [l.name, l.family] if str(l.family) != "" else str(l.name)
	var ts := tenures_of(ref)
	if not ts.is_empty():
		return "%s %s" % [ts[0].name, ts[0].family] if str(ts[0].family) != "" else str(ts[0].name)
	return ""


## Differences between the records and the live world (diagnostic, for tests; not run by the game): the open holder of an
## office that is dead or no longer in the post, and a living reeve or guard with no tenure. Empty when they agree.
func audit() -> Array:
	var out := []
	for office in _open:
		var ref := str(holder_of(office))
		var n := w.npc(World.ref_id(ref))
		var kind := str(office).split("/")[1]
		if n == null or not n.alive or n.job != kind:
			out.append("%s held by %s who is not in the post" % [office, ref])
	return out


# ------------------------------------------------------------- internals -------------------
func _free_guard_slot() -> int:
	for i in range(1, CivicOffices.guard_count() + 1):
		if not _open.has(CivicOffices.office_id("guard", i)):
			return i
	return 0


func _open_tenure(office: String, n: NPC, observed: bool) -> void:
	var ref := World.npc_ref(n.id)
	if _open.has(office):
		if str(tenures[int(_open[office])].holder) == ref:
			return                                       # already the holder: never a second tenure
		_close(int(_open[office]), "replaced", "")
	for o in _held_by(ref):                              # one office at a time per holder
		_close(int(_open[o]), "replaced", "")
	tenures.append({"id": tenures.size() + 1, "office": office, "holder": ref, "name": n.name, "family": n.family,
			"from": w.day(), "to": -1, "how": "", "cause": "", "observed": observed})
	var i := tenures.size() - 1
	_open[office] = i
	_by_holder[ref] = _by_holder.get(ref, []) + [i]


func _held_by(ref: String) -> Array:
	var out := []
	for i in _by_holder.get(ref, []):
		var t: Dictionary = tenures[int(i)]
		if int(t.to) < 0:
			out.append(t.office)
	return out


func _close_holder(ref: String, how: String, cause: String) -> void:
	for o in _held_by(ref):
		_close(int(_open[o]), how, cause)


func _close(i: int, how: String, cause: String) -> void:
	var t: Dictionary = tenures[i]
	t.to = w.day()
	t.how = how
	t.cause = cause
	_open.erase(t.office)


func _legacy_of(n: NPC, end: String, cause: String, to: String) -> Dictionary:
	var trades := []
	if n.left_job != "":
		trades.append({"job": n.left_job})
	if n.job != "" and (trades.is_empty() or trades[0].job != n.job):
		trades.append({"job": n.job, "since": n.job_since})
	return {"name": n.name, "family": n.family, "end": end, "day": w.day(), "cause": cause, "destination": to,
			"trades": trades, "offices": offices_held(World.npc_ref(n.id))}


## A saved trade list read back: days are whole numbers again (JSON reads them as floats).
static func _trades_from(a: Array) -> Array:
	var out := []
	for t in a:
		var e := {"job": str(t.job)}
		if t.has("since"):
			e["since"] = int(t.since)
		out.append(e)
	return out


func _reindex() -> void:
	_open.clear()
	_by_holder.clear()
	for i in tenures.size():
		var t: Dictionary = tenures[i]
		_by_holder[t.holder] = _by_holder.get(t.holder, []) + [i]
		if int(t.to) < 0:
			_open[t.office] = i


# ------------------------------------------------------------- save -------------------------
func to_dict() -> Dictionary:
	return {"format": FORMAT, "seeded_day": seeded_day, "unslotted": unslotted, "tenures": tenures.duplicate(true), "legacy": legacy.duplicate(true)}


func load_dict(d: Dictionary) -> void:
	tenures = []
	legacy = {}
	if d.is_empty():
		return
	seeded_day = int(d.get("seeded_day", -1))
	unslotted = int(d.get("unslotted", 0))
	for t in d.get("tenures", []):
		tenures.append({"id": int(t.id), "office": str(t.office), "holder": str(t.holder), "name": str(t.name), "family": str(t.family),
				"from": int(t["from"]), "to": int(t.to), "how": str(t.how), "cause": str(t.cause), "observed": bool(t.observed)})
	var lg: Dictionary = d.get("legacy", {})
	for k in lg:
		var l: Dictionary = lg[k]
		legacy[str(k)] = {"name": str(l.name), "family": str(l.family), "end": str(l.end), "day": int(l.day), "cause": str(l.cause),
				"destination": str(l.destination), "trades": _trades_from(l.trades), "offices": (l.offices as Array).duplicate()}
	_reindex()
